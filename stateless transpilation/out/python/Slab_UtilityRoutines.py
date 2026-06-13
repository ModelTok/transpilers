# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: module containing LowerCase (str), UpperCase (str), VerString (str), ProgramName (str), TotalWarningErrors (int), TotalSevereErrors (int), Elapsed_Time (float)
# - SimData: module containing InputEcho (int), SurfaceTemps (int)

import os
import sys
from typing import Optional

class _ExternalData:
    LowerCase = "abcdefghijklmnopqrstuvwxyz"
    UpperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    VerString = "1.0"
    ProgramName = "GroundTempCalc:Slab"
    TotalWarningErrors = 0
    TotalSevereErrors = 0
    Elapsed_Time = 0.0
    InputEcho = 0
    SurfaceTemps = 0

DataStringGlobals = _ExternalData()
SimData = _ExternalData()

_open_units = {}
_total_errors = 0
_standard_error_output = None

def abort_energy_plus():
    num_warnings = str(DataStringGlobals.TotalWarningErrors).lstrip()
    num_severe = str(DataStringGlobals.TotalSevereErrors).lstrip()
    
    message = f'GroundTempCalc:Slab Terminated--Fatal Error Detected. {num_warnings} Warning; {num_severe} Severe Errors'
    show_message(message)
    
    tempfl = get_new_unit_number()
    with open('eplusout.end', 'w') as f:
        f.write(message + '\n')
    
    close_misc_open_files()
    sys.exit('GroundTempCalc Terminated--Error(s) Detected.')

def close_misc_open_files():
    max_unit_number = 1000
    for unit_number in range(1, max_unit_number + 1):
        if unit_number in _open_units:
            try:
                _open_units[unit_number].close()
                del _open_units[unit_number]
            except:
                pass

def end_energy_plus():
    num_warnings = str(DataStringGlobals.TotalWarningErrors).lstrip()
    num_severe = str(DataStringGlobals.TotalSevereErrors).lstrip()
    
    hours = int(DataStringGlobals.Elapsed_Time / 3600.0)
    remaining = DataStringGlobals.Elapsed_Time - hours * 3600
    minutes = int(remaining / 60.0)
    remaining = remaining - minutes * 60
    seconds = int(remaining)
    
    elapsed = f"{hours:02d}hr {minutes:02d}min {seconds:02d}sec"
    
    message = f'GroundTempCalc:Slab Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed}'
    show_message(message)
    
    tempfl = get_new_unit_number()
    with open('eplusout.end', 'w') as f:
        f.write(f'GroundTempCalc:Slab Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors\n')
    
    close_misc_open_files()
    sys.exit('GroundTempCalc Completed Successfully.')

def get_new_unit_number() -> int:
    default_input_unit = 5
    default_output_unit = 6
    preconnected_units = [5, 6]
    max_unit_number = 1000
    
    for unit_number in range(1, max_unit_number + 1):
        if unit_number == default_input_unit or unit_number == default_output_unit:
            continue
        if unit_number in preconnected_units:
            continue
        if unit_number not in _open_units:
            return unit_number
    
    return -1

def find_unit_number(file_name: str) -> int:
    max_unit_number = 1000
    
    try:
        file_exists = os.path.exists(file_name)
        file_is_open = False
    except:
        file_exists = False
        file_is_open = False
    
    if not file_is_open:
        unit_number = get_new_unit_number()
        if unit_number != -1:
            try:
                f = open(file_name, 'a')
                _open_units[unit_number] = f
            except:
                pass
    else:
        file_name_length = len(file_name.rstrip())
        for unit_number in range(1, max_unit_number + 1):
            pass
    
    return unit_number if unit_number != -1 else -1

def convert_case_to_upper(input_string: str) -> str:
    output_string = list(input_string)
    lower_case = DataStringGlobals.LowerCase
    upper_case = DataStringGlobals.UpperCase
    
    ilen = len(input_string.rstrip())
    for a in range(ilen):
        b = lower_case.find(input_string[a])
        if b != -1:
            output_string[a] = upper_case[b]
        else:
            output_string[a] = input_string[a]
    
    return ''.join(output_string)

def convert_case_to_lower(input_string: str) -> str:
    output_string = list(input_string)
    upper_case = DataStringGlobals.UpperCase
    lower_case = DataStringGlobals.LowerCase
    
    ilen = len(input_string.rstrip())
    for a in range(ilen):
        b = upper_case.find(input_string[a])
        if b != -1:
            output_string[a] = lower_case[b]
        else:
            output_string[a] = input_string[a]
    
    return ''.join(output_string)

def find_non_space(string: str) -> int:
    find_non_space_result = 0
    ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            find_non_space_result = i + 1
            break
    return find_non_space_result

def show_fatal_error(error_message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    epo_written = False
    
    if out_unit1 is not None:
        if out_unit1 == SimData.SurfaceTemps:
            epo_written = True
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Fatal', error_message)
            show_error_message(' **  Fatal  ** ' + error_message, out_unit2)
    
    if out_unit2 is not None:
        if out_unit2 == SimData.SurfaceTemps:
            epo_written = True
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Fatal', error_message)
            show_error_message(' **  Fatal  ** ' + error_message, out_unit1)
    
    if not epo_written:
        write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Fatal', error_message)
        show_error_message(' **  Fatal  ** ' + error_message, out_unit1, out_unit2)
    
    abort_energy_plus()

def show_severe_error(error_message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    DataStringGlobals.TotalSevereErrors += 1
    epo_written = False
    
    if out_unit1 is not None:
        if out_unit1 == SimData.SurfaceTemps:
            epo_written = True
            show_error_message(' ** Severe  ** ' + error_message, out_unit2)
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Severe', error_message)
    
    if out_unit2 is not None:
        if out_unit2 == SimData.SurfaceTemps:
            epo_written = True
            show_error_message(' ** Severe  ** ' + error_message, out_unit1)
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Severe', error_message)
    
    if not epo_written:
        write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Severe', error_message)
        show_error_message(' ** Severe  ** ' + error_message, out_unit1, out_unit2)

def show_continue_error(message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    show_error_message(' **   ~~~   ** ' + message, out_unit1, out_unit2)

def show_message(message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    show_error_message(' ************* ' + message, out_unit1, out_unit2)

def show_warning_error(error_message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    DataStringGlobals.TotalWarningErrors += 1
    epo_written = False
    
    if out_unit1 is not None:
        if out_unit1 == SimData.SurfaceTemps:
            epo_written = True
            show_error_message(' ** Warning ** ' + error_message, out_unit2)
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Warning', error_message)
    
    if out_unit2 is not None:
        if out_unit2 == SimData.SurfaceTemps:
            epo_written = True
            show_error_message(' ** Warning ** ' + error_message, out_unit1)
            write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Warning', error_message)
    
    if not epo_written:
        write_preprocessor_object(SimData.SurfaceTemps, DataStringGlobals.ProgramName, 'Warning', error_message)
        show_error_message(' ** Warning ** ' + error_message, out_unit1, out_unit2)

def show_error_message(error_message: str, out_unit1: Optional[int] = None, out_unit2: Optional[int] = None):
    global _total_errors, _standard_error_output
    
    if _total_errors == 0:
        try:
            _standard_error_output = open('eplusout.err', 'w')
            _standard_error_output.write('Program Version,' + DataStringGlobals.VerString + '\n')
        except:
            _standard_error_output = None
    
    _total_errors += 1
    error_format = '  ' + error_message
    
    if _standard_error_output:
        _standard_error_output.write(error_format + '\n')
    
    if out_unit1 is not None and out_unit1 in _open_units:
        _open_units[out_unit1].write(error_format + '\n')
    
    if out_unit2 is not None and out_unit2 in _open_units:
        _open_units[out_unit2].write(error_format + '\n')

def write_preprocessor_object(unit_no: int, program_name: str, severity_level: str, in_message: str):
    chars_per_line = 95
    fmta = 'A'
    message = in_message
    
    len_msg = len(message)
    
    comma_semi_pos = message.find(',')
    while comma_semi_pos >= 0:
        message = message[:comma_semi_pos] + '.' + message[comma_semi_pos+1:]
        comma_semi_pos = message.find(',')
    
    comma_semi_pos = message.find(';')
    while comma_semi_pos >= 0:
        message = message[:comma_semi_pos] + '.' + message[comma_semi_pos+1:]
        comma_semi_pos = message.find(';')
    
    start_of_line = 0
    end_of_line = start_of_line + chars_per_line
    
    if unit_no in _open_units:
        _open_units[unit_no].write(f' Output:PreprocessorMessage,{program_name},{severity_level},\n')
    
    if end_of_line > len_msg:
        end_of_line = len_msg
        if unit_no in _open_units:
            _open_units[unit_no].write(message[start_of_line:end_of_line] + ';\n')
    else:
        while True:
            while end_of_line < len_msg and message[end_of_line] != ' ':
                end_of_line -= 1
                if end_of_line == start_of_line:
                    end_of_line = start_of_line + chars_per_line
                    if end_of_line > len_msg:
                        end_of_line = len_msg
                    break
            
            if end_of_line < len_msg:
                iquote1 = message[start_of_line:len_msg].find('"')
                iquote2 = 0
                if iquote1 >= 0:
                    if iquote1 >= 0 and start_of_line + iquote1 <= end_of_line:
                        iquote2 = message[start_of_line + iquote1 + 1:len_msg].find('"')
                    if iquote1 >= 0 and start_of_line + iquote1 - 1 <= end_of_line and start_of_line + iquote1 + 1 + iquote2 - 1 > end_of_line:
                        end_of_line = start_of_line + iquote1 - 2
                    else:
                        end_of_line = start_of_line + iquote1 + 1 + iquote2 - 1
            
            if end_of_line < len_msg:
                if unit_no in _open_units:
                    _open_units[unit_no].write(message[start_of_line:end_of_line] + ',\n')
            else:
                if unit_no in _open_units:
                    _open_units[unit_no].write(message[start_of_line:min(end_of_line, len_msg)] + ';\n')
            
            start_of_line = end_of_line + 1
            end_of_line = start_of_line + chars_per_line
            if start_of_line > len_msg:
                break
            if end_of_line > len_msg:
                end_of_line = len_msg
            if end_of_line - start_of_line + 1 <= chars_per_line:
                if unit_no in _open_units:
                    _open_units[unit_no].write(message[start_of_line:end_of_line] + ';\n')
                break
