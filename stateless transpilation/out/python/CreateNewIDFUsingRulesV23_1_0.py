from dataclasses import dataclass, field
from typing import Any, List, Optional, Protocol, Tuple
from enum import Enum
import re

# EXTERNAL DEPS (to wire in glue):
# - FullFileName, FileNamePath, Blank, ProgramPath, Auditf: from DataStringGlobals
# - IDFRecords, Comments, NumIDFRecords, CurComment: from DataVCompareGlobals
# - MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs: constants from DataVCompareGlobals
# - ObjectDef, NotInNew, FatalError: from InputProcessor
# - OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames: from DataVCompareGlobals
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution: from DataVCompareGlobals
# - ProcessingIMFFile: from DataVCompareGlobals
# - ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList: from InputProcessor
# - DisplayString, ProcessRviMviFiles, CloseOut, CreateNewName, CheckSpecialObjects, WriteOutIDFLinesAsComments, WriteOutIDFLines: from VCompareGlobalRoutines
# - GetNewUnitNumber: from General
# - ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError: from DataGlobals
# - ProgNameConversion: from DataStringGlobals
# - SameString: utility function


@dataclass
class GlobalState:
    """Stub for external module state."""
    FullFileName: str = ""
    FileNamePath: str = ""
    Blank: str = ""
    ProgramPath: str = ""
    Auditf: Any = None
    IDFRecords: List[Any] = field(default_factory=list)
    Comments: List[str] = field(default_factory=list)
    NumIDFRecords: int = 0
    CurComment: int = 0
    ObjectDef: List[Any] = field(default_factory=list)
    NotInNew: List[str] = field(default_factory=list)
    FatalError: bool = False
    OldRepVarName: List[str] = field(default_factory=list)
    NewRepVarName: List[str] = field(default_factory=list)
    NewRepVarCaution: List[str] = field(default_factory=list)
    NumRepVarNames: int = 0
    OTMVarCaution: List[bool] = field(default_factory=list)
    CMtrVarCaution: List[bool] = field(default_factory=list)
    CMtrDVarCaution: List[bool] = field(default_factory=list)
    ProcessingIMFFile: bool = False
    ProgNameConversion: str = ""


class ExternalServices(Protocol):
    """Protocol for external service stubs."""
    def ProcessInput(self, old_idd: str, new_idd: str, filename: str) -> None: ...
    def DisplayString(self, msg: str) -> None: ...
    def ProcessRviMviFiles(self, path: str, ext: str) -> None: ...
    def CloseOut(self) -> None: ...
    def CreateNewName(self, action: str, name: str, suffix: str) -> None: ...
    def CheckSpecialObjects(self, lun: int, obj_name: str, cur_args: int, 
                           out_args: List[str], fld_names: List[str], 
                           fld_units: List[str], written: bool) -> bool: ...
    def WriteOutIDFLinesAsComments(self, lun: int, obj_name: str, cur_args: int,
                                  out_args: List[str], fld_names: List[str],
                                  fld_units: List[str]) -> None: ...
    def WriteOutIDFLines(self, lun: int, obj_name: str, cur_args: int,
                        out_args: List[str], fld_names: List[str],
                        fld_units: List[str]) -> None: ...
    def GetNewUnitNumber(self) -> int: ...
    def FindItemInList(self, item: str, list_: List[str], size: int) -> int: ...
    def GetObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def GetNewObjectDefInIDD(self, obj_name: str) -> Tuple[int, List[bool], List[bool], int, List[str], List[str], List[str]]: ...
    def ScanOutputVariablesForReplacement(self, field_idx: int, del_this: bool, check_rvi: bool,
                                         no_diff: bool, obj_name: str, lun: int, out_var: bool,
                                         mtr_var: bool, time_bin: bool, cur_args: int,
                                         written: bool, is_ems: bool) -> Tuple[bool, bool]: ...
    def ShowWarningError(self, msg: str, auditf: Any) -> None: ...
    def GetNumSectionsFound(self, section: str) -> int: ...
    def copyfile(self, src: str, dst: str) -> bool: ...
    def writePreprocessorObject(self, lun: int, prog_name: str, level: str, msg: str) -> None: ...


def make_upper_case(s: str) -> str:
    return s.upper()


def make_lower_case(s: str) -> str:
    return s.lower()


def same_string(a: str, b: str) -> bool:
    return a.upper() == b.upper()


def trim_trail_zeros(s: str) -> str:
    """Remove trailing zeros from numeric string."""
    if '.' not in s:
        return s
    s = s.rstrip('0')
    if s.endswith('.'):
        s = s.rstrip('.')
    return s


def set_this_version_variables(state: GlobalState) -> Tuple[str, float, str, str, str, str, str]:
    """Set version variables for conversion 22.2 => 23.1."""
    ver_string = 'Conversion 22.2 => 23.1'
    version_num = 23.1
    s_version_num = '***'
    s_version_num_four_chars = '23.1'
    idd_file_name_with_path = state.ProgramPath.rstrip('/') + '/V22-2-0-Energy+.idd'
    new_idd_file_name_with_path = state.ProgramPath.rstrip('/') + '/V23-1-0-Energy+.idd'
    rep_var_file_name_with_path = state.ProgramPath.rstrip('/') + '/Report Variables 22-2-0 to 23-1-0.csv'
    
    return (ver_string, version_num, s_version_num, s_version_num_four_chars,
            idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path)


def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_filename: str,
    arg_file: bool,
    arg_idf_extension: str,
    state: GlobalState,
    services: ExternalServices,
) -> bool:
    """
    Create new IDF files using conversion rules.
    Returns updated end_of_file flag.
    """
    
    fmta = "(A)"
    first_time = True
    
    # Get version info
    ver_string, version_num, s_version_num, s_version_num_four_chars, \
        idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path = \
        set_this_version_variables(state)
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    max_name_length = 100  # placeholder
    max_total_args = 500   # placeholder
    
    alphas = [""] * 100
    numbers = [""] * 100
    in_args = [""] * max_total_args
    temp_args = [""] * max_total_args
    aorn = [False] * max_total_args
    req_fld = [False] * max_total_args
    fld_names = [""] * max_total_args
    fld_defaults = [""] * max_total_args
    fld_units = [""] * max_total_args
    nw_aorn = [False] * max_total_args
    nw_req_fld = [False] * max_total_args
    nw_fld_names = [""] * max_total_args
    nw_fld_defaults = [""] * max_total_args
    nw_fld_units = [""] * max_total_args
    out_args = [""] * max_total_args
    p_out_args = [""] * max_total_args
    delete_this_record = [False] * len(state.IDFRecords)
    
    # Local variables for V10_0_0 compatibility
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
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='', flush=True)
                full_filename = input()
            else:
                if not arg_file:
                    # Simulate READ from file
                    full_filename = ""
                    ios = 1
                elif not arg_file_being_done:
                    full_filename = input_filename
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_filename = ""
                    ios = 1
            
            if full_filename.startswith('!'):
                full_filename = ""
                continue
            
            units_arg = ""
            if ios != 0:
                full_filename = ""
            
            full_filename = full_filename.lstrip()
            
            if full_filename != "":
                services.DisplayString('Processing IDF -- ' + full_filename)
                if state.Auditf:
                    state.Auditf.write(' Processing IDF -- ' + full_filename + '\n')
                
                dot_pos = full_filename.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_filename[:dot_pos]
                    local_file_extension = make_lower_case(full_filename[dot_pos+1:])
                else:
                    file_name_path = full_filename
                    print(' assuming file extension of .idf')
                    if state.Auditf:
                        state.Auditf.write(' ..assuming file extension of .idf\n')
                    full_filename = full_filename + '.idf'
                    local_file_extension = 'idf'
                
                state.FullFileName = full_filename
                state.FileNamePath = file_name_path
                
                dif_lfn = services.GetNewUnitNumber()
                
                try:
                    with open(full_filename, 'r') as f:
                        file_ok = True
                except FileNotFoundError:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_filename)
                    if state.Auditf:
                        state.Auditf.write('File not found=' + full_filename + '\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        output_file = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        services.ShowWarningError(
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            state.Auditf
                        )
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    services.ProcessInput(idd_file_name_with_path, new_idd_file_name_with_path, full_filename)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Clear and reallocate arrays
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if make_upper_case(state.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    # Write deletion comments
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            # Would write deletion marker
                            pass
                    
                    # Main processing loop
                    services.DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(state.NumIDFRecords):
                        if delete_this_record[num]:
                            continue
                        
                        # Write comments
                        if hasattr(state.IDFRecords[num], 'CommtS') and hasattr(state.IDFRecords[num], 'CommtE'):
                            for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE + 1):
                                if xcount < len(state.Comments):
                                    # Write comment
                                    pass
                        
                        if no_version and num == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD('VERSION')
                            out_args[0] = s_version_num_four_chars
                            cur_args = 1
                            services.ShowWarningError('No version found in file, defaulting to ' + s_version_num_four_chars, state.Auditf)
                            services.WriteOutIDFLinesAsComments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = state.IDFRecords[num].Name
                        
                        if services.FindItemInList(object_name, [o.Name for o in state.ObjectDef], len(state.ObjectDef)) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                services.GetObjectDefInIDD(object_name)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(min(num_alphas, len(alphas))):
                                alphas[i] = state.IDFRecords[num].Alphas[i] if i < len(state.IDFRecords[num].Alphas) else ""
                            for i in range(min(num_numbers, len(numbers))):
                                numbers[i] = state.IDFRecords[num].Numbers[i] if i < len(state.IDFRecords[num].Numbers) else ""
                            
                            cur_args = num_alphas + num_numbers
                            in_args = [""] * max_total_args
                            out_args = [""] * max_total_args
                            temp_args = [""] * max_total_args
                            
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = numbers[nn]
                                    nn += 1
                        else:
                            if state.Auditf:
                                state.Auditf.write('Object="' + object_name + '" does not seem to be on the "old" IDD.\n')
                                state.Auditf.write('... will be listed as comments (no field names) on the new output file.\n')
                                state.Auditf.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(num_alphas):
                                out_args[i] = state.IDFRecords[num].Alphas[i] if i < len(state.IDFRecords[num].Alphas) else ""
                            
                            nn = num_alphas + 1
                            for i in range(num_numbers):
                                out_args[nn] = state.IDFRecords[num].Numbers[i] if i < len(state.IDFRecords[num].Numbers) else ""
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * cur_args
                            nw_fld_units = [""] * cur_args
                            
                            services.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if services.FindItemInList(make_upper_case(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        # Main SELECT CASE logic
                        obj_upper = make_upper_case(state.IDFRecords[num].Name)
                        
                        if obj_upper == 'VERSION':
                            if in_args[0][:4] == s_version_num_four_chars and arg_file:
                                services.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                # Close and delete file
                                latest_version = True
                                break
                            
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[0] = s_version_num_four_chars
                            no_diff = False
                        
                        elif obj_upper == 'OUTPUT:VARIABLE':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = '*'
                                no_diff = False
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                True, False, False, cur_args, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                0, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, cur_args, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = '*'
                                no_diff = False
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, True, cur_args, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE',
                                          'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            if out_args[0] == "":
                                out_args[0] = '*'
                                no_diff = False
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, False, cur_args, written, False
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                2, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, False, False, cur_args, written, True
                            )
                            if del_this:
                                continue
                        
                        elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            no_diff = True
                            out_args[:cur_args] = in_args[:cur_args]
                            cur_var = 3
                            
                            for var in range(3, cur_args, 2):
                                uc_rep_var_name = make_upper_case(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != "" and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.OTMVarCaution[arg]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Output Table Monthly (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".'
                                                    )
                                                    state.OTMVarCaution[arg] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        
                                        if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != "":
                                                    if not state.OTMVarCaution[arg + 1]:
                                                        services.writePreprocessorObject(
                                                            dif_lfn, state.ProgNameConversion, 'Warning',
                                                            'Output Table Monthly (old)="' + state.OldRepVarName[arg].strip() +
                                                            '" conversion to Output Table Monthly (new)="' +
                                                            state.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                            state.NewRepVarCaution[arg + 1].strip() + '".'
                                                        )
                                                        state.OTMVarCaution[arg + 1] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        
                                        if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != "":
                                                if not state.OTMVarCaution[arg + 2]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Output Table Monthly (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Output Table Monthly (new)="' +
                                                        state.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg + 2].strip() + '".'
                                                    )
                                                    state.OTMVarCaution[arg + 2] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                            
                            cur_args = cur_var - 1
                        
                        elif obj_upper == 'METER:CUSTOM':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            cur_var = 4
                            
                            for var in range(4, cur_args, 2):
                                uc_rep_var_name = make_upper_case(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != "" and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrVarCaution[arg]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".'
                                                    )
                                                    state.CMtrVarCaution[arg] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        
                                        if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != "" and not same_string(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrVarCaution[arg + 1]:
                                                        services.writePreprocessorObject(
                                                            dif_lfn, state.ProgNameConversion, 'Warning',
                                                            'Custom Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                            '" conversion to Custom Meter (new)="' +
                                                            state.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                            state.NewRepVarCaution[arg + 1].strip() + '".'
                                                        )
                                                        state.CMtrVarCaution[arg + 1] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        
                                        if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != "":
                                                if not state.CMtrVarCaution[arg + 2]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Custom Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg + 2].strip() + '".'
                                                    )
                                                    state.CMtrVarCaution[arg + 2] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if out_args[arg] == "":
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif obj_upper == 'METER:CUSTOMDECREMENT':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            cur_var = 4
                            
                            for var in range(4, cur_args, 2):
                                uc_rep_var_name = make_upper_case(in_args[var])
                                out_args[cur_var] = in_args[var]
                                out_args[cur_var + 1] = in_args[var + 1]
                                
                                pos = uc_rep_var_name.find('[')
                                if pos > 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    out_args[cur_var] = in_args[var][:pos]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                
                                del_this = False
                                for arg in range(state.NumRepVarNames):
                                    uc_comp_rep_var_name = make_upper_case(state.OldRepVarName[arg])
                                    
                                    if uc_comp_rep_var_name[-1] == '*':
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
                                                out_args[cur_var] = state.NewRepVarName[arg]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg] != "" and not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                if not state.CMtrDVarCaution[arg]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg].strip() + '".'
                                                    )
                                                    state.CMtrDVarCaution[arg] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        else:
                                            del_this = True
                                        
                                        if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                            if not same_string(state.NewRepVarCaution[arg][:6], 'Forkeq'):
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                                
                                                if state.NewRepVarCaution[arg + 1] != "" and not same_string(state.NewRepVarCaution[arg + 1][:6], 'Forkeq'):
                                                    if not state.CMtrDVarCaution[arg + 1]:
                                                        services.writePreprocessorObject(
                                                            dif_lfn, state.ProgNameConversion, 'Warning',
                                                            'Custom Decrement Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                            '" conversion to Custom Decrement Meter (new)="' +
                                                            state.NewRepVarName[arg + 1].strip() + '" has the following caution "' +
                                                            state.NewRepVarCaution[arg + 1].strip() + '".'
                                                        )
                                                        state.CMtrDVarCaution[arg + 1] = True
                                                
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                        
                                        if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                            cur_var += 2
                                            if not wild_match:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2]
                                            else:
                                                out_args[cur_var] = state.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name.rstrip()):]
                                            
                                            if state.NewRepVarCaution[arg + 2] != "":
                                                if not state.CMtrDVarCaution[arg + 2]:
                                                    services.writePreprocessorObject(
                                                        dif_lfn, state.ProgNameConversion, 'Warning',
                                                        'Custom Decrement Meter (old)="' + state.OldRepVarName[arg].strip() +
                                                        '" conversion to Custom Meter (new)="' +
                                                        state.NewRepVarName[arg + 2].strip() + '" has the following caution "' +
                                                        state.NewRepVarCaution[arg + 2].strip() + '".'
                                                    )
                                                    state.CMtrDVarCaution[arg + 2] = True
                                            
                                            out_args[cur_var + 1] = in_args[var + 1]
                                            no_diff = False
                                        
                                        break
                                
                                if not del_this:
                                    cur_var += 2
                            
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if out_args[arg] == "":
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif obj_upper in ['DEMANDMANAGERASSIGNMENTLIST', 'UTILITYCOST:TARIFF']:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                1, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, cur_args, written, False
                            )
                        
                        elif obj_upper == 'ELECTRICLOADCENTER:DISTRIBUTION':
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = True
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                5, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, cur_args, written, False
                            )
                            
                            del_this, check_rvi = services.ScanOutputVariablesForReplacement(
                                11, False, check_rvi, no_diff, object_name, dif_lfn,
                                False, True, False, cur_args, written, False
                            )
                        
                        else:
                            if services.FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                if state.Auditf:
                                    state.Auditf.write('Object="' + object_name + '" is not in the "new" IDD.\n')
                                    state.Auditf.write('... will be listed as comments on the new output file.\n')
                                services.WriteOutIDFLinesAsComments(dif_lfn, object_name, cur_args, in_args, fld_names, fld_units)
                                written = True
                            else:
                                nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    services.GetNewObjectDefInIDD(object_name)
                                out_args[:cur_args] = in_args[:cur_args]
                                no_diff = True
                        
                        # Handle min-fields change
                        if diff_min_fields and no_diff:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                services.GetNewObjectDefInIDD(object_name)
                            out_args[:cur_args] = in_args[:cur_args]
                            no_diff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        # Write output
                        if not written:
                            written = services.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            services.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    services.DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if state.NumIDFRecords > 0 and state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE + 1, state.CurComment + 1):
                            if xcount < len(state.Comments):
                                pass
                    
                    if services.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            services.GetNewObjectDefInIDD(object_name)
                        no_diff = False
                        out_args[0] = 'Regular'
                        cur_args = 1
                        services.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    try:
                        with open(file_name_path + '.rvi', 'r') as f:
                            file_exist = True
                    except FileNotFoundError:
                        file_exist = False
                    
                    # Close output file
                    services.ProcessRviMviFiles(file_name_path, 'rvi')
                    services.ProcessRviMviFiles(file_name_path, 'mvi')
                    services.CloseOut()
                else:
                    services.ProcessRviMviFiles(file_name_path, 'rvi')
                    services.ProcessRviMviFiles(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            services.CreateNewName('Reallocate', "", ' ')
        
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
        err_flag = False
        services.copyfile(file_name_path + '.' + arg_idf_extension,
                         file_name_path + '.' + arg_idf_extension + 'old')
        services.copyfile(file_name_path + '.' + arg_idf_extension + 'new',
                         file_name_path + '.' + arg_idf_extension)
        
        try:
            with open(file_name_path + '.rvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            services.copyfile(file_name_path + '.rvi', file_name_path + '.rviold')
        
        try:
            with open(file_name_path + '.rvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            services.copyfile(file_name_path + '.rvinew', file_name_path + '.rvi')
        
        try:
            with open(file_name_path + '.mvi', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            services.copyfile(file_name_path + '.mvi', file_name_path + '.mviold')
        
        try:
            with open(file_name_path + '.mvinew', 'r') as f:
                file_exist = True
        except FileNotFoundError:
            file_exist = False
        
        if file_exist:
            services.copyfile(file_name_path + '.mvinew', file_name_path + '.mvi')
    
    return end_of_file
