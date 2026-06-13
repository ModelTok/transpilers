# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ver_string, version_num, s_version_num, s_version_num_four_chars, idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path, program_path, full_file_name, blank, prog_name_conversion
# - DataVCompareGlobals: max_name_length, max_alpha_args_found, max_numeric_args_found, max_total_args, auditf, file_ok, alphas, numbers, in_args, temp_args, a_or_n, req_fld, fld_names, fld_defaults, fld_units, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units, out_args, num_idf_records, idf_records, comments, cur_comment, object_def, num_object_defs, not_in_new, num_rep_var_names, old_rep_var_name, new_rep_var_name, new_rep_var_caution, otm_var_caution, cmtr_var_caution, cmtr_d_var_caution, processing_imf_file, fatal_error
# - InputProcessor: process_input, get_object_def_in_idd, get_new_object_def_in_idd, find_item_in_list
# - VCompareGlobalRoutines: scan_output_variables_for_replacement, write_out_idf_lines_as_comments, check_special_objects, write_out_idf_lines, get_num_sections_found, process_rvi_mvi_files, close_out, create_new_name, write_preprocessor_object
# - General: make_lower_case, copyfile_fn, get_new_unit_number, trim_trail_zeros
# - DataGlobals: show_message, show_continue_error, show_fatal_error, show_severe_error, show_warning_error

import os
from typing import Callable, List, Optional, Any

trait ExternalState:
    fn get_ver_string(self) -> String: ...
    fn set_ver_string(inout self, v: String): ...
    fn get_version_num(self) -> Float64: ...
    fn set_version_num(inout self, v: Float64): ...
    fn get_s_version_num(self) -> String: ...
    fn set_s_version_num(inout self, v: String): ...
    fn get_s_version_num_four_chars(self) -> String: ...
    fn set_s_version_num_four_chars(inout self, v: String): ...
    fn get_idd_file_name_with_path(self) -> String: ...
    fn set_idd_file_name_with_path(inout self, v: String): ...
    fn get_new_idd_file_name_with_path(self) -> String: ...
    fn set_new_idd_file_name_with_path(inout self, v: String): ...
    fn get_rep_var_file_name_with_path(self) -> String: ...
    fn set_rep_var_file_name_with_path(inout self, v: String): ...
    fn get_program_path(self) -> String: ...
    fn set_program_path(inout self, v: String): ...
    fn get_full_file_name(self) -> String: ...
    fn set_full_file_name(inout self, v: String): ...
    fn get_blank(self) -> String: ...
    fn set_blank(inout self, v: String): ...
    fn get_prog_name_conversion(self) -> String: ...
    fn set_prog_name_conversion(inout self, v: String): ...
    fn get_max_name_length(self) -> Int: ...
    fn set_max_name_length(inout self, v: Int): ...
    fn get_max_alpha_args_found(self) -> Int: ...
    fn set_max_alpha_args_found(inout self, v: Int): ...
    fn get_max_numeric_args_found(self) -> Int: ...
    fn set_max_numeric_args_found(inout self, v: Int): ...
    fn get_max_total_args(self) -> Int: ...
    fn set_max_total_args(inout self, v: Int): ...
    fn get_auditf(self) -> AnyPointer: ...
    fn set_auditf(inout self, v: AnyPointer): ...
    fn get_file_ok(self) -> Bool: ...
    fn set_file_ok(inout self, v: Bool): ...
    fn get_alphas(self) -> DynamicVector[String]: ...
    fn set_alphas(inout self, v: DynamicVector[String]): ...
    fn get_numbers(self) -> DynamicVector[Float64]: ...
    fn set_numbers(inout self, v: DynamicVector[Float64]): ...
    fn get_in_args(self) -> DynamicVector[String]: ...
    fn set_in_args(inout self, v: DynamicVector[String]): ...
    fn get_temp_args(self) -> DynamicVector[String]: ...
    fn set_temp_args(inout self, v: DynamicVector[String]): ...
    fn get_a_or_n(self) -> DynamicVector[Bool]: ...
    fn set_a_or_n(inout self, v: DynamicVector[Bool]): ...
    fn get_req_fld(self) -> DynamicVector[Bool]: ...
    fn set_req_fld(inout self, v: DynamicVector[Bool]): ...
    fn get_fld_names(self) -> DynamicVector[String]: ...
    fn set_fld_names(inout self, v: DynamicVector[String]): ...
    fn get_fld_defaults(self) -> DynamicVector[String]: ...
    fn set_fld_defaults(inout self, v: DynamicVector[String]): ...
    fn get_fld_units(self) -> DynamicVector[String]: ...
    fn set_fld_units(inout self, v: DynamicVector[String]): ...
    fn get_nw_a_or_n(self) -> DynamicVector[Bool]: ...
    fn set_nw_a_or_n(inout self, v: DynamicVector[Bool]): ...
    fn get_nw_req_fld(self) -> DynamicVector[Bool]: ...
    fn set_nw_req_fld(inout self, v: DynamicVector[Bool]): ...
    fn get_nw_fld_names(self) -> DynamicVector[String]: ...
    fn set_nw_fld_names(inout self, v: DynamicVector[String]): ...
    fn get_nw_fld_defaults(self) -> DynamicVector[String]: ...
    fn set_nw_fld_defaults(inout self, v: DynamicVector[String]): ...
    fn get_nw_fld_units(self) -> DynamicVector[String]: ...
    fn set_nw_fld_units(inout self, v: DynamicVector[String]): ...
    fn get_out_args(self) -> DynamicVector[String]: ...
    fn set_out_args(inout self, v: DynamicVector[String]): ...
    fn get_num_idf_records(self) -> Int: ...
    fn set_num_idf_records(inout self, v: Int): ...
    fn get_idf_records(self) -> DynamicVector[AnyPointer]: ...
    fn set_idf_records(inout self, v: DynamicVector[AnyPointer]): ...
    fn get_comments(self) -> DynamicVector[String]: ...
    fn set_comments(inout self, v: DynamicVector[String]): ...
    fn get_cur_comment(self) -> Int: ...
    fn set_cur_comment(inout self, v: Int): ...
    fn get_object_def(self) -> DynamicVector[AnyPointer]: ...
    fn set_object_def(inout self, v: DynamicVector[AnyPointer]): ...
    fn get_num_object_defs(self) -> Int: ...
    fn set_num_object_defs(inout self, v: Int): ...
    fn get_not_in_new(self) -> DynamicVector[String]: ...
    fn set_not_in_new(inout self, v: DynamicVector[String]): ...
    fn get_num_rep_var_names(self) -> Int: ...
    fn set_num_rep_var_names(inout self, v: Int): ...
    fn get_old_rep_var_name(self) -> DynamicVector[String]: ...
    fn set_old_rep_var_name(inout self, v: DynamicVector[String]): ...
    fn get_new_rep_var_name(self) -> DynamicVector[String]: ...
    fn set_new_rep_var_name(inout self, v: DynamicVector[String]): ...
    fn get_new_rep_var_caution(self) -> DynamicVector[String]: ...
    fn set_new_rep_var_caution(inout self, v: DynamicVector[String]): ...
    fn get_otm_var_caution(self) -> DynamicVector[Bool]: ...
    fn set_otm_var_caution(inout self, v: DynamicVector[Bool]): ...
    fn get_cmtr_var_caution(self) -> DynamicVector[Bool]: ...
    fn set_cmtr_var_caution(inout self, v: DynamicVector[Bool]): ...
    fn get_cmtr_d_var_caution(self) -> DynamicVector[Bool]: ...
    fn set_cmtr_d_var_caution(inout self, v: DynamicVector[Bool]): ...
    fn get_processing_imf_file(self) -> Bool: ...
    fn set_processing_imf_file(inout self, v: Bool): ...
    fn get_fatal_error(self) -> Bool: ...
    fn set_fatal_error(inout self, v: Bool): ...
    fn display_string(inout self, msg: String): ...
    fn process_input(inout self, idd_path: String, new_idd_path: String, idf_file: String): ...
    fn get_object_def_in_idd(inout self, obj_name: String) -> AnyPointer: ...
    fn get_new_object_def_in_idd(inout self, obj_name: String) -> AnyPointer: ...
    fn find_item_in_list(self, item: String, list_items: DynamicVector[String], list_size: Int) -> Int: ...
    fn scan_output_variables_for_replacement(inout self, field: Int, del_this: DynamicVector[Bool], check_rvi: Bool, no_diff: DynamicVector[Bool], obj_name: String, dif_file: AnyPointer, is_out_var: Bool, is_mtr_var: Bool, is_time_bin_var: Bool, cur_args: DynamicVector[Int], written: DynamicVector[Bool], is_ems_sensor: Bool): ...
    fn write_out_idf_lines_as_comments(inout self, dif_file: AnyPointer, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]): ...
    fn check_special_objects(inout self, dif_file: AnyPointer, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String], written: DynamicVector[Bool]): ...
    fn write_out_idf_lines(inout self, dif_file: AnyPointer, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]): ...
    fn get_num_sections_found(self, section: String) -> Int: ...
    fn process_rvi_mvi_files(inout self, file_path: String, ext: String): ...
    fn close_out(inout self): ...
    fn create_new_name(inout self, action: String, out_name: inout String, char: String): ...
    fn write_preprocessor_object(inout self, dif_file: AnyPointer, prog_name: String, level: String, msg: String): ...
    fn make_lower_case(self, s: String) -> String: ...
    fn copyfile_fn(self, src: String, dest: String, err_flag: inout Bool): ...
    fn get_new_unit_number(self) -> Int: ...
    fn trim_trail_zeros(self, s: String) -> String: ...
    fn show_message(inout self, msg: String): ...
    fn show_continue_error(inout self, msg: String): ...
    fn show_fatal_error(inout self, msg: String): ...
    fn show_severe_error(inout self, msg: String): ...
    fn show_warning_error(inout self, msg: String, auditf: AnyPointer): ...

@always_inline
fn set_this_version_variables(inout state: ExternalState) -> None:
    state.set_ver_string('Conversion 24.2 => 25.1')
    state.set_version_num(25.1)
    state.set_s_version_num('***')
    state.set_s_version_num_four_chars('25.1')
    var prog_path = state.get_program_path()
    state.set_idd_file_name_with_path(prog_path + 'V24-2-0-Energy+.idd')
    state.set_new_idd_file_name_with_path(prog_path + 'V25-1-0-Energy+.idd')
    state.set_rep_var_file_name_with_path(prog_path + 'Report Variables 24-2-0 to 25-1-0.csv')

fn create_new_idf_using_rules(
    inout end_of_file: DynamicVector[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: ExternalState
) -> None:
    var ios: Int = 0
    var dot_pos: Int = 0
    var status: Int = 0
    var na: Int = 0
    var nn: Int = 0
    var cur_args: Int = 0
    var dif_lfn: Int = 0
    var x_count: Int = 0
    var num: Int = 0
    var arg: Int = 0
    var first_time: Bool = True
    var units_arg: String = state.get_blank()
    var object_name: String = state.get_blank()
    var del_this: Bool = False
    var pos: Int = 0
    var pos2: Int = 0
    var exit_because_bad_file: Bool = False
    var still_working: Bool = False
    var no_diff: Bool = False
    var check_rvi: Bool = False
    var no_version: Bool = False
    var diff_min_fields: Bool = False
    var written: Bool = False
    var var_num: Int = 0
    var cur_var: Int = 0
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var local_file_extension: String = ' '
    var wild_match: Bool = False
    var conn_comp: Bool = False
    var conn_comp_ctrl: Bool = False
    var file_exist: Bool = False
    var created_output_name: String = state.get_blank()
    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
    var c_out_args: Int = 0
    var units_field: String = ''
    var err_flag: Bool = False
    var i: Int = 0
    var cur_field: Int = 0
    var new_field: Int = 0
    var ka_index: Int = 0
    var search_num: Int = 0
    var alpha_num_i: Int = 0
    var save_number: Float64 = 0.0
    
    var tot_run_periods: Int = 0
    var run_period_num: Int = 0
    var iterate_run_period: Int = 0
    var current_run_period_names: DynamicVector[String] = DynamicVector[String]()
    var potential_run_period_name: String = ''
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    var file_name_path: String = state.get_blank()
    var dif_file: AnyPointer = AnyPointer()
    var num_alphas: Int = 0
    var num_numbers: Int = 0
    var nw_num_args: Int = 0
    var obj_min_flds: Int = 0
    var nw_obj_min_flds: Int = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                var line: String = input()
                state.set_full_file_name(line)
            else:
                if not arg_file:
                    try:
                        var input_line: String = input()
                        state.set_full_file_name(input_line)
                    except:
                        state.set_full_file_name(state.get_blank())
                        ios = 1
                elif not arg_file_being_done:
                    state.set_full_file_name(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.set_full_file_name(state.get_blank())
                    ios = 1
                
                var full_file = state.get_full_file_name()
                if full_file and full_file[0:1] == '!':
                    state.set_full_file_name(state.get_blank())
                    continue
            
            units_arg = state.get_blank()
            if ios != 0:
                state.set_full_file_name(state.get_blank())
            
            var full_file_name = state.get_full_file_name()
            state.set_full_file_name(full_file_name.lstrip())
            
            var full_file_trimmed = state.get_full_file_name()
            if full_file_trimmed != state.get_blank():
                state.display_string('Processing IDF -- ' + full_file_trimmed)
                state.show_warning_error(' Processing IDF -- ' + full_file_trimmed, state.get_auditf())
                
                var full_file_search = state.get_full_file_name()
                dot_pos = full_file_search.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_search[0:dot_pos]
                    local_file_extension = state.make_lower_case(full_file_search[dot_pos+1:])
                else:
                    file_name_path = full_file_search
                    print(' assuming file extension of .idf')
                    state.show_warning_error(' ..assuming file extension of .idf', state.get_auditf())
                    state.set_full_file_name(full_file_search + '.idf')
                    local_file_extension = 'idf'
                
                dif_lfn = state.get_new_unit_number()
                state.set_file_ok(os.path.exists(state.get_full_file_name()))
                
                if not state.get_file_ok():
                    print('File not found=' + state.get_full_file_name())
                    state.show_warning_error('File not found=' + state.get_full_file_name(), state.get_auditf())
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    var dif_filename: String
                    if diff_only:
                        dif_filename = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_filename = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        state.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.get_auditf())
                        state.set_processing_imf_file(True)
                    else:
                        state.set_processing_imf_file(False)
                    
                    state.process_input(state.get_idd_file_name_with_path(), state.get_new_idd_file_name_with_path(), state.get_full_file_name())
                    
                    if state.get_fatal_error():
                        exit_because_bad_file = True
                        break
                    
                    for j in range(state.get_num_idf_records()):
                        delete_this_record.push_back(False)
                    
                    var blank_str = state.get_blank()
                    var alphas_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_alpha_args_found()):
                        alphas_vec.push_back(blank_str)
                    state.set_alphas(alphas_vec)
                    
                    var numbers_vec: DynamicVector[Float64] = DynamicVector[Float64]()
                    for j in range(state.get_max_numeric_args_found()):
                        numbers_vec.push_back(0.0)
                    state.set_numbers(numbers_vec)
                    
                    var in_args_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        in_args_vec.push_back(blank_str)
                    state.set_in_args(in_args_vec)
                    
                    var temp_args_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        temp_args_vec.push_back(blank_str)
                    state.set_temp_args(temp_args_vec)
                    
                    var a_or_n_vec: DynamicVector[Bool] = DynamicVector[Bool]()
                    for j in range(state.get_max_total_args()):
                        a_or_n_vec.push_back(False)
                    state.set_a_or_n(a_or_n_vec)
                    
                    var req_fld_vec: DynamicVector[Bool] = DynamicVector[Bool]()
                    for j in range(state.get_max_total_args()):
                        req_fld_vec.push_back(False)
                    state.set_req_fld(req_fld_vec)
                    
                    var fld_names_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        fld_names_vec.push_back(blank_str)
                    state.set_fld_names(fld_names_vec)
                    
                    var fld_defaults_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        fld_defaults_vec.push_back(blank_str)
                    state.set_fld_defaults(fld_defaults_vec)
                    
                    var fld_units_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        fld_units_vec.push_back(blank_str)
                    state.set_fld_units(fld_units_vec)
                    
                    var nw_a_or_n_vec: DynamicVector[Bool] = DynamicVector[Bool]()
                    for j in range(state.get_max_total_args()):
                        nw_a_or_n_vec.push_back(False)
                    state.set_nw_a_or_n(nw_a_or_n_vec)
                    
                    var nw_req_fld_vec: DynamicVector[Bool] = DynamicVector[Bool]()
                    for j in range(state.get_max_total_args()):
                        nw_req_fld_vec.push_back(False)
                    state.set_nw_req_fld(nw_req_fld_vec)
                    
                    var nw_fld_names_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        nw_fld_names_vec.push_back(blank_str)
                    state.set_nw_fld_names(nw_fld_names_vec)
                    
                    var nw_fld_defaults_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        nw_fld_defaults_vec.push_back(blank_str)
                    state.set_nw_fld_defaults(nw_fld_defaults_vec)
                    
                    var nw_fld_units_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        nw_fld_units_vec.push_back(blank_str)
                    state.set_nw_fld_units(nw_fld_units_vec)
                    
                    var out_args_vec: DynamicVector[String] = DynamicVector[String]()
                    for j in range(state.get_max_total_args()):
                        out_args_vec.push_back(blank_str)
                    state.set_out_args(out_args_vec)
                    
                    no_version = True
                    for num_check in range(1, state.get_num_idf_records() + 1):
                        if state.find_item_in_list(state.get_full_file_name(), state.get_not_in_new(), state.get_num_object_defs()) == 0:
                            no_version = False
                            break
                    
                    state.display_string('Processing IDF -- Processing idf objects . . .')
                    
                    state.display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if state.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        state.write_out_idf_lines(dif_file, object_name, 1, state.get_out_args(), state.get_nw_fld_names(), state.get_nw_fld_units())
                    
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
                    state.close_out()
                else:
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file[0] = True
            
            state.create_new_name('Reallocate', inout created_output_name, ' ')
        
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
        err_flag = False
        state.copyfile_fn(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', inout err_flag)
        state.copyfile_fn(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, inout err_flag)
        
        if os.path.exists(file_name_path + '.rvi'):
            state.copyfile_fn(file_name_path + '.rvi', file_name_path + '.rviold', inout err_flag)
        
        if os.path.exists(file_name_path + '.rvinew'):
            state.copyfile_fn(file_name_path + '.rvinew', file_name_path + '.rvi', inout err_flag)
        
        if os.path.exists(file_name_path + '.mvi'):
            state.copyfile_fn(file_name_path + '.mvi', file_name_path + '.mviold', inout err_flag)
        
        if os.path.exists(file_name_path + '.mvinew'):
            state.copyfile_fn(file_name_path + '.mvinew', file_name_path + '.mvi', inout err_flag)
