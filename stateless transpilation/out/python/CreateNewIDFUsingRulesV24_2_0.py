# EXTERNAL DEPS (to wire in glue):
# - InputProcessor (module): GetNewUnitNumber, GetObjectItem, GetNumObjectsFound, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound
# - DataVCompareGlobals (module): NumIDFRecords, IDFRecords, NotInNew, ObjectDef, NumObjectDefs, FatalError, ProcessingIMFFile, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, Comments, CurComment, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, FileOK, Auditf, ProgramPath, blank, MaxNameLength, MakingPretty, IDFRecords, VerString, VersionNum, sVersionNum, sVersionNumFourChars
# - VCompareGlobalRoutines (module): DisplayString, ProcessInput, FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CloseOut, CreateNewName, copyfile, writePreprocessorObject, TrimTrailZeros, SameString, ProcessNumber, MakeUPPERCase, MakeLowerCase
# - DataStringGlobals (module): ProgNameConversion
# - General (module): utility functions
# - DataGlobals (module): ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

from typing import List, Dict, Tuple, Optional, Protocol
from dataclasses import dataclass, field
from enum import Enum
import sys

class IDFRecord:
    def __init__(self):
        self.Name = ""
        self.NumAlphas = 0
        self.NumNumbers = 0
        self.Alphas: List[str] = []
        self.Numbers: List[float] = []
        self.CommtS = 0
        self.CommtE = 0

@dataclass
class FanVOTransitionInfo:
    oldFanName: str = ""
    availSchedule: str = ""
    fanTotalEff_str: str = ""
    pressureRise_str: str = ""
    maxAirFlow_str: str = ""
    minFlowInputMethod: str = ""
    minAirFlowFrac_str: str = ""
    fanPowerMinAirFlow_str: str = ""
    motorEfficiency: str = ""
    motorInAirStreamFrac: str = ""
    coeff1: str = ""
    coeff2: str = ""
    coeff3: str = ""
    coeff4: str = ""
    coeff5: str = ""
    inletAirNodeName: str = ""
    outletAirNodeName: str = ""
    endUseSubCat: str = ""

class ExternalDeps(Protocol):
    def GetNewUnitNumber(self) -> int: ...
    def GetObjectItem(self, obj_type: str, obj_num: int, alphas: List[str], num_alphas: int, numbers: List[float], num_numbers: int, status: int) -> None: ...
    def GetNumObjectsFound(self, obj_type: str) -> int: ...
    def GetObjectDefInIDD(self, name: str, num_args: int, aorn: List[bool], req_fld: List[bool], obj_min_flds: int, fld_names: List[str], fld_defaults: List[str], fld_units: List[str]) -> None: ...
    def GetNewObjectDefInIDD(self, name: str, nw_num_args: int, nw_aorn: List[bool], nw_req_fld: List[bool], nw_obj_min_flds: int, nw_fld_names: List[str], nw_fld_defaults: List[str], nw_fld_units: List[str]) -> None: ...
    def GetNumSectionsFound(self, section: str) -> int: ...
    def ProcessInput(self, idd_old: str, idd_new: str, idf_file: str) -> None: ...
    def DisplayString(self, msg: str) -> None: ...
    def FindItemInList(self, item: str, list_items: List[str], count: int) -> int: ...
    def WriteOutIDFLines(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def WriteOutIDFLinesAsComments(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def CheckSpecialObjects(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str], written: bool) -> bool: ...
    def ScanOutputVariablesForReplacement(self, field_num: int, del_this: bool, check_rvi: bool, nodiff: bool, obj_name: str, unit: int, out_var: bool, mtr_var: bool, time_bin_var: bool, cur_args: int, written: bool, is_meter: bool) -> None: ...
    def ProcessRviMviFiles(self, file_path: str, ext: str) -> None: ...
    def CloseOut(self) -> None: ...
    def CreateNewName(self, action: str, name_out: str, suffix: str) -> None: ...
    def copyfile(self, src: str, dst: str, err_flag: bool) -> None: ...
    def writePreprocessorObject(self, unit: int, prog_name: str, msg_type: str, msg: str) -> None: ...
    def MakeUPPERCase(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def SameString(self, s1: str, s2: str) -> bool: ...
    def ProcessNumber(self, s: str, err_flag: bool) -> float: ...
    def ShowFatalError(self, msg: str, unit: int) -> None: ...
    def ShowWarningError(self, msg: str, unit: int) -> None: ...
    def ShowSevereError(self, msg: str, unit: int) -> None: ...
    def TrimTrailZeros(self, s: str) -> str: ...
    def ADJUSTL(self, s: str) -> str: ...

def set_this_version_variables(deps: ExternalDeps, globals_state) -> None:
    globals_state.VerString = 'Conversion 24.1 => 24.2'
    globals_state.VersionNum = 24.2
    globals_state.sVersionNum = '***'
    globals_state.sVersionNumFourChars = '24.2'
    globals_state.IDDFileNameWithPath = globals_state.ProgramPath.rstrip('/') + '/V24-1-0-Energy+.idd'
    globals_state.NewIDDFileNameWithPath = globals_state.ProgramPath.rstrip('/') + '/V24-2-0-Energy+.idd'
    globals_state.RepVarFileNameWithPath = globals_state.ProgramPath.rstrip('/') + '/Report Variables 24-1-0 to 24-2-0.csv'

def create_new_idf_using_rules(
    deps: ExternalDeps,
    globals_state,
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> bool:
    
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
                print('-->', end='', flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                deps.DisplayString('Processing IDF -- ' + full_file_name)
                deps.show_message_to_audit(' Processing IDF -- ' + full_file_name, globals_state.Auditf)
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    deps.show_message_to_audit(' ..assuming file extension of .idf', globals_state.Auditf)
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = deps.GetNewUnitNumber()
                import os
                file_ok = os.path.exists(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    deps.show_message_to_audit('File not found=' + full_file_name, globals_state.Auditf)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = file_name_path + '.' + local_file_extension + 'new'
                    
                    dif_file = open(dif_file_name, 'w')
                    
                    if local_file_extension == 'imf':
                        deps.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', globals_state.Auditf)
                        globals_state.ProcessingIMFFile = True
                    else:
                        globals_state.ProcessingIMFFile = False
                    
                    deps.ProcessInput(globals_state.IDDFileNameWithPath, globals_state.NewIDDFileNameWithPath, full_file_name)
                    
                    if globals_state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    globals_state.DeleteThisRecord = [False] * globals_state.NumIDFRecords
                    
                    no_version = True
                    for num in range(globals_state.NumIDFRecords):
                        if deps.MakeUPPERCase(globals_state.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(globals_state.NumIDFRecords):
                        if globals_state.DeleteThisRecord[num]:
                            dif_file.write('! Deleting: ' + globals_state.IDFRecords[num].Name + '="' + globals_state.IDFRecords[num].Alphas[0] + '".\n')
                    
                    spm_types = [
                        "SETPOINTMANAGER:SCHEDULED",
                        "SETPOINTMANAGER:SCHEDULED:DUALSETPOINT",
                        "SETPOINTMANAGER:OUTDOORAIRRESET",
                        "SETPOINTMANAGER:SINGLEZONE:REHEAT",
                        "SETPOINTMANAGER:SINGLEZONE:HEATING",
                        "SETPOINTMANAGER:SINGLEZONE:COOLING",
                        "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MINIMUM",
                        "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MAXIMUM",
                        "SETPOINTMANAGER:MIXEDAIR",
                        "SETPOINTMANAGER:OUTDOORAIRPRETREAT",
                        "SETPOINTMANAGER:WARMEST",
                        "SETPOINTMANAGER:COLDEST",
                        "SETPOINTMANAGER:RETURNAIRBYPASSFLOW",
                        "SETPOINTMANAGER:WARMESTTEMPERATUREFLOW",
                        "SETPOINTMANAGER:MULTIZONE:HEATING:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:COOLING:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:MINIMUMHUMIDITY:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:MAXIMUMHUMIDITY:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MINIMUM",
                        "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MAXIMUM",
                        "SETPOINTMANAGER:FOLLOWOUTDOORAIRTEMPERATURE",
                        "SETPOINTMANAGER:FOLLOWSYSTEMNODETEMPERATURE",
                        "SETPOINTMANAGER:FOLLOWGROUNDTEMPERATURE",
                        "SETPOINTMANAGER:CONDENSERENTERINGRESET",
                        "SETPOINTMANAGER:CONDENSERENTERINGRESET:IDEAL",
                        "SETPOINTMANAGER:SINGLEZONE:ONESTAGECOOLING",
                        "SETPOINTMANAGER:SINGLEZONE:ONESTAGEHEATING",
                        "SETPOINTMANAGER:RETURNTEMPERATURE:CHILLEDWATER",
                        "SETPOINTMANAGER:RETURNTEMPERATURE:HOTWATER"
                    ]
                    
                    tot_spms = 0
                    for spm_type in spm_types:
                        tot_spms += deps.GetNumObjectsFound(spm_type)
                    
                    print("Found ", tot_spms, " SPMs")
                    
                    spm_names = [""] * tot_spms
                    spm_index = 0
                    
                    for spm_type in spm_types:
                        for spm_num in range(1, deps.GetNumObjectsFound(spm_type) + 1):
                            alphas = [""] * 100
                            numbers = [0.0] * 100
                            num_alphas = 0
                            num_numbers = 0
                            status = 0
                            
                            deps.GetObjectItem(spm_type, spm_num, alphas, num_alphas, numbers, num_numbers, status)
                            
                            if deps.FindItemInList(alphas[0].strip(), spm_names, spm_index) != 0:
                                deps.ShowFatalError('SetpointManager Unicity of Names: SPM of type ' + spm_type + ' has a name already found=' + alphas[0], globals_state.Auditf)
                            
                            spm_index += 1
                            spm_names[spm_index - 1] = alphas[0]
                    
                    num_vrftu = deps.GetNumObjectsFound('ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW')
                    vav_fan_name_to_delete = [""] * num_vrftu
                    vrftu_i = 0
                    
                    for num in range(globals_state.NumIDFRecords):
                        rec_name = deps.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                        if rec_name == 'ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW':
                            if deps.SameString(globals_state.IDFRecords[num].Alphas[6], 'FAN:VARIABLEVOLUME'):
                                vav_fan_name_to_delete[vrftu_i] = globals_state.IDFRecords[num].Alphas[7]
                            else:
                                vav_fan_name_to_delete[vrftu_i] = ''
                            vrftu_i += 1
                    
                    num_fan_variable_volume = deps.GetNumObjectsFound('FAN:VARIABLEVOLUME')
                    old_fan_vo = [FanVOTransitionInfo() for _ in range(num_fan_variable_volume)]
                    num_old_fan_vo = 0
                    
                    for num in range(globals_state.NumIDFRecords):
                        rec_name = deps.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                        if rec_name == 'FAN:VARIABLEVOLUME':
                            record = globals_state.IDFRecords[num]
                            old_fan_vo[num_old_fan_vo].oldFanName = record.Alphas[0]
                            old_fan_vo[num_old_fan_vo].availSchedule = record.Alphas[1]
                            old_fan_vo[num_old_fan_vo].fanTotalEff_str = str(record.Numbers[0])
                            old_fan_vo[num_old_fan_vo].pressureRise_str = str(record.Numbers[1])
                            old_fan_vo[num_old_fan_vo].maxAirFlow_str = str(record.Numbers[2])
                            old_fan_vo[num_old_fan_vo].minFlowInputMethod = record.Alphas[2]
                            old_fan_vo[num_old_fan_vo].minAirFlowFrac_str = str(record.Numbers[3])
                            old_fan_vo[num_old_fan_vo].fanPowerMinAirFlow_str = str(record.Numbers[4])
                            old_fan_vo[num_old_fan_vo].motorEfficiency = str(record.Numbers[5])
                            old_fan_vo[num_old_fan_vo].motorInAirStreamFrac = str(record.Numbers[6])
                            old_fan_vo[num_old_fan_vo].coeff1 = str(record.Numbers[7])
                            old_fan_vo[num_old_fan_vo].coeff2 = str(record.Numbers[8])
                            old_fan_vo[num_old_fan_vo].coeff3 = str(record.Numbers[9])
                            old_fan_vo[num_old_fan_vo].coeff4 = str(record.Numbers[10])
                            old_fan_vo[num_old_fan_vo].coeff5 = str(record.Numbers[11])
                            old_fan_vo[num_old_fan_vo].inletAirNodeName = record.Alphas[3]
                            old_fan_vo[num_old_fan_vo].outletAirNodeName = record.Alphas[4]
                            if len(record.Alphas) == 6:
                                old_fan_vo[num_old_fan_vo].endUseSubCat = record.Alphas[5]
                            else:
                                old_fan_vo[num_old_fan_vo].endUseSubCat = ''
                            
                            if deps.FindItemInList(record.Alphas[0], vav_fan_name_to_delete, num_vrftu) != 0:
                                globals_state.DeleteThisRecord[num] = True
                            
                            num_old_fan_vo += 1
                    
                    deps.DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(globals_state.NumIDFRecords):
                        if globals_state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(globals_state.IDFRecords[num].CommtS, globals_state.IDFRecords[num].CommtE + 1):
                            dif_file.write(globals_state.Comments[xcount] + '\n')
                            if xcount == globals_state.IDFRecords[num].CommtE:
                                dif_file.write('\n')
                        
                        if no_version and num == 0:
                            nw_num_args = 0
                            nw_aorn = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            deps.GetNewObjectDefInIDD('VERSION', nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            out_args = [""] * 1000
                            out_args[0] = globals_state.sVersionNumFourChars
                            cur_args = 1
                            
                            deps.ShowWarningError('No version found in file, defaulting to ' + globals_state.sVersionNumFourChars, globals_state.Auditf)
                            deps.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = globals_state.IDFRecords[num].Name
                        
                        if deps.FindItemInList(object_name, [d.Name for d in globals_state.ObjectDef], globals_state.NumObjectDefs) != 0:
                            num_args = 0
                            aorn = []
                            req_fld = []
                            obj_min_flds = 0
                            fld_names = []
                            fld_defaults = []
                            fld_units = []
                            
                            deps.GetObjectDefInIDD(object_name, num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units)
                            
                            num_alphas = globals_state.IDFRecords[num].NumAlphas
                            num_numbers = globals_state.IDFRecords[num].NumNumbers
                            
                            in_args = [""] * 1000
                            out_args = [""] * 1000
                            
                            for i in range(num_alphas):
                                in_args[i] = globals_state.IDFRecords[num].Alphas[i]
                            
                            for i in range(num_numbers):
                                in_args[num_alphas + i] = str(globals_state.IDFRecords[num].Numbers[i])
                            
                            cur_args = num_alphas + num_numbers
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    in_args[arg] = globals_state.IDFRecords[num].Alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(globals_state.IDFRecords[num].Numbers[nn])
                                    nn += 1
                        else:
                            deps.show_message_to_audit('Object="' + object_name + '" does not seem to be on the "old" IDD.', globals_state.Auditf)
                            num_alphas = globals_state.IDFRecords[num].NumAlphas
                            num_numbers = globals_state.IDFRecords[num].NumNumbers
                            out_args = [""] * 1000
                            
                            for i in range(num_alphas):
                                out_args[i] = globals_state.IDFRecords[num].Alphas[i]
                            
                            nn = num_alphas
                            for i in range(num_numbers):
                                out_args[nn] = str(globals_state.IDFRecords[num].Numbers[i])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * 1000
                            nw_fld_units = [""] * 1000
                            
                            deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.FindItemInList(deps.MakeUPPERCase(object_name), globals_state.NotInNew, len(globals_state.NotInNew)) == 0:
                            nw_num_args = 0
                            nw_aorn = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            
                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not globals_state.MakingPretty:
                            rec_name_upper = deps.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                            
                            if rec_name_upper == 'VERSION':
                                if in_args[0][:4] == globals_state.sVersionNumFourChars and arg_file:
                                    deps.ShowWarningError('File is already at latest version.  No new diff file made.', globals_state.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                
                                out_args[0] = globals_state.sVersionNumFourChars
                                no_diff = False
                            
                            elif rec_name_upper == 'HEATPUMP:PLANTLOOP:EIR:COOLING':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                no_diff = False
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                out_args[6] = ''
                                out_args[7] = ''
                                for i in range(3):
                                    out_args[8 + i] = in_args[6 + i]
                                out_args[11] = ''
                                for i in range(cur_args - 9):
                                    out_args[12 + i] = in_args[9 + i]
                                cur_args = cur_args + 3
                            
                            elif rec_name_upper == 'HEATPUMP:PLANTLOOP:EIR:HEATING':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                no_diff = False
                                for i in range(6):
                                    out_args[i] = in_args[i]
                                out_args[6] = ''
                                out_args[7] = ''
                                for i in range(3):
                                    out_args[8 + i] = in_args[6 + i]
                                out_args[11] = ''
                                for i in range(cur_args - 9):
                                    out_args[12 + i] = in_args[9 + i]
                                cur_args = cur_args + 3
                            
                            elif rec_name_upper == 'OUTPUTCONTROL:FILES':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                no_diff = False
                                for i in range(8):
                                    out_args[i] = in_args[i]
                                out_args[8] = in_args[8]
                                for i in range(cur_args - 8):
                                    out_args[9 + i] = in_args[8 + i]
                                cur_args = cur_args + 1
                            
                            elif rec_name_upper == 'ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW':
                                is_variable_volume = False
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(13):
                                    out_args[i] = in_args[i]
                                
                                if deps.SameString(in_args[13], 'FAN:VARIABLEVOLUME'):
                                    no_diff = False
                                    is_variable_volume = True
                                    out_args[13] = 'Fan:SystemModel'
                                    out_args[14] = in_args[14]
                                    sys_fan_name = in_args[14].strip()
                                else:
                                    out_args[13] = in_args[13]
                                    out_args[14] = in_args[14]
                                
                                for i in range(cur_args - 15):
                                    out_args[15 + i] = in_args[15 + i]
                                
                                if is_variable_volume:
                                    deps.WriteOutIDFLines(dif_lfn, 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow', cur_args, out_args, nw_fld_names, nw_fld_units)
                                    
                                    object_name = 'Fan:SystemModel'
                                    for num3 in range(num_fan_variable_volume):
                                        if deps.SameString(old_fan_vo[num3].oldFanName, sys_fan_name):
                                            nw_num_args = 0
                                            nw_aorn = []
                                            nw_req_fld = []
                                            nw_obj_min_flds = 0
                                            nw_fld_names = []
                                            nw_fld_defaults = []
                                            nw_fld_units = []
                                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                            
                                            out_args[0] = sys_fan_name
                                            out_args[1] = old_fan_vo[num3].availSchedule
                                            out_args[2] = old_fan_vo[num3].inletAirNodeName
                                            out_args[3] = old_fan_vo[num3].outletAirNodeName
                                            out_args[4] = old_fan_vo[num3].maxAirFlow_str
                                            out_args[5] = 'Continuous'
                                            
                                            if deps.SameString(old_fan_vo[num3].minFlowInputMethod, "FixedFlowRate"):
                                                if not deps.SameString(old_fan_vo[num3].maxAirFlow_str, "AUTOSIZE"):
                                                    err_flag = False
                                                    fan_power_min_air_flow = deps.ProcessNumber(old_fan_vo[num3].fanPowerMinAirFlow_str, err_flag)
                                                    if err_flag:
                                                        deps.ShowSevereError('Invalid Number, FAN:VARIABLEVOLUME field 8, Fan Power Minimum Air Flow Rate, Name=' + out_args[0], globals_state.Auditf)
                                                    
                                                    err_flag = False
                                                    max_air_flow = deps.ProcessNumber(old_fan_vo[num3].maxAirFlow_str, err_flag)
                                                    if err_flag:
                                                        deps.ShowSevereError('Invalid Number, FAN:VARIABLEVOLUME field 5, Maximum Flow Rate, Name=' + out_args[0], globals_state.Auditf)
                                                    
                                                    out_args[6] = f"{fan_power_min_air_flow / max_air_flow:.5f}"
                                                else:
                                                    err_flag = False
                                                    fan_power_min_air_flow = deps.ProcessNumber(old_fan_vo[num3].fanPowerMinAirFlow_str, err_flag)
                                                    if err_flag:
                                                        deps.ShowSevereError('Invalid Number, FAN:VARIABLEVOLUME field 8, Fan Power Minimum Air Flow Rate, Name=' + out_args[0], globals_state.Auditf)
                                                    
                                                    if fan_power_min_air_flow != 0:
                                                        deps.writePreprocessorObject(dif_lfn, globals_state.ProgNameConversion, 'Warning',
                                                            'Cannot calculate Electric Power Minimum Flow Rate Fraction for Fan:SystemModel=' + sys_fan_name +
                                                            ' when old Fan:VariableVolume Maximum Flow Rate is autosize and Fan Power Minimum Air Flow Rate is non-zero. ' +
                                                            'Electric Power Minimum Flow Rate Fraction is set to zero. ' +
                                                            'Manually size the Maximum Flow Rate if Electric Power Minimum Flow Rate Fraction should not be zero.')
                                                        deps.ShowWarningError('Cannot calculate Electric Power Minimum Flow Rate Fraction for Fan:SystemModel=' + sys_fan_name +
                                                            ' when old Fan:VariableVolume Maximum Flow Rate is autosize and Fan Power Minimum Air Flow Rate is non-zero. ' +
                                                            'Electric Power Minimum Flow Rate Fraction is set to zero. ' +
                                                            'Manually size the Maximum Flow Rate if Electric Power Minimum Flow Rate Fraction should not be zero.', globals_state.Auditf)
                                                    
                                                    out_args[6] = '0.0'
                                            else:
                                                out_args[6] = old_fan_vo[num3].minAirFlowFrac_str
                                            
                                            out_args[7] = old_fan_vo[num3].pressureRise_str
                                            out_args[8] = old_fan_vo[num3].motorEfficiency
                                            out_args[9] = old_fan_vo[num3].motorInAirStreamFrac
                                            out_args[10] = 'autosize'
                                            out_args[11] = 'TotalEfficiencyAndPressure'
                                            out_args[12] = ''
                                            out_args[13] = ''
                                            out_args[14] = old_fan_vo[num3].fanTotalEff_str
                                            out_args[15] = sys_fan_name + '_curve'
                                            out_args[16] = ''
                                            out_args[17] = ''
                                            out_args[18] = ''
                                            out_args[19] = ''
                                            out_args[20] = old_fan_vo[num3].endUseSubCat
                                            cur_args = 21
                                            
                                            deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                            
                                            object_name = 'Curve:Quartic'
                                            nw_num_args = 0
                                            nw_aorn = []
                                            nw_req_fld = []
                                            nw_obj_min_flds = 0
                                            nw_fld_names = []
                                            nw_fld_defaults = []
                                            nw_fld_units = []
                                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                            
                                            out_args[0] = sys_fan_name + '_curve'
                                            out_args[1] = old_fan_vo[num3].coeff1
                                            out_args[2] = old_fan_vo[num3].coeff2
                                            out_args[3] = old_fan_vo[num3].coeff3
                                            out_args[4] = old_fan_vo[num3].coeff4
                                            out_args[5] = old_fan_vo[num3].coeff5
                                            out_args[6] = '0.0'
                                            out_args[7] = '1.0'
                                            out_args[8] = '0.0'
                                            out_args[9] = '5.0'
                                            out_args[10] = 'Dimensionless'
                                            out_args[11] = 'Dimensionless'
                                            cur_args = 12
                                            
                                            deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                            break
                            
                            elif rec_name_upper == 'OUTPUT:VARIABLE':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                
                                if out_args[0] == "":
                                    out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(
                                    2, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                    True, False, False, cur_args, written, False)
                                
                                if del_this:
                                    continue
                            
                            elif rec_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(
                                    1, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                    False, True, False, cur_args, written, False)
                                
                                if del_this:
                                    continue
                            
                            elif rec_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                
                                if out_args[0] == "":
                                    out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(
                                    2, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                    False, False, True, cur_args, written, False)
                                
                                if del_this:
                                    continue
                            
                            elif rec_name_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                
                                if out_args[0] == "":
                                    out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(
                                    2, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                    False, False, False, cur_args, written, False)
                                
                                if del_this:
                                    continue
                            
                            elif rec_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args = 0
                                nw_aorn = []
                                nw_req_fld = []
                                nw_obj_min_flds = 0
                                nw_fld_names = []
                                nw_fld_defaults = []
                                nw_fld_units = []
                                deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                                
                                del_this = False
                                deps.ScanOutputVariablesForReplacement(
                                    3, del_this, check_rvi, no_diff, object_name, dif_lfn,
                                    False, False, False, cur_args, written, True)
                                
                                if del_this:
                                    continue
                            
                            elif rec_name_upper in ['OUTPUT:TABLE:MONTHLY', 'METER:CUSTOM', 'METER:CUSTOMDECREMENT', 'DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF', 'ELECTRICLOADCENTER:DISTRIBUTION']:
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                no_diff = True
                            
                            else:
                                if deps.FindItemInList(object_name, globals_state.NotInNew, len(globals_state.NotInNew)) != 0:
                                    deps.show_message_to_audit('Object="' + object_name + '" is not in the "new" IDD.', globals_state.Auditf)
                                    deps.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, globals_state.FldNames, globals_state.FldUnits)
                                    written = True
                                else:
                                    nw_num_args = 0
                                    nw_aorn = []
                                    nw_req_fld = []
                                    nw_obj_min_flds = 0
                                    nw_fld_names = []
                                    nw_fld_defaults = []
                                    nw_fld_units = []
                                    deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    no_diff = True
                        else:
                            nw_num_args = 0
                            nw_aorn = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            deps.GetNewObjectDefInIDD(globals_state.IDFRecords[num].Name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if diff_min_fields and no_diff:
                            nw_num_args = 0
                            nw_aorn = []
                            nw_req_fld = []
                            nw_obj_min_flds = 0
                            nw_fld_names = []
                            nw_fld_defaults = []
                            nw_fld_units = []
                            deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                            no_diff = False
                            
                            for arg in range(cur_args, nw_obj_min_flds):
                                out_args[arg] = nw_fld_defaults[arg]
                            
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            written_check = False
                            deps.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written_check)
                            written = written_check
                        
                        if not written:
                            deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    deps.DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if globals_state.IDFRecords[globals_state.NumIDFRecords - 1].CommtE != globals_state.CurComment:
                        for xcount in range(globals_state.IDFRecords[globals_state.NumIDFRecords - 1].CommtE + 1, globals_state.CurComment + 1):
                            dif_file.write(globals_state.Comments[xcount] + '\n')
                            if xcount == globals_state.IDFRecords[globals_state.NumIDFRecords - 1].CommtE:
                                dif_file.write('\n')
                    
                    if deps.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args = 0
                        nw_aorn = []
                        nw_req_fld = []
                        nw_obj_min_flds = 0
                        nw_fld_names = []
                        nw_fld_defaults = []
                        nw_fld_units = []
                        deps.GetNewObjectDefInIDD(object_name, nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        no_diff = False
                        out_args = [""] * 1000
                        out_args[0] = 'Regular'
                        cur_args = 1
                        deps.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    import os
                    rvi_exists = os.path.exists(file_name_path + '.rvi')
                    dif_file.close()
                    deps.ProcessRviMviFiles(file_name_path, 'rvi')
                    deps.ProcessRviMviFiles(file_name_path, 'mvi')
                    deps.CloseOut()
                else:
                    deps.ProcessRviMviFiles(file_name_path, 'rvi')
                    deps.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            created_output_name = ""
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
        deps.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        deps.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag)
        
        import os
        rvi_exists = os.path.exists(file_name_path + '.rvi')
        if rvi_exists:
            deps.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        
        rvi_new_exists = os.path.exists(file_name_path + '.rvinew')
        if rvi_new_exists:
            deps.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        
        mvi_exists = os.path.exists(file_name_path + '.mvi')
        if mvi_exists:
            deps.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        
        mvi_new_exists = os.path.exists(file_name_path + '.mvinew')
        if mvi_new_exists:
            deps.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
    
    return end_of_file
