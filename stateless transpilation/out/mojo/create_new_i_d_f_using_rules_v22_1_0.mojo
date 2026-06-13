from collections import Dict
from memory import UnsafePointer

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: prog_name_conversion, program_path, blank
# - DataVCompareGlobals: shared state objects
# - VCompareGlobalRoutines: helper functions
# - InputProcessor: processing functions
# - DataGlobals: error/warning functions


struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int
    var commt_e: Int
    
    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.alphas = DynamicVector[String]()
        self.numbers = DynamicVector[Float64]()
        self.commt_s = 0
        self.commt_e = 0


struct ExternalDeps:
    var prog_name_conversion: String
    var program_path: String
    var blank: String
    
    var full_file_name: String
    var file_name_path: String
    var audit_f: Int
    var fatal_error: Bool
    var making_pretty: Bool
    var processing_imf_file: Bool
    var file_ok: Bool
    
    var idf_records: DynamicVector[IDFRecord]
    var comments: DynamicVector[String]
    var cur_comment: Int
    var num_idf_records: Int
    
    var not_in_new: DynamicVector[String]
    var num_object_defs: Int
    var object_def_names: DynamicVector[String]
    
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var max_name_length: Int
    
    var num_alpha: Int
    var num_numbers: Int
    
    var num_rep_var_names: Int
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var new_rep_var_caution: DynamicVector[String]
    var otm_var_caution: DynamicVector[Bool]
    var cmtr_var_caution: DynamicVector[Bool]
    var cmtr_d_var_caution: DynamicVector[Bool]
    
    fn __init__(inout self):
        self.prog_name_conversion = ""
        self.program_path = ""
        self.blank = ""
        self.full_file_name = ""
        self.file_name_path = ""
        self.audit_f = 0
        self.fatal_error = False
        self.making_pretty = False
        self.processing_imf_file = False
        self.file_ok = False
        self.idf_records = DynamicVector[IDFRecord]()
        self.comments = DynamicVector[String]()
        self.cur_comment = 0
        self.num_idf_records = 0
        self.not_in_new = DynamicVector[String]()
        self.num_object_defs = 0
        self.object_def_names = DynamicVector[String]()
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0
        self.max_name_length = 0
        self.num_alpha = 0
        self.num_numbers = 0
        self.num_rep_var_names = 0
        self.old_rep_var_name = DynamicVector[String]()
        self.new_rep_var_name = DynamicVector[String]()
        self.new_rep_var_caution = DynamicVector[String]()
        self.otm_var_caution = DynamicVector[Bool]()
        self.cmtr_var_caution = DynamicVector[Bool]()
        self.cmtr_d_var_caution = DynamicVector[Bool]()


trait ExternalFunctions:
    fn get_new_unit_number(self) -> Int: ...
    fn show_message(self, msg: String, audit_file: Int = 0): ...
    fn show_continue_error(self, msg: String, audit_file: Int = 0): ...
    fn show_fatal_error(self, msg: String, audit_file: Int = 0): ...
    fn show_severe_error(self, msg: String, audit_file: Int = 0): ...
    fn show_warning_error(self, msg: String, audit_file: Int = 0): ...
    fn trim_trail_zeros(self, s: String) -> String: ...
    fn make_lower_case(self, s: String) -> String: ...
    fn make_upper_case(self, s: String) -> String: ...
    fn same_string(self, s1: String, s2: String) -> Bool: ...
    fn find_item_in_list(self, item: String, list_items: DynamicVector[String], size: Int) -> Int: ...
    fn process_input(self, idd_file: String, new_idd_file: String, idf_file: String, inout deps: ExternalDeps): ...
    fn display_string(self, msg: String): ...
    fn write_out_idf_lines_as_comments(self, file_unit: Int, object_name: String, cur_args: Int, 
                                       out_args: DynamicVector[String], fld_names: DynamicVector[String], 
                                       fld_units: DynamicVector[String]): ...
    fn scan_output_variables_for_replacement(self, field_num: Int, del_this: UnsafePointer[Bool], 
                                            check_rvi: UnsafePointer[Bool], nodiff: UnsafePointer[Bool],
                                            object_name: String, file_unit: Int, out_var: Bool, mtr_var: Bool,
                                            time_bin_var: Bool, cur_args: Int, written: UnsafePointer[Bool],
                                            ems_actuator: Bool, inout deps: ExternalDeps): ...
    fn write_out_idf_lines(self, file_unit: Int, object_name: String, cur_args: Int,
                          out_args: DynamicVector[String], fld_names: DynamicVector[String],
                          fld_units: DynamicVector[String]): ...
    fn check_special_objects(self, file_unit: Int, object_name: String, cur_args: Int,
                            out_args: DynamicVector[String], fld_names: DynamicVector[String],
                            fld_units: DynamicVector[String], written: UnsafePointer[Bool]): ...
    fn get_num_sections_found(self, section_name: String) -> Int: ...
    fn process_rvi_mvi_files(self, file_name_path: String, extension: String, inout deps: ExternalDeps): ...
    fn close_out(self): ...
    fn create_new_name(self, action: String, created_output_name: UnsafePointer[String], extra: String, inout deps: ExternalDeps): ...
    fn copyfile(self, src: String, dst: String, err_flag: UnsafePointer[Bool]): ...
    fn write_preprocessor_object(self, file_unit: Int, prog_name: String, level: String, msg: String): ...


@always_inline
fn trim_string(s: String) -> String:
    return s.rstrip()


@always_inline
fn adjust_left(s: String) -> String:
    return s.lstrip()


@always_inline
fn scan_backward(s: String, char: String) -> Int:
    var idx = s.rfind(char)
    return idx + 1 if idx >= 0 else 0


@always_inline
fn scan_forward(s: String, char: String) -> Int:
    var idx = s.find(char)
    return idx + 1 if idx >= 0 else 0


@always_inline
fn len_trim(s: String) -> Int:
    return len(s.rstrip())


fn set_this_version_variables(inout deps: ExternalDeps) -> (String, String, String):
    deps.blank = ""
    var ver_string = "Conversion 9.6 => 22.1"
    var version_num = 22.1
    var s_version_num = "***"
    var s_version_num_four_chars = "22.1"
    
    var idd_file_name_with_path = deps.program_path.rstrip() + "V9-6-0-Energy+.idd"
    var new_idd_file_name_with_path = deps.program_path.rstrip() + "V22-1-0-Energy+.idd"
    var rep_var_file_name_with_path = deps.program_path.rstrip() + "Report Variables 9-6-0 to 22-1-0.csv"
    
    return (idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path)


fn create_new_idf_using_rules(
    end_of_file: UnsafePointer[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout deps: ExternalDeps,
    ext_funcs: ExternalFunctions
) -> None:
    var fmta = "(A)"
    
    var ios = 0
    var dot_pos = 0
    var status = 0
    var na = 0
    var nn = 0
    var cur_args = 0
    var dif_lfn = 0
    var x_count = 0
    var num = 0
    var arg = 0
    var first_time = True
    var units_arg = ""
    var object_name = ""
    var uc_rep_var_name = ""
    var uc_comp_rep_var_name = ""
    var del_this = False
    var pos = 0
    var pos2 = 0
    var cur_var_iterator = 0
    var exit_because_bad_file = False
    var still_working = True
    var no_diff = True
    var check_rvi = False
    var no_version = True
    var diff_min_fields = False
    var written = False
    var var = 0
    var cur_var = 0
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = ""
    var wild_match = False
    
    var p_out_args = DynamicVector[String]()
    var conn_comp = False
    var conn_comp_ctrl = False
    var file_exist = False
    var created_output_name = ""
    var delete_this_record = DynamicVector[Bool]()
    var c_out_args = 0
    var units_field = ""
    var err_flag = False
    
    var i = 0
    var cur_field = 0
    var new_field = 0
    var ka_index = 0
    var search_num = 0
    var alpha_num_i = 0
    var save_number = 0.0
    
    var tot_run_periods = 0
    var run_period_num = 0
    var iterate_run_period = 0
    var wwhp_eq_ft_cool_index = 0
    var wwhp_eq_ft_heat_index = 0
    var wahp_eq_ft_cool_index = 0
    var wahp_eq_ft_heat_index = 0
    var current_run_period_names = DynamicVector[String]()
    var potential_run_period_name = ""
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[]:
            var full_file_name = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
            else:
                if not arg_file:
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == "!":
                    full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                ext_funcs.display_string("Processing IDF -- " + full_file_name.strip())
                
                dot_pos = scan_backward(full_file_name, ".")
                var file_name_path = ""
                if dot_pos != 0:
                    file_name_path = full_file_name[:dot_pos - 1]
                    local_file_extension = ext_funcs.make_lower_case(full_file_name[dot_pos:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.rstrip() + ".idf"
                    local_file_extension = "idf"
                
                deps.full_file_name = full_file_name
                deps.file_name_path = file_name_path
                
                dif_lfn = ext_funcs.get_new_unit_number()
                
                file_exist = False
                
                deps.file_ok = file_exist
                
                if not file_exist:
                    print("File not found=" + full_file_name)
                    end_of_file[] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    var out_file_name = ""
                    if diff_only:
                        out_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        ext_funcs.show_warning_error("Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.", deps.audit_f)
                        deps.processing_imf_file = True
                    else:
                        deps.processing_imf_file = False
                    
                    ext_funcs.process_input(
                        file_name_path,
                        file_name_path,
                        full_file_name,
                        deps
                    )
                    
                    if deps.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    if deps.num_idf_records > 0:
                        delete_this_record = DynamicVector[Bool](capacity=deps.num_idf_records)
                        for _ in range(deps.num_idf_records):
                            delete_this_record.push_back(False)
                    
                    no_version = True
                    for num_idx in range(deps.idf_records.size):
                        if ext_funcs.make_upper_case(deps.idf_records[num_idx].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num_idx in range(delete_this_record.size):
                        if delete_this_record[num_idx]:
                            print("! Deleting: " + deps.idf_records[num_idx].name + "=\"" + deps.idf_records[num_idx].alphas[0] + "\".")
                    
                    ext_funcs.display_string("Processing IDF -- Processing idf objects . . .")
                    
                    for num_idx in range(deps.idf_records.size):
                        if delete_this_record[num_idx]:
                            continue
                        
                        for x_count_idx in range(deps.idf_records[num_idx].commt_s, deps.idf_records[num_idx].commt_e + 1):
                            if x_count_idx < deps.comments.size:
                                print(deps.comments[x_count_idx].rstrip())
                                if x_count_idx == deps.idf_records[num_idx].commt_e:
                                    print()
                        
                        if no_version and num_idx == 0:
                            object_name = "VERSION"
                        
                        object_name = deps.idf_records[num_idx].name
                        
                        if ext_funcs.find_item_in_list(object_name, deps.object_def_names, deps.num_object_defs) != 0:
                            var num_alphas = deps.idf_records[num_idx].num_alphas
                            var num_numbers = deps.idf_records[num_idx].num_numbers
                            
                            var alphas = DynamicVector[String](capacity=num_alphas)
                            var numbers = DynamicVector[Float64](capacity=num_numbers)
                            
                            cur_args = num_alphas + num_numbers
                            var in_args = DynamicVector[String](capacity=cur_args + 1)
                            var out_args = DynamicVector[String](capacity=cur_args + 1)
                            var temp_args = DynamicVector[String](capacity=cur_args + 1)
                            
                            for _ in range(cur_args + 1):
                                in_args.push_back("")
                                out_args.push_back("")
                                temp_args.push_back("")
                            
                            na = 0
                            nn = 0
                            for arg_idx in range(cur_args):
                                if na <= num_alphas:
                                    na += 1
                                    if na - 1 < alphas.size:
                                        in_args[arg_idx] = alphas[na - 1]
                                else:
                                    nn += 1
                                    if nn - 1 < numbers.size:
                                        in_args[arg_idx] = str(numbers[nn - 1])
                    
                    ext_funcs.display_string("Processing IDF -- Processing idf objects complete.")
                    
                    if deps.idf_records.size > 0 and deps.idf_records[deps.idf_records.size - 1].commt_e != deps.cur_comment:
                        for x_count_idx in range(deps.idf_records[deps.idf_records.size - 1].commt_e + 1, deps.cur_comment + 1):
                            if x_count_idx < deps.comments.size:
                                print(deps.comments[x_count_idx].rstrip())
                                if x_count_idx == deps.idf_records[deps.idf_records.size - 1].commt_e:
                                    print()
                    
                    if ext_funcs.get_num_sections_found("Report Variable Dictionary") > 0:
                        object_name = "Output:VariableDictionary"
                        var out_args_report = DynamicVector[String]()
                        out_args_report.push_back("Regular")
                        cur_args = 1
                        var nw_fld_names = DynamicVector[String]()
                        var nw_fld_units = DynamicVector[String]()
                        ext_funcs.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args_report, nw_fld_names, nw_fld_units)
                    
                    file_exist = False
                    
                    ext_funcs.process_rvi_mvi_files(file_name_path, "rvi", deps)
                    ext_funcs.process_rvi_mvi_files(file_name_path, "mvi", deps)
                    ext_funcs.close_out()
                
                else:
                    ext_funcs.process_rvi_mvi_files(file_name_path, "rvi", deps)
                    ext_funcs.process_rvi_mvi_files(file_name_path, "mvi", deps)
            
            else:
                end_of_file[] = True
            
            var created_output_name_ptr = UnsafePointer[String].address_of(created_output_name)
            ext_funcs.create_new_name("Reallocate", created_output_name_ptr, " ", deps)
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[] = False
            else:
                end_of_file[] = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        var err_flag_ptr = UnsafePointer[Bool].address_of(err_flag)
        
        ext_funcs.copyfile(
            file_name_path + "." + arg_idf_extension,
            file_name_path + "." + arg_idf_extension + "old",
            err_flag_ptr
        )
        ext_funcs.copyfile(
            file_name_path + "." + arg_idf_extension + "new",
            file_name_path + "." + arg_idf_extension,
            err_flag_ptr
        )
        
        file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(file_name_path + ".rvi", file_name_path + ".rviold", err_flag_ptr)
        
        file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(file_name_path + ".rvinew", file_name_path + ".rvi", err_flag_ptr)
        
        file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(file_name_path + ".mvi", file_name_path + ".mviold", err_flag_ptr)
        
        file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(file_name_path + ".mvinew", file_name_path + ".mvi", err_flag_ptr)
