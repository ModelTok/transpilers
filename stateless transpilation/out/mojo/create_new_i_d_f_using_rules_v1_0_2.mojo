# EXTERNAL DEPS (to wire in glue):
# - FullFileName: String (mutable)
# - FileNamePath: String (mutable)
# - IDFRecords: DynamicVector of IDFRecord with fields Name, NumAlphas, NumNumbers, Alphas, Numbers, CommtS, CommtE
# - Comments: DynamicVector[String]
# - NumIDFRecords: Int
# - CurComment: Int (mutable)
# - ObjectDef: struct with Name field
# - NumObjectDefs: Int
# - MaxAlphaArgsFound: Int
# - MaxNumericArgsFound: Int
# - MaxTotalArgs: Int
# - ProcessingIMFFile: Bool (mutable)
# - FatalError: Bool (mutable)
# - Auditf: Int (file unit)
# - ProgramPath: String
# - VerString: String (mutable)
# - VersionNum: Float64 (mutable)
# - IDDFileNameWithPath: String (mutable)
# - NewIDDFileNameWithPath: String (mutable)
# - RepVarFileNameWithPath: String (mutable)
# - OldRepVarName: DynamicVector[String]
# - NewRepVarName: DynamicVector[String]
# - NumRepVarNames: Int
# - NotInNew: DynamicVector[String]
# - MakingPretty: Bool
# - ExternalState: struct containing shared module state

from memory import UnsafePointer
from collections import InlineArray

alias Blank = ""
alias MaxNameLength = 256
alias MaxTotalArgsConstant = 500

struct SetVersion:
    pass

fn set_this_version_variables(state: UnsafePointer[ExternalState]) -> None:
    state[].VerString = String("Conversion 1.0.1 => 1.0.2")
    state[].VersionNum = 1.0
    state[].IDDFileNameWithPath = String(state[].ProgramPath) + String("V1-0-1-Energy+.idd")
    state[].NewIDDFileNameWithPath = String(state[].ProgramPath) + String("V1-0-2-Energy+.idd")
    state[].RepVarFileNameWithPath = String(state[].ProgramPath) + String("Report Variables 1-0-1-042 to 1-0-2.csv")

fn create_new_idf_using_rules(
    state: UnsafePointer[ExternalState],
    end_of_file: UnsafePointer[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = String(arg_idf_extension)
    end_of_file[].set(False)
    var ios = 0
    
    while still_working:
        var exit_because_bad_file = False
        while not end_of_file[]:
            var full_file_name = String()
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
            else:
                if not arg_file:
                    try:
                        full_file_name = state[].read_line_from_unit(in_lfn)
                        ios = 0
                    except:
                        full_file_name = String(Blank)
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = String(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = String(Blank)
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = String(Blank)
                    continue
            
            var units_arg = String(Blank)
            if ios != 0:
                full_file_name = String(Blank)
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != String(Blank):
                state[].display_string(String("Processing IDF -- ") + full_file_name)
                state[].write_audit(String("Processing IDF -- ") + full_file_name)
                
                var dot_pos = full_file_name.rfind('.')
                var file_name_path = String()
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print("assuming file extension of .idf")
                    state[].write_audit(String("..assuming file extension of .idf"))
                    full_file_name = full_file_name.rstrip() + String(".idf")
                    local_file_extension = String("idf")
                
                var dif_lfn = state[].get_new_unit_number()
                var file_ok = state[].file_exists(full_file_name)
                
                if not file_ok:
                    print(String("File not found=") + full_file_name)
                    state[].write_audit(String("File not found=") + full_file_name)
                    end_of_file[].set(True)
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == String("idf") or local_file_extension == String("imf"):
                    var check_rvi = False
                    
                    var output_file_name = String()
                    if diff_only:
                        output_file_name = file_name_path + String(".") + local_file_extension + String("dif")
                    else:
                        output_file_name = file_name_path + String(".") + local_file_extension + String("new")
                    
                    state[].open_output_file(dif_lfn, output_file_name)
                    
                    if local_file_extension == String("imf"):
                        state[].show_warning_error(String("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully."))
                        state[].ProcessingIMFFile = True
                    else:
                        state[].ProcessingIMFFile = False
                    
                    state[].process_input(state[].IDDFileNameWithPath, state[].NewIDDFileNameWithPath, full_file_name)
                    if state[].FatalError:
                        exit_because_bad_file = True
                        break
                    
                    var alphas = DynamicVector[String](state[].MaxAlphaArgsFound)
                    var numbers = DynamicVector[Float64](state[].MaxNumericArgsFound)
                    var in_args = DynamicVector[String](state[].MaxTotalArgs)
                    var aor_n = DynamicVector[Bool](state[].MaxTotalArgs)
                    var req_fld = DynamicVector[Bool](state[].MaxTotalArgs)
                    var fld_names = DynamicVector[String](state[].MaxTotalArgs)
                    var fld_defaults = DynamicVector[String](state[].MaxTotalArgs)
                    var fld_units = DynamicVector[String](state[].MaxTotalArgs)
                    var nw_aor_n = DynamicVector[Bool](state[].MaxTotalArgs)
                    var nw_req_fld = DynamicVector[Bool](state[].MaxTotalArgs)
                    var nw_fld_names = DynamicVector[String](state[].MaxTotalArgs)
                    var nw_fld_defaults = DynamicVector[String](state[].MaxTotalArgs)
                    var nw_fld_units = DynamicVector[String](state[].MaxTotalArgs)
                    var out_args = DynamicVector[String](state[].MaxTotalArgs)
                    var match_arg = DynamicVector[Bool](state[].MaxTotalArgs)
                    var delete_this_record = DynamicVector[Bool](state[].NumIDFRecords)
                    
                    var no_version = True
                    for num in range(state[].NumIDFRecords):
                        if state[].IDFRecords[num].Name.upper() != String("VERSION"):
                            continue
                        no_version = False
                        break
                    
                    var num_comis_facades = state[].get_num_objects_found(String("COMIS EXTERNAL NODE"))
                    var comis_facade_names = DynamicVector[String](num_comis_facades)
                    for num in range(num_comis_facades):
                        state[].get_object_item(String("COMIS EXTERNAL NODE"), num + 1, alphas, numbers)
                        comis_facade_names.push_back(alphas[0])
                    
                    var lrbo_list = state[].get_num_objects_found(String("LOAD RANGE BASED OPERATION"))
                    var clrbo_list = state[].get_num_objects_found(String("COOLING LOAD RANGE BASED OPERATION"))
                    var hlrbo_list = state[].get_num_objects_found(String("HEATING LOAD RANGE BASED OPERATION"))
                    var count = lrbo_list + clrbo_list + hlrbo_list
                    var lrbo_scheme = DynamicVector[String](count)
                    var lrbo_type = DynamicVector[Int](count)
                    var lrbo = 0
                    
                    for num in range(state[].NumIDFRecords):
                        var obj_name_upper = state[].IDFRecords[num].Name.upper()
                        
                        if obj_name_upper == String("LOAD RANGE BASED OPERATION"):
                            var object_name = String(state[].IDFRecords[num].Name)
                            var num_alphas = state[].IDFRecords[num].NumAlphas
                            var num_numbers = state[].IDFRecords[num].NumNumbers
                            var cur_args = num_alphas + num_numbers
                            var na = 0
                            var nn = 0
                            
                            var ffield = True
                            var mx_field = False
                            var minus = False
                            for arg in range(1, cur_args, 3):
                                if ffield:
                                    ffield = False
                                else:
                                    var pos = out_args[arg].find('-')
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                                if arg + 1 < len(out_args):
                                    pos = out_args[arg + 1].find('-')
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                            
                            lrbo_scheme.push_back(in_args[0].upper())
                            if mx_field:
                                lrbo_type.push_back(0)
                            elif not minus:
                                lrbo_type.push_back(2)
                            else:
                                lrbo_type.push_back(1)
                            lrbo += 1
                        
                        elif obj_name_upper == String("HEATING LOAD RANGE BASED OPERATION"):
                            lrbo_scheme.push_back(state[].IDFRecords[num].Alphas[0].upper())
                            lrbo_type.push_back(2)
                            lrbo += 1
                        
                        elif obj_name_upper == String("COOLING LOAD RANGE BASED OPERATION"):
                            lrbo_scheme.push_back(state[].IDFRecords[num].Alphas[0].upper())
                            lrbo_type.push_back(1)
                            lrbo += 1
                    
                    for num in range(state[].NumIDFRecords):
                        var obj_name_upper = state[].IDFRecords[num].Name.upper()
                        if obj_name_upper != String("PLANT OPERATION SCHEMES") and obj_name_upper != String("CONDENSER OPERATION SCHEMES"):
                            continue
                        
                        var num_alphas = state[].IDFRecords[num].NumAlphas
                        for arg in range(1, num_alphas, 3):
                            if state[].IDFRecords[num].Alphas[arg].upper() != String("LOAD RANGE BASED OPERATION"):
                                continue
                            var count_search = state[].find_item_in_list(state[].IDFRecords[num].Alphas[arg + 1].upper(), lrbo_scheme)
                            if count_search != -1:
                                if lrbo_type[count_search] == 1:
                                    state[].IDFRecords[num].Alphas[arg] = String("COOLING LOAD RANGE BASED OPERATION")
                                elif lrbo_type[count_search] == 2:
                                    state[].IDFRecords[num].Alphas[arg] = String("HEATING LOAD RANGE BASED OPERATION")
                    
                    for num in range(state[].NumIDFRecords):
                        for xcount in range(state[].IDFRecords[num].CommtS, state[].IDFRecords[num].CommtE + 1):
                            if xcount < len(state[].Comments):
                                state[].write_line_to_unit(dif_lfn, state[].Comments[xcount])
                            if xcount == state[].IDFRecords[num].CommtE:
                                state[].write_line_to_unit(dif_lfn, String(""))
                        
                        if no_version and num == 0:
                            state[].get_new_object_def_in_idd(String("VERSION"), nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = String("1.0.2")
                            var cur_args = 1
                            state[].write_out_idf_lines_as_comments(dif_lfn, String("VERSION"), cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        var object_name = String(state[].IDFRecords[num].Name)
                        var num_alphas = state[].IDFRecords[num].NumAlphas
                        var num_numbers = state[].IDFRecords[num].NumNumbers
                        cur_args = num_alphas + num_numbers
                        var na = 0
                        var nn = 0
                        
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if not state[].MakingPretty:
                            var obj_name_upper = state[].IDFRecords[num].Name.upper()
                            
                            if obj_name_upper == String("VERSION"):
                                if in_args[0].substring(0, 5) == String("1.0.2") and arg_file:
                                    state[].show_warning_error(String("File is already at latest version.  No new diff file made."))
                                    state[].close_file(dif_lfn, delete=True)
                                    latest_version = True
                                    break
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = String("1.0.2")
                                no_diff = False
                            
                            elif obj_name_upper == String("COMIS SURFACE DATA"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[1]
                                out_args[3] = in_args[3]
                                var n_index = 0
                                try:
                                    n_index = int(in_args[2])
                                except:
                                    n_index = 0
                                if n_index == 0:
                                    out_args[2] = String(Blank)
                                else:
                                    out_args[2] = comis_facade_names[n_index - 1]
                                no_diff = False
                            
                            elif obj_name_upper == String("DAYLIGHTING"):
                                if cur_args > 5:
                                    state[].get_new_object_def_in_idd(String("DAYLIGHTING:DETAILED"), nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = String("Daylighting:Detailed")
                                    out_args[0] = in_args[0]
                                    cur_args = cur_args - 3
                                else:
                                    state[].get_new_object_def_in_idd(String("DAYLIGHTING:SIMPLE"), nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    object_name = String("Daylighting:Simple")
                                    out_args[0] = in_args[0]
                                    out_args[1] = in_args[1]
                                    out_args[2] = in_args[2]
                                    out_args[3] = in_args[3]
                                    cur_args = 4
                                no_diff = False
                            
                            elif obj_name_upper == String("LOAD RANGE BASED OPERATION"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                var ffield = True
                                var mx_field = False
                                var minus = False
                                for arg in range(1, cur_args, 3):
                                    if ffield:
                                        ffield = False
                                    else:
                                        var pos = out_args[arg].find('-')
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                                    if arg + 1 < len(out_args):
                                        pos = out_args[arg + 1].find('-')
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                                
                                if mx_field:
                                    state[].write_line_to_unit(dif_lfn, String("! Next object is obsolete, needs hand transition to new"))
                                elif not minus:
                                    object_name = String("Heating Load Range Based Operation")
                                else:
                                    object_name = String("Cooling Load Range Based Operation")
                                    for arg in range(1, cur_args, 3):
                                        var pos = out_args[arg].find('-')
                                        if pos >= 0:
                                            out_args[arg] = out_args[arg][0:pos] + String(" ") + out_args[arg][pos+1:]
                                        if arg + 1 < len(out_args):
                                            pos = out_args[arg + 1].find('-')
                                            if pos >= 0:
                                                out_args[arg + 1] = out_args[arg + 1][0:pos] + String(" ") + out_args[arg + 1][pos+1:]
                                no_diff = False
                            
                            elif obj_name_upper == String("WINDOWSHADINGCONTROL"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = False
                                if state[].same_string(String("InteriorNonInsulatingShade"), in_args[1]):
                                    out_args[1] = String("InteriorShade")
                                if state[].same_string(String("ExteriorNonInsulatingShade"), in_args[1]):
                                    out_args[1] = String("ExteriorShade")
                                if state[].same_string(String("InteriorInsulatingShade"), in_args[1]):
                                    out_args[1] = String("InteriorShade")
                                if state[].same_string(String("ExteriorInsulatingShade"), in_args[1]):
                                    out_args[1] = String("ExteriorShade")
                                if state[].same_string(String("Schedule"), in_args[3]):
                                    out_args[3] = String("OnIfScheduleAllows")
                                if state[].same_string(String("SolarOnWindow"), in_args[3]):
                                    out_args[3] = String("OnIfHighSolarOnWindow")
                                if state[].same_string(String("HorizontalSolar"), in_args[3]):
                                    out_args[3] = String("OnIfHighHorizontalSolar")
                                if state[].same_string(String("OutsideAirTemp"), in_args[3]):
                                    out_args[3] = String("OnIfHighOutsideAirTemp")
                                if state[].same_string(String("ZoneAirTemp"), in_args[3]):
                                    out_args[3] = String("OnIfHighZoneAirTemp")
                                if state[].same_string(String("ZoneCooling"), in_args[3]):
                                    out_args[3] = String("OnIfHighZoneCooling")
                                if state[].same_string(String("Glare"), in_args[3]):
                                    out_args[3] = String("OnIfHighGlare")
                                if state[].same_string(String("DaylightIlluminance"), in_args[3]):
                                    out_args[3] = String("MeetDaylightIlluminanceSetpoint")
                            
                            elif obj_name_upper == String("REPORT VARIABLE"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = True
                                if out_args[0] == String(Blank):
                                    out_args[0] = String("*")
                                    no_diff = False
                                var del_this = state[].scan_output_variables_for_replacement(
                                    2, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=True, mtr_var=False, time_bin_var=False, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper in [String("REPORT METER"), String("REPORT METERFILEONLY"), String("REPORT CUMULATIVE METER"), String("REPORT CUMULATIVE METERFILEONLY")]:
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = True
                                del_this = state[].scan_output_variables_for_replacement(
                                    1, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=False, mtr_var=True, time_bin_var=False, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == String("REPORT:TABLE:TIMEBINS"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = True
                                if out_args[0] == String(Blank):
                                    out_args[0] = String("*")
                                    no_diff = False
                                del_this = state[].scan_output_variables_for_replacement(
                                    2, check_rvi, no_diff, object_name, dif_lfn,
                                    out_var=False, mtr_var=False, time_bin_var=True, cur_args=cur_args
                                )
                                if del_this:
                                    continue
                            
                            elif obj_name_upper == String("REPORT:TABLE:MONTHLY"):
                                state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = True
                                if out_args[0] == String(Blank):
                                    out_args[0] = String("*")
                                    no_diff = False
                                var cur_var = 3
                                for var in range(3, cur_args, 2):
                                    var uc_rep_var_name = in_args[var].upper()
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    var pos_open = uc_rep_var_name.find('[')
                                    if pos_open >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos_open]
                                        out_args[cur_var] = in_args[var][0:pos_open]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state[].NumRepVarNames):
                                        var uc_comp_rep_var_name = state[].OldRepVarName[arg].upper()
                                        var wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[0:-1]
                                        
                                        var pos_find = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos_find > 0:
                                            continue
                                        if pos_find >= 0:
                                            if state[].NewRepVarName[arg] != String("<DELETE>"):
                                                if not wild_match:
                                                    out_args[cur_var] = state[].NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = state[].NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < state[].NumRepVarNames and state[].OldRepVarName[arg] == state[].OldRepVarName[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state[].NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state[].NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            
                                            if arg + 2 < state[].NumRepVarNames and state[].OldRepVarName[arg] == state[].OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state[].NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = state[].NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if state[].find_item_in_list(object_name, state[].NotInNew) != -1:
                                    state[].write_audit(String("Object=\"") + object_name + String("\" is not in the \"new\" IDD."))
                                    state[].write_audit(String("... will be listed as comments on the new output file."))
                                    state[].write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    no_diff = True
                        
                        else:
                            state[].get_new_object_def_in_idd(state[].IDFRecords[num].Name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                        
                        if diff_min_fields and no_diff:
                            state[].get_new_object_def_in_idd(object_name, nw_aor_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            no_diff = False
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            state[].check_special_objects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            state[].write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state[].IDFRecords[state[].NumIDFRecords - 1].CommtE != state[].CurComment:
                        for xcount in range(state[].IDFRecords[state[].NumIDFRecords - 1].CommtE + 1, state[].CurComment + 1):
                            if xcount < len(state[].Comments):
                                state[].write_line_to_unit(dif_lfn, state[].Comments[xcount])
                            if xcount == state[].IDFRecords[state[].NumIDFRecords - 1].CommtE:
                                state[].write_line_to_unit(dif_lfn, String(""))
                    
                    state[].close_file(dif_lfn)
                    if check_rvi:
                        state[].process_rvi_mvi_files(file_name_path, String("rvi"))
                        state[].process_rvi_mvi_files(file_name_path, String("mvi"))
                    state[].close_out()
                
                else:
                    state[].process_rvi_mvi_files(file_name_path, String("rvi"))
                    state[].process_rvi_mvi_files(file_name_path, String("mvi"))
            
            else:
                end_of_file[].set(True)
            
            state[].create_new_name(String("Reallocate"), String(""))
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[].set(False)
            else:
                end_of_file[].set(True)
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var err_flag = False
        state[].copyfile(file_name_path + String(".") + arg_idf_extension,
                      file_name_path + String(".") + arg_idf_extension + String("old"), err_flag)
        state[].copyfile(file_name_path + String(".") + arg_idf_extension + String("new"),
                      file_name_path + String(".") + arg_idf_extension, err_flag)
        
        if state[].file_exists(file_name_path + String(".rvi")):
            state[].copyfile(file_name_path + String(".rvi"), file_name_path + String(".rviold"), err_flag)
        
        if state[].file_exists(file_name_path + String(".rvinew")):
            state[].copyfile(file_name_path + String(".rvinew"), file_name_path + String(".rvi"), err_flag)
        
        if state[].file_exists(file_name_path + String(".mvi")):
            state[].copyfile(file_name_path + String(".mvi"), file_name_path + String(".mviold"), err_flag)
        
        if state[].file_exists(file_name_path + String(".mvinew")):
            state[].copyfile(file_name_path + String(".mvinew"), file_name_path + String(".mvi"), err_flag)
