from collections import InlineArray
from sys import exit as sys_exit
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: UpperCase (String), LowerCase (String), TotalWarningErrors (mutable int ref),
#   TotalSevereErrors (mutable int ref), VerString (String), Elapsed_Time (mutable float ref), ProgramName (String)
# - BasementSimData: EPObjects (Int32, file unit number)
# - ShowErrorMessage(message: String, unit1: Optional[Int32], unit2: Optional[Int32]): fn
# - ShowMessage(message: String, unit1: Optional[Int32], unit2: Optional[Int32]): fn
# - CloseMiscOpenFiles(): fn
# - writePreprocessorObject(unit_no: Int32, program_name: String, severity_level: String, message: String): fn
# - AbortEnergyPlus(): fn

struct StringGlobals:
    var upper_case: String
    var lower_case: String
    var total_warning_errors: Int32
    var total_severe_errors: Int32
    var ver_string: String
    var elapsed_time: Float64
    var program_name: String

struct BasementData:
    var ep_objects: Int32

struct FileUnitManager:
    var open_units: InlineArray[UInt8, 1001]
    var total_errors: Int32
    var standard_error_output: Int32

fn abort_energy_plus(
    inout globals: StringGlobals,
    show_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
    close_misc_fn: fn() -> None,
    get_unit_fn: fn() -> Int32,
):
    let num_warnings = String(globals.total_warning_errors)
    let num_severe = String(globals.total_severe_errors)
    let msg = "GroundTempCalc:Basement Terminated--Fatal Error Detected. " + num_warnings + " Warning; " + num_severe + " Severe Errors"
    
    show_message_fn(msg, None, None)
    
    let tempfl = get_unit_fn()
    var f = open("eplusout.end", "w")
    f.write(msg + "\n")
    f.close()
    
    close_misc_fn()
    sys_exit("GroundTempCalc Terminated--Error(s) Detected.")

fn close_misc_open_files():
    let max_unit_number: Int32 = 1000
    for unit_number in range(1, max_unit_number + 1):
        pass

fn end_energy_plus(
    inout globals: StringGlobals,
    show_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
    close_misc_fn: fn() -> None,
    get_unit_fn: fn() -> Int32,
):
    let num_warnings = String(globals.total_warning_errors)
    let num_severe = String(globals.total_severe_errors)
    
    var elapsed_time = globals.elapsed_time
    let hours = Int32(elapsed_time / 3600.0)
    elapsed_time = elapsed_time - Float64(hours) * 3600.0
    let minutes = Int32(elapsed_time / 60.0)
    elapsed_time = elapsed_time - Float64(minutes) * 60.0
    let seconds = Int32(elapsed_time)
    
    let elapsed_str = String(hours) + "hr " + String(minutes) + "min " + String(seconds) + "sec"
    let msg = "GroundTempCalc:Basement Completed Successfully-- " + num_warnings + " Warning; " + num_severe + " Severe Errors; Elapsed Time=" + elapsed_str
    
    show_message_fn(msg, None, None)
    
    let tempfl = get_unit_fn()
    var f = open("eplusout.end", "w")
    f.write("GroundTempCalc:Basement Completed Successfully-- " + num_warnings + " Warning; " + num_severe + " Severe Errors\n")
    f.close()
    
    close_misc_fn()
    sys_exit("GroundTempCalc Completed Successfully.")

fn get_new_unit_number() -> Int32:
    let end_of_record: Int32 = -2
    let end_of_file: Int32 = -1
    let default_input_unit: Int32 = 5
    let default_output_unit: Int32 = 6
    let number_of_preconnected_units: Int32 = 2
    let preconnected_units = InlineArray[Int32, 2](5, 6)
    let max_unit_number: Int32 = 1000
    
    for unit_number in range(1, max_unit_number + 1):
        if unit_number == default_input_unit or unit_number == default_output_unit:
            continue
        if unit_number == 5 or unit_number == 6:
            continue
        return Int32(unit_number)
    
    return -1

fn find_unit_number(file_name: String) -> Int32:
    let max_unit_number: Int32 = 1000
    return -1

fn convert_case_to_upper(
    input_string: String,
    globals: StringGlobals,
) -> String:
    var output_string = String()
    let input_trimmed = input_string
    
    for a in range(len(input_trimmed)):
        let char = input_string[a]
        let b = globals.lower_case.find(char)
        if b != -1:
            output_string += globals.upper_case[b]
        else:
            output_string += char
    
    return output_string

fn convert_case_to_lower(
    input_string: String,
    globals: StringGlobals,
) -> String:
    var output_string = String()
    let input_trimmed = input_string
    
    for a in range(len(input_trimmed)):
        let char = input_string[a]
        let b = globals.upper_case.find(char)
        if b != -1:
            output_string += globals.lower_case[b]
        else:
            output_string += char
    
    return output_string

fn find_non_space(string: String) -> Int32:
    let ilen = len(string)
    for i in range(ilen):
        if string[i] != " ":
            return Int32(i + 1)
    return 0

fn show_fatal_error(
    error_message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    inout globals: StringGlobals,
    basement_data: BasementData,
    show_error_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
    write_preprocessor_fn: fn(Int32, String, String, String) -> None,
    abort_fn: fn() -> None,
):
    var epo_written = False
    
    if out_unit_1 is not None:
        if out_unit_1.value() == basement_data.ep_objects:
            epo_written = True
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Fatal", error_message)
    
    if out_unit_2 is not None:
        if out_unit_2.value() == basement_data.ep_objects:
            epo_written = True
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Fatal", error_message)
    
    if not epo_written:
        write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Fatal", error_message)
        show_error_message_fn(" **  Fatal  ** " + error_message, out_unit_1, out_unit_2)
    
    abort_fn()

fn show_severe_error(
    error_message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    inout globals: StringGlobals,
    basement_data: BasementData,
    show_error_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
    write_preprocessor_fn: fn(Int32, String, String, String) -> None,
):
    var epo_written = False
    
    globals.total_severe_errors += 1
    
    if out_unit_1 is not None:
        if out_unit_1.value() == basement_data.ep_objects:
            epo_written = True
            show_error_message_fn(" ** Severe  ** " + error_message, out_unit_2, None)
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Severe", error_message)
    
    if out_unit_2 is not None:
        if out_unit_2.value() == basement_data.ep_objects:
            epo_written = True
            show_error_message_fn(" ** Severe  ** " + error_message, out_unit_1, None)
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Severe", error_message)
    
    if not epo_written:
        write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Severe", error_message)
        epo_written = True
        show_error_message_fn(" ** Severe  ** " + error_message, out_unit_1, out_unit_2)

fn show_continue_error(
    message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    show_error_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
):
    show_error_message_fn(" **   ~~~   ** " + message, out_unit_1, out_unit_2)

fn show_message(
    message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    show_error_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
):
    show_error_message_fn(" ************* " + message, out_unit_1, out_unit_2)

fn show_warning_error(
    error_message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    inout globals: StringGlobals,
    basement_data: BasementData,
    show_error_message_fn: fn(String, Optional[Int32], Optional[Int32]) -> None,
    write_preprocessor_fn: fn(Int32, String, String, String) -> None,
):
    var epo_written = False
    
    globals.total_warning_errors += 1
    
    if out_unit_1 is not None:
        if out_unit_1.value() == basement_data.ep_objects:
            epo_written = True
            show_error_message_fn(" ** Warning ** " + error_message, out_unit_2, None)
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Warning", error_message)
    
    if out_unit_2 is not None:
        if out_unit_2.value() == basement_data.ep_objects:
            epo_written = True
            show_error_message_fn(" ** Warning ** " + error_message, out_unit_1, None)
            write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Warning", error_message)
    
    if not epo_written:
        write_preprocessor_fn(basement_data.ep_objects, globals.program_name, "Warning", error_message)
        show_error_message_fn(" ** Warning ** " + error_message, out_unit_1, out_unit_2)

fn show_error_message(
    error_message: String,
    out_unit_1: Optional[Int32],
    out_unit_2: Optional[Int32],
    inout globals: StringGlobals,
    get_unit_fn: fn() -> Int32,
):
    pass

fn write_preprocessor_object(
    unit_no: Int32,
    program_name: String,
    severity_level: String,
    inmessage: String,
):
    let chars_per_line: Int32 = 95
    var message = inmessage
    var len_msg = len(message)
    
    var start_of_line: Int32 = 0
    var end_of_line = start_of_line + chars_per_line
    
    if end_of_line > len_msg:
        end_of_line = len_msg
    else:
        while True:
            while end_of_line < len_msg and message[Int(end_of_line)] != " ":
                end_of_line -= 1
                if end_of_line == start_of_line:
                    end_of_line = start_of_line + chars_per_line
                    if end_of_line > len_msg:
                        end_of_line = len_msg
                    break
            
            start_of_line = end_of_line + 1
            end_of_line = start_of_line + chars_per_line
            
            if start_of_line > len_msg:
                break
            if end_of_line > len_msg:
                end_of_line = len_msg
            if end_of_line - start_of_line + 1 <= chars_per_line:
                break
