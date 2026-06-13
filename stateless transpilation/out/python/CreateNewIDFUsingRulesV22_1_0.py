# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ProgNameConversion, ProgramPath, blank
# - DataVCompareGlobals: shared state objects (FullFileName, FileNamePath, IDFRecords, Comments, etc.)
# - VCompareGlobalRoutines: various helper functions
# - InputProcessor: various processing functions
# - DataGlobals: error/warning functions
# - General module functions

from typing import Protocol, List, Tuple, Optional, Union
from dataclasses import dataclass, field
from enum import Enum


@dataclass
class ExternalDeps:
    """Stub for external dependencies to be injected."""
    prog_name_conversion: str
    program_path: str
    blank: str
    
    full_file_name: str = ""
    file_name_path: str = ""
    audit_f: int = 0
    fatal_error: bool = False
    making_pretty: bool = False
    processing_imf_file: bool = False
    file_ok: bool = False
    
    idf_records: List['IDFRecord'] = field(default_factory=list)
    comments: List[str] = field(default_factory=list)
    cur_comment: int = 0
    num_idf_records: int = 0
    
    not_in_new: List[str] = field(default_factory=list)
    num_object_defs: int = 0
    object_def_names: List[str] = field(default_factory=list)
    
    max_alpha_args_found: int = 0
    max_numeric_args_found: int = 0
    max_total_args: int = 0
    max_name_length: int = 0
    
    num_alpha: int = 0
    num_numbers: int = 0
    
    num_rep_var_names: int = 0
    old_rep_var_name: List[str] = field(default_factory=list)
    new_rep_var_name: List[str] = field(default_factory=list)
    new_rep_var_caution: List[str] = field(default_factory=list)
    otm_var_caution: List[bool] = field(default_factory=list)
    cmtr_var_caution: List[bool] = field(default_factory=list)
    cmtr_d_var_caution: List[bool] = field(default_factory=list)


@dataclass
class IDFRecord:
    """Fortran-equivalent IDFRecord derived type."""
    name: str
    num_alphas: int
    num_numbers: int
    alphas: List[str]
    numbers: List[Union[int, float]]
    commt_s: int
    commt_e: int


class ExternalFunctions(Protocol):
    """External function stubs."""
    
    def get_new_unit_number(self) -> int:
        """Returns a new available unit number for file I/O."""
        ...
    
    def show_message(self, msg: str, audit_file: int = 0) -> None:
        ...
    
    def show_continue_error(self, msg: str, audit_file: int = 0) -> None:
        ...
    
    def show_fatal_error(self, msg: str, audit_file: int = 0) -> None:
        ...
    
    def show_severe_error(self, msg: str, audit_file: int = 0) -> None:
        ...
    
    def show_warning_error(self, msg: str, audit_file: int = 0) -> None:
        ...
    
    def trim_trail_zeros(self, s: str) -> str:
        """Trim trailing zeros from string."""
        ...
    
    def make_lower_case(self, s: str) -> str:
        ...
    
    def make_upper_case(self, s: str) -> str:
        ...
    
    def same_string(self, s1: str, s2: str) -> bool:
        ...
    
    def find_item_in_list(self, item: str, list_items: List[str], size: int) -> int:
        """Returns 1-based index, or 0 if not found."""
        ...
    
    def get_object_def_in_idd(self, object_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]:
        """Returns (NumArgs, AorN, ReqFld, ObjMinFlds, FldNames, FldDefaults, FldUnits)."""
        ...
    
    def get_new_object_def_in_idd(self, object_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]:
        """Returns (NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits)."""
        ...
    
    def process_input(self, idd_file_with_path: str, new_idd_file_with_path: str, idf_file: str, deps: ExternalDeps) -> None:
        ...
    
    def display_string(self, msg: str) -> None:
        ...
    
    def write_out_idf_lines_as_comments(self, file_unit: int, object_name: str, cur_args: int, 
                                       out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None:
        ...
    
    def scan_output_variables_for_replacement(self, field_num: int, del_this: List[bool], check_rvi: List[bool],
                                             nodiff: List[bool], object_name: str, file_unit: int,
                                             out_var: bool, mtr_var: bool, time_bin_var: bool,
                                             cur_args: int, written: List[bool], ems_actuator: bool,
                                             deps: ExternalDeps) -> None:
        ...
    
    def write_out_idf_lines(self, file_unit: int, object_name: str, cur_args: int,
                           out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None:
        ...
    
    def check_special_objects(self, file_unit: int, object_name: str, cur_args: int,
                             out_args: List[str], fld_names: List[str], fld_units: List[str],
                             written: List[bool]) -> None:
        ...
    
    def get_num_sections_found(self, section_name: str) -> int:
        ...
    
    def process_rvi_mvi_files(self, file_name_path: str, extension: str, deps: ExternalDeps) -> None:
        ...
    
    def close_out(self) -> None:
        ...
    
    def create_new_name(self, action: str, created_output_name: List[str], extra: str, deps: ExternalDeps) -> None:
        ...
    
    def copyfile(self, src: str, dst: str, err_flag: List[bool]) -> None:
        ...
    
    def write_preprocessor_object(self, file_unit: int, prog_name: str, level: str, msg: str) -> None:
        ...


def set_this_version_variables(deps: ExternalDeps) -> None:
    """Equivalent to SetThisVersionVariables subroutine."""
    deps.blank = ""
    ver_string = "Conversion 9.6 => 22.1"
    version_num = 22.1
    s_version_num = "***"
    s_version_num_four_chars = "22.1"
    
    idd_file_name_with_path = deps.program_path.rstrip() + "V9-6-0-Energy+.idd"
    new_idd_file_name_with_path = deps.program_path.rstrip() + "V22-1-0-Energy+.idd"
    rep_var_file_name_with_path = deps.program_path.rstrip() + "Report Variables 9-6-0 to 22-1-0.csv"
    
    return idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path


def trim_string(s: str) -> str:
    """Equivalent to TRIM in Fortran."""
    return s.rstrip()


def adjust_left(s: str) -> str:
    """Equivalent to ADJUSTL in Fortran."""
    return s.lstrip()


def scan_backward(s: str, char: str) -> int:
    """SCAN with .true. for backward search; returns 1-based position or 0."""
    idx = s.rfind(char)
    return idx + 1 if idx >= 0 else 0


def scan_forward(s: str, char: str) -> int:
    """SCAN with .false. for forward search; returns 1-based position or 0."""
    idx = s.find(char)
    return idx + 1 if idx >= 0 else 0


def len_trim(s: str) -> int:
    """Equivalent to LEN_TRIM in Fortran."""
    return len(s.rstrip())


def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDeps,
    ext_funcs: ExternalFunctions
) -> None:
    """
    Main subroutine equivalent to CreateNewIDFUsingRules.
    
    Note: end_of_file is a list to allow in-out semantics in Python.
    """
    fmta = "(A)"
    
    ios = 0
    dot_pos = 0
    status = 0
    na = 0
    nn = 0
    cur_args = 0
    dif_lfn = 0
    x_count = 0
    num = 0
    arg = 0
    first_time = True
    units_arg = ""
    object_name = ""
    uc_rep_var_name = ""
    uc_comp_rep_var_name = ""
    del_this = False
    pos = 0
    pos2 = 0
    cur_var_iterator = 0
    exit_because_bad_file = False
    still_working = True
    no_diff = True
    check_rvi = False
    no_version = True
    diff_min_fields = False
    written = False
    var = 0
    cur_var = 0
    arg_file_being_done = False
    latest_version = False
    local_file_extension = ""
    wild_match = False
    
    p_out_args: List[str] = []
    conn_comp = False
    conn_comp_ctrl = False
    file_exist = False
    created_output_name = ""
    delete_this_record: List[bool] = []
    c_out_args = 0
    units_field = ""
    err_flag = False
    
    i = 0
    cur_field = 0
    new_field = 0
    ka_index = 0
    search_num = 0
    alpha_num_i = 0
    save_number = 0.0
    
    tot_run_periods = 0
    run_period_num = 0
    iterate_run_period = 0
    wwhp_eq_ft_cool_index = 0
    wwhp_eq_ft_heat_index = 0
    wahp_eq_ft_cool_index = 0
    wahp_eq_ft_heat_index = 0
    current_run_period_names: List[str] = []
    potential_run_period_name = ""
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        with open(f"unit_{in_lfn}.txt", "r") as f:
                            full_file_name = f.readline().strip()
                        ios = 0
                    except:
                        full_file_name = ""
                        ios = 1
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
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                ext_funcs.display_string(f"Processing IDF -- {full_file_name.strip()}")
                
                dot_pos = scan_backward(full_file_name, ".")
                if dot_pos != 0:
                    file_name_path = full_file_name[0:dot_pos - 1]
                    local_file_extension = ext_funcs.make_lower_case(full_file_name[dot_pos:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.rstrip() + ".idf"
                    local_file_extension = "idf"
                
                deps.full_file_name = full_file_name
                deps.file_name_path = file_name_path
                
                dif_lfn = ext_funcs.get_new_unit_number()
                
                try:
                    with open(full_file_name, "r") as f:
                        file_exist = True
                except:
                    file_exist = False
                
                deps.file_ok = file_exist
                
                if not file_exist:
                    print(f"File not found={full_file_name}")
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        out_file_name = f"{file_name_path}.{local_file_extension}dif"
                    else:
                        out_file_name = f"{file_name_path}.{local_file_extension}new"
                    
                    if local_file_extension == "imf":
                        ext_funcs.show_warning_error("Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.", deps.audit_f)
                        deps.processing_imf_file = True
                    else:
                        deps.processing_imf_file = False
                    
                    ext_funcs.process_input(
                        deps.file_name_path if hasattr(deps, 'idd_file_name_with_path') else "",
                        deps.file_name_path if hasattr(deps, 'new_idd_file_name_with_path') else "",
                        full_file_name,
                        deps
                    )
                    
                    if deps.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    if deps.num_idf_records > 0:
                        delete_this_record = [False] * deps.num_idf_records
                    else:
                        delete_this_record = []
                    
                    no_version = True
                    for num in range(len(deps.idf_records)):
                        if ext_funcs.make_upper_case(deps.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(len(delete_this_record)):
                        if delete_this_record[num]:
                            print(f"! Deleting: {deps.idf_records[num].name}=\"{deps.idf_records[num].alphas[0]}\".")
                    
                    ext_funcs.display_string("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(len(deps.idf_records)):
                        if delete_this_record[num]:
                            continue
                        
                        for x_count in range(deps.idf_records[num].commt_s, deps.idf_records[num].commt_e + 1):
                            if x_count < len(deps.comments):
                                print(deps.comments[x_count].rstrip())
                                if x_count == deps.idf_records[num].commt_e:
                                    print()
                        
                        if no_version and num == 0:
                            object_name = "VERSION"
                            num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                ext_funcs.get_new_object_def_in_idd(object_name)
                            out_args = [""] * (nw_obj_min_flds + 1)
                            out_args[0] = "22.1"
                            cur_args = 1
                            ext_funcs.show_warning_error(f"No version found in file, defaulting to 22.1", deps.audit_f)
                            ext_funcs.write_out_idf_lines_as_comments(dif_lfn, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = deps.idf_records[num].name
                        
                        if ext_funcs.find_item_in_list(object_name, deps.object_def_names, deps.num_object_defs) != 0:
                            num_args, aor_n, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                ext_funcs.get_object_def_in_idd(object_name)
                            
                            num_alphas = deps.idf_records[num].num_alphas
                            num_numbers = deps.idf_records[num].num_numbers
                            
                            alphas = deps.idf_records[num].alphas.copy()
                            numbers = deps.idf_records[num].numbers.copy()
                            
                            cur_args = num_alphas + num_numbers
                            in_args = [""] * (cur_args + 1)
                            out_args = [""] * (cur_args + 1)
                            temp_args = [""] * (cur_args + 1)
                            
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na - 1] if na <= len(alphas) else ""
                                else:
                                    nn += 1
                                    in_args[arg] = str(numbers[nn - 1]) if nn <= len(numbers) else ""
                        else:
                            num_alphas = deps.idf_records[num].num_alphas
                            num_numbers = deps.idf_records[num].num_numbers
                            alphas = deps.idf_records[num].alphas.copy()
                            numbers = deps.idf_records[num].numbers.copy()
                            
                            out_args = [""] * (num_alphas + num_numbers + 1)
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * (cur_args + 1)
                            nw_fld_units = [""] * (cur_args + 1)
                            ext_funcs.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if ext_funcs.find_item_in_list(ext_funcs.make_upper_case(object_name), deps.not_in_new, len(deps.not_in_new)) == 0:
                            num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                ext_funcs.get_new_object_def_in_idd(object_name)
                            
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not deps.making_pretty:
                            object_upper = ext_funcs.make_upper_case(object_name.strip())
                            
                            if object_upper == "VERSION":
                                if in_args[0][0:4] == "22.1" and arg_file:
                                    ext_funcs.show_warning_error("File is already at latest version. No new diff file made.", deps.audit_f)
                                    latest_version = True
                                    end_of_file[0] = True
                                    break
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0] = "22.1"
                                no_diff = False
                            
                            elif object_upper == "PYTHONPLUGIN:SEARCHPATHS":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                no_diff = False
                                out_args[0:3] = in_args[0:3]
                                out_args[3] = "Yes"
                                if cur_args >= 4:
                                    out_args[4:cur_args + 2] = in_args[3:cur_args + 1]
                                cur_args = cur_args + 1
                            
                            elif object_upper == "OUTPUT:VARIABLE":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    no_diff = False
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    2, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, True, False, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                if del_this_list[0]:
                                    continue
                            
                            elif object_upper in ("OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"):
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    1, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, True, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                if del_this_list[0]:
                                    continue
                            
                            elif object_upper == "OUTPUT:TABLE:TIMEBINS":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    no_diff = False
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    2, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, False, True,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                if del_this_list[0]:
                                    continue
                            
                            elif object_upper in ("EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"):
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    no_diff = False
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    2, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, False, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                if del_this_list[0]:
                                    continue
                            
                            elif object_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    3, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, False, False,
                                    cur_args, written_list, True, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                if del_this_list[0]:
                                    continue
                            
                            elif object_upper == "OUTPUT:TABLE:MONTHLY":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                no_diff = True
                                out_args[0:cur_args] = in_args[0:cur_args]
                                
                                cur_var = 3
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = ext_funcs.make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    pos = uc_rep_var_name.find("[")
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        out_args[cur_var] = in_args[var][0:pos]
                                        out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    del_this = False
                                    
                                    for arg in range(len(deps.old_rep_var_name)):
                                        uc_comp_rep_var_name = ext_funcs.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name.rstrip()[-1:] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + " "
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        
                                        if pos > 0:
                                            if deps.new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg] != "" and not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    if not deps.otm_var_caution[arg]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Output Table Monthly (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Output Table Monthly (new)=\"{deps.new_rep_var_name[arg]}\" has the following caution \"{deps.new_rep_var_caution[arg]}\"."
                                                        )
                                                        deps.otm_var_caution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != "":
                                                        if not deps.otm_var_caution[arg + 1]:
                                                            ext_funcs.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, "Warning",
                                                                f"Output Table Monthly (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Output Table Monthly (new)=\"{deps.new_rep_var_name[arg + 1]}\" has the following caution \"{deps.new_rep_var_caution[arg + 1]}\"."
                                                            )
                                                            deps.otm_var_caution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                    no_diff = False
                                            
                                            if arg + 2 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != "":
                                                    if not deps.otm_var_caution[arg + 2]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Output Table Monthly (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Output Table Monthly (new)=\"{deps.new_rep_var_name[arg + 2]}\" has the following caution \"{deps.new_rep_var_caution[arg + 2]}\"."
                                                        )
                                                        deps.otm_var_caution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif object_upper == "METER:CUSTOM":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                cur_var = 4
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = ext_funcs.make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    pos = uc_rep_var_name.find("[")
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        out_args[cur_var] = in_args[var][0:pos]
                                        out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    del_this = False
                                    
                                    for arg in range(len(deps.old_rep_var_name)):
                                        uc_comp_rep_var_name = ext_funcs.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name.rstrip()[-1:] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + " "
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        
                                        if pos > 0:
                                            if deps.new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg] != "" and not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    if not deps.cmtr_var_caution[arg]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Custom Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Meter (new)=\"{deps.new_rep_var_name[arg]}\" has the following caution \"{deps.new_rep_var_caution[arg]}\"."
                                                        )
                                                        deps.cmtr_var_caution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != "" and not ext_funcs.same_string(deps.new_rep_var_caution[arg + 1][0:6], "Forkeq"):
                                                        if not deps.cmtr_var_caution[arg + 1]:
                                                            ext_funcs.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, "Warning",
                                                                f"Custom Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Meter (new)=\"{deps.new_rep_var_name[arg + 1]}\" has the following caution \"{deps.new_rep_var_caution[arg + 1]}\"."
                                                            )
                                                            deps.cmtr_var_caution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                    no_diff = False
                                            
                                            if arg + 2 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != "":
                                                    if not deps.cmtr_var_caution[arg + 2]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Custom Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Meter (new)=\"{deps.new_rep_var_name[arg + 2]}\" has the following caution \"{deps.new_rep_var_caution[arg + 2]}\"."
                                                        )
                                                        deps.cmtr_var_caution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == "":
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif object_upper == "METER:CUSTOMDECREMENT":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                cur_var = 4
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = ext_funcs.make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    pos = uc_rep_var_name.find("[")
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        out_args[cur_var] = in_args[var][0:pos]
                                        out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                    
                                    del_this = False
                                    
                                    for arg in range(len(deps.old_rep_var_name)):
                                        uc_comp_rep_var_name = ext_funcs.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name.rstrip()[-1:] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name.rstrip()[:-1] + " "
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
                                        else:
                                            wild_match = False
                                            pos = 0
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 1
                                        
                                        if pos > 0 and pos != 1:
                                            continue
                                        
                                        if pos > 0:
                                            if deps.new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg] != "" and not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    if not deps.cmtr_d_var_caution[arg]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Custom Decrement Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Meter (new)=\"{deps.new_rep_var_name[arg]}\" has the following caution \"{deps.new_rep_var_caution[arg]}\"."
                                                        )
                                                        deps.cmtr_d_var_caution[arg] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not ext_funcs.same_string(deps.new_rep_var_caution[arg][0:6], "Forkeq"):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        out_args[cur_var] = deps.new_rep_var_name[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != "" and not ext_funcs.same_string(deps.new_rep_var_caution[arg + 1][0:6], "Forkeq"):
                                                        if not deps.cmtr_d_var_caution[arg + 1]:
                                                            ext_funcs.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, "Warning",
                                                                f"Custom Decrement Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Decrement Meter (new)=\"{deps.new_rep_var_name[arg + 1]}\" has the following caution \"{deps.new_rep_var_caution[arg + 1]}\"."
                                                            )
                                                            deps.cmtr_d_var_caution[arg + 1] = True
                                                    
                                                    out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                    no_diff = False
                                            
                                            if arg + 2 < len(deps.old_rep_var_name) and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.new_rep_var_name[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.strip()):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != "":
                                                    if not deps.cmtr_d_var_caution[arg + 2]:
                                                        ext_funcs.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, "Warning",
                                                            f"Custom Decrement Meter (old)=\"{deps.old_rep_var_name[arg]}\" conversion to Custom Meter (new)=\"{deps.new_rep_var_name[arg + 2]}\" has the following caution \"{deps.new_rep_var_caution[arg + 2]}\"."
                                                        )
                                                        deps.cmtr_d_var_caution[arg + 2] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1] if var + 1 < cur_args else ""
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    
                                    var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if out_args[arg] == "":
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif object_upper in ("DEMANDMANAGERASSIGNMENTLIST", "UTILITYCOST:TARIFF"):
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    2, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, True, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                            
                            elif object_upper == "ELECTRICLOADCENTER:DISTRIBUTION":
                                num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    ext_funcs.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    6, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, True, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                                
                                del_this_list = [False]
                                check_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                written_list = [written]
                                
                                ext_funcs.scan_output_variables_for_replacement(
                                    12, del_this_list, check_rvi_list, no_diff_list,
                                    object_name, dif_lfn, False, True, False,
                                    cur_args, written_list, False, deps
                                )
                                
                                check_rvi = check_rvi_list[0]
                                no_diff = no_diff_list[0]
                                written = written_list[0]
                            
                            else:
                                if ext_funcs.find_item_in_list(object_name, deps.not_in_new, len(deps.not_in_new)) != 0:
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    written = True
                                else:
                                    num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        ext_funcs.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    no_diff = True
                        
                        else:
                            num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                ext_funcs.get_new_object_def_in_idd(object_name)
                            out_args[0:cur_args] = in_args[0:cur_args]
                        
                        if diff_min_fields and no_diff:
                            num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                ext_funcs.get_new_object_def_in_idd(object_name)
                            out_args[0:cur_args] = in_args[0:cur_args]
                            no_diff = False
                            for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                if arg < len(nw_fld_defaults):
                                    out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            ext_funcs.check_special_objects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, [written])
                            written = [written][0]
                        
                        if not written:
                            ext_funcs.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    ext_funcs.display_string("Processing IDF -- Processing idf objects complete.")
                    
                    if len(deps.idf_records) > 0 and deps.idf_records[-1].commt_e != deps.cur_comment:
                        for x_count in range(deps.idf_records[-1].commt_e + 1, deps.cur_comment + 1):
                            if x_count < len(deps.comments):
                                print(deps.comments[x_count].rstrip())
                                if x_count == deps.idf_records[-1].commt_e:
                                    print()
                    
                    if ext_funcs.get_num_sections_found("Report Variable Dictionary") > 0:
                        object_name = "Output:VariableDictionary"
                        num_new_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            ext_funcs.get_new_object_def_in_idd(object_name)
                        no_diff = False
                        out_args = ["Regular"] + [""] * num_new_args
                        cur_args = 1
                        ext_funcs.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    file_exist = False
                    try:
                        with open(f"{file_name_path}.rvi", "r"):
                            file_exist = True
                    except:
                        file_exist = False
                    
                    ext_funcs.process_rvi_mvi_files(file_name_path, "rvi", deps)
                    ext_funcs.process_rvi_mvi_files(file_name_path, "mvi", deps)
                    ext_funcs.close_out()
                
                else:
                    ext_funcs.process_rvi_mvi_files(file_name_path, "rvi", deps)
                    ext_funcs.process_rvi_mvi_files(file_name_path, "mvi", deps)
            
            else:
                end_of_file[0] = True
            
            created_output_name_list = [""]
            ext_funcs.create_new_name("Reallocate", created_output_name_list, " ", deps)
        
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
        err_flag = False
        ext_funcs.copyfile(
            f"{file_name_path}.{arg_idf_extension}",
            f"{file_name_path}.{arg_idf_extension}old",
            [err_flag]
        )
        ext_funcs.copyfile(
            f"{file_name_path}.{arg_idf_extension}new",
            f"{file_name_path}.{arg_idf_extension}",
            [err_flag]
        )
        
        file_exist = False
        try:
            with open(f"{file_name_path}.rvi", "r"):
                file_exist = True
        except:
            file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(f"{file_name_path}.rvi", f"{file_name_path}.rviold", [err_flag])
        
        file_exist = False
        try:
            with open(f"{file_name_path}.rvinew", "r"):
                file_exist = True
        except:
            file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(f"{file_name_path}.rvinew", f"{file_name_path}.rvi", [err_flag])
        
        file_exist = False
        try:
            with open(f"{file_name_path}.mvi", "r"):
                file_exist = True
        except:
            file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(f"{file_name_path}.mvi", f"{file_name_path}.mviold", [err_flag])
        
        file_exist = False
        try:
            with open(f"{file_name_path}.mvinew", "r"):
                file_exist = True
        except:
            file_exist = False
        
        if file_exist:
            ext_funcs.copyfile(f"{file_name_path}.mvinew", f"{file_name_path}.mvi", [err_flag])
