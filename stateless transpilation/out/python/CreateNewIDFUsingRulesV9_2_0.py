# EXTERNAL DEPS (to wire in glue):
# - VerString, VersionNum, sVersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath (DataVCompareGlobals)
# - ProgramPath (DataStringGlobals)
# - Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits (module state)
# - NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg (module state)
# - PAorN, PReqFld, PFldNames, PFldDefaults, PFldUnits, POutArgs (module state)
# - IDFRecords, Comments, NumIDFRecords, CurComment (module state)
# - MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs (module state)
# - NumAlphas, NumNumbers, NumArgs, ObjMinFlds, NwNumArgs, NwObjMinFlds (module state)
# - ObjectDef, NumObjectDefs (module state)
# - ProcessingIMFFile, FatalError (module state)
# - NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames (module state)
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution (module state)
# - FileOK, Auditf, FullFileName, FileNamePath, Blank (module state)
# - MakingPretty (module state)
# - GetNewUnitNumber, ProcessInput, DisplayString, GetNewObjectDefInIDD, GetObjectDefInIDD (InputProcessor)
# - FindItemInList, MakeUPPERCase, SameString, TrimSigDigits, RoundSigDigits, MakeLowerCase (General)
# - WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects (output routines)
# - ScanOutputVariablesForReplacement, writePreprocessorObject, ProcessRviMviFiles, CloseOut, CreateNewName (conversion routines)
# - copyfile, ShowWarningError, ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError (DataGlobals)
# - GetNumObjectsFound, GetObjectItem, GetNumSectionsFound (InputProcessor)
# - ProcessNumber, SortUnique (utility)

from typing import List, Tuple, Optional


def set_this_version_variables(state):
    """Set version conversion variables."""
    state.VerString = 'Conversion 9.1 => 9.2'
    state.VersionNum = 9.2
    state.sVersionNum = '9.2'
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V9-1-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V9-2-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 9-1-0 to 9-2-0.csv'


def create_new_idf_using_rules(
    state,
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> bool:
    """
    Create new IDFs based on conversion rules.
    
    Returns: end_of_file flag
    """
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    fmta = "(A)"
    blank = ""
    
    # Preallocate arrays (mimicking Fortran allocation)
    state.Alphas = [""] * (state.MaxAlphaArgsFound + 1)
    state.Numbers = [0.0] * (state.MaxNumericArgsFound + 1)
    state.InArgs = [""] * (state.MaxTotalArgs + 1)
    state.TempArgs = [""] * (state.MaxTotalArgs + 1)
    state.AorN = [False] * (state.MaxTotalArgs + 1)
    state.ReqFld = [False] * (state.MaxTotalArgs + 1)
    state.FldNames = [""] * (state.MaxTotalArgs + 1)
    state.FldDefaults = [""] * (state.MaxTotalArgs + 1)
    state.FldUnits = [""] * (state.MaxTotalArgs + 1)
    state.NwAorN = [False] * (state.MaxTotalArgs + 1)
    state.NwReqFld = [False] * (state.MaxTotalArgs + 1)
    state.NwFldNames = [""] * (state.MaxTotalArgs + 1)
    state.NwFldDefaults = [""] * (state.MaxTotalArgs + 1)
    state.NwFldUnits = [""] * (state.MaxTotalArgs + 1)
    state.OutArgs = [""] * (state.MaxTotalArgs + 1)
    state.PAorN = [False] * (state.MaxTotalArgs + 1)
    state.PReqFld = [False] * (state.MaxTotalArgs + 1)
    state.PFldNames = [""] * (state.MaxTotalArgs + 1)
    state.PFldDefaults = [""] * (state.MaxTotalArgs + 1)
    state.PFldUnits = [""] * (state.MaxTotalArgs + 1)
    state.POutArgs = [""] * (state.MaxTotalArgs + 1)
    state.MatchArg = [""] * (state.MaxTotalArgs + 1)
    
    delete_this_record = [False] * (state.NumIDFRecords + 1)
    num_perim_objs = 0
    pargs = 0
    
    current_run_period_names = []
    iterate_run_period = 0
    tot_run_periods = 0
    
    num_ind_vars_vals = []
    cur_indices = []
    increments = []
    step_size = []
    ind_vars = []
    ind_var_order = []
    output_vals = []
    
    schedule_type_limits_any_number = False
    write_schedule_type_obj = True
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        full_file_name = blank
                        ios = 1
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
                state.DisplayString(f'Processing IDF -- {full_file_name}')
                state.Auditf.write(f' Processing IDF -- {full_file_name}\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    state.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                # Try to open file
                try:
                    with open(full_file_name, 'r') as f:
                        file_ok = True
                except FileNotFoundError:
                    file_ok = False
                
                if not file_ok:
                    print(f'File not found={full_file_name}')
                    state.Auditf.write(f'File not found={full_file_name}\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_lfn = open(f'{file_name_path}.{local_file_extension}dif', 'w')
                    else:
                        dif_lfn = open(f'{file_name_path}.{local_file_extension}new', 'w')
                    
                    if local_file_extension == 'imf':
                        state.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        dif_lfn.close()
                        break
                    
                    delete_this_record = [False] * (state.NumIDFRecords + 1)
                    
                    no_version = True
                    for num in range(1, state.NumIDFRecords + 1):
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for num in range(1, state.NumIDFRecords + 1):
                        if not state.SameString(state.IDFRecords[num].Name, 'ScheduleTypeLimits'):
                            continue
                        if not state.SameString(state.IDFRecords[num].Alphas[1], 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            dif_lfn.write(f'! Deleting: {state.IDFRecords[num].Name}="{state.IDFRecords[num].Alphas[1]}".\n')
                    
                    # Pre-process RunPeriod
                    state.DisplayString('Processing IDF -- RunPeriod preprocessing . . .')
                    iterate_run_period = 0
                    tot_run_periods = state.GetNumObjectsFound('RUNPERIOD')
                    current_run_period_names = [""] * (tot_run_periods + 1)
                    
                    for run_period_num in range(1, tot_run_periods + 1):
                        alphas, num_alphas, numbers, num_numbers, status = state.GetObjectItem('RUNPERIOD', run_period_num)
                        current_run_period_names[run_period_num] = alphas[1].strip()
                    
                    state.DisplayString('Processing IDF -- RunPeriod preprocessing complete.')
                    
                    # Main processing loop
                    state.DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS + 1, state.IDFRecords[num].CommtE + 1):
                            dif_lfn.write(state.Comments[xcount] + '\n')
                            if xcount == state.IDFRecords[num].CommtE:
                                dif_lfn.write('\n')
                        
                        if no_version and num == 1:
                            object_name = 'VERSION'
                            state.GetNewObjectDefInIDD(object_name)
                            state.OutArgs[1] = state.sVersionNum
                            cur_args = 1
                            state.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args)
                        
                        object_name = state.IDFRecords[num].Name
                        upper_obj_name = state.MakeUPPERCase(state.IDFRecords[num].Name)
                        
                        # Check for deleted objects
                        if upper_obj_name == 'PROGRAMCONTROL':
                            continue
                        if upper_obj_name == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if upper_obj_name == 'AIRFLOW MODEL':
                            continue
                        if upper_obj_name == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if upper_obj_name == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if upper_obj_name == 'WATER HEATER:SIMPLE':
                            dif_lfn.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            state.writePreprocessorObject(dif_lfn, state.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        if state.FindItemInList(object_name, state.ObjectDef_Name, state.NumObjectDefs) != 0:
                            state.GetObjectDefInIDD(object_name)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                state.Alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(1, num_numbers + 1):
                                state.Numbers[i] = state.IDFRecords[num].Numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            for i in range(1, state.MaxTotalArgs + 1):
                                state.InArgs[i] = blank
                                state.OutArgs[i] = blank
                                state.TempArgs[i] = blank
                            
                            na = 0
                            nn = 0
                            for arg in range(1, cur_args + 1):
                                if state.AorN[arg]:
                                    na += 1
                                    state.InArgs[arg] = state.Alphas[na]
                                else:
                                    nn += 1
                                    state.InArgs[arg] = str(state.Numbers[nn])
                        else:
                            state.Auditf.write(f'Object="{object_name}" does not seem to be on the "old" IDD.\n')
                            state.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            state.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                state.OutArgs[i] = state.IDFRecords[num].Alphas[i]
                            
                            nn = num_alphas + 1
                            for i in range(1, num_numbers + 1):
                                state.OutArgs[nn] = str(state.IDFRecords[num].Numbers[i])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.FindItemInList(state.MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            state.GetNewObjectDefInIDD(object_name)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            upper_obj = state.MakeUPPERCase(state.IDFRecords[num].Name)
                            
                            if upper_obj == 'VERSION':
                                if state.InArgs[1][:3] == state.sVersionNum and arg_file:
                                    state.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                    dif_lfn.close()
                                    latest_version = True
                                    break
                                state.GetNewObjectDefInIDD(object_name)
                                state.OutArgs[1] = state.sVersionNum
                                no_diff = False
                            
                            elif upper_obj == 'FOUNDATION:KIVA':
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                state.OutArgs[1] = state.InArgs[1]
                                state.OutArgs[2] = blank
                                for i in range(3, cur_args + 2):
                                    state.OutArgs[i] = state.InArgs[i - 1]
                                cur_args = cur_args + 1
                                no_diff = False
                            
                            elif upper_obj == 'RUNPERIOD':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                if state.SameString(state.InArgs[1].strip(), ''):
                                    no_diff = False
                                    iterate_run_period += 1
                                    potential_run_period_name = f'RUNPERIOD {state.TrimSigDigits(iterate_run_period)}'
                                    while state.FindItemInList(potential_run_period_name, current_run_period_names, tot_run_periods) != 0:
                                        iterate_run_period += 1
                                        potential_run_period_name = f'RUNPERIOD {state.TrimSigDigits(iterate_run_period)}'
                                    state.OutArgs[1] = potential_run_period_name
                            
                            elif upper_obj == 'SCHEDULE:FILE':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                if state.SameString(state.InArgs[7].strip(), 'FIXED'):
                                    no_diff = False
                                    state.OutArgs[7] = 'SPACE'
                            
                            elif upper_obj == 'TABLE:ONEINDEPENDENTVARIABLE':
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf.write(f'Object="{object_name}" is not in the "new" IDD.\n')
                                state.Auditf.write('... will be listed as comments on the new output file.\n')
                                state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args)
                                written = True
                                
                                num_ind_vars_vals = [0] * 2
                                num_ind_vars_vals[0] = (cur_args - 10) // 2
                                num_output_vals = num_ind_vars_vals[0]
                                
                                ind_vars = [[""] * num_ind_vars_vals[0]]
                                output_vals = [""] * (num_output_vals + 1)
                                
                                pargs = 10 + num_ind_vars_vals[0]
                                state.GetNewObjectDefInIDD('TABLE:INDEPENDENTVARIABLE')
                                state.POutArgs[1] = f'{state.InArgs[1]}_IndependentVariable1'
                                if state.SameString(state.InArgs[3], "LINEARINTERPOLATIONOFTABLE"):
                                    state.POutArgs[2] = "Linear"
                                    state.POutArgs[3] = "Constant"
                                elif state.SameString(state.InArgs[3], "LAGRANGEINTERPOLATIONLINEAREXTRAPOLATION"):
                                    state.POutArgs[2] = "Cubic"
                                    state.POutArgs[3] = "Linear"
                                else:
                                    state.POutArgs[2] = "Cubic"
                                    state.POutArgs[3] = "Constant"
                                
                                state.POutArgs[4] = state.InArgs[4]
                                state.POutArgs[5] = state.InArgs[5]
                                
                                for i_pt in range(1, num_ind_vars_vals[0] + 1):
                                    ind_vars[0][i_pt - 1] = state.InArgs[11 + 2 * (i_pt - 1)]
                                    output_vals[i_pt] = state.InArgs[12 + 2 * (i_pt - 1)]
                                
                                state.POutArgs[6] = blank
                                state.POutArgs[7] = state.InArgs[8]
                                state.POutArgs[8] = blank
                                state.POutArgs[9] = blank
                                state.POutArgs[10] = blank
                                for i in range(1, num_ind_vars_vals[0] + 1):
                                    state.POutArgs[10 + i] = ind_vars[0][i - 1]
                                
                                state.WriteOutIDFLines(dif_lfn, 'Table:IndependentVariable', pargs)
                                
                                pargs = 2
                                state.GetNewObjectDefInIDD('TABLE:INDEPENDENTVARIABLELIST')
                                state.POutArgs[1] = f'{state.InArgs[1]}_IndependentVariableList'
                                state.POutArgs[2] = f'{state.InArgs[1]}_IndependentVariable1'
                                state.WriteOutIDFLines(dif_lfn, 'Table:IndependentVariableList', pargs)
                                
                                pargs = 10 + num_output_vals
                                state.GetNewObjectDefInIDD('TABLE:LOOKUP')
                                state.POutArgs[1] = state.InArgs[1]
                                state.POutArgs[2] = f'{state.InArgs[1]}_IndependentVariableList'
                                
                                if state.InArgs[10] == blank:
                                    state.POutArgs[3] = blank
                                    state.POutArgs[4] = blank
                                else:
                                    state.POutArgs[3] = 'DivisorOnly'
                                    state.POutArgs[4] = state.InArgs[10]
                                
                                state.POutArgs[5] = state.InArgs[6]
                                state.POutArgs[6] = state.InArgs[7]
                                state.POutArgs[7] = state.InArgs[9]
                                state.POutArgs[8] = blank
                                state.POutArgs[9] = blank
                                state.POutArgs[10] = blank
                                for i in range(1, num_output_vals + 1):
                                    state.POutArgs[10 + i] = output_vals[i]
                                
                                state.WriteOutIDFLines(dif_lfn, 'Table:Lookup', pargs)
                            
                            elif upper_obj == 'TABLE:TWOINDEPENDENTVARIABLES':
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf.write(f'Object="{object_name}" is not in the "new" IDD.\n')
                                state.Auditf.write('... will be listed as comments on the new output file.\n')
                                state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args)
                                written = True
                                
                                num_output_vals = (cur_args - 14) // 3
                                ind_vars = [[""] * num_output_vals for _ in range(2)]
                                ind_var_order = [[0] * num_output_vals for _ in range(2)]
                                output_vals = [""] * (num_output_vals + 1)
                                
                                num_ind_vars_vals = [num_output_vals, num_output_vals]
                                
                                if state.InArgs[14] != blank:
                                    state.writePreprocessorObject(dif_lfn, state.ProgNameConversion, 'Warning',
                                        f'Table:TwoIndependentVariables="{state.InArgs[1]}" references an external file="{state.InArgs[14]}". External files must be converted to the new format usingtable_convert.py.')
                                    dif_lfn.write(' \n')
                                    state.ShowWarningError(f'Table:TwoIndependentVariables="{state.InArgs[1]}" references an external file="{state.InArgs[14]}". External files must be converted to the new format usingtable_convert.py or by appending the contents of the external file to the original IDF object.', state.Auditf)
                                
                                for i_pt in range(1, num_output_vals + 1):
                                    ind_vars[0][i_pt - 1] = state.InArgs[15 + 3 * (i_pt - 1)]
                                    ind_vars[1][i_pt - 1] = state.InArgs[16 + 3 * (i_pt - 1)]
                                    output_vals[i_pt] = state.InArgs[17 + 3 * (i_pt - 1)]
                                
                                for i_pt in range(0, 2):
                                    num_ind_vars_vals[i_pt] = num_output_vals
                                    ind_var_order[i_pt] = state.SortUnique(ind_vars[i_pt], num_output_vals)
                                    
                                    pargs = 10 + num_ind_vars_vals[i_pt]
                                    state.GetNewObjectDefInIDD('TABLE:INDEPENDENTVARIABLE')
                                    state.POutArgs[1] = f'{state.InArgs[1]}_IndependentVariable{i_pt + 1}'
                                    if state.SameString(state.InArgs[3], "LINEARINTERPOLATIONOFTABLE"):
                                        state.POutArgs[2] = "Linear"
                                        state.POutArgs[3] = "Constant"
                                    elif state.SameString(state.InArgs[3], "LAGRANGEINTERPOLATIONLINEAREXTRAPOLATION"):
                                        state.POutArgs[2] = "Cubic"
                                        state.POutArgs[3] = "Linear"
                                    else:
                                        state.POutArgs[2] = "Cubic"
                                        state.POutArgs[3] = "Constant"
                                    
                                    if i_pt == 0:
                                        state.POutArgs[4] = state.InArgs[4]
                                        state.POutArgs[5] = state.InArgs[5]
                                        state.POutArgs[7] = state.InArgs[10]
                                    else:
                                        state.POutArgs[4] = state.InArgs[6]
                                        state.POutArgs[5] = state.InArgs[7]
                                        state.POutArgs[7] = state.InArgs[11]
                                    
                                    state.POutArgs[6] = blank
                                    state.POutArgs[8] = blank
                                    state.POutArgs[9] = blank
                                    state.POutArgs[10] = blank
                                    
                                    for i in range(1, num_ind_vars_vals[i_pt] + 1):
                                        state.POutArgs[10 + i] = ind_vars[i_pt][i - 1]
                                    
                                    state.WriteOutIDFLines(dif_lfn, 'Table:IndependentVariable', pargs)
                                
                                if num_output_vals != num_ind_vars_vals[0] * num_ind_vars_vals[1]:
                                    print("Dimensional Mismatch")
                                
                                pargs = 3
                                state.GetNewObjectDefInIDD('TABLE:INDEPENDENTVARIABLELIST')
                                state.POutArgs[1] = f'{state.InArgs[1]}_IndependentVariableList'
                                state.POutArgs[2] = f'{state.InArgs[1]}_IndependentVariable1'
                                state.POutArgs[3] = f'{state.InArgs[1]}_IndependentVariable2'
                                state.WriteOutIDFLines(dif_lfn, 'Table:IndependentVariableList', pargs)
                                
                                pargs = 10 + num_output_vals
                                state.GetNewObjectDefInIDD('TABLE:LOOKUP')
                                state.POutArgs[1] = state.InArgs[1]
                                state.POutArgs[2] = f'{state.InArgs[1]}_IndependentVariableList'
                                
                                if state.InArgs[13] == blank:
                                    state.POutArgs[3] = blank
                                    state.POutArgs[4] = blank
                                else:
                                    state.POutArgs[3] = 'DivisorOnly'
                                    state.POutArgs[4] = state.InArgs[13]
                                
                                state.POutArgs[5] = state.InArgs[8]
                                state.POutArgs[6] = state.InArgs[9]
                                state.POutArgs[7] = state.InArgs[12]
                                state.POutArgs[8] = blank
                                state.POutArgs[9] = blank
                                state.POutArgs[10] = blank
                                
                                for i_pt in range(1, num_output_vals + 1):
                                    state.POutArgs[10 + (ind_var_order[0][i_pt - 1] - 1) * num_ind_vars_vals[1] + ind_var_order[1][i_pt - 1]] = output_vals[i_pt]
                                
                                state.WriteOutIDFLines(dif_lfn, 'Table:Lookup', pargs)
                            
                            elif upper_obj == 'TABLE:MULTIVARIABLELOOKUP':
                                # Handle complex table logic...
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf.write(f'Object="{object_name}" is not in the "new" IDD.\n')
                                state.Auditf.write('... will be listed as comments on the new output file.\n')
                                state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args)
                                written = True
                            
                            elif upper_obj == 'THERMALSTORAGE:ICE:DETAILED':
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                for i in range(1, 6):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                if state.SameString(state.InArgs[6].strip(), 'QUADRATICLINEAR'):
                                    state.OutArgs[6] = 'FractionDischargedLMTD'
                                elif state.SameString(state.InArgs[6].strip(), 'CUBICLINEAR'):
                                    state.OutArgs[6] = 'LMTDMassFlow'
                                else:
                                    state.OutArgs[6] = state.InArgs[6]
                                
                                state.OutArgs[7] = state.InArgs[7]
                                
                                if state.SameString(state.InArgs[8].strip(), 'QUADRATICLINEAR'):
                                    state.OutArgs[8] = 'FractionChargedLMTD'
                                elif state.SameString(state.InArgs[8].strip(), 'CUBICLINEAR'):
                                    state.OutArgs[8] = 'LMTDMassFlow'
                                else:
                                    state.OutArgs[8] = state.InArgs[8]
                                
                                for i in range(9, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                no_diff = False
                            
                            elif upper_obj == 'ZONEHVAC:EQUIPMENTLIST':
                                no_diff = False
                                state.GetNewObjectDefInIDD(object_name)
                                write_schedule_type_obj = True
                                
                                for cur_field in range(1, cur_args + 1):
                                    if cur_field < 3:
                                        zeq_heating_or_cooling = 'Neither'
                                    elif ((cur_field - 2) - 5) % 6 == 0:
                                        zeq_heating_or_cooling = 'Cooling'
                                    elif ((cur_field - 2) - 6) % 6 == 0:
                                        zeq_heating_or_cooling = 'Heating'
                                    else:
                                        zeq_heating_or_cooling = 'Neither'
                                    
                                    if state.InArgs[cur_field] != blank and (zeq_heating_or_cooling in ('Cooling', 'Heating')):
                                        zeq_num = (cur_field - 3) // 6 + 1
                                        zeq_num_str = state.RoundSigDigits(zeq_num, 0)
                                        
                                        if write_schedule_type_obj:
                                            state.GetNewObjectDefInIDD('ScheduleTypeLimits')
                                            state.POutArgs[1] = 'ZoneEqList ScheduleTypeLimts'
                                            state.POutArgs[2] = '0.0'
                                            state.POutArgs[3] = '1.0'
                                            state.POutArgs[4] = 'Continuous'
                                            state.WriteOutIDFLines(dif_lfn, 'ScheduleTypeLimits', 4)
                                            write_schedule_type_obj = False
                                        
                                        state.OutArgs[cur_field] = f'{state.InArgs[1]} {zeq_heating_or_cooling}Frac{zeq_num_str}'
                                        state.GetNewObjectDefInIDD('Schedule:Constant')
                                        state.POutArgs[1] = state.OutArgs[cur_field]
                                        state.POutArgs[2] = 'ZoneEqList ScheduleTypeLimts'
                                        state.POutArgs[3] = state.InArgs[cur_field]
                                        state.WriteOutIDFLines(dif_lfn, 'Schedule:Constant', state.PNumArgs)
                                    else:
                                        state.OutArgs[cur_field] = state.InArgs[cur_field]
                            
                            elif upper_obj == 'OUTPUT:VARIABLE':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1] == blank:
                                    state.OutArgs[1] = '*'
                                    no_diff = False
                                
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn, cur_args, is_out_var=True)
                            
                            elif upper_obj in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                state.ScanOutputVariablesForReplacement(1, object_name, dif_lfn, cur_args, is_mtr_var=True)
                            
                            elif upper_obj == 'OUTPUT:TABLE:TIMEBINS':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1] == blank:
                                    state.OutArgs[1] = '*'
                                    no_diff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn, cur_args, is_time_bin_var=True)
                            
                            elif upper_obj in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1] == blank:
                                    state.OutArgs[1] = '*'
                                    no_diff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn, cur_args)
                            
                            elif upper_obj == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                state.ScanOutputVariablesForReplacement(3, object_name, dif_lfn, cur_args)
                            
                            elif upper_obj == 'OUTPUT:TABLE:MONTHLY':
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = True
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                cur_var = 3
                                var = 3
                                while var <= cur_args:
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(1, state.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == '*':
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
                                            if state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif upper_obj == 'METER:CUSTOM':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var <= cur_args:
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(1, state.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == '*':
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
                                            if state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var, 0, -1):
                                    if state.OutArgs[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif upper_obj == 'METER:CUSTOMDECREMENT':
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var <= cur_args:
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(1, state.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == '*':
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
                                            if state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var, 0, -1):
                                    if state.OutArgs[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            else:
                                if state.FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                    state.Auditf.write(f'Object="{object_name}" is not in the "new" IDD.\n')
                                    state.Auditf.write('... will be listed as comments on the new output file.\n')
                                    state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args)
                                    written = True
                                else:
                                    state.GetNewObjectDefInIDD(object_name)
                                    for i in range(1, cur_args + 1):
                                        state.OutArgs[i] = state.InArgs[i]
                                    no_diff = True
                        
                        else:  # MakingPretty
                            state.GetNewObjectDefInIDD(object_name)
                            for i in range(1, cur_args + 1):
                                state.OutArgs[i] = state.InArgs[i]
                        
                        if diff_min_fields and no_diff:
                            state.GetNewObjectDefInIDD(object_name)
                            for i in range(1, cur_args + 1):
                                state.OutArgs[i] = state.InArgs[i]
                            no_diff = False
                            for arg in range(cur_args + 1, state.NwObjMinFlds + 1):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            state.CheckSpecialObjects(dif_lfn, object_name, cur_args)
                        
                        if not written:
                            state.WriteOutIDFLines(dif_lfn, object_name, cur_args)
                    
                    state.DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if state.IDFRecords[state.NumIDFRecords].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords].CommtE + 1, state.CurComment + 1):
                            dif_lfn.write(state.Comments[xcount] + '\n')
                    
                    if state.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        state.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        state.OutArgs[1] = 'Regular'
                        cur_args = 1
                        state.WriteOutIDFLines(dif_lfn, object_name, cur_args)
                    
                    dif_lfn.close()
                    state.ProcessRviMviFiles(file_name_path, 'rvi')
                    state.ProcessRviMviFiles(file_name_path, 'mvi')
                    state.CloseOut()
                else:
                    state.ProcessRviMviFiles(file_name_path, 'rvi')
                    state.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            state.CreateNewName('Reallocate', '')
        
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
        state.copyfile(f'{file_name_path}.{arg_idf_extension}', f'{file_name_path}.{arg_idf_extension}old', err_flag)
        state.copyfile(f'{file_name_path}.{arg_idf_extension}new', f'{file_name_path}.{arg_idf_extension}', err_flag)
        try:
            with open(f'{file_name_path}.rvi', 'r'):
                state.copyfile(f'{file_name_path}.rvi', f'{file_name_path}.rviold', err_flag)
        except FileNotFoundError:
            pass
        try:
            with open(f'{file_name_path}.rvinew', 'r'):
                state.copyfile(f'{file_name_path}.rvinew', f'{file_name_path}.rvi', err_flag)
        except FileNotFoundError:
            pass
        try:
            with open(f'{file_name_path}.mvi', 'r'):
                state.copyfile(f'{file_name_path}.mvi', f'{file_name_path}.mviold', err_flag)
        except FileNotFoundError:
            pass
        try:
            with open(f'{file_name_path}.mvinew', 'r'):
                state.copyfile(f'{file_name_path}.mvinew', f'{file_name_path}.mvi', err_flag)
        except FileNotFoundError:
            pass
    
    return end_of_file


def sort_unique(str_array: List[str], size: int) -> Tuple[List[str], List[int]]:
    """Sort unique values and return order indices."""
    in_numbers = []
    out_numbers = []
    order = [0] * (size + 1)
    
    init_size = size
    
    for i in range(size):
        in_numbers.append(float(str_array[i]))
    
    min_val = min(in_numbers) - 1
    max_val = max(in_numbers)
    
    size = 0
    while min_val < max_val:
        size += 1
        min_val = min(x for x in in_numbers if x > min_val)
        out_numbers.append(min_val)
    
    for i in range(size):
        str_array[i] = f'{out_numbers[i]:.5f}'.strip()
    
    for i in range(init_size):
        for i2 in range(size):
            if abs(out_numbers[i2] - in_numbers[i]) < 1e-10:
                order[i] = i2 + 1
                break
    
    return str_array, order
