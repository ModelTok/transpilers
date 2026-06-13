# EXTERNAL DEPS (to wire in glue):
# - get_new_unit_number() from InputProcessor
# - process_input() from InputProcessor
# - find_item_in_list(), make_lower_case(), make_upper_case() from General
# - get_object_def_in_idd(), get_new_object_def_in_idd() from InputProcessor
# - same_string() from General
# - scan_output_variables_for_replacement() from VCompareGlobalRoutines
# - write_out_idf_lines_as_comments() from VCompareGlobalRoutines
# - check_special_objects() from VCompareGlobalRoutines
# - write_out_idf_lines() from VCompareGlobalRoutines
# - get_num_sections_found() from InputProcessor
# - process_rvi_mvi_files() from VCompareGlobalRoutines
# - close_out() from VCompareGlobalRoutines
# - create_new_name() from VCompareGlobalRoutines
# - copyfile() from system utilities
# - show_warning_error(), show_message() from DataGlobals
# - write_preprocessor_object() from VCompareGlobalRoutines
# - data_string_globals.prog_name_conversion
# - data_v_compare_globals: all shared state variables

from typing import Protocol, List, Dict, Optional, Any
from dataclasses import dataclass, field
import sys


@dataclass
class GlobalState:
    """External shared state from modules and COMMON blocks"""
    ver_string: str = ""
    version_num: float = 0.0
    idd_file_name_with_path: str = ""
    new_idd_file_name_with_path: str = ""
    rep_var_file_name_with_path: str = ""
    full_file_name: str = ""
    auditf: Any = None
    program_path: str = ""
    file_ok: bool = False
    file_name_path: str = ""
    processing_imf_file: bool = False
    fatal_error: bool = False
    num_idf_records: int = 0
    idf_records: List[Any] = field(default_factory=list)
    comments: List[str] = field(default_factory=list)
    cur_comment: int = 0
    alphas: List[str] = field(default_factory=list)
    numbers: List[float] = field(default_factory=list)
    in_args: List[str] = field(default_factory=list)
    a_or_n: List[bool] = field(default_factory=list)
    req_fld: List[bool] = field(default_factory=list)
    fld_names: List[str] = field(default_factory=list)
    fld_defaults: List[str] = field(default_factory=list)
    fld_units: List[str] = field(default_factory=list)
    nw_a_or_n: List[bool] = field(default_factory=list)
    nw_req_fld: List[bool] = field(default_factory=list)
    nw_fld_names: List[str] = field(default_factory=list)
    nw_fld_defaults: List[str] = field(default_factory=list)
    nw_fld_units: List[str] = field(default_factory=list)
    out_args: List[str] = field(default_factory=list)
    match_arg: List[int] = field(default_factory=list)
    object_def: List[Any] = field(default_factory=list)
    num_object_defs: int = 0
    not_in_new: List[str] = field(default_factory=list)
    old_rep_var_name: List[str] = field(default_factory=list)
    new_rep_var_name: List[str] = field(default_factory=list)
    new_rep_var_caution: List[str] = field(default_factory=list)
    num_rep_var_names: int = 0
    otm_var_caution: List[bool] = field(default_factory=list)
    cmtr_var_caution: List[bool] = field(default_factory=list)
    cmtr_d_var_caution: List[bool] = field(default_factory=list)
    max_alpha_args_found: int = 0
    max_numeric_args_found: int = 0
    max_total_args: int = 0
    making_pretty: bool = False


class ExternalFunctions(Protocol):
    """External functions to be provided"""
    def get_new_unit_number(self) -> int: ...
    def process_input(self, idd_file: str, new_idd_file: str, idf_file: str) -> None: ...
    def find_item_in_list(self, item: str, list_items: List[str], size: int) -> int: ...
    def make_lower_case(self, input_str: str) -> str: ...
    def make_upper_case(self, input_str: str) -> str: ...
    def get_object_def_in_idd(self, obj_name: str, num_args: List[int], a_or_n: List[bool],
                              req_fld: List[bool], obj_min_flds: List[int], fld_names: List[str],
                              fld_defaults: List[str], fld_units: List[str]) -> None: ...
    def get_new_object_def_in_idd(self, obj_name: str, num_args: List[int], a_or_n: List[bool],
                                  req_fld: List[bool], obj_min_flds: List[int], fld_names: List[str],
                                  fld_defaults: List[str], fld_units: List[str]) -> None: ...
    def same_string(self, str1: str, str2: str) -> bool: ...
    def scan_output_variables_for_replacement(self, var_idx: int, del_this: List[bool],
                                             check_rvi: List[bool], nodiff: List[bool],
                                             obj_name: str, dif_lfn: Any, out_var: bool,
                                             mtr_var: bool, time_bin_var: bool, cur_args: List[int],
                                             written: List[bool], is_sensor: bool) -> None: ...
    def write_out_idf_lines_as_comments(self, dif_lfn: Any, obj_name: str, cur_args: int,
                                       out_args: List[str], fld_names: List[str],
                                       fld_units: List[str]) -> None: ...
    def check_special_objects(self, dif_lfn: Any, obj_name: str, cur_args: int,
                             out_args: List[str], nw_fld_names: List[str],
                             nw_fld_units: List[str], written: List[bool]) -> None: ...
    def write_out_idf_lines(self, dif_lfn: Any, obj_name: str, cur_args: int,
                           out_args: List[str], nw_fld_names: List[str],
                           nw_fld_units: List[str]) -> None: ...
    def get_num_sections_found(self, section_name: str) -> int: ...
    def process_rvi_mvi_files(self, file_name_path: str, ext: str) -> None: ...
    def close_out(self) -> None: ...
    def create_new_name(self, action: str, created_name: List[str], dummy: str) -> None: ...
    def copyfile(self, src: str, dst: str) -> None: ...
    def show_warning_error(self, msg: str, auditf: Any) -> None: ...
    def show_message(self, msg: str) -> None: ...
    def write_preprocessor_object(self, dif_lfn: Any, prog_name: str, level: str, msg: str) -> None: ...


def set_version_variables(state: GlobalState) -> None:
    """SetThisVersionVariables subroutine"""
    state.ver_string = 'Conversion 7.1 => 7.2'
    state.version_num = 7.2
    state.idd_file_name_with_path = state.program_path.rstrip() + 'V7-1-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V7-2-0-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 7-1-0-012 to 7-2-0.csv'


def create_new_idf_using_rules(
    state: GlobalState,
    extern: ExternalFunctions,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    prog_name_conversion: str
) -> None:
    """CreateNewIDFUsingRules subroutine"""
    
    blank = ""
    first_time = True
    
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
                print('Enter input file name, with path')
                state.full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        state.full_file_name = input()
                        ios = 0
                    except EOFError:
                        ios = 1
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = blank
                    ios = 1
                
                if state.full_file_name and state.full_file_name[0] == '!':
                    state.full_file_name = blank
                    continue
            
            if ios != 0:
                state.full_file_name = blank
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name != blank:
                # Found file name
                dot_pos = state.full_file_name.rfind('.')
                
                if dot_pos != -1:
                    state.file_name_path = state.full_file_name[:dot_pos]
                    local_file_extension = extern.make_lower_case(state.full_file_name[dot_pos+1:])
                else:
                    state.file_name_path = state.full_file_name
                    state.full_file_name = state.full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                # Process the old input
                dif_lfn = extern.get_new_unit_number()
                
                try:
                    with open(state.full_file_name, 'r'):
                        state.file_ok = True
                except FileNotFoundError:
                    state.file_ok = False
                
                if not state.file_ok:
                    print(f'File not found={state.full_file_name}')
                    if state.auditf:
                        state.auditf.write(f'File not found={state.full_file_name}\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file_name = f"{state.file_name_path}.{local_file_extension}dif"
                    else:
                        dif_file_name = f"{state.file_name_path}.{local_file_extension}new"
                    
                    dif_file = open(dif_file_name, 'w')
                    
                    if local_file_extension == 'imf':
                        extern.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    extern.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, state.full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        dif_file.close()
                        break
                    
                    # Allocate arrays
                    state.alphas = [blank] * state.max_alpha_args_found
                    state.numbers = [0.0] * state.max_numeric_args_found
                    state.in_args = [blank] * state.max_total_args
                    state.a_or_n = [False] * state.max_total_args
                    state.req_fld = [False] * state.max_total_args
                    state.fld_names = [blank] * state.max_total_args
                    state.fld_defaults = [blank] * state.max_total_args
                    state.fld_units = [blank] * state.max_total_args
                    state.nw_a_or_n = [False] * state.max_total_args
                    state.nw_req_fld = [False] * state.max_total_args
                    state.nw_fld_names = [blank] * state.max_total_args
                    state.nw_fld_defaults = [blank] * state.max_total_args
                    state.nw_fld_units = [blank] * state.max_total_args
                    state.out_args = [blank] * state.max_total_args
                    state.match_arg = [0] * state.max_total_args
                    delete_this_record = [False] * state.num_idf_records
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if extern.make_upper_case(state.idf_records[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            dif_file.write(f'! Deleting: {state.idf_records[num].Name}:{state.idf_records[num].Alphas[0]}\n')
                    
                    for num in range(state.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.idf_records[num].CommtS, state.idf_records[num].CommtE):
                            dif_file.write(state.comments[xcount] + '\n')
                            if xcount == state.idf_records[num].CommtE - 1:
                                dif_file.write(' \n')
                        
                        if no_version and num == 0:
                            nw_num_args = [0]
                            nw_a_or_n_local = [False] * state.max_total_args
                            nw_req_fld_local = [False] * state.max_total_args
                            nw_obj_min_flds = [0]
                            nw_fld_names_local = [blank] * state.max_total_args
                            nw_fld_defaults_local = [blank] * state.max_total_args
                            nw_fld_units_local = [blank] * state.max_total_args
                            
                            extern.get_new_object_def_in_idd('VERSION', nw_num_args, nw_a_or_n_local,
                                                             nw_req_fld_local, nw_obj_min_flds,
                                                             nw_fld_names_local, nw_fld_defaults_local,
                                                             nw_fld_units_local)
                            state.out_args[0] = '7.2.0.002'
                            cur_args = 1
                            extern.write_out_idf_lines_as_comments(dif_file, 'Version', cur_args,
                                                                   state.out_args, nw_fld_names_local,
                                                                   nw_fld_units_local)
                        
                        # Deleted objects
                        obj_upper = extern.make_upper_case(state.idf_records[num].Name.rstrip())
                        if obj_upper in ['SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL',
                                        'GENERATOR:FC:BATTERY DATA', 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                            continue
                        
                        if obj_upper == 'WATER HEATER:SIMPLE':
                            dif_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        object_name = state.idf_records[num].Name
                        
                        if extern.find_item_in_list(object_name, [obj.Name for obj in state.object_def],
                                                   state.num_object_defs) != 0:
                            # Object found in old IDD
                            num_args = [0]
                            a_or_n_local = [False] * state.max_total_args
                            req_fld_local = [False] * state.max_total_args
                            obj_min_flds = [0]
                            fld_names_local = [blank] * state.max_total_args
                            fld_defaults_local = [blank] * state.max_total_args
                            fld_units_local = [blank] * state.max_total_args
                            
                            extern.get_object_def_in_idd(object_name, num_args, a_or_n_local,
                                                         req_fld_local, obj_min_flds, fld_names_local,
                                                         fld_defaults_local, fld_units_local)
                            
                            num_alphas = state.idf_records[num].NumAlphas
                            num_numbers = state.idf_records[num].NumNumbers
                            state.alphas[:num_alphas] = state.idf_records[num].Alphas[:num_alphas]
                            state.numbers[:num_numbers] = state.idf_records[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            state.in_args = [blank] * state.max_total_args
                            state.out_args = [blank] * state.max_total_args
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if a_or_n_local[arg]:
                                    state.in_args[arg] = state.alphas[na]
                                    na += 1
                                else:
                                    state.in_args[arg] = str(state.numbers[nn])
                                    nn += 1
                        else:
                            # Object not in old IDD
                            num_alphas = state.idf_records[num].NumAlphas
                            num_numbers = state.idf_records[num].NumNumbers
                            state.alphas[:num_alphas] = state.idf_records[num].Alphas[:num_alphas]
                            state.numbers[:num_numbers] = state.idf_records[num].Numbers[:num_numbers]
                            
                            for arg in range(num_alphas):
                                state.out_args[arg] = state.alphas[arg]
                            
                            nn = num_alphas
                            for arg in range(num_numbers):
                                state.out_args[nn] = str(state.numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            state.nw_fld_names = [blank] * state.max_total_args
                            state.nw_fld_units = [blank] * state.max_total_args
                            extern.write_out_idf_lines_as_comments(dif_file, object_name, cur_args,
                                                                   state.out_args, state.nw_fld_names,
                                                                   state.nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if extern.find_item_in_list(extern.make_upper_case(object_name),
                                                   state.not_in_new, len(state.not_in_new)) == 0:
                            nw_num_args = [0]
                            nw_a_or_n_local = [False] * state.max_total_args
                            nw_req_fld_local = [False] * state.max_total_args
                            nw_obj_min_flds = [0]
                            nw_fld_names_local = [blank] * state.max_total_args
                            nw_fld_defaults_local = [blank] * state.max_total_args
                            nw_fld_units_local = [blank] * state.max_total_args
                            
                            extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                             nw_a_or_n_local, nw_req_fld_local,
                                                             nw_obj_min_flds, nw_fld_names_local,
                                                             nw_fld_defaults_local, nw_fld_units_local)
                            
                            if obj_min_flds[0] != nw_obj_min_flds[0]:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        # Main transformation logic
                        if not state.making_pretty:
                            obj_upper = extern.make_upper_case(state.idf_records[num].Name.rstrip())
                            
                            if obj_upper == 'VERSION':
                                if state.in_args[0][:3] == '7.2' and arg_file:
                                    extern.show_warning_error('File is already at latest version.  No new diff file made.', state.auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[0] = '7.2'
                                nodiff = False
                            
                            elif obj_upper == 'COIL:COOLING:DX:TWOSPEED':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:6] = state.in_args[:6]
                                state.out_args[6] = blank
                                state.out_args[7:cur_args+1] = state.in_args[6:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'EXTERNALINTERFACE':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                if extern.same_string(state.out_args[0], 'FunctionalMockupUnit'):
                                    state.out_args[0] = 'FunctionalMockupUnitImport'
                            
                            elif obj_upper == 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNIT':
                                nodiff = False
                                object_name = 'ExternalInterface:FunctionalMockupUnitImport'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                            
                            elif obj_upper == 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNIT:FROM:VARIABLE':
                                nodiff = False
                                object_name = 'ExternalInterface:FunctionalMockupUnitImport:From:Variable'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                if state.out_args[0] == blank:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    False, False, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNIT:TO:SCHEDULE':
                                nodiff = False
                                object_name = 'ExternalInterface:FunctionalMockupUnitImport:To:Schedule'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                            
                            elif obj_upper == 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNIT:TO:ACTUATOR':
                                nodiff = False
                                object_name = 'ExternalInterface:FunctionalMockupUnitImport:To:Actuator'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                            
                            elif obj_upper == 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNIT:TO:VARIABLE':
                                nodiff = False
                                object_name = 'ExternalInterface:FunctionalMockupUnitImport:To:Variable'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                if state.out_args[0] == blank:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    False, False, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == 'WINDOWMATERIAL:GAS':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                
                                if cur_args >= 5:
                                    cur_args = cur_args + 1
                                    state.out_args[:5] = state.in_args[:5]
                                    state.out_args[5] = '0.0'
                                else:
                                    state.out_args[:cur_args] = state.in_args[:cur_args]
                                
                                if cur_args > 6:
                                    cur_args = cur_args + 1
                                    state.out_args[6:8] = state.in_args[5:7]
                                    state.out_args[8] = '0.0'
                                
                                if cur_args > 9:
                                    cur_args = cur_args + 1
                                    state.out_args[9:11] = state.in_args[7:9]
                                    state.out_args[11] = '0.0'
                                
                                if cur_args >= 13:
                                    state.out_args[12] = state.in_args[9]
                                if cur_args >= 14:
                                    state.out_args[13] = state.in_args[10]
                            
                            elif obj_upper == 'COIL:COOLING:DX:MULTISPEED':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                
                                state.out_args[:21] = state.in_args[:21]
                                state.out_args[21] = blank
                                state.out_args[22:40] = state.in_args[21:39]
                                state.out_args[40] = blank
                                state.out_args[41:55] = state.in_args[39:53]
                                
                                if cur_args > 53:
                                    state.out_args[55:59] = state.in_args[53:57]
                                    state.out_args[59] = blank
                                    state.out_args[60:74] = state.in_args[57:71]
                                
                                if cur_args > 71:
                                    state.out_args[74:78] = state.in_args[71:75]
                                    state.out_args[78] = blank
                                    state.out_args[79:93] = state.in_args[75:89]
                                    cur_args = cur_args + 4
                                else:
                                    if cur_args > 53:
                                        cur_args = cur_args + 3
                                    else:
                                        cur_args = cur_args + 2
                            
                            elif obj_upper == 'SIZING:ZONE':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                
                                state.out_args[0] = state.in_args[0]
                                state.out_args[1] = 'SupplyAirTemperature'
                                state.out_args[2] = state.in_args[1]
                                state.out_args[3] = blank
                                state.out_args[4] = 'SupplyAirTemperature'
                                state.out_args[5] = state.in_args[2]
                                state.out_args[6] = blank
                                state.out_args[7:cur_args+4] = state.in_args[3:cur_args]
                                cur_args = cur_args + 4
                            
                            elif obj_upper == 'ZONECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:CONSTANT':
                                nodiff = False
                                object_name = 'ZoneContaminantSourceAndSink:Generic:Constant'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'SURFACECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:PRESSUREDRIVEN':
                                nodiff = False
                                object_name = 'SurfaceContaminantSourceAndSink:Generic:PressureDriven'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'ZONECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:CUTOFFMODEL':
                                nodiff = False
                                object_name = 'ZoneContaminantSourceAndSink:Generic:CutoffModel'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'ZONECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:DECAYSOURCE':
                                nodiff = False
                                object_name = 'ZoneContaminantSourceAndSink:Generic:DecaySource'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'SURFACECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:BOUDARYLAYERDIFFUSION':
                                nodiff = False
                                object_name = 'SurfaceContaminantSourceAndSink:Generic:BoundaryLayerDiffusion'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'SURFACECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:DEPOSITIONVELOCITYSINK':
                                nodiff = False
                                object_name = 'SurfaceContaminantSourceAndSink:Generic:DepositionVelocitySink'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'ZONECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT:DEPOSITIONRATESINK':
                                nodiff = False
                                object_name = 'ZoneContaminantSourceAndSink:Generic:DepositionRateSink'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                            
                            elif obj_upper == 'CONSTRUCTIONPROPERTY:USEHBALGORITHMCONDFDDETAILED':
                                nodiff = False
                                object_name = 'SurfaceProperty:HeatTransferAlgorithm:Construction'
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[0] = blank
                                state.out_args[1] = 'ConductionFiniteDifference'
                                state.out_args[2] = state.in_args[0]
                                cur_args = 3
                            
                            elif obj_upper == 'HEATBALANCEALGORITHM':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                
                                if extern.same_string(state.in_args[0], 'ConductionFiniteDifferenceSimplified'):
                                    state.out_args[0] = 'ConductionTransferFunction'
                                else:
                                    nodiff = True
                            
                            elif obj_upper == 'AIRCONDITIONER:VARIABLEREFRIGERANTFLOW':
                                nodiff = False
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                
                                state.out_args[:17] = state.in_args[:17]
                                state.out_args[17] = blank
                                
                                if cur_args <= 55:
                                    state.out_args[18:cur_args+1] = state.in_args[17:cur_args]
                                    cur_args = cur_args + 1
                                else:
                                    state.out_args[18:56] = state.in_args[17:55]
                                    state.out_args[56] = state.in_args[55]
                                    state.out_args[57] = blank
                                    state.out_args[58] = blank
                                    state.out_args[59:cur_args+4] = state.in_args[56:cur_args]
                                    cur_args = cur_args + 4
                            
                            elif obj_upper == 'OUTPUT:VARIABLE':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                if state.out_args[0] == blank:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    True, False, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY',
                                             'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    1, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    False, True, False, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                if state.out_args[0] == blank:
                                    state.out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    False, False, True, [cur_args], [written], False)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                
                                del_this = [False]
                                extern.scan_output_variables_for_replacement(
                                    3, del_this, [check_rvi], [nodiff], object_name, dif_file,
                                    False, False, False, [cur_args], [written], True)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                nodiff = True
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                cur_var = 3
                                
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = extern.make_upper_case(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos != -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    del_this = False
                                    
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = extern.make_upper_case(state.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not state.otm_var_caution[arg]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Output Table Monthly (old)="{state.old_rep_var_name[arg]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg]}" has the following caution "{state.new_rep_var_caution[arg]}".')
                                                        dif_file.write(' \n')
                                                        state.otm_var_caution[arg] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.num_rep_var_names - 1 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+1]:
                                                if not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg+1]:
                                                        if not state.otm_var_caution[arg+1]:
                                                            extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                                f'Output Table Monthly (old)="{state.old_rep_var_name[arg]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg+1]}" has the following caution "{state.new_rep_var_caution[arg+1]}".')
                                                            dif_file.write(' \n')
                                                            state.otm_var_caution[arg+1] = True
                                                    
                                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                                    nodiff = False
                                            
                                            if arg < state.num_rep_var_names - 2 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg+2]:
                                                    if not state.otm_var_caution[arg+2]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Output Table Monthly (old)="{state.old_rep_var_name[arg]}" conversion to Output Table Monthly (new)="{state.new_rep_var_name[arg+2]}" has the following caution "{state.new_rep_var_caution[arg+2]}".')
                                                        dif_file.write(' \n')
                                                        state.otm_var_caution[arg+2] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                    
                                    var = var + 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_upper == 'METER:CUSTOM':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                cur_var = 4
                                
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = extern.make_upper_case(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos != -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    del_this = False
                                    
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = extern.make_upper_case(state.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not state.cmtr_var_caution[arg]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Custom Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg]}" has the following caution "{state.new_rep_var_caution[arg]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_var_caution[arg] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.num_rep_var_names - 1 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+1]:
                                                if not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg+1] and not extern.same_string(state.new_rep_var_caution[arg+1][:6], 'Forkeq'):
                                                        if not state.cmtr_var_caution[arg+1]:
                                                            extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                                f'Custom Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg+1]}" has the following caution "{state.new_rep_var_caution[arg+1]}".')
                                                            dif_file.write(' \n')
                                                            state.cmtr_var_caution[arg+1] = True
                                                    
                                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                                    nodiff = False
                                            
                                            if arg < state.num_rep_var_names - 2 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg+2]:
                                                    if not state.cmtr_var_caution[arg+2]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Custom Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg+2]}" has the following caution "{state.new_rep_var_caution[arg+2]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_var_caution[arg+2] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                    
                                    var = var + 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var, 0, -1):
                                    if state.out_args[arg-1] == blank:
                                        cur_args = cur_args - 1
                                    else:
                                        break
                            
                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args = [0]
                                nw_a_or_n_local = [False] * state.max_total_args
                                nw_req_fld_local = [False] * state.max_total_args
                                nw_obj_min_flds = [0]
                                nw_fld_names_local = [blank] * state.max_total_args
                                nw_fld_defaults_local = [blank] * state.max_total_args
                                nw_fld_units_local = [blank] * state.max_total_args
                                
                                extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                 nw_a_or_n_local, nw_req_fld_local,
                                                                 nw_obj_min_flds, nw_fld_names_local,
                                                                 nw_fld_defaults_local, nw_fld_units_local)
                                state.out_args[:cur_args] = state.in_args[:cur_args]
                                nodiff = True
                                cur_var = 4
                                
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = extern.make_upper_case(state.in_args[var])
                                    state.out_args[cur_var] = state.in_args[var]
                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos != -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        state.out_args[cur_var] = state.in_args[var][:pos]
                                        state.out_args[cur_var+1] = state.in_args[var+1]
                                    
                                    del_this = False
                                    
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = extern.make_upper_case(state.old_rep_var_name[arg])
                                        
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
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
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg] and not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not state.cmtr_d_var_caution[arg]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg]}" has the following caution "{state.new_rep_var_caution[arg]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_d_var_caution[arg] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.num_rep_var_names - 1 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+1]:
                                                if not extern.same_string(state.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var = cur_var + 2
                                                    if not wild_match:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1]
                                                    else:
                                                        state.out_args[cur_var] = state.new_rep_var_name[arg+1] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    
                                                    if state.new_rep_var_caution[arg+1] and not extern.same_string(state.new_rep_var_caution[arg+1][:6], 'Forkeq'):
                                                        if not state.cmtr_d_var_caution[arg+1]:
                                                            extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                                f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Decrement Meter (new)="{state.new_rep_var_name[arg+1]}" has the following caution "{state.new_rep_var_caution[arg+1]}".')
                                                            dif_file.write(' \n')
                                                            state.cmtr_d_var_caution[arg+1] = True
                                                    
                                                    state.out_args[cur_var+1] = state.in_args[var+1]
                                                    nodiff = False
                                            
                                            if arg < state.num_rep_var_names - 2 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg+2]:
                                                cur_var = cur_var + 2
                                                if not wild_match:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2]
                                                else:
                                                    state.out_args[cur_var] = state.new_rep_var_name[arg+2] + state.out_args[cur_var][len(uc_comp_rep_var_name):]
                                                
                                                if state.new_rep_var_caution[arg+2]:
                                                    if not state.cmtr_d_var_caution[arg+2]:
                                                        extern.write_preprocessor_object(dif_file, prog_name_conversion, 'Warning',
                                                            f'Custom Decrement Meter (old)="{state.old_rep_var_name[arg]}" conversion to Custom Meter (new)="{state.new_rep_var_name[arg+2]}" has the following caution "{state.new_rep_var_caution[arg+2]}".')
                                                        dif_file.write(' \n')
                                                        state.cmtr_d_var_caution[arg+2] = True
                                                
                                                state.out_args[cur_var+1] = state.in_args[var+1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var = cur_var + 2
                                    
                                    var = var + 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var, 0, -1):
                                    if state.out_args[arg-1] == blank:
                                        cur_args = cur_args - 1
                                    else:
                                        break
                            
                            else:
                                if extern.find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    extern.write_out_idf_lines_as_comments(dif_file, object_name, cur_args,
                                                                           state.in_args, state.fld_names, state.fld_units)
                                    written = True
                                else:
                                    nw_num_args = [0]
                                    nw_a_or_n_local = [False] * state.max_total_args
                                    nw_req_fld_local = [False] * state.max_total_args
                                    nw_obj_min_flds = [0]
                                    nw_fld_names_local = [blank] * state.max_total_args
                                    nw_fld_defaults_local = [blank] * state.max_total_args
                                    nw_fld_units_local = [blank] * state.max_total_args
                                    
                                    extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                                     nw_a_or_n_local, nw_req_fld_local,
                                                                     nw_obj_min_flds, nw_fld_names_local,
                                                                     nw_fld_defaults_local, nw_fld_units_local)
                                    state.out_args[:cur_args] = state.in_args[:cur_args]
                                    nodiff = True
                        
                        else:  # Making Pretty
                            nw_num_args = [0]
                            nw_a_or_n_local = [False] * state.max_total_args
                            nw_req_fld_local = [False] * state.max_total_args
                            nw_obj_min_flds = [0]
                            nw_fld_names_local = [blank] * state.max_total_args
                            nw_fld_defaults_local = [blank] * state.max_total_args
                            nw_fld_units_local = [blank] * state.max_total_args
                            
                            extern.get_new_object_def_in_idd(state.idf_records[num].Name, nw_num_args,
                                                             nw_a_or_n_local, nw_req_fld_local,
                                                             nw_obj_min_flds, nw_fld_names_local,
                                                             nw_fld_defaults_local, nw_fld_units_local)
                            state.out_args[:cur_args] = state.in_args[:cur_args]
                        
                        if diff_min_fields and nodiff:
                            nw_num_args = [0]
                            nw_a_or_n_local = [False] * state.max_total_args
                            nw_req_fld_local = [False] * state.max_total_args
                            nw_obj_min_flds = [0]
                            nw_fld_names_local = [blank] * state.max_total_args
                            nw_fld_defaults_local = [blank] * state.max_total_args
                            nw_fld_units_local = [blank] * state.max_total_args
                            
                            extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                             nw_a_or_n_local, nw_req_fld_local,
                                                             nw_obj_min_flds, nw_fld_names_local,
                                                             nw_fld_defaults_local, nw_fld_units_local)
                            state.out_args[:cur_args] = state.in_args[:cur_args]
                            nodiff = False
                            
                            for arg in range(cur_args, nw_obj_min_flds[0]):
                                state.out_args[arg] = nw_fld_defaults_local[arg]
                            
                            cur_args = max(nw_obj_min_flds[0], cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            extern.check_special_objects(dif_file, object_name, cur_args,
                                                        state.out_args, state.nw_fld_names,
                                                        state.nw_fld_units, [written])
                        
                        if not written:
                            extern.write_out_idf_lines(dif_file, object_name, cur_args,
                                                      state.out_args, state.nw_fld_names,
                                                      state.nw_fld_units)
                    
                    if state.idf_records[state.num_idf_records-1].CommtE != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records-1].CommtE, state.cur_comment):
                            dif_file.write(state.comments[xcount] + '\n')
                            if xcount == state.idf_records[num].CommtE - 1:
                                dif_file.write(' \n')
                    
                    if extern.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args = [0]
                        nw_a_or_n_local = [False] * state.max_total_args
                        nw_req_fld_local = [False] * state.max_total_args
                        nw_obj_min_flds = [0]
                        nw_fld_names_local = [blank] * state.max_total_args
                        nw_fld_defaults_local = [blank] * state.max_total_args
                        nw_fld_units_local = [blank] * state.max_total_args
                        
                        extern.get_new_object_def_in_idd(object_name, nw_num_args,
                                                         nw_a_or_n_local, nw_req_fld_local,
                                                         nw_obj_min_flds, nw_fld_names_local,
                                                         nw_fld_defaults_local, nw_fld_units_local)
                        nodiff = False
                        state.out_args[0] = 'Regular'
                        cur_args = 1
                        extern.write_out_idf_lines(dif_file, object_name, cur_args,
                                                  state.out_args, nw_fld_names_local,
                                                  nw_fld_units_local)
                    
                    dif_file.close()
                    extern.process_rvi_mvi_files(state.file_name_path, 'rvi')
                    extern.process_rvi_mvi_files(state.file_name_path, 'mvi')
                    extern.close_out()
                
                else:
                    extern.process_rvi_mvi_files(state.file_name_path, 'rvi')
                    extern.process_rvi_mvi_files(state.file_name_path, 'mvi')
            
            else:
                end_of_file[0] = True
            
            created_output_name = [blank]
            extern.create_new_name('Reallocate', created_output_name, ' ')
        
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
        src = f"{state.file_name_path}.{arg_idf_extension}"
        dst = f"{state.file_name_path}.{arg_idf_extension}old"
        extern.copyfile(src, dst)
        
        src = f"{state.file_name_path}.{arg_idf_extension}new"
        dst = f"{state.file_name_path}.{arg_idf_extension}"
        extern.copyfile(src, dst)
        
        rvi_file = f"{state.file_name_path}.rvi"
        try:
            with open(rvi_file, 'r'):
                src = rvi_file
                dst = f"{state.file_name_path}.rviold"
                extern.copyfile(src, dst)
        except FileNotFoundError:
            pass
        
        rvi_new_file = f"{state.file_name_path}.rvinew"
        try:
            with open(rvi_new_file, 'r'):
                src = rvi_new_file
                dst = f"{state.file_name_path}.rvi"
                extern.copyfile(src, dst)
        except FileNotFoundError:
            pass
        
        mvi_file = f"{state.file_name_path}.mvi"
        try:
            with open(mvi_file, 'r'):
                src = mvi_file
                dst = f"{state.file_name_path}.mviold"
                extern.copyfile(src, dst)
        except FileNotFoundError:
            pass
        
        mvi_new_file = f"{state.file_name_path}.mvinew"
        try:
            with open(mvi_new_file, 'r'):
                src = mvi_new_file
                dst = f"{state.file_name_path}.mvi"
                extern.copyfile(src, dst)
        except FileNotFoundError:
            pass
