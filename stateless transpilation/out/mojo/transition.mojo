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

from sys import exit as sys_exit
from math import huge

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


@value
struct EnergyPlusState:
    """Stub struct for EnergyPlus shared state."""
    var big_number: Float64
    var d_big_number: Float64
    var path_char: String
    var program_path: String
    var audit_f: Int32
    var progname: String
    var progname_conversion: String
    var ver_string: String
    var with_units: Bool
    var leave_blank: Bool
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var num_rep_var_names: Int32
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var new_rep_var_caution: List[String]
    var out_var_caution: List[Bool]
    var mtr_var_caution: List[Bool]
    var time_bin_var_caution: List[Bool]
    var otm_var_caution: List[Bool]
    var cmtr_var_caution: List[Bool]
    var cmtr_d_var_caution: List[Bool]
    var path_limit: Int32
    var blank: String


@value
struct StringGlobalsState:
    """Stub struct for string globals."""
    var blank: String
    var path_limit: Int32
    
    fn make_upper_case(self, s: String) -> String:
        return s.upper()
    
    fn make_lower_case(self, s: String) -> String:
        return s.lower()
    
    fn convert_case_to_lower(self, line_in: String) -> String:
        return line_in.lower()


trait ProcessorTrait:
    """Trait for processor functions."""
    fn process_input(self, inout state: EnergyPlusState, idd_file: String, new_idd_file: String):
        ...
    fn compare_old_new(self, inout state: EnergyPlusState):
        ...
    fn display_string(self, s: String):
        ...
    fn get_new_unit_number(self) -> Int32:
        ...
    fn create_new_idf_using_rules(
        self, inout state: EnergyPlusState, end_of_file: Bool, diff_only: Bool,
        in_lfn: Int32, ask_for_input: Bool, input_file_name: String,
        arg_file: Bool, arg_file_extension: String
    ):
        ...
    fn set_this_version_variables(self, inout state: EnergyPlusState):
        ...
    fn end_energy_plus(self, inout state: EnergyPlusState):
        ...


alias EPLUS_INI_FORMAT = "(/,'[',A,']',/,'dir=',A)"
alias FMTA = "(A)"
alias MULTIPLE_TRANSITIONS = "MULTIPLETRANSITIONS"
alias CRLF = String(chr(13)) + String(chr(10))


fn read_ini_file(
    inout state: EnergyPlusState,
    inout string_state: StringGlobalsState,
    heading: String,
    kind_of_parameter: String
) -> String:
    """
    Read .ini file and retrieve path names.
    
    SUBROUTINE INFORMATION:
    AUTHOR: Linda K. Lawrie
    DATE WRITTEN: September 1997
    """
    var line_length = state.path_limit + 10
    var data_out = String()
    var param = kind_of_parameter.strip()
    var ilen = len(param)
    var end_of_file = False
    var found = False
    var new_heading = False
    
    try:
        var f = open("Energy+.ini", "r")
        var lines = List[String]()
        for line in f:
            lines.append(line)
        f.close()
        
        var line_idx = 0
        
        while not end_of_file and not found:
            if line_idx >= len(lines):
                end_of_file = True
                break
            
            var line = lines[line_idx]
            line_idx += 1
            
            if len(line.strip()) == 0:
                continue
            
            var line_lower = line.lower()
            
            if heading.lower() not in line_lower:
                continue
            
            var ilb = "[" in line_lower
            var irb = "]" in line_lower
            if not ilb or not irb:
                continue
            
            if "[" + heading.lower() + "]" not in line_lower:
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
                
                ilb = "[" in line_lower
                irb = "]" in line_lower
                new_heading = ilb and irb
                
                var ieq = line_lower.find("=")
                var ipar = line_lower.find(param.lower())
                
                if ieq == -1 or ipar == -1:
                    continue
                
                if param.lower() + "=" not in line_lower:
                    continue
                
                if ipar > ieq:
                    continue
                
                data_out = line[ieq + 1:].strip()
                found = True
                break
    except:
        return data_out
    
    if kind_of_parameter == "dir":
        var ipos = len(data_out.rstrip())
        if ipos != 0:
            if data_out[ipos - 1] != state.path_char[0]:
                data_out = data_out.rstrip() + state.path_char
    
    return data_out


fn transition_main(
    inout state: EnergyPlusState,
    inout string_state: StringGlobalsState,
    inout processor: ProcessorTrait
) -> None:
    """Main program logic for Transition."""
    
    state.big_number = huge[Float64]()
    state.d_big_number = huge[Float64]()
    
    var eplus_ini_exists = False
    try:
        _ = open("Energy+.ini", "r")
        eplus_ini_exists = True
    except:
        eplus_ini_exists = False
    
    if eplus_ini_exists:
        var lfn = processor.get_new_unit_number()
        state.program_path = read_ini_file(state, string_state, "program", "dir")
        
        var len_path = len(state.program_path.rstrip())
        if len_path > 0:
            if state.program_path[len_path - 1] != state.path_char[0]:
                state.program_path = state.program_path.rstrip() + state.path_char
    else:
        state.program_path = "  "
        var lfn = processor.get_new_unit_number()
        try:
            var f = open("Energy+.ini", "w")
            f.write("[program]\ndir=" + state.program_path + "\n")
            f.close()
        except:
            pass
    
    var c_env_value = String()
    var append_audit = False
    
    state.audit_f = processor.get_new_unit_number()
    
    processor.display_string("Transition Starting")
    processor.set_this_version_variables(state)
    
    state.progname = "Conversion"
    state.progname_conversion = state.ver_string
    processor.display_string(state.ver_string)
    
    var audit_file: FileDescriptor
    try:
        if append_audit:
            audit_file = open("Transition.audit", "a")
        else:
            audit_file = open("Transition.audit", "w")
        
        _ = audit_file.write(state.ver_string + "\n")
        if append_audit:
            _ = audit_file.write(" Appending to previous Transition.audit\n")
        else:
            _ = audit_file.write(" Starting new Transition.audit\n")
    except:
        pass
    
    var diff_arg = "FULL"
    var units_arg = "YES"
    var blank_arg = "YES"
    
    var input_file_name = String()
    var list_processing_file_name = String()
    var ask_for_input = False
    var arg_file = False
    var lst_file = False
    var arg_file_extension = "   "
    
    var cmd_args = 0
    
    if cmd_args == 0:
        ask_for_input = True
        arg_file = False
    else:
        input_file_name = String()
        ask_for_input = False
        var dotpos = input_file_name.rfind(".")
        if dotpos >= 0:
            var ext = string_state.make_upper_case(input_file_name[dotpos:])
            if ext == ".IDF" or ext == ".IMF" or ext == ".RVI" or ext == ".MVI":
                arg_file = True
                arg_file_extension = string_state.make_lower_case(input_file_name[dotpos + 1:])
                lst_file = False
            elif ext == ".LST":
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
    
    processor.process_input(state, state.idd_file_name_with_path, state.new_idd_file_name_with_path)
    processor.compare_old_new(state)
    
    var diff_only = False
    var end_of_file = False
    var in_lfn = 0
    var arg_value = String()
    
    if ask_for_input:
        print("Enter \"diff\" for differences only, \"full\" for full idf outputs")
        print("-->", end="")
        input_file_name = input()
        input_file_name = input_file_name.strip()
        if input_file_name.startswith("@"):
            ask_for_input = False
            input_file_name = input_file_name[1:]
            var in_exist = False
            try:
                _ = open(input_file_name, "r")
                in_exist = True
            except:
                in_exist = False
            
            if not in_exist:
                print("No file=" + input_file_name)
                try:
                    _ = audit_file.write(" No file=" + input_file_name + "\n")
                except:
                    pass
                sys_exit(1)
            
            try:
                var f = open(input_file_name, "r")
                arg_value = f.read().strip()
                f.close()
            except:
                arg_value = ""
        else:
            arg_value = input_file_name
    else:
        if not arg_file:
            var in_exist = False
            try:
                _ = open(input_file_name, "r")
                in_exist = True
            except:
                in_exist = False
            
            if not in_exist:
                print("No file=" + input_file_name)
                try:
                    _ = audit_file.write(" No file=" + input_file_name + "\n")
                except:
                    pass
                sys_exit(1)
            
            try:
                var f = open(input_file_name, "r")
                arg_value = f.read().strip()
                f.close()
            except:
                arg_value = ""
        else:
            arg_value = diff_arg
    
    arg_value = arg_value.strip().upper()
    if len(arg_value) > 0 and arg_value[0] == 'd':
        diff_only = True
        processor.display_string("Will create new IDFs with Diff only")
        try:
            _ = audit_file.write(" Will create new IDFs with Diff only\n")
        except:
            pass
    else:
        diff_only = False
        processor.display_string("Will create new full IDFs")
        try:
            _ = audit_file.write(" Will create new full IDFs\n")
        except:
            pass
    
    if arg_value == string_state.blank:
        end_of_file = True
    
    if ask_for_input:
        print("Enter \"yes\" for including units on output lines, \"no\" for no units inclusion")
        print("-->", end="")
        arg_value = input().strip()
    else:
        if not arg_file:
            try:
                var f = open(input_file_name, "r")
                arg_value = f.read().strip()
                f.close()
            except:
                arg_value = ""
                end_of_file = True
        else:
            arg_value = units_arg
    
    arg_value = arg_value.strip().upper()
    if len(arg_value) > 0 and arg_value[0] == 'Y':
        state.with_units = True
        processor.display_string("Will create new IDF lines with units where applicable")
        try:
            _ = audit_file.write(" Will create new IDF lines with units where applicable\n")
        except:
            pass
    else:
        state.with_units = False
        processor.display_string("New IDF lines will not include units")
        try:
            _ = audit_file.write(" New IDF lines will not include units\n")
        except:
            pass
    
    if ask_for_input:
        print("Enter \"yes\" for preserving blanks in default fields, \"no\" to fill those fields with defaults")
        print("-->", end="")
        arg_value = input().strip()
    else:
        if not arg_file:
            try:
                var f = open(input_file_name, "r")
                arg_value = f.read().strip()
                f.close()
            except:
                arg_value = ""
                end_of_file = True
        else:
            arg_value = blank_arg
    
    arg_value = arg_value.strip().upper()
    if len(arg_value) > 0 and arg_value[0] == 'Y':
        state.leave_blank = True
        processor.display_string("Will create new IDF lines leaving blank incoming fields as blank (no default fill)")
        try:
            _ = audit_file.write(" Will create new IDF lines leaving blank incoming fields as blank (no default fill)\n")
        except:
            pass
    else:
        state.leave_blank = False
        processor.display_string("New IDF lines will have blank fields filled with defaults as applicable")
        try:
            _ = audit_file.write(" New IDF lines will have blank fields filled with defaults as applicable\n")
        except:
            pass
    
    var rep_var_file_retry = True
    while rep_var_file_retry:
        rep_var_file_retry = False
        
        var rep_var_exists = False
        try:
            _ = open(state.rep_var_file_name_with_path, "r")
            rep_var_exists = True
        except:
            rep_var_exists = False
        
        if rep_var_exists:
            var lfn2 = processor.get_new_unit_number()
            try:
                var f = open(state.rep_var_file_name_with_path, "r")
                var lines = List[String]()
                for line in f:
                    lines.append(line.rstrip("\n"))
                
                if len(lines) > 1:
                    var num_str = lines[1].strip()
                    state.num_rep_var_names = atol(num_str) if num_str else 0
                    
                    state.old_rep_var_name = List[String]()
                    state.new_rep_var_name = List[String]()
                    state.new_rep_var_caution = List[String]()
                    state.out_var_caution = List[Bool]()
                    state.mtr_var_caution = List[Bool]()
                    state.time_bin_var_caution = List[Bool]()
                    state.otm_var_caution = List[Bool]()
                    state.cmtr_var_caution = List[Bool]()
                    state.cmtr_d_var_caution = List[Bool]()
                    
                    for i in range(state.num_rep_var_names + 2):
                        state.old_rep_var_name.append(string_state.blank)
                        state.new_rep_var_name.append(string_state.blank)
                        state.new_rep_var_caution.append(string_state.blank)
                        state.out_var_caution.append(False)
                        state.mtr_var_caution.append(False)
                        state.time_bin_var_caution.append(False)
                        state.otm_var_caution.append(False)
                        state.cmtr_var_caution.append(False)
                        state.cmtr_d_var_caution.append(False)
                    
                    for count in range(state.num_rep_var_names):
                        if count + 2 < len(lines):
                            var rep_var_line = lines[count + 2]
                            var pos = rep_var_line.find(",")
                            var old_rep_var = String()
                            var new_rep_var = String()
                            
                            if pos >= 0:
                                old_rep_var = rep_var_line[:pos]
                                var remaining = rep_var_line[pos + 1:]
                                pos = remaining.find(",")
                                if pos >= 0:
                                    new_rep_var = remaining[:pos]
                                    rep_var_line = remaining[pos + 1:]
                                else:
                                    new_rep_var = remaining
                                    rep_var_line = ""
                            
                            old_rep_var = old_rep_var.replace("\"", " ").replace("'", " ").strip()
                            new_rep_var = new_rep_var.replace("\"", " ").replace("'", " ").strip()
                            
                            while "," in rep_var_line:
                                pos = rep_var_line.find(",")
                                rep_var_line = rep_var_line[pos + 1:]
                            
                            rep_var_line = rep_var_line.replace("\"", " ").replace("'", " ").strip()
                            
                            state.old_rep_var_name[count] = old_rep_var
                            state.new_rep_var_name[count] = new_rep_var
                            state.new_rep_var_caution[count] = rep_var_line
                
                f.close()
            
            except:
                print(" Report Variable Name file=" + state.rep_var_file_name_with_path)
                print(" is not accessible. Might be in use by another program.")
                try:
                    _ = audit_file.write(" Report Variable Name file=" + state.rep_var_file_name_with_path + "\n")
                    _ = audit_file.write(" is not accessible. Might be in use by another program.\n")
                except:
                    pass
                
                if ask_for_input:
                    print(" Enter Y to proceed anyway, N to try again")
                    var yesno = input().strip()
                    if yesno == "N" or yesno == "n":
                        rep_var_file_retry = True
                        continue
                
                state.num_rep_var_names = 0
                state.old_rep_var_name = List[String]()
                state.new_rep_var_name = List[String]()
                state.new_rep_var_caution = List[String]()
                state.out_var_caution = List[Bool]()
                state.mtr_var_caution = List[Bool]()
                state.time_bin_var_caution = List[Bool]()
                state.otm_var_caution = List[Bool]()
                state.cmtr_var_caution = List[Bool]()
                state.cmtr_d_var_caution = List[Bool]()
                
                for i in range(2):
                    state.old_rep_var_name.append(string_state.blank)
                    state.new_rep_var_name.append(string_state.blank)
                    state.new_rep_var_caution.append(string_state.blank)
                    state.out_var_caution.append(False)
                    state.mtr_var_caution.append(False)
                    state.time_bin_var_caution.append(False)
                    state.otm_var_caution.append(False)
                    state.cmtr_var_caution.append(False)
                    state.cmtr_d_var_caution.append(False)
        else:
            print(" Report Variable Name file=" + state.rep_var_file_name_with_path)
            print(" not found.")
            try:
                _ = audit_file.write(" Report Variable Name file=" + state.rep_var_file_name_with_path + "\n")
                _ = audit_file.write(" not found.\n")
            except:
                pass
            
            state.num_rep_var_names = 0
            state.old_rep_var_name = List[String]()
            state.new_rep_var_name = List[String]()
            state.new_rep_var_caution = List[String]()
            state.out_var_caution = List[Bool]()
            state.mtr_var_caution = List[Bool]()
            state.time_bin_var_caution = List[Bool]()
            state.otm_var_caution = List[Bool]()
            state.cmtr_var_caution = List[Bool]()
            state.cmtr_d_var_caution = List[Bool]()
            
            for i in range(2):
                state.old_rep_var_name.append(string_state.blank)
                state.new_rep_var_name.append(string_state.blank)
                state.new_rep_var_caution.append(string_state.blank)
                state.out_var_caution.append(False)
                state.mtr_var_caution.append(False)
                state.time_bin_var_caution.append(False)
                state.otm_var_caution.append(False)
                state.cmtr_var_caution.append(False)
                state.cmtr_d_var_caution.append(False)
    
    print(lst_file)
    
    if not lst_file:
        processor.create_new_idf_using_rules(state, end_of_file, diff_only, in_lfn, 
                                             ask_for_input, input_file_name, arg_file, 
                                             arg_file_extension)
    else:
        var lfn3 = processor.get_new_unit_number()
        var list_exists = False
        try:
            _ = open(list_processing_file_name, "r")
            list_exists = True
        except:
            list_exists = False
        
        if list_exists:
            try:
                var f = open(list_processing_file_name, "r")
                print(" ListProcessing with file=" + list_processing_file_name)
                try:
                    _ = audit_file.write(" ListProcessing with file=" + list_processing_file_name + "\n")
                except:
                    pass
                
                for line in f:
                    input_file_name = line.rstrip("\n")
                    var dotpos2 = input_file_name.rfind(".")
                    if dotpos2 >= 0:
                        arg_file_extension = string_state.make_lower_case(input_file_name[dotpos2 + 1:])
                    else:
                        arg_file_extension = "idf"
                    processor.create_new_idf_using_rules(state, end_of_file, diff_only, 0,
                                                         ask_for_input, input_file_name,
                                                         arg_file, arg_file_extension)
                f.close()
            except:
                print(" ListProcessing file=" + list_processing_file_name)
                print(" is not accessible. Might be in use by another program.")
                try:
                    _ = audit_file.write(" ListProcessing file=" + list_processing_file_name + "\n")
                    _ = audit_file.write(" is not accessible. Might be in use by another program.\n")
                except:
                    pass
        else:
            print("No file=" + list_processing_file_name)
            try:
                _ = audit_file.write(" No file=" + list_processing_file_name + "\n")
            except:
                pass
    
    try:
        audit_file.close()
    except:
        pass
    
    processor.end_energy_plus(state)


fn main():
    pass
