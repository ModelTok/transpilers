from dataclasses import dataclass, field
from typing import List, Optional, Dict, Tuple
import math
import sys

# EXTERNAL DEPS (to wire in glue):
# - r64 (from DataPrecisionGlobals): float type
# - MaxNameLength (from DataGlobals): int
# - rTinyValue (from DataGlobals): float
# - FullName, DefaultIDD, DefaultIDF (from DataStringGlobals): str
# - EPObjects (from BasementSimData): logging/error object
# - GetNewUnitNumber(): int → external
# - ShowFatalError(msg, obj): external
# - ShowSevereError(msg, file=None, obj=None): external
# - ShowWarningError(msg, file=None, obj=None): external
# - ShowContinueError(msg, file=None, obj=None): external
# - ShowMessage(msg): external
# - ShowAuditErrorMessage(sev, msg): external (defined herein)
# - ConvertCasetoUPPER(in_str, out_str): external
# - FindNonSpace(s): int → external (find first non-space position)

MAX_NAME_LENGTH = 128
MAX_INPUT_LINE_LENGTH = 500
OBJECT_DEF_ALLOC_INC = 100
SECTION_DEF_ALLOC_INC = 20
SECTIONS_IDF_ALLOC_INC = 20
OBJECTS_IDF_ALLOC_INC = 500
MAX_OBJECT_NAME_LENGTH = MAX_NAME_LENGTH
MAX_SECTION_NAME_LENGTH = MAX_NAME_LENGTH
MAX_ALPHA_ARG_LENGTH = MAX_NAME_LENGTH
BLANK = ' '
ALPHA_NUM = 'ANan'
FMT_A = '(A)'
DEF_AUTO_SIZE_VALUE = -99999.0
DEF_AUTO_CALCULATE_VALUE = -99999.0
R_TINY_VALUE = 1e-12

@dataclass
class RangeCheckDef:
    min_max_chk: bool = False
    field_number: int = 0
    field_name: str = field(default_factory=lambda: ' ' * (MAX_NAME_LENGTH + 40))
    min_max_string: List[str] = field(default_factory=lambda: [' ' * 20, ' ' * 20])
    min_max_value: List[float] = field(default_factory=lambda: [0.0, 0.0])
    which_min_max: List[int] = field(default_factory=lambda: [0, 0])
    default_chk: bool = False
    default: float = 0.0
    def_auto_size: bool = False
    auto_sizable: bool = False
    auto_size_value: float = 0.0
    def_auto_calculate: bool = False
    auto_calculatable: bool = False
    auto_calculate_value: float = 0.0

@dataclass
class ObjectsDefinition:
    name: str = BLANK
    num_params: int = 0
    num_alpha: int = 0
    num_numeric: int = 0
    min_num_fields: int = 0
    name_alpha1: bool = False
    unique_object: bool = False
    required_object: bool = False
    extensible_object: bool = False
    extensible_num: int = 0
    last_extend_alpha: int = 0
    last_extend_num: int = 0
    obs_ptr: int = 0
    alpha_or_numeric: List[bool] = field(default_factory=list)
    req_field: List[bool] = field(default_factory=list)
    alph_retain_case: List[bool] = field(default_factory=list)
    alph_field_chks: List[str] = field(default_factory=list)
    alph_field_defs: List[str] = field(default_factory=list)
    num_range_chks: List[RangeCheckDef] = field(default_factory=list)
    num_found: int = 0

@dataclass
class SectionsDefinition:
    name: str = BLANK
    num_found: int = 0

@dataclass
class FileSectionsDefinition:
    name: str = BLANK
    first_record: int = 0
    first_line_no: int = 0
    last_record: int = 0

@dataclass
class LineDefinition:
    name: str = BLANK
    num_alphas: int = 0
    num_numbers: int = 0
    object_def_ptr: int = 0
    alphas: List[str] = field(default_factory=list)
    alph_blank: List[bool] = field(default_factory=list)
    numbers: List[float] = field(default_factory=list)
    num_blank: List[bool] = field(default_factory=list)

class InputProcessorState:
    def __init__(self):
        self.num_object_defs = 0
        self.num_section_defs = 0
        self.max_object_defs = 0
        self.max_section_defs = 0
        self.idd_file = None
        self.idf_file = None
        self.num_lines = 0
        self.max_idf_records = 0
        self.num_idf_records = 0
        self.max_idf_sections = 0
        self.num_idf_sections = 0
        self.echo_input_file = None
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
        self.input_line = BLANK
        self.listof_sections: List[str] = []
        self.listof_objects: List[str] = []
        self.current_field_name = BLANK
        self.replacement_name = BLANK
        self.object_start_record: List[int] = []
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
        self.line_buf_len: List[int] = []
        self.sorted_idd = False
        self.object_def: List[ObjectsDefinition] = []
        self.section_def: List[SectionsDefinition] = []
        self.sections_on_file: List[FileSectionsDefinition] = []
        self.line_item = LineDefinition()
        self.idf_records: List[LineDefinition] = []

def make_upper_case(input_string: str) -> str:
    return input_string.upper()

def find_item_in_list(string: str, list_of_items: List[str], num_items: int) -> int:
    for count in range(num_items):
        if string == list_of_items[count]:
            return count + 1
    return 0

def find_item(string: str, list_of_items: List[str], num_items: int) -> int:
    result = find_item_in_list(string, list_of_items, num_items)
    if result != 0:
        return result
    string_uc = make_upper_case(string)
    for count in range(num_items):
        if string_uc == make_upper_case(list_of_items[count]):
            return count + 1
    return 0

def same_string(test_string1: str, test_string2: str) -> bool:
    if len(test_string1.strip()) != len(test_string2.strip()):
        return False
    if test_string1 == test_string2:
        return True
    return make_upper_case(test_string1) == make_upper_case(test_string2)

def process_number(string: str) -> Tuple[float, bool]:
    valid_numerics = '0123456789.+-EeDd\t'
    pstring = string.strip()
    error_flag = False
    if not pstring:
        return 0.0, True
    for ch in pstring:
        if ch not in valid_numerics:
            error_flag = True
            break
    if not error_flag:
        try:
            return float(pstring), False
        except ValueError:
            return 0.0, True
    return 0.0, True

def ip_trim_sig_digits(integer_value: int) -> str:
    return str(integer_value)

def process_min_max_def_line(uc_input_line: str, state) -> Tuple[int, str, float, str, int]:
    which_min_max = 0
    min_max_string = BLANK
    value = 0.0
    default_string = BLANK
    err_level = 0
    
    if not uc_input_line or len(uc_input_line) < 4:
        return which_min_max, min_max_string, value, default_string, err_level
    
    pos = uc_input_line.find(' ')
    if pos == -1:
        pos = len(uc_input_line)
    
    prefix = uc_input_line[:4].upper()
    
    if prefix == '\\MIN':
        which_min_max = 1
        if '>' in uc_input_line:
            pos = uc_input_line.find('>') + 1
            which_min_max = 2
        min_max_string = '>=' if which_min_max == 1 else '>'
    elif prefix == '\\MAX':
        which_min_max = 3
        if '<' in uc_input_line:
            pos = uc_input_line.find('<') + 1
            which_min_max = 4
        min_max_string = '<=' if which_min_max == 3 else '<'
    elif prefix == '\\DEF':
        which_min_max = 5
        min_max_string = BLANK
    elif prefix == '\\AUT':
        which_min_max = 6
        min_max_string = BLANK
    else:
        which_min_max = 0
        min_max_string = BLANK
        value = -999999.0
    
    if which_min_max != 0:
        nspace = 0
        for i in range(pos, len(uc_input_line)):
            if uc_input_line[i] != ' ':
                nspace = i - pos
                break
        
        if nspace == 0:
            if which_min_max != 6:
                err_level = 2
            else:
                value = DEF_AUTO_SIZE_VALUE if uc_input_line[:6].upper() == '\\AUTOS' else DEF_AUTO_CALCULATE_VALUE
        else:
            pos = pos + nspace
            nspace = len(uc_input_line[pos:].split()[0]) if uc_input_line[pos:].split() else 0
            if nspace > 0:
                min_max_string = min_max_string + uc_input_line[pos:pos+nspace]
                value, err_flag = process_number(uc_input_line[pos:pos+nspace])
                if err_flag:
                    err_level = 1
                nspace_excl = uc_input_line[pos:].find('!')
                if nspace_excl >= 0:
                    default_string = uc_input_line[pos:pos+nspace_excl]
                else:
                    default_string = uc_input_line[pos:]
                default_string = default_string.strip()
                if not default_string:
                    if which_min_max == 6:
                        value = DEF_AUTO_SIZE_VALUE if uc_input_line[:6].upper() == '\\AUTOS' else DEF_AUTO_CALCULATE_VALUE
                    else:
                        err_level = 2
    
    return which_min_max, min_max_string, value, default_string, err_level

def read_input_line(state, unit_file, echo_input_file=None) -> Tuple[int, bool, int, bool]:
    cur_pos = 1
    blank_line = False
    input_line_length = 0
    end_of_file = False
    
    try:
        line = unit_file.readline()
        if not line:
            end_of_file = True
            return cur_pos, blank_line, input_line_length, end_of_file
        
        if line.endswith('\r\n'):
            line = line[:-2]
        elif line.endswith('\n'):
            line = line[:-1]
        elif line.endswith('\r'):
            line = line[:-1]
        
        if len(line) > MAX_INPUT_LINE_LENGTH:
            line = line[:MAX_INPUT_LINE_LENGTH]
        
        line = line.replace('\t', ' ')
        
        blank_line = not line.strip()
        cur_pos = 0
        input_line_length = len(line.rstrip())
        state.input_line = line
        
        if state.echo_input_line and echo_input_file:
            state.num_lines += 1
            if state.num_lines < 100000:
                echo_input_file.write(f'{state.num_lines:6d} {line}\n')
            else:
                echo_input_file.write(f'{state.num_lines} {line}\n')
        
        state.echo_input_line = True
        
    except Exception:
        end_of_file = True
    
    return cur_pos, blank_line, input_line_length, end_of_file

def process_input(state, idd_file_name: Optional[str] = None, idf_file_name: Optional[str] = None, 
                  echo_input_file=None, ep_objects=None, external_deps=None):
    pass

def get_num_sections_found(state, section_word: str) -> int:
    found = find_item_in_list(make_upper_case(section_word), state.listof_sections, state.num_section_defs)
    if found == 0:
        return 0
    return state.section_def[found - 1].num_found

def get_num_sections_in_input(state) -> int:
    return state.num_idf_sections

def get_list_of_sections_in_input(state) -> List[str]:
    max_allowed_out = min(state.num_idf_sections, len(state.sections_on_file))
    return [state.sections_on_file[i].name for i in range(max_allowed_out)]

def get_num_objects_found(state, object_word: str) -> int:
    found = find_item_in_list(make_upper_case(object_word), state.listof_objects, state.num_object_defs)
    if found == 0:
        return 0
    return state.object_def[found - 1].num_found

def get_record_locations(state, which: int) -> Tuple[int, int]:
    if 0 < which <= state.num_idf_sections:
        return state.sections_on_file[which - 1].first_record, state.sections_on_file[which - 1].last_record
    return 0, 0

def get_object_item_num(state, obj_type: str, obj_name: str) -> int:
    item_num = 0
    item_found = False
    uc_obj_type = make_upper_case(obj_type)
    found = find_item_in_list(uc_obj_type, state.listof_objects, state.num_object_defs)
    
    if found != 0:
        num_obj_of_type = state.object_def[found - 1].num_found
        start_record = state.object_start_record[found - 1] if found - 1 < len(state.object_start_record) else 0
        
        if start_record > 0:
            for obj_num in range(start_record - 1, state.num_idf_records):
                if state.idf_records[obj_num].name != uc_obj_type:
                    continue
                item_num += 1
                if item_num > num_obj_of_type:
                    break
                if state.idf_records[obj_num].alphas and len(state.idf_records[obj_num].alphas) > 0:
                    if state.idf_records[obj_num].alphas[0] == obj_name:
                        item_found = True
                        break
        
        if not item_found:
            item_num = 0
    else:
        item_num = -1
    
    return item_num

def tell_me_how_many_object_item_args(state, object_name: str, number: int) -> Tuple[int, int, int]:
    count = 0
    status = -1
    num_alpha = 0
    num_numbers = 0
    
    for loop_index in range(state.num_idf_records):
        if state.idf_records[loop_index].name == make_upper_case(object_name):
            count += 1
            if count == number:
                num_alpha = state.idf_records[loop_index].num_alphas
                num_numbers = state.idf_records[loop_index].num_numbers
                status = 1
                break
    
    return num_alpha, num_numbers, status

def get_object_item_from_file(state, which: int) -> Tuple[str, int, List[str], int, List[float], List[bool], List[bool]]:
    object_word = BLANK
    num_alpha = 0
    num_numeric = 0
    alpha_args = []
    numeric_args = []
    alpha_blanks = []
    numeric_blanks = []
    
    if 0 < which <= state.num_idf_records:
        x_line_item = state.idf_records[which - 1]
        object_word = x_line_item.name
        num_alpha = x_line_item.num_alphas
        num_numeric = x_line_item.num_numbers
        alpha_args = x_line_item.alphas[:num_alpha] if num_alpha >= 1 else []
        alpha_blanks = x_line_item.alph_blank[:num_alpha] if num_alpha >= 1 else []
        numeric_args = x_line_item.numbers[:num_numeric] if num_numeric >= 1 else []
        numeric_blanks = x_line_item.num_blank[:num_numeric] if num_numeric >= 1 else []
    
    return object_word, num_alpha, alpha_args, num_numeric, numeric_args, alpha_blanks, numeric_blanks

def verify_name(name_to_verify: str, names_list: List[str], num_of_names: int, 
                string_to_display: str, external_deps=None) -> Tuple[bool, bool]:
    error_found = False
    is_blank = False
    
    if num_of_names > 0:
        found = find_item_in_list(name_to_verify, names_list, num_of_names)
        if found != 0:
            error_found = True
    
    if name_to_verify.strip() == '':
        error_found = True
        is_blank = True
    
    return error_found, is_blank

def range_check(errors_found: bool, what_field_string: str, what_object_string: str, error_level: str,
                lower_bound_string: Optional[str] = None, lower_bound_condition: Optional[bool] = None,
                upper_bound_string: Optional[str] = None, upper_bound_condition: Optional[bool] = None,
                value_string: Optional[str] = None, external_deps=None) -> bool:
    error = False
    if upper_bound_condition is not None:
        if not upper_bound_condition:
            error = True
    if lower_bound_condition is not None:
        if not lower_bound_condition:
            error = True
    
    if error:
        message = f'Out of range value field={what_field_string},'
        if value_string:
            message += f' Value=[{value_string}]'
        message += ', range={'
        if lower_bound_string:
            message += lower_bound_string
        if lower_bound_string and upper_bound_string:
            message += ' and ' + upper_bound_string
        elif upper_bound_string:
            message += upper_bound_string
        message += f'}}, for item={what_object_string}'
        errors_found = True
    
    return errors_found

def turn_on_report_range_check_errors(state):
    state.report_range_check_errors = True

def turn_off_report_range_check_errors(state):
    state.report_range_check_errors = False

def get_num_range_check_errors_found(state) -> int:
    return state.num_out_of_range_errors_found

def get_num_objects_in_idd(state) -> int:
    return state.num_object_defs

def get_list_of_objects_in_idd(state) -> List[str]:
    return [state.object_def[i].name for i in range(state.num_object_defs)]

def get_object_def_in_idd(state, object_word: str) -> Tuple[int, List[bool], List[bool], int]:
    which = find_item_in_list(object_word, [state.object_def[i].name for i in range(state.num_object_defs)], state.num_object_defs)
    if which == 0:
        return 0, [], [], 0
    
    num_args = state.object_def[which - 1].num_params
    alpha_or_numeric = state.object_def[which - 1].alpha_or_numeric[:num_args]
    required_fields = state.object_def[which - 1].req_field[:num_args]
    min_num_fields = state.object_def[which - 1].min_num_fields
    
    return num_args, alpha_or_numeric, required_fields, min_num_fields

def dump_current_line_buffer(start_line: int, num_conx_lines: int, line_buf: str, line_buf_len: List[int]):
    pass

def show_audit_error_message(severity: str, error_message: str, echo_input_file=None):
    if severity:
        if echo_input_file:
            echo_input_file.write(f'{severity}{error_message}\n')
    else:
        if echo_input_file:
            echo_input_file.write(f' ************* {error_message}\n')
