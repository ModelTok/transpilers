from collections import Dict, List
from utils.string import String
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.Blank: string constant for blank values
# - DataVCompareGlobals: global state (VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf, ProcessingIMFFile, MakingPretty, CurComment, FileOK, NumRepVarNames, OldRepVarName, NewRepVarName)
# - InputProcessor: functions/state (ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, NumIDFRecords, IDFRecords, Comments, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, FatalError, CloseOut)
# - VCompareGlobalRoutines: functions (FindNumber)
# - General: functions (ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError, GetNewUnitNumber, TrimTrailZeros, FindItemInList, MakeUPPERCase, MakeLowerCase, ProcessNumber, samestring, DisplayString, WriteOutIDFLinesAsComments, WriteOutIDFLines, CheckSpecialObjects, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CreateNewName, copyfile)
# - DataGlobals: error display functions

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[String]
    var commt_s: Int
    var commt_e: Int

struct ObjectDefEntry:
    var name: String

struct ExternalState:
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var full_file_name: String
    var file_name_path: String
    var auditf: Int
    var processing_imf_file: Bool
    var making_pretty: Bool
    var cur_comment: Int
    var file_ok: Bool
    var num_rep_var_names: Int
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var num_idf_records: Int
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var fatal_error: Bool
    var object_def: List[ObjectDefEntry]
    var num_object_defs: Int
    var not_in_new: List[String]

fn set_this_version_variables(inout state: ExternalState) -> None:
    state.ver_string = "Conversion 1.3 => 1.4"
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path + "V1-3-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V1-4-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 1-3-0-018 to 1-4-0.csv"

fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: ExternalState
) -> Bool:
    
    let BLANK = ""
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    var end_of_file_local = False
    var ios = 0
    var err_flag = False
    
    let max_total_args = state.max_total_args
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file_local:
            var full_file_name = String()
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                let input_line = input()
                full_file_name = input_line
            else:
                if not arg_file:
                    ios = 1
                    full_file_name = BLANK
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = BLANK
                    ios = 1
            
            if full_file_name.count > 0 and full_file_name[0] == "!":
                full_file_name = BLANK
                continue
            
            if ios != 0:
                full_file_name = BLANK
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != BLANK:
                print("Processing IDF -- " + full_file_name)
                
                let dot_pos = full_file_name.rfind(".")
                var file_name_path = String()
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                state.file_name_path = file_name_path
                
                var file_ok = os.path.exists(full_file_name)
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file_local = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    
                    var dif_file_name = String()
                    if diff_only:
                        dif_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var alphas = List[String](capacity=state.max_alpha_args_found + 1)
                    var numbers = List[String](capacity=state.max_numeric_args_found + 1)
                    var in_args = List[String](capacity=max_total_args + 1)
                    var a_or_n = List[Bool](capacity=max_total_args + 1)
                    var req_fld = List[Bool](capacity=max_total_args + 1)
                    var fld_names = List[String](capacity=max_total_args + 1)
                    var fld_defaults = List[String](capacity=max_total_args + 1)
                    var fld_units = List[String](capacity=max_total_args + 1)
                    var nw_a_or_n = List[Bool](capacity=max_total_args + 1)
                    var nw_req_fld = List[Bool](capacity=max_total_args + 1)
                    var nw_fld_names = List[String](capacity=max_total_args + 1)
                    var nw_fld_defaults = List[String](capacity=max_total_args + 1)
                    var nw_fld_units = List[String](capacity=max_total_args + 1)
                    var out_args = List[String](capacity=max_total_args + 1)
                    var match_arg = List[String](capacity=max_total_args + 1)
                    var delete_this_record = List[Bool](capacity=state.num_idf_records + 1)
                    
                    var comis_sim = False
                    var ads_sim = False
                    
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num - 1].name.upper() == "COMIS SIMULATION":
                            comis_sim = True
                        if state.idf_records[num - 1].name.upper() == "ADS SIMULATION":
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        print("File contains both COMIS and ADS Simulation objects=" + full_file_name)
                        print("Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.")
                        exit_because_bad_file = True
                        break
                    
                    var no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num - 1].name.upper() != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var dif_file = open(dif_file_name, "w")
                    
                    for num in range(1, state.num_idf_records + 1):
                        var object_name = state.idf_records[num - 1].name
                        var obj_upper = object_name.upper()
                        
                        if obj_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if obj_upper == "AIRFLOW MODEL":
                            continue
                        if obj_upper == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if obj_upper == "WATER HEATER:SIMPLE":
                            dif_file.write("\n")
                            continue
                        
                        var num_alphas = state.idf_records[num - 1].num_alphas
                        var num_numbers = state.idf_records[num - 1].num_numbers
                        var cur_args = num_alphas + num_numbers
                        var in_args_local = List[String](capacity=max_total_args + 1)
                        var out_args_local = List[String](capacity=max_total_args + 1)
                        
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if not state.making_pretty:
                            if obj_upper == "VERSION":
                                out_args_local.append("1.4")
                                no_diff = False
                            
                            elif obj_upper == "COOLING TOWER:VARIABLE SPEED":
                                out_args_local.append("")
                                for i in range(1, 18):
                                    out_args_local.append(in_args_local[i])
                                out_args_local.append(in_args_local[18])
                                out_args_local.append("Saturated Exit")
                                out_args_local.append(" ")
                                out_args_local.append(in_args_local[19])
                                out_args_local.append("Scheduled Rate")
                                out_args_local.append(" ")
                                cur_args = 23
                                no_diff = False
                            
                            elif obj_upper == "CHILLER:ELECTRIC:EIR":
                                for i in range(1, 20):
                                    out_args_local.append(in_args_local[i])
                                for arg in range(21, cur_args + 1):
                                    out_args_local.append(in_args_local[arg])
                                cur_args -= 1
                                no_diff = False
                            
                            elif obj_upper == "WATER HEATER:MIXED":
                                for i in range(1, 20):
                                    out_args_local.append(in_args_local[i])
                                if in_args_local[20].upper() == "EXTERIOR":
                                    out_args_local.append("Outside Air Node")
                                else:
                                    out_args_local.append(in_args_local[20])
                                out_args_local.append(in_args_local[21])
                                out_args_local.append(in_args_local[22])
                                if in_args_local[20].upper() == "EXTERIOR":
                                    out_args_local.append(in_args_local[1] + " OA Node")
                                else:
                                    out_args_local.append(" ")
                                for arg in range(23, cur_args + 1):
                                    out_args_local.append(in_args_local[arg])
                                cur_args += 1
                                no_diff = False
                                written = True
                            
                            elif obj_upper == "SET POINT MANAGER:OUTSIDE AIR PRETREAT":
                                for i in range(1, 5):
                                    out_args_local.append(in_args_local[i])
                                if in_args_local[5].to_f64() == 0.0:
                                    out_args_local.append("0.00001")
                                    no_diff = False
                                else:
                                    out_args_local.append(in_args_local[5])
                                if in_args_local[6].to_f64() == 0.0:
                                    out_args_local.append("0.00001")
                                    no_diff = False
                                else:
                                    out_args_local.append(in_args_local[6])
                                for i in range(7, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                            
                            elif obj_upper == "BUILDING":
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                if cur_args == 8:
                                    no_diff = False
                                    if out_args_local[8].upper() == "YES":
                                        out_args_local[6] = out_args_local[6] + "WithReflections"
                                        out_args_local[8] = BLANK
                                        cur_args = 7
                                    elif out_args_local[8].upper() == "NO":
                                        out_args_local[8] = BLANK
                                        cur_args = 7
                            
                            elif obj_upper == "WINDOWSHADINGCONTROL":
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = False
                                if in_args_local[2].lower() == "interiornoninsulatingshade":
                                    out_args_local[2] = "InteriorShade"
                                if in_args_local[2].lower() == "exteriornoninsulatingshade":
                                    out_args_local[2] = "ExteriorShade"
                                if in_args_local[2].lower() == "interiorinsulatingshade":
                                    out_args_local[2] = "InteriorShade"
                                if in_args_local[2].lower() == "exteriorinsulatingshade":
                                    out_args_local[2] = "ExteriorShade"
                                if in_args_local[4].lower() == "schedule":
                                    out_args_local[4] = "OnIfScheduleAllows"
                                if in_args_local[4].lower() == "solaronwindow":
                                    out_args_local[4] = "OnIfHighSolarOnWindow"
                                if in_args_local[4].lower() == "horizontalsolar":
                                    out_args_local[4] = "OnIfHighHorizontalSolar"
                                if in_args_local[4].lower() == "outsideairtemp":
                                    out_args_local[4] = "OnIfHighOutsideAirTemp"
                                if in_args_local[4].lower() == "zoneairtemp":
                                    out_args_local[4] = "OnIfHighZoneAirTemp"
                                if in_args_local[4].lower() == "zonecooling":
                                    out_args_local[4] = "OnIfHighZoneCooling"
                                if in_args_local[4].lower() == "glare":
                                    out_args_local[4] = "OnIfHighGlare"
                                if in_args_local[4].lower() == "daylightilluminance":
                                    out_args_local[4] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif obj_upper == "REPORT VARIABLE":
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = True
                                if out_args_local[1] == BLANK:
                                    out_args_local[1] = "*"
                                    no_diff = False
                            
                            elif obj_upper in ["REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"]:
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = True
                            
                            elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = True
                                if out_args_local[1] == BLANK:
                                    out_args_local[1] = "*"
                                    no_diff = False
                            
                            elif obj_upper == "REPORT:TABLE:MONTHLY":
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = True
                                if out_args_local[1] == BLANK:
                                    out_args_local[1] = "*"
                                    no_diff = False
                            
                            else:
                                for i in range(1, cur_args + 1):
                                    out_args_local.append(in_args_local[i])
                                no_diff = True
                        else:
                            for i in range(1, cur_args + 1):
                                out_args_local.append(in_args_local[i])
                        
                        if diff_min_fields and no_diff:
                            no_diff = False
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            pass
            else:
                end_of_file_local = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file_local = False
            else:
                end_of_file_local = True
                still_working = False
    
    return end_of_file_local
