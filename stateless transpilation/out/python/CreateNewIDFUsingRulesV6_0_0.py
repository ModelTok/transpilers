from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Dict, Any
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ProgNameConversion (str)
# - DataVCompareGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath,
#   RepVarFileNameWithPath, IDFRecords, Comments, NumIDFRecords, CurComment, ProcessingIMFFile,
#   FatalError, NotInNew, MakingPretty, OldRepVarName, NewRepVarName, NewRepVarCaution,
#   NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution
# - InputProcessor: ProcessInput()
# - VCompareGlobalRoutines: GetNewObjectDefInIDD(), GetObjectDefInIDD(), ScanOutputVariablesForReplacement(),
#   WriteOutIDFLinesAsComments(), WriteOutIDFLines(), CheckSpecialObjects(), CloseOut(),
#   ProcessRviMviFiles(), CreateNewName(), GetNumSectionsFound()
# - DataStringGlobals: ProgNameConversion
# - General: TrimTrailZeros(), MakeLowerCase(), MakeUPPERCase(), FindItemInList(), SameString()
# - DataGlobals: ShowMessage(), ShowContinueError(), ShowFatalError(), ShowSevereError(),
#   ShowWarningError(), copyfile()
# - External: GetNewUnitNumber(), FindNumber()
# - Auditf: file unit for audit output

@dataclass
class IDFRecord:
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str]
    Numbers: List[str]
    CommtS: int
    CommtE: int

@dataclass
class ObjectDefType:
    Name: List[str]

class ExternalDeps(Protocol):
    ProgNameConversion: str
    VerString: str
    VersionNum: float
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    IDFRecords: List[IDFRecord]
    Comments: List[str]
    NumIDFRecords: int
    CurComment: int
    ProcessingIMFFile: bool
    FatalError: bool
    NotInNew: List[str]
    MakingPretty: bool
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    NumRepVarNames: int
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    ObjectDef: ObjectDefType
    Auditf: int
    ProgramPath: str
    
    def ProcessInput(self, idd_old: str, idd_new: str, idf_file: str) -> None: ...
    def GetNewObjectDefInIDD(self, obj_name: str, nw_num_args: List[int], nw_aorn: List[bool],
                             nw_req_fld: List[bool], nw_obj_min_flds: List[int], 
                             nw_fld_names: List[str], nw_fld_defaults: List[str],
                             nw_fld_units: List[str]) -> None: ...
    def GetObjectDefInIDD(self, obj_name: str, num_args: List[int], aorn: List[bool],
                          req_fld: List[bool], obj_min_flds: List[int], fld_names: List[str],
                          fld_defaults: List[str], fld_units: List[str]) -> None: ...
    def ScanOutputVariablesForReplacement(self, field_num: int, del_this: List[bool],
                                          check_rvi: List[bool], nodiff: List[bool],
                                          obj_name: str, diff_lfn: int, out_var: bool,
                                          mtr_var: bool, time_bin_var: bool, cur_args: int,
                                          written: List[bool], sensor: bool) -> None: ...
    def WriteOutIDFLinesAsComments(self, diff_lfn: int, obj_name: str, cur_args: int,
                                   out_args: List[str], fld_names: List[str],
                                   fld_units: List[str]) -> None: ...
    def WriteOutIDFLines(self, diff_lfn: int, obj_name: str, cur_args: int,
                         out_args: List[str], fld_names: List[str],
                         fld_units: List[str]) -> None: ...
    def CheckSpecialObjects(self, diff_lfn: int, obj_name: str, cur_args: int,
                            out_args: List[str], fld_names: List[str],
                            fld_units: List[str], written: List[bool]) -> None: ...
    def CloseOut(self) -> None: ...
    def ProcessRviMviFiles(self, file_name_path: str, extension: str) -> None: ...
    def CreateNewName(self, action: str, created_output_name: List[str], placeholder: str) -> None: ...
    def GetNumSectionsFound(self, section_name: str) -> int: ...
    def TrimTrailZeros(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def MakeUPPERCase(self, s: str) -> str: ...
    def FindItemInList(self, item: str, item_list: List[str], num_items: int) -> int: ...
    def SameString(self, s1: str, s2: str) -> bool: ...
    def GetNewUnitNumber(self) -> int: ...
    def FindNumber(self, s: str) -> int: ...
    def DisplayString(self, msg: str) -> None: ...
    def ShowWarningError(self, msg: str, audit_unit: int) -> None: ...
    def writePreprocessorObject(self, diff_lfn: int, prog_name: str, level: str, msg: str) -> None: ...
    def copyfile(self, src: str, dest: str, err_flag: List[bool]) -> None: ...

blank = ''
max_name_length = 100
max_alpha_args_found = 0
max_numeric_args_found = 0
max_total_args = 0

_set_version_first_time = True

def set_this_version_variables(deps: ExternalDeps) -> None:
    deps.VerString = 'Conversion 5.0 => 6.0'
    deps.VersionNum = 6.0
    deps.IDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V5-0-0-Energy+.idd'
    deps.NewIDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V6-0-0-Energy+.idd'
    deps.RepVarFileNameWithPath = deps.ProgramPath.rstrip() + 'Report Variables 5-0-0-031 to 6-0-0.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDeps
) -> None:
    global _set_version_first_time
    
    fmta = '(A)'
    
    if _set_version_first_time:
        _set_version_first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    alphas: List[str] = []
    numbers: List[str] = []
    in_args: List[str] = []
    aorn: List[bool] = []
    req_fld: List[bool] = []
    fld_names: List[str] = []
    fld_defaults: List[str] = []
    fld_units: List[str] = []
    nw_aorn: List[bool] = []
    nw_req_fld: List[bool] = []
    nw_fld_names: List[str] = []
    nw_fld_defaults: List[str] = []
    nw_fld_units: List[str] = []
    out_args: List[str] = []
    match_arg: List[int] = []
    delete_this_record: List[bool] = []
    
    full_file_name = ''
    file_name_path = ''
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        ios = 1
                        full_file_name = ''
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
                deps.DisplayString('Processing IDF -- ' + full_file_name)
                with open(deps.Auditf, 'a') as f:
                    f.write(' Processing IDF -- ' + full_file_name + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = deps.MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    with open(deps.Auditf, 'a') as f:
                        f.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = deps.GetNewUnitNumber()
                
                try:
                    with open(full_file_name, 'r'):
                        file_ok = True
                except FileNotFoundError:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    with open(deps.Auditf, 'a') as f:
                        f.write('File not found=' + full_file_name + '\n')
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
                    
                    if local_file_extension == 'imf':
                        deps.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.Auditf)
                        deps.ProcessingIMFFile = True
                    else:
                        deps.ProcessingIMFFile = False
                    
                    deps.ProcessInput(deps.IDDFileNameWithPath, deps.NewIDDFileNameWithPath, full_file_name)
                    
                    if deps.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [blank] * (max_alpha_args_found + 1)
                    numbers = [blank] * (max_numeric_args_found + 1)
                    in_args = [blank] * (max_total_args + 1)
                    aorn = [False] * (max_total_args + 1)
                    req_fld = [False] * (max_total_args + 1)
                    fld_names = [blank] * (max_total_args + 1)
                    fld_defaults = [blank] * (max_total_args + 1)
                    fld_units = [blank] * (max_total_args + 1)
                    nw_aorn = [False] * (max_total_args + 1)
                    nw_req_fld = [False] * (max_total_args + 1)
                    nw_fld_names = [blank] * (max_total_args + 1)
                    nw_fld_defaults = [blank] * (max_total_args + 1)
                    nw_fld_units = [blank] * (max_total_args + 1)
                    out_args = [blank] * (max_total_args + 1)
                    match_arg = [0] * (max_total_args + 1)
                    delete_this_record = [False] * (deps.NumIDFRecords + 1)
                    
                    no_version = True
                    for num in range(0, deps.NumIDFRecords):
                        if deps.MakeUPPERCase(deps.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    dif_file = open(dif_file_name, 'w')
                    
                    for num in range(0, deps.NumIDFRecords):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + deps.IDFRecords[num].Name + ':' + deps.IDFRecords[num].Alphas[0] + '\n')
                    
                    for num in range(0, deps.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(deps.IDFRecords[num].CommtS, deps.IDFRecords[num].CommtE + 1):
                            dif_file.write(deps.Comments[xcount] + '\n')
                            if xcount == deps.IDFRecords[num].CommtE:
                                dif_file.write(' \n')
                        
                        if no_version and num == 0:
                            nw_num_args = [0]
                            deps.GetNewObjectDefInIDD('VERSION', nw_num_args, nw_aorn, nw_req_fld, 
                                                     [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '3.2'
                            cur_args = 1
                            deps.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        obj_upper = deps.MakeUPPERCase(deps.IDFRecords[num].Name.strip())
                        
                        if obj_upper == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if obj_upper == 'AIRFLOW MODEL':
                            continue
                        if obj_upper == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if obj_upper == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if obj_upper == 'WATER HEATER:SIMPLE':
                            dif_file.write('! The WATER HEATER:SIMPLE object has been deleted\n')
                            dif_file.write('Output:PreprocessorMessage,Transition,' + deps.ProgNameConversion + ',The WATER HEATER:SIMPLE object has been deleted;\n')
                            continue
                        
                        object_name = deps.IDFRecords[num].Name
                        
                        if deps.FindItemInList(object_name, deps.ObjectDef.Name, len(deps.ObjectDef.Name)) != 0:
                            num_args = [0]
                            deps.GetObjectDefInIDD(object_name, num_args, aorn, req_fld, [0], fld_names, fld_defaults, fld_units)
                            
                            num_alphas = deps.IDFRecords[num].NumAlphas
                            num_numbers = deps.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                alphas[i] = deps.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = deps.IDFRecords[num].Numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = [blank] * (cur_args + 1)
                            out_args = [blank] * (cur_args + 1)
                            
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = numbers[nn]
                                    nn += 1
                        else:
                            with open(deps.Auditf, 'a') as f:
                                f.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                                f.write('... will be listed as comments (no field names) on the new output file.\n')
                                f.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = deps.IDFRecords[num].NumAlphas
                            num_numbers = deps.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                alphas[i] = deps.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = deps.IDFRecords[num].Numbers[i]
                            
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = numbers[arg]
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [blank] * (cur_args + 1)
                            nw_fld_units = [blank] * (cur_args + 1)
                            deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.FindItemInList(deps.MakeUPPERCase(object_name), deps.NotInNew, len(deps.NotInNew)) == 0:
                            nw_num_args = [0]
                            nw_obj_min_flds = [0]
                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            obj_min_flds = [0]
                            if len(aorn) > 0:
                                obj_min_flds[0] = len(aorn)
                            
                            if obj_min_flds[0] != nw_obj_min_flds[0]:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not deps.MakingPretty:
                            obj_case = deps.MakeUPPERCase(deps.IDFRecords[num].Name.strip())
                            
                            if obj_case == 'VERSION':
                                if in_args[0][:3] == '6.0' and arg_file:
                                    deps.ShowWarningError('File is already at latest version.  No new diff file made.', deps.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '6.0'
                                no_diff = False
                            
                            elif obj_case == 'COIL:COOLING:DX:MULTISPEED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(12):
                                    out_args[i] = in_args[i]
                                for i in range(13, 16):
                                    out_args[i] = blank
                                for i in range(16, 16 + (cur_args - 12)):
                                    out_args[i] = in_args[i - 3]
                                cur_args = cur_args + 3
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(8):
                                    out_args[i] = in_args[i]
                                for i in range(8, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(10):
                                    out_args[i] = in_args[i]
                                for i in range(10, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARYHEATONLY':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(8):
                                    out_args[i] = in_args[i]
                                for i in range(8, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARYHEATCOOL':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(10):
                                    out_args[i] = in_args[i]
                                for i in range(10, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(8):
                                    out_args[i] = in_args[i]
                                for i in range(8, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                for i in range(6, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR:MULTISPEED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                for i in range(5, cur_args - 1):
                                    out_args[i] = in_args[i + 1]
                                cur_args = cur_args - 1
                            
                            elif obj_case == 'COOLINGTOWER:SINGLESPEED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(24):
                                    out_args[i] = in_args[i]
                                if cur_args <= 9:
                                    out_args[9] = 'UFactorTimesAreaAndDesignWaterFlowRate'
                                if cur_args >= 25:
                                    for i in range(25, 29):
                                        out_args[i] = blank
                                    for i in range(29, cur_args + 4):
                                        out_args[i] = in_args[i - 4]
                                    cur_args = cur_args + 4
                            
                            elif obj_case == 'COOLINGTOWER:TWOSPEED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(27):
                                    out_args[i] = in_args[i]
                                if cur_args <= 12:
                                    out_args[12] = 'UFactorTimesAreaAndDesignWaterFlowRate'
                                if cur_args >= 28:
                                    for i in range(28, 32):
                                        out_args[i] = blank
                                    for i in range(32, cur_args + 4):
                                        out_args[i] = in_args[i - 4]
                                    cur_args = cur_args + 4
                            
                            elif obj_case == 'COOLINGTOWER:VARIABLESPEED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(25):
                                    out_args[i] = in_args[i]
                                if cur_args >= 26:
                                    for i in range(26, 30):
                                        out_args[i] = blank
                                    for i in range(30, cur_args + 4):
                                        out_args[i] = in_args[i - 4]
                                    cur_args = cur_args + 4
                            
                            elif obj_case == 'ZONEAIRHEATBALANCEALGORITHM':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                if out_args[0][0] == '3':
                                    out_args[0] = 'ThirdOrderBackwardDifference'
                            
                            elif obj_case == 'REFRIGERATION:CONDENSER:AIRCOOLED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                out_args[5] = blank
                                for i in range(6, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'REFRIGERATION:CONDENSER:EVAPORATIVECOOLED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                out_args[5] = blank
                                for i in range(6, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'COIL:WATERHEATING:DESUPERHEATER':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if deps.SameString(in_args[13], 'Refrigeration:Condenser'):
                                    out_args[13] = 'Refrigeration:Condenser:AirCooled'
                            
                            elif obj_case == 'COIL:HEATING:DESUPERHEATER':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if deps.SameString(in_args[5], 'Refrigeration:Condenser'):
                                    out_args[5] = 'Refrigeration:Condenser:AirCooled'
                            
                            elif obj_case == 'ZONEHVAC:FOURPIPEFANCOIL':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                out_args[2] = 'ConstantFanVariableFlow'
                                out_args[3] = in_args[2]
                                out_args[4] = blank
                                out_args[5] = blank
                                out_args[6] = in_args[3]
                                out_args[7] = blank
                                for i in range(8, 12):
                                    out_args[i] = in_args[i - 3]
                                for i in range(12, cur_args + 2):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 2
                            
                            elif obj_case == 'PEOPLE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args >= 11:
                                    out_args[10] = blank
                                    for i in range(11, cur_args + 1):
                                        out_args[i] = in_args[i - 1]
                                    cur_args = cur_args + 1
                            
                            elif obj_case == 'GASEQUIPMENT':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args >= 11:
                                    out_args[10] = blank
                                    for i in range(11, cur_args + 1):
                                        out_args[i] = in_args[i - 1]
                                    cur_args = cur_args + 1
                            
                            elif obj_case == 'PLANTEQUIPMENTOPERATION:OUTDOORDRYBULBDIFFERENCE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                c_out_args = 2
                                arg = 2
                                while arg < cur_args:
                                    if deps.SameString(in_args[arg + 2], 'ON'):
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 1]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 3]
                                    arg += 4
                                cur_args = c_out_args
                            
                            elif obj_case == 'PLANTEQUIPMENTOPERATION:OUTDOORWETBULBDIFFERENCE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                c_out_args = 2
                                arg = 2
                                while arg < cur_args:
                                    if deps.SameString(in_args[arg + 2], 'ON'):
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 1]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 3]
                                    arg += 4
                                cur_args = c_out_args
                            
                            elif obj_case == 'PLANTEQUIPMENTOPERATION:OUTDOORDEWPOINTDIFFERENCE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                c_out_args = 2
                                arg = 2
                                while arg < cur_args:
                                    if deps.SameString(in_args[arg + 2], 'ON'):
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 1]
                                        c_out_args += 1
                                        out_args[c_out_args] = in_args[arg + 3]
                                    arg += 4
                                cur_args = c_out_args
                            
                            elif obj_case == 'COIL:HEATING:WATER':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                            
                            elif obj_case == 'SIZING:ZONE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(10):
                                    out_args[i] = in_args[i]
                                out_args[10] = in_args[9]
                                for i in range(11, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'SIZING:PARAMETERS':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[0]
                                if cur_args > 1:
                                    out_args[2] = in_args[1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'FAN:VARIABLEVOLUME':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                if deps.SameString(in_args[5], 'autosize'):
                                    out_args[5] = 'Fraction'
                                    out_args[6] = '0.25'
                                    out_args[7] = blank
                                else:
                                    out_args[5] = 'FixedFlowRate'
                                    out_args[6] = blank
                                    out_args[7] = in_args[5]
                                for i in range(8, cur_args + 2):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 2
                            
                            elif obj_case in ('SURFACEPROPERTY:CONVECTIONCOEFFICIENTS', 'SURFACEPROPERTY:CONVECTIONCOEFFICIENTS:MULTIPLESURFACE'):
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                if deps.SameString(out_args[2], 'Detailed'):
                                    out_args[2] = 'TARP'
                                elif deps.SameString(out_args[2], 'BLAST'):
                                    out_args[2] = 'TARP'
                                elif deps.SameString(out_args[1], 'Outside') and deps.SameString(out_args[2], 'Simple'):
                                    out_args[2] = 'SimpleCombined'
                                
                                out_args[3] = in_args[3]
                                out_args[4] = in_args[4]
                                out_args[5] = blank
                                
                                if cur_args > 5:
                                    out_args[6] = in_args[5]
                                    out_args[7] = in_args[6]
                                    if deps.SameString(out_args[7], 'Detailed'):
                                        out_args[7] = 'TARP'
                                    elif deps.SameString(out_args[7], 'BLAST'):
                                        out_args[7] = 'TARP'
                                    elif deps.SameString(out_args[6], 'Outside') and deps.SameString(out_args[7], 'Simple'):
                                        out_args[7] = 'SimpleCombined'
                                    
                                    out_args[8] = in_args[7]
                                    out_args[9] = blank
                                    cur_args = cur_args + 1
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'ZONE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args >= 10:
                                    if deps.SameString(out_args[9], 'Detailed'):
                                        out_args[9] = 'TARP'
                                if cur_args >= 11:
                                    if deps.SameString(out_args[10], 'Detailed'):
                                        out_args[10] = 'TARP'
                                    elif deps.SameString(out_args[10], 'BLAST'):
                                        out_args[10] = 'TARP'
                                    elif deps.SameString(out_args[10], 'Simple'):
                                        out_args[10] = 'SimpleCombined'
                            
                            elif obj_case == 'SURFACECONVECTIONALGORITHM:INSIDE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if deps.SameString(out_args[0], 'Detailed'):
                                    out_args[0] = 'TARP'
                            
                            elif obj_case == 'SURFACECONVECTIONALGORITHM:OUTSIDE':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if deps.SameString(out_args[0], 'Detailed'):
                                    out_args[0] = 'TARP'
                                elif deps.SameString(out_args[0], 'BLAST'):
                                    out_args[0] = 'TARP'
                                elif deps.SameString(out_args[0], 'Simple'):
                                    out_args[0] = 'SimpleCombined'
                            
                            elif obj_case == 'COMPONENTCOST:LINEITEM':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args > 13:
                                    for arg in range(13, cur_args):
                                        if in_args[arg] != blank:
                                            dif_file.write('Output:PreprocessorMessage,' + deps.ProgNameConversion.strip() + ',warning,Non-used Fields in the ComponentCost:LineItem have been deleted;\n')
                                            break
                                cur_args = min(13, cur_args)
                            
                            elif obj_case == 'ZONECAPACITANCEMULTIPLIER':
                                no_diff = False
                                object_name = 'ZoneCapacitanceMultiplier:ResearchSpecial'
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[0]
                                out_args[2] = in_args[0]
                                cur_args = 3
                            
                            elif obj_case == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args >= 19:
                                    out_args[18] = blank
                                    out_args[19] = in_args[18]
                                    cur_args = 20
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:FANCOIL':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(4):
                                    out_args[i] = in_args[i]
                                out_args[4] = in_args[3]
                                for i in range(5, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:PTAC':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                out_args[6] = in_args[5]
                                for i in range(7, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:PTHP':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                out_args[6] = in_args[5]
                                for i in range(7, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:UNITARY':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                out_args[5] = in_args[4]
                                for i in range(6, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:VAV:FANPOWERED':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                out_args[5] = in_args[4]
                                for i in range(6, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:WATERTOAIRHEATPUMP':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                out_args[6] = in_args[5]
                                for i in range(7, cur_args + 1):
                                    out_args[i] = in_args[i - 1]
                                cur_args = cur_args + 1
                            
                            elif obj_case == 'HVACTEMPLATE:ZONE:VAV':
                                no_diff = False
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(5):
                                    out_args[i] = in_args[i]
                                out_args[5] = in_args[4]
                                out_args[6] = 'Constant'
                                out_args[7] = in_args[5]
                                out_args[8] = blank
                                out_args[9] = blank
                                for i in range(10, 17):
                                    out_args[i] = in_args[i - 3]
                                for i in range(17, 21):
                                    out_args[i] = blank
                                for i in range(21, 26):
                                    out_args[i] = in_args[i - 7]
                                cur_args = 25
                            
                            elif obj_case == 'CONSTRUCTION:USEHBALGORITHMCONDFDDETAILED':
                                no_diff = False
                                object_name = 'ConstructionProperty:UseHBAlgorithmCondFDDetailed'
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                            
                            elif obj_case == 'WINDOWPROPERTY:SHADINGCONTROL':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                
                                if deps.SameString('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if deps.SameString('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if deps.SameString('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if deps.SameString('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                
                                if deps.SameString('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if deps.SameString('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if deps.SameString('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if deps.SameString('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutdoorAirTemperature'
                                if deps.SameString('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemperature'
                                if deps.SameString('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if deps.SameString('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if deps.SameString('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif obj_case == 'OUTPUT:VARIABLE':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = [False]
                                written_list = [False]
                                deps.ScanOutputVariablesForReplacement(1, del_this, [check_rvi], [no_diff], object_name, dif_lfn, True, False, False, cur_args, written_list, False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_case in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                del_this = [False]
                                written_list = [False]
                                deps.ScanOutputVariablesForReplacement(0, del_this, [check_rvi], [no_diff], object_name, dif_lfn, False, True, False, cur_args, written_list, False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_case == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = [False]
                                written_list = [False]
                                deps.ScanOutputVariablesForReplacement(1, del_this, [check_rvi], [no_diff], object_name, dif_lfn, False, False, True, cur_args, written_list, False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_case == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                del_this = [False]
                                written_list = [False]
                                deps.ScanOutputVariablesForReplacement(2, del_this, [check_rvi], [no_diff], object_name, dif_lfn, False, False, False, cur_args, written_list, True)
                                if del_this[0]:
                                    continue
                            
                            elif obj_case == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = True
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                
                                cur_var = 3
                                var = 2
                                while var < cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(deps.NumRepVarNames):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_idx = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos_idx = 0 if uc_rep_var_name == uc_comp_rep_var_name else -1
                                        
                                        if pos_idx > 0 and pos_idx != 1:
                                            continue
                                        if pos_idx > -1:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg] != blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.OTMVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Output Table Monthly (new)="' +
                                                           deps.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.OTMVarCaution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if deps.NewRepVarCaution[arg + 1] != blank:
                                                        if not deps.OTMVarCaution[arg + 1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                               'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() +
                                                               '" conversion to Output Table Monthly (new)="' +
                                                               deps.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                               deps.NewRepVarCaution[arg + 1].strip() + '".')
                                                            dif_file.write(' \n')
                                                            deps.OTMVarCaution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.NumRepVarNames and deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg + 2] != blank:
                                                    if not deps.OTMVarCaution[arg + 2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Output Table Monthly (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Output Table Monthly (new)="' +
                                                           deps.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg + 2].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.OTMVarCaution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_case == 'METER:CUSTOM':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                cur_var = 4
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(deps.NumRepVarNames):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_idx = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos_idx = 0 if uc_rep_var_name == uc_comp_rep_var_name else -1
                                        
                                        if pos_idx > 0 and pos_idx != 1:
                                            continue
                                        if pos_idx > -1:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg] != blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.CMtrVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           deps.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.CMtrVarCaution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if deps.NewRepVarCaution[arg + 1] != blank and not deps.SameString(deps.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not deps.CMtrVarCaution[arg + 1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                               'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                               '" conversion to Custom Meter (new)="' +
                                                               deps.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                               deps.NewRepVarCaution[arg + 1].strip() + '".')
                                                            dif_file.write(' \n')
                                                            deps.CMtrVarCaution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.NumRepVarNames and deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg + 2] != blank:
                                                    if not deps.CMtrVarCaution[arg + 2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Custom Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           deps.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg + 2].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.CMtrVarCaution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var
                                arg = cur_var - 1
                                while arg >= 0:
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1
                            
                            elif obj_case == 'METER:CUSTOMDECREMENT':
                                nw_num_args = [0]
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                cur_var = 4
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = deps.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(deps.NumRepVarNames):
                                        uc_comp_rep_var_name = deps.MakeUPPERCase(deps.OldRepVarName[arg])
                                        
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_idx = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos_idx = 0 if uc_rep_var_name == uc_comp_rep_var_name else -1
                                        
                                        if pos_idx > 0 and pos_idx != 1:
                                            continue
                                        if pos_idx > -1:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg] != blank and not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not deps.CMtrDVarCaution[arg]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           deps.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.CMtrDVarCaution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 1]:
                                                if not deps.SameString(deps.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.NewRepVarName[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    
                                                    if deps.NewRepVarCaution[arg + 1] != blank and not deps.SameString(deps.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not deps.CMtrDVarCaution[arg + 1]:
                                                            deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                               'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                               '" conversion to Custom Decrement Meter (new)="' +
                                                               deps.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                               deps.NewRepVarCaution[arg + 1].strip() + '".')
                                                            dif_file.write(' \n')
                                                            deps.CMtrDVarCaution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.NumRepVarNames and deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if deps.NewRepVarCaution[arg + 2] != blank:
                                                    if not deps.CMtrDVarCaution[arg + 2]:
                                                        deps.writePreprocessorObject(dif_lfn, deps.ProgNameConversion, 'Warning',
                                                           'Custom Decrement Meter (old)="' + deps.OldRepVarName[arg].strip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           deps.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                           deps.NewRepVarCaution[arg + 2].strip() + '".')
                                                        dif_file.write(' \n')
                                                        deps.CMtrDVarCaution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var
                                arg = cur_var - 1
                                while arg >= 0:
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1
                            
                            else:
                                if deps.FindItemInList(object_name, deps.NotInNew, len(deps.NotInNew)) != 0:
                                    with open(deps.Auditf, 'a') as f:
                                        f.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                        f.write('... will be listed as comments on the new output file.\n')
                                    deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args = [0]
                                    deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    no_diff = True
                        else:
                            nw_num_args = [0]
                            deps.GetNewObjectDefInIDD(deps.IDFRecords[num].Name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if diff_min_fields and no_diff:
                            nw_num_args = [0]
                            nw_obj_min_flds = [0]
                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                            no_diff = False
                            for arg in range(cur_args, nw_obj_min_flds[0]):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds[0], cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, [written])
                        
                        if not written:
                            deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if deps.IDFRecords[deps.NumIDFRecords - 1].CommtE != deps.CurComment:
                        for xcount in range(deps.IDFRecords[deps.NumIDFRecords - 1].CommtE + 1, deps.CurComment + 1):
                            dif_file.write(deps.Comments[xcount] + '\n')
                            if xcount == deps.IDFRecords[deps.NumIDFRecords - 1].CommtE:
                                dif_file.write(' \n')
                    
                    if deps.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args = [0]
                        deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, [0], nw_fld_names, nw_fld_defaults, nw_fld_units)
                        no_diff = False
                        out_args[0] = 'Regular'
                        cur_args = 1
                        deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    dif_file.close()
                    
                    if check_rvi:
                        deps.ProcessRviMviFiles(file_name_path, 'rvi')
                        deps.ProcessRviMviFiles(file_name_path, 'mvi')
                    
                    deps.CloseOut()
                else:
                    deps.ProcessRviMviFiles(file_name_path, 'rvi')
                    deps.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file[0] = True
            
            deps.CreateNewName('Reallocate', [''], ' ')
        
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
        err_flag = [False]
        deps.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        deps.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag)
        
        try:
            with open(file_name_path + '.rvi', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            deps.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        try:
            with open(file_name_path + '.rvinew', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            deps.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        try:
            with open(file_name_path + '.mvi', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            deps.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        try:
            with open(file_name_path + '.mvinew', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            deps.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
