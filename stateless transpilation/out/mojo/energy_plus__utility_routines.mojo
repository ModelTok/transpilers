from collections import List, Dict, Optional
from math import max as math_max, min as math_min, isfinite

enum ErrorMessageCategory:
    Invalid = -1
    Unclassified = 0
    Input_invalid = 1
    Input_field_not_found = 2
    Input_field_blank = 3
    Input_object_not_found = 4
    Input_cannot_find_object = 5
    Input_topology_problem = 6
    Input_unused = 7
    Input_fatal = 8
    Runtime_general = 9
    Runtime_flow_out_of_range = 10
    Runtime_temp_out_of_range = 11
    Runtime_airflow_network = 12
    Fatal_general = 13
    Developer_general = 14
    Developer_invalid_index = 15
    Num = 16

enum Clusive:
    Invalid = -1
    In = 0
    Ex = 1
    Num = 2

struct ErrorCountIndex:
    var index: Int
    var count: Int
    
    fn __init__(inout self):
        self.index = 0
        self.count = 0

struct ErrorObjectHeader:
    var routineName: String
    var objectType: String
    var objectName: String
    
    fn __init__(inout self, name: String, obj_type: String, obj_name: String):
        self.routineName = name
        self.objectType = obj_type
        self.objectName = obj_name

struct UtilityRoutinesData:
    var outputErrorHeader: Bool
    var appendPerfLog_headerRow: String
    var appendPerfLog_valuesRow: String
    var GetMatrixInputFlag: Bool
    
    fn __init__(inout self):
        self.outputErrorHeader = True
        self.appendPerfLog_headerRow = ""
        self.appendPerfLog_valuesRow = ""
        self.GetMatrixInputFlag = True
    
    fn init_constant_state(inout self, state: SIMD[DType.float64, 1]) -> None:
        pass
    
    fn init_state(inout self, state: SIMD[DType.float64, 1]) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        self.outputErrorHeader = True
        self.appendPerfLog_headerRow = ""
        self.appendPerfLog_valuesRow = ""
        self.GetMatrixInputFlag = True

var MONTH_NAMES_CC = InlineArray[StringLiteral, 12]("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
var MONTH_NAMES_UC = InlineArray[StringLiteral, 12]("JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER")
var YES_NO_NAMES = InlineArray[StringLiteral, 2]("No", "Yes")
var YES_NO_NAMES_UC = InlineArray[StringLiteral, 2]("NO", "YES")

@always_inline
fn pow2[T: Numeric](x: T) -> T:
    return x * x

@always_inline
fn pow3[T: Numeric](x: T) -> T:
    return x * x * x

@always_inline
fn pow4[T: Numeric](x: T) -> T:
    var y = x * x
    return y * y

@always_inline
fn pow5[T: Numeric](x: T) -> T:
    var y = x * x
    y *= y
    return y * x

@always_inline
fn pow6[T: Numeric](x: T) -> T:
    var y = x * x
    y *= y
    return y * y

@always_inline
fn pow7[T: Numeric](x: T) -> T:
    var y = x * x
    y *= y
    y *= y
    return y * x

fn env_var_on(env_var_str: String) -> Bool:
    return len(env_var_str) > 0 and (env_var_str[0] == 'Y' or env_var_str[0] == 'y' or env_var_str[0] == 'T' or env_var_str[0] == 't')

fn make_upper(input_string: String) -> String:
    var result = input_string
    for i in range(len(input_string)):
        var ch = input_string[i]
        var cur_char_val = int(ord(ch))
        if (97 <= cur_char_val <= 122) or (224 <= cur_char_val <= 255):
            result[i] = chr(cur_char_val - 32)
    return result

fn same_string(s: String, t: String) -> Bool:
    return equali(s, t)

fn find_non_space(string: String) -> Int:
    for i in range(len(string)):
        if string[i] != ' ':
            return i
    return len(string)

fn process_number(string: String) -> Float64:
    var result_val = 0.0
    var s = string.strip()
    
    if not s or len(s) == 0:
        return result_val
    
    try:
        result_val = float(s)
        if not isfinite(result_val):
            return 0.0
        return result_val
    except:
        return 0.0

fn find_item_in_list(string: String, list_of_items: List[String], num_items: Optional[Int] = None) -> Int:
    var n = num_items.value_or(len(list_of_items))
    
    for count in range(n):
        if string == list_of_items[count]:
            return count + 1
    return 0

fn find_int_in_list(list_items: List[Int], item: Int) -> Int:
    for i in range(len(list_items)):
        if list_items[i] == item:
            return i
    return -1

fn find_item(string: String, list_of_items: List[String], num_items: Optional[Int] = None) -> Int:
    var n = num_items.value_or(len(list_of_items))
    
    var result = find_item_in_list(string, list_of_items, n)
    if result != 0:
        return result
    
    for count in range(n):
        if equali(string, list_of_items[count]):
            return count + 1
    return 0

fn set_design_object_name_and_pointer(state: SIMD[DType.float64, 1], name_to_be_set: String, ptr_to_be_set: Int,
                                      user_name: String, list_of_names: List[String], item_type: String,
                                      item_name: String) -> Tuple[String, Int, Bool]:
    var result_name = user_name
    var result_ptr = find_item_in_list(result_name, list_of_names)
    var error_found = False
    
    if result_ptr <= 0:
        error_found = True
        show_severe_error(state, "Object = " + item_type + " with the Name = " + item_name + " has an invalid Design Object Name = " + result_name + ".")
        show_continue_error(state, "  The Design Object Name was not found or was left blank.  This is not allowed.")
        show_continue_error(state, "  A valid Design Object Name must be provided for any " + item_type + " object.")
    
    return (result_name, result_ptr, error_found)

struct CaseInsensitiveHasher:
    fn hash(self, key: String) -> Int:
        return hash(make_upper(key))

struct CaseInsensitiveComparator:
    fn compare(self, a: String, b: String) -> Bool:
        return lessthani(a, b)

fn append_perf_log(state: SIMD[DType.float64, 1], col_header: String, col_value: String, final_column: Bool = False) -> None:
    if col_header == "RESET" and col_value == "RESET":
        return
    pass

fn convert_case_to_upper(input_string: String) -> String:
    var upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    var lower_case = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    
    var result = input_string
    for a in range(len(input_string)):
        var ch = input_string[a]
        var b = lower_case.find(ch)
        if b != -1:
            result[a] = upper_case[b]
    return result

fn convert_case_to_lower(input_string: String) -> String:
    var upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    var lower_case = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    
    var result = input_string
    for a in range(len(input_string)):
        var ch = input_string[a]
        var b = upper_case.find(ch)
        if b != -1:
            result[a] = lower_case[b]
    return result

fn emit_error_message(state: SIMD[DType.float64, 1], category: ErrorMessageCategory, msg: String, should_fatal: Bool) -> None:
    if not should_fatal:
        show_severe_error(state, msg)
    else:
        show_fatal_error(state, msg)

fn emit_warning_message(state: SIMD[DType.float64, 1], category: ErrorMessageCategory, msg: String, count_as_error: Bool = False) -> None:
    if count_as_error:
        show_warning_error(state, msg)
    else:
        show_warning_message(state, msg)

fn show_error_message(state: SIMD[DType.float64, 1], error_message: String) -> None:
    pass

fn show_fatal_error(state: SIMD[DType.float64, 1], error_message: String) -> None:
    show_error_message(state, " **  Fatal  ** " + error_message)
    raise Error(error_message)

fn show_severe_error(state: SIMD[DType.float64, 1], error_message: String) -> None:
    show_error_message(state, " ** Severe  ** " + error_message)

fn show_severe_message(state: SIMD[DType.float64, 1], error_message: String) -> None:
    show_error_message(state, " ** Severe  ** " + error_message)

fn show_continue_error(state: SIMD[DType.float64, 1], message: String) -> None:
    show_error_message(state, " **   ~~~   ** " + message)

fn show_continue_error_time_stamp(state: SIMD[DType.float64, 1], message: String) -> None:
    show_error_message(state, " **   ~~~   ** " + message)

fn show_message(state: SIMD[DType.float64, 1], message: String) -> None:
    if not message:
        show_error_message(state, " *************")
    else:
        show_error_message(state, " ************* " + message)

fn show_warning_error(state: SIMD[DType.float64, 1], error_message: String) -> None:
    show_error_message(state, " ** Warning ** " + error_message)

fn show_warning_message(state: SIMD[DType.float64, 1], error_message: String) -> None:
    show_error_message(state, " ** Warning ** " + error_message)

fn summarize_errors(state: SIMD[DType.float64, 1]) -> None:
    show_message(state, "")
    show_message(state, "===== Final Error Summary =====")
    show_message(state, "The following error categories occurred.  Consider correcting or noting.")
    show_message(state, "")

fn show_recurring_errors(state: SIMD[DType.float64, 1]) -> None:
    show_message(state, "")
    show_message(state, "===== Recurring Error Summary =====")
    show_message(state, "The following recurring error messages occurred.")
    show_message(state, "")

fn abort_energy_plus(state: SIMD[DType.float64, 1]) -> Int:
    show_message(state, "Fatal error -- final processing.  More error messages may appear.")
    show_message(state, "EnergyPlus Terminated--Fatal Error Detected.")
    return 1

fn close_misc_open_files(state: SIMD[DType.float64, 1]) -> None:
    pass

fn end_energy_plus(state: SIMD[DType.float64, 1]) -> Int:
    show_message(state, "EnergyPlus Completed Successfully.")
    return 0

fn show_severe_duplicate_name(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName + ", duplicate name.")

fn show_severe_empty_field(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, dep_field_name: String = "", dep_field_value: String = "") -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var suffix = "" if not dep_field_name else " when " + dep_field_name + " = " + dep_field_value
    show_continue_error(state, field_name + " cannot be empty" + suffix + ".")

fn show_severe_item_not_found(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", item not found.")

fn show_detailed_severe_item_not_found(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + field_name + " = " + field_value + ", item not found.")
    show_continue_error(state, field_name + " = " + field_value + ", item not found.")

fn show_severe_item_not_found_audit(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", item not found.")

fn show_severe_duplicate_assignment(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, prev_value: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", field previously assigned to " + prev_value + ".")

fn show_severe_invalid_key(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, msg: String = "") -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", invalid key.")
    if msg:
        show_continue_error(state, msg)

fn show_severe_invalid_bool(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", invalid boolean (\"Yes\"/\"No\").")

fn show_severe_custom(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, msg: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, msg)

fn show_severe_custom_field(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, msg: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", " + msg)

fn show_severe_custom_audit(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, msg: String) -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, msg)

fn show_severe_bad_min(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_min: Clusive, min_val: Float64, msg: String = "") -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op = ">=" if clu_min == Clusive.In else ">"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op + " " + str(min_val))
    if msg:
        show_continue_error(state, msg)

fn show_severe_bad_max(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_max: Clusive, max_val: Float64, msg: String = "") -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op + " " + str(max_val))
    if msg:
        show_continue_error(state, msg)

fn show_severe_bad_min_max(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_min: Clusive, min_val: Float64, clu_max: Clusive, max_val: Float64, msg: String = "") -> None:
    show_severe_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op_min = ">=" if clu_min == Clusive.In else ">"
    var op_max = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op_min + " " + str(min_val) + " and " + op_max + " " + str(max_val))
    if msg:
        show_continue_error(state, msg)

fn show_warning_item_not_found(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, default_value: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    if not default_value:
        show_continue_error(state, field_name + " = " + field_value + ", item not found.")
    else:
        show_continue_error(state, field_name + " = " + field_value + ", item not found, " + default_value + " will be used.")

fn show_warning_custom(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, msg: String) -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, msg)

fn show_warning_custom_field(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, msg: String) -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", " + msg)

fn show_warning_invalid_key(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, default_value: String, msg: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", invalid key, " + default_value + " will be used.")
    if msg:
        show_continue_error(state, msg)

fn show_warning_invalid_bool(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_value: String, default_value: String) -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " = " + field_value + ", invalid boolean (\"Yes\"/\"No\"), " + default_value + " will be used.")

fn show_warning_empty_field(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, default_value: String = "", dep_field_name: String = "", dep_field_value: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " is empty.")
    
    if dep_field_name:
        show_continue_error(state, "Cannot be empty when " + dep_field_name + " = " + dep_field_value)
    if default_value:
        show_continue_error(state, default_value + " will be used.")

fn show_warning_non_empty_field(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, dep_field_name: String = "", dep_field_value: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    show_continue_error(state, field_name + " is not empty.")
    if dep_field_name:
        show_continue_error(state, field_name + " is ignored when " + dep_field_name + " = " + dep_field_value + ".")

fn show_warning_bad_min(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_min: Clusive, min_val: Float64, msg: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op = ">=" if clu_min == Clusive.In else ">"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op + " " + str(min_val))
    if msg:
        show_continue_error(state, msg)

fn show_warning_bad_max(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_max: Clusive, max_val: Float64, msg: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op + " " + str(max_val))
    if msg:
        show_continue_error(state, msg)

fn show_warning_bad_min_max(state: SIMD[DType.float64, 1], eoh: ErrorObjectHeader, field_name: String, field_val: Float64, clu_min: Clusive, min_val: Float64, clu_max: Clusive, max_val: Float64, msg: String = "") -> None:
    show_warning_error(state, eoh.routineName + ": " + eoh.objectType + " = " + eoh.objectName)
    var op_min = ">=" if clu_min == Clusive.In else ">"
    var op_max = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, field_name + " = " + str(field_val) + ", but must be " + op_min + " " + str(min_val) + " and " + op_max + " " + str(max_val))
    if msg:
        show_continue_error(state, msg)

fn fclamp(v: Float64, min_val: Float64, max_val: Float64) -> Float64:
    if v < min_val:
        return min_val
    elif v > max_val:
        return max_val
    return v

fn get_enum_value(s_list: List[String], s: String) -> Int:
    for i in range(len(s_list)):
        if s_list[i] == s:
            return i
    return -1

fn get_yes_no_value(s: String) -> Int:
    return get_enum_value(List[String](YES_NO_NAMES_UC), s)

fn has(text: String, substring: String) -> Bool:
    return substring in text

fn equali(a: String, b: String) -> Bool:
    return a.upper() == b.upper()

fn lessthani(a: String, b: String) -> Bool:
    return a.upper() < b.upper()
