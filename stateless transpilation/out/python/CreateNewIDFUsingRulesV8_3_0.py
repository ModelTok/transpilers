# EXTERNAL DEPS (to wire in glue):
# DataStringGlobals: ProgNameConversion (str), ProgramPath (str), blank (str)
# DataVCompareGlobals: IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath (str),
#   FullFileName, FileNamePath (mutable str), Auditf (int), NumIDFRecords (int),
#   IDFRecords (list), Comments (list[str]), CurComment (int),
#   MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, MaxNameLength (int),
#   Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits (allocatable),
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits (allocatable),
#   OutArgs, MatchArg (allocatable),
#   ProcessingIMFFile, FatalError, FileOK (mutable bool),
#   OldRepVarName, NewRepVarName, NewRepVarCaution (list[str]), NumRepVarNames (int),
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution (mutable list[bool]),
#   ObjectDef (list), NumObjectDefs (int), NotInNew (list[str]),
#   VersionNum, sVersionNum, VerString (mutable), MakingPretty (bool)
# InputProcessor: ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD
# General: FindItemInList, MakeUPPERCase, MakeLowerCase, SameString
# VCompareGlobalRoutines: DisplayString, ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments,
#   CheckSpecialObjects, WriteOutIDFLines, GetNumSectionsFound, ProcessRviMviFiles,
#   CloseOut, CreateNewName, copyfile, writePreprocessorObject
# DataGlobals: ShowWarningError
# External: GetNewUnitNumber

def set_this_version_variables(state):
    """SetThisVersionVariables subroutine equivalent"""
    state.VerString = 'Conversion 8.2 => 8.3'
    state.VersionNum = 8.3
    state.sVersionNum = '8.3'
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-2-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-3-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 8-2-0 to 8-3-0.csv'


def create_new_idf_using_rules(state, end_of_file, diff_only, in_lfn, ask_for_input, 
                                input_file_name, arg_file, arg_idf_extension):
    """
    CreateNewIDFUsingRules subroutine equivalent
    
    Creates new IDFs based on specified rules for version conversion.
    """
    fmta = "(A)"
    
    first_time = True
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                state.FullFileName = input('-->')
            else:
                if not arg_file:
                    try:
                        state.FullFileName = input()
                        ios = 0
                    except EOFError:
                        ios = 1
                elif not arg_file_being_done:
                    state.FullFileName = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.FullFileName = state.blank
                    ios = 1
            
            if state.FullFileName and state.FullFileName[0] == '!':
                state.FullFileName = state.blank
                continue
            
            units_arg = state.blank
            if ios != 0:
                state.FullFileName = state.blank
            state.FullFileName = state.FullFileName.lstrip()
            
            if state.FullFileName != state.blank:
                state.DisplayString('Processing IDF -- ' + state.FullFileName)
                state.write_audit(fmta, ' Processing IDF -- ' + state.FullFileName)
                
                dot_pos = state.FullFileName.rfind('.')
                if dot_pos != -1:
                    state.FileNamePath = state.FullFileName[:dot_pos]
                    local_file_extension = state.MakeLowerCase(state.FullFileName[dot_pos+1:])
                else:
                    state.FileNamePath = state.FullFileName
                    print(' assuming file extension of .idf')
                    state.write_audit(fmta, ' ..assuming file extension of .idf')
                    state.FullFileName = state.FullFileName + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = state.GetNewUnitNumber()
                
                import os
                file_ok = os.path.exists(state.FullFileName)
                if not file_ok:
                    print('File not found=' + state.FullFileName)
                    state.write_audit('File not found=' + state.FullFileName)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        out_file = open(state.FileNamePath + '.' + local_file_extension + 'dif', 'w')
                    else:
                        out_file = open(state.FileNamePath + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        state.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, state.FullFileName)
                    if state.FatalError:
                        exit_because_bad_file = True
                        out_file.close()
                        break
                    
                    # Clean up and reallocate arrays
                    state.DeleteThisRecord = [False] * state.NumIDFRecords
                    state.Alphas = [state.blank] * state.MaxAlphaArgsFound
                    state.Numbers = [0.0] * state.MaxNumericArgsFound
                    state.InArgs = [state.blank] * state.MaxTotalArgs
                    state.AorN = [False] * state.MaxTotalArgs
                    state.ReqFld = [False] * state.MaxTotalArgs
                    state.FldNames = [state.blank] * state.MaxTotalArgs
                    state.FldDefaults = [state.blank] * state.MaxTotalArgs
                    state.FldUnits = [state.blank] * state.MaxTotalArgs
                    state.NwAorN = [False] * state.MaxTotalArgs
                    state.NwReqFld = [False] * state.MaxTotalArgs
                    state.NwFldNames = [state.blank] * state.MaxTotalArgs
                    state.NwFldDefaults = [state.blank] * state.MaxTotalArgs
                    state.NwFldUnits = [state.blank] * state.MaxTotalArgs
                    state.OutArgs = [state.blank] * state.MaxTotalArgs
                    state.MatchArg = [state.blank] * state.MaxTotalArgs
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for num in range(state.NumIDFRecords):
                        if not state.SameString(state.IDFRecords[num]['Name'], 'ScheduleTypeLimits'):
                            continue
                        if not state.SameString(state.IDFRecords[num]['Alphas'][0], 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            out_file.write('! Deleting: ' + state.IDFRecords[num]['Name'] + '="' + 
                                         state.IDFRecords[num]['Alphas'][0] + '".\n')
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num]['CommtS'], state.IDFRecords[num]['CommtE'] + 1):
                            out_file.write(state.Comments[xcount] + '\n')
                            if xcount == state.IDFRecords[num]['CommtE']:
                                out_file.write('\n')
                        
                        if no_version and num == 0:
                            state.GetNewObjectDefInIDD('VERSION', state)
                            state.OutArgs[0] = state.sVersionNum
                            cur_args = 1
                            state.WriteOutIDFLinesAsComments(out_file, 'Version', cur_args, state.OutArgs, 
                                                           state.NwFldNames, state.NwFldUnits)
                        
                        object_name = state.IDFRecords[num]['Name']
                        
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) == 'AIRFLOW MODEL':
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num]['Name']) == 'WATER HEATER:SIMPLE':
                            out_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning', 
                                                        'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        if state.FindItemInList(object_name, state.ObjectDef, 'Name', state.NumObjectDefs) >= 0:
                            state.GetObjectDefInIDD(object_name, state)
                            num_alphas = state.IDFRecords[num]['NumAlphas']
                            num_numbers = state.IDFRecords[num]['NumNumbers']
                            state.Alphas[:num_alphas] = state.IDFRecords[num]['Alphas'][:num_alphas]
                            state.Numbers[:num_numbers] = state.IDFRecords[num]['Numbers'][:num_numbers]
                            cur_args = num_alphas + num_numbers
                            state.InArgs = [state.blank] * state.MaxTotalArgs
                            state.OutArgs = [state.blank] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if state.AorN[arg]:
                                    state.InArgs[arg] = state.Alphas[na]
                                    na += 1
                                else:
                                    state.InArgs[arg] = str(state.Numbers[nn])
                                    nn += 1
                        else:
                            state.write_audit('Object="' + object_name + '" does not seem to be on the "old" IDD.')
                            state.write_audit('... will be listed as comments (no field names) on the new output file.')
                            state.write_audit('... Alpha fields will be listed first, then numerics.')
                            num_alphas = state.IDFRecords[num]['NumAlphas']
                            num_numbers = state.IDFRecords[num]['NumNumbers']
                            state.Alphas[:num_alphas] = state.IDFRecords[num]['Alphas'][:num_alphas]
                            state.Numbers[:num_numbers] = state.IDFRecords[num]['Numbers'][:num_numbers]
                            for arg in range(num_alphas):
                                state.OutArgs[arg] = state.Alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                state.OutArgs[nn] = str(state.Numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            state.NwFldNames = [state.blank] * state.MaxTotalArgs
                            state.NwFldUnits = [state.blank] * state.MaxTotalArgs
                            state.WriteOutIDFLinesAsComments(out_file, object_name, cur_args, state.OutArgs, 
                                                           state.NwFldNames, state.NwFldUnits)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.FindItemInList(state.MakeUPPERCase(object_name), state.NotInNew, None, len(state.NotInNew)) < 0:
                            state.GetNewObjectDefInIDD(object_name, state)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            obj_upper = state.MakeUPPERCase(state.IDFRecords[num]['Name'])
                            
                            if obj_upper == 'VERSION':
                                if state.InArgs[0][:3] == '8.3' and arg_file:
                                    state.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                    out_file.close()
                                    latest_version = True
                                    break
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[0] = state.sVersionNum
                                nodiff = False
                            
                            elif obj_upper == 'CHILLER:ELECTRIC:REFORMULATEDEIR':
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:9] = state.InArgs[:9]
                                state.OutArgs[9] = 'LeavingCondenserWaterTemperature'
                                state.OutArgs[10:cur_args+1] = state.InArgs[9:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'SITE:GROUNDDOMAIN':
                                nodiff = False
                                object_name = 'Site:GroundDomain:Slab'
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            
                            elif obj_upper == 'GROUNDHEATEXCHANGER:VERTICAL':
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[0:3] = state.InArgs[0:3]
                                state.OutArgs[3] = state.InArgs[10]
                                state.OutArgs[4:10] = state.InArgs[4:10]
                                state.OutArgs[10:cur_args-1] = state.InArgs[11:cur_args]
                                cur_args = cur_args - 1
                            
                            elif obj_upper == 'EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL':
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[0:3] = state.InArgs[0:3]
                                state.OutArgs[3:6] = ['', '', '']
                                state.OutArgs[6] = state.InArgs[4]
                                state.OutArgs[7:9] = ['', '']
                                state.OutArgs[9] = state.InArgs[5]
                                state.OutArgs[10] = '1.0'
                                
                                indirect_old_field_five = float(state.InArgs[6])
                                indirect_old_field_six = float(state.InArgs[7])
                                state.OutArgs[11] = 'Autosize'
                                indirect_new_field_thirteen = indirect_old_field_six / indirect_old_field_five
                                state.OutArgs[12] = f'{indirect_new_field_thirteen:10.5f}'.strip()
                                state.OutArgs[13] = ''
                                state.OutArgs[14:16] = state.InArgs[8:10]
                                state.OutArgs[16] = 'Autosize'
                                state.OutArgs[17:19] = state.InArgs[11:13]
                                state.OutArgs[19] = ''
                                state.OutArgs[20:25] = state.InArgs[13:18]
                                cur_args = cur_args + 7
                            
                            elif obj_upper == 'EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL':
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[0:3] = state.InArgs[0:3]
                                state.OutArgs[3] = ''
                                state.OutArgs[4] = state.InArgs[3]
                                state.OutArgs[5:7] = ['', '']
                                state.OutArgs[7:13] = state.InArgs[4:10]
                                cur_args = cur_args + 3
                            
                            elif obj_upper == 'OUTPUT:VARIABLE':
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = '*'
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(state, 2, object_name, out_file, True, False, False, 
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 
                                             'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                state.ScanOutputVariablesForReplacement(state, 1, object_name, out_file, False, True, False,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = '*'
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(state, 2, object_name, out_file, False, False, True,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE',
                                             'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = '*'
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(state, 2, object_name, out_file, False, False, False,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                state.ScanOutputVariablesForReplacement(state, 3, object_name, out_file, False, False, False,
                                                                       cur_args, written, True)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                state.GetNewObjectDefInIDD(object_name, state)
                                nodiff = True
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
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
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not state.OTMVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.OldRepVarName[arg] + 
                                                            '" conversion to Output Table Monthly (new)="' + 
                                                            state.NewRepVarName[arg] + '" has the following caution "' + 
                                                            state.NewRepVarCaution[arg] + '".')
                                                        out_file.write(' \n')
                                                        state.OTMVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_upper == 'METER:CUSTOM':
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
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
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not state.CMtrVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + state.OldRepVarName[arg] + 
                                                            '" conversion to Custom Meter (new)="' + 
                                                            state.NewRepVarName[arg] + '" has the following caution "' + 
                                                            state.NewRepVarCaution[arg] + '".')
                                                        out_file.write(' \n')
                                                        state.CMtrVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg + 1 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                if not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                    else:
                                                        state.OutArgs[cur_var] = state.NewRepVarName[arg + 1] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                    if arg + 1 < len(state.NewRepVarCaution) and state.NewRepVarCaution[arg + 1] != state.blank and not state.SameString(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not state.CMtrVarCaution[arg + 1]:
                                                            state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                                'Custom Meter (old)="' + state.OldRepVarName[arg] + 
                                                                '" conversion to Custom Meter (new)="' + 
                                                                state.NewRepVarName[arg + 1] + '" has the following caution "' + 
                                                                state.NewRepVarCaution[arg + 1] + '".')
                                                            out_file.write(' \n')
                                                            state.CMtrVarCaution[arg + 1] = True
                                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                    nodiff = False
                                            
                                            if arg + 2 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 2] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if arg + 2 < len(state.NewRepVarCaution) and state.NewRepVarCaution[arg + 2] != state.blank:
                                                    if not state.CMtrVarCaution[arg + 2]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + state.OldRepVarName[arg] + 
                                                            '" conversion to Custom Meter (new)="' + 
                                                            state.NewRepVarName[arg + 2] + '" has the following caution "' + 
                                                            state.NewRepVarCaution[arg + 2] + '".')
                                                        out_file.write(' \n')
                                                        state.CMtrVarCaution[arg + 2] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                nodiff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.OutArgs[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                state.GetNewObjectDefInIDD(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
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
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not state.CMtrDVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + 
                                                            '" conversion to Custom Meter (new)="' + 
                                                            state.NewRepVarName[arg] + '" has the following caution "' + 
                                                            state.NewRepVarCaution[arg] + '".')
                                                        out_file.write(' \n')
                                                        state.CMtrDVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg + 1 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                if not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                    else:
                                                        state.OutArgs[cur_var] = state.NewRepVarName[arg + 1] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                    if arg + 1 < len(state.NewRepVarCaution) and state.NewRepVarCaution[arg + 1] != state.blank and not state.SameString(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not state.CMtrDVarCaution[arg + 1]:
                                                            state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                                'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + 
                                                                '" conversion to Custom Decrement Meter (new)="' + 
                                                                state.NewRepVarName[arg + 1] + '" has the following caution "' + 
                                                                state.NewRepVarCaution[arg + 1] + '".')
                                                            out_file.write(' \n')
                                                            state.CMtrDVarCaution[arg + 1] = True
                                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                    nodiff = False
                                            
                                            if arg + 2 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 2] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if arg + 2 < len(state.NewRepVarCaution) and state.NewRepVarCaution[arg + 2] != state.blank:
                                                    if not state.CMtrDVarCaution[arg + 2]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + 
                                                            '" conversion to Custom Meter (new)="' + 
                                                            state.NewRepVarName[arg + 2] + '" has the following caution "' + 
                                                            state.NewRepVarCaution[arg + 2] + '".')
                                                        out_file.write(' \n')
                                                        state.CMtrDVarCaution[arg + 2] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                nodiff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.OutArgs[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            else:
                                if state.FindItemInList(object_name, state.NotInNew, None, len(state.NotInNew)) >= 0:
                                    state.write_audit('Object="' + object_name + '" is not in the "new" IDD.')
                                    state.write_audit('... will be listed as comments on the new output file.')
                                    state.WriteOutIDFLinesAsComments(out_file, object_name, cur_args, state.InArgs,
                                                                   state.FldNames, state.FldUnits)
                                    written = True
                                else:
                                    state.GetNewObjectDefInIDD(object_name, state)
                                    state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                    nodiff = True
                        
                        else:
                            state.GetNewObjectDefInIDD(state.IDFRecords[num]['Name'], state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                        
                        if diff_min_fields and nodiff:
                            state.GetNewObjectDefInIDD(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = False
                            for arg in range(cur_args, state.NwObjMinFlds):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            state.CheckSpecialObjects(out_file, object_name, cur_args, state.OutArgs,
                                                    state.NwFldNames, state.NwFldUnits, written)
                        
                        if not written:
                            state.WriteOutIDFLines(out_file, object_name, cur_args, state.OutArgs,
                                                 state.NwFldNames, state.NwFldUnits)
                    
                    if state.IDFRecords[state.NumIDFRecords - 1]['CommtE'] != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1]['CommtE'] + 1, state.CurComment + 1):
                            out_file.write(state.Comments[xcount] + '\n')
                            if xcount == state.IDFRecords[state.NumIDFRecords - 1]['CommtE']:
                                out_file.write('\n')
                    
                    if state.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        state.GetNewObjectDefInIDD(object_name, state)
                        nodiff = False
                        state.OutArgs[0] = 'Regular'
                        cur_args = 1
                        state.WriteOutIDFLines(out_file, object_name, cur_args, state.OutArgs,
                                            state.NwFldNames, state.NwFldUnits)
                    
                    out_file.close()
                    state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                    state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
                    state.CloseOut()
                
                else:
                    state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                    state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
            
            else:
                end_of_file = True
            
            state.CreateNewName('Reallocate', ' ')
        
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
        state.copyfile(state.FileNamePath + '.' + arg_idf_extension,
                      state.FileNamePath + '.' + arg_idf_extension + 'old', err_flag)
        state.copyfile(state.FileNamePath + '.' + arg_idf_extension + 'new',
                      state.FileNamePath + '.' + arg_idf_extension, err_flag)
        
        import os
        if os.path.exists(state.FileNamePath + '.rvi'):
            state.copyfile(state.FileNamePath + '.rvi', state.FileNamePath + '.rviold', err_flag)
        
        if os.path.exists(state.FileNamePath + '.rvinew'):
            state.copyfile(state.FileNamePath + '.rvinew', state.FileNamePath + '.rvi', err_flag)
        
        if os.path.exists(state.FileNamePath + '.mvi'):
            state.copyfile(state.FileNamePath + '.mvi', state.FileNamePath + '.mviold', err_flag)
        
        if os.path.exists(state.FileNamePath + '.mvinew'):
            state.copyfile(state.FileNamePath + '.mvinew', state.FileNamePath + '.mvi', err_flag)
    
    return end_of_file
```

END>>>

<<<FILE out/mojo/create_new_i_d_f_using_rules_v8_3_0.mojo>>>
# EXTERNAL DEPS (to wire in glue):
# DataStringGlobals: ProgNameConversion (String), ProgramPath (String), blank (String)
# DataVCompareGlobals: IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath (String),
#   FullFileName, FileNamePath (mutable String), Auditf (Int), NumIDFRecords (Int),
#   IDFRecords (List), Comments (List[String]), CurComment (Int),
#   MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, MaxNameLength (Int),
#   Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits (allocatable),
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits (allocatable),
#   OutArgs, MatchArg (allocatable),
#   ProcessingIMFFile, FatalError, FileOK (mutable Bool),
#   OldRepVarName, NewRepVarName, NewRepVarCaution (List[String]), NumRepVarNames (Int),
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution (mutable List[Bool]),
#   ObjectDef (List), NumObjectDefs (Int), NotInNew (List[String]),
#   VersionNum, sVersionNum, VerString (mutable String), MakingPretty (Bool)
# InputProcessor: ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD
# General: FindItemInList, MakeUPPERCase, MakeLowerCase, SameString
# VCompareGlobalRoutines: DisplayString, ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments,
#   CheckSpecialObjects, WriteOutIDFLines, GetNumSectionsFound, ProcessRviMviFiles,
#   CloseOut, CreateNewName, copyfile, writePreprocessorObject
# DataGlobals: ShowWarningError
# External: GetNewUnitNumber

from math import floor

fn set_this_version_variables(inout state) -> None:
    state.VerString = "Conversion 8.2 => 8.3"
    state.VersionNum = 8.3
    state.sVersionNum = "8.3"
    state.IDDFileNameWithPath = state.ProgramPath + "V8-2-0-Energy+.idd"
    state.NewIDDFileNameWithPath = state.ProgramPath + "V8-3-0-Energy+.idd"
    state.RepVarFileNameWithPath = state.ProgramPath + "Report Variables 8-2-0 to 8-3-0.csv"


fn create_new_idf_using_rules(inout state, inout end_of_file: Bool, diff_only: Bool, 
                               in_lfn: Int, ask_for_input: Bool, 
                               input_file_name: String, arg_file: Bool, 
                               arg_idf_extension: String) -> None:
    let fmta = "(A)"
    var first_time: Bool = True
    
    if first_time:
        first_time = False
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                state.FullFileName = input("-->")
            else:
                if not arg_file:
                    state.FullFileName = input()
                    ios = 0
                elif not arg_file_being_done:
                    state.FullFileName = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.FullFileName = state.blank
                    ios = 1
            
            if len(state.FullFileName) > 0 and state.FullFileName[0] == "!":
                state.FullFileName = state.blank
                continue
            
            var units_arg = state.blank
            if ios != 0:
                state.FullFileName = state.blank
            state.FullFileName = state.FullFileName.lstrip()
            
            if state.FullFileName != state.blank:
                state.DisplayString("Processing IDF -- " + state.FullFileName)
                state.write_audit(fmta, " Processing IDF -- " + state.FullFileName)
                
                var dot_pos: Int = state.FullFileName.rfind(".")
                if dot_pos >= 0:
                    state.FileNamePath = state.FullFileName[:dot_pos]
                    local_file_extension = state.MakeLowerCase(state.FullFileName[dot_pos+1:])
                else:
                    state.FileNamePath = state.FullFileName
                    print(" assuming file extension of .idf")
                    state.write_audit(fmta, " ..assuming file extension of .idf")
                    state.FullFileName = state.FullFileName + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = state.GetNewUnitNumber()
                
                var file_ok: Bool = state.file_exists(state.FullFileName)
                if not file_ok:
                    print("File not found=" + state.FullFileName)
                    state.write_audit("File not found=" + state.FullFileName)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var out_file: FileHandle
                    if diff_only:
                        out_file = state.open_file(state.FileNamePath + "." + local_file_extension + "dif", "w")
                    else:
                        out_file = state.open_file(state.FileNamePath + "." + local_file_extension + "new", "w")
                    
                    if local_file_extension == "imf":
                        state.ShowWarningError("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, state.FullFileName)
                    if state.FatalError:
                        exit_because_bad_file = True
                        state.close_file(out_file)
                        break
                    
                    state.allocate_arrays()
                    state.DeleteThisRecord = List[Bool](state.NumIDFRecords, False)
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var schedule_type_limits_any_number: Bool = False
                    for num in range(state.NumIDFRecords):
                        if not state.SameString(state.IDFRecords[num].Name, "ScheduleTypeLimits"):
                            continue
                        if not state.SameString(state.IDFRecords[num].Alphas[0], "Any Number"):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            state.write_file(out_file, "! Deleting: " + state.IDFRecords[num].Name + "=\"" + 
                                           state.IDFRecords[num].Alphas[0] + "\".")
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE + 1):
                            state.write_file(out_file, state.Comments[xcount])
                            if xcount == state.IDFRecords[num].CommtE:
                                state.write_file(out_file, "")
                        
                        if no_version and num == 0:
                            state.GetNewObjectDefInIDD("VERSION")
                            state.OutArgs[0] = state.sVersionNum
                            var cur_args: Int = 1
                            state.WriteOutIDFLinesAsComments(out_file, "Version", cur_args, state.OutArgs, 
                                                           state.NwFldNames, state.NwFldUnits)
                        
                        var object_name = state.IDFRecords[num].Name
                        
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) == "AIRFLOW MODEL":
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) == "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS":
                            continue
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) == "WATER HEATER:SIMPLE":
                            state.write_file(out_file, "! ** The WATER HEATER:SIMPLE object has been deleted")
                            state.writePreprocessorObject(out_file, state.ProgNameConversion, "Warning", 
                                                        "The WATER HEATER:SIMPLE object has been deleted")
                            continue
                        
                        if state.FindItemInList(object_name, state.ObjectDef, "Name", state.NumObjectDefs) >= 0:
                            state.GetObjectDefInIDD(object_name)
                            var num_alphas: Int = state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = state.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                state.Alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                state.Numbers[i] = state.IDFRecords[num].Numbers[i]
                            cur_args = num_alphas + num_numbers
                            state.InArgs = List[String](state.MaxTotalArgs, state.blank)
                            state.OutArgs = List[String](state.MaxTotalArgs, state.blank)
                            var na: Int = 0
                            var nn: Int = 0
                            for arg in range(cur_args):
                                if state.AorN[arg]:
                                    state.InArgs[arg] = state.Alphas[na]
                                    na += 1
                                else:
                                    state.InArgs[arg] = str(state.Numbers[nn])
                                    nn += 1
                        else:
                            state.write_audit("Object=\"" + object_name + "\" does not seem to be on the \"old\" IDD.")
                            state.write_audit("... will be listed as comments (no field names) on the new output file.")
                            state.write_audit("... Alpha fields will be listed first, then numerics.")
                            var num_alphas: Int = state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = state.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                state.Alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                state.Numbers[i] = state.IDFRecords[num].Numbers[i]
                            for arg in range(num_alphas):
                                state.OutArgs[arg] = state.Alphas[arg]
                            var nn: Int = num_alphas + 1
                            for arg in range(num_numbers):
                                state.OutArgs[nn] = str(state.Numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            state.NwFldNames = List[String](state.MaxTotalArgs, state.blank)
                            state.NwFldUnits = List[String](state.MaxTotalArgs, state.blank)
                            state.WriteOutIDFLinesAsComments(out_file, object_name, cur_args, state.OutArgs, 
                                                           state.NwFldNames, state.NwFldUnits)
                            continue
                        
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if state.FindItemInList(state.MakeUPPERCase(object_name), state.NotInNew, None, len(state.NotInNew)) < 0:
                            state.GetNewObjectDefInIDD(object_name)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            var obj_upper = state.MakeUPPERCase(state.IDFRecords[num].Name)
                            
                            if obj_upper == "VERSION":
                                if state.InArgs[0][:3] == "8.3" and arg_file:
                                    state.ShowWarningError("File is already at latest version.  No new diff file made.", state.Auditf)
                                    state.close_file(out_file)
                                    latest_version = True
                                    break
                                state.GetNewObjectDefInIDD(object_name)
                                state.OutArgs[0] = state.sVersionNum
                                nodiff = False
                            
                            elif obj_upper == "CHILLER:ELECTRIC:REFORMULATEDEIR":
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(9):
                                    state.OutArgs[i] = state.InArgs[i]
                                state.OutArgs[9] = "LeavingCondenserWaterTemperature"
                                for i in range(cur_args - 9):
                                    state.OutArgs[10 + i] = state.InArgs[9 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == "SITE:GROUNDDOMAIN":
                                nodiff = False
                                object_name = "Site:GroundDomain:Slab"
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                            
                            elif obj_upper == "GROUNDHEATEXCHANGER:VERTICAL":
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(3):
                                    state.OutArgs[i] = state.InArgs[i]
                                state.OutArgs[3] = state.InArgs[10]
                                for i in range(6):
                                    state.OutArgs[4 + i] = state.InArgs[4 + i]
                                for i in range(cur_args - 11):
                                    state.OutArgs[10 + i] = state.InArgs[11 + i]
                                cur_args = cur_args - 1
                            
                            elif obj_upper == "EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL":
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(3):
                                    state.OutArgs[i] = state.InArgs[i]
                                for i in range(3):
                                    state.OutArgs[3 + i] = ""
                                state.OutArgs[6] = state.InArgs[4]
                                for i in range(2):
                                    state.OutArgs[7 + i] = ""
                                state.OutArgs[9] = state.InArgs[5]
                                state.OutArgs[10] = "1.0"
                                
                                var indirect_old_field_five: Float64 = atof(state.InArgs[6])
                                var indirect_old_field_six: Float64 = atof(state.InArgs[7])
                                state.OutArgs[11] = "Autosize"
                                var indirect_new_field_thirteen: Float64 = indirect_old_field_six / indirect_old_field_five
                                state.OutArgs[12] = str(indirect_new_field_thirteen, precision=5)
                                state.OutArgs[13] = ""
                                for i in range(2):
                                    state.OutArgs[14 + i] = state.InArgs[8 + i]
                                state.OutArgs[16] = "Autosize"
                                for i in range(2):
                                    state.OutArgs[17 + i] = state.InArgs[11 + i]
                                state.OutArgs[19] = ""
                                for i in range(5):
                                    state.OutArgs[20 + i] = state.InArgs[13 + i]
                                cur_args = cur_args + 7
                            
                            elif obj_upper == "EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL":
                                nodiff = False
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(3):
                                    state.OutArgs[i] = state.InArgs[i]
                                state.OutArgs[3] = ""
                                state.OutArgs[4] = state.InArgs[3]
                                for i in range(2):
                                    state.OutArgs[5 + i] = ""
                                for i in range(6):
                                    state.OutArgs[7 + i] = state.InArgs[4 + i]
                                cur_args = cur_args + 3
                            
                            elif obj_upper == "OUTPUT:VARIABLE":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = "*"
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, out_file, True, False, False, 
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == "OUTPUT:METER" or obj_upper == "OUTPUT:METER:METERFILEONLY" or \
                                 obj_upper == "OUTPUT:METER:CUMULATIVE" or obj_upper == "OUTPUT:METER:CUMULATIVE:METERFILEONLY":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                state.ScanOutputVariablesForReplacement(1, object_name, out_file, False, True, False,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == "OUTPUT:TABLE:TIMEBINS":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = "*"
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, out_file, False, False, True,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE" or \
                                 obj_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = "*"
                                    nodiff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, out_file, False, False, False,
                                                                       cur_args, written, False)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                state.ScanOutputVariablesForReplacement(3, object_name, out_file, False, False, False,
                                                                       cur_args, written, True)
                                if state.DeleteThis:
                                    continue
                            
                            elif obj_upper == "OUTPUT:TABLE:MONTHLY":
                                state.GetNewObjectDefInIDD(object_name)
                                nodiff = True
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                var cur_var: Int = 2
                                for var_idx in range(2, cur_args, 2):
                                    var uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var_idx])
                                    state.OutArgs[cur_var] = state.InArgs[var_idx]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    var pos: Int = uc_rep_var_name.find("[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    
                                    var del_this: Bool = False
                                    for arg in range(state.NumRepVarNames):
                                        var uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        var wild_match: Bool = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.NewRepVarName[arg] != "<DELETE>":
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], "Forkeq"):
                                                    if not state.OTMVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, "Warning",
                                                            "Output Table Monthly (old)=\"" + state.OldRepVarName[arg] + 
                                                            "\" conversion to Output Table Monthly (new)=\"" + 
                                                            state.NewRepVarName[arg] + "\" has the following caution \"" + 
                                                            state.NewRepVarCaution[arg] + "\".")
                                                        state.write_file(out_file, " ")
                                                        state.OTMVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_upper == "METER:CUSTOM":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                var cur_var: Int = 3
                                for var_idx in range(3, cur_args, 2):
                                    var uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var_idx])
                                    state.OutArgs[cur_var] = state.InArgs[var_idx]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    var pos: Int = uc_rep_var_name.find("[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    
                                    var del_this: Bool = False
                                    for arg in range(state.NumRepVarNames):
                                        var uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        var wild_match: Bool = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.NewRepVarName[arg] != "<DELETE>":
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], "Forkeq"):
                                                    if not state.CMtrVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, "Warning",
                                                            "Custom Meter (old)=\"" + state.OldRepVarName[arg] + 
                                                            "\" conversion to Custom Meter (new)=\"" + 
                                                            state.NewRepVarName[arg] + "\" has the following caution \"" + 
                                                            state.NewRepVarCaution[arg] + "\".")
                                                        state.write_file(out_file, " ")
                                                        state.CMtrVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.OutArgs[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_upper == "METER:CUSTOMDECREMENT":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                                var cur_var: Int = 3
                                for var_idx in range(3, cur_args, 2):
                                    var uc_rep_var_name = state.MakeUPPERCase(state.InArgs[var_idx])
                                    state.OutArgs[cur_var] = state.InArgs[var_idx]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    var pos: Int = uc_rep_var_name.find("[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                    
                                    var del_this: Bool = False
                                    for arg in range(state.NumRepVarNames):
                                        var uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                        var wild_match: Bool = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.NewRepVarName[arg] != "<DELETE>":
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg] != state.blank and not state.SameString(state.NewRepVarCaution[arg][:6], "Forkeq"):
                                                    if not state.CMtrDVarCaution[arg]:
                                                        state.writePreprocessorObject(out_file, state.ProgNameConversion, "Warning",
                                                            "Custom Decrement Meter (old)=\"" + state.OldRepVarName[arg] + 
                                                            "\" conversion to Custom Meter (new)=\"" + 
                                                            state.NewRepVarName[arg] + "\" has the following caution \"" + 
                                                            state.NewRepVarCaution[arg] + "\".")
                                                        state.write_file(out_file, " ")
                                                        state.CMtrDVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if state.OutArgs[arg] == state.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            else:
                                if state.FindItemInList(object_name, state.NotInNew, None, len(state.NotInNew)) >= 0:
                                    state.write_audit("Object=\"" + object_name + "\" is not in the \"new\" IDD.")
                                    state.write_audit("... will be listed as comments on the new output file.")
                                    state.WriteOutIDFLinesAsComments(out_file, object_name, cur_args, state.InArgs,
                                                                   state.FldNames, state.FldUnits)
                                    written = True
                                else:
                                    state.GetNewObjectDefInIDD(object_name)
                                    for i in range(cur_args):
                                        state.OutArgs[i] = state.InArgs[i]
                                    nodiff = True
                        
                        else:
                            state.GetNewObjectDefInIDD(state.IDFRecords[num].Name)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                        
                        if diff_min_fields and nodiff:
                            state.GetNewObjectDefInIDD(object_name)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = False
                            for arg in range(cur_args, state.NwObjMinFlds):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            state.CheckSpecialObjects(out_file, object_name, cur_args, state.OutArgs,
                                                    state.NwFldNames, state.NwFldUnits, written)
                        
                        if not written:
                            state.WriteOutIDFLines(out_file, object_name, cur_args, state.OutArgs,
                                                 state.NwFldNames, state.NwFldUnits)
                    
                    if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE + 1, state.CurComment + 1):
                            state.write_file(out_file, state.Comments[xcount])
                            if xcount == state.IDFRecords[state.NumIDFRecords - 1].CommtE:
                                state.write_file(out_file, "")
                    
                    if state.GetNumSectionsFound("Report Variable Dictionary") > 0:
                        object_name = "Output:VariableDictionary"
                        state.GetNewObjectDefInIDD(object_name)
                        nodiff = False
                        state.OutArgs[0] = "Regular"
                        cur_args = 1
                        state.WriteOutIDFLines(out_file, object_name, cur_args, state.OutArgs,
                                            state.NwFldNames, state.NwFldUnits)
                    
                    state.close_file(out_file)
                    state.ProcessRviMviFiles(state.FileNamePath, "rvi")
                    state.ProcessRviMviFiles(state.FileNamePath, "mvi")
                    state.CloseOut()
                
                else:
                    state.ProcessRviMviFiles(state.FileNamePath, "rvi")
                    state.ProcessRviMviFiles(state.FileNamePath, "mvi")
            
            else:
                end_of_file = True
            
            state.CreateNewName("Reallocate", " ")
        
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
        var err_flag: Bool = False
        state.copyfile(state.FileNamePath + "." + arg_idf_extension,
                      state.FileNamePath + "." + arg_idf_extension + "old", err_flag)
        state.copyfile(state.FileNamePath + "." + arg_idf_extension + "new",
                      state.FileNamePath + "." + arg_idf_extension, err_flag)
        
        if state.file_exists(state.FileNamePath + ".rvi"):
            state.copyfile(state.FileNamePath + ".rvi", state.FileNamePath + ".rviold", err_flag)
        
        if state.file_exists(state.FileNamePath + ".rvinew"):
            state.copyfile(state.FileNamePath + ".rvinew", state.FileNamePath + ".rvi", err_flag)
        
        if state.file_exists(state.FileNamePath + ".mvi"):
            state.copyfile(state.FileNamePath + ".mvi", state.FileNamePath + ".mviold", err_flag)
        
        if state.file_exists(state.FileNamePath + ".mvinew"):
            state.copyfile(state.FileNamePath + ".mvinew", state.FileNamePath + ".mvi", err_flag)
