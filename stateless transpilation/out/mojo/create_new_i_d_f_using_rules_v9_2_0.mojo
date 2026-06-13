# EXTERNAL DEPS (to wire in glue):
# - VerString, VersionNum, sVersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath (DataVCompareGlobals)
# - ProgramPath (DataStringGlobals)
# - Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits (module state)
# - NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg (module state)
# - PAorN, PReqFld, PFldNames, PFldDefaults, PFldUnits, POutArgs (module state)
# - IDFRecords, Comments, NumIDFRecords, CurComment (module state)
# - MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs (module state)
# - NumAlphas, NumNumbers, NumArgs, ObjMinFlds, NwNumArgs, NwObjMinFlds (module state)
# - ObjectDef, NumObjectDefs (module state)
# - ProcessingIMFFile, FatalError (module state)
# - NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames (module state)
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution (module state)
# - FileOK, Auditf, FullFileName, FileNamePath, Blank (module state)
# - MakingPretty (module state)
# - GetNewUnitNumber, ProcessInput, DisplayString, GetNewObjectDefInIDD, GetObjectDefInIDD (InputProcessor)
# - FindItemInList, MakeUPPERCase, SameString, TrimSigDigits, RoundSigDigits, MakeLowerCase (General)
# - WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects (output routines)
# - ScanOutputVariablesForReplacement, writePreprocessorObject, ProcessRviMviFiles, CloseOut, CreateNewName (conversion routines)
# - copyfile, ShowWarningError, ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError (DataGlobals)
# - GetNumObjectsFound, GetObjectItem, GetNumSectionsFound (InputProcessor)
# - ProcessNumber, SortUnique (utility)

from collections import List
from memory import UnsafePointer


fn set_this_version_variables(inout state: State):
    """Set version conversion variables."""
    state.VerString = "Conversion 9.1 => 9.2"
    state.VersionNum = 9.2
    state.sVersionNum = "9.2"
    state.IDDFileNameWithPath = state.ProgramPath.strip() + "V9-1-0-Energy+.idd"
    state.NewIDDFileNameWithPath = state.ProgramPath.strip() + "V9-2-0-Energy+.idd"
    state.RepVarFileNameWithPath = state.ProgramPath.strip() + "Report Variables 9-1-0 to 9-2-0.csv"


fn create_new_idf_using_rules(
    inout state: State,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: StringLiteral,
    arg_file: Bool,
    arg_idf_extension: StringLiteral
) -> Bool:
    """
    Create new IDFs based on conversion rules.
    
    Returns: end_of_file flag
    """
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = String(arg_idf_extension)
    end_of_file = False
    var ios: Int = 0
    
    let fmta: StringLiteral = "(A)"
    let blank: StringLiteral = ""
    
    # Preallocate arrays
    state.Alphas = List[String](capacity=state.MaxAlphaArgsFound + 1)
    state.Numbers = List[Float64](capacity=state.MaxNumericArgsFound + 1)
    state.InArgs = List[String](capacity=state.MaxTotalArgs + 1)
    state.TempArgs = List[String](capacity=state.MaxTotalArgs + 1)
    state.AorN = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.ReqFld = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.FldNames = List[String](capacity=state.MaxTotalArgs + 1)
    state.FldDefaults = List[String](capacity=state.MaxTotalArgs + 1)
    state.FldUnits = List[String](capacity=state.MaxTotalArgs + 1)
    state.NwAorN = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.NwReqFld = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.NwFldNames = List[String](capacity=state.MaxTotalArgs + 1)
    state.NwFldDefaults = List[String](capacity=state.MaxTotalArgs + 1)
    state.NwFldUnits = List[String](capacity=state.MaxTotalArgs + 1)
    state.OutArgs = List[String](capacity=state.MaxTotalArgs + 1)
    state.PAorN = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.PReqFld = List[Bool](capacity=state.MaxTotalArgs + 1)
    state.PFldNames = List[String](capacity=state.MaxTotalArgs + 1)
    state.PFldDefaults = List[String](capacity=state.MaxTotalArgs + 1)
    state.PFldUnits = List[String](capacity=state.MaxTotalArgs + 1)
    state.POutArgs = List[String](capacity=state.MaxTotalArgs + 1)
    state.MatchArg = List[String](capacity=state.MaxTotalArgs + 1)
    
    var delete_this_record = List[Bool](capacity=state.NumIDFRecords + 1)
    var num_perim_objs: Int = 0
    var pargs: Int = 0
    
    var current_run_period_names = List[String]()
    var iterate_run_period: Int = 0
    var tot_run_periods: Int = 0
    
    var num_ind_vars_vals = List[Int]()
    var cur_indices = List[Int]()
    var increments = List[Int]()
    var step_size = List[Int]()
    var ind_vars = List[List[String]]()
    var ind_var_order = List[List[Int]]()
    var output_vals = List[String]()
    
    var schedule_type_limits_any_number: Bool = False
    var write_schedule_type_obj: Bool = True
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            var full_file_name: String
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # Input reading would be done through state
                full_file_name = state.read_input()
            else:
                if not arg_file:
                    try:
                        full_file_name = state.read_input()
                        ios = 0
                    except:
                        full_file_name = blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = String(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                
                if full_file_name.size() > 0 and full_file_name[0] == UInt8(ord('!')):
                    full_file_name = blank
                    continue
            
            var units_arg: String = blank
            if ios != 0:
                full_file_name = blank
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name.size() > 0:
                state.DisplayString("Processing IDF -- " + full_file_name)
                state.Auditf_write(" Processing IDF -- " + full_file_name + "\n")
                
                var dot_pos: Int = full_file_name.rfind(".")
                var file_name_path: String
                
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = state.MakeLowerCase(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    state.Auditf_write(" ..assuming file extension of .idf\n")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                # Check if file exists
                var file_ok: Bool = state.file_exists(full_file_name)
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    state.Auditf_write("File not found=" + full_file_name + "\n")
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_lfn_path: String
                    if diff_only:
                        dif_lfn_path = file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_lfn_path = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        state.ShowWarningError("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.")
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    for i in range(state.NumIDFRecords + 1):
                        delete_this_record.append(False)
                    
                    no_version = True
                    for num in range(1, state.NumIDFRecords + 1):
                        if state.MakeUPPERCase(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for num in range(1, state.NumIDFRecords + 1):
                        if not state.SameString(state.IDFRecords[num].Name, "ScheduleTypeLimits"):
                            continue
                        if not state.SameString(state.IDFRecords[num].Alphas[1], "Any Number"):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            state.write_to_file(dif_lfn_path, "! Deleting: " + state.IDFRecords[num].Name + "=\"" + state.IDFRecords[num].Alphas[1] + "\".\n")
                    
                    # Pre-process RunPeriod
                    state.DisplayString("Processing IDF -- RunPeriod preprocessing . . .")
                    iterate_run_period = 0
                    tot_run_periods = state.GetNumObjectsFound("RUNPERIOD")
                    
                    for run_period_num in range(1, tot_run_periods + 1):
                        var alphas = state.GetObjectItem("RUNPERIOD", run_period_num)
                        current_run_period_names.append(alphas[1].strip())
                    
                    state.DisplayString("Processing IDF -- RunPeriod preprocessing complete.")
                    
                    # Main processing loop
                    state.DisplayString("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(1, state.NumIDFRecords + 1):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS + 1, state.IDFRecords[num].CommtE + 1):
                            state.write_to_file(dif_lfn_path, state.Comments[xcount] + "\n")
                            if xcount == state.IDFRecords[num].CommtE:
                                state.write_to_file(dif_lfn_path, "\n")
                        
                        if no_version and num == 1:
                            var object_name: String = "VERSION"
                            state.GetNewObjectDefInIDD(object_name)
                            state.OutArgs[1] = state.sVersionNum
                            var cur_args: Int = 1
                            state.WriteOutIDFLinesAsComments(dif_lfn_path, "Version", cur_args)
                        
                        var object_name: String = state.IDFRecords[num].Name
                        var upper_obj_name: String = state.MakeUPPERCase(state.IDFRecords[num].Name)
                        
                        # Check for deleted objects
                        if upper_obj_name == "PROGRAMCONTROL":
                            continue
                        if upper_obj_name == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if upper_obj_name == "AIRFLOW MODEL":
                            continue
                        if upper_obj_name == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if upper_obj_name == "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS":
                            continue
                        if upper_obj_name == "WATER HEATER:SIMPLE":
                            state.write_to_file(dif_lfn_path, "! ** The WATER HEATER:SIMPLE object has been deleted\n")
                            state.writePreprocessorObject(dif_lfn_path, state.ProgNameConversion, "Warning", "The WATER HEATER:SIMPLE object has been deleted")
                            continue
                        
                        if state.FindItemInList(object_name, state.ObjectDef_Name, state.NumObjectDefs) != 0:
                            state.GetObjectDefInIDD(object_name)
                            var num_alphas: Int = state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                state.Alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(1, num_numbers + 1):
                                state.Numbers[i] = state.IDFRecords[num].Numbers[i]
                            
                            var cur_args: Int = num_alphas + num_numbers
                            for i in range(1, state.MaxTotalArgs + 1):
                                state.InArgs[i] = blank
                                state.OutArgs[i] = blank
                                state.TempArgs[i] = blank
                            
                            var na: Int = 0
                            var nn: Int = 0
                            for arg in range(1, cur_args + 1):
                                if state.AorN[arg]:
                                    na += 1
                                    state.InArgs[arg] = state.Alphas[na]
                                else:
                                    nn += 1
                                    state.InArgs[arg] = String(state.Numbers[nn])
                        else:
                            state.Auditf_write("Object=\"" + object_name + "\" does not seem to be on the \"old\" IDD.\n")
                            state.Auditf_write("... will be listed as comments (no field names) on the new output file.\n")
                            state.Auditf_write("... Alpha fields will be listed first, then numerics.\n")
                            
                            var num_alphas: Int = state.IDFRecords[num].NumAlphas
                            var num_numbers: Int = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                state.OutArgs[i] = state.IDFRecords[num].Alphas[i]
                            
                            var nn: Int = num_alphas + 1
                            for i in range(1, num_numbers + 1):
                                state.OutArgs[nn] = String(state.IDFRecords[num].Numbers[i])
                                nn += 1
                            
                            var cur_args: Int = num_alphas + num_numbers
                            state.WriteOutIDFLinesAsComments(dif_lfn_path, object_name, cur_args)
                            continue
                        
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if state.FindItemInList(state.MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            state.GetNewObjectDefInIDD(object_name)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            var upper_obj: String = state.MakeUPPERCase(state.IDFRecords[num].Name)
                            
                            if upper_obj == "VERSION":
                                if state.InArgs[1][0:3] == state.sVersionNum and arg_file:
                                    state.ShowWarningError("File is already at latest version.  No new diff file made.")
                                    latest_version = True
                                    break
                                state.GetNewObjectDefInIDD(object_name)
                                state.OutArgs[1] = state.sVersionNum
                                no_diff = False
                            
                            elif upper_obj == "FOUNDATION:KIVA":
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                state.OutArgs[1] = state.InArgs[1]
                                state.OutArgs[2] = blank
                                for i in range(3, cur_args + 2):
                                    state.OutArgs[i] = state.InArgs[i - 1]
                                cur_args = cur_args + 1
                                no_diff = False
                            
                            elif upper_obj == "RUNPERIOD":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                if state.SameString(state.InArgs[1].strip(), ""):
                                    no_diff = False
                                    iterate_run_period += 1
                                    var potential_run_period_name: String = "RUNPERIOD " + state.TrimSigDigits(iterate_run_period)
                                    while state.FindItemInList(potential_run_period_name, current_run_period_names, tot_run_periods) != 0:
                                        iterate_run_period += 1
                                        potential_run_period_name = "RUNPERIOD " + state.TrimSigDigits(iterate_run_period)
                                    state.OutArgs[1] = potential_run_period_name
                            
                            elif upper_obj == "SCHEDULE:FILE":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                if state.SameString(state.InArgs[7].strip(), "FIXED"):
                                    no_diff = False
                                    state.OutArgs[7] = "SPACE"
                            
                            elif upper_obj == "TABLE:ONEINDEPENDENTVARIABLE":
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf_write("Object=\"" + object_name + "\" is not in the \"new\" IDD.\n")
                                state.Auditf_write("... will be listed as comments on the new output file.\n")
                                state.WriteOutIDFLinesAsComments(dif_lfn_path, object_name, cur_args)
                                written = True
                            
                            elif upper_obj == "TABLE:TWOINDEPENDENTVARIABLES":
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf_write("Object=\"" + object_name + "\" is not in the \"new\" IDD.\n")
                                state.Auditf_write("... will be listed as comments on the new output file.\n")
                                state.WriteOutIDFLinesAsComments(dif_lfn_path, object_name, cur_args)
                                written = True
                            
                            elif upper_obj == "TABLE:MULTIVARIABLELOOKUP":
                                state.GetNewObjectDefInIDD(object_name)
                                state.Auditf_write("Object=\"" + object_name + "\" is not in the \"new\" IDD.\n")
                                state.Auditf_write("... will be listed as comments on the new output file.\n")
                                state.WriteOutIDFLinesAsComments(dif_lfn_path, object_name, cur_args)
                                written = True
                            
                            elif upper_obj == "THERMALSTORAGE:ICE:DETAILED":
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = False
                                for i in range(1, 6):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                if state.SameString(state.InArgs[6].strip(), "QUADRATICLINEAR"):
                                    state.OutArgs[6] = "FractionDischargedLMTD"
                                elif state.SameString(state.InArgs[6].strip(), "CUBICLINEAR"):
                                    state.OutArgs[6] = "LMTDMassFlow"
                                else:
                                    state.OutArgs[6] = state.InArgs[6]
                                
                                state.OutArgs[7] = state.InArgs[7]
                                
                                if state.SameString(state.InArgs[8].strip(), "QUADRATICLINEAR"):
                                    state.OutArgs[8] = "FractionChargedLMTD"
                                elif state.SameString(state.InArgs[8].strip(), "CUBICLINEAR"):
                                    state.OutArgs[8] = "LMTDMassFlow"
                                else:
                                    state.OutArgs[8] = state.InArgs[8]
                                
                                for i in range(9, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                
                                no_diff = False
                            
                            elif upper_obj == "ZONEHVAC:EQUIPMENTLIST":
                                no_diff = False
                                state.GetNewObjectDefInIDD(object_name)
                                write_schedule_type_obj = True
                                
                                for cur_field in range(1, cur_args + 1):
                                    var zeq_heating_or_cooling: String
                                    if cur_field < 3:
                                        zeq_heating_or_cooling = "Neither"
                                    elif ((cur_field - 2) - 5) % 6 == 0:
                                        zeq_heating_or_cooling = "Cooling"
                                    elif ((cur_field - 2) - 6) % 6 == 0:
                                        zeq_heating_or_cooling = "Heating"
                                    else:
                                        zeq_heating_or_cooling = "Neither"
                                    
                                    if state.InArgs[cur_field].size() > 0 and (zeq_heating_or_cooling == "Cooling" or zeq_heating_or_cooling == "Heating"):
                                        var zeq_num: Int = (cur_field - 3) // 6 + 1
                                        var zeq_num_str: String = state.RoundSigDigits(zeq_num, 0)
                                        
                                        if write_schedule_type_obj:
                                            state.GetNewObjectDefInIDD("ScheduleTypeLimits")
                                            state.POutArgs[1] = "ZoneEqList ScheduleTypeLimts"
                                            state.POutArgs[2] = "0.0"
                                            state.POutArgs[3] = "1.0"
                                            state.POutArgs[4] = "Continuous"
                                            state.WriteOutIDFLines(dif_lfn_path, "ScheduleTypeLimits", 4)
                                            write_schedule_type_obj = False
                                        
                                        state.OutArgs[cur_field] = state.InArgs[1] + " " + zeq_heating_or_cooling + "Frac" + zeq_num_str
                                        state.GetNewObjectDefInIDD("Schedule:Constant")
                                        state.POutArgs[1] = state.OutArgs[cur_field]
                                        state.POutArgs[2] = "ZoneEqList ScheduleTypeLimts"
                                        state.POutArgs[3] = state.InArgs[cur_field]
                                        state.WriteOutIDFLines(dif_lfn_path, "Schedule:Constant", state.PNumArgs)
                                    else:
                                        state.OutArgs[cur_field] = state.InArgs[cur_field]
                            
                            elif upper_obj == "OUTPUT:VARIABLE":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1].size() == 0:
                                    state.OutArgs[1] = "*"
                                    no_diff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn_path, cur_args)
                            
                            elif upper_obj == "OUTPUT:METER" or upper_obj == "OUTPUT:METER:METERFILEONLY" or upper_obj == "OUTPUT:METER:CUMULATIVE" or upper_obj == "OUTPUT:METER:CUMULATIVE:METERFILEONLY":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                state.ScanOutputVariablesForReplacement(1, object_name, dif_lfn_path, cur_args)
                            
                            elif upper_obj == "OUTPUT:TABLE:TIMEBINS":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1].size() == 0:
                                    state.OutArgs[1] = "*"
                                    no_diff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn_path, cur_args)
                            
                            elif upper_obj == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE" or upper_obj == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                if state.OutArgs[1].size() == 0:
                                    state.OutArgs[1] = "*"
                                    no_diff = False
                                state.ScanOutputVariablesForReplacement(2, object_name, dif_lfn_path, cur_args)
                            
                            elif upper_obj == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                                state.ScanOutputVariablesForReplacement(3, object_name, dif_lfn_path, cur_args)
                            
                            elif upper_obj == "OUTPUT:TABLE:MONTHLY":
                                state.GetNewObjectDefInIDD(object_name)
                                no_diff = True
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                # Complex table monthly logic would go here
                                pass
                            
                            elif upper_obj == "METER:CUSTOM":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                            
                            elif upper_obj == "METER:CUSTOMDECREMENT":
                                state.GetNewObjectDefInIDD(object_name)
                                for i in range(1, cur_args + 1):
                                    state.OutArgs[i] = state.InArgs[i]
                                no_diff = True
                            
                            else:
                                if state.FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                    state.Auditf_write("Object=\"" + object_name + "\" is not in the \"new\" IDD.\n")
                                    state.Auditf_write("... will be listed as comments on the new output file.\n")
                                    state.WriteOutIDFLinesAsComments(dif_lfn_path, object_name, cur_args)
                                    written = True
                                else:
                                    state.GetNewObjectDefInIDD(object_name)
                                    for i in range(1, cur_args + 1):
                                        state.OutArgs[i] = state.InArgs[i]
                                    no_diff = True
                        
                        else:  # MakingPretty
                            state.GetNewObjectDefInIDD(object_name)
                            for i in range(1, cur_args + 1):
                                state.OutArgs[i] = state.InArgs[i]
                        
                        if diff_min_fields and no_diff:
                            state.GetNewObjectDefInIDD(object_name)
                            for i in range(1, cur_args + 1):
                                state.OutArgs[i] = state.InArgs[i]
                            no_diff = False
                            for arg in range(cur_args + 1, state.NwObjMinFlds + 1):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            state.CheckSpecialObjects(dif_lfn_path, object_name, cur_args)
                        
                        if not written:
                            state.WriteOutIDFLines(dif_lfn_path, object_name, cur_args)
                    
                    state.DisplayString("Processing IDF -- Processing idf objects complete.")
                    
                    if state.IDFRecords[state.NumIDFRecords].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords].CommtE + 1, state.CurComment + 1):
                            state.write_to_file(dif_lfn_path, state.Comments[xcount] + "\n")
                    
                    if state.GetNumSectionsFound("Report Variable Dictionary") > 0:
                        var object_name: String = "Output:VariableDictionary"
                        state.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        state.OutArgs[1] = "Regular"
                        cur_args = 1
                        state.WriteOutIDFLines(dif_lfn_path, object_name, cur_args)
                    
                    state.ProcessRviMviFiles(file_name_path, "rvi")
                    state.ProcessRviMviFiles(file_name_path, "mvi")
                    state.CloseOut()
                else:
                    state.ProcessRviMviFiles(file_name_path, "rvi")
                    state.ProcessRviMviFiles(file_name_path, "mvi")
            else:
                end_of_file = True
            
            state.CreateNewName("Reallocate", "")
        
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
        state.copyfile(file_name_path + "." + arg_idf_extension, file_name_path + "." + arg_idf_extension + "old", err_flag)
        state.copyfile(file_name_path + "." + arg_idf_extension + "new", file_name_path + "." + arg_idf_extension, err_flag)
        if state.file_exists(file_name_path + ".rvi"):
            state.copyfile(file_name_path + ".rvi", file_name_path + ".rviold", err_flag)
        if state.file_exists(file_name_path + ".rvinew"):
            state.copyfile(file_name_path + ".rvinew", file_name_path + ".rvi", err_flag)
        if state.file_exists(file_name_path + ".mvi"):
            state.copyfile(file_name_path + ".mvi", file_name_path + ".mviold", err_flag)
        if state.file_exists(file_name_path + ".mvinew"):
            state.copyfile(file_name_path + ".mvinew", file_name_path + ".mvi", err_flag)
    
    return end_of_file


fn sort_unique(inout str_array: List[String], size: Int) -> List[Int]:
    """Sort unique values and return order indices."""
    var in_numbers = List[Float64]()
    var out_numbers = List[Float64]()
    var order = List[Int]()
    
    var init_size: Int = size
    
    for i in range(size):
        in_numbers.append(Float64(str_array[i]))
    
    var min_val: Float64 = in_numbers[0] - 1.0
    for i in range(1, size):
        if in_numbers[i] < min_val + 1.0:
            min_val = in_numbers[i] - 1.0
    
    var max_val: Float64 = in_numbers[0]
    for i in range(1, size):
        if in_numbers[i] > max_val:
            max_val = in_numbers[i]
    
    var cur_size: Int = 0
    while min_val < max_val:
        cur_size += 1
        var found_min: Float64 = max_val + 1.0
        for i in range(size):
            if in_numbers[i] > min_val and in_numbers[i] < found_min:
                found_min = in_numbers[i]
        min_val = found_min
        out_numbers.append(min_val)
    
    for i in range(cur_size):
        str_array[i] = String(out_numbers[i])
    
    for i in range(init_size):
        for i2 in range(cur_size):
            let diff: Float64 = out_numbers[i2] - in_numbers[i]
            if abs(diff) < 1e-10:
                order.append(i2 + 1)
                break
    
    return order
