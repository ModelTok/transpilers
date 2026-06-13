# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ver_string, version_num, s_version_num, s_version_num_four_chars, idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path, program_path, full_file_name, blank, prog_name_conversion
# - DataVCompareGlobals: max_name_length, max_alpha_args_found, max_numeric_args_found, max_total_args, auditf, file_ok, alphas, numbers, in_args, temp_args, a_or_n, req_fld, fld_names, fld_defaults, fld_units, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units, out_args, num_idf_records, idf_records, comments, cur_comment, object_def, num_object_defs, not_in_new, num_rep_var_names, old_rep_var_name, new_rep_var_name, new_rep_var_caution, otm_var_caution, cmtr_var_caution, cmtr_d_var_caution, processing_imf_file, fatal_error
# - InputProcessor: process_input, get_object_def_in_idd, get_new_object_def_in_idd, find_item_in_list
# - VCompareGlobalRoutines: scan_output_variables_for_replacement, write_out_idf_lines_as_comments, check_special_objects, write_out_idf_lines, get_num_sections_found, process_rvi_mvi_files, close_out, create_new_name, write_preprocessor_object
# - General: make_lower_case, copyfile_fn, get_new_unit_number, trim_trail_zeros
# - DataGlobals: show_message, show_continue_error, show_fatal_error, show_severe_error, show_warning_error

from typing import List, Any, Protocol
import os

class ExternalState(Protocol):
    ver_string: str
    version_num: float
    s_version_num: str
    s_version_num_four_chars: str
    idd_file_name_with_path: str
    new_idd_file_name_with_path: str
    rep_var_file_name_with_path: str
    program_path: str
    full_file_name: str
    blank: str
    prog_name_conversion: str
    max_name_length: int
    max_alpha_args_found: int
    max_numeric_args_found: int
    max_total_args: int
    auditf: Any
    file_ok: bool
    alphas: List[str]
    numbers: List[float]
    in_args: List[str]
    temp_args: List[str]
    a_or_n: List[bool]
    req_fld: List[bool]
    fld_names: List[str]
    fld_defaults: List[str]
    fld_units: List[str]
    nw_a_or_n: List[bool]
    nw_req_fld: List[bool]
    nw_fld_names: List[str]
    nw_fld_defaults: List[str]
    nw_fld_units: List[str]
    out_args: List[str]
    num_idf_records: int
    idf_records: List[Any]
    comments: List[str]
    cur_comment: int
    object_def: List[Any]
    num_object_defs: int
    not_in_new: List[str]
    num_rep_var_names: int
    old_rep_var_name: List[str]
    new_rep_var_name: List[str]
    new_rep_var_caution: List[str]
    otm_var_caution: List[bool]
    cmtr_var_caution: List[bool]
    cmtr_d_var_caution: List[bool]
    processing_imf_file: bool
    fatal_error: bool
    display_string: callable
    process_input: callable
    get_object_def_in_idd: callable
    get_new_object_def_in_idd: callable
    find_item_in_list: callable
    scan_output_variables_for_replacement: callable
    write_out_idf_lines_as_comments: callable
    check_special_objects: callable
    write_out_idf_lines: callable
    get_num_sections_found: callable
    process_rvi_mvi_files: callable
    close_out: callable
    create_new_name: callable
    write_preprocessor_object: callable
    make_lower_case: callable
    copyfile_fn: callable
    get_new_unit_number: callable
    trim_trail_zeros: callable
    show_message: callable
    show_continue_error: callable
    show_fatal_error: callable
    show_severe_error: callable
    show_warning_error: callable

def set_this_version_variables(state: ExternalState) -> None:
    state.ver_string = 'Conversion 24.2 => 25.1'
    state.version_num = 25.1
    state.s_version_num = '***'
    state.s_version_num_four_chars = '25.1'
    state.idd_file_name_with_path = state.program_path.rstrip() + 'V24-2-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V25-1-0-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 24-2-0 to 25-1-0.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: ExternalState
) -> None:
    ios = 0
    dot_pos = 0
    status = 0
    na = 0
    nn = 0
    cur_args = 0
    dif_lfn = 0
    x_count = 0
    num = 0
    arg = 0
    first_time = True
    units_arg = state.blank
    object_name = state.blank
    del_this = False
    pos = 0
    pos2 = 0
    exit_because_bad_file = False
    still_working = False
    no_diff = False
    check_rvi = False
    no_version = False
    diff_min_fields = False
    written = False
    var_num = 0
    cur_var = 0
    arg_file_being_done = False
    latest_version = False
    local_file_extension = ' '
    wild_match = False
    conn_comp = False
    conn_comp_ctrl = False
    file_exist = False
    created_output_name = state.blank
    delete_this_record = []
    c_out_args = 0
    units_field = ''
    err_flag = False
    i = 0
    cur_field = 0
    new_field = 0
    ka_index = 0
    search_num = 0
    alpha_num_i = 0
    save_number = 0.0
    
    tot_run_periods = 0
    run_period_num = 0
    iterate_run_period = 0
    current_run_period_names = []
    potential_run_period_name = ''
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    file_name_path = state.blank
    dif_file = None
    num_alphas = 0
    num_numbers = 0
    nw_num_args = 0
    obj_min_flds = 0
    nw_obj_min_flds = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                state.full_file_name = input()
            else:
                if not arg_file:
                    try:
                        state.full_file_name = input()
                    except EOFError:
                        state.full_file_name = state.blank
                        ios = 1
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = state.blank
                    ios = 1
                
                if state.full_file_name and state.full_file_name[0:1] == '!':
                    state.full_file_name = state.blank
                    continue
            
            units_arg = state.blank
            if ios != 0:
                state.full_file_name = state.blank
            
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name != state.blank:
                state.display_string(f'Processing IDF -- {state.full_file_name}')
                state.show_warning_error(f' Processing IDF -- {state.full_file_name}', state.auditf)
                
                dot_pos = state.full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = state.full_file_name[0:dot_pos]
                    local_file_extension = state.make_lower_case(state.full_file_name[dot_pos+1:])
                else:
                    file_name_path = state.full_file_name
                    print(' assuming file extension of .idf')
                    state.show_warning_error(' ..assuming file extension of .idf', state.auditf)
                    state.full_file_name = state.full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = state.get_new_unit_number()
                state.file_ok = os.path.exists(state.full_file_name)
                
                if not state.file_ok:
                    print(f'File not found={state.full_file_name}')
                    state.show_warning_error(f'File not found={state.full_file_name}', state.auditf)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file = open(f'{file_name_path}.{local_file_extension}dif', 'w')
                    else:
                        dif_file = open(f'{file_name_path}.{local_file_extension}new', 'w')
                    
                    if local_file_extension == 'imf':
                        state.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    state.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, state.full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    delete_this_record = [False] * state.num_idf_records
                    
                    state.alphas = [state.blank] * state.max_alpha_args_found
                    state.numbers = [0.0] * state.max_numeric_args_found
                    state.in_args = [state.blank] * state.max_total_args
                    state.temp_args = [state.blank] * state.max_total_args
                    state.a_or_n = [False] * state.max_total_args
                    state.req_fld = [False] * state.max_total_args
                    state.fld_names = [state.blank] * state.max_total_args
                    state.fld_defaults = [state.blank] * state.max_total_args
                    state.fld_units = [state.blank] * state.max_total_args
                    state.nw_a_or_n = [False] * state.max_total_args
                    state.nw_req_fld = [False] * state.max_total_args
                    state.nw_fld_names = [state.blank] * state.max_total_args
                    state.nw_fld_defaults = [state.blank] * state.max_total_args
                    state.nw_fld_units = [state.blank] * state.max_total_args
                    state.out_args = [state.blank] * state.max_total_args
                    
                    no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num - 1]['name'].upper() == 'VERSION':
                            no_version = False
                            break
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num - 1]:
                            dif_file.write(f"! Deleting: {state.idf_records[num - 1]['name']}=\"{state.idf_records[num - 1]['alphas'][0] if state.idf_records[num - 1]['alphas'] else ''}\".\\n")
                    
                    state.display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num - 1]:
                            continue
                        
                        commt_s = state.idf_records[num - 1].get('commt_s', 0)
                        commt_e = state.idf_records[num - 1].get('commt_e', 0)
                        for x_count in range(commt_s + 1, commt_e + 1):
                            dif_file.write(f"{state.comments[x_count - 1]}\n")
                            if x_count == commt_e:
                                dif_file.write('\n')
                        
                        if no_version and num == 1:
                            state.get_new_object_def_in_idd('VERSION', nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                            state.out_args[0] = state.s_version_num_four_chars
                            cur_args = 1
                            state.show_warning_error(f'No version found in file, defaulting to {state.s_version_num_four_chars}', state.auditf)
                            state.write_out_idf_lines_as_comments(dif_file, 'Version', cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                        
                        object_name = state.idf_records[num - 1]['name']
                        
                        if state.find_item_in_list(object_name, [d['name'] for d in state.object_def], state.num_object_defs) != 0:
                            state.get_object_def_in_idd(object_name, num_alphas, state.a_or_n, state.req_fld, obj_min_flds, state.fld_names, state.fld_defaults, state.fld_units)
                            num_alphas = state.idf_records[num - 1]['num_alphas']
                            num_numbers = state.idf_records[num - 1]['num_numbers']
                            
                            for i in range(0, num_alphas):
                                state.alphas[i] = state.idf_records[num - 1]['alphas'][i] if i < len(state.idf_records[num - 1]['alphas']) else state.blank
                            
                            for i in range(0, num_numbers):
                                state.numbers[i] = state.idf_records[num - 1]['numbers'][i] if i < len(state.idf_records[num - 1]['numbers']) else 0.0
                            
                            cur_args = num_alphas + num_numbers
                            state.in_args = [state.blank] * state.max_total_args
                            state.out_args = [state.blank] * state.max_total_args
                            state.temp_args = [state.blank] * state.max_total_args
                            na = 0
                            nn = 0
                            
                            for arg in range(0, cur_args):
                                if state.a_or_n[arg]:
                                    na += 1
                                    state.in_args[arg] = state.alphas[na - 1]
                                else:
                                    nn += 1
                                    state.in_args[arg] = str(state.numbers[nn - 1])
                        else:
                            state.show_warning_error(f'Object="{object_name}" does not seem to be on the "old" IDD.', state.auditf)
                            state.show_warning_error('... will be listed as comments (no field names) on the new output file.', state.auditf)
                            state.show_warning_error('... Alpha fields will be listed first, then numerics.', state.auditf)
                            
                            num_alphas = state.idf_records[num - 1]['num_alphas']
                            num_numbers = state.idf_records[num - 1]['num_numbers']
                            
                            for i in range(0, num_alphas):
                                state.alphas[i] = state.idf_records[num - 1]['alphas'][i] if i < len(state.idf_records[num - 1]['alphas']) else state.blank
                            
                            for i in range(0, num_numbers):
                                state.numbers[i] = state.idf_records[num - 1]['numbers'][i] if i < len(state.idf_records[num - 1]['numbers']) else 0.0
                            
                            for arg in range(0, num_alphas):
                                state.out_args[arg] = state.alphas[arg]
                            
                            nn = num_alphas + 1
                            for arg in range(0, num_numbers):
                                state.out_args[nn - 1] = str(state.numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            state.nw_fld_names = [state.blank] * state.max_total_args
                            state.nw_fld_units = [state.blank] * state.max_total_args
                            state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) == 0:
                            state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                            
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not False:
                            obj_name_upper = object_name.upper()
                            
                            if obj_name_upper == 'VERSION':
                                if state.in_args[0][0:4] == state.s_version_num_four_chars and arg_file:
                                    state.show_warning_error('File is already at latest version.  No new diff file made.', state.auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                state.out_args[0] = state.s_version_num_four_chars
                                no_diff = False
                            
                            elif obj_name_upper == 'OUTPUT:VARIABLE':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                if state.out_args[0] == state.blank:
                                    state.out_args[0] = '*'
                                    no_diff = False
                                
                                state.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_file, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                state.scan_output_variables_for_replacement(1, del_this, check_rvi, no_diff, object_name, dif_file, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                if state.out_args[0] == state.blank:
                                    state.out_args[0] = '*'
                                    no_diff = False
                                
                                state.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_file, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                if state.out_args[0] == state.blank:
                                    state.out_args[0] = '*'
                                    no_diff = False
                                
                                state.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_file, False, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                state.scan_output_variables_for_replacement(3, del_this, check_rvi, no_diff, object_name, dif_file, False, False, False, cur_args, written, True)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                no_diff = True
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                
                                cur_var = 3
                                var_idx = 3
                                while var_idx <= cur_args:
                                    uc_rep_var_name = state.in_args[var_idx - 1].upper()
                                    state.out_args[cur_var - 1] = state.in_args[var_idx - 1]
                                    state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        state.out_args[cur_var - 1] = state.in_args[var_idx - 1][0:pos]
                                        state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    del_this = False
                                    for arg_idx in range(0, state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg_idx].upper()
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        
                                        if pos > 0 or pos != 0:
                                            continue
                                        
                                        if pos == 0:
                                            if state.new_rep_var_name[arg_idx] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx] != state.blank and not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    if not state.otm_var_caution[arg_idx]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Output Table Monthly (old)="{state.old_rep_var_name[arg_idx]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg_idx]}" has the following caution "{state.new_rep_var_caution[arg_idx]}".')
                                                        dif_file.write(' \n')
                                                        state.otm_var_caution[arg_idx] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg_idx + 1 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 1]:
                                                if not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1]
                                                    else:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg_idx + 1] != state.blank:
                                                        if not state.otm_var_caution[arg_idx + 1]:
                                                            state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Output Table Monthly (old)="{state.old_rep_var_name[arg_idx]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg_idx + 1]}" has the following caution "{state.new_rep_var_caution[arg_idx + 1]}".')
                                                            dif_file.write(' \n')
                                                            state.otm_var_caution[arg_idx + 1] = True
                                                    
                                                    state.out_args[cur_var] = state.in_args[var_idx]
                                                    no_diff = False
                                            
                                            if arg_idx + 2 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx + 2] != state.blank:
                                                    if not state.otm_var_caution[arg_idx + 2]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Output Table Monthly (old)="{state.old_rep_var_name[arg_idx]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg_idx + 2]}" has the following caution "{state.new_rep_var_caution[arg_idx + 2]}".')
                                                        dif_file.write(' \n')
                                                        state.otm_var_caution[arg_idx + 2] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var_idx += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_name_upper == 'METER:CUSTOM':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                cur_var = 4
                                var_idx = 4
                                while var_idx <= cur_args:
                                    uc_rep_var_name = state.in_args[var_idx - 1].upper()
                                    state.out_args[cur_var - 1] = state.in_args[var_idx - 1]
                                    state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        state.out_args[cur_var - 1] = state.in_args[var_idx - 1][0:pos]
                                        state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    del_this = False
                                    for arg_idx in range(0, state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg_idx].upper()
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        
                                        if pos > 0 or pos != 0:
                                            continue
                                        
                                        if pos == 0:
                                            if state.new_rep_var_name[arg_idx] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx] != state.blank and not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    if not state.cmtr_var_caution[arg_idx]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg_idx]}" has the following caution "{state.new_rep_var_caution[arg_idx]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_var_caution[arg_idx] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg_idx + 1 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 1]:
                                                if not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1]
                                                    else:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg_idx + 1] != state.blank and not (state.new_rep_var_caution[arg_idx + 1][0:6] == 'Forkeq'):
                                                        if not state.cmtr_var_caution[arg_idx + 1]:
                                                            state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg_idx + 1]}" has the following caution "{state.new_rep_var_caution[arg_idx + 1]}".')
                                                            dif_file.write(' \n')
                                                            state.cmtr_var_caution[arg_idx + 1] = True
                                                    
                                                    state.out_args[cur_var] = state.in_args[var_idx]
                                                    no_diff = False
                                            
                                            if arg_idx + 2 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx + 2] != state.blank:
                                                    if not state.cmtr_var_caution[arg_idx + 2]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg_idx + 2]}" has the following caution "{state.new_rep_var_caution[arg_idx + 2]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_var_caution[arg_idx + 2] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var_idx += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper == 'METER:CUSTOMDECREMENT':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                cur_var = 4
                                var_idx = 4
                                while var_idx <= cur_args:
                                    uc_rep_var_name = state.in_args[var_idx - 1].upper()
                                    state.out_args[cur_var - 1] = state.in_args[var_idx - 1]
                                    state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        state.out_args[cur_var - 1] = state.in_args[var_idx - 1][0:pos]
                                        state.out_args[cur_var] = state.in_args[var_idx]
                                    
                                    del_this = False
                                    for arg_idx in range(0, state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg_idx].upper()
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        
                                        if pos > 0 or pos != 0:
                                            continue
                                        
                                        if pos == 0:
                                            if state.new_rep_var_name[arg_idx] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx] != state.blank and not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    if not state.cmtr_d_var_caution[arg_idx]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg_idx]}" has the following caution "{state.new_rep_var_caution[arg_idx]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_d_var_caution[arg_idx] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg_idx + 1 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 1]:
                                                if not (state.new_rep_var_caution[arg_idx][0:6] == 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1]
                                                    else:
                                                        state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 1] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg_idx + 1] != state.blank and not (state.new_rep_var_caution[arg_idx + 1][0:6] == 'Forkeq'):
                                                        if not state.cmtr_d_var_caution[arg_idx + 1]:
                                                            state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Decrement Meter (new)="{state.new_rep_var_name[arg_idx + 1]}" has the following caution "{state.new_rep_var_caution[arg_idx + 1]}".')
                                                            dif_file.write(' \n')
                                                            state.cmtr_d_var_caution[arg_idx + 1] = True
                                                    
                                                    state.out_args[cur_var] = state.in_args[var_idx]
                                                    no_diff = False
                                            
                                            if arg_idx + 2 < state.num_rep_var_names and state.old_rep_var_name[arg_idx] == state.old_rep_var_name[arg_idx + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2]
                                                else:
                                                    state.out_args[cur_var - 1] = state.new_rep_var_name[arg_idx + 2] + state.out_args[cur_var - 1][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg_idx + 2] != state.blank:
                                                    if not state.cmtr_d_var_caution[arg_idx + 2]:
                                                        state.write_preprocessor_object(dif_file, state.prog_name_conversion, 'Warning', f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg_idx]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg_idx + 2]}" has the following caution "{state.new_rep_var_caution[arg_idx + 2]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_d_var_caution[arg_idx + 2] = True
                                                
                                                state.out_args[cur_var] = state.in_args[var_idx]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var_idx += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper in ('DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF'):
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                state.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_file, False, True, False, cur_args, written, False)
                            
                            elif obj_name_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                for i in range(0, cur_args):
                                    state.out_args[i] = state.in_args[i]
                                no_diff = True
                                
                                state.scan_output_variables_for_replacement(6, del_this, check_rvi, no_diff, object_name, dif_file, False, True, False, cur_args, written, False)
                                state.scan_output_variables_for_replacement(12, del_this, check_rvi, no_diff, object_name, dif_file, False, True, False, cur_args, written, False)
                            
                            else:
                                if state.find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    state.show_warning_error(f'Object="{object_name}" is not in the "new" IDD.', state.auditf)
                                    state.show_warning_error('... will be listed as comments on the new output file.', state.auditf)
                                    state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state.in_args, state.fld_names, state.fld_units)
                                    written = True
                                else:
                                    state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                                    for i in range(0, cur_args):
                                        state.out_args[i] = state.in_args[i]
                                    no_diff = True
                        else:
                            state.get_new_object_def_in_idd(state.idf_records[num - 1]['name'], nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                            for i in range(0, cur_args):
                                state.out_args[i] = state.in_args[i]
                        
                        if diff_min_fields and no_diff:
                            state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                            for i in range(0, cur_args):
                                state.out_args[i] = state.in_args[i]
                            no_diff = False
                            
                            for arg in range(cur_args, nw_obj_min_flds):
                                state.out_args[arg] = state.nw_fld_defaults[arg]
                            
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            state.check_special_objects(dif_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units, written)
                        
                        if not written:
                            state.write_out_idf_lines(dif_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    state.display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if state.num_idf_records > 0 and state.idf_records[state.num_idf_records - 1].get('commt_e', 0) != state.cur_comment:
                        for x_count in range(state.idf_records[state.num_idf_records - 1].get('commt_e', 0) + 1, state.cur_comment + 1):
                            dif_file.write(f"{state.comments[x_count - 1]}\n")
                            if x_count == state.idf_records[num - 1].get('commt_e', 0):
                                dif_file.write('\n')
                    
                    if state.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        state.get_new_object_def_in_idd(object_name, nw_num_args, state.nw_a_or_n, state.nw_req_fld, nw_obj_min_flds, state.nw_fld_names, state.nw_fld_defaults, state.nw_fld_units)
                        no_diff = False
                        state.out_args[0] = 'Regular'
                        cur_args = 1
                        state.write_out_idf_lines(dif_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    dif_file.close()
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
                    state.close_out()
                else:
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file[0] = True
            
            state.create_new_name('Reallocate', created_output_name, ' ')
        
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
        state.copyfile_fn(f'{file_name_path}.{arg_idf_extension}', f'{file_name_path}.{arg_idf_extension}old', err_flag)
        state.copyfile_fn(f'{file_name_path}.{arg_idf_extension}new', f'{file_name_path}.{arg_idf_extension}', err_flag)
        
        if os.path.exists(f'{file_name_path}.rvi'):
            state.copyfile_fn(f'{file_name_path}.rvi', f'{file_name_path}.rviold', err_flag)
        
        if os.path.exists(f'{file_name_path}.rvinew'):
            state.copyfile_fn(f'{file_name_path}.rvinew', f'{file_name_path}.rvi', err_flag)
        
        if os.path.exists(f'{file_name_path}.mvi'):
            state.copyfile_fn(f'{file_name_path}.mvi', f'{file_name_path}.mviold', err_flag)
        
        if os.path.exists(f'{file_name_path}.mvinew'):
            state.copyfile_fn(f'{file_name_path}.mvinew', f'{file_name_path}.mvi', err_flag)
