from dataclasses import dataclass, field
from typing import List, Optional, Protocol, Tuple
import os
import sys

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.Blank: string constant for blank values
# - DataVCompareGlobals: global state (VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf, ProcessingIMFFile, MakingPretty, CurComment, FileOK, NumRepVarNames, OldRepVarName, NewRepVarName)
# - InputProcessor: functions/state (ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, NumIDFRecords, IDFRecords, Comments, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, FatalError, CloseOut)
# - VCompareGlobalRoutines: functions (FindNumber)
# - General: functions (ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError, GetNewUnitNumber, TrimTrailZeros, FindItemInList, MakeUPPERCase, MakeLowerCase, ProcessNumber, samestring, DisplayString, WriteOutIDFLinesAsComments, WriteOutIDFLines, CheckSpecialObjects, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CreateNewName, copyfile)
# - DataGlobals: error display functions

@dataclass
class IDFRecord:
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[str] = field(default_factory=list)
    CommtS: int = 0
    CommtE: int = 0

@dataclass
class ObjectDefEntry:
    Name: str

@dataclass
class ExternalState:
    VerString: str = ""
    VersionNum: float = 0.0
    IDDFileNameWithPath: str = ""
    NewIDDFileNameWithPath: str = ""
    RepVarFileNameWithPath: str = ""
    ProgramPath: str = ""
    FullFileName: str = ""
    FileNamePath: str = ""
    Auditf: int = 0
    ProcessingIMFFile: bool = False
    MakingPretty: bool = False
    CurComment: int = 0
    FileOK: bool = False
    NumRepVarNames: int = 0
    OldRepVarName: List[str] = field(default_factory=list)
    NewRepVarName: List[str] = field(default_factory=list)
    NumIDFRecords: int = 0
    IDFRecords: List[IDFRecord] = field(default_factory=list)
    Comments: List[str] = field(default_factory=list)
    MaxAlphaArgsFound: int = 0
    MaxNumericArgsFound: int = 0
    MaxTotalArgs: int = 0
    FatalError: bool = False
    ObjectDef: List[ObjectDefEntry] = field(default_factory=list)
    NumObjectDefs: int = 0
    NotInNew: List[str] = field(default_factory=list)

class ExternalFunctions(Protocol):
    def ProcessInput(self, idd_file: str, new_idd_file: str, idf_file: str) -> None: ...
    def GetNewObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def GetObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def FindNumber(self, arg: str) -> int: ...
    def CloseOut(self) -> None: ...
    def GetNewUnitNumber(self) -> int: ...
    def TrimTrailZeros(self, val: str) -> str: ...
    def FindItemInList(self, item: str, list_items: List[str], list_size: int) -> int: ...
    def MakeUPPERCase(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def ProcessNumber(self, s: str) -> Tuple[float, bool]: ...
    def samestring(self, a: str, b: str) -> bool: ...
    def DisplayString(self, msg: str) -> None: ...
    def ShowWarningError(self, msg: str, file_unit: int) -> None: ...
    def WriteOutIDFLinesAsComments(self, file_unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def WriteOutIDFLines(self, file_unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def CheckSpecialObjects(self, file_unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> Tuple[bool]: ...
    def ScanOutputVariablesForReplacement(self, var_index: int, del_this: bool, check_rvi: bool, no_diff: bool, obj_name: str, file_unit: int, out_var: bool, mtr_var: bool, time_bin_var: bool, cur_args: int, written: bool) -> Tuple[bool, bool, bool, int, bool]: ...
    def ProcessRviMviFiles(self, file_path: str, ext: str) -> None: ...
    def CreateNewName(self, action: str, name: str, ext: str) -> None: ...
    def copyfile(self, src: str, dst: str) -> bool: ...

def set_this_version_variables(state: ExternalState, ext_funcs: ExternalFunctions) -> None:
    state.VerString = 'Conversion 1.3 => 1.4'
    state.VersionNum = 1.0
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-3-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-4-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 1-3-0-018 to 1-4-0.csv'

def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: ExternalState,
    ext_funcs: ExternalFunctions
) -> bool:
    
    BLANK = ""
    fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    err_flag = False
    
    max_total_args = state.MaxTotalArgs
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        with open(f"unit_{in_lfn}", 'r') as f:
                            full_file_name = f.readline().strip()
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = BLANK
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = BLANK
                    ios = 1
            
            if full_file_name and full_file_name[0] == '!':
                full_file_name = BLANK
                continue
            
            units_arg = BLANK
            if ios != 0:
                full_file_name = BLANK
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != BLANK:
                ext_funcs.DisplayString('Processing IDF -- ' + full_file_name)
                with open(f"unit_{state.Auditf}", 'a') as f:
                    f.write(' Processing IDF -- ' + full_file_name + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = ext_funcs.MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    with open(f"unit_{state.Auditf}", 'a') as f:
                        f.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                state.FileNamePath = file_name_path
                
                dif_lfn = ext_funcs.GetNewUnitNumber()
                file_ok = os.path.exists(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    with open(f"unit_{state.Auditf}", 'a') as f:
                        f.write('File not found=' + full_file_name + '\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    
                    if diff_only:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        ext_funcs.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    ext_funcs.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [BLANK] * (state.MaxAlphaArgsFound + 1)
                    numbers = [BLANK] * (state.MaxNumericArgsFound + 1)
                    in_args = [BLANK] * (max_total_args + 1)
                    a_or_n = [False] * (max_total_args + 1)
                    req_fld = [False] * (max_total_args + 1)
                    fld_names = [BLANK] * (max_total_args + 1)
                    fld_defaults = [BLANK] * (max_total_args + 1)
                    fld_units = [BLANK] * (max_total_args + 1)
                    nw_a_or_n = [False] * (max_total_args + 1)
                    nw_req_fld = [False] * (max_total_args + 1)
                    nw_fld_names = [BLANK] * (max_total_args + 1)
                    nw_fld_defaults = [BLANK] * (max_total_args + 1)
                    nw_fld_units = [BLANK] * (max_total_args + 1)
                    out_args = [BLANK] * (max_total_args + 1)
                    match_arg = [BLANK] * (max_total_args + 1)
                    delete_this_record = [False] * (state.NumIDFRecords + 1)
                    
                    comis_sim = False
                    ads_sim = False
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if ext_funcs.MakeUPPERCase(state.IDFRecords[num-1].Name) == 'COMIS SIMULATION':
                            comis_sim = True
                        if ext_funcs.MakeUPPERCase(state.IDFRecords[num-1].Name) == 'ADS SIMULATION':
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        print('File contains both COMIS and ADS Simulation objects=' + full_file_name)
                        print('Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.')
                        with open(f"unit_{state.Auditf}", 'a') as f:
                            f.write(' ..File contains both COMIS and ADS Simulation objects=' + full_file_name + '\n')
                            f.write(' ..Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.\n')
                        exit_because_bad_file = True
                        break
                    
                    no_version = True
                    for num in range(1, state.NumIDFRecords + 1):
                        if ext_funcs.MakeUPPERCase(state.IDFRecords[num-1].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    with open(dif_file_name, 'w') as dif_file:
                        for num in range(1, state.NumIDFRecords + 1):
                            for xcount in range(state.IDFRecords[num-1].CommtS, state.IDFRecords[num-1].CommtE + 1):
                                if xcount < len(state.Comments):
                                    dif_file.write(state.Comments[xcount].rstrip() + '\n')
                                    if xcount == state.IDFRecords[num-1].CommtE:
                                        dif_file.write(' \n')
                            
                            if no_version and num == 1:
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD('VERSION')
                                out_args[1] = '1.4'
                                cur_args = 1
                                ext_funcs.WriteOutIDFLinesAsComments(dif_lfn, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = state.IDFRecords[num-1].Name
                            
                            if ext_funcs.MakeUPPERCase(object_name.rstrip()) == 'SKY RADIANCE DISTRIBUTION':
                                continue
                            if ext_funcs.MakeUPPERCase(object_name.rstrip()) == 'AIRFLOW MODEL':
                                continue
                            if ext_funcs.MakeUPPERCase(object_name.rstrip()) == 'GENERATOR:FC:BATTERY DATA':
                                continue
                            if ext_funcs.MakeUPPERCase(object_name.rstrip()) == 'WATER HEATER:SIMPLE':
                                dif_file.write('\n')
                                continue
                            
                            if ext_funcs.FindItemInList(object_name, [od.Name for od in state.ObjectDef], state.NumObjectDefs) != 0:
                                num_args, a_or_n, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = ext_funcs.GetObjectDefInIDD(object_name)
                                num_alphas = state.IDFRecords[num-1].NumAlphas
                                num_numbers = state.IDFRecords[num-1].NumNumbers
                                alphas[1:num_alphas+1] = state.IDFRecords[num-1].Alphas[1:num_alphas+1]
                                numbers[1:num_numbers+1] = state.IDFRecords[num-1].Numbers[1:num_numbers+1]
                                cur_args = num_alphas + num_numbers
                                in_args = [BLANK] * (max_total_args + 1)
                                out_args = [BLANK] * (max_total_args + 1)
                                na = 0
                                nn = 0
                                for arg in range(1, cur_args + 1):
                                    if a_or_n[arg]:
                                        na += 1
                                        in_args[arg] = alphas[na]
                                    else:
                                        nn += 1
                                        in_args[arg] = numbers[nn]
                            else:
                                with open(f"unit_{state.Auditf}", 'a') as f:
                                    f.write('Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.\n')
                                    f.write('... will be listed as comments (no field names) on the new output file.\n')
                                    f.write('... Alpha fields will be listed first, then numerics.\n')
                                num_alphas = state.IDFRecords[num-1].NumAlphas
                                num_numbers = state.IDFRecords[num-1].NumNumbers
                                alphas[1:num_alphas+1] = state.IDFRecords[num-1].Alphas[1:num_alphas+1]
                                numbers[1:num_numbers+1] = state.IDFRecords[num-1].Numbers[1:num_numbers+1]
                                for arg in range(1, num_alphas + 1):
                                    out_args[arg] = alphas[arg]
                                nn = num_alphas + 1
                                for arg in range(1, num_numbers + 1):
                                    out_args[nn] = numbers[arg]
                                    nn += 1
                                cur_args = num_alphas + num_numbers
                                nw_fld_names = [BLANK] * (max_total_args + 1)
                                nw_fld_units = [BLANK] * (max_total_args + 1)
                                ext_funcs.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue
                            
                            no_diff = True
                            diff_min_fields = False
                            written = False
                            
                            if ext_funcs.FindItemInList(ext_funcs.MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                if obj_min_flds != nw_obj_min_flds:
                                    diff_min_fields = True
                                else:
                                    diff_min_fields = False
                            
                            if not state.MakingPretty:
                                obj_upper = ext_funcs.MakeUPPERCase(object_name.rstrip())
                                
                                if obj_upper == 'VERSION':
                                    if in_args[1][0:3] == '1.4' and arg_file:
                                        ext_funcs.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                        latest_version = True
                                        break
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1] = '1.4'
                                    no_diff = False
                                
                                elif obj_upper == 'COOLING TOWER:VARIABLE SPEED':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:18] = in_args[1:18]
                                    out_args[20] = in_args[18]
                                    out_args[23] = in_args[19]
                                    out_args[18] = 'Saturated Exit'
                                    out_args[19] = ' '
                                    out_args[21] = 'Scheduled Rate'
                                    out_args[22] = ' '
                                    cur_args = 23
                                    no_diff = False
                                
                                elif obj_upper == 'CHILLER:ELECTRIC:EIR':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:20] = in_args[1:20]
                                    for arg in range(21, cur_args + 1):
                                        out_args[arg - 1] = in_args[arg]
                                    cur_args -= 1
                                    no_diff = False
                                
                                elif obj_upper == 'WATER HEATER:MIXED':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:20] = in_args[1:20]
                                    if ext_funcs.MakeUPPERCase(in_args[20]) == 'EXTERIOR':
                                        out_args[20] = 'Outside Air Node'
                                    else:
                                        out_args[20] = in_args[20]
                                    out_args[21:23] = in_args[21:23]
                                    if ext_funcs.MakeUPPERCase(in_args[20]) == 'EXTERIOR':
                                        out_args[23] = in_args[1].rstrip() + ' OA Node'
                                    else:
                                        out_args[23] = ' '
                                    for arg in range(23, cur_args + 1):
                                        out_args[arg + 1] = in_args[arg]
                                    cur_args += 1
                                    no_diff = False
                                    ext_funcs.WriteOutIDFLines(dif_lfn, 'WATER HEATER:MIXED', cur_args, out_args, nw_fld_names, nw_fld_units)
                                    
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD('OUTSIDE AIR NODE')
                                    out_args[1] = in_args[1].rstrip() + ' OA Node'
                                    cur_args = 1
                                    ext_funcs.WriteOutIDFLines(dif_lfn, 'OUTSIDE AIR NODE', cur_args, out_args, nw_fld_names, nw_fld_units)
                                    written = True
                                
                                elif obj_upper == 'SET POINT MANAGER:OUTSIDE AIR PRETREAT':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:5] = in_args[1:5]
                                    val, pn_err_flag = ext_funcs.ProcessNumber(in_args[5])
                                    if val == 0.0:
                                        no_diff = False
                                        out_args[5] = '0.00001'
                                    else:
                                        out_args[5] = in_args[5]
                                    val, pn_err_flag = ext_funcs.ProcessNumber(in_args[6])
                                    if val == 0.0:
                                        no_diff = False
                                        out_args[6] = '0.00001'
                                    else:
                                        out_args[6] = in_args[6]
                                    out_args[7:cur_args+1] = in_args[7:cur_args+1]
                                
                                elif obj_upper == 'BUILDING':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    if cur_args == 8:
                                        no_diff = False
                                        if ext_funcs.MakeUPPERCase(out_args[8]) == 'YES':
                                            out_args[6] = out_args[6].rstrip() + 'WithReflections'
                                            out_args[8] = BLANK
                                            cur_args = 7
                                        elif ext_funcs.MakeUPPERCase(out_args[8]) == 'NO':
                                            out_args[8] = BLANK
                                            cur_args = 7
                                
                                elif obj_upper == 'WINDOWSHADINGCONTROL':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    no_diff = False
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    if ext_funcs.samestring('InteriorNonInsulatingShade', in_args[2]):
                                        out_args[2] = 'InteriorShade'
                                    if ext_funcs.samestring('ExteriorNonInsulatingShade', in_args[2]):
                                        out_args[2] = 'ExteriorShade'
                                    if ext_funcs.samestring('InteriorInsulatingShade', in_args[2]):
                                        out_args[2] = 'InteriorShade'
                                    if ext_funcs.samestring('ExteriorInsulatingShade', in_args[2]):
                                        out_args[2] = 'ExteriorShade'
                                    if ext_funcs.samestring('Schedule', in_args[4]):
                                        out_args[4] = 'OnIfScheduleAllows'
                                    if ext_funcs.samestring('SolarOnWindow', in_args[4]):
                                        out_args[4] = 'OnIfHighSolarOnWindow'
                                    if ext_funcs.samestring('HorizontalSolar', in_args[4]):
                                        out_args[4] = 'OnIfHighHorizontalSolar'
                                    if ext_funcs.samestring('OutsideAirTemp', in_args[4]):
                                        out_args[4] = 'OnIfHighOutsideAirTemp'
                                    if ext_funcs.samestring('ZoneAirTemp', in_args[4]):
                                        out_args[4] = 'OnIfHighZoneAirTemp'
                                    if ext_funcs.samestring('ZoneCooling', in_args[4]):
                                        out_args[4] = 'OnIfHighZoneCooling'
                                    if ext_funcs.samestring('Glare', in_args[4]):
                                        out_args[4] = 'OnIfHighGlare'
                                    if ext_funcs.samestring('DaylightIlluminance', in_args[4]):
                                        out_args[4] = 'MeetDaylightIlluminanceSetpoint'
                                
                                elif obj_upper == 'REPORT VARIABLE':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    no_diff = True
                                    if out_args[1] == BLANK:
                                        out_args[1] = '*'
                                        no_diff = False
                                    del_this, check_rvi, no_diff, cur_args, written = ext_funcs.ScanOutputVariablesForReplacement(
                                        2, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                        True, False, False, cur_args, written)
                                    if del_this:
                                        continue
                                
                                elif obj_upper in ['REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY']:
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    no_diff = True
                                    del_this, check_rvi, no_diff, cur_args, written = ext_funcs.ScanOutputVariablesForReplacement(
                                        1, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                        False, True, False, cur_args, written)
                                    if del_this:
                                        continue
                                
                                elif obj_upper == 'REPORT:TABLE:TIMEBINS':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    no_diff = True
                                    if out_args[1] == BLANK:
                                        out_args[1] = '*'
                                        no_diff = False
                                    del_this, check_rvi, no_diff, cur_args, written = ext_funcs.ScanOutputVariablesForReplacement(
                                        2, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                        False, False, True, cur_args, written)
                                    if del_this:
                                        continue
                                
                                elif obj_upper == 'REPORT:TABLE:MONTHLY':
                                    nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                    out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                    no_diff = True
                                    if out_args[1] == BLANK:
                                        out_args[1] = '*'
                                        no_diff = False
                                    cur_var = 3
                                    var = 3
                                    while var <= cur_args:
                                        uc_rep_var_name = ext_funcs.MakeUPPERCase(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                        pos = uc_rep_var_name.find('[')
                                        if pos > 0:
                                            uc_rep_var_name = uc_rep_var_name[0:pos]
                                            out_args[cur_var] = in_args[var][0:pos]
                                            out_args[cur_var + 1] = in_args[var + 1]
                                        del_this = False
                                        for arg in range(1, state.NumRepVarNames + 1):
                                            uc_comp_rep_var_name = ext_funcs.MakeUPPERCase(state.OldRepVarName[arg - 1])
                                            if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            else:
                                                wild_match = False
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                            if pos > 0 and pos != 0:
                                                var += 2
                                                continue
                                            if pos >= 0:
                                                if state.NewRepVarName[arg - 1] != '<DELETE>':
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg - 1]
                                                    else:
                                                        out_args[cur_var] = state.NewRepVarName[arg - 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                else:
                                                    del_this = True
                                                if arg < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg - 1]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg]
                                                    else:
                                                        out_args[cur_var] = state.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg + 1] == state.OldRepVarName[arg - 1]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = state.NewRepVarName[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                break
                                        if not del_this:
                                            cur_var += 2
                                        var += 2
                                    cur_args = cur_var - 1
                                
                                else:
                                    if ext_funcs.FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                        with open(f"unit_{state.Auditf}", 'a') as f:
                                            f.write('Object="' + object_name.rstrip() + '" is not in the "new" IDD.\n')
                                            f.write('... will be listed as comments on the new output file.\n')
                                        ext_funcs.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                        written = True
                                    else:
                                        nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                        out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                        no_diff = True
                            else:
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(state.IDFRecords[num-1].Name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            
                            if diff_min_fields and no_diff:
                                nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = ext_funcs.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = False
                                for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = max(nw_obj_min_flds, cur_args)
                            
                            if no_diff and diff_only:
                                continue
                            
                            if not written:
                                check_special_written = ext_funcs.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                if isinstance(check_special_written, tuple):
                                    written = check_special_written[0]
                            
                            if not written:
                                ext_funcs.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                            for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE + 1, state.CurComment + 1):
                                if xcount < len(state.Comments):
                                    dif_file.write(state.Comments[xcount].rstrip() + '\n')
                                    if xcount == state.IDFRecords[state.NumIDFRecords - 1].CommtE:
                                        dif_file.write(' \n')
                    
                    ext_funcs.CloseOut()
                    if check_rvi:
                        ext_funcs.ProcessRviMviFiles(file_name_path, 'rvi')
                        ext_funcs.ProcessRviMviFiles(file_name_path, 'mvi')
                else:
                    ext_funcs.ProcessRviMviFiles(file_name_path, 'rvi')
                    ext_funcs.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            ext_funcs.CreateNewName('Reallocate', BLANK, ' ')
        
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
        ext_funcs.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old')
        ext_funcs.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension)
        if os.path.exists(file_name_path + '.rvi'):
            ext_funcs.copyfile(file_name_path + '.rvi', file_name_path + '.rviold')
        if os.path.exists(file_name_path + '.rvinew'):
            ext_funcs.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi')
        if os.path.exists(file_name_path + '.mvi'):
            ext_funcs.copyfile(file_name_path + '.mvi', file_name_path + '.mviold')
        if os.path.exists(file_name_path + '.mvinew'):
            ext_funcs.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi')
    
    return end_of_file
