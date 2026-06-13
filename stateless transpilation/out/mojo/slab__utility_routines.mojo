# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: module containing LowerCase (str), UpperCase (str), VerString (str), ProgramName (str), TotalWarningErrors (int), TotalSevereErrors (int), Elapsed_Time (float)
# - SimData: module containing InputEcho (int), SurfaceTemps (int)

from collections import InlineArray
import sys

struct _ExternalData:
    var lower_case: String
    var upper_case: String
    var ver_string: String
    var program_name: String
    var total_warning_errors: Int32
    var total_severe_errors: Int32
    var elapsed_time: Float64
    var input_echo: Int32
    var surface_temps: Int32

var _data_string_globals = _ExternalData(
    lower_case="abcdefghijklmnopqrstuvwxyz",
    upper_case="ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    ver_string="1.0",
    program_name="GroundTempCalc:Slab",
    total_warning_errors=0,
    total_severe_errors=0,
    elapsed_time=0.0,
    input_echo=0,
    surface_temps=0
)

var _open_units: dict[Int32, Int32] = dict()
var _total_errors: Int32 = 0
var _standard_error_output: Int32 = -1

fn abort_energy_plus() -> None:
    var num_warnings = str(_data_string_globals.total_warning_errors)
    var num_severe = str(_data_string_globals.total_severe_errors)
    
    var message = String("GroundTempCalc:Slab Terminated--Fatal Error Detected. ") + num_warnings + String(" Warning; ") + num_severe + String(" Severe Errors")
    show_message(message)
    
    var tempfl = get_new_unit_number()
    sys.exit("GroundTempCalc Terminated--Error(s) Detected.")

fn close_misc_open_files() -> None:
    let max_unit_number: Int32 = 1000
    for unit_number in range(1, max_unit_number + 1):
        pass

fn end_energy_plus() -> None:
    var num_warnings = str(_data_string_globals.total_warning_errors)
    var num_severe = str(_data_string_globals.total_severe_errors)
    
    var hours = Int32(_data_string_globals.elapsed_time / 3600.0)
    var remaining = _data_string_globals.elapsed_time - Float64(hours) * 3600.0
    var minutes = Int32(remaining / 60.0)
    remaining = remaining - Float64(minutes) * 60.0
    var seconds = Int32(remaining)
    
    var elapsed = String()
    # Format string representation
    sys.exit("GroundTempCalc Completed Successfully.")

fn get_new_unit_number() -> Int32:
    let default_input_unit: Int32 = 5
    let default_output_unit: Int32 = 6
    let max_unit_number: Int32 = 1000
    
    for unit_number in range(1, max_unit_number + 1):
        if unit_number == default_input_unit or unit_number == default_output_unit:
            continue
        return Int32(unit_number)
    
    return Int32(-1)

fn find_unit_number(file_name: String) -> Int32:
    let max_unit_number: Int32 = 1000
    return Int32(get_new_unit_number())

fn convert_case_to_upper(input_string: String) -> String:
    var output_string = input_string
    let lower_case = _data_string_globals.lower_case
    let upper_case = _data_string_globals.upper_case
    
    let ilen = len(input_string)
    for a in range(ilen):
        var b = lower_case.find(input_string[a])
        if b >= 0:
            var char_upper = upper_case[b]
            output_string[a] = char_upper
    
    return output_string

fn convert_case_to_lower(input_string: String) -> String:
    var output_string = input_string
    let upper_case = _data_string_globals.upper_case
    let lower_case = _data_string_globals.lower_case
    
    let ilen = len(input_string)
    for a in range(ilen):
        var b = upper_case.find(input_string[a])
        if b >= 0:
            var char_lower = lower_case[b]
            output_string[a] = char_lower
    
    return output_string

fn find_non_space(string: String) -> Int32:
    var find_non_space_result: Int32 = 0
    let ilen = len(string)
    for i in range(ilen):
        if string[i] != ' ':
            find_non_space_result = Int32(i + 1)
            break
    return find_non_space_result

fn show_fatal_error(error_message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    var epo_written: Bool = False
    
    if out_unit1 >= 0:
        if out_unit1 == _data_string_globals.surface_temps:
            epo_written = True
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Fatal", error_message)
            show_error_message(String(" **  Fatal  ** ") + error_message, out_unit2)
    
    if out_unit2 >= 0:
        if out_unit2 == _data_string_globals.surface_temps:
            epo_written = True
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Fatal", error_message)
            show_error_message(String(" **  Fatal  ** ") + error_message, out_unit1)
    
    if not epo_written:
        write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Fatal", error_message)
        show_error_message(String(" **  Fatal  ** ") + error_message, out_unit1, out_unit2)
    
    abort_energy_plus()

fn show_severe_error(error_message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    _data_string_globals.total_severe_errors += 1
    var epo_written: Bool = False
    
    if out_unit1 >= 0:
        if out_unit1 == _data_string_globals.surface_temps:
            epo_written = True
            show_error_message(String(" ** Severe  ** ") + error_message, out_unit2)
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Severe", error_message)
    
    if out_unit2 >= 0:
        if out_unit2 == _data_string_globals.surface_temps:
            epo_written = True
            show_error_message(String(" ** Severe  ** ") + error_message, out_unit1)
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Severe", error_message)
    
    if not epo_written:
        write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Severe", error_message)
        show_error_message(String(" ** Severe  ** ") + error_message, out_unit1, out_unit2)

fn show_continue_error(message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    show_error_message(String(" **   ~~~   ** ") + message, out_unit1, out_unit2)

fn show_message(message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    show_error_message(String(" ************* ") + message, out_unit1, out_unit2)

fn show_warning_error(error_message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    _data_string_globals.total_warning_errors += 1
    var epo_written: Bool = False
    
    if out_unit1 >= 0:
        if out_unit1 == _data_string_globals.surface_temps:
            epo_written = True
            show_error_message(String(" ** Warning ** ") + error_message, out_unit2)
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Warning", error_message)
    
    if out_unit2 >= 0:
        if out_unit2 == _data_string_globals.surface_temps:
            epo_written = True
            show_error_message(String(" ** Warning ** ") + error_message, out_unit1)
            write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Warning", error_message)
    
    if not epo_written:
        write_preprocessor_object(_data_string_globals.surface_temps, _data_string_globals.program_name, "Warning", error_message)
        show_error_message(String(" ** Warning ** ") + error_message, out_unit1, out_unit2)

fn show_error_message(error_message: String, out_unit1: Int32 = -1, out_unit2: Int32 = -1) -> None:
    if _total_errors == 0:
        pass
    
    _total_errors += 1
    var error_format = String("  ") + error_message

fn write_preprocessor_object(unit_no: Int32, program_name: String, severity_level: String, in_message: String) -> None:
    let chars_per_line: Int32 = 95
    var message = in_message
    
    let len_msg = len(message)
    
    var comma_semi_pos = message.find(",")
    while comma_semi_pos >= 0:
        var temp = message[:comma_semi_pos] + String(".") + message[comma_semi_pos+1:]
        message = temp
        comma_semi_pos = message.find(",")
    
    comma_semi_pos = message.find(";")
    while comma_semi_pos >= 0:
        var temp = message[:comma_semi_pos] + String(".") + message[comma_semi_pos+1:]
        message = temp
        comma_semi_pos = message.find(";")
    
    var start_of_line: Int32 = 0
    var end_of_line: Int32 = start_of_line + chars_per_line
    
    if end_of_line > len_msg:
        end_of_line = len_msg
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
                var iquote1 = message[start_of_line:].find("\"")
                var iquote2: Int32 = 0
                if iquote1 >= 0:
                    if start_of_line + iquote1 <= end_of_line:
                        iquote2 = message[start_of_line + iquote1 + 1:].find("\"")
            
            start_of_line = end_of_line + 1
            end_of_line = start_of_line + chars_per_line
            if start_of_line > len_msg:
                break
            if end_of_line > len_msg:
                end_of_line = len_msg
            if end_of_line - start_of_line + 1 <= chars_per_line:
                break
