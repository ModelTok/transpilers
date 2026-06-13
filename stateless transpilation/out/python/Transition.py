"""
NOTICE

Copyright 1996-2010 The Board of Trustees of the University of Illinois
and The Regents of the University of California through Ernest Orlando Lawrence
Berkeley National Laboratory, pending any required approval by the
US Department of Energy. All rights reserved.

Portions of the EnergyPlus software package have been developed and copyrighted
by other individuals, companies and institutions. These portions have been
incorporated into the EnergyPlus software package under license.

NOTICE: The U.S. Government is granted for itself and others acting on its
behalf a paid-up, nonexclusive, irrevocable, worldwide license in this data to
reproduce, prepare derivative works, and perform publicly and display publicly.

PROGRAM INFORMATION:
AUTHOR: Linda K. Lawrie, et al
DATE WRITTEN: January 1997
"""

import sys
import os
from typing import Protocol

# EXTERNAL DEPS (to wire in glue):
# - DataGlobals.BigNumber, DBigNumber, PathChar, ProgramPath, AuditF, Progname, PrognameConversion
#   VerString, withUnits, LeaveBlank, IDDFileNameWithPath, NewIDDFileNameWithPath,
#   RepVarFileNameWithPath, NumRepVarNames, OldRepVarName, NewRepVarName, NewRepVarCaution,
#   OutVarCaution, MtrVarCaution, TimeBinVarCaution, OTMVarCaution, CMtrVarCaution,
#   CMtrDVarCaution (from DataGlobals)
# - DataStringGlobals.PathLimit, Blank, MakeUPPERCase(), MakeLowerCase(), ConvertCasetoLower()
# - InputProcessor.ProcessInput()
# - SetVersion.SetThisVersionVariables()
# - DisplayString(), GetNewUnitNumber(), CompareOldNew(), CreateNewIDFUsingRules(), EndEnergyPlus()


class EnergyPlusState(Protocol):
    """Stub protocol for EnergyPlus shared state."""
    big_number: float
    d_big_number: float
    path_char: str
    program_path: str
    audit_f: int
    progname: str
    progname_conversion: str
    ver_string: str
    with_units: bool
    leave_blank: bool
    idd_file_name_with_path: str
    new_idd_file_name_with_path: str
    rep_var_file_name_with_path: str
    num_rep_var_names: int
    old_rep_var_name: list
    new_rep_var_name: list
    new_rep_var_caution: list
    out_var_caution: list
    mtr_var_caution: list
    time_bin_var_caution: list
    otm_var_caution: list
    cmtr_var_caution: list
    cmtr_d_var_caution: list
    path_limit: int
    blank: str


class StringGlobalsState(Protocol):
    """Stub protocol for string globals."""
    blank: str
    path_limit: int
    def make_upper_case(self, s: str) -> str: ...
    def make_lower_case(self, s: str) -> str: ...
    def convert_case_to_lower(self, line_in: str, line_out: str) -> str: ...


class ProcessorState(Protocol):
    """Stub protocol for processor functions."""
    def process_input(self, idd_file: str, new_idd_file: str) -> None: ...
    def compare_old_new(self) -> None: ...
    def display_string(self, s: str) -> None: ...
    def get_new_unit_number(self) -> int: ...
    def create_new_idf_using_rules(self, end_of_file: bool, diff_only: bool, 
                                   in_lfn: int, ask_for_input: bool, 
                                   input_file_name: str, arg_file: bool, 
                                   arg_file_extension: str) -> None: ...
    def set_this_version_variables(self) -> None: ...
    def end_energy_plus(self) -> None: ...


EPLUS_INI_FORMAT = "(/,'[',A,']',/,'dir=',A)"
FMTA = "(A)"
MULTIPLE_TRANSITIONS = 'MULTIPLETRANSITIONS'
CRLF = chr(13) + chr(10)


def read_ini_file(unit_number: int, heading: str, kind_of_parameter: str, 
                  state: StringGlobalsState) -> str:
    """
    Read .ini file and retrieve path names.
    
    SUBROUTINE INFORMATION:
    AUTHOR: Linda K. Lawrie
    DATE WRITTEN: September 1997
    """
    line_length = state.path_limit + 10
    
    data_out = ''
    param = kind_of_parameter.strip()
    ilen = len(param)
    
    end_of_file = False
    found = False
    new_heading = False
    
    try:
        with open('Energy+.ini', 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return data_out
    
    line_idx = 0
    
    while not end_of_file and not found:
        if line_idx >= len(lines):
            end_of_file = True
            break
        
        line = lines[line_idx]
        line_idx += 1
        
        if len(line.strip()) == 0:
            continue
        
        line_lower = line.lower()
        
        if heading.lower() not in line_lower:
            continue
        
        ilb = '[' in line_lower
        irb = ']' in line_lower
        if not ilb or not irb:
            continue
        
        if '[' + heading.lower() + ']' not in line_lower:
            continue
        
        while not end_of_file and not new_heading:
            if line_idx >= len(lines):
                end_of_file = True
                break
            
            line = lines[line_idx]
            line_idx += 1
            
            if len(line.strip()) == 0:
                continue
            
            line_lower = line.lower()
            
            ilb = '[' in line_lower
            irb = ']' in line_lower
            new_heading = ilb and irb
            
            ieq = line_lower.find('=')
            ipar = line_lower.find(param.lower())
            
            if ieq == -1 or ipar == -1:
                continue
            
            if param.lower() + '=' not in line_lower:
                continue
            
            if ipar > ieq:
                continue
            
            data_out = line[ieq + 1:].strip()
            found = True
            break
    
    if kind_of_parameter == 'dir':
        ipos = len(data_out.rstrip())
        if ipos != 0:
            if data_out[ipos - 1] != state.path_limit:
                data_out = data_out.rstrip() + state.path_limit
    
    return data_out


def transition_main(state: EnergyPlusState, string_state: StringGlobalsState, 
                    processor: ProcessorState) -> None:
    """Main program logic for Transition."""
    
    state.big_number = sys.float_info.max
    state.d_big_number = sys.float_info.max
    
    eplus_ini_exists = os.path.exists('Energy+.ini')
    if eplus_ini_exists:
        lfn = processor.get_new_unit_number()
        state.program_path = read_ini_file(lfn, 'program', 'dir', string_state)
        
        len_path = len(state.program_path.rstrip())
        if len_path > 0:
            if state.program_path[len_path - 1] != state.path_char:
                state.program_path = state.program_path.rstrip() + state.path_char
    else:
        state.program_path = '  '
        lfn = processor.get_new_unit_number()
        with open('Energy+.ini', 'w') as f:
            f.write(f"[program]\ndir={state.program_path}\n")
    
    c_env_value = os.getenv(MULTIPLE_TRANSITIONS, '')
    c_env_value = string_state.make_upper_case(c_env_value)
    append_audit = c_env_value[0:1] == 'Y' if c_env_value else False
    
    state.audit_f = processor.get_new_unit_number()
    
    processor.display_string('Transition Starting')
    processor.set_this_version_variables()
    
    state.progname = 'Conversion'
    state.progname_conversion = state.ver_string
    processor.display_string(state.ver_string)
    
    audit_mode = 'a' if append_audit else 'w'
    audit_file = open('Transition.audit', audit_mode)
    
    audit_file.write(state.ver_string + '\n')
    if append_audit:
        audit_file.write(' Appending to previous Transition.audit\n')
    else:
        audit_file.write(' Starting new Transition.audit\n')
    
    diff_arg = 'FULL'
    units_arg = 'YES'
    blank_arg = 'YES'
    
    cmd_args = len(sys.argv) - 1
    input_file_name = ''
    list_processing_file_name = ''
    ask_for_input = False
    arg_file = False
    lst_file = False
    arg_file_extension = '   '
    
    if cmd_args == 0:
        ask_for_input = True
        arg_file = False
    else:
        input_file_name = sys.argv[1].strip()
        ask_for_input = False
        dotpos = input_file_name.rfind('.')
        if dotpos >= 0:
            ext = string_state.make_upper_case(input_file_name[dotpos:])
            if ext in ['.IDF', '.IMF', '.RVI', '.MVI']:
                arg_file = True
                arg_file_extension = string_state.make_lower_case(input_file_name[dotpos + 1:])
                lst_file = False
            elif ext == '.LST':
                list_processing_file_name = input_file_name
                arg_file = True
                lst_file = True
            else:
                list_processing_file_name = input_file_name
                arg_file = True
                lst_file = True
        else:
            list_processing_file_name = input_file_name
            arg_file = True
            lst_file = True
        
        if cmd_args > 1:
            diff_arg = string_state.make_upper_case(sys.argv[2])
        if cmd_args > 2:
            units_arg = string_state.make_upper_case(sys.argv[3])
        if cmd_args > 3:
            blank_arg = string_state.make_upper_case(sys.argv[4])
    
    processor.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path)
    processor.compare_old_new()
    
    if ask_for_input:
        print('Enter "diff" for differences only, "full" for full idf outputs')
        print('-->', end='')
        input_file_name = input().strip()
        if input_file_name.startswith('@'):
            ask_for_input = False
            input_file_name = input_file_name[1:]
            if not os.path.exists(input_file_name):
                print(f'No file={input_file_name}')
                audit_file.write(f' No file={input_file_name}\n')
                audit_file.close()
                sys.exit(1)
            in_lfn = processor.get_new_unit_number()
            with open(input_file_name, 'r') as f:
                try:
                    arg_value = f.readline().strip()
                except:
                    arg_value = ''
        else:
            arg_value = input_file_name
    else:
        if not arg_file:
            if not os.path.exists(input_file_name):
                print(f'No file={input_file_name}')
                audit_file.write(f' No file={input_file_name}\n')
                audit_file.close()
                sys.exit(1)
            in_lfn = processor.get_new_unit_number()
            with open(input_file_name, 'r') as f:
                try:
                    arg_value = f.readline().strip()
                except:
                    arg_value = ''
        else:
            arg_value = diff_arg
    
    arg_value = arg_value.strip().upper()
    end_of_file = False
    if arg_value[0:1] == 'D':
        diff_only = True
        processor.display_string('Will create new IDFs with Diff only')
        audit_file.write(' Will create new IDFs with Diff only\n')
    else:
        diff_only = False
        processor.display_string('Will create new full IDFs')
        audit_file.write(' Will create new full IDFs\n')
    
    if arg_value == string_state.blank:
        end_of_file = True
    
    if ask_for_input:
        print('Enter "yes" for including units on output lines, "no" for no units inclusion')
        print('-->', end='')
        arg_value = input().strip()
    else:
        if not arg_file:
            try:
                with open(input_file_name, 'r') as f:
                    arg_value = f.readline().strip()
            except:
                arg_value = ''
                end_of_file = True
        else:
            arg_value = units_arg
    
    arg_value = arg_value.strip().upper()
    if arg_value[0:1] == 'Y':
        state.with_units = True
        processor.display_string('Will create new IDF lines with units where applicable')
        audit_file.write(' Will create new IDF lines with units where applicable\n')
    else:
        state.with_units = False
        processor.display_string('New IDF lines will not include units')
        audit_file.write(' New IDF lines will not include units\n')
    
    if ask_for_input:
        print('Enter "yes" for preserving blanks in default fields, "no" to fill those fields with defaults')
        print('-->', end='')
        arg_value = input().strip()
    else:
        if not arg_file:
            try:
                with open(input_file_name, 'r') as f:
                    arg_value = f.readline().strip()
            except:
                arg_value = ''
                end_of_file = True
        else:
            arg_value = blank_arg
    
    arg_value = arg_value.strip().upper()
    if arg_value[0:1] == 'Y':
        state.leave_blank = True
        processor.display_string('Will create new IDF lines leaving blank incoming fields as blank (no default fill)')
        audit_file.write(' Will create new IDF lines leaving blank incoming fields as blank (no default fill)\n')
    else:
        state.leave_blank = False
        processor.display_string('New IDF lines will have blank fields filled with defaults as applicable')
        audit_file.write(' New IDF lines will have blank fields filled with defaults as applicable\n')
    
    rep_var_file_retry = True
    while rep_var_file_retry:
        rep_var_file_retry = False
        
        if os.path.exists(state.rep_var_file_name_with_path):
            lfn = processor.get_new_unit_number()
            try:
                with open(state.rep_var_file_name_with_path, 'r') as f:
                    lines = f.readlines()
                    f.seek(0)
                    f.readline()
                    num_rep_var_names_str = f.readline().strip()
                    state.num_rep_var_names = int(num_rep_var_names_str) if num_rep_var_names_str else 0
                    
                    state.old_rep_var_name = [string_state.blank] * (state.num_rep_var_names + 2)
                    state.new_rep_var_name = [string_state.blank] * (state.num_rep_var_names + 2)
                    state.new_rep_var_caution = [string_state.blank] * (state.num_rep_var_names + 2)
                    state.out_var_caution = [False] * (state.num_rep_var_names + 2)
                    state.mtr_var_caution = [False] * (state.num_rep_var_names + 2)
                    state.time_bin_var_caution = [False] * (state.num_rep_var_names + 2)
                    state.otm_var_caution = [False] * (state.num_rep_var_names + 2)
                    state.cmtr_var_caution = [False] * (state.num_rep_var_names + 2)
                    state.cmtr_d_var_caution = [False] * (state.num_rep_var_names + 2)
                    
                    f.seek(0)
                    f.readline()
                    f.readline()
                    
                    for count in range(state.num_rep_var_names):
                        rep_var_line = f.readline().rstrip('\n')
                        pos = rep_var_line.find(',')
                        if pos >= 0:
                            old_rep_var = rep_var_line[:pos]
                            remaining = rep_var_line[pos + 1:]
                            pos = remaining.find(',')
                            if pos >= 0:
                                new_rep_var = remaining[:pos]
                                rep_var_line = remaining[pos + 1:]
                            else:
                                new_rep_var = remaining
                                rep_var_line = ''
                        
                        old_rep_var = old_rep_var.replace('"', ' ').replace("'", ' ').strip()
                        new_rep_var = new_rep_var.replace('"', ' ').replace("'", ' ').strip()
                        
                        while ',' in rep_var_line:
                            pos = rep_var_line.find(',')
                            rep_var_line = rep_var_line[pos + 1:]
                        
                        rep_var_line = rep_var_line.replace('"', ' ').replace("'", ' ').strip()
                        
                        state.old_rep_var_name[count] = old_rep_var
                        state.new_rep_var_name[count] = new_rep_var
                        state.new_rep_var_caution[count] = rep_var_line
            
            except IOError:
                print(f' Report Variable Name file={state.rep_var_file_name_with_path}')
                print(' is not accessible. Might be in use by another program.')
                audit_file.write(f' Report Variable Name file={state.rep_var_file_name_with_path}\n')
                audit_file.write(' is not accessible. Might be in use by another program.\n')
                
                if ask_for_input:
                    print(' Enter Y to proceed anyway, N to try again')
                    yesno = input().strip()
                    if yesno == 'N' or yesno == 'n':
                        rep_var_file_retry = True
                        continue
                
                state.num_rep_var_names = 0
                state.old_rep_var_name = [string_state.blank] * 2
                state.new_rep_var_name = [string_state.blank] * 2
                state.new_rep_var_caution = [string_state.blank] * 2
                state.out_var_caution = [False] * 2
                state.mtr_var_caution = [False] * 2
                state.time_bin_var_caution = [False] * 2
                state.otm_var_caution = [False] * 2
                state.cmtr_var_caution = [False] * 2
                state.cmtr_d_var_caution = [False] * 2
        else:
            print(f' Report Variable Name file={state.rep_var_file_name_with_path}')
            print(' not found.')
            audit_file.write(f' Report Variable Name file={state.rep_var_file_name_with_path}\n')
            audit_file.write(' not found.\n')
            
            state.num_rep_var_names = 0
            state.old_rep_var_name = [string_state.blank] * 2
            state.new_rep_var_name = [string_state.blank] * 2
            state.new_rep_var_caution = [string_state.blank] * 2
            state.out_var_caution = [False] * 2
            state.mtr_var_caution = [False] * 2
            state.time_bin_var_caution = [False] * 2
            state.otm_var_caution = [False] * 2
            state.cmtr_var_caution = [False] * 2
            state.cmtr_d_var_caution = [False] * 2
    
    print(lst_file)
    
    if not lst_file:
        processor.create_new_idf_using_rules(end_of_file, diff_only, 0, ask_for_input, 
                                             input_file_name, arg_file, arg_file_extension)
    else:
        lfn = processor.get_new_unit_number()
        if os.path.exists(list_processing_file_name):
            try:
                with open(list_processing_file_name, 'r') as f:
                    print(f' ListProcessing with file={list_processing_file_name}')
                    audit_file.write(f' ListProcessing with file={list_processing_file_name}\n')
                    for input_file_name in f:
                        input_file_name = input_file_name.rstrip('\n')
                        dotpos = input_file_name.rfind('.')
                        if dotpos >= 0:
                            arg_file_extension = string_state.make_lower_case(input_file_name[dotpos + 1:])
                        else:
                            arg_file_extension = 'idf'
                        processor.create_new_idf_using_rules(end_of_file, diff_only, 0, 
                                                             ask_for_input, input_file_name, 
                                                             arg_file, arg_file_extension)
            except IOError:
                print(f' ListProcessing file={list_processing_file_name}')
                print(' is not accessible. Might be in use by another program.')
                audit_file.write(f' ListProcessing file={list_processing_file_name}\n')
                audit_file.write(' is not accessible. Might be in use by another program.\n')
        else:
            print(f'No file={list_processing_file_name}')
            audit_file.write(f' No file={list_processing_file_name}\n')
    
    audit_file.close()
    processor.end_energy_plus()


if __name__ == '__main__':
    pass
