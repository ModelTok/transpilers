from collections import InlineArray
from sys import argv
from math import max as math_max


# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: blank, MaxNameLength, ProgNameConversion, ProgramPath
# - DataVCompareGlobals: IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath,
#                        IDFRecords, NumIDFRecords, Comments, CurComment, Auditf,
#                        ObjectDef, NumObjectDefs, NotInNew,
#                        Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#                        NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs,
#                        MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#                        OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames,
#                        OTMVarCaution, CMtrVarCaution, CMtrDVarCaution,
#                        FullFileName, FileNamePath, FileOK, FatalError, ProcessingIMFFile, MakingPretty,
#                        VerString, VersionNum, sVersionNum, sVersionNumFourChars
# - VCompareGlobalRoutines: ProcessInput, ProcessRviMviFiles, CloseOut, CreateNewName
# - InputProcessor: GetNewUnitNumber, FindItemInList, GetObjectDefInIDD, GetNewObjectDefInIDD
# - General: DisplayString, WriteOutIDFLinesAsComments, ScanOutputVariablesForReplacement,
#            WriteOutIDFLines, CheckSpecialObjects, GetNumSectionsFound, writePreprocessorObject, copyfile
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - Fortran intrinsics: ADJUSTL, TRIM, SCAN, LEN_TRIM, INDEX, MakeUPPERCase, MakeLowerCase, SameString


struct IDFRecord:
    var name: String
    var num_alphas: Int32
    var num_numbers: Int32
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int32
    var commt_e: Int32


struct ObjectDefEntry:
    var name: String


struct VersionState:
    var ver_string: String
    var version_num: Float64
    var s_version_num: String
    var s_version_num_four_chars: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String

    fn __init__(inout self):
        self.ver_string = "Conversion 25.2 => 26.1"
        self.version_num = 26.1
        self.s_version_num = "***"
        self.s_version_num_four_chars = "26.1"
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""


fn set_this_version_variables(inout state: VersionState, program_path: String) -> None:
    state.ver_string = "Conversion 25.2 => 26.1"
    state.version_num = 26.1
    state.s_version_num = "***"
    state.s_version_num_four_chars = "26.1"
    state.idd_file_name_with_path = program_path.rstrip() + "V25-2-0-Energy+.idd"
    state.new_idd_file_name_with_path = program_path.rstrip() + "V26-1-0-Energy+.idd"
    state.rep_var_file_name_with_path = program_path.rstrip() + "Report Variables 25-2-0 to 26-1-0.csv"


@always_inline
fn _trim(s: String) -> String:
    return s.rstrip()


@always_inline
fn _len_trim(s: String) -> Int32:
    return len(s.rstrip())


@always_inline
fn _make_upper_case(s: String) -> String:
    return s.upper()


@always_inline
fn _make_lower_case(s: String) -> String:
    return s.lower()


@always_inline
fn _adjustl(s: String) -> String:
    return s.lstrip()


@always_inline
fn _scan(s: String, pattern: String, backward: Bool = False) -> Int32:
    if backward:
        var pos = s.rfind(pattern)
        if pos >= 0:
            return pos + 1
        return 0
    else:
        var pos = s.find(pattern)
        if pos >= 0:
            return pos + 1
        return 0


@always_inline
fn _index_func(s: String, pattern: String) -> Int32:
    var pos = s.find(pattern)
    if pos >= 0:
        return pos + 1
    return 0


@always_inline
fn _same_string(s1: String, s2: String) -> Bool:
    return _make_upper_case(s1) == _make_upper_case(s2)


fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int32,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout state: VersionState,
    blank: String,
    max_name_length: Int32,
    program_path: String,
    inout idf_records: DynamicVector[IDFRecord],
    num_idf_records: Int32,
    inout comments: DynamicVector[String],
    cur_comment: Int32,
    auditf: Int32,
    inout object_defs: DynamicVector[ObjectDefEntry],
    num_object_defs: Int32,
    inout not_in_new: DynamicVector[String],
    inout alphas: DynamicVector[String],
    inout numbers: DynamicVector[Float64],
    inout in_args: DynamicVector[String],
    inout temp_args: DynamicVector[String],
    inout aor_n: DynamicVector[Bool],
    inout req_fld: DynamicVector[Bool],
    inout fld_names: DynamicVector[String],
    inout fld_defaults: DynamicVector[String],
    inout fld_units: DynamicVector[String],
    inout nw_aor_n: DynamicVector[Bool],
    inout nw_req_fld: DynamicVector[Bool],
    inout nw_fld_names: DynamicVector[String],
    inout nw_fld_defaults: DynamicVector[String],
    inout nw_fld_units: DynamicVector[String],
    inout out_args: DynamicVector[String],
    max_alpha_args_found: Int32,
    max_numeric_args_found: Int32,
    max_total_args: Int32,
    inout old_rep_var_name: DynamicVector[String],
    inout new_rep_var_name: DynamicVector[String],
    inout new_rep_var_caution: DynamicVector[String],
    num_rep_var_names: Int32,
    inout otm_var_caution: DynamicVector[Bool],
    inout cmtr_var_caution: DynamicVector[Bool],
    inout cmtr_d_var_caution: DynamicVector[Bool],
    inout full_file_name: String,
    inout file_name_path: String,
    inout file_ok: Bool,
    inout fatal_error: Bool,
    inout processing_imf_file: Bool,
    making_pretty: Bool,
    prog_name_conversion: String,
    get_new_unit_number,
    process_input,
    find_item_in_list,
    get_object_def_in_idd,
    get_new_object_def_in_idd,
    display_string,
    show_warning_error,
    write_out_idf_lines_as_comments,
    scan_output_variables_for_replacement,
    write_out_idf_lines,
    check_special_objects,
    create_new_name,
    process_rvi_mvi_files,
    close_out,
    get_num_sections_found,
    write_preprocessor_object,
    copyfile_func,
) -> Bool:

    let fmta = "(A)"
    var first_time = True
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    var delete_this_record = InlineArray[Bool, 100000](fill=False)
    
    if first_time:
        first_time = False

    while still_working:
        var exit_because_bad_file = False
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end=" ", flush=True)
                var line = input()
                full_file_name = line
            else:
                if not arg_file:
                    try:
                        var line = input()
                        full_file_name = line
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = blank
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                    
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = blank
                    continue

            var units_arg = blank
            if ios != 0:
                full_file_name = blank
            
            full_file_name = _adjustl(full_file_name)
            
            if full_file_name != blank:
                display_string("Processing IDF -- " + _trim(full_file_name))
                
                var dot_pos = _scan(full_file_name, ".", backward=True)
                if dot_pos != 0:
                    file_name_path = full_file_name[:dot_pos-1]
                    local_file_extension = _make_lower_case(full_file_name[dot_pos:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = _trim(full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                let dif_lfn = get_new_unit_number()
                file_ok = True
                
                if not file_ok:
                    print("File not found=" + _trim(full_file_name))
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var dif_file: String
                    if diff_only:
                        dif_file = _trim(file_name_path) + "." + _trim(local_file_extension) + "dif"
                    else:
                        dif_file = _trim(file_name_path) + "." + _trim(local_file_extension) + "new"
                    
                    if local_file_extension == "imf":
                        show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", auditf)
                        processing_imf_file = True
                    else:
                        processing_imf_file = False
                    
                    process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, _trim(full_file_name))
                    
                    if fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    delete_this_record = InlineArray[Bool, 100000](fill=False)
                    
                    no_version = True
                    for num in range(num_idf_records):
                        if _make_upper_case(idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    display_string("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(idf_records[num].commt_s, idf_records[num].commt_e + 1):
                            pass
                        
                        if no_version and num == 0:
                            get_new_object_def_in_idd("VERSION")
                            out_args[0] = state.s_version_num_four_chars
                            var cur_args = 1
                            show_warning_error("No version found in file, defaulting to " + state.s_version_num_four_chars, auditf)
                            write_out_idf_lines_as_comments(dif_file, "Version", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        var object_name = idf_records[num].name
                        
                        if find_item_in_list(object_name, object_defs, num_object_defs) != 0:
                            get_object_def_in_idd(object_name)
                            var num_alphas = idf_records[num].num_alphas
                            var num_numbers = idf_records[num].num_numbers
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
                            num_alphas = idf_records[num].num_alphas
                            num_numbers = idf_records[num].num_numbers
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if find_item_in_list(_make_upper_case(object_name), not_in_new, len(not_in_new)) == 0:
                            get_new_object_def_in_idd(object_name)
                        
                        if not making_pretty:
                            if _make_upper_case(_trim(idf_records[num].name)) == "VERSION":
                                if in_args[0][0:4] == state.s_version_num_four_chars and arg_file:
                                    show_warning_error("File is already at latest version.  No new diff file made.", auditf)
                                    exit_because_bad_file = True
                                    latest_version = True
                                    break
                                get_new_object_def_in_idd(object_name)
                                out_args[0] = state.s_version_num_four_chars
                                nodiff = False
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT":
                                get_new_object_def_in_idd(object_name)
                                nodiff = False
                                for i in range(9):
                                    out_args[i] = in_args[i]
                                for i in range(cur_args - 10):
                                    out_args[9 + i] = in_args[10 + i]
                                cur_args -= 1
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT":
                                get_new_object_def_in_idd(object_name)
                                nodiff = False
                                for i in range(8):
                                    out_args[i] = in_args[i]
                                for i in range(cur_args - 9):
                                    out_args[8 + i] = in_args[9 + i]
                                cur_args -= 1
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:VARIABLE":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = "*"
                                    nodiff = False
                                scan_output_variables_for_replacement(
                                    2, blank, checkrvi, nodiff, object_name, dif_file,
                                    True, False, False, cur_args, written, False
                                )
                            
                            elif (_make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:METER" or
                                  _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:METER:METERFILEONLY" or
                                  _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:METER:CUMULATIVE" or
                                  _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:METER:CUMULATIVE:METERFILEONLY"):
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                scan_output_variables_for_replacement(
                                    1, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, True, False, cur_args, written, False
                                )
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:TABLE:TIMEBINS":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = "*"
                                    nodiff = False
                                scan_output_variables_for_replacement(
                                    2, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, False, True, cur_args, written, False
                                )
                            
                            elif (_make_upper_case(_trim(idf_records[num].name)) == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE" or
                                  _make_upper_case(_trim(idf_records[num].name)) == "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"):
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == blank:
                                    out_args[0] = "*"
                                    nodiff = False
                                scan_output_variables_for_replacement(
                                    2, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, False, False, cur_args, written, False
                                )
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                scan_output_variables_for_replacement(
                                    3, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, False, False, cur_args, written, True
                                )
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "OUTPUT:TABLE:MONTHLY":
                                get_new_object_def_in_idd(object_name)
                                nodiff = True
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                var cur_var = 3
                                for var in range(3, cur_args, 2):
                                    var uc_rep_var_name = _make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    var pos = _index_func(uc_rep_var_name, "[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos-1]
                                        out_args[cur_var] = in_args[var][:pos-1]
                                        out_args[cur_var+1] = in_args[var+1]
                                    var del_this = False
                                    for arg in range(num_rep_var_names):
                                        var uc_comp_rep_var_name = _make_upper_case(old_rep_var_name[arg])
                                        var wild_match = False
                                        if uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                            pos = _index_func(_trim(uc_rep_var_name), _trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg] != blank and not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    if not otm_var_caution[arg]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Output Table Monthly (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Output Table Monthly (new)=\"" + _trim(new_rep_var_name[arg]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg]) + "\".")
                                                        otm_var_caution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                if not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+1]
                                                    else:
                                                        out_args[cur_var] = _trim(new_rep_var_name[arg+1]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+1] != blank:
                                                        if not otm_var_caution[arg+1]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                "Output Table Monthly (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Output Table Monthly (new)=\"" + _trim(new_rep_var_name[arg+1]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+1]) + "\".")
                                                            otm_var_caution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg+2]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg+2]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg+2] != blank:
                                                    if not otm_var_caution[arg+2]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Output Table Monthly (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Output Table Monthly (new)=\"" + _trim(new_rep_var_name[arg+2]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+2]) + "\".")
                                                        otm_var_caution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "METER:CUSTOM":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                cur_var = 4
                                for var in range(4, cur_args, 2):
                                    var uc_rep_var_name = _make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = _index_func(uc_rep_var_name, "[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos-1]
                                        out_args[cur_var] = in_args[var][:pos-1]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(num_rep_var_names):
                                        uc_comp_rep_var_name = _make_upper_case(old_rep_var_name[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                            pos = _index_func(_trim(uc_rep_var_name), _trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg] != blank and not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    if not cmtr_var_caution[arg]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Custom Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Meter (new)=\"" + _trim(new_rep_var_name[arg]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg]) + "\".")
                                                        cmtr_var_caution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                if not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+1]
                                                    else:
                                                        out_args[cur_var] = _trim(new_rep_var_name[arg+1]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+1] != blank and not _same_string(new_rep_var_caution[arg+1][:6], "Forkeq"):
                                                        if not cmtr_var_caution[arg+1]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                "Custom Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Meter (new)=\"" + _trim(new_rep_var_name[arg+1]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+1]) + "\".")
                                                            cmtr_var_caution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg+2]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg+2]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg+2] != blank:
                                                    if not cmtr_var_caution[arg+2]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Custom Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Meter (new)=\"" + _trim(new_rep_var_name[arg+2]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+2]) + "\".")
                                                        cmtr_var_caution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "METER:CUSTOMDECREMENT":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                cur_var = 4
                                for var in range(4, cur_args, 2):
                                    uc_rep_var_name = _make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var+1] = in_args[var+1]
                                    pos = _index_func(uc_rep_var_name, "[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos-1]
                                        out_args[cur_var] = in_args[var][:pos-1]
                                        out_args[cur_var+1] = in_args[var+1]
                                    del_this = False
                                    for arg in range(num_rep_var_names):
                                        uc_comp_rep_var_name = _make_upper_case(old_rep_var_name[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                            pos = _index_func(_trim(uc_rep_var_name), _trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg] != blank and not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    if not cmtr_d_var_caution[arg]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Custom Decrement Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Meter (new)=\"" + _trim(new_rep_var_name[arg]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg]) + "\".")
                                                        cmtr_d_var_caution[arg] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                if not _same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+1]
                                                    else:
                                                        out_args[cur_var] = _trim(new_rep_var_name[arg+1]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+1] != blank and not _same_string(new_rep_var_caution[arg+1][:6], "Forkeq"):
                                                        if not cmtr_d_var_caution[arg+1]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                "Custom Decrement Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Decrement Meter (new)=\"" + _trim(new_rep_var_name[arg+1]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+1]) + "\".")
                                                            cmtr_d_var_caution[arg+1] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                            if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = new_rep_var_name[arg+2]
                                                else:
                                                    out_args[cur_var] = _trim(new_rep_var_name[arg+2]) + out_args[cur_var][_len_trim(uc_comp_rep_var_name):]
                                                if new_rep_var_caution[arg+2] != blank:
                                                    if not cmtr_d_var_caution[arg+2]:
                                                        write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                            "Custom Decrement Meter (old)=\"" + _trim(old_rep_var_name[arg]) + "\" conversion to Custom Meter (new)=\"" + _trim(new_rep_var_name[arg+2]) + "\" has the following caution \"" + _trim(new_rep_var_caution[arg+2]) + "\".")
                                                        cmtr_d_var_caution[arg+2] = True
                                                out_args[cur_var+1] = in_args[var+1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif (_make_upper_case(_trim(idf_records[num].name)) == "DEMANDMANAGERASSIGNMENTLIST" or
                                  _make_upper_case(_trim(idf_records[num].name)) == "UTILITYCOST:TARIFF"):
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                scan_output_variables_for_replacement(
                                    2, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, True, False, cur_args, written, False
                                )
                            
                            elif _make_upper_case(_trim(idf_records[num].name)) == "ELECTRICLOADCENTER:DISTRIBUTION":
                                get_new_object_def_in_idd(object_name)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                scan_output_variables_for_replacement(
                                    6, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, True, False, cur_args, written, False
                                )
                                scan_output_variables_for_replacement(
                                    12, blank, checkrvi, nodiff, object_name, dif_file,
                                    False, True, False, cur_args, written, False
                                )
                            
                            else:
                                if find_item_in_list(object_name, not_in_new, len(not_in_new)) != 0:
                                    write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    get_new_object_def_in_idd(object_name)
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    nodiff = True
                        else:
                            get_new_object_def_in_idd(idf_records[num].name)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if diff_min_fields and nodiff:
                            get_new_object_def_in_idd(object_name)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                            nodiff = False
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    display_string("Processing IDF -- Processing idf objects complete.")
                    
                    if get_num_sections_found("Report Variable Dictionary") > 0:
                        object_name = "Output:VariableDictionary"
                        get_new_object_def_in_idd(object_name)
                        nodiff = False
                        out_args[0] = "Regular"
                        cur_args = 1
                        write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    close_out()
                else:
                    process_rvi_mvi_files(file_name_path, "rvi")
                    process_rvi_mvi_files(file_name_path, "mvi")
            else:
                end_of_file = True
            
            create_new_name("Reallocate", " ")

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
        var err_flag = False
        copyfile_func(_trim(file_name_path) + "." + _trim(arg_idf_extension), _trim(file_name_path) + "." + _trim(arg_idf_extension) + "old", err_flag)
        copyfile_func(_trim(file_name_path) + "." + _trim(arg_idf_extension) + "new", _trim(file_name_path) + "." + _trim(arg_idf_extension), err_flag)

    return end_of_file
