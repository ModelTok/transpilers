from typing import Protocol, List, Optional, Tuple
from dataclasses import dataclass, field
from pathlib import Path

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: VerString, VersionNum, sVersionNum, sVersionNumFourChars, 
#   IDDFileNameWithPath, NewIDDFileNameWithPath, ProgNameConversion, ProgramPath, 
#   FullFileName, FileNamePath, Auditf, Comments, CurComment, Blank
# - DataVCompareGlobals: various flags/state
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList
# - VCompareGlobalRoutines: CheckSpecialObjects, WriteOutIDFLines, WriteOutIDFLinesAsComments,
#   ProcessRviMviFiles, CreateNewName, CloseOut, DisplayString, GetNumSectionsFound
# - General: MakeUPPERCase, MakeLowerCase, TrimTrailZeros, GetNewUnitNumber
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

class IDFRecord(Protocol):
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str]
    Numbers: List[float]
    CommtS: int
    CommtE: int

class ObjectDefItem(Protocol):
    Name: str

class StringGlobals(Protocol):
    VerString: str
    VersionNum: float
    sVersionNum: str
    sVersionNumFourChars: str
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    ProgNameConversion: str
    ProgramPath: str
    FullFileName: str
    FileNamePath: str
    Auditf: int
    Comments: List[str]
    CurComment: int
    Blank: str

class VCompareGlobals(Protocol):
    IDFRecords: List[IDFRecord]
    NumIDFRecords: int
    ObjectDef: List[ObjectDefItem]
    NumObjectDefs: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    Alphas: List[str]
    Numbers: List[float]
    InArgs: List[str]
    TempArgs: List[str]
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
    NotInNew: List[str]
    ProcessingIMFFile: bool
    FatalError: bool
    FileOK: bool

class InputProcessor(Protocol):
    def ProcessInput(self, idd_path: str, new_idd_path: str, idf_path: str) -> None: ...
    def GetObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def GetNewObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def FindItemInList(self, item: str, list_items: List[str], size: int) -> int: ...

class VCompareRoutines(Protocol):
    def CheckSpecialObjects(self, lun: int, obj_name: str, cur_args: int, out_args: List[str], 
                           fld_names: List[str], fld_units: List[str], written: List[bool]) -> None: ...
    def WriteOutIDFLines(self, lun: int, obj_name: str, cur_args: int, out_args: List[str],
                        fld_names: List[str], fld_units: List[str]) -> None: ...
    def WriteOutIDFLinesAsComments(self, lun: int, obj_name: str, cur_args: int, out_args: List[str],
                                   fld_names: List[str], fld_units: List[str]) -> None: ...
    def ProcessRviMviFiles(self, file_path: str, ext: str) -> None: ...
    def CreateNewName(self, cmd: str, output_name: str, placeholder: str) -> None: ...
    def CloseOut(self) -> None: ...
    def DisplayString(self, msg: str) -> None: ...
    def GetNumSectionsFound(self, section: str) -> int: ...

class General(Protocol):
    def MakeUPPERCase(self, s: str) -> str: ...
    def MakeLowerCase(self, s: str) -> str: ...
    def TrimTrailZeros(self, s: str) -> str: ...
    def GetNewUnitNumber(self) -> int: ...
    def copyfile(self, src: str, dst: str, err_flag: List[bool]) -> None: ...

class DataGlobals(Protocol):
    def ShowMessage(self, msg: str) -> None: ...
    def ShowContinueError(self, msg: str, lun: Optional[int] = None) -> None: ...
    def ShowFatalError(self, msg: str, lun: Optional[int] = None) -> None: ...
    def ShowSevereError(self, msg: str, lun: Optional[int] = None) -> None: ...
    def ShowWarningError(self, msg: str, lun: Optional[int] = None) -> None: ...

_first_time = True

def set_this_version_variables(
    string_globals: StringGlobals,
) -> None:
    string_globals.VerString = 'Pretty Only @CMAKE_VERSION_MAJOR@.@CMAKE_VERSION_MINOR@'
    string_globals.VersionNum = '@CMAKE_VERSION_MAJOR@.@CMAKE_VERSION_MINOR@'
    string_globals.sVersionNum = '***'
    string_globals.sVersionNumFourChars = '@CMAKE_VERSION_MAJOR@.@CMAKE_VERSION_MINOR@'
    string_globals.IDDFileNameWithPath = (string_globals.ProgramPath.strip() + 
        'V@CMAKE_VERSION_MAJOR@-@CMAKE_VERSION_MINOR@-@CMAKE_VERSION_PATCH@-Energy+.idd')
    string_globals.NewIDDFileNameWithPath = (string_globals.ProgramPath.strip() + 
        'V@CMAKE_VERSION_MAJOR@-@CMAKE_VERSION_MINOR@-@CMAKE_VERSION_PATCH@-Energy+.idd')

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    string_globals: StringGlobals,
    vcompare_globals: VCompareGlobals,
    input_processor: InputProcessor,
    vcompare_routines: VCompareRoutines,
    general: General,
    data_globals: DataGlobals,
) -> None:
    global _first_time
    
    fmta = "(A)"
    
    if _first_time:
        _first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    delete_this_record: List[bool] = []
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        full_file_name = string_globals.Blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = string_globals.Blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = string_globals.Blank
                    continue
            
            units_arg = string_globals.Blank
            if ios != 0:
                full_file_name = string_globals.Blank
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != string_globals.Blank:
                vcompare_routines.DisplayString('Processing IDF -- ' + full_file_name.strip())
                f_audit = open(str(string_globals.Auditf), 'a')
                f_audit.write(' Processing IDF -- ' + full_file_name.strip() + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = general.MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    f_audit.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.strip() + '.idf'
                    local_file_extension = 'idf'
                
                string_globals.FileNamePath = file_name_path
                dif_lfn = general.GetNewUnitNumber()
                
                try:
                    file_ok = Path(full_file_name).exists()
                except:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    f_audit.write('File not found=' + full_file_name + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    f_audit.close()
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file = open(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        dif_file = open(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        data_globals.ShowWarningError(
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            string_globals.Auditf
                        )
                        vcompare_globals.ProcessingIMFFile = True
                    else:
                        vcompare_globals.ProcessingIMFFile = False
                    
                    input_processor.ProcessInput(
                        string_globals.IDDFileNameWithPath,
                        string_globals.NewIDDFileNameWithPath,
                        full_file_name
                    )
                    
                    if vcompare_globals.FatalError:
                        exit_because_bad_file = True
                        f_audit.close()
                        dif_file.close()
                        break
                    
                    delete_this_record = [False] * vcompare_globals.NumIDFRecords
                    
                    vcompare_globals.Alphas = [string_globals.Blank] * vcompare_globals.MaxAlphaArgsFound
                    vcompare_globals.Numbers = [0.0] * vcompare_globals.MaxNumericArgsFound
                    vcompare_globals.InArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.TempArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.AorN = [False] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.ReqFld = [False] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.FldNames = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.FldDefaults = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.FldUnits = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.NwAorN = [False] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.NwReqFld = [False] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.NwFldNames = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.NwFldDefaults = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.NwFldUnits = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    vcompare_globals.OutArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                    
                    no_version = True
                    for num in range(vcompare_globals.NumIDFRecords):
                        if general.MakeUPPERCase(vcompare_globals.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(vcompare_globals.NumIDFRecords):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + vcompare_globals.IDFRecords[num].Name.strip() + 
                                         '="' + vcompare_globals.IDFRecords[num].Alphas[0].strip() + '".\n')
                    
                    vcompare_routines.DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(vcompare_globals.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(vcompare_globals.IDFRecords[num].CommtS,
                                          vcompare_globals.IDFRecords[num].CommtE + 1):
                            if xcount < len(string_globals.Comments):
                                dif_file.write(string_globals.Comments[xcount].strip() + '\n')
                                if xcount == vcompare_globals.IDFRecords[num].CommtE:
                                    dif_file.write('\n')
                        
                        if no_version and num == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.GetNewObjectDefInIDD('VERSION')
                            out_args = [string_globals.sVersionNumFourChars] + [string_globals.Blank] * (vcompare_globals.MaxTotalArgs - 1)
                            cur_args = 1
                            data_globals.ShowWarningError(
                                'No version found in file, defaulting to ' + string_globals.sVersionNumFourChars,
                                string_globals.Auditf
                            )
                            vcompare_routines.WriteOutIDFLinesAsComments(
                                dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units
                            )
                        
                        object_name = vcompare_globals.IDFRecords[num].Name
                        
                        if input_processor.FindItemInList(object_name, 
                                                         [od.Name for od in vcompare_globals.ObjectDef],
                                                         vcompare_globals.NumObjectDefs) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                input_processor.GetObjectDefInIDD(object_name)
                            num_alphas = vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = vcompare_globals.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                vcompare_globals.Alphas[i] = vcompare_globals.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                vcompare_globals.Numbers[i] = vcompare_globals.IDFRecords[num].Numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            vcompare_globals.InArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            vcompare_globals.OutArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            vcompare_globals.TempArgs = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    vcompare_globals.InArgs[arg] = vcompare_globals.Alphas[na]
                                    na += 1
                                else:
                                    vcompare_globals.InArgs[arg] = str(vcompare_globals.Numbers[nn])
                                    nn += 1
                        else:
                            f_audit.write('Object="' + object_name.strip() + 
                                        '" does not seem to be on the "old" IDD.\n')
                            f_audit.write('... will be listed as comments (no field names) on the new output file.\n')
                            f_audit.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = vcompare_globals.IDFRecords[num].NumAlphas
                            num_numbers = vcompare_globals.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                vcompare_globals.Alphas[i] = vcompare_globals.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                vcompare_globals.Numbers[i] = vcompare_globals.IDFRecords[num].Numbers[i]
                            
                            out_args = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            for arg in range(num_alphas):
                                out_args[arg] = vcompare_globals.Alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = str(vcompare_globals.Numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            nw_fld_units = [string_globals.Blank] * vcompare_globals.MaxTotalArgs
                            vcompare_routines.WriteOutIDFLinesAsComments(
                                dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                            )
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if input_processor.FindItemInList(
                            general.MakeUPPERCase(object_name),
                            vcompare_globals.NotInNew,
                            len(vcompare_globals.NotInNew)
                        ) == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.GetNewObjectDefInIDD(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            input_processor.GetNewObjectDefInIDD(object_name)
                        
                        for i in range(cur_args):
                            vcompare_globals.OutArgs[i] = vcompare_globals.InArgs[i]
                        
                        if diff_min_fields and nodiff:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.GetNewObjectDefInIDD(object_name)
                            for i in range(cur_args):
                                vcompare_globals.OutArgs[i] = vcompare_globals.InArgs[i]
                            nodiff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                vcompare_globals.OutArgs[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        written_list = [written]
                        vcompare_routines.CheckSpecialObjects(
                            dif_lfn, object_name, cur_args, vcompare_globals.OutArgs,
                            nw_fld_names, nw_fld_units, written_list
                        )
                        written = written_list[0]
                        
                        if not written:
                            vcompare_routines.WriteOutIDFLines(
                                dif_lfn, object_name, cur_args, vcompare_globals.OutArgs,
                                nw_fld_names, nw_fld_units
                            )
                    
                    vcompare_routines.DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if vcompare_globals.IDFRecords[vcompare_globals.NumIDFRecords - 1].CommtE != string_globals.CurComment:
                        for xcount in range(vcompare_globals.IDFRecords[vcompare_globals.NumIDFRecords - 1].CommtE + 1,
                                          string_globals.CurComment + 1):
                            if xcount < len(string_globals.Comments):
                                dif_file.write(string_globals.Comments[xcount].strip() + '\n')
                                if xcount == vcompare_globals.IDFRecords[vcompare_globals.NumIDFRecords - 1].CommtE:
                                    dif_file.write('\n')
                    
                    if vcompare_routines.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            input_processor.GetNewObjectDefInIDD(object_name)
                        nodiff = False
                        out_args = ['Regular'] + [string_globals.Blank] * (vcompare_globals.MaxTotalArgs - 1)
                        cur_args = 1
                        vcompare_routines.WriteOutIDFLines(
                            dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                        )
                    
                    try:
                        file_exist = Path(file_name_path + '.rvi').exists()
                    except:
                        file_exist = False
                    
                    dif_file.close()
                    vcompare_routines.ProcessRviMviFiles(file_name_path, 'rvi')
                    vcompare_routines.ProcessRviMviFiles(file_name_path, 'mvi')
                    vcompare_routines.CloseOut()
                else:
                    vcompare_routines.ProcessRviMviFiles(file_name_path, 'rvi')
                    vcompare_routines.ProcessRviMviFiles(file_name_path, 'mvi')
                
                f_audit.close()
            else:
                end_of_file[0] = True
            
            created_output_name = ''
            vcompare_routines.CreateNewName('Reallocate', created_output_name, ' ')
        
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
        general.copyfile(
            file_name_path + '.' + arg_idf_extension,
            file_name_path + '.' + arg_idf_extension + 'old',
            err_flag
        )
        general.copyfile(
            file_name_path + '.' + arg_idf_extension + 'new',
            file_name_path + '.' + arg_idf_extension,
            err_flag
        )
        
        try:
            file_exist = Path(file_name_path + '.rvi').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.rvi',
                file_name_path + '.rviold',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.rvinew').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.rvinew',
                file_name_path + '.rvi',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.mvi').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.mvi',
                file_name_path + '.mviold',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.mvinew').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.mvinew',
                file_name_path + '.mvi',
                err_flag
            )
