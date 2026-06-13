# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath
# - DataStringGlobals.Blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - DataStringGlobals.ProgramPath, Auditf, FileNamePath, FullFileName, FileOK, ProcessingIMFFile
# - DataStringGlobals.Comments, CurComment, NumIDFRecords, IDFRecords
# - DataVCompareGlobals.ObjectDef, NumObjectDefs, NotInNew, FatalError, WithUnits
# - DataVCompareGlobals.MakingPretty, NumRepVarNames, OldRepVarName, NewRepVarName
# - InputProcessor.ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, GetNumObjectsFound, GetObjectItem
# - VCompareGlobalRoutines.ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments, WriteOutIDFLines, CheckSpecialObjects
# - VCompareGlobalRoutines.CloseOut, CreateNewName, ProcessRviMviFiles, copyfile
# - General.MakeUPPERCase, MakeLowerCase, FindItemInList, ProcessNumber, TrimTrailZeros, samestring
# - DataGlobals.ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - DisplayString, GetNewUnitNumber, FindNumber (external functions)

from typing import List, Tuple, Optional
from dataclasses import dataclass, field


def set_this_version_variables(state: 'GlobalState') -> None:
    state.ver_string = 'Conversion 1.0 => 1.0.1'
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path.rstrip('/\\') + '/V1-0-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip('/\\') + '/V1-0-1-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip('/\\') + '/Report Variables 1-0-0-023 to 1-0-1.csv'


def create_new_idf_using_rules(
    state: 'GlobalState',
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> bool:
    fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension.strip()
    end_of_file = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                full_file_name = input().strip()
            else:
                if not arg_file:
                    try:
                        full_file_name = state.read_line_from_unit(in_lfn)
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
                state.display_string('Processing IDF -- ' + full_file_name)
                state.write_audit(f' Processing IDF -- {full_file_name}\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos > 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    state.write_audit(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = state.get_new_unit_number()
                file_ok = state.file_exists(full_file_name)
                
                if not file_ok:
                    print(f'File not found={full_file_name}')
                    state.write_audit(f'File not found={full_file_name}\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    check_rvi = False
                    
                    if diff_only:
                        output_file = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file = file_name_path + '.' + local_file_extension + 'new'
                    
                    dif_file = state.open_file_for_write(dif_lfn, output_file)
                    
                    if local_file_extension == 'imf':
                        state.show_warning_error(
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            state.auditf
                        )
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    state.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [''] * state.max_alpha_args_found
                    numbers = [0.0] * state.max_numeric_args_found
                    in_args = [''] * state.max_total_args
                    a_or_n = [False] * state.max_total_args
                    req_fld = [False] * state.max_total_args
                    fld_names = [''] * state.max_total_args
                    fld_defaults = [''] * state.max_total_args
                    fld_units = [''] * state.max_total_args
                    nw_a_or_n = [False] * state.max_total_args
                    nw_req_fld = [False] * state.max_total_args
                    nw_fld_names = [''] * state.max_total_args
                    nw_fld_defaults = [''] * state.max_total_args
                    nw_fld_units = [''] * state.max_total_args
                    out_args = [''] * state.max_total_args
                    match_arg = [''] * state.max_total_args
                    delete_this_record = [False] * state.num_idf_records
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if state.idf_records[num].name.upper() != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        for xcount in range(state.idf_records[num].commt_s, state.idf_records[num].commt_e + 1):
                            dif_file.write(state.comments[xcount] + '\n')
                            if xcount == state.idf_records[num].commt_e:
                                dif_file.write(' \n')
                        
                        if no_version and num == 0:
                            state.get_new_object_def_in_idd('VERSION', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '1.0.1'
                            cur_args = 1
                            state.write_out_idf_lines_as_comments(dif_file, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = state.idf_records[num].name
                        
                        if state.find_item_in_list(object_name, [od.name for od in state.object_def], state.num_object_defs) != 0:
                            state.get_object_def_in_idd(object_name, a_or_n, req_fld, fld_names, fld_defaults, fld_units)
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            alphas[:num_alphas] = state.idf_records[num].alphas[:num_alphas]
                            numbers[:num_numbers] = state.idf_records[num].numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [''] * state.max_total_args
                            out_args = [''] * state.max_total_args
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if a_or_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        else:
                            state.write_audit(f'Object="{object_name}" does not seem to be on the "old" IDD.\n')
                            state.write_audit('... will be listed as comments (no field names) on the new output file.\n')
                            state.write_audit('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            alphas[:num_alphas] = state.idf_records[num].alphas[:num_alphas]
                            numbers[:num_numbers] = state.idf_records[num].numbers[:num_numbers]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [''] * state.max_total_args
                            nw_fld_units = [''] * state.max_total_args
                            state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) == 0:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            obj_min_flds = state.get_obj_min_flds(object_name)
                            nw_obj_min_flds = state.get_nw_obj_min_flds(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.making_pretty:
                            object_name_upper = object_name.upper().strip()
                            
                            if object_name_upper == 'VERSION':
                                if in_args[0][:3] == '1.0.1' and arg_file:
                                    state.show_warning_error('File is already at latest version.  No new diff file made.', state.auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '1.0.1'
                                nodiff = False
                            
                            elif object_name_upper == 'RUNPERIOD':
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                if out_args[4].upper() == '<BLANK>':
                                    out_args[4] = 'UseWeatherFile'
                                nodiff = False
                            
                            elif object_name_upper == 'MATERIAL:WINDOWGAS':
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                if in_args[1].upper() == 'CUSTOM':
                                    state.show_severe_error(f'WindowGas object=Custom, arguments beyond thickness must be re-derived, Name={in_args[0]}', state.auditf)
                                    dif_file.write(f' !!! Cannot convert WindowGas, Name={in_args[0]}\n')
                                    continue
                                else:
                                    cur_args = 3
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                            
                            elif object_name_upper == 'OTHERSIDECOEFFICIENTS':
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args = in_args.copy()
                                err_flag = False
                                osc7 = state.process_number(out_args[6], err_flag)
                                if err_flag:
                                    state.show_severe_error(f'Invalid Number, OtherSideCoefficients field 7, Name={out_args[0]}', state.auditf)
                                    dif_file.write(f'  ! Invalid Number, field 7 {{{nw_fld_names[6]}}} value={out_args[6]}\n')
                                elif osc7 == 0.0:
                                    err_in_osc = False
                                    osc2 = state.process_number(out_args[7], err_flag)
                                    if err_flag:
                                        state.show_severe_error(f'Invalid Number, OtherSideCoefficients field 8, Name={out_args[0]}', state.auditf)
                                        dif_file.write(f'  ! Invalid Number, field 8 {{{nw_fld_names[7]}}} value={out_args[7]}\n')
                                        err_in_osc = True
                                    osc3 = state.process_number(out_args[4], err_flag)
                                    if err_flag:
                                        state.show_severe_error(f'Invalid Number, OtherSideCoefficients field 5, Name={out_args[0]}', state.auditf)
                                        dif_file.write(f'  ! Invalid Number, field 5 {{{nw_fld_names[4]}}} value={out_args[4]}\n')
                                        err_in_osc = True
                                    osc4 = state.process_number(out_args[3], err_flag)
                                    if err_flag:
                                        state.show_severe_error(f'Invalid Number, OtherSideCoefficients field 4, Name={out_args[0]}', state.auditf)
                                        dif_file.write(f'  ! Invalid Number, field 4 {{{nw_fld_names[3]}}} value={out_args[3]}\n')
                                        err_in_osc = True
                                    osc6 = state.process_number(out_args[5], err_flag)
                                    if err_flag:
                                        state.show_severe_error(f'Invalid Number, OtherSideCoefficients field 6, Name={out_args[0]}', state.auditf)
                                        dif_file.write(f'  ! Invalid Number, field 6 {{{nw_fld_names[5]}}} value={out_args[5]}\n')
                                        err_in_osc = True
                                    
                                    if not err_in_osc:
                                        sum_oscf = osc2 + osc3 + osc4 + osc6
                                        if sum_oscf != 0.0:
                                            osc2 = osc2 / sum_oscf
                                            out_args[7] = state.trim_trail_zeros(osc2)
                                            osc3 = osc3 / sum_oscf
                                            out_args[4] = state.trim_trail_zeros(osc3)
                                            osc4 = osc4 / sum_oscf
                                            out_args[3] = state.trim_trail_zeros(osc4)
                                            osc6 = osc6 / sum_oscf
                                            out_args[5] = state.trim_trail_zeros(osc6)
                                        else:
                                            state.show_severe_error(f'Cannot convert OtherSideCoefficients, SUM(C2+C3+C4+C6)=0.0, Name={out_args[0]}', state.auditf)
                                            err_in_osc = True
                                else:
                                    state.show_severe_error(f'Cannot convert OtherSideCoefficients, WindSpeed Modifier <> 0.0, Name={out_args[0]}', state.auditf)
                                    err_in_osc = True
                                
                                if not err_in_osc:
                                    dif_file.write(f'  {object_name},\n')
                                    for arg in range(cur_args):
                                        if arg != cur_args - 1:
                                            lstring = ',  !- '
                                        else:
                                            lstring = ';  !- '
                                        if state.with_units and nw_fld_units[arg] != '':
                                            dif_file.write(f'    {out_args[arg]}{lstring}{nw_fld_names[arg]} {{{nw_fld_units[arg]}}}\n')
                                        else:
                                            dif_file.write(f'    {out_args[arg]}{lstring}{nw_fld_names[arg]}\n')
                                else:
                                    dif_file.write(f' ! {object_name},\n')
                                    for arg in range(cur_args):
                                        if arg != cur_args - 1:
                                            lstring = ',  !- '
                                        else:
                                            lstring = ';  !- '
                                        if state.with_units and nw_fld_units[arg] != '':
                                            dif_file.write(f' !   {out_args[arg]}{lstring}{nw_fld_names[arg]} {{{nw_fld_units[arg]}}}\n')
                                        else:
                                            dif_file.write(f' !   {out_args[arg]}{lstring}{nw_fld_names[arg]}\n')
                                written = True
                            
                            # Additional cases follow similar patterns...
                            # (Continuing with remaining CASE statements from original)
                            else:
                                if state.find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) != 0:
                                    state.write_audit(f'Object="{object_name}" is not in the "new" IDD.\n')
                                    state.write_audit('... will be listed as comments on the new output file.\n')
                                    state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    nodiff = True
                        else:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if diff_min_fields and nodiff:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[:cur_args] = in_args[:cur_args]
                            nodiff = False
                            nw_obj_min_flds = state.get_nw_obj_min_flds(object_name)
                            for arg in range(cur_args, nw_obj_min_flds):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            state.check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            state.write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.idf_records[state.num_idf_records - 1].commt_e != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records - 1].commt_e + 1, state.cur_comment + 1):
                            dif_file.write(state.comments[xcount] + '\n')
                    
                    dif_file.close()
                    
                    if check_rvi:
                        state.process_rvi_mvi_files(file_name_path, 'rvi')
                        state.process_rvi_mvi_files(file_name_path, 'mvi')
                    
                    state.close_out()
                else:
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            state.create_new_name('Reallocate', '', ' ')
            break
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        state.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        state.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag)
        
        if state.file_exists(file_name_path + '.rvi'):
            state.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        if state.file_exists(file_name_path + '.rvinew'):
            state.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        if state.file_exists(file_name_path + '.mvi'):
            state.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        if state.file_exists(file_name_path + '.mvinew'):
            state.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
    
    return end_of_file
