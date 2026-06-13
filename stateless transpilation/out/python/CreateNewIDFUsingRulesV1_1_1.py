# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, Blank, ProgramPath
# - DataVCompareGlobals: IDFRecords, NumIDFRecords, Comments, CurComment, ObjectDef, NumObjectDefs
#   VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath
#   FullFileName, FileNamePath, Auditf, ProcessingIMFFile, FatalError, OldRepVarName, NewRepVarName, NumRepVarNames, NotInNew
# - InputProcessor: GetNewUnitNumber, FindNumber, ProcessInput
# - VCompareGlobalRoutines: FindItemInList, GetObjectDefInIDD, GetNewObjectDefInIDD, WriteOutIDFLinesAsComments, WriteOutIDFLines, GetNumObjectsFound, CheckSpecialObjects, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CloseOut, CreateNewName
# - General: DisplayString, MakeUPPERCase, MakeLowerCase, TrimTrailZeros, samestring, copyfile
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError


def set_this_version_variables(data_state):
    data_state.VerString = 'Conversion 1.1 => 1.1.1'
    data_state.VersionNum = 1.0
    data_state.IDDFileNameWithPath = data_state.ProgramPath.rstrip() + 'V1-1-0-Energy+.idd'
    data_state.NewIDDFileNameWithPath = data_state.ProgramPath.rstrip() + 'V1-1-1-Energy+.idd'
    data_state.RepVarFileNameWithPath = data_state.ProgramPath.rstrip() + 'Report Variables 1-1-0-020 to 1-1-1.csv'


def create_new_idf_using_rules(data_state, end_of_file, diff_only, in_lfn, ask_for_input, input_file_name, arg_file, arg_idf_extension):
    cond_eq_strings = [
        'COOLING TOWER:SINGLE SPEED    ',
        'COOLING TOWER:TWO SPEED       ',
        'GROUND HEAT EXCHANGER:VERTICAL',
        'GROUND HEAT EXCHANGER:SURFACE ',
        'GROUND HEAT EXCHANGER:POND    '
    ]
    num_cond_eq = 5
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = data_state.input_lines[data_state.input_line_index]
                        data_state.input_line_index += 1
                        ios = 0
                    except IndexError:
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
                data_state.DisplayString('Processing IDF -- ' + full_file_name.strip())
                data_state.Auditf.write(' Processing IDF -- ' + full_file_name.strip() + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    data_state.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.strip() + '.idf'
                    local_file_extension = 'idf'
                
                data_state.FileNamePath = file_name_path
                
                try:
                    with open(full_file_name, 'r') as f:
                        file_ok = True
                except FileNotFoundError:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    data_state.Auditf.write('File not found=' + full_file_name + '\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    checkrvi = False
                    if diff_only:
                        dif_lfn = open(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        dif_lfn = open(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        data_state.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', data_state.Auditf)
                        data_state.ProcessingIMFFile = True
                    else:
                        data_state.ProcessingIMFFile = False
                    
                    data_state.ProcessInput(data_state.IDDFileNameWithPath, data_state.NewIDDFileNameWithPath, full_file_name)
                    
                    if data_state.FatalError:
                        exit_because_bad_file = True
                        dif_lfn.close()
                        break
                    
                    alphas = ['' for _ in range(data_state.MaxAlphaArgsFound)]
                    numbers = [0.0 for _ in range(data_state.MaxNumericArgsFound)]
                    in_args = ['' for _ in range(data_state.MaxTotalArgs)]
                    aor_n = [False for _ in range(data_state.MaxTotalArgs)]
                    req_fld = [False for _ in range(data_state.MaxTotalArgs)]
                    fld_names = ['' for _ in range(data_state.MaxTotalArgs)]
                    fld_defaults = ['' for _ in range(data_state.MaxTotalArgs)]
                    fld_units = ['' for _ in range(data_state.MaxTotalArgs)]
                    nw_aor_n = [False for _ in range(data_state.MaxTotalArgs)]
                    nw_req_fld = [False for _ in range(data_state.MaxTotalArgs)]
                    nw_fld_names = ['' for _ in range(data_state.MaxTotalArgs)]
                    nw_fld_defaults = ['' for _ in range(data_state.MaxTotalArgs)]
                    nw_fld_units = ['' for _ in range(data_state.MaxTotalArgs)]
                    out_args = ['' for _ in range(data_state.MaxTotalArgs)]
                    match_arg = [False for _ in range(data_state.MaxTotalArgs)]
                    delete_this_record = [False for _ in range(data_state.NumIDFRecords)]
                    
                    no_version = True
                    for num in range(data_state.NumIDFRecords):
                        if data_state.make_upper_case(data_state.IDFRecords[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    lrbo = data_state.GetNumObjectsFound('LOAD RANGE BASED OPERATION')
                    clrbo = data_state.GetNumObjectsFound('COOLING LOAD RANGE BASED OPERATION')
                    hlrbo = data_state.GetNumObjectsFound('HEATING LOAD RANGE BASED OPERATION')
                    count = lrbo + clrbo + hlrbo
                    lrbo_scheme = ['' for _ in range(count)]
                    lrbo_type = [0 for _ in range(count)]
                    lrbo = 0
                    
                    for num in range(data_state.NumIDFRecords):
                        obj_name_upper = data_state.make_upper_case(data_state.IDFRecords[num]['Name'].strip())
                        
                        if obj_name_upper == 'LOAD RANGE BASED OPERATION':
                            object_name = data_state.IDFRecords[num]['Name']
                            if data_state.FindItemInList(object_name, data_state.ObjectDef, data_state.NumObjectDefs) != 0:
                                data_state.GetObjectDefInIDD(object_name, aor_n, req_fld, fld_names, fld_defaults, fld_units)
                            
                            num_alphas = data_state.IDFRecords[num]['NumAlphas']
                            num_numbers = data_state.IDFRecords[num]['NumNumbers']
                            for i in range(num_alphas):
                                alphas[i] = data_state.IDFRecords[num]['Alphas'][i]
                            for i in range(num_numbers):
                                numbers[i] = data_state.IDFRecords[num]['Numbers'][i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = ['' for _ in range(data_state.MaxTotalArgs)]
                            out_args = ['' for _ in range(data_state.MaxTotalArgs)]
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                            
                            ffield = False
                            mxfield = False
                            minus = False
                            for arg in range(1, cur_args, 3):
                                if ffield:
                                    ffield = False
                                else:
                                    pos = out_args[arg].find('-')
                                    if pos > 0:
                                        minus = True
                                    elif minus:
                                        mxfield = True
                                
                                pos = out_args[arg+1].find('-')
                                if pos > 0:
                                    minus = True
                                elif minus:
                                    mxfield = True
                            
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = data_state.make_upper_case(in_args[0])
                            
                            if mxfield:
                                lrbo_type[lrbo-1] = 0
                            elif not minus:
                                lrbo_type[lrbo-1] = 2
                            else:
                                lrbo_type[lrbo-1] = 1
                        
                        elif obj_name_upper == 'HEATING LOAD RANGE BASED OPERATION':
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = data_state.make_upper_case(data_state.IDFRecords[num]['Alphas'][0])
                            lrbo_type[lrbo-1] = 2
                        
                        elif obj_name_upper == 'COOLING LOAD RANGE BASED OPERATION':
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = data_state.make_upper_case(data_state.IDFRecords[num]['Alphas'][0])
                            lrbo_type[lrbo-1] = 1
                    
                    for num in range(data_state.NumIDFRecords):
                        if data_state.make_upper_case(data_state.IDFRecords[num]['Name']) not in ['PLANT OPERATION SCHEMES', 'CONDENSER OPERATION SCHEMES']:
                            continue
                        
                        num_alphas = data_state.IDFRecords[num]['NumAlphas']
                        num_numbers = data_state.IDFRecords[num]['NumNumbers']
                        for arg in range(1, num_alphas, 3):
                            if data_state.make_upper_case(data_state.IDFRecords[num]['Alphas'][arg]) != 'LOAD RANGE BASED OPERATION':
                                continue
                            found = data_state.FindItemInList(data_state.make_upper_case(data_state.IDFRecords[num]['Alphas'][arg+1]), lrbo_scheme, lrbo)
                            if found != 0:
                                if lrbo_type[found-1] == 1:
                                    data_state.IDFRecords[num]['Alphas'][arg] = 'COOLING LOAD RANGE BASED OPERATION'
                                elif lrbo_type[found-1] == 2:
                                    data_state.IDFRecords[num]['Alphas'][arg] = 'HEATING LOAD RANGE BASED OPERATION'
                    
                    for num in range(data_state.NumIDFRecords):
                        for xcount in range(data_state.IDFRecords[num]['CommtS']+1, data_state.IDFRecords[num]['CommtE']+1):
                            dif_lfn.write(data_state.Comments[xcount-1].strip() + '\n')
                            if xcount == data_state.IDFRecords[num]['CommtE']:
                                dif_lfn.write(' \n')
                        
                        if no_version and num == 0:
                            data_state.GetNewObjectDefInIDD('VERSION', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '1.1.1'
                            cur_args = 1
                            data_state.WriteOutIDFLinesAsComments(dif_lfn, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = data_state.IDFRecords[num]['Name']
                        if data_state.FindItemInList(object_name, data_state.ObjectDef, data_state.NumObjectDefs) != 0:
                            data_state.GetObjectDefInIDD(object_name, aor_n, req_fld, fld_names, fld_defaults, fld_units)
                            num_alphas = data_state.IDFRecords[num]['NumAlphas']
                            num_numbers = data_state.IDFRecords[num]['NumNumbers']
                            for i in range(num_alphas):
                                alphas[i] = data_state.IDFRecords[num]['Alphas'][i]
                            for i in range(num_numbers):
                                numbers[i] = data_state.IDFRecords[num]['Numbers'][i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = ['' for _ in range(data_state.MaxTotalArgs)]
                            out_args = ['' for _ in range(data_state.MaxTotalArgs)]
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
                            data_state.Auditf.write('Object="' + object_name.strip() + '" does not seem to be on the "old" IDD.\n')
                            data_state.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            data_state.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = data_state.IDFRecords[num]['NumAlphas']
                            num_numbers = data_state.IDFRecords[num]['NumNumbers']
                            for i in range(num_alphas):
                                alphas[i] = data_state.IDFRecords[num]['Alphas'][i]
                            for i in range(num_numbers):
                                numbers[i] = data_state.IDFRecords[num]['Numbers'][i]
                            
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = ['' for _ in range(data_state.MaxTotalArgs)]
                            nw_fld_units = ['' for _ in range(data_state.MaxTotalArgs)]
                            data_state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            written = True
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if data_state.FindItemInList(data_state.make_upper_case(object_name), data_state.NotInNew, len(data_state.NotInNew)) == 0:
                            data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        if not data_state.MakingPretty:
                            obj_upper = data_state.make_upper_case(data_state.IDFRecords[num]['Name'].strip())
                            
                            if obj_upper == 'VERSION':
                                if in_args[0][:5] == '1.1.1' and arg_file:
                                    data_state.ShowWarningError('File is already at latest version.  No new diff file made.', data_state.Auditf)
                                    dif_lfn.close()
                                    latest_version = True
                                    break
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '1.1.1'
                            
                            elif obj_upper == 'SKY RADIANCE DISTRIBUTION':
                                written = True
                            
                            elif obj_upper == 'SURFACE:SHADING:DETACHED':
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                            
                            elif obj_upper == 'DAYLIGHTING':
                                if cur_args > 5:
                                    data_state.GetNewObjectDefInIDD('DAYLIGHTING:DETAILED', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = 'Daylighting:Detailed'
                                    out_args[0] = in_args[0]
                                    out_args[1:cur_args-3] = in_args[4:cur_args]
                                    cur_args = cur_args - 3
                                else:
                                    data_state.GetNewObjectDefInIDD('DAYLIGHTING:SIMPLE', nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = 'Daylighting:Simple'
                                    out_args[:4] = in_args[:4]
                                    cur_args = 4
                            
                            elif obj_upper == 'LOAD RANGE BASED OPERATION':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args = in_args[:]
                                ffield = True
                                mxfield = False
                                minus = False
                                for arg in range(1, cur_args, 3):
                                    if ffield:
                                        ffield = False
                                    else:
                                        pos = out_args[arg].find('-')
                                        if pos > 0:
                                            minus = True
                                        elif minus:
                                            mxfield = True
                                    
                                    pos = out_args[arg+1].find('-')
                                    if pos > 0:
                                        minus = True
                                    elif minus:
                                        mxfield = True
                                
                                if mxfield:
                                    dif_lfn.write(' ! Next object is obsolete, needs hand transition to new\n')
                                elif not minus:
                                    object_name = 'Heating Load Range Based Operation'
                                else:
                                    object_name = 'Cooling Load Range Based Operation'
                                    for arg in range(1, cur_args, 3):
                                        pos = out_args[arg].find('-')
                                        if pos > 0:
                                            out_args[arg] = out_args[arg][:pos] + ' ' + out_args[arg][pos+1:]
                                        pos = out_args[arg+1].find('-')
                                        if pos > 0:
                                            out_args[arg+1] = out_args[arg+1][:pos] + ' ' + out_args[arg+1][pos+1:]
                            
                            elif obj_upper == 'PLANT OPERATION SCHEMES':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                            
                            elif obj_upper == 'CONDENSER OPERATION SCHEMES':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                            
                            elif obj_upper == 'HEAT RECOVERY LOOP':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                                data_state.ShowWarningError('Object=HEAT RECOVERY LOOP=' + out_args[0].strip() + ' is obsolete.  Convert to new scheme.', data_state.Auditf)
                                dif_lfn.write(' ! Next object is obsolete.  Convert to new scheme\n')
                            
                            elif obj_upper == 'LOAD RANGE EQUIPMENT LIST':
                                nodiff = False
                                mxfield = False
                                new_obj_name = ''
                                match_eq = 0
                                for arg in range(1, cur_args, 2):
                                    uc_line_name = data_state.make_upper_case(in_args[arg])
                                    for varg in range(num_cond_eq):
                                        if uc_line_name == cond_eq_strings[varg]:
                                            match_eq = 1
                                            new_obj_name = 'CONDENSER EQUIPMENT LIST'
                                            break
                                    if match_eq == 1:
                                        break
                                
                                if match_eq != 1:
                                    new_obj_name = 'PLANT EQUIPMENT LIST'
                                
                                for arg in range(1, cur_args, 2):
                                    uc_line_name = data_state.make_upper_case(in_args[arg])
                                    found = data_state.FindItemInList(uc_line_name, cond_eq_strings, num_cond_eq)
                                    if found != 0:
                                        if new_obj_name != '' and new_obj_name != 'CONDENSER EQUIPMENT LIST':
                                            mxfield = True
                                        else:
                                            new_obj_name = 'CONDENSER EQUIPMENT LIST'
                                    else:
                                        if new_obj_name != '' and new_obj_name != 'PLANT EQUIPMENT LIST':
                                            mxfield = True
                                        else:
                                            new_obj_name = 'PLANT EQUIPMENT LIST'
                                
                                if new_obj_name == '' or mxfield:
                                    new_obj_name = 'LOAD RANGE EQUIPMENT LIST'
                                
                                data_state.GetNewObjectDefInIDD(new_obj_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                if mxfield:
                                    data_state.ShowWarningError('Object LOAD RANGE EQUIPMENT LIST=' + out_args[0].strip() + ' has mixed Plant and Condenser Equipment.  Needs hand transition.', data_state.Auditf)
                                    dif_lfn.write(' ! Next object is obsolete and has Mixed Plant and Condenser Equipment, needs hand transition to new\n')
                                object_name = new_obj_name
                            
                            elif obj_upper == 'HEAT EXCHANGER:HYDRONIC:FREE COOLING':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                                dif_lfn.write(' ! Next object has new fields that need hand transition to new.\n')
                            
                            elif obj_upper in ['DESIGNDAY', 'ELECTRIC EQUIPMENT', 'BUILDING', 'PURCHASED AIR', 'CHILLER:COMBUSTION TURBINE', 'CHILLER:ENGINEDRIVEN', 'HEAT EXCHANGER:AIR TO AIR:GENERIC']:
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                                for arg in range(cur_args, nw_fld_defaults.__len__()):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = nw_fld_defaults.__len__()
                            
                            elif obj_upper == 'WATERHEATER:SIMPLE':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = False
                                for arg in range(cur_args, nw_fld_defaults.__len__()):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = nw_fld_defaults.__len__()
                            
                            elif obj_upper == 'WINDOWSHADINGCONTROL':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                nodiff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if data_state.samestring('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if data_state.samestring('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if data_state.samestring('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if data_state.samestring('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if data_state.samestring('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if data_state.samestring('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if data_state.samestring('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if data_state.samestring('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutsideAirTemp'
                                if data_state.samestring('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemp'
                                if data_state.samestring('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if data_state.samestring('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if data_state.samestring('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif obj_upper == 'REPORT VARIABLE':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = False
                                data_state.ScanOutputVariablesForReplacement(2, del_this, checkrvi, nodiff, object_name, dif_lfn, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper in ['REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY']:
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                del_this = False
                                data_state.ScanOutputVariablesForReplacement(1, del_this, checkrvi, nodiff, object_name, dif_lfn, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'REPORT:TABLE:TIMEBINS':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = False
                                data_state.ScanOutputVariablesForReplacement(2, del_this, checkrvi, nodiff, object_name, dif_lfn, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'REPORT:TABLE:MONTHLY':
                                data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = data_state.make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    
                                    del_this = False
                                    for arg in range(data_state.NumRepVarNames):
                                        uc_comp_rep_var_name = data_state.make_upper_case(data_state.OldRepVarName[arg])
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if data_state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < data_state.NumRepVarNames and data_state.OldRepVarName[arg] == data_state.OldRepVarName[arg+1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg+1]
                                                else:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg+1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            
                                            if arg + 2 < data_state.NumRepVarNames and data_state.OldRepVarName[arg] == data_state.OldRepVarName[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg+2]
                                                else:
                                                    out_args[cur_var] = data_state.NewRepVarName[arg+2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            else:
                                if data_state.FindItemInList(object_name, data_state.NotInNew, len(data_state.NotInNew)) != 0:
                                    data_state.Auditf.write('Object="' + object_name.strip() + '" is not in the "new" IDD.\n')
                                    data_state.Auditf.write('... will be listed as comments on the new output file.\n')
                                    data_state.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    continue
                                else:
                                    data_state.GetNewObjectDefInIDD(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    nodiff = True
                        
                        else:
                            data_state.GetNewObjectDefInIDD(data_state.IDFRecords[num]['Name'], nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if not nodiff or not diff_only:
                            if not written:
                                data_state.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                            
                            if not written:
                                data_state.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if data_state.IDFRecords[data_state.NumIDFRecords-1]['CommtE'] != data_state.CurComment:
                        for xcount in range(data_state.IDFRecords[data_state.NumIDFRecords-1]['CommtE'], data_state.CurComment):
                            dif_lfn.write(data_state.Comments[xcount].strip() + '\n')
                            if xcount == data_state.IDFRecords[data_state.NumIDFRecords-1]['CommtE']:
                                dif_lfn.write(' \n')
                    
                    dif_lfn.close()
                    if checkrvi:
                        data_state.ProcessRviMviFiles(file_name_path, 'rvi')
                        data_state.ProcessRviMviFiles(file_name_path, 'mvi')
                    data_state.CloseOut()
                else:
                    data_state.ProcessRviMviFiles(file_name_path, 'rvi')
                    data_state.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            data_state.CreateNewName('Reallocate', '', ' ')
        
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
        data_state.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        data_state.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag)
        try:
            with open(file_name_path + '.rvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            data_state.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        try:
            with open(file_name_path + '.rvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            data_state.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        try:
            with open(file_name_path + '.mvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            data_state.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        try:
            with open(file_name_path + '.mvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            data_state.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
    
    return end_of_file
