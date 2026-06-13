"""
EnergyPlus IDF version 9.2 → 9.3 transition rules.
Translated from Fortran CreateNewIDFUsingRulesV9_3_0 module.
"""

from collections import InlineArray
from math import (
    min as math_min,
    max as math_max,
    floor,
    ceil,
    fabs,
)
import os


# ============ EXTERNAL DEPS (to wire in glue) ============
# From DataStringGlobals:
#   ProgNameConversion, ProgramPath, Blank
# From DataVCompareGlobals:
#   IDFRecords, NumIDFRecords, Comments, CurComment, Alphas, Numbers, InArgs, TempArgs,
#   AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames,
#   NwFldDefaults, NwFldUnits, OutArgs, MatchArg, ObjectDef, NumObjectDefs,
#   MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, MaxNameLength,
#   NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames,
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, IDDFileNameWithPath,
#   NewIDDFileNameWithPath, RepVarFileNameWithPath, VerString, VersionNum, sVersionNum,
#   FullFileName, FileNamePath, FileOK, Auditf, ProcessingIMFFile, FatalError
# From InputProcessor:
#   GetNewUnitNumber, SameString, GetObjectItem, GetNumObjectsFound, GetObjectItemNum,
#   GetNewObjectDefInIDD, GetObjectDefInIDD, FindItemInList
# From General:
#   MakeUPPERCase, MakeLowerCase, DisplayString, ProcessInput
# From DataGlobals:
#   ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError,
#   GetNumSectionsFound
# From output routines:
#   WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects,
#   ScanOutputVariablesForReplacement, writePreprocessorObject, CreateNewName,
#   ProcessRviMviFiles, CloseOut, copyfile
# ============================================================


struct IDFRecord:
    var name: StringRef
    var cmmt_s: Int
    var cmmt_e: Int
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]


struct EnergyPlusState:
    """State container for EnergyPlus transition processing."""
    var ver_string: String
    var version_num: Float64
    var s_version_num: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var prog_name_conversion: String
    var full_file_name: String
    var file_name_path: String
    var file_ok: Bool
    var auditf: Int
    var processing_imf_file: Bool
    var fatal_error: Bool
    var num_idf_records: Int
    var idf_records: DynamicVector[IDFRecord]
    var cur_comment: Int
    var comments: DynamicVector[String]
    var delete_this_record: DynamicVector[Bool]
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var in_args: DynamicVector[String]
    var temp_args: DynamicVector[String]
    var aor_n: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var nw_aor_n: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var out_args: DynamicVector[String]
    var p_aor_n: DynamicVector[Bool]
    var p_req_fld: DynamicVector[Bool]
    var p_fld_names: DynamicVector[String]
    var p_fld_defaults: DynamicVector[String]
    var p_fld_units: DynamicVector[String]
    var p_out_args: DynamicVector[String]
    var match_arg: DynamicVector[String]
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var not_in_new: DynamicVector[String]
    var atsdu_node_names: DynamicVector[String]
    var matching_atsdu_air_flow_node_names: DynamicVector[String]
    
    fn __init__(inout self):
        self.ver_string = ""
        self.version_num = 0.0
        self.s_version_num = ""
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""
        self.program_path = ""
        self.prog_name_conversion = ""
        self.full_file_name = ""
        self.file_name_path = ""
        self.file_ok = False
        self.auditf = 0
        self.processing_imf_file = False
        self.fatal_error = False
        self.num_idf_records = 0
        self.cur_comment = 0
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0


fn set_this_version_variables(inout state: EnergyPlusState) -> None:
    """Module SetVersion::SetThisVersionVariables translated from Fortran."""
    state.ver_string = "Conversion 9.2 => 9.3"
    state.version_num = 9.3
    state.s_version_num = "9.3"
    state.idd_file_name_with_path = state.program_path + "V9-2-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V9-3-0-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 9-2-0 to 9-3-0.csv"


fn create_new_idf_using_rules(
    inout state: EnergyPlusState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: StringRef,
    arg_file: Bool,
    arg_idf_extension: StringRef,
) -> None:
    """Subroutine CreateNewIDFUsingRules translated from Fortran."""
    
    var first_time: Bool = True
    var fmta: String = "(A)"
    var blank: String = ""
    
    if first_time:
        first_time = False
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = String(arg_idf_extension)
    end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # Would read from input
                state.full_file_name = ""
            else:
                if not arg_file:
                    # Read from input file
                    ios = 0
                elif not arg_file_being_done:
                    state.full_file_name = String(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = blank
                    ios = 1
                
                if state.full_file_name and state.full_file_name[0] == "!":
                    state.full_file_name = blank
                    continue
            
            var units_arg: String = blank
            if ios != 0:
                state.full_file_name = blank
            
            state.full_file_name = _lstrip(state.full_file_name)
            
            if state.full_file_name != blank:
                _display_string("Processing IDF -- " + state.full_file_name)
                _write_audit(state.auditf, " Processing IDF -- " + state.full_file_name)
                
                var dot_pos: Int = _rfind(state.full_file_name, ".")
                if dot_pos >= 0:
                    state.file_name_path = state.full_file_name[0:dot_pos]
                    local_file_extension = _to_lower(state.full_file_name[dot_pos + 1:])
                else:
                    state.file_name_path = state.full_file_name
                    print(" assuming file extension of .idf")
                    _write_audit(state.auditf, " ..assuming file extension of .idf")
                    state.full_file_name = state.full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = _get_new_unit_number()
                state.file_ok = _file_exists(state.full_file_name)
                
                if not state.file_ok:
                    print("File not found=" + state.full_file_name)
                    _write_audit(state.auditf, "File not found=" + state.full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var output_file: String
                    if diff_only:
                        output_file = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        output_file = state.file_name_path + "." + local_file_extension + "new"
                    
                    _open_output_file(dif_lfn, output_file)
                    
                    if local_file_extension == "imf":
                        _show_warning_error(
                            "Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.",
                            state.auditf
                        )
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    _process_input(
                        state.idd_file_name_with_path,
                        state.new_idd_file_name_with_path,
                        state.full_file_name
                    )
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    # Clean up and reallocate arrays
                    _deallocate_arrays(inout state)
                    _allocate_arrays(inout state)
                    
                    # Check for VERSION object
                    no_version = True
                    for num in range(state.num_idf_records):
                        if state.idf_records[num].name.upper() == "VERSION":
                            no_version = False
                            break
                    
                    # Write delete markers
                    for num in range(state.num_idf_records):
                        if state.delete_this_record[num]:
                            var record: IDFRecord = state.idf_records[num]
                            var alpha_name: String = ""
                            if record.num_alphas > 0:
                                alpha_name = record.alphas[0]
                            _write_output(dif_lfn, "! Deleting: " + record.name + "=\"" + alpha_name + "\".")
                    
                    # PREPROCESSING
                    _preprocess_atsdu(inout state)
                    
                    # PROCESSING
                    _display_string("Processing IDF -- Processing idf objects . . .")
                    _process_idf_records(inout state, dif_lfn, diff_only, no_version, check_rvi)
                    
                    _display_string("Processing IDF -- Processing idf objects complete.")
                    
                    _close_output_file(dif_lfn)
                    _process_rvi_mvi_files(state.file_name_path, "rvi")
                    _process_rvi_mvi_files(state.file_name_path, "mvi")
                    _close_out()
                else:
                    _process_rvi_mvi_files(state.file_name_path, "rvi")
                    _process_rvi_mvi_files(state.file_name_path, "mvi")
            else:
                end_of_file = True
            
            _create_new_name("Reallocate", "", " ")
        
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
        _copy_file(
            state.file_name_path + "." + String(arg_idf_extension),
            state.file_name_path + "." + String(arg_idf_extension) + "old",
            err_flag
        )
        _copy_file(
            state.file_name_path + "." + String(arg_idf_extension) + "new",
            state.file_name_path + "." + String(arg_idf_extension),
            err_flag
        )


fn _preprocess_atsdu(inout state: EnergyPlusState) -> None:
    """Preprocess AirTerminal:SingleDuct:Uncontrolled objects."""
    var tot_atsdu_objs: Int = _get_num_objects_found("AIRTERMINAL:SINGLEDUCT:UNCONTROLLED")
    if tot_atsdu_objs > 0:
        state.atsdu_node_names = DynamicVector[String](capacity=tot_atsdu_objs)
    
    var tot_afn_dist_node_objs: Int = _get_num_objects_found("AIRFLOWNETWORK:DISTRIBUTION:NODE")
    if tot_afn_dist_node_objs > 0 and tot_atsdu_objs > 0:
        state.matching_atsdu_air_flow_node_names = DynamicVector[String](capacity=tot_atsdu_objs)


fn _process_idf_records(
    inout state: EnergyPlusState,
    dif_lfn: Int,
    diff_only: Bool,
    no_version: Bool,
    check_rvi: Bool
) -> None:
    """Process all IDF records with transition rules."""
    
    for num in range(state.num_idf_records):
        if state.delete_this_record[num]:
            continue
        
        var record: IDFRecord = state.idf_records[num]
        var object_name: String = record.name
        
        # Skip deleted objects
        var obj_upper: String = _to_upper(object_name)
        if obj_upper in ("PROGRAMCONTROL", "SKY RADIANCE DISTRIBUTION", "AIRFLOW MODEL",
                         "GENERATOR:FC:BATTERY DATA", "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS"):
            continue
        
        if obj_upper == "WATER HEATER:SIMPLE":
            _write_output(dif_lfn, "! ** The WATER HEATER:SIMPLE object has been deleted")
            _write_preprocessor_object(dif_lfn, state.prog_name_conversion, "Warning",
                                      "The WATER HEATER:SIMPLE object has been deleted")
            continue


fn fix_fuel_types(inout out_args: DynamicVector[String], index: Int, inout no_diff: Bool) -> None:
    """Convert old fuel type names to new standardized names."""
    var val: String = _to_lower(out_args[index])
    
    if val == "electric" or val == "elec":
        out_args[index] = "Electricity"
        no_diff = False
    elif val == "gas" or val == "natural gas":
        out_args[index] = "NaturalGas"
        no_diff = False
    elif val == "propanegas" or val == "lpg" or val == "propane gas":
        out_args[index] = "Propane"
        no_diff = False
    elif val == "fueloil#1" or val == "fuel oil #1" or val == "fuel oil" or val == "distillate oil" or val == "distillateoil":
        out_args[index] = "FuelOilNo1"
        no_diff = False
    elif val == "fueloil#2" or val == "fuel oil #2" or val == "residual oil" or val == "residualoil":
        out_args[index] = "FuelOilNo2"
        no_diff = False


fn sort_unique(str_array: DynamicVector[String]) -> Tuple[DynamicVector[String], DynamicVector[Int]]:
    """Sort unique numeric strings and return sorted array and original indices."""
    var size: Int = len(str_array)
    var in_numbers: DynamicVector[Float64] = DynamicVector[Float64](capacity=size)
    
    for i in range(size):
        in_numbers.push_back(_string_to_float(str_array[i]))
    
    # Note: Simplified; a full sort would be needed for production
    var out_strings: DynamicVector[String] = DynamicVector[String](capacity=size)
    var order: DynamicVector[Int] = DynamicVector[Int](capacity=size)
    
    return out_strings, order


fn update_ems_function_name(
    inout in_out_arg: String,
    old_name: StringRef,
    new_name: StringRef,
    inout no_diff: Bool
) -> None:
    """Update EMS function names in expressions."""
    if _find_substring(in_out_arg, String(old_name)) >= 0:
        in_out_arg = _replace_string(in_out_arg, String(old_name), String(new_name))
        no_diff = False


fn delim(line: StringRef, dlim: StringRef = " ") -> DynamicVector[String]:
    """Parse a delimited string into tokens."""
    var tokens: DynamicVector[String] = DynamicVector[String]()
    var current_token: String = ""
    var delim_str: String = String(dlim)
    var line_str: String = String(line)
    
    for char in line_str:
        if _is_delimiter(char, delim_str):
            if len(current_token) > 0:
                tokens.push_back(current_token)
                current_token = ""
        else:
            current_token += String(char)
    
    if len(current_token) > 0:
        tokens.push_back(current_token)
    
    return tokens


fn _deallocate_arrays(inout state: EnergyPlusState) -> None:
    """Deallocate work arrays."""
    state.delete_this_record = DynamicVector[Bool]()
    state.alphas = DynamicVector[String]()
    state.numbers = DynamicVector[Float64]()
    state.in_args = DynamicVector[String]()
    state.temp_args = DynamicVector[String]()
    state.aor_n = DynamicVector[Bool]()
    state.req_fld = DynamicVector[Bool]()
    state.fld_names = DynamicVector[String]()
    state.fld_defaults = DynamicVector[String]()
    state.fld_units = DynamicVector[String]()
    state.nw_aor_n = DynamicVector[Bool]()
    state.nw_req_fld = DynamicVector[Bool]()
    state.nw_fld_names = DynamicVector[String]()
    state.nw_fld_defaults = DynamicVector[String]()
    state.nw_fld_units = DynamicVector[String]()
    state.out_args = DynamicVector[String]()
    state.p_aor_n = DynamicVector[Bool]()
    state.p_req_fld = DynamicVector[Bool]()
    state.p_fld_names = DynamicVector[String]()
    state.p_fld_defaults = DynamicVector[String]()
    state.p_fld_units = DynamicVector[String]()
    state.p_out_args = DynamicVector[String]()
    state.match_arg = DynamicVector[String]()


fn _allocate_arrays(inout state: EnergyPlusState) -> None:
    """Allocate work arrays."""
    var max_args: Int = state.max_total_args
    state.delete_this_record = DynamicVector[Bool](capacity=state.num_idf_records)
    state.alphas = DynamicVector[String](capacity=state.max_alpha_args_found)
    state.numbers = DynamicVector[Float64](capacity=state.max_numeric_args_found)
    state.in_args = DynamicVector[String](capacity=max_args)
    state.temp_args = DynamicVector[String](capacity=max_args)
    state.aor_n = DynamicVector[Bool](capacity=max_args)
    state.req_fld = DynamicVector[Bool](capacity=max_args)
    state.fld_names = DynamicVector[String](capacity=max_args)
    state.fld_defaults = DynamicVector[String](capacity=max_args)
    state.fld_units = DynamicVector[String](capacity=max_args)
    state.nw_aor_n = DynamicVector[Bool](capacity=max_args)
    state.nw_req_fld = DynamicVector[Bool](capacity=max_args)
    state.nw_fld_names = DynamicVector[String](capacity=max_args)
    state.nw_fld_defaults = DynamicVector[String](capacity=max_args)
    state.nw_fld_units = DynamicVector[String](capacity=max_args)
    state.out_args = DynamicVector[String](capacity=max_args)
    state.p_aor_n = DynamicVector[Bool](capacity=max_args)
    state.p_req_fld = DynamicVector[Bool](capacity=max_args)
    state.p_fld_names = DynamicVector[String](capacity=max_args)
    state.p_fld_defaults = DynamicVector[String](capacity=max_args)
    state.p_fld_units = DynamicVector[String](capacity=max_args)
    state.p_out_args = DynamicVector[String](capacity=max_args)
    state.match_arg = DynamicVector[String](capacity=max_args)


# ========== Helper functions (stub implementations) ==========

@always_inline
fn _file_exists(path: StringRef) -> Bool:
    return os.path.exists(String(path))


@always_inline
fn _lstrip(s: StringRef) -> String:
    var s_str: String = String(s)
    var i: Int = 0
    while i < len(s_str) and s_str[i] == " ":
        i += 1
    return s_str[i:]


@always_inline
fn _rfind(s: StringRef, ch: StringRef) -> Int:
    var s_str: String = String(s)
    var ch_str: String = String(ch)
    var pos: Int = -1
    for i in range(len(s_str) - 1, -1, -1):
        if String(s_str[i]) == ch_str:
            return i
    return pos


@always_inline
fn _to_lower(s: StringRef) -> String:
    return String(s).lower()


@always_inline
fn _to_upper(s: StringRef) -> String:
    return String(s).upper()


@always_inline
fn _display_string(msg: StringRef) -> None:
    print(String(msg))


@always_inline
fn _write_audit(unit: Int, msg: StringRef) -> None:
    # Stub: would write to audit file
    pass


@always_inline
fn _show_warning_error(msg: StringRef, audit: Int) -> None:
    print("WARNING: " + String(msg))


@always_inline
fn _write_output(unit: Int, msg: StringRef) -> None:
    # Stub: would write to output file
    pass


@always_inline
fn _get_new_unit_number() -> Int:
    return 10


@always_inline
fn _open_output_file(unit: Int, path: StringRef) -> None:
    # Stub
    pass


@always_inline
fn _process_input(idd_old: StringRef, idd_new: StringRef, idf: StringRef) -> None:
    # Stub
    pass


@always_inline
fn _get_num_objects_found(obj_type: StringRef) -> Int:
    return 0


@always_inline
fn _close_output_file(unit: Int) -> None:
    pass


@always_inline
fn _process_rvi_mvi_files(file_path: StringRef, ext: StringRef) -> None:
    pass


@always_inline
fn _close_out() -> None:
    pass


@always_inline
fn _create_new_name(op: StringRef, out_name: StringRef, extra: StringRef) -> None:
    pass


@always_inline
fn _copy_file(src: StringRef, dst: StringRef, inout err_flag: Bool) -> None:
    pass


@always_inline
fn _write_preprocessor_object(unit: Int, prog_name: StringRef, msg_type: StringRef, msg: StringRef) -> None:
    pass


@always_inline
fn _find_substring(s: StringRef, sub: StringRef) -> Int:
    return String(s).find(String(sub))


@always_inline
fn _replace_string(s: StringRef, old: StringRef, new: StringRef) -> String:
    return String(s).replace(String(old), String(new))


@always_inline
fn _is_delimiter(ch: StringRef, delim: StringRef) -> Bool:
    return String(delim).find(String(ch)) >= 0


@always_inline
fn _string_to_float(s: StringRef) -> Float64:
    return Float64(String(s))
