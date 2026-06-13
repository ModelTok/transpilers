from python import Python
from collections import Dict, List
from memory import UnsafePointer
from sys import stdout

alias MAX_NAME_LENGTH = 128
alias MAX_INPUT_LINE_LENGTH = 500
alias OBJECT_DEF_ALLOC_INC = 100
alias SECTION_DEF_ALLOC_INC = 20
alias SECTIONS_IDF_ALLOC_INC = 20
alias OBJECTS_IDF_ALLOC_INC = 500
alias MAX_OBJECT_NAME_LENGTH = MAX_NAME_LENGTH
alias MAX_SECTION_NAME_LENGTH = MAX_NAME_LENGTH
alias MAX_ALPHA_ARG_LENGTH = MAX_NAME_LENGTH
alias BLANK = " "
alias ALPHA_NUM = "ANan"
alias FMT_A = "(A)"
alias DEF_AUTO_SIZE_VALUE = -99999.0
alias DEF_AUTO_CALCULATE_VALUE = -99999.0
alias R_TINY_VALUE = 1e-12

struct RangeCheckDef:
    var min_max_chk: Bool
    var field_number: Int32
    var field_name: String
    var min_max_string: SIMD[DType.float64, 2]
    var min_max_value: SIMD[DType.float64, 2]
    var which_min_max: SIMD[DType.int32, 2]
    var default_chk: Bool
    var default: Float64
    var def_auto_size: Bool
    var auto_sizable: Bool
    var auto_size_value: Float64
    var def_auto_calculate: Bool
    var auto_calculatable: Bool
    var auto_calculate_value: Float64
    
    fn __init__(inout self):
        self.min_max_chk = False
        self.field_number = 0
        self.field_name = ""
        self.min_max_string = SIMD[DType.float64, 2](0.0, 0.0)
        self.min_max_value = SIMD[DType.float64, 2](0.0, 0.0)
        self.which_min_max = SIMD[DType.int32, 2](0, 0)
        self.default_chk = False
        self.default = 0.0
        self.def_auto_size = False
        self.auto_sizable = False
        self.auto_size_value = 0.0
        self.def_auto_calculate = False
        self.auto_calculatable = False
        self.auto_calculate_value = 0.0

struct ObjectsDefinition:
    var name: String
    var num_params: Int32
    var num_alpha: Int32
    var num_numeric: Int32
    var min_num_fields: Int32
    var name_alpha1: Bool
    var unique_object: Bool
    var required_object: Bool
    var extensible_object: Bool
    var extensible_num: Int32
    var last_extend_alpha: Int32
    var last_extend_num: Int32
    var obs_ptr: Int32
    var num_found: Int32
    
    fn __init__(inout self):
        self.name = ""
        self.num_params = 0
        self.num_alpha = 0
        self.num_numeric = 0
        self.min_num_fields = 0
        self.name_alpha1 = False
        self.unique_object = False
        self.required_object = False
        self.extensible_object = False
        self.extensible_num = 0
        self.last_extend_alpha = 0
        self.last_extend_num = 0
        self.obs_ptr = 0
        self.num_found = 0

struct SectionsDefinition:
    var name: String
    var num_found: Int32
    
    fn __init__(inout self):
        self.name = ""
        self.num_found = 0

struct FileSectionsDefinition:
    var name: String
    var first_record: Int32
    var first_line_no: Int32
    var last_record: Int32
    
    fn __init__(inout self):
        self.name = ""
        self.first_record = 0
        self.first_line_no = 0
        self.last_record = 0

struct LineDefinition:
    var name: String
    var num_alphas: Int32
    var num_numbers: Int32
    var object_def_ptr: Int32
    
    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.object_def_ptr = 0

struct InputProcessorState:
    var num_object_defs: Int32
    var num_section_defs: Int32
    var max_object_defs: Int32
    var max_section_defs: Int32
    var num_lines: Int32
    var max_idf_records: Int32
    var num_idf_records: Int32
    var max_idf_sections: Int32
    var num_idf_sections: Int32
    var input_line_length: Int32
    var max_alpha_args_found: Int32
    var max_numeric_args_found: Int32
    var max_alpha_idf_args_found: Int32
    var max_numeric_idf_args_found: Int32
    var max_alpha_idf_def_args_found: Int32
    var max_numeric_idf_def_args_found: Int32
    var num_out_of_range_errors_found: Int32
    var num_blank_req_field_found: Int32
    var num_misc_errors_found: Int32
    var minimum_number_of_fields: Int32
    var num_obsolete_objects: Int32
    var total_audit_errors: Int32
    var num_secret_objects: Int32
    var processing_idd: Bool
    var input_line: String
    var current_field_name: String
    var replacement_name: String
    var overall_error_flag: Bool
    var echo_input_line: Bool
    var report_range_check_errors: Bool
    var field_set: Bool
    var required_field: Bool
    var retain_case_flag: Bool
    var obsolete_object: Bool
    var required_object: Bool
    var unique_object: Bool
    var extensible_object: Bool
    var extensible_num_fields: Int32
    var sorted_idd: Bool
    
    fn __init__(inout self):
        self.num_object_defs = 0
        self.num_section_defs = 0
        self.max_object_defs = 0
        self.max_section_defs = 0
        self.num_lines = 0
        self.max_idf_records = 0
        self.num_idf_records = 0
        self.max_idf_sections = 0
        self.num_idf_sections = 0
        self.input_line_length = 0
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_alpha_idf_args_found = 0
        self.max_numeric_idf_args_found = 0
        self.max_alpha_idf_def_args_found = 0
        self.max_numeric_idf_def_args_found = 0
        self.num_out_of_range_errors_found = 0
        self.num_blank_req_field_found = 0
        self.num_misc_errors_found = 0
        self.minimum_number_of_fields = 0
        self.num_obsolete_objects = 0
        self.total_audit_errors = 0
        self.num_secret_objects = 0
        self.processing_idd = False
        self.input_line = ""
        self.current_field_name = ""
        self.replacement_name = ""
        self.overall_error_flag = False
        self.echo_input_line = True
        self.report_range_check_errors = True
        self.field_set = False
        self.required_field = False
        self.retain_case_flag = False
        self.obsolete_object = False
        self.required_object = False
        self.unique_object = False
        self.extensible_object = False
        self.extensible_num_fields = 0
        self.sorted_idd = False

fn make_upper_case(input_string: String) -> String:
    return input_string.upper()

fn find_item_in_list(string: String, list_of_items: List[String], num_items: Int32) -> Int32:
    for count in range(num_items):
        if string == list_of_items[count]:
            return count + 1
    return 0

fn find_item(string: String, list_of_items: List[String], num_items: Int32) -> Int32:
    var result = find_item_in_list(string, list_of_items, num_items)
    if result != 0:
        return result
    var string_uc = make_upper_case(string)
    for count in range(num_items):
        if string_uc == make_upper_case(list_of_items[count]):
            return count + 1
    return 0

fn same_string(test_string1: String, test_string2: String) -> Bool:
    if len(test_string1.strip()) != len(test_string2.strip()):
        return False
    if test_string1 == test_string2:
        return True
    return make_upper_case(test_string1) == make_upper_case(test_string2)

fn process_number(string: String) -> Tuple[Float64, Bool]:
    let valid_numerics = "0123456789.+-EeDd\t"
    var pstring = string.strip()
    var error_flag = False
    if len(pstring) == 0:
        return Tuple(0.0, True)
    var has_valid = True
    for ch in pstring:
        if ch.isdigit() or ch in "+-eEdD. \t":
            continue
        has_valid = False
        break
    if has_valid:
        try:
            return Tuple(atof(pstring), False)
        except:
            return Tuple(0.0, True)
    return Tuple(0.0, True)

fn ip_trim_sig_digits(integer_value: Int32) -> String:
    return str(integer_value)

fn process_min_max_def_line(uc_input_line: String, inout state: InputProcessorState) -> Tuple[Int32, String, Float64, String, Int32]:
    var which_min_max: Int32 = 0
    var min_max_string: String = ""
    var value: Float64 = 0.0
    var default_string: String = ""
    var err_level: Int32 = 0
    
    if len(uc_input_line) < 4:
        return Tuple(which_min_max, min_max_string, value, default_string, err_level)
    
    var pos = uc_input_line.find(" ")
    if pos == -1:
        pos = len(uc_input_line)
    
    var prefix = uc_input_line[:4].upper()
    
    if prefix == "\\MIN":
        which_min_max = 1
        if uc_input_line.find(">") != -1:
            pos = uc_input_line.find(">") + 1
            which_min_max = 2
        min_max_string = ">=" if which_min_max == 1 else ">"
    elif prefix == "\\MAX":
        which_min_max = 3
        if uc_input_line.find("<") != -1:
            pos = uc_input_line.find("<") + 1
            which_min_max = 4
        min_max_string = "<=" if which_min_max == 3 else "<"
    elif prefix == "\\DEF":
        which_min_max = 5
        min_max_string = ""
    elif prefix == "\\AUT":
        which_min_max = 6
        min_max_string = ""
    else:
        which_min_max = 0
        min_max_string = ""
        value = -999999.0
    
    return Tuple(which_min_max, min_max_string, value, default_string, err_level)

fn get_num_sections_found(inout state: InputProcessorState, section_word: String) -> Int32:
    var found = find_item_in_list(make_upper_case(section_word), List[String](), state.num_section_defs)
    if found == 0:
        return 0
    return 0

fn get_num_sections_in_input(inout state: InputProcessorState) -> Int32:
    return state.num_idf_sections

fn get_num_objects_found(inout state: InputProcessorState, object_word: String) -> Int32:
    var found = find_item_in_list(make_upper_case(object_word), List[String](), state.num_object_defs)
    if found == 0:
        return 0
    return 0

fn get_num_range_check_errors_found(inout state: InputProcessorState) -> Int32:
    return state.num_out_of_range_errors_found

fn get_num_objects_in_idd(inout state: InputProcessorState) -> Int32:
    return state.num_object_defs

fn turn_on_report_range_check_errors(inout state: InputProcessorState):
    state.report_range_check_errors = True

fn turn_off_report_range_check_errors(inout state: InputProcessorState):
    state.report_range_check_errors = False

fn verify_name(name_to_verify: String, names_list: List[String], num_of_names: Int32, string_to_display: String) -> Tuple[Bool, Bool]:
    var error_found = False
    var is_blank = False
    
    if num_of_names > 0:
        var found = find_item_in_list(name_to_verify, names_list, num_of_names)
        if found != 0:
            error_found = True
    
    if name_to_verify.strip() == "":
        error_found = True
        is_blank = True
    
    return Tuple(error_found, is_blank)

fn range_check(inout errors_found: Bool, what_field_string: String, what_object_string: String, error_level: String,
                lower_bound_string: StringRef = "", lower_bound_condition: Bool = True,
                upper_bound_string: StringRef = "", upper_bound_condition: Bool = True,
                value_string: StringRef = "") -> Bool:
    var error = False
    if not upper_bound_condition:
        error = True
    if not lower_bound_condition:
        error = True
    
    if error:
        errors_found = True
    
    return errors_found

fn dump_current_line_buffer(start_line: Int32, num_conx_lines: Int32, line_buf: String, line_buf_len: List[Int32]):
    pass

fn show_audit_error_message(severity: String, error_message: String):
    pass
