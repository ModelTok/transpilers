from sys import argv
from pathlib import Path

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: Blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - DataVCompareGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath,
#                        RepVarFileNameWithPath, ProgramPath, FullFileName, FileNamePath,
#                        Comments, IDFRecords, NumIDFRecords, CurComment, FatalError,
#                        ProcessingIMFFile, Auditf, ObjectDef, NumObjectDefs, OldRepVarName,
#                        NewRepVarName, NumRepVarNames, NotInNew, MakingPretty
# - VCompareGlobalRoutines: various state management
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumObjectsFound
# - General: various utility functions
# - DataGlobals: error reporting functions
# External functions: GetNewUnitNumber(), FindNumber(), TrimTrailZeros()

@value
struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int
    var commt_e: Int

    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.alphas = DynamicVector[String]()
        self.numbers = DynamicVector[Float64]()
        self.commt_s = 0
        self.commt_e = 0


struct GlobalState:
    var blank: String
    var max_name_length: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var full_file_name: String
    var file_name_path: String
    var comments: DynamicVector[String]
    var idf_records: DynamicVector[IDFRecord]
    var num_idf_records: Int
    var cur_comment: Int
    var fatal_error: Bool
    var processing_imf_file: Bool
    var auditf: Int
    var object_def: DynamicVector[String]
    var num_object_defs: Int
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var num_rep_var_names: Int
    var not_in_new: DynamicVector[String]
    var making_pretty: Bool

    fn __init__(inout self):
        self.blank = ""
        self.max_name_length = 0
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0
        self.ver_string = ""
        self.version_num = 0.0
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""
        self.program_path = ""
        self.full_file_name = ""
        self.file_name_path = ""
        self.comments = DynamicVector[String]()
        self.idf_records = DynamicVector[IDFRecord]()
        self.num_idf_records = 0
        self.cur_comment = 0
        self.fatal_error = False
        self.processing_imf_file = False
        self.auditf = 0
        self.object_def = DynamicVector[String]()
        self.num_object_defs = 0
        self.old_rep_var_name = DynamicVector[String]()
        self.new_rep_var_name = DynamicVector[String]()
        self.num_rep_var_names = 0
        self.not_in_new = DynamicVector[String]()
        self.making_pretty = False


fn trim_string(s: String) -> String:
    """TRIM equivalent - remove trailing whitespace"""
    return s.rstrip()


fn adjust_left(s: String) -> String:
    """ADJUSTL equivalent - remove leading whitespace"""
    return s.lstrip()


fn make_lower_case(s: String) -> String:
    """MakeLowerCase equivalent"""
    return s.lower()


fn make_upper_case(s: String) -> String:
    """MakeUPPERCase equivalent"""
    return s.upper()


fn same_string(s1: String, s2: String) -> Bool:
    """Case-insensitive string comparison"""
    return s1.lower() == s2.lower()


fn find_item_in_list(target: String, list_items: DynamicVector[String], size: Int) -> Int:
    """FindItemInList - returns 1-based index or 0 if not found"""
    var target_upper = make_upper_case(target)
    for i in range(min(size, len(list_items))):
        if make_upper_case(list_items[i]) == target_upper:
            return i + 1
    return 0


fn set_this_version_variables(inout state: GlobalState) -> None:
    """SetThisVersionVariables subroutine"""
    state.ver_string = "Conversion 1.0.2 => 1.0.3"
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path.rstrip() + "V1-0-2-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path.rstrip() + "V1-0-3-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path.rstrip() + "Report Variables 1-0-2-008 to 1-0-3.csv"


fn create_new_idf_using_rules(
    inout state: GlobalState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
) -> Bool:
    """CreateNewIDFUsingRules subroutine - returns EndOfFile status"""
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    var end_of_file_local = False
    var ios = 0
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file_local:
            var full_file_name = String()
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # In actual implementation, would read from stdin
            else:
                if not arg_file:
                    # Read from file in_lfn
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == "!":
                    full_file_name = state.blank
                    continue
            
            if ios != 0:
                full_file_name = state.blank
            
            full_file_name = adjust_left(full_file_name)
            
            if full_file_name != state.blank:
                # Process file
                var dot_pos = full_file_name.rfind(".")
                var file_name_path = String()
                
                if dot_pos != -1:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = trim_string(full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                state.file_name_path = file_name_path
                state.full_file_name = full_file_name
                
                var file_ok = Path(full_file_name).exists()
                
                if not file_ok:
                    print("File not found=" + trim_string(full_file_name))
                    end_of_file_local = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    
                    var out_filename = String()
                    if diff_only:
                        out_filename = trim_string(file_name_path) + "." + trim_string(local_file_extension) + "dif"
                    else:
                        out_filename = trim_string(file_name_path) + "." + trim_string(local_file_extension) + "new"
                    
                    if local_file_extension == "imf":
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    var alphas = DynamicVector[String](state.max_alpha_args_found)
                    var numbers = DynamicVector[Float64](state.max_numeric_args_found)
                    var in_args = DynamicVector[String](state.max_total_args)
                    var aorn = DynamicVector[Bool](state.max_total_args)
                    var req_fld = DynamicVector[Bool](state.max_total_args)
                    var fld_names = DynamicVector[String](state.max_total_args)
                    var fld_defaults = DynamicVector[String](state.max_total_args)
                    var fld_units = DynamicVector[String](state.max_total_args)
                    var nwaorn = DynamicVector[Bool](state.max_total_args)
                    var nw_req_fld = DynamicVector[Bool](state.max_total_args)
                    var nw_fld_names = DynamicVector[String](state.max_total_args)
                    var nw_fld_defaults = DynamicVector[String](state.max_total_args)
                    var nw_fld_units = DynamicVector[String](state.max_total_args)
                    var out_args = DynamicVector[String](state.max_total_args)
                    var match_arg = DynamicVector[Bool](state.max_total_args)
                    var delete_this_record = DynamicVector[Bool](state.num_idf_records)
                    
                    var no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case(state.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    # Preprocess Load Range info
                    var lrbo = 0
                    var clrbo = 0
                    var hlrbo = 0
                    var count = lrbo + clrbo + hlrbo
                    var lrbo_scheme = DynamicVector[String](count)
                    var lrbo_type = DynamicVector[Int](count)
                    lrbo = 0
                    
                    # First scan for Load Range Based Operations
                    for num in range(state.num_idf_records):
                        var record_name_upper = make_upper_case(trim_string(state.idf_records[num].name))
                        
                        if record_name_upper == "LOAD RANGE BASED OPERATION":
                            var object_name = state.idf_records[num].name
                            var num_alphas = state.idf_records[num].num_alphas
                            var num_numbers = state.idf_records[num].num_numbers
                            
                            var mx_field = False
                            var minus = False
                            var cur_args = num_alphas + num_numbers
                            
                            for arg in range(1, cur_args, 3):
                                if arg + 1 < len(out_args):
                                    var pos = out_args[arg].find("-")
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                                    
                                    if arg + 1 < len(out_args):
                                        pos = out_args[arg + 1].find("-")
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                            
                            lrbo += 1
                            if num_alphas > 0:
                                lrbo_scheme.push_back(make_upper_case(state.idf_records[num].alphas[0]))
                            
                            if mx_field:
                                lrbo_type.push_back(0)
                            elif not minus:
                                lrbo_type.push_back(2)
                            else:
                                lrbo_type.push_back(1)
                        
                        elif record_name_upper == "HEATING LOAD RANGE BASED OPERATION":
                            lrbo += 1
                            if state.idf_records[num].num_alphas > 0:
                                lrbo_scheme.push_back(make_upper_case(state.idf_records[num].alphas[0]))
                            lrbo_type.push_back(2)
                        
                        elif record_name_upper == "COOLING LOAD RANGE BASED OPERATION":
                            lrbo += 1
                            if state.idf_records[num].num_alphas > 0:
                                lrbo_scheme.push_back(make_upper_case(state.idf_records[num].alphas[0]))
                            lrbo_type.push_back(1)
                    
                    # Scan and replace PLANT/CONDENSER Operation Schemes
                    for num in range(state.num_idf_records):
                        var record_name_upper = make_upper_case(state.idf_records[num].name)
                        if record_name_upper != "PLANT OPERATION SCHEMES" and \
                           record_name_upper != "CONDENSER OPERATION SCHEMES":
                            continue
                        
                        var num_alphas = state.idf_records[num].num_alphas
                        for arg in range(1, num_alphas, 3):
                            if arg + 1 < len(state.idf_records[num].alphas):
                                if make_upper_case(state.idf_records[num].alphas[arg]) != "LOAD RANGE BASED OPERATION":
                                    continue
                                
                                var count_found = find_item_in_list(
                                    make_upper_case(state.idf_records[num].alphas[arg + 1]),
                                    lrbo_scheme, lrbo)
                                
                                if count_found != 0:
                                    if lrbo_type[count_found - 1] == 1:
                                        state.idf_records[num].alphas[arg] = "COOLING LOAD RANGE BASED OPERATION"
                                    elif lrbo_type[count_found - 1] == 2:
                                        state.idf_records[num].alphas[arg] = "HEATING LOAD RANGE BASED OPERATION"
                    
                    # Main processing loop
                    for num in range(state.num_idf_records):
                        var object_name = state.idf_records[num].name
                        var num_alphas = state.idf_records[num].num_alphas
                        var num_numbers = state.idf_records[num].num_numbers
                        var cur_args = num_alphas + num_numbers
                        var no_diff = True
                        var written = False
                        
                        var object_name_upper = make_upper_case(trim_string(state.idf_records[num].name))
                        
                        if object_name_upper == "VERSION":
                            pass
                        elif object_name_upper == "COOLING TOWER:SINGLE SPEED":
                            if cur_args < 10:
                                for arg in range(cur_args, 9):
                                    pass
                                cur_args = 10
                            no_diff = False
                        elif object_name_upper == "COOLING TOWER:TWO SPEED":
                            if cur_args < 13:
                                for arg in range(cur_args, 12):
                                    pass
                                cur_args = 13
                            no_diff = False
                        elif object_name_upper == "RUNPERIOD":
                            if cur_args < 8:
                                for arg in range(cur_args, 7):
                                    pass
                                cur_args = 8
                            no_diff = False
                        elif object_name_upper == "PHOTOVOLTAICS":
                            no_diff = False
                        elif object_name_upper == "DAYLIGHTING":
                            if cur_args > 5:
                                object_name = "Daylighting:Detailed"
                                cur_args = cur_args - 3
                            else:
                                object_name = "Daylighting:Simple"
                                cur_args = 4
                            no_diff = False
                        elif object_name_upper == "LOAD RANGE BASED OPERATION":
                            no_diff = False
                        elif object_name_upper == "WINDOWSHADINGCONTROL":
                            no_diff = False
                        elif object_name_upper in ["REPORT VARIABLE", "REPORT METER", "REPORT METERFILEONLY",
                                                   "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY",
                                                   "REPORT:TABLE:TIMEBINS", "REPORT:TABLE:MONTHLY"]:
                            no_diff = True
                    
                    if check_rvi:
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
