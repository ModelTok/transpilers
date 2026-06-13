from typing import Protocol, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from io import StringIO

# EXTERNAL DEPS (to wire in glue):
# DataStringGlobals: ProgNameConversion, program_path
# DataVCompareGlobals: IDFRecords, Comments, ObjectDef, NumObjectDefs, Alphas, Numbers, InArgs, TempArgs, OutArgs,
#                      AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits,
#                      NotInNew, CurComment, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution,
#                      MakingPretty, ProcessingIMFFile, FatalError, FullFileName, FileNamePath, Auditf, NumIDFRecords,
#                      MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, MaxNameLength, blank, NumRepVarNames, FileOK
# InputProcessor: ProcessInput, GetNewUnitNumber, GetNewObjectDefInIDD, GetObjectDefInIDD
# VCompareGlobalRoutines: ScanOutputVariablesForReplacement, CheckSpecialObjects, WriteOutIDFLinesAsComments, WriteOutIDFLines
# General: TrimTrailZeros, MakeUPPERCase, MakeLowerCase, FindItemInList
# DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# Other: DisplayString, writePreprocessorObject, ProcessRviMviFiles, CloseOut, CreateNewName, copyfile, GetNumSectionsFound


class ExternalState(Protocol):
    """Protocol for external shared state and utilities."""
    
    program_path: str
    full_file_name: str
    file_name_path: str
    audit_file_unit: int
    num_idf_records: int
    idf_records: List[Any]
    comments: List[str]
    object_def: List[Any]
    num_object_defs: int
    alphas: List[str]
    numbers: List[float]
    in_args: List[str]
    temp_args: List[str]
    out_args: List[str]
    aor_n: List[bool]
    req_fld: List[bool]
    fld_names: List[str]
    fld_defaults: List[str]
    fld_units: List[str]
    nw_aor_n: List[bool]
    nw_req_fld: List[bool]
    nw_fld_names: List[str]
    nw_fld_defaults: List[str]
    nw_fld_units: List[str]
    not_in_new: List[str]
    cur_comment: int
    old_rep_var_name: List[str]
    new_rep_var_name: List[str]
    new_rep_var_caution: List[str]
    otm_var_caution: List[bool]
    cmtr_var_caution: List[bool]
    cmtr_d_var_caution: List[bool]
    making_pretty: bool
    processing_imf_file: bool
    fatal_error: bool
    max_alpha_args_found: int
    max_numeric_args_found: int
    max_total_args: int
    max_name_length: int
    blank_str: str
    num_rep_var_names: int
    file_ok: bool
    program_name_conversion: str
    ver_string: str
    version_num: float
    s_version_num: str
    s_version_num_four_chars: str
    idd_file_name_with_path: str
    new_idd_file_name_with_path: str
    rep_var_file_name_with_path: str


def set_this_version_variables(state: ExternalState) -> None:
    """
    Set version-specific variables for conversion from 25.1 to 25.2.
    """
    state.ver_string = 'Conversion 25.1 => 25.2'
    state.version_num = 25.2
    state.s_version_num = '***'
    state.s_version_num_four_chars = '25.2'
    state.idd_file_name_with_path = state.program_path.rstrip() + 'V25-1-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V25-2-0-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 25-1-0 to 25-2-0.csv'


def create_new_idf_using_rules(
    state: ExternalState,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    display_string_fn,
    get_new_unit_number_fn,
    process_input_fn,
    get_new_object_def_idd_fn,
    get_object_def_idd_fn,
    write_out_idf_lines_as_comments_fn,
    scan_output_variables_for_replacement_fn,
    check_special_objects_fn,
    write_out_idf_lines_fn,
    show_warning_error_fn,
    find_item_in_list_fn,
    make_upper_case_fn,
    make_lower_case_fn,
    trim_trail_zeros_fn,
    write_preprocessor_object_fn,
    get_num_sections_found_fn,
    process_rvi_mvi_files_fn,
    close_out_fn,
    create_new_name_fn,
    copyfile_fn,
    show_message_fn,
) -> None:
    """
    Create new IDFs based on conversion rules from version 25.1 to 25.2.
    """
    fmta = "(A)"
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                full_file_name = input()
                state.full_file_name = full_file_name
            else:
                if not arg_file:
                    try:
                        with open(in_lfn, 'r') as f:
                            full_file_name = f.readline().strip()
                            ios = 0
                    except:
                        full_file_name = ''
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ''
                    ios = 1
                
                if full_file_name.startswith('!'):
                    full_file_name = ''
                    continue
            
            units_arg = ''
            if ios != 0:
                full_file_name = ''
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != '':
                state.full_file_name = full_file_name
                display_string_fn('Processing IDF -- ' + full_file_name)
                with open(state.audit_file_unit, 'a') as f:
                    f.write(' Processing IDF -- ' + full_file_name + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case_fn(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    with open(state.audit_file_unit, 'a') as f:
                        f.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                state.file_name_path = file_name_path
                dif_lfn = get_new_unit_number_fn()
                
                import os
                file_ok = os.path.exists(full_file_name)
                state.file_ok = file_ok
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    with open(state.audit_file_unit, 'a') as f:
                        f.write('File not found=' + full_file_name + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        output_filename = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_filename = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        show_warning_error_fn('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.audit_file_unit)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    process_input_fn(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    # Clean up and reallocate arrays
                    state.alphas = [state.blank_str] * state.max_alpha_args_found
                    state.numbers = [0.0] * state.max_numeric_args_found
                    state.in_args = [state.blank_str] * state.max_total_args
                    state.temp_args = [state.blank_str] * state.max_total_args
                    state.aor_n = [False] * state.max_total_args
                    state.req_fld = [False] * state.max_total_args
                    state.fld_names = [state.blank_str] * state.max_total_args
                    state.fld_defaults = [state.blank_str] * state.max_total_args
                    state.fld_units = [state.blank_str] * state.max_total_args
                    state.nw_aor_n = [False] * state.max_total_args
                    state.nw_req_fld = [False] * state.max_total_args
                    state.nw_fld_names = [state.blank_str] * state.max_total_args
                    state.nw_fld_defaults = [state.blank_str] * state.max_total_args
                    state.nw_fld_units = [state.blank_str] * state.max_total_args
                    state.out_args = [state.blank_str] * state.max_total_args
                    delete_this_record = [False] * state.num_idf_records
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case_fn(state.idf_records[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            with open(dif_lfn, 'a') as f:
                                f.write('! Deleting: ' + state.idf_records[num]['Name'] + '="' + state.idf_records[num]['Alphas'][0] + '".\n')
                    
                    display_string_fn('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.idf_records[num]['CommtS'], state.idf_records[num]['CommtE'] + 1):
                            if xcount < len(state.comments):
                                with open(dif_lfn, 'a') as f:
                                    f.write(state.comments[xcount].rstrip() + '\n')
                                if xcount == state.idf_records[num]['CommtE']:
                                    with open(dif_lfn, 'a') as f:
                                        f.write('\n')
                        
                        if no_version and num == 0:
                            nw_num_args = 0
                            nw_aor_n = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            get_new_object_def_idd_fn('VERSION', [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                            state.out_args[0] = state.s_version_num_four_chars
                            cur_args = 1
                            show_warning_error_fn('No version found in file, defaulting to ' + state.s_version_num_four_chars, state.audit_file_unit)
                            write_out_idf_lines_as_comments_fn(dif_lfn, 'Version', cur_args, state.out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = state.idf_records[num]['Name']
                        
                        if find_item_in_list_fn(object_name, [o['Name'] for o in state.object_def], state.num_object_defs) != 0:
                            num_args = 0
                            aor_n = []
                            req_fld = []
                            obj_min_flds = 0
                            fld_names = []
                            fld_defaults = []
                            fld_units = []
                            get_object_def_idd_fn(object_name, [num_args, aor_n, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units])
                            
                            num_alphas = state.idf_records[num]['NumAlphas']
                            num_numbers = state.idf_records[num]['NumNumbers']
                            state.alphas[:num_alphas] = state.idf_records[num]['Alphas'][:num_alphas]
                            state.numbers[:num_numbers] = state.idf_records[num]['Numbers'][:num_numbers]
                            cur_args = num_alphas + num_numbers
                            state.in_args = [state.blank_str] * state.max_total_args
                            state.out_args = [state.blank_str] * state.max_total_args
                            state.temp_args = [state.blank_str] * state.max_total_args
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    state.in_args[arg] = state.alphas[na]
                                    na += 1
                                else:
                                    state.in_args[arg] = str(state.numbers[nn])
                                    nn += 1
                        else:
                            with open(state.audit_file_unit, 'a') as f:
                                f.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                                f.write('... will be listed as comments (no field names) on the new output file.\n')
                                f.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = state.idf_records[num]['NumAlphas']
                            num_numbers = state.idf_records[num]['NumNumbers']
                            state.alphas[:num_alphas] = state.idf_records[num]['Alphas'][:num_alphas]
                            state.numbers[:num_numbers] = state.idf_records[num]['Numbers'][:num_numbers]
                            
                            for arg in range(num_alphas):
                                state.out_args[arg] = state.alphas[arg]
                            
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                state.out_args[nn] = str(state.numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            state.nw_fld_names = [state.blank_str] * state.max_total_args
                            state.nw_fld_units = [state.blank_str] * state.max_total_args
                            write_out_idf_lines_as_comments_fn(dif_lfn, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list_fn(make_upper_case_fn(object_name), state.not_in_new, len(state.not_in_new)) == 0:
                            nw_num_args = 0
                            nw_aor_n = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                            
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.making_pretty:
                            object_name_upper = make_upper_case_fn(state.idf_records[num]['Name'].rstrip())
                            
                            if object_name_upper == 'VERSION':
                                if state.in_args[0][:4] == state.s_version_num_four_chars and arg_file:
                                    show_warning_error_fn('File is already at latest version.  No new diff file made.', state.audit_file_unit)
                                    with open(dif_lfn, 'r') as f:
                                        pass
                                    latest_version = True
                                    break
                                
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[0] = state.s_version_num_four_chars
                                nodiff = False
                            
                            elif object_name_upper == 'AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR:MULTISPEED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[:11] = state.in_args[:11]
                                state.out_args[11] = " "
                                state.out_args[12:cur_args] = state.in_args[12:cur_args]
                            
                            elif object_name_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:COOLING:DX:VARIABLESPEED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:HEATING:DX:VARIABLESPEED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = ''
                                state.out_args[2:cur_args+1] = state.in_args[1:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_name_upper == 'GROUNDHEATEXCHANGER:SYSTEM':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                if cur_args > 10:
                                    nodiff = False
                                    state.out_args[:10] = state.in_args[:10]
                                    state.out_args[10] = ''
                                    state.out_args[11] = ''
                                    state.out_args[12:cur_args+2] = state.in_args[10:cur_args]
                                    cur_args = cur_args + 2
                                else:
                                    nodiff = True
                                    state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif object_name_upper == 'OUTPUT:VARIABLE':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                if state.out_args[0] == state.blank_str:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, True, False, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif object_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(1, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, True, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif object_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                if state.out_args[0] == state.blank_str:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, True, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif object_name_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                if state.out_args[0] == state.blank_str:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif object_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(3, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, False, [cur_args], [written], True)
                                if del_this[0]:
                                    continue
                            
                            elif object_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                nodiff = True
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                cur_var = 3
                                
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = make_upper_case_fn(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = make_upper_case_fn(state.old_rep_var_name[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg] != state.blank_str and not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    if not state.otm_var_caution[arg]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.new_rep_var_name[arg] + '" has the following caution "' + state.new_rep_var_caution[arg] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.otm_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1] != state.blank_str:
                                                        if not state.otm_var_caution[arg + 1]:
                                                            write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                                'Output Table Monthly (old)="' + state.old_rep_var_name[arg] +
                                                                '" conversion to Output Table Monthly (new)="' +
                                                                state.new_rep_var_name[arg + 1] + '" has the following caution "' + state.new_rep_var_caution[arg + 1] + '".')
                                                            with open(dif_lfn, 'a') as f:
                                                                f.write(' \n')
                                                            state.otm_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    nodiff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg + 2] != state.blank_str:
                                                    if not state.otm_var_caution[arg + 2]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.new_rep_var_name[arg + 2] + '" has the following caution "' + state.new_rep_var_caution[arg + 2] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.otm_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                
                                cur_args = cur_var - 1
                            
                            elif object_name_upper == 'METER:CUSTOM':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                cur_var = 4
                                
                                for var in range(4, cur_args, 2):
                                    uc_rep_var_name = make_upper_case_fn(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = make_upper_case_fn(state.old_rep_var_name[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg] != state.blank_str and not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    if not state.cmtr_var_caution[arg]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Custom Meter (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg] + '" has the following caution "' + state.new_rep_var_caution[arg] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.cmtr_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1] != state.blank_str and not (state.new_rep_var_caution[arg + 1][:6] == 'Forkeq'):
                                                        if not state.cmtr_var_caution[arg + 1]:
                                                            write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                                'Custom Meter (old)="' + state.old_rep_var_name[arg] +
                                                                '" conversion to Custom Meter (new)="' +
                                                                state.new_rep_var_name[arg + 1] + '" has the following caution "' + state.new_rep_var_caution[arg + 1] + '".')
                                                            with open(dif_lfn, 'a') as f:
                                                                f.write(' \n')
                                                            state.cmtr_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    nodiff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg + 2] != state.blank_str:
                                                    if not state.cmtr_var_caution[arg + 2]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Custom Meter (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg + 2] + '" has the following caution "' + state.new_rep_var_caution[arg + 2] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.cmtr_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == state.blank_str:
                                        cur_args = cur_args - 1
                                    else:
                                        break
                            
                            elif object_name_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                cur_var = 4
                                
                                for var in range(4, cur_args, 2):
                                    uc_rep_var_name = make_upper_case_fn(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = make_upper_case_fn(state.old_rep_var_name[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg] != state.blank_str and not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    if not state.cmtr_d_var_caution[arg]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg] + '" has the following caution "' + state.new_rep_var_caution[arg] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.cmtr_d_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not (state.new_rep_var_caution[arg][:6] == 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1] != state.blank_str and not (state.new_rep_var_caution[arg + 1][:6] == 'Forkeq'):
                                                        if not state.cmtr_d_var_caution[arg + 1]:
                                                            write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                                'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg] +
                                                                '" conversion to Custom Decrement Meter (new)="' +
                                                                state.new_rep_var_name[arg + 1] + '" has the following caution "' + state.new_rep_var_caution[arg + 1] + '".')
                                                            with open(dif_lfn, 'a') as f:
                                                                f.write(' \n')
                                                            state.cmtr_d_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    nodiff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2] + state.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.new_rep_var_caution[arg + 2] != state.blank_str:
                                                    if not state.cmtr_d_var_caution[arg + 2]:
                                                        write_preprocessor_object_fn(dif_lfn, state.program_name_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg + 2] + '" has the following caution "' + state.new_rep_var_caution[arg + 2] + '".')
                                                        with open(dif_lfn, 'a') as f:
                                                            f.write(' \n')
                                                        state.cmtr_d_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == state.blank_str:
                                        cur_args = cur_args - 1
                                    else:
                                        break
                            
                            elif object_name_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, True, False, [cur_args], [written], False)
                            
                            elif object_name_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                nw_num_args = 0
                                nw_aor_n = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(6, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, True, False, [cur_args], [written], False)
                                
                                del_this = [False]
                                scan_output_variables_for_replacement_fn(12, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, True, False, [cur_args], [written], False)
                            
                            else:
                                if find_item_in_list_fn(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    with open(state.audit_file_unit, 'a') as f:
                                        f.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                        f.write('... will be listed as comments on the new output file.\n')
                                    write_out_idf_lines_as_comments_fn(dif_lfn, object_name, cur_args, state.in_args, state.fld_names, state.fld_units)
                                    written = True
                                else:
                                    nw_num_args = 0
                                    nw_aor_n = []
                                    nw_req_fld = []
                                    nw_obj_min_flds = 0
                                    nw_fld_names = []
                                    nw_fld_defaults = []
                                    nw_fld_units = []
                                    get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                                    state.out_args[:cur_args] = state.in_args[:cur_args]
                                    nodiff = True
                        else:
                            nw_num_args = 0
                            nw_aor_n = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            get_new_object_def_idd_fn(state.idf_records[num]['Name'], [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                            state.out_args[:cur_args] = state.in_args[:cur_args]
                        
                        if diff_min_fields and nodiff:
                            nw_num_args = 0
                            nw_aor_n = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                            state.out_args[:cur_args] = state.in_args[:cur_args]
                            nodiff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                state.out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects_fn(dif_lfn, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units, [written])
                        
                        if not written:
                            write_out_idf_lines_fn(dif_lfn, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    display_string_fn('Processing IDF -- Processing idf objects complete.')
                    if state.idf_records[state.num_idf_records - 1]['CommtE'] != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records - 1]['CommtE'] + 1, state.cur_comment + 1):
                            if xcount < len(state.comments):
                                with open(dif_lfn, 'a') as f:
                                    f.write(state.comments[xcount].rstrip() + '\n')
                                if xcount == state.idf_records[state.num_idf_records - 1]['CommtE']:
                                    with open(dif_lfn, 'a') as f:
                                        f.write('\n')
                    
                    if get_num_sections_found_fn('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args = 0
                        nw_aor_n = []
                        nw_req_fld = []
                        nw_obj_min_flds = 0
                        nw_fld_names = []
                        nw_fld_defaults = []
                        nw_fld_units = []
                        get_new_object_def_idd_fn(object_name, [nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units])
                        nodiff = False
                        state.out_args[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines_fn(dif_lfn, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    import os
                    rvi_file = state.file_name_path + '.rvi'
                    file_exist = os.path.exists(rvi_file)
                    
                    with open(dif_lfn, 'r') as f:
                        pass
                    
                    process_rvi_mvi_files_fn(state.file_name_path, 'rvi')
                    process_rvi_mvi_files_fn(state.file_name_path, 'mvi')
                    close_out_fn()
                else:
                    process_rvi_mvi_files_fn(state.file_name_path, 'rvi')
                    process_rvi_mvi_files_fn(state.file_name_path, 'mvi')
            else:
                end_of_file[0] = True
            
            created_output_name = ''
            create_new_name_fn('Reallocate', [created_output_name], ' ')
        
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
        err_flag = [False]
        copyfile_fn(state.file_name_path + '.' + arg_idf_extension, state.file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        copyfile_fn(state.file_name_path + '.' + arg_idf_extension + 'new', state.file_name_path + '.' + arg_idf_extension, err_flag)
        
        import os
        rvi_file = state.file_name_path + '.rvi'
        if os.path.exists(rvi_file):
            copyfile_fn(rvi_file, state.file_name_path + '.rviold', err_flag)
        
        rvi_new_file = state.file_name_path + '.rvinew'
        if os.path.exists(rvi_new_file):
            copyfile_fn(rvi_new_file, state.file_name_path + '.rvi', err_flag)
        
        mvi_file = state.file_name_path + '.mvi'
        if os.path.exists(mvi_file):
            copyfile_fn(mvi_file, state.file_name_path + '.mviold', err_flag)
        
        mvi_new_file = state.file_name_path + '.mvinew'
        if os.path.exists(mvi_new_file):
            copyfile_fn(mvi_new_file, state.file_name_path + '.mvi', err_flag)
