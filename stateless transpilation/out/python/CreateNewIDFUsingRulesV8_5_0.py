from typing import List, Optional, Dict, Any, Protocol

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ProgNameConversion, MaxNameLength, blank, ProgramPath, Auditf
# - DataVCompareGlobals: IDFRecords, NumIDFRecords, Comments, CurComment, FullFileName, FileNamePath, FileOK, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, ObjectDef, NumObjectDefs, NotInNew, ProcessingIMFFile, FatalError, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound, FindItemInList
# - VCompareGlobalRoutines: ScanOutputVariablesForReplacement, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName, DisplayString, writePreprocessorObject
# - General: SameString, MakeUPPERCase, MakeLowerCase, TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - System: GetNewUnitNumber, copyfile

class IDFRecord(Protocol):
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str]
    Numbers: List[float]
    CommtS: int
    CommtE: int

class ObjectDefEntry(Protocol):
    Name: str

class DataVCompareGlobalsStub(Protocol):
    IDFRecords: List[Any]
    NumIDFRecords: int
    Comments: List[str]
    CurComment: int
    FullFileName: str
    FileNamePath: str
    FileOK: bool
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    NumRepVarNames: int
    ObjectDef: List[ObjectDefEntry]
    NumObjectDefs: int
    NotInNew: List[str]
    ProcessingIMFFile: bool
    FatalError: bool
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int

class DataStringGlobalsStub(Protocol):
    ProgNameConversion: str
    MaxNameLength: int
    blank: str
    ProgramPath: str
    Auditf: int

class InputProcessorStub(Protocol):
    def ProcessInput(self, old_idd: str, new_idd: str, idf_file: str) -> None: ...
    def GetObjectDefInIDD(self, obj_name: str) -> tuple: ...
    def GetNewObjectDefInIDD(self, obj_name: str) -> tuple: ...
    def GetNumSectionsFound(self, section: str) -> int: ...
    def FindItemInList(self, item: str, items: List[str], count: int) -> int: ...

class ExternalFunctionsStub(Protocol):
    def GetNewUnitNumber(self) -> int: ...
    def TrimTrailZeros(self, s: str) -> str: ...
    def SameString(self, s1: str, s2: str) -> bool: ...
    def MakeUPPERCase(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def ShowWarningError(self, msg: str, unit: int) -> None: ...
    def ShowFatalError(self, msg: str) -> None: ...
    def ScanOutputVariablesForReplacement(self, field: int, del_this: List[bool], checkrvi: List[bool], nodiff: List[bool], obj_name: str, unit: int, out_var: bool, mtr_var: bool, time_bin: bool, cur_args: int, written: List[bool], sensor: bool) -> None: ...
    def WriteOutIDFLines(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def WriteOutIDFLinesAsComments(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def CheckSpecialObjects(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str], written: List[bool]) -> None: ...
    def ProcessRviMviFiles(self, file_path: str, ext: str) -> None: ...
    def CloseOut(self) -> None: ...
    def CreateNewName(self, action: str, out_name: List[str], dummy: str) -> None: ...
    def DisplayString(self, msg: str) -> None: ...
    def writePreprocessorObject(self, unit: int, prog: str, level: str, msg: str) -> None: ...
    def copyfile(self, src: str, dst: str) -> bool: ...

def set_this_version_variables(
    data_string_globals: DataStringGlobalsStub,
    data_vcompare_globals: DataVCompareGlobalsStub,
) -> None:
    data_vcompare_globals.VerString = 'Conversion 8.4 => 8.5'
    data_vcompare_globals.VersionNum = 8.5
    data_vcompare_globals.sVersionNum = '8.5'
    data_vcompare_globals.IDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'V8-4-0-Energy+.idd'
    data_vcompare_globals.NewIDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'V8-5-0-Energy+.idd'
    data_vcompare_globals.RepVarFileNameWithPath = data_string_globals.ProgramPath.rstrip() + 'Report Variables 8-4-0 to 8-5-0.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    data_string_globals: DataStringGlobalsStub,
    data_vcompare_globals: DataVCompareGlobalsStub,
    input_processor: InputProcessorStub,
    external_functions: ExternalFunctionsStub,
) -> None:
    fmta = "(A)"
    
    first_time = True
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension if arg_idf_extension else ' '
    end_of_file[0] = False
    ios = 0
    
    max_name_length = data_string_globals.MaxNameLength
    max_alpha_args_found = data_vcompare_globals.MaxAlphaArgsFound
    max_numeric_args_found = data_vcompare_globals.MaxNumericArgsFound
    max_total_args = data_vcompare_globals.MaxTotalArgs
    blank_str = data_string_globals.blank
    
    delete_this_record = []
    alphas = [''] * (max_alpha_args_found + 1)
    numbers = [0.0] * (max_numeric_args_found + 1)
    in_args = [blank_str] * (max_total_args + 1)
    aorn = [False] * (max_total_args + 1)
    req_fld = [False] * (max_total_args + 1)
    fld_names = [''] * (max_total_args + 1)
    fld_defaults = [''] * (max_total_args + 1)
    fld_units = [''] * (max_total_args + 1)
    nwaorn = [False] * (max_total_args + 1)
    nw_req_fld = [False] * (max_total_args + 1)
    nw_fld_names = [''] * (max_total_args + 1)
    nw_fld_defaults = [''] * (max_total_args + 1)
    nw_fld_units = [''] * (max_total_args + 1)
    out_args = [blank_str] * (max_total_args + 1)
    match_arg = [False] * (max_total_args + 1)
    
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
                    full_file_name = blank_str
                    ios = 1
                
                if full_file_name.startswith('!'):
                    full_file_name = blank_str
                    continue
            
            units_arg = blank_str
            if ios != 0:
                full_file_name = blank_str
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != blank_str:
                external_functions.DisplayString('Processing IDF -- ' + full_file_name)
                data_string_globals.Auditf.write(' Processing IDF -- ' + full_file_name + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    data_vcompare_globals.FileNamePath = full_file_name[:dot_pos]
                    local_file_extension = external_functions.MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    data_vcompare_globals.FileNamePath = full_file_name
                    print(' assuming file extension of .idf')
                    data_string_globals.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = external_functions.GetNewUnitNumber()
                try:
                    with open(full_file_name, 'r'):
                        data_vcompare_globals.FileOK = True
                except FileNotFoundError:
                    data_vcompare_globals.FileOK = False
                
                if not data_vcompare_globals.FileOK:
                    print('File not found=' + full_file_name)
                    data_string_globals.Auditf.write('File not found=' + full_file_name + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file = open(data_vcompare_globals.FileNamePath + '.' + local_file_extension + 'dif', 'w')
                    else:
                        dif_file = open(data_vcompare_globals.FileNamePath + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        external_functions.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', data_string_globals.Auditf)
                        data_vcompare_globals.ProcessingIMFFile = True
                    else:
                        data_vcompare_globals.ProcessingIMFFile = False
                    
                    input_processor.ProcessInput(
                        data_vcompare_globals.IDDFileNameWithPath,
                        data_vcompare_globals.NewIDDFileNameWithPath,
                        full_file_name
                    )
                    
                    if data_vcompare_globals.FatalError:
                        exit_because_bad_file = True
                        dif_file.close()
                        break
                    
                    delete_this_record = [False] * (data_vcompare_globals.NumIDFRecords + 1)
                    
                    no_version = True
                    for num in range(1, data_vcompare_globals.NumIDFRecords + 1):
                        if external_functions.MakeUPPERCase(data_vcompare_globals.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for num in range(1, data_vcompare_globals.NumIDFRecords + 1):
                        if not external_functions.SameString(data_vcompare_globals.IDFRecords[num].Name, 'ScheduleTypeLimits'):
                            continue
                        if not external_functions.SameString(data_vcompare_globals.IDFRecords[num].Alphas[1], 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(1, data_vcompare_globals.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + data_vcompare_globals.IDFRecords[num].Name + '="' + data_vcompare_globals.IDFRecords[num].Alphas[1] + '".\n')
                    
                    for num in range(1, data_vcompare_globals.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(data_vcompare_globals.IDFRecords[num].CommtS + 1, data_vcompare_globals.IDFRecords[num].CommtE + 1):
                            dif_file.write(data_vcompare_globals.Comments[xcount] + '\n')
                            if xcount == data_vcompare_globals.IDFRecords[num].CommtE:
                                dif_file.write('\n')
                        
                        if no_version and num == 1:
                            object_name = 'VERSION'
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1] = data_vcompare_globals.sVersionNum
                            cur_args = 1
                            external_functions.WriteOutIDFLinesAsComments(dif_file, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name_upper = external_functions.MakeUPPERCase(data_vcompare_globals.IDFRecords[num].Name.rstrip())
                        if object_name_upper in ('SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA', 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS'):
                            continue
                        
                        if object_name_upper == 'WATER HEATER:SIMPLE':
                            dif_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        object_name = data_vcompare_globals.IDFRecords[num].Name
                        
                        if external_functions.FindItemInList(object_name, [od.Name for od in data_vcompare_globals.ObjectDef], data_vcompare_globals.NumObjectDefs) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = input_processor.GetObjectDefInIDD(object_name)
                            num_alphas = data_vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = data_vcompare_globals.IDFRecords[num].NumNumbers
                            alphas[1:num_alphas+1] = data_vcompare_globals.IDFRecords[num].Alphas[1:num_alphas+1]
                            numbers[1:num_numbers+1] = data_vcompare_globals.IDFRecords[num].Numbers[1:num_numbers+1]
                            cur_args = num_alphas + num_numbers
                            in_args = [blank_str] * (max_total_args + 1)
                            out_args = [blank_str] * (max_total_args + 1)
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
                            data_string_globals.Auditf.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                            data_string_globals.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            data_string_globals.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = data_vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = data_vcompare_globals.IDFRecords[num].NumNumbers
                            alphas[1:num_alphas+1] = data_vcompare_globals.IDFRecords[num].Alphas[1:num_alphas+1]
                            numbers[1:num_numbers+1] = data_vcompare_globals.IDFRecords[num].Numbers[1:num_numbers+1]
                            for arg in range(1, num_alphas + 1):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(1, num_numbers + 1):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [blank_str] * (max_total_args + 1)
                            nw_fld_units = [blank_str] * (max_total_args + 1)
                            external_functions.WriteOutIDFLinesAsComments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if external_functions.FindItemInList(external_functions.MakeUPPERCase(object_name), data_vcompare_globals.NotInNew, len(data_vcompare_globals.NotInNew)) == 0:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        object_name_upper = external_functions.MakeUPPERCase(data_vcompare_globals.IDFRecords[num].Name.rstrip())
                        
                        if object_name_upper == 'VERSION':
                            if (in_args[1][:3] == data_vcompare_globals.sVersionNum) and arg_file:
                                external_functions.ShowWarningError('File is already at latest version.  No new diff file made.', data_string_globals.Auditf)
                                dif_file.close()
                                latest_version = True
                                break
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1] = data_vcompare_globals.sVersionNum
                            no_diff = False
                        
                        elif object_name_upper == 'ENERGYMANAGEMENTSYSTEM:ACTUATOR':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            inner_case = external_functions.MakeUPPERCase(in_args[4])
                            if inner_case == 'OUTDOOR AIR DRYBLUB TEMPERATURE':
                                no_diff = True
                                out_args = in_args[:]
                                out_args[4] = 'Outdoor Air Drybulb Temperature'
                            elif inner_case == 'OUTDOOR AIR WETBLUB TEMPERATURE':
                                no_diff = True
                                out_args = in_args[:]
                                out_args[4] = 'Outdoor Air Wetbulb Temperature'
                        
                        elif object_name_upper == 'OUTPUT:VARIABLE':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            if out_args[1] == blank_str:
                                out_args[1] = '*'
                                no_diff = False
                            del_this = [False]
                            external_functions.ScanOutputVariablesForReplacement(
                                2, del_this, [check_rvi], [no_diff], object_name, dif_file,
                                True, False, False, cur_args, [written], False
                            )
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            del_this = [False]
                            external_functions.ScanOutputVariablesForReplacement(
                                1, del_this, [check_rvi], [no_diff], object_name, dif_file,
                                False, True, False, cur_args, [written], False
                            )
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            if out_args[1] == blank_str:
                                out_args[1] = '*'
                                no_diff = False
                            del_this = [False]
                            external_functions.ScanOutputVariablesForReplacement(
                                2, del_this, [check_rvi], [no_diff], object_name, dif_file,
                                False, False, True, cur_args, [written], False
                            )
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper in ('EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE'):
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            if out_args[1] == blank_str:
                                out_args[1] = '*'
                                no_diff = False
                            del_this = [False]
                            external_functions.ScanOutputVariablesForReplacement(
                                2, del_this, [check_rvi], [no_diff], object_name, dif_file,
                                False, False, False, cur_args, [written], False
                            )
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            del_this = [False]
                            external_functions.ScanOutputVariablesForReplacement(
                                3, del_this, [check_rvi], [no_diff], object_name, dif_file,
                                False, False, False, cur_args, [written], True
                            )
                            if del_this[0]:
                                continue
                        
                        elif object_name_upper == 'OUTPUT:TABLE:MONTHLY':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            no_diff = True
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            cur_var = 3
                            var = 3
                            while var <= cur_args:
                                uc_rep_var_name = external_functions.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, data_vcompare_globals.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = external_functions.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg] != blank_str and not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not data_vcompare_globals.OTMVarCaution[arg]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Output Table Monthly (new)="' + data_vcompare_globals.NewRepVarName[arg] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.OTMVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 1 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]:
                                            if not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_vcompare_globals.NewRepVarCaution[arg + 1] != blank_str:
                                                    if not data_vcompare_globals.OTMVarCaution[arg + 1]:
                                                        external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                            '" conversion to Output Table Monthly (new)="' + data_vcompare_globals.NewRepVarName[arg + 1] +
                                                            '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                        dif_file.write(' \n')
                                                        data_vcompare_globals.OTMVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 2 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg + 2] != blank_str:
                                                if not data_vcompare_globals.OTMVarCaution[arg + 2]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Output Table Monthly (new)="' + data_vcompare_globals.NewRepVarName[arg + 2] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.OTMVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var - 1
                        
                        elif object_name_upper == 'METER:CUSTOM':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            cur_var = 4
                            var = 4
                            while var <= cur_args:
                                uc_rep_var_name = external_functions.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, data_vcompare_globals.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = external_functions.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg] != blank_str and not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not data_vcompare_globals.CMtrVarCaution[arg]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Custom Meter (new)="' + data_vcompare_globals.NewRepVarName[arg] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.CMtrVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 1 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]:
                                            if not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_vcompare_globals.NewRepVarCaution[arg + 1] != blank_str and not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not data_vcompare_globals.CMtrVarCaution[arg + 1]:
                                                        external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                            '" conversion to Custom Meter (new)="' + data_vcompare_globals.NewRepVarName[arg + 1] +
                                                            '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                        dif_file.write(' \n')
                                                        data_vcompare_globals.CMtrVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 2 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg + 2] != blank_str:
                                                if not data_vcompare_globals.CMtrVarCaution[arg + 2]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Custom Meter (new)="' + data_vcompare_globals.NewRepVarName[arg + 2] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.CMtrVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var
                            for arg in range(cur_var, 0, -1):
                                if out_args[arg] == blank_str:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_name_upper == 'METER:CUSTOMDECREMENT':
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = True
                            cur_var = 4
                            var = 4
                            while var <= cur_args:
                                uc_rep_var_name = external_functions.MakeUPPERCase(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                del_this = False
                                for arg in range(1, data_vcompare_globals.NumRepVarNames + 1):
                                    uc_comp_rep_var_name = external_functions.MakeUPPERCase(data_vcompare_globals.OldRepVarName[arg])
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
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg] != blank_str and not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not data_vcompare_globals.CMtrDVarCaution[arg]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Custom Meter (new)="' + data_vcompare_globals.NewRepVarName[arg] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.CMtrDVarCaution[arg] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 1 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 1]:
                                            if not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if data_vcompare_globals.NewRepVarCaution[arg + 1] != blank_str and not external_functions.SameString(data_vcompare_globals.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not data_vcompare_globals.CMtrDVarCaution[arg + 1]:
                                                        external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                            '" conversion to Custom Decrement Meter (new)="' + data_vcompare_globals.NewRepVarName[arg + 1] +
                                                            '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 1] + '".')
                                                        dif_file.write(' \n')
                                                        data_vcompare_globals.CMtrDVarCaution[arg + 1] = True
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        if arg < len(data_vcompare_globals.OldRepVarName) - 2 and data_vcompare_globals.OldRepVarName[arg] == data_vcompare_globals.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = data_vcompare_globals.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            if data_vcompare_globals.NewRepVarCaution[arg + 2] != blank_str:
                                                if not data_vcompare_globals.CMtrDVarCaution[arg + 2]:
                                                    external_functions.writePreprocessorObject(dif_file, data_string_globals.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + data_vcompare_globals.OldRepVarName[arg] +
                                                        '" conversion to Custom Meter (new)="' + data_vcompare_globals.NewRepVarName[arg + 2] +
                                                        '" has the following caution "' + data_vcompare_globals.NewRepVarCaution[arg + 2] + '".')
                                                    dif_file.write(' \n')
                                                    data_vcompare_globals.CMtrDVarCaution[arg + 2] = True
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            cur_args = cur_var
                            for arg in range(cur_var, 0, -1):
                                if out_args[arg] == blank_str:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:16] = in_args[1:16]
                            out_args[16] = in_args[17]
                            cur_args = max(cur_args - 1, 13)
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:17] = in_args[1:17]
                            out_args[17] = in_args[18]
                            cur_args = max(cur_args - 1, 14)
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:6] = in_args[1:6]
                            out_args[6:cur_args] = in_args[7:cur_args+1]
                            cur_args = cur_args - 1
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:8] = in_args[1:8]
                            out_args[8:cur_args-1] = in_args[10:cur_args+1]
                            cur_args = cur_args - 2
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:7] = in_args[1:7]
                            out_args[7:cur_args] = in_args[8:cur_args+1]
                            cur_args = cur_args - 1
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:8] = in_args[1:8]
                            out_args[8:cur_args-1] = in_args[10:cur_args+1]
                            cur_args = cur_args - 2
                        
                        elif object_name_upper == 'UNITARYSYSTEMPERFORMANCE:MULTISPEED':
                            no_diff = False
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:4] = in_args[1:4]
                            out_args[4] = 'No'
                            out_args[5:13] = in_args[4:12]
                            cur_args = cur_args + 1
                        
                        else:
                            if external_functions.FindItemInList(object_name, data_vcompare_globals.NotInNew, len(data_vcompare_globals.NotInNew)) != 0:
                                data_string_globals.Auditf.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                data_string_globals.Auditf.write('... will be listed as comments on the new output file.\n')
                                external_functions.WriteOutIDFLinesAsComments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                written = True
                            else:
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                                out_args[1:cur_args+1] = in_args[1:cur_args+1]
                                no_diff = True
                        
                        if diff_min_fields and no_diff:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            no_diff = False
                            for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            external_functions.CheckSpecialObjects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, [written])
                        
                        if not written:
                            external_functions.WriteOutIDFLines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if data_vcompare_globals.IDFRecords[data_vcompare_globals.NumIDFRecords].CommtE != data_vcompare_globals.CurComment:
                        for xcount in range(data_vcompare_globals.IDFRecords[data_vcompare_globals.NumIDFRecords].CommtE + 1, data_vcompare_globals.CurComment + 1):
                            dif_file.write(data_vcompare_globals.Comments[xcount] + '\n')
                            if xcount == data_vcompare_globals.IDFRecords[num].CommtE:
                                dif_file.write('\n')
                    
                    if input_processor.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = input_processor.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        out_args[1] = 'Regular'
                        cur_args = 1
                        external_functions.WriteOutIDFLines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    try:
                        with open(data_vcompare_globals.FileNamePath + '.rvi', 'r'):
                            file_exist = True
                    except FileNotFoundError:
                        file_exist = False
                    
                    dif_file.close()
                    external_functions.ProcessRviMviFiles(data_vcompare_globals.FileNamePath, 'rvi')
                    external_functions.ProcessRviMviFiles(data_vcompare_globals.FileNamePath, 'mvi')
                    external_functions.CloseOut()
                else:
                    external_functions.ProcessRviMviFiles(data_vcompare_globals.FileNamePath, 'rvi')
                    external_functions.ProcessRviMviFiles(data_vcompare_globals.FileNamePath, 'mvi')
            else:
                end_of_file[0] = True
            
            created_output_name = ['']
            external_functions.CreateNewName('Reallocate', created_output_name, ' ')
        
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
        external_functions.copyfile(
            data_vcompare_globals.FileNamePath + '.' + arg_idf_extension,
            data_vcompare_globals.FileNamePath + '.' + arg_idf_extension + 'old',
            err_flag
        )
        external_functions.copyfile(
            data_vcompare_globals.FileNamePath + '.' + arg_idf_extension + 'new',
            data_vcompare_globals.FileNamePath + '.' + arg_idf_extension,
            err_flag
        )
        
        try:
            with open(data_vcompare_globals.FileNamePath + '.rvi', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            external_functions.copyfile(
                data_vcompare_globals.FileNamePath + '.rvi',
                data_vcompare_globals.FileNamePath + '.rviold',
                err_flag
            )
        
        try:
            with open(data_vcompare_globals.FileNamePath + '.rvinew', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            external_functions.copyfile(
                data_vcompare_globals.FileNamePath + '.rvinew',
                data_vcompare_globals.FileNamePath + '.rvi',
                err_flag
            )
        
        try:
            with open(data_vcompare_globals.FileNamePath + '.mvi', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            external_functions.copyfile(
                data_vcompare_globals.FileNamePath + '.mvi',
                data_vcompare_globals.FileNamePath + '.mviold',
                err_flag
            )
        
        try:
            with open(data_vcompare_globals.FileNamePath + '.mvinew', 'r'):
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            external_functions.copyfile(
                data_vcompare_globals.FileNamePath + '.mvinew',
                data_vcompare_globals.FileNamePath + '.mvi',
                err_flag
            )
