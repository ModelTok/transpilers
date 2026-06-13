# EXTERNAL DEPS (to wire in glue):
# From DataStringGlobals:
#   - VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath
#   - RepVarFileNameWithPath, ProgramPath, MaxNameLength, blank, FullFileName
#   - ProcessingIMFFile, Auditf (file handle)
# From DataVCompareGlobals:
#   - IDFRecords, FatalError, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
#   - NumIDFRecords, CurComment, OldRepVarName, NewRepVarName, NumRepVarNames
#   - NotInNew, ObjectDef, NumObjectDefs, MakingPretty
# From InputProcessor:
#   - GetNewObjectDefInIDD, GetObjectDefInIDD, ProcessInput, FindItemInList
#   - WriteOutIDFLines, WriteOutIDFLinesAsComments
# From VCompareGlobalRoutines:
#   - DisplayString, MakeUPPERCase, MakeLowerCase, ScanOutputVariablesForReplacement
#   - CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName
#   - ProcessNumber, samestring, copyfile
# From DataGlobals:
#   - ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# External functions:
#   - GetNewUnitNumber() -> int
#   - FindNumber(str, str) -> int
#   - TrimTrailZeros(str) -> str

def set_this_version_variables(
    data_string_globals,
):
    """SetThisVersionVariables equivalent"""
    data_string_globals.VerString = 'Conversion 2.1 => 2.2'
    data_string_globals.VersionNum = 2.0
    data_string_globals.IDDFileNameWithPath = (
        data_string_globals.ProgramPath.rstrip() + 'V2-1-0-Energy+.idd'
    )
    data_string_globals.NewIDDFileNameWithPath = (
        data_string_globals.ProgramPath.rstrip() + 'V2-2-0-Energy+.idd'
    )
    data_string_globals.RepVarFileNameWithPath = (
        data_string_globals.ProgramPath.rstrip() + 'Report Variables 2-1-0-023 to 2-2-0.csv'
    )


def create_new_idf_using_rules(
    end_of_file,
    diff_only,
    in_lfn,
    ask_for_input,
    input_file_name,
    arg_file,
    arg_idf_extension,
    data_string_globals,
    data_v_compare_globals,
    input_processor,
    general,
    data_globals,
    external_funcs,
):
    """CreateNewIDFUsingRules equivalent"""
    
    max_name_length = data_string_globals.MaxNameLength
    blank = data_string_globals.blank
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension if arg_idf_extension else ' '
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
                        full_file_name = next(in_lfn)
                        ios = 0
                    except StopIteration:
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
                data_string_globals.FullFileName = full_file_name
                external_funcs['DisplayString']('Processing IDF -- ' + full_file_name.rstrip())
                data_globals.Auditf.write(' Processing IDF -- ' + full_file_name.rstrip() + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    data_globals.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = external_funcs['GetNewUnitNumber']()
                try:
                    file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_file_name.rstrip())
                    data_globals.Auditf.write('File not found=' + full_file_name.rstrip() + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'new'
                    
                    dif_file = open(dif_file_name, 'w')
                    
                    if local_file_extension == 'imf':
                        external_funcs['ShowWarningError'](
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            data_globals.Auditf
                        )
                        data_string_globals.ProcessingIMFFile = True
                    else:
                        data_string_globals.ProcessingIMFFile = False
                    
                    external_funcs['ProcessInput'](
                        data_string_globals.IDDFileNameWithPath,
                        data_string_globals.NewIDDFileNameWithPath,
                        full_file_name,
                        data_v_compare_globals,
                        input_processor,
                        external_funcs
                    )
                    
                    if data_v_compare_globals.FatalError:
                        exit_because_bad_file = True
                        dif_file.close()
                        break
                    
                    num_idf_records = data_v_compare_globals.NumIDFRecords
                    max_total_args = data_v_compare_globals.MaxTotalArgs
                    
                    alphas = [blank] * data_v_compare_globals.MaxAlphaArgsFound
                    numbers = [0.0] * data_v_compare_globals.MaxNumericArgsFound
                    in_args = [blank] * max_total_args
                    a_or_n = [False] * max_total_args
                    req_fld = [False] * max_total_args
                    fld_names = [blank] * max_total_args
                    fld_defaults = [blank] * max_total_args
                    fld_units = [blank] * max_total_args
                    nw_a_or_n = [False] * max_total_args
                    nw_req_fld = [False] * max_total_args
                    nw_fld_names = [blank] * max_total_args
                    nw_fld_defaults = [blank] * max_total_args
                    nw_fld_units = [blank] * max_total_args
                    out_args = [blank] * max_total_args
                    match_arg = [False] * max_total_args
                    delete_this_record = [False] * num_idf_records
                    
                    idf_records = data_v_compare_globals.IDFRecords
                    
                    for num in range(num_idf_records):
                        if idf_records[num]['Name'].upper() == 'CONNECTION COMPONENT:PLANTLOOP':
                            conn_comp = True
                        if idf_records[num]['Name'].upper() == 'CONNECTION COMPONENT:PLANTLOOP:CONTROLLED':
                            conn_comp_ctrl = True
                    
                    if conn_comp or conn_comp_ctrl:
                        primary_side_name = blank
                        secondary_side_name = blank
                        branch_primary_name = blank
                        branch_list_primary_name = blank
                        plant_loop_primary_name = blank
                        branch_secondary_name = blank
                        branch_list_secondary_name = blank
                        plant_loop_secondary_name = blank
                        secondary_setpoint_manager_node_name = blank
                        secondary_setpoint_manager_node_list_name = blank
                        primary_loop_num = 0
                        
                        plant_old_demand_branch_list_name = blank
                        plant_old_demand_connector_list_name = blank
                        plant_loop_primary_demand_inlet_node_name = blank
                        plant_loop_primary_demand_outlet_node_name = blank
                        plant_loop_secondary_supply_inlet_node_name = blank
                        plant_loop_secondary_supply_outlet_node_name = blank
                        
                        for num in range(num_idf_records):
                            if idf_records[num]['Name'].upper() not in ('CONNECTION COMPONENT:PLANTLOOP', 'CONNECTION COMPONENT:PLANTLOOP:CONTROLLED'):
                                continue
                            
                            primary_side_name = idf_records[num]['Alphas'][1].upper()
                            secondary_side_name = idf_records[num]['Alphas'][3].upper()
                            dif_file.write('! connection component, name=' + idf_records[num]['Alphas'][0] +
                                          ', primary side=' + primary_side_name +
                                          ', secondary side=' + secondary_side_name + '\n')
                            delete_this_record[num] = True
                            
                            for num1 in range(num_idf_records):
                                if idf_records[num1]['Name'].upper() != 'BRANCH':
                                    continue
                                if idf_records[num1]['Alphas'][3].upper() == primary_side_name:
                                    branch_primary_name = idf_records[num1]['Alphas'][0].upper()
                                    delete_this_record[num1] = True
                                    dif_file.write('! primary side branch=' + branch_primary_name + '\n')
                                if idf_records[num1]['Alphas'][3].upper() == secondary_side_name:
                                    branch_secondary_name = idf_records[num1]['Alphas'][0].upper()
                                    delete_this_record[num1] = True
                                    dif_file.write('! secondary side branch=' + branch_secondary_name + '\n')
                            
                            pump_num = 0
                            for num1 in range(num_idf_records):
                                if idf_records[num1]['Name'].upper() != 'BRANCH LIST':
                                    continue
                                for num2 in range(1, idf_records[num1]['NumAlphas']):
                                    if idf_records[num1]['Alphas'][num2].upper() == branch_primary_name:
                                        branch_list_primary_name = idf_records[num1]['Alphas'][0].upper()
                                        for num3 in range(num2, idf_records[num1]['NumAlphas'] - 1):
                                            idf_records[num1]['Alphas'][num3] = idf_records[num1]['Alphas'][num3 + 1]
                                        dif_file.write('! primary side branch list=' + branch_list_primary_name + '\n')
                                    if idf_records[num1]['Alphas'][num2].upper() == branch_secondary_name:
                                        branch_list_secondary_name = idf_records[num1]['Alphas'][0].upper()
                                        for num3 in range(num2, idf_records[num1]['NumAlphas'] - 1):
                                            idf_records[num1]['Alphas'][num3] = idf_records[num1]['Alphas'][num3 + 1]
                                        dif_file.write('! secondary side branch list=' + branch_list_secondary_name + '\n')
                            
                            for num1 in range(num_idf_records):
                                if idf_records[num1]['Name'].upper() != 'PLANT LOOP':
                                    continue
                                if idf_records[num1]['Alphas'][6].upper() == branch_list_secondary_name:
                                    delete_this_record[num1] = True
                                    dif_file.write('! secondary plant loop (from supply side=' + idf_records[num1]['Alphas'][0] + '\n')
                                    secondary_setpoint_manager_node_name = idf_records[num1]['Alphas'][3]
                                    secondary_setpoint_manager_node_list_name = secondary_setpoint_manager_node_name
                                    dif_file.write('! secondary set point manager=' + secondary_setpoint_manager_node_name + '\n')
                                    plant_loop_secondary_supply_inlet_node_name = idf_records[num1]['Alphas'][4].upper()
                                    plant_loop_secondary_supply_outlet_node_name = idf_records[num1]['Alphas'][5].upper()
                                    break
                                if idf_records[num1]['Alphas'][10].upper() == branch_list_secondary_name:
                                    dif_file.write('! secondary plant loop (from demand side)=' + idf_records[num1]['Alphas'][0] + '\n')
                                    secondary_setpoint_manager_node_name = idf_records[num1]['Alphas'][3]
                                    secondary_setpoint_manager_node_list_name = secondary_setpoint_manager_node_name
                                    dif_file.write('! secondary set point manager=' + secondary_setpoint_manager_node_name + '\n')
                                    plant_loop_secondary_supply_inlet_node_name = idf_records[num1]['Alphas'][4].upper()
                                    plant_loop_secondary_supply_outlet_node_name = idf_records[num1]['Alphas'][5].upper()
                            
                            for num2 in range(num_idf_records):
                                if idf_records[num2]['Name'].upper() != 'PLANT LOOP':
                                    continue
                                if idf_records[num2]['Alphas'][6].upper() == branch_list_primary_name:
                                    dif_file.write('! primary plant loop (from supply side=' + idf_records[num2]['Alphas'][0] + '\n')
                                if idf_records[num2]['Alphas'][10].upper() == branch_list_primary_name:
                                    alphas_copy = idf_records[num2]['Alphas'][:idf_records[num2]['NumAlphas']]
                                    idf_records[num2]['Alphas'] = [blank] * 16
                                    for idx, val in enumerate(alphas_copy):
                                        idf_records[num2]['Alphas'][idx] = val
                                    
                                    dif_file.write('! primary plant loop (from demand side=' + idf_records[num2]['Alphas'][0] + '\n')
                                    plant_old_demand_branch_list_name = idf_records[num2]['Alphas'][10].upper()
                                    plant_old_demand_connector_list_name = idf_records[num2]['Alphas'][11].upper()
                                    plant_loop_primary_demand_inlet_node_name = idf_records[num2]['Alphas'][8].upper()
                                    plant_loop_primary_demand_outlet_node_name = idf_records[num2]['Alphas'][9].upper()
                                    
                                    idf_records[num2]['Alphas'][8] = idf_records[num1]['Alphas'][8]
                                    idf_records[num2]['Alphas'][9] = idf_records[num1]['Alphas'][9]
                                    idf_records[num2]['Alphas'][10] = idf_records[num1]['Alphas'][10]
                                    idf_records[num2]['Alphas'][11] = idf_records[num1]['Alphas'][11]
                                    primary_loop_num = num2
                                    
                                    if idf_records[num]['Name'].upper() == 'CONNECTION COMPONENT:PLANTLOOP':
                                        idf_records[num2]['Alphas'][15] = 'Common Pipe'
                                        idf_records[num2]['NumAlphas'] = 16
                                    else:
                                        idf_records[num2]['Alphas'][15] = 'Two Way Common Pipe'
                                        idf_records[num2]['NumAlphas'] = 16
                                    
                                    for num3 in range(num_idf_records):
                                        if idf_records[num3]['Name'].upper() == 'PLANT OPERATION SCHEMES':
                                            if idf_records[num1]['Alphas'][2].upper() == idf_records[num3]['Alphas'][0].upper():
                                                delete_this_record[num3] = True
                                                dif_file.write('! secondary plant loop, op scheme=' + idf_records[num3]['Alphas'][0] + '\n')
                                                
                                                for num4 in range(1, idf_records[num3]['NumAlphas'], 3):
                                                    for num5 in range(num_idf_records):
                                                        if idf_records[num5]['Name'].upper() != idf_records[num3]['Alphas'][num4].upper():
                                                            continue
                                                        if idf_records[num5]['Alphas'][0].upper() != idf_records[num3]['Alphas'][num4 + 1].upper():
                                                            continue
                                                        delete_this_record[num5] = True
                                                        
                                                        for num6 in range(1, idf_records[num5]['NumAlphas']):
                                                            for num7 in range(num_idf_records):
                                                                if idf_records[num7]['Name'].upper() != 'PLANT EQUIPMENT LIST':
                                                                    continue
                                                                if idf_records[num7]['Alphas'][0].upper() != idf_records[num5]['Alphas'][num6].upper():
                                                                    continue
                                                                delete_this_record[num7] = True
                                        
                                        if idf_records[num3]['Name'].upper() == 'BRANCH LIST':
                                            if idf_records[num1]['Alphas'][6].upper() == idf_records[num3]['Alphas'][0].upper():
                                                delete_this_record[num3] = True
                                                dif_file.write('! secondary plant loop, supply branch list=' + idf_records[num3]['Alphas'][0] + '\n')
                                                
                                                for num4 in range(1, idf_records[num3]['NumAlphas']):
                                                    for num5 in range(num_idf_records):
                                                        if idf_records[num5]['Name'].upper() != 'BRANCH':
                                                            continue
                                                        if idf_records[num3]['Alphas'][num4].upper() != idf_records[num5]['Alphas'][0].upper():
                                                            continue
                                                        delete_this_record[num5] = True
                                                        dif_file.write('! secondary plant loop, branch=' + idf_records[num5]['Alphas'][0] + '\n')
                                                        
                                                        for num6 in range(1, idf_records[num5]['NumAlphas'], 5):
                                                            test_name = idf_records[num5]['Alphas'][num6].upper()
                                                            if test_name[:4] == 'PUMP':
                                                                for num7 in range(num_idf_records):
                                                                    if idf_records[num5]['Alphas'][num6].upper() == idf_records[num7]['Name'].upper():
                                                                        if idf_records[num5]['Alphas'][num6 + 1].upper() == idf_records[num7]['Alphas'][0].upper():
                                                                            pump_num = num7
                                                                            dif_file.write('! secondary plant loop, supply side pump=' +
                                                                                         idf_records[num7]['Name'] + ':' + idf_records[num7]['Alphas'][0] + '\n')
                                                                            break
                                                            else:
                                                                for num7 in range(num_idf_records):
                                                                    if idf_records[num5]['Alphas'][num6].upper() == idf_records[num7]['Name'].upper():
                                                                        if idf_records[num5]['Alphas'][num6 + 1].upper() == idf_records[num7]['Alphas'][0].upper():
                                                                            delete_this_record[num7] = True
                                                                            dif_file.write('! secondary plant loop, branch component=' +
                                                                                         idf_records[num7]['Name'] + ':' + idf_records[num7]['Alphas'][0] + '\n')
                            
                            if idf_records[num]['Name'].upper() == 'CONNECTION COMPONENT:PLANTLOOP':
                                success = False
                                for num2 in range(num_idf_records):
                                    if idf_records[num2]['Name'].upper() != 'NODE LIST':
                                        continue
                                    if idf_records[num2]['Alphas'][0].upper() != secondary_setpoint_manager_node_list_name.upper():
                                        continue
                                    success = True
                                    break
                                
                                if not success:
                                    for num2 in range(num_idf_records):
                                        if idf_records[num2]['Name'].upper() != 'NODE LIST':
                                            continue
                                        for num3 in range(1, idf_records[num2]['NumAlphas']):
                                            if idf_records[num2]['Alphas'][num3].upper() != secondary_setpoint_manager_node_name.upper():
                                                continue
                                            secondary_setpoint_manager_node_list_name = idf_records[num2]['Alphas'][0]
                                            success = True
                                            break
                                
                                success = False
                                for num3 in range(num_idf_records):
                                    name_upper = idf_records[num3]['Name'].upper()
                                    if name_upper == 'SET POINT MANAGER:SCHEDULED':
                                        if (idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:SCHEDULED:DUALSETPOINT':
                                        if (idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:OUTSIDE AIR':
                                        if (idf_records[num3]['Alphas'][2].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][2].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper in ('SET POINT MANAGER:SINGLE ZONE REHEAT', 'SET POINT MANAGER:SINGLE ZONE HEATING',
                                                        'SET POINT MANAGER:SINGLE ZONE COOLING', 'SET POINT MANAGER:MIXED AIR'):
                                        if (idf_records[num3]['Alphas'][5].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][5].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper in ('SET POINT MANAGER:SINGLE ZONE MIN HUM', 'SET POINT MANAGER:WARMEST',
                                                        'SET POINT MANAGER:COLDEST'):
                                        if (idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:SINGLE ZONE MAX HUM':
                                        if (idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:OUTSIDE AIR PRETREAT':
                                        if (idf_records[num3]['Alphas'][6].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][6].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:WARMEST TEMP FLOW':
                                        if (idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        delete_this_record[num3] = True
                                        success = True
                            else:
                                if primary_loop_num == 0:
                                    continue
                                
                                success = False
                                for num2 in range(num_idf_records):
                                    if idf_records[num2]['Name'].upper() != 'NODE LIST':
                                        continue
                                    if idf_records[num2]['Alphas'][0].upper() != secondary_setpoint_manager_node_list_name.upper():
                                        continue
                                    success = True
                                    break
                                
                                if not success:
                                    for num2 in range(num_idf_records):
                                        if idf_records[num2]['Name'].upper() != 'NODE LIST':
                                            continue
                                        for num3 in range(1, idf_records[num2]['NumAlphas']):
                                            if idf_records[num2]['Alphas'][num3].upper() != secondary_setpoint_manager_node_name.upper():
                                                continue
                                            secondary_setpoint_manager_node_list_name = idf_records[num2]['Alphas'][0]
                                            success = True
                                            break
                                
                                success = False
                                for num3 in range(num_idf_records):
                                    name_upper = idf_records[num3]['Name'].upper()
                                    if name_upper in ('SET POINT MANAGER:SCHEDULED', 'SET POINT MANAGER:SINGLE ZONE MAX HUM'):
                                        if (idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][3].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        dif_file.write('! replacing setpoint node on primary loop with reference ' +
                                                     idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                        idf_records[num3]['Alphas'][3] = idf_records[primary_loop_num]['Alphas'][8]
                                        success = True
                                    elif name_upper in ('SET POINT MANAGER:SCHEDULED:DUALSETPOINT', 'SET POINT MANAGER:SINGLE ZONE MIN HUM',
                                                        'SET POINT MANAGER:WARMEST', 'SET POINT MANAGER:COLDEST', 'SET POINT MANAGER:WARMEST TEMP FLOW'):
                                        if (idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][4].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        dif_file.write('! replacing setpoint node on primary loop with reference ' +
                                                     idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                        idf_records[num3]['Alphas'][4] = idf_records[primary_loop_num]['Alphas'][8]
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:OUTSIDE AIR':
                                        if (idf_records[num3]['Alphas'][2].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][2].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        dif_file.write('! replacing setpoint node on primary loop with reference ' +
                                                     idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                        idf_records[num3]['Alphas'][2] = idf_records[primary_loop_num]['Alphas'][8]
                                        success = True
                                    elif name_upper in ('SET POINT MANAGER:SINGLE ZONE REHEAT', 'SET POINT MANAGER:SINGLE ZONE HEATING',
                                                        'SET POINT MANAGER:SINGLE ZONE COOLING', 'SET POINT MANAGER:MIXED AIR'):
                                        if (idf_records[num3]['Alphas'][5].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][5].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        dif_file.write('! replacing setpoint node on primary loop with reference ' +
                                                     idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                        idf_records[num3]['Alphas'][5] = idf_records[primary_loop_num]['Alphas'][8]
                                        success = True
                                    elif name_upper == 'SET POINT MANAGER:OUTSIDE AIR PRETREAT':
                                        if (idf_records[num3]['Alphas'][6].upper() != secondary_setpoint_manager_node_list_name.upper() and
                                            idf_records[num3]['Alphas'][6].upper() != secondary_setpoint_manager_node_name.upper()):
                                            continue
                                        dif_file.write('! replacing setpoint node on primary loop with reference ' +
                                                     idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                        idf_records[num3]['Alphas'][6] = idf_records[primary_loop_num]['Alphas'][8]
                                        success = True
                                    elif name_upper == 'SYSTEM AVAILABILITY MANAGER:DIFFERENTIAL THERMOSTAT':
                                        if (idf_records[num3]['Alphas'][1] == plant_loop_secondary_supply_inlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_secondary_supply_outlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_primary_demand_inlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_primary_demand_outlet_node_name or
                                            idf_records[num3]['Alphas'][2] == plant_loop_secondary_supply_inlet_node_name or
                                            idf_records[num3]['Alphas'][2] == plant_loop_secondary_supply_outlet_node_name or
                                            idf_records[num3]['Alphas'][2] == plant_loop_primary_demand_inlet_node_name or
                                            idf_records[num3]['Alphas'][2] == plant_loop_primary_demand_outlet_node_name):
                                            dif_file.write('! found node to be deleted on System Availability Manager, ' +
                                                         idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                            dif_file.write('Preprocessor Message,' + data_string_globals.ProgNameConversion + ', Severe,\n')
                                            dif_file.write(idf_records[num3]['Name'] + ',\n')
                                            dif_file.write(idf_records[num3]['Alphas'][0].upper() + ',\n')
                                            dif_file.write('contains a reference to a primary/secondary plant loop node that will be removed,\n')
                                            dif_file.write('due to transition of Connection Component:Plant Loop:Controlled,\n')
                                            dif_file.write(idf_records[num]['Alphas'][0].upper() + '.,\n')
                                            dif_file.write('This will not transition automatically.  Please contact EnergyPlus Support.;\n')
                                    elif name_upper in ('SYSTEM AVAILABILITY MANAGER:HIGH TEMPERATURE TURN OFF', 'SYSTEM AVAILABILITY MANAGER:HIGH TEMPERATURE TURN ON',
                                                        'SYSTEM AVAILABILITY MANAGER:LOW TEMPERATURE TURN OFF', 'SYSTEM AVAILABILITY MANAGER:LOW TEMPERATURE TURN ON'):
                                        if (idf_records[num3]['Alphas'][1] == plant_loop_secondary_supply_inlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_secondary_supply_outlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_primary_demand_inlet_node_name or
                                            idf_records[num3]['Alphas'][1] == plant_loop_primary_demand_outlet_node_name):
                                            dif_file.write('! found node to be deleted on System Availability Manager, ' +
                                                         idf_records[num3]['Name'] + ':' + idf_records[num3]['Alphas'][0].upper() + '\n')
                                            dif_file.write('Preprocessor Message,' + data_string_globals.ProgNameConversion + ', Severe,\n')
                                            dif_file.write(idf_records[num3]['Name'] + ',\n')
                                            dif_file.write(idf_records[num3]['Alphas'][0].upper() + ',\n')
                                            dif_file.write('contains a reference to a primary/secondary plant loop node that will be removed,\n')
                                            dif_file.write('due to transition of Connection Component:Plant Loop:Controlled,\n')
                                            dif_file.write(idf_records[num]['Alphas'][0].upper() + '.,\n')
                                            dif_file.write('This will not transition automatically.  Please contact EnergyPlus Support.;\n')
                    
                    no_version = True
                    for num in range(num_idf_records):
                        if idf_records[num]['Name'].upper() == 'VERSION':
                            no_version = False
                            break
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + idf_records[num]['Name'] + ':' + idf_records[num]['Alphas'][0] + '\n')
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(idf_records[num]['CommtS'], idf_records[num]['CommtE'] + 1):
                            dif_file.write(data_v_compare_globals.Comments[xcount] + '\n')
                            if xcount == idf_records[num]['CommtE']:
                                dif_file.write('\n')
                        
                        if no_version and num == 0:
                            external_funcs['GetNewObjectDefInIDD'](
                                'VERSION', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                data_v_compare_globals, input_processor
                            )
                            out_args[0] = '2.2'
                            cur_args = 1
                            external_funcs['WriteOutIDFLines'](
                                dif_file, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units,
                                data_v_compare_globals, external_funcs
                            )
                        
                        object_name = idf_records[num]['Name']
                        
                        if object_name.upper() in ('SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA'):
                            continue
                        
                        if object_name.upper() == 'WATER HEATER:SIMPLE':
                            dif_file.write('! The WATER HEATER:SIMPLE object has been deleted\n')
                            continue
                        
                        if external_funcs['FindItemInList'](object_name, data_v_compare_globals.ObjectDef, data_v_compare_globals.NumObjectDefs,
                                                           input_processor):
                            external_funcs['GetObjectDefInIDD'](
                                object_name, a_or_n, req_fld, fld_names, fld_defaults, fld_units,
                                data_v_compare_globals, input_processor
                            )
                            num_alphas = idf_records[num]['NumAlphas']
                            num_numbers = idf_records[num]['NumNumbers']
                            alphas[:num_alphas] = idf_records[num]['Alphas'][:num_alphas]
                            numbers[:num_numbers] = idf_records[num]['Numbers'][:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [blank] * max_total_args
                            out_args = [blank] * max_total_args
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if a_or_n[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na - 1]
                                else:
                                    nn += 1
                                    in_args[arg] = str(numbers[nn - 1])
                        else:
                            data_globals.Auditf.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                            data_globals.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            data_globals.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = idf_records[num]['NumAlphas']
                            num_numbers = idf_records[num]['NumNumbers']
                            alphas[:num_alphas] = idf_records[num]['Alphas'][:num_alphas]
                            numbers[:num_numbers] = idf_records[num]['Numbers'][:num_numbers]
                            out_args = [blank] * max_total_args
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn - 1] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [blank] * max_total_args
                            nw_fld_units = [blank] * max_total_args
                            external_funcs['WriteOutIDFLinesAsComments'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                data_v_compare_globals, external_funcs
                            )
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if external_funcs['FindItemInList'](object_name.upper(), data_v_compare_globals.NotInNew, len(data_v_compare_globals.NotInNew),
                                                           input_processor) == 0:
                            external_funcs['GetNewObjectDefInIDD'](
                                object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                data_v_compare_globals, input_processor
                            )
                        
                        if not data_v_compare_globals.MakingPretty:
                            object_upper = object_name.upper()
                            
                            if object_upper == 'VERSION':
                                if in_args[0][:3] == '2.2' and arg_file:
                                    external_funcs['ShowWarningError'](
                                        'File is already at latest version.  No new diff file made.',
                                        data_globals.Auditf
                                    )
                                    dif_file.close()
                                    latest_version = True
                                    break
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = '2.2'
                                no_diff = False
                            
                            elif object_upper == 'DOMESTIC HOT WATER':
                                if in_args[1] != blank or in_args[2] != blank:
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'WATER USE CONNECTIONS', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = in_args[0]
                                    out_args[1:3] = in_args[1:3]
                                    out_args[3:6] = [blank, blank, blank]
                                    out_args[6] = in_args[5]
                                    out_args[7:10] = [blank, blank, blank]
                                    out_args[10] = in_args[0]
                                    cur_args = 11
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'WATER USE CONNECTIONS', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                
                                external_funcs['GetNewObjectDefInIDD'](
                                    'WATER USE EQUIPMENT', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[6]
                                out_args[2] = in_args[3]
                                out_args[3] = in_args[4]
                                out_args[4:6] = [blank, blank]
                                out_args[6] = in_args[5]
                                cur_args = 7
                                external_funcs['WriteOutIDFLines'](
                                    dif_file, 'WATER USE EQUIPMENT', cur_args, out_args, nw_fld_names, nw_fld_units,
                                    data_v_compare_globals, external_funcs
                                )
                                written = True
                            
                            elif object_upper == 'BRANCH':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                for arg in range(2, cur_args, 5):
                                    if out_args[arg].upper() == 'DOMESTIC HOT WATER':
                                        out_args[arg] = 'Water Use Connections'
                                        no_diff = False
                            
                            elif object_upper == 'AIR CONDITIONER:WINDOW:CYCLING':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = False
                                if in_args[11].upper() == 'CYCFANCYCCOMP':
                                    out_args[11] = 'Air Conditioner:Window ' + in_args[0].rstrip() + ' Cycling Fan Schedule'
                                    allzeroes = True
                                elif in_args[11].upper() == 'CONTFANCYCCOMP':
                                    out_args[11] = 'Air Conditioner:Window ' + in_args[0].rstrip() + ' Continuous Fan Schedule'
                                    allzeroes = False
                                else:
                                    out_args[11] = 'Invalid Supply air fan operating mode ' + in_args[11].rstrip()
                                
                                external_funcs['WriteOutIDFLines'](
                                    dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                    data_v_compare_globals, external_funcs
                                )
                                
                                if out_args[11][:7] != 'Invalid':
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULETYPE', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[11].rstrip() + ' Type'
                                    cur_args = 1
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULETYPE', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                    
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULE:COMPACT', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[11]
                                    out_args[1] = out_args[11].rstrip() + ' Type'
                                    out_args[2] = 'Through: 12/31'
                                    out_args[3] = 'For: AllDays'
                                    out_args[4] = 'Until: 24:00'
                                    out_args[5] = '0' if allzeroes else '1'
                                    cur_args = 6
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULE:COMPACT', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                written = True
                            
                            elif object_upper == 'PACKAGEDTERMINAL:HEATPUMP:AIRTOAIR':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:4] = in_args[:4]
                                out_args[4:25] = in_args[6:27]
                                cur_args = cur_args - 2
                                no_diff = False
                                if in_args[27].upper() == 'CYCFANCYCCOMP':
                                    out_args[25] = 'PackagedTerminal:HeatPump:AirToAir ' + in_args[0].rstrip() + ' Cycling Fan Schedule'
                                    allzeroes = True
                                elif in_args[27].upper() == 'CONTFANCYCCOMP':
                                    out_args[25] = 'PackagedTerminal:HeatPump:AirToAir ' + in_args[0].rstrip() + ' Continuous Fan Schedule'
                                    allzeroes = False
                                else:
                                    out_args[25] = 'Invalid Supply air fan operating mode ' + in_args[27].rstrip()
                                
                                external_funcs['WriteOutIDFLines'](
                                    dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                    data_v_compare_globals, external_funcs
                                )
                                
                                if out_args[25][:7] != 'Invalid':
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULETYPE', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[25].rstrip() + ' Type'
                                    cur_args = 1
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULETYPE', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                    
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULE:COMPACT', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[25]
                                    out_args[1] = out_args[25].rstrip() + ' Type'
                                    out_args[2] = 'Through: 12/31'
                                    out_args[3] = 'For: AllDays'
                                    out_args[4] = 'Until: 24:00'
                                    out_args[5] = '0' if allzeroes else '1'
                                    cur_args = 6
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULE:COMPACT', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                written = True
                            
                            elif object_upper == 'UNITARYSYSTEM:HEATPUMP:WATERTOAIR':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:25] = in_args[:25]
                                no_diff = False
                                if in_args[25].upper() == 'CYCFANCYCCOMP':
                                    out_args[25] = 'UnitarySystem:HeatPump:WaterToAir ' + in_args[0].rstrip() + ' Cycling Fan Schedule'
                                    allzeroes = True
                                elif in_args[25].upper() == 'CONTFANCYCCOMP':
                                    out_args[25] = 'UnitarySystem:HeatPump:WaterToAir ' + in_args[0].rstrip() + ' Continuous Fan Schedule'
                                    allzeroes = False
                                else:
                                    out_args[25] = 'Invalid Supply air fan operating mode ' + in_args[25].rstrip()
                                
                                external_funcs['WriteOutIDFLines'](
                                    dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                    data_v_compare_globals, external_funcs
                                )
                                
                                if out_args[25][:7] != 'Invalid':
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULETYPE', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[25].rstrip() + ' Type'
                                    cur_args = 1
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULETYPE', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                    
                                    external_funcs['GetNewObjectDefInIDD'](
                                        'SCHEDULE:COMPACT', nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[0] = out_args[25]
                                    out_args[1] = out_args[25].rstrip() + ' Type'
                                    out_args[2] = 'Through: 12/31'
                                    out_args[3] = 'For: AllDays'
                                    out_args[4] = 'Until: 24:00'
                                    out_args[5] = '0' if allzeroes else '1'
                                    cur_args = 6
                                    external_funcs['WriteOutIDFLines'](
                                        dif_file, 'SCHEDULE:COMPACT', cur_args, out_args, nw_fld_names, nw_fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                written = True
                            
                            elif object_upper == 'CONTROLLER:STAND ALONE ERV':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = in_args[0]
                                no_diff = False
                                out_args[1:4] = in_args[2:5]
                                cur_args = cur_args - 1
                                for arg in range(1, 4):
                                    if external_funcs['ProcessNumber'](out_args[arg]) == 0.0:
                                        out_args[arg] = blank
                                out_args[4:6] = [blank, blank]
                                out_args[6:8] = in_args[7:9]
                            
                            elif object_upper == 'ENERGY RECOVERY VENTILATOR:STAND ALONE':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:4] = in_args[:4]
                                no_diff = False
                                out_args[4] = in_args[6]
                                out_args[5:8] = in_args[9:12]
                                cur_args = cur_args - 4
                            
                            elif object_upper == 'CONTROLLER:OUTSIDE AIR':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                no_diff = False
                                out_args[:13] = in_args[:13]
                                for arg in range(10, 13):
                                    if external_funcs['ProcessNumber'](out_args[arg]) == 0.0:
                                        out_args[arg] = blank
                                out_args[13:15] = [blank, blank]
                                out_args[15:19] = in_args[13:17]
                                cur_args = cur_args + 2
                            
                            elif object_upper == 'COMPACT HVAC:SYSTEM:UNITARY':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                no_diff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                for arg in range(24, 27):
                                    if external_funcs['ProcessNumber'](out_args[arg]) == 0.0:
                                        out_args[arg] = blank
                            
                            elif object_upper == 'COMPACT HVAC:SYSTEM:VAV':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                no_diff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                for arg in range(30, 33):
                                    if external_funcs['ProcessNumber'](out_args[arg]) == 0.0:
                                        out_args[arg] = blank
                            
                            elif object_upper == 'PEOPLE':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:2] = in_args[:2]
                                no_diff = False
                                out_args[2] = in_args[3]
                                out_args[3] = 'people'
                                out_args[4] = in_args[2]
                                out_args[5:7] = [blank, blank]
                                out_args[7] = in_args[4]
                                if cur_args >= 15:
                                    out_args[8] = in_args[14]
                                else:
                                    out_args[8] = blank
                                out_args[9] = in_args[5]
                                if cur_args >= 16:
                                    out_args[10] = in_args[15]
                                else:
                                    out_args[10] = blank
                                out_args[11] = in_args[6]
                                out_args[12:19] = in_args[7:14]
                                for var in range(18, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper == 'LIGHTS':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                out_args[3] = 'lighting level'
                                out_args[4] = in_args[3]
                                out_args[5:7] = [blank, blank]
                                out_args[7:15] = in_args[4:12]
                                for var in range(14, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper in ('ELECTRIC EQUIPMENT', 'GAS EQUIPMENT', 'HOT WATER EQUIPMENT', 'STEAM EQUIPMENT', 'OTHER EQUIPMENT'):
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                out_args[3] = 'equipment level'
                                out_args[4] = in_args[3]
                                out_args[5:7] = [blank, blank]
                                out_args[7:11] = in_args[4:8]
                                for var in range(10, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper == 'INFILTRATION':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                out_args[3] = 'flow/zone'
                                out_args[4] = in_args[3]
                                out_args[5:8] = [blank, blank, blank]
                                out_args[8:12] = in_args[4:8]
                                for var in range(11, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper in ('MIXING', 'CROSS MIXING'):
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                out_args[3] = 'flow/zone'
                                out_args[4] = in_args[3]
                                out_args[5:8] = [blank, blank, blank]
                                out_args[8:12] = in_args[4:8]
                                for var in range(11, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper == 'VENTILATION':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                out_args[3] = 'flow/zone'
                                out_args[4] = in_args[3]
                                out_args[5:8] = [blank, blank, blank]
                                out_args[8:15] = in_args[6:13]
                                out_args[15] = in_args[4]
                                out_args[16] = blank
                                out_args[17] = in_args[13]
                                out_args[18] = blank
                                out_args[19] = in_args[5]
                                out_args[20] = blank
                                out_args[21] = in_args[14]
                                out_args[22] = blank
                                out_args[23] = in_args[15]
                                out_args[24] = blank
                                out_args[25] = in_args[16]
                                for var in range(25, -1, -1):
                                    if out_args[var] != blank:
                                        cur_args = var + 1
                                        break
                            
                            elif object_upper == 'GENERATOR:PV:EQUIVALENT ONE-DIODE':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:3] = in_args[:3]
                                no_diff = False
                                err_flag = False
                                save_number = external_funcs['ProcessNumber'](in_args[3])
                                if save_number == 1:
                                    out_args[3] = 'Decoupled NOCT Conditions'
                                elif save_number == 2:
                                    out_args[3] = 'Decoupled Ulleberg Dynamic'
                                else:
                                    out_args[3] = blank
                                out_args[4:24] = in_args[4:24]
                                out_args[24] = '1.0'
                                out_args[25] = '1.E+6'
                                cur_args = 26
                            
                            elif object_upper == 'ELECTRIC LOAD CENTER:GENERATORS':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = in_args[0]
                                no_diff = False
                                num_sets = 0
                                for arg in range(1, cur_args, 4):
                                    if in_args[arg] != blank:
                                        num_sets += 1
                                o_arg = 1
                                arg = 1
                                for set_num in range(num_sets):
                                    out_args[o_arg:o_arg+4] = in_args[arg:arg+4]
                                    out_args[o_arg+4] = blank
                                    o_arg += 5
                                    arg += 4
                                cur_args = o_arg - 1
                            
                            elif object_upper == 'WINDOWSHADINGCONTROL':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                no_diff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if external_funcs['samestring']('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if external_funcs['samestring']('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if external_funcs['samestring']('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if external_funcs['samestring']('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if external_funcs['samestring']('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if external_funcs['samestring']('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if external_funcs['samestring']('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if external_funcs['samestring']('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutsideAirTemp'
                                if external_funcs['samestring']('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemp'
                                if external_funcs['samestring']('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if external_funcs['samestring']('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if external_funcs['samestring']('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif object_upper == 'REPORT VARIABLE':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                external_funcs['ScanOutputVariablesForReplacement'](
                                    2, del_this, check_rvi, no_diff, object_name, dif_file,
                                    True, False, False, cur_args, written, False,
                                    data_v_compare_globals, external_funcs
                                )
                                if del_this:
                                    continue
                            
                            elif object_upper in ('REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY'):
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                del_this = False
                                external_funcs['ScanOutputVariablesForReplacement'](
                                    1, del_this, check_rvi, no_diff, object_name, dif_file,
                                    False, True, False, cur_args, written, False,
                                    data_v_compare_globals, external_funcs
                                )
                                if del_this:
                                    continue
                            
                            elif object_upper == 'REPORT:TABLE:TIMEBINS':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                external_funcs['ScanOutputVariablesForReplacement'](
                                    2, del_this, check_rvi, no_diff, object_name, dif_file,
                                    False, False, True, cur_args, written, False,
                                    data_v_compare_globals, external_funcs
                                )
                                if del_this:
                                    continue
                            
                            elif object_upper == 'REPORT:TABLE:MONTHLY':
                                external_funcs['GetNewObjectDefInIDD'](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = in_args[var].upper()
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    del_this = False
                                    for arg in range(data_v_compare_globals.NumRepVarNames):
                                        uc_comp_rep_var_name = data_v_compare_globals.OldRepVarName[arg].upper()
                                        wild_match = False
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if data_v_compare_globals.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = data_v_compare_globals.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = (data_v_compare_globals.NewRepVarName[arg] +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name):])
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if (arg + 1 < data_v_compare_globals.NumRepVarNames and
                                                data_v_compare_globals.OldRepVarName[arg] == data_v_compare_globals.OldRepVarName[arg + 1]):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_v_compare_globals.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = (data_v_compare_globals.NewRepVarName[arg + 1] +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name):])
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            if (arg + 2 < data_v_compare_globals.NumRepVarNames and
                                                data_v_compare_globals.OldRepVarName[arg] == data_v_compare_globals.OldRepVarName[arg + 2]):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_v_compare_globals.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = (data_v_compare_globals.NewRepVarName[arg + 2] +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name):])
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            else:
                                if external_funcs['FindItemInList'](object_name, data_v_compare_globals.NotInNew, len(data_v_compare_globals.NotInNew),
                                                                   input_processor) != 0:
                                    data_globals.Auditf.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                    data_globals.Auditf.write('... will be listed as comments on the new output file.\n')
                                    external_funcs['WriteOutIDFLinesAsComments'](
                                        dif_file, object_name, cur_args, in_args, fld_names, fld_units,
                                        data_v_compare_globals, external_funcs
                                    )
                                    written = True
                                else:
                                    external_funcs['GetNewObjectDefInIDD'](
                                        object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                        data_v_compare_globals, input_processor
                                    )
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                        
                        else:
                            external_funcs['GetNewObjectDefInIDD'](
                                idf_records[num]['Name'], nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                data_v_compare_globals, input_processor
                            )
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if diff_min_fields and no_diff:
                            external_funcs['GetNewObjectDefInIDD'](
                                object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                data_v_compare_globals, input_processor
                            )
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = False
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            external_funcs['CheckSpecialObjects'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written,
                                data_v_compare_globals, external_funcs
                            )
                        
                        if not written:
                            external_funcs['WriteOutIDFLines'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                data_v_compare_globals, external_funcs
                            )
                    
                    if idf_records[num_idf_records - 1]['CommtE'] != data_v_compare_globals.CurComment:
                        for xcount in range(idf_records[num_idf_records - 1]['CommtE'] + 1, data_v_compare_globals.CurComment + 1):
                            dif_file.write(data_v_compare_globals.Comments[xcount] + '\n')
                            if xcount == idf_records[num]['CommtE']:
                                dif_file.write('\n')
                    
                    dif_file.close()
                    
                    if check_rvi:
                        external_funcs['ProcessRviMviFiles'](file_name_path, 'rvi', data_v_compare_globals, external_funcs)
                        external_funcs['ProcessRviMviFiles'](file_name_path, 'mvi', data_v_compare_globals, external_funcs)
                    
                    external_funcs['CloseOut'](data_v_compare_globals, external_funcs)
                
                else:
                    external_funcs['ProcessRviMviFiles'](file_name_path, 'rvi', data_v_compare_globals, external_funcs)
                    external_funcs['ProcessRviMviFiles'](file_name_path, 'mvi', data_v_compare_globals, external_funcs)
            
            else:
                end_of_file[0] = True
            
            external_funcs['CreateNewName']('Reallocate', blank, ' ', data_v_compare_globals, external_funcs)
        
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
        external_funcs['copyfile'](
            file_name_path + '.' + arg_idf_extension,
            file_name_path + '.' + arg_idf_extension + 'old',
            err_flag
        )
        external_funcs['copyfile'](
            file_name_path + '.' + arg_idf_extension + 'new',
            file_name_path + '.' + arg_idf_extension,
            err_flag
        )
        
        import os
        if os.path.exists(file_name_path + '.rvi'):
            external_funcs['copyfile'](file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        if os.path.exists(file_name_path + '.rvinew'):
            external_funcs['copyfile'](file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        if os.path.exists(file_name_path + '.mvi'):
            external_funcs['copyfile'](file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        if os.path.exists(file_name_path + '.mvinew'):
            external_funcs['copyfile'](file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
