# EXTERNAL DEPS (to wire in glue):
# - FullFileName: str (mutable)
# - FileNamePath: str (mutable)
# - IDFRecords: list of IDFRecord objects with fields Name, NumAlphas, NumNumbers, Alphas, Numbers, CommtS, CommtE
# - Comments: list of str
# - NumIDFRecords: int
# - CurComment: int (mutable)
# - ObjectDef: object with Name array
# - NumObjectDefs: int
# - MaxAlphaArgsFound: int
# - MaxNumericArgsFound: int
# - MaxTotalArgs: int
# - ProcessingIMFFile: bool (mutable)
# - FatalError: bool (mutable)
# - Auditf: int (file unit)
# - ProgramPath: str
# - VerString: str (mutable)
# - VersionNum: float (mutable)
# - IDDFileNameWithPath: str (mutable)
# - NewIDDFileNameWithPath: str (mutable)
# - RepVarFileNameWithPath: str (mutable)
# - OldRepVarName: list of str
# - NewRepVarName: list of str
# - NumRepVarNames: int
# - NotInNew: list of str
# - MakingPretty: bool
# - ExternalState: object containing shared module state

from typing import List, Dict, Any, Tuple

Blank = ''

def set_this_version_variables(state: Any) -> None:
    state.VerString = 'Conversion 1.0.1 => 1.0.2'
    state.VersionNum = 1.0
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-0-1-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-0-2-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 1-0-1-042 to 1-0-2.csv'

def create_new_idf_using_rules(
    state: Any,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> None:
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
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
                        full_file_name = state.read_line_from_unit(in_lfn)
                        ios = 0
                    except:
                        full_file_name = Blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = Blank
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = Blank
                    continue
            
            units_arg = Blank
            if ios != 0:
                full_file_name = Blank
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != Blank:
                state.display_string('Processing IDF -- ' + full_file_name)
                state.write_audit('Processing IDF -- ' + full_file_name)
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print('assuming file extension of .idf')
                    state.write_audit('..assuming file extension of .idf')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = state.get_new_unit_number()
                file_ok = state.file_exists(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    state.write_audit('File not found=' + full_file_name)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    
                    if diff_only:
                        output_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file_name = file_name_path + '.' + local_file_extension + 'new'
                    
                    state.open_output_file(dif_lfn, output_file_name)
                    
                    if local_file_extension == 'imf':
                        state.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.')
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.process_input(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [Blank] * state.MaxAlphaArgsFound
                    numbers = [0.0] * state.MaxNumericArgsFound
                    in_args = [Blank] * state.MaxTotalArgs
                    aor_n = [False] * state.MaxTotalArgs
                    req_fld = [False] * state.MaxTotalArgs
                    fld_names = [Blank] * state.MaxTotalArgs
                    fld_defaults = [Blank] * state.MaxTotalArgs
                    fld_units = [Blank] * state.MaxTotalArgs
                    nw_aor_n = [False] * state.MaxTotalArgs
                    nw_req_fld = [False] * state.MaxTotalArgs
                    nw_fld_names = [Blank] * state.MaxTotalArgs
                    nw_fld_defaults = [Blank] * state.MaxTotalArgs
                    nw_fld_units = [Blank] * state.MaxTotalArgs
                    out_args = [Blank] * state.MaxTotalArgs
                    match_arg = [False] * state.MaxTotalArgs
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if state.IDFRecords[num].Name.upper() != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    num_comis_facades = state.get_num_objects_found('COMIS EXTERNAL NODE')
                    comis_facade_names = [Blank] * num_comis_facades
                    for num in range(num_comis_facades):
                        state.get_object_item('COMIS EXTERNAL NODE', num + 1, alphas, numbers)
                        comis_facade_names[num] = alphas[0]
                    
                    lrbo_list = state.get_num_objects_found('LOAD RANGE BASED OPERATION')
                    clrbo_list = state.get_num_objects_found('COOLING LOAD RANGE BASED OPERATION')
                    hlrbo_list = state.get_num_objects_found('HEATING LOAD RANGE BASED OPERATION')
                    count = lrbo_list + clrbo_list + hlrbo_list
                    lrbo_scheme = [Blank] * count
                    lrbo_type = [0] * count
                    lrbo = 0
                    
                    for num in range(state.NumIDFRecords):
                        obj_name_upper = state.IDFRecords[num].Name.upper()
                        
                        if obj_name_upper == 'LOAD RANGE BASED OPERATION':
                            object_name = state.IDFRecords[num].Name
                            if state.find_item_in_list(object_name, [od.Name for od in state.ObjectDef], state.NumObjectDefs) != -1:
                                state.get_object_def_in_idd(object_name, aor_n, req_fld, fld_names, fld_defaults, fld_units)
                            
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [Blank] * state.MaxTotalArgs
                            out_args = [Blank] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                            
                            ffield = True
                            mx_field = False
                            minus = False
                            for arg in range(1, cur_args, 3):
                                if ffield:
                                    ffield = False
                                else:
                                    pos = out_args[arg].find('-')
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                                if arg + 1 < len(out_args):
                                    pos = out_args[arg + 1].find('-')
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                            
                            lrbo_scheme[lrbo] = in_args[0].upper()
                            if mx_field:
                                lrbo_type[lrbo] = 0
                            elif not minus:
                                lrbo_type[lrbo] = 2
                            else:
                                lrbo_type[lrbo] = 1
                            lrbo += 1
                        
                        elif obj_name_upper == 'HEATING LOAD RANGE BASED OPERATION':
                            lrbo_scheme[lrbo] = state.IDFRecords[num].Alphas[0].upper()
                            lrbo_type[lrbo] = 2
                            lrbo += 1
                        
                        elif obj_name_upper == 'COOLING LOAD RANGE BASED OPERATION':
                            lrbo_scheme[lrbo] = state.IDFRecords[num].Alphas[0].upper()
                            lrbo_type[lrbo] = 1
                            lrbo += 1
                    
                    for num in range(state.NumIDFRecords):
                        obj_name_upper = state.IDFRecords[num].Name.upper()
                        if obj_name_upper != 'PLANT OPERATION SCHEMES' and obj_name_upper != 'CONDENSER OPERATION SCHEMES':
                            continue
                        
                        num_alphas = state.IDFRecords[num].NumAlphas
                        for arg in range(1, num_alphas, 3):
                            if state.IDFRecords[num].Alphas[arg].upper() != 'LOAD RANGE BASED OPERATION':
                                continue
                            count = state.find_item_in_list(state.IDFRecords[num].Alphas[arg + 1].upper(), lrbo_scheme, lrbo)
                            if count != -1:
                                if lrbo_type[count] == 1:
                                    state.IDFRecords[num].Alphas[arg] = 'COOLING LOAD RANGE BASED OPERATION'
                                elif lrbo_type[count] == 2:
                                    state.IDFRecords[num].Alphas[arg] = 'HEATING LOAD RANGE BASED OPERATION'
                    
                    for num in range(state.NumIDFRecords):
                        for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE + 1):
                            if xcount < len(state.Comments):
                                state.write_line_to_unit(dif_lfn, state.Comments[xcount])
                            if xcount == state.IDFRecords[num].CommtE:
                                state.write_line_to_unit(dif_lfn, '')
                        
                        if no_version and num == 0:
                            state.get_new_object_def_in_idd('VERSION', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '1.0.2'
                            cur_args = 1
                            state.write_out_idf_lines_as_comments(dif_lfn, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = state.IDFRecords[num].Name
                        if state.find_item_in_list(object_name, [od.Name for od in state.ObjectDef], state.NumObjectDefs) != -1:
                            state.get_object_def_in_idd(object_name, aor_n, req_fld, fld_names, fld_defaults, fld_units)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [Blank] * state.MaxTotalArgs
                            out_args = [Blank] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        else:
                            state.write_audit('Object="' + object_name + '" does not seem to be on the "old" IDD.')
                            state.write_audit('... will be listed as comments (no field names) on the new output file.')
                            state.write_audit('... Alpha fields will be listed first, then numerics.')
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [Blank] * state.MaxTotalArgs
                            nw_fld_units = [Blank] * state.MaxTotalArgs
                            state.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.find_item_in_list(object_name.upper(), state.NotInNew, len(state.NotInNew)) == -1:
                            state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        if not state.MakingPretty:
                            obj_name_upper = state.IDFRecords[num].Name.upper()
                            
                            if obj_name_upper == 'VERSION':
                                if in_args[0][:5] == '1.0.2' and arg_file:
                                    state.show_warning_error('File is already at latest version.  No new diff file made.')
                                    state.close_file(dif_lfn, delete=True)
                                    latest_version = True
                                    break
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '1.0.2'
                                no_diff = False
                            
                            elif obj_name_upper == 'COMIS SURFACE DATA':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                out_args[3] = in_args[3]
                                try:
                                    n_index = int(in_args[2])
                                except:
                                    n_index = 0
                                if n_index == 0:
                                    out_args[2] = Blank
                                else:
                                    out_args[2] = comis_facade_names[n_index - 1]
                                no_diff = False
                            
                            elif obj_name_upper == 'DAYLIGHTING':
                                if cur_args > 5:
                                    state.get_new_object_def_in_idd('DAYLIGHTING:DETAILED', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = 'Daylighting:Detailed'
                                    out_args[0] = in_args[0]
                                    out_args[1:cur_args-3] = in_args[4:cur_args]
                                    cur_args = cur_args - 3
                                else:
                                    state.get_new_object_def_in_idd('DAYLIGHTING:SIMPLE', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = 'Daylighting:Simple'
                                    out_args[0:4] = in_args[0:4]
                                    cur_args = 4
                                no_diff = False
                            
                            elif obj_name_upper == 'LOAD RANGE BASED OPERATION':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args = in_args[:]
                                ffield = True
                                mx_field = False
                                minus = False
                                for arg in range(1, cur_args, 3):
                                    if ffield:
                                        ffield = False
                                    else:
                                        pos = out_args[arg].find('-')
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                                    if arg + 1 < len(out_args):
                                        pos = out_args[arg + 1].find('-')
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                                
                                if mx_field:
                                    state.write_line_to_unit(dif_lfn, '! Next object is obsolete, needs hand transition to new')
                                elif not minus:
                                    object_name = 'Heating Load Range Based Operation'
                                else:
                                    object_name = 'Cooling Load Range Based Operation'
                                    for arg in range(1, cur_args, 3):
                                        pos = out_args[arg].find('-')
                                        if pos >= 0:
                                            out_args[arg] = out_args[arg][:pos] + ' ' + out_args[arg][pos+1:]
                                        if arg + 1 < len(out_args):
                                            pos = out_args[arg + 1].find('-')
                                            if pos >= 0:
                                                out_args[arg + 1] = out_args[arg + 1][:pos] + ' ' + out_args[arg + 1][pos+1:]
                                no_diff = False
                            
                            elif obj_name_upper == 'WINDOWSHADINGCONTROL':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if state.same_string('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if state.same_string('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if state.same_string('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if state.same_string('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if state.same_string('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if state.same_string('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if state.same_string('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if state.same_string('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutsideAirTemp'
                                if state.same_string('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemp'
                                if state.same_string('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if state.same_string('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if state.same_string('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif obj_name_upper == 'REPORT VARIABLE':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == Blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = state.scan_output_variables_for_replacement(
                                    2, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=True, mtr_var=False, time_bin_var=False, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ['REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY']:
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                del_this = state.scan_output_variables_for_replacement(
                                    1, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=False, mtr_var=True, time_bin_var=False, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'REPORT:TABLE:TIMEBINS':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == Blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = state.scan_output_variables_for_replacement(
                                    2, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=False, mtr_var=False, time_bin_var=True, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'REPORT:TABLE:MONTHLY':
                                state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == Blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = in_args[var].upper()
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = state.OldRepVarName[arg].upper()
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            
                                            if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if state.find_item_in_list(object_name, state.NotInNew, len(state.NotInNew)) != -1:
                                    state.write_audit('Object="' + object_name + '" is not in the "new" IDD.')
                                    state.write_audit('... will be listed as comments on the new output file.')
                                    state.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                        
                        else:
                            state.get_new_object_def_in_idd(state.IDFRecords[num].Name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if diff_min_fields and no_diff:
                            state.get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = False
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            state.check_special_objects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            state.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE + 1, state.CurComment + 1):
                            if xcount < len(state.Comments):
                                state.write_line_to_unit(dif_lfn, state.Comments[xcount])
                            if xcount == state.IDFRecords[state.NumIDFRecords - 1].CommtE:
                                state.write_line_to_unit(dif_lfn, '')
                    
                    state.close_file(dif_lfn)
                    if check_rvi:
                        state.process_rvi_mvi_files(file_name_path, 'rvi')
                        state.process_rvi_mvi_files(file_name_path, 'mvi')
                    state.close_out()
                
                else:
                    state.process_rvi_mvi_files(file_name_path, 'rvi')
                    state.process_rvi_mvi_files(file_name_path, 'mvi')
            
            else:
                end_of_file[0] = True
            
            state.create_new_name('Reallocate', '')
        
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
        state.copyfile(file_name_path + '.' + arg_idf_extension,
                      file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        state.copyfile(file_name_path + '.' + arg_idf_extension + 'new',
                      file_name_path + '.' + arg_idf_extension, err_flag)
        
        if state.file_exists(file_name_path + '.rvi'):
            state.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        if state.file_exists(file_name_path + '.rvinew'):
            state.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        if state.file_exists(file_name_path + '.mvi'):
            state.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        if state.file_exists(file_name_path + '.mvinew'):
            state.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
