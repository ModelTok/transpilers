# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.ProgNameConversion (str)
# - InputProcessor.SameString(a, b) -> bool
# - InputProcessor.FindItemInList(item, list, size) -> int (0=not found, 1-based index if found)
# - InputProcessor.GetNewUnitNumber() -> int
# - InputProcessor.ProcessInput(idd_old, idd_new, idf_file) -> None
# - InputProcessor.GetObjectDefInIDD(name, NumArgs, AorN, ReqFld, ObjMinFlds, FldNames, FldDefaults, FldUnits) -> None
# - InputProcessor.GetNewObjectDefInIDD(name, ...) -> None
# - General.MakeLowerCase(s) -> str
# - General.MakeUPPERCase(s) -> str
# - General.MakeUpperCase(s) -> str
# - VCompareGlobalRoutines.DisplayString(msg) -> None
# - VCompareGlobalRoutines.WriteOutIDFLines(unit, objname, curargs, outargs, fldnames, fldunits) -> None
# - VCompareGlobalRoutines.WriteOutIDFLinesAsComments(unit, objname, curargs, outargs, fldnames, fldunits) -> None
# - VCompareGlobalRoutines.CheckSpecialObjects(unit, objname, curargs, outargs, fldnames, fldunits, written_ref) -> None
# - VCompareGlobalRoutines.ScanOutputVariablesForReplacement(...) -> None
# - VCompareGlobalRoutines.writePreprocessorObject(unit, progname, severity, msg) -> None
# - VCompareGlobalRoutines.CreateNewName(action, outname_ref, inname) -> None
# - VCompareGlobalRoutines.ProcessRviMviFiles(filepath, ext) -> None
# - VCompareGlobalRoutines.CloseOut() -> None
# - VCompareGlobalRoutines.GetNumSectionsFound(section) -> int
# - VCompareGlobalRoutines.copyfile(src, dst, errflag_ref) -> None
# - DataGlobals.ShowWarningError(msg, unit=None) -> None
# - DataGlobals.ShowFatalError(msg, unit=None) -> None

from typing import List, Optional, Callable, Any
from dataclasses import dataclass, field
from io import IOBase

@dataclass
class IDFRecord:
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str]
    Numbers: List[float]
    CommtS: int
    CommtE: int

@dataclass
class ObjectDefInfo:
    Name: str

@dataclass
class ExternalState:
    ProgNameConversion: str
    VerString: str
    VersionNum: float
    sVersionNum: str
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    ProgramPath: str
    Auditf: IOBase
    FullFileName: str
    FileNamePath: str
    IDFRecords: List[IDFRecord]
    Comments: List[str]
    NumIDFRecords: int
    CurComment: int
    ProcessingIMFFile: bool
    FatalError: bool
    ObjectDef: List[ObjectDefInfo]
    NumObjectDefs: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    NumRepVarNames: int
    NotInNew: List[str]
    Blank: str
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    DisplayString: Callable[[str], None]
    WriteOutIDFLines: Callable[..., None]
    WriteOutIDFLinesAsComments: Callable[..., None]
    CheckSpecialObjects: Callable[..., None]
    ScanOutputVariablesForReplacement: Callable[..., None]
    writePreprocessorObject: Callable[..., None]
    CreateNewName: Callable[..., None]
    ProcessRviMviFiles: Callable[[str, str], None]
    CloseOut: Callable[[], None]
    GetNumSectionsFound: Callable[[str], int]
    copyfile: Callable[[str, str], bool]
    ProcessInput: Callable[[str, str, str], None]
    GetObjectDefInIDD: Callable[..., None]
    GetNewObjectDefInIDD: Callable[..., None]
    SameString: Callable[[str, str], bool]
    FindItemInList: Callable[[str, List[str], int], int]
    GetNewUnitNumber: Callable[[], int]
    MakeLowerCase: Callable[[str], str]
    MakeUPPERCase: Callable[[str], str]
    MakeUpperCase: Callable[[str], str]
    ShowWarningError: Callable[[str, Optional[IOBase]], None]
    ShowFatalError: Callable[[str, Optional[IOBase]], None]

def string_trim(s: str) -> str:
    return s.rstrip()

def string_len_trim(s: str) -> int:
    return len(s.rstrip())

def string_adjustl(s: str) -> str:
    return s.lstrip()

def set_this_version_variables(state: ExternalState) -> None:
    state.VerString = 'Conversion 8.8 => 8.9'
    state.VersionNum = 8.9
    state.sVersionNum = '8.9'
    state.IDDFileNameWithPath = string_trim(state.ProgramPath) + 'V8-8-0-Energy+.idd'
    state.NewIDDFileNameWithPath = string_trim(state.ProgramPath) + 'V8-9-0-Energy+.idd'
    state.RepVarFileNameWithPath = string_trim(state.ProgramPath) + 'Report Variables 8-8-0 to 8-9-0.csv'

def fix_fuel_types(in_out_arg: List[str], index: int) -> None:
    arg = in_out_arg[index]
    if arg == '':
        return
    arg_upper = arg.upper()
    
    if arg_upper == 'ELECTRIC':
        in_out_arg[index] = 'Electricity'
    elif arg_upper == 'ELEC':
        in_out_arg[index] = 'Electricity'
    elif arg_upper == 'GAS':
        in_out_arg[index] = 'NaturalGas'
    elif arg_upper == 'NATURAL GAS':
        in_out_arg[index] = 'NaturalGas'
    elif arg_upper == 'PROPANE':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'LPG':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'PROPANE GAS':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'FUEL OIL #1':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'FUEL OIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'DISTILLATE OIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'DISTILLATEOIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'FUEL OIL #2':
        in_out_arg[index] = 'FuelOil#2'
    elif arg_upper == 'RESIDUAL OIL':
        in_out_arg[index] = 'FuelOil#2'
    elif arg_upper == 'RESIDUALOIL':
        in_out_arg[index] = 'FuelOil#2'

def create_new_idf_using_rules(
    state: ExternalState,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: IOBase,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> None:
    fmta = "(A)"
    
    first_time = True
    if first_time:
        first_time = False
    
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
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = in_lfn.readline().strip()
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = ''
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.Blank
                    ios = 1
            
            if full_file_name and full_file_name[0] == '!':
                full_file_name = state.Blank
                continue
            
            units_arg = state.Blank
            if ios != 0:
                full_file_name = state.Blank
            
            full_file_name = string_adjustl(full_file_name)
            
            if full_file_name != state.Blank:
                state.DisplayString('Processing IDF -- ' + string_trim(full_file_name))
                state.Auditf.write(' Processing IDF -- ' + string_trim(full_file_name) + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    dot_pos += 1  # Convert to 1-based
                    state.FileNamePath = full_file_name[:dot_pos-1]
                    local_file_extension = state.MakeLowerCase(full_file_name[dot_pos:])
                else:
                    dot_pos = 0
                    state.FileNamePath = full_file_name
                    print(' assuming file extension of .idf')
                    state.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = string_trim(full_file_name) + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = state.GetNewUnitNumber()
                
                try:
                    with open(full_file_name, 'r') as f:
                        file_ok = True
                except FileNotFoundError:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + string_trim(full_file_name))
                    state.Auditf.write('File not found=' + string_trim(full_file_name) + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_path = state.FileNamePath + '.' + string_trim(local_file_extension) + 'dif'
                    else:
                        dif_file_path = state.FileNamePath + '.' + string_trim(local_file_extension) + 'new'
                    
                    dif_lfn_handle = open(dif_file_path, 'w')
                    
                    if local_file_extension == 'imf':
                        state.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        dif_lfn_handle.close()
                        break
                    
                    alphas = [state.Blank] * (state.MaxAlphaArgsFound + 1)
                    numbers = [0.0] * (state.MaxNumericArgsFound + 1)
                    in_args = [state.Blank] * (state.MaxTotalArgs + 1)
                    temp_args = [state.Blank] * (state.MaxTotalArgs + 1)
                    aorn = [False] * (state.MaxTotalArgs + 1)
                    req_fld = [False] * (state.MaxTotalArgs + 1)
                    fld_names = [state.Blank] * (state.MaxTotalArgs + 1)
                    fld_defaults = [state.Blank] * (state.MaxTotalArgs + 1)
                    fld_units = [state.Blank] * (state.MaxTotalArgs + 1)
                    
                    nw_aorn = [False] * (state.MaxTotalArgs + 1)
                    nw_req_fld = [False] * (state.MaxTotalArgs + 1)
                    nw_fld_names = [state.Blank] * (state.MaxTotalArgs + 1)
                    nw_fld_defaults = [state.Blank] * (state.MaxTotalArgs + 1)
                    nw_fld_units = [state.Blank] * (state.MaxTotalArgs + 1)
                    
                    p_aorn = [False] * (state.MaxTotalArgs + 1)
                    p_req_fld = [False] * (state.MaxTotalArgs + 1)
                    p_fld_names = [state.Blank] * (state.MaxTotalArgs + 1)
                    p_fld_defaults = [state.Blank] * (state.MaxTotalArgs + 1)
                    p_fld_units = [state.Blank] * (state.MaxTotalArgs + 1)
                    
                    out_args = [state.Blank] * (state.MaxTotalArgs + 1)
                    p_out_args = [state.Blank] * (state.MaxTotalArgs + 1)
                    match_arg = [state.Blank] * (state.MaxTotalArgs + 1)
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
                            dif_lfn_handle.write('! Deleting: ' + string_trim(state.IDFRecords[num].Name) + '="' + string_trim(state.IDFRecords[num].Alphas[1]) + '".\n')
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS + 1, state.IDFRecords[num].CommtE + 1):
                            dif_lfn_handle.write(string_trim(state.Comments[xcount]) + '\n')
                            if xcount == state.IDFRecords[num].CommtE:
                                dif_lfn_handle.write('\n')
                        
                        if no_version and num == 1:
                            state.GetNewObjectDefInIDD('VERSION', nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1] = state.sVersionNum
                            cur_args = 1
                            state.WriteOutIDFLinesAsComments(dif_lfn_handle, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if state.MakeUPPERCase(string_trim(state.IDFRecords[num].Name)) in ['PROGRAMCONTROL', 'SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA', 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                            continue
                        
                        if state.MakeUPPERCase(string_trim(state.IDFRecords[num].Name)) == 'WATER HEATER:SIMPLE':
                            dif_lfn_handle.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        object_name = state.IDFRecords[num].Name
                        
                        if state.FindItemInList(object_name, [d.Name for d in state.ObjectDef], state.NumObjectDefs) != 0:
                            state.GetObjectDefInIDD(object_name, aorn, req_fld, fld_names, fld_defaults, fld_units)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[1:num_alphas+1] = state.IDFRecords[num].Alphas[1:num_alphas+1]
                            numbers[1:num_numbers+1] = state.IDFRecords[num].Numbers[1:num_numbers+1]
                            cur_args = num_alphas + num_numbers
                            in_args = [state.Blank] * (state.MaxTotalArgs + 1)
                            out_args = [state.Blank] * (state.MaxTotalArgs + 1)
                            temp_args = [state.Blank] * (state.MaxTotalArgs + 1)
                            na = 0
                            nn = 0
                            for arg in range(1, cur_args + 1):
                                if aorn[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na]
                                else:
                                    nn += 1
                                    in_args[arg] = str(numbers[nn])
                        else:
                            state.Auditf.write('Object="' + string_trim(object_name) + '" does not seem to be on the "old" IDD.\n')
                            state.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            state.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[1:num_alphas+1] = state.IDFRecords[num].Alphas[1:num_alphas+1]
                            numbers[1:num_numbers+1] = state.IDFRecords[num].Numbers[1:num_numbers+1]
                            for arg in range(1, num_alphas + 1):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(1, num_numbers + 1):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [state.Blank] * (state.MaxTotalArgs + 1)
                            nw_fld_units = [state.Blank] * (state.MaxTotalArgs + 1)
                            state.WriteOutIDFLinesAsComments(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if state.FindItemInList(state.MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        object_name_upper = state.MakeUPPERCase(string_trim(state.IDFRecords[num].Name))
                        
                        if object_name_upper == 'VERSION':
                            if in_args[1][:3] == state.sVersionNum and arg_file:
                                state.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                dif_lfn_handle.close()
                                latest_version = True
                                break
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1] = state.sVersionNum
                            nodiff = False
                        
                        elif object_name_upper == 'ZONEHVAC:EQUIPMENTLIST':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1] = in_args[1]
                            out_args[2] = 'SequentialLoad'
                            out_args[3:cur_args+2] = in_args[2:cur_args+1]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == 'GROUNDHEATEXCHANGER:VERTICAL':
                            nodiff = False
                            object_name = 'GroundHeatExchanger:System'
                            temp_args = in_args[:]
                            temp_args_num = cur_args
                            
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:5] = temp_args[1:5]
                            out_args[5] = 'Site:GroundTemperature:Undisturbed:KusudaAchenbach'
                            out_args[6] = string_trim(temp_args[1]) + ' Ground Temps'
                            out_args[7:9] = temp_args[8:10]
                            out_args[9] = string_trim(temp_args[1]) + ' Response Factors'
                            cur_args = 9
                            state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = 'GroundHeatExchanger:Vertical:Properties'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1] = string_trim(temp_args[1]) + ' Properties'
                            out_args[2] = '1'
                            out_args[3] = temp_args[6]
                            try:
                                glhe_temp_val = float(temp_args[7])
                                out_args[4] = str(glhe_temp_val * 2)
                            except:
                                out_args[4] = temp_args[7]
                            out_args[5] = temp_args[11]
                            out_args[6] = '3.90E+06'
                            out_args[7] = temp_args[12]
                            out_args[8] = '1.77E+06'
                            out_args[9] = temp_args[13]
                            out_args[10] = temp_args[15]
                            out_args[11] = temp_args[14]
                            cur_args = 11
                            state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = 'Site:GroundTemperature:Undisturbed:KusudaAchenbach'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1] = string_trim(temp_args[1]) + ' Ground Temps'
                            out_args[2] = temp_args[8]
                            out_args[3] = '920'
                            glhe_temp_val = 0.0
                            try:
                                glhe_temp_val = float(temp_args[9])
                                out_args[4] = str(glhe_temp_val / 920.0)
                            except:
                                out_args[4] = temp_args[9]
                            out_args[5] = temp_args[10]
                            out_args[6] = '3.2'
                            out_args[7] = '8'
                            cur_args = 7
                            state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = 'GroundHeatExchanger:ResponseFactors'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1] = string_trim(temp_args[1]) + ' Response Factors'
                            out_args[2] = string_trim(temp_args[1]) + ' Properties'
                            out_args[3] = temp_args[5]
                            out_args[4] = temp_args[17]
                            cur_args = 4
                            i = 0
                            while True:
                                i += 1
                                cur_field = 2 * (i - 1) + 19
                                if cur_field > temp_args_num:
                                    break
                                out_args[cur_args + 1] = temp_args[cur_field]
                                out_args[cur_args + 2] = temp_args[cur_field + 1]
                                cur_args += 2
                            
                            state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            written = True
                        
                        elif object_name_upper == 'AIRCONDITIONER:VARIABLEREFRIGERANTFLOW':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 67:
                                fix_fuel_types(out_args, 67)
                        
                        elif object_name_upper == 'BOILER:HOTWATER':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 2:
                                fix_fuel_types(out_args, 2)
                            if cur_args >= 15 and state.SameString(in_args[15], 'VariableFlow'):
                                out_args[15] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'BOILER:STEAM':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 2:
                                fix_fuel_types(out_args, 2)
                        
                        elif object_name_upper == 'BRANCH':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            i = 0
                            while True:
                                i += 1
                                cur_field = 4 * (i - 1) + 3
                                if cur_field > cur_args:
                                    break
                                if state.SameString(in_args[cur_field], "GroundHeatExchanger:Vertical"):
                                    out_args[cur_field] = "GroundHeatExchanger:System"
                        
                        elif object_name_upper == 'CHILLER:ELECTRIC:EIR':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 23 and state.SameString(in_args[23], 'VariableFlow'):
                                out_args[23] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:ELECTRIC:REFORMULATEDEIR':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 22 and state.SameString(in_args[22], 'VariableFlow'):
                                out_args[22] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:ELECTRIC':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 27 and state.SameString(in_args[27], 'VariableFlow'):
                                out_args[27] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:ABSORPTION:INDIRECT':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 16 and state.SameString(in_args[16], 'VariableFlow'):
                                out_args[16] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:ABSORPTION':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 23 and state.SameString(in_args[23], 'VariableFlow'):
                                out_args[23] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:CONSTANTCOP':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 11 and state.SameString(in_args[11], 'VariableFlow'):
                                out_args[11] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:ENGINEDRIVEN':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 36:
                                fix_fuel_types(out_args, 36)
                            if cur_args >= 41 and state.SameString(in_args[41], 'VariableFlow'):
                                out_args[41] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'CHILLER:COMBUSTIONTURBINE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 54 and state.SameString(in_args[54], 'VariableFlow'):
                                out_args[54] = 'LeavingSetpointModulated'
                            if cur_args >= 55:
                                fix_fuel_types(out_args, 55)
                        
                        elif object_name_upper == 'CHILLERHEATER:ABSORPTION:DIRECTFIRED':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 33:
                                fix_fuel_types(out_args, 33)
                        
                        elif object_name_upper == 'FUELFACTORS':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 1:
                                fix_fuel_types(out_args, 1)
                                if state.SameString(out_args[1], "PropaneGas"):
                                    out_args[1] = "Propane"
                        
                        elif object_name_upper == 'GENERATOR:COMBUSTIONTURBINE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 22:
                                fix_fuel_types(out_args, 22)
                        
                        elif object_name_upper == 'GENERATOR:INTERNALCOMBUSTIONENGINE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 20:
                                fix_fuel_types(out_args, 20)
                        
                        elif object_name_upper == 'GENERATOR:MICROTURBINE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 12:
                                fix_fuel_types(out_args, 12)
                        
                        elif object_name_upper == 'WATERHEATER:MIXED':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 11:
                                fix_fuel_types(out_args, 11)
                            if cur_args >= 15:
                                fix_fuel_types(out_args, 15)
                            if cur_args >= 18:
                                fix_fuel_types(out_args, 18)
                        
                        elif object_name_upper == 'WATERHEATER:STRATIFIED':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 17:
                                fix_fuel_types(out_args, 17)
                            if cur_args >= 20:
                                fix_fuel_types(out_args, 20)
                            if cur_args >= 24:
                                fix_fuel_types(out_args, 24)
                        
                        elif object_name_upper == 'CONDENSEREQUIPMENTLIST':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            i = 0
                            while True:
                                i += 1
                                cur_field = 2 * (i - 1) + 2
                                if cur_field > cur_args:
                                    break
                                if state.SameString(in_args[cur_field], "GroundHeatExchanger:Vertical"):
                                    out_args[cur_field] = "GroundHeatExchanger:System"
                        
                        elif object_name_upper == 'ELECTRICEQUIPMENT:ITE:AIRCOOLED':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:3] = in_args[1:3]
                            out_args[3] = 'FlowFromSystem'
                            out_args[4:cur_args+2] = in_args[3:cur_args+1]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == 'HEATBALANCEALGORITHM':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 1:
                                if state.SameString(in_args[1], 'Default'):
                                    out_args[1] = 'ConductionTransferFunction'
                                elif state.SameString(in_args[1], 'CTF'):
                                    out_args[1] = 'ConductionTransferFunction'
                                elif state.SameString(in_args[1], 'EMPD'):
                                    out_args[1] = 'MoisturePenetrationDepthConductionTransferFunction'
                                elif state.SameString(in_args[1], 'CondFD'):
                                    out_args[1] = 'ConductionFiniteDifference'
                                elif state.SameString(in_args[1], 'CONDUCTIONFINITEDIFFERENCEDETAILED'):
                                    out_args[1] = 'ConductionFiniteDifference'
                                elif state.SameString(in_args[1], 'HAMT'):
                                    out_args[1] = 'CombinedHeatAndMoistureFiniteElement'
                        
                        elif object_name_upper == 'OUTPUT:CONSTRUCTIONS':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 1:
                                if state.SameString(in_args[1][:3], 'Con'):
                                    out_args[1] = 'Constructions'
                                elif state.SameString(in_args[1][:3], 'Mat'):
                                    out_args[1] = 'Materials'
                            if cur_args >= 2:
                                if state.SameString(in_args[2][:3], 'Con'):
                                    out_args[2] = 'Constructions'
                                elif state.SameString(in_args[2][:3], 'Mat'):
                                    out_args[2] = 'Materials'
                        
                        elif object_name_upper == 'SCHEDULE:DAY:INTERVAL':
                            object_name = 'Schedule:Day:Interval'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args = in_args[:]
                            if state.SameString(in_args[3], 'YES'):
                                out_args[3] = 'Average'
                        
                        elif object_name_upper == 'SCHEDULE:DAY:LIST':
                            object_name = 'Schedule:Day:List'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args = in_args[:]
                            if state.SameString(in_args[3], 'YES'):
                                out_args[3] = 'Average'
                        
                        elif object_name_upper == 'SCHEDULE:COMPACT':
                            object_name = 'Schedule:Compact'
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args = in_args[:]
                            for arg in range(3, cur_args + 1):
                                upper_in_arg = state.MakeUpperCase(in_args[arg])
                                if "INTERPOLATE" in upper_in_arg and "YES" in upper_in_arg:
                                    out_args[arg] = "Interpolate:Average"
                        
                        elif object_name_upper == 'SIZINGPERIOD:DESIGNDAY':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 18:
                                if state.SameString(in_args[18], '0'):
                                    out_args[18] = 'No'
                                elif state.SameString(in_args[18], '1'):
                                    out_args[18] = 'Yes'
                            if cur_args >= 19:
                                if state.SameString(in_args[19], '0'):
                                    out_args[19] = 'No'
                                elif state.SameString(in_args[19], '1'):
                                    out_args[19] = 'Yes'
                            if cur_args >= 20:
                                if state.SameString(in_args[20], '0'):
                                    out_args[20] = 'No'
                                elif state.SameString(in_args[20], '1'):
                                    out_args[20] = 'Yes'
                        
                        elif object_name_upper == 'GENERATOR:WINDTURBINE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 3:
                                if state.SameString(in_args[3], 'HAWT'):
                                    out_args[3] = 'HorizontalAxisWindTurbine'
                                elif state.SameString(in_args[3], 'None'):
                                    out_args[3] = 'HorizontalAxisWindTurbine'
                                elif state.SameString(in_args[3], 'VAWT'):
                                    out_args[3] = 'VerticalAxisWindTurbine'
                            if cur_args >= 4:
                                if state.SameString(in_args[4], 'FSFP'):
                                    out_args[4] = 'FixedSpeedFixedPitch'
                                elif state.SameString(in_args[4], 'FSVP'):
                                    out_args[4] = 'FixedSpeedVariablePitch'
                                elif state.SameString(in_args[4], 'VSFP'):
                                    out_args[4] = 'VariableSpeedFixedPitch'
                                elif state.SameString(in_args[4], 'VSVP'):
                                    out_args[4] = 'VariableSpeedVariablePitch'
                                elif state.SameString(in_args[4], 'None'):
                                    out_args[4] = 'VariableSpeedVariablePitch'
                        
                        elif object_name_upper == 'ZONE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 12:
                                if state.SameString(in_args[12], 'DOE2'):
                                    out_args[12] = 'DOE-2'
                        
                        elif object_name_upper == 'ZONEAIRHEATBALANCEALGORITHM':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 1:
                                if state.SameString(in_args[1], '3RDORDERBACKWARDDIFFERENCE'):
                                    out_args[1] = 'ThirdOrderBackwardDifference'
                        
                        elif object_name_upper == 'OUTPUT:TABLE:SUMMARYREPORTS':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            cur_field = 0
                            for temp_args_num in range(1, cur_args + 1):
                                if in_args[temp_args_num] != state.Blank:
                                    cur_field += 1
                                    out_args[cur_field] = in_args[temp_args_num]
                            if cur_field < cur_args:
                                nodiff = False
                                cur_args = cur_field
                        
                        elif object_name_upper == 'OUTPUT:VARIABLE':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            if out_args[1] == state.Blank:
                                out_args[1] = '*'
                                nodiff = False
                            
                            del_this = [False]
                            state.ScanOutputVariablesForReplacement(
                                2, del_this, checkrvi, nodiff, object_name, dif_lfn_handle, True, False, False, cur_args, written)
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            del_this = [False]
                            state.ScanOutputVariablesForReplacement(
                                1, del_this, checkrvi, nodiff, object_name, dif_lfn_handle, False, True, False, cur_args, written)
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            if out_args[1] == state.Blank:
                                out_args[1] = '*'
                                nodiff = False
                            del_this = [False]
                            state.ScanOutputVariablesForReplacement(
                                2, del_this, checkrvi, nodiff, object_name, dif_lfn_handle, False, False, True, cur_args, written)
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            if out_args[1] == state.Blank:
                                out_args[1] = '*'
                                nodiff = False
                            del_this = [False]
                            state.ScanOutputVariablesForReplacement(
                                2, del_this, checkrvi, nodiff, object_name, dif_lfn_handle, False, False, False, cur_args, written)
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            del_this = [False]
                            state.ScanOutputVariablesForReplacement(
                                3, del_this, checkrvi, nodiff, object_name, dif_lfn_handle, False, False, False, cur_args, written, True)
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'OUTPUT:TABLE:MONTHLY':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            nodiff = True
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            cur_var = 3
                            var = 3
                            while var <= cur_args:
                                uc_rep_var_name = state.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, state.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg] != state.Blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.OTMVarCaution[arg]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Output Table Monthly (new)="' +
                                                        string_trim(state.NewRepVarName[arg]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.OTMVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        if arg + 1 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = string_trim(state.NewRepVarName[arg + 1]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg + 1] != state.Blank:
                                                    if not state.OTMVarCaution[arg + 1]:
                                                        state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            string_trim(state.NewRepVarName[arg + 1]) +
                                                            '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 1]) + '".')
                                                        dif_lfn_handle.write('\n')
                                                        state.OTMVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                        if arg + 2 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg + 2]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg + 2] != state.Blank:
                                                if not state.OTMVarCaution[arg + 2]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Output Table Monthly (new)="' +
                                                        string_trim(state.NewRepVarName[arg + 2]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 2]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.OTMVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var - 1
                        
                        elif object_name_upper == 'METER:CUSTOM':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            cur_var = 4
                            var = 4
                            while var <= cur_args:
                                uc_rep_var_name = state.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, state.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg] != state.Blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrVarCaution[arg]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Custom Meter (new)="' +
                                                        string_trim(state.NewRepVarName[arg]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.CMtrVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        if arg + 1 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = string_trim(state.NewRepVarName[arg + 1]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg + 1] != state.Blank and not state.SameString(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrVarCaution[arg + 1]:
                                                        state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                            '" conversion to Custom Meter (new)="' +
                                                            string_trim(state.NewRepVarName[arg + 1]) +
                                                            '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 1]) + '".')
                                                        dif_lfn_handle.write('\n')
                                                        state.CMtrVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                        if arg + 2 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg + 2]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg + 2] != state.Blank:
                                                if not state.CMtrVarCaution[arg + 2]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Custom Meter (new)="' +
                                                        string_trim(state.NewRepVarName[arg + 2]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 2]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.CMtrVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var
                            for arg in range(cur_var, 0, -1):
                                if out_args[arg] == state.Blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_name_upper == 'METER:CUSTOMDECREMENT':
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            cur_var = 4
                            var = 4
                            while var <= cur_args:
                                uc_rep_var_name = state.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, state.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = state.MakeUPPERCase(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg] != state.Blank and not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrDVarCaution[arg]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Custom Meter (new)="' +
                                                        string_trim(state.NewRepVarName[arg]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.CMtrDVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        if arg + 1 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not state.SameString(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = string_trim(state.NewRepVarName[arg + 1]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg + 1] != state.Blank and not state.SameString(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrDVarCaution[arg + 1]:
                                                        state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                            '" conversion to Custom Decrement Meter (new)="' +
                                                            string_trim(state.NewRepVarName[arg + 1]) +
                                                            '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 1]) + '".')
                                                        dif_lfn_handle.write('\n')
                                                        state.CMtrDVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                        if arg + 2 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = string_trim(state.NewRepVarName[arg + 2]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                            if state.NewRepVarCaution[arg + 2] != state.Blank:
                                                if not state.CMtrDVarCaution[arg + 2]:
                                                    state.writePreprocessorObject(dif_lfn_handle, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + string_trim(state.OldRepVarName[arg]) +
                                                        '" conversion to Custom Meter (new)="' +
                                                        string_trim(state.NewRepVarName[arg + 2]) +
                                                        '" has the following caution "' + string_trim(state.NewRepVarCaution[arg + 2]) + '".')
                                                    dif_lfn_handle.write('\n')
                                                    state.CMtrDVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            nodiff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var
                            for arg in range(cur_var, 0, -1):
                                if out_args[arg] == state.Blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        else:
                            if state.FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                state.Auditf.write('Object="' + string_trim(object_name) + '" is not in the "new" IDD.\n')
                                state.Auditf.write('... will be listed as comments on the new output file.\n')
                                state.WriteOutIDFLinesAsComments(dif_lfn_handle, object_name, cur_args, in_args, fld_names, fld_units)
                                written = True
                            else:
                                state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                nodiff = True
                        
                        if diff_min_fields and nodiff:
                            state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = False
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            state.CheckSpecialObjects(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.IDFRecords[state.NumIDFRecords].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords].CommtE + 1, state.CurComment + 1):
                            dif_lfn_handle.write(string_trim(state.Comments[xcount]) + '\n')
                    
                    if state.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        state.GetNewObjectDefInIDD(object_name, nw_aorn, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        nodiff = False
                        out_args[1] = 'Regular'
                        cur_args = 1
                        state.WriteOutIDFLines(dif_lfn_handle, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    dif_lfn_handle.close()
                    state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                    state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
                    state.CloseOut()
                else:
                    state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                    state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
            else:
                end_of_file[0] = True
            
            state.CreateNewName('Reallocate', '', '')
        
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
        state.copyfile(state.FileNamePath + '.' + arg_idf_extension, state.FileNamePath + '.' + arg_idf_extension + 'old')
        state.copyfile(state.FileNamePath + '.' + arg_idf_extension + 'new', state.FileNamePath + '.' + arg_idf_extension)
        try:
            with open(state.FileNamePath + '.rvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        if file_exist:
            state.copyfile(state.FileNamePath + '.rvi', state.FileNamePath + '.rviold')
        try:
            with open(state.FileNamePath + '.rvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        if file_exist:
            state.copyfile(state.FileNamePath + '.rvinew', state.FileNamePath + '.rvi')
        try:
            with open(state.FileNamePath + '.mvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        if file_exist:
            state.copyfile(state.FileNamePath + '.mvi', state.FileNamePath + '.mviold')
        try:
            with open(state.FileNamePath + '.mvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        if file_exist:
            state.copyfile(state.FileNamePath + '.mvinew', state.FileNamePath + '.mvi')
