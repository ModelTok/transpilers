from math import *
from collections import InlineArray

# EXTERNAL DEPS (to wire in glue):
# ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList, GetNumSectionsFound, GetNewUnitNumber, GetFieldOrIDDDefault from InputProcessor
# IDFRecords, Comments, NumIDFRecords, Alphas, Numbers, etc. from DataVCompareGlobals
# ProgNameConversion from DataStringGlobals
# ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError from DataGlobals
# Various processing functions from VCompareGlobalRoutines

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[Float]
    var commt_s: Int
    var commt_e: Int

struct ObjectDef:
    var name: String
    var num_args: Int

struct VCompareState:
    var ver_string: String
    var version_num: Float
    var s_version_num: String
    var s_version_num_four_chars: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var num_idf_records: Int
    var alphas: List[String]
    var numbers: List[Float]
    var in_args: List[String]
    var temp_args: List[String]
    var a_or_n: List[Bool]
    var req_fld: List[Bool]
    var fld_names: List[String]
    var fld_defaults: List[String]
    var fld_units: List[String]
    var nw_a_or_n: List[Bool]
    var nw_req_fld: List[Bool]
    var nw_fld_names: List[String]
    var nw_fld_defaults: List[String]
    var nw_fld_units: List[String]
    var out_args: List[String]
    var object_def: List[ObjectDef]
    var num_object_defs: Int
    var fatal_error: Bool
    var processing_imf_file: Bool
    var making_pretty: Bool
    var full_file_name: String
    var file_name_path: String
    var auditf: String
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var not_in_new: List[String]
    var max_name_length: Int
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var new_rep_var_caution: List[String]
    var num_rep_var_names: Int
    var otm_var_caution: List[Bool]
    var cmtr_var_caution: List[Bool]
    var cmtr_d_var_caution: List[Bool]
    var file_ok: Bool
    var end_of_file: Bool
    var obj_min_flds: Int
    var nw_obj_min_flds: Int
    var num_alphas: Int
    var num_numbers: Int
    var num_args: Int
    var nw_num_args: Int
    var cur_comment: Int
    var progname_conversion: String

fn set_this_version_variables(inout state: VCompareState):
    state.ver_string = "Conversion 23.2 => 24.1"
    state.version_num = 24.1
    state.s_version_num = "***"
    state.s_version_num_four_chars = "24.1"
    state.idd_file_name_with_path = state.program_path + "V23-2-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V24-1-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 23-2-0 to 24-1-0.csv"

fn create_new_idf_using_rules(
    inout state: VCompareState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
):
    state.end_of_file = end_of_file
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    state.end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not state.end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="", flush=True)
                let line = input()
                state.full_file_name = line
            else:
                if not arg_file:
                    state.full_file_name = ""
                    ios = 1
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = ""
                    ios = 1
                
                if state.full_file_name and state.full_file_name.startswith("!"):
                    state.full_file_name = ""
                    continue
            
            var units_arg: String = ""
            if ios != 0:
                state.full_file_name = ""
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name != "":
                display_string("Processing IDF -- " + state.full_file_name)
                write_audit(state.auditf, " Processing IDF -- " + state.full_file_name)
                
                var dot_pos: Int = 0
                for i in range(len(state.full_file_name) - 1, -1, -1):
                    if state.full_file_name[i] == ".":
                        dot_pos = i
                        break
                
                if dot_pos > 0:
                    state.file_name_path = state.full_file_name[:dot_pos]
                    local_file_extension = state.full_file_name[dot_pos + 1:].lower()
                else:
                    state.file_name_path = state.full_file_name
                    print(" assuming file extension of .idf")
                    write_audit(state.auditf, " ..assuming file extension of .idf")
                    state.full_file_name = state.full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = get_new_unit_number()
                state.file_ok = file_exists(state.full_file_name)
                
                if not state.file_ok:
                    print("File not found=" + state.full_file_name)
                    write_audit(state.auditf, "File not found=" + state.full_file_name)
                    state.end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_file_name: String
                    if diff_only:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, state.full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var delete_this_record = InlineArray[Bool, 10000](fill=False)
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case(state.idf_records[num].name) == "VERSION":
                            no_version = False
                            break
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            write_audit(state.auditf, "! Deleting: " + state.idf_records[num].name + "=\"" + state.idf_records[num].alphas[0] + "\".")
                    
                    display_string("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name: String = state.idf_records[num].name
                        var cur_args: Int = 0
                        var written: Bool = False
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        
                        if find_item_in_list(object_name, state.object_def, state.num_object_defs) != 0:
                            get_object_def_in_idd(state, object_name)
                            state.num_alphas = state.idf_records[num].num_alphas
                            state.num_numbers = state.idf_records[num].num_numbers
                            cur_args = state.num_alphas + state.num_numbers
                        else:
                            write_audit(state.auditf, "Object=\"" + object_name + "\" does not seem to be on the \"old\" IDD.")
                            write_audit(state.auditf, "... will be listed as comments (no field names) on the new output file.")
                            write_audit(state.auditf, "... Alpha fields will be listed first, then numerics.")
                            state.num_alphas = state.idf_records[num].num_alphas
                            state.num_numbers = state.idf_records[num].num_numbers
                            cur_args = state.num_alphas + state.num_numbers
                            write_out_idf_lines_as_comments(dif_file_name, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) == 0:
                            get_new_object_def_in_idd(state, object_name)
                            if state.obj_min_flds != state.nw_obj_min_flds:
                                diff_min_fields = True
                        
                        if not state.making_pretty:
                            let obj_name_upper = make_upper_case(state.idf_records[num].name)
                            
                            if obj_name_upper == "VERSION":
                                if state.in_args[0].startswith(state.s_version_num_four_chars) and arg_file:
                                    show_warning_error("File is already at latest version.  No new diff file made.", state.auditf)
                                    latest_version = True
                                    break
                                get_new_object_def_in_idd(state, object_name)
                                state.out_args[0] = state.s_version_num_four_chars
                                no_diff = False
                            
                            elif obj_name_upper == "AIRLOOPHVAC:UNITARYSYSTEM":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                if cur_args > 38:
                                    if same_string(state.in_args[11], "Coil:Heating:DX:VariableSpeed") or same_string(state.in_args[14], "Coil:Cooling:DX:VariableSpeed"):
                                        state.out_args[38] = "Yes"
                                    else:
                                        state.out_args[38] = "No"
                                    cur_args = cur_args + 1
                            
                            elif obj_name_upper == "COMFORTVIEWFACTORANGLES":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                state.out_args[0] = state.in_args[0]
                                cur_args = cur_args - 1
                            
                            elif obj_name_upper == "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                
                                var hx_effect_at_75_airflow = InlineArray[String, 4](fill="")
                                var hx_effect_at_100_airflow = InlineArray[String, 4](fill="")
                                
                                hx_effect_at_75_airflow[0] = get_field_or_idd_default(state.in_args[5], state.fld_defaults[5])
                                hx_effect_at_75_airflow[1] = get_field_or_idd_default(state.in_args[6], state.fld_defaults[6])
                                hx_effect_at_75_airflow[2] = get_field_or_idd_default(state.in_args[9], state.fld_defaults[9])
                                hx_effect_at_75_airflow[3] = get_field_or_idd_default(state.in_args[10], state.fld_defaults[10])
                                
                                hx_effect_at_100_airflow[0] = get_field_or_idd_default(state.in_args[3], state.fld_defaults[3])
                                hx_effect_at_100_airflow[1] = get_field_or_idd_default(state.in_args[4], state.fld_defaults[4])
                                hx_effect_at_100_airflow[2] = get_field_or_idd_default(state.in_args[7], state.fld_defaults[7])
                                hx_effect_at_100_airflow[3] = get_field_or_idd_default(state.in_args[8], state.fld_defaults[8])
                                
                                write_out_idf_lines(dif_file_name, "HeatExchanger:AirToAir:SensibleAndLatent", cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                
                                for i in range(4):
                                    let effect75 = atof(hx_effect_at_75_airflow[i])
                                    let effect100 = atof(hx_effect_at_100_airflow[i])
                                    if effect75 != effect100:
                                        let table_id = str(i + 1)
                                        state.out_args[0] = state.in_args[0] + "_" + table_id
                                        state.out_args[1] = "effectiveness_IndependentVariableList"
                                        state.out_args[2] = "DivisorOnly"
                                        state.out_args[3] = hx_effect_at_100_airflow[i]
                                        state.out_args[4] = "0.0"
                                        state.out_args[5] = "10.0"
                                        state.out_args[6] = "Dimensionless"
                                        state.out_args[7] = ""
                                        state.out_args[8] = ""
                                        state.out_args[9] = ""
                                        state.out_args[10] = hx_effect_at_75_airflow[i]
                                        state.out_args[11] = hx_effect_at_100_airflow[i]
                                        cur_args = 12
                                        write_out_idf_lines(dif_file_name, "Table:Lookup", cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                                
                                written = True
                            
                            elif obj_name_upper == "PEOPLE":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                if same_string(state.out_args[12], "ZoneAveraged"):
                                    state.out_args[12] = "EnclosureAveraged"
                            
                            elif obj_name_upper == "ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                if same_string(state.in_args[16], "Coil:Cooling:DX:VariableSpeed"):
                                    state.out_args[9] = "Yes"
                                else:
                                    state.out_args[9] = "No"
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == "ZONEHVAC:PACKAGEDTERMINALHEATPUMP":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                if same_string(state.in_args[14], "Coil:Heating:DX:VariableSpeed") or same_string(state.in_args[17], "Coil:Cooling:DX:VariableSpeed"):
                                    state.out_args[9] = "Yes"
                                else:
                                    state.out_args[9] = "No"
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == "ZONEHVAC:WATERTOAIRHEATPUMP":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = False
                                state.out_args[9] = "No"
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == "OUTPUT:VARIABLE":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = True
                                if state.out_args[0] == "":
                                    state.out_args[0] = "*"
                                    no_diff = False
                                
                                var del_this: Bool = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_file_name, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ("OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"):
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = True
                                var del_this: Bool = False
                                scan_output_variables_for_replacement(state, 1, del_this, checkrvi, no_diff, object_name, dif_file_name, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == "OUTPUT:TABLE:TIMEBINS":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = True
                                if state.out_args[0] == "":
                                    state.out_args[0] = "*"
                                    no_diff = False
                                var del_this: Bool = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_file_name, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in ("EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"):
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = True
                                if state.out_args[0] == "":
                                    state.out_args[0] = "*"
                                    no_diff = False
                                var del_this: Bool = False
                                scan_output_variables_for_replacement(state, 2, del_this, checkrvi, no_diff, object_name, dif_file_name, False, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                get_new_object_def_in_idd(state, object_name)
                                no_diff = True
                                var del_this: Bool = False
                                scan_output_variables_for_replacement(state, 3, del_this, checkrvi, no_diff, object_name, dif_file_name, False, False, False, cur_args, written, True)
                                if del_this:
                                    continue
                            
                            else:
                                if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    write_audit(state.auditf, "Object=\"" + object_name + "\" is not in the \"new\" IDD.")
                                    write_audit(state.auditf, "... will be listed as comments on the new output file.")
                                    write_out_idf_lines_as_comments(dif_file_name, object_name, cur_args, state.in_args, state.fld_names, state.fld_units)
                                    written = True
                                else:
                                    get_new_object_def_in_idd(state, object_name)
                                    no_diff = True
                        else:
                            get_new_object_def_in_idd(state, state.idf_records[num].name)
                        
                        if diff_min_fields and no_diff:
                            get_new_object_def_in_idd(state, object_name)
                            no_diff = False
                            for arg in range(cur_args, state.nw_obj_min_flds):
                                state.out_args[arg] = state.nw_fld_defaults[arg]
                            cur_args = max(state.nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_file_name, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                            written = False
                        
                        if not written:
                            write_out_idf_lines(dif_file_name, object_name, cur_args, state.out_args, state.nw_fld_names, state.nw_fld_units)
                    
                    display_string("Processing IDF -- Processing idf objects complete.")
                    
                    process_rvi_mvi_files(state, state.file_name_path, "rvi")
                    process_rvi_mvi_files(state, state.file_name_path, "mvi")
                    close_out(state)
                else:
                    process_rvi_mvi_files(state, state.file_name_path, "rvi")
                    process_rvi_mvi_files(state, state.file_name_path, "mvi")
            else:
                state.end_of_file = True
            
            create_new_name(state, "Reallocate", "", "")
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                state.end_of_file = False
            else:
                state.end_of_file = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var err_flag: Bool = False
        copy_file(state.file_name_path + "." + arg_idf_extension, state.file_name_path + "." + arg_idf_extension + "old", err_flag)
        copy_file(state.file_name_path + "." + arg_idf_extension + "new", state.file_name_path + "." + arg_idf_extension, err_flag)
        
        if file_exists(state.file_name_path + ".rvi"):
            copy_file(state.file_name_path + ".rvi", state.file_name_path + ".rviold", err_flag)
        
        if file_exists(state.file_name_path + ".rvinew"):
            copy_file(state.file_name_path + ".rvinew", state.file_name_path + ".rvi", err_flag)
        
        if file_exists(state.file_name_path + ".mvi"):
            copy_file(state.file_name_path + ".mvi", state.file_name_path + ".mviold", err_flag)
        
        if file_exists(state.file_name_path + ".mvinew"):
            copy_file(state.file_name_path + ".mvinew", state.file_name_path + ".mvi", err_flag)

@always_inline
fn display_string(message: String):
    print(message)

@always_inline
fn write_audit(auditf: String, message: String):
    if auditf:
        print(message)

@always_inline
fn show_warning_error(message: String, auditf: String = ""):
    print("Warning: " + message)

@always_inline
fn show_severe_error(message: String, auditf: String = ""):
    print("Severe: " + message)

@always_inline
fn file_exists(filename: String) -> Bool:
    return False

@always_inline
fn copy_file(src: String, dst: String, inout err_flag: Bool):
    pass

@always_inline
fn get_new_unit_number() -> Int:
    return 0

@always_inline
fn make_upper_case(s: String) -> String:
    return s.upper()

@always_inline
fn make_lower_case(s: String) -> String:
    return s.lower()

@always_inline
fn same_string(a: String, b: String) -> Bool:
    return a.upper() == b.upper()

@always_inline
fn find_item_in_list(item: String, lst: List[ObjectDef], size: Int) -> Int:
    return 0

@always_inline
fn find_item_in_list_str(item: String, lst: List[String], size: Int) -> Int:
    return 0

@always_inline
fn get_object_def_in_idd(inout state: VCompareState, obj_name: String):
    pass

@always_inline
fn get_new_object_def_in_idd(inout state: VCompareState, obj_name: String):
    pass

@always_inline
fn process_input(idd_file: String, new_idd_file: String, idf_file: String):
    pass

@always_inline
fn scan_output_variables_for_replacement(
    inout state: VCompareState,
    field: Int,
    inout del_this: Bool,
    inout checkrvi: Bool,
    inout nodiff: Bool,
    obj_name: String,
    dif_lfn: String,
    out_var: Bool,
    mtr_var: Bool,
    timebin_var: Bool,
    inout cur_args: Int,
    inout written: Bool,
    is_sensor: Bool
):
    pass

@always_inline
fn write_out_idf_lines(dif_lfn: String, obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]):
    pass

@always_inline
fn write_out_idf_lines_as_comments(dif_lfn: String, obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]):
    pass

@always_inline
fn check_special_objects(dif_lfn: String, obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]):
    pass

@always_inline
fn create_new_name(inout state: VCompareState, action: String, arg1: String, arg2: String):
    pass

@always_inline
fn process_rvi_mvi_files(inout state: VCompareState, file_path: String, ext: String):
    pass

@always_inline
fn close_out(inout state: VCompareState):
    pass

@always_inline
fn get_field_or_idd_default(field: String, default: String) -> String:
    if field:
        return field
    return default

@always_inline
fn atof(s: String) -> Float:
    return 0.0

@always_inline
fn str(i: Int) -> String:
    return ""

@always_inline
fn write_preprocessor_object(dif_lfn: String, prog_name: String, severity: String, message: String):
    pass
