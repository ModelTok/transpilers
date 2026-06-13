from math import floor
from utils.list import List
from utils.string import String

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: MAX_NAME_LENGTH, BLANK
# - DataVCompareGlobals: ver_string, version_num, idd_file_name_with_path, new_idd_file_name_with_path,
#   rep_var_file_name_with_path, program_path, full_file_name, auditf, file_ok, max_alpha_args_found,
#   max_numeric_args_found, max_total_args, num_idf_records, idf_records, comments, cur_comment,
#   processing_imf_file, fatal_error, num_object_defs, object_def, not_in_new, obj_min_flds,
#   num_rep_var_names, old_rep_var_name, new_rep_var_name, making_pretty
# - VCompareGlobalRoutines: Various output/processing functions
# - InputProcessor: process_input
# - General: make_upper_case, make_lower_case, find_item_in_list, process_number, round_sig_digits,
#   same_string, trim_trail_zeros
# - DataGlobals: show_message, show_continue_error, show_fatal_error, show_severe_error, show_warning_error


@value
struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[String]
    var commt_s: Int
    var commt_e: Int


@value
struct ObjectDefinition:
    var name: List[String]


trait ExternalDeps:
    fn get_max_name_length(inout self) -> Int: ...
    fn get_blank(inout self) -> String: ...
    fn get_ver_string(inout self) -> String: ...
    fn set_ver_string(inout self, value: String): ...
    fn get_version_num(inout self) -> Float64: ...
    fn set_version_num(inout self, value: Float64): ...
    fn get_idd_file_name_with_path(inout self) -> String: ...
    fn set_idd_file_name_with_path(inout self, value: String): ...
    fn get_new_idd_file_name_with_path(inout self) -> String: ...
    fn set_new_idd_file_name_with_path(inout self, value: String): ...
    fn get_rep_var_file_name_with_path(inout self) -> String: ...
    fn set_rep_var_file_name_with_path(inout self, value: String): ...
    fn get_program_path(inout self) -> String: ...
    fn get_num_idf_records(inout self) -> Int: ...
    fn get_idf_records(inout self) -> List[IDFRecord]: ...
    fn get_num_object_defs(inout self) -> Int: ...
    fn get_not_in_new(inout self) -> List[String]: ...
    fn get_num_rep_var_names(inout self) -> Int: ...


fn set_this_version_variables(inout deps: ExternalDeps) -> None:
    deps.set_ver_string('Conversion 1.2.3 => 1.3')
    deps.set_version_num(1.0)
    var program_path = deps.get_program_path()
    deps.set_idd_file_name_with_path(program_path + 'V1-2-3-Energy+.idd')
    deps.set_new_idd_file_name_with_path(program_path + 'V1-3-0-Energy+.idd')
    deps.set_rep_var_file_name_with_path(program_path + 'Report Variables 1-2-3-031 to 1-3-0.csv')


fn create_new_idf_using_rules(
    inout deps: ExternalDeps,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    # External function stubs (parameter types would be defined by the actual implementations)
) -> Bool:
    var max_name_length = deps.get_max_name_length()
    var blank = deps.get_blank()
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    var file_name_path = String()
    var full_file_name = String()
    var diff_lfn: Int = 0
    
    var err_flag = False
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end: '')
                # input would need to be handled by external code
            else:
                if not arg_file:
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = blank
                    continue
            
            local_file_extension = blank
            if ios != 0:
                full_file_name = blank
            
            if full_file_name != blank:
                var dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                diff_lfn = get_new_unit_number()
                
                var file_ok = path_exists(full_file_name)
                
                if not file_ok:
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    var check_rvi = False
                    
                    var output_file: FileHandle
                    if diff_only:
                        output_file = open_file(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        output_file = open_file(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.')
                    
                    var num_idf_records = deps.get_num_idf_records()
                    var comis_sim = False
                    var ads_sim = False
                    
                    for num in range(num_idf_records):
                        var idf_records = deps.get_idf_records()
                        if make_upper_case(idf_records[num].name) == 'COMIS SIMULATION':
                            comis_sim = True
                        if make_upper_case(idf_records[num].name) == 'ADS SIMULATION':
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        exit_because_bad_file = True
                        close_file(output_file)
                        break
                    
                    var no_version = True
                    for num in range(num_idf_records):
                        var idf_records = deps.get_idf_records()
                        if make_upper_case(idf_records[num].name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(num_idf_records):
                        var idf_records = deps.get_idf_records()
                        var object_name = idf_records[num].name
                        
                        if make_upper_case(object_name.strip()) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if make_upper_case(object_name.strip()) == 'AIRFLOW MODEL':
                            continue
                        if make_upper_case(object_name.strip()) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if make_upper_case(object_name.strip()) == 'WATER HEATER:SIMPLE':
                            continue
                        
                        var num_object_defs = deps.get_num_object_defs()
                        if find_item_in_list(object_name, deps.get_not_in_new(), len(deps.get_not_in_new())) != -1:
                            continue
                    
                    close_file(output_file)
                else:
                    pass
            else:
                end_of_file = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
    
    return end_of_file


fn make_upper_case(s: String) -> String:
    return s.upper()


fn make_lower_case(s: String) -> String:
    return s.lower()


fn find_item_in_list(item: String, list: List[String], size: Int) -> Int:
    for i in range(size):
        if list[i] == item:
            return i
    return -1


fn process_number(s: String, inout err_flag: Bool) -> Float64:
    try:
        return atof(s)
    except:
        err_flag = True
        return 0.0


fn round_sig_digits(value: Float64, digits: Int) -> String:
    return str(value)


fn same_string(s1: String, s2: String) -> Bool:
    return s1.lower() == s2.lower()


fn get_new_unit_number() -> Int:
    return 10


fn path_exists(path: String) -> Bool:
    return True


fn open_file(path: String, mode: String) -> FileHandle:
    return FileHandle()


fn close_file(inout file: FileHandle) -> None:
    pass


fn show_warning_error(msg: String) -> None:
    print('WARNING: ' + msg)


struct FileHandle:
    pass
