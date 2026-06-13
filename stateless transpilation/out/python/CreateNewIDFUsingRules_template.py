from dataclasses import dataclass, field
from typing import Protocol, Callable, List, Optional, Dict, Any
from enum import Enum


# EXTERNAL DEPS (to wire in glue):
# - InputProcessor.ProcessInput(idd_old, idd_new, idf_file)
# - InputProcessor.GetNewObjectDefInIDD(obj_name) -> tuple(num_args, aorn, reqfld, min_flds, names, defaults, units)
# - InputProcessor.GetObjectDefInIDD(obj_name) -> tuple(num_args, aorn, reqfld, min_flds, names, defaults, units)
# - InputProcessor.FindItemInList(item, list, size) -> int
# - DataVCompareGlobals.IDFRecords: list of IDFRecord
# - DataVCompareGlobals.Comments: list of comment strings
# - DataVCompareGlobals.CurComment: int
# - DataVCompareGlobals.NumIDFRecords: int
# - DataVCompareGlobals.FatalError: bool
# - DataVCompareGlobals.ProcessingIMFFile: bool
# - VCompareGlobalRoutines.ScanOutputVariablesForReplacement(...)
# - VCompareGlobalRoutines.WriteOutIDFLinesAsComments(...)
# - VCompareGlobalRoutines.WriteOutIDFLines(...)
# - VCompareGlobalRoutines.CheckSpecialObjects(...)
# - VCompareGlobalRoutines.ProcessRviMviFiles(...)
# - VCompareGlobalRoutines.CloseOut()
# - VCompareGlobalRoutines.CreateNewName(...)
# - VCompareGlobalRoutines.writePreprocessorObject(...)
# - VCompareGlobalRoutines.GetNumSectionsFound(section_name) -> int
# - General.MakeUPPERCase(string) -> string
# - General.MakeLowerCase(string) -> string
# - General.SameString(s1, s2) -> bool
# - DataStringGlobals.Blank: str constant
# - DataStringGlobals.ProgramPath: str
# - DataStringGlobals.ProgNameConversion: str
# - DataGlobals.ShowWarningError(msg, auditf)
# - DataGlobals.ShowMessage(msg)
# - DataGlobals.ShowContinueError(msg)
# - DataGlobals.ShowFatalError(msg)
# - DataGlobals.ShowSevereError(msg)
# - General.GetNewUnitNumber() -> int
# - DataGlobals.TRIM(string) -> string
# - copyfile(src, dst, errflag) -> None
# - INQUIRE file existence check


@dataclass
class IDFRecord:
    name: str
    alphas: List[str] = field(default_factory=list)
    numbers: List[float] = field(default_factory=list)
    num_alphas: int = 0
    num_numbers: int = 0
    commt_s: int = 0
    commt_e: int = 0


@dataclass
class ObjectDefinition:
    name: str


class ExternalDependencies(Protocol):
    """Interface for external module dependencies."""
    
    idd_records: List[IDFRecord]
    comments: List[str]
    cur_comment: int
    num_idf_records: int
    fatal_error: bool
    processing_imf_file: bool
    
    program_path: str
    prog_name_conversion: str
    blank: str
    max_name_length: int
    max_alpha_args_found: int
    max_numeric_args_found: int
    max_total_args: int
    
    full_file_name: str
    file_name_path: str
    audit_f: int
    
    alphas: List[str]
    numbers: List[float]
    in_args: List[str]
    temp_args: List[str]
    out_args: List[str]
    a_or_n: List[bool]
    req_fld: List[bool]
    fld_names: List[str]
    fld_defaults: List[str]
    fld_units: List[str]
    
    nw_a_or_n: List[bool]
    nw_req_fld: List[bool]
    nw_fld_names: List[str]
    nw_fld_defaults: List[str]
    nw_fld_units: List[str]
    
    object_def: List[ObjectDefinition]
    num_object_defs: int
    not_in_new: List[str]
    
    old_rep_var_name: List[str]
    new_rep_var_name: List[str]
    new_rep_var_caution: List[str]
    num_rep_var_names: int
    
    otm_var_caution: List[bool]
    cmtr_var_caution: List[bool]
    cmtr_d_var_caution: List[bool]
    
    num_args: int
    obj_min_flds: int
    nw_num_args: int
    nw_obj_min_flds: int
    num_alphas: int
    num_numbers: int
    
    file_ok: bool
    
    def process_input(self, idd_old: str, idd_new: str, idf_file: str) -> None: ...
    def display_string(self, msg: str) -> None: ...
    def get_new_object_def_idd(self, obj_name: str) -> None: ...
    def get_object_def_idd(self, obj_name: str) -> None: ...
    def find_item_in_list(self, item: str, list_items: List[str]) -> int: ...
    def scan_output_variables_for_replacement(self, field_num: int, del_this: List[bool], 
                                              check_rvi: List[bool], nodiff: List[bool], 
                                              obj_name: str, dif_lfn: int, 
                                              out_var: bool, mtr_var: bool, time_bin_var: bool,
                                              cur_args: int, written: List[bool], sensor: bool) -> None: ...
    def write_out_idf_lines_as_comments(self, dif_lfn: int, obj_name: str, cur_args: int, 
                                        out_args: List[str], fld_names: List[str], 
                                        fld_units: List[str]) -> None: ...
    def write_out_idf_lines(self, dif_lfn: int, obj_name: str, cur_args: int, 
                            out_args: List[str], fld_names: List[str], 
                            fld_units: List[str]) -> None: ...
    def check_special_objects(self, dif_lfn: int, obj_name: str, cur_args: int, 
                              out_args: List[str], fld_names: List[str], 
                              fld_units: List[str], written: List[bool]) -> None: ...
    def process_rvi_mvi_files(self, file_name_path: str, extension: str) -> None: ...
    def close_out(self) -> None: ...
    def create_new_name(self, operation: str, output_name: List[str], filler: str) -> None: ...
    def write_preprocessor_object(self, dif_lfn: int, prog_name: str, msg_type: str, msg: str) -> None: ...
    def get_num_sections_found(self, section_name: str) -> int: ...
    def make_upper_case(self, s: str) -> str: ...
    def make_lower_case(self, s: str) -> str: ...
    def same_string(self, s1: str, s2: str) -> bool: ...
    def show_warning_error(self, msg: str, auditf: int) -> None: ...
    def show_message(self, msg: str) -> None: ...
    def show_continue_error(self, msg: str) -> None: ...
    def show_fatal_error(self, msg: str) -> None: ...
    def show_severe_error(self, msg: str) -> None: ...
    def get_new_unit_number(self) -> int: ...
    def trim(self, s: str) -> str: ...
    def copy_file(self, src: str, dst: str) -> bool: ...
    def file_exists(self, path: str) -> bool: ...


def set_this_version_variables(deps: ExternalDependencies) -> None:
    """Set version variables for this version transition."""
    deps.trim('Conversion 9.3 => 9.4')
    version_num = 9.4
    deps.blank
    sVersionNum = '***'
    sVersionNumFourChars = '23.2'
    idd_file_name_with_path = deps.trim(deps.program_path) + 'V9-3-0-Energy+.idd'
    new_idd_file_name_with_path = deps.trim(deps.program_path) + 'V9-4-0-Energy+.idd'
    rep_var_file_name_with_path = deps.trim(deps.program_path) + 'Report Variables 9-3-0 to 9-4-0.csv'


def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDependencies
) -> None:
    """Create new IDF using rules specified by developers."""
    
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    fmt_a = "(A)"
    
    delete_this_record = [False] * (deps.num_idf_records + 1)
    created_output_name = ['']
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                deps.full_file_name = input()
            else:
                if not arg_file:
                    try:
                        deps.full_file_name = input()
                    except EOFError:
                        ios = 1
                elif not arg_file_being_done:
                    deps.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    deps.full_file_name = deps.blank
                    ios = 1
                
                if deps.full_file_name and deps.full_file_name[0] == '!':
                    deps.full_file_name = deps.blank
                    continue
            
            if ios != 0:
                deps.full_file_name = deps.blank
            
            deps.full_file_name = deps.full_file_name.lstrip()
            
            if deps.full_file_name != deps.blank:
                deps.display_string('Processing IDF -- ' + deps.trim(deps.full_file_name))
                
                dot_pos = deps.full_file_name.rfind('.')
                if dot_pos != -1:
                    deps.file_name_path = deps.full_file_name[:dot_pos]
                    local_file_extension = deps.make_lower_case(deps.full_file_name[dot_pos+1:])
                else:
                    deps.file_name_path = deps.full_file_name
                    print(' assuming file extension of .idf')
                    deps.full_file_name = deps.trim(deps.full_file_name) + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = deps.get_new_unit_number()
                file_ok = deps.file_exists(deps.trim(deps.full_file_name))
                
                if not file_ok:
                    print('File not found=' + deps.trim(deps.full_file_name))
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        output_file = deps.trim(deps.file_name_path) + '.' + deps.trim(local_file_extension) + 'dif'
                    else:
                        output_file = deps.trim(deps.file_name_path) + '.' + deps.trim(local_file_extension) + 'new'
                    
                    if local_file_extension == 'imf':
                        deps.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.audit_f)
                        deps.processing_imf_file = True
                    else:
                        deps.processing_imf_file = False
                    
                    deps.process_input(
                        deps.trim(deps.program_path) + 'V9-3-0-Energy+.idd',
                        deps.trim(deps.program_path) + 'V9-4-0-Energy+.idd',
                        deps.full_file_name
                    )
                    
                    if deps.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    # Deallocate and reallocate arrays
                    deps.alphas = [deps.blank] * deps.max_alpha_args_found
                    deps.numbers = [0.0] * deps.max_numeric_args_found
                    deps.in_args = [deps.blank] * deps.max_total_args
                    deps.temp_args = [deps.blank] * deps.max_total_args
                    deps.a_or_n = [False] * deps.max_total_args
                    deps.req_fld = [False] * deps.max_total_args
                    deps.fld_names = [deps.blank] * deps.max_total_args
                    deps.fld_defaults = [deps.blank] * deps.max_total_args
                    deps.fld_units = [deps.blank] * deps.max_total_args
                    deps.nw_a_or_n = [False] * deps.max_total_args
                    deps.nw_req_fld = [False] * deps.max_total_args
                    deps.nw_fld_names = [deps.blank] * deps.max_total_args
                    deps.nw_fld_defaults = [deps.blank] * deps.max_total_args
                    deps.nw_fld_units = [deps.blank] * deps.max_total_args
                    deps.out_args = [deps.blank] * deps.max_total_args
                    delete_this_record = [False] * (deps.num_idf_records + 1)
                    
                    no_version = True
                    for num in range(deps.num_idf_records):
                        if deps.make_upper_case(deps.idd_records[num].name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(deps.num_idf_records):
                        if delete_this_record[num]:
                            pass
                    
                    deps.display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(deps.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(deps.idd_records[num].commt_s, deps.idd_records[num].commt_e + 1):
                            if xcount < len(deps.comments):
                                pass
                        
                        if no_version and num == 0:
                            deps.get_new_object_def_idd('VERSION')
                            deps.out_args[0] = '23.2'
                            cur_args = 1
                            deps.show_warning_error('No version found in file, defaulting to 23.2', deps.audit_f)
                            deps.write_out_idf_lines_as_comments(dif_lfn, 'Version', cur_args, deps.out_args, deps.nw_fld_names, deps.nw_fld_units)
                        
                        object_name = deps.idd_records[num].name
                        
                        if deps.find_item_in_list(object_name, [o.name for o in deps.object_def]) != -1:
                            deps.get_object_def_idd(object_name)
                            num_alphas = deps.idd_records[num].num_alphas
                            num_numbers = deps.idd_records[num].num_numbers
                            deps.alphas[:num_alphas] = deps.idd_records[num].alphas[:num_alphas]
                            deps.numbers[:num_numbers] = deps.idd_records[num].numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            deps.in_args = [deps.blank] * deps.max_total_args
                            deps.out_args = [deps.blank] * deps.max_total_args
                            deps.temp_args = [deps.blank] * deps.max_total_args
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if deps.a_or_n[arg]:
                                    deps.in_args[arg] = deps.alphas[na]
                                    na += 1
                                else:
                                    deps.in_args[arg] = str(deps.numbers[nn])
                                    nn += 1
                        else:
                            num_alphas = deps.idd_records[num].num_alphas
                            num_numbers = deps.idd_records[num].num_numbers
                            deps.alphas[:num_alphas] = deps.idd_records[num].alphas[:num_alphas]
                            deps.numbers[:num_numbers] = deps.idd_records[num].numbers[:num_numbers]
                            for arg in range(num_alphas):
                                deps.out_args[arg] = deps.alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                deps.out_args[nn] = str(deps.numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            deps.nw_fld_names = [deps.blank] * deps.max_total_args
                            deps.nw_fld_units = [deps.blank] * deps.max_total_args
                            deps.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, deps.out_args, deps.nw_fld_names, deps.nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.find_item_in_list(deps.make_upper_case(object_name), deps.not_in_new) == -1:
                            deps.get_new_object_def_idd(object_name)
                            if deps.obj_min_flds != deps.nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not False:  # not MakingPretty
                            obj_name_upper = deps.make_upper_case(deps.trim(deps.idd_records[num].name))
                            
                            if obj_name_upper == 'VERSION':
                                if deps.in_args[0][:4] == '23.2' and arg_file:
                                    deps.show_warning_error('File is already at latest version.  No new diff file made.', deps.audit_f)
                                    latest_version = True
                                    break
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[0] = '23.2'
                                no_diff = False
                            
                            elif obj_name_upper == 'OUTPUT:VARIABLE':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                if deps.out_args[0] == deps.blank:
                                    deps.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    True, False, False, cur_args, written_flag, False
                                )
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 
                                                    'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    1, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, True, False, cur_args, written_flag, False
                                )
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                if deps.out_args[0] == deps.blank:
                                    deps.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, False, True, cur_args, written_flag, False
                                )
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE',
                                                    'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                if deps.out_args[0] == deps.blank:
                                    deps.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, False, False, cur_args, written_flag, False
                                )
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    3, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, False, False, cur_args, written_flag, True
                                )
                                if del_this[0]:
                                    continue
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                deps.get_new_object_def_idd(object_name)
                                no_diff = True
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                cur_var = 3
                                
                                for var in range(3, cur_args + 1, 2):
                                    uc_rep_var_name = deps.make_upper_case(deps.in_args[var - 1])
                                    deps.out_args[cur_var - 1] = deps.in_args[var - 1]
                                    deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        deps.out_args[cur_var - 1] = deps.in_args[var - 1][:pos]
                                        deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    del_this = False
                                    for arg in range(deps.num_rep_var_names):
                                        uc_comp_rep_var_name = deps.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_match = deps.trim(uc_rep_var_name).find(deps.trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos_match = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos_match = 0
                                        
                                        if pos_match > 0 and pos_match != 0:
                                            continue
                                        
                                        if pos_match >= 0:
                                            if deps.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg] != deps.blank and not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not deps.otm_var_caution[arg]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg]) + '".'
                                                        )
                                                        deps.otm_var_caution[arg] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 1]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != deps.blank:
                                                        if not deps.otm_var_caution[arg + 1]:
                                                            deps.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, 'Warning',
                                                                'Output Table Monthly (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                                '" conversion to Output Table Monthly (new)="' +
                                                                deps.trim(deps.new_rep_var_name[arg + 1]) + 
                                                                '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 1]) + '".'
                                                            )
                                                            deps.otm_var_caution[arg + 1] = True
                                                    
                                                    deps.out_args[cur_var] = deps.in_args[var]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 2]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != deps.blank:
                                                    if not deps.otm_var_caution[arg + 2]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Output Table Monthly (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg + 2]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 2]) + '".'
                                                        )
                                                        deps.otm_var_caution[arg + 2] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var - 1
                            
                            elif obj_name_upper == 'METER:CUSTOM':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                cur_var = 4
                                
                                for var in range(4, cur_args + 1, 2):
                                    uc_rep_var_name = deps.make_upper_case(deps.in_args[var - 1])
                                    deps.out_args[cur_var - 1] = deps.in_args[var - 1]
                                    deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        deps.out_args[cur_var - 1] = deps.in_args[var - 1][:pos]
                                        deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    del_this = False
                                    for arg in range(deps.num_rep_var_names):
                                        uc_comp_rep_var_name = deps.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_match = deps.trim(uc_rep_var_name).find(deps.trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos_match = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos_match = 0
                                        
                                        if pos_match > 0 and pos_match != 0:
                                            continue
                                        
                                        if pos_match >= 0:
                                            if deps.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg] != deps.blank and not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not deps.cmtr_var_caution[arg]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Custom Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Custom Meter (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg]) + '".'
                                                        )
                                                        deps.cmtr_var_caution[arg] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 1]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != deps.blank and not deps.same_string(deps.new_rep_var_caution[arg + 1][:6], 'Forkeq'):
                                                        if not deps.cmtr_var_caution[arg + 1]:
                                                            deps.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, 'Warning',
                                                                'Custom Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                                '" conversion to Custom Meter (new)="' +
                                                                deps.trim(deps.new_rep_var_name[arg + 1]) + 
                                                                '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 1]) + '".'
                                                            )
                                                            deps.cmtr_var_caution[arg + 1] = True
                                                    
                                                    deps.out_args[cur_var] = deps.in_args[var]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 2]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != deps.blank:
                                                    if not deps.cmtr_var_caution[arg + 2]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Custom Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Custom Meter (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg + 2]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 2]) + '".'
                                                        )
                                                        deps.cmtr_var_caution[arg + 2] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if deps.out_args[arg] == deps.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper == 'METER:CUSTOMDECREMENT':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                cur_var = 4
                                
                                for var in range(4, cur_args + 1, 2):
                                    uc_rep_var_name = deps.make_upper_case(deps.in_args[var - 1])
                                    deps.out_args[cur_var - 1] = deps.in_args[var - 1]
                                    deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > -1:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        deps.out_args[cur_var - 1] = deps.in_args[var - 1][:pos]
                                        deps.out_args[cur_var] = deps.in_args[var]
                                    
                                    del_this = False
                                    for arg in range(deps.num_rep_var_names):
                                        uc_comp_rep_var_name = deps.make_upper_case(deps.old_rep_var_name[arg])
                                        
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            pos_match = deps.trim(uc_rep_var_name).find(deps.trim(uc_comp_rep_var_name))
                                        else:
                                            wild_match = False
                                            pos_match = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos_match = 0
                                        
                                        if pos_match > 0 and pos_match != 0:
                                            continue
                                        
                                        if pos_match >= 0:
                                            if deps.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg] != deps.blank and not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    if not deps.cmtr_d_var_caution[arg]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Custom Meter (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg]) + '".'
                                                        )
                                                        deps.cmtr_d_var_caution[arg] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg + 1 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 1]:
                                                if not deps.same_string(deps.new_rep_var_caution[arg][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 1]
                                                    else:
                                                        deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 1]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                    
                                                    if deps.new_rep_var_caution[arg + 1] != deps.blank and not deps.same_string(deps.new_rep_var_caution[arg + 1][:6], 'Forkeq'):
                                                        if not deps.cmtr_d_var_caution[arg + 1]:
                                                            deps.write_preprocessor_object(
                                                                dif_lfn, deps.prog_name_conversion, 'Warning',
                                                                'Custom Decrement Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                                '" conversion to Custom Decrement Meter (new)="' +
                                                                deps.trim(deps.new_rep_var_name[arg + 1]) + 
                                                                '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 1]) + '".'
                                                            )
                                                            deps.cmtr_d_var_caution[arg + 1] = True
                                                    
                                                    deps.out_args[cur_var] = deps.in_args[var]
                                                    no_diff = False
                                            
                                            if arg + 2 < deps.num_rep_var_names and deps.old_rep_var_name[arg] == deps.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    deps.out_args[cur_var - 1] = deps.new_rep_var_name[arg + 2]
                                                else:
                                                    deps.out_args[cur_var - 1] = deps.trim(deps.new_rep_var_name[arg + 2]) + deps.out_args[cur_var - 1][len(uc_comp_rep_var_name):]
                                                
                                                if deps.new_rep_var_caution[arg + 2] != deps.blank:
                                                    if not deps.cmtr_d_var_caution[arg + 2]:
                                                        deps.write_preprocessor_object(
                                                            dif_lfn, deps.prog_name_conversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + deps.trim(deps.old_rep_var_name[arg]) + 
                                                            '" conversion to Custom Meter (new)="' +
                                                            deps.trim(deps.new_rep_var_name[arg + 2]) + 
                                                            '" has the following caution "' + deps.trim(deps.new_rep_var_caution[arg + 2]) + '".'
                                                        )
                                                        deps.cmtr_d_var_caution[arg + 2] = True
                                                
                                                deps.out_args[cur_var] = deps.in_args[var]
                                                no_diff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                
                                cur_args = cur_var
                                for arg in range(cur_var - 1, -1, -1):
                                    if deps.out_args[arg] == deps.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_name_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    2, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, True, False, cur_args, written_flag, False
                                )
                            
                            elif obj_name_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                deps.get_new_object_def_idd(object_name)
                                deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                no_diff = True
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    6, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, True, False, cur_args, written_flag, False
                                )
                                
                                del_this = [False]
                                written_flag = [False]
                                deps.scan_output_variables_for_replacement(
                                    12, del_this, [check_rvi], [no_diff], object_name, dif_lfn,
                                    False, True, False, cur_args, written_flag, False
                                )
                            
                            else:
                                if deps.find_item_in_list(object_name, deps.not_in_new) != -1:
                                    deps.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, deps.in_args, deps.fld_names, deps.fld_units)
                                    written = True
                                else:
                                    deps.get_new_object_def_idd(object_name)
                                    deps.out_args[:cur_args] = deps.in_args[:cur_args]
                                    no_diff = True
                        
                        else:
                            deps.get_new_object_def_idd(deps.idd_records[num].name)
                            deps.out_args[:cur_args] = deps.in_args[:cur_args]
                        
                        if diff_min_fields and no_diff:
                            deps.get_new_object_def_idd(object_name)
                            deps.out_args[:cur_args] = deps.in_args[:cur_args]
                            no_diff = False
                            for arg in range(cur_args + 1, deps.nw_obj_min_flds + 1):
                                deps.out_args[arg - 1] = deps.nw_fld_defaults[arg - 1]
                            cur_args = max(deps.nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.check_special_objects(dif_lfn, object_name, cur_args, deps.out_args, 
                                                      deps.nw_fld_names, deps.nw_fld_units, [written])
                        
                        if not written:
                            deps.write_out_idf_lines(dif_lfn, object_name, cur_args, deps.out_args, 
                                                    deps.nw_fld_names, deps.nw_fld_units)
                    
                    deps.display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if deps.idd_records[deps.num_idf_records - 1].commt_e != deps.cur_comment:
                        for xcount in range(deps.idd_records[deps.num_idf_records - 1].commt_e + 1, deps.cur_comment + 1):
                            if xcount < len(deps.comments):
                                pass
                    
                    if deps.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        deps.get_new_object_def_idd(object_name)
                        no_diff = False
                        deps.out_args[0] = 'Regular'
                        cur_args = 1
                        deps.write_out_idf_lines(dif_lfn, object_name, cur_args, deps.out_args, 
                                                deps.nw_fld_names, deps.nw_fld_units)
                    
                    if deps.file_exists(deps.trim(deps.file_name_path) + '.rvi'):
                        pass
                    
                    deps.process_rvi_mvi_files(deps.file_name_path, 'rvi')
                    deps.process_rvi_mvi_files(deps.file_name_path, 'mvi')
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(deps.file_name_path, 'rvi')
                    deps.process_rvi_mvi_files(deps.file_name_path, 'mvi')
            
            else:
                end_of_file[0] = True
            
            deps.create_new_name('Reallocate', created_output_name, ' ')
        
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
        deps.copy_file(
            deps.trim(deps.file_name_path) + '.' + deps.trim(arg_idf_extension),
            deps.trim(deps.file_name_path) + '.' + deps.trim(arg_idf_extension) + 'old'
        )
        deps.copy_file(
            deps.trim(deps.file_name_path) + '.' + deps.trim(arg_idf_extension) + 'new',
            deps.trim(deps.file_name_path) + '.' + deps.trim(arg_idf_extension)
        )
        
        if deps.file_exists(deps.trim(deps.file_name_path) + '.rvi'):
            deps.copy_file(
                deps.trim(deps.file_name_path) + '.rvi',
                deps.trim(deps.file_name_path) + '.rviold'
            )
        
        if deps.file_exists(deps.trim(deps.file_name_path) + '.rvinew'):
            deps.copy_file(
                deps.trim(deps.file_name_path) + '.rvinew',
                deps.trim(deps.file_name_path) + '.rvi'
            )
        
        if deps.file_exists(deps.trim(deps.file_name_path) + '.mvi'):
            deps.copy_file(
                deps.trim(deps.file_name_path) + '.mvi',
                deps.trim(deps.file_name_path) + '.mviold'
            )
        
        if deps.file_exists(deps.trim(deps.file_name_path) + '.mvinew'):
            deps.copy_file(
                deps.trim(deps.file_name_path) + '.mvinew',
                deps.trim(deps.file_name_path) + '.mvi'
            )
