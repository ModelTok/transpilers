from typing import List, Dict, Tuple, Optional, Protocol
from dataclasses import dataclass, field
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: Blank, MaxNameLength, MaxNameLengthDiffUnits
# - DataVCompareGlobals: global state (FullFileName, FileNamePath, Auditf, VerString, VersionNum, 
#   IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath,
#   ProcessingIMFFile, FatalError, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   NumIDFRecords, IDFRecords, Comments, CurComment, Blank, OldRepVarName, NewRepVarName,
#   NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, ObjectDef, NumObjectDefs,
#   NumRepVarNames, NotInNew, ProgNameConversion, MakingPretty)
# - InputProcessor: ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, FindItemInList
# - VCompareGlobalRoutines: ScanOutputVariablesForReplacement, CheckSpecialObjects, ProcessRviMviFiles,
#   WriteOutIDFLinesAsComments, WriteOutIDFLines, WriteOutIDFLines, GetNumSectionsFound, CloseOut,
#   CreateNewName
# - General: MakeLowerCase, MakeUPPERCase, SameString, ProcessNumber, RoundSigDigits, TrimTrailZeros,
#   GetNewUnitNumber, FindNumber, writePreprocessorObject, copyfile
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError


class ExternalDependencies(Protocol):
    """Protocol for external global state and functions."""
    
    # Global scalar state
    FullFileName: str
    FileNamePath: str
    Auditf: int
    VerString: str
    VersionNum: float
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    ProgramPath: str
    ProcessingIMFFile: bool
    FatalError: bool
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    NumIDFRecords: int
    CurComment: int
    Blank: str
    NumObjectDefs: int
    NumRepVarNames: int
    ProgNameConversion: str
    MakingPretty: bool
    
    # Arrays/collections
    IDFRecords: List[Dict]
    Comments: List[str]
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    ObjectDef: Dict
    NotInNew: List[str]
    
    # Functions
    def DisplayString(s: str) -> None: ...
    def GetNewObjectDefInIDD(name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def GetObjectDefInIDD(name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def MakeUPPERCase(s: str) -> str: ...
    def MakeLowerCase(s: str) -> str: ...
    def WriteOutIDFLinesAsComments(lfn: int, obj: str, nargs: int, args: List[str], fnames: List[str], funits: List[str]) -> None: ...
    def WriteOutIDFLines(lfn: int, obj: str, nargs: int, args: List[str], fnames: List[str], funits: List[str]) -> None: ...
    def ScanOutputVariablesForReplacement(idx: int, del_this: bool, check_rvi: bool, nodiff: bool, 
                                          obj: str, lfn: int, is_outvar: bool, is_mtrvar: bool, 
                                          is_timebinvar: bool, nargs: int, written: bool, sensor: bool) -> None: ...
    def CheckSpecialObjects(lfn: int, obj: str, nargs: int, args: List[str], fnames: List[str], funits: List[str], written: bool) -> None: ...
    def ProcessInput(idd_old: str, idd_new: str, idf: str) -> None: ...
    def CreateNewName(op: str, name: str, ext: str) -> None: ...
    def CloseOut() -> None: ...
    def ProcessRviMviFiles(path: str, ext: str) -> None: ...
    def FindItemInList(item: str, lst: List[str], size: int) -> int: ...
    def SameString(s1: str, s2: str) -> bool: ...
    def ShowWarningError(msg: str, lfn: int) -> None: ...
    def ShowSevereError(msg: str, lfn: int) -> None: ...
    def ShowMessage(msg: str) -> None: ...
    def ShowContinueError(msg: str) -> None: ...
    def ShowFatalError(msg: str) -> None: ...
    def ProcessNumber(s: str, err_flag: bool) -> float: ...
    def RoundSigDigits(val: float, digits: int) -> str: ...
    def TrimTrailZeros(s: str) -> str: ...
    def GetNewUnitNumber() -> int: ...
    def FindNumber(name: str, lst: List[str]) -> int: ...
    def writePreprocessorObject(lfn: int, prog: str, severity: str, msg: str) -> None: ...
    def copyfile(src: str, dst: str, err_flag: bool) -> None: ...
    def GetNumSectionsFound(section: str) -> int: ...


def set_this_version_variables(deps: ExternalDependencies) -> None:
    """Initialize version variables for conversion from V4.0 to V5.0."""
    deps.VerString = 'Conversion 4.0 => 5.0'
    deps.VersionNum = 5.0
    deps.IDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V4-0-0-Energy+.idd'
    deps.NewIDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V5-0-0-Energy+.idd'
    deps.RepVarFileNameWithPath = deps.ProgramPath.rstrip() + 'Report Variables 4-0-0-024 to 5-0-0.csv'


def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDependencies
) -> bool:
    """
    Creates new IDFs based on conversion rules specified by developers.
    Processes files and applies transformations from V4.0 to V5.0 format.
    """
    
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    fmt_a = "(A)"
    
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
                        full_file_name = deps.Blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = deps.Blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = deps.Blank
                    continue
            
            units_arg = deps.Blank
            if ios != 0:
                full_file_name = deps.Blank
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != deps.Blank:
                deps.DisplayString('Processing IDF -- ' + full_file_name)
                print(' Processing IDF -- ' + full_file_name, file=open(deps.Auditf, 'a'))
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = deps.MakeLowerCase(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    print(' ..assuming file extension of .idf', file=open(deps.Auditf, 'a'))
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                deps.FileNamePath = file_name_path
                dif_lfn = deps.GetNewUnitNumber()
                file_ok = os.path.isfile(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    print('File not found=' + full_file_name, file=open(deps.Auditf, 'a'))
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        output_file = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        deps.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.Auditf)
                        deps.ProcessingIMFFile = True
                    else:
                        deps.ProcessingIMFFile = False
                    
                    deps.ProcessInput(deps.IDDFileNameWithPath, deps.NewIDDFileNameWithPath, full_file_name)
                    
                    if deps.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    alphas = [deps.Blank] * (deps.MaxAlphaArgsFound + 1)
                    numbers = [0.0] * (deps.MaxNumericArgsFound + 1)
                    in_args = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    a_or_n = [False] * (deps.MaxTotalArgs + 1)
                    req_fld = [False] * (deps.MaxTotalArgs + 1)
                    fld_names = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    fld_defaults = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    fld_units = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    nw_a_or_n = [False] * (deps.MaxTotalArgs + 1)
                    nw_req_fld = [False] * (deps.MaxTotalArgs + 1)
                    nw_fld_names = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    nw_fld_defaults = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    nw_fld_units = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    out_args = [deps.Blank] * (deps.MaxTotalArgs + 1)
                    match_arg = [False] * (deps.MaxTotalArgs + 1)
                    
                    delete_this_record = [False] * (deps.NumIDFRecords + 1)
                    
                    no_version = True
                    for num in range(1, deps.NumIDFRecords + 1):
                        if deps.MakeUPPERCase(deps.IDFRecords[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(1, deps.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            print('! Deleting: ' + deps.IDFRecords[num]['Name'].rstrip() + ':' + deps.IDFRecords[num]['Alphas'][1].rstrip(), file=open(dif_lfn, 'a'))
                    
                    for num in range(1, deps.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(deps.IDFRecords[num]['CommtS'] + 1, deps.IDFRecords[num]['CommtE'] + 1):
                            print(deps.Comments[xcount].rstrip(), file=open(dif_lfn, 'a'))
                            if xcount == deps.IDFRecords[num]['CommtE']:
                                print(' ', file=open(dif_lfn, 'a'))
                        
                        if no_version and num == 1:
                            nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD('VERSION')
                            out_args[1] = '3.2'
                            cur_args = 1
                            deps.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = deps.IDFRecords[num]['Name']
                        
                        # Skip deleted objects
                        if deps.MakeUPPERCase(object_name.strip()) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if deps.MakeUPPERCase(object_name.strip()) == 'AIRFLOW MODEL':
                            continue
                        if deps.MakeUPPERCase(object_name.strip()) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if deps.MakeUPPERCase(object_name.strip()) == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if deps.MakeUPPERCase(object_name.strip()) == 'WATER HEATER:SIMPLE':
                            print('! The WATER HEATER:SIMPLE object has been deleted', file=open(dif_lfn, 'a'))
                            print('Output:PreprocessorMessage,' + deps.ProgNameConversion.strip() + ',warning,The WATER HEATER:SIMPLE object has been deleted;', file=open(dif_lfn, 'a'))
                            continue
                        
                        if deps.FindItemInList(object_name, [d['Name'] for d in deps.ObjectDef], deps.NumObjectDefs) != 0:
                            num_args, a_or_n, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = deps.GetObjectDefInIDD(object_name)
                            num_alphas = deps.IDFRecords[num]['NumAlphas']
                            num_numbers = deps.IDFRecords[num]['NumNumbers']
                            for i in range(1, num_alphas + 1):
                                alphas[i] = deps.IDFRecords[num]['Alphas'][i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = deps.IDFRecords[num]['Numbers'][i]
                            cur_args = num_alphas + num_numbers
                            in_args = [deps.Blank] * (deps.MaxTotalArgs + 1)
                            out_args = [deps.Blank] * (deps.MaxTotalArgs + 1)
                            na = 0
                            nn = 0
                            for arg in range(1, cur_args + 1):
                                if a_or_n[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na]
                                else:
                                    nn += 1
                                    in_args[arg] = str(numbers[nn])
                        else:
                            print('Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.', file=open(deps.Auditf, 'a'))
                            print('... will be listed as comments (no field names) on the new output file.', file=open(deps.Auditf, 'a'))
                            print('... Alpha fields will be listed first, then numerics.', file=open(deps.Auditf, 'a'))
                            num_alphas = deps.IDFRecords[num]['NumAlphas']
                            num_numbers = deps.IDFRecords[num]['NumNumbers']
                            for i in range(1, num_alphas + 1):
                                alphas[i] = deps.IDFRecords[num]['Alphas'][i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = deps.IDFRecords[num]['Numbers'][i]
                            for arg in range(1, num_alphas + 1):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(1, num_numbers + 1):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [deps.Blank] * (deps.MaxTotalArgs + 1)
                            nw_fld_units = [deps.Blank] * (deps.MaxTotalArgs + 1)
                            deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.FindItemInList(deps.MakeUPPERCase(object_name), deps.NotInNew, len(deps.NotInNew)) == 0:
                            nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not deps.MakingPretty:
                            obj_upper = deps.MakeUPPERCase(object_name.strip())
                            
                            if obj_upper == 'VERSION':
                                if in_args[1][:3] == '5.0' and arg_file:
                                    deps.ShowWarningError('File is already at latest version.  No new diff file made.', deps.Auditf)
                                    os.close(dif_lfn)
                                    latest_version = True
                                    break
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1] = '5.0'
                                no_diff = False
                            
                            elif obj_upper == 'UTILITYCOST:VARIABLE':
                                no_diff = False
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:3] = in_args[1:3]
                                out_args[3] = 'Dimensionless'
                                out_args[4:cur_args+2] = in_args[3:cur_args+1]
                            
                            elif obj_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                no_diff = False
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:20] = in_args[1:20]
                                wto_ahp_recip = False
                                wto_ahp_rotary = False
                                wto_ahp_scroll = False
                                if deps.SameString(in_args[2], 'Reciprocating'):
                                    wto_ahp_recip = True
                                elif deps.SameString(in_args[2], 'Rotary'):
                                    wto_ahp_rotary = True
                                elif deps.SameString(in_args[2], 'Scroll'):
                                    wto_ahp_scroll = True
                                else:
                                    print('Output:PreprocessorMessage,' + deps.ProgNameConversion.strip() + ',warning,Coil:Cooling:WaterToAirHeatPump:ParameterEstimation=' + in_args[1].strip() + ', does not appear to have a valid Compressor Type;', file=open(dif_lfn, 'a'))
                                
                                if wto_ahp_recip:
                                    out_args[20:23] = in_args[20:23]
                                    out_args[23:26] = [deps.Blank] * 3
                                elif wto_ahp_rotary:
                                    out_args[20:22] = in_args[20:22]
                                    out_args[22:26] = [deps.Blank] * 4
                                elif wto_ahp_scroll:
                                    out_args[20:23] = [deps.Blank] * 3
                                    out_args[23:26] = in_args[20:23]
                                else:
                                    out_args[20:26] = [deps.Blank] * 6
                                
                                if deps.SameString(in_args[3], 'Water'):
                                    out_args[26] = in_args[23]
                                    out_args[27:29] = [deps.Blank] * 2
                                else:
                                    out_args[26] = deps.Blank
                                    out_args[27:29] = in_args[23:25]
                                cur_args = 28
                            
                            elif obj_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                no_diff = False
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:17] = in_args[1:17]
                                wto_ahp_recip = False
                                wto_ahp_rotary = False
                                wto_ahp_scroll = False
                                if deps.SameString(in_args[2], 'Reciprocating'):
                                    wto_ahp_recip = True
                                elif deps.SameString(in_args[2], 'Rotary'):
                                    wto_ahp_rotary = True
                                elif deps.SameString(in_args[2], 'Scroll'):
                                    wto_ahp_scroll = True
                                else:
                                    print('Output:PreprocessorMessage,' + deps.ProgNameConversion.strip() + ',warning,Coil:Heating:WaterToAirHeatPump:ParameterEstimation=' + in_args[1].strip() + ', does not appear to have a valid Compressor Type;', file=open(dif_lfn, 'a'))
                                
                                if wto_ahp_recip:
                                    out_args[17:20] = in_args[17:20]
                                    out_args[20:23] = [deps.Blank] * 3
                                elif wto_ahp_rotary:
                                    out_args[17:19] = in_args[17:19]
                                    out_args[19:23] = [deps.Blank] * 4
                                elif wto_ahp_scroll:
                                    out_args[17:20] = [deps.Blank] * 3
                                    out_args[20:23] = in_args[17:20]
                                else:
                                    out_args[17:23] = [deps.Blank] * 6
                                
                                if deps.SameString(in_args[3], 'Water'):
                                    out_args[23] = in_args[20]
                                    out_args[24:26] = [deps.Blank] * 2
                                else:
                                    out_args[23] = deps.Blank
                                    out_args[24:26] = in_args[20:22]
                                cur_args = 25
                            
                            elif obj_upper == 'REFRIGERATION:SECONDARYSYSTEM':
                                no_diff = False
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                if cur_args < 18:
                                    in_args[cur_args+1:19] = [deps.Blank] * (18 - cur_args)
                                out_args[1:14] = in_args[1:14]
                                out_args[14:17] = [deps.Blank] * 3
                                if deps.SameString(in_args[14], 'Yes'):
                                    out_args[17] = '1.0'
                                else:
                                    out_args[17] = deps.Blank
                                out_args[18:20] = in_args[15:17]
                                out_args[20:22] = [deps.Blank] * 2
                                out_args[22:24] = in_args[17:19]
                                if cur_args >= 14:
                                    cur_args = 23
                            
                            elif obj_upper == 'REFRIGERATION:CASE':
                                no_diff = False
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                if cur_args < 35:
                                    in_args[cur_args:36] = [deps.Blank] * (35 - cur_args + 1)
                                out_args[1:16] = in_args[1:16]
                                out_args[16] = deps.Blank
                                out_args[17:37] = in_args[16:36]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'ZONEVENTILATION':
                                object_name = 'ZoneVentilation:DesignFlowRate'
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            
                            elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                if cur_args > 7:
                                    out_args[1:8] = in_args[1:8]
                                    out_args[8] = deps.Blank
                                    in_num = 8
                                    if cur_args >= 8:
                                        out_args[9] = in_args[8]
                                        in_num = 9
                                    if cur_args > 9:
                                        out_args[10:cur_args+1] = in_args[10:cur_args+1]
                                        in_num = cur_args
                                    cur_args = in_num
                                else:
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            
                            elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:6] = in_args[1:6]
                                out_args[6] = 'Constant'
                                out_args[7] = in_args[6]
                                cur_args = 7
                            
                            elif obj_upper == 'COOLINGTOWER:SINGLESPEED':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                if cur_args > 12:
                                    out_args[1:13] = in_args[1:13]
                                    out_args[13:16] = [deps.Blank] * 3
                                    out_args[16:cur_args+4] = in_args[13:cur_args+1]
                                    cur_args = cur_args + 3
                                else:
                                    no_diff = True
                            
                            elif obj_upper == 'COOLINGTOWER:TWOSPEED':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                if cur_args > 16:
                                    out_args[1:17] = in_args[1:17]
                                    out_args[17:20] = [deps.Blank] * 3
                                    out_args[20:cur_args+4] = in_args[17:cur_args+1]
                                    cur_args = cur_args + 3
                                else:
                                    no_diff = True
                            
                            elif obj_upper == 'COIL:COOLING:DX:SINGLESPEED':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:7] = in_args[1:7]
                                out_args[7] = deps.Blank
                                out_args[8:cur_args+2] = in_args[7:cur_args+1]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'COIL:COOLING:WATER:DETAILEDGEOMETRY':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:13] = in_args[1:13]
                                err_flag = False
                                field_a = deps.ProcessNumber(in_args[13], err_flag)
                                if err_flag:
                                    deps.ShowSevereError('Invalid Number, Coil:Cooling:Water:DetailedGeometry field 13, [' + in_args[13].strip() + '], Name=' + out_args[1].strip(), deps.Auditf)
                                    print('  ! Invalid Number, field 13 {' + fld_names[13].strip() + '} value=' + in_args[13].strip(), file=open(dif_lfn, 'a'))
                                else:
                                    if field_a < 1.0:
                                        field_a = field_a * 1000.0
                                        out_args[13] = deps.RoundSigDigits(field_a, 4)
                                    else:
                                        out_args[13] = in_args[13]
                                err_flag = False
                                field_a = deps.ProcessNumber(in_args[14], err_flag)
                                if err_flag:
                                    deps.ShowSevereError('Invalid Number, Coil:Cooling:Water:DetailedGeometry field 14, [' + in_args[14].strip() + '], Name=' + out_args[1].strip(), deps.Auditf)
                                    print('  ! Invalid Number, field 14 {' + fld_names[14].strip() + '} value=' + in_args[14].strip(), file=open(dif_lfn, 'a'))
                                else:
                                    if field_a < 1.0:
                                        field_a = field_a * 1000.0
                                        out_args[14] = deps.RoundSigDigits(field_a, 4)
                                    else:
                                        out_args[14] = in_args[14]
                                out_args[15:cur_args+1] = in_args[15:cur_args+1]
                            
                            elif obj_upper == 'SIZINGPERIOD:DESIGNDAY':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                if cur_args < 17:
                                    no_diff = True
                                else:
                                    if deps.SameString(in_args[17], 'Default Multipliers'):
                                        out_args[17] = 'DefaultMultipliers'
                            
                            elif obj_upper == 'GROUNDHEATEXCHANGER:VERTICAL':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:22] = in_args[1:22]
                                out_args[22] = deps.Blank
                                out_args[23:cur_args+2] = in_args[22:cur_args+1]
                            
                            elif obj_upper == 'ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                if cur_args > 9:
                                    if out_args[9] == deps.Blank and out_args[10] == deps.Blank:
                                        out_args[11] = deps.Blank
                                    elif in_args[11] != deps.Blank:
                                        err_flag = False
                                        field_a = deps.ProcessNumber(in_args[11], err_flag)
                                        if field_a < 0.5:
                                            out_args[11] = '.5'
                                if cur_args > 14:
                                    if out_args[14] == deps.Blank and out_args[15] == deps.Blank:
                                        out_args[16] = deps.Blank
                                    elif in_args[16] != deps.Blank:
                                        err_flag = False
                                        field_a = deps.ProcessNumber(in_args[16], err_flag)
                                        if field_a < 0.5:
                                            out_args[16] = '.5'
                            
                            elif obj_upper == 'WINDOWPROPERTY:SHADINGCONTROL':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                if deps.SameString('InteriorNonInsulatingShade', in_args[2]):
                                    out_args[2] = 'InteriorShade'
                                if deps.SameString('ExteriorNonInsulatingShade', in_args[2]):
                                    out_args[2] = 'ExteriorShade'
                                if deps.SameString('InteriorInsulatingShade', in_args[2]):
                                    out_args[2] = 'InteriorShade'
                                if deps.SameString('ExteriorInsulatingShade', in_args[2]):
                                    out_args[2] = 'ExteriorShade'
                                if deps.SameString('Schedule', in_args[4]):
                                    out_args[4] = 'OnIfScheduleAllows'
                                if deps.SameString('SolarOnWindow', in_args[4]):
                                    out_args[4] = 'OnIfHighSolarOnWindow'
                                if deps.SameString('HorizontalSolar', in_args[4]):
                                    out_args[4] = 'OnIfHighHorizontalSolar'
                                if deps.SameString('OutsideAirTemp', in_args[4]):
                                    out_args[4] = 'OnIfHighOutdoorAirTemperature'
                                if deps.SameString('ZoneAirTemp', in_args[4]):
                                    out_args[4] = 'OnIfHighZoneAirTemperature'
                                if deps.SameString('ZoneCooling', in_args[4]):
                                    out_args[4] = 'OnIfHighZoneCooling'
                                if deps.SameString('Glare', in_args[4]):
                                    out_args[4] = 'OnIfHighGlare'
                                if deps.SameString('DaylightIlluminance', in_args[4]):
                                    out_args[4] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif obj_upper == 'OUTPUT:VARIABLE':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                if out_args[1] == deps.Blank:
                                    out_args[1] = '*'
                                    no_diff = False
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(2, del_this, check_rvi, no_diff, object_name, dif_lfn, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(1, del_this, check_rvi, no_diff, object_name, dif_lfn, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                if out_args[1] == deps.Blank:
                                    out_args[1] = '*'
                                    no_diff = False
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(2, del_this, check_rvi, no_diff, object_name, dif_lfn, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(3, del_this, check_rvi, no_diff, object_name, dif_lfn, False, False, False, cur_args, written, True)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                no_diff = True
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                cur_var = 3
                                var = 3
                                while var <= cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(1, deps.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            var += 2
                                            continue
                                        if pos > 0:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg] != deps.Blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.OTMVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Output Table Monthly (new)="' + deps.NewRepVarName[arg].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.OTMVarCaution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if deps.NewRepVarCaution[arg+1] != deps.Blank:
                                                        if not deps.OTMVarCaution[arg+1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Output Table Monthly (new)="' + deps.NewRepVarName[arg+1].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+1].strip() + '".')
                                                            print(' ', file=open(dif_lfn, 'a'))
                                                            deps.OTMVarCaution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    no_diff = False
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg+2] != deps.Blank:
                                                    if not deps.OTMVarCaution[arg+2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Output Table Monthly (new)="' + deps.NewRepVarName[arg+2].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+2].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.OTMVarCaution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var - 1
                            
                            elif obj_upper == 'METER:CUSTOM':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var <= cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(1, deps.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            var += 2
                                            continue
                                        if pos > 0:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg] != deps.Blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.CMtrVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Meter (new)="' + deps.NewRepVarName[arg].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.CMtrVarCaution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if deps.NewRepVarCaution[arg+1] != deps.Blank and not deps.SameString(deps.NewRepVarCaution[arg+1][:6], 'Forkeq'):
                                                        if not deps.CMtrVarCaution[arg+1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Meter (new)="' + deps.NewRepVarName[arg+1].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+1].strip() + '".')
                                                            print(' ', file=open(dif_lfn, 'a'))
                                                            deps.CMtrVarCaution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    no_diff = False
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg+2] != deps.Blank:
                                                    if not deps.CMtrVarCaution[arg+2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Meter (new)="' + deps.NewRepVarName[arg+2].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+2].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.CMtrVarCaution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var
                                arg = cur_var
                                while arg >= 1:
                                    if out_args[arg] == deps.Blank:
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1
                            
                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var <= cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(1, deps.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        if uc_comp_rep_var_name[-1:] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            var += 2
                                            continue
                                        if pos > 0:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg] != deps.Blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.CMtrDVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Meter (new)="' + deps.NewRepVarName[arg].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.CMtrDVarCaution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg+1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if deps.NewRepVarCaution[arg+1] != deps.Blank and not deps.SameString(deps.NewRepVarCaution[arg+1][:6], 'Forkeq'):
                                                        if not deps.CMtrDVarCaution[arg+1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Decrement Meter (new)="' + deps.NewRepVarName[arg+1].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+1].strip() + '".')
                                                            print(' ', file=open(dif_lfn, 'a'))
                                                            deps.CMtrDVarCaution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    no_diff = False
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg+2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if deps.NewRepVarCaution[arg+2] != deps.Blank:
                                                    if not deps.CMtrDVarCaution[arg+2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning', 'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() + '" conversion to Custom Meter (new)="' + deps.NewRepVarName[arg+2].strip() + '" has the following caution "' + deps.NewRepVarCaution[arg+2].strip() + '".')
                                                        print(' ', file=open(dif_lfn, 'a'))
                                                        deps.CMtrDVarCaution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var
                                arg = cur_var
                                while arg >= 1:
                                    if out_args[arg] == deps.Blank:
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1
                            
                            else:
                                if deps.FindItemInList(object_name, deps.NotInNew, len(deps.NotInNew)) != 0:
                                    print('Object="' + object_name.rstrip() + '" is not in the "new" IDD.', file=open(deps.Auditf, 'a'))
                                    print('... will be listed as comments on the new output file.', file=open(deps.Auditf, 'a'))
                                    deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    no_diff = True
                        else:
                            nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(deps.IDFRecords[num]['Name'])
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                        
                        if diff_min_fields and no_diff:
                            nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = False
                            for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if deps.IDFRecords[deps.NumIDFRecords]['CommtE'] != deps.CurComment:
                        for xcount in range(deps.IDFRecords[deps.NumIDFRecords]['CommtE'] + 1, deps.CurComment + 1):
                            print(deps.Comments[xcount].rstrip(), file=open(dif_lfn, 'a'))
                            if xcount == deps.IDFRecords[num]['CommtE']:
                                print(' ', file=open(dif_lfn, 'a'))
                    
                    if deps.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = deps.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        out_args[1] = 'Regular'
                        cur_args = 1
                        deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    os.close(dif_lfn)
                    if check_rvi:
                        deps.ProcessRviMviFiles(deps.FileNamePath, 'rvi')
                        deps.ProcessRviMviFiles(deps.FileNamePath, 'mvi')
                    deps.CloseOut()
                else:
                    deps.ProcessRviMviFiles(deps.FileNamePath, 'rvi')
                    deps.ProcessRviMviFiles(deps.FileNamePath, 'mvi')
            else:
                end_of_file = True
            
            created_output_name = ''
            deps.CreateNewName('Reallocate', created_output_name, ' ')
        
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
        deps.copyfile(deps.FileNamePath + '.' + arg_idf_extension, deps.FileNamePath + '.' + arg_idf_extension + 'old', err_flag)
        deps.copyfile(deps.FileNamePath + '.' + arg_idf_extension + 'new', deps.FileNamePath + '.' + arg_idf_extension, err_flag)
        file_exist = os.path.isfile(deps.FileNamePath + '.rvi')
        if file_exist:
            deps.copyfile(deps.FileNamePath + '.rvi', deps.FileNamePath + '.rviold', err_flag)
        file_exist = os.path.isfile(deps.FileNamePath + '.rvinew')
        if file_exist:
            deps.copyfile(deps.FileNamePath + '.rvinew', deps.FileNamePath + '.rvi', err_flag)
        file_exist = os.path.isfile(deps.FileNamePath + '.mvi')
        if file_exist:
            deps.copyfile(deps.FileNamePath + '.mvi', deps.FileNamePath + '.mviold', err_flag)
        file_exist = os.path.isfile(deps.FileNamePath + '.mvinew')
        if file_exist:
            deps.copyfile(deps.FileNamePath + '.mvinew', deps.FileNamePath + '.mvi', err_flag)
    
    return end_of_file
