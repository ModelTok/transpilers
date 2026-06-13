from typing import Protocol, List, Optional, Tuple, Any
from dataclasses import dataclass, field

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor.ProcessInput (void, sets global IDF records)
# - VCompareGlobalRoutines.DisplayString, GetNewUnitNumber, GetObjectDefInIDD, GetNewObjectDefInIDD, 
#   FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, ScanOutputVariablesForReplacement,
#   CheckSpecialObjects, writePreprocessorObject, CreateNewName, ProcessRviMviFiles, CloseOut, GetNumSectionsFound
# - General.copyfile, TrimTrailZeros, MakeLowerCase
# - DataGlobals.ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - DataStringGlobals: VerString, VersionNum, sVersionNum, sVersionNumFourChars, IDDFileNameWithPath,
#   NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath, MaxNameLength, blank, Auditf,
#   FullFileName, FileNamePath, IDFRecords, NumIDFRecords, Comments, CurComment,
#   MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, ProcessingIMFFile,
#   Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits,
#   ObjectDef, NumObjectDefs, OldRepVarName, NumRepVarNames, NewRepVarName, NewRepVarCaution,
#   CMtrVarCaution, OTMVarCaution, CMtrDVarCaution, NotInNew, MakingPretty, FatalError
# - DataVCompareGlobals.OutArgs, NwNumArgs, NwObjMinFlds, ObjMinFlds, NumAlphas, NumNumbers

@dataclass
class IDFRecord:
    name: str
    alphas: List[str]
    numbers: List[float]
    num_alphas: int
    num_numbers: int
    commt_s: int
    commt_e: int

@dataclass
class ObjectDef:
    name: str

class DataStringGlobalsProtocol(Protocol):
    ver_string: str
    version_num: float
    s_version_num: str
    s_version_num_four_chars: str
    idd_file_name_with_path: str
    new_idd_file_name_with_path: str
    rep_var_file_name_with_path: str
    program_path: str
    max_name_length: int
    blank: str
    auditf: int
    full_file_name: str
    file_name_path: str
    idf_records: List[IDFRecord]
    num_idf_records: int
    comments: List[str]
    cur_comment: int
    max_alpha_args_found: int
    max_numeric_args_found: int
    max_total_args: int
    processing_imf_file: bool
    alphas: List[str]
    numbers: List[float]
    in_args: List[str]
    temp_args: List[str]
    aor_n: List[bool]
    req_fld: List[bool]
    fld_names: List[str]
    fld_defaults: List[str]
    fld_units: List[str]
    nw_aor_n: List[bool]
    nw_req_fld: List[bool]
    nw_fld_names: List[str]
    nw_fld_defaults: List[str]
    nw_fld_units: List[str]
    object_def: List[ObjectDef]
    num_object_defs: int
    old_rep_var_name: List[str]
    num_rep_var_names: int
    new_rep_var_name: List[str]
    new_rep_var_caution: List[str]
    cmtr_var_caution: List[bool]
    otm_var_caution: List[bool]
    cmtr_d_var_caution: List[bool]
    not_in_new: List[str]
    making_pretty: bool
    fatal_error: bool
    out_args: List[str]
    nw_num_args: int
    nw_obj_min_flds: int
    obj_min_flds: int
    num_alphas: int
    num_numbers: int

class DataGlobalsProtocol(Protocol):
    def show_message(self, msg: str) -> None: ...
    def show_continue_error(self, msg: str) -> None: ...
    def show_fatal_error(self, msg: str) -> None: ...
    def show_severe_error(self, msg: str) -> None: ...
    def show_warning_error(self, msg: str, auditf: int = None) -> None: ...

class VCompareRoutinesProtocol(Protocol):
    def display_string(self, msg: str) -> None: ...
    def get_new_unit_number(self) -> int: ...
    def process_input(self, idd: str, new_idd: str, idf: str) -> None: ...
    def get_object_def_in_idd(self, name: str, args: List[int], aorn: List[bool], 
                              reqf: List[bool], minf: List[int], fnames: List[str],
                              fdef: List[str], fun: List[str]) -> None: ...
    def get_new_object_def_in_idd(self, name: str, nargs: List[int], naorn: List[bool],
                                  nreqf: List[bool], nminf: List[int], nfnames: List[str],
                                  nfdef: List[str], nfun: List[str]) -> None: ...
    def find_item_in_list(self, name: str, lst: List[str]) -> int: ...
    def write_out_idf_lines_as_comments(self, unit: int, name: str, num_args: int,
                                        args: List[str], fnames: List[str], fun: List[str]) -> None: ...
    def write_out_idf_lines(self, unit: int, name: str, num_args: int,
                            args: List[str], fnames: List[str], fun: List[str]) -> None: ...
    def scan_output_variables_for_replacement(self, field: int, deltbl: List[bool],
                                              chkrvi: List[bool], nodiff: List[bool],
                                              obj_name: str, unit: int, outvar: bool,
                                              mtrvar: bool, timebinvar: bool,
                                              curargs: List[int], writ: List[bool],
                                              is_sensor: bool) -> None: ...
    def check_special_objects(self, unit: int, name: str, num_args: int,
                              args: List[str], fnames: List[str], fun: List[str],
                              writ: List[bool]) -> None: ...
    def write_preprocessor_object(self, unit: int, prog_name: str, msg_type: str, msg: str) -> None: ...
    def create_new_name(self, action: str, outname: List[str], suffix: str) -> None: ...
    def process_rvi_mvi_files(self, path: str, ext: str) -> None: ...
    def close_out(self) -> None: ...
    def get_num_sections_found(self, sect: str) -> int: ...
    def copyfile(self, src: str, dst: str, errflg: List[bool]) -> None: ...

class GeneralProtocol(Protocol):
    def make_lower_case(self, s: str) -> str: ...
    def make_upper_case(self, s: str) -> str: ...
    def same_string(self, s1: str, s2: str) -> bool: ...
    def trim_trail_zeros(self, s: str) -> str: ...

def set_this_version_variables(dsg: DataStringGlobalsProtocol, prog_path: str) -> None:
    dsg.ver_string = 'Conversion 22.1 => 22.2'
    dsg.version_num = 22.2
    dsg.s_version_num = '***'
    dsg.s_version_num_four_chars = '22.2'
    dsg.idd_file_name_with_path = dsg.program_path.rstrip() + 'V22-1-0-Energy+.idd'
    dsg.new_idd_file_name_with_path = dsg.program_path.rstrip() + 'V22-2-0-Energy+.idd'
    dsg.rep_var_file_name_with_path = dsg.program_path.rstrip() + 'Report Variables 22-1-0 to 22-2-0.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    dsg: DataStringGlobalsProtocol,
    dg: DataGlobalsProtocol,
    vcr: VCompareRoutinesProtocol,
    gen: GeneralProtocol
) -> None:
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
    p_out_args = [''] * dsg.max_total_args
    conn_comp = False
    conn_comp_ctrl = False
    file_exist = False
    created_output_name = ""
    delete_this_record = [False] * dsg.max_total_args
    c_out_args = 0
    units_field = ""
    err_flag = [False]
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
    current_run_period_names = []
    num1 = 0
    surrounding_field1 = ""
    surrounding_field2 = ""
    matched_surrounding_name = ""
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
                print('Enter input file name, with path')
                dsg.full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        with open(f"unit_{in_lfn}", 'r') as f:
                            line = f.readline()
                            dsg.full_file_name = line if line else ""
                            ios = 0
                    except:
                        dsg.full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    dsg.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    dsg.full_file_name = ""
                    ios = 1
                
                if dsg.full_file_name.startswith('!'):
                    dsg.full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                dsg.full_file_name = ""
            dsg.full_file_name = dsg.full_file_name.lstrip()
            
            if dsg.full_file_name != "":
                vcr.display_string('Processing IDF -- ' + dsg.full_file_name.rstrip())
                
                dot_pos = dsg.full_file_name.rfind('.')
                if dot_pos != -1:
                    dsg.file_name_path = dsg.full_file_name[:dot_pos]
                    local_file_extension = gen.make_lower_case(dsg.full_file_name[dot_pos+1:])
                else:
                    dsg.file_name_path = dsg.full_file_name
                    print(' assuming file extension of .idf')
                    dsg.full_file_name = dsg.full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = vcr.get_new_unit_number()
                
                try:
                    with open(dsg.full_file_name, 'r') as f:
                        file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print(f'File not found={dsg.full_file_name}')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        out_file = dsg.file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        out_file = dsg.file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        dg.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', dsg.auditf)
                        dsg.processing_imf_file = True
                    else:
                        dsg.processing_imf_file = False
                    
                    vcr.process_input(dsg.idd_file_name_with_path, dsg.new_idd_file_name_with_path, dsg.full_file_name)
                    
                    if dsg.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    dsg.alphas = [dsg.blank] * dsg.max_alpha_args_found
                    dsg.numbers = [0.0] * dsg.max_numeric_args_found
                    dsg.in_args = [dsg.blank] * dsg.max_total_args
                    dsg.temp_args = [dsg.blank] * dsg.max_total_args
                    dsg.aor_n = [False] * dsg.max_total_args
                    dsg.req_fld = [False] * dsg.max_total_args
                    dsg.fld_names = [dsg.blank] * dsg.max_total_args
                    dsg.fld_defaults = [dsg.blank] * dsg.max_total_args
                    dsg.fld_units = [dsg.blank] * dsg.max_total_args
                    dsg.nw_aor_n = [False] * dsg.max_total_args
                    dsg.nw_req_fld = [False] * dsg.max_total_args
                    dsg.nw_fld_names = [dsg.blank] * dsg.max_total_args
                    dsg.nw_fld_defaults = [dsg.blank] * dsg.max_total_args
                    dsg.nw_fld_units = [dsg.blank] * dsg.max_total_args
                    dsg.out_args = [dsg.blank] * dsg.max_total_args
                    p_out_args = [dsg.blank] * dsg.max_total_args
                    delete_this_record = [False] * dsg.num_idf_records
                    
                    no_version = True
                    for num_check in range(dsg.num_idf_records):
                        if gen.make_upper_case(dsg.idf_records[num_check].name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(dsg.num_idf_records):
                        if delete_this_record[num]:
                            pass
                    
                    vcr.display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(dsg.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(dsg.idf_records[num].commt_s, dsg.idf_records[num].commt_e + 1):
                            pass
                        
                        if no_version and num == 0:
                            nw_num_args_tmp = [0]
                            nw_aor_n_tmp = [False] * dsg.max_total_args
                            nw_req_fld_tmp = [False] * dsg.max_total_args
                            nw_obj_min_flds_tmp = [0]
                            nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                            vcr.get_new_object_def_in_idd('VERSION', nw_num_args_tmp, nw_aor_n_tmp,
                                                           nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                           nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                            dsg.out_args[0] = dsg.s_version_num_four_chars
                            cur_args = 1
                            dg.show_warning_error('No version found in file, defaulting to ' + dsg.s_version_num_four_chars, dsg.auditf)
                            vcr.write_out_idf_lines_as_comments(dif_lfn, 'Version', cur_args, dsg.out_args,
                                                                nw_fld_names_tmp, nw_fld_units_tmp)
                        
                        object_name = dsg.idf_records[num].name
                        
                        if vcr.find_item_in_list(object_name, [obj.name for obj in dsg.object_def]) != 0:
                            num_args_tmp = [0]
                            aor_n_tmp = [False] * dsg.max_total_args
                            req_fld_tmp = [False] * dsg.max_total_args
                            obj_min_flds_tmp = [0]
                            fld_names_tmp = [dsg.blank] * dsg.max_total_args
                            fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                            fld_units_tmp = [dsg.blank] * dsg.max_total_args
                            
                            vcr.get_object_def_in_idd(object_name, num_args_tmp, aor_n_tmp, req_fld_tmp,
                                                       obj_min_flds_tmp, fld_names_tmp, fld_defaults_tmp, fld_units_tmp)
                            
                            dsg.num_alphas = dsg.idf_records[num].num_alphas
                            dsg.num_numbers = dsg.idf_records[num].num_numbers
                            dsg.alphas[:dsg.num_alphas] = dsg.idf_records[num].alphas[:dsg.num_alphas]
                            dsg.numbers[:dsg.num_numbers] = dsg.idf_records[num].numbers[:dsg.num_numbers]
                            cur_args = dsg.num_alphas + dsg.num_numbers
                            dsg.in_args = [dsg.blank] * dsg.max_total_args
                            dsg.out_args = [dsg.blank] * dsg.max_total_args
                            dsg.temp_args = [dsg.blank] * dsg.max_total_args
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if aor_n_tmp[arg]:
                                    dsg.in_args[arg] = dsg.alphas[na]
                                    na += 1
                                else:
                                    dsg.in_args[arg] = str(dsg.numbers[nn])
                                    nn += 1
                        else:
                            dsg.num_alphas = dsg.idf_records[num].num_alphas
                            dsg.num_numbers = dsg.idf_records[num].num_numbers
                            dsg.alphas[:dsg.num_alphas] = dsg.idf_records[num].alphas[:dsg.num_alphas]
                            dsg.numbers[:dsg.num_numbers] = dsg.idf_records[num].numbers[:dsg.num_numbers]
                            for arg in range(dsg.num_alphas):
                                dsg.out_args[arg] = dsg.alphas[arg]
                            nn = dsg.num_alphas
                            for arg in range(dsg.num_numbers):
                                dsg.out_args[nn] = str(dsg.numbers[arg])
                                nn += 1
                            cur_args = dsg.num_alphas + dsg.num_numbers
                            dsg.nw_fld_names = [dsg.blank] * dsg.max_total_args
                            dsg.nw_fld_units = [dsg.blank] * dsg.max_total_args
                            vcr.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, dsg.out_args,
                                                                dsg.nw_fld_names, dsg.nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if vcr.find_item_in_list(gen.make_upper_case(object_name), dsg.not_in_new) == 0:
                            nw_num_args_tmp = [0]
                            nw_aor_n_tmp = [False] * dsg.max_total_args
                            nw_req_fld_tmp = [False] * dsg.max_total_args
                            nw_obj_min_flds_tmp = [0]
                            nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                            
                            vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                           nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                           nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                            
                            dsg.obj_min_flds = obj_min_flds_tmp[0] if 'obj_min_flds_tmp' in locals() else 0
                            dsg.nw_obj_min_flds = nw_obj_min_flds_tmp[0]
                            
                            if dsg.obj_min_flds != dsg.nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not dsg.making_pretty:
                            obj_upper = gen.make_upper_case(dsg.idf_records[num].name.rstrip())
                            
                            if obj_upper == 'VERSION':
                                if dsg.in_args[0][:4] == dsg.s_version_num_four_chars and arg_file:
                                    dg.show_warning_error('File is already at latest version.  No new diff file made.', dsg.auditf)
                                    latest_version = True
                                    break
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                dsg.out_args[0] = dsg.s_version_num_four_chars
                                no_diff = False
                            
                            elif obj_upper == 'COIL:COOLING:DX:CURVEFIT:SPEED':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(8):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[8] = ''
                                for i in range(cur_args - 8):
                                    dsg.out_args[9 + i] = dsg.in_args[8 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'COIL:COOLING:DX:SINGLESPEED':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(7):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[7] = ''
                                for i in range(cur_args - 7):
                                    dsg.out_args[8 + i] = dsg.in_args[7 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'COIL:COOLING:DX:MULTISPEED':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(23):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[23] = ''
                                for i in range(19):
                                    dsg.out_args[24 + i] = dsg.in_args[23 + i]
                                dsg.out_args[43] = ''
                                for i in range(19):
                                    dsg.out_args[44 + i] = dsg.in_args[42 + i]
                                dsg.out_args[63] = ''
                                for i in range(19):
                                    dsg.out_args[64 + i] = dsg.in_args[61 + i]
                                dsg.out_args[83] = ''
                                for i in range(cur_args - 80):
                                    dsg.out_args[84 + i] = dsg.in_args[80 + i]
                                if cur_args >= 23:
                                    cur_args = cur_args + 1
                                if cur_args >= 42:
                                    cur_args = cur_args + 1
                                if cur_args >= 61:
                                    cur_args = cur_args + 1
                                if cur_args >= 80:
                                    cur_args = cur_args + 1
                            
                            elif obj_upper == 'COIL:HEATING:DX:SINGLESPEED':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(5):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[5] = ''
                                for i in range(cur_args - 5):
                                    dsg.out_args[6 + i] = dsg.in_args[5 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == 'COIL:HEATING:DX:MULTISPEED':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(22):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[22] = ''
                                for i in range(11):
                                    dsg.out_args[23 + i] = dsg.in_args[22 + i]
                                dsg.out_args[34] = ''
                                for i in range(11):
                                    dsg.out_args[35 + i] = dsg.in_args[33 + i]
                                dsg.out_args[46] = ''
                                for i in range(11):
                                    dsg.out_args[47 + i] = dsg.in_args[44 + i]
                                dsg.out_args[58] = ''
                                for i in range(cur_args - 55):
                                    dsg.out_args[59 + i] = dsg.in_args[55 + i]
                                if cur_args >= 22:
                                    cur_args = cur_args + 1
                                if cur_args >= 33:
                                    cur_args = cur_args + 1
                                if cur_args >= 44:
                                    cur_args = cur_args + 1
                                if cur_args >= 55:
                                    cur_args = cur_args + 1
                            
                            elif obj_upper == 'FUELFACTORS':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                dsg.out_args[0] = dsg.in_args[0]
                                for i in range(cur_args - 2):
                                    dsg.out_args[1 + i] = dsg.in_args[3 + i]
                                cur_args = cur_args - 2
                            
                            elif obj_upper == 'SPACE':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                dsg.out_args[0] = dsg.in_args[0]
                                dsg.out_args[1] = dsg.in_args[1]
                                dsg.out_args[2] = 'autocalculate'
                                dsg.out_args[3] = 'autocalculate'
                                for i in range(cur_args - 2):
                                    dsg.out_args[4 + i] = dsg.in_args[2 + i]
                                cur_args = cur_args + 2
                            
                            elif obj_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(10):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[10] = '30.0'
                                dsg.out_args[11] = '27.0'
                                dsg.out_args[12] = '19.0'
                                for i in range(cur_args - 10):
                                    dsg.out_args[13 + i] = dsg.in_args[10 + i]
                                cur_args = cur_args + 3
                                dg.show_warning_error('For ' + object_name.rstrip() + ', rated temperature from ISO 13256-1:1988 for water loop application are used, make sure that they align with your application.', dsg.auditf)
                            
                            elif obj_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = False
                                for i in range(9):
                                    dsg.out_args[i] = dsg.in_args[i]
                                dsg.out_args[9] = '20.0'
                                dsg.out_args[10] = '20.0'
                                dsg.out_args[11] = '1.0'
                                for i in range(cur_args - 9):
                                    dsg.out_args[12 + i] = dsg.in_args[9 + i]
                                cur_args = cur_args + 3
                                dg.show_warning_error('For ' + object_name.rstrip() + ', rated temperature from ISO 13256-1:1988 for water loop application are used, make sure that they align with your application.', dsg.auditf)
                            
                            elif obj_upper == 'OUTPUT:VARIABLE':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                if dsg.out_args[0] == dsg.blank:
                                    dsg.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(2, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          True, False, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                if del_this:
                                    continue
                            
                            elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(1, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, True, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                if dsg.out_args[0] == dsg.blank:
                                    dsg.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(2, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, False, True,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                if del_this:
                                    continue
                            
                            elif obj_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE',
                                               'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                if dsg.out_args[0] == dsg.blank:
                                    dsg.out_args[0] = '*'
                                    no_diff = False
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(2, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, False, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(3, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, False, False,
                                                                          cur_args_list, written_list, True)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                no_diff = True
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                cur_var = 3
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = gen.make_upper_case(dsg.in_args[var])
                                    dsg.out_args[cur_var] = dsg.in_args[var]
                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        dsg.out_args[cur_var] = dsg.in_args[var][:pos]
                                        dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    del_this = False
                                    for arg_iter in range(dsg.num_rep_var_names):
                                        uc_comp_rep_var_name = gen.make_upper_case(dsg.old_rep_var_name[arg_iter])
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = dsg.out_args[cur_var].upper().find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            arg_iter += 1
                                            continue
                                        if pos >= 0:
                                            if dsg.new_rep_var_name[arg_iter] != '<DELETE>':
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter] != dsg.blank and not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    if not dsg.otm_var_caution[arg_iter]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Output Table Monthly (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Output Table Monthly (new)="' +
                                                           dsg.new_rep_var_name[arg_iter].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter].rstrip() + '".')
                                                        dsg.otm_var_caution[arg_iter] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if arg_iter + 1 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 1]:
                                                if not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1]
                                                    else:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if dsg.new_rep_var_caution[arg_iter + 1] != dsg.blank:
                                                        if not dsg.otm_var_caution[arg_iter + 1]:
                                                            vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                               'Output Table Monthly (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                               '" conversion to Output Table Monthly (new)="' +
                                                               dsg.new_rep_var_name[arg_iter + 1].rstrip() +
                                                               '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 1].rstrip() + '".')
                                                            dsg.otm_var_caution[arg_iter + 1] = True
                                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                    no_diff = False
                                            if arg_iter + 2 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter + 2] != dsg.blank:
                                                    if not dsg.otm_var_caution[arg_iter + 2]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Output Table Monthly (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Output Table Monthly (new)="' +
                                                           dsg.new_rep_var_name[arg_iter + 2].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 2].rstrip() + '".')
                                                        dsg.otm_var_caution[arg_iter + 2] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var - 1
                            
                            elif obj_upper == 'METER:CUSTOM':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = gen.make_upper_case(dsg.in_args[var])
                                    dsg.out_args[cur_var] = dsg.in_args[var]
                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        dsg.out_args[cur_var] = dsg.in_args[var][:pos]
                                        dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    del_this = False
                                    for arg_iter in range(dsg.num_rep_var_names):
                                        uc_comp_rep_var_name = gen.make_upper_case(dsg.old_rep_var_name[arg_iter])
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = dsg.out_args[cur_var].upper().find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            arg_iter += 1
                                            continue
                                        if pos >= 0:
                                            if dsg.new_rep_var_name[arg_iter] != '<DELETE>':
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter] != dsg.blank and not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    if not dsg.cmtr_var_caution[arg_iter]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Custom Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           dsg.new_rep_var_name[arg_iter].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter].rstrip() + '".')
                                                        dsg.cmtr_var_caution[arg_iter] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if arg_iter + 1 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 1]:
                                                if not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1]
                                                    else:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if dsg.new_rep_var_caution[arg_iter + 1] != dsg.blank and not gen.same_string(dsg.new_rep_var_caution[arg_iter + 1][:6], 'Forkeq'):
                                                        if not dsg.cmtr_var_caution[arg_iter + 1]:
                                                            vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                               'Custom Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                               '" conversion to Custom Meter (new)="' +
                                                               dsg.new_rep_var_name[arg_iter + 1].rstrip() +
                                                               '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 1].rstrip() + '".')
                                                            dsg.cmtr_var_caution[arg_iter + 1] = True
                                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                    no_diff = False
                                            if arg_iter + 2 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter + 2] != dsg.blank:
                                                    if not dsg.cmtr_var_caution[arg_iter + 2]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Custom Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           dsg.new_rep_var_name[arg_iter + 2].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 2].rstrip() + '".')
                                                        dsg.cmtr_var_caution[arg_iter + 2] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var
                                for arg_iter in range(cur_var - 1, -1, -1):
                                    if dsg.out_args[arg_iter] == dsg.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                cur_var = 4
                                var = 4
                                while var < cur_args:
                                    uc_rep_var_name = gen.make_upper_case(dsg.in_args[var])
                                    dsg.out_args[cur_var] = dsg.in_args[var]
                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        dsg.out_args[cur_var] = dsg.in_args[var][:pos]
                                        dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                    del_this = False
                                    for arg_iter in range(dsg.num_rep_var_names):
                                        uc_comp_rep_var_name = gen.make_upper_case(dsg.old_rep_var_name[arg_iter])
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                            pos = dsg.out_args[cur_var].upper().find(uc_comp_rep_var_name.rstrip())
                                        else:
                                            wild_match = False
                                            pos = -1
                                            if uc_rep_var_name == uc_comp_rep_var_name:
                                                pos = 0
                                        if pos > 0:
                                            arg_iter += 1
                                            continue
                                        if pos >= 0:
                                            if dsg.new_rep_var_name[arg_iter] != '<DELETE>':
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter] != dsg.blank and not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    if not dsg.cmtr_d_var_caution[arg_iter]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Custom Decrement Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           dsg.new_rep_var_name[arg_iter].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter].rstrip() + '".')
                                                        dsg.cmtr_d_var_caution[arg_iter] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if arg_iter + 1 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 1]:
                                                if not gen.same_string(dsg.new_rep_var_caution[arg_iter][:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1]
                                                    else:
                                                        dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 1].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                    if dsg.new_rep_var_caution[arg_iter + 1] != dsg.blank and not gen.same_string(dsg.new_rep_var_caution[arg_iter + 1][:6], 'Forkeq'):
                                                        if not dsg.cmtr_d_var_caution[arg_iter + 1]:
                                                            vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                               'Custom Decrement Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                               '" conversion to Custom Decrement Meter (new)="' +
                                                               dsg.new_rep_var_name[arg_iter + 1].rstrip() +
                                                               '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 1].rstrip() + '".')
                                                            dsg.cmtr_d_var_caution[arg_iter + 1] = True
                                                    dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                    no_diff = False
                                            if arg_iter + 2 < dsg.num_rep_var_names and dsg.old_rep_var_name[arg_iter] == dsg.old_rep_var_name[arg_iter + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2]
                                                else:
                                                    dsg.out_args[cur_var] = dsg.new_rep_var_name[arg_iter + 2].rstrip() + dsg.out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                if dsg.new_rep_var_caution[arg_iter + 2] != dsg.blank:
                                                    if not dsg.cmtr_d_var_caution[arg_iter + 2]:
                                                        vcr.write_preprocessor_object(dif_lfn, dsg.s_version_num_four_chars, 'Warning',
                                                           'Custom Decrement Meter (old)="' + dsg.old_rep_var_name[arg_iter].rstrip() +
                                                           '" conversion to Custom Meter (new)="' +
                                                           dsg.new_rep_var_name[arg_iter + 2].rstrip() +
                                                           '" has the following caution "' + dsg.new_rep_var_caution[arg_iter + 2].rstrip() + '".')
                                                        dsg.cmtr_d_var_caution[arg_iter + 2] = True
                                                dsg.out_args[cur_var + 1] = dsg.in_args[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                cur_args = cur_var
                                for arg_iter in range(cur_var - 1, -1, -1):
                                    if dsg.out_args[arg_iter] == dsg.blank:
                                        cur_args -= 1
                                    else:
                                        break
                            
                            elif obj_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(2, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, True, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                            
                            elif obj_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                                nw_num_args_tmp = [0]
                                nw_aor_n_tmp = [False] * dsg.max_total_args
                                nw_req_fld_tmp = [False] * dsg.max_total_args
                                nw_obj_min_flds_tmp = [0]
                                nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                               nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                               nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                for i in range(cur_args):
                                    dsg.out_args[i] = dsg.in_args[i]
                                no_diff = True
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(6, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, True, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                                
                                del_this_list = [False]
                                chk_rvi_list = [check_rvi]
                                no_diff_list = [no_diff]
                                cur_args_list = [cur_args]
                                written_list = [written]
                                
                                vcr.scan_output_variables_for_replacement(12, del_this_list, chk_rvi_list,
                                                                          no_diff_list, object_name, dif_lfn,
                                                                          False, True, False,
                                                                          cur_args_list, written_list, False)
                                
                                del_this = del_this_list[0]
                                check_rvi = chk_rvi_list[0]
                                no_diff = no_diff_list[0]
                                cur_args = cur_args_list[0]
                                written = written_list[0]
                            
                            else:
                                if vcr.find_item_in_list(object_name, dsg.not_in_new) != 0:
                                    nw_num_args_tmp = [0]
                                    nw_aor_n_tmp = [False] * dsg.max_total_args
                                    nw_req_fld_tmp = [False] * dsg.max_total_args
                                    nw_obj_min_flds_tmp = [0]
                                    nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                    nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                    nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                    vcr.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, dsg.in_args,
                                                                        dsg.fld_names, dsg.fld_units)
                                    written = True
                                else:
                                    nw_num_args_tmp = [0]
                                    nw_aor_n_tmp = [False] * dsg.max_total_args
                                    nw_req_fld_tmp = [False] * dsg.max_total_args
                                    nw_obj_min_flds_tmp = [0]
                                    nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                                    nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                                    nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                                    vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                                   nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                                   nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                                    for i in range(cur_args):
                                        dsg.out_args[i] = dsg.in_args[i]
                                    no_diff = True
                        else:
                            nw_num_args_tmp = [0]
                            nw_aor_n_tmp = [False] * dsg.max_total_args
                            nw_req_fld_tmp = [False] * dsg.max_total_args
                            nw_obj_min_flds_tmp = [0]
                            nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                            vcr.get_new_object_def_in_idd(dsg.idf_records[num].name, nw_num_args_tmp, nw_aor_n_tmp,
                                                           nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                           nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                            for i in range(cur_args):
                                dsg.out_args[i] = dsg.in_args[i]
                        
                        if diff_min_fields and no_diff:
                            nw_num_args_tmp = [0]
                            nw_aor_n_tmp = [False] * dsg.max_total_args
                            nw_req_fld_tmp = [False] * dsg.max_total_args
                            nw_obj_min_flds_tmp = [0]
                            nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                            nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                            vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                           nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                           nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                            for i in range(cur_args):
                                dsg.out_args[i] = dsg.in_args[i]
                            no_diff = False
                            for arg in range(cur_args, nw_obj_min_flds_tmp[0]):
                                dsg.out_args[arg] = nw_fld_defaults_tmp[arg]
                            cur_args = max(nw_obj_min_flds_tmp[0], cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            written_list = [written]
                            vcr.check_special_objects(dif_lfn, object_name, cur_args, dsg.out_args,
                                                     dsg.nw_fld_names, dsg.nw_fld_units, written_list)
                            written = written_list[0]
                        
                        if not written:
                            vcr.write_out_idf_lines(dif_lfn, object_name, cur_args, dsg.out_args,
                                                   dsg.nw_fld_names, dsg.nw_fld_units)
                    
                    vcr.display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if vcr.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args_tmp = [0]
                        nw_aor_n_tmp = [False] * dsg.max_total_args
                        nw_req_fld_tmp = [False] * dsg.max_total_args
                        nw_obj_min_flds_tmp = [0]
                        nw_fld_names_tmp = [dsg.blank] * dsg.max_total_args
                        nw_fld_defaults_tmp = [dsg.blank] * dsg.max_total_args
                        nw_fld_units_tmp = [dsg.blank] * dsg.max_total_args
                        vcr.get_new_object_def_in_idd(object_name, nw_num_args_tmp, nw_aor_n_tmp,
                                                       nw_req_fld_tmp, nw_obj_min_flds_tmp,
                                                       nw_fld_names_tmp, nw_fld_defaults_tmp, nw_fld_units_tmp)
                        no_diff = False
                        dsg.out_args[0] = 'Regular'
                        cur_args = 1
                        vcr.write_out_idf_lines(dif_lfn, object_name, cur_args, dsg.out_args,
                                               nw_fld_names_tmp, nw_fld_units_tmp)
                    
                    vcr.process_rvi_mvi_files(dsg.file_name_path, 'rvi')
                    vcr.process_rvi_mvi_files(dsg.file_name_path, 'mvi')
                    vcr.close_out()
                else:
                    vcr.process_rvi_mvi_files(dsg.file_name_path, 'rvi')
                    vcr.process_rvi_mvi_files(dsg.file_name_path, 'mvi')
            else:
                end_of_file[0] = True
            
            created_output_name_list = ['']
            vcr.create_new_name('Reallocate', created_output_name_list, ' ')
        
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
        err_flag = [False]
        vcr.copyfile(dsg.file_name_path + '.' + arg_idf_extension,
                     dsg.file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        vcr.copyfile(dsg.file_name_path + '.' + arg_idf_extension + 'new',
                     dsg.file_name_path + '.' + arg_idf_extension, err_flag)
        try:
            with open(dsg.file_name_path + '.rvi', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            vcr.copyfile(dsg.file_name_path + '.rvi',
                         dsg.file_name_path + '.rviold', err_flag)
        try:
            with open(dsg.file_name_path + '.rvinew', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            vcr.copyfile(dsg.file_name_path + '.rvinew',
                         dsg.file_name_path + '.rvi', err_flag)
        try:
            with open(dsg.file_name_path + '.mvi', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            vcr.copyfile(dsg.file_name_path + '.mvi',
                         dsg.file_name_path + '.mviold', err_flag)
        try:
            with open(dsg.file_name_path + '.mvinew', 'r') as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            vcr.copyfile(dsg.file_name_path + '.mvinew',
                         dsg.file_name_path + '.mvi', err_flag)
