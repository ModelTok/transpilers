from typing import Protocol, List, Dict, Any, Optional, Tuple
import os

class DataStringGlobals(Protocol):
    ProgNameConversion: str
    ProgramPath: str
    VerString: str
    VersionNum: float
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    FullFileName: str
    FileNamePath: str
    Auditf: Any
    blank: str

class IDFRecord:
    def __init__(self):
        self.Name: str = ""
        self.NumAlphas: int = 0
        self.NumNumbers: int = 0
        self.Alphas: List[str] = []
        self.Numbers: List[str] = []
        self.CommtS: int = 0
        self.CommtE: int = 0

class DataVCompareGlobals(Protocol):
    FatalError: bool
    IDFRecords: List[IDFRecord]
    Comments: List[str]
    NumIDFRecords: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    CurComment: int
    ObjectDef: Any
    NumObjectDefs: int
    NotInNew: List[str]
    NumRepVarNames: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    ProcessingIMFFile: bool
    MakingPretty: bool

class GeneralRoutines(Protocol):
    def SameString(a: str, b: str) -> bool: pass
    def MakeUPPERCase(s: str) -> str: pass
    def MakeLowerCase(s: str) -> str: pass
    def FindItemInList(name: str, list_: List[str], size: int) -> int: pass
    def ProcessNumber(s: str, err_flag: List[bool]) -> float: pass
    def RoundSigDigits(val: float, digits: int) -> str: pass
    def TrimTrailZeros(s: str) -> str: pass

class ExternalFunctions(Protocol):
    def GetNewUnitNumber() -> int: pass
    def GetNewObjectDefInIDD(name: str, num_args: List[int], aorn: List[bool], 
                             req_fld: List[bool], obj_min_flds: List[int], 
                             fld_names: List[str], fld_defaults: List[str], 
                             fld_units: List[str]) -> None: pass
    def GetObjectDefInIDD(name: str, num_args: List[int], aorn: List[bool], 
                          req_fld: List[bool], obj_min_flds: List[int], 
                          fld_names: List[str], fld_defaults: List[str], 
                          fld_units: List[str]) -> None: pass
    def DisplayString(msg: str) -> None: pass
    def WriteOutIDFLinesAsComments(lun: int, obj_name: str, cur_args: int, 
                                   out_args: List[str], fld_names: List[str], 
                                   fld_units: List[str]) -> None: pass
    def WriteOutIDFLines(lun: int, obj_name: str, cur_args: int, 
                         out_args: List[str], fld_names: List[str], 
                         fld_units: List[str]) -> None: pass
    def ScanOutputVariablesForReplacement(field: int, del_this: List[bool], 
                                         check_rvi: List[bool], nodiff: List[bool], 
                                         obj_name: str, lun: int, out_var: bool, 
                                         mtr_var: bool, time_bin_var: bool, 
                                         cur_args: int, written: List[bool], 
                                         is_sensor: bool) -> None: pass
    def writePreprocessorObject(lun: int, prog: str, level: str, msg: str) -> None: pass
    def CheckSpecialObjects(lun: int, obj_name: str, cur_args: int, 
                           out_args: List[str], fld_names: List[str], 
                           fld_units: List[str], written: List[bool]) -> None: pass
    def ProcessInput(idd_old: str, idd_new: str, idf_file: str) -> None: pass
    def ProcessRviMviFiles(file_path: str, ext: str) -> None: pass
    def CloseOut() -> None: pass
    def CreateNewName(mode: str, name: List[str], extra: str) -> None: pass
    def copyfile(src: str, dst: str, err_flag: List[bool]) -> None: pass
    def GetNumSectionsFound(section: str) -> int: pass

def set_this_version_variables(data_string_globals: DataStringGlobals) -> None:
    data_string_globals.VerString = 'Conversion 7.0 => 7.1'
    data_string_globals.VersionNum = 7.1
    data_string_globals.IDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'V7-0-0-Energy+.idd'
    data_string_globals.NewIDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'V7-1-0-Energy+.idd'
    data_string_globals.RepVarFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'Report Variables 7-0-0-036 to 7-1-0.csv'

def create_new_idf_using_rules(
    data_string_globals: DataStringGlobals,
    data_vcompare_globals: DataVCompareGlobals,
    general: GeneralRoutines,
    external: ExternalFunctions,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str
) -> None:
    fmta = "(A)"
    
    first_time = True
    if first_time:
        pass
    
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
                print('-->', end='')
                data_string_globals.FullFileName = input()
            else:
                if not arg_file:
                    try:
                        with open(str(in_lfn), 'r') as f:
                            data_string_globals.FullFileName = f.readline().strip()
                        ios = 0
                    except:
                        ios = 1
                elif not arg_file_being_done:
                    data_string_globals.FullFileName = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    data_string_globals.FullFileName = ''
                    ios = 1
                
                if data_string_globals.FullFileName and data_string_globals.FullFileName[0] == '!':
                    data_string_globals.FullFileName = ''
                    continue
            
            if ios != 0:
                data_string_globals.FullFileName = ''
            
            data_string_globals.FullFileName = data_string_globals.FullFileName.lstrip()
            
            if data_string_globals.FullFileName:
                external.DisplayString('Processing IDF -- ' + data_string_globals.FullFileName)
                data_string_globals.Auditf.write(' Processing IDF -- ' + data_string_globals.FullFileName + '\n')
                
                dot_pos = data_string_globals.FullFileName.rfind('.')
                if dot_pos >= 0:
                    data_string_globals.FileNamePath = data_string_globals.FullFileName[:dot_pos]
                    local_file_extension = general.MakeLowerCase(data_string_globals.FullFileName[dot_pos+1:])
                else:
                    data_string_globals.FileNamePath = data_string_globals.FullFileName
                    print(' assuming file extension of .idf')
                    data_string_globals.Auditf.write(' ..assuming file extension of .idf\n')
                    data_string_globals.FullFileName = data_string_globals.FullFileName + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = external.GetNewUnitNumber()
                file_ok = os.path.exists(data_string_globals.FullFileName)
                
                if not file_ok:
                    print('File not found=' + data_string_globals.FullFileName)
                    data_string_globals.Auditf.write('File not found=' + data_string_globals.FullFileName + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        out_file = data_string_globals.FileNamePath + '.' + local_file_extension + 'dif'
                    else:
                        out_file = data_string_globals.FileNamePath + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        external.WriteOutIDFLinesAsComments(dif_lfn, 'NOTE', 0, [], [], [])
                        data_vcompare_globals.ProcessingIMFFile = True
                    else:
                        data_vcompare_globals.ProcessingIMFFile = False
                    
                    external.ProcessInput(data_string_globals.IDDFileNameWithPath, 
                                        data_string_globals.NewIDDFileNameWithPath,
                                        data_string_globals.FullFileName)
                    
                    if data_vcompare_globals.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [''] * data_vcompare_globals.MaxAlphaArgsFound
                    numbers = [''] * data_vcompare_globals.MaxNumericArgsFound
                    in_args = [''] * data_vcompare_globals.MaxTotalArgs
                    aorn = [False] * data_vcompare_globals.MaxTotalArgs
                    req_fld = [False] * data_vcompare_globals.MaxTotalArgs
                    fld_names = [''] * data_vcompare_globals.MaxTotalArgs
                    fld_defaults = [''] * data_vcompare_globals.MaxTotalArgs
                    fld_units = [''] * data_vcompare_globals.MaxTotalArgs
                    nw_aorn = [False] * data_vcompare_globals.MaxTotalArgs
                    nw_req_fld = [False] * data_vcompare_globals.MaxTotalArgs
                    nw_fld_names = [''] * data_vcompare_globals.MaxTotalArgs
                    nw_fld_defaults = [''] * data_vcompare_globals.MaxTotalArgs
                    nw_fld_units = [''] * data_vcompare_globals.MaxTotalArgs
                    out_args = [''] * data_vcompare_globals.MaxTotalArgs
                    match_arg = [''] * data_vcompare_globals.MaxTotalArgs
                    delete_this_record = [False] * data_vcompare_globals.NumIDFRecords
                    
                    no_version = True
                    for num in range(data_vcompare_globals.NumIDFRecords):
                        if general.MakeUPPERCase(data_vcompare_globals.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(data_vcompare_globals.NumIDFRecords):
                        if delete_this_record[num]:
                            with open(out_file, 'a') as f:
                                f.write('! Deleting: ' + data_vcompare_globals.IDFRecords[num].Name + ':' + 
                                       data_vcompare_globals.IDFRecords[num].Alphas[0] + '\n')
                    
                    for num in range(data_vcompare_globals.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(data_vcompare_globals.IDFRecords[num].CommtS + 1, 
                                          data_vcompare_globals.IDFRecords[num].CommtE + 1):
                            with open(out_file, 'a') as f:
                                f.write(data_vcompare_globals.Comments[xcount].rstrip() + '\n')
                                if xcount == data_vcompare_globals.IDFRecords[num].CommtE:
                                    f.write(' \n')
                        
                        if no_version and num == 0:
                            external.GetNewObjectDefInIDD('VERSION', [0], nw_aorn, nw_req_fld, [0], 
                                                         nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '7.1'
                            cur_args = 1
                            external.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, out_args, 
                                                               nw_fld_names, nw_fld_units)
                        
                        object_name = data_vcompare_globals.IDFRecords[num].Name
                        
                        if general.MakeUPPERCase(object_name.strip()) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if general.MakeUPPERCase(object_name.strip()) == 'AIRFLOW MODEL':
                            continue
                        if general.MakeUPPERCase(object_name.strip()) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if general.MakeUPPERCase(object_name.strip()) == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if general.MakeUPPERCase(object_name.strip()) == 'WATER HEATER:SIMPLE':
                            with open(out_file, 'a') as f:
                                f.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            external.writePreprocessorObject(dif_lfn, data_string_globals.ProgNameConversion, 'Warning',
                                                            'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        if general.FindItemInList(object_name, [d.Name for d in data_vcompare_globals.ObjectDef], 
                                                data_vcompare_globals.NumObjectDefs) != 0:
                            external.GetObjectDefInIDD(object_name, [0], aorn, req_fld, [0], fld_names, 
                                                      fld_defaults, fld_units)
                            num_alphas = data_vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = data_vcompare_globals.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = data_vcompare_globals.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = data_vcompare_globals.IDFRecords[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [''] * data_vcompare_globals.MaxTotalArgs
                            out_args = [''] * data_vcompare_globals.MaxTotalArgs
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
                            data_string_globals.Auditf.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                            data_string_globals.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            data_string_globals.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = data_vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = data_vcompare_globals.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = data_vcompare_globals.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = data_vcompare_globals.IDFRecords[num].Numbers[:num_numbers]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = numbers[arg]
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [''] * data_vcompare_globals.MaxTotalArgs
                            nw_fld_units = [''] * data_vcompare_globals.MaxTotalArgs
                            external.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, 
                                                               nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if general.FindItemInList(general.MakeUPPERCase(object_name), 
                                                data_vcompare_globals.NotInNew, 
                                                len(data_vcompare_globals.NotInNew)) == 0:
                            external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                         nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        if not data_vcompare_globals.MakingPretty:
                            obj_name_upper = general.MakeUPPERCase(object_name.strip())
                            
                            if obj_name_upper == 'VERSION':
                                if in_args[0][:3] == '7.1' and arg_file:
                                    print('File is already at latest version.  No new diff file made.')
                                    data_string_globals.Auditf.write('File is already at latest version.  No new diff file made.\n')
                                    latest_version = True
                                    break
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '7.1'
                                nodiff = False
                            
                            elif obj_name_upper == 'AIRLOOPHVAC:RETURNPLENUM':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:4] = in_args[0:4]
                                out_args[4] = ''
                                out_args[5:cur_args+1] = in_args[4:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'AIRLOOPHVAC:UNITARYCOOLONLY':
                                nodiff = False
                                object_name = 'CoilSystem:Cooling:DX'
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                            
                            elif obj_name_upper == 'BRANCH':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                for arg in range(3, cur_args, 5):
                                    if not general.SameString(out_args[arg], 'AirLoopHVAC:UnitaryCoolOnly'):
                                        continue
                                    out_args[arg] = 'CoilSystem:Cooling:DX'
                            
                            elif obj_name_upper == 'ZONEHVAC:OUTDOORAIRUNIT:EQUIPMENTLIST':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                for arg in range(1, cur_args, 2):
                                    if not general.SameString(out_args[arg], 'AirLoopHVAC:UnitaryCoolOnly'):
                                        continue
                                    out_args[arg] = 'CoilSystem:Cooling:DX'
                            
                            elif obj_name_upper == 'AIRLOOPHVAC:OUTDOORAIRSYSTEM:EQUIPMENTLIST':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                for arg in range(1, cur_args, 2):
                                    if not general.SameString(out_args[arg], 'AirLoopHVAC:UnitaryCoolOnly'):
                                        continue
                                    out_args[arg] = 'CoilSystem:Cooling:DX'
                            
                            elif obj_name_upper == 'SIZINGPERIOD:DESIGNDAY':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[11]
                                out_args[2] = in_args[10]
                                out_args[3] = in_args[12]
                                out_args[4] = in_args[1]
                                out_args[5] = in_args[2]
                                if cur_args >= 17:
                                    out_args[6] = in_args[16]
                                else:
                                    out_args[6] = ''
                                if cur_args >= 18:
                                    out_args[7] = in_args[17]
                                else:
                                    out_args[7] = ''
                                out_args[8] = in_args[14]
                                if (general.SameString(out_args[8], 'Wetbulb') or 
                                    general.SameString(out_args[8], 'Wet-bulb') or 
                                    out_args[8] == ''):
                                    out_args[8] = 'Wetbulb'
                                    out_args[9] = in_args[3]
                                    out_args[10] = in_args[15]
                                    out_args[11] = ''
                                    out_args[12] = ''
                                elif general.SameString(out_args[8], 'Dewpoint'):
                                    out_args[9] = in_args[3]
                                    out_args[10] = in_args[15]
                                    out_args[11] = ''
                                    out_args[12] = ''
                                elif general.SameString(out_args[8], 'HumidityRatio'):
                                    out_args[9] = ''
                                    out_args[10] = in_args[15]
                                    out_args[11] = in_args[3]
                                    out_args[12] = ''
                                elif general.SameString(out_args[8], 'Enthalpy'):
                                    out_args[9] = ''
                                    out_args[10] = in_args[15]
                                    out_args[11] = ''
                                    err_flag = [False]
                                    test_value = general.ProcessNumber(in_args[3], err_flag)
                                    if not err_flag[0]:
                                        test_value = test_value * 1000.0
                                        out_args[12] = general.RoundSigDigits(test_value, 2)
                                    else:
                                        out_args[12] = 'invalid'
                                elif general.SameString(out_args[8], 'Schedule'):
                                    out_args[8] = 'RelativeHumiditySchedule'
                                    out_args[9:13] = [''] * 4
                                    out_args[10] = in_args[15]
                                elif (general.SameString(out_args[8], 'WetBulbProfileMultiplierSchedule') or
                                      general.SameString(out_args[8], 'WetBulbProfileDifferenceSchedule') or
                                      general.SameString(out_args[8], 'WetBulbProfileDefaultMultipliers')):
                                    out_args[9] = in_args[3]
                                    out_args[10] = in_args[15]
                                    out_args[11:13] = ['', '']
                                
                                if cur_args >= 24:
                                    out_args[13] = in_args[23]
                                else:
                                    out_args[13] = ''
                                out_args[14] = in_args[4]
                                out_args[15] = in_args[5]
                                out_args[16] = in_args[6]
                                err_flag = [False]
                                test_value = general.ProcessNumber(in_args[8], err_flag)
                                if test_value == 0.0:
                                    out_args[17] = 'No'
                                elif test_value == 1.0:
                                    out_args[17] = 'Yes'
                                elif in_args[8] == '':
                                    out_args[17] = ''
                                else:
                                    out_args[17] = 'invalid'
                                test_value = general.ProcessNumber(in_args[9], err_flag)
                                if test_value == 0.0:
                                    out_args[18] = 'No'
                                elif test_value == 1.0:
                                    out_args[18] = 'Yes'
                                elif in_args[9] == '':
                                    out_args[18] = ''
                                else:
                                    out_args[18] = 'invalid'
                                test_value = general.ProcessNumber(in_args[13], err_flag)
                                if test_value == 0.0:
                                    out_args[19] = 'No'
                                elif test_value == 1.0:
                                    out_args[19] = 'Yes'
                                elif in_args[13] == '':
                                    out_args[19] = ''
                                else:
                                    out_args[19] = 'invalid'
                                if cur_args >= 19:
                                    out_args[20] = in_args[18]
                                else:
                                    out_args[20] = 'ASHRAEClearSky'
                                if cur_args >= 20:
                                    out_args[21] = in_args[19]
                                else:
                                    out_args[21] = ''
                                if cur_args >= 21:
                                    out_args[22] = in_args[20]
                                else:
                                    out_args[22] = ''
                                if cur_args >= 22:
                                    out_args[23] = in_args[21]
                                else:
                                    out_args[23] = ''
                                if cur_args >= 23:
                                    out_args[24] = in_args[22]
                                else:
                                    out_args[24] = ''
                                if (general.SameString(out_args[20], 'ASHRAEClearSky') or 
                                    general.SameString(out_args[20], 'ZhangHuang')):
                                    out_args[25] = in_args[7]
                                    cur_args = 26
                                else:
                                    arg_idx = 24
                                    if in_args[7] != '':
                                        external.writePreprocessorObject(dif_lfn, data_string_globals.ProgNameConversion, 
                                                                        'Warning',
                                                                        'SizingPeriod:DesignDay object="' + 
                                                                        out_args[0].strip() + '" ' + 
                                                                        nw_fld_names[20] + '="' + 
                                                                        out_args[20] + '" does not use ' +
                                                                        nw_fld_names[25] + ' but prior input was not blank.')
                                        out_args[25] = in_args[7]
                                        arg_idx = 25
                                    for idx in range(arg_idx, 20, -1):
                                        if out_args[idx] != '':
                                            cur_args = idx + 1
                                            break
                            
                            elif obj_name_upper == 'CONTROLLER:MECHANICALVENTILATION':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:4] = in_args[0:4]
                                out_args[4] = ''
                                nargs = cur_args
                                c_out_args = 5
                                for arg in range(4, nargs, 5):
                                    out_args[c_out_args] = in_args[arg]
                                    c_out_args += 1
                                    out_args[c_out_args] = in_args[arg + 1]
                                    c_out_args += 1
                                    out_args[c_out_args] = 'CM DSZAD ' + in_args[arg].strip()
                                    c_out_args += 1
                                c_out_args -= 1
                                external.WriteOutIDFLines(dif_lfn, object_name, c_out_args, out_args, 
                                                         nw_fld_names, nw_fld_units)
                                
                                object_name = 'DesignSpecification:ZoneAirDistribution'
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for arg in range(4, nargs, 5):
                                    out_args[0] = 'CM DSZAD ' + in_args[arg].strip()
                                    out_args[1] = in_args[arg + 2]
                                    out_args[2] = in_args[arg + 3]
                                    out_args[3] = in_args[arg + 4]
                                    c_out_args = 4
                                    external.WriteOutIDFLines(dif_lfn, object_name, c_out_args, out_args, 
                                                             nw_fld_names, nw_fld_units)
                                written = True
                            
                            elif obj_name_upper == 'SIZING:ZONE':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:18] = in_args[0:18]
                                if in_args[18] != '' or in_args[19] != '':
                                    out_args[18] = 'SZ DZAD ' + in_args[0].strip()
                                    c_out_args = 19
                                else:
                                    c_out_args = 18
                                external.WriteOutIDFLines(dif_lfn, object_name, c_out_args, out_args, 
                                                         nw_fld_names, nw_fld_units)
                                
                                if in_args[18] != '' or in_args[19] != '':
                                    object_name = 'DesignSpecification:ZoneAirDistribution'
                                    external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                                 nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = 'SZ DZAD ' + in_args[0].strip()
                                    out_args[1] = in_args[18]
                                    out_args[2] = in_args[19]
                                    if out_args[2] == '':
                                        c_out_args = 2
                                    else:
                                        c_out_args = 3
                                    external.WriteOutIDFLines(dif_lfn, object_name, c_out_args, out_args, 
                                                             nw_fld_names, nw_fld_units)
                                written = True
                            
                            elif obj_name_upper == 'COIL:HEATING:DX:SINGLESPEED':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:5] = in_args[0:5]
                                out_args[5] = ''
                                out_args[6:15] = in_args[5:14]
                                out_args[15] = ''
                                out_args[16:23] = in_args[14:21]
                                if cur_args > 21:
                                    out_args[23] = ''
                                    out_args[24] = in_args[21]
                                    cur_args = 25
                                else:
                                    cur_args = 23
                            
                            elif obj_name_upper == 'WINDOWMATERIAL:SHADE':
                                nodiff = False
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if out_args[6] == '':
                                    out_args[6] = '0.0'
                                if out_args[7] == '':
                                    out_args[7] = '0.003'
                                if out_args[8] == '':
                                    out_args[8] = '0.1'
                            
                            elif obj_name_upper == 'OUTPUT:VARIABLE':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                check_rvi_ref = [check_rvi]
                                nodiff_ref = [nodiff]
                                written_ref = [written]
                                external.ScanOutputVariablesForReplacement(2, del_this, check_rvi_ref, nodiff_ref,
                                                                          object_name, dif_lfn, True, False, False,
                                                                          cur_args, written_ref, False)
                                check_rvi = check_rvi_ref[0]
                                nodiff = nodiff_ref[0]
                                written = written_ref[0]
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 
                                                   'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                del_this = [False]
                                check_rvi_ref = [check_rvi]
                                nodiff_ref = [nodiff]
                                written_ref = [written]
                                external.ScanOutputVariablesForReplacement(1, del_this, check_rvi_ref, nodiff_ref,
                                                                          object_name, dif_lfn, False, True, False,
                                                                          cur_args, written_ref, False)
                                check_rvi = check_rvi_ref[0]
                                nodiff = nodiff_ref[0]
                                written = written_ref[0]
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                check_rvi_ref = [check_rvi]
                                nodiff_ref = [nodiff]
                                written_ref = [written]
                                external.ScanOutputVariablesForReplacement(2, del_this, check_rvi_ref, nodiff_ref,
                                                                          object_name, dif_lfn, False, False, True,
                                                                          cur_args, written_ref, False)
                                check_rvi = check_rvi_ref[0]
                                nodiff = nodiff_ref[0]
                                written = written_ref[0]
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                del_this = [False]
                                check_rvi_ref = [check_rvi]
                                nodiff_ref = [nodiff]
                                written_ref = [written]
                                external.ScanOutputVariablesForReplacement(3, del_this, check_rvi_ref, nodiff_ref,
                                                                          object_name, dif_lfn, False, False, False,
                                                                          cur_args, written_ref, True)
                                check_rvi = check_rvi_ref[0]
                                nodiff = nodiff_ref[0]
                                written = written_ref[0]
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                nodiff = True
                                out_args[0:cur_args] = in_args[0:cur_args]
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = general.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    del_this = False
                                    for arg in range(data_vcompare_globals.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                            if data_vcompare_globals.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if (data_vcompare_globals.NewRepVarCaution[arg] != '' and
                                                    not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq')):
                                                    if not data_vcompare_globals.OTMVarCaution[arg]:
                                                        external.writePreprocessorObject(dif_lfn, 
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Output Table Monthly (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Output Table Monthly (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                        data_vcompare_globals.OTMVarCaution[arg] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if (arg + 1 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]):
                                                if not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 1].rstrip() +
                                                                            out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                    if data_vcompare_globals.NewRepVarCaution[arg + 1] != '':
                                                        if not data_vcompare_globals.OTMVarCaution[arg + 1]:
                                                            external.writePreprocessorObject(dif_lfn,
                                                                                            data_string_globals.ProgNameConversion,
                                                                                            'Warning',
                                                                                            'Output Table Monthly (old)="' +
                                                                                            data_vcompare_globals.OldRepVarName[arg] +
                                                                                            '" conversion to Output Table Monthly (new)="' +
                                                                                            data_vcompare_globals.NewRepVarName[arg + 1] +
                                                                                            '" has the following caution "' +
                                                                                            data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                            data_vcompare_globals.OTMVarCaution[arg + 1] = True
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                            if (arg + 2 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 2].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if data_vcompare_globals.NewRepVarCaution[arg + 2] != '':
                                                    if not data_vcompare_globals.OTMVarCaution[arg + 2]:
                                                        external.writePreprocessorObject(dif_lfn,
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Output Table Monthly (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Output Table Monthly (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg + 2] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                        data_vcompare_globals.OTMVarCaution[arg + 2] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            elif obj_name_upper == 'METER:CUSTOM':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = general.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    del_this = False
                                    for arg in range(data_vcompare_globals.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                            if data_vcompare_globals.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if (data_vcompare_globals.NewRepVarCaution[arg] != '' and
                                                    not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq')):
                                                    if not data_vcompare_globals.CMtrVarCaution[arg]:
                                                        external.writePreprocessorObject(dif_lfn,
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Custom Meter (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Custom Meter (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                        data_vcompare_globals.CMtrVarCaution[arg] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if (arg + 1 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]):
                                                if not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 1].rstrip() +
                                                                            out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                    if (data_vcompare_globals.NewRepVarCaution[arg + 1] != '' and
                                                        not general.SameString(data_vcompare_globals.NewRepVarCaution[arg + 1][:6], 'Forkeq')):
                                                        if not data_vcompare_globals.CMtrVarCaution[arg + 1]:
                                                            external.writePreprocessorObject(dif_lfn,
                                                                                            data_string_globals.ProgNameConversion,
                                                                                            'Warning',
                                                                                            'Custom Meter (old)="' +
                                                                                            data_vcompare_globals.OldRepVarName[arg] +
                                                                                            '" conversion to Custom Meter (new)="' +
                                                                                            data_vcompare_globals.NewRepVarName[arg + 1] +
                                                                                            '" has the following caution "' +
                                                                                            data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                            data_vcompare_globals.CMtrVarCaution[arg + 1] = True
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                            if (arg + 2 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 2].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if data_vcompare_globals.NewRepVarCaution[arg + 2] != '':
                                                    if not data_vcompare_globals.CMtrVarCaution[arg + 2]:
                                                        external.writePreprocessorObject(dif_lfn,
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Custom Meter (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Custom Meter (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg + 2] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                        data_vcompare_globals.CMtrVarCaution[arg + 2] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == '':
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper == 'METER:CUSTOMDECREMENT':
                                external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                             nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = True
                                cur_var = 3
                                for var in range(3, cur_args, 2):
                                    uc_rep_var_name = general.MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    del_this = False
                                    for arg in range(data_vcompare_globals.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                            if data_vcompare_globals.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if (data_vcompare_globals.NewRepVarCaution[arg] != '' and
                                                    not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq')):
                                                    if not data_vcompare_globals.CMtrDVarCaution[arg]:
                                                        external.writePreprocessorObject(dif_lfn,
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Custom Decrement Meter (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Custom Meter (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                        data_vcompare_globals.CMtrDVarCaution[arg] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if (arg + 1 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]):
                                                if not general.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 1].rstrip() +
                                                                            out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                    if (data_vcompare_globals.NewRepVarCaution[arg + 1] != '' and
                                                        not general.SameString(data_vcompare_globals.NewRepVarCaution[arg + 1][:6], 'Forkeq')):
                                                        if not data_vcompare_globals.CMtrDVarCaution[arg + 1]:
                                                            external.writePreprocessorObject(dif_lfn,
                                                                                            data_string_globals.ProgNameConversion,
                                                                                            'Warning',
                                                                                            'Custom Decrement Meter (old)="' +
                                                                                            data_vcompare_globals.OldRepVarName[arg] +
                                                                                            '" conversion to Custom Decrement Meter (new)="' +
                                                                                            data_vcompare_globals.NewRepVarName[arg + 1] +
                                                                                            '" has the following caution "' +
                                                                                            data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                            data_vcompare_globals.CMtrDVarCaution[arg + 1] = True
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                            if (arg + 2 < len(data_vcompare_globals.OldRepVarName) and
                                                data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = (data_vcompare_globals.NewRepVarName[arg + 2].rstrip() +
                                                                        out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):])
                                                if data_vcompare_globals.NewRepVarCaution[arg + 2] != '':
                                                    if not data_vcompare_globals.CMtrDVarCaution[arg + 2]:
                                                        external.writePreprocessorObject(dif_lfn,
                                                                                        data_string_globals.ProgNameConversion,
                                                                                        'Warning',
                                                                                        'Custom Decrement Meter (old)="' +
                                                                                        data_vcompare_globals.OldRepVarName[arg] +
                                                                                        '" conversion to Custom Meter (new)="' +
                                                                                        data_vcompare_globals.NewRepVarName[arg + 2] +
                                                                                        '" has the following caution "' +
                                                                                        data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                        data_vcompare_globals.CMtrDVarCaution[arg + 2] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == '':
                                        cur_args -= 1
                                    else:
                                        break
                            
                            else:
                                if general.FindItemInList(object_name, data_vcompare_globals.NotInNew, 
                                                        len(data_vcompare_globals.NotInNew)) != 0:
                                    data_string_globals.Auditf.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                    data_string_globals.Auditf.write('... will be listed as comments on the new output file.\n')
                                    external.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args,
                                                                       fld_names, fld_units)
                                    written = True
                                else:
                                    external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0],
                                                                 nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                        
                        else:
                            external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                         nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]
                        
                        if diff_min_fields and nodiff:
                            external.GetNewObjectDefInIDD(object_name, [0], nw_aorn, nw_req_fld, [0], 
                                                         nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]
                            nodiff = False
                            for arg in range(cur_args, len(nw_fld_defaults)):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(len(nw_fld_defaults), cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            written_ref = [written]
                            external.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, 
                                                        nw_fld_names, nw_fld_units, written_ref)
                            written = written_ref[0]
                        
                        if not written:
                            external.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, 
                                                     nw_fld_names, nw_fld_units)
            else:
                end_of_file[0] = True
        
        created_output_name = ['']
        external.CreateNewName('Reallocate', created_output_name, ' ')
        
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
        external.copyfile(data_string_globals.FileNamePath + '.' + arg_idf_extension,
                         data_string_globals.FileNamePath + '.' + arg_idf_extension + 'old', err_flag)
        external.copyfile(data_string_globals.FileNamePath + '.' + arg_idf_extension + 'new',
                         data_string_globals.FileNamePath + '.' + arg_idf_extension, err_flag)
        if os.path.exists(data_string_globals.FileNamePath + '.rvi'):
            external.copyfile(data_string_globals.FileNamePath + '.rvi',
                             data_string_globals.FileNamePath + '.rviold', err_flag)
        if os.path.exists(data_string_globals.FileNamePath + '.rvinew'):
            external.copyfile(data_string_globals.FileNamePath + '.rvinew',
                             data_string_globals.FileNamePath + '.rvi', err_flag)
        if os.path.exists(data_string_globals.FileNamePath + '.mvi'):
            external.copyfile(data_string_globals.FileNamePath + '.mvi',
                             data_string_globals.FileNamePath + '.mviold', err_flag)
        if os.path.exists(data_string_globals.FileNamePath + '.mvinew'):
            external.copyfile(data_string_globals.FileNamePath + '.mvinew',
                             data_string_globals.FileNamePath + '.mvi', err_flag)
