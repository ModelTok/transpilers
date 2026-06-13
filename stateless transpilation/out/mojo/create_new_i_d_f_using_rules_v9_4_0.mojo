# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ProgNameConversion, ProgramPath, Blank, IDFRecords, Comments, NumIDFRecords,
#   IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath,
#   MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, Alphas, Numbers, InArgs,
#   TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults,
#   NwFldUnits, OutArgs, Auditf, NumAlphas, NumNumbers, NwNumArgs, NwObjMinFlds, ObjectDef, NumObjectDefs,
#   ObjMinFlds, FatalError, ProcessingIMFFile
# - DataVCompareGlobals: (shared state variables)
# - InputProcessor: GetNumObjectsFound, GetObjectItem
# - VCompareGlobalRoutines: ScanOutputVariablesForReplacement, CheckSpecialObjects, WriteOutIDFLines,
#   WriteOutIDFLinesAsComments, DisplayString, CreateNewName, ProcessRviMviFiles, CloseOut, MakeUPPERCase,
#   MakeLowerCase, FindItemInList, SameString, MakingPretty, NotInNew, OldRepVarName, NewRepVarName,
#   NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution
# - General: TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

from math import *

struct ExternalState:
    pass

var version_string: String = String("Conversion 9.3 => 9.4")
var version_num: Float64 = 9.4
var s_version_num: String = String("9.4")
var idd_file_name_with_path: String = String()
var new_idd_file_name_with_path: String = String()
var rep_var_file_name_with_path: String = String()

fn set_this_version_variables(program_path: String, inout global_state: ExternalState) -> None:
    version_string = String("Conversion 9.3 => 9.4")
    version_num = 9.4
    s_version_num = String("9.4")
    idd_file_name_with_path = program_path + String("V9-3-0-Energy+.idd")
    new_idd_file_name_with_path = program_path + String("V9-4-0-Energy+.idd")
    rep_var_file_name_with_path = program_path + String("Report Variables 9-3-0 to 9-4-0.csv")

fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout global_state: ExternalState,
    program_path: String
) -> None:
    alias BLANK = String()
    alias FMT_A = String("(A)")
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    var first_time: Bool = True
    
    while still_working:
        var exit_because_bad_file: Bool = False
        while not end_of_file:
            var full_file_name: String = String()
            
            if ask_for_input:
                print("Enter input file name, with path")
                # Would read from input
                pass
            else:
                if not arg_file:
                    # Would read from InLfn
                    pass
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = BLANK
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = BLANK
                    continue
            
            var units_arg: String = BLANK
            if ios != 0:
                full_file_name = BLANK
            
            # Strip leading whitespace
            while len(full_file_name) > 0 and full_file_name[0] == ' ':
                full_file_name = full_file_name[1:]
            
            if len(full_file_name) > 0:
                print("Processing IDF -- " + full_file_name)
                
                var dot_pos: Int = -1
                for i in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[i] == '.':
                        dot_pos = i
                        break
                
                var file_name_path: String = String()
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = String()
                    for i in range(dot_pos + 1, len(full_file_name)):
                        if full_file_name[i] >= 'A' and full_file_name[i] <= 'Z':
                            local_file_extension += String(chr(ord(full_file_name[i]) + 32))
                        else:
                            local_file_extension += String(full_file_name[i])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name + String(".idf")
                    local_file_extension = String("idf")
                
                # Check if file exists (stub)
                var file_ok: Bool = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == String("idf") or local_file_extension == String("imf"):
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var out_file: String = String()
                    if diff_only:
                        out_file = file_name_path + String(".") + local_file_extension + String("dif")
                    else:
                        out_file = file_name_path + String(".") + local_file_extension + String("new")
                    
                    if local_file_extension == String("imf"):
                        # ShowWarningError
                        pass
                    
                    # Preprocessing
                    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
                    var output_diagnostics_names: DynamicVector[String] = DynamicVector[String]()
                    var num_output_diagnostics_names: Int = 0
                    var already_processed_one_output_diagnostic: Bool = False
                    var meter_custom_names: DynamicVector[String] = DynamicVector[String]()
                    var tot_meter_custom: Int = 0
                    var tot_meter_custom_decr: Int = 0
                    var throw_python_warning: Bool = True
                    
                    # Processing section
                    print("Processing IDF -- Processing idf objects . . .")
                    
                    # Main object processing loop would go here
                    
                    print("Processing IDF -- Processing idf objects complete.")
            else:
                end_of_file = True
            break
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False

fn replace_fuel_name_with_end_use_subcategory(inout in_out_arg: String, inout no_diff_arg: Bool) -> None:
    var len_in_arg: Int = len(in_out_arg)
    
    var n_ea: Int = -1
    var n_eca: Int = -1
    var n_ga: Int = -1
    var n_nga: Int = -1
    var n_fo1a: Int = -1
    var n_fo1na: Int = -1
    var n_fo2a: Int = -1
    var n_fo2na: Int = -1
    
    # Find leading resource type
    if in_out_arg.find(String("Electric:")) == 0:
        n_ea = 0
    if in_out_arg.find(String("Electricity:")) == 0:
        n_eca = 0
    if in_out_arg.find(String("Gas:")) == 0:
        n_ga = 0
    if in_out_arg.find(String("NaturalGas:")) == 0:
        n_nga = 0
    if in_out_arg.find(String("FuelOil#1:")) == 0:
        n_fo1a = 0
    if in_out_arg.find(String("FuelOilNo1:")) == 0:
        n_fo1na = 0
    if in_out_arg.find(String("FuelOil#2:")) == 0:
        n_fo2a = 0
    if in_out_arg.find(String("FuelOilNo2:")) == 0:
        n_fo2na = 0
    
    var n_eb: Int = -1
    var n_ecb: Int = -1
    var n_gb: Int = -1
    var n_ngb: Int = -1
    var n_fo1b: Int = -1
    var n_fo1nb: Int = -1
    var n_fo2b: Int = -1
    var n_fo2nb: Int = -1
    
    # Find trailing resource type
    var search_pos: Int = 0
    for i in range(len(in_out_arg)):
        if i <= len(in_out_arg) - 9:
            if in_out_arg[i] == ':' and in_out_arg[i+1:] == String("Electric"):
                n_eb = i
    
    if n_ea == 0 and n_eca == -1:
        in_out_arg = String("Electricity:") + in_out_arg[9:]
        no_diff_arg = False
    elif n_ga == 0 and n_nga == -1:
        in_out_arg = String("NaturalGas:") + in_out_arg[4:]
        no_diff_arg = False
    elif n_fo1a == 0 and n_fo1na == -1:
        in_out_arg = String("FuelOilNo1:") + in_out_arg[10:]
        no_diff_arg = False
    elif n_fo2a == 0 and n_fo2na == -1:
        in_out_arg = String("FuelOilNo2:") + in_out_arg[10:]
        no_diff_arg = False
    elif n_eb > 0 and n_ecb == -1:
        in_out_arg = in_out_arg[:n_eb] + String(":Electricity")
        no_diff_arg = False
    elif n_gb > 0 and n_ngb == -1:
        in_out_arg = in_out_arg[:n_gb] + String(":NaturalGas")
        no_diff_arg = False
    elif n_fo1b > 0 and n_fo1nb == -1:
        in_out_arg = in_out_arg[:n_fo1b] + String(":FuelOilNo1")
        no_diff_arg = False
    elif n_fo2b > 0 and n_fo2nb == -1:
        in_out_arg = in_out_arg[:n_fo2b] + String(":FuelOilNo2")
        no_diff_arg = False
