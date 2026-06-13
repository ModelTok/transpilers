from sys.info import os_is_windows
from memory import memcpy, memset
from math import max as math_max

# EXTERNAL DEPS (to wire in glue):
# - ProgNameConversion: String
# - blank: String
# - MaxNameLength: Int
# - MaxAlphaArgsFound: Int
# - MaxNumericArgsFound: Int
# - MaxTotalArgs: Int
# - ProgPath: String
# - Auditf: file handle
# - IDFRecords: List of IDFRecord structs
# - Comments: List of Strings
# - Alphas: List of Strings
# - Numbers: List of Float64
# - InArgs: List of Strings
# - TempArgs: List of Strings
# - AorN: List of Bool
# - ReqFld: List of Bool
# - FldNames: List of Strings
# - FldDefaults: List of Strings
# - FldUnits: List of Strings
# - NwAorN: List of Bool
# - NwReqFld: List of Bool
# - NwFldNames: List of Strings
# - NwFldDefaults: List of Strings
# - NwFldUnits: List of Strings
# - OutArgs: List of Strings
# - MatchArg: List of Strings
# - PAorN: List of Bool
# - PReqFld: List of Bool
# - PFldNames: List of Strings
# - PFldDefaults: List of Strings
# - PFldUnits: List of Strings
# - POutArgs: List of Strings
# - DeleteThisRecord: List of Bool
# - ObjectDef: List of object definitions with Name field
# - NumObjectDefs: Int
# - NumIDFRecords: Int
# - NumRepVarNames: Int
# - CurComment: Int
# - ProcessingIMFFile: Bool
# - FatalError: Bool
# - FileOK: Bool
# - VersionNum: Float64
# - sVersionNum: String
# - VerString: String
# - IDDFileNameWithPath: String
# - NewIDDFileNameWithPath: String
# - RepVarFileNameWithPath: String
# - OldRepVarName: List of Strings
# - NewRepVarName: List of Strings
# - NewRepVarCaution: List of Strings
# - OTMVarCaution: List of Bool
# - CMtrVarCaution: List of Bool
# - CMtrDVarCaution: List of Bool
# - External functions: GetNewUnitNumber, TrimTrailZeros, FindItemInList,
#   GetObjectDefInIDD, GetNewObjectDefInIDD, MakeUPPERCase, MakeLowerCase,
#   SameString, DisplayString, ProcessInput, CheckSpecialObjects,
#   WriteOutIDFLines, WriteOutIDFLinesAsComments, writePreprocessorObject,
#   CreateNewName, CloseOut, ProcessRviMviFiles, ShowWarningError, copyfile,
#   GetNumSectionsFound

struct IDFRecord:
    var Name: String
    var NumAlphas: Int
    var NumNumbers: Int
    var Alphas: List[String]
    var Numbers: List[Float64]
    var CommtS: Int
    var CommtE: Int

struct ExternalState:
    var ProgNameConversion: String
    var blank: String
    var MaxNameLength: Int
    var MaxAlphaArgsFound: Int
    var MaxNumericArgsFound: Int
    var MaxTotalArgs: Int
    var ProgPath: String
    var Auditf: AnyPointer
    var IDFRecords: List[IDFRecord]
    var Comments: List[String]
    var Alphas: List[String]
    var Numbers: List[Float64]
    var InArgs: List[String]
    var TempArgs: List[String]
    var AorN: List[Bool]
    var ReqFld: List[Bool]
    var FldNames: List[String]
    var FldDefaults: List[String]
    var FldUnits: List[String]
    var NwAorN: List[Bool]
    var NwReqFld: List[Bool]
    var NwFldNames: List[String]
    var NwFldDefaults: List[String]
    var NwFldUnits: List[String]
    var OutArgs: List[String]
    var MatchArg: List[String]
    var PAorN: List[Bool]
    var PReqFld: List[Bool]
    var PFldNames: List[String]
    var PFldDefaults: List[String]
    var PFldUnits: List[String]
    var POutArgs: List[String]
    var DeleteThisRecord: List[Bool]
    var ObjectDef: List[AnyPointer]
    var NumObjectDefs: Int
    var NumIDFRecords: Int
    var NumRepVarNames: Int
    var CurComment: Int
    var ProcessingIMFFile: Bool
    var FatalError: Bool
    var FileOK: Bool
    var VersionNum: Float64
    var sVersionNum: String
    var VerString: String
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String
    var OldRepVarName: List[String]
    var NewRepVarName: List[String]
    var NewRepVarCaution: List[String]
    var OTMVarCaution: List[Bool]
    var CMtrVarCaution: List[Bool]
    var CMtrDVarCaution: List[Bool]
    var NotInNew: List[String]
    var ObjMinFlds: Int
    var NwObjMinFlds: Int
    var MakingPretty: Bool

fn trim_string(s: String) -> String:
    return s.rstrip()

fn make_lower_case(s: String) -> String:
    var result = String()
    for i in range(len(s)):
        if s[i].isupper():
            result += chr(ord(s[i]) + 32)
        else:
            result += s[i]
    return result

fn make_upper_case(s: String) -> String:
    var result = String()
    for i in range(len(s)):
        if s[i].islower():
            result += chr(ord(s[i]) - 32)
        else:
            result += s[i]
    return result

fn find_item_in_list(item: String, lst: List[String], size: Int) -> Int:
    let upper_item = make_upper_case(item)
    for i in range(min(size, len(lst))):
        if make_upper_case(lst[i]) == upper_item:
            return i + 1
    return 0

fn same_string(s1: String, s2: String) -> Bool:
    return make_upper_case(s1) == make_upper_case(s2)

fn set_this_version_variables(inout state: ExternalState) -> None:
    state.VerString = "Conversion 9.0 => 9.1"
    state.VersionNum = 9.1
    state.sVersionNum = "9.1"
    state.IDDFileNameWithPath = trim_string(state.ProgPath) + "V9-0-0-Energy+.idd"
    state.NewIDDFileNameWithPath = trim_string(state.ProgPath) + "V9-1-0-Energy+.idd"
    state.RepVarFileNameWithPath = trim_string(state.ProgPath) + "Report Variables 9-0-0 to 9-1-0.csv"

fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: ExternalState,
    get_new_unit_number: AnyPointer,
    trim_trail_zeros: AnyPointer,
    display_string: AnyPointer,
    process_input: AnyPointer,
    get_object_def_in_idd: AnyPointer,
    get_new_object_def_in_idd: AnyPointer,
    check_special_objects: AnyPointer,
    write_out_idf_lines: AnyPointer,
    write_out_idf_lines_as_comments: AnyPointer,
    write_preprocessor_object: AnyPointer,
    create_new_name: AnyPointer,
    close_out: AnyPointer,
    process_rvi_mvi_files: AnyPointer,
    show_warning_error: AnyPointer,
    copyfile: AnyPointer,
    get_num_sections_found: AnyPointer
) -> None:
    var first_time = True
    
    if first_time:
        first_time = False
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file[0] = False
    var ios = 0
    
    var full_file_name = state.blank
    var file_name_path = state.blank
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                try:
                    full_file_name = input()
                except:
                    full_file_name = state.blank
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                    except:
                        full_file_name = state.blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.blank
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == "!":
                    full_file_name = state.blank
                    continue
            
            var units_arg = state.blank
            if ios != 0:
                full_file_name = state.blank
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != state.blank:
                print("Processing IDF -- " + trim_string(full_file_name))
                
                var dot_pos = 0
                for i in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[i] == ".":
                        dot_pos = i
                        break
                
                if dot_pos != 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = trim_string(full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn = 1
                var file_ok = True
                
                if not file_ok:
                    print("File not found=" + trim_string(full_file_name))
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var dif_file_name = ""
                    if diff_only:
                        dif_file_name = trim_string(file_name_path) + "." + trim_string(local_file_extension) + "dif"
                    else:
                        dif_file_name = trim_string(file_name_path) + "." + trim_string(local_file_extension) + "new"
                    
                    if local_file_extension == "imf":
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    var num_alphas = 0
                    var num_numbers = 0
                    var cur_args = 0
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var schedule_type_limits_any_number = False
                    for num in range(state.NumIDFRecords):
                        if not same_string(state.IDFRecords[num].Name, "ScheduleTypeLimits"):
                            continue
                        if num < len(state.IDFRecords) and state.IDFRecords[num].NumAlphas > 0:
                            if not same_string(state.IDFRecords[num].Alphas[0], "Any Number"):
                                continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            var del_msg = "! Deleting: " + trim_string(state.IDFRecords[num].Name) + "=\""
                            if state.IDFRecords[num].NumAlphas > 0:
                                del_msg += trim_string(state.IDFRecords[num].Alphas[0])
                            del_msg += "\".\n"
                    
                    print("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE):
                            if xcount < len(state.Comments):
                                pass
                            if xcount == state.IDFRecords[num].CommtE - 1:
                                pass
                        
                        if no_version and num == 0:
                            state.OutArgs[0] = state.sVersionNum
                            cur_args = 1
                        
                        var obj_name_upper = make_upper_case(trim_string(state.IDFRecords[num].Name))
                        
                        if obj_name_upper == "PROGRAMCONTROL":
                            continue
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
                        
                        var object_name = state.IDFRecords[num].Name
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if obj_name_upper == "VERSION":
                            if state.InArgs[0][0:3] == state.sVersionNum and arg_file:
                                latest_version = True
                                break
                            state.OutArgs[0] = state.sVersionNum
                            no_diff = False
                        
                        elif obj_name_upper == "HYBRIDMODEL:ZONE":
                            no_diff = False
                            for i in range(4):
                                state.OutArgs[i] = state.InArgs[i]
                            state.OutArgs[4] = "No"
                            state.OutArgs[5] = state.InArgs[4]
                            for i in range(6, 16):
                                state.OutArgs[i] = state.blank
                            for i in range(4):
                                if 16 + i < len(state.OutArgs) and 5 + i < len(state.InArgs):
                                    state.OutArgs[16 + i] = state.InArgs[5 + i]
                            cur_args = 20
                            no_diff = False
                        
                        elif obj_name_upper == "ZONEHVAC:EQUIPMENTLIST":
                            no_diff = False
                            state.OutArgs[0] = state.InArgs[0]
                            state.OutArgs[1] = state.InArgs[1]
                            for i in range(1, ((cur_args - 2) // 4) + 1):
                                if (i - 1) * 6 + 2 < len(state.OutArgs) and (i - 1) * 4 + 2 < len(state.InArgs):
                                    state.OutArgs[(i - 1) * 6 + 2] = state.InArgs[(i - 1) * 4 + 2]
                                if (i - 1) * 6 + 3 < len(state.OutArgs) and (i - 1) * 4 + 3 < len(state.InArgs):
                                    state.OutArgs[(i - 1) * 6 + 3] = state.InArgs[(i - 1) * 4 + 3]
                                if (i - 1) * 6 + 4 < len(state.OutArgs) and (i - 1) * 4 + 4 < len(state.InArgs):
                                    state.OutArgs[(i - 1) * 6 + 4] = state.InArgs[(i - 1) * 4 + 4]
                                if (i - 1) * 6 + 5 < len(state.OutArgs) and (i - 1) * 4 + 5 < len(state.InArgs):
                                    state.OutArgs[(i - 1) * 6 + 5] = state.InArgs[(i - 1) * 4 + 5]
                                if (i - 1) * 6 + 6 < len(state.OutArgs):
                                    state.OutArgs[(i - 1) * 6 + 6] = ""
                                if (i - 1) * 6 + 7 < len(state.OutArgs):
                                    state.OutArgs[(i - 1) * 6 + 7] = ""
                            cur_args = (((cur_args - 2) // 4) * 6) + 2
                        
                        elif obj_name_upper == "OUTPUT:VARIABLE":
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            no_diff = True
                            if state.OutArgs[0] == state.blank:
                                state.OutArgs[0] = "*"
                                no_diff = False
                        
                        elif obj_name_upper == "OUTPUT:TABLE:MONTHLY":
                            no_diff = True
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            var cur_var = 2
                            for var in range(2, cur_args, 2):
                                var uc_rep_var_name = make_upper_case(state.InArgs[var])
                                state.OutArgs[cur_var] = state.InArgs[var]
                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                var pos = uc_rep_var_name.find("[")
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[0:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var][0:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                var del_this = False
                                for arg in range(state.NumRepVarNames):
                                    var uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    var wild_match = False
                                    if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[0:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                    else:
                                        wild_match = False
                                        pos = 0
                                        if uc_rep_var_name == uc_comp_rep_var_name:
                                            pos = 1
                                    
                                    if pos > 0 and pos != 1:
                                        continue
                                    if pos > 0:
                                        if arg < len(state.NewRepVarName) and state.NewRepVarName[arg] != "<DELETE>":
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                            if arg < len(state.NewRepVarCaution) and len(state.NewRepVarCaution[arg]) > 0:
                                                if not same_string(state.NewRepVarCaution[arg][0:6], "Forkeq"):
                                                    if arg < len(state.OTMVarCaution) and not state.OTMVarCaution[arg]:
                                                        state.OTMVarCaution[arg] = True
                                            state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        
                                        if arg + 1 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if arg < len(state.NewRepVarCaution) and not same_string(state.NewRepVarCaution[arg][0:6], "Forkeq"):
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg + 1]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                        
                                        if arg + 2 < len(state.OldRepVarName) and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg + 2]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                            state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                            no_diff = False
                                        break
                                if not del_this:
                                    cur_var += 2
                            cur_args = cur_var - 1
                        
                        else:
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            no_diff = True
                        
                        if diff_min_fields and no_diff:
                            for i in range(cur_args):
                                state.OutArgs[i] = state.InArgs[i]
                            no_diff = False
                            for arg in range(cur_args, state.NwObjMinFlds):
                                if arg < len(state.NwFldDefaults):
                                    state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = math_max(state.NwObjMinFlds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            pass
                        
                        if not written:
                            pass
                    
                    print("Processing IDF -- Processing idf objects complete.")
                    
                    if state.NumIDFRecords > 0:
                        if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                            for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE, state.CurComment):
                                if xcount < len(state.Comments):
                                    pass
                    
                else:
                    pass
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
        pass
