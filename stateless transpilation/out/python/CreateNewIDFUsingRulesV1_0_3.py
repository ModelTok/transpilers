from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Any
from enum import Enum
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: Blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - DataVCompareGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, 
#                        RepVarFileNameWithPath, ProgramPath, FullFileName, FileNamePath,
#                        Comments, IDFRecords, NumIDFRecords, CurComment, FatalError,
#                        ProcessingIMFFile, Auditf, ObjectDef, NumObjectDefs, OldRepVarName,
#                        NewRepVarName, NumRepVarNames, NotInNew, MakingPretty
# - VCompareGlobalRoutines: various state management
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumObjectsFound
# - General: various utility functions
# - DataGlobals: error reporting functions
# External functions: GetNewUnitNumber(), FindNumber(), TrimTrailZeros()

class GlobalState(Protocol):
    """External dependencies that must be provided"""
    Blank: str
    MaxNameLength: int
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    VerString: str
    VersionNum: float
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    ProgramPath: str
    FullFileName: str
    FileNamePath: str
    Comments: List[str]
    IDFRecords: List[Any]
    NumIDFRecords: int
    CurComment: int
    FatalError: bool
    ProcessingIMFFile: bool
    Auditf: int
    ObjectDef: List[Any]
    NumObjectDefs: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NumRepVarNames: int
    NotInNew: List[str]
    MakingPretty: bool


@dataclass
class IDFRecord:
    Name: str = ""
    NumAlphas: int = 0
    NumNumbers: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[float] = field(default_factory=list)
    CommtS: int = 0
    CommtE: int = 0


def set_this_version_variables(state: GlobalState) -> None:
    """SetThisVersionVariables subroutine"""
    state.VerString = 'Conversion 1.0.2 => 1.0.3'
    state.VersionNum = 1.0
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-0-2-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V1-0-3-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 1-0-2-008 to 1-0-3.csv'


def trim_string(s: str) -> str:
    """TRIM equivalent"""
    return s.rstrip()


def adjust_left(s: str) -> str:
    """ADJUSTL equivalent"""
    return s.lstrip()


def make_lower_case(s: str) -> str:
    """MakeLowerCase equivalent"""
    return s.lower()


def make_upper_case(s: str) -> str:
    """MakeUPPERCase equivalent"""
    return s.upper()


def same_string(s1: str, s2: str) -> bool:
    """Case-insensitive string comparison"""
    return s1.lower() == s2.lower()


def find_item_in_list(target: str, list_items: List[str], size: int) -> int:
    """FindItemInList - returns 1-based index or 0 if not found"""
    target_upper = make_upper_case(target)
    for i in range(min(size, len(list_items))):
        if make_upper_case(list_items[i]) == target_upper:
            return i + 1
    return 0


def create_new_idf_using_rules(
    state: GlobalState,
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    # External functions (inject these)
    get_new_unit_number,
    find_number,
    trim_trail_zeros,
    display_string,
    process_input,
    get_object_def_in_idd,
    get_new_object_def_in_idd,
    get_num_objects_found,
    show_warning_error,
    show_severe_error,
    scan_output_variables_for_replacement,
    check_special_objects,
    write_out_idf_lines,
    write_out_idf_lines_as_comments,
    process_rvi_mvi_files,
    close_out,
    create_new_name,
    copy_file,
    process_number,
) -> bool:
    """CreateNewIDFUsingRules subroutine - returns EndOfFile status"""
    
    fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file_local = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file_local:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        ios = 1
                        full_file_name = ""
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.Blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = state.Blank
                    continue
            
            if ios != 0:
                full_file_name = state.Blank
            
            full_file_name = adjust_left(full_file_name)
            
            if full_file_name != state.Blank:
                display_string('Processing IDF -- ' + trim_string(full_file_name))
                
                # Find last occurrence of '.'
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = trim_string(full_file_name) + '.idf'
                    local_file_extension = 'idf'
                
                state.FileNamePath = file_name_path
                state.FullFileName = full_file_name
                
                dif_lfn = get_new_unit_number()
                file_ok = os.path.exists(trim_string(full_file_name))
                
                if not file_ok:
                    print('File not found=' + trim_string(full_file_name))
                    end_of_file_local = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    
                    if diff_only:
                        out_filename = trim_string(file_name_path) + '.' + trim_string(local_file_extension) + 'dif'
                    else:
                        out_filename = trim_string(file_name_path) + '.' + trim_string(local_file_extension) + 'new'
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    process_input(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    alphas = [state.Blank] * state.MaxAlphaArgsFound
                    numbers = [0.0] * state.MaxNumericArgsFound
                    in_args = [state.Blank] * state.MaxTotalArgs
                    aorn = [False] * state.MaxTotalArgs
                    req_fld = [False] * state.MaxTotalArgs
                    fld_names = [state.Blank] * state.MaxTotalArgs
                    fld_defaults = [state.Blank] * state.MaxTotalArgs
                    fld_units = [state.Blank] * state.MaxTotalArgs
                    nwaorn = [False] * state.MaxTotalArgs
                    nw_req_fld = [False] * state.MaxTotalArgs
                    nw_fld_names = [state.Blank] * state.MaxTotalArgs
                    nw_fld_defaults = [state.Blank] * state.MaxTotalArgs
                    nw_fld_units = [state.Blank] * state.MaxTotalArgs
                    out_args = [state.Blank] * state.MaxTotalArgs
                    match_arg = [False] * state.MaxTotalArgs
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    # Preprocess Load Range info
                    lrbo = get_num_objects_found('LOAD RANGE BASED OPERATION')
                    clrbo = get_num_objects_found('COOLING LOAD RANGE BASED OPERATION')
                    hlrbo = get_num_objects_found('HEATING LOAD RANGE BASED OPERATION')
                    count = lrbo + clrbo + hlrbo
                    lrbo_scheme = [state.Blank] * count
                    lrbo_type = [0] * count
                    lrbo = 0
                    
                    # First scan for Load Range Based Operations
                    for num in range(state.NumIDFRecords):
                        record_name_upper = make_upper_case(trim_string(state.IDFRecords[num].Name))
                        
                        if record_name_upper == 'LOAD RANGE BASED OPERATION':
                            object_name = state.IDFRecords[num].Name
                            if find_item_in_list(object_name, [d.Name for d in state.ObjectDef], state.NumObjectDefs) != 0:
                                get_object_def_in_idd(object_name, state)
                            
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [state.Blank] * state.MaxTotalArgs
                            out_args = [state.Blank] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                            
                            mx_field = False
                            minus = False
                            for arg in range(1, cur_args, 3):
                                if arg + 1 < len(out_args):
                                    pos = out_args[arg].find('-')
                                    if pos >= 0:
                                        minus = True
                                    elif minus:
                                        mx_field = True
                                    
                                    if arg + 1 < len(out_args):
                                        pos = out_args[arg + 1].find('-')
                                        if pos >= 0:
                                            minus = True
                                        elif minus:
                                            mx_field = True
                            
                            lrbo += 1
                            lrbo_scheme[lrbo - 1] = make_upper_case(in_args[0])
                            
                            if mx_field:
                                lrbo_type[lrbo - 1] = 0
                            elif not minus:
                                lrbo_type[lrbo - 1] = 2
                            else:
                                lrbo_type[lrbo - 1] = 1
                        
                        elif record_name_upper == 'HEATING LOAD RANGE BASED OPERATION':
                            lrbo += 1
                            lrbo_scheme[lrbo - 1] = make_upper_case(state.IDFRecords[num].Alphas[0])
                            lrbo_type[lrbo - 1] = 2
                        
                        elif record_name_upper == 'COOLING LOAD RANGE BASED OPERATION':
                            lrbo += 1
                            lrbo_scheme[lrbo - 1] = make_upper_case(state.IDFRecords[num].Alphas[0])
                            lrbo_type[lrbo - 1] = 1
                    
                    # Scan and replace PLANT/CONDENSER Operation Schemes
                    for num in range(state.NumIDFRecords):
                        record_name_upper = make_upper_case(state.IDFRecords[num].Name)
                        if record_name_upper != 'PLANT OPERATION SCHEMES' and \
                           record_name_upper != 'CONDENSER OPERATION SCHEMES':
                            continue
                        
                        num_alphas = state.IDFRecords[num].NumAlphas
                        for arg in range(1, num_alphas, 3):
                            if make_upper_case(state.IDFRecords[num].Alphas[arg]) != 'LOAD RANGE BASED OPERATION':
                                continue
                            
                            count = find_item_in_list(make_upper_case(state.IDFRecords[num].Alphas[arg + 1]), 
                                                     lrbo_scheme, lrbo)
                            if count != 0:
                                if lrbo_type[count - 1] == 1:
                                    state.IDFRecords[num].Alphas[arg] = 'COOLING LOAD RANGE BASED OPERATION'
                                elif lrbo_type[count - 1] == 2:
                                    state.IDFRecords[num].Alphas[arg] = 'HEATING LOAD RANGE BASED OPERATION'
                    
                    # Main processing loop
                    with open(out_filename, 'w') as dif_file:
                        for num in range(state.NumIDFRecords):
                            # Write comments
                            for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE + 1):
                                if xcount < len(state.Comments):
                                    dif_file.write(trim_string(state.Comments[xcount]) + '\n')
                                    if xcount == state.IDFRecords[num].CommtE:
                                        dif_file.write('\n')
                            
                            # Write VERSION if needed
                            if no_version and num == 0:
                                get_new_object_def_in_idd('VERSION', state)
                                out_args[0] = '1.0.3'
                                cur_args = 1
                                write_out_idf_lines_as_comments(dif_file, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            object_name = state.IDFRecords[num].Name
                            if find_item_in_list(object_name, [d.Name for d in state.ObjectDef], state.NumObjectDefs) != 0:
                                get_object_def_in_idd(object_name, state)
                                num_alphas = state.IDFRecords[num].NumAlphas
                                num_numbers = state.IDFRecords[num].NumNumbers
                                alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                                numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                                cur_args = num_alphas + num_numbers
                                in_args = [state.Blank] * state.MaxTotalArgs
                                out_args = [state.Blank] * state.MaxTotalArgs
                                na = 0
                                nn = 0
                                
                                for arg in range(cur_args):
                                    if aorn[arg]:
                                        in_args[arg] = alphas[na]
                                        na += 1
                                    else:
                                        in_args[arg] = str(numbers[nn])
                                        nn += 1
                            else:
                                num_alphas = state.IDFRecords[num].NumAlphas
                                num_numbers = state.IDFRecords[num].NumNumbers
                                alphas[:num_alphas] = state.IDFRecords[num].Alphas[:num_alphas]
                                numbers[:num_numbers] = state.IDFRecords[num].Numbers[:num_numbers]
                                
                                out_args = [state.Blank] * state.MaxTotalArgs
                                for arg in range(num_alphas):
                                    out_args[arg] = alphas[arg]
                                
                                nn = num_alphas
                                for arg in range(num_numbers):
                                    out_args[nn] = str(numbers[arg])
                                    nn += 1
                                
                                cur_args = num_alphas + num_numbers
                                nw_fld_names = [state.Blank] * state.MaxTotalArgs
                                nw_fld_units = [state.Blank] * state.MaxTotalArgs
                                write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                continue
                            
                            no_diff = True
                            written = False
                            
                            if find_item_in_list(make_upper_case(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                                get_new_object_def_in_idd(object_name, state)
                            
                            if not state.MakingPretty:
                                object_name_upper = make_upper_case(trim_string(state.IDFRecords[num].Name))
                                
                                if object_name_upper == 'VERSION':
                                    if in_args[0][:5] == '1.0.3' and arg_file:
                                        show_warning_error('File is already at latest version.  No new diff file made.', state.Auditf)
                                        break
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[0] = '1.0.3'
                                
                                elif object_name_upper == 'COOLING TOWER:SINGLE SPEED':
                                    get_new_object_def_in_idd(object_name, state)
                                    if cur_args < 10:
                                        out_args[:cur_args] = in_args[:cur_args]
                                        for arg in range(cur_args, 9):
                                            out_args[arg] = state.Blank
                                        out_args[9] = 'UA and Design Water Flow Rate'
                                        cur_args = 10
                                    no_diff = False
                                
                                elif object_name_upper == 'COOLING TOWER:TWO SPEED':
                                    get_new_object_def_in_idd(object_name, state)
                                    if cur_args < 13:
                                        out_args[:cur_args] = in_args[:cur_args]
                                        for arg in range(cur_args, 12):
                                            out_args[arg] = state.Blank
                                        out_args[12] = 'UA and Design Water Flow Rate'
                                        cur_args = 13
                                    no_diff = False
                                
                                elif object_name_upper == 'RUNPERIOD':
                                    get_new_object_def_in_idd(object_name, state)
                                    if cur_args < 8:
                                        out_args[:cur_args] = in_args[:cur_args]
                                        for arg in range(cur_args, 7):
                                            out_args[arg] = state.Blank
                                        out_args[7] = 'No'
                                        cur_args = 8
                                    no_diff = False
                                
                                elif object_name_upper == 'PHOTOVOLTAICS':
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    save_number = process_number(in_args[35], state)
                                    if abs(save_number) > 1.0:
                                        show_warning_error('Photovoltaics=' + trim_string(out_args[0]) + ' invalid number, field 36=' + trim_string(in_args[35]), state.Auditf)
                                        out_args[35] = 'invalid number, ! Originally=' + trim_string(in_args[35])
                                    no_diff = False
                                
                                elif object_name_upper == 'DAYLIGHTING':
                                    if cur_args > 5:
                                        get_new_object_def_in_idd('DAYLIGHTING:DETAILED', state)
                                        object_name = 'Daylighting:Detailed'
                                        out_args[0] = in_args[0]
                                        out_args[1:cur_args - 3] = in_args[4:cur_args]
                                        cur_args = cur_args - 3
                                    else:
                                        get_new_object_def_in_idd('DAYLIGHTING:SIMPLE', state)
                                        object_name = 'Daylighting:Simple'
                                        out_args[:4] = in_args[:4]
                                        cur_args = 4
                                    no_diff = False
                                
                                elif object_name_upper == 'LOAD RANGE BASED OPERATION':
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args = in_args[:]
                                    f_field = True
                                    mx_field = False
                                    minus = False
                                    
                                    for arg in range(1, cur_args, 3):
                                        if f_field:
                                            f_field = False
                                        else:
                                            pos = out_args[arg].find('-')
                                            if pos >= 0:
                                                minus = True
                                            elif minus:
                                                mx_field = True
                                        
                                        if arg + 1 < cur_args:
                                            pos = out_args[arg + 1].find('-')
                                            if pos >= 0:
                                                minus = True
                                            elif minus:
                                                mx_field = True
                                    
                                    if mx_field:
                                        show_severe_error('Object LOAD RANGE BASED OPERATION=' + trim_string(out_args[0]) + ' needs hand transition.', state.Auditf)
                                        dif_file.write(' ! Next object is obsolete, needs hand transition to new\n')
                                    elif not minus:
                                        object_name = 'Heating Load Range Based Operation'
                                    else:
                                        object_name = 'Cooling Load Range Based Operation'
                                        for arg in range(1, cur_args, 3):
                                            pos = out_args[arg].find('-')
                                            if pos >= 0:
                                                out_args[arg] = out_args[arg][:pos] + ' ' + out_args[arg][pos+1:]
                                            if arg + 1 < cur_args:
                                                pos = out_args[arg + 1].find('-')
                                                if pos >= 0:
                                                    out_args[arg + 1] = out_args[arg + 1][:pos] + ' ' + out_args[arg + 1][pos+1:]
                                    no_diff = False
                                
                                elif object_name_upper == 'WINDOWSHADINGCONTROL':
                                    get_new_object_def_in_idd(object_name, state)
                                    no_diff = False
                                    out_args[:cur_args] = in_args[:cur_args]
                                    
                                    if same_string('InteriorNonInsulatingShade', in_args[1]):
                                        out_args[1] = 'InteriorShade'
                                    if same_string('ExteriorNonInsulatingShade', in_args[1]):
                                        out_args[1] = 'ExteriorShade'
                                    if same_string('InteriorInsulatingShade', in_args[1]):
                                        out_args[1] = 'InteriorShade'
                                    if same_string('ExteriorInsulatingShade', in_args[1]):
                                        out_args[1] = 'ExteriorShade'
                                    if same_string('Schedule', in_args[3]):
                                        out_args[3] = 'OnIfScheduleAllows'
                                    if same_string('SolarOnWindow', in_args[3]):
                                        out_args[3] = 'OnIfHighSolarOnWindow'
                                    if same_string('HorizontalSolar', in_args[3]):
                                        out_args[3] = 'OnIfHighHorizontalSolar'
                                    if same_string('OutsideAirTemp', in_args[3]):
                                        out_args[3] = 'OnIfHighOutsideAirTemp'
                                    if same_string('ZoneAirTemp', in_args[3]):
                                        out_args[3] = 'OnIfHighZoneAirTemp'
                                    if same_string('ZoneCooling', in_args[3]):
                                        out_args[3] = 'OnIfHighZoneCooling'
                                    if same_string('Glare', in_args[3]):
                                        out_args[3] = 'OnIfHighGlare'
                                    if same_string('DaylightIlluminance', in_args[3]):
                                        out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                                
                                elif object_name_upper == 'REPORT VARIABLE':
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                                    if out_args[0] == state.Blank:
                                        out_args[0] = '*'
                                        no_diff = False
                                    
                                    del_this = scan_output_variables_for_replacement(
                                        2, check_rvi, no_diff, object_name, dif_file,
                                        True, False, False, cur_args, written, False, state)
                                    if del_this:
                                        continue
                                
                                elif object_name_upper in ['REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY']:
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                                    
                                    del_this = scan_output_variables_for_replacement(
                                        1, check_rvi, no_diff, object_name, dif_file,
                                        False, True, False, cur_args, written, False, state)
                                    if del_this:
                                        continue
                                
                                elif object_name_upper == 'REPORT:TABLE:TIMEBINS':
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                                    if out_args[0] == state.Blank:
                                        out_args[0] = '*'
                                        no_diff = False
                                    
                                    del_this = scan_output_variables_for_replacement(
                                        2, check_rvi, no_diff, object_name, dif_file,
                                        False, False, True, cur_args, written, False, state)
                                    if del_this:
                                        continue
                                
                                elif object_name_upper == 'REPORT:TABLE:MONTHLY':
                                    get_new_object_def_in_idd(object_name, state)
                                    out_args[:cur_args] = in_args[:cur_args]
                                    no_diff = True
                                    if out_args[0] == state.Blank:
                                        out_args[0] = '*'
                                        no_diff = False
                                    
                                    cur_var = 2
                                    for var in range(2, cur_args, 2):
                                        uc_rep_var_name = make_upper_case(in_args[var])
                                        out_args[cur_var] = in_args[var]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                        
                                        pos = uc_rep_var_name.find('[')
                                        if pos >= 0:
                                            uc_rep_var_name = uc_rep_var_name[:pos]
                                            out_args[cur_var] = in_args[var][:pos]
                                            out_args[cur_var + 1] = in_args[var + 1]
                                        
                                        del_this = False
                                        for arg in range(state.NumRepVarNames):
                                            uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                            wild_match = False
                                            
                                            if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == '*':
                                                wild_match = True
                                                uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                            
                                            pos = trim_string(uc_rep_var_name).find(trim_string(uc_comp_rep_var_name))
                                            if pos > 0:
                                                continue
                                            if pos >= 0:
                                                if state.NewRepVarName[arg] != '<DELETE>':
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg]
                                                    else:
                                                        out_args[cur_var] = trim_string(state.NewRepVarName[arg]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                else:
                                                    del_this = True
                                                
                                                if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                    else:
                                                        out_args[cur_var] = trim_string(state.NewRepVarName[arg + 1]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                
                                                if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                    cur_var += 2
                                                    if not wild_match:
                                                        out_args[cur_var] = state.NewRepVarName[arg + 2]
                                                    else:
                                                        out_args[cur_var] = trim_string(state.NewRepVarName[arg + 2]) + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                    out_args[cur_var + 1] = in_args[var + 1]
                                                    no_diff = False
                                                break
                                        
                                        if not del_this:
                                            cur_var += 2
                                    
                                    cur_args = cur_var - 1
                                
                                else:
                                    if find_item_in_list(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                        write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                        written = True
                                    else:
                                        get_new_object_def_in_idd(object_name, state)
                                        out_args[:cur_args] = in_args[:cur_args]
                                        no_diff = True
                            
                            else:
                                get_new_object_def_in_idd(state.IDFRecords[num].Name, state)
                                out_args[:cur_args] = in_args[:cur_args]
                            
                            if not no_diff or not diff_only:
                                if not written:
                                    check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written, state)
                                
                                if not written:
                                    write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        # Write trailing comments
                        if state.IDFRecords[-1].CommtE != state.CurComment:
                            for xcount in range(state.IDFRecords[-1].CommtE + 1, state.CurComment + 1):
                                if xcount < len(state.Comments):
                                    dif_file.write(trim_string(state.Comments[xcount]) + '\n')
                    
                    if check_rvi:
                        process_rvi_mvi_files(file_name_path, 'rvi')
                        process_rvi_mvi_files(file_name_path, 'mvi')
                    
                    close_out()
                
                else:
                    process_rvi_mvi_files(file_name_path, 'rvi')
                    process_rvi_mvi_files(file_name_path, 'mvi')
            
            else:
                end_of_file_local = True
            
            create_new_name('Reallocate', state)
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file_local = False
            else:
                end_of_file_local = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copy_file(trim_string(state.FileNamePath) + '.' + trim_string(arg_idf_extension),
                 trim_string(state.FileNamePath) + '.' + trim_string(arg_idf_extension) + 'old', err_flag)
        copy_file(trim_string(state.FileNamePath) + '.' + trim_string(arg_idf_extension) + 'new',
                 trim_string(state.FileNamePath) + '.' + trim_string(arg_idf_extension), err_flag)
        
        file_exist = os.path.exists(trim_string(state.FileNamePath) + '.rvi')
        if file_exist:
            copy_file(trim_string(state.FileNamePath) + '.rvi',
                     trim_string(state.FileNamePath) + '.rviold', err_flag)
        
        file_exist = os.path.exists(trim_string(state.FileNamePath) + '.rvinew')
        if file_exist:
            copy_file(trim_string(state.FileNamePath) + '.rvinew',
                     trim_string(state.FileNamePath) + '.rvi', err_flag)
        
        file_exist = os.path.exists(trim_string(state.FileNamePath) + '.mvi')
        if file_exist:
            copy_file(trim_string(state.FileNamePath) + '.mvi',
                     trim_string(state.FileNamePath) + '.mviold', err_flag)
        
        file_exist = os.path.exists(trim_string(state.FileNamePath) + '.mvinew')
        if file_exist:
            copy_file(trim_string(state.FileNamePath) + '.mvinew',
                     trim_string(state.FileNamePath) + '.mvi', err_flag)
    
    return end_of_file_local
