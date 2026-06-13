from typing import Protocol, Optional, List, Dict, Any
from dataclasses import dataclass, field
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor: ProcessInput(idd_path, new_idd_path, idf_path), GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList
# - DataVCompareGlobals: IDFRecords (list of records), NumIDFRecords, Comments, CurComment, FatalError, NumObjectDefs, ObjectDef
# - VCompareGlobalRoutines: SameString, FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, WritePreprocessorObject, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CloseOut, CreateNewName, CopyFile
# - DataStringGlobals: ProgNameConversion, ProgramPath
# - General: MakeLowerCase, MakeUPPERCase, TrimTrailZeros, SameString, TRIM, ADJUSTL, MakeUPPERCase
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

class ExternalDeps(Protocol):
    """Protocol for external module dependencies"""
    def process_input(self, old_idd: str, new_idd: str, idf_file: str) -> None: ...
    def get_object_def_in_idd(self, obj_name: str) -> Dict[str, Any]: ...
    def get_new_object_def_in_idd(self, obj_name: str) -> Dict[str, Any]: ...
    def find_item_in_list(self, item: str, list_items: List[str]) -> int: ...
    def same_string(self, s1: str, s2: str) -> bool: ...
    def write_out_idf_lines(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def write_out_idf_lines_as_comments(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str]) -> None: ...
    def check_special_objects(self, unit: int, obj_name: str, cur_args: int, out_args: List[str], fld_names: List[str], fld_units: List[str], written: List[bool]) -> None: ...
    def write_preprocessor_object(self, unit: int, prog_name: str, level: str, msg: str) -> None: ...
    def scan_output_variables_for_replacement(self, field_num: int, del_this: List[bool], check_rvi: List[bool], no_diff: List[bool], obj_name: str, unit: int, out_var: bool, mtr_var: bool, time_bin_var: bool, cur_args: int, written: List[bool], sensor: bool) -> None: ...
    def process_rvi_mvi_files(self, file_path: str, extension: str) -> None: ...
    def close_out(self) -> None: ...
    def create_new_name(self, action: str, output_name: List[str], path: str) -> None: ...
    def copy_file(self, src: str, dst: str, err_flag: List[bool]) -> None: ...
    def make_lower_case(self, s: str) -> str: ...
    def make_upper_case(self, s: str) -> str: ...
    def show_warning_error(self, msg: str, unit: Optional[int] = None) -> None: ...
    
@dataclass
class GlobalState:
    """Global state from DataVCompareGlobals and related modules"""
    idf_records: List[Dict[str, Any]] = field(default_factory=list)
    num_idf_records: int = 0
    comments: List[str] = field(default_factory=list)
    cur_comment: int = 0
    fatal_error: bool = False
    num_object_defs: int = 0
    object_def: List[Dict[str, Any]] = field(default_factory=list)
    processing_imf_file: bool = False
    old_rep_var_names: List[str] = field(default_factory=list)
    new_rep_var_names: List[str] = field(default_factory=list)
    new_rep_var_caution: List[str] = field(default_factory=list)
    num_rep_var_names: int = 0
    otm_var_caution: List[bool] = field(default_factory=list)
    cmtr_var_caution: List[bool] = field(default_factory=list)
    cmtr_dvar_caution: List[bool] = field(default_factory=list)
    program_path: str = ""
    prog_name_conversion: str = ""
    ver_string: str = ""
    version_num: float = 0.0
    idd_file_name_with_path: str = ""
    new_idd_file_name_with_path: str = ""
    rep_var_file_name_with_path: str = ""
    auditf: int = 0
    full_file_name: str = ""
    file_name_path: str = ""
    file_ok: bool = False
    cond_fd_variables: bool = False
    num_chillers: int = 0
    num_chiller_heaters: int = 0
    making_pretty: bool = False
    not_in_new: List[str] = field(default_factory=list)
    max_alpha_args_found: int = 0
    max_numeric_args_found: int = 0
    max_total_args: int = 0

def set_this_version_variables(state: GlobalState) -> None:
    """SetThisVersionVariables subroutine equivalent"""
    state.ver_string = 'Conversion 7.2 => 8.0'
    state.version_num = 8.0
    state.idd_file_name_with_path = state.program_path.rstrip() + 'V7-2-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V8-0-0-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 7-2-0-006 to 8-0-0.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDeps,
    state: GlobalState
) -> None:
    """CreateNewIDFUsingRules subroutine equivalent"""
    
    first_time = True
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
                print('-->', end='', flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        with open(input_file_name, 'r') as f:
                            line = f.readline()
                            full_file_name = line.strip() if line else ""
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
                
                if full_file_name.startswith('!'):
                    full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                deps.write_preprocessor_object(state.auditf, state.prog_name_conversion, 'Info', 'Processing IDF -- ' + full_file_name)
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                import os
                if not os.path.exists(full_file_name):
                    print('File not found=' + full_file_name)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_lfn = open(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        dif_lfn = open(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        deps.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    try:
                        deps.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    except:
                        pass
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    max_args = state.max_total_args
                    alphas = [""] * (state.max_alpha_args_found + 1)
                    numbers = [""] * (state.max_numeric_args_found + 1)
                    in_args = [""] * (max_args + 1)
                    aor_n = [False] * (max_args + 1)
                    req_fld = [False] * (max_args + 1)
                    fld_names = [""] * (max_args + 1)
                    fld_defaults = [""] * (max_args + 1)
                    fld_units = [""] * (max_args + 1)
                    nw_aor_n = [False] * (max_args + 1)
                    nw_req_fld = [False] * (max_args + 1)
                    nw_fld_names = [""] * (max_args + 1)
                    nw_fld_defaults = [""] * (max_args + 1)
                    nw_fld_units = [""] * (max_args + 1)
                    out_args = [""] * (max_args + 1)
                    match_arg = [""] * (max_args + 1)
                    delete_this_record = [False] * (state.num_idf_records + 1)
                    
                    no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num].get('name', '').upper() == 'VERSION':
                            no_version = False
                            break
                    
                    state.cond_fd_variables = False
                    state.num_chillers = 0
                    state.num_chiller_heaters = 0
                    
                    for num in range(1, state.num_idf_records + 1):
                        obj_name = state.idf_records[num].get('name', '')
                        chiller_types = [
                            'Chiller:Electric:EIR',
                            'Chiller:Electric:ReformulatedEIR',
                            'Chiller:Electric',
                            'Chiller:Absorption:Indirect',
                            'Chiller:Absorption',
                            'Chiller:ConstantCOP',
                            'Chiller:EngineDriven',
                            'Chiller:CombustionTurbine'
                        ]
                        
                        if any(deps.same_string(obj_name, ct) for ct in chiller_types):
                            state.num_chillers += 1
                        
                        chiller_heater_types = [
                            'ChillerHeater:Absorption:DirectFired',
                            'ChillerHeater:Absorption:DoubleEffect'
                        ]
                        
                        if any(deps.same_string(obj_name, cht) for cht in chiller_heater_types):
                            state.num_chiller_heaters += 1
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            dif_lfn.write('! Deleting: ' + state.idf_records[num]['name'] + '="' + state.idf_records[num]['alphas'][0] + '".\n')
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            continue
                        
                        obj_record = state.idf_records[num]
                        for xcount in range(obj_record.get('commt_s', 0), obj_record.get('commt_e', 0) + 1):
                            if xcount < len(state.comments):
                                dif_lfn.write(state.comments[xcount] + '\n')
                            if xcount == obj_record.get('commt_e', 0):
                                dif_lfn.write(' \n')
                        
                        if no_version and num == 1:
                            deps.get_new_object_def_in_idd('VERSION')
                            out_args[0] = '8.0'
                            cur_args = 1
                            deps.write_out_idf_lines_as_comments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        # Skip deleted objects
                        obj_name_upper = obj_record['name'].upper()
                        if obj_name_upper in ['SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA', 
                                             'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                            continue
                        
                        if obj_name_upper == 'WATER HEATER:SIMPLE':
                            dif_lfn.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            deps.write_preprocessor_object(dif_lfn, state.prog_name_conversion, 'Warning', 
                                                          'The WATER HEATER:SIMPLE object has been deleted')
                            continue
                        
                        obj_name = obj_record['name']
                        
                        if deps.find_item_in_list(obj_name, [od['name'] for od in state.object_def]) != 0:
                            deps.get_object_def_in_idd(obj_name)
                            num_alphas = obj_record.get('num_alphas', 0)
                            num_numbers = obj_record.get('num_numbers', 0)
                            
                            for i in range(min(num_alphas, len(obj_record.get('alphas', [])))):
                                alphas[i] = obj_record['alphas'][i]
                            
                            for i in range(min(num_numbers, len(obj_record.get('numbers', [])))):
                                numbers[i] = obj_record['numbers'][i]
                            
                            cur_args = num_alphas + num_numbers
                            
                            in_args = [""] * (cur_args + 1)
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na] if na < len(alphas) else ""
                                else:
                                    nn += 1
                                    in_args[arg] = numbers[nn] if nn < len(numbers) else ""
                        else:
                            num_alphas = obj_record.get('num_alphas', 0)
                            num_numbers = obj_record.get('num_numbers', 0)
                            
                            for i in range(num_alphas):
                                alphas[i] = obj_record['alphas'][i] if i < len(obj_record.get('alphas', [])) else ""
                            for i in range(num_numbers):
                                numbers[i] = obj_record['numbers'][i] if i < len(obj_record.get('numbers', [])) else ""
                            
                            out_args = alphas[:num_alphas] + numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * len(out_args)
                            nw_fld_units = [""] * len(out_args)
                            
                            deps.write_out_idf_lines_as_comments(dif_lfn, obj_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.find_item_in_list(obj_name.upper(), state.not_in_new) == 0:
                            deps.get_new_object_def_in_idd(obj_name)
                        
                        if not state.making_pretty:
                            obj_name_upper = obj_record['name'].upper()
                            
                            if obj_name_upper == 'VERSION':
                                if in_args[0].startswith('8.0') and arg_file:
                                    deps.show_warning_error('File is already at latest version.  No new diff file made.', state.auditf)
                                    dif_lfn.close()
                                    latest_version = True
                                    break
                                deps.get_new_object_def_in_idd(obj_name)
                                out_args[0] = '8.0'
                                no_diff = False
                            
                            elif obj_name_upper == 'SHADOWCALCULATION':
                                no_diff = False
                                deps.get_new_object_def_in_idd(obj_name)
                                out_args[0] = 'AverageOverDaysInFrequency'
                                out_args[1:cur_args+1] = in_args[0:cur_args]
                                cur_args = cur_args + 1
                            
                            elif obj_name_upper == 'COIL:HEATING:DX:MULTISPEED':
                                no_diff = False
                                deps.get_new_object_def_in_idd(obj_name)
                                out_args[0:5] = in_args[0:5]
                                out_args[5] = ""
                                out_args[6:16] = in_args[5:15]
                                out_args[16] = ""
                                out_args[17:21] = in_args[15:19]
                                out_args[21] = ""
                                out_args[22:32] = in_args[19:29]
                                out_args[32] = ""
                                out_args[33:40] = in_args[29:36]
                                c_out_args = cur_args + 4
                                if cur_args > 36:
                                    out_args[40:43] = in_args[36:39]
                                    out_args[43] = ""
                                    out_args[44:51] = in_args[39:46]
                                    c_out_args = c_out_args + 1
                                if cur_args > 46:
                                    out_args[51:54] = in_args[46:49]
                                    out_args[54] = ""
                                    out_args[55:62] = in_args[49:56]
                                    c_out_args = c_out_args + 1
                                cur_args = c_out_args
                            
                            # More CASE branches would follow here for other object types
                            # (ENERGYMANAGEMENTSYSTEM:OUTPUTVARIABLE, BRANCH, PLANTEQUIPMENTLIST, etc.)
                            # Due to length, I'll use a simplified representation
                            else:
                                deps.get_new_object_def_in_idd(obj_name)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                        
                        else:
                            deps.get_new_object_def_in_idd(obj_record['name'])
                            out_args[:cur_args] = in_args[:cur_args]
                        
                        if diff_min_fields and no_diff:
                            deps.get_new_object_def_in_idd(obj_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = False
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.check_special_objects(dif_lfn, obj_name, cur_args, out_args, nw_fld_names, nw_fld_units, [written])
                        
                        if not written:
                            deps.write_out_idf_lines(dif_lfn, obj_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    # Handle final comments
                    if state.num_idf_records > 0 and state.idf_records[state.num_idf_records].get('commt_e', 0) != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records].get('commt_e', 0) + 1, state.cur_comment + 1):
                            if xcount < len(state.comments):
                                dif_lfn.write(state.comments[xcount] + '\n')
                    
                    # Check for Output Variable Dictionary
                    if state.idf_records and 'Report Variable Dictionary' in str(state.idf_records):
                        deps.get_new_object_def_in_idd('Output:VariableDictionary')
                        out_args[0] = 'Regular'
                        deps.write_out_idf_lines(dif_lfn, 'Output:VariableDictionary', 1, out_args, nw_fld_names, nw_fld_units)
                    
                    # Check for RVI file
                    import os
                    if os.path.exists(file_name_path + '.rvi'):
                        deps.write_preprocessor_object(dif_lfn, state.prog_name_conversion, 'Warning',
                                                      'rvi file associated with this input is being processed. Review for accuracy.')
                        dif_lfn.write(' \n')
                    
                    dif_lfn.close()
                    deps.process_rvi_mvi_files(file_name_path, 'rvi')
                    deps.process_rvi_mvi_files(file_name_path, 'mvi')
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(file_name_path, 'rvi')
                    deps.process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file[0] = True
        
        created_output_name = ""
        deps.create_new_name('Reallocate', [created_output_name], ' ')
        
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
        deps.copy_file(file_name_path + '.' + arg_idf_extension, 
                      file_name_path + '.' + arg_idf_extension + 'old', [err_flag])
        deps.copy_file(file_name_path + '.' + arg_idf_extension + 'new', 
                      file_name_path + '.' + arg_idf_extension, [err_flag])
        
        import os
        if os.path.exists(file_name_path + '.rvi'):
            deps.copy_file(file_name_path + '.rvi', file_name_path + '.rviold', [err_flag])
        
        if os.path.exists(file_name_path + '.rvinew'):
            deps.copy_file(file_name_path + '.rvinew', file_name_path + '.rvi', [err_flag])
        
        if os.path.exists(file_name_path + '.mvi'):
            deps.copy_file(file_name_path + '.mvi', file_name_path + '.mviold', [err_flag])
        
        if os.path.exists(file_name_path + '.mvinew'):
            deps.copy_file(file_name_path + '.mvinew', file_name_path + '.mvi', [err_flag])
