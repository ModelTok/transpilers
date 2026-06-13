# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals (source: EnergyPlus): ProgramPath
# - DataVCompareGlobals (source: EnergyPlus): VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf, Comments, IDFRecords, NumIDFRecords, CurComment, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NotInNew, MakingPretty, FatalError, ProcessingIMFFile, ObjectDef, NumObjectDefs, OldRepVarName, NewRepVarName, NumRepVarNames, MaxNameLength, blank
# - InputProcessor (source: EnergyPlus): ProcessInput
# - VCompareGlobalRoutines (source: EnergyPlus): GetNewObjectDefInIDD, GetObjectDefInIDD, FindItemInList, WriteOutIDFLinesAsComments, WriteOutIDFLines, ScanOutputVariablesForReplacement, CheckSpecialObjects, CreateNewName, ProcessRviMviFiles, CloseOut
# - General (source: EnergyPlus): MakeLowerCase, MakeUPPERCase, SameString, TrimTrailZeros
# - DataGlobals (source: EnergyPlus): ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - System (source: EnergyPlus): GetNewUnitNumber, copyfile, DisplayString

from memory import Span, memcpy
from memory.unsafe import Pointer

struct CoilData:
    var name: String
    var c_type: String
    
    fn __init__(inout self):
        self.name = ""
        self.c_type = ""

fn set_this_version_variables(inout state: State):
    state.ver_string = "Conversion 1.1.1 => 1.2"
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path.strip() + "V1-1-1-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path.strip() + "V1-2-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path.strip() + "Report Variables 1-1-1-012 to 1-2-0.csv"

@always_inline
fn trim_trailing_zeros(s: String) -> String:
    var result = s
    while len(result) > 0 and result[-1] == "0":
        result = result[:len(result)-1]
    return result

@always_inline
fn make_uppercase_case(s: String) -> String:
    var result = String()
    for i in range(len(s)):
        var c = s[i]
        if c >= "a" and c <= "z":
            result += chr(ord(c) - 32)
        else:
            result += c
    return result

@always_inline
fn make_lower_case(s: String) -> String:
    var result = String()
    for i in range(len(s)):
        var c = s[i]
        if c >= "A" and c <= "Z":
            result += chr(ord(c) + 32)
        else:
            result += c
    return result

@always_inline
fn same_string(s1: String, s2: String) -> Bool:
    return make_uppercase_case(s1.strip()) == make_uppercase_case(s2.strip())

@always_inline
fn find_item_in_list(item: String, list_items: List[String], size: Int) -> Int:
    var item_upper = make_uppercase_case(item)
    for i in range(size):
        if make_uppercase_case(list_items[i]) == item_upper:
            return i
    return -1

fn create_new_idf_using_rules(
    inout state: State,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
):
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    
    var alphas = List[String]()
    var numbers = List[Float64]()
    var in_args = List[String]()
    var a_or_n = List[Bool]()
    var req_fld = List[Bool]()
    var fld_names = List[String]()
    var fld_defaults = List[String]()
    var fld_units = List[String]()
    var nw_a_or_n = List[Bool]()
    var nw_req_fld = List[Bool]()
    var nw_fld_names = List[String]()
    var nw_fld_defaults = List[String]()
    var nw_fld_units = List[String]()
    var out_args = List[String]()
    var match_arg = List[Bool]()
    var delete_this_record = List[Bool]()
    var coils = List[CoilData]()
    var num_coils = 0
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file:
            var full_file_name = String()
            
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
                    full_file_name = ""
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == "!":
                    full_file_name = ""
                    continue
            
            if ios != 0:
                full_file_name = ""
            full_file_name = full_file_name.strip()
            
            if len(full_file_name) > 0:
                print("Processing IDF -- " + full_file_name)
                
                var dot_pos = full_file_name.rfind(".")
                var file_name_path = String()
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.strip() + ".idf"
                    local_file_extension = "idf"
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    
                    if local_file_extension == "imf":
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    ProcessInput(state, state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    alphas = List[String]()
                    for _ in range(state.max_alpha_args_found):
                        alphas.append("")
                    
                    numbers = List[Float64]()
                    for _ in range(state.max_numeric_args_found):
                        numbers.append(0.0)
                    
                    in_args = List[String]()
                    for _ in range(state.max_total_args):
                        in_args.append("")
                    
                    a_or_n = List[Bool]()
                    for _ in range(state.max_total_args):
                        a_or_n.append(False)
                    
                    req_fld = List[Bool]()
                    for _ in range(state.max_total_args):
                        req_fld.append(False)
                    
                    fld_names = List[String]()
                    for _ in range(state.max_total_args):
                        fld_names.append("")
                    
                    fld_defaults = List[String]()
                    for _ in range(state.max_total_args):
                        fld_defaults.append("")
                    
                    fld_units = List[String]()
                    for _ in range(state.max_total_args):
                        fld_units.append("")
                    
                    nw_a_or_n = List[Bool]()
                    for _ in range(state.max_total_args):
                        nw_a_or_n.append(False)
                    
                    nw_req_fld = List[Bool]()
                    for _ in range(state.max_total_args):
                        nw_req_fld.append(False)
                    
                    nw_fld_names = List[String]()
                    for _ in range(state.max_total_args):
                        nw_fld_names.append("")
                    
                    nw_fld_defaults = List[String]()
                    for _ in range(state.max_total_args):
                        nw_fld_defaults.append("")
                    
                    nw_fld_units = List[String]()
                    for _ in range(state.max_total_args):
                        nw_fld_units.append("")
                    
                    out_args = List[String]()
                    for _ in range(state.max_total_args):
                        out_args.append("")
                    
                    match_arg = List[Bool]()
                    for _ in range(state.max_total_args):
                        match_arg.append(False)
                    
                    delete_this_record = List[Bool]()
                    for _ in range(state.num_idf_records):
                        delete_this_record.append(False)
                    
                    num_coils = 0
                    for num in range(state.num_idf_records):
                        if make_uppercase_case(state.idf_records[num].name[:5]) != "COIL:":
                            continue
                        num_coils += 1
                    
                    coils = List[CoilData]()
                    for _ in range(num_coils):
                        coils.append(CoilData())
                    
                    num_coils = 0
                    for num in range(state.num_idf_records):
                        if make_uppercase_case(state.idf_records[num].name[:5]) != "COIL:":
                            continue
                        coils[num_coils].c_type = state.idf_records[num].name
                        if len(state.idf_records[num].alphas) > 0:
                            coils[num_coils].name = state.idf_records[num].alphas[0]
                        num_coils += 1
                    
                    var no_version = True
                    for num in range(state.num_idf_records):
                        if make_uppercase_case(state.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        var obj_upper = make_uppercase_case(state.idf_records[num].name.strip())
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        var object_name = state.idf_records[num].name
                        var cur_args = 0
                        var num_alphas = 0
                        var num_numbers = 0
                        
                        if obj_upper == "VERSION":
                            if len(in_args) > 0 and len(in_args[0]) >= 3 and in_args[0][:3] == "1.2" and arg_file:
                                latest_version = True
                                break
                        elif obj_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
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
