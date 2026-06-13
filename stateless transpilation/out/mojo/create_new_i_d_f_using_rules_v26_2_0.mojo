from collections import InlineArray
from memory import UnsafePointer
from memory.unsafe_pointer import bitcast
import math

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList, GetNumSectionsFound
# - DataVCompareGlobals: IDFRecords, Comments, NumIDFRecords, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs,
#   ObjectDef, NumObjectDefs, NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution,
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, NumRepVarNames, FatalError
# - VCompareGlobalRoutines: DisplayString, ScanOutputVariablesForReplacement, WriteOutIDFLines,
#   WriteOutIDFLinesAsComments, CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName,
#   GetNewUnitNumber, WritePreprocessorObject, CopyFile
# - DataStringGlobals: MaxNameLength, Blank, ProgNameConversion
# - General: MakeUPPERCase, MakeLowerCase, TrimTrailZeros, SameString
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

struct StringArray:
    data: DynamicVector[String]
    
    fn __init__(inout self, size: Int):
        self.data = DynamicVector[String](capacity=size)
        for _ in range(size):
            self.data.push_back("")
    
    fn __getitem__(self, index: Int) -> String:
        return self.data[index]
    
    fn __setitem__(inout self, index: Int, value: String):
        if index < len(self.data):
            self.data[index] = value
    
    fn __len__(self) -> Int:
        return len(self.data)

struct FloatArray:
    data: DynamicVector[Float64]
    
    fn __init__(inout self, size: Int):
        self.data = DynamicVector[Float64](capacity=size)
        for _ in range(size):
            self.data.push_back(0.0)
    
    fn __getitem__(self, index: Int) -> Float64:
        return self.data[index]
    
    fn __setitem__(inout self, index: Int, value: Float64):
        if index < len(self.data):
            self.data[index] = value
    
    fn __len__(self) -> Int:
        return len(self.data)

struct BoolArray:
    data: DynamicVector[Bool]
    
    fn __init__(inout self, size: Int):
        self.data = DynamicVector[Bool](capacity=size)
        for _ in range(size):
            self.data.push_back(False)
    
    fn __getitem__(self, index: Int) -> Bool:
        return self.data[index]
    
    fn __setitem__(inout self, index: Int, value: Bool):
        if index < len(self.data):
            self.data[index] = value
    
    fn __len__(self) -> Int:
        return len(self.data)

struct IDFRecord:
    name: String
    num_alphas: Int
    num_numbers: Int
    alphas: StringArray
    numbers: FloatArray
    commt_s: Int
    commt_e: Int
    
    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.alphas = StringArray(1000)
        self.numbers = FloatArray(1000)
        self.commt_s = 0
        self.commt_e = 0

struct GlobalState:
    full_file_name: String
    file_name_path: String
    program_path: String
    auditf: Int
    file_ok: Bool
    processing_imf_file: Bool
    idd_file_name_with_path: String
    new_idd_file_name_with_path: String
    rep_var_file_name_with_path: String
    ver_string: String
    version_num: Float64
    s_version_num: String
    s_version_num_four_chars: String
    idf_records: DynamicVector[IDFRecord]
    comments: StringArray
    num_idf_records: Int
    alphas: StringArray
    numbers: FloatArray
    in_args: StringArray
    temp_args: StringArray
    aor_n: BoolArray
    req_fld: BoolArray
    fld_names: StringArray
    fld_defaults: StringArray
    fld_units: StringArray
    nw_aor_n: BoolArray
    nw_req_fld: BoolArray
    nw_fld_names: StringArray
    nw_fld_defaults: StringArray
    nw_fld_units: StringArray
    out_args: StringArray
    object_def: DynamicVector[String]
    num_object_defs: Int
    not_in_new: DynamicVector[String]
    max_alpha_args_found: Int
    max_numeric_args_found: Int
    max_total_args: Int
    old_rep_var_name: StringArray
    new_rep_var_name: StringArray
    new_rep_var_caution: StringArray
    otm_var_caution: BoolArray
    cmtr_var_caution: BoolArray
    cmtr_dvar_caution: BoolArray
    num_rep_var_names: Int
    fatal_error: Bool
    
    fn __init__(inout self):
        self.full_file_name = ""
        self.file_name_path = ""
        self.program_path = ""
        self.auditf = 0
        self.file_ok = False
        self.processing_imf_file = False
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""
        self.ver_string = ""
        self.version_num = 0.0
        self.s_version_num = ""
        self.s_version_num_four_chars = ""
        self.idf_records = DynamicVector[IDFRecord]()
        self.comments = StringArray(10000)
        self.num_idf_records = 0
        self.alphas = StringArray(1000)
        self.numbers = FloatArray(1000)
        self.in_args = StringArray(10000)
        self.temp_args = StringArray(10000)
        self.aor_n = BoolArray(10000)
        self.req_fld = BoolArray(10000)
        self.fld_names = StringArray(10000)
        self.fld_defaults = StringArray(10000)
        self.fld_units = StringArray(10000)
        self.nw_aor_n = BoolArray(10000)
        self.nw_req_fld = BoolArray(10000)
        self.nw_fld_names = StringArray(10000)
        self.nw_fld_defaults = StringArray(10000)
        self.nw_fld_units = StringArray(10000)
        self.out_args = StringArray(10000)
        self.object_def = DynamicVector[String]()
        self.num_object_defs = 0
        self.not_in_new = DynamicVector[String]()
        self.max_alpha_args_found = 1000
        self.max_numeric_args_found = 1000
        self.max_total_args = 10000
        self.old_rep_var_name = StringArray(1000)
        self.new_rep_var_name = StringArray(1000)
        self.new_rep_var_caution = StringArray(1000)
        self.otm_var_caution = BoolArray(1000)
        self.cmtr_var_caution = BoolArray(1000)
        self.cmtr_dvar_caution = BoolArray(1000)
        self.num_rep_var_names = 0
        self.fatal_error = False

var first_time_global = True

fn set_this_version_variables(inout state: GlobalState) -> None:
    state.ver_string = "Conversion 26.1 => 26.2"
    state.version_num = 26.2
    state.s_version_num = "***"
    state.s_version_num_four_chars = "26.2"
    state.idd_file_name_with_path = state.program_path + "V26-1-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V26-2-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 26-1-0 to 26-2-0.csv"

@export
fn create_new_idf_using_rules(
    inout state: GlobalState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    let blank = ""
    let fmta = "(A)"
    
    if first_time_global:
        first_time_global = False
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    
    var tot_run_periods: Int = 0
    var run_period_num: Int = 0
    var iterate_run_period: Int = 0
    var current_run_period_names = StringArray(100)
    var potential_run_period_name = ""
    
    while still_working:
        var exit_because_bad_file = False
        while not end_of_file:
            var full_file_name = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
            else:
                if not arg_file:
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == "!":
                    full_file_name = blank
                    continue
            
            var units_arg = blank
            if ios != 0:
                full_file_name = blank
            
            if len(full_file_name) > 0:
                var dot_pos = full_file_name.rfind(".")
                if dot_pos != -1:
                    state.file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    state.file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                state.full_file_name = full_file_name
                var dif_lfn = 0  # get_new_unit_number()
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var output_filename = ""
                    if diff_only:
                        output_filename = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        output_filename = state.file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var delete_this_record = BoolArray(state.num_idf_records)
                    
                    var no_version_found = True
                    for num in range(state.num_idf_records):
                        if state.idf_records[num].name.upper() != "VERSION":
                            continue
                        no_version_found = False
                        break
                    
                    var cur_args = 0
                    var num_alphas = 0
                    var num_numbers = 0
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name = state.idf_records[num].name
                        num_alphas = state.idf_records[num].num_alphas
                        num_numbers = state.idf_records[num].num_numbers
                        cur_args = num_alphas + num_numbers
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        
                        var object_upper = object_name.upper()
                        
                        if object_upper == "VERSION":
                            if state.in_args[0][:4] == state.s_version_num_four_chars and arg_file:
                                latest_version = True
                                break
                            state.out_args[0] = state.s_version_num_four_chars
                            nodiff = False
                        
                        elif object_upper == "COIL:COOLING:DX:CURVEFIT:OPERATINGMODE":
                            nodiff = False
                            for i in range(8):
                                state.out_args[i] = state.in_args[i]
                            state.out_args[8] = ""
                            for i in range(8, cur_args):
                                state.out_args[i + 1] = state.in_args[i]
                            cur_args = cur_args + 1
                        
                        elif object_upper == "OUTPUT:VARIABLE":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == blank:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_upper in ["OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_upper == "OUTPUT:TABLE:TIMEBINS":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == blank:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_upper in ["EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            if state.out_args[0] == blank:
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif object_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_upper == "OUTPUT:TABLE:MONTHLY":
                            nodiff = True
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            
                            var cur_var = 3
                            var var_idx = 3
                            while var_idx < cur_args:
                                var uc_rep_var_name = state.in_args[var_idx].upper()
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                var pos = uc_rep_var_name.find("[")
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                var del_this = False
                                for arg in range(state.num_rep_var_names):
                                    var uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                    if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                        var wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                    else:
                                        wild_match = False
                                        pos = 0
                                        if uc_rep_var_name == uc_comp_rep_var_name:
                                            pos = 1
                                    
                                    if pos > 0 and pos != 1:
                                        continue
                                    if pos > 0:
                                        if state.new_rep_var_name[arg] != "<DELETE>":
                                            if not wild_match:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg]
                                            else:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var - 1
                        
                        elif object_upper == "METER:CUSTOM":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                var uc_rep_var_name = state.in_args[var_idx].upper()
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                pos = uc_rep_var_name.find("[")
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                del_this = False
                                for arg in range(state.num_rep_var_names):
                                    var uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                    if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                    else:
                                        wild_match = False
                                        pos = 0
                                        if uc_rep_var_name == uc_comp_rep_var_name:
                                            pos = 1
                                    
                                    if pos > 0 and pos != 1:
                                        continue
                                    if pos > 0:
                                        if state.new_rep_var_name[arg] != "<DELETE>":
                                            if not wild_match:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg]
                                            else:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.out_args[arg] == blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_upper == "METER:CUSTOMDECREMENT":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                            
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                var uc_rep_var_name = state.in_args[var_idx].upper()
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                pos = uc_rep_var_name.find("[")
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                del_this = False
                                for arg in range(state.num_rep_var_names):
                                    var uc_comp_rep_var_name = state.old_rep_var_name[arg].upper()
                                    if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                    else:
                                        wild_match = False
                                        pos = 0
                                        if uc_rep_var_name == uc_comp_rep_var_name:
                                            pos = 1
                                    
                                    if pos > 0 and pos != 1:
                                        continue
                                    if pos > 0:
                                        if state.new_rep_var_name[arg] != "<DELETE>":
                                            if not wild_match:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg]
                                            else:
                                                state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var_idx += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.out_args[arg] == blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_upper in ["DEMANDMANAGERASSIGNMENTLIST", "UTILITYCOST:TARIFF"]:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        elif object_upper == "ELECTRICLOADCENTER:DISTRIBUTION":
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                        
                        else:
                            for i in range(cur_args):
                                state.out_args[i] = state.in_args[i]
                            nodiff = True
                    
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
