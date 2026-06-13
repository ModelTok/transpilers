from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any, Protocol
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: blank, MaxNameLength, ProgNameConversion, ProgramPath
# - DataVCompareGlobals: IDFRecords, Comments, NumIDFRecords, CurComment, ObjectDef, NumObjectDefs, NotInNew, FatalError, ProcessingIMFFile, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NumAlphas, NumNumbers, NumRepVarNames, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf
# - VCompareGlobalRoutines: GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound, SameString, MakeUPPERCase, MakeLowerCase, FindItemInList, DisplayString, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ScanOutputVariablesForReplacement, writePreprocessorObject, ProcessInput, CloseOut, CreateNewName, ProcessRviMviFiles, copyfile
# - General: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - External: GetNewUnitNumber, TrimTrailZeros, CalculateMuEMPD

class GlobalState(Protocol):
    """Protocol for shared state object"""
    blank: str
    MaxNameLength: int
    ProgNameConversion: str
    ProgramPath: str
    IDFRecords: List[Any]
    Comments: List[str]
    NumIDFRecords: int
    CurComment: int
    ObjectDef: Any
    NumObjectDefs: int
    NotInNew: List[str]
    FatalError: bool
    ProcessingIMFFile: bool
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    Alphas: List[str]
    Numbers: List[str]
    InArgs: List[str]
    AorN: List[bool]
    ReqFld: List[bool]
    FldNames: List[str]
    FldDefaults: List[str]
    FldUnits: List[str]
    NwAorN: List[bool]
    NwReqFld: List[bool]
    NwFldNames: List[str]
    NwFldDefaults: List[str]
    NwFldUnits: List[str]
    OutArgs: List[str]
    MatchArg: List[str]
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    NumAlphas: int
    NumNumbers: int
    NumRepVarNames: int
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    FullFileName: str
    FileNamePath: str
    Auditf: Any

def set_this_version_variables(state: GlobalState) -> None:
    """SetThisVersionVariables subroutine"""
    state.VerString = 'Conversion 8.5 => 8.6'
    state.VersionNum = 8.6
    state.sVersionNum = '8.6'
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-5-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-6-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 8-5-0 to 8-6-0.csv'

@dataclass
class DElightRefPtType:
    """Daylighting DELight Reference Point type"""
    RefPtName: str = ''
    ControlName: str = ''
    X: str = ''
    Y: str = ''
    Z: str = ''
    FracZone: str = ''
    IllumSetPt: str = ''
    ZoneName: str = ''

def create_new_idf_using_rules(
    state: GlobalState,
    external_fns: Dict[str, Any],
    end_of_file_io: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> None:
    """CreateNewIDFUsingRules subroutine"""
    
    # Local variables
    d_light_ref_pt: List[DElightRefPtType] = []
    num_d_light_ref_pt = 0
    i_ref_pt = 0
    
    ios = 0
    dot_pos = 0
    na = 0
    nn = 0
    cur_args = 0
    dif_lfn = 0
    xcount = 0
    num = 0
    unitsarg = ''
    object_name = ''
    uc_rep_var_name = ''
    uc_comp_rep_var_name = ''
    del_this = False
    pos = 0
    pos2 = 0
    exit_because_bad_file = False
    still_working = True
    nodiff = False
    checkrvi = False
    no_version = True
    diff_min_fields = False
    written = False
    
    first_time = True
    var = 0
    cur_var = 0
    arg_file_being_done = False
    latest_version = False
    local_file_extension = ' '
    wild_match = False
    conn_comp = False
    conn_comp_ctrl = False
    file_exist = False
    created_output_name = ''
    delete_this_record: List[bool] = []
    c_out_args = 0
    units_field = ''
    schedule_type_limits_any_number = False
    cycling = False
    continuous = False
    out_schedule_name = ''
    is_d_light_out_var = False
    
    material_density = 0.0
    empd_coeff_a = 0.0
    empd_coeff_b = 0.0
    empd_coeff_c = 0.0
    empd_coeff_d = 0.0
    empd_coeff_d_empd = 0.0
    mu_empd = 0.0
    matl_search_num = 0
    found_material = False
    
    err_flag = False
    
    i = 0
    cur_field = 0
    new_field = 0
    ka_index = 0
    search_num = 0
    alpha_num_i = 0
    
    get_new_unit_number = external_fns.get('GetNewUnitNumber')
    trim_trail_zeros = external_fns.get('TrimTrailZeros')
    calculate_mu_empd = external_fns.get('CalculateMuEMPD')
    get_object_def_in_idd = external_fns.get('GetObjectDefInIDD')
    get_new_object_def_in_idd = external_fns.get('GetNewObjectDefInIDD')
    make_upper_case = external_fns.get('MakeUPPERCase')
    same_string = external_fns.get('SameString')
    find_item_in_list = external_fns.get('FindItemInList')
    make_lower_case = external_fns.get('MakeLowerCase')
    display_string = external_fns.get('DisplayString')
    write_out_idf_lines = external_fns.get('WriteOutIDFLines')
    write_out_idf_lines_as_comments = external_fns.get('WriteOutIDFLinesAsComments')
    check_special_objects = external_fns.get('CheckSpecialObjects')
    scan_output_variables_for_replacement = external_fns.get('ScanOutputVariablesForReplacement')
    write_preprocessor_object = external_fns.get('writePreprocessorObject')
    process_input = external_fns.get('ProcessInput')
    close_out = external_fns.get('CloseOut')
    create_new_name = external_fns.get('CreateNewName')
    process_rvi_mvi_files = external_fns.get('ProcessRviMviFiles')
    show_warning_error = external_fns.get('ShowWarningError')
    show_fatal_error = external_fns.get('ShowFatalError')
    get_num_sections_found = external_fns.get('GetNumSectionsFound')
    copy_file = external_fns.get('copyfile')
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file_io[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file_io[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                state.FullFileName = input()
            else:
                if not arg_file:
                    try:
                        line = input()
                        state.FullFileName = line
                        ios = 0
                    except:
                        state.FullFileName = ''
                        ios = 1
                elif not arg_file_being_done:
                    state.FullFileName = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.FullFileName = ''
                    ios = 1
                
                if state.FullFileName.startswith('!'):
                    state.FullFileName = ''
                    continue
            
            unitsarg = ''
            if ios != 0:
                state.FullFileName = ''
            state.FullFileName = state.FullFileName.lstrip()
            
            if state.FullFileName != '':
                display_string('Processing IDF -- ' + state.FullFileName)
                print(' Processing IDF -- ' + state.FullFileName, file=state.Auditf)
                
                dot_pos = state.FullFileName.rfind('.')
                if dot_pos != -1:
                    state.FileNamePath = state.FullFileName[:dot_pos]
                    local_file_extension = make_lower_case(state.FullFileName[dot_pos+1:])
                else:
                    state.FileNamePath = state.FullFileName
                    print(' assuming file extension of .idf')
                    print(' ..assuming file extension of .idf', file=state.Auditf)
                    state.FullFileName = state.FullFileName + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = get_new_unit_number()
                
                file_ok = os.path.isfile(state.FullFileName)
                if not file_ok:
                    print('File not found=' + state.FullFileName)
                    print('File not found=' + state.FullFileName, file=state.Auditf)
                    end_of_file_io[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_name = state.FileNamePath + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = state.FileNamePath + '.' + local_file_extension + 'new'
                    
                    try:
                        dif_file = open(dif_file_name, 'w')
                    except:
                        dif_file = None
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    process_input(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, state.FullFileName, state)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Deallocate old arrays and allocate new ones
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    # Check for VERSION record
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    # Check for ScheduleTypeLimits Any Number
                    schedule_type_limits_any_number = False
                    for num in range(state.NumIDFRecords):
                        if not same_string(state.IDFRecords[num]['Name'], 'ScheduleTypeLimits'):
                            continue
                        if not same_string(state.IDFRecords[num]['Alphas'][0], 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    # Write deletion comments
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + state.IDFRecords[num]['Name'] + '="' + state.IDFRecords[num]['Alphas'][0] + '".\n')
                    
                    # PREPROCESSING FOR DAYLIGHTING:DELIGHT:REFERENCEPOINT
                    if not d_light_ref_pt:
                        num_d_light_ref_pt = 0
                        for num in range(state.NumIDFRecords):
                            if make_upper_case(state.IDFRecords[num]['Name']) == 'DAYLIGHTING:DELIGHT:REFERENCEPOINT':
                                num_d_light_ref_pt += 1
                        
                        d_light_ref_pt = [DElightRefPtType() for _ in range(num_d_light_ref_pt)]
                        
                        i_ref_pt = 0
                        for num in range(state.NumIDFRecords):
                            if make_upper_case(state.IDFRecords[num]['Name']) == 'DAYLIGHTING:DELIGHT:REFERENCEPOINT':
                                d_light_ref_pt[i_ref_pt].RefPtName = state.IDFRecords[num]['Alphas'][0]
                                d_light_ref_pt[i_ref_pt].ControlName = state.IDFRecords[num]['Alphas'][1]
                                d_light_ref_pt[i_ref_pt].X = str(state.IDFRecords[num]['Numbers'][0])
                                d_light_ref_pt[i_ref_pt].Y = str(state.IDFRecords[num]['Numbers'][1])
                                d_light_ref_pt[i_ref_pt].Z = str(state.IDFRecords[num]['Numbers'][2])
                                d_light_ref_pt[i_ref_pt].FracZone = str(state.IDFRecords[num]['Numbers'][3])
                                d_light_ref_pt[i_ref_pt].IllumSetPt = str(state.IDFRecords[num]['Numbers'][4])
                                i_ref_pt += 1
                        
                        for num in range(state.NumIDFRecords):
                            if make_upper_case(state.IDFRecords[num]['Name']) == 'DAYLIGHTING:DELIGHT:CONTROLS':
                                for i_ref_pt in range(num_d_light_ref_pt):
                                    if make_upper_case(state.IDFRecords[num]['Alphas'][0]) == make_upper_case(d_light_ref_pt[i_ref_pt].ControlName):
                                        d_light_ref_pt[i_ref_pt].ZoneName = state.IDFRecords[num]['Alphas'][1]
                    
                    # Main processing loop
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        # Write comments
                        for xcount in range(state.IDFRecords[num].get('CommtS', 0), state.IDFRecords[num].get('CommtE', 0) + 1):
                            if xcount < len(state.Comments):
                                dif_file.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[num].get('CommtE', 0):
                                    dif_file.write('\n')
                        
                        if no_version and num == 0:
                            get_new_object_def_in_idd('VERSION', state)
                            state.OutArgs[0] = state.sVersionNum
                            cur_args = 1
                            write_out_idf_lines_as_comments(dif_file, 'Version', cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                        
                        # Check for deleted objects
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'PROGRAMCONTROL':
                            continue
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'AIRFLOW MODEL':
                            continue
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if make_upper_case(state.IDFRecords[num]['Name']) == 'WATER HEATER:SIMPLE':
                            dif_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted', state)
                            continue
                        
                        object_name = state.IDFRecords[num]['Name']
                        
                        if find_item_in_list(object_name, [od['Name'] for od in state.ObjectDef], state.NumObjectDefs) != 0:
                            get_object_def_in_idd(object_name, state)
                            state.NumAlphas = state.IDFRecords[num]['NumAlphas']
                            state.NumNumbers = state.IDFRecords[num]['NumNumbers']
                            for i in range(state.NumAlphas):
                                state.Alphas[i] = state.IDFRecords[num]['Alphas'][i]
                            for i in range(state.NumNumbers):
                                state.Numbers[i] = state.IDFRecords[num]['Numbers'][i]
                            
                            cur_args = state.NumAlphas + state.NumNumbers
                            for arg in range(cur_args):
                                state.InArgs[arg] = ''
                            for arg in range(cur_args):
                                state.OutArgs[arg] = ''
                            
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
                            print('Object="' + object_name + '" does not seem to be on the "old" IDD.', file=state.Auditf)
                            print('... will be listed as comments (no field names) on the new output file.', file=state.Auditf)
                            print('... Alpha fields will be listed first, then numerics.', file=state.Auditf)
                            
                            state.NumAlphas = state.IDFRecords[num]['NumAlphas']
                            state.NumNumbers = state.IDFRecords[num]['NumNumbers']
                            for i in range(state.NumAlphas):
                                state.Alphas[i] = state.IDFRecords[num]['Alphas'][i]
                            for i in range(state.NumNumbers):
                                state.Numbers[i] = state.IDFRecords[num]['Numbers'][i]
                            
                            for arg in range(state.NumAlphas):
                                state.OutArgs[arg] = state.Alphas[arg]
                            nn = state.NumAlphas + 1
                            for arg in range(state.NumNumbers):
                                state.OutArgs[nn] = str(state.Numbers[arg])
                                nn += 1
                            
                            cur_args = state.NumAlphas + state.NumNumbers
                            for i in range(cur_args):
                                state.NwFldNames[i] = ''
                                state.NwFldUnits[i] = ''
                            
                            write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(make_upper_case(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            get_new_object_def_in_idd(object_name, state)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        # Global replacement for Coil:Heating:Gas
                        for alpha_num_i in range(cur_args):
                            if same_string('COIL:HEATING:GAS', state.InArgs[alpha_num_i]):
                                state.InArgs[alpha_num_i] = 'Coil:Heating:Fuel'
                                nodiff = False
                        
                        # Main SELECT CASE
                        obj_upper = make_upper_case(state.IDFRecords[num]['Name'].strip())
                        
                        if obj_upper == 'VERSION':
                            if state.InArgs[0][:3] == state.sVersionNum and arg_file:
                                show_warning_error('File is already at latest version.  No new diff file made.', state.Auditf)
                                dif_file.close()
                                os.remove(dif_file_name)
                                latest_version = True
                                break
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.sVersionNum
                            nodiff = False
                        
                        elif obj_upper == 'EXTERIOR:FUELEQUIPMENT':
                            object_name = 'Exterior:FuelEquipment'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            if same_string('Gas', state.InArgs[1]):
                                state.OutArgs[1] = 'NaturalGas'
                            if same_string('LPG', state.InArgs[1]):
                                state.OutArgs[1] = 'PropaneGas'
                        
                        elif obj_upper == 'HVACTEMPLATE:SYSTEM:UNITARYSYSTEM':
                            object_name = 'HVACTemplate:System:UnitarySystem'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            for i in range(56):
                                state.OutArgs[i] = state.InArgs[i]
                            for i in range(57, cur_args - 1):
                                state.OutArgs[i] = state.InArgs[i + 1]
                            cur_args -= 1
                        
                        elif obj_upper == 'HVACTEMPLATE:SYSTEM:UNITARY':
                            object_name = 'HVACTemplate:System:Unitary'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            for i in range(39):
                                state.OutArgs[i] = state.InArgs[i]
                            for i in range(40, cur_args - 1):
                                state.OutArgs[i] = state.InArgs[i + 1]
                            cur_args -= 1
                        
                        elif obj_upper == 'CHILLERHEATER:ABSORPTION:DIRECTFIRED':
                            object_name = 'ChillerHeater:Absorption:DirectFired'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            for i in range(32):
                                state.OutArgs[i] = state.InArgs[i]
                            state.OutArgs[32] = state.InArgs[33]
                            state.OutArgs[33] = state.InArgs[34]
                            cur_args -= 1
                        
                        elif obj_upper == 'SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MINIMUM':
                            object_name = 'SetpointManager:SingleZone:Humidity:Minimum'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[3]
                            state.OutArgs[2] = state.InArgs[4]
                            cur_args -= 2
                        
                        elif obj_upper == 'SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MAXIMUM':
                            object_name = 'SetpointManager:SingleZone:Humidity:Maximum'
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[3]
                            state.OutArgs[2] = state.InArgs[4]
                            cur_args -= 2
                        
                        elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT':
                            nodiff = False
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            if same_string(state.InArgs[15], 'REVERSE'):
                                if (not same_string(state.InArgs[16], '')) or (not same_string(state.InArgs[17], '')):
                                    state.OutArgs[15] = 'ReverseWithLimits'
                        
                        elif obj_upper == 'BRANCH':
                            object_name = 'Branch'
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[2]
                            cur_args -= 1
                            nodiff = False
                            i = 0
                            cur_field = 3
                            new_field = 2
                            while True:
                                state.OutArgs[new_field] = state.InArgs[cur_field]
                                state.OutArgs[new_field + 1] = state.InArgs[cur_field + 1]
                                state.OutArgs[new_field + 2] = state.InArgs[cur_field + 2]
                                state.OutArgs[new_field + 3] = state.InArgs[cur_field + 3]
                                cur_field += 5
                                new_field += 4
                                if new_field > cur_args:
                                    break
                                cur_args -= 1
                        
                        elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER':
                            nodiff = False
                            object_name = "AirTerminal:SingleDuct:Mixer"
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(6):
                                state.OutArgs[i] = state.InArgs[i]
                            cur_args += 1
                            state.OutArgs[6] = 'InletSide'
                        
                        elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER':
                            nodiff = False
                            object_name = "AirTerminal:SingleDuct:Mixer"
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(6):
                                state.OutArgs[i] = state.InArgs[i]
                            cur_args += 1
                            state.OutArgs[6] = 'SupplySide'
                        
                        elif obj_upper == 'ZONEHVAC:AIRDISTRIBUTIONUNIT':
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            if same_string('AirTerminal:SingleDuct:InletSideMixer', state.InArgs[2]) or same_string('AirTerminal:SingleDuct:SupplySideMixer', state.InArgs[2]):
                                state.OutArgs[2] = 'AirTerminal:SingleDuct:Mixer'
                        
                        elif obj_upper == 'OTHEREQUIPMENT':
                            nodiff = False
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = 'None'
                            for i in range(9):
                                state.OutArgs[i + 2] = state.InArgs[i + 1]
                            cur_args += 1
                        
                        elif obj_upper == 'COIL:HEATING:GAS':
                            nodiff = False
                            object_name = 'Coil:Heating:Fuel'
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[1]
                            state.OutArgs[2] = 'NaturalGas'
                            for i in range(8):
                                state.OutArgs[i + 3] = state.InArgs[i + 2]
                            cur_args += 1
                        
                        elif obj_upper == 'DAYLIGHTING:CONTROLS':
                            nodiff = False
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0].rstrip() + '_DaylCtrl'
                            state.OutArgs[1] = state.InArgs[0]
                            state.OutArgs[2] = 'SplitFlux'
                            state.OutArgs[3] = state.InArgs[19]
                            if state.InArgs[12] == '1':
                                state.OutArgs[4] = 'Continuous'
                            elif state.InArgs[12] == '2':
                                state.OutArgs[4] = 'Stepped'
                            elif state.InArgs[12] == '3':
                                state.OutArgs[4] = 'ContinuousOff'
                            else:
                                state.OutArgs[4] = 'Continuous'
                            for i in range(4):
                                state.OutArgs[i + 5] = state.InArgs[i + 15]
                            if state.OutArgs[7] == '0':
                                state.OutArgs[7] = ''
                            state.OutArgs[9] = state.InArgs[0].rstrip() + '_DaylRefPt1'
                            state.OutArgs[10] = state.InArgs[13]
                            state.OutArgs[11] = state.InArgs[14]
                            state.OutArgs[12] = ''
                            state.OutArgs[13] = state.InArgs[0].rstrip() + '_DaylRefPt1'
                            state.OutArgs[14] = state.InArgs[8]
                            state.OutArgs[15] = state.InArgs[10]
                            if state.InArgs[1] == '2':
                                state.OutArgs[16] = state.InArgs[0].rstrip() + '_DaylRefPt2'
                                state.OutArgs[17] = state.InArgs[9]
                                state.OutArgs[18] = state.InArgs[11]
                                cur_args = 19
                            else:
                                cur_args = 16
                            write_out_idf_lines(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                            
                            object_name = 'Daylighting:ReferencePoint'
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0].rstrip() + '_DaylRefPt1'
                            state.OutArgs[1] = state.InArgs[0]
                            for i in range(3):
                                state.OutArgs[i + 2] = state.InArgs[i + 2]
                            cur_args = 5
                            write_out_idf_lines(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                            
                            if state.InArgs[1] == '2':
                                object_name = 'Daylighting:ReferencePoint'
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[0] = state.InArgs[0].rstrip() + '_DaylRefPt2'
                                state.OutArgs[1] = state.InArgs[0]
                                for i in range(3):
                                    state.OutArgs[i + 2] = state.InArgs[i + 5]
                                cur_args = 5
                                write_out_idf_lines(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                            
                            written = True
                        
                        elif obj_upper == 'DAYLIGHTING:DELIGHT:CONTROLS':
                            object_name = 'Daylighting:Controls'
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[1]
                            state.OutArgs[2] = 'DElight'
                            state.OutArgs[3] = ''
                            if state.InArgs[4] == '1':
                                state.OutArgs[4] = 'Continuous'
                            elif state.InArgs[4] == '2':
                                state.OutArgs[4] = 'Stepped'
                            elif state.InArgs[4] == '3':
                                state.OutArgs[4] = 'ContinuousOff'
                            else:
                                state.OutArgs[4] = 'Continuous'
                            for i in range(4):
                                state.OutArgs[i + 5] = state.InArgs[i + 3]
                            if state.OutArgs[7] == '0':
                                state.OutArgs[7] = ''
                            state.OutArgs[9] = ''
                            state.OutArgs[10] = '0'
                            state.OutArgs[11] = ''
                            state.OutArgs[12] = state.InArgs[7]
                            cur_args = 13
                            for i_ref_pt in range(num_d_light_ref_pt):
                                if make_upper_case(state.InArgs[0]) == make_upper_case(d_light_ref_pt[i_ref_pt].ControlName):
                                    state.OutArgs[cur_args] = d_light_ref_pt[i_ref_pt].RefPtName
                                    state.OutArgs[cur_args + 1] = d_light_ref_pt[i_ref_pt].FracZone
                                    state.OutArgs[cur_args + 2] = d_light_ref_pt[i_ref_pt].IllumSetPt
                                    cur_args += 3
                        
                        elif obj_upper == 'DAYLIGHTING:DELIGHT:REFERENCEPOINT':
                            object_name = 'Daylighting:ReferencePoint'
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.InArgs[0]
                            for i_ref_pt in range(num_d_light_ref_pt):
                                if make_upper_case(state.InArgs[1]) == make_upper_case(d_light_ref_pt[i_ref_pt].ControlName):
                                    state.OutArgs[1] = d_light_ref_pt[i_ref_pt].ZoneName
                            for i in range(3):
                                state.OutArgs[i + 2] = state.InArgs[i + 2]
                            cur_args = 5
                        
                        elif obj_upper == 'MATERIALPROPERTY:MOISTUREPENETRATIONDEPTH:SETTINGS':
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = "Could not find Material Match for " + state.InArgs[0]
                            state.OutArgs[2] = state.InArgs[2]
                            state.OutArgs[3] = state.InArgs[3]
                            state.OutArgs[4] = state.InArgs[4]
                            state.OutArgs[5] = state.InArgs[5]
                            state.OutArgs[6] = state.InArgs[1]
                            state.OutArgs[7] = "0"
                            state.OutArgs[8] = "0"
                            state.OutArgs[9] = "0"
                            cur_args = 10
                            
                            found_material = False
                            for matl_search_num in range(state.NumIDFRecords):
                                if make_upper_case(state.IDFRecords[matl_search_num]['Name']) != 'MATERIAL':
                                    continue
                                if make_upper_case(state.IDFRecords[matl_search_num]['Alphas'][0]) == make_upper_case(state.InArgs[0]):
                                    found_material = True
                                    dif_file.write('! Found a material component match; name =' + state.IDFRecords[matl_search_num]['Alphas'][0] + '\n')
                                    material_density = float(state.IDFRecords[matl_search_num]['Numbers'][2])
                                    break
                            
                            if not found_material:
                                dif_file.write('! Didnt find a material component match for name =' + state.IDFRecords[matl_search_num]['Alphas'][0] + '\n')
                                show_fatal_error('Material match issue', state)
                            
                            empd_coeff_a = float(state.InArgs[2])
                            empd_coeff_b = float(state.InArgs[3])
                            empd_coeff_c = float(state.InArgs[4])
                            empd_coeff_d = float(state.InArgs[5])
                            empd_coeff_d_empd = float(state.InArgs[1])
                            mu_empd = calculate_mu_empd(empd_coeff_a, empd_coeff_b, empd_coeff_c, empd_coeff_d, empd_coeff_d_empd, material_density)
                            state.OutArgs[1] = str(mu_empd)
                        
                        elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:ACTUATOR':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            actuator_upper = make_upper_case(state.InArgs[3])
                            if actuator_upper == 'OUTDOOR AIR DRYBLUB TEMPERATURE':
                                nodiff = True
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                state.OutArgs[3] = 'Outdoor Air Drybulb Temperature'
                            elif actuator_upper == 'OUTDOOR AIR WETBLUB TEMPERATURE':
                                nodiff = True
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                state.OutArgs[3] = 'Outdoor Air Wetbulb Temperature'
                        
                        elif obj_upper == 'OUTPUT:VARIABLE':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            if state.OutArgs[0] == '':
                                state.OutArgs[0] = '*'
                                nodiff = False
                            
                            if state.InArgs[0] != '*':
                                is_d_light_out_var = False
                                if same_string(state.InArgs[1][:27], 'Daylighting Reference Point'):
                                    for i_ref_pt in range(num_d_light_ref_pt):
                                        if make_upper_case(state.InArgs[0]) == make_upper_case(d_light_ref_pt[i_ref_pt].RefPtName):
                                            is_d_light_out_var = True
                                    if not is_d_light_out_var:
                                        state.OutArgs[0] = state.InArgs[0].rstrip() + '_DaylCtrl'
                                
                                if same_string(state.InArgs[1], 'Daylighting Lighting Power Multiplier'):
                                    for i_ref_pt in range(num_d_light_ref_pt):
                                        if make_upper_case(state.InArgs[0]) == make_upper_case(d_light_ref_pt[i_ref_pt].ZoneName):
                                            is_d_light_out_var = True
                                            state.OutArgs[0] = d_light_ref_pt[i_ref_pt].ControlName
                                    if not is_d_light_out_var:
                                        state.OutArgs[0] = state.InArgs[0].rstrip() + '_DaylCtrl'
                            
                            del_this = False
                            scan_output_variables_for_replacement(2, del_this, checkrvi, nodiff, object_name, dif_file, True, False, False, cur_args, written, False, state)
                            if del_this:
                                continue
                        
                        elif obj_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            del_this = False
                            scan_output_variables_for_replacement(1, del_this, checkrvi, nodiff, object_name, dif_file, False, True, False, cur_args, written, False, state)
                            if del_this:
                                continue
                        
                        elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            if state.OutArgs[0] == '':
                                state.OutArgs[0] = '*'
                                nodiff = False
                            del_this = False
                            scan_output_variables_for_replacement(2, del_this, checkrvi, nodiff, object_name, dif_file, False, False, True, cur_args, written, False, state)
                            if del_this:
                                continue
                        
                        elif obj_upper in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            if state.OutArgs[0] == '':
                                state.OutArgs[0] = '*'
                                nodiff = False
                            del_this = False
                            scan_output_variables_for_replacement(2, del_this, checkrvi, nodiff, object_name, dif_file, False, False, False, cur_args, written, False, state)
                            if del_this:
                                continue
                        
                        elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            del_this = False
                            scan_output_variables_for_replacement(3, del_this, checkrvi, nodiff, object_name, dif_file, False, False, False, cur_args, written, True, state)
                            if del_this:
                                continue
                        
                        elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = True
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            cur_var = 3
                            var_idx = 3
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var_idx])
                                state.OutArgs[cur_var] = state.InArgs[var_idx]
                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                        if state.NewRepVarName[arg] != '<DELETE>':
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != '' and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.OTMVarCaution[arg]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + state.OldRepVarName[arg] + '" conversion to Output Table Monthly (new)="' + state.NewRepVarName[arg] + '" has the following caution "' + state.NewRepVarCaution[arg] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.OTMVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        
                                        if arg < state.NumRepVarNames - 1 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != '':
                                                    if not state.OTMVarCaution[arg + 1]:
                                                        write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.OldRepVarName[arg] + '" conversion to Output Table Monthly (new)="' + state.NewRepVarName[arg + 1] + '" has the following caution "' + state.NewRepVarCaution[arg + 1] + '".', state)
                                                        dif_file.write(' \n')
                                                        state.OTMVarCaution[arg + 1] = True
                                                
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                        
                                        if arg < state.NumRepVarNames - 2 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != '':
                                                if not state.OTMVarCaution[arg + 2]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + state.OldRepVarName[arg] + '" conversion to Output Table Monthly (new)="' + state.NewRepVarName[arg + 2] + '" has the following caution "' + state.NewRepVarCaution[arg + 2] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.OTMVarCaution[arg + 2] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var - 1
                        
                        elif obj_upper == 'METER:CUSTOM':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var_idx])
                                state.OutArgs[cur_var] = state.InArgs[var_idx]
                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                        if state.NewRepVarName[arg] != '<DELETE>':
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != '' and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrVarCaution[arg]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Meter (new)="' + state.NewRepVarName[arg] + '" has the following caution "' + state.NewRepVarCaution[arg] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.CMtrVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        
                                        if arg < state.NumRepVarNames - 1 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != '' and not same_string(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrVarCaution[arg + 1]:
                                                        write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Meter (new)="' + state.NewRepVarName[arg + 1] + '" has the following caution "' + state.NewRepVarCaution[arg + 1] + '".', state)
                                                        dif_file.write(' \n')
                                                        state.CMtrVarCaution[arg + 1] = True
                                                
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                        
                                        if arg < state.NumRepVarNames - 2 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != '':
                                                if not state.CMtrVarCaution[arg + 2]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Meter (new)="' + state.NewRepVarName[arg + 2] + '" has the following caution "' + state.NewRepVarCaution[arg + 2] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.CMtrVarCaution[arg + 2] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.OutArgs[arg] == '':
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif obj_upper == 'METER:CUSTOMDECREMENT':
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = True
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var_idx])
                                state.OutArgs[cur_var] = state.InArgs[var_idx]
                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var_idx][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                        if state.NewRepVarName[arg] != '<DELETE>':
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != '' and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrDVarCaution[arg]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Meter (new)="' + state.NewRepVarName[arg] + '" has the following caution "' + state.NewRepVarCaution[arg] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.CMtrDVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        
                                        if arg < state.NumRepVarNames - 1 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != '' and not same_string(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrDVarCaution[arg + 1]:
                                                        write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Decrement Meter (new)="' + state.NewRepVarName[arg + 1] + '" has the following caution "' + state.NewRepVarCaution[arg + 1] + '".', state)
                                                        dif_file.write(' \n')
                                                        state.CMtrDVarCaution[arg + 1] = True
                                                
                                                state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                                nodiff = False
                                        
                                        if arg < state.NumRepVarNames - 2 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2] + state.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != '':
                                                if not state.CMtrDVarCaution[arg + 2]:
                                                    write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + state.OldRepVarName[arg] + '" conversion to Custom Meter (new)="' + state.NewRepVarName[arg + 2] + '" has the following caution "' + state.NewRepVarCaution[arg + 2] + '".', state)
                                                    dif_file.write(' \n')
                                                    state.CMtrDVarCaution[arg + 2] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var_idx + 1]
                                            nodiff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.OutArgs[arg] == '':
                                    cur_args -= 1
                                else:
                                    break
                        
                        else:
                            if find_item_in_list(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                print('Object="' + object_name + '" is not in the "new" IDD.', file=state.Auditf)
                                print('... will be listed as comments on the new output file.', file=state.Auditf)
                                write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state.InArgs, state.FldNames, state.FldUnits, state)
                                written = True
                            else:
                                get_new_object_def_in_idd(object_name, state)
                                for i in range(cur_args):
                                    state.OutArgs[i] = state.InArgs[i]
                                nodiff = True
                        
                        if diff_min_fields and nodiff:
                            get_new_object_def_in_idd(object_name, state)
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            nodiff = False
                            for arg in range(cur_args, state.NwObjMinFlds):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, written, state)
                        
                        if not written:
                            write_out_idf_lines(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                    
                    # Write trailing comments
                    if state.IDFRecords[state.NumIDFRecords - 1].get('CommtE', 0) != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].get('CommtE', 0) + 1, state.CurComment + 1):
                            if xcount < len(state.Comments):
                                dif_file.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[state.NumIDFRecords - 1].get('CommtE', 0):
                                    dif_file.write('\n')
                    
                    if get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        get_new_object_def_in_idd(object_name, state)
                        nodiff = False
                        state.OutArgs[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines(dif_file, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits, state)
                    
                    dif_file.close()
                    process_rvi_mvi_files(state.FileNamePath, 'rvi', state)
                    process_rvi_mvi_files(state.FileNamePath, 'mvi', state)
                    close_out(state)
                else:
                    process_rvi_mvi_files(state.FileNamePath, 'rvi', state)
                    process_rvi_mvi_files(state.FileNamePath, 'mvi', state)
            else:
                end_of_file_io[0] = True
            
            create_new_name('Reallocate', created_output_name, ' ', state)
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file_io[0] = False
            else:
                end_of_file_io[0] = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copy_file(state.FileNamePath + '.' + arg_idf_extension, state.FileNamePath + '.' + arg_idf_extension + 'old', err_flag)
        copy_file(state.FileNamePath + '.' + arg_idf_extension + 'new', state.FileNamePath + '.' + arg_idf_extension, err_flag)
        
        if os.path.isfile(state.FileNamePath + '.rvi'):
            copy_file(state.FileNamePath + '.rvi', state.FileNamePath + '.rviold', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.rvinew'):
            copy_file(state.FileNamePath + '.rvinew', state.FileNamePath + '.rvi', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.mvi'):
            copy_file(state.FileNamePath + '.mvi', state.FileNamePath + '.mviold', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.mvinew'):
            copy_file(state.FileNamePath + '.mvinew', state.FileNamePath + '.mvi', err_flag)
