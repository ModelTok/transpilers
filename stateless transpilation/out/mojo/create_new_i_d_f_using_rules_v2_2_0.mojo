# EXTERNAL DEPS (to wire in glue):
# From DataStringGlobals:
#   - VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath
#   - RepVarFileNameWithPath, ProgramPath, MaxNameLength, blank, FullFileName
#   - ProcessingIMFFile, Auditf (file handle)
# From DataVCompareGlobals:
#   - IDFRecords, FatalError, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
#   - NumIDFRecords, CurComment, OldRepVarName, NewRepVarName, NumRepVarNames
#   - NotInNew, ObjectDef, NumObjectDefs, MakingPretty
# From InputProcessor:
#   - GetNewObjectDefInIDD, GetObjectDefInIDD, ProcessInput, FindItemInList
#   - WriteOutIDFLines, WriteOutIDFLinesAsComments
# From VCompareGlobalRoutines:
#   - DisplayString, MakeUPPERCase, MakeLowerCase, ScanOutputVariablesForReplacement
#   - CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName
#   - ProcessNumber, samestring, copyfile
# From DataGlobals:
#   - ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# External functions:
#   - GetNewUnitNumber() -> int
#   - FindNumber(str, str) -> int
#   - TrimTrailZeros(str) -> str

import sys
from math import *

fn set_this_version_variables(
    inout data_string_globals: StringGlobalsData,
) -> None:
    """SetThisVersionVariables equivalent"""
    data_string_globals.VerString = "Conversion 2.1 => 2.2"
    data_string_globals.VersionNum = 2.0
    data_string_globals.IDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + "V2-1-0-Energy+.idd"
    data_string_globals.NewIDDFileNameWithPath = data_string_globals.ProgramPath.rstrip() + "V2-2-0-Energy+.idd"
    data_string_globals.RepVarFileNameWithPath = data_string_globals.ProgramPath.rstrip() + "Report Variables 2-1-0-023 to 2-2-0.csv"


fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: List[String],
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout data_string_globals: StringGlobalsData,
    inout data_v_compare_globals: VCompareGlobalsData,
    inout input_processor: InputProcessorData,
    inout general: GeneralData,
    inout data_globals: GlobalsData,
    external_funcs: Dict[String, Callable],
) -> None:
    """CreateNewIDFUsingRules equivalent"""
    
    var max_name_length: Int = data_string_globals.MaxNameLength
    var blank: String = data_string_globals.blank
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var local_file_extension: String = arg_idf_extension if arg_idf_extension else " "
    end_of_file[0] = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file[0]:
            var full_file_name: String
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # Note: Mojo doesn't have built-in input(); would need wrapper
                # For now, representing as placeholder
                full_file_name = ""
            else:
                if not arg_file:
                    try:
                        full_file_name = next(in_lfn)
                        ios = 0
                    except:
                        full_file_name = blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == "!":
                    full_file_name = blank
                    continue
            
            var units_arg: String = blank
            if ios != 0:
                full_file_name = blank
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != blank:
                data_string_globals.FullFileName = full_file_name
                external_funcs["DisplayString"]("Processing IDF -- " + full_file_name.rstrip())
                data_globals.Auditf.write(" Processing IDF -- " + full_file_name.rstrip() + "\n")
                
                var dot_pos: Int = full_file_name.rfind(".")
                var file_name_path: String
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    data_globals.Auditf.write(" ..assuming file extension of .idf\n")
                    full_file_name = full_file_name.rstrip() + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = external_funcs["GetNewUnitNumber"]()
                var file_ok: Bool = True
                try:
                    pass
                except:
                    file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_file_name.rstrip())
                    data_globals.Auditf.write("File not found=" + full_file_name.rstrip() + "\n")
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ("idf", "imf"):
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_file_name: String
                    if diff_only:
                        dif_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    var dif_file = open(dif_file_name, "w")
                    
                    if local_file_extension == "imf":
                        external_funcs["ShowWarningError"](
                            "Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.",
                            data_globals.Auditf
                        )
                        data_string_globals.ProcessingIMFFile = True
                    else:
                        data_string_globals.ProcessingIMFFile = False
                    
                    external_funcs["ProcessInput"](
                        data_string_globals.IDDFileNameWithPath,
                        data_string_globals.NewIDDFileNameWithPath,
                        full_file_name,
                        data_v_compare_globals,
                        input_processor,
                        external_funcs
                    )
                    
                    if data_v_compare_globals.FatalError:
                        exit_because_bad_file = True
                        dif_file.close()
                        break
                    
                    var num_idf_records: Int = data_v_compare_globals.NumIDFRecords
                    var max_total_args: Int = data_v_compare_globals.MaxTotalArgs
                    
                    var alphas = InlineArray[String, 5000]()
                    var numbers = InlineArray[Float64, 5000]()
                    var in_args = InlineArray[String, 5000]()
                    var a_or_n = InlineArray[Bool, 5000]()
                    var req_fld = InlineArray[Bool, 5000]()
                    var fld_names = InlineArray[String, 5000]()
                    var fld_defaults = InlineArray[String, 5000]()
                    var fld_units = InlineArray[String, 5000]()
                    var nw_a_or_n = InlineArray[Bool, 5000]()
                    var nw_req_fld = InlineArray[Bool, 5000]()
                    var nw_fld_names = InlineArray[String, 5000]()
                    var nw_fld_defaults = InlineArray[String, 5000]()
                    var nw_fld_units = InlineArray[String, 5000]()
                    var out_args = InlineArray[String, 5000]()
                    var match_arg = InlineArray[Bool, 5000]()
                    var delete_this_record = InlineArray[Bool, 5000]()
                    
                    for i in range(num_idf_records):
                        alphas[i] = blank
                        numbers[i] = 0.0
                        delete_this_record[i] = False
                    
                    var idf_records = data_v_compare_globals.IDFRecords
                    
                    for num in range(num_idf_records):
                        if idf_records[num]["Name"].upper() == "CONNECTION COMPONENT:PLANTLOOP":
                            conn_comp = True
                        if idf_records[num]["Name"].upper() == "CONNECTION COMPONENT:PLANTLOOP:CONTROLLED":
                            conn_comp_ctrl = True
                    
                    if conn_comp or conn_comp_ctrl:
                        var primary_side_name: String = blank
                        var secondary_side_name: String = blank
                        var branch_primary_name: String = blank
                        var branch_list_primary_name: String = blank
                        var branch_secondary_name: String = blank
                        var branch_list_secondary_name: String = blank
                        var secondary_setpoint_manager_node_name: String = blank
                        var secondary_setpoint_manager_node_list_name: String = blank
                        var primary_loop_num: Int = 0
                        
                        var plant_old_demand_branch_list_name: String = blank
                        var plant_old_demand_connector_list_name: String = blank
                        var plant_loop_primary_demand_inlet_node_name: String = blank
                        var plant_loop_primary_demand_outlet_node_name: String = blank
                        var plant_loop_secondary_supply_inlet_node_name: String = blank
                        var plant_loop_secondary_supply_outlet_node_name: String = blank
                        
                        for num in range(num_idf_records):
                            if idf_records[num]["Name"].upper() not in ("CONNECTION COMPONENT:PLANTLOOP", "CONNECTION COMPONENT:PLANTLOOP:CONTROLLED"):
                                continue
                            
                            primary_side_name = idf_records[num]["Alphas"][1].upper()
                            secondary_side_name = idf_records[num]["Alphas"][3].upper()
                            dif_file.write("! connection component, name=" + idf_records[num]["Alphas"][0] +
                                          ", primary side=" + primary_side_name +
                                          ", secondary side=" + secondary_side_name + "\n")
                            delete_this_record[num] = True
                            
                            for num1 in range(num_idf_records):
                                if idf_records[num1]["Name"].upper() != "BRANCH":
                                    continue
                                if idf_records[num1]["Alphas"][3].upper() == primary_side_name:
                                    branch_primary_name = idf_records[num1]["Alphas"][0].upper()
                                    delete_this_record[num1] = True
                                    dif_file.write("! primary side branch=" + branch_primary_name + "\n")
                                if idf_records[num1]["Alphas"][3].upper() == secondary_side_name:
                                    branch_secondary_name = idf_records[num1]["Alphas"][0].upper()
                                    delete_this_record[num1] = True
                                    dif_file.write("! secondary side branch=" + branch_secondary_name + "\n")
                    
                    var no_version: Bool = True
                    for num in range(num_idf_records):
                        if idf_records[num]["Name"].upper() == "VERSION":
                            no_version = False
                            break
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            dif_file.write("! Deleting: " + idf_records[num]["Name"] + ":" + idf_records[num]["Alphas"][0] + "\n")
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name: String = idf_records[num]["Name"]
                        
                        if object_name.upper() in ("SKY RADIANCE DISTRIBUTION", "AIRFLOW MODEL", "GENERATOR:FC:BATTERY DATA"):
                            continue
                        
                        if object_name.upper() == "WATER HEATER:SIMPLE":
                            dif_file.write("! The WATER HEATER:SIMPLE object has been deleted\n")
                            continue
                        
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        var cur_args: Int = 0
                        
                        if not data_v_compare_globals.MakingPretty:
                            var object_upper: String = object_name.upper()
                            
                            if object_upper == "VERSION":
                                external_funcs["GetNewObjectDefInIDD"](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = "2.2"
                                no_diff = False
                            
                            elif object_upper == "DOMESTIC HOT WATER":
                                external_funcs["GetNewObjectDefInIDD"](
                                    "WATER USE EQUIPMENT", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[6]
                                out_args[2] = in_args[3]
                                out_args[3] = in_args[4]
                                out_args[4] = blank
                                out_args[5] = blank
                                out_args[6] = in_args[5]
                                cur_args = 7
                                written = True
                            
                            elif object_upper == "REPORT VARIABLE":
                                external_funcs["GetNewObjectDefInIDD"](
                                    object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units,
                                    data_v_compare_globals, input_processor
                                )
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = "*"
                                    no_diff = False
                        
                        if not written:
                            external_funcs["WriteOutIDFLines"](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units,
                                data_v_compare_globals, external_funcs
                            )
                    
                    dif_file.close()
                    
                    if check_rvi:
                        external_funcs["ProcessRviMviFiles"](file_name_path, "rvi", data_v_compare_globals, external_funcs)
                        external_funcs["ProcessRviMviFiles"](file_name_path, "mvi", data_v_compare_globals, external_funcs)
                    
                    external_funcs["CloseOut"](data_v_compare_globals, external_funcs)
                
                else:
                    external_funcs["ProcessRviMviFiles"](file_name_path, "rvi", data_v_compare_globals, external_funcs)
                    external_funcs["ProcessRviMviFiles"](file_name_path, "mvi", data_v_compare_globals, external_funcs)
            
            else:
                end_of_file[0] = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
