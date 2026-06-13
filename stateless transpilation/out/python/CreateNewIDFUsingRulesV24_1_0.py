# EXTERNAL DEPS (to wire in glue):
# ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList, GetNumSectionsFound, GetNewUnitNumber, GetFieldOrIDDDefault from InputProcessor
# IDFRecords, Comments, NumIDFRecords, Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, ObjectDef, NumObjectDefs, FatalError, ProcessingIMFFile, MakingPretty, FullFileName, FileNamePath, Auditf, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NotInNew, MaxNameLength, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, FileOK from DataVCompareGlobals
# ProgNameConversion from DataStringGlobals
# ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError from DataGlobals
# ScanOutputVariablesForReplacement, WriteOutIDFLines, WriteOutIDFLinesAsComments, DisplayString, CheckSpecialObjects, CreateNewName, ProcessRviMviFiles, CloseOut, copyfile, writePreprocessorObject, MakeUPPERCase, MakeLowerCase, SameString, TrimTrailZeros from VCompareGlobalRoutines
# ProgramPath from various
# VerString, VersionNum, sVersionNum, sVersionNumFourChars, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath as module-level state

class SetVersion:
    first_time = True
    
    @staticmethod
    def set_this_version_variables(state):
        state.ver_string = 'Conversion 23.2 => 24.1'
        state.version_num = 24.1
        state.s_version_num = '***'
        state.s_version_num_four_chars = '24.1'
        state.idd_file_name_with_path = state.program_path.rstrip() + 'V23-2-0-Energy+.idd'
        state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V24-1-0-Energy+.idd'
        state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 23-2-0 to 24-1-0.csv'

def create_new_idf_using_rules(state, end_of_file, diff_only, in_lfn, ask_for_input, input_file_name, arg_file, arg_idf_extension):
    state.end_of_file = end_of_file
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension.strip()
    state.end_of_file = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not state.end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                state.full_file_name = input().strip()
            else:
                if not arg_file:
                    try:
                        state.full_file_name = next(iter(state.input_lines))
                    except (StopIteration, AttributeError):
                        state.full_file_name = ''
                        ios = 1
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = ''
                    ios = 1
                
                if state.full_file_name and state.full_file_name[0:1] == '!':
                    state.full_file_name = ''
                    continue
            
            units_arg = ''
            if ios != 0:
                state.full_file_name = ''
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name:
                display_string('Processing IDF -- ' + state.full_file_name.rstrip())
                write_audit(state.auditf, ' Processing IDF -- ' + state.full_file_name.rstrip())
                
                dot_pos = state.full_file_name.rfind('.')
                if dot_pos > 0:
                    state.file_name_path = state.full_file_name[:dot_pos]
                    local_file_extension = state.full_file_name[dot_pos+1:].lower()
                else:
                    state.file_name_path = state.full_file_name
                    print(' assuming file extension of .idf')
                    write_audit(state.auditf, ' ..assuming file extension of .idf')
                    state.full_file_name = state.full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = get_new_unit_number()
                file_ok = file_exists(state.full_file_name.rstrip())
                
                if not file_ok:
                    print('File not found=' + state.full_file_name.rstrip())
                    write_audit(state.auditf, 'File not found=' + state.full_file_name.rstrip())
                    state.end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_name = state.file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = state.file_name_path + '.' + local_file_extension + 'new'
                    
                    dif_lfn_file = open(dif_file_name, 'w')
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, state.full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    delete_this_record = [False] * state.num_idf_records
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if state.idf_records[num].name.upper() == 'VERSION':
                            no_version = False
                            break
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            dif_lfn_file.write('! Deleting: ' + state.idf_records[num].name.rstrip() + '="' + state.idf_records[num].alphas[0].rstrip() + '".\n')
                    
                    display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.idf_records[num].commt_s, state.idf_records[num].commt_e + 1):
                            dif_lfn_file.write(state.comments[xcount].rstrip() + '\n')
                            if xcount == state.idf_records[num].commt_e:
                                dif_lfn_file.write('\n')
                        
                        if no_version and num == 0:
                            get_new_object_def_in_idd(state, 'VERSION', {})
                            state.out_args[0] = state.s_version_num_four_chars
                            cur_args = 1
                            show_warning_error('No version found in file, defaulting to ' + state.s_version_num_four_chars, state.auditf)
                            write_out_idf_lines_as_comments(dif_lfn_file, 'Version', cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                        
                        object_name = state.idf_records[num].name
                        
                        if find_item_in_list(object_name, [obj.name for obj in state.object_def], state.num_object_defs) != 0:
                            get_object_def_in_idd(state, object_name)
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            state.alphas = state.idf_records[num].alphas[:]
                            state.numbers = state.idf_records[num].numbers[:]
                            cur_args = num_alphas + num_numbers
                            state.in_args = [''] * len(state.in_args)
                            state.out_args = [''] * len(state.out_args)
                            state.temp_args = [''] * len(state.temp_args)
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if state.a_or_n[arg]:
                                    state.in_args[arg] = state.alphas[na]
                                    na += 1
                                else:
                                    state.in_args[arg] = str(state.numbers[nn])
                                    nn += 1
                        else:
                            write_audit(state.auditf, 'Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.')
                            write_audit(state.auditf, '... will be listed as comments (no field names) on the new output file.')
                            write_audit(state.auditf, '... Alpha fields will be listed first, then numerics.')
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            state.alphas = state.idf_records[num].alphas[:]
                            state.numbers = state.idf_records[num].numbers[:]
                            for arg in range(num_alphas):
                                state.out_args[arg] = state.alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                state.out_args[nn] = str(state.numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            state.nw_fld_names = [''] * len(state.nw_fld_names)
                            state.nw_fld_units = [''] * len(state.nw_fld_units)
                            write_out_idf_lines_as_comments(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) == 0:
                            get_new_object_def_in_idd(state, object_name, {})
                            if state.obj_min_flds != state.nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.making_pretty:
                            obj_name_upper = state.idf_records[num].name.upper()
                            
                            if obj_name_upper == 'VERSION':
                                if state.in_args[0][0:4] == state.s_version_num_four_chars and arg_file:
                                    show_warning_error('File is already at latest version.  No new diff file made.', state.auditf)
                                    dif_lfn_file.close()
                                    latest_version = True
                                    break
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0] = state.s_version_num_four_chars
                                no_diff = False
                            
                            elif obj_name_upper == 'AIRLOOPHVAC:UNITARYSYSTEM':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                if cur_args > 38:
                                    if same_string(state.in_args[11], 'Coil:Heating:DX:VariableSpeed') or same_string(state.in_args[14], 'Coil:Cooling:DX:VariableSpeed'):
                                        state.out_args[38] = 'Yes'
                                    else:
                                        state.out_args[38] = 'No'
                                    state.out_args[39:cur_args+1] = state.in_args[38:cur_args]
                                    cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'COMFORTVIEWFACTORANGLES':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1:cur_args-1] = state.in_args[2:cur_args]
                                cur_args = cur_args - 1
                            
                            elif obj_name_upper == 'HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                
                                hx_effect_at_75_airflow = [
                                    get_field_or_idd_default(state.in_args[5], state.fld_defaults[5]),
                                    get_field_or_idd_default(state.in_args[6], state.fld_defaults[6]),
                                    get_field_or_idd_default(state.in_args[9], state.fld_defaults[9]),
                                    get_field_or_idd_default(state.in_args[10], state.fld_defaults[10])
                                ]
                                hx_effect_at_100_airflow = [
                                    get_field_or_idd_default(state.in_args[3], state.fld_defaults[3]),
                                    get_field_or_idd_default(state.in_args[4], state.fld_defaults[4]),
                                    get_field_or_idd_default(state.in_args[7], state.fld_defaults[7]),
                                    get_field_or_idd_default(state.in_args[8], state.fld_defaults[8])
                                ]
                                
                                state.out_args[0:5] = state.in_args[0:5]
                                state.out_args[5] = state.in_args[7]
                                state.out_args[6] = state.in_args[8]
                                state.out_args[7:19] = state.in_args[11:23]
                                
                                table_added = False
                                table_independent_var_added = False
                                
                                for i in range(4):
                                    effect75 = float(hx_effect_at_75_airflow[i])
                                    effect100 = float(hx_effect_at_100_airflow[i])
                                    if effect75 != effect100:
                                        table_id = str(i + 1)
                                        hx_table_name_i = state.in_args[0] + '_' + table_id
                                        state.out_args[19 + i] = hx_table_name_i
                                        table_added = True
                                    else:
                                        state.out_args[19 + i] = ''
                                
                                write_out_idf_lines(dif_lfn_file, 'HeatExchanger:AirToAir:SensibleAndLatent', cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                
                                for i in range(4):
                                    effect75 = float(hx_effect_at_75_airflow[i])
                                    effect100 = float(hx_effect_at_100_airflow[i])
                                    if effect75 != effect100:
                                        object_name = 'Table:Lookup'
                                        get_new_object_def_in_idd(state, object_name, {})
                                        state.out_args[0] = state.in_args[0] + '_' + str(i + 1)
                                        state.out_args[1] = 'effectiveness_IndependentVariableList'
                                        state.out_args[2] = 'DivisorOnly'
                                        state.out_args[3] = hx_effect_at_100_airflow[i]
                                        state.out_args[4] = '0.0'
                                        state.out_args[5] = '10.0'
                                        state.out_args[6] = 'Dimensionless'
                                        state.out_args[7] = ''
                                        state.out_args[8] = ''
                                        state.out_args[9] = ''
                                        state.out_args[10] = hx_effect_at_75_airflow[i]
                                        state.out_args[11] = hx_effect_at_100_airflow[i]
                                        cur_args = 12
                                        write_out_idf_lines(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                
                                if table_added and not table_independent_var_added:
                                    table_independent_var_added = True
                                    object_name = 'Table:IndependentVariableList'
                                    get_new_object_def_in_idd(state, object_name, {})
                                    state.out_args[0] = 'effectiveness_IndependentVariableList'
                                    state.out_args[1] = 'HxAirFlowRatio'
                                    cur_args = 2
                                    write_out_idf_lines(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                    
                                    object_name = 'Table:IndependentVariable'
                                    get_new_object_def_in_idd(state, object_name, {})
                                    state.out_args[0] = 'HxAirFlowRatio'
                                    state.out_args[1] = 'Linear'
                                    state.out_args[2] = 'Linear'
                                    state.out_args[3] = '0.0'
                                    state.out_args[4] = '10.0'
                                    state.out_args[5] = ''
                                    state.out_args[6] = 'Dimensionless'
                                    state.out_args[7] = ''
                                    state.out_args[8] = ''
                                    state.out_args[9] = ''
                                    state.out_args[10] = '0.75'
                                    state.out_args[11] = '1.0'
                                    cur_args = 12
                                    write_out_idf_lines(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                
                                written = True
                            
                            elif obj_name_upper == 'PEOPLE':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                if same_string(state.out_args[12], 'ZoneAveraged'):
                                    state.out_args[12] = 'EnclosureAveraged'
                            
                            elif obj_name_upper == 'ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0:9] = state.in_args[0:9]
                                if same_string(state.in_args[16], 'Coil:Cooling:DX:VariableSpeed'):
                                    state.out_args[9] = 'Yes'
                                else:
                                    state.out_args[9] = 'No'
                                state.out_args[10:cur_args+1] = state.in_args[9:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'ZONEHVAC:PACKAGEDTERMINALHEATPUMP':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0:9] = state.in_args[0:9]
                                if same_string(state.in_args[14], 'Coil:Heating:DX:VariableSpeed') or same_string(state.in_args[17], 'Coil:Cooling:DX:VariableSpeed'):
                                    state.out_args[9] = 'Yes'
                                else:
                                    state.out_args[9] = 'No'
                                state.out_args[10:cur_args+1] = state.in_args[9:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'ZONEHVAC:WATERTOAIRHEATPUMP':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = False
                                state.out_args[0:9] = state.in_args[0:9]
                                state.out_args[9] = 'No'
                                state.out_args[10:cur_args+1] = state.in_args[9:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'OUTPUT:VARIABLE':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                if state.out_args[0] == '':
                                    state.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_lfn_file, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                del_this = False
                                scan_output_variables_for_replacement(state, 1, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                if state.out_args[0] == '':
                                    state.out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                if state.out_args[0] == '':
                                    state.out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                del_this = False
                                scan_output_variables_for_replacement(state, 3, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, False, False, cur_args, written, True)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                get_new_object_def_in_idd(state, object_name, {})
                                no_diff = True
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = state.in_args[var].upper()
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    if not state.otm_var_caution[arg]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.new_rep_var_name[arg].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.otm_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1]:
                                                        if not state.otm_var_caution[arg + 1]:
                                                            write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                                'Output Table Monthly (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                                '" conversion to Output Table Monthly (new)="' +
                                                                state.new_rep_var_name[arg + 1].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 1].rstrip() + '".')
                                                            dif_lfn_file.write('\n')
                                                            state.otm_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg + 2]:
                                                    if not state.otm_var_caution[arg + 2]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.new_rep_var_name[arg + 2].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 2].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.otm_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_name_upper == 'METER:CUSTOM':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                cur_var = 4
                                for var in range(4, cur_args, 2):
                                    uc_rep_var_name = state.in_args[var].upper()
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    if not state.cmtr_var_caution[arg]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Custom Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.cmtr_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1] and not state.new_rep_var_caution[arg + 1][:6].upper() == 'FORKEQ':
                                                        if not state.cmtr_var_caution[arg + 1]:
                                                            write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                                'Custom Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                                '" conversion to Custom Meter (new)="' +
                                                                state.new_rep_var_name[arg + 1].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 1].rstrip() + '".')
                                                            dif_lfn_file.write('\n')
                                                            state.cmtr_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg + 2]:
                                                    if not state.cmtr_var_caution[arg + 2]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Custom Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg + 2].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 2].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.cmtr_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == '':
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper == 'METER:CUSTOMDECREMENT':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                cur_var = 4
                                for var in range(4, cur_args, 2):
                                    uc_rep_var_name = state.in_args[var].upper()
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var + 1] = state.in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    if not state.cmtr_d_var_caution[arg]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.cmtr_d_var_caution[arg] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                if not state.new_rep_var_caution[arg][:6].upper() == 'FORKEQ':
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg + 1].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg + 1] and not state.new_rep_var_caution[arg + 1][:6].upper() == 'FORKEQ':
                                                        if not state.cmtr_d_var_caution[arg + 1]:
                                                            write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                                'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                                '" conversion to Custom Decrement Meter (new)="' +
                                                                state.new_rep_var_name[arg + 1].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 1].rstrip() + '".')
                                                            dif_lfn_file.write('\n')
                                                            state.cmtr_d_var_caution[arg + 1] = True
                                                    
                                                    state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg + 2].rstrip() + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg + 2]:
                                                    if not state.cmtr_d_var_caution[arg + 2]:
                                                        write_preprocessor_object(dif_lfn_file, state.progname_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.old_rep_var_name[arg].rstrip() +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.new_rep_var_name[arg + 2].rstrip() + '" has the following caution "' + state.new_rep_var_caution[arg + 2].rstrip() + '".')
                                                        dif_lfn_file.write('\n')
                                                        state.cmtr_d_var_caution[arg + 2] = True
                                                
                                                state.out_args[cur_var + 1] = state.in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.out_args[arg] == '':
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper in ('DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF'):
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                del_this = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, True, False, cur_args, written, False)
                            
                            elif obj_name_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                get_new_object_def_in_idd(state, object_name, {})
                                state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                no_diff = True
                                
                                del_this = False
                                scan_output_variables_for_replacement(state, 6, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, True, False, cur_args, written, False)
                                
                                del_this = False
                                scan_output_variables_for_replacement(state, 12, del_this, checkrvi, no_diff, object_name, dif_lfn_file, False, True, False, cur_args, written, False)
                            
                            else:
                                if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    write_audit(state.auditf, 'Object="' + object_name.rstrip() + '" is not in the "new" IDD.')
                                    write_audit(state.auditf, '... will be listed as comments on the new output file.')
                                    write_out_idf_lines_as_comments(dif_lfn_file, object_name, cur_args, state.in_args, state.fld_names, state.fld_units)
                                    written = True
                                else:
                                    get_new_object_def_in_idd(state, object_name, {})
                                    state.out_args[0:cur_args] = state.in_args[0:cur_args]
                                    no_diff = True
                        
                        else:
                            get_new_object_def_in_idd(state, state.idf_records[num].name, {})
                            state.out_args[0:cur_args] = state.in_args[0:cur_args]
                        
                        if diff_min_fields and no_diff:
                            get_new_object_def_in_idd(state, object_name, {})
                            state.out_args[0:cur_args] = state.in_args[0:cur_args]
                            no_diff = False
                            for arg in range(cur_args, state.nw_obj_min_flds):
                                state.out_args[arg] = state.nw_fld_defaults[arg]
                            cur_args = max(state.nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            written = False
                        
                        if not written:
                            write_out_idf_lines(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    display_string('Processing IDF -- Processing idf objects complete.')
                    if state.idf_records[state.num_idf_records - 1].commt_e != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records - 1].commt_e + 1, state.cur_comment + 1):
                            dif_lfn_file.write(state.comments[xcount].rstrip() + '\n')
                    
                    if get_num_sections_found(state, 'Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        get_new_object_def_in_idd(state, object_name, {})
                        no_diff = False
                        state.out_args[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines(dif_lfn_file, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    file_exist = file_exists(state.file_name_path + '.rvi')
                    
                    dif_lfn_file.close()
                    process_rvi_mvi_files(state, state.file_name_path, 'rvi')
                    process_rvi_mvi_files(state, state.file_name_path, 'mvi')
                    close_out(state)
                else:
                    process_rvi_mvi_files(state, state.file_name_path, 'rvi')
                    process_rvi_mvi_files(state, state.file_name_path, 'mvi')
            else:
                state.end_of_file = True
            
            create_new_name(state, 'Reallocate', '', '')
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                state.end_of_file = False
            else:
                state.end_of_file = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copy_file(state.file_name_path + '.' + arg_idf_extension, state.file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        copy_file(state.file_name_path + '.' + arg_idf_extension + 'new', state.file_name_path + '.' + arg_idf_extension, err_flag)
        
        file_exist = file_exists(state.file_name_path + '.rvi')
        if file_exist:
            copy_file(state.file_name_path + '.rvi', state.file_name_path + '.rviold', err_flag)
        
        file_exist = file_exists(state.file_name_path + '.rvinew')
        if file_exist:
            copy_file(state.file_name_path + '.rvinew', state.file_name_path + '.rvi', err_flag)
        
        file_exist = file_exists(state.file_name_path + '.mvi')
        if file_exist:
            copy_file(state.file_name_path + '.mvi', state.file_name_path + '.mviold', err_flag)
        
        file_exist = file_exists(state.file_name_path + '.mvinew')
        if file_exist:
            copy_file(state.file_name_path + '.mvinew', state.file_name_path + '.mvi', err_flag)

def display_string(message):
    print(message)

def write_audit(auditf, message):
    if auditf:
        auditf.write(message + '\n')

def show_warning_error(message, auditf=None):
    print('Warning: ' + message)
    if auditf:
        auditf.write('Warning: ' + message + '\n')

def show_severe_error(message, auditf=None):
    print('Severe: ' + message)
    if auditf:
        auditf.write('Severe: ' + message + '\n')

def file_exists(filename):
    import os
    return os.path.exists(filename)

def copy_file(src, dst, err_flag):
    import shutil
    try:
        shutil.copy2(src, dst)
    except Exception as e:
        print(f'Error copying file: {e}')
        err_flag = True

def get_new_unit_number():
    import io
    return io.StringIO()

def make_upper_case(s):
    return s.upper() if s else s

def make_lower_case(s):
    return s.lower() if s else s

def same_string(a, b):
    return a.upper() == b.upper() if a and b else False

def find_item_in_list(item, lst, size):
    try:
        return lst.index(item) + 1
    except (ValueError, AttributeError):
        return 0

def get_object_def_in_idd(state, obj_name):
    pass

def get_new_object_def_in_idd(state, obj_name, kwargs):
    pass

def process_input(idd_file, new_idd_file, idf_file):
    pass

def scan_output_variables_for_replacement(state, field, del_this, checkrvi, nodiff, obj_name, dif_lfn, out_var, mtr_var, timebin_var, cur_args, written, is_sensor):
    pass

def write_out_idf_lines(dif_lfn, obj_name, cur_args, out_args, fld_names, fld_units):
    for i in range(cur_args):
        dif_lfn.write(f'{fld_names[i]} = {out_args[i]}\n')

def write_out_idf_lines_as_comments(dif_lfn, obj_name, cur_args, out_args, fld_names, fld_units):
    dif_lfn.write(f'! {obj_name}\n')
    for i in range(cur_args):
        dif_lfn.write(f'!   {out_args[i]}\n')

def check_special_objects(dif_lfn, obj_name, cur_args, out_args, fld_names, fld_units):
    pass

def create_new_name(state, action, arg1, arg2):
    pass

def process_rvi_mvi_files(state, file_path, ext):
    pass

def close_out(state):
    pass

def get_field_or_idd_default(field, default):
    return field if field else default

def get_num_sections_found(state, section_name):
    return 0

def write_preprocessor_object(dif_lfn, prog_name, severity, message):
    dif_lfn.write(f'! {severity}: {message}\n')
