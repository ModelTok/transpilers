# EXTERNAL DEPS (to wire in glue):
# From DataStringGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath, ProgNameConversion, blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# From DataVCompareGlobals: FullFileName, FileNamePath, Auditf, IDFRecords, NumIDFRecords, FatalError, ObjectDef, NumObjectDefs, NumAlphas, NumNumbers, Comments, CurComment, MakingPretty, NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, ProcessingIMFFile
# From InputProcessor: ProcessInput
# From VCompareGlobalRoutines: GetObjectDefInIDD, GetNewObjectDefInIDD
# From DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# From General: ScanOutputVariablesForReplacement, CheckSpecialObjects, GetNumSectionsFound, ProcessRviMviFiles, CloseOut, CreateNewName, WriteOutIDFLines, WriteOutIDFLinesAsComments, writePreprocessorObject, DisplayString, copyfile
# External functions: GetNewUnitNumber, TrimTrailZeros, FindItemInList, MakeUPPERCase, MakeLowerCase, SameString

from typing import Protocol, List, Any, Tuple

class ExternalState(Protocol):
    def get_ver_string(self) -> str: ...
    def set_ver_string(self, val: str) -> None: ...
    def get_version_num(self) -> float: ...
    def set_version_num(self, val: float) -> None: ...
    def get_idd_file_name_with_path(self) -> str: ...
    def set_idd_file_name_with_path(self, val: str) -> None: ...
    def get_new_idd_file_name_with_path(self) -> str: ...
    def set_new_idd_file_name_with_path(self, val: str) -> None: ...
    def get_rep_var_file_name_with_path(self) -> str: ...
    def set_rep_var_file_name_with_path(self, val: str) -> None: ...
    def get_program_path(self) -> str: ...
    def get_blank(self) -> str: ...
    def get_max_name_length(self) -> int: ...
    def get_max_alpha_args_found(self) -> int: ...
    def get_max_numeric_args_found(self) -> int: ...
    def get_max_total_args(self) -> int: ...
    def get_full_file_name(self) -> str: ...
    def set_full_file_name(self, val: str) -> None: ...
    def get_file_name_path(self) -> str: ...
    def set_file_name_path(self, val: str) -> None: ...
    def get_auditf(self) -> int: ...
    def get_idf_records(self) -> List[Any]: ...
    def get_num_idf_records(self) -> int: ...
    def get_fatal_error(self) -> bool: ...
    def get_object_def(self) -> List[Any]: ...
    def get_num_object_defs(self) -> int: ...
    def set_num_alphas(self, val: int) -> None: ...
    def set_num_numbers(self, val: int) -> None: ...
    def get_comments(self) -> List[str]: ...
    def get_cur_comment(self) -> int: ...
    def get_making_pretty(self) -> bool: ...
    def get_not_in_new(self) -> List[str]: ...
    def get_old_rep_var_name(self) -> List[str]: ...
    def get_new_rep_var_name(self) -> List[str]: ...
    def get_new_rep_var_caution(self) -> List[str]: ...
    def get_num_rep_var_names(self) -> int: ...
    def get_otm_var_caution(self) -> List[bool]: ...
    def get_cmtr_var_caution(self) -> List[bool]: ...
    def get_cmtr_d_var_caution(self) -> List[bool]: ...
    def set_processing_imf_file(self, val: bool) -> None: ...

def set_this_version_variables(state: ExternalState) -> None:
    state.set_ver_string('Conversion 8.0 => 8.1')
    state.set_version_num(8.1)
    program_path = state.get_program_path()
    state.set_idd_file_name_with_path(program_path.rstrip() + 'V8-0-0-Energy+.idd')
    state.set_new_idd_file_name_with_path(program_path.rstrip() + 'V8-1-0-Energy+.idd')
    state.set_rep_var_file_name_with_path(program_path.rstrip() + 'Report Variables 8-0-0-007 to 8-1-0.csv')

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: ExternalState,
    get_new_unit_number: Any,
    trim_trail_zeros: Any,
    find_item_in_list: Any,
    make_uppercase: Any,
    make_lowercase: Any,
    same_string: Any,
    scan_output_variables_for_replacement: Any,
    get_object_def_in_idd: Any,
    get_new_object_def_in_idd: Any,
    display_string: Any,
    write_preprocessor_object: Any,
    process_input: Any,
    write_out_idf_lines_as_comments: Any,
    write_out_idf_lines: Any,
    check_special_objects: Any,
    get_num_sections_found: Any,
    process_rvi_mvi_files: Any,
    close_out: Any,
    create_new_name: Any,
    copyfile: Any,
    show_warning_error: Any,
) -> None:
    first_time = True
    blank = state.get_blank()
    max_name_length = state.get_max_name_length()
    max_total_args = state.get_max_total_args()

    if first_time:
        first_time = False

    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = ' ' * 10
    local_file_extension = arg_idf_extension if len(arg_idf_extension) <= 10 else arg_idf_extension[:10]
    end_of_file[0] = False
    ios = 0

    while still_working:
        exit_because_bad_file = False

        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        line = open(in_lfn).readline()
                        full_file_name = line.strip()
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = blank
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

            units_arg = blank
            if ios != 0:
                full_file_name = blank
            full_file_name = full_file_name.lstrip()

            if full_file_name != blank:
                display_string('Processing IDF -- ' + full_file_name)
                auditf = state.get_auditf()
                with open(auditf, 'a') as f:
                    f.write(' Processing IDF -- ' + full_file_name + '\n')

                dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lowercase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    with open(auditf, 'a') as f:
                        f.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'

                state.set_full_file_name(full_file_name)
                state.set_file_name_path(file_name_path)

                dif_lfn = get_new_unit_number()
                import os
                file_ok = os.path.exists(full_file_name)

                if not file_ok:
                    print('File not found=' + full_file_name)
                    with open(auditf, 'a') as f:
                        f.write('File not found=' + full_file_name + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break

                if local_file_extension in ['idf', 'imf']:
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False

                    if diff_only:
                        output_file = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file = file_name_path + '.' + local_file_extension + 'new'

                    dif_f = open(dif_lfn, 'w')

                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', auditf)
                        state.set_processing_imf_file(True)
                    else:
                        state.set_processing_imf_file(False)

                    idd_file = state.get_idd_file_name_with_path()
                    new_idd_file = state.get_new_idd_file_name_with_path()
                    process_input(idd_file, new_idd_file, full_file_name)

                    if state.get_fatal_error():
                        exit_because_bad_file = True
                        break

                    alphas = [''] * state.get_max_alpha_args_found()
                    numbers = [0.0] * state.get_max_numeric_args_found()
                    in_args = [''] * max_total_args
                    aorn = [False] * max_total_args
                    req_fld = [False] * max_total_args
                    fld_names = [''] * max_total_args
                    fld_defaults = [''] * max_total_args
                    fld_units = [''] * max_total_args
                    nw_aorn = [False] * max_total_args
                    nw_req_fld = [False] * max_total_args
                    nw_fld_names = [''] * max_total_args
                    nw_fld_defaults = [''] * max_total_args
                    nw_fld_units = [''] * max_total_args
                    out_args = [''] * max_total_args
                    match_arg = [''] * max_total_args
                    delete_this_record = [False] * state.get_num_idf_records()

                    no_version = True
                    idf_records = state.get_idf_records()
                    for num in range(state.get_num_idf_records()):
                        if make_uppercase(idf_records[num].get('Name', '')) != 'VERSION':
                            continue
                        no_version = False
                        break

                    schedule_type_limits_any_number = False
                    for num in range(state.get_num_idf_records()):
                        record_name = idf_records[num].get('Name', '')
                        if not same_string(record_name, 'ScheduleTypeLimits'):
                            continue
                        alphas_list = idf_records[num].get('Alphas', [])
                        if len(alphas_list) > 0 and same_string(alphas_list[0], 'Any Number'):
                            schedule_type_limits_any_number = True
                            break

                    for num in range(state.get_num_idf_records()):
                        if delete_this_record[num]:
                            record_name = idf_records[num].get('Name', '')
                            alphas_list = idf_records[num].get('Alphas', [])
                            first_alpha = alphas_list[0] if len(alphas_list) > 0 else ''
                            dif_f.write('! Deleting: ' + record_name + '="' + first_alpha + '".\n')

                    for num in range(state.get_num_idf_records()):
                        if delete_this_record[num]:
                            continue

                        record = idf_records[num]
                        cmmt_s = record.get('CommtS', 0)
                        cmmt_e = record.get('CommtE', 0)
                        comments = state.get_comments()
                        for xcount in range(cmmt_s, cmmt_e):
                            dif_f.write(comments[xcount] + '\n')
                            if xcount == cmmt_e - 1:
                                dif_f.write(' \n')

                        if no_version and num == 0:
                            nw_num_args = 0
                            get_new_object_def_in_idd('VERSION', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '8.0'
                            cur_args = 1
                            write_out_idf_lines_as_comments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)

                        record_name = make_uppercase(record.get('Name', '').strip())
                        
                        if record_name in ['SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA', 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                            continue
                        
                        if record_name == 'WATER HEATER:SIMPLE':
                            dif_f.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            prog_name = 'PrognameConversion'
                            write_preprocessor_object(dif_lfn, prog_name, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted')
                            continue

                        object_name = record.get('Name', '')
                        obj_def = state.get_object_def()
                        if find_item_in_list(object_name, [o.get('Name', '') for o in obj_def], state.get_num_object_defs()) != 0:
                            num_args = 0
                            get_object_def_in_idd(object_name, num_args, aorn, req_fld, [0], fld_names, fld_defaults, fld_units)
                            num_alphas = record.get('NumAlphas', 0)
                            num_numbers = record.get('NumNumbers', 0)
                            state.set_num_alphas(num_alphas)
                            state.set_num_numbers(num_numbers)
                            alphas = record.get('Alphas', [])
                            numbers = record.get('Numbers', [])
                            cur_args = num_alphas + num_numbers
                            in_args = [blank] * max_total_args
                            out_args = [blank] * max_total_args
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        else:
                            with open(auditf, 'a') as f:
                                f.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                                f.write('... will be listed as comments (no field names) on the new output file.\n')
                                f.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = record.get('NumAlphas', 0)
                            num_numbers = record.get('NumNumbers', 0)
                            state.set_num_alphas(num_alphas)
                            state.set_num_numbers(num_numbers)
                            alphas = record.get('Alphas', [])
                            numbers = record.get('Numbers', [])
                            out_args = [blank] * max_total_args
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [blank] * max_total_args
                            nw_fld_units = [blank] * max_total_args
                            write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue

                        nodiff = True
                        diff_min_fields = False
                        written = False

                        if find_item_in_list(make_uppercase(object_name), state.get_not_in_new(), len(state.get_not_in_new())) == 0:
                            nw_num_args = 0
                            get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            if state.get_num_object_defs() != 0:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False

                        if not state.get_making_pretty():
                            record_name_upper = make_uppercase(record.get('Name', '').strip())

                            if record_name_upper == 'VERSION':
                                if in_args[0][:3] == '8.1' and arg_file:
                                    show_warning_error('File is already at latest version.  No new diff file made.', auditf)
                                    dif_f.close()
                                    latest_version = True
                                    break
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '8.1'
                                nodiff = False

                            elif record_name_upper == 'PEOPLE':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                if cur_args > 15:
                                    out_args[15] = 'ClothingInsulationSchedule'
                                    out_args[16] = blank
                                    out_args[17:cur_args+2] = in_args[15:cur_args]
                                    cur_args = cur_args + 2

                            elif record_name_upper == 'COOLINGTOWER:SINGLESPEED':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:8] = in_args[0:8]
                                if same_string(out_args[7], 'autosize'):
                                    out_args[7] = 'autocalculate'
                                out_args[8] = blank
                                out_args[9] = in_args[8]
                                if same_string(out_args[9], 'autosize'):
                                    out_args[9] = 'autocalculate'
                                out_args[10] = blank
                                out_args[11] = in_args[9]
                                out_args[12] = blank
                                out_args[13:15] = in_args[10:12]
                                out_args[15] = blank
                                if cur_args > 12:
                                    out_args[16:cur_args+4] = in_args[12:cur_args]
                                cur_args = cur_args + 4

                            elif record_name_upper == 'COOLINGTOWER:TWOSPEED':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:8] = in_args[0:8]
                                if same_string(out_args[7], 'autosize'):
                                    out_args[7] = 'autocalculate'
                                out_args[8] = blank
                                out_args[9] = in_args[8]
                                if same_string(out_args[9], 'autosize'):
                                    out_args[9] = 'autocalculate'
                                out_args[10] = blank
                                out_args[11] = in_args[9]
                                out_args[12] = blank
                                out_args[13] = in_args[10]
                                if same_string(out_args[13], 'autosize'):
                                    out_args[13] = 'autocalculate'
                                out_args[14] = blank
                                out_args[15] = in_args[11]
                                if same_string(out_args[15], 'autosize'):
                                    out_args[15] = 'autocalculate'
                                out_args[16] = blank
                                out_args[17] = in_args[12]
                                out_args[18] = blank
                                out_args[19:21] = in_args[13:15]
                                out_args[21] = blank
                                out_args[22] = in_args[15]
                                out_args[23] = blank
                                if cur_args > 16:
                                    out_args[24:cur_args+8] = in_args[16:cur_args]
                                cur_args = cur_args + 8

                            elif record_name_upper == 'EVAPORATIVEFLUIDCOOLER:SINGLESPEED':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:8] = in_args[0:8]
                                out_args[8] = blank
                                if cur_args > 8:
                                    out_args[9:cur_args+1] = in_args[8:cur_args]
                                cur_args = cur_args + 1

                            elif record_name_upper == 'EVAPORATIVEFLUIDCOOLER:TWOSPEED':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:6] = in_args[0:6]
                                if same_string(out_args[5], 'autosize'):
                                    out_args[5] = 'autocalculate'
                                out_args[6] = blank
                                out_args[7] = in_args[6]
                                if same_string(out_args[7], 'autosize'):
                                    out_args[7] = 'autocalculate'
                                out_args[8] = blank
                                out_args[9:12] = in_args[7:10]
                                out_args[12] = blank
                                out_args[13:15] = in_args[10:12]
                                out_args[15] = blank
                                out_args[16:18] = in_args[12:14]
                                if same_string(out_args[17], 'autosize'):
                                    out_args[17] = 'autocalculate'
                                out_args[18] = blank
                                out_args[19:22] = in_args[14:17]
                                out_args[22] = blank
                                if cur_args > 17:
                                    out_args[23:cur_args+6] = in_args[17:cur_args]
                                cur_args = cur_args + 6

                            elif record_name_upper == 'FLUIDCOOLER:TWOSPEED':
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:6] = in_args[0:6]
                                if same_string(out_args[5], 'autosize'):
                                    out_args[5] = 'autocalculate'
                                out_args[6] = blank
                                out_args[7:9] = in_args[6:8]
                                out_args[9] = blank
                                out_args[10:17] = in_args[8:15]
                                if same_string(out_args[16], 'autosize'):
                                    out_args[16] = 'autocalculate'
                                out_args[17] = blank
                                out_args[18] = in_args[15]
                                if same_string(out_args[18], 'autosize'):
                                    out_args[18] = 'autocalculate'
                                out_args[19] = blank
                                if cur_args > 16:
                                    out_args[20] = in_args[16]
                                cur_args = cur_args + 4

                            elif record_name_upper in ['HEATPUMP:WATERTOWATER:EQUATIONFIT:HEATING', 'HEATPUMP:WATERTOWATER:EQUATIONFIT:COOLING']:
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:19] = in_args[0:19]
                                if cur_args < 19:
                                    out_args[cur_args:19] = [blank] * (19 - cur_args)
                                cur_args = 19

                            elif record_name_upper in ['HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:HEATING', 'HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:COOLING']:
                                nodiff = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if cur_args < 20:
                                    out_args[cur_args:20] = [blank] * (20 - cur_args)
                                if cur_args == 23:
                                    cur_args = 22

                            elif record_name_upper == 'HVACTEMPLATE:ZONE:PTAC':
                                nodiff = False
                                cycling = False
                                continuous = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                out_schedule_name = blank
                                if same_string(out_args[12], 'Cycling'):
                                    out_args[12] = 'HVACTemplate:Zone:PTAC' + out_args[0][:min(len(out_args[0]), 59)] + 'CyclingFanSchedule'
                                    out_schedule_name = out_args[12]
                                    cycling = True
                                elif same_string(out_args[12], 'Continuous'):
                                    out_args[12] = 'HVACTemplate:Zone:PTAC' + out_args[0][:min(len(out_args[0]), 56)] + 'ContinuousFanSchedule'
                                    out_schedule_name = out_args[12]
                                    continuous = True
                                write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                                if not schedule_type_limits_any_number:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('ScheduleTypeLimits', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'Any Number'
                                    cur_args = 1
                                    write_out_idf_lines(dif_lfn, 'ScheduleTypeLimits', cur_args, out_args, nw_fld_names, nw_fld_units)

                                if cycling or continuous:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('Schedule:Constant', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = out_schedule_name
                                    out_args[1] = 'Any Number'
                                    cur_args = 3
                                    if cycling:
                                        out_args[2] = '0'
                                    if continuous:
                                        out_args[2] = '1'
                                    write_out_idf_lines(dif_lfn, 'Schedule:Constant', cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue

                            elif record_name_upper == 'HVACTEMPLATE:ZONE:PTHP':
                                nodiff = False
                                cycling = False
                                continuous = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                out_schedule_name = blank
                                if same_string(out_args[12], 'Cycling'):
                                    out_args[12] = 'HVACTemplate:Zone:PTHP' + out_args[0][:min(len(out_args[0]), 59)] + 'CyclingFanSchedule'
                                    out_schedule_name = out_args[12]
                                    cycling = True
                                elif same_string(out_args[12], 'Continuous'):
                                    out_args[12] = 'HVACTemplate:Zone:PTHP' + out_args[0][:min(len(out_args[0]), 56)] + 'ContinuousFanSchedule'
                                    out_schedule_name = out_args[12]
                                    continuous = True
                                write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                                if not schedule_type_limits_any_number:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('ScheduleTypeLimits', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'Any Number'
                                    cur_args = 1
                                    write_out_idf_lines(dif_lfn, 'ScheduleTypeLimits', cur_args, out_args, nw_fld_names, nw_fld_units)

                                if cycling or continuous:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('Schedule:Constant', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = out_schedule_name
                                    out_args[1] = 'Any Number'
                                    cur_args = 3
                                    if cycling:
                                        out_args[2] = '0'
                                    if continuous:
                                        out_args[2] = '1'
                                    write_out_idf_lines(dif_lfn, 'Schedule:Constant', cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue

                            elif record_name_upper == 'HVACTEMPLATE:ZONE:WATERTOAIRHEATPUMP':
                                nodiff = False
                                cycling = False
                                continuous = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                out_schedule_name = blank
                                if same_string(out_args[12], 'Cycling'):
                                    out_args[12] = 'HVACTemplate:Zone:WaterToAirHeatPump' + out_args[0][:min(len(out_args[0]), 45)] + 'CyclingFanSchedule'
                                    out_schedule_name = out_args[12]
                                    cycling = True
                                elif same_string(out_args[12], 'Continuous'):
                                    out_args[12] = 'HVACTemplate:Zone:WaterToAirHeatPump' + out_args[0][:min(len(out_args[0]), 42)] + 'ContinuousFanSchedule'
                                    out_schedule_name = out_args[12]
                                    continuous = True
                                write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                                if not schedule_type_limits_any_number:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('ScheduleTypeLimits', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'Any Number'
                                    cur_args = 1
                                    write_out_idf_lines(dif_lfn, 'ScheduleTypeLimits', cur_args, out_args, nw_fld_names, nw_fld_units)

                                if cycling or continuous:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('Schedule:Constant', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = out_schedule_name
                                    out_args[1] = 'Any Number'
                                    cur_args = 3
                                    if cycling:
                                        out_args[2] = '0'
                                    if continuous:
                                        out_args[2] = '1'
                                    write_out_idf_lines(dif_lfn, 'Schedule:Constant', cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue

                            elif record_name_upper == 'HVACTEMPLATE:SYSTEM:UNITARY':
                                nodiff = False
                                cycling = False
                                continuous = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                out_schedule_name = blank
                                if same_string(out_args[4], 'Cycling'):
                                    out_args[4] = 'HVACTemplate:System:Unitary' + out_args[0][:min(len(out_args[0]), 54)] + 'CyclingFanSchedule'
                                    out_schedule_name = out_args[4]
                                    cycling = True
                                elif same_string(out_args[4], 'Continuous'):
                                    out_args[4] = 'HVACTemplate:System:Unitary' + out_args[0][:min(len(out_args[0]), 51)] + 'ContinuousFanSchedule'
                                    out_schedule_name = out_args[4]
                                    continuous = True
                                write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                                if not schedule_type_limits_any_number:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('ScheduleTypeLimits', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'Any Number'
                                    cur_args = 1
                                    write_out_idf_lines(dif_lfn, 'ScheduleTypeLimits', cur_args, out_args, nw_fld_names, nw_fld_units)

                                if cycling or continuous:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('Schedule:Constant', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = out_schedule_name
                                    out_args[1] = 'Any Number'
                                    cur_args = 3
                                    if cycling:
                                        out_args[2] = '0'
                                    if continuous:
                                        out_args[2] = '1'
                                    write_out_idf_lines(dif_lfn, 'Schedule:Constant', cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue

                            elif record_name_upper == 'HVACTEMPLATE:SYSTEM:UNITARYHEATPUMP:AIRTOAIR':
                                nodiff = False
                                cycling = False
                                continuous = False
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                out_schedule_name = blank
                                if same_string(out_args[6], 'Cycling'):
                                    out_args[6] = 'HVACTemplate:System:UnitaryHeatPump:AirToAir' + out_args[0][:min(len(out_args[0]), 37)] + 'CyclingFanSchedule'
                                    out_schedule_name = out_args[6]
                                    cycling = True
                                elif same_string(out_args[6], 'Continuous'):
                                    out_args[6] = 'HVACTemplate:System:UnitaryHeatPump:AirToAir' + out_args[0][:min(len(out_args[0]), 34)] + 'ContinuousFanSchedule'
                                    out_schedule_name = out_args[6]
                                    continuous = True
                                write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                                if not schedule_type_limits_any_number:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('ScheduleTypeLimits', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'Any Number'
                                    cur_args = 1
                                    write_out_idf_lines(dif_lfn, 'ScheduleTypeLimits', cur_args, out_args, nw_fld_names, nw_fld_units)

                                if cycling or continuous:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd('Schedule:Constant', nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = out_schedule_name
                                    out_args[1] = 'Any Number'
                                    cur_args = 3
                                    if cycling:
                                        out_args[2] = '0'
                                    if continuous:
                                        out_args[2] = '1'
                                    write_out_idf_lines(dif_lfn, 'Schedule:Constant', cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue

                            elif record_name_upper == 'OUTPUT:VARIABLE':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                scan_output_variables_for_replacement(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, True, False, False, cur_args, [written], False)
                                if del_this[0]:
                                    continue

                            elif record_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                del_this = [False]
                                scan_output_variables_for_replacement(1, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, True, False, cur_args, [written], False)
                                if del_this[0]:
                                    continue

                            elif record_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                scan_output_variables_for_replacement(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, True, cur_args, [written], False)
                                if del_this[0]:
                                    continue

                            elif record_name_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                scan_output_variables_for_replacement(2, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, False, cur_args, [written], False)
                                if del_this[0]:
                                    continue

                            elif record_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                del_this = [False]
                                scan_output_variables_for_replacement(3, del_this, [checkrvi], [nodiff], object_name, dif_lfn, False, False, False, cur_args, [written], True)
                                if del_this[0]:
                                    continue

                            elif record_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                nodiff = True
                                out_args[0:cur_args] = in_args[0:cur_args]
                                cur_var = 3
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = make_uppercase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(state.get_num_rep_var_names()):
                                        uc_comp_rep_var_name = make_uppercase(state.get_old_rep_var_name()[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if state.get_new_rep_var_name()[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg] != blank and not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    if not state.get_otm_var_caution()[arg]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Output Table Monthly (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.get_new_rep_var_name()[arg] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_otm_var_caution()[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+1]:
                                                if not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1]
                                                    else:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    if state.get_new_rep_var_caution()[arg+1] != blank:
                                                        if not state.get_otm_var_caution()[arg+1]:
                                                            write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                                'Output Table Monthly (old)="' + state.get_old_rep_var_name()[arg] +
                                                                '" conversion to Output Table Monthly (new)="' +
                                                                state.get_new_rep_var_name()[arg+1] +
                                                                '" has the following caution "' + state.get_new_rep_var_caution()[arg+1] + '".')
                                                            dif_f.write(' \n')
                                                            state.get_otm_var_caution()[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg+2] != blank:
                                                    if not state.get_otm_var_caution()[arg+2]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Output Table Monthly (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.get_new_rep_var_name()[arg+2] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg+2] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_otm_var_caution()[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1

                            elif record_name_upper == 'METER:CUSTOM':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                cur_var = 4
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = make_uppercase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(state.get_num_rep_var_names()):
                                        uc_comp_rep_var_name = make_uppercase(state.get_old_rep_var_name()[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if state.get_new_rep_var_name()[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg] != blank and not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    if not state.get_cmtr_var_caution()[arg]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Custom Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.get_new_rep_var_name()[arg] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_cmtr_var_caution()[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+1]:
                                                if not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1]
                                                    else:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    if state.get_new_rep_var_caution()[arg+1] != blank and not same_string(state.get_new_rep_var_caution()[arg+1][:6], 'Forkeq'):
                                                        if not state.get_cmtr_var_caution()[arg+1]:
                                                            write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                                'Custom Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                                '" conversion to Custom Meter (new)="' +
                                                                state.get_new_rep_var_name()[arg+1] +
                                                                '" has the following caution "' + state.get_new_rep_var_caution()[arg+1] + '".')
                                                            dif_f.write(' \n')
                                                            state.get_cmtr_var_caution()[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg+2] != blank:
                                                    if not state.get_cmtr_var_caution()[arg+2]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Custom Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.get_new_rep_var_name()[arg+2] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg+2] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_cmtr_var_caution()[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break

                            elif record_name_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                cur_var = 4
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = make_uppercase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(state.get_num_rep_var_names()):
                                        uc_comp_rep_var_name = make_uppercase(state.get_old_rep_var_name()[arg])
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if state.get_new_rep_var_name()[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg] != blank and not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    if not state.get_cmtr_d_var_caution()[arg]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.get_new_rep_var_name()[arg] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_cmtr_d_var_caution()[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+1]:
                                                if not same_string(state.get_new_rep_var_caution()[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1]
                                                    else:
                                                        out_args[cur_var] = state.get_new_rep_var_name()[arg+1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    if state.get_new_rep_var_caution()[arg+1] != blank and not same_string(state.get_new_rep_var_caution()[arg+1][:6], 'Forkeq'):
                                                        if not state.get_cmtr_d_var_caution()[arg+1]:
                                                            write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                                'Custom Decrement Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                                '" conversion to Custom Decrement Meter (new)="' +
                                                                state.get_new_rep_var_name()[arg+1] +
                                                                '" has the following caution "' + state.get_new_rep_var_caution()[arg+1] + '".')
                                                            dif_f.write(' \n')
                                                            state.get_cmtr_d_var_caution()[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if state.get_old_rep_var_name()[arg] == state.get_old_rep_var_name()[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2]
                                                else:
                                                    out_args[cur_var] = state.get_new_rep_var_name()[arg+2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.get_new_rep_var_caution()[arg+2] != blank:
                                                    if not state.get_cmtr_d_var_caution()[arg+2]:
                                                        write_preprocessor_object(dif_lfn, 'PrognameConversion', 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.get_old_rep_var_name()[arg] +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.get_new_rep_var_name()[arg+2] +
                                                            '" has the following caution "' + state.get_new_rep_var_caution()[arg+2] + '".')
                                                        dif_f.write(' \n')
                                                        state.get_cmtr_d_var_caution()[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break

                            else:
                                if find_item_in_list(object_name, state.get_not_in_new(), len(state.get_not_in_new())) != 0:
                                    with open(auditf, 'a') as f:
                                        f.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                        f.write('... will be listed as comments on the new output file.\n')
                                    write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True

                        else:
                            nw_num_args = 0
                            get_new_object_def_in_idd(record.get('Name', ''), nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]

                        if diff_min_fields and nodiff:
                            nw_num_args = 0
                            get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]
                            nodiff = False
                            for arg in range(cur_args, 0):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(0, cur_args)

                        if nodiff and diff_only:
                            continue

                        if not written:
                            check_special_objects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, [written])

                        if not written:
                            write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                    if state.get_idf_records() and state.get_idf_records()[-1].get('CommtE', 0) != state.get_cur_comment():
                        comments = state.get_comments()
                        for xcount in range(state.get_idf_records()[-1].get('CommtE', 0), state.get_cur_comment()):
                            dif_f.write(comments[xcount] + '\n')
                            if xcount == state.get_idf_records()[-1].get('CommtE', 0):
                                dif_f.write(' \n')

                    if get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args = 0
                        get_new_object_def_in_idd(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                        nodiff = False
                        out_args[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)

                    dif_f.close()
                    import os
                    if os.path.exists(file_name_path + '.rvi'):
                        pass
                    process_rvi_mvi_files(file_name_path, 'rvi')
                    process_rvi_mvi_files(file_name_path, 'mvi')
                    close_out()
                else:
                    process_rvi_mvi_files(file_name_path, 'rvi')
                    process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file[0] = True

            created_output_name = ''
            create_new_name('Reallocate', [created_output_name], ' ')

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
        copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', [err_flag])
        copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, [err_flag])
        import os
        if os.path.exists(file_name_path + '.rvi'):
            copyfile(file_name_path + '.rvi', file_name_path + '.rviold', [err_flag])
        if os.path.exists(file_name_path + '.rvinew'):
            copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', [err_flag])
        if os.path.exists(file_name_path + '.mvi'):
            copyfile(file_name_path + '.mvi', file_name_path + '.mviold', [err_flag])
        if os.path.exists(file_name_path + '.mvinew'):
            copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', [err_flag])
