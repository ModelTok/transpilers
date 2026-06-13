from typing import Optional, Protocol
import sys
from io import IOBase

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: UpperCase (str), LowerCase (str), TotalWarningErrors (int, mutable),
#   TotalSevereErrors (int, mutable), VerString (str), Elapsed_Time (float, mutable), ProgramName (str)
# - BasementSimData: EPObjects (int, file unit number)
# - ShowErrorMessage(message: str, unit1: Optional[int], unit2: Optional[int]): callable
# - ShowMessage(message: str, unit1: Optional[int], unit2: Optional[int]): callable
# - CloseMiscOpenFiles(): callable
# - writePreprocessorObject(unit_no: int, program_name: str, severity_level: str, message: str): callable
# - AbortEnergyPlus(): callable (raises SystemExit)

class MutableInt:
    def __init__(self, value: int = 0):
        self.value = value

class MutableFloat:
    def __init__(self, value: float = 0.0):
        self.value = value

class DataStringGlobals(Protocol):
    UpperCase: str
    LowerCase: str
    TotalWarningErrors: MutableInt
    TotalSevereErrors: MutableInt
    VerString: str
    Elapsed_Time: MutableFloat
    ProgramName: str

class BasementSimData(Protocol):
    EPObjects: int

_open_units = {}
_total_errors = 0
_standard_error_output = None

def abort_energy_plus(
    data_string_globals: DataStringGlobals,
    show_message_fn,
    close_misc_open_files_fn,
    get_new_unit_number_fn,
):
    """AbortEnergyPlus"""
    num_warnings = str(data_string_globals.TotalWarningErrors.value).lstrip()
    num_severe = str(data_string_globals.TotalSevereErrors.value).lstrip()
    
    msg = f'GroundTempCalc:Basement Terminated--Fatal Error Detected. {num_warnings} Warning; {num_severe} Severe Errors'
    show_message_fn(msg, None, None)
    
    tempfl = get_new_unit_number_fn()
    with open('eplusout.end', 'w') as f:
        f.write(msg + '\n')
    
    close_misc_open_files_fn()
    sys.exit('GroundTempCalc Terminated--Error(s) Detected.')

def close_misc_open_files():
    """CloseMiscOpenFiles"""
    max_unit_number = 1000
    for unit_number in range(1, max_unit_number + 1):
        if unit_number in _open_units:
            try:
                _open_units[unit_number].close()
                del _open_units[unit_number]
            except:
                pass

def end_energy_plus(
    data_string_globals: DataStringGlobals,
    show_message_fn,
    close_misc_open_files_fn,
    get_new_unit_number_fn,
):
    """EndEnergyPlus"""
    num_warnings = str(data_string_globals.TotalWarningErrors.value).lstrip()
    num_severe = str(data_string_globals.TotalSevereErrors.value).lstrip()
    
    elapsed_time = data_string_globals.Elapsed_Time.value
    hours = int(elapsed_time / 3600.0)
    elapsed_time = elapsed_time - hours * 3600
    minutes = int(elapsed_time / 60.0)
    elapsed_time = elapsed_time - minutes * 60
    seconds = int(elapsed_time)
    elapsed_str = f'{hours:02d}hr {minutes:02d}min {seconds:02d}sec'
    
    msg = f'GroundTempCalc:Basement Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed_str}'
    show_message_fn(msg, None, None)
    
    tempfl = get_new_unit_number_fn()
    with open('eplusout.end', 'w') as f:
        f.write(f'GroundTempCalc:Basement Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors\n')
    
    close_misc_open_files_fn()
    sys.exit('GroundTempCalc Completed Successfully.')

def get_new_unit_number() -> int:
    """GetNewUnitNumber"""
    END_OF_RECORD = -2
    END_OF_FILE = -1
    DEFAULT_INPUT_UNIT = 5
    DEFAULT_OUTPUT_UNIT = 6
    NUMBER_OF_PRECONNECTED_UNITS = 2
    PRECONNECTED_UNITS = [5, 6]
    MaxUnitNumber = 1000
    
    for unit_number in range(1, MaxUnitNumber + 1):
        if unit_number == DEFAULT_INPUT_UNIT or unit_number == DEFAULT_OUTPUT_UNIT:
            continue
        if unit_number in PRECONNECTED_UNITS:
            continue
        if unit_number not in _open_units:
            return unit_number
    
    return -1

def find_unit_number(file_name: str) -> int:
    """FindUnitNumber"""
    MaxUnitNumber = 1000
    
    if file_name not in [f.name for f in _open_units.values() if hasattr(f, 'name')]:
        unit_number = get_new_unit_number()
        f = open(file_name, 'a')
        _open_units[unit_number] = f
        return unit_number
    else:
        file_name_length = len(file_name.rstrip())
        for unit_number in range(1, MaxUnitNumber + 1):
            if unit_number in _open_units:
                test_file = _open_units[unit_number]
                if hasattr(test_file, 'name'):
                    test_file_name = test_file.name
                    test_file_length = len(test_file_name.rstrip())
                    pos = test_file_name.find(file_name)
                    if pos != -1:
                        if pos + file_name_length - 1 == test_file_length - 1:
                            return unit_number
    
    return -1

def convert_case_to_upper(
    input_string: str,
    data_string_globals: DataStringGlobals,
) -> str:
    """ConvertCasetoUpper"""
    output_string = list(input_string)
    input_trimmed = input_string.rstrip()
    
    for a in range(len(input_trimmed)):
        b = data_string_globals.LowerCase.find(input_string[a])
        if b != -1:
            output_string[a] = data_string_globals.UpperCase[b]
    
    return ''.join(output_string)

def convert_case_to_lower(
    input_string: str,
    data_string_globals: DataStringGlobals,
) -> str:
    """ConvertCasetoLower"""
    output_string = list(input_string)
    input_trimmed = input_string.rstrip()
    
    for a in range(len(input_trimmed)):
        b = data_string_globals.UpperCase.find(input_string[a])
        if b != -1:
            output_string[a] = data_string_globals.LowerCase[b]
    
    return ''.join(output_string)

def find_non_space(string: str) -> int:
    """FindNonSpace"""
    ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0

def show_fatal_error(
    error_message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    data_string_globals: DataStringGlobals,
    basement_sim_data: BasementSimData,
    show_error_message_fn,
    write_preprocessor_object_fn,
    abort_energy_plus_fn,
):
    """ShowFatalError"""
    epo_written = False
    
    if out_unit_1 is not None:
        if out_unit_1 == basement_sim_data.EPObjects:
            epo_written = True
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Fatal', error_message)
    
    if out_unit_2 is not None:
        if out_unit_2 == basement_sim_data.EPObjects:
            epo_written = True
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Fatal', error_message)
    
    if not epo_written:
        write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Fatal', error_message)
        show_error_message_fn(' **  Fatal  ** ' + error_message, out_unit_1, out_unit_2)
    
    abort_energy_plus_fn()

def show_severe_error(
    error_message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    data_string_globals: DataStringGlobals,
    basement_sim_data: BasementSimData,
    show_error_message_fn,
    write_preprocessor_object_fn,
):
    """ShowSevereError"""
    epo_written = False
    
    data_string_globals.TotalSevereErrors.value += 1
    
    if out_unit_1 is not None:
        if out_unit_1 == basement_sim_data.EPObjects:
            epo_written = True
            show_error_message_fn(' ** Severe  ** ' + error_message, out_unit_2)
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Severe', error_message)
    
    if out_unit_2 is not None:
        if out_unit_2 == basement_sim_data.EPObjects:
            epo_written = True
            show_error_message_fn(' ** Severe  ** ' + error_message, out_unit_1)
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Severe', error_message)
    
    if not epo_written:
        write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Severe', error_message)
        epo_written = True
        show_error_message_fn(' ** Severe  ** ' + error_message, out_unit_1, out_unit_2)

def show_continue_error(
    message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    show_error_message_fn,
):
    """ShowContinueError"""
    show_error_message_fn(' **   ~~~   ** ' + message, out_unit_1, out_unit_2)

def show_message(
    message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    show_error_message_fn,
):
    """ShowMessage"""
    show_error_message_fn(' ************* ' + message, out_unit_1, out_unit_2)

def show_warning_error(
    error_message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    data_string_globals: DataStringGlobals,
    basement_sim_data: BasementSimData,
    show_error_message_fn,
    write_preprocessor_object_fn,
):
    """ShowWarningError"""
    epo_written = False
    
    data_string_globals.TotalWarningErrors.value += 1
    
    if out_unit_1 is not None:
        if out_unit_1 == basement_sim_data.EPObjects:
            epo_written = True
            show_error_message_fn(' ** Warning ** ' + error_message, out_unit_2)
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Warning', error_message)
    
    if out_unit_2 is not None:
        if out_unit_2 == basement_sim_data.EPObjects:
            epo_written = True
            show_error_message_fn(' ** Warning ** ' + error_message, out_unit_1)
            write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Warning', error_message)
    
    if not epo_written:
        write_preprocessor_object_fn(basement_sim_data.EPObjects, data_string_globals.ProgramName, 'Warning', error_message)
        show_error_message_fn(' ** Warning ** ' + error_message, out_unit_1, out_unit_2)

def show_error_message(
    error_message: str,
    out_unit_1: Optional[int],
    out_unit_2: Optional[int],
    data_string_globals: DataStringGlobals,
    get_new_unit_number_fn,
):
    """ShowErrorMessage"""
    global _total_errors, _standard_error_output
    
    error_format = '  {}'
    
    if _total_errors == 0:
        _standard_error_output = get_new_unit_number_fn()
        with open('eplusout.err', 'w') as f:
            f.write(f'Program Version,{data_string_globals.VerString}\n')
            _open_units[_standard_error_output] = f
    
    _total_errors += 1
    
    if _standard_error_output is not None and _standard_error_output in _open_units:
        _open_units[_standard_error_output].write(error_format.format(error_message.rstrip()) + '\n')
    
    if out_unit_1 is not None and out_unit_1 in _open_units:
        _open_units[out_unit_1].write(error_format.format(error_message.rstrip()) + '\n')
    
    if out_unit_2 is not None and out_unit_2 in _open_units:
        _open_units[out_unit_2].write(error_format.format(error_message.rstrip()) + '\n')

def write_preprocessor_object(
    unit_no: int,
    program_name: str,
    severity_level: str,
    inmessage: str,
):
    """writePreProcessorObject"""
    chars_per_line = 95
    message = inmessage
    
    if unit_no not in _open_units:
        return
    
    unit_file = _open_units[unit_no]
    unit_file.write(f' Output:PreprocessorMessage,{program_name},{severity_level},\n')
    
    len_msg = len(message)
    message = message.replace(',', '.')
    message = message.replace(';', '.')
    
    start_of_line = 0
    end_of_line = start_of_line + chars_per_line
    
    if end_of_line > len_msg:
        end_of_line = len_msg
        unit_file.write(message[start_of_line:end_of_line] + ';\n')
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
                    if (iquote1 >= 0 and start_of_line + iquote1 - 1 <= end_of_line and
                        start_of_line + iquote1 + 1 + iquote2 - 1 > end_of_line):
                        end_of_line = start_of_line + iquote1 - 2
                    else:
                        end_of_line = start_of_line + iquote1 + 1 + iquote2 - 1
            
            if end_of_line < len_msg:
                unit_file.write(message[start_of_line:end_of_line] + ',\n')
            else:
                unit_file.write(message[start_of_line:min(end_of_line, len_msg)] + ';\n')
            
            start_of_line = end_of_line + 1
            end_of_line = start_of_line + chars_per_line
            
            if start_of_line > len_msg:
                break
            if end_of_line > len_msg:
                end_of_line = len_msg
            if end_of_line - start_of_line + 1 <= chars_per_line:
                unit_file.write(message[start_of_line:end_of_line] + ';\n')
                break
