from typing import List, Any
from dataclasses import dataclass, field
import os

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor module: ProcessInput()
# - DataVCompareGlobals: module-level state
# - VCompareGlobalRoutines: subroutines
# - General: MakeLowerCase(), MakeUPPERCase(), samestring()
# - DataGlobals: ShowMessage(), ShowContinueError(), ShowFatalError(), ShowSevereError(), ShowWarningError()
# - System functions: GetNewUnitNumber(), FindNumber(), TrimTrailZeros(), copyfile()
# - IDD/Object management: GetObjectDefInIDD(), GetNewObjectDefInIDD(), FindItemInList()
# - Output writing: WriteOutIDFLinesAsComments(), WriteOutIDFLines(), CheckSpecialObjects()
# - Report variables: ScanOutputVariablesForReplacement()
# - File processing: ProcessRviMviFiles(), CloseOut(), DisplayString(), CreateNewName()

@dataclass
class IDFRecord:
    name: str = ''
    commt_s: int = 0
    commt_e: int = 0
    num_alphas: int = 0
    num_numbers: int = 0
    alphas: List[str] = field(default_factory=list)
    numbers: List[float] = field(default_factory=list)

@dataclass
class ObjectDefEntry:
    name: str = ''

@dataclass
class TransitionState:
    full_file_name: str = ''
    file_name_path: str = ''
    file_ok: bool = False
    blank: str = ''
    audit_f: Any = None
    program_path: str = ''
    ver_string: str = ''
    version_num: float = 1.0
    idd_file_name_with_path: str = ''
    new_idd_file_name_with_path: str = ''
    rep_var_file_name_with_path: str = ''
    num_idf_records: int = 0
    idf_records: List[IDFRecord] = field(default_factory=list)
    comments: List[str] = field(default_factory=list)
    cur_comment: int = 0
    processing_imf_file: bool = False
    fatal_error: bool = False
    making_pretty: bool = False
    max_alpha_args_found: int = 0
    max_numeric_args_found: int = 0
    max_total_args: 0
    object_def: List[ObjectDefEntry] = field(default_factory=list)
    num_object_defs: int = 0
    not_in_new: List[str] = field(default_factory=list)
    num_rep_var_names: int = 0
    old_rep_var_name: List[str] = field(default_factory=list)
    new_rep_var_name: List[str] = field(default_factory=list)

def make_lower_case(s: str) -> str:
    return s.lower()

def make_upper_case(s: str) -> str:
    return s.upper()

def trim_trailing_zeros(s: str) -> str:
    return s.rstrip('0').rstrip('.') if '.' in s else s

def find_item_in_list(item: str, lst: List[str], size: int) -> int:
    item_upper = make_upper_case(item)
    for i in range(size):
        if make_upper_case(lst[i]) == item_upper:
            return i + 1
    return 0

def samestring(s1: str, s2: str) -> bool:
    return make_upper_case(s1) == make_upper_case(s2)

def set_this_version_variables(state: TransitionState) -> None:
    state.ver_string = 'Conversion 1.2 => 1.2.1'
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path.rstrip() + 'V1-2-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path.rstrip() + 'V1-2-1-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path.rstrip() + 'Report Variables 1-2-0-029 to 1-2-1.csv'

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: TransitionState,
    external_functions: Any
) -> None:
    fmta = "(A)"
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    alphas: List[str] = []
    numbers: List[float] = []
    in_args: List[str] = []
    aor_n: List[bool] = []
    req_fld: List[bool] = []
    fld_names: List[str] = []
    fld_defaults: List[str] = []
    fld_units: List[str] = []
    nw_aor_n: List[bool] = []
    nw_req_fld: List[bool] = []
    nw_fld_names: List[str] = []
    nw_fld_defaults: List[str] = []
    nw_fld_units: List[str] = []
    out_args: List[str] = []
    match_arg: List[int] = []
    delete_this_record: List[bool] = []
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        line = external_functions['read_line'](in_lfn)
                        full_file_name = line
                        ios = 0
                    except:
                        full_file_name = state.blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = state.blank
                    continue
            
            units_arg = state.blank
            if ios != 0:
                full_file_name = state.blank
            
            full_file_name = full_file_name.lstrip()
            state.full_file_name = full_file_name
            
            if full_file_name != state.blank:
                external_functions['display_string']('Processing IDF -- ' + full_file_name.rstrip())
                state.audit_f.write(' Processing IDF -- ' + full_file_name.rstrip() + '\n')
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    state.file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    state.file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    state.audit_f.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    state.full_file_name = full_file_name
                    local_file_extension = 'idf'
                
                dif_lfn = external_functions['get_new_unit_number']()
                state.file_ok = os.path.exists(full_file_name.rstrip())
                
                if not state.file_ok:
                    print('File not found=' + full_file_name.rstrip())
                    state.audit_f.write('File not found=' + full_file_name.rstrip() + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    checkrvi = False
                    
                    if diff_only:
                        dif_file_name = state.file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_name = state.file_name_path + '.' + local_file_extension + 'new'
                    
                    dif_file = open(dif_file_name, 'w')
                    
                    if local_file_extension == 'imf':
                        external_functions['show_warning_error'](
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            state.audit_f)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    external_functions['process_input'](
                        state.idd_file_name_with_path,
                        state.new_idd_file_name_with_path,
                        full_file_name.rstrip(),
                        state,
                        external_functions)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        dif_file.close()
                        break
                    
                    alphas = [state.blank] * state.max_alpha_args_found
                    numbers = [0.0] * state.max_numeric_args_found
                    in_args = [state.blank] * state.max_total_args
                    aor_n = [False] * state.max_total_args
                    req_fld = [False] * state.max_total_args
                    fld_names = [state.blank] * state.max_total_args
                    fld_defaults = [state.blank] * state.max_total_args
                    fld_units = [state.blank] * state.max_total_args
                    nw_aor_n = [False] * state.max_total_args
                    nw_req_fld = [False] * state.max_total_args
                    nw_fld_names = [state.blank] * state.max_total_args
                    nw_fld_defaults = [state.blank] * state.max_total_args
                    nw_fld_units = [state.blank] * state.max_total_args
                    out_args = [state.blank] * state.max_total_args
                    match_arg = [0] * state.max_total_args
                    delete_this_record = [False] * state.num_idf_records
                    
                    no_version = True
                    for num in range(state.num_idf_records):
                        if make_upper_case(state.idf_records[num].name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        for xcount in range(state.idf_records[num].commt_s, state.idf_records[num].commt_e + 1):
                            if xcount < len(state.comments):
                                dif_file.write(state.comments[xcount].rstrip() + '\n')
                            if xcount == state.idf_records[num].commt_e:
                                dif_file.write(' \n')
                        
                        if no_version and num == 0:
                            external_functions['get_new_object_def_in_idd'](
                                'VERSION',
                                state,
                                external_functions)
                            out_args[0] = '1.2.1'
                            cur_args = 1
                            external_functions['write_out_idf_lines_as_comments'](
                                dif_file, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if make_upper_case(state.idf_records[num].name.rstrip()) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        
                        object_name = state.idf_records[num].name
                        
                        if find_item_in_list(object_name, [d.name for d in state.object_def], state.num_object_defs) != 0:
                            external_functions['get_object_def_in_idd'](
                                object_name,
                                state,
                                external_functions)
                            
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            for i in range(num_alphas):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.idf_records[num].numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = [state.blank] * state.max_total_args
                            out_args = [state.blank] * state.max_total_args
                            
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
                            state.audit_f.write('Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.\n')
                            state.audit_f.write('... will be listed as comments (no field names) on the new output file.\n')
                            state.audit_f.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            for i in range(num_alphas):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.idf_records[num].numbers[i]
                            
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            
                            nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = str(numbers[arg])
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [state.blank] * state.max_total_args
                            nw_fld_units = [state.blank] * state.max_total_args
                            
                            external_functions['write_out_idf_lines_as_comments'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(make_upper_case(object_name), state.not_in_new, len(state.not_in_new)) == 0:
                            external_functions['get_new_object_def_in_idd'](
                                object_name,
                                state,
                                external_functions)
                            # ObjMinFlds vs NwObjMinFlds comparison would require state tracking
                        
                        if not state.making_pretty:
                            object_upper = make_upper_case(state.idf_records[num].name.rstrip())
                            
                            if object_upper == 'VERSION':
                                if in_args[0][:5] == '1.2.1' and arg_file:
                                    external_functions['show_warning_error'](
                                        'File is already at latest version.  No new diff file made.',
                                        state.audit_f)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                out_args[0] = '1.2.1'
                            
                            elif object_upper == 'DESICCANT DEHUMIDIFIER:SOLID':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[13]) == 'FAN:SIMPLE:CONSTVOLUME' and
                                    make_upper_case(out_args[15]) == 'DEFAULT'):
                                    dif_file.write(' ! Following Object (field 14) needs to be "Fan:Simple:VariableVolume" with coefficients (0,1,0,0,0) or changed\n')
                                    external_functions['show_warning_error'](
                                        'Desiccant Dehumidifier:Solid ' + out_args[0].rstrip() + ' needs change.  See resultant input file for explanation.',
                                        state.audit_f)
                                nodiff = False
                            
                            elif object_upper == 'GROUND HEAT EXCHANGER:POND':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if make_upper_case(out_args[3]) != 'WATER':
                                    dif_file.write(' Following Object may need manual manipulation to work\n')
                                    external_functions['show_warning_error'](
                                        'Ground Heat Exchanger:Pond="' + out_args[0].rstrip() + '" may need manual change to work.',
                                        state.audit_f)
                                    nodiff = False
                            
                            elif object_upper == 'GROUND HEAT EXCHANGER:SURFACE':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if make_upper_case(out_args[4]) != 'WATER':
                                    dif_file.write(' Following Object may need manual manipulation to work\n')
                                    external_functions['show_warning_error'](
                                        'Ground Heat Exchanger:Surface="' + out_args[0].rstrip() + '" may need manual change to work.',
                                        state.audit_f)
                                    nodiff = False
                            
                            elif object_upper == 'HEAT EXCHANGER:HYDRONIC:FREE COOLING':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[8]) != 'WATER' or
                                    make_upper_case(out_args[9]) != 'WATER'):
                                    dif_file.write(' Following Object may need manual manipulation to work\n')
                                    external_functions['show_warning_error'](
                                        'Heat Exchanger:Hydronic:Free Cooling="' + out_args[0].rstrip() + '" may need manual change to work.',
                                        state.audit_f)
                                    nodiff = False
                            
                            elif object_upper == 'HEAT EXCHANGER:PLATE:FREE COOLING':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if (make_upper_case(out_args[7]) != 'WATER' or
                                    make_upper_case(out_args[8]) != 'WATER'):
                                    dif_file.write(' Following Object may need manual manipulation to work\n')
                                    external_functions['show_warning_error'](
                                        'Heat Exchanger:Plate:Free Cooling="' + out_args[0].rstrip() + '" may need manual change to work.',
                                        state.audit_f)
                                    nodiff = False
                            
                            elif object_upper == 'BUILDING':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if cur_args == 8:
                                    nodiff = False
                                    if make_upper_case(out_args[7]) == 'YES':
                                        out_args[5] = out_args[5].rstrip() + 'WithReflections'
                                        out_args[7] = state.blank
                                        cur_args = 7
                                    elif make_upper_case(out_args[7]) == 'NO':
                                        out_args[7] = state.blank
                                        cur_args = 7
                            
                            elif (object_upper == 'SET POINT MANAGER:SINGLE ZONE MIN HUM' or
                                  object_upper == 'SET POINT MANAGER:SINGLE ZONE MAX HUM'):
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                out_args[1] = state.blank
                                out_args[2] = state.blank
                            
                            elif object_upper == 'WINDOWSHADINGCONTROL':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                
                                if samestring('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if samestring('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if samestring('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if samestring('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                
                                if samestring('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if samestring('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if samestring('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if samestring('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutsideAirTemp'
                                if samestring('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemp'
                                if samestring('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if samestring('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if samestring('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif object_upper == 'REPORT VARIABLE':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                
                                del_this = [False]
                                external_functions['scan_output_variables_for_replacement'](
                                    2, del_this, checkrvi, nodiff, object_name, dif_file,
                                    True, False, False, cur_args, written, False, out_args, state, external_functions)
                                if del_this[0]:
                                    continue
                            
                            elif (object_upper == 'REPORT METER' or
                                  object_upper == 'REPORT METERFILEONLY' or
                                  object_upper == 'REPORT CUMULATIVE METER' or
                                  object_upper == 'REPORT CUMULATIVE METERFILEONLY'):
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                del_this = [False]
                                external_functions['scan_output_variables_for_replacement'](
                                    1, del_this, checkrvi, nodiff, object_name, dif_file,
                                    False, True, False, cur_args, written, False, out_args, state, external_functions)
                                if del_this[0]:
                                    continue
                            
                            elif object_upper == 'REPORT:TABLE:TIMEBINS':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                del_this = [False]
                                external_functions['scan_output_variables_for_replacement'](
                                    2, del_this, checkrvi, nodiff, object_name, dif_file,
                                    False, False, True, cur_args, written, False, out_args, state, external_functions)
                                if del_this[0]:
                                    continue
                            
                            elif object_upper == 'REPORT:TABLE:MONTHLY':
                                external_functions['get_new_object_def_in_idd'](
                                    object_name,
                                    state,
                                    external_functions)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == state.blank:
                                    out_args[0] = '*'
                                    nodiff = False
                                
                                cur_var = 3
                                var = 3
                                while var < cur_args:
                                    uc_rep_var_name = make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(state.num_rep_var_names):
                                        uc_comp_rep_var_name = make_upper_case(state.old_rep_var_name[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1] + ' '
                                        
                                        pos_idx = uc_rep_var_name.find(uc_comp_rep_var_name.rstrip())
                                        if pos_idx > 0 and pos_idx != 0:
                                            var += 2
                                            continue
                                        
                                        if pos_idx >= 0:
                                            if state.new_rep_var_name[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.num_rep_var_names - 1 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 1].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            
                                            if arg < state.num_rep_var_names - 2 and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 2].rstrip() + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    state.audit_f.write('Object="' + object_name.rstrip() + '" is not in the "new" IDD.\n')
                                    state.audit_f.write('... will be listed as comments on the new output file.\n')
                                    external_functions['write_out_idf_lines_as_comments'](
                                        dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    external_functions['get_new_object_def_in_idd'](
                                        object_name,
                                        state,
                                        external_functions)
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    nodiff = True
                        
                        else:
                            external_functions['get_new_object_def_in_idd'](
                                state.idf_records[num].name,
                                state,
                                external_functions)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if not written:
                            external_functions['check_special_objects'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            external_functions['write_out_idf_lines'](
                                dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.idf_records[state.num_idf_records - 1].commt_e != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records - 1].commt_e + 1, state.cur_comment + 1):
                            if xcount < len(state.comments):
                                dif_file.write(state.comments[xcount].rstrip() + '\n')
                            if xcount == state.idf_records[state.num_idf_records - 1].commt_e:
                                dif_file.write(' \n')
                    
                    dif_file.close()
                    
                    if checkrvi:
                        external_functions['process_rvi_mvi_files'](state.file_name_path, 'rvi')
                        external_functions['process_rvi_mvi_files'](state.file_name_path, 'mvi')
                    
                    external_functions['close_out']()
                
                else:
                    external_functions['process_rvi_mvi_files'](state.file_name_path, 'rvi')
                    external_functions['process_rvi_mvi_files'](state.file_name_path, 'mvi')
            
            else:
                end_of_file[0] = True
            
            external_functions['create_new_name']('Reallocate', state)
        
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
        external_functions['copyfile'](
            state.file_name_path + '.' + arg_idf_extension,
            state.file_name_path + '.' + arg_idf_extension + 'old',
            err_flag)
        external_functions['copyfile'](
            state.file_name_path + '.' + arg_idf_extension + 'new',
            state.file_name_path + '.' + arg_idf_extension,
            err_flag)
        
        if os.path.exists(state.file_name_path + '.rvi'):
            external_functions['copyfile'](
                state.file_name_path + '.rvi',
                state.file_name_path + '.rviold',
                err_flag)
        
        if os.path.exists(state.file_name_path + '.rvinew'):
            external_functions['copyfile'](
                state.file_name_path + '.rvinew',
                state.file_name_path + '.rvi',
                err_flag)
        
        if os.path.exists(state.file_name_path + '.mvi'):
            external_functions['copyfile'](
                state.file_name_path + '.mvi',
                state.file_name_path + '.mviold',
                err_flag)
        
        if os.path.exists(state.file_name_path + '.mvinew'):
            external_functions['copyfile'](
                state.file_name_path + '.mvinew',
                state.file_name_path + '.mvi',
                err_flag)
