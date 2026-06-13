"""
Slab_InputProcessor - Mojo port of EnergyPlus InputProcessor module.
Processes IDD (Input Data Dictionary) and IDF (Input Data File) for EnergyPlus.
"""

from collections import InlineArray
from memory.unsafe import Pointer
import sys

alias MAX_OBJECT_NAME_LENGTH = 100
alias MAX_SECTION_NAME_LENGTH = 100
alias MAX_ALPHA_ARG_LENGTH = 100
alias MAX_INPUT_LINE_LENGTH = 500
alias DEF_AUTO_SIZE_VALUE = -99999.0
alias DEF_AUTO_CALCULATE_VALUE = -99999.0
alias R_TINY_VALUE = 1e-10


struct RangeCheckDef:
    """Range check definition for numeric fields."""
    var min_max_chk: Bool
    var field_number: Int32
    var field_name: String
    var min_max_string: InlineArray[String, 2]
    var min_max_value: InlineArray[Float64, 2]
    var which_min_max: InlineArray[Int32, 2]
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
        self.field_name = String()
        self.min_max_string = InlineArray[String, 2](fill=String())
        self.min_max_value = InlineArray[Float64, 2](fill=0.0)
        self.which_min_max = InlineArray[Int32, 2](fill=0)
        self.default_chk = False
        self.default = 0.0
        self.def_auto_size = False
        self.auto_sizable = False
        self.auto_size_value = 0.0
        self.def_auto_calculate = False
        self.auto_calculatable = False
        self.auto_calculate_value = 0.0


struct ObjectsDefinition:
    """Object definition structure."""
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
    var alpha_or_numeric: DynamicVector[Bool]
    var req_field: DynamicVector[Bool]
    var alph_retain_case: DynamicVector[Bool]
    var alph_field_chks: DynamicVector[String]
    var alph_field_defs: DynamicVector[String]
    var num_range_chks: DynamicVector[RangeCheckDef]
    
    fn __init__(inout self):
        self.name = String()
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
        self.alpha_or_numeric = DynamicVector[Bool]()
        self.req_field = DynamicVector[Bool]()
        self.alph_retain_case = DynamicVector[Bool]()
        self.alph_field_chks = DynamicVector[String]()
        self.alph_field_defs = DynamicVector[String]()
        self.num_range_chks = DynamicVector[RangeCheckDef]()


struct SectionsDefinition:
    """Section definition structure."""
    var name: String
    var num_found: Int32
    
    fn __init__(inout self):
        self.name = String()
        self.num_found = 0


struct FileSectionsDefinition:
    """File sections definition structure."""
    var name: String
    var first_record: Int32
    var first_line_no: Int32
    var last_record: Int32
    
    fn __init__(inout self):
        self.name = String()
        self.first_record = 0
        self.first_line_no = 0
        self.last_record = 0


struct LineDefinition:
    """Line/record definition structure."""
    var name: String
    var num_alphas: Int32
    var num_numbers: Int32
    var object_def_ptr: Int32
    var alphas: DynamicVector[String]
    var alph_blank: DynamicVector[Bool]
    var numbers: DynamicVector[Float64]
    var num_blank: DynamicVector[Bool]
    
    fn __init__(inout self):
        self.name = String()
        self.num_alphas = 0
        self.num_numbers = 0
        self.object_def_ptr = 0
        self.alphas = DynamicVector[String]()
        self.alph_blank = DynamicVector[Bool]()
        self.numbers = DynamicVector[Float64]()
        self.num_blank = DynamicVector[Bool]()


struct InputProcessorState:
    """Module state container for InputProcessor."""
    # Parameters
    var object_def_alloc_inc: Int32
    var section_def_alloc_inc: Int32
    var sections_idf_alloc_inc: Int32
    var objects_idf_alloc_inc: Int32
    var max_object_name_length: Int32
    var max_section_name_length: Int32
    var max_alpha_arg_length: Int32
    var max_input_line_length: Int32
    var blank: String
    var alpha_num: String
    var def_auto_size_value: Float64
    var def_auto_calculate_value: Float64
    var r_tiny_value: Float64
    
    # Integer Variables
    var num_object_defs: Int32
    var num_section_defs: Int32
    var max_object_defs: Int32
    var max_section_defs: Int32
    var idd_file: Int32
    var idf_file: Int32
    var num_lines: Int32
    var max_idf_records: Int32
    var num_idf_records: Int32
    var max_idf_sections: Int32
    var num_idf_sections: Int32
    var echo_input_file: Int32
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
    
    # Character Variables
    var input_line: String
    var current_field_name: String
    var replacement_name: String
    
    # Logical Variables
    var processing_idd: Bool
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
    
    # Arrays
    var listof_sections: DynamicVector[String]
    var listof_objects: DynamicVector[String]
    var object_start_record: DynamicVector[Int32]
    var line_buf_len: DynamicVector[Int32]
    var object_def: DynamicVector[ObjectsDefinition]
    var section_def: DynamicVector[SectionsDefinition]
    var sections_on_file: DynamicVector[FileSectionsDefinition]
    var idf_records: DynamicVector[LineDefinition]
    var line_item: LineDefinition
    
    fn __init__(inout self):
        self.object_def_alloc_inc = 100
        self.section_def_alloc_inc = 20
        self.sections_idf_alloc_inc = 20
        self.objects_idf_alloc_inc = 500
        self.max_object_name_length = 100
        self.max_section_name_length = 100
        self.max_alpha_arg_length = 100
        self.max_input_line_length = 500
        self.blank = " "
        self.alpha_num = "ANan"
        self.def_auto_size_value = -99999.0
        self.def_auto_calculate_value = -99999.0
        self.r_tiny_value = 1e-10
        
        self.num_object_defs = 0
        self.num_section_defs = 0
        self.max_object_defs = 0
        self.max_section_defs = 0
        self.idd_file = 0
        self.idf_file = 0
        self.num_lines = 0
        self.max_idf_records = 0
        self.num_idf_records = 0
        self.max_idf_sections = 0
        self.num_idf_sections = 0
        self.echo_input_file = 0
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
        
        self.input_line = String()
        self.current_field_name = String()
        self.replacement_name = String()
        
        self.processing_idd = False
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
        
        self.listof_sections = DynamicVector[String]()
        self.listof_objects = DynamicVector[String]()
        self.object_start_record = DynamicVector[Int32]()
        self.line_buf_len = DynamicVector[Int32]()
        self.object_def = DynamicVector[ObjectsDefinition]()
        self.section_def = DynamicVector[SectionsDefinition]()
        self.sections_on_file = DynamicVector[FileSectionsDefinition]()
        self.idf_records = DynamicVector[LineDefinition]()
        self.line_item = LineDefinition()


@always_inline
fn make_upper_case(input_string: String) -> String:
    """Convert string to uppercase."""
    return input_string.upper()


@always_inline
fn same_string(test_string1: String, test_string2: String) -> Bool:
    """Check if two strings are equal (case-insensitive)."""
    return test_string1.upper() == test_string2.upper()


fn find_item_in_list(string: String, list_of_items: DynamicVector[String], num_items: Int32) -> Int32:
    """Find string in list. Returns 1-based index or 0 if not found."""
    for i in range(num_items):
        if string == list_of_items[i]:
            return i + 1
    return 0


fn find_item(string: String, list_of_items: DynamicVector[String], num_items: Int32) -> Int32:
    """Find string in list (case-insensitive). Returns 1-based index or 0."""
    var result = find_item_in_list(string, list_of_items, num_items)
    if result != 0:
        return result
    
    var string_uc = make_upper_case(string)
    for i in range(num_items):
        if string_uc == make_upper_case(list_of_items[i]):
            return i + 1
    return 0


fn process_number(string: String) -> Tuple[Float64, Bool]:
    """Process a string as a number. Returns (value, error_flag)."""
    var valid_numerics = "0123456789.+-EeDd\t"
    var p_string = string.strip()
    if p_string.is_empty():
        return 0.0, False
    
    for ch in string:
        if ch not in valid_numerics:
            return 0.0, True
    
    try:
        var value = Float64(p_string)
        return value, False
    except:
        return 0.0, True


fn ip_trim_sig_digits(int_value: Int32) -> String:
    """Convert integer to string."""
    return str(int_value).strip()


fn process_input(
    inout state: InputProcessorState,
    idd_filename: Optional[String] = None,
    idf_filename: Optional[String] = None,
    default_idd: String = "Energy+.idd",
    default_idf: String = "in.idf"
) -> None:
    """Main entry point for processing input."""
    var full_name = idd_filename if idd_filename else default_idd
    
    state.idd_file = 0
    state.num_lines = 0
    
    # Initialize state
    state.max_section_defs = state.section_def_alloc_inc
    state.max_object_defs = state.object_def_alloc_inc
    
    for _ in range(state.max_section_defs):
        state.section_def.push_back(SectionsDefinition())
    
    for _ in range(state.max_object_defs):
        state.object_def.push_back(ObjectsDefinition())
    
    state.num_object_defs = 0
    state.num_section_defs = 0
    
    # Process IDD file
    state.processing_idd = True
    # process_data_dic_file(state)
    state.processing_idd = False
    
    state.num_idf_records = 0
    state.max_idf_records = state.objects_idf_alloc_inc
    state.num_idf_sections = 0
    state.max_idf_sections = state.sections_idf_alloc_inc
    
    for _ in range(state.max_idf_sections):
        state.sections_on_file.push_back(FileSectionsDefinition())
    
    for _ in range(state.max_idf_records):
        state.idf_records.push_back(LineDefinition())
    
    # Initialize LineItem
    var max_num = state.max_numeric_args_found
    var max_alpha = state.max_alpha_args_found
    
    for _ in range(max_num):
        state.line_item.numbers.push_back(0.0)
        state.line_item.num_blank.push_back(False)
    
    for _ in range(max_alpha):
        state.line_item.alphas.push_back(String())
        state.line_item.alph_blank.push_back(False)


fn turn_on_report_range_check_errors(inout state: InputProcessorState) -> None:
    """Turn on range check error reporting."""
    state.report_range_check_errors = True


fn turn_off_report_range_check_errors(inout state: InputProcessorState) -> None:
    """Turn off range check error reporting."""
    state.report_range_check_errors = False


fn get_num_range_check_errors_found(state: InputProcessorState) -> Int32:
    """Get number of range check errors."""
    return state.num_out_of_range_errors_found


fn get_num_objects_in_idd(state: InputProcessorState) -> Int32:
    """Get number of objects in IDD."""
    return state.num_object_defs


fn get_num_sections_found(state: InputProcessorState, section_word: String) -> Int32:
    """Get number of sections found."""
    var found = find_item_in_list(
        make_upper_case(section_word),
        get_section_names(state),
        state.num_section_defs
    )
    if found == 0:
        return 0
    return state.section_def[found - 1].num_found


fn get_num_sections_in_input(state: InputProcessorState) -> Int32:
    """Get number of sections in input."""
    return state.num_idf_sections


@always_inline
fn get_section_names(state: InputProcessorState) -> DynamicVector[String]:
    """Helper to extract section names."""
    var names = DynamicVector[String]()
    for i in range(state.num_section_defs):
        names.push_back(state.section_def[i].name)
    return names


@always_inline
fn get_object_names(state: InputProcessorState) -> DynamicVector[String]:
    """Helper to extract object names."""
    var names = DynamicVector[String]()
    for i in range(state.num_object_defs):
        names.push_back(state.object_def[i].name)
    return names


fn get_num_objects_found(state: InputProcessorState, object_word: String) -> Int32:
    """Get number of objects found."""
    var found = find_item_in_list(
        make_upper_case(object_word),
        state.listof_objects,
        state.num_object_defs
    )
    if found != 0:
        return state.object_def[found - 1].num_found
    return 0


fn get_list_of_objects_in_idd(state: InputProcessorState) -> DynamicVector[String]:
    """Get list of objects in IDD."""
    return get_object_names(state)


fn get_record_locations(state: InputProcessorState, which: Int32) -> Tuple[Int32, Int32]:
    """Get record locations."""
    var idx = which - 1
    return (state.sections_on_file[idx].first_record, state.sections_on_file[idx].last_record)


fn get_object_item_num(state: InputProcessorState, obj_type: String, obj_name: String) -> Int32:
    """Get occurrence number of an object."""
    var item_num: Int32 = 0
    var uc_obj_type = make_upper_case(obj_type)
    
    var found = find_item_in_list(uc_obj_type, state.listof_objects, state.num_object_defs)
    
    if found == 0:
        return -1
    
    var start_record = state.object_start_record[found - 1]
    if start_record == 0:
        return 0
    
    for obj_num in range(start_record - 1, state.num_idf_records):
        if state.idf_records[obj_num].name != uc_obj_type:
            continue
        item_num += 1
        if state.idf_records[obj_num].num_alphas > 0:
            if state.idf_records[obj_num].alphas[0] == obj_name:
                return item_num
    
    return 0


fn get_list_of_sections_in_input(state: InputProcessorState) -> DynamicVector[String]:
    """Get list of sections in input."""
    var sections = DynamicVector[String]()
    for i in range(state.num_idf_sections):
        sections.push_back(state.sections_on_file[i].name)
    return sections


fn verify_name(
    state: InputProcessorState,
    name_to_verify: String,
    names_list: DynamicVector[String],
    num_of_names: Int32,
    string_to_display: String
) -> Tuple[Bool, Bool]:
    """Verify name. Returns (error_found, is_blank)."""
    var error_found: Bool = False
    var is_blank: Bool = False
    
    if num_of_names > 0:
        var found = find_item_in_list(name_to_verify, names_list, num_of_names)
        if found != 0:
            error_found = True
    
    if name_to_verify.strip().is_empty():
        error_found = True
        is_blank = True
    
    return error_found, is_blank


fn range_check(
    inout state: InputProcessorState,
    errors_found: Bool,
    what_field_string: String,
    what_object_string: String,
    error_level: String,
    lower_bound_string: Optional[String] = None,
    lower_bound_condition: Optional[Bool] = None,
    upper_bound_string: Optional[String] = None,
    upper_bound_condition: Optional[Bool] = None,
    value_string: Optional[String] = None
) -> Bool:
    """Range check subroutine."""
    var error: Bool = False
    
    if upper_bound_condition and not upper_bound_condition.value():
        error = True
    if lower_bound_condition and not lower_bound_condition.value():
        error = True
    
    if error:
        var error_string = error_level.upper()
        var message = String()
        message += "Out of range value field=" + what_field_string + ","
        if value_string:
            message += " Value=[" + value_string.value() + "]"
        message += " range={"
        if lower_bound_string:
            message += lower_bound_string.value()
        if lower_bound_string and upper_bound_string:
            message += " and " + upper_bound_string.value()
        elif upper_bound_string:
            message += upper_bound_string.value()
        message += "}, for item=" + what_object_string
    
    return errors_found
