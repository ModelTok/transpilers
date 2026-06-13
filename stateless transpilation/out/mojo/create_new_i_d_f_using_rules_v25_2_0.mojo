from typing import Optional, List
from math import max as math_max

# EXTERNAL DEPS (to wire in glue):
# DataStringGlobals: ProgNameConversion, program_path
# DataVCompareGlobals: IDFRecords, Comments, ObjectDef, NumObjectDefs, Alphas, Numbers, InArgs, TempArgs, OutArgs,
#                      AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits,
#                      NotInNew, CurComment, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution,
#                      MakingPretty, ProcessingIMFFile, FatalError, FullFileName, FileNamePath, Auditf, NumIDFRecords,
#                      MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, MaxNameLength, blank, NumRepVarNames, FileOK
# InputProcessor: ProcessInput, GetNewUnitNumber, GetNewObjectDefInIDD, GetObjectDefInIDD
# VCompareGlobalRoutines: ScanOutputVariablesForReplacement, CheckSpecialObjects, WriteOutIDFLinesAsComments, WriteOutIDFLines
# General: TrimTrailZeros, MakeUPPERCase, MakeLowerCase, FindItemInList
# DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# Other: DisplayString, writePreprocessorObject, ProcessRviMviFiles, CloseOut, CreateNewName, copyfile, GetNumSectionsFound


struct ExternalState:
    var program_path: String
    var full_file_name: String
    var file_name_path: String
    var audit_file_unit: Int32
    var num_idf_records: Int32
    var idf_records: InlineArray[String, 10000]
    var comments: InlineArray[String, 10000]
    var object_def: InlineArray[String, 1000]
    var num_object_defs: Int32
    var alphas: InlineArray[String, 1000]
    var numbers: InlineArray[Float32, 1000]
    var in_args: InlineArray[String, 1000]
    var temp_args: InlineArray[String, 1000]
    var out_args: InlineArray[String, 1000]
    var aor_n: InlineArray[Bool, 1000]
    var req_fld: InlineArray[Bool, 1000]
    var fld_names: InlineArray[String, 1000]
    var fld_defaults: InlineArray[String, 1000]
    var fld_units: InlineArray[String, 1000]
    var nw_aor_n: InlineArray[Bool, 1000]
    var nw_req_fld: InlineArray[Bool, 1000]
    var nw_fld_names: InlineArray[String, 1000]
    var nw_fld_defaults: InlineArray[String, 1000]
    var nw_fld_units: InlineArray[String, 1000]
    var not_in_new: InlineArray[String, 100]
    var cur_comment: Int32
    var old_rep_var_name: InlineArray[String, 1000]
    var new_rep_var_name: InlineArray[String, 1000]
    var new_rep_var_caution: InlineArray[String, 1000]
    var otm_var_caution: InlineArray[Bool, 1000]
    var cmtr_var_caution: InlineArray[Bool, 1000]
    var cmtr_d_var_caution: InlineArray[Bool, 1000]
    var making_pretty: Bool
    var processing_imf_file: Bool
    var fatal_error: Bool
    var max_alpha_args_found: Int32
    var max_numeric_args_found: Int32
    var max_total_args: Int32
    var max_name_length: Int32
    var blank_str: String
    var num_rep_var_names: Int32
    var file_ok: Bool
    var program_name_conversion: String
    var ver_string: String
    var version_num: Float32
    var s_version_num: String
    var s_version_num_four_chars: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String


@always_inline
fn set_this_version_variables(inout state: ExternalState) -> None:
    state.ver_string = "Conversion 25.1 => 25.2"
    state.version_num = 25.2
    state.s_version_num = "***"
    state.s_version_num_four_chars = "25.2"
    state.idd_file_name_with_path = state.program_path + "V25-1-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V25-2-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 25-1-0 to 25-2-0.csv"


fn create_new_idf_using_rules(
    inout state: ExternalState,
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int32,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    display_string_fn: fn(String) -> None,
    get_new_unit_number_fn: fn() -> Int32,
    process_input_fn: fn(String, String, String) -> None,
    get_new_object_def_idd_fn: fn(String, inout List[Any]) -> None,
    get_object_def_idd_fn: fn(String, inout List[Any]) -> None,
    write_out_idf_lines_as_comments_fn: fn(Int32, String, Int32, InlineArray[String, 1000], InlineArray[String, 1000], InlineArray[String, 1000]) -> None,
    scan_output_variables_for_replacement_fn: fn(Int32, inout List[Bool], inout List[Bool], inout List[Bool], String, Int32, Bool, Bool, Bool, inout List[Int32], inout List[Bool], Bool) -> None,
    check_special_objects_fn: fn(Int32, String, Int32, InlineArray[String, 1000], InlineArray[String, 1000], InlineArray[String, 1000], inout List[Bool]) -> None,
    write_out_idf_lines_fn: fn(Int32, String, Int32, InlineArray[String, 1000], InlineArray[String, 1000], InlineArray[String, 1000]) -> None,
    show_warning_error_fn: fn(String, Int32) -> None,
    find_item_in_list_fn: fn(String, InlineArray[String, 100], Int32) -> Int32,
    make_upper_case_fn: fn(String) -> String,
    make_lower_case_fn: fn(String) -> String,
    trim_trail_zeros_fn: fn(String) -> String,
    write_preprocessor_object_fn: fn(Int32, String, String, String) -> None,
    get_num_sections_found_fn: fn(String) -> Int32,
    process_rvi_mvi_files_fn: fn(String, String) -> None,
    close_out_fn: fn() -> None,
    create_new_name_fn: fn(String, inout List[String], String) -> None,
    copyfile_fn: fn(String, String, inout List[Bool]) -> None,
    show_message_fn: fn(String) -> None,
) -> None:
    let fmta = "(A)"
    var first_time = True
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file[0] = False
    var ios: Int32 = 0
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file[0]:
            var full_file_name: String
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="", flush=True)
                full_file_name = input()
                state.full_file_name = full_file_name
            else:
                if not arg_file:
                    try:
                        var f: FileHandle = open(in_lfn, "r")
                        full_file_name = f.readline().strip()
                        ios = 0
                        f.close()
                    except:
                        full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if full_file_name.startswith("!"):
                    full_file_name = ""
                    continue
            
            var units_arg = ""
            if ios != 0:
                full_file_name = ""
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                state.full_file_name = full_file_name
                display_string_fn("Processing IDF -- " + full_file_name)
                
                try:
                    var f: FileHandle = open(state.audit_file_unit, "a")
                    f.write(" Processing IDF -- " + full_file_name + "\n")
                    f.close()
                except:
                    pass
                
                var dot_pos = full_file_name.rfind(".")
                var file_name_path: String
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case_fn(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    try:
                        var f: FileHandle = open(state.audit_file_unit, "a")
                        f.write(" ..assuming file extension of .idf\n")
                        f.close()
                    except:
                        pass
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                state.file_name_path = file_name_path
                var dif_lfn = get_new_unit_number_fn()
                
                var file_ok: Bool = False
                try:
                    var f: FileHandle = open(full_file_name, "r")
                    file_ok = True
                    f.close()
                except:
                    file_ok = False
                
                state.file_ok = file_ok
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    try:
                        var f: FileHandle = open(state.audit_file_unit, "a")
                        f.write("File not found=" + full_file_name + "\n")
                        f.close()
                    except:
                        pass
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var output_filename: String
                    if diff_only:
                        output_filename = file_name_path + "." + local_file_extension + "dif"
                    else:
                        output_filename = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        show_warning_error_fn("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.audit_file_unit)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    process_input_fn(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var num_alphas: Int32 = 0
                    var num_numbers: Int32 = 0
                    var cur_args: Int32 = 0
                    var na: Int32 = 0
                    var nn: Int32 = 0
                    var nw_num_args: Int32 = 0
                    var nw_obj_min_flds: Int32 = 0
                    var num_args: Int32 = 0
                    var obj_min_flds: Int32 = 0
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case_fn(state.idf_records[num]) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var delete_this_record: InlineArray[Bool, 10000] = InlineArray[Bool, 10000](fill=False)
                    
                    display_string_fn("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        
                        var object_name = state.idf_records[num]
                        var object_name_upper = make_upper_case_fn(object_name)
                        
                        if object_name_upper == "VERSION":
                            if state.in_args[0].prefix(4) == state.s_version_num_four_chars and arg_file:
                                show_warning_error_fn("File is already at latest version.  No new diff file made.", state.audit_file_unit)
                                latest_version = True
                                break
                            
                            state.out_args[0] = state.s_version_num_four_chars
                            nodiff = False
                        
                        elif object_name_upper == "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR:MULTISPEED":
                            nodiff = False
                            for i in range(11):
                                state.out_args[i] = state.in_args[i]
                            state.out_args[11] = " "
                            for i in range(12, cur_args):
                                state.out_args[i] = state.in_args[i]
                        
                        elif object_name_upper == "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:COOLING:DX:VARIABLESPEED":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:HEATING:DX:VARIABLESPEED":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = ""
                            for i in range(1, cur_args):
                                state.out_args[i+1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == "GROUNDHEATEXCHANGER:SYSTEM":
                            if cur_args > 10:
                                nodiff = False
                                for i in range(10):
                                    state.out_args[i] = state.in_args[i]
                                state.out_args[10] = ""
                                state.out_args[11] = ""
                                for i in range(10, cur_args):
                                    state.out_args[i+2] = state.in_args[i]
                                cur_args = cur_args + 2
                            else:
                                nodiff = True
                                for i in range(cur_args):
                                    state.out_args[i] = state.in_args[i]
                        
                        elif object_name_upper == "OUTPUT:VARIABLE":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == state.blank_str:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_name_upper in ["OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_name_upper == "OUTPUT:TABLE:TIMEBINS":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == state.blank_str:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_name_upper in ["EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == state.blank_str:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_name_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_name_upper == "OUTPUT:TABLE:MONTHLY":
                            nodiff = True
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                        
                        elif object_name_upper == "METER:CUSTOM":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_name_upper == "METER:CUSTOMDECREMENT":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_name_upper in ["DEMANDMANAGERASSIGNMENTLIST", "UTILITYCOST:TARIFF"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_name_upper == "ELECTRICLOADCENTER:DISTRIBUTION":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        else:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            write_out_idf_lines_fn(dif_lfn, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    display_string_fn("Processing IDF -- Processing idf objects complete.")
                    
                    if get_num_sections_found_fn("Report Variable Dictionary") > 0:
                        var output_var_dict_name = "Output:VariableDictionary"
                        state.out_args[0] = "Regular"
                        write_out_idf_lines_fn(dif_lfn, output_var_dict_name, 1, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    process_rvi_mvi_files_fn(state.file_name_path, "rvi")
                    process_rvi_mvi_files_fn(state.file_name_path, "mvi")
                    close_out_fn()
                else:
                    process_rvi_mvi_files_fn(state.file_name_path, "rvi")
                    process_rvi_mvi_files_fn(state.file_name_path, "mvi")
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
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var err_flag: List[Bool] = List[Bool]([False])
        copyfile_fn(state.file_name_path + "." + arg_idf_extension, state.file_name_path + "." + arg_idf_extension + "old", err_flag)
        copyfile_fn(state.file_name_path + "." + arg_idf_extension + "new", state.file_name_path + "." + arg_idf_extension, err_flag)
        
        var rvi_file = state.file_name_path + ".rvi"
        try:
            var f: FileHandle = open(rvi_file, "r")
            f.close()
            copyfile_fn(rvi_file, state.file_name_path + ".rviold", err_flag)
        except:
            pass
        
        var rvi_new_file = state.file_name_path + ".rvinew"
        try:
            var f: FileHandle = open(rvi_new_file, "r")
            f.close()
            copyfile_fn(rvi_new_file, state.file_name_path + ".rvi", err_flag)
        except:
            pass
        
        var mvi_file = state.file_name_path + ".mvi"
        try:
            var f: FileHandle = open(mvi_file, "r")
            f.close()
            copyfile_fn(mvi_file, state.file_name_path + ".mviold", err_flag)
        except:
            pass
        
        var mvi_new_file = state.file_name_path + ".mvinew"
        try:
            var f: FileHandle = open(mvi_new_file, "r")
            f.close()
            copyfile_fn(mvi_new_file, state.file_name_path + ".mvi", err_flag)
        except:
            pass
