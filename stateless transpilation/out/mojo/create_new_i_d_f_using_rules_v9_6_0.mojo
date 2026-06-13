from builtin.io import _CSTDERR
from memory import memset, memcpy
from collections import Dict, List
from pathlib import Path


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


struct StringArray:
    """Array of strings."""
    data: DynamicVector[StringRef]


struct IDFRecord:
    """IDFRecord struct."""
    Name: String
    NumAlphas: Int
    NumNumbers: Int
    Alphas: DynamicVector[String]
    Numbers: DynamicVector[Float64]
    CommtS: Int
    CommtE: Int


struct GlobalsState:
    """Global state struct."""
    var VerString: String
    var VersionNum: Float64
    var sVersionNum: String
    var ProgramPath: String
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String
    var IDFRecords: DynamicVector[IDFRecord]
    var Comments: DynamicVector[String]
    var ObjectDef: DynamicVector[String]
    var NumObjectDefs: Int
    var NumIDFRecords: Int
    var ObjMinFlds: Int
    var NwObjMinFlds: Int
    var Alphas: DynamicVector[String]
    var Numbers: DynamicVector[Float64]
    var InArgs: DynamicVector[String]
    var TempArgs: DynamicVector[String]
    var OutArgs: DynamicVector[String]
    var AorN: DynamicVector[Bool]
    var ReqFld: DynamicVector[Bool]
    var FldNames: DynamicVector[String]
    var FldDefaults: DynamicVector[String]
    var FldUnits: DynamicVector[String]
    var NwAorN: DynamicVector[Bool]
    var NwReqFld: DynamicVector[Bool]
    var NwFldNames: DynamicVector[String]
    var NwFldDefaults: DynamicVector[String]
    var NwFldUnits: DynamicVector[String]
    var NotInNew: DynamicVector[String]
    var NumRepVarNames: Int
    var OldRepVarName: DynamicVector[String]
    var NewRepVarName: DynamicVector[String]
    var NewRepVarCaution: DynamicVector[String]
    var OTMVarCaution: DynamicVector[Bool]
    var CMtrVarCaution: DynamicVector[Bool]
    var CMtrDVarCaution: DynamicVector[Bool]
    var MaxNameLength: Int
    var MaxAlphaArgsFound: Int
    var MaxNumericArgsFound: Int
    var MaxTotalArgs: Int
    var FullFileName: String
    var FileNamePath: String
    var FileOK: Bool
    var ProcessingIMFFile: Bool
    var FatalError: Bool
    var NumAlphas: Int
    var NumNumbers: Int
    var MakingPretty: Bool
    var CurComment: Int
    
    fn __init__(inout self):
        self.VerString = ""
        self.VersionNum = 0.0
        self.sVersionNum = ""
        self.ProgramPath = ""
        self.IDDFileNameWithPath = ""
        self.NewIDDFileNameWithPath = ""
        self.RepVarFileNameWithPath = ""
        self.IDFRecords = DynamicVector[IDFRecord]()
        self.Comments = DynamicVector[String]()
        self.ObjectDef = DynamicVector[String]()
        self.NumObjectDefs = 0
        self.NumIDFRecords = 0
        self.ObjMinFlds = 0
        self.NwObjMinFlds = 0
        self.Alphas = DynamicVector[String]()
        self.Numbers = DynamicVector[Float64]()
        self.InArgs = DynamicVector[String]()
        self.TempArgs = DynamicVector[String]()
        self.OutArgs = DynamicVector[String]()
        self.AorN = DynamicVector[Bool]()
        self.ReqFld = DynamicVector[Bool]()
        self.FldNames = DynamicVector[String]()
        self.FldDefaults = DynamicVector[String]()
        self.FldUnits = DynamicVector[String]()
        self.NwAorN = DynamicVector[Bool]()
        self.NwReqFld = DynamicVector[Bool]()
        self.NwFldNames = DynamicVector[String]()
        self.NwFldDefaults = DynamicVector[String]()
        self.NwFldUnits = DynamicVector[String]()
        self.NotInNew = DynamicVector[String]()
        self.NumRepVarNames = 0
        self.OldRepVarName = DynamicVector[String]()
        self.NewRepVarName = DynamicVector[String]()
        self.NewRepVarCaution = DynamicVector[String]()
        self.OTMVarCaution = DynamicVector[Bool]()
        self.CMtrVarCaution = DynamicVector[Bool]()
        self.CMtrDVarCaution = DynamicVector[Bool]()
        self.MaxNameLength = 0
        self.MaxAlphaArgsFound = 0
        self.MaxNumericArgsFound = 0
        self.MaxTotalArgs = 0
        self.FullFileName = ""
        self.FileNamePath = ""
        self.FileOK = False
        self.ProcessingIMFFile = False
        self.FatalError = False
        self.NumAlphas = 0
        self.NumNumbers = 0
        self.MakingPretty = False
        self.CurComment = 0


fn SetThisVersionVariables(inout globals_state: GlobalsState) -> None:
    """Set version variables for 9.5 => 9.6 conversion."""
    globals_state.VerString = "Conversion 9.5 => 9.6"
    globals_state.VersionNum = 9.6
    globals_state.sVersionNum = "9.6"
    globals_state.IDDFileNameWithPath = globals_state.ProgramPath.strip() + "V9-5-0-Energy+.idd"
    globals_state.NewIDDFileNameWithPath = globals_state.ProgramPath.strip() + "V9-6-0-Energy+.idd"
    globals_state.RepVarFileNameWithPath = globals_state.ProgramPath.strip() + "Report Variables 9-5-0 to 9-6-0.csv"


fn CreateNewIDFUsingRules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout globals_state: GlobalsState
) -> Bool:
    """
    Create new IDFs based on rules specified by developers.
    """
    
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = " " * 10
    var ios: Int = 0
    
    if first_time:
        first_time = False
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            var full_file_name: String = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                # Would read from input here
                full_file_name = ""
            else:
                if not arg_file:
                    # Would read from file here
                    full_file_name = ""
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if full_file_name.__len__() > 0 and full_file_name[0] == "!":
                    full_file_name = ""
                    continue
            
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.strip()
            
            if full_file_name != "":
                DisplayString("Processing IDF -- " + full_file_name)
                
                var dot_pos: Int = -1
                for i in range(full_file_name.__len__() - 1, -1, -1):
                    if full_file_name[i] == ".":
                        dot_pos = i
                        break
                
                var file_name_path: String = ""
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = MakeLowerCase(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print("assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                # Check file exists
                var file_exists: Bool = False
                # Would check file existence here
                
                if not file_exists:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var out_file_name: String = ""
                    if diff_only:
                        out_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        ShowWarningError(
                            "Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.",
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
                    
                    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
                    for _ in range(globals_state.NumIDFRecords):
                        delete_this_record.push_back(False)
                    
                    # Check for VERSION record
                    no_version = True
                    for num in range(globals_state.NumIDFRecords):
                        if MakeUPPERCase(globals_state.IDFRecords[num].Name) == "VERSION":
                            no_version = False
                            break
                    
                    # Main processing loop
                    DisplayString("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(globals_state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name: String = globals_state.IDFRecords[num].Name
                        var cur_args: Int = 0
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if no_version and num == 0:
                            GetNewObjectDefInIDD("VERSION", globals_state)
                            globals_state.OutArgs[0] = globals_state.sVersionNum
                            cur_args = 1
                            ShowWarningError(
                                "No version found in file, defaulting to " + globals_state.sVersionNum,
                                globals_state
                            )
                            WriteOutIDFLinesAsComments(
                                out_file_name, "Version", cur_args, globals_state.OutArgs,
                                globals_state.NwFldNames, globals_state.NwFldUnits,
                                globals_state
                            )
                        
                        if FindItemInList(object_name, globals_state.ObjectDef, globals_state.NumObjectDefs, globals_state) != 0:
                            GetObjectDefInIDD(object_name, globals_state)
                            
                            var num_alphas: Int = globals_state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = globals_state.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                globals_state.InArgs[i] = globals_state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                globals_state.InArgs[num_alphas + i] = String(globals_state.IDFRecords[num].Numbers[i])
                            
                            cur_args = num_alphas + num_numbers
                        else:
                            var num_alphas: Int = globals_state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = globals_state.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                globals_state.OutArgs[i] = globals_state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                globals_state.OutArgs[num_alphas + i] = String(globals_state.IDFRecords[num].Numbers[i])
                            
                            cur_args = num_alphas + num_numbers
                            WriteOutIDFLinesAsComments(
                                out_file_name, object_name, cur_args, globals_state.OutArgs, 
                                DynamicVector[String](), DynamicVector[String](),
                                globals_state
                            )
                            continue
                        
                        if FindItemInList(MakeUPPERCase(object_name), globals_state.NotInNew, globals_state.NotInNew.__len__(), globals_state) == 0:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            if globals_state.ObjMinFlds != globals_state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        # Process based on object type
                        if not globals_state.MakingPretty:
                            var object_upper: String = MakeUPPERCase(object_name.strip())
                            
                            if object_upper == "VERSION":
                                if globals_state.InArgs[0].__len__() >= 3 and globals_state.InArgs[0][:3] == globals_state.sVersionNum and arg_file:
                                    ShowWarningError(
                                        "File is already at latest version. No new diff file made.",
                                        globals_state
                                    )
                                    latest_version = True
                                    break
                                
                                GetNewObjectDefInIDD(object_name, globals_state)
                                globals_state.OutArgs[0] = globals_state.sVersionNum
                                nodiff = False
                            
                            elif object_upper == "AIRFLOWNETWORK:MULTIZONE:REFERENCECRACKCONDITIONS":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if globals_state.InArgs[1] == "":
                                    globals_state.OutArgs[1] = "20.0"
                            
                            elif object_upper == "AIRLOOPHVAC:OUTDOORAIRSYSTEM":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(3):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if cur_args == 4:
                                    cur_args = 3
                            
                            elif object_upper == "BUILDINGSURFACE:DETAILED":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(4):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                globals_state.OutArgs[4] = ""
                                for i in range(cur_args - 4):
                                    globals_state.OutArgs[5 + i] = globals_state.InArgs[4 + i]
                                cur_args = cur_args + 1
                            
                            elif object_upper == "CEILING:ADIABATIC" or object_upper == "CEILING:INTERZONE" or 
                                 object_upper == "FLOOR:DETAILED" or object_upper == "FLOOR:GROUNDCONTACT" or
                                 object_upper == "FLOOR:ADIABATIC" or object_upper == "FLOOR:INTERZONE" or
                                 object_upper == "ROOFCEILING:DETAILED" or object_upper == "ROOF" or
                                 object_upper == "WALL:DETAILED" or object_upper == "WALL:EXTERIOR" or
                                 object_upper == "WALL:ADIABATIC" or object_upper == "WALL:UNDERGROUND" or
                                 object_upper == "WALL:INTERZONE":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(3):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                globals_state.OutArgs[3] = ""
                                for i in range(cur_args - 3):
                                    globals_state.OutArgs[4 + i] = globals_state.InArgs[3 + i]
                                cur_args = cur_args + 1
                            
                            elif object_upper == "CONTROLLER:MECHANICALVENTILATION":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if MakeUPPERCase(globals_state.OutArgs[3]) == "VENTILATIONRATEPROCEDURE":
                                    globals_state.OutArgs[3] = "Standard62.1VentilationRateProcedure"
                            
                            elif object_upper == "GROUNDHEATEXCHANGER:SYSTEM":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(9):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if cur_args > 9:
                                    for i in range(cur_args - 9):
                                        globals_state.OutArgs[10 + i] = globals_state.InArgs[9 + i]
                                    if globals_state.InArgs[8] == "":
                                        globals_state.OutArgs[9] = "UHFCALC"
                                    cur_args = cur_args + 1
                            
                            elif object_upper == "INTERNALMASS":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(3):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                globals_state.OutArgs[3] = ""
                                for i in range(cur_args - 3):
                                    globals_state.OutArgs[4 + i] = globals_state.InArgs[3 + i]
                                cur_args = cur_args + 1
                            
                            elif object_upper == "SIZING:SYSTEM":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if MakeUPPERCase(globals_state.OutArgs[26]) == "VENTILATIONRATEPROCEDURE":
                                    globals_state.OutArgs[26] = "Standard62.1VentilationRateProcedure"
                            
                            elif object_upper == "PERFORMANCEPRECISIONTRADEOFFS":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                nodiff = False
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                if MakeUPPERCase(globals_state.InArgs[2]) == "MODE06":
                                    globals_state.OutArgs[2] = "Mode07"
                                elif MakeUPPERCase(globals_state.InArgs[2]) == "MODE07":
                                    globals_state.OutArgs[2] = "Mode08"
                            
                            elif object_upper == "OUTPUT:VARIABLE":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                if globals_state.OutArgs[0] == "":
                                    globals_state.OutArgs[0] = "*"
                                    nodiff = False
                                
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    True, False, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == "OUTPUT:METER" or object_upper == "OUTPUT:METER:METERFILEONLY" or
                                 object_upper == "OUTPUT:METER:CUMULATIVE" or object_upper == "OUTPUT:METER:CUMULATIVE:METERFILEONLY":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    1, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == "OUTPUT:TABLE:TIMEBINS":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                if globals_state.OutArgs[0] == "":
                                    globals_state.OutArgs[0] = "*"
                                    nodiff = False
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, True, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE" or
                                 object_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                if globals_state.OutArgs[0] == "":
                                    globals_state.OutArgs[0] = "*"
                                    nodiff = False
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    3, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, False, False, cur_args, written, True, globals_state
                                )
                            
                            elif object_upper == "DEMANDMANAGERASSIGNMENTLIST" or object_upper == "UTILITYCOST:TARIFF":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
                                nodiff = True
                                ScanOutputVariablesForReplacement(
                                    2, False, checkrvi, nodiff, object_name, out_file_name,
                                    False, True, False, cur_args, written, False, globals_state
                                )
                            
                            elif object_upper == "ELECTRICLOADCENTER:DISTRIBUTION":
                                GetNewObjectDefInIDD(object_name, globals_state)
                                for i in range(cur_args):
                                    globals_state.OutArgs[i] = globals_state.InArgs[i]
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
                                if FindItemInList(object_name, globals_state.NotInNew, globals_state.NotInNew.__len__(), globals_state) != 0:
                                    WriteOutIDFLinesAsComments(
                                        out_file_name, object_name, cur_args, globals_state.InArgs,
                                        globals_state.FldNames, globals_state.FldUnits, globals_state
                                    )
                                    written = True
                                else:
                                    GetNewObjectDefInIDD(object_name, globals_state)
                                    for i in range(cur_args):
                                        globals_state.OutArgs[i] = globals_state.InArgs[i]
                                    nodiff = True
                        
                        else:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            for i in range(cur_args):
                                globals_state.OutArgs[i] = globals_state.InArgs[i]
                        
                        if diff_min_fields and nodiff:
                            GetNewObjectDefInIDD(object_name, globals_state)
                            for i in range(cur_args):
                                globals_state.OutArgs[i] = globals_state.InArgs[i]
                            nodiff = False
                            for arg in range(cur_args, globals_state.NwObjMinFlds):
                                globals_state.OutArgs[arg] = globals_state.NwFldDefaults[arg]
                            cur_args = max(globals_state.NwObjMinFlds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            CheckSpecialObjects(
                                out_file_name, object_name, cur_args, globals_state.OutArgs,
                                globals_state.NwFldNames, globals_state.NwFldUnits,
                                written, globals_state
                            )
                        
                        if not written:
                            WriteOutIDFLines(
                                out_file_name, object_name, cur_args, globals_state.OutArgs,
                                globals_state.NwFldNames, globals_state.NwFldUnits, globals_state
                            )
                    
                    DisplayString("Processing IDF -- Processing idf objects complete.")
                    
                    if GetNumSectionsFound("Report Variable Dictionary", globals_state) > 0:
                        object_name = "Output:VariableDictionary"
                        GetNewObjectDefInIDD(object_name, globals_state)
                        globals_state.OutArgs[0] = "Regular"
                        cur_args = 1
                        WriteOutIDFLines(
                            out_file_name, object_name, cur_args, globals_state.OutArgs,
                            globals_state.NwFldNames, globals_state.NwFldUnits, globals_state
                        )
                    
                    ProcessRviMviFiles(file_name_path, "rvi", globals_state)
                    ProcessRviMviFiles(file_name_path, "mvi", globals_state)
                    CloseOut(globals_state)
                
                else:
                    ProcessRviMviFiles(file_name_path, "rvi", globals_state)
                    ProcessRviMviFiles(file_name_path, "mvi", globals_state)
            
            else:
                end_of_file = True
            
            CreateNewName("Reallocate", globals_state)
        
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
        var err_flag: Bool = False
        copyfile(
            file_name_path + "." + arg_idf_extension,
            file_name_path + "." + arg_idf_extension + "old",
            err_flag
        )
        copyfile(
            file_name_path + "." + arg_idf_extension + "new",
            file_name_path + "." + arg_idf_extension,
            err_flag
        )
        
        # Would check file existence here
        copyfile(
            file_name_path + ".rvi",
            file_name_path + ".rviold",
            err_flag
        )
        
        copyfile(
            file_name_path + ".rvinew",
            file_name_path + ".rvi",
            err_flag
        )
        
        copyfile(
            file_name_path + ".mvi",
            file_name_path + ".mviold",
            err_flag
        )
        
        copyfile(
            file_name_path + ".mvinew",
            file_name_path + ".mvi",
            err_flag
        )
    
    return end_of_file


fn DisplayString(message: String) -> None:
    """Display a message."""
    print(message)


fn MakeUPPERCase(s: String) -> String:
    """Convert string to uppercase."""
    return s.upper()


fn MakeLowerCase(s: String) -> String:
    """Convert string to lowercase."""
    return s.lower()


fn FindItemInList(item: String, list_items: DynamicVector[String], list_size: Int, inout globals_state: GlobalsState) -> Int:
    """Find item in list, return index or 0."""
    for i in range(list_size):
        if i < list_items.__len__() and item == list_items[i]:
            return i + 1
    return 0


fn GetObjectDefInIDD(object_name: String, inout globals_state: GlobalsState) -> None:
    """Get object definition from old IDD."""
    pass


fn GetNewObjectDefInIDD(object_name: String, inout globals_state: GlobalsState) -> None:
    """Get object definition from new IDD."""
    pass


fn WriteOutIDFLinesAsComments(filename: String, object_name: String, cur_args: Int, out_args: DynamicVector[String],
                               fld_names: DynamicVector[String], fld_units: DynamicVector[String], 
                               inout globals_state: GlobalsState) -> None:
    """Write IDF lines as comments."""
    pass


fn WriteOutIDFLines(filename: String, object_name: String, cur_args: Int, out_args: DynamicVector[String],
                     fld_names: DynamicVector[String], fld_units: DynamicVector[String], 
                     inout globals_state: GlobalsState) -> None:
    """Write IDF lines."""
    pass


fn ScanOutputVariablesForReplacement(field_num: Int, del_this: Bool, checkrvi: Bool, nodiff: Bool,
                                      object_name: String, filename: String, out_var: Bool, mtr_var: Bool,
                                      timebin_var: Bool, cur_args: Int, written: Bool, is_sensor: Bool,
                                      inout globals_state: GlobalsState) -> None:
    """Scan and replace output variables."""
    pass


fn CheckSpecialObjects(filename: String, object_name: String, cur_args: Int, out_args: DynamicVector[String],
                       fld_names: DynamicVector[String], fld_units: DynamicVector[String], written: Bool, 
                       inout globals_state: GlobalsState) -> None:
    """Check for special object types."""
    pass


fn ShowWarningError(message: String, inout globals_state: GlobalsState) -> None:
    """Show warning error."""
    print("Warning: " + message)


fn ProcessRviMviFiles(file_path: String, ext: String, inout globals_state: GlobalsState) -> None:
    """Process RVI/MVI files."""
    pass


fn CreateNewName(mode: String, inout globals_state: GlobalsState) -> None:
    """Create new name."""
    pass


fn CloseOut(inout globals_state: GlobalsState) -> None:
    """Close output."""
    pass


fn GetNumSectionsFound(section_name: String, inout globals_state: GlobalsState) -> Int:
    """Get number of sections found."""
    return 0


fn ProcessInput(idd_file: String, new_idd_file: String, idf_file: String, inout globals_state: GlobalsState) -> None:
    """Process input file."""
    pass


fn copyfile(src: String, dst: String, inout err_flag: Bool) -> None:
    """Copy file."""
    # Would implement file copy here
    pass
