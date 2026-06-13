from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Any
from enum import Enum
import os

# EXTERNAL DEPS (to wire in glue):
# From DataStringGlobals: ProgNameConversion, ProgramPath, Blank
# From DataVCompareGlobals: IDFRecords, Comments, ObjectDef, NumObjectDefs, NumIDFRecords,
#   Alphas, Numbers, InArgs, TempArgs, OutArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, MaxNameLength, MaxAlphaArgsFound,
#   MaxNumericArgsFound, MaxTotalArgs, Auditf, FullFileName, FileNamePath, FileOK, ProcessingIMFFile,
#   FatalError, IDDFileNameWithPath, NewIDDFileNameWithPath, NumAlphas, NumNumbers, ObjMinFlds,
#   NwObjMinFlds, NotInNew, NumRepVarNames, OldRepVarName, NewRepVarName, NewRepVarCaution,
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, MakingPretty, CurComment
# From InputProcessor: ProcessInput
# From VCompareGlobalRoutines: FindItemInList, GetObjectDefInIDD, GetNewObjectDefInIDD,
#   DisplayString, WriteOutIDFLinesAsComments, WriteOutIDFLines, ScanOutputVariablesForReplacement,
#   CheckSpecialObjects, ProcessRviMviFiles, CreateNewName, CloseOut, GetNumSectionsFound,
#   writePreprocessorObject
# From General: TrimTrailZeros, MakeLowerCase, MakeUPPERCase, SameString
# From DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# GetNewUnitNumber: EXTERNAL function
# copyfile: EXTERNAL function

class SetVersion:
    """Encapsulates SetVersion module."""
    
    @staticmethod
    def SetThisVersionVariables(globals_state: 'GlobalsState') -> None:
        """Set version variables for 9.5 => 9.6 conversion."""
        globals_state.VerString = 'Conversion 9.5 => 9.6'
        globals_state.VersionNum = 9.6
        globals_state.sVersionNum = '9.6'
        globals_state.IDDFileNameWithPath = globals_state.ProgramPath.rstrip() + 'V9-5-0-Energy+.idd'
        globals_state.NewIDDFileNameWithPath = globals_state.ProgramPath.rstrip() + 'V9-6-0-Energy+.idd'
        globals_state.RepVarFileNameWithPath = globals_state.ProgramPath.rstrip() + 'Report Variables 9-5-0 to 9-6-0.csv'


def CreateNewIDFUsingRules(
    EndOfFile: bool,
    DiffOnly: bool,
    InLfn: int,
    AskForInput: bool,
    InputFileName: str,
    ArgFile: bool,
    ArgIDFExtension: str,
    globals_state: 'GlobalsState'
) -> bool:
    """
    Create new IDFs based on rules specified by developers.
    
    Args:
        EndOfFile: Whether EOF reached
        DiffOnly: Only create diff, not full conversion
        InLfn: Input logical file number
        AskForInput: Ask user for input filename
        InputFileName: Input file name if ArgFile is True
        ArgFile: Reading from command-line argument file
        ArgIDFExtension: File extension for IDF files
        globals_state: Global state object
    
    Returns:
        EndOfFile flag
    """
    
    # Local variables
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = ' ' * 10
    end_of_file = EndOfFile
    ios = 0
    
    if first_time:
        first_time = False
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if AskForInput:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not ArgFile:
                    # READ from input file
                    full_file_name = ''  # placeholder for file read
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = InputFileName
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ''
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = ''
                    continue
            
            if ios != 0:
                full_file_name = ''
            
            full_file_name = full_file_name.strip()
            
            if full_file_name != '':
                DisplayString('Processing IDF -- ' + full_file_name)
                globals_state.write_audit('Processing IDF -- ' + full_file_name)
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print('assuming file extension of .idf')
                    globals_state.write_audit('..assuming file extension of .idf')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                # Check file exists
                file_exists = os.path.exists(full_file_name)
                
                if not file_exists:
                    print(f'File not found={full_file_name}')
                    globals_state.write_audit(f'File not found={full_file_name}')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if DiffOnly:
                        out_file_name = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        out_file_name = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        ShowWarningError(
                            'Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.',
                            globals_state
                        )
                        globals_state.ProcessingIMFFile = True
                    else:
                        globals_state.ProcessingIMFFile = False
                    
                    ProcessInput(
                        globals_state.IDDFileNameWithPath,
                        globals_state.NewIDDFileNameWithPath,
                        full_file_name,
                        globals_state
                    )
                    
                    if globals_state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate/deallocate arrays as needed
                    delete_this_record = [False] * globals_state.NumIDFRecords
                    
                    # Check for VERSION record
                    no_version = True
                    for num in range(globals_state.NumIDFRecords):
                        if MakeUPPERCase(globals_state.IDFRecords[num]['Name']) == 'VERSION':
                            no_version = False
                            break
                    
                    # Write deleted records as comments
                    for num in range(globals_state.NumIDFRecords):
                        if delete_this_record[num]:
                            globals_state.write_output(
                                out_file_name,
                                f"! Deleting: {globals_state.IDFRecords[num]['Name']}=\"{globals_state.IDFRecords[num]['Alphas'][0]}\"."
                            )
                    
                    # Main processing loop
                    DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(globals_state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        # Write comments
                        for xcount in range(globals_state.IDFRecords[num]['CommtS'], globals_state.IDFRecords[num]['CommtE'] + 1):
                            if xcount < len(globals_state.Comments):
                                globals_state.write_output(out_file_name, globals_state.Comments[xcount])
                                if xcount == globals_state.IDFRecords[num]['CommtE']:
                                    globals_state.write_output(out_file_name, '')
                        
                        if no_version and num == 0:
                            GetNewObjectDefInIDD('VERSION', globals_state)
                            out_args = [globals_state.sVersionNum]
                            cur_args = 1
                            ShowWarningError(
                                f'No version found in file, defaulting to {globals_state.sVersionNum}',
                                globals_state
                            )
                            WriteOutIDFLinesAsComments(
                                out_file_name, 'Version', cur_args, out_args,
                                globals_state.NwFldNames, globals_state.NwFldUnits,
                                globals_state
                            )
                        
                        object_name = globals_state.IDFRecords[num]['Name']
                        
                        if FindItemInList(object_name, globals_state.ObjectDef, globals_state.NumObjectDefs, globals_state) != 0:
                            GetObjectDefInIDD(object_name, globals_state)
                            
                            num_alphas = globals_state.IDFRecords[num]['NumAlphas']
                            num_numbers = globals_state.IDFRecords[num]['NumNumbers']
                            
                            in_args = [''] * (num_alphas + num_numbers)
                            out_args = [''] * (num_alphas + num_numbers)
                            temp_args = [''] * (num_alphas + num_numbers)
                            
                            for i in range(num_alphas):
                                in_args[i] = globals_state.IDFRecords[num]['Alphas'][i]
                            for i in range(num_numbers):
                                in_args[num_alphas + i] = str(globals_state.IDFRecords[num]['Numbers'][i])
                            
                            cur_args = num_alphas + num_numbers
                        else:
                            globals_state.write_audit(
                                f'Object="{object_name}" does not seem to be on the "old" IDD.'
                            )
                            globals_state.write_audit(
                                '... will be listed as comments (no field names) on the new output file.'
                            )
                            globals_state.write_audit(
                                '... Alpha fields will be listed first, then numerics.'
                            )
                            
                            num_alphas = globals_state.IDFRecords[num]['NumAlphas']
                            num_numbers = globals_state.IDFRecords[num]['NumNumbers']
                            
                            out_args = [''] * (num_alphas + num_numbers)
                            for i in range(num_alphas):
                                out_args[i] = globals_state.IDFRecords[num]['Alphas'][i]
                            for i in range(num_numbers):
                                out_args[num_alphas + i] = str(globals_state.IDFRecords[num]['Numbers'][i])
                            
                            cur_args = num_alphas + num_numbers
                            WriteOutIDFLinesAsComments(
                                out_file_name, object_name, cur_args, out_args, [], [],
                                globals_state
                            )
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if FindItemInList(MakeUPPERCase(object_name), globals_state.NotInNew, len(globals_state.NotInNew), globals_state) == 0:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            if globals_state.ObjMinFlds != globals_state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        # Process based on object type
                        if not globals_state.MakingPretty:
                            object_upper = MakeUPPERCase(object_name.strip())
                            
                            if object_upper == 'VERSION':
                                if in_args[0][:3] == globals_state.sVersionNum and ArgFile:
                                    ShowWarningError(
                                        'File is already at latest version. No new diff file made.',
                                        globals_state
                                    )
                                    os.remove(out_file_name)
                                    latest_version = True
                                    break
                                
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[0] = globals_state.sVersionNum
                                nodiff = False
                            
                            elif object_upper == 'AIRFLOWNETWORK:MULTIZONE:REFERENCECRACKCONDITIONS':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if in_args[1] == '':
                                    out_args[1] = "20.0"
                            
                            elif object_upper == 'AIRLOOPHVAC:OUTDOORAIRSYSTEM':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[0:3] = in_args[0:3]
                                if cur_args == 4:
                                    cur_args = 3
                            
                            elif object_upper == 'BUILDINGSURFACE:DETAILED':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[0:4] = in_args[0:4]
                                out_args[4] = ''
                                out_args[5:cur_args+1] = in_args[4:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_upper in ['CEILING:ADIABATIC', 'CEILING:INTERZONE', 'FLOOR:DETAILED',
                                                  'FLOOR:GROUNDCONTACT', 'FLOOR:ADIABATIC', 'FLOOR:INTERZONE',
                                                  'ROOFCEILING:DETAILED', 'ROOF', 'WALL:DETAILED', 'WALL:EXTERIOR',
                                                  'WALL:ADIABATIC', 'WALL:UNDERGROUND', 'WALL:INTERZONE']:
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[0:3] = in_args[0:3]
                                out_args[3] = ''
                                out_args[4:cur_args+1] = in_args[3:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_upper == 'CONTROLLER:MECHANICALVENTILATION':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if MakeUPPERCase(out_args[3]) == "VENTILATIONRATEPROCEDURE":
                                    out_args[3] = "Standard62.1VentilationRateProcedure"
                            
                            elif object_upper == 'GROUNDHEATEXCHANGER:SYSTEM':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[0:9] = in_args[0:9]
                                if cur_args > 9:
                                    out_args[10:cur_args+1] = in_args[9:cur_args]
                                    if in_args[8] == '':
                                        out_args[9] = 'UHFCALC'
                                    cur_args = cur_args + 1
                            
                            elif object_upper == 'INTERNALMASS':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[0:3] = in_args[0:3]
                                out_args[3] = ''
                                out_args[4:cur_args+1] = in_args[3:cur_args]
                                cur_args = cur_args + 1
                            
                            elif object_upper == 'SIZING:SYSTEM':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if MakeUPPERCase(out_args[26]) == "VENTILATIONRATEPROCEDURE":
                                    out_args[26] = "Standard62.1VentilationRateProcedure"
                            
                            elif object_upper == 'PERFORMANCEPRECISIONTRADEOFFS':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                out_args[:cur_args] = in_args[:cur_args]
                                if MakeUPPERCase(in_args[2]) == "MODE06":
                                    out_args[2] = 'Mode07'
                                elif MakeUPPERCase(in_args[2]) == "MODE07":
                                    out_args[2] = 'Mode08'
                            
                            elif object_upper == 'OUTPUT:VARIABLE':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    True, False, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 
                                                  'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    1, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == 'OUTPUT:TABLE:TIMEBINS':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, True, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE',
                                                  'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                if out_args[0] == '':
                                    out_args[0] = '*'
                                    nodiff = False
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    3, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, False, cur_args, written, True, globals_state
                                )
                            
                            elif object_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                GetNewObjectDefInIDD(object_name, globals_state)
                                out_args[:cur_args] = in_args[:cur_args]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    6, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                                ScanOutputVariablesForReplacement(
                                    12, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                            
                            else:
                                if FindItemInList(object_name, globals_state.NotInNew, len(globals_state.NotInNew), globals_state) != 0:
                                    globals_state.write_audit(
                                        f'Object="{object_name}" is not in the "new" IDD.'
                                    )
                                    globals_state.write_audit(
                                        '... will be listed as comments on the new output file.'
                                    )
                                    WriteOutIDFLinesAsComments(
                                        out_file_name, object_name, cur_args, in_args,
                                        globals_state.FldNames, globals_state.FldUnits, globals_state
                                    )
                                    written = True
                                else:
                                    GetNewObjectDefInIDD(object_name, globals_state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    nodiff = True
                        
                        else:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if diff_min_fields and nodiff:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            out_args[:cur_args] = in_args[:cur_args]
                            nodiff = False
                            for arg in range(cur_args, globals_state.NwObjMinFlds):
                                out_args[arg] = globals_state.NwFldDefaults[arg]
                            cur_args = max(globals_state.NwObjMinFlds, cur_args)
                        
                        if nodiff and DiffOnly:
                            continue
                        
                        if not written:
                            CheckSpecialObjects(
                                out_file_name, object_name, cur_args, out_args,
                                globals_state.NwFldNames, globals_state.NwFldUnits,
                                written, globals_state
                            )
                        
                        if not written:
                            WriteOutIDFLines(
                                out_file_name, object_name, cur_args, out_args,
                                globals_state.NwFldNames, globals_state.NwFldUnits, globals_state
                            )
                    
                    DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if GetNumSectionsFound('Report Variable Dictionary', globals_state) > 0:
                        object_name = 'Output:VariableDictionary'
                        GetNewObjectDefInIDD(object_name, globals_state)
                        out_args = ['Regular']
                        cur_args = 1
                        WriteOutIDFLines(
                            out_file_name, object_name, cur_args, out_args,
                            globals_state.NwFldNames, globals_state.NwFldUnits, globals_state
                        )
                    
                    ProcessRviMviFiles(file_name_path, 'rvi', globals_state)
                    ProcessRviMviFiles(file_name_path, 'mvi', globals_state)
                    CloseOut(globals_state)
                
                else:
                    ProcessRviMviFiles(file_name_path, 'rvi', globals_state)
                    ProcessRviMviFiles(file_name_path, 'mvi', globals_state)
            
            else:
                end_of_file = True
            
            CreateNewName('Reallocate', globals_state)
        
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
        copyfile(
            file_name_path + '.' + ArgIDFExtension,
            file_name_path + '.' + ArgIDFExtension + 'old',
            err_flag
        )
        copyfile(
            file_name_path + '.' + ArgIDFExtension + 'new',
            file_name_path + '.' + ArgIDFExtension,
            err_flag
        )
        
        if os.path.exists(file_name_path + '.rvi'):
            copyfile(
                file_name_path + '.rvi',
                file_name_path + '.rviold',
                err_flag
            )
        
        if os.path.exists(file_name_path + '.rvinew'):
            copyfile(
                file_name_path + '.rvinew',
                file_name_path + '.rvi',
                err_flag
            )
        
        if os.path.exists(file_name_path + '.mvi'):
            copyfile(
                file_name_path + '.mvi',
                file_name_path + '.mviold',
                err_flag
            )
        
        if os.path.exists(file_name_path + '.mvinew'):
            copyfile(
                file_name_path + '.mvinew',
                file_name_path + '.mvi',
                err_flag
            )
    
    return end_of_file


@dataclass
class GlobalsState:
    """Global state passed as parameter."""
    VerString: str = ''
    VersionNum: float = 0.0
    sVersionNum: str = ''
    ProgramPath: str = ''
    IDDFileNameWithPath: str = ''
    NewIDDFileNameWithPath: str = ''
    RepVarFileNameWithPath: str = ''
    IDFRecords: List[dict] = field(default_factory=list)
    Comments: List[str] = field(default_factory=list)
    ObjectDef: List[dict] = field(default_factory=list)
    NumObjectDefs: int = 0
    NumIDFRecords: int = 0
    ObjMinFlds: int = 0
    NwObjMinFlds: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[float] = field(default_factory=list)
    InArgs: List[str] = field(default_factory=list)
    TempArgs: List[str] = field(default_factory=list)
    OutArgs: List[str] = field(default_factory=list)
    AorN: List[bool] = field(default_factory=list)
    ReqFld: List[bool] = field(default_factory=list)
    FldNames: List[str] = field(default_factory=list)
    FldDefaults: List[str] = field(default_factory=list)
    FldUnits: List[str] = field(default_factory=list)
    NwAorN: List[bool] = field(default_factory=list)
    NwReqFld: List[bool] = field(default_factory=list)
    NwFldNames: List[str] = field(default_factory=list)
    NwFldDefaults: List[str] = field(default_factory=list)
    NwFldUnits: List[str] = field(default_factory=list)
    NotInNew: List[str] = field(default_factory=list)
    NumRepVarNames: int = 0
    OldRepVarName: List[str] = field(default_factory=list)
    NewRepVarName: List[str] = field(default_factory=list)
    NewRepVarCaution: List[str] = field(default_factory=list)
    OTMVarCaution: List[bool] = field(default_factory=list)
    CMtrVarCaution: List[bool] = field(default_factory=list)
    CMtrDVarCaution: List[bool] = field(default_factory=list)
    MaxNameLength: int = 0
    MaxAlphaArgsFound: int = 0
    MaxNumericArgsFound: int = 0
    MaxTotalArgs: int = 0
    Auditf: Any = None
    FullFileName: str = ''
    FileNamePath: str = ''
    FileOK: bool = False
    ProcessingIMFFile: bool = False
    FatalError: bool = False
    NumAlphas: int = 0
    NumNumbers: int = 0
    MakingPretty: bool = False
    CurComment: int = 0
    
    def write_audit(self, message: str) -> None:
        """Write to audit file."""
        if self.Auditf:
            self.Auditf.write(message + '\n')
    
    def write_output(self, filename: str, message: str) -> None:
        """Write to output file."""
        with open(filename, 'a') as f:
            f.write(message + '\n')


def DisplayString(message: str) -> None:
    """Display a message."""
    print(message)


def MakeUPPERCase(s: str) -> str:
    """Convert string to uppercase."""
    return s.upper()


def MakeLowerCase(s: str) -> str:
    """Convert string to lowercase."""
    return s.lower()


def FindItemInList(item: str, list_items: List[str], list_size: int, globals_state: GlobalsState) -> int:
    """Find item in list, return index or 0."""
    for i, list_item in enumerate(list_items[:list_size]):
        if item == list_item:
            return i + 1
    return 0


def GetObjectDefInIDD(object_name: str, globals_state: GlobalsState) -> None:
    """Get object definition from old IDD."""
    pass


def GetNewObjectDefInIDD(object_name: str, globals_state: GlobalsState) -> None:
    """Get object definition from new IDD."""
    pass


def WriteOutIDFLinesAsComments(filename: str, object_name: str, cur_args: int, out_args: List[str],
                               fld_names: List[str], fld_units: List[str], globals_state: GlobalsState) -> None:
    """Write IDF lines as comments."""
    pass


def WriteOutIDFLines(filename: str, object_name: str, cur_args: int, out_args: List[str],
                     fld_names: List[str], fld_units: List[str], globals_state: GlobalsState) -> None:
    """Write IDF lines."""
    pass


def ScanOutputVariablesForReplacement(field_num: int, del_this: bool, checkrvi: bool, nodiff: bool,
                                      object_name: str, filename: str, out_var: bool, mtr_var: bool,
                                      timebin_var: bool, cur_args: int, written: bool, is_sensor: bool,
                                      globals_state: GlobalsState) -> None:
    """Scan and replace output variables."""
    pass


def CheckSpecialObjects(filename: str, object_name: str, cur_args: int, out_args: List[str],
                       fld_names: List[str], fld_units: List[str], written: bool, globals_state: GlobalsState) -> None:
    """Check for special object types."""
    pass


def ShowWarningError(message: str, globals_state: GlobalsState) -> None:
    """Show warning error."""
    print(f"Warning: {message}")
    globals_state.write_audit(f"Warning: {message}")


def ProcessRviMviFiles(file_path: str, ext: str, globals_state: GlobalsState) -> None:
    """Process RVI/MVI files."""
    pass


def CreateNewName(mode: str, globals_state: GlobalsState) -> None:
    """Create new name."""
    pass


def CloseOut(globals_state: GlobalsState) -> None:
    """Close output."""
    pass


def GetNumSectionsFound(section_name: str, globals_state: GlobalsState) -> int:
    """Get number of sections found."""
    return 0


def ProcessInput(idd_file: str, new_idd_file: str, idf_file: str, globals_state: GlobalsState) -> None:
    """Process input file."""
    pass


def copyfile(src: str, dst: str, err_flag: bool) -> None:
    """Copy file."""
    try:
        with open(src, 'r') as fsrc:
            with open(dst, 'w') as fdst:
                fdst.write(fsrc.read())
    except Exception:
        pass
