from collections import InlineArray
import os

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor module: process_input()
# - DataVCompareGlobals: module-level state
# - VCompareGlobalRoutines: subroutines
# - General: make_lower_case(), make_upper_case(), samestring()
# - DataGlobals: show_message(), show_continue_error(), show_fatal_error(), show_severe_error(), show_warning_error()
# - System functions: get_new_unit_number(), find_number(), trim_trailing_zeros(), copyfile()
# - IDD/Object management: get_object_def_in_idd(), get_new_object_def_in_idd(), find_item_in_list()
# - Output writing: write_out_idf_lines_as_comments(), write_out_idf_lines(), check_special_objects()
# - Report variables: scan_output_variables_for_replacement()
# - File processing: process_rvi_mvi_files(), close_out(), display_string(), create_new_name()

struct IDFRecord:
    var name: String
    var commt_s: Int
    var commt_e: Int
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[Float64]
    
    fn __init__(inout self):
        self.name = ""
        self.commt_s = 0
        self.commt_e = 0
        self.num_alphas = 0
        self.num_numbers = 0
        self.alphas = List[String]()
        self.numbers = List[Float64]()

struct ObjectDefEntry:
    var name: String
    
    fn __init__(inout self):
        self.name = ""

struct TransitionState:
    var full_file_name: String
    var file_name_path: String
    var file_ok: Bool
    var blank: String
    var audit_f: UnsafePointer[NoneType]
    var program_path: String
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var num_idf_records: Int
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var cur_comment: Int
    var processing_imf_file: Bool
    var fatal_error: Bool
    var making_pretty: Bool
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var object_def: List[ObjectDefEntry]
    var num_object_defs: Int
    var not_in_new: List[String]
    var num_rep_var_names: Int
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    
    fn __init__(inout self):
        self.full_file_name = ""
        self.file_name_path = ""
        self.file_ok = False
        self.blank = ""
        self.audit_f = UnsafePointer[NoneType]()
        self.program_path = ""
        self.ver_string = ""
        self.version_num = 1.0
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""
        self.num_idf_records = 0
        self.idf_records = List[IDFRecord]()
        self.comments = List[String]()
        self.cur_comment = 0
        self.processing_imf_file = False
        self.fatal_error = False
        self.making_pretty = False
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0
        self.object_def = List[ObjectDefEntry]()
        self.num_object_defs = 0
        self.not_in_new = List[String]()
        self.num_rep_var_names = 0
        self.old_rep_var_name = List[String]()
        self.new_rep_var_name = List[String]()

fn make_lower_case(s: String) -> String:
    return s.lower()

fn make_upper_case(s: String) -> String:
    return s.upper()

fn trim_trailing_zeros(s: String) -> String:
    var result = s
    if "." in s:
        while result.endswith("0"):
            result = result[:-1]
        if result.endswith("."):
            result = result[:-1]
    return result

fn find_item_in_list(item: String, lst: List[String], size: Int) -> Int:
    var item_upper = make_upper_case(item)
    for i in range(size):
        if make_upper_case(lst[i]) == item_upper:
            return i + 1
    return 0

fn samestring(s1: String, s2: String) -> Bool:
    return make_upper_case(s1) == make_upper_case(s2)

fn set_this_version_variables(inout state: TransitionState) -> None:
    state.ver_string = "Conversion 1.2 => 1.2.1"
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path.rstrip() + "V1-2-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path.rstrip() + "V1-2-1-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path.rstrip() + "Report Variables 1-2-0-029 to 1-2-1.csv"

fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: TransitionState,
    external_functions: UnsafePointer[NoneType]
) -> None:
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file[0] = False
    var ios = 0
    
    var alphas = List[String]()
    var numbers = List[Float64]()
    var in_args = List[String]()
    var aor_n = List[Bool]()
    var req_fld = List[Bool]()
    var fld_names = List[String]()
    var fld_defaults = List[String]()
    var fld_units = List[String]()
    var nw_aor_n = List[Bool]()
    var nw_req_fld = List[Bool]()
    var nw_fld_names = List[String]()
    var nw_fld_defaults = List[String]()
    var nw_fld_units = List[String]()
    var out_args = List[String]()
    var match_arg = List[Int]()
    var delete_this_record = List[Bool]()
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file[0]:
            var full_file_name: String
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                full_file_name = input()
            else:
                if not arg_file:
                    # Read from file unit - external function needed
                    full_file_name = ""
                    ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.blank
                    ios = 1
                
                if full_file_name and full_file_name[0:1] == "!":
                    full_file_name = state.blank
                    continue
            
            var units_arg = state.blank
            if ios != 0:
                full_file_name = state.blank
            
            full_file_name = full_file_name.lstrip()
            state.full_file_name = full_file_name
            
            if full_file_name != state.blank:
                var dot_pos = full_file_name.rfind(".")
                if dot_pos != -1:
                    state.file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    state.file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.rstrip() + ".idf"
                    state.full_file_name = full_file_name
                    local_file_extension = "idf"
                
                var dif_lfn = 0  # External function needed for get_new_unit_number
                state.file_ok = os.path.exists(full_file_name.rstrip())
                
                if not state.file_ok:
                    print("File not found=" + full_file_name.rstrip())
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    
                    var dif_file_name: String
                    if diff_only:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "new"
                    
                    var dif_file: NoneType  # Would be file handle from external function
                    
                    if local_file_extension == "imf":
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    alphas = List[String](capacity=state.max_alpha_args_found)
                    numbers = List[Float64](capacity=state.max_numeric_args_found)
                    in_args = List[String](capacity=state.max_total_args)
                    aor_n = List[Bool](capacity=state.max_total_args)
                    req_fld = List[Bool](capacity=state.max_total_args)
                    fld_names = List[String](capacity=state.max_total_args)
                    fld_defaults = List[String](capacity=state.max_total_args)
                    fld_units = List[String](capacity=state.max_total_args)
                    nw_aor_n = List[Bool](capacity=state.max_total_args)
                    nw_req_fld = List[Bool](capacity=state.max_total_args)
                    nw_fld_names = List[String](capacity=state.max_total_args)
                    nw_fld_defaults = List[String](capacity=state.max_total_args)
                    nw_fld_units = List[String](capacity=state.max_total_args)
                    out_args = List[String](capacity=state.max_total_args)
                    match_arg = List[Int](capacity=state.max_total_args)
                    delete_this_record = List[Bool](capacity=state.num_idf_records)
                    
                    var no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case(state.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        for xcount in range(state.idf_records[num].commt_s, state.idf_records[num].commt_e + 1):
                            if xcount < len(state.comments):
                                pass  # Write to file
                            if xcount == state.idf_records[num].commt_e:
                                pass  # Write newline to file
                        
                        if no_version and num == 0:
                            out_args[0] = "1.2.1"
                            var cur_args = 1
                        
                        if make_upper_case(state.idf_records[num].name.rstrip()) == "SKY RADIANCE DISTRIBUTION":
                            continue
                        
                        var object_name = state.idf_records[num].name
                        
                        if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) == 0:
                            var num_alphas = state.idf_records[num].num_alphas
                            var num_numbers = state.idf_records[num].num_numbers
                            
                            cur_args = num_alphas + num_numbers
                            
                            var na = 0
                            var nn = 0
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        else:
                            var num_alphas = state.idf_records[num].num_alphas
                            var num_numbers = state.idf_records[num].num_numbers
                            
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            
                            nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            continue
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if not state.making_pretty:
                            var object_upper = make_upper_case(state.idf_records[num].name.rstrip())
                            
                            if object_upper == "VERSION":
                                if in_args[0][:5] == "1.2.1" and arg_file:
                                    latest_version = True
                                    break
                                out_args[0] = "1.2.1"
                            
                            elif object_upper == "DESICCANT DEHUMIDIFIER:SOLID":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[13]) == "FAN:SIMPLE:CONSTVOLUME" and
                                    make_upper_case(out_args[15]) == "DEFAULT"):
                                    pass  # Write warning
                                nodiff = False
                            
                            elif object_upper == "GROUND HEAT EXCHANGER:POND":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if make_upper_case(out_args[3]) != "WATER":
                                    nodiff = False
                            
                            elif object_upper == "GROUND HEAT EXCHANGER:SURFACE":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if make_upper_case(out_args[4]) != "WATER":
                                    nodiff = False
                            
                            elif object_upper == "HEAT EXCHANGER:HYDRONIC:FREE COOLING":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[8]) != "WATER" or
                                    make_upper_case(out_args[9]) != "WATER"):
                                    nodiff = False
                            
                            elif object_upper == "HEAT EXCHANGER:PLATE:FREE COOLING":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[7]) != "WATER" or
                                    make_upper_case(out_args[8]) != "WATER"):
                                    nodiff = False
                            
                            elif object_upper == "BUILDING":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args == 8:
                                    nodiff = False
                                    if make_upper_case(out_args[7]) == "YES":
                                        out_args[5] = out_args[5].rstrip() + "WithReflections"
                                        out_args[7] = state.blank
                                        cur_args = 7
                                    elif make_upper_case(out_args[7]) == "NO":
                                        out_args[7] = state.blank
                                        cur_args = 7
                            
                            elif (object_upper == "SET POINT MANAGER:SINGLE ZONE MIN HUM" or
                                  object_upper == "SET POINT MANAGER:SINGLE ZONE MAX HUM"):
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                out_args[1] = state.blank
                                out_args[2] = state.blank
                            
                            elif object_upper == "WINDOWSHADINGCONTROL":
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                
                                if samestring("InteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if samestring("ExteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                if samestring("InteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if samestring("ExteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                
                                if samestring("Schedule", in_args[3]):
                                    out_args[3] = "OnIfScheduleAllows"
                                if samestring("SolarOnWindow", in_args[3]):
                                    out_args[3] = "OnIfHighSolarOnWindow"
                                if samestring("HorizontalSolar", in_args[3]):
                                    out_args[3] = "OnIfHighHorizontalSolar"
                                if samestring("OutsideAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighOutsideAirTemp"
                                if samestring("ZoneAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighZoneAirTemp"
                                if samestring("ZoneCooling", in_args[3]):
                                    out_args[3] = "OnIfHighZoneCooling"
                                if samestring("Glare", in_args[3]):
                                    out_args[3] = "OnIfHighGlare"
                                if samestring("DaylightIlluminance", in_args[3]):
                                    out_args[3] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif object_upper == "REPORT VARIABLE":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = "*"
                                    nodiff = False
                            
                            elif (object_upper == "REPORT METER" or
                                  object_upper == "REPORT METERFILEONLY" or
                                  object_upper == "REPORT CUMULATIVE METER" or
                                  object_upper == "REPORT CUMULATIVE METERFILEONLY"):
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                            
                            elif object_upper == "REPORT:TABLE:TIMEBINS":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = "*"
                                    nodiff = False
                            
                            elif object_upper == "REPORT:TABLE:MONTHLY":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = "*"
                                    nodiff = False
                                
                                var cur_var = 3
                                var var_idx = 3
                                while var_idx < cur_args:
                                    var uc_rep_var_name = make_upper_case(in_args[var_idx])
                                    out_args[cur_var] = in_args[var_idx]
                                    out_args[cur_var + 1] = in_args[var_idx + 1]
                                    
                                    var pos = uc_rep_var_name.find("[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var_idx][:pos]
                                        out_args[cur_var + 1] = in_args[var_idx + 1]
                                    
                                    var del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        var uc_comp_rep_var_name = make_upper_case(state.old_rep_var_name[arg])
                                        var wild_match = False
                                        if uc_comp_rep_var_name[-1:] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                        
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        if pos > 0 and pos != 0:
                                            var_idx += 2
                                            continue
                                        
                                        if pos >= 0:
                                            if state.new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.num_rep_var_names - 1 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            
                                            if arg < state.num_rep_var_names - 2 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var_idx += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    written = True
                                else:
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    nodiff = True
                        
                        else:
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
            
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
        var err_flag = False
