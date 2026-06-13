from typing import Protocol, List, Optional, Tuple
from dataclasses import dataclass, field
import os
import shutil

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList, GetNumSectionsFound
# - DataVCompareGlobals: IDFRecords, Comments, NumIDFRecords, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs,
#   ObjectDef, NumObjectDefs, NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution,
#   OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, NumRepVarNames, FatalError
# - VCompareGlobalRoutines: DisplayString, ScanOutputVariablesForReplacement, WriteOutIDFLines,
#   WriteOutIDFLinesAsComments, CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName,
#   GetNewUnitNumber, writePreprocessorObject, copyfile
# - DataStringGlobals: MaxNameLength, Blank, ProgNameConversion
# - General: MakeUPPERCase, MakeLowerCase, TrimTrailZeros, SameString
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

class GlobalState(Protocol):
    FullFileName: str
    FileNamePath: str
    ProgramPath: str
    Auditf: int
    FileOK: bool
    ProcessingIMFFile: bool
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    VerString: str
    VersionNum: float
    sVersionNum: str
    sVersionNumFourChars: str
    FirstTime: bool
    IDFRecords: List
    Comments: List[str]
    NumIDFRecords: int
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
    ObjectDef: List
    NumObjectDefs: int
    NotInNew: List[str]
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    NewRepVarCaution: List[str]
    OTMVarCaution: List[bool]
    CMtrVarCaution: List[bool]
    CMtrDVarCaution: List[bool]
    NumRepVarNames: int
    FatalError: bool

first_time = True

def set_this_version_variables(state: GlobalState) -> None:
    state.VerString = 'Conversion 26.1 => 26.2'
    state.VersionNum = 26.2
    state.sVersionNum = '***'
    state.sVersionNumFourChars = '26.2'
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V26-1-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V26-2-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 26-1-0 to 26-2-0.csv'

def create_new_idf_using_rules(
    state: GlobalState,
    end_of_file: List[bool],
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    # External function imports
    display_string,
    get_new_unit_number,
    process_input,
    get_object_def_in_idd,
    get_new_object_def_in_idd,
    find_item_in_list,
    trim,
    make_upper_case,
    make_lower_case,
    scan_output_variables_for_replacement,
    write_out_idf_lines,
    write_out_idf_lines_as_comments,
    check_special_objects,
    process_rvi_mvi_files,
    close_out,
    create_new_name,
    show_warning_error,
    get_num_sections_found,
    write_preprocessor_object,
    copy_file,
    adjust_l,
    same_string,
    trim_trail_zeros
) -> None:
    blank = ''
    fmta = '(A)'
    
    global first_time
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    tot_run_periods = 0
    run_period_num = 0
    iterate_run_period = 0
    current_run_period_names = []
    potential_run_period_name = ''
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        full_file_name = blank
                        ios = 1
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
            full_file_name = adjust_l(full_file_name)
            
            if full_file_name != blank:
                display_string('Processing IDF -- ' + full_file_name)
                state.Auditf = open(state.Auditf, 'a') if isinstance(state.Auditf, str) else state.Auditf
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    state.FileNamePath = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    state.FileNamePath = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = full_file_name + '.idf'
                    local_file_extension = 'idf'
                
                state.FullFileName = full_file_name
                dif_lfn = get_new_unit_number()
                state.FileOK = os.path.isfile(full_file_name)
                
                if not state.FileOK:
                    print('File not found=' + full_file_name)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        output_filename = state.FileNamePath + '.' + local_file_extension + 'dif'
                    else:
                        output_filename = state.FileNamePath + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    process_input(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Deallocate and reallocate arrays
                    state.Alphas = [blank] * state.MaxAlphaArgsFound
                    state.Numbers = [0.0] * state.MaxNumericArgsFound
                    state.InArgs = [blank] * state.MaxTotalArgs
                    state.TempArgs = [blank] * state.MaxTotalArgs
                    state.AorN = [False] * state.MaxTotalArgs
                    state.ReqFld = [False] * state.MaxTotalArgs
                    state.FldNames = [blank] * state.MaxTotalArgs
                    state.FldDefaults = [blank] * state.MaxTotalArgs
                    state.FldUnits = [blank] * state.MaxTotalArgs
                    state.NwAorN = [False] * state.MaxTotalArgs
                    state.NwReqFld = [False] * state.MaxTotalArgs
                    state.NwFldNames = [blank] * state.MaxTotalArgs
                    state.NwFldDefaults = [blank] * state.MaxTotalArgs
                    state.NwFldUnits = [blank] * state.MaxTotalArgs
                    state.OutArgs = [blank] * state.MaxTotalArgs
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num]['Name']) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            with open(output_filename, 'a') as f:
                                f.write('! Deleting: ' + trim(state.IDFRecords[num]['Name']) + '="' + trim(state.IDFRecords[num]['Alphas'][0]) + '".\n')
                    
                    display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(state.IDFRecords[num]['CommtS'], state.IDFRecords[num]['CommtE']):
                            with open(output_filename, 'a') as f:
                                f.write(trim(state.Comments[xcount]) + '\n')
                                if xcount == state.IDFRecords[num]['CommtE'] - 1:
                                    f.write('\n')
                        
                        if no_version and num == 0:
                            get_new_object_def_in_idd('VERSION', state)
                            state.OutArgs[0] = state.sVersionNumFourChars
                            cur_args = 1
                            show_warning_error('No version found in file, defaulting to ' + state.sVersionNumFourChars, state.Auditf)
                            write_out_idf_lines_as_comments(output_filename, 'Version', cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                        
                        object_name = state.IDFRecords[num]['Name']
                        
                        if find_item_in_list(object_name, state.ObjectDef, state.NumObjectDefs) != 0:
                            get_object_def_in_idd(object_name, state)
                            num_alphas = state.IDFRecords[num]['NumAlphas']
                            num_numbers = state.IDFRecords[num]['NumNumbers']
                            state.Alphas[:num_alphas] = state.IDFRecords[num]['Alphas'][:num_alphas]
                            state.Numbers[:num_numbers] = state.IDFRecords[num]['Numbers'][:num_numbers]
                            cur_args = num_alphas + num_numbers
                            state.InArgs = [blank] * state.MaxTotalArgs
                            state.OutArgs = [blank] * state.MaxTotalArgs
                            state.TempArgs = [blank] * state.MaxTotalArgs
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
                            num_alphas = state.IDFRecords[num]['NumAlphas']
                            num_numbers = state.IDFRecords[num]['NumNumbers']
                            state.Alphas[:num_alphas] = state.IDFRecords[num]['Alphas'][:num_alphas]
                            state.Numbers[:num_numbers] = state.IDFRecords[num]['Numbers'][:num_numbers]
                            for arg in range(num_alphas):
                                state.OutArgs[arg] = state.Alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                state.OutArgs[nn] = str(state.Numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            state.NwFldNames = [blank] * state.MaxTotalArgs
                            state.NwFldUnits = [blank] * state.MaxTotalArgs
                            write_out_idf_lines_as_comments(output_filename, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(make_upper_case(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            get_new_object_def_in_idd(object_name, state)
                        
                        # Main processing logic
                        object_upper = make_upper_case(trim(object_name))
                        
                        if object_upper == 'VERSION':
                            if state.InArgs[0][:4] == state.sVersionNumFourChars and arg_file:
                                show_warning_error('File is already at latest version.  No new diff file made.', state.Auditf)
                                nodiff = False
                                latest_version = True
                                break
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[0] = state.sVersionNumFourChars
                            nodiff = False
                        
                        elif object_upper == 'COIL:COOLING:DX:CURVEFIT:OPERATINGMODE':
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = False
                            state.OutArgs[0:8] = state.InArgs[0:8]
                            state.OutArgs[8] = ''
                            state.OutArgs[9:cur_args+1] = state.InArgs[8:cur_args]
                            cur_args = cur_args + 1
                        
                        elif object_upper == 'OUTPUT:VARIABLE':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            if state.OutArgs[0] == blank:
                                state.OutArgs[0] = '*'
                                nodiff = False
                            scan_output_variables_for_replacement(2, state, checkrvi, nodiff, object_name, output_filename, True, False, False, cur_args, written, False)
                        
                        elif object_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            scan_output_variables_for_replacement(1, state, checkrvi, nodiff, object_name, output_filename, False, True, False, cur_args, written, False)
                        
                        elif object_upper == 'OUTPUT:TABLE:TIMEBINS':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            if state.OutArgs[0] == blank:
                                state.OutArgs[0] = '*'
                                nodiff = False
                            scan_output_variables_for_replacement(2, state, checkrvi, nodiff, object_name, output_filename, False, False, True, cur_args, written, False)
                        
                        elif object_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            if state.OutArgs[0] == blank:
                                state.OutArgs[0] = '*'
                                nodiff = False
                            scan_output_variables_for_replacement(2, state, checkrvi, nodiff, object_name, output_filename, False, False, False, cur_args, written, False)
                        
                        elif object_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            scan_output_variables_for_replacement(3, state, checkrvi, nodiff, object_name, output_filename, False, False, False, cur_args, written, True)
                        
                        elif object_upper == 'OUTPUT:TABLE:MONTHLY':
                            get_new_object_def_in_idd(object_name, state)
                            nodiff = True
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            cur_var = 3
                            var = 3
                            while var < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var])
                                state.OutArgs[cur_var] = state.InArgs[var]
                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg].strip() + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            if state.NewRepVarCaution[arg] != blank and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.OTMVarCaution[arg]:
                                                    write_preprocessor_object(output_filename, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Output Table Monthly (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".')
                                                    state.OTMVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            
                            cur_args = cur_var - 1
                        
                        elif object_upper == 'METER:CUSTOM':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            cur_var = 4
                            var = 4
                            while var < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var])
                                state.OutArgs[cur_var] = state.InArgs[var]
                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg].strip() + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            if state.NewRepVarCaution[arg] != blank and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrVarCaution[arg]:
                                                    write_preprocessor_object(output_filename, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".')
                                                    state.CMtrVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.OutArgs[arg] == blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_upper == 'METER:CUSTOMDECREMENT':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            cur_var = 4
                            var = 4
                            while var < cur_args:
                                uc_rep_var_name = make_upper_case(state.InArgs[var])
                                state.OutArgs[cur_var] = state.InArgs[var]
                                state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.OutArgs[cur_var] = state.InArgs[var][:pos]
                                    state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                        wild_match = True
                                        uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name.strip())
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
                                                state.OutArgs[cur_var] = state.NewRepVarName[arg].strip() + state.OutArgs[cur_var][len(uc_comp_rep_var_name):]
                                            
                                            if state.NewRepVarCaution[arg] != blank and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrDVarCaution[arg]:
                                                    write_preprocessor_object(output_filename, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".')
                                                    state.CMtrDVarCaution[arg] = True
                                            
                                            state.OutArgs[cur_var + 1] = state.InArgs[var + 1]
                                            nodiff = False
                                        else:
                                            del_this = True
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                                var += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.OutArgs[arg] == blank:
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif object_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            scan_output_variables_for_replacement(2, state, checkrvi, nodiff, object_name, output_filename, False, True, False, cur_args, written, False)
                        
                        elif object_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                            get_new_object_def_in_idd(object_name, state)
                            state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                            nodiff = True
                            scan_output_variables_for_replacement(6, state, checkrvi, nodiff, object_name, output_filename, False, True, False, cur_args, written, False)
                            scan_output_variables_for_replacement(12, state, checkrvi, nodiff, object_name, output_filename, False, True, False, cur_args, written, False)
                        
                        else:
                            if find_item_in_list(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                write_out_idf_lines_as_comments(output_filename, object_name, cur_args, state.InArgs, state.FldNames, state.FldUnits)
                                written = True
                            else:
                                get_new_object_def_in_idd(object_name, state)
                                state.OutArgs[:cur_args] = state.InArgs[:cur_args]
                                nodiff = True
                        
                        if not written:
                            check_special_objects(output_filename, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                        
                        if not written:
                            write_out_idf_lines(output_filename, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                    
                    display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        get_new_object_def_in_idd(object_name, state)
                        nodiff = False
                        state.OutArgs[0] = 'Regular'
                        cur_args = 1
                        write_out_idf_lines(output_filename, object_name, cur_args, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                    
                    process_rvi_mvi_files(state.FileNamePath, 'rvi')
                    process_rvi_mvi_files(state.FileNamePath, 'mvi')
                    close_out()
                
                else:
                    process_rvi_mvi_files(state.FileNamePath, 'rvi')
                    process_rvi_mvi_files(state.FileNamePath, 'mvi')
            else:
                end_of_file[0] = True
            
            create_new_name('Reallocate', ' ')
        
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
        copy_file(state.FileNamePath + '.' + arg_idf_extension, state.FileNamePath + '.' + arg_idf_extension + 'old', err_flag)
        copy_file(state.FileNamePath + '.' + arg_idf_extension + 'new', state.FileNamePath + '.' + arg_idf_extension, err_flag)
        
        if os.path.isfile(state.FileNamePath + '.rvi'):
            copy_file(state.FileNamePath + '.rvi', state.FileNamePath + '.rviold', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.rvinew'):
            copy_file(state.FileNamePath + '.rvinew', state.FileNamePath + '.rvi', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.mvi'):
            copy_file(state.FileNamePath + '.mvi', state.FileNamePath + '.mviold', err_flag)
        
        if os.path.isfile(state.FileNamePath + '.mvinew'):
            copy_file(state.FileNamePath + '.mvinew', state.FileNamePath + '.mvi', err_flag)
