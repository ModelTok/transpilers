from memory import InlineArray
from math import min as math_min

# EXTERNAL DEPS (to wire in glue):
# - FullFileName, FileNamePath, Blank, ProgramPath, Auditf: from DataStringGlobals
# - IDFRecords, Comments, NumIDFRecords, CurComment: from DataVCompareGlobals
# - MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs: constants
# - ObjectDef, NotInNew, FatalError: from InputProcessor
# - OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames: from DataVCompareGlobals
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution: from DataVCompareGlobals
# - ProcessingIMFFile: from DataVCompareGlobals
# - ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList: from InputProcessor
# - DisplayString, ProcessRviMviFiles, CloseOut, CreateNewName, CheckSpecialObjects: from VCompareGlobalRoutines
# - WriteOutIDFLinesAsComments, WriteOutIDFLines: from VCompareGlobalRoutines
# - GetNewUnitNumber: from General
# - ShowWarningError, ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError: from DataGlobals
# - ProgNameConversion: from DataStringGlobals
# - SameString: utility function


@value
struct IDFRecord:
    Name: String
    NumAlphas: Int
    NumNumbers: Int
    Alphas: InlineArray[String, 100]
    Numbers: InlineArray[String, 100]
    CommtS: Int
    CommtE: Int


@value
struct ObjectDefRecord:
    Name: String


struct GlobalState:
    var FullFileName: String
    var FileNamePath: String
    var Blank: String
    var ProgramPath: String
    var Auditf: String
    var IDFRecords: InlineArray[IDFRecord, 1000]
    var Comments: InlineArray[String, 10000]
    var NumIDFRecords: Int
    var CurComment: Int
    var ObjectDef: InlineArray[ObjectDefRecord, 500]
    var NotInNew: InlineArray[String, 100]
    var FatalError: Bool
    var OldRepVarName: InlineArray[String, 500]
    var NewRepVarName: InlineArray[String, 500]
    var NewRepVarCaution: InlineArray[String, 500]
    var NumRepVarNames: Int
    var OTMVarCaution: InlineArray[Bool, 500]
    var CMtrVarCaution: InlineArray[Bool, 500]
    var CMtrDVarCaution: InlineArray[Bool, 500]
    var ProcessingIMFFile: Bool
    var ProgNameConversion: String
    
    fn __init__(inout self):
        self.FullFileName = ""
        self.FileNamePath = ""
        self.Blank = ""
        self.ProgramPath = ""
        self.Auditf = ""
        self.IDFRecords = InlineArray[IDFRecord, 1000](fill=IDFRecord(
            Name="", NumAlphas=0, NumNumbers=0,
            Alphas=InlineArray[String, 100](fill=""),
            Numbers=InlineArray[String, 100](fill=""),
            CommtS=0, CommtE=0
        ))
        self.Comments = InlineArray[String, 10000](fill="")
        self.NumIDFRecords = 0
        self.CurComment = 0
        self.ObjectDef = InlineArray[ObjectDefRecord, 500](fill=ObjectDefRecord(Name=""))
        self.NotInNew = InlineArray[String, 100](fill="")
        self.FatalError = False
        self.OldRepVarName = InlineArray[String, 500](fill="")
        self.NewRepVarName = InlineArray[String, 500](fill="")
        self.NewRepVarCaution = InlineArray[String, 500](fill="")
        self.NumRepVarNames = 0
        self.OTMVarCaution = InlineArray[Bool, 500](fill=False)
        self.CMtrVarCaution = InlineArray[Bool, 500](fill=False)
        self.CMtrDVarCaution = InlineArray[Bool, 500](fill=False)
        self.ProcessingIMFFile = False
        self.ProgNameConversion = ""


trait ExternalServices:
    fn ProcessInput(self, old_idd: String, new_idd: String, filename: String):
        pass
    fn DisplayString(self, msg: String):
        pass
    fn ProcessRviMviFiles(self, path: String, ext: String):
        pass
    fn CloseOut(self):
        pass
    fn CreateNewName(self, action: String, name: String, suffix: String):
        pass
    fn CheckSpecialObjects(self, lun: Int, obj_name: String, cur_args: Int,
                          out_args: InlineArray[String, 500],
                          fld_names: InlineArray[String, 500],
                          fld_units: InlineArray[String, 500]) -> Bool:
        return False
    fn WriteOutIDFLinesAsComments(self, lun: Int, obj_name: String, cur_args: Int,
                                 out_args: InlineArray[String, 500],
                                 fld_names: InlineArray[String, 500],
                                 fld_units: InlineArray[String, 500]):
        pass
    fn WriteOutIDFLines(self, lun: Int, obj_name: String, cur_args: Int,
                       out_args: InlineArray[String, 500],
                       fld_names: InlineArray[String, 500],
                       fld_units: InlineArray[String, 500]):
        pass
    fn GetNewUnitNumber(self) -> Int:
        return 0
    fn FindItemInList(self, item: String, list_: InlineArray[String, 100], size: Int) -> Int:
        return 0
    fn GetObjectDefInIDD(self, obj_name: String) -> (Int, InlineArray[Bool, 500], InlineArray[Bool, 500], Int, InlineArray[String, 500], InlineArray[String, 500], InlineArray[String, 500]):
        return (0, InlineArray[Bool, 500](fill=False), InlineArray[Bool, 500](fill=False), 0, InlineArray[String, 500](fill=""), InlineArray[String, 500](fill=""), InlineArray[String, 500](fill=""))
    fn GetNewObjectDefInIDD(self, obj_name: String) -> (Int, InlineArray[Bool, 500], InlineArray[Bool, 500], Int, InlineArray[String, 500], InlineArray[String, 500], InlineArray[String, 500]):
        return (0, InlineArray[Bool, 500](fill=False), InlineArray[Bool, 500](fill=False), 0, InlineArray[String, 500](fill=""), InlineArray[String, 500](fill=""), InlineArray[String, 500](fill=""))
    fn ScanOutputVariablesForReplacement(self, field_idx: Int, del_this: Bool, check_rvi: Bool,
                                        no_diff: Bool, obj_name: String, lun: Int, out_var: Bool,
                                        mtr_var: Bool, time_bin: Bool, cur_args: Int,
                                        written: Bool, is_ems: Bool) -> (Bool, Bool):
        return (False, check_rvi)
    fn ShowWarningError(self, msg: String, auditf: String):
        pass
    fn GetNumSectionsFound(self, section: String) -> Int:
        return 0
    fn copyfile(self, src: String, dst: String) -> Bool:
        return False
    fn writePreprocessorObject(self, lun: Int, prog_name: String, level: String, msg: String):
        pass


@always_inline
fn make_upper_case(s: String) -> String:
    return s.upper()


@always_inline
fn make_lower_case(s: String) -> String:
    return s.lower()


@always_inline
fn same_string(a: String, b: String) -> Bool:
    return a.upper() == b.upper()


fn set_this_version_variables(inout state: GlobalState) -> (String, Float64, String, String, String, String, String):
    let ver_string = "Conversion 22.2 => 23.1"
    let version_num = 23.1
    let s_version_num = "***"
    let s_version_num_four_chars = "23.1"
    let idd_file_name_with_path = state.ProgramPath + "V22-2-0-Energy+.idd"
    let new_idd_file_name_with_path = state.ProgramPath + "V23-1-0-Energy+.idd"
    let rep_var_file_name_with_path = state.ProgramPath + "Report Variables 22-2-0 to 23-1-0.csv"
    
    return (ver_string, version_num, s_version_num, s_version_num_four_chars,
            idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path)


fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_filename: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: GlobalState,
    services: ExternalServices,
) -> Bool:
    let fmta = "(A)"
    var first_time = True
    
    let ver_string: String
    let version_num: Float64
    let s_version_num: String
    let s_version_num_four_chars: String
    let idd_file_name_with_path: String
    let new_idd_file_name_with_path: String
    let rep_var_file_name_with_path: String
    
    (ver_string, version_num, s_version_num, s_version_num_four_chars,
     idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path) = \
        set_this_version_variables(state)
    
    if first_time:
        first_time = False
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    
    let max_name_length = 100
    let max_total_args = 500
    
    var alphas = InlineArray[String, 100](fill="")
    var numbers = InlineArray[String, 100](fill="")
    var in_args = InlineArray[String, 500](fill="")
    var temp_args = InlineArray[String, 500](fill="")
    var aorn = InlineArray[Bool, 500](fill=False)
    var req_fld = InlineArray[Bool, 500](fill=False)
    var fld_names = InlineArray[String, 500](fill="")
    var fld_defaults = InlineArray[String, 500](fill="")
    var fld_units = InlineArray[String, 500](fill="")
    var nw_aorn = InlineArray[Bool, 500](fill=False)
    var nw_req_fld = InlineArray[Bool, 500](fill=False)
    var nw_fld_names = InlineArray[String, 500](fill="")
    var nw_fld_defaults = InlineArray[String, 500](fill="")
    var nw_fld_units = InlineArray[String, 500](fill="")
    var out_args = InlineArray[String, 500](fill="")
    var p_out_args = InlineArray[String, 500](fill="")
    var delete_this_record = InlineArray[Bool, 1000](fill=False)
    
    var tot_run_periods: Int = 0
    var run_period_num: Int = 0
    var iterate_run_period: Int = 0
    var wwhp_eq_ft_cool_index: Int = 0
    var wwhp_eq_ft_heat_index: Int = 0
    var wahp_eq_ft_cool_index: Int = 0
    var wahp_eq_ft_heat_index: Int = 0
    var current_run_period_names = InlineArray[String, 100](fill="")
    var num1: Int = 0
    var surrounding_field1 = ""
    var surrounding_field2 = ""
    var matched_surrounding_name = ""
    var potential_run_period_name = ""
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file:
            var full_filename = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                # Simulated input
                full_filename = ""
            else:
                if not arg_file:
                    full_filename = ""
                    ios = 1
                elif not arg_file_being_done:
                    full_filename = input_filename
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_filename = ""
                    ios = 1
            
            if full_filename.startswith("!"):
                full_filename = ""
                continue
            
            var units_arg = ""
            if ios != 0:
                full_filename = ""
            
            full_filename = full_filename.lstrip()
            
            if full_filename != "":
                services.DisplayString("Processing IDF -- " + full_filename)
                
                let dot_pos = full_filename.rfind(".")
                var file_name_path = ""
                
                if dot_pos != -1:
                    file_name_path = full_filename[:dot_pos]
                    local_file_extension = make_lower_case(full_filename[dot_pos+1:])
                else:
                    file_name_path = full_filename
                    print(" assuming file extension of .idf")
                    full_filename = full_filename + ".idf"
                    local_file_extension = "idf"
                
                state.FullFileName = full_filename
                state.FileNamePath = file_name_path
                
                let dif_lfn = services.GetNewUnitNumber()
                
                var file_ok = False
                try:
                    # Check if file exists
                    file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_filename)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    let output_file = if diff_only {
                        file_name_path + "." + local_file_extension + "dif"
                    } else {
                        file_name_path + "." + local_file_extension + "new"
                    }
                    
                    if local_file_extension == "imf":
                        services.ShowWarningError(
                            "Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.",
                            state.Auditf
                        )
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    services.ProcessInput(idd_file_name_with_path, new_idd_file_name_with_path, full_filename)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    delete_this_record = InlineArray[Bool, 1000](fill=False)
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    services.DisplayString("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        if no_version and num == 0:
                            let nw_num_args: Int
                            let nw_aorn_ret: InlineArray[Bool, 500]
                            let nw_req_fld_ret: InlineArray[Bool, 500]
                            let nw_obj_min_flds: Int
                            let nw_fld_names_ret: InlineArray[String, 500]
                            let nw_fld_defaults_ret: InlineArray[String, 500]
                            let nw_fld_units_ret: InlineArray[String, 500]
                            
                            (nw_num_args, nw_aorn_ret, nw_req_fld_ret, nw_obj_min_flds,
                             nw_fld_names_ret, nw_fld_defaults_ret, nw_fld_units_ret) = \
                                services.GetNewObjectDefInIDD("VERSION")
                            
                            out_args[0] = s_version_num_four_chars
                            let cur_args = 1
                            services.ShowWarningError("No version found in file, defaulting to " + s_version_num_four_chars, state.Auditf)
                            services.WriteOutIDFLinesAsComments(dif_lfn, "Version", cur_args, out_args, nw_fld_names_ret, nw_fld_units_ret)
                        
                        let object_name = state.IDFRecords[num].Name
                        
                        let found_idx = services.FindItemInList(object_name, state.NotInNew, state.NumIDFRecords)
                        
                        var num_args: Int = 0
                        var aorn_ret: InlineArray[Bool, 500] = InlineArray[Bool, 500](fill=False)
                        var req_fld_ret: InlineArray[Bool, 500] = InlineArray[Bool, 500](fill=False)
                        var obj_min_flds: Int = 0
                        var fld_names_ret: InlineArray[String, 500] = InlineArray[String, 500](fill="")
                        var fld_defaults_ret: InlineArray[String, 500] = InlineArray[String, 500](fill="")
                        var fld_units_ret: InlineArray[String, 500] = InlineArray[String, 500](fill="")
                        
                        if found_idx != 0:
                            (num_args, aorn_ret, req_fld_ret, obj_min_flds,
                             fld_names_ret, fld_defaults_ret, fld_units_ret) = \
                                services.GetObjectDefInIDD(object_name)
                            
                            let num_alphas = state.IDFRecords[num].NumAlphas
                            let num_numbers = state.IDFRecords[num].NumNumbers
                            
                            var cur_args = num_alphas + num_numbers
                            in_args = InlineArray[String, 500](fill="")
                            out_args = InlineArray[String, 500](fill="")
                            temp_args = InlineArray[String, 500](fill="")
                            
                            var na = 0
                            var nn = 0
                            for arg in range(cur_args):
                                if aorn_ret[arg]:
                                    in_args[arg] = state.IDFRecords[num].Alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = state.IDFRecords[num].Numbers[nn]
                                    nn += 1
                        else:
                            let num_alphas = state.IDFRecords[num].NumAlphas
                            let num_numbers = state.IDFRecords[num].NumNumbers
                            
                            var cur_args = num_alphas + num_numbers
                            out_args = InlineArray[String, 500](fill="")
                            
                            for i in range(num_alphas):
                                out_args[i] = state.IDFRecords[num].Alphas[i]
                            
                            var nn = num_alphas + 1
                            for i in range(num_numbers):
                                out_args[nn] = state.IDFRecords[num].Numbers[i]
                                nn += 1
                            
                            nw_fld_names = InlineArray[String, 500](fill="")
                            nw_fld_units = InlineArray[String, 500](fill="")
                            
                            services.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        
                        let obj_upper = make_upper_case(state.IDFRecords[num].Name)
                        
                        if obj_upper == "VERSION":
                            if in_args[0].startswith(s_version_num_four_chars) and arg_file:
                                services.ShowWarningError("File is already at latest version.  No new diff file made.", state.Auditf)
                                latest_version = True
                                break
                            
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            out_args[0] = s_version_num_four_chars
                            no_diff = False
                        
                        elif obj_upper == "OUTPUT:VARIABLE":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = "*"
                                no_diff = False
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                True, False, False, 100, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == "OUTPUT:METER" or obj_upper == "OUTPUT:METER:METERFILEONLY" or 
                             obj_upper == "OUTPUT:METER:CUMULATIVE" or obj_upper == "OUTPUT:METER:CUMULATIVE:METERFILEONLY":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                0, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, 100, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == "OUTPUT:TABLE:TIMEBINS":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = "*"
                                no_diff = False
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, True, 100, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE" or
                             obj_upper == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = "*"
                                no_diff = False
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, False, 100, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                2, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, False, 100, written, True
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == "OUTPUT:TABLE:MONTHLY":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            no_diff = True
                            for i in range(100):
                                out_args[i] = in_args[i]
                            
                            var cur_var = 3
                            var var_idx = 3
                            while var_idx < 100:
                                let uc_rep_var_name = make_upper_case(in_args[var_idx])
                                out_args[cur_var] = in_args[var_idx]
                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                
                                let pos = uc_rep_var_name.find("[")
                                var del_this = False
                                
                                for arg in range(state.NumRepVarNames):
                                    var wild_match = False
                                    var match_pos = 0
                                    
                                    if state.OldRepVarName[arg].endswith("*"):
                                        wild_match = True
                                    
                                    if wild_match or uc_rep_var_name == make_upper_case(state.OldRepVarName[arg]):
                                        if state.NewRepVarName[arg] != "<DELETE>":
                                            out_args[cur_var] = state.NewRepVarName[arg]
                                            out_args[cur_var + 1] = in_args[var_idx + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                
                                var_idx += 2
                        
                        elif obj_upper == "DEMANDMANAGERASSIGNMENTLIST" or obj_upper == "UTILITYCOST:TARIFF":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            let (del_this, check_rvi_ret) = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, 100, written, False
                            )
                        
                        elif obj_upper == "ELECTRICLOADCENTER:DISTRIBUTION":
                            let nw_result = services.GetNewObjectDefInIDD(object_name)
                            for i in range(100):
                                out_args[i] = in_args[i]
                            no_diff = True
                            
                            let (del_this1, check_rvi_ret1) = services.ScanOutputVariablesForReplacement(
                                5, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, 100, written, False
                            )
                            
                            let (del_this2, check_rvi_ret2) = services.ScanOutputVariablesForReplacement(
                                11, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, 100, written, False
                            )
                        
                        else:
                            let not_in_new_idx = services.FindItemInList(object_name, state.NotInNew, state.NumIDFRecords)
                            if not_in_new_idx != 0:
                                services.WriteOutIDFLinesAsComments(dif_lfn, object_name, 100, in_args, fld_names_ret, fld_units_ret)
                                written = True
                            else:
                                let nw_result = services.GetNewObjectDefInIDD(object_name)
                                for i in range(100):
                                    out_args[i] = in_args[i]
                                no_diff = True
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            written = services.CheckSpecialObjects(dif_lfn, object_name, 100, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            services.WriteOutIDFLines(dif_lfn, object_name, 100, out_args, nw_fld_names, nw_fld_units)
                    
                    services.DisplayString("Processing IDF -- Processing idf objects complete.")
                    
                    if services.GetNumSectionsFound("Report Variable Dictionary") > 0:
                        let object_name = "Output:VariableDictionary"
                        let nw_result = services.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        out_args[0] = "Regular"
                        let cur_args = 1
                        services.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    services.ProcessRviMviFiles(file_name_path, "rvi")
                    services.ProcessRviMviFiles(file_name_path, "mvi")
                    services.CloseOut()
                else:
                    services.ProcessRviMviFiles(file_name_path, "rvi")
                    services.ProcessRviMviFiles(file_name_path, "mvi")
            else:
                end_of_file = True
            
            services.CreateNewName("Reallocate", "", " ")
        
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
        services.copyfile(state.FileNamePath + "." + arg_idf_extension,
                         state.FileNamePath + "." + arg_idf_extension + "old")
        services.copyfile(state.FileNamePath + "." + arg_idf_extension + "new",
                         state.FileNamePath + "." + arg_idf_extension)
        
        services.copyfile(state.FileNamePath + ".rvi", state.FileNamePath + ".rviold")
        services.copyfile(state.FileNamePath + ".rvinew", state.FileNamePath + ".rvi")
        services.copyfile(state.FileNamePath + ".mvi", state.FileNamePath + ".mviold")
        services.copyfile(state.FileNamePath + ".mvinew", state.FileNamePath + ".mvi")
    
    return end_of_file
