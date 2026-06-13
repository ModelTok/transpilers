from typing import Protocol, List, Dict, Any, Tuple, Optional
from dataclasses import dataclass, field
import os
import re

# EXTERNAL DEPS (to wire in glue):
# - ProgNameConversion: str
# - blank: str
# - MaxNameLength: int
# - MaxAlphaArgsFound: int
# - MaxNumericArgsFound: int
# - MaxTotalArgs: int
# - ProgPath: str
# - Auditf: file handle
# - IDFRecords: List[IDFRecord]
# - Comments: List[str]
# - Alphas: List[str]
# - Numbers: List[float]
# - InArgs: List[str]
# - TempArgs: List[str]
# - AorN: List[bool]
# - ReqFld: List[bool]
# - FldNames: List[str]
# - FldDefaults: List[str]
# - FldUnits: List[str]
# - NwAorN: List[bool]
# - NwReqFld: List[bool]
# - NwFldNames: List[str]
# - NwFldDefaults: List[str]
# - NwFldUnits: List[str]
# - OutArgs: List[str]
# - MatchArg: List[str]
# - PAorN: List[bool]
# - PReqFld: List[bool]
# - PFldNames: List[str]
# - PFldDefaults: List[str]
# - PFldUnits: List[str]
# - POutArgs: List[str]
# - DeleteThisRecord: List[bool]
# - ObjectDef: List of object definitions with Name field
# - NumObjectDefs: int
# - NumIDFRecords: int
# - NumRepVarNames: int
# - CurComment: int
# - ProcessingIMFFile: bool
# - FatalError: bool
# - FileOK: bool
# - VersionNum: float
# - sVersionNum: str
# - VerString: str
# - IDDFileNameWithPath: str
# - NewIDDFileNameWithPath: str
# - RepVarFileNameWithPath: str
# - OldRepVarName: List[str]
# - NewRepVarName: List[str]
# - NewRepVarCaution: List[str]
# - OTMVarCaution: List[bool]
# - CMtrVarCaution: List[bool]
# - CMtrDVarCaution: List[bool]
# - External functions: GetNewUnitNumber, TrimTrailZeros, FindItemInList,
#   GetObjectDefInIDD, GetNewObjectDefInIDD, MakeUPPERCase, MakeLowerCase,
#   SameString, DisplayString, ProcessInput, CheckSpecialObjects,
#   WriteOutIDFLines, WriteOutIDFLinesAsComments, writePreprocessorObject,
#   CreateNewName, CloseOut, ProcessRviMviFiles, ShowWarningError, copyfile,
#   GetNumSectionsFound

class ExternalState(Protocol):
    ProgNameConversion: str
    blank: str
    MaxNameLength: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    ProgPath: str
    Auditf: Any
    IDFRecords: List[Any]
    Comments: List[str]
    Alphas: List[str]
    Numbers: List[float]
    InArgs: List[str]
    TempArgs: List[str]
    AorN: List[bool]
    ReqFld: List[bool]
    FldNames: List[str]
    FldDefaults: List[str]
    FldUnits: List[str]
    NwAorN: List[bool]
    NwReqFld: List[bool]
    NwFldNames: List[str]
    NwFldDefaults: List[str]
    NwFldUnits: List[str]
    OutArgs: List[str]
    MatchArg: List[str]
    PAorN: List[bool]
    PReqFld: List[bool]
    PFldNames: List[str]
    PFldDefaults: List[str]
    PFldUnits: List[str]
    POutArgs: List[str]
    DeleteThisRecord: List[bool]
    ObjectDef: List[Any]
    NumObjectDefs: int
    NumIDFRecords: int
    NumRepVarNames: int
    CurComment: int
    ProcessingIMFFile: bool
    FatalError: bool
    FileOK: bool
    VersionNum: float
    sVersionNum: str
    VerString: str
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]

def set_this_version_variables(state: ExternalState) -> None:
    state.VerString = 'Conversion 9.0 => 9.1'
    state.VersionNum = 9.1
    state.sVersionNum = '9.1'
    state.IDDFileNameWithPath = state.ProgPath.rstrip() + 'V9-0-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgPath.rstrip() + 'V9-1-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgPath.rstrip() + 'Report Variables 9-0-0 to 9-1-0.csv'

def trim_string(s: str) -> str:
    return s.rstrip()

def scan_backward(s: str, chars: str) -> int:
    for i in range(len(s) - 1, -1, -1):
        if s[i] in chars:
            return i + 1
    return 0

def make_lower_case(s: str) -> str:
    return s.lower()

def make_upper_case(s: str) -> str:
    return s.upper()

def find_item_in_list(item: str, lst: List[str], size: int) -> int:
    for i in range(min(size, len(lst))):
        if make_upper_case(lst[i]) == make_upper_case(item):
            return i + 1
    return 0

def same_string(s1: str, s2: str) -> bool:
    return make_upper_case(s1) == make_upper_case(s2)

def create_new_idf_using_rules(
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: ExternalState,
    get_new_unit_number: callable,
    trim_trail_zeros: callable,
    display_string: callable,
    process_input: callable,
    get_object_def_in_idd: callable,
    get_new_object_def_in_idd: callable,
    check_special_objects: callable,
    write_out_idf_lines: callable,
    write_out_idf_lines_as_comments: callable,
    write_preprocessor_object: callable,
    create_new_name: callable,
    close_out: callable,
    process_rvi_mvi_files: callable,
    show_warning_error: callable,
    copyfile: callable,
    get_num_sections_found: callable
) -> None:
    
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
    
    full_file_name = state.blank
    file_name_path = state.blank
    
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
                        full_file_name = input()
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
            
            if full_file_name != state.blank:
                display_string('Processing IDF -- ' + trim_string(full_file_name))
                state.Auditf.write(' Processing IDF -- ' + trim_string(full_file_name) + '\n')
                
                dot_pos = 0
                for i in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[i] == '.':
                        dot_pos = i
                        break
                
                if dot_pos != 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    state.Auditf.write(' ..assuming file extension of .idf\n')
                    full_file_name = trim_string(full_file_name) + '.idf'
                    local_file_extension = 'idf'
                
                dif_lfn = get_new_unit_number()
                file_ok = os.path.exists(trim_string(full_file_name))
                
                if not file_ok:
                    print('File not found=' + trim_string(full_file_name))
                    state.Auditf.write('File not found=' + trim_string(full_file_name) + '\n')
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        dif_file = open(trim_string(file_name_path) + '.' + trim_string(local_file_extension) + 'dif', 'w')
                    else:
                        dif_file = open(trim_string(file_name_path) + '.' + trim_string(local_file_extension) + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    process_input(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name, state)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    state.DeleteThisRecord = [False] * state.NumIDFRecords
                    state.Alphas = [state.blank] * state.MaxAlphaArgsFound
                    state.Numbers = [0.0] * state.MaxNumericArgsFound
                    state.InArgs = [state.blank] * state.MaxTotalArgs
                    state.TempArgs = [state.blank] * state.MaxTotalArgs
                    state.AorN = [False] * state.MaxTotalArgs
                    state.ReqFld = [False] * state.MaxTotalArgs
                    state.FldNames = [state.blank] * state.MaxTotalArgs
                    state.FldDefaults = [state.blank] * state.MaxTotalArgs
                    state.FldUnits = [state.blank] * state.MaxTotalArgs
                    state.NwAorN = [False] * state.MaxTotalArgs
                    state.NwReqFld = [False] * state.MaxTotalArgs
                    state.NwFldNames = [state.blank] * state.MaxTotalArgs
                    state.NwFldDefaults = [state.blank] * state.MaxTotalArgs
                    state.NwFldUnits = [state.blank] * state.MaxTotalArgs
                    state.OutArgs = [state.blank] * state.MaxTotalArgs
                    state.POutArgs = [state.blank] * state.MaxTotalArgs
                    state.MatchArg = [state.blank] * state.MaxTotalArgs
                    state.PAorN = [False] * state.MaxTotalArgs
                    state.PReqFld = [False] * state.MaxTotalArgs
                    state.PFldNames = [state.blank] * state.MaxTotalArgs
                    state.PFldDefaults = [state.blank] * state.MaxTotalArgs
                    state.PFldUnits = [state.blank] * state.MaxTotalArgs
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for num in range(state.NumIDFRecords):
                        if not same_string(state.IDFRecords[num].Name, 'ScheduleTypeLimits'):
                            continue
                        if not same_string(state.IDFRecords[num].Alphas[0] if num < len(state.IDFRecords) and state.IDFRecords[num].Alphas else state.blank, 'Any Number'):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            dif_file.write('! Deleting: ' + trim_string(state.IDFRecords[num].Name) + '="' + trim_string(state.IDFRecords[num].Alphas[0] if state.IDFRecords[num].Alphas else state.blank) + '".\n')
                    
                    display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(state.NumIDFRecords):
                        if state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE):
                            dif_file.write(trim_string(state.Comments[xcount]) + '\n')
                            if xcount == state.IDFRecords[num].CommtE - 1:
                                dif_file.write('\n')
                        
                        if no_version and num == 0:
                            get_new_object_def_in_idd('VERSION', state)
                            state.OutArgs[0] = state.sVersionNum
                            cur_args = 1
                            write_out_idf_lines_as_comments(dif_file, 'Version', cur_args, state)
                        
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'PROGRAMCONTROL':
                            continue
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'AIRFLOW MODEL':
                            continue
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if make_upper_case(trim_string(state.IDFRecords[num].Name)) == 'WATER HEATER:SIMPLE':
                            dif_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning', 'The WATER HEATER:SIMPLE object has been deleted', state)
                            continue
                        
                        object_name = state.IDFRecords[num].Name
                        obj_found = find_item_in_list(object_name, [obj.Name if hasattr(obj, 'Name') else '' for obj in state.ObjectDef], state.NumObjectDefs)
                        
                        if obj_found != 0:
                            get_object_def_in_idd(object_name, state)
                            num_alphas = state.IDFRecords[num].NumAlphas if hasattr(state.IDFRecords[num], 'NumAlphas') else 0
                            num_numbers = state.IDFRecords[num].NumNumbers if hasattr(state.IDFRecords[num], 'NumNumbers') else 0
                            state.Alphas[0:num_alphas] = state.IDFRecords[num].Alphas[0:num_alphas] if hasattr(state.IDFRecords[num], 'Alphas') else []
                            state.Numbers[0:num_numbers] = state.IDFRecords[num].Numbers[0:num_numbers] if hasattr(state.IDFRecords[num], 'Numbers') else []
                            cur_args = num_alphas + num_numbers
                            state.InArgs = [state.blank] * state.MaxTotalArgs
                            state.OutArgs = [state.blank] * state.MaxTotalArgs
                            state.TempArgs = [state.blank] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if state.AorN[arg]:
                                    state.InArgs[arg] = state.Alphas[na]
                                    na += 1
                                else:
                                    state.InArgs[arg] = str(state.Numbers[nn])
                                    nn += 1
                        else:
                            state.Auditf.write('Object="' + trim_string(object_name) + '" does not seem to be on the "old" IDD.\n')
                            state.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                            state.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            num_alphas = state.IDFRecords[num].NumAlphas if hasattr(state.IDFRecords[num], 'NumAlphas') else 0
                            num_numbers = state.IDFRecords[num].NumNumbers if hasattr(state.IDFRecords[num], 'NumNumbers') else 0
                            state.Alphas[0:num_alphas] = state.IDFRecords[num].Alphas[0:num_alphas] if hasattr(state.IDFRecords[num], 'Alphas') else []
                            state.Numbers[0:num_numbers] = state.IDFRecords[num].Numbers[0:num_numbers] if hasattr(state.IDFRecords[num], 'Numbers') else []
                            for arg in range(num_alphas):
                                state.OutArgs[arg] = state.Alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                state.OutArgs[nn] = str(state.Numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            state.NwFldNames = [state.blank] * state.MaxTotalArgs
                            state.NwFldUnits = [state.blank] * state.MaxTotalArgs
                            write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(make_upper_case(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            get_new_object_def_in_idd(object_name, state)
                        
                        obj_min_flds = getattr(state, 'ObjMinFlds', 0)
                        nw_obj_min_flds = getattr(state, 'NwObjMinFlds', 0)
                        
                        if obj_min_flds != nw_obj_min_flds:
                            diff_min_fields = True
                        else:
                            diff_min_fields = False
                        
                        if not getattr(state, 'MakingPretty', False):
                            obj_name_upper = make_upper_case(trim_string(state.IDFRecords[num].Name))
                            
                            if obj_name_upper == 'VERSION':
                                if state.InArgs[0][0:3] == state.sVersionNum and arg_file:
                                    show_warning_error('File is already at latest version.  No new diff file made.', state.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[0] = state.sVersionNum
                                no_diff = False
                            
                            elif obj_name_upper == 'HYBRIDMODEL:ZONE':
                                get_new_object_def_in_idd(object_name, state)
                                no_diff = False
                                state.OutArgs[0:4] = state.InArgs[0:4]
                                state.OutArgs[4] = 'No'
                                state.OutArgs[5] = state.InArgs[4]
                                state.OutArgs[6:16] = [state.blank] * 10
                                state.OutArgs[16:20] = state.InArgs[5:9]
                                cur_args = 20
                                no_diff = False
                            
                            elif obj_name_upper == 'ZONEHVAC:EQUIPMENTLIST':
                                get_new_object_def_in_idd(object_name, state)
                                no_diff = False
                                state.OutArgs[0] = state.InArgs[0]
                                state.OutArgs[1] = state.InArgs[1]
                                for i in range(1, (cur_args - 2) // 4 + 1):
                                    state.OutArgs[(i - 1) * 6 + 2] = state.InArgs[(i - 1) * 4 + 2]
                                    state.OutArgs[(i - 1) * 6 + 3] = state.InArgs[(i - 1) * 4 + 3]
                                    state.OutArgs[(i - 1) * 6 + 4] = state.InArgs[(i - 1) * 4 + 4]
                                    state.OutArgs[(i - 1) * 6 + 5] = state.InArgs[(i - 1) * 4 + 5]
                                    state.OutArgs[(i - 1) * 6 + 6] = ""
                                    state.OutArgs[(i - 1) * 6 + 7] = ""
                                cur_args = ((cur_args - 2) // 4) * 6 + 2
                            
                            elif obj_name_upper == 'OUTPUT:VARIABLE':
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                                no_diff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = '*'
                                    no_diff = False
                            
                            elif obj_name_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                                no_diff = True
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:TIMEBINS':
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                                no_diff = True
                                if state.OutArgs[0] == state.blank:
                                    state.OutArgs[0] = '*'
                                    no_diff = False
                            
                            elif obj_name_upper == 'OUTPUT:TABLE:MONTHLY':
                                get_new_object_def_in_idd(object_name, state)
                                no_diff = True
                                state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = make_upper_case(state.InArgs[var])
                                    state.OutArgs[cur_var] = state.InArgs[var]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos]
                                        state.OutArgs[cur_var] = state.InArgs[var][0:pos]
                                        state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                        wild_match = False
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
                                            if state.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg] and not same_string(state.NewRepVarCaution[arg][0:6], 'Forkeq'):
                                                    if not state.OTMVarCaution[arg]:
                                                        write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning', 
                                                            'Output Table Monthly (old)="' + trim_string(state.OldRepVarName[arg]) + '" conversion to Output Table Monthly (new)="' + trim_string(state.NewRepVarName[arg]) + '" has the following caution "' + trim_string(state.NewRepVarCaution[arg]) + '".', state)
                                                        dif_file.write(' \n')
                                                        state.OTMVarCaution[arg] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            
                                            if arg < state.NumRepVarNames - 1 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                if not same_string(state.NewRepVarCaution[arg][0:6], 'Forkeq'):
                                                    cur_var += 2
                                                    if not wild_match:
                                                        state.OutArgs[cur_var] = state.NewRepVarName[arg + 1]
                                                    else:
                                                        state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg + 1]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                    if state.NewRepVarCaution[arg + 1]:
                                                        if not state.OTMVarCaution[arg + 1]:
                                                            write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                                'Output Table Monthly (old)="' + trim_string(state.OldRepVarName[arg]) + '" conversion to Output Table Monthly (new)="' + trim_string(state.NewRepVarName[arg + 1]) + '" has the following caution "' + trim_string(state.NewRepVarCaution[arg + 1]) + '".', state)
                                                            dif_file.write(' \n')
                                                            state.OTMVarCaution[arg + 1] = True
                                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                    no_diff = False
                                            
                                            if arg < state.NumRepVarNames - 2 and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    state.OutArgs[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    state.OutArgs[cur_var] = trim_string(state.NewRepVarName[arg + 2]) + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                                if state.NewRepVarCaution[arg + 2]:
                                                    if not state.OTMVarCaution[arg + 2]:
                                                        write_preprocessor_object(dif_file, state.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + trim_string(state.OldRepVarName[arg]) + '" conversion to Output Table Monthly (new)="' + trim_string(state.NewRepVarName[arg + 2]) + '" has the following caution "' + trim_string(state.NewRepVarCaution[arg + 2]) + '".', state)
                                                        dif_file.write(' \n')
                                                        state.OTMVarCaution[arg + 2] = True
                                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            else:
                                if find_item_in_list(object_name, getattr(state, 'NotInNew', []), len(getattr(state, 'NotInNew', []))) != 0:
                                    state.Auditf.write('Object="' + trim_string(object_name) + '" is not in the "new" IDD.\n')
                                    state.Auditf.write('... will be listed as comments on the new output file.\n')
                                    write_out_idf_lines_as_comments(dif_file, object_name, cur_args, state)
                                    written = True
                                else:
                                    get_new_object_def_in_idd(object_name, state)
                                    state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                                    no_diff = True
                        
                        else:
                            get_new_object_def_in_idd(state.IDFRecords[num].Name, state)
                            state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                        
                        if diff_min_fields and no_diff:
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0:cur_args] = state.InArgs[0:cur_args]
                            no_diff = False
                            nw_obj_min_flds = getattr(state, 'NwObjMinFlds', 0)
                            for arg in range(cur_args, nw_obj_min_flds):
                                state.OutArgs[arg] = state.NwFldDefaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_file, object_name, cur_args, state)
                        
                        if not written:
                            write_out_idf_lines(dif_file, object_name, cur_args, state)
                    
                    display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE, state.CurComment):
                            dif_file.write(trim_string(state.Comments[xcount]) + '\n')
                            if xcount == state.IDFRecords[state.NumIDFRecords - 1].CommtE:
                                dif_file.write('\n')
                    
                    if get_num_sections_found('Report Variable Dictionary', state) > 0:
                        object_name = 'Output:VariableDictionary'
                        get_new_object_def_in_idd(object_name, state)
                        state.OutArgs[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines(dif_file, object_name, cur_args, state)
                    
                    dif_file.close()
                    process_rvi_mvi_files(file_name_path, 'rvi', state)
                    process_rvi_mvi_files(file_name_path, 'mvi', state)
                    close_out(state)
                else:
                    process_rvi_mvi_files(file_name_path, 'rvi', state)
                    process_rvi_mvi_files(file_name_path, 'mvi', state)
            else:
                end_of_file[0] = True
            
            create_new_name('Reallocate', state)
        
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
        copyfile(trim_string(file_name_path) + '.' + trim_string(arg_idf_extension),
                 trim_string(file_name_path) + '.' + trim_string(arg_idf_extension) + 'old', state)
        copyfile(trim_string(file_name_path) + '.' + trim_string(arg_idf_extension) + 'new',
                 trim_string(file_name_path) + '.' + trim_string(arg_idf_extension), state)
        file_exist = os.path.exists(trim_string(file_name_path) + '.rvi')
        if file_exist:
            copyfile(trim_string(file_name_path) + '.rvi', trim_string(file_name_path) + '.rviold', state)
        file_exist = os.path.exists(trim_string(file_name_path) + '.rvinew')
        if file_exist:
            copyfile(trim_string(file_name_path) + '.rvinew', trim_string(file_name_path) + '.rvi', state)
        file_exist = os.path.exists(trim_string(file_name_path) + '.mvi')
        if file_exist:
            copyfile(trim_string(file_name_path) + '.mvi', trim_string(file_name_path) + '.mviold', state)
        file_exist = os.path.exists(trim_string(file_name_path) + '.mvinew')
        if file_exist:
            copyfile(trim_string(file_name_path) + '.mvinew', trim_string(file_name_path) + '.mvi', state)
