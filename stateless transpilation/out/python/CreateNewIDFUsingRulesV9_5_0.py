from typing import Protocol, Optional, List, Dict, Tuple, Any
from dataclasses import dataclass, field

# EXTERNAL DEPS (to wire in glue):
# - IDFData: holds IDFRecords, Comments, NumIDFRecords, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - ObjectDefData: holds ObjectDef, NumObjectDefs
# - FieldData: holds Alphas, Numbers, InArgs, OutArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits
# - NewFieldData: holds NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits
# - ReportVarData: holds NumRepVarNames, OldRepVarName, NewRepVarName, NewRepVarCaution
# - CautionTracking: holds OTMVarCaution, CMtrVarCaution, CMtrDVarCaution
# - NotInNew: array of object names not in new IDD
# - GlobalFlags: holds FirstTime, ProcessingIMFFile, FatalError, MakingPretty, FullFileName, FileNamePath, FileOK, Auditf, ProgramPath
# - Callbacks: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError, DisplayString, GetNewUnitNumber, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, ProcessInput, CloseOut, CreateNewName, ProcessRviMviFiles, GetNumSectionsFound, CheckSpecialObjects, ScanOutputVariablesForReplacement, writePreprocessorObject, MakeLowerCase, MakeUPPERCase, TrimTrailZeros, SameString, copyfile

class IDFRecord(Protocol):
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str]
    Numbers: List[str]
    CommtS: int
    CommtE: int

class ObjectDef(Protocol):
    Name: List[str]

class IDFData(Protocol):
    IDFRecords: List[IDFRecord]
    Comments: List[str]
    NumIDFRecords: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int

class ObjectDefData(Protocol):
    ObjectDef: ObjectDef
    NumObjectDefs: int

class FieldData(Protocol):
    Alphas: List[str]
    Numbers: List[str]
    InArgs: List[str]
    OutArgs: List[str]
    TempArgs: List[str]
    AorN: List[bool]
    ReqFld: List[bool]
    FldNames: List[str]
    FldDefaults: List[str]
    FldUnits: List[str]
    NumAlphas: int
    NumNumbers: int
    NumArgs: int
    ObjMinFlds: int
    CurComment: int

class NewFieldData(Protocol):
    NwAorN: List[bool]
    NwReqFld: List[bool]
    NwFldNames: List[str]
    NwFldDefaults: List[str]
    NwFldUnits: List[str]
    NwNumArgs: int
    NwObjMinFlds: int

class ReportVarData(Protocol):
    NumRepVarNames: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]

class CautionTracking(Protocol):
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]

class GlobalFlags(Protocol):
    FirstTime: bool
    ProcessingIMFFile: bool
    FatalError: bool
    MakingPretty: bool
    FullFileName: str
    FileNamePath: str
    FileOK: bool
    Auditf: Any
    ProgramPath: str
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    VersionNum: float
    sVersionNum: str
    VerString: str

class Callbacks(Protocol):
    ShowMessage: callable
    ShowContinueError: callable
    ShowFatalError: callable
    ShowSevereError: callable
    ShowWarningError: callable
    DisplayString: callable
    GetNewUnitNumber: callable
    GetObjectDefInIDD: callable
    GetNewObjectDefInIDD: callable
    FindItemInList: callable
    WriteOutIDFLines: callable
    WriteOutIDFLinesAsComments: callable
    ProcessInput: callable
    CloseOut: callable
    CreateNewName: callable
    ProcessRviMviFiles: callable
    GetNumSectionsFound: callable
    CheckSpecialObjects: callable
    ScanOutputVariablesForReplacement: callable
    writePreprocessorObject: callable
    MakeLowerCase: callable
    MakeUPPERCase: callable
    TrimTrailZeros: callable
    SameString: callable
    copyfile: callable

def set_this_version_variables(flags: GlobalFlags) -> None:
    flags.VerString = 'Conversion 9.4 => 9.5'
    flags.VersionNum = 9.5
    flags.sVersionNum = '9.5'
    flags.IDDFileNameWithPath = flags.ProgramPath.rstrip() + 'V9-4-0-Energy+.idd'
    flags.NewIDDFileNameWithPath = flags.ProgramPath.rstrip() + 'V9-5-0-Energy+.idd'
    flags.RepVarFileNameWithPath = flags.ProgramPath.rstrip() + 'Report Variables 9-4-0 to 9-5-0.csv'

def create_new_idf_using_rules(
    end_of_file_ref: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    idf_data: IDFData,
    obj_def_data: ObjectDefData,
    field_data: FieldData,
    new_field_data: NewFieldData,
    report_var_data: ReportVarData,
    caution_tracking: CautionTracking,
    not_in_new: List[str],
    flags: GlobalFlags,
    callbacks: Callbacks
) -> None:
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = ' '
    end_of_file_ref[0] = False
    ios = 0

    while still_working:
        exit_because_bad_file = False
        while not end_of_file_ref[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        with open(in_lfn, 'r') as f:
                            line = f.readline()
                            if line:
                                full_file_name = line.strip()
                                ios = 0
                            else:
                                full_file_name = ''
                                ios = 1
                    except:
                        full_file_name = ''
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ''
                    ios = 1

                if full_file_name and full_file_name[0] == '!':
                    full_file_name = ''
                    continue

            units_arg = ''
            if ios != 0:
                full_file_name = ''
            full_file_name = full_file_name.lstrip()

            if full_file_name != '':
                callbacks.DisplayString('Processing IDF -- ' + full_file_name)
                callbacks.WriteOutIDFLines(flags.Auditf, ' Processing IDF -- ' + full_file_name, 0, [], [], [])

                dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = callbacks.MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    callbacks.WriteOutIDFLines(flags.Auditf, ' ..assuming file extension of .idf', 0, [], [], [])
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'

                dif_lfn = callbacks.GetNewUnitNumber()
                try:
                    with open(full_file_name, 'r') as f:
                        file_ok = True
                except:
                    file_ok = False

                if not file_ok:
                    print('File not found=' + full_file_name)
                    callbacks.WriteOutIDFLines(flags.Auditf, 'File not found=' + full_file_name, 0, [], [], [])
                    end_of_file_ref[0] = True
                    exit_because_bad_file = True
                    break

                if local_file_extension in ['idf', 'imf']:
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False

                    if diff_only:
                        out_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        out_file_name = file_name_path + '.' + local_file_extension + 'new'

                    if local_file_extension == 'imf':
                        callbacks.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', flags.Auditf)
                        flags.ProcessingIMFFile = True
                    else:
                        flags.ProcessingIMFFile = False

                    callbacks.ProcessInput(flags.IDDFileNameWithPath, flags.NewIDDFileNameWithPath, full_file_name, idf_data, flags)

                    if flags.FatalError:
                        exit_because_bad_file = True
                        break

                    for i in range(len(field_data.Alphas)):
                        field_data.Alphas[i] = ''
                    for i in range(len(field_data.Numbers)):
                        field_data.Numbers[i] = ''
                    for i in range(len(field_data.InArgs)):
                        field_data.InArgs[i] = ''
                    for i in range(len(field_data.TempArgs)):
                        field_data.TempArgs[i] = ''
                    for i in range(len(field_data.AorN)):
                        field_data.AorN[i] = False
                    for i in range(len(field_data.ReqFld)):
                        field_data.ReqFld[i] = False
                    for i in range(len(field_data.FldNames)):
                        field_data.FldNames[i] = ''
                    for i in range(len(field_data.FldDefaults)):
                        field_data.FldDefaults[i] = ''
                    for i in range(len(field_data.FldUnits)):
                        field_data.FldUnits[i] = ''
                    for i in range(len(new_field_data.NwAorN)):
                        new_field_data.NwAorN[i] = False
                    for i in range(len(new_field_data.NwReqFld)):
                        new_field_data.NwReqFld[i] = False
                    for i in range(len(new_field_data.NwFldNames)):
                        new_field_data.NwFldNames[i] = ''
                    for i in range(len(new_field_data.NwFldDefaults)):
                        new_field_data.NwFldDefaults[i] = ''
                    for i in range(len(new_field_data.NwFldUnits)):
                        new_field_data.NwFldUnits[i] = ''
                    for i in range(len(field_data.OutArgs)):
                        field_data.OutArgs[i] = ''

                    delete_this_record = [False] * idf_data.NumIDFRecords

                    no_version = True
                    for num in range(idf_data.NumIDFRecords):
                        if callbacks.MakeUPPERCase(idf_data.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break

                    for num in range(idf_data.NumIDFRecords):
                        if delete_this_record[num]:
                            with open(out_file_name, 'a') as f:
                                f.write('! Deleting: ' + idf_data.IDFRecords[num].Name + '="' + idf_data.IDFRecords[num].Alphas[0] + '".\n')

                    callbacks.DisplayString('Processing IDF -- Processing idf objects . . .')

                    wwhp_eq_ft_cool_index = 0
                    wwhp_eq_ft_heat_index = 0
                    wahp_eq_ft_cool_index = 0
                    wahp_eq_ft_heat_index = 0

                    for num in range(idf_data.NumIDFRecords):
                        if delete_this_record[num]:
                            continue

                        for xcount in range(idf_data.IDFRecords[num].CommtS, idf_data.IDFRecords[num].CommtE + 1):
                            with open(out_file_name, 'a') as f:
                                f.write(idf_data.Comments[xcount].rstrip() + '\n')
                            if xcount == idf_data.IDFRecords[num].CommtE:
                                with open(out_file_name, 'a') as f:
                                    f.write('\n')

                        if no_version and num == 0:
                            callbacks.GetNewObjectDefInIDD('VERSION', new_field_data, flags, callbacks)
                            field_data.OutArgs[0] = flags.sVersionNum
                            cur_args = 1
                            callbacks.ShowWarningError('No version found in file, defaulting to ' + flags.sVersionNum, flags.Auditf)
                            callbacks.WriteOutIDFLinesAsComments(out_file_name, 'Version', cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                        object_name = idf_data.IDFRecords[num].Name
                        obj_index = callbacks.FindItemInList(object_name, obj_def_data.ObjectDef.Name, obj_def_data.NumObjectDefs)

                        if obj_index >= 0:
                            callbacks.GetObjectDefInIDD(object_name, field_data, flags, callbacks)
                            field_data.NumAlphas = idf_data.IDFRecords[num].NumAlphas
                            field_data.NumNumbers = idf_data.IDFRecords[num].NumNumbers
                            for i in range(field_data.NumAlphas):
                                field_data.Alphas[i] = idf_data.IDFRecords[num].Alphas[i]
                            for i in range(field_data.NumNumbers):
                                field_data.Numbers[i] = idf_data.IDFRecords[num].Numbers[i]
                            cur_args = field_data.NumAlphas + field_data.NumNumbers
                            for i in range(len(field_data.InArgs)):
                                field_data.InArgs[i] = ''
                            for i in range(len(field_data.OutArgs)):
                                field_data.OutArgs[i] = ''
                            for i in range(len(field_data.TempArgs)):
                                field_data.TempArgs[i] = ''
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if field_data.AorN[arg]:
                                    field_data.InArgs[arg] = field_data.Alphas[na]
                                    na += 1
                                else:
                                    field_data.InArgs[arg] = str(field_data.Numbers[nn])
                                    nn += 1
                        else:
                            with open(flags.Auditf, 'a') as f:
                                f.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                                f.write('... will be listed as comments (no field names) on the new output file.\n')
                                f.write('... Alpha fields will be listed first, then numerics.\n')
                            field_data.NumAlphas = idf_data.IDFRecords[num].NumAlphas
                            field_data.NumNumbers = idf_data.IDFRecords[num].NumNumbers
                            for i in range(field_data.NumAlphas):
                                field_data.Alphas[i] = idf_data.IDFRecords[num].Alphas[i]
                            for i in range(field_data.NumNumbers):
                                field_data.Numbers[i] = idf_data.IDFRecords[num].Numbers[i]
                            for arg in range(field_data.NumAlphas):
                                field_data.OutArgs[arg] = field_data.Alphas[arg]
                            nn = field_data.NumAlphas
                            for arg in range(field_data.NumNumbers):
                                field_data.OutArgs[nn] = str(field_data.Numbers[arg])
                                nn += 1
                            cur_args = field_data.NumAlphas + field_data.NumNumbers
                            for i in range(len(new_field_data.NwFldNames)):
                                new_field_data.NwFldNames[i] = ''
                            for i in range(len(new_field_data.NwFldUnits)):
                                new_field_data.NwFldUnits[i] = ''
                            callbacks.WriteOutIDFLinesAsComments(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                            continue

                        no_diff = True
                        diff_min_fields = False
                        written = False

                        if callbacks.FindItemInList(callbacks.MakeUPPERCase(object_name), not_in_new, len(not_in_new)) == -1:
                            callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                            if field_data.ObjMinFlds != new_field_data.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False

                        if not flags.MakingPretty:
                            upper_name = callbacks.MakeUPPERCase(object_name.strip())

                            if upper_name == 'VERSION':
                                if field_data.InArgs[0][:3] == flags.sVersionNum and arg_file:
                                    callbacks.ShowWarningError('File is already at latest version.  No new diff file made.', flags.Auditf)
                                    latest_version = True
                                    break
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = flags.sVersionNum
                                no_diff = False

                            elif upper_name == 'CONSTRUCTION:AIRBOUNDARY':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                for i in range(cur_args - 2):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 3]
                                cur_args = cur_args - 2
                                if field_data.InArgs[1] == "InteriorWindow":
                                    callbacks.ShowWarningError('Construction:AirBoundary=' + field_data.InArgs[0] + ' Solar and Daylighting Method option InteriorWindow is no longer valid.', flags.Auditf)
                                    callbacks.ShowContinueError('The air boundary will be modeled using the GroupedZones method.', flags.Auditf)
                                    callbacks.writePreprocessorObject(out_file_name, flags.ProgNameConversion, 'Warning', 'Construction:AirBoundary=' + field_data.InArgs[0] + ' Solar and Daylighting Method option InteriorWindow is no longer valid. The air boundary will be modeled using the GroupedZones method.', callbacks)
                                if field_data.InArgs[2] == "IRTSurface":
                                    callbacks.ShowWarningError('Construction:AirBoundary=' + field_data.InArgs[0] + ' Radiant Exchange Method option IRTSurface is no longer valid.', flags.Auditf)
                                    callbacks.ShowContinueError('The air boundary will be modeled using the GroupedZones method.', flags.Auditf)
                                    callbacks.writePreprocessorObject(out_file_name, flags.ProgNameConversion, 'Warning', 'Construction:AirBoundary=' + field_data.InArgs[0] + ' Radiant Exchange Method option IRTSurface is no longer valid. The air boundary will be modeled using the GroupedZones method.', callbacks)

                            elif upper_name == 'COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                for i in range(10):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                for i in range(cur_args - 13):
                                    field_data.OutArgs[i + 13] = field_data.InArgs[i + 26]
                                wahp_eq_ft_cool_index += 1
                                field_data.OutArgs[10] = f"WAHPCoolCapCurveTot{wahp_eq_ft_cool_index:2d}".strip()
                                field_data.OutArgs[11] = f"WAHPCoolCapCurveSens{wahp_eq_ft_cool_index:2d}".strip()
                                field_data.OutArgs[12] = f"WAHPCoolPowCurve{wahp_eq_ft_cool_index:2d}".strip()
                                cur_args = cur_args - 13
                                callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WAHPCoolCapCurveTot{wahp_eq_ft_cool_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 10]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuintLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WAHPCoolCapCurveSens{wahp_eq_ft_cool_index:2d}".strip()
                                for i in range(6):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 15]
                                for i in range(8, 17, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuintLinear', 17, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WAHPCoolPowCurve{wahp_eq_ft_cool_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 21]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                                written = True

                            elif upper_name == 'COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                for i in range(9):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                wahp_eq_ft_heat_index += 1
                                field_data.OutArgs[9] = f"WAHPHeatCapCurve{wahp_eq_ft_heat_index:2d}".strip()
                                field_data.OutArgs[10] = f"WAHPHeatPowCurve{wahp_eq_ft_heat_index:2d}".strip()
                                cur_args = cur_args - 8
                                callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WAHPHeatCapCurve{wahp_eq_ft_heat_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 9]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WAHPHeatPowCurve{wahp_eq_ft_heat_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 14]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                                written = True

                            elif upper_name == 'CONSTRUCTION:INTERNALSOURCE':
                                written = True
                                callbacks.GetNewObjectDefInIDD('ConstructionProperty:InternalHeatSource', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = field_data.InArgs[0].strip() + ' Heat Source'
                                field_data.OutArgs[1] = field_data.InArgs[0]
                                for i in range(5):
                                    field_data.OutArgs[i + 2] = field_data.InArgs[i + 1]
                                if field_data.OutArgs[6] == '':
                                    field_data.OutArgs[6] = '0.0'
                                callbacks.WriteOutIDFLines(out_file_name, 'ConstructionProperty:InternalHeatSource', new_field_data.NwNumArgs, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                                callbacks.GetNewObjectDefInIDD('Construction', new_field_data, flags, callbacks)
                                new_field_data.NwNumArgs = cur_args - 5
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                for i in range(new_field_data.NwNumArgs - 1):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 6]
                                callbacks.WriteOutIDFLines(out_file_name, 'Construction', new_field_data.NwNumArgs, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                            elif upper_name == 'HEATPUMP:WATERTOWATER:EQUATIONFIT:COOLING':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                for i in range(9):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                for i in range(cur_args - 8):
                                    field_data.OutArgs[i + 11] = field_data.InArgs[i + 19]
                                wwhp_eq_ft_cool_index += 1
                                field_data.OutArgs[9] = f"WWHPCoolCapCurve{wwhp_eq_ft_cool_index:2d}".strip()
                                field_data.OutArgs[10] = f"WWHPCoolPowCurve{wwhp_eq_ft_cool_index:2d}".strip()
                                cur_args = cur_args - 8
                                callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WWHPCoolCapCurve{wwhp_eq_ft_cool_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 9]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WWHPCoolPowCurve{wwhp_eq_ft_cool_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 14]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', 14, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                                written = True

                            elif upper_name == 'HEATPUMP:WATERTOWATER:EQUATIONFIT:HEATING':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                for i in range(9):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                for i in range(cur_args - 8):
                                    field_data.OutArgs[i + 11] = field_data.InArgs[i + 19]
                                wwhp_eq_ft_heat_index += 1
                                field_data.OutArgs[9] = f"WWHPHeatCapCurve{wwhp_eq_ft_heat_index:2d}".strip()
                                field_data.OutArgs[10] = f"WWHPHeatPowCurve{wwhp_eq_ft_heat_index:2d}".strip()
                                cur_args = cur_args - 8
                                callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WWHPHeatCapCurve{wwhp_eq_ft_heat_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 9]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                cur_args_inner = 14
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', cur_args_inner, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                                callbacks.GetNewObjectDefInIDD('Curve:QuadLinear', new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = f"WWHPHeatPowCurve{wwhp_eq_ft_heat_index:2d}".strip()
                                for i in range(5):
                                    field_data.OutArgs[i + 1] = field_data.InArgs[i + 14]
                                for i in range(7, 14, 2):
                                    field_data.OutArgs[i] = "-100"
                                    field_data.OutArgs[i + 1] = "100"
                                cur_args_inner = 14
                                callbacks.WriteOutIDFLines(out_file_name, 'Curve:QuadLinear', cur_args_inner, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)
                                written = True

                            elif upper_name == 'ZONEAIRMASSFLOWCONSERVATION':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = False
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                if field_data.OutArgs[0] in ["YES", "Yes", "yes"]:
                                    field_data.OutArgs[0] = "AdjustMixingOnly"
                                if field_data.OutArgs[0] in ["NO", "No", "no"]:
                                    field_data.OutArgs[0] = "None"

                            elif upper_name == 'ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                field_data.OutArgs[1] = field_data.InArgs[0].strip() + ' Design Object'
                                for i in range(3):
                                    field_data.OutArgs[i + 2] = field_data.InArgs[i + 1]
                                field_data.OutArgs[5] = field_data.InArgs[7]
                                field_data.OutArgs[6] = field_data.InArgs[12]
                                for i in range(3):
                                    field_data.OutArgs[i + 7] = field_data.InArgs[i + 15]
                                field_data.OutArgs[10] = field_data.InArgs[21]
                                for i in range(3):
                                    field_data.OutArgs[i + 11] = field_data.InArgs[i + 24]
                                for i in range(2):
                                    field_data.OutArgs[i + 14] = field_data.InArgs[i + 31]
                                cur_args = 16

                                callbacks.GetNewObjectDefInIDD('ZoneHVAC:LowTemperatureRadiant:VariableFlow:Design', field_data, flags, callbacks)
                                p_out_args = [''] * 20
                                p_out_args[0] = field_data.OutArgs[1]
                                for i in range(3):
                                    p_out_args[i + 1] = field_data.InArgs[i + 4]
                                for i in range(4):
                                    p_out_args[i + 4] = field_data.InArgs[i + 8]
                                for i in range(2):
                                    p_out_args[i + 8] = field_data.InArgs[i + 13]
                                for i in range(3):
                                    p_out_args[i + 10] = field_data.InArgs[i + 18]
                                for i in range(2):
                                    p_out_args[i + 13] = field_data.InArgs[i + 22]
                                for i in range(4):
                                    p_out_args[i + 15] = field_data.InArgs[i + 27]
                                cur_var_iterator = 19
                                if field_data.InArgs[33] != '':
                                    p_out_args[19] = field_data.InArgs[33]
                                    cur_var_iterator = 20
                                callbacks.WriteOutIDFLines(out_file_name, 'ZoneHVAC:LowTemperatureRadiant:VariableFlow:Design', cur_var_iterator, p_out_args, field_data.FldNames, field_data.FldUnits, callbacks)
                                no_diff = False

                            elif upper_name == 'ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                field_data.OutArgs[1] = field_data.InArgs[0].strip() + ' Design Object'
                                for i in range(3):
                                    field_data.OutArgs[i + 2] = field_data.InArgs[i + 1]
                                field_data.OutArgs[5] = field_data.InArgs[7]
                                for i in range(4):
                                    field_data.OutArgs[i + 6] = field_data.InArgs[i + 11]
                                for i in range(12):
                                    field_data.OutArgs[i + 10] = field_data.InArgs[i + 17]
                                for i in range(2):
                                    field_data.OutArgs[i + 22] = field_data.InArgs[i + 31]
                                cur_args = 24

                                callbacks.GetNewObjectDefInIDD('ZoneHVAC:LowTemperatureRadiant:ConstantFlow:Design', field_data, flags, callbacks)
                                p_out_args = [''] * 12
                                p_out_args[0] = field_data.OutArgs[1]
                                for i in range(3):
                                    p_out_args[i + 1] = field_data.InArgs[i + 4]
                                for i in range(3):
                                    p_out_args[i + 4] = field_data.InArgs[i + 8]
                                for i in range(2):
                                    p_out_args[i + 7] = field_data.InArgs[i + 15]
                                for i in range(2):
                                    p_out_args[i + 9] = field_data.InArgs[i + 29]
                                cur_var_iterator = 11
                                if field_data.InArgs[33] != '':
                                    p_out_args[11] = field_data.InArgs[33]
                                    cur_var_iterator = 12
                                callbacks.WriteOutIDFLines(out_file_name, 'ZoneHVAC:LowTemperatureRadiant:ConstantFlow:Design', cur_var_iterator, p_out_args, field_data.FldNames, field_data.FldUnits, callbacks)
                                no_diff = False

                            elif upper_name == 'ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                field_data.OutArgs[1] = field_data.InArgs[0].strip() + ' Design Object'
                                for i in range(5):
                                    field_data.OutArgs[i + 2] = field_data.InArgs[i + 1]
                                field_data.OutArgs[7] = field_data.InArgs[7]
                                field_data.OutArgs[8] = field_data.InArgs[10]
                                if cur_args > 14:
                                    for i in range(cur_args - 14):
                                        field_data.OutArgs[i + 9] = field_data.InArgs[i + 14]
                                    cur_args = cur_args - 5
                                else:
                                    cur_args = 9

                                callbacks.GetNewObjectDefInIDD('ZoneHVAC:Baseboard:RadiantConvective:Water:Design', field_data, flags, callbacks)
                                p_out_args = [''] * 7
                                p_out_args[0] = field_data.OutArgs[1]
                                p_out_args[1] = field_data.InArgs[6]
                                for i in range(2):
                                    p_out_args[i + 2] = field_data.InArgs[i + 8]
                                for i in range(3):
                                    p_out_args[i + 4] = field_data.InArgs[i + 11]
                                callbacks.WriteOutIDFLines(out_file_name, 'ZoneHVAC:Baseboard:RadiantConvective:Water:Design', 7, p_out_args, field_data.FldNames, field_data.FldUnits, callbacks)
                                no_diff = False

                            elif upper_name == 'ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                field_data.OutArgs[0] = field_data.InArgs[0]
                                field_data.OutArgs[1] = field_data.InArgs[0].strip() + ' Design Object'
                                for i in range(3):
                                    field_data.OutArgs[i + 2] = field_data.InArgs[i + 1]
                                field_data.OutArgs[5] = field_data.InArgs[5]
                                for i in range(2):
                                    field_data.OutArgs[i + 6] = field_data.InArgs[i + 8]
                                if cur_args > 13:
                                    for i in range(cur_args - 13):
                                        field_data.OutArgs[i + 8] = field_data.InArgs[i + 13]
                                    cur_args = cur_args - 5
                                else:
                                    cur_args = 8

                                callbacks.GetNewObjectDefInIDD('ZoneHVAC:Baseboard:RadiantConvective:Steam:Design', field_data, flags, callbacks)
                                p_out_args = [''] * 7
                                p_out_args[0] = field_data.OutArgs[1]
                                p_out_args[1] = field_data.InArgs[4]
                                for i in range(2):
                                    p_out_args[i + 2] = field_data.InArgs[i + 6]
                                for i in range(3):
                                    p_out_args[i + 4] = field_data.InArgs[i + 10]
                                callbacks.WriteOutIDFLines(out_file_name, 'ZoneHVAC:Baseboard:RadiantConvective:Steam:Design', 7, p_out_args, field_data.FldNames, field_data.FldUnits, callbacks)
                                no_diff = False

                            elif upper_name == 'OUTPUT:VARIABLE':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                if field_data.OutArgs[0] == '':
                                    field_data.OutArgs[0] = '*'
                                    no_diff = False
                                callbacks.ScanOutputVariablesForReplacement(2, field_data, object_name, out_file_name, False, True, False, cur_args, written, False, callbacks, caution_tracking)
                                if field_data.OutArgs[0] == '<DELETE>':
                                    continue

                            elif upper_name in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                callbacks.ScanOutputVariablesForReplacement(1, field_data, object_name, out_file_name, False, False, True, cur_args, written, False, callbacks, caution_tracking)

                            elif upper_name == 'OUTPUT:TABLE:TIMEBINS':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                if field_data.OutArgs[0] == '':
                                    field_data.OutArgs[0] = '*'
                                    no_diff = False
                                callbacks.ScanOutputVariablesForReplacement(2, field_data, object_name, out_file_name, False, False, True, cur_args, written, False, callbacks, caution_tracking)

                            elif upper_name in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                if field_data.OutArgs[0] == '':
                                    field_data.OutArgs[0] = '*'
                                    no_diff = False
                                callbacks.ScanOutputVariablesForReplacement(2, field_data, object_name, out_file_name, False, False, False, cur_args, written, False, callbacks, caution_tracking)

                            elif upper_name == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                callbacks.ScanOutputVariablesForReplacement(3, field_data, object_name, out_file_name, False, False, False, cur_args, written, True, callbacks, caution_tracking)

                            elif upper_name == 'OUTPUT:TABLE:MONTHLY':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                no_diff = True
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                cur_var = 3
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = callbacks.MakeUPPERCase(field_data.InArgs[var])
                                    field_data.OutArgs[cur_var] = field_data.InArgs[var]
                                    field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        field_data.OutArgs[cur_var] = field_data.InArgs[var][:pos]
                                        field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                    del_this = False
                                    for arg in range(report_var_data.NumRepVarNames):
                                        uc_comp_rep_var_name = callbacks.MakeUPPERCase(report_var_data.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            wild_match = False
                                            pos = 1 if uc_rep_var_name == uc_comp_rep_var_name else 0
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if report_var_data.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    field_data.OutArgs[cur_var] = report_var_data.NewRepVarName[arg]
                                                else:
                                                    field_data.OutArgs[cur_var] = report_var_data.NewRepVarName[arg] + field_data.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if report_var_data.NewRepVarCaution[arg] != '' and not callbacks.SameString(report_var_data.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not caution_tracking.OTMVarCaution[arg]:
                                                        callbacks.writePreprocessorObject(out_file_name, flags.ProgNameConversion, 'Warning', 'Output Table Monthly (old)="' + report_var_data.OldRepVarName[arg] + '" conversion to Output Table Monthly (new)="' + report_var_data.NewRepVarName[arg] + '" has the following caution "' + report_var_data.NewRepVarCaution[arg] + '".', callbacks)
                                                        with open(out_file_name, 'a') as f:
                                                            f.write(' \n')
                                                        caution_tracking.OTMVarCaution[arg] = True
                                                field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var - 1

                            elif upper_name == 'METER:CUSTOM' or upper_name == 'METER:CUSTOMDECREMENT':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = callbacks.MakeUPPERCase(field_data.InArgs[var])
                                    field_data.OutArgs[cur_var] = field_data.InArgs[var]
                                    field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        field_data.OutArgs[cur_var] = field_data.InArgs[var][:pos]
                                        field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                    del_this = False
                                    for arg in range(report_var_data.NumRepVarNames):
                                        uc_comp_rep_var_name = callbacks.MakeUPPERCase(report_var_data.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        else:
                                            wild_match = False
                                            pos = 1 if uc_rep_var_name == uc_comp_rep_var_name else 0
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            caution_dict = caution_tracking.CMtrVarCaution if upper_name == 'METER:CUSTOM' else caution_tracking.CMtrDVarCaution
                                            if report_var_data.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    field_data.OutArgs[cur_var] = report_var_data.NewRepVarName[arg]
                                                else:
                                                    field_data.OutArgs[cur_var] = report_var_data.NewRepVarName[arg] + field_data.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if report_var_data.NewRepVarCaution[arg] != '' and not callbacks.SameString(report_var_data.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                    if not caution_dict[arg]:
                                                        meter_type = 'Custom Meter' if upper_name == 'METER:CUSTOM' else 'Custom Decrement Meter'
                                                        callbacks.writePreprocessorObject(out_file_name, flags.ProgNameConversion, 'Warning', meter_type + ' (old)="' + report_var_data.OldRepVarName[arg] + '" conversion to ' + meter_type + ' (new)="' + report_var_data.NewRepVarName[arg] + '" has the following caution "' + report_var_data.NewRepVarCaution[arg] + '".', callbacks)
                                                        with open(out_file_name, 'a') as f:
                                                            f.write(' \n')
                                                        caution_dict[arg] = True
                                                field_data.OutArgs[cur_var + 1] = field_data.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if field_data.OutArgs[arg] == '':
                                        cur_args -= 1
                                    else:
                                        break

                            elif upper_name in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                callbacks.ScanOutputVariablesForReplacement(2, field_data, object_name, out_file_name, False, True, False, cur_args, written, False, callbacks, caution_tracking)

                            elif upper_name == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                for i in range(cur_args):
                                    field_data.OutArgs[i] = field_data.InArgs[i]
                                no_diff = True
                                callbacks.ScanOutputVariablesForReplacement(6, field_data, object_name, out_file_name, False, True, False, cur_args, written, False, callbacks, caution_tracking)
                                callbacks.ScanOutputVariablesForReplacement(12, field_data, object_name, out_file_name, False, True, False, cur_args, written, False, callbacks, caution_tracking)

                            else:
                                if callbacks.FindItemInList(object_name, not_in_new, len(not_in_new)) >= 0:
                                    with open(flags.Auditf, 'a') as f:
                                        f.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                        f.write('... will be listed as comments on the new output file.\n')
                                    callbacks.WriteOutIDFLinesAsComments(out_file_name, object_name, cur_args, field_data.InArgs, field_data.FldNames, field_data.FldUnits, callbacks)
                                    written = True
                                else:
                                    callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                                    for i in range(cur_args):
                                        field_data.OutArgs[i] = field_data.InArgs[i]
                                    no_diff = True

                        else:
                            callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                            for i in range(cur_args):
                                field_data.OutArgs[i] = field_data.InArgs[i]

                        if diff_min_fields and no_diff:
                            callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                            for i in range(cur_args):
                                field_data.OutArgs[i] = field_data.InArgs[i]
                            no_diff = False
                            for arg in range(cur_args, new_field_data.NwObjMinFlds):
                                field_data.OutArgs[arg] = new_field_data.NwFldDefaults[arg]
                            cur_args = max(new_field_data.NwObjMinFlds, cur_args)

                        if no_diff and diff_only:
                            continue

                        if not written:
                            callbacks.CheckSpecialObjects(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, written, callbacks)

                        if not written:
                            callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                    callbacks.DisplayString('Processing IDF -- Processing idf objects complete.')

                    if idf_data.IDFRecords[idf_data.NumIDFRecords - 1].CommtE != field_data.CurComment:
                        for xcount in range(idf_data.IDFRecords[idf_data.NumIDFRecords - 1].CommtE + 1, field_data.CurComment + 1):
                            with open(out_file_name, 'a') as f:
                                f.write(idf_data.Comments[xcount].rstrip() + '\n')
                            if xcount == idf_data.IDFRecords[idf_data.NumIDFRecords - 1].CommtE:
                                with open(out_file_name, 'a') as f:
                                    f.write('\n')

                    if callbacks.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        callbacks.GetNewObjectDefInIDD(object_name, new_field_data, flags, callbacks)
                        no_diff = False
                        field_data.OutArgs[0] = 'Regular'
                        cur_args = 1
                        callbacks.WriteOutIDFLines(out_file_name, object_name, cur_args, field_data.OutArgs, new_field_data.NwFldNames, new_field_data.NwFldUnits, callbacks)

                    callbacks.ProcessRviMviFiles(file_name_path, 'rvi', callbacks)
                    callbacks.ProcessRviMviFiles(file_name_path, 'mvi', callbacks)
                    callbacks.CloseOut(callbacks)
                else:
                    callbacks.ProcessRviMviFiles(file_name_path, 'rvi', callbacks)
                    callbacks.ProcessRviMviFiles(file_name_path, 'mvi', callbacks)
            else:
                end_of_file_ref[0] = True

            callbacks.CreateNewName('Reallocate', '', ' ', callbacks)

        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file_ref[0] = False
            else:
                end_of_file_ref[0] = True
                still_working = False

    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        callbacks.copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag, callbacks)
        callbacks.copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag, callbacks)
        try:
            with open(file_name_path + '.rvi', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            callbacks.copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag, callbacks)
        try:
            with open(file_name_path + '.rvinew', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            callbacks.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag, callbacks)
        try:
            with open(file_name_path + '.mvi', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            callbacks.copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag, callbacks)
        try:
            with open(file_name_path + '.mvinew', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            callbacks.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag, callbacks)
