# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: blank, ProgNameConversion
# - DataVCompareGlobals: VersionNum, sVersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, 
#   RepVarFileNameWithPath, ProgramPath, ProcessingIMFFile, Auditf, FatalError, FullFileName,
#   FileNamePath, NumIDFRecords, IDFRecords, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld,
#   NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg, DeleteThisRecord, Comments,
#   CurComment, NumRepVarNames, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution,
#   CMtrVarCaution, CMtrDVarCaution, ObjectDef, NumObjectDefs, NotInNew, MakingPretty
# - VCompareGlobalRoutines: DisplayString, ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD,
#   ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments, WriteOutIDFLines,
#   CheckSpecialObjects, CreateNewName, ProcessRviMviFiles, CloseOut, writePreprocessorObject,
#   GetNumSectionsFound, copyfile
# - General: MakeUPPERCase, MakeLowerCase, SameString, FindItemInList, TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - External functions: GetNewUnitNumber, CalculateMuEMPD

from typing import Protocol


class DataStringGlobalsProto(Protocol):
    blank: str
    ProgNameConversion: str


class IDFRecordProto(Protocol):
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: list
    Numbers: list
    CommtS: int
    CommtE: int


class ObjectDefProto(Protocol):
    Name: list


class DataVCompareGlobalsProto(Protocol):
    VersionNum: float
    sVersionNum: str
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    ProgramPath: str
    ProcessingIMFFile: bool
    Auditf: int
    FatalError: bool
    FullFileName: str
    FileNamePath: str
    NumIDFRecords: int
    IDFRecords: list
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    Alphas: list
    Numbers: list
    InArgs: list
    AorN: list
    ReqFld: list
    FldNames: list
    FldDefaults: list
    FldUnits: list
    NwAorN: list
    NwReqFld: list
    NwFldNames: list
    NwFldDefaults: list
    NwFldUnits: list
    OutArgs: list
    MatchArg: list
    DeleteThisRecord: list
    Comments: list
    CurComment: int
    NumRepVarNames: int
    OldRepVarName: list
    NewRepVarName: list
    NewRepVarCaution: list
    OTMVarCaution: list
    CMtrVarCaution: list
    CMtrDVarCaution: list
    ObjectDef: ObjectDefProto
    NumObjectDefs: int
    NotInNew: list
    MakingPretty: bool


class VCompareGlobalRoutinesProto(Protocol):
    def DisplayString(self, msg: str) -> None: ...
    def ProcessInput(self, idd_path: str, new_idd_path: str, idf_path: str) -> None: ...
    def GetObjectDefInIDD(self, name: str) -> tuple: ...
    def GetNewObjectDefInIDD(self, name: str) -> tuple: ...
    def ScanOutputVariablesForReplacement(self, field_num: int, del_this: bool, check_rvi: bool,
                                          nodiff: bool, obj_name: str, lfn: int, out_var: bool,
                                          mtr_var: bool, time_bin_var: bool, cur_args: int,
                                          written: bool, is_sensor: bool) -> None: ...
    def WriteOutIDFLinesAsComments(self, lfn: int, obj_name: str, cur_args: int,
                                    out_args: list, fld_names: list, fld_units: list) -> None: ...
    def WriteOutIDFLines(self, lfn: int, obj_name: str, cur_args: int,
                         out_args: list, fld_names: list, fld_units: list) -> None: ...
    def CheckSpecialObjects(self, lfn: int, obj_name: str, cur_args: int,
                            out_args: list, fld_names: list, fld_units: list, written: bool) -> None: ...
    def CreateNewName(self, mode: str, output_name: str, extra: str) -> str: ...
    def ProcessRviMviFiles(self, file_path: str, ext: str) -> None: ...
    def CloseOut(self) -> None: ...
    def writePreprocessorObject(self, lfn: int, prog_name: str, msg_type: str, msg: str) -> None: ...
    def GetNumSectionsFound(self, section: str) -> int: ...
    def copyfile(self, src: str, dst: str, err_flag: list) -> None: ...


class GeneralProto(Protocol):
    def MakeUPPERCase(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def SameString(self, s1: str, s2: str) -> bool: ...
    def FindItemInList(self, item: str, list_items: list, n: int) -> int: ...
    def TrimTrailZeros(self, s: str) -> str: ...


class DataGlobalsProto(Protocol):
    def ShowMessage(self, msg: str) -> None: ...
    def ShowContinueError(self, msg: str) -> None: ...
    def ShowFatalError(self, msg: str) -> None: ...
    def ShowSevereError(self, msg: str) -> None: ...
    def ShowWarningError(self, msg: str, lfn: int = -1) -> None: ...


def set_this_version_variables(data_version: DataVCompareGlobalsProto,
                               data_string: DataStringGlobalsProto) -> None:
    data_version.VersionNum = 8.7
    data_version.sVersionNum = '8.7'
    data_version.IDDFileNameWithPath = data_version.ProgramPath.rstrip() + 'V8-6-0-Energy+.idd'
    data_version.NewIDDFileNameWithPath = data_version.ProgramPath.rstrip() + 'V8-7-0-Energy+.idd'
    data_version.RepVarFileNameWithPath = data_version.ProgramPath.rstrip() + 'Report Variables 8-6-0 to 8-7-0.csv'


def create_new_idf_using_rules(
    end_of_file: list,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    data_version: DataVCompareGlobalsProto,
    data_string: DataStringGlobalsProto,
    v_compare: VCompareGlobalRoutinesProto,
    general: GeneralProto,
    data_globals: DataGlobalsProto
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
                print('-->', end='', flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
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
                v_compare.DisplayString('Processing IDF -- ' + full_file_name)
                data_version.Auditf.write(' Processing IDF -- ' + full_file_name + '\n')

                dot_pos = full_file_name.rfind('.')
                
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = general.MakeLowerCase(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    data_version.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'

                dif_lfn = v_compare.GetNewUnitNumber()

                import os
                file_ok = os.path.exists(full_file_name)

                if not file_ok:
                    print('File not found=' + full_file_name)
                    data_version.Auditf.write('File not found=' + full_file_name + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break

                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False

                    if diff_only:
                        dif_file_path = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_path = file_name_path + '.' + local_file_extension + 'new'

                    dif_file = open(dif_file_path, 'w')

                    if local_file_extension == 'imf':
                        data_globals.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', data_version.Auditf)
                        data_version.ProcessingIMFFile = True
                    else:
                        data_version.ProcessingIMFFile = False

                    v_compare.ProcessInput(data_version.IDDFileNameWithPath, data_version.NewIDDFileNameWithPath, full_file_name)

                    if data_version.FatalError:
                        exit_because_bad_file = True
                        break

                    data_version.DeleteThisRecord = [False] * data_version.NumIDFRecords
                    data_version.Alphas = [''] * data_version.MaxAlphaArgsFound
                    data_version.Numbers = [0.0] * data_version.MaxNumericArgsFound
                    data_version.InArgs = [''] * data_version.MaxTotalArgs
                    data_version.AorN = [False] * data_version.MaxTotalArgs
                    data_version.ReqFld = [False] * data_version.MaxTotalArgs
                    data_version.FldNames = [''] * data_version.MaxTotalArgs
                    data_version.FldDefaults = [''] * data_version.MaxTotalArgs
                    data_version.FldUnits = [''] * data_version.MaxTotalArgs
                    data_version.NwAorN = [False] * data_version.MaxTotalArgs
                    data_version.NwReqFld = [False] * data_version.MaxTotalArgs
                    data_version.NwFldNames = [''] * data_version.MaxTotalArgs
                    data_version.NwFldDefaults = [''] * data_version.MaxTotalArgs
                    data_version.NwFldUnits = [''] * data_version.MaxTotalArgs
                    data_version.OutArgs = [''] * data_version.MaxTotalArgs
                    data_version.MatchArg = [''] * data_version.MaxTotalArgs

                    no_version = True
                    for num in range(data_version.NumIDFRecords):
                        if general.MakeUPPERCase(data_version.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break

                    schedule_type_limits_any_number = False
                    for num in range(data_version.NumIDFRecords):
                        if not general.SameString(data_version.IDFRecords[num].Name, 'ScheduleTypeLimits'):
                            continue
                        if not general.SameString(data_version.IDFRecords[num].Alphas[0], 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break

                    for num in range(data_version.NumIDFRecords):
                        if data_version.DeleteThisRecord[num]:
                            dif_file.write('! Deleting: ' + data_version.IDFRecords[num].Name + '="' + data_version.IDFRecords[num].Alphas[0] + '".\n')

                    for num in range(data_version.NumIDFRecords):
                        if data_version.DeleteThisRecord[num]:
                            continue

                        for xcount in range(data_version.IDFRecords[num].CommtS, data_version.IDFRecords[num].CommtE + 1):
                            dif_file.write(data_version.Comments[xcount].rstrip() + '\n')
                            if xcount == data_version.IDFRecords[num].CommtE:
                                dif_file.write('\n')

                        if no_version and num == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD('VERSION')
                            data_version.OutArgs[0] = data_version.sVersionNum
                            cur_args = 1
                            v_compare.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, data_version.OutArgs, nw_fld_names, nw_fld_units)

                        obj_name = data_version.IDFRecords[num].Name
                        obj_upper = general.MakeUPPERCase(obj_name.rstrip())

                        if obj_upper == 'PROGRAMCONTROL':
                            continue
                        if obj_upper == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if obj_upper == 'AIRFLOW MODEL':
                            continue
                        if obj_upper == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if obj_upper == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if obj_upper == 'WATER HEATER:SIMPLE':
                            dif_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted')
                            continue

                        if general.FindItemInList(obj_name, data_version.ObjectDef.Name, data_version.NumObjectDefs) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = v_compare.GetObjectDefInIDD(obj_name)
                            num_alphas = data_version.IDFRecords[num].NumAlphas
                            num_numbers = data_version.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                data_version.Alphas[i] = data_version.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                data_version.Numbers[i] = data_version.IDFRecords[num].Numbers[i]
                            cur_args = num_alphas + num_numbers
                            data_version.InArgs = [''] * data_version.MaxTotalArgs
                            data_version.OutArgs = [''] * data_version.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    data_version.InArgs[arg] = data_version.Alphas[na]
                                    na += 1
                                else:
                                    data_version.InArgs[arg] = str(data_version.Numbers[nn])
                                    nn += 1
                        else:
                            data_version.Auditf.write('Object="' + obj_name + '" does not seem to be on the "old" IDD.\n')
                            data_version.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            data_version.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = data_version.IDFRecords[num].NumAlphas
                            num_numbers = data_version.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                data_version.Alphas[i] = data_version.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                data_version.Numbers[i] = data_version.IDFRecords[num].Numbers[i]
                            for arg in range(num_alphas):
                                data_version.OutArgs[arg] = data_version.Alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                data_version.OutArgs[nn] = str(data_version.Numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            data_version.NwFldNames = [''] * data_version.MaxTotalArgs
                            data_version.NwFldUnits = [''] * data_version.MaxTotalArgs
                            v_compare.WriteOutIDFLinesAsComments(dif_lfn, obj_name, cur_args, data_version.OutArgs, data_version.NwFldNames, data_version.NwFldUnits)
                            continue

                        nodiff = True
                        diff_min_fields = False
                        written = False

                        if general.FindItemInList(general.MakeUPPERCase(obj_name), data_version.NotInNew, len(data_version.NotInNew)) == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False

                        if not data_version.MakingPretty:
                            obj_upper = general.MakeUPPERCase(data_version.IDFRecords[num].Name.rstrip())

                            if obj_upper == 'VERSION':
                                if data_version.InArgs[0][:3] == data_version.sVersionNum and arg_file:
                                    data_globals.ShowWarningError('File is already at latest version.  No new diff file made.', data_version.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                data_version.OutArgs[0] = data_version.sVersionNum
                                nodiff = False

                            elif obj_upper in ['COIL:COOLING:DX:MULTISPEED', 'COIL:HEATING:DX:MULTISPEED']:
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                if general.SameString(data_version.InArgs[15], ''):
                                    data_version.OutArgs[15] = 'NaturalGas'
                                elif general.SameString(data_version.InArgs[15], 'PropaneGas'):
                                    data_version.OutArgs[15] = 'Propane'

                            elif obj_upper == 'COOLINGTOWER:SINGLESPEED':
                                obj_name = 'CoolingTower:SingleSpeed'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(16):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                for i in range(16, 20):
                                    data_version.OutArgs[i] = ''
                                for i in range(20, cur_args + 4):
                                    data_version.OutArgs[i] = data_version.InArgs[i - 4]
                                cur_args = cur_args + 4

                            elif obj_upper == 'COOLINGTOWER:TWOSPEED':
                                obj_name = 'CoolingTower:TwoSpeed'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(24):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                for i in range(24, 28):
                                    data_version.OutArgs[i] = ''
                                for i in range(28, cur_args + 4):
                                    data_version.OutArgs[i] = data_version.InArgs[i - 4]
                                cur_args = cur_args + 4

                            elif obj_upper == 'COOLINGTOWER:VARIABLESPEED:MERKEL':
                                obj_name = 'CoolingTower:VariableSpeed:Merkel'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(24):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                for i in range(24, 28):
                                    data_version.OutArgs[i] = ''
                                for i in range(28, cur_args + 4):
                                    data_version.OutArgs[i] = data_version.InArgs[i - 4]
                                cur_args = cur_args + 4

                            elif obj_upper == 'AIRFLOWNETWORK:SIMULATIONCONTROL':
                                obj_name = 'AirflowNetwork:SimulationControl'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(3):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                for i in range(3, cur_args - 1):
                                    data_version.OutArgs[i] = data_version.InArgs[i + 2]
                                cur_args = cur_args - 1

                            elif obj_upper == 'ZONECAPACITANCEMULTIPLIER:RESEARCHSPECIAL':
                                obj_name = 'ZoneCapacitanceMultiplier:ResearchSpecial'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                data_version.OutArgs[0] = 'Multiplier'
                                data_version.OutArgs[1] = ''
                                for i in range(cur_args):
                                    data_version.OutArgs[i + 2] = data_version.InArgs[i]
                                cur_args = cur_args + 2

                            elif obj_upper == 'WATERHEATER:HEATPUMP:WRAPPEDCONDENSER':
                                obj_name = 'WaterHeater:HeatPump:WrappedCondenser'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                if general.SameString(data_version.InArgs[34], 'MutuallyExlcusive'):
                                    data_version.OutArgs[34] = 'MutuallyExclusive'

                            elif obj_upper == 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT:DUCT':
                                obj_name = 'AirflowNetwork:Distribution:Component:Duct'
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = False
                                for i in range(6):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                afn_duct_u_val = float(data_version.InArgs[6])
                                data_version.OutArgs[6] = f'{afn_duct_u_val / 0.815384615:.6f}'
                                data_version.OutArgs[7] = data_version.InArgs[7]
                                data_version.OutArgs[8] = f'{afn_duct_u_val / 0.153846154:.6f}'
                                data_version.OutArgs[9] = f'{afn_duct_u_val / 0.030769231:.6f}'
                                cur_args = cur_args + 2

                            elif obj_upper == 'OUTPUT:VARIABLE':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                if data_version.OutArgs[0] == '':
                                    data_version.OutArgs[0] = '*'
                                    nodiff = False
                                del_this = False
                                v_compare.ScanOutputVariablesForReplacement(2, del_this, check_rvi, nodiff, obj_name, dif_lfn,
                                                                             True, False, False, cur_args, written, False)
                                if del_this:
                                    continue

                            elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                del_this = False
                                v_compare.ScanOutputVariablesForReplacement(1, del_this, check_rvi, nodiff, obj_name, dif_lfn,
                                                                             False, True, False, cur_args, written, False)
                                if del_this:
                                    continue

                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                if data_version.OutArgs[0] == '':
                                    data_version.OutArgs[0] = '*'
                                    nodiff = False
                                del_this = False
                                v_compare.ScanOutputVariablesForReplacement(2, del_this, check_rvi, nodiff, obj_name, dif_lfn,
                                                                             False, False, True, cur_args, written, False)
                                if del_this:
                                    continue

                            elif obj_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                if data_version.OutArgs[0] == '':
                                    data_version.OutArgs[0] = '*'
                                    nodiff = False
                                del_this = False
                                v_compare.ScanOutputVariablesForReplacement(2, del_this, check_rvi, nodiff, obj_name, dif_lfn,
                                                                             False, False, False, cur_args, written, False)
                                if del_this:
                                    continue

                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                del_this = False
                                v_compare.ScanOutputVariablesForReplacement(3, del_this, check_rvi, nodiff, obj_name, dif_lfn,
                                                                             False, False, False, cur_args, written, True)
                                if del_this:
                                    continue

                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                nodiff = True
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]

                                cur_var = 2
                                var_idx = 2
                                while var_idx < cur_args:
                                    uc_rep_var_name = general.MakeUPPERCase(data_version.InArgs[var_idx])
                                    data_version.OutArgs[cur_var] = data_version.InArgs[var_idx]
                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        data_version.OutArgs[cur_var] = data_version.InArgs[var_idx][:pos]
                                        data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]

                                    del_this = False
                                    for arg in range(data_version.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_version.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name.rstrip()[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1

                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if data_version.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg] != '' and not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not data_version.OTMVarCaution[arg]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Output Table Monthly (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Output Table Monthly (new)="' +
                                                                                          data_version.NewRepVarName[arg].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.OTMVarCaution[arg] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 1]:
                                                if not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1]
                                                    else:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if data_version.NewRepVarCaution[arg + 1] != '':
                                                        if not data_version.OTMVarCaution[arg + 1]:
                                                            v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                              'Output Table Monthly (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                              '" conversion to Output Table Monthly (new)="' +
                                                                                              data_version.NewRepVarName[arg + 1].rstrip() +
                                                                                              '" has the following caution "' + data_version.NewRepVarCaution[arg + 1].rstrip() + '".')
                                                            dif_file.write('\n')
                                                            data_version.OTMVarCaution[arg + 1] = True
                                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                    nodiff = False
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg + 2] != '':
                                                    if not data_version.OTMVarCaution[arg + 2]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Output Table Monthly (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Output Table Monthly (new)="' +
                                                                                          data_version.NewRepVarName[arg + 2].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg + 2].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.OTMVarCaution[arg + 2] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var_idx += 2
                                cur_args = cur_var

                            elif obj_upper == 'METER:CUSTOM':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                cur_var = 3
                                var_idx = 3
                                while var_idx < cur_args:
                                    uc_rep_var_name = general.MakeUPPERCase(data_version.InArgs[var_idx])
                                    data_version.OutArgs[cur_var] = data_version.InArgs[var_idx]
                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        data_version.OutArgs[cur_var] = data_version.InArgs[var_idx][:pos]
                                        data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]

                                    del_this = False
                                    for arg in range(data_version.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_version.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name.rstrip()[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1

                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if data_version.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg] != '' and not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not data_version.CMtrVarCaution[arg]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Custom Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Custom Meter (new)="' +
                                                                                          data_version.NewRepVarName[arg].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.CMtrVarCaution[arg] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 1]:
                                                if not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1]
                                                    else:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if data_version.NewRepVarCaution[arg + 1] != '' and not general.SameString(data_version.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not data_version.CMtrVarCaution[arg + 1]:
                                                            v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                              'Custom Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                              '" conversion to Custom Meter (new)="' +
                                                                                              data_version.NewRepVarName[arg + 1].rstrip() +
                                                                                              '" has the following caution "' + data_version.NewRepVarCaution[arg + 1].rstrip() + '".')
                                                            dif_file.write('\n')
                                                            data_version.CMtrVarCaution[arg + 1] = True
                                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                    nodiff = False
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg + 2] != '':
                                                    if not data_version.CMtrVarCaution[arg + 2]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Custom Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Custom Meter (new)="' +
                                                                                          data_version.NewRepVarName[arg + 2].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg + 2].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.CMtrVarCaution[arg + 2] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var_idx += 2
                                cur_args = cur_var
                                arg = cur_var
                                while arg >= 1:
                                    if data_version.OutArgs[arg - 1] == '':
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1

                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                for i in range(cur_args):
                                    data_version.OutArgs[i] = data_version.InArgs[i]
                                nodiff = True
                                cur_var = 3
                                var_idx = 3
                                while var_idx < cur_args:
                                    uc_rep_var_name = general.MakeUPPERCase(data_version.InArgs[var_idx])
                                    data_version.OutArgs[cur_var] = data_version.InArgs[var_idx]
                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        data_version.OutArgs[cur_var] = data_version.InArgs[var_idx][:pos]
                                        data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]

                                    del_this = False
                                    for arg in range(data_version.NumRepVarNames):
                                        uc_comp_rep_var_name = general.MakeUPPERCase(data_version.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name.rstrip()[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + ' '
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1

                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if data_version.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg] != '' and not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not data_version.CMtrDVarCaution[arg]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Custom Decrement Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Custom Meter (new)="' +
                                                                                          data_version.NewRepVarName[arg].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.CMtrDVarCaution[arg] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 1]:
                                                if not general.SameString(data_version.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1]
                                                    else:
                                                        data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 1].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if data_version.NewRepVarCaution[arg + 1] != '' and not general.SameString(data_version.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                        if not data_version.CMtrDVarCaution[arg + 1]:
                                                            v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                              'Custom Decrement Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                              '" conversion to Custom Decrement Meter (new)="' +
                                                                                              data_version.NewRepVarName[arg + 1].rstrip() +
                                                                                              '" has the following caution "' + data_version.NewRepVarCaution[arg + 1].rstrip() + '".')
                                                            dif_file.write('\n')
                                                            data_version.CMtrDVarCaution[arg + 1] = True
                                                    data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                    nodiff = False
                                            if data_version.OldRepVarName[arg] == data_version.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2]
                                                else:
                                                    data_version.OutArgs[cur_var] = data_version.NewRepVarName[arg + 2].rstrip() + data_version.OutArgs[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_version.NewRepVarCaution[arg + 2] != '':
                                                    if not data_version.CMtrDVarCaution[arg + 2]:
                                                        v_compare.writePreprocessorObject(dif_lfn, data_string.ProgNameConversion, 'Warning',
                                                                                          'Custom Decrement Meter (old)="' + data_version.OldRepVarName[arg].rstrip() +
                                                                                          '" conversion to Custom Meter (new)="' +
                                                                                          data_version.NewRepVarName[arg + 2].rstrip() +
                                                                                          '" has the following caution "' + data_version.NewRepVarCaution[arg + 2].rstrip() + '".')
                                                        dif_file.write('\n')
                                                        data_version.CMtrDVarCaution[arg + 2] = True
                                                data_version.OutArgs[cur_var + 1] = data_version.InArgs[var_idx + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var_idx += 2
                                cur_args = cur_var
                                arg = cur_var
                                while arg >= 1:
                                    if data_version.OutArgs[arg - 1] == '':
                                        cur_args -= 1
                                    else:
                                        break
                                    arg -= 1

                            else:
                                if general.FindItemInList(obj_name, data_version.NotInNew, len(data_version.NotInNew)) != 0:
                                    data_version.Auditf.write('Object="' + obj_name + '" is not in the "new" IDD.\n')
                                    data_version.Auditf.write('... will be listed as comments on the new output file.\n')
                                    v_compare.WriteOutIDFLinesAsComments(dif_lfn, obj_name, cur_args, data_version.InArgs, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                                    for i in range(cur_args):
                                        data_version.OutArgs[i] = data_version.InArgs[i]
                                    nodiff = True

                        else:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(data_version.IDFRecords[num].Name)
                            for i in range(cur_args):
                                data_version.OutArgs[i] = data_version.InArgs[i]

                        if diff_min_fields and nodiff:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                            for i in range(cur_args):
                                data_version.OutArgs[i] = data_version.InArgs[i]
                            nodiff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                data_version.OutArgs[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)

                        if nodiff and diff_only:
                            continue

                        if not written:
                            v_compare.CheckSpecialObjects(dif_lfn, obj_name, cur_args, data_version.OutArgs,
                                                         nw_fld_names, nw_fld_units, written)

                        if not written:
                            v_compare.WriteOutIDFLines(dif_lfn, obj_name, cur_args, data_version.OutArgs,
                                                      nw_fld_names, nw_fld_units)

                    if data_version.IDFRecords[data_version.NumIDFRecords - 1].CommtE != data_version.CurComment:
                        for xcount in range(data_version.IDFRecords[data_version.NumIDFRecords - 1].CommtE + 1, data_version.CurComment + 1):
                            dif_file.write(data_version.Comments[xcount].rstrip() + '\n')
                            if xcount == data_version.IDFRecords[data_version.NumIDFRecords - 1].CommtE:
                                dif_file.write('\n')

                    if v_compare.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        obj_name = 'Output:VariableDictionary'
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = v_compare.GetNewObjectDefInIDD(obj_name)
                        nodiff = False
                        data_version.OutArgs[0] = 'Regular'
                        cur_args = 1
                        v_compare.WriteOutIDFLines(dif_lfn, obj_name, cur_args, data_version.OutArgs, nw_fld_names, nw_fld_units)

                    import os
                    file_exist = os.path.exists(file_name_path + '.rvi')

                    dif_file.close()
                    v_compare.ProcessRviMviFiles(file_name_path, 'rvi')
                    v_compare.ProcessRviMviFiles(file_name_path, 'mvi')
                    v_compare.CloseOut()

                else:
                    v_compare.ProcessRviMviFiles(file_name_path, 'rvi')
                    v_compare.ProcessRviMviFiles(file_name_path, 'mvi')

            else:
                end_of_file[0] = True

            created_output_name = v_compare.CreateNewName('Reallocate', '', ' ')

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
        v_compare.copyfile(file_name_path + '.' + arg_idf_extension,
                          file_name_path + '.' + arg_idf_extension + 'old', [err_flag])
        v_compare.copyfile(file_name_path + '.' + arg_idf_extension + 'new',
                          file_name_path + '.' + arg_idf_extension, [err_flag])
        import os
        if os.path.exists(file_name_path + '.rvi'):
            v_compare.copyfile(file_name_path + '.rvi',
                              file_name_path + '.rviold', [err_flag])
        if os.path.exists(file_name_path + '.rvinew'):
            v_compare.copyfile(file_name_path + '.rvinew',
                              file_name_path + '.rvi', [err_flag])
        if os.path.exists(file_name_path + '.mvi'):
            v_compare.copyfile(file_name_path + '.mvi',
                              file_name_path + '.mviold', [err_flag])
        if os.path.exists(file_name_path + '.mvinew'):
            v_compare.copyfile(file_name_path + '.mvinew',
                              file_name_path + '.mvi', [err_flag])
