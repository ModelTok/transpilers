from memory import Span, memset_zero, stack_allocation
from collections import InlineArray

alias MAX_NAME_LENGTH = 256
alias BLANK_STR = ""

struct IDFRecord:
    var name: String
    var num_alphas: Int32
    var num_numbers: Int32
    var alphas: List[String]
    var numbers: List[String]
    var commt_s: Int32
    var commt_e: Int32

struct DataStringGlobals:
    var prog_name_conversion: String
    var program_path: String
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var full_file_name: String
    var file_name_path: String
    var auditf: AnyPointer

struct DataVCompareGlobals:
    var fatal_error: Bool
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var num_idf_records: Int32
    var max_alpha_args_found: Int32
    var max_numeric_args_found: Int32
    var max_total_args: Int32
    var cur_comment: Int32
    var num_object_defs: Int32
    var object_def_names: List[String]
    var not_in_new: List[String]
    var num_rep_var_names: Int32
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var new_rep_var_caution: List[String]
    var otm_var_caution: List[Bool]
    var cmtr_var_caution: List[Bool]
    var cmtr_d_var_caution: List[Bool]
    var processing_imf_file: Bool
    var making_pretty: Bool

fn set_this_version_variables(inout data_string_globals: DataStringGlobals) -> None:
    data_string_globals.ver_string = "Conversion 7.0 => 7.1"
    data_string_globals.version_num = 7.1
    data_string_globals.idd_file_name_with_path = data_string_globals.program_path + "V7-0-0-Energy+.idd"
    data_string_globals.new_idd_file_name_with_path = data_string_globals.program_path + "V7-1-0-Energy+.idd"
    data_string_globals.rep_var_file_name_with_path = data_string_globals.program_path + "Report Variables 7-0-0-036 to 7-1-0.csv"

@always_inline
fn make_upper_case(s: String) -> String:
    var result = String(s)
    for i in range(len(result)):
        if result[i].isascii() and result[i].islower():
            result[i] = chr(ord(result[i]) - 32)
    return result

@always_inline
fn make_lower_case(s: String) -> String:
    var result = String(s)
    for i in range(len(result)):
        if result[i].isascii() and result[i].isupper():
            result[i] = chr(ord(result[i]) + 32)
    return result

@always_inline
fn same_string(a: String, b: String) -> Bool:
    return make_upper_case(a.strip()) == make_upper_case(b.strip())

fn create_new_idf_using_rules(
    inout data_string_globals: DataStringGlobals,
    inout data_vcompare_globals: DataVCompareGlobals,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int32,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    var first_time: Bool = True
    if first_time:
        pass
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int32 = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                var line = ""
                data_string_globals.full_file_name = line
            else:
                if not arg_file:
                    data_string_globals.full_file_name = ""
                    ios = 0
                elif not arg_file_being_done:
                    data_string_globals.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    data_string_globals.full_file_name = ""
                    ios = 1
                
                if data_string_globals.full_file_name and data_string_globals.full_file_name[0] == '!':
                    data_string_globals.full_file_name = ""
                    continue
            
            if ios != 0:
                data_string_globals.full_file_name = ""
            
            data_string_globals.full_file_name = data_string_globals.full_file_name.lstrip()
            
            if data_string_globals.full_file_name:
                print("Processing IDF -- " + data_string_globals.full_file_name)
                
                var dot_pos: Int32 = -1
                for i in range(len(data_string_globals.full_file_name) - 1, -1, -1):
                    if data_string_globals.full_file_name[i] == '.':
                        dot_pos = i
                        break
                
                if dot_pos >= 0:
                    data_string_globals.file_name_path = data_string_globals.full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(data_string_globals.full_file_name[dot_pos + 1:])
                else:
                    data_string_globals.file_name_path = data_string_globals.full_file_name
                    print(" assuming file extension of .idf")
                    data_string_globals.full_file_name = data_string_globals.full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int32 = 0
                var file_ok: Bool = False
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var out_file: String
                    if diff_only:
                        out_file = data_string_globals.file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file = data_string_globals.file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        data_vcompare_globals.processing_imf_file = True
                    else:
                        data_vcompare_globals.processing_imf_file = False
                    
                    if data_vcompare_globals.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var alphas = List[String](capacity=data_vcompare_globals.max_alpha_args_found)
                    var numbers = List[String](capacity=data_vcompare_globals.max_numeric_args_found)
                    var in_args = List[String](capacity=data_vcompare_globals.max_total_args)
                    var aorn = List[Bool](capacity=data_vcompare_globals.max_total_args)
                    var req_fld = List[Bool](capacity=data_vcompare_globals.max_total_args)
                    var fld_names = List[String](capacity=data_vcompare_globals.max_total_args)
                    var fld_defaults = List[String](capacity=data_vcompare_globals.max_total_args)
                    var fld_units = List[String](capacity=data_vcompare_globals.max_total_args)
                    var nw_aorn = List[Bool](capacity=data_vcompare_globals.max_total_args)
                    var nw_req_fld = List[Bool](capacity=data_vcompare_globals.max_total_args)
                    var nw_fld_names = List[String](capacity=data_vcompare_globals.max_total_args)
                    var nw_fld_defaults = List[String](capacity=data_vcompare_globals.max_total_args)
                    var nw_fld_units = List[String](capacity=data_vcompare_globals.max_total_args)
                    var out_args = List[String](capacity=data_vcompare_globals.max_total_args)
                    var match_arg = List[String](capacity=data_vcompare_globals.max_total_args)
                    var delete_this_record = List[Bool](capacity=data_vcompare_globals.num_idf_records)
                    
                    no_version = True
                    for num in range(data_vcompare_globals.num_idf_records):
                        if make_upper_case(data_vcompare_globals.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(data_vcompare_globals.num_idf_records):
                        if delete_this_record[num]:
                            var write_str = "! Deleting: " + data_vcompare_globals.idf_records[num].name
                            if data_vcompare_globals.idf_records[num].num_alphas > 0:
                                write_str += ":" + data_vcompare_globals.idf_records[num].alphas[0]
                    
                    for num in range(data_vcompare_globals.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(data_vcompare_globals.idf_records[num].commt_s + 1,
                                          data_vcompare_globals.idf_records[num].commt_e + 1):
                            if xcount < len(data_vcompare_globals.comments):
                                if xcount == data_vcompare_globals.idf_records[num].commt_e:
                                    pass
                        
                        if no_version and num == 0:
                            out_args.append("7.1")
                        
                        var object_name = data_vcompare_globals.idf_records[num].name
                        
                        var obj_name_upper = make_upper_case(object_name.strip())
                        
                        if obj_name_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if obj_name_upper == "AIRFLOW MODEL":
                            continue
                        if obj_name_upper == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if obj_name_upper == "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS":
                            continue
                        if obj_name_upper == "WATER HEATER:SIMPLE":
                            continue
                        
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if not data_vcompare_globals.making_pretty:
                            if obj_name_upper == "VERSION":
                                nodiff = False
                            elif obj_name_upper == "AIRLOOPHVAC:RETURNPLENUM":
                                nodiff = False
                            elif obj_name_upper == "AIRLOOPHVAC:UNITARYCOOLONLY":
                                nodiff = False
                                object_name = "CoilSystem:Cooling:DX"
                            elif obj_name_upper == "BRANCH":
                                nodiff = False
                            elif obj_name_upper == "ZONEHVAC:OUTDOORAIRUNIT:EQUIPMENTLIST":
                                nodiff = False
                            elif obj_name_upper == "AIRLOOPHVAC:OUTDOORAIRSYSTEM:EQUIPMENTLIST":
                                nodiff = False
                            elif obj_name_upper == "SIZINGPERIOD:DESIGNDAY":
                                nodiff = False
                            elif obj_name_upper == "CONTROLLER:MECHANICALVENTILATION":
                                nodiff = False
                                written = True
                            elif obj_name_upper == "SIZING:ZONE":
                                nodiff = False
                                written = True
                            elif obj_name_upper == "COIL:HEATING:DX:SINGLESPEED":
                                nodiff = False
                            elif obj_name_upper == "WINDOWMATERIAL:SHADE":
                                nodiff = False
                            elif obj_name_upper == "OUTPUT:VARIABLE":
                                nodiff = False
                            elif obj_name_upper in ("OUTPUT:METER", "OUTPUT:METER:METERFILEONLY",
                                                   "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"):
                                nodiff = True
                            elif obj_name_upper == "OUTPUT:TABLE:TIMEBINS":
                                nodiff = False
                            elif obj_name_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                nodiff = False
                            elif obj_name_upper == "OUTPUT:TABLE:MONTHLY":
                                nodiff = True
                            elif obj_name_upper == "METER:CUSTOM":
                                nodiff = True
                            elif obj_name_upper == "METER:CUSTOMDECREMENT":
                                nodiff = True
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            pass
            else:
                end_of_file = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
