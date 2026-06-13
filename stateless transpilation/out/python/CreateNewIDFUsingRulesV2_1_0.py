from typing import Protocol, Any, List, Optional, Callable
from dataclasses import dataclass, field
import os


@dataclass
class IDFRecord:
    Name: str = ""
    NumAlphas: int = 0
    NumNumbers: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[float] = field(default_factory=list)
    CommtS: int = 0
    CommtE: int = 0


@dataclass
class ObjectDefType:
    Name: List[str] = field(default_factory=list)


class ExternalContext(Protocol):
    ver_string: str
    version_num: float
    idd_file_name_with_path: str
    new_idd_file_name_with_path: str
    rep_var_file_name_with_path: str
    blank: str
    fatal_error: bool
    max_alpha_args_found: int
    max_numeric_args_found: int
    max_total_args: int
    num_idf_records: int
    idf_records: List[IDFRecord]
    object_def: ObjectDefType
    num_object_defs: int
    comments: List[str]
    cur_comment: int
    not_in_new: List[str]
    num_rep_var_names: int
    old_rep_var_name: List[str]
    new_rep_var_name: List[str]
    processing_imf_file: bool
    making_pretty: bool
    file_name_path: str
    full_file_name: str
    auditf: Any

    def display_string(self, msg: str) -> None: ...
    def process_input(self, old_idd: str, new_idd: str, file_path: str) -> None: ...
    def get_new_object_def_in_idd(self, obj_name: str) -> tuple: ...
    def get_object_def_in_idd(self, obj_name: str) -> tuple: ...
    def find_item_in_list(self, item: str, item_list: List[str]) -> int: ...
    def write_out_idf_lines_as_comments(self, lfn: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def write_out_idf_lines(self, lfn: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def make_upper_case(self, s: str) -> str: ...
    def make_lower_case(self, s: str) -> str: ...
    def process_number(self, s: str) -> tuple: ...
    def round_sig_digits(self, num: float, digits: int) -> str: ...
    def scan_output_variables_for_replacement(self, arg_pos: int, out_var: bool, mtr_var: bool, time_bin_var: bool, cur_args: int, obj_name: str, lfn: int, out_args: List[str]) -> tuple: ...
    def check_special_objects(self, lfn: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> tuple: ...
    def process_rvi_mvi_files(self, path: str, ext: str) -> None: ...
    def close_out(self) -> None: ...
    def create_new_name(self, action: str, out_name: str, marker: str) -> str: ...
    def same_string(self, s1: str, s2: str) -> bool: ...
    def copy_file(self, src: str, dst: str) -> bool: ...
    def trim_trail_zeros(self, s: str) -> str: ...
    def get_new_unit_number(self) -> int: ...
    def show_warning_error(self, msg: str, lfn: Any) -> None: ...
    def show_severe_error(self, msg: str, lfn: Any) -> None: ...


def set_this_version_variables(context: ExternalContext) -> None:
    context.ver_string = "Conversion 2.0 => 2.1"
    context.version_num = 2.0
    context.idd_file_name_with_path = context.file_name_path + "V2-0-0-Energy+.idd"
    context.new_idd_file_name_with_path = context.file_name_path + "V2-1-0-Energy+.idd"
    context.rep_var_file_name_with_path = context.file_name_path + "Report Variables 2-0-0-025 to 2-1-0.csv"


def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    context: ExternalContext,
) -> bool:
    fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="", flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    ios = 0
                    try:
                        with open(in_lfn, "r") as f:
                            full_file_name = f.readline().strip()
                            ios = 0
                    except:
                        ios = 1
                        full_file_name = ""
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if full_file_name.startswith("!"):
                    full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.strip()
            
            if full_file_name != "":
                context.display_string("Processing IDF -- " + full_file_name)
                print("Processing IDF -- " + full_file_name, file=context.auditf)
                
                dot_pos = full_file_name.rfind(".")
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = context.make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print("assuming file extension of .idf")
                    print("..assuming file extension of .idf", file=context.auditf)
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                dif_lfn = context.get_new_unit_number()
                file_ok = os.path.exists(full_file_name)
                
                if not file_ok:
                    print(f"File not found={full_file_name}")
                    print(f"File not found={full_file_name}", file=context.auditf)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    comis_sim = False
                    ads_sim = False
                    
                    if diff_only:
                        out_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        context.show_warning_error(
                            "Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.",
                            context.auditf
                        )
                        context.processing_imf_file = True
                    else:
                        context.processing_imf_file = False
                    
                    context.process_input(
                        context.idd_file_name_with_path,
                        context.new_idd_file_name_with_path,
                        full_file_name
                    )
                    
                    if context.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [""] * context.max_alpha_args_found
                    numbers = [0.0] * context.max_numeric_args_found
                    in_args = [""] * context.max_total_args
                    aor_n = [False] * context.max_total_args
                    req_fld = [False] * context.max_total_args
                    fld_names = [""] * context.max_total_args
                    fld_defaults = [""] * context.max_total_args
                    fld_units = [""] * context.max_total_args
                    nw_aor_n = [False] * context.max_total_args
                    nw_req_fld = [False] * context.max_total_args
                    nw_fld_names = [""] * context.max_total_args
                    nw_fld_defaults = [""] * context.max_total_args
                    nw_fld_units = [""] * context.max_total_args
                    out_args = [""] * context.max_total_args
                    match_arg = [False] * context.max_total_args
                    delete_this_record = [False] * context.num_idf_records
                    
                    for num in range(context.num_idf_records):
                        if context.make_upper_case(context.idf_records[num].Name) == "COMIS SIMULATION":
                            comis_sim = True
                        if context.make_upper_case(context.idf_records[num].Name) == "ADS SIMULATION":
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        print(f"File contains both COMIS and ADS Simulation objects={full_file_name}")
                        print(
                            "Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file."
                        )
                        print(
                            f"..File contains both COMIS and ADS Simulation objects={full_file_name}",
                            file=context.auditf
                        )
                        print(
                            "..Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.",
                            file=context.auditf
                        )
                        exit_because_bad_file = True
                        break
                    
                    no_version = True
                    for num in range(context.num_idf_records):
                        if context.make_upper_case(context.idf_records[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    with open(out_file_name, "w") as dif_file:
                        for num in range(context.num_idf_records):
                            for xcount in range(
                                context.idf_records[num].CommtS,
                                context.idf_records[num].CommtE + 1
                            ):
                                dif_file.write(context.comments[xcount] + "\n")
                                if xcount == context.idf_records[num].CommtE:
                                    dif_file.write("\n")
                            
                            if no_version and num == 0:
                                nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    context.get_new_object_def_in_idd("VERSION")
                                out_args[0] = "2.1"
                                cur_args = 1
                                context.write_out_idf_lines_as_comments(
                                    dif_file, "VERSION", cur_args, out_args,
                                    nw_fld_names, nw_fld_units
                                )
                            
                            if context.make_upper_case(context.idf_records[num].Name.strip()) == "SKY RADIANCE DISTRIBUTION":
                                continue
                            if context.make_upper_case(context.idf_records[num].Name.strip()) == "AIRFLOW MODEL":
                                continue
                            if context.make_upper_case(context.idf_records[num].Name.strip()) == "GENERATOR:FC:BATTERY DATA":
                                continue
                            if context.make_upper_case(context.idf_records[num].Name.strip()) == "WATER HEATER:SIMPLE":
                                dif_file.write("\n")
                                continue
                            
                            object_name = context.idf_records[num].Name
                            if context.find_item_in_list(object_name, context.object_def.Name) != 0:
                                num_args, aor_n, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                    context.get_object_def_in_idd(object_name)
                                num_alphas = context.idf_records[num].NumAlphas
                                num_numbers = context.idf_records[num].NumNumbers
                                for i in range(num_alphas):
                                    alphas[i] = context.idf_records[num].Alphas[i]
                                for i in range(num_numbers):
                                    numbers[i] = context.idf_records[num].Numbers[i]
                                cur_args = num_alphas + num_numbers
                                in_args = [""] * context.max_total_args
                                out_args = [""] * context.max_total_args
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
                                print(
                                    f'Object="{object_name}" does not seem to be on the "old" IDD.',
                                    file=context.auditf
                                )
                                print(
                                    "... will be listed as comments (no field names) on the new output file.",
                                    file=context.auditf
                                )
                                print(
                                    "... Alpha fields will be listed first, then numerics.",
                                    file=context.auditf
                                )
                                num_alphas = context.idf_records[num].NumAlphas
                                num_numbers = context.idf_records[num].NumNumbers
                                for i in range(num_alphas):
                                    alphas[i] = context.idf_records[num].Alphas[i]
                                for i in range(num_numbers):
                                    numbers[i] = context.idf_records[num].Numbers[i]
                                for arg in range(num_alphas):
                                    out_args[arg] = alphas[arg]
                                nn = num_alphas
                                for arg in range(num_numbers):
                                    out_args[nn] = str(numbers[arg])
                                    nn += 1
                                cur_args = num_alphas + num_numbers
                                nw_fld_names = [""] * context.max_total_args
                                nw_fld_units = [""] * context.max_total_args
                                context.write_out_idf_lines_as_comments(
                                    dif_file, object_name, cur_args, out_args,
                                    nw_fld_names, nw_fld_units
                                )
                                continue
                            
                            nodiff = True
                            diff_min_fields = False
                            written = False
                            
                            if context.find_item_in_list(context.make_upper_case(object_name), context.not_in_new) == 0:
                                nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    context.get_new_object_def_in_idd(object_name)
                                if obj_min_flds != nw_obj_min_flds:
                                    diff_min_fields = True
                                else:
                                    diff_min_fields = False
                            
                            if not context.making_pretty:
                                obj_upper = context.make_upper_case(context.idf_records[num].Name.strip())
                                
                                if obj_upper == "VERSION":
                                    if in_args[0][:3] == "2.1" and arg_file:
                                        context.show_warning_error(
                                            "File is already at latest version. No new diff file made.",
                                            context.auditf
                                        )
                                        dif_file.close()
                                        latest_version = True
                                        break
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0] = "2.1"
                                    nodiff = False
                                
                                elif obj_upper == "SYSTEM SIZING":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:5] = in_args[0:5]
                                    out_args[5] = ".008"
                                    out_args[6] = "11.0"
                                    out_args[7] = ".008"
                                    for i in range(8, cur_args + 3):
                                        if i - 3 < len(in_args):
                                            out_args[i] = in_args[i - 3]
                                    cur_args = cur_args + 3
                                    nodiff = False
                                
                                elif obj_upper == "HEAT EXCHANGER:DESICCANT:BALANCEDFLOW:PERFORMANCE DATA TYPE 1":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    for arg in range(24, 28):
                                        err_flag, save_number = context.process_number(out_args[arg])
                                        if err_flag:
                                            context.show_severe_error(
                                                f"Invalid Number, HEAT EXCHANGER:DESICCANT:BALANCEDFLOW:PERFORMANCE DATA TYPE 1 field {arg}, Name={out_args[0]}",
                                                context.auditf
                                            )
                                            dif_file.write(f"  ! Invalid Number, field {arg} {{{nw_fld_names[arg]}}} contents={out_args[arg]}\n")
                                        else:
                                            save_number = save_number * 100.0
                                            out_args[arg] = context.round_sig_digits(save_number, 1)
                                    for arg in range(48, 52):
                                        err_flag, save_number = context.process_number(out_args[arg])
                                        if err_flag:
                                            context.show_severe_error(
                                                f"Invalid Number, HEAT EXCHANGER:DESICCANT:BALANCEDFLOW:PERFORMANCE DATA TYPE 1 field {arg}, Name={out_args[0]}",
                                                context.auditf
                                            )
                                            dif_file.write(f"  ! Invalid Number, field {arg} {{{nw_fld_names[arg]}}} contents={out_args[arg]}\n")
                                        else:
                                            save_number = save_number * 100.0
                                            out_args[arg] = context.round_sig_digits(save_number, 1)
                                    nodiff = False
                                
                                elif obj_upper == "HEAT EXCHANGER:DESICCANT:BALANCEDFLOW":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    if context.make_upper_case(out_args[6]) == "HEAT EXCHANGER:DESICCANT:BALANCED:PERFORMANCE DATA TYPE 1":
                                        nodiff = False
                                        out_args[6] = "HEAT EXCHANGER:DESICCANT:BALANCEDFLOW:PERFORMANCE DATA TYPE 1"
                                    else:
                                        nodiff = True
                                
                                elif obj_upper == "COMPRESSOR RACK:REFRIGERATED CASE":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:7] = in_args[0:7]
                                    for i in range(8, 16):
                                        out_args[i] = ""
                                    for i in range(16, cur_args + 8):
                                        out_args[i] = in_args[i - 8]
                                    cur_args = cur_args + 8
                                    nodiff = False
                                
                                elif obj_upper == "DOMESTIC HOT WATER":
                                    if in_args[1] != "" or in_args[2] != "":
                                        nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                            context.get_new_object_def_in_idd("WATER USE CONNECTIONS")
                                        out_args[0] = in_args[0]
                                        out_args[1:3] = in_args[1:3]
                                        out_args[3:6] = ["", "", ""]
                                        out_args[6] = in_args[5]
                                        out_args[7:10] = ["", "", ""]
                                        out_args[10] = in_args[0]
                                        cur_args = 11
                                        context.write_out_idf_lines(
                                            dif_file, "WATER USE CONNECTIONS", cur_args, out_args,
                                            nw_fld_names, nw_fld_units
                                        )
                                    
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd("WATER USE EQUIPMENT")
                                    out_args[0] = in_args[0]
                                    out_args[1] = in_args[6]
                                    out_args[2] = in_args[3]
                                    out_args[3] = in_args[4]
                                    out_args[4:6] = ["", ""]
                                    out_args[6] = in_args[5]
                                    cur_args = 7
                                    context.write_out_idf_lines(
                                        dif_file, "WATER USE EQUIPMENT", cur_args, out_args,
                                        nw_fld_names, nw_fld_units
                                    )
                                    written = True
                                
                                elif obj_upper == "BRANCH":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    for arg in range(2, cur_args, 5):
                                        if context.make_upper_case(out_args[arg]) == "DOMESTIC HOT WATER":
                                            out_args[arg] = "Water Use Connections"
                                            nodiff = False
                                
                                elif obj_upper == "COMPACT HVAC:ZONE:FAN COIL":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:3] = in_args[0:3]
                                    out_args[3] = ""
                                    out_args[4] = in_args[3]
                                    out_args[5] = in_args[4] if context.make_upper_case(in_args[3]) == "FLOW/PERSON" else "0.0"
                                    out_args[6] = in_args[4] if context.make_upper_case(in_args[3]) == "FLOW/AREA" else "0.0"
                                    out_args[7] = in_args[4] if context.make_upper_case(in_args[3]) == "FLOW/ZONE" else "0.0"
                                    out_args[8:19] = in_args[5:16]
                                    cur_args = 19
                                
                                elif obj_upper == "COMPACT HVAC:ZONE:UNITARY":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:4] = in_args[0:4]
                                    out_args[4] = ""
                                    out_args[5] = in_args[4]
                                    out_args[6] = in_args[5] if context.make_upper_case(in_args[4]) == "FLOW/PERSON" else "0.0"
                                    out_args[7] = in_args[5] if context.make_upper_case(in_args[4]) == "FLOW/AREA" else "0.0"
                                    out_args[8] = in_args[5] if context.make_upper_case(in_args[4]) == "FLOW/ZONE" else "0.0"
                                    out_args[9:11] = in_args[6:8]
                                    out_args[11:14] = nw_fld_defaults[11:14]
                                    cur_args = 14
                                
                                elif obj_upper == "COMPACT HVAC:ZONE:VAV":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:4] = in_args[0:4]
                                    out_args[4] = ""
                                    out_args[5] = in_args[4]
                                    out_args[6] = in_args[5]
                                    out_args[7] = in_args[6] if context.make_upper_case(in_args[5]) == "FLOW/PERSON" else "0.0"
                                    out_args[8] = in_args[6] if context.make_upper_case(in_args[5]) == "FLOW/AREA" else "0.0"
                                    out_args[9] = in_args[6] if context.make_upper_case(in_args[5]) == "FLOW/ZONE" else "0.0"
                                    out_args[10:15] = in_args[7:12]
                                    out_args[15:18] = nw_fld_defaults[15:18]
                                    cur_args = 18
                                
                                elif obj_upper == "COMPACT HVAC:ZONE:VAV:FAN POWERED":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:4] = in_args[0:4]
                                    out_args[4] = ""
                                    out_args[5:10] = in_args[4:9]
                                    out_args[10] = in_args[9] if context.make_upper_case(in_args[8]) == "FLOW/PERSON" else "0.0"
                                    out_args[11] = in_args[9] if context.make_upper_case(in_args[8]) == "FLOW/AREA" else "0.0"
                                    out_args[12] = in_args[9] if context.make_upper_case(in_args[8]) == "FLOW/ZONE" else "0.0"
                                    out_args[13:20] = in_args[10:17]
                                    out_args[20:23] = nw_fld_defaults[20:23]
                                    cur_args = 23
                                
                                elif obj_upper == "WATER HEATER:MIXED":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = True
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    if cur_args >= 31:
                                        out_args[0:39] = [""] * 39
                                        out_args[0:cur_args] = in_args[0:cur_args]
                                        out_args[36] = ""
                                        out_args[37] = ""
                                        out_args[38] = ""
                                        cur_args = 39
                                        nodiff = False
                                
                                elif obj_upper == "WATER HEATER:STRATIFIED":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = True
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    if cur_args >= 37:
                                        out_args[0:57] = [""] * 57
                                        out_args[0:48] = in_args[0:48]
                                        out_args[48] = ""
                                        out_args[49] = ""
                                        out_args[50] = ""
                                        for i in range(51, cur_args + 3):
                                            if i - 3 < len(in_args):
                                                out_args[i] = in_args[i - 3]
                                        cur_args = cur_args + 3
                                        nodiff = False
                                
                                elif obj_upper == "WINDOWSHADINGCONTROL":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    nodiff = False
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    if context.same_string("InteriorNonInsulatingShade", in_args[1]):
                                        out_args[1] = "InteriorShade"
                                    if context.same_string("ExteriorNonInsulatingShade", in_args[1]):
                                        out_args[1] = "ExteriorShade"
                                    if context.same_string("InteriorInsulatingShade", in_args[1]):
                                        out_args[1] = "InteriorShade"
                                    if context.same_string("ExteriorInsulatingShade", in_args[1]):
                                        out_args[1] = "ExteriorShade"
                                    if context.same_string("Schedule", in_args[3]):
                                        out_args[3] = "OnIfScheduleAllows"
                                    if context.same_string("SolarOnWindow", in_args[3]):
                                        out_args[3] = "OnIfHighSolarOnWindow"
                                    if context.same_string("HorizontalSolar", in_args[3]):
                                        out_args[3] = "OnIfHighHorizontalSolar"
                                    if context.same_string("OutsideAirTemp", in_args[3]):
                                        out_args[3] = "OnIfHighOutsideAirTemp"
                                    if context.same_string("ZoneAirTemp", in_args[3]):
                                        out_args[3] = "OnIfHighZoneAirTemp"
                                    if context.same_string("ZoneCooling", in_args[3]):
                                        out_args[3] = "OnIfHighZoneCooling"
                                    if context.same_string("Glare", in_args[3]):
                                        out_args[3] = "OnIfHighGlare"
                                    if context.same_string("DaylightIlluminance", in_args[3]):
                                        out_args[3] = "MeetDaylightIlluminanceSetpoint"
                                
                                elif obj_upper == "REPORT VARIABLE":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == "":
                                        out_args[0] = "*"
                                        nodiff = False
                                    del_this, checkrvi, nodiff, cur_args, written = context.scan_output_variables_for_replacement(
                                        2, True, False, False, cur_args, object_name, dif_file, out_args
                                    )
                                    if del_this:
                                        continue
                                
                                elif obj_upper in ("REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"):
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    del_this, checkrvi, nodiff, cur_args, written = context.scan_output_variables_for_replacement(
                                        1, False, True, False, cur_args, object_name, dif_file, out_args
                                    )
                                    if del_this:
                                        continue
                                
                                elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == "":
                                        out_args[0] = "*"
                                        nodiff = False
                                    del_this, checkrvi, nodiff, cur_args, written = context.scan_output_variables_for_replacement(
                                        2, False, False, True, cur_args, object_name, dif_file, out_args
                                    )
                                    if del_this:
                                        continue
                                
                                elif obj_upper == "REPORT:TABLE:MONTHLY":
                                    nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        context.get_new_object_def_in_idd(object_name)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    nodiff = True
                                    if out_args[0] == "":
                                        out_args[0] = "*"
                                        nodiff = False
                                    cur_var = 3
                                    for var in range(3, cur_args, 2):
                                        uc_rep_var_name = context.make_upper_case(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                        pos = uc_rep_var_name.find("[")
                                        if pos > 0:
                                            uc_rep_var_name = uc_rep_var_name[:pos]
                                            out_args[cur_var] = in_args[var][:pos]
                                            out_args[cur_var + 1] = in_args[var + 1]
                                        del_this = False
                                        for arg in range(context.num_rep_var_names):
                                            uc_comp_rep_var_name = context.make_upper_case(context.old_rep_var_name[arg])
                                            wild_match = False
                                            if uc_comp_rep_var_name[-1] == "*":
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + " "
                                            pos = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                            if pos > 0 and pos != 1:
                                                continue
                                            if pos == 0:
                                                if context.new_rep_var_name[arg] != "<DELETE>":
                                                    if not wild_match:
                                                        out_args[cur_var] = context.new_rep_var_name[arg]
                                                    else:
                                                        out_args[cur_var] = context.new_rep_var_name[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                                else:
                                                    del_this = True
                                                if arg < context.num_rep_var_names - 1 and context.old_rep_var_name[arg] == context.old_rep_var_name[arg + 1]:
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        out_args[cur_var] = context.new_rep_var_name[arg + 1]
                                                    else:
                                                        out_args[cur_var] = context.new_rep_var_name[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                                if arg < context.num_rep_var_names - 2 and context.old_rep_var_name[arg] == context.old_rep_var_name[arg + 2]:
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        out_args[cur_var] = context.new_rep_var_name[arg + 2]
                                                    else:
                                                        out_args[cur_var] = context.new_rep_var_name[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    nodiff = False
                                                break
                                        if not del_this:
                                            cur_var = cur_var + 2
                                    cur_args = cur_var - 1
                                
                                else:
                                    if context.find_item_in_list(object_name, context.not_in_new) != 0:
                                        print(
                                            f'Object="{object_name}" is not in the "new" IDD.',
                                            file=context.auditf
                                        )
                                        print(
                                            "... will be listed as comments on the new output file.",
                                            file=context.auditf
                                        )
                                        context.write_out_idf_lines_as_comments(
                                            dif_file, object_name, cur_args, in_args,
                                            fld_names, fld_units
                                        )
                                        written = True
                                    else:
                                        nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                            context.get_new_object_def_in_idd(object_name)
                                        out_args[0:cur_args] = in_args[0:cur_args]
                                        nodiff = True
                            else:
                                nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    context.get_new_object_def_in_idd(context.idf_records[num].Name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                            
                            if diff_min_fields and nodiff:
                                nw_num_args, nw_aor_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    context.get_new_object_def_in_idd(object_name)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                nodiff = False
                                for arg in range(cur_args, nw_obj_min_flds):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = max(nw_obj_min_flds, cur_args)
                            
                            if nodiff and diff_only:
                                continue
                            
                            if not written:
                                written = context.check_special_objects(
                                    dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                                )
                            
                            if not written:
                                context.write_out_idf_lines(
                                    dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                                )
                        
                        if context.num_idf_records > 0:
                            if context.idf_records[context.num_idf_records - 1].CommtE != context.cur_comment:
                                for xcount in range(
                                    context.idf_records[context.num_idf_records - 1].CommtE + 1,
                                    context.cur_comment + 1
                                ):
                                    dif_file.write(context.comments[xcount] + "\n")
                                    if xcount == context.idf_records[context.num_idf_records - 1].CommtE:
                                        dif_file.write("\n")
                    
                    if checkrvi:
                        context.process_rvi_mvi_files(file_name_path, "rvi")
                        context.process_rvi_mvi_files(file_name_path, "mvi")
                    context.close_out()
                else:
                    context.process_rvi_mvi_files(file_name_path, "rvi")
                    context.process_rvi_mvi_files(file_name_path, "mvi")
            else:
                end_of_file = True
            
            context.create_new_name("Reallocate", "", " ")
        
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
        err_flag = context.copy_file(
            file_name_path + "." + arg_idf_extension,
            file_name_path + "." + arg_idf_extension + "old"
        )
        err_flag = context.copy_file(
            file_name_path + "." + arg_idf_extension + "new",
            file_name_path + "." + arg_idf_extension
        )
        if os.path.exists(file_name_path + ".rvi"):
            context.copy_file(
                file_name_path + ".rvi",
                file_name_path + ".rviold"
            )
        if os.path.exists(file_name_path + ".rvinew"):
            context.copy_file(
                file_name_path + ".rvinew",
                file_name_path + ".rvi"
            )
        if os.path.exists(file_name_path + ".mvi"):
            context.copy_file(
                file_name_path + ".mvi",
                file_name_path + ".mviold"
            )
        if os.path.exists(file_name_path + ".mvinew"):
            context.copy_file(
                file_name_path + ".mvinew",
                file_name_path + ".mvi"
            )
    
    return end_of_file
