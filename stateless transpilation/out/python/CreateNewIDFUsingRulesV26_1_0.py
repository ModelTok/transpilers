from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Protocol
from enum import Enum
import os


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

@dataclass
class IDFRecord:
    Name: str
    NumAlphas: int
    NumNumbers: int
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[float] = field(default_factory=list)
    CommtS: int = 0
    CommtE: int = 0

@dataclass
class ObjectDefEntry:
    Name: str

@dataclass
class VersionState:
    ver_string: str = "Conversion 25.2 => 26.1"
    version_num: float = 26.1
    s_version_num: str = "***"
    s_version_num_four_chars: str = "26.1"
    idd_file_name_with_path: str = ""
    new_idd_file_name_with_path: str = ""
    rep_var_file_name_with_path: str = ""


class ExternalDepsProtocol(Protocol):
    def get_blank(self) -> str: ...
    def get_max_name_length(self) -> int: ...
    def get_program_path(self) -> str: ...
    def get_idf_records(self) -> List[IDFRecord]: ...
    def get_num_idf_records(self) -> int: ...
    def get_comments(self) -> List[str]: ...
    def get_cur_comment(self) -> int: ...
    def get_auditf(self) -> int: ...
    def get_object_defs(self) -> List[ObjectDefEntry]: ...
    def get_num_object_defs(self) -> int: ...
    def get_not_in_new(self) -> List[str]: ...
    def get_alphas(self) -> List[str]: ...
    def get_numbers(self) -> List[float]: ...


def set_this_version_variables(state: VersionState, program_path: str) -> None:
    state.ver_string = "Conversion 25.2 => 26.1"
    state.version_num = 26.1
    state.s_version_num = "***"
    state.s_version_num_four_chars = "26.1"
    state.idd_file_name_with_path = program_path.rstrip() + "V25-2-0-Energy+.idd"
    state.new_idd_file_name_with_path = program_path.rstrip() + "V26-1-0-Energy+.idd"
    state.rep_var_file_name_with_path = program_path.rstrip() + "Report Variables 25-2-0 to 26-1-0.csv"


def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: VersionState,
    blank: str,
    max_name_length: int,
    program_path: str,
    idf_records: List[IDFRecord],
    num_idf_records: int,
    comments: List[str],
    cur_comment: int,
    auditf: int,
    object_defs: List[ObjectDefEntry],
    num_object_defs: int,
    not_in_new: List[str],
    alphas: List[str],
    numbers: List[float],
    in_args: List[str],
    temp_args: List[str],
    aor_n: List[bool],
    req_fld: List[bool],
    fld_names: List[str],
    fld_defaults: List[str],
    fld_units: List[str],
    nw_aor_n: List[bool],
    nw_req_fld: List[bool],
    nw_fld_names: List[str],
    nw_fld_defaults: List[str],
    nw_fld_units: List[str],
    out_args: List[str],
    max_alpha_args_found: int,
    max_numeric_args_found: int,
    max_total_args: int,
    old_rep_var_name: List[str],
    new_rep_var_name: List[str],
    new_rep_var_caution: List[str],
    num_rep_var_names: int,
    otm_var_caution: List[bool],
    cmtr_var_caution: List[bool],
    cmtr_d_var_caution: List[bool],
    full_file_name: str,
    file_name_path: str,
    file_ok: bool,
    fatal_error: bool,
    processing_imf_file: bool,
    making_pretty: bool,
    prog_name_conversion: str,
    get_new_unit_number,
    process_input,
    find_item_in_list,
    get_object_def_in_idd,
    get_new_object_def_in_idd,
    display_string,
    show_warning_error,
    make_upper_case,
    make_lower_case,
    write_out_idf_lines_as_comments,
    scan_output_variables_for_replacement,
    write_out_idf_lines,
    check_special_objects,
    create_new_name,
    process_rvi_mvi_files,
    close_out,
    get_num_sections_found,
    write_preprocessor_object,
    adjustl,
    trim,
    scan,
    len_trim,
    index_func,
    same_string,
    copyfile_func,
) -> bool:

    fmta = "(A)"
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    delete_this_record = [False] * num_idf_records
    
    if first_time:
        first_time = False

    while still_working:
        exit_because_bad_file = False
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end=" ", flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        with open(in_lfn, 'r') as f:
                            full_file_name = f.readline().strip()
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

            units_arg = blank
            if ios != 0:
                full_file_name = blank
            
            full_file_name = adjustl(full_file_name)
            
            if full_file_name != blank:
                display_string(f"Processing IDF -- {trim(full_file_name)}")
                with open(auditf, 'a') as af:
                    af.write(f" Processing IDF -- {trim(full_file_name)}\n")
                
                dot_pos = scan(full_file_name, '.', backward=True)
                if dot_pos != 0:
                    file_name_path = full_file_name[:dot_pos-1]
                    local_file_extension = make_lower_case(full_file_name[dot_pos:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    with open(auditf, 'a') as af:
                        af.write(" ..assuming file extension of .idf\n")
                    full_file_name = trim(full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                dif_lfn = get_new_unit_number()
                file_ok = os.path.exists(trim(full_file_name))
                
                if not file_ok:
                    print(f"File not found={trim(full_file_name)}")
                    with open(auditf, 'a') as af:
                        af.write(f"File not found={trim(full_file_name)}\n")
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file = trim(file_name_path) + "." + trim(local_file_extension) + "dif"
                    else:
                        dif_file = trim(file_name_path) + "." + trim(local_file_extension) + "new"
                    
                    if local_file_extension == "imf":
                        show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", auditf)
                        processing_imf_file = True
                    else:
                        processing_imf_file = False
                    
                    process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, trim(full_file_name))
                    
                    if fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    delete_this_record = [False] * num_idf_records
                    
                    no_version = True
                    for num in range(num_idf_records):
                        if make_upper_case(idf_records[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    with open(dif_file, 'w') as dfn:
                        for num in range(num_idf_records):
                            if delete_this_record[num]:
                                dfn.write(f"! Deleting: {trim(idf_records[num].Name)}=\"{trim(idf_records[num].Alphas[0])}\".\n")
                    
                    display_string("Processing IDF -- Processing idf objects . . .")
                    
                    with open(dif_file, 'a') as dfn:
                        for num in range(num_idf_records):
                            if delete_this_record[num]:
                                continue
                            
                            for xcount in range(idf_records[num].CommtS, idf_records[num].CommtE + 1):
                                dfn.write(trim(comments[xcount]) + "\n")
                                if xcount == idf_records[num].CommtE:
                                    dfn.write("\n")
                            
                            if no_version and num == 0:
                                get_new_object_def_in_idd("VERSION")
                                out_args[0] = state.s_version_num_four_chars
                                cur_args = 1
                                show_warning_error(f"No version found in file, defaulting to {state.s_version_num_four_chars}", auditf)
                                write_out_idf_lines_as_comments(dif_file, "Version", cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = idf_records[num].Name
                            
                            if find_item_in_list(object_name, [od.Name for od in object_defs], num_object_defs) != 0:
                                get_object_def_in_idd(object_name)
                                num_alphas = idf_records[num].NumAlphas
                                num_numbers = idf_records[num].NumNumbers
                                alphas[0:num_alphas] = idf_records[num].Alphas[0:num_alphas]
                                numbers[0:num_numbers] = idf_records[num].Numbers[0:num_numbers]
                                cur_args = num_alphas + num_numbers
                                in_args = [blank] * max_total_args
                                out_args = [blank] * max_total_args
                                temp_args = [blank] * max_total_args
                                na = 0
                                nn = 0
                                for arg in range(cur_args):
                                    if aor_n[arg]:
                                        in_args[arg] = alphas[na]
                                        na += 1
                                    else:
                                        in_args[arg] = str(numbers[nn])
                                        nn += 1
                            else:
                                with open(auditf, 'a') as af:
                                    af.write(f"Object=\"{trim(object_name)}\" does not seem to be on the \"old\" IDD.\n")
                                    af.write("... will be listed as comments (no field names) on the new output file.\n")
                                    af.write("... Alpha fields will be listed first, then numerics.\n")
                                
                                num_alphas = idf_records[num].NumAlphas
                                num_numbers = idf_records[num].NumNumbers
                                alphas[0:num_alphas] = idf_records[num].Alphas[0:num_alphas]
                                numbers[0:num_numbers] = idf_records[num].Numbers[0:num_numbers]
                                for arg in range(num_alphas):
                                    out_args[arg] = alphas[arg]
                                nn = num_alphas + 1
                                for arg in range(num_numbers):
                                    out_args[nn] = str(numbers[arg])
                                    nn += 1
                                cur_args = num_alphas + num_numbers
                                nw_fld_names = [blank] * max_total_args
                                nw_fld_units = [blank] * max_total_args
                                write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue
                            
                            nodiff = True
                            diff_min_fields = False
                            written = False
                            
                            if find_item_in_list(make_upper_case(object_name), not_in_new, len(not_in_new)) == 0:
                                get_new_object_def_in_idd(object_name)
                            
                            if not making_pretty:
                                if make_upper_case(trim(idf_records[num].Name)) == "VERSION":
                                    if in_args[0][0:4] == state.s_version_num_four_chars and arg_file:
                                        show_warning_error("File is already at latest version.  No new diff file made.", auditf)
                                        exit_because_bad_file = True
                                        latest_version = True
                                        break
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0] = state.s_version_num_four_chars
                                    nodiff = False
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT":
                                    get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:9] = in_args[0:9]
                                    out_args[9:cur_args-1] = in_args[10:cur_args]
                                    cur_args -= 1
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT":
                                    get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:8] = in_args[0:8]
                                    out_args[8:cur_args-1] = in_args[9:cur_args]
                                    cur_args -= 1
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "OUTPUT:VARIABLE":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == blank:
                                        out_args[0] = "*"
                                        nodiff = False
                                    scan_output_variables_for_replacement(
                                        2, blank, checkrvi, nodiff, object_name, dif_file,
                                        True, False, False, cur_args, written, False
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) in ["OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"]:
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    scan_output_variables_for_replacement(
                                        1, blank, checkrvi, nodiff, object_name, dif_file,
                                        False, True, False, cur_args, written, False
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "OUTPUT:TABLE:TIMEBINS":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == blank:
                                        out_args[0] = "*"
                                        nodiff = False
                                    scan_output_variables_for_replacement(
                                        2, blank, checkrvi, nodiff, object_name, dif_file,
                                        False, False, True, cur_args, written, False
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) in ["EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"]:
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == blank:
                                        out_args[0] = "*"
                                        nodiff = False
                                    scan_output_variables_for_replacement(
                                        2, blank, checkrvi, nodiff, object_name, dif_file,
                                        False, False, False, cur_args, written, False
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    scan_output_variables_for_replacement(
                                        3, blank, checkrvi, nodiff, object_name, dif_file,
                                        False, False, False, cur_args, written, True
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "OUTPUT:TABLE:MONTHLY":
                                    get_new_object_def_in_idd(object_name)
                                    nodiff = True
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    cur_var = 3
                                    for var in range(3, cur_args, 2):
                                        uc_rep_var_name = make_upper_case(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var+1] = in_args[var+1]
                                        pos = index_func(uc_rep_var_name, "[")
                                        if pos > 0:
                                            uc_rep_var_name = uc_rep_var_name[:pos-1]
                                            out_args[cur_var] = in_args[var][:pos-1]
                                            out_args[cur_var+1] = in_args[var+1]
                                        del_this = False
                                        for arg in range(num_rep_var_names):
                                            uc_comp_rep_var_name = make_upper_case(old_rep_var_name[arg])
                                            if uc_comp_rep_var_name[-1] == "*":
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                                pos = index_func(trim(uc_rep_var_name), trim(uc_comp_rep_var_name))
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
                                                        out_args[cur_var] = trim(new_rep_var_name[arg]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg] != blank and not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        if not otm_var_caution[arg]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Output Table Monthly (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Output Table Monthly (new)=\"{trim(new_rep_var_name[arg])}\" has the following caution \"{trim(new_rep_var_caution[arg])}\".")
                                                            otm_var_caution[arg] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                                else:
                                                    del_this = True
                                                if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                    if not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        cur_var += 2
                                                        if not wild_match:
                                                            out_args[cur_var] = new_rep_var_name[arg+1]
                                                        else:
                                                            out_args[cur_var] = trim(new_rep_var_name[arg+1]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                        if new_rep_var_caution[arg+1] != blank:
                                                            if not otm_var_caution[arg+1]:
                                                                write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                    f"Output Table Monthly (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Output Table Monthly (new)=\"{trim(new_rep_var_name[arg+1])}\" has the following caution \"{trim(new_rep_var_caution[arg+1])}\".")
                                                                otm_var_caution[arg+1] = True
                                                        out_args[cur_var+1] = in_args[var+1]
                                                        nodiff = False
                                                if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+2]
                                                    else:
                                                        out_args[cur_var] = trim(new_rep_var_name[arg+2]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+2] != blank:
                                                        if not otm_var_caution[arg+2]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Output Table Monthly (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Output Table Monthly (new)=\"{trim(new_rep_var_name[arg+2])}\" has the following caution \"{trim(new_rep_var_caution[arg+2])}\".")
                                                            otm_var_caution[arg+2] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                                break
                                        if not del_this:
                                            cur_var += 2
                                    cur_args = cur_var - 1
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "METER:CUSTOM":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    cur_var = 4
                                    for var in range(4, cur_args, 2):
                                        uc_rep_var_name = make_upper_case(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var+1] = in_args[var+1]
                                        pos = index_func(uc_rep_var_name, "[")
                                        if pos > 0:
                                            uc_rep_var_name = uc_rep_var_name[:pos-1]
                                            out_args[cur_var] = in_args[var][:pos-1]
                                            out_args[cur_var+1] = in_args[var+1]
                                        del_this = False
                                        for arg in range(num_rep_var_names):
                                            uc_comp_rep_var_name = make_upper_case(old_rep_var_name[arg])
                                            if uc_comp_rep_var_name[-1] == "*":
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                                pos = index_func(trim(uc_rep_var_name), trim(uc_comp_rep_var_name))
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
                                                        out_args[cur_var] = trim(new_rep_var_name[arg]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg] != blank and not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        if not cmtr_var_caution[arg]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Custom Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Meter (new)=\"{trim(new_rep_var_name[arg])}\" has the following caution \"{trim(new_rep_var_caution[arg])}\".")
                                                            cmtr_var_caution[arg] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                                else:
                                                    del_this = True
                                                if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                    if not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        cur_var += 2
                                                        if not wild_match:
                                                            out_args[cur_var] = new_rep_var_name[arg+1]
                                                        else:
                                                            out_args[cur_var] = trim(new_rep_var_name[arg+1]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                        if new_rep_var_caution[arg+1] != blank and not same_string(new_rep_var_caution[arg+1][:6], "Forkeq"):
                                                            if not cmtr_var_caution[arg+1]:
                                                                write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                    f"Custom Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Meter (new)=\"{trim(new_rep_var_name[arg+1])}\" has the following caution \"{trim(new_rep_var_caution[arg+1])}\".")
                                                                cmtr_var_caution[arg+1] = True
                                                        out_args[cur_var+1] = in_args[var+1]
                                                        nodiff = False
                                                if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+2]
                                                    else:
                                                        out_args[cur_var] = trim(new_rep_var_name[arg+2]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+2] != blank:
                                                        if not cmtr_var_caution[arg+2]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Custom Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Meter (new)=\"{trim(new_rep_var_name[arg+2])}\" has the following caution \"{trim(new_rep_var_caution[arg+2])}\".")
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
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "METER:CUSTOMDECREMENT":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    cur_var = 4
                                    for var in range(4, cur_args, 2):
                                        uc_rep_var_name = make_upper_case(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var+1] = in_args[var+1]
                                        pos = index_func(uc_rep_var_name, "[")
                                        if pos > 0:
                                            uc_rep_var_name = uc_rep_var_name[:pos-1]
                                            out_args[cur_var] = in_args[var][:pos-1]
                                            out_args[cur_var+1] = in_args[var+1]
                                        del_this = False
                                        for arg in range(num_rep_var_names):
                                            uc_comp_rep_var_name = make_upper_case(old_rep_var_name[arg])
                                            if uc_comp_rep_var_name[-1] == "*":
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                                pos = index_func(trim(uc_rep_var_name), trim(uc_comp_rep_var_name))
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
                                                        out_args[cur_var] = trim(new_rep_var_name[arg]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg] != blank and not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        if not cmtr_d_var_caution[arg]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Custom Decrement Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Meter (new)=\"{trim(new_rep_var_name[arg])}\" has the following caution \"{trim(new_rep_var_caution[arg])}\".")
                                                            cmtr_d_var_caution[arg] = True
                                                    out_args[cur_var+1] = in_args[var+1]
                                                    nodiff = False
                                                else:
                                                    del_this = True
                                                if arg < len(old_rep_var_name) - 1 and old_rep_var_name[arg] == old_rep_var_name[arg+1]:
                                                    if not same_string(new_rep_var_caution[arg][:6], "Forkeq"):
                                                        cur_var += 2
                                                        if not wild_match:
                                                            out_args[cur_var] = new_rep_var_name[arg+1]
                                                        else:
                                                            out_args[cur_var] = trim(new_rep_var_name[arg+1]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                        if new_rep_var_caution[arg+1] != blank and not same_string(new_rep_var_caution[arg+1][:6], "Forkeq"):
                                                            if not cmtr_d_var_caution[arg+1]:
                                                                write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                    f"Custom Decrement Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Decrement Meter (new)=\"{trim(new_rep_var_name[arg+1])}\" has the following caution \"{trim(new_rep_var_caution[arg+1])}\".")
                                                                cmtr_d_var_caution[arg+1] = True
                                                        out_args[cur_var+1] = in_args[var+1]
                                                        nodiff = False
                                                if arg < len(old_rep_var_name) - 2 and old_rep_var_name[arg] == old_rep_var_name[arg+2]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = new_rep_var_name[arg+2]
                                                    else:
                                                        out_args[cur_var] = trim(new_rep_var_name[arg+2]) + out_args[cur_var][len_trim(uc_comp_rep_var_name):]
                                                    if new_rep_var_caution[arg+2] != blank:
                                                        if not cmtr_d_var_caution[arg+2]:
                                                            write_preprocessor_object(dif_file, prog_name_conversion, "Warning",
                                                                f"Custom Decrement Meter (old)=\"{trim(old_rep_var_name[arg])}\" conversion to Custom Meter (new)=\"{trim(new_rep_var_name[arg+2])}\" has the following caution \"{trim(new_rep_var_caution[arg+2])}\".")
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
                                
                                elif make_upper_case(trim(idf_records[num].Name)) in ["DEMANDMANAGERASSIGNMENTLIST", "UTILITYCOST:TARIFF"]:
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    scan_output_variables_for_replacement(
                                        2, blank, checkrvi, nodiff, object_name, dif_file,
                                        False, True, False, cur_args, written, False
                                    )
                                
                                elif make_upper_case(trim(idf_records[num].Name)) == "ELECTRICLOADCENTER:DISTRIBUTION":
                                    get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
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
                                        with open(auditf, 'a') as af:
                                            af.write(f"Object=\"{trim(object_name)}\" is not in the \"new\" IDD.\n")
                                            af.write("... will be listed as comments on the new output file.\n")
                                        write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                        written = True
                                    else:
                                        get_new_object_def_in_idd(object_name)
                                        out_args[0:cur_args] = in_args[0:cur_args]
                                        nodiff = True
                            else:
                                get_new_object_def_in_idd(idf_records[num].Name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                            
                            if diff_min_fields and nodiff:
                                get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = False
                            
                            if nodiff and diff_only:
                                continue
                            
                            if not written:
                                check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                            
                            if not written:
                                write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    display_string("Processing IDF -- Processing idf objects complete.")
                    
                    if idf_records[num_idf_records - 1].CommtE != cur_comment:
                        with open(dif_file, 'a') as dfn:
                            for xcount in range(idf_records[num_idf_records - 1].CommtE + 1, cur_comment + 1):
                                dfn.write(trim(comments[xcount]) + "\n")
                                if xcount == idf_records[num_idf_records - 1].CommtE:
                                    dfn.write("\n")
                    
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
        err_flag = False
        copyfile_func(f"{trim(file_name_path)}.{trim(arg_idf_extension)}", f"{trim(file_name_path)}.{trim(arg_idf_extension)}old", err_flag)
        copyfile_func(f"{trim(file_name_path)}.{trim(arg_idf_extension)}new", f"{trim(file_name_path)}.{trim(arg_idf_extension)}", err_flag)
        
        if os.path.exists(f"{trim(file_name_path)}.rvi"):
            copyfile_func(f"{trim(file_name_path)}.rvi", f"{trim(file_name_path)}.rviold", err_flag)
        
        if os.path.exists(f"{trim(file_name_path)}.rvinew"):
            copyfile_func(f"{trim(file_name_path)}.rvinew", f"{trim(file_name_path)}.rvi", err_flag)
        
        if os.path.exists(f"{trim(file_name_path)}.mvi"):
            copyfile_func(f"{trim(file_name_path)}.mvi", f"{trim(file_name_path)}.mviold", err_flag)
        
        if os.path.exists(f"{trim(file_name_path)}.mvinew"):
            copyfile_func(f"{trim(file_name_path)}.mvinew", f"{trim(file_name_path)}.mvi", err_flag)

    return end_of_file
