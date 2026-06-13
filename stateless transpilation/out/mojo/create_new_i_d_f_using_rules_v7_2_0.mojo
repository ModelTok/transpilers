# EXTERNAL DEPS (to wire in glue):
# - get_new_unit_number() from InputProcessor
# - process_input() from InputProcessor
# - find_item_in_list(), make_lower_case(), make_upper_case() from General
# - get_object_def_in_idd(), get_new_object_def_in_idd() from InputProcessor
# - same_string() from General
# - scan_output_variables_for_replacement() from VCompareGlobalRoutines
# - write_out_idf_lines_as_comments() from VCompareGlobalRoutines
# - check_special_objects() from VCompareGlobalRoutines
# - write_out_idf_lines() from VCompareGlobalRoutines
# - get_num_sections_found() from InputProcessor
# - process_rvi_mvi_files() from VCompareGlobalRoutines
# - close_out() from VCompareGlobalRoutines
# - create_new_name() from VCompareGlobalRoutines
# - copyfile() from system utilities
# - show_warning_error(), show_message() from DataGlobals
# - write_preprocessor_object() from VCompareGlobalRoutines
# - data_string_globals.prog_name_conversion
# - data_v_compare_globals: all shared state variables

from memory import DTypePointer, memset_zero
from sys import DynamicVector
from builtin import DynamicVector as Vector


@value
struct GlobalState:
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var full_file_name: String
    var auditf: UnsafePointer[UInt8]
    var program_path: String
    var file_ok: Bool
    var file_name_path: String
    var processing_imf_file: Bool
    var fatal_error: Bool
    var num_idf_records: Int
    var idf_records: DynamicVector[UnsafePointer[UInt8]]
    var comments: DynamicVector[String]
    var cur_comment: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var in_args: DynamicVector[String]
    var a_or_n: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var nw_a_or_n: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var out_args: DynamicVector[String]
    var match_arg: DynamicVector[Int]
    var object_def: DynamicVector[UnsafePointer[UInt8]]
    var num_object_defs: Int
    var not_in_new: DynamicVector[String]
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var new_rep_var_caution: DynamicVector[String]
    var num_rep_var_names: Int
    var otm_var_caution: DynamicVector[Bool]
    var cmtr_var_caution: DynamicVector[Bool]
    var cmtr_d_var_caution: DynamicVector[Bool]
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var making_pretty: Bool
    
    fn __init__(inout self):
        self.ver_string = ""
        self.version_num = 0.0
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""
        self.full_file_name = ""
        self.auditf = UnsafePointer[UInt8]()
        self.program_path = ""
        self.file_ok = False
        self.file_name_path = ""
        self.processing_imf_file = False
        self.fatal_error = False
        self.num_idf_records = 0
        self.idf_records = DynamicVector[UnsafePointer[UInt8]]()
        self.comments = DynamicVector[String]()
        self.cur_comment = 0
        self.alphas = DynamicVector[String]()
        self.numbers = DynamicVector[Float64]()
        self.in_args = DynamicVector[String]()
        self.a_or_n = DynamicVector[Bool]()
        self.req_fld = DynamicVector[Bool]()
        self.fld_names = DynamicVector[String]()
        self.fld_defaults = DynamicVector[String]()
        self.fld_units = DynamicVector[String]()
        self.nw_a_or_n = DynamicVector[Bool]()
        self.nw_req_fld = DynamicVector[Bool]()
        self.nw_fld_names = DynamicVector[String]()
        self.nw_fld_defaults = DynamicVector[String]()
        self.nw_fld_units = DynamicVector[String]()
        self.out_args = DynamicVector[String]()
        self.match_arg = DynamicVector[Int]()
        self.object_def = DynamicVector[UnsafePointer[UInt8]]()
        self.num_object_defs = 0
        self.not_in_new = DynamicVector[String]()
        self.old_rep_var_name = DynamicVector[String]()
        self.new_rep_var_name = DynamicVector[String]()
        self.new_rep_var_caution = DynamicVector[String]()
        self.num_rep_var_names = 0
        self.otm_var_caution = DynamicVector[Bool]()
        self.cmtr_var_caution = DynamicVector[Bool]()
        self.cmtr_d_var_caution = DynamicVector[Bool]()
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0
        self.making_pretty = False


fn set_version_variables(inout state: GlobalState) -> None:
    state.ver_string = "Conversion 7.1 => 7.2"
    state.version_num = 7.2
    state.idd_file_name_with_path = state.program_path.strip() + "V7-1-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path.strip() + "V7-2-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path.strip() + "Report Variables 7-1-0-012 to 7-2-0.csv"


fn trim_trailing_zeros(input_str: String) -> String:
    return input_str.strip()


@always_inline
fn make_blank() -> String:
    return ""


@always_inline
fn string_at(vec: DynamicVector[String], idx: Int) -> String:
    if idx < len(vec):
        return vec[idx]
    return ""


@always_inline
fn update_string_vec(inout vec: DynamicVector[String], idx: Int, val: String):
    if idx >= len(vec):
        for _ in range(idx - len(vec) + 1):
            vec.push_back("")
    vec[idx] = val


fn create_new_idf_using_rules(
    inout state: GlobalState,
    inout end_of_file: DynamicVector[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    prog_name_conversion: String,
    extern_get_new_unit_number: fn() -> Int,
    extern_process_input: fn(String, String, String) -> None,
    extern_find_item_in_list: fn(String, DynamicVector[String], Int) -> Int,
    extern_make_lower_case: fn(String) -> String,
    extern_make_upper_case: fn(String) -> String,
    extern_get_object_def_in_idd: fn(String, inout DynamicVector[Int], inout DynamicVector[Bool],
                                     inout DynamicVector[Bool], inout DynamicVector[Int],
                                     inout DynamicVector[String], inout DynamicVector[String],
                                     inout DynamicVector[String]) -> None,
    extern_get_new_object_def_in_idd: fn(String, inout DynamicVector[Int], inout DynamicVector[Bool],
                                         inout DynamicVector[Bool], inout DynamicVector[Int],
                                         inout DynamicVector[String], inout DynamicVector[String],
                                         inout DynamicVector[String]) -> None,
    extern_same_string: fn(String, String) -> Bool,
    extern_scan_output_variables_for_replacement: fn(Int, inout DynamicVector[Bool],
                                                     inout DynamicVector[Bool], inout DynamicVector[Bool],
                                                     String, UnsafePointer[UInt8], Bool, Bool, Bool,
                                                     inout DynamicVector[Int], inout DynamicVector[Bool], Bool) -> None,
    extern_write_out_idf_lines_as_comments: fn(UnsafePointer[UInt8], String, Int,
                                               DynamicVector[String], DynamicVector[String],
                                               DynamicVector[String]) -> None,
    extern_check_special_objects: fn(UnsafePointer[UInt8], String, Int,
                                    DynamicVector[String], DynamicVector[String],
                                    DynamicVector[String], inout DynamicVector[Bool]) -> None,
    extern_write_out_idf_lines: fn(UnsafePointer[UInt8], String, Int,
                                  DynamicVector[String], DynamicVector[String],
                                  DynamicVector[String]) -> None,
    extern_get_num_sections_found: fn(String) -> Int,
    extern_process_rvi_mvi_files: fn(String, String) -> None,
    extern_close_out: fn() -> None,
    extern_create_new_name: fn(String, inout DynamicVector[String], String) -> None,
    extern_copyfile: fn(String, String) -> None,
    extern_show_warning_error: fn(String, UnsafePointer[UInt8]) -> None,
    extern_write_preprocessor_object: fn(UnsafePointer[UInt8], String, String, String) -> None
) -> None:
    
    var blank = make_blank()
    var first_time: Bool = True
    
    if first_time:
        first_time = False
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file[0] = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                pass
            else:
                if not arg_file:
                    pass
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = blank
                    ios = 1
                
                if state.full_file_name.startswith("!"):
                    state.full_file_name = blank
                    continue
            
            if ios != 0:
                state.full_file_name = blank
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name != blank:
                var dot_pos: Int = state.full_file_name.rfind(".")
                
                if dot_pos != -1:
                    state.file_name_path = state.full_file_name[:dot_pos]
                    local_file_extension = extern_make_lower_case(state.full_file_name[dot_pos+1:])
                else:
                    state.file_name_path = state.full_file_name
                    state.full_file_name = state.full_file_name.strip() + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = extern_get_new_unit_number()
                
                state.file_ok = True
                
                if not state.file_ok:
                    print("File not found=" + state.full_file_name)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_file_name: String
                    if diff_only:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        extern_show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    extern_process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, state.full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    for _ in range(state.max_alpha_args_found):
                        state.alphas.push_back("")
                    for _ in range(state.max_numeric_args_found):
                        state.numbers.push_back(0.0)
                    for _ in range(state.max_total_args):
                        state.in_args.push_back("")
                        state.a_or_n.push_back(False)
                        state.req_fld.push_back(False)
                        state.fld_names.push_back("")
                        state.fld_defaults.push_back("")
                        state.fld_units.push_back("")
                        state.nw_a_or_n.push_back(False)
                        state.nw_req_fld.push_back(False)
                        state.nw_fld_names.push_back("")
                        state.nw_fld_defaults.push_back("")
                        state.nw_fld_units.push_back("")
                        state.out_args.push_back("")
                        state.match_arg.push_back(0)
                    
                    var delete_this_record = DynamicVector[Bool]()
                    for _ in range(state.num_idf_records):
                        delete_this_record.push_back(False)
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        pass
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            pass
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name: String = ""
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        var obj_upper: String = extern_make_upper_case(object_name)
                        
                        if obj_upper == "VERSION":
                            if state.in_args[0][:3] == "7.2" and arg_file:
                                extern_show_warning_error("File is already at latest version.  No new diff file made.", state.auditf)
                                latest_version = True
                                break
                            
                            var nw_num_args = DynamicVector[Int]()
                            nw_num_args.push_back(0)
                            state.out_args[0] = "7.2"
                            nodiff = False
                        
                        if diff_min_fields and nodiff:
                            var nw_num_args = DynamicVector[Int]()
                            nw_num_args.push_back(0)
                            nodiff = False
                            
                            var cur_args_local: Int = 0
                            for arg in range(cur_args_local, 0):
                                pass
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            var check_written = DynamicVector[Bool]()
                            check_written.push_back(False)
                            pass
            
            else:
                end_of_file[0] = True
            
            var created_output_name = DynamicVector[String]()
            created_output_name.push_back("")
            extern_create_new_name("Reallocate", created_output_name, " ")
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var src: String = state.file_name_path + "." + arg_idf_extension
        var dst: String = state.file_name_path + "." + arg_idf_extension + "old"
        extern_copyfile(src, dst)
        
        src = state.file_name_path + "." + arg_idf_extension + "new"
        dst = state.file_name_path + "." + arg_idf_extension
        extern_copyfile(src, dst)
        
        var rvi_file: String = state.file_name_path + ".rvi"
        src = rvi_file
        dst = state.file_name_path + ".rviold"
        extern_copyfile(src, dst)
        
        var rvi_new_file: String = state.file_name_path + ".rvinew"
        src = rvi_new_file
        dst = state.file_name_path + ".rvi"
        extern_copyfile(src, dst)
        
        var mvi_file: String = state.file_name_path + ".mvi"
        src = mvi_file
        dst = state.file_name_path + ".mviold"
        extern_copyfile(src, dst)
        
        var mvi_new_file: String = state.file_name_path + ".mvinew"
        src = mvi_new_file
        dst = state.file_name_path + ".mvi"
        extern_copyfile(src, dst)
