from typing import Optional, List, Callable, Any, Union, Protocol
from dataclasses import dataclass, field
from enum import IntEnum
import math
import sys

class ErrorMessageCategory(IntEnum):
    Invalid = -1
    Unclassified = 0
    Input_invalid = 1
    Input_field_not_found = 2
    Input_field_blank = 3
    Input_object_not_found = 4
    Input_cannot_find_object = 5
    Input_topology_problem = 6
    Input_unused = 7
    Input_fatal = 8
    Runtime_general = 9
    Runtime_flow_out_of_range = 10
    Runtime_temp_out_of_range = 11
    Runtime_airflow_network = 12
    Fatal_general = 13
    Developer_general = 14
    Developer_invalid_index = 15
    Num = 16

class Clusive(IntEnum):
    Invalid = -1
    In = 0
    Ex = 1
    Num = 2

@dataclass
class ErrorCountIndex:
    index: int = 0
    count: int = 0

@dataclass
class ErrorObjectHeader:
    routineName: str
    objectType: str
    objectName: str

@dataclass
class UtilityRoutinesData:
    outputErrorHeader: bool = True
    appendPerfLog_headerRow: str = ""
    appendPerfLog_valuesRow: str = ""
    GetMatrixInputFlag: bool = True

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.outputErrorHeader = True
        self.appendPerfLog_headerRow = ""
        self.appendPerfLog_valuesRow = ""
        self.GetMatrixInputFlag = True

MONTH_NAMES_CC = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
MONTH_NAMES_UC = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
YES_NO_NAMES = ["No", "Yes"]
YES_NO_NAMES_UC = ["NO", "YES"]

def pow2(x: Union[int, float]) -> Union[int, float]:
    return x * x

def pow3(x: Union[int, float]) -> Union[int, float]:
    return x * x * x

def pow4(x: Union[int, float]) -> Union[int, float]:
    y = x * x
    return y * y

def pow5(x: Union[int, float]) -> Union[int, float]:
    y = x * x
    y *= y
    return y * x

def pow6(x: Union[int, float]) -> Union[int, float]:
    y = x * x
    y *= y
    return y * y

def pow7(x: Union[int, float]) -> Union[int, float]:
    y = x * x
    y *= y
    y *= y
    return y * x

def env_var_on(env_var_str: str) -> bool:
    return len(env_var_str) > 0 and env_var_str[0].upper() in ('Y', 'T')

def make_upper(input_string: str) -> str:
    result = list(input_string)
    for i, ch in enumerate(input_string):
        cur_char_val = ord(ch)
        if (97 <= cur_char_val <= 122) or (224 <= cur_char_val <= 255):
            result[i] = chr(cur_char_val - 32)
    return "".join(result)

def same_string(s: str, t: str) -> bool:
    return equali(s, t)

def find_non_space(string: str) -> int:
    for i, ch in enumerate(string):
        if ch != ' ':
            return i
    return len(string)

def process_number(string: str, error_flag: List[bool]) -> float:
    error_flag[0] = False
    
    if not string:
        return 0.0
    
    string = string.strip()
    if not string:
        return 0.0
    
    try:
        result = float(string)
        if not math.isfinite(result):
            error_flag[0] = True
            return 0.0
        return result
    except (ValueError, OverflowError):
        error_flag[0] = True
        return 0.0

def find_item_in_list(string: str, list_of_items: List[str], num_items: Optional[int] = None) -> int:
    if num_items is None:
        num_items = len(list_of_items)
    
    for count in range(num_items):
        if string == list_of_items[count]:
            return count + 1
    return 0

def find_int_in_list(list_items: List[int], item: int) -> int:
    try:
        return list_items.index(item) + 1
    except ValueError:
        return -1

def find_item(string: str, list_of_items: List[str], num_items: Optional[int] = None) -> int:
    if num_items is None:
        num_items = len(list_of_items)
    
    result = find_item_in_list(string, list_of_items, num_items)
    if result != 0:
        return result
    
    for count in range(num_items):
        if equali(string, list_of_items[count]):
            return count + 1
    return 0

def set_design_object_name_and_pointer(state: Any, name_to_be_set: List[str], ptr_to_be_set: List[int], 
                                       user_name: str, list_of_names: List[str], item_type: str, 
                                       item_name: str, error_found: List[bool]) -> None:
    name_to_be_set[0] = user_name
    ptr_to_be_set[0] = find_item_in_list(name_to_be_set[0], list_of_names)
    
    if ptr_to_be_set[0] <= 0:
        error_found[0] = True
        show_severe_error(state, f"Object = {item_type} with the Name = {item_name} has an invalid Design Object Name = {name_to_be_set[0]}.")
        show_continue_error(state, "  The Design Object Name was not found or was left blank.  This is not allowed.")
        show_continue_error(state, f"  A valid Design Object Name must be provided for any {item_type} object.")

class CaseInsensitiveHasher:
    def hash(self, key: str) -> int:
        return hash(make_upper(key))

class CaseInsensitiveComparator:
    def compare(self, a: str, b: str) -> bool:
        return lessthani(a, b)

def append_perf_log(state: Any, col_header: str, col_value: str, final_column: bool = False) -> None:
    if col_header == "RESET" and col_value == "RESET":
        state.dataUtilityRoutines.appendPerfLog_headerRow = ""
        state.dataUtilityRoutines.appendPerfLog_valuesRow = ""
        return
    
    state.dataUtilityRoutines.appendPerfLog_headerRow += col_header + ","
    state.dataUtilityRoutines.appendPerfLog_valuesRow += col_value + ","
    
    if final_column:
        import os
        perf_log_path = state.dataStrGlobals.outputPerfLogFilePath
        
        if not os.path.exists(perf_log_path):
            if state.files.outputControl.perflog:
                try:
                    with open(perf_log_path, 'w') as f:
                        f.write(state.dataUtilityRoutines.appendPerfLog_headerRow + "\n")
                        f.write(state.dataUtilityRoutines.appendPerfLog_valuesRow + "\n")
                except Exception:
                    show_fatal_error(state, f"appendPerfLog: Could not open file \"{perf_log_path}\" for output (write).")
        else:
            if state.files.outputControl.perflog:
                try:
                    with open(perf_log_path, 'a') as f:
                        f.write(state.dataUtilityRoutines.appendPerfLog_valuesRow + "\n")
                except Exception:
                    show_fatal_error(state, f"appendPerfLog: Could not open file \"{perf_log_path}\" for output (append).")

def convert_case_to_upper(input_string: str) -> str:
    upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    lower_case = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    
    result = list(input_string)
    for a, ch in enumerate(input_string):
        try:
            b = lower_case.index(ch)
            result[a] = upper_case[b]
        except ValueError:
            pass
    return "".join(result)

def convert_case_to_lower(input_string: str) -> str:
    upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    lower_case = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    
    result = list(input_string)
    for a, ch in enumerate(input_string):
        try:
            b = upper_case.index(ch)
            result[a] = lower_case[b]
        except ValueError:
            pass
    return "".join(result)

def emit_error_message(state: Any, category: ErrorMessageCategory, msg: str, should_fatal: bool) -> None:
    if not should_fatal:
        show_severe_error(state, msg)
    else:
        show_fatal_error(state, msg)

def emit_error_messages(state: Any, category: ErrorMessageCategory, msgs: List[str], should_fatal: bool, 
                       zero_based_time_stamp_index: int = -1) -> None:
    for msg_idx, msg in enumerate(msgs):
        if msg_idx == zero_based_time_stamp_index:
            show_continue_error_time_stamp(state, msg)
            continue
        if msg_idx == 0:
            show_severe_error(state, msg)
        elif msg_idx == len(msgs) - 1 and should_fatal:
            show_fatal_error(state, msg)
        else:
            show_continue_error(state, msg)

def emit_warning_message(state: Any, category: ErrorMessageCategory, msg: str, count_as_error: bool = False) -> None:
    if count_as_error:
        show_warning_error(state, msg)
    else:
        show_warning_message(state, msg)

def emit_warning_messages(state: Any, category: ErrorMessageCategory, msgs: List[str], count_as_error: bool = False) -> None:
    for msg_idx, msg in enumerate(msgs):
        if msg_idx == 0:
            if count_as_error:
                show_warning_error(state, msg)
            else:
                show_warning_message(state, msg)
        else:
            show_continue_error(state, msg)

def show_error_message(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    err_stream = getattr(state.files, 'err_stream', None)
    
    if state.dataUtilityRoutines.outputErrorHeader and err_stream:
        err_stream.write(f"Program Version,{state.dataStrGlobals.VerStringVar},{state.dataStrGlobals.IDDVerString}\n")
        state.dataUtilityRoutines.outputErrorHeader = False
    
    if not state.dataGlobal.DoingInputProcessing:
        if err_stream:
            err_stream.write(f"  {error_message}\n")
    else:
        if state.dataGlobal.printConsoleOutput:
            print(error_message)
    
    if out_unit1:
        out_unit1.write(f"  {error_message}\n")
    if out_unit2:
        out_unit2.write(f"  {error_message}\n")

def show_fatal_error(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    show_error_message(state, f" **  Fatal  ** {error_message}", out_unit1, out_unit2)
    display_string(state, f"**FATAL:{error_message}")
    show_error_message(state, " ...Summary of Errors that led to program termination:", out_unit1, out_unit2)
    show_error_message(state, f" ..... Reference severe error count={state.dataErrTracking.TotalSevereErrors}", out_unit1, out_unit2)
    show_error_message(state, f" ..... Last severe error={state.dataErrTracking.LastSevereError}", out_unit1, out_unit2)
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 2, error_message, 1)
        if state.dataSQLiteProcedures.sqlite.sqliteWithinTransaction():
            state.dataSQLiteProcedures.sqlite.sqliteCommit()
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Fatal', error_message)
    
    raise FatalError(error_message)

def show_severe_error(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(error_message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
    
    state.dataErrTracking.TotalSevereErrors += 1
    if (state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and 
        not state.dataGlobal.KickOffSimulation and not state.dataErrTracking.AbortProcessing):
        state.dataErrTracking.TotalSevereErrorsDuringWarmup += 1
    if state.dataGlobal.DoingSizing:
        state.dataErrTracking.TotalSevereErrorsDuringSizing += 1
    
    show_error_message(state, f" ** Severe  ** {error_message}", out_unit1, out_unit2)
    state.dataErrTracking.LastSevereError = error_message
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, error_message, 1)
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Severe', error_message)

def show_severe_message(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(error_message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
    
    show_error_message(state, f" ** Severe  ** {error_message}", out_unit1, out_unit2)
    state.dataErrTracking.LastSevereError = error_message
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, error_message, 0)
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Severe', error_message)

def show_continue_error(state: Any, message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    show_error_message(state, f" **   ~~~   ** {message}", out_unit1, out_unit2)
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(message)
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Continue', message)

def show_continue_error_time_stamp(state: Any, message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    cenv_header = ""
    
    if state.dataGlobal.WarmupFlag:
        if not state.dataGlobal.SetupFlag:
            if not state.dataGlobal.DoingSizing:
                cenv_header = " During Warmup, Environment="
            else:
                cenv_header = " During Warmup & Sizing, Environment="
        else:
            if not state.dataGlobal.DoingSizing:
                cenv_header = " During Setup, Environment="
            else:
                cenv_header = " During Setup & Sizing, Environment="
    else:
        if not state.dataGlobal.DoingSizing:
            cenv_header = " Environment="
        else:
            cenv_header = " During Sizing, Environment="
    
    if len(message) < 50:
        sys_time_interval = create_sys_time_interval_string(state)
        m = f"{message}{cenv_header}{state.dataEnvrn.EnvironmentName}, at Simulation time={state.dataEnvrn.CurMnDy} {sys_time_interval}"
        show_error_message(state, f" **   ~~~   ** {m}", out_unit1, out_unit2)
        
        if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(m)
        
        if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback('Continue', m)
    else:
        sys_time_interval = create_sys_time_interval_string(state)
        postfix = f"{cenv_header}{state.dataEnvrn.EnvironmentName}, at Simulation time={state.dataEnvrn.CurMnDy} {sys_time_interval}"
        show_error_message(state, f" **   ~~~   ** {message}")
        show_error_message(state, f" **   ~~~   ** {postfix}", out_unit1, out_unit2)
        
        if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(message)
        
        if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback('Continue', message)
            state.dataGlobal.errorCallback('Continue', postfix)

def show_message(state: Any, message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    if not message:
        show_error_message(state, " *************", out_unit1, out_unit2)
    else:
        show_error_message(state, f" ************* {message}", out_unit1, out_unit2)
        
        if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, -1, message, 0)
        
        if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback('Info', message)

def show_warning_error(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(error_message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
    
    state.dataErrTracking.TotalWarningErrors += 1
    if (state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and 
        not state.dataGlobal.KickOffSimulation and not state.dataErrTracking.AbortProcessing):
        state.dataErrTracking.TotalWarningErrorsDuringWarmup += 1
    if state.dataGlobal.DoingSizing:
        state.dataErrTracking.TotalWarningErrorsDuringSizing += 1
    
    show_error_message(state, f" ** Warning ** {error_message}", out_unit1, out_unit2)
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, error_message, 1)
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Warning', error_message)

def show_warning_message(state: Any, error_message: str, out_unit1: Optional[Any] = None, out_unit2: Optional[Any] = None) -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(error_message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
    
    show_error_message(state, f" ** Warning ** {error_message}", out_unit1, out_unit2)
    
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, error_message, 0)
    
    if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback('Warning', error_message)

def show_recurring_severe_error_at_end(state: Any, message: str, msg_index: List[int],
                                       report_max_of: Optional[float] = None, report_min_of: Optional[float] = None,
                                       report_sum_of: Optional[float] = None, report_max_units: str = "",
                                       report_min_units: str = "", report_sum_units: str = "") -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
            break
    
    b_new_message_found = True
    for loop in range(state.dataErrTracking.NumRecurringErrors):
        if same_string(state.dataErrTracking.RecurringErrors[loop].Message, f" ** Severe  ** {message}"):
            b_new_message_found = False
            msg_index[0] = loop
            break
    
    if b_new_message_found:
        msg_index[0] = 0
    
    state.dataErrTracking.TotalSevereErrors += 1
    store_recurring_error_message(state, f" ** Severe  ** {message}", msg_index, report_max_of, report_min_of,
                                  report_sum_of, report_max_units, report_min_units, report_sum_units)

def show_recurring_warning_error_at_end(state: Any, message: str, msg_index: List[int],
                                        report_max_of: Optional[float] = None, report_min_of: Optional[float] = None,
                                        report_sum_of: Optional[float] = None, report_max_units: str = "",
                                        report_min_units: str = "", report_sum_units: str = "") -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
            break
    
    b_new_message_found = True
    for loop in range(state.dataErrTracking.NumRecurringErrors):
        if same_string(state.dataErrTracking.RecurringErrors[loop].Message, f" ** Warning ** {message}"):
            b_new_message_found = False
            msg_index[0] = loop
            break
    
    if b_new_message_found:
        msg_index[0] = 0
    
    state.dataErrTracking.TotalWarningErrors += 1
    store_recurring_error_message(state, f" ** Warning ** {message}", msg_index, report_max_of, report_min_of,
                                  report_sum_of, report_max_units, report_min_units, report_sum_units)

def show_recurring_continue_error_at_end(state: Any, message: str, msg_index: List[int],
                                        report_max_of: Optional[float] = None, report_min_of: Optional[float] = None,
                                        report_sum_of: Optional[float] = None, report_max_units: str = "",
                                        report_min_units: str = "", report_sum_units: str = "") -> None:
    for loop in range(len(getattr(state.dataErrorTracking, 'MessageSearch', []))):
        if has(message, state.dataErrorTracking.MessageSearch[loop]):
            state.dataErrTracking.MatchCounts[loop] += 1
            break
    
    b_new_message_found = True
    for loop in range(state.dataErrTracking.NumRecurringErrors):
        if same_string(state.dataErrTracking.RecurringErrors[loop].Message, f" **   ~~~   ** {message}"):
            b_new_message_found = False
            msg_index[0] = loop
            break
    
    if b_new_message_found:
        msg_index[0] = 0
    
    store_recurring_error_message(state, f" **   ~~~   ** {message}", msg_index, report_max_of, report_min_of,
                                  report_sum_of, report_max_units, report_min_units, report_sum_units)

def store_recurring_error_message(state: Any, error_message: str, error_msg_index: List[int],
                                  error_report_max_of: Optional[float] = None, error_report_min_of: Optional[float] = None,
                                  error_report_sum_of: Optional[float] = None, error_report_max_units: str = "",
                                  error_report_min_units: str = "", error_report_sum_units: str = "") -> None:
    if error_msg_index[0] == 0:
        state.dataErrTracking.NumRecurringErrors += 1
        state.dataErrTracking.RecurringErrors.append({
            'Message': error_message,
            'Count': 1,
            'WarmupCount': 1 if state.dataGlobal.WarmupFlag else 0,
            'SizingCount': 1 if state.dataGlobal.DoingSizing else 0,
            'MaxValue': error_report_max_of if error_report_max_of is not None else 0.0,
            'ReportMax': error_report_max_of is not None,
            'MaxUnits': error_report_max_units,
            'MinValue': error_report_min_of if error_report_min_of is not None else 0.0,
            'ReportMin': error_report_min_of is not None,
            'MinUnits': error_report_min_units,
            'SumValue': error_report_sum_of if error_report_sum_of is not None else 0.0,
            'ReportSum': error_report_sum_of is not None,
            'SumUnits': error_report_sum_units
        })
        error_msg_index[0] = state.dataErrTracking.NumRecurringErrors
    elif error_msg_index[0] > 0:
        err = state.dataErrTracking.RecurringErrors[error_msg_index[0] - 1]
        err['Count'] += 1
        if state.dataGlobal.WarmupFlag:
            err['WarmupCount'] += 1
        if state.dataGlobal.DoingSizing:
            err['SizingCount'] += 1
        
        if error_report_max_of is not None:
            err['MaxValue'] = max(error_report_max_of, err['MaxValue'])
            err['ReportMax'] = True
        if error_report_min_of is not None:
            err['MinValue'] = min(error_report_min_of, err['MinValue'])
            err['ReportMin'] = True
        if error_report_sum_of is not None:
            err['SumValue'] += error_report_sum_of
            err['ReportSum'] = True

def summarize_errors(state: Any) -> None:
    if any(state.dataErrTracking.MatchCounts):
        show_message(state, "")
        show_message(state, "===== Final Error Summary =====")
        show_message(state, "The following error categories occurred.  Consider correcting or noting.")
        
        for loop in range(len(getattr(state.dataErrorTracking, 'Summaries', []))):
            if state.dataErrTracking.MatchCounts[loop] > 0:
                show_message(state, state.dataErrorTracking.Summaries[loop])
                this_more_details = getattr(state.dataErrorTracking, 'MoreDetails', [''])[loop] if loop < len(getattr(state.dataErrorTracking, 'MoreDetails', [])) else ""
                
                if this_more_details:
                    start_c = 0
                    while start_c < len(this_more_details):
                        end_c = this_more_details.find("<CR", start_c)
                        if end_c == -1:
                            break
                        show_message(state, f"..{this_more_details[start_c:end_c]}")
                        if this_more_details[end_c:end_c+5] == "<CRE>":
                            break
                        start_c = end_c + 4
        
        show_message(state, "")

def show_recurring_errors(state: Any) -> None:
    if state.dataErrTracking.NumRecurringErrors > 0:
        show_message(state, "")
        show_message(state, "===== Recurring Error Summary =====")
        show_message(state, "The following recurring error messages occurred.")
        
        for loop in range(state.dataErrTracking.NumRecurringErrors):
            error = state.dataErrTracking.RecurringErrors[loop]
            
            if error['Message'].startswith(" **   ~~~   ** "):
                show_message(state, error['Message'])
                if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(error['Message'])
                if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
                    state.dataGlobal.errorCallback('Continue', error['Message'])
            else:
                warning = error['Message'].startswith(" ** Warning ** ")
                severe = error['Message'].startswith(" ** Severe  ** ")
                
                show_message(state, "")
                show_message(state, error['Message'])
                show_message(state, f" **   ~~~   **   This error occurred {error['Count']} total times;")
                show_message(state, f" **   ~~~   **   during Warmup {error['WarmupCount']} times;")
                show_message(state, f" **   ~~~   **   during Sizing {error['SizingCount']} times.")
                
                if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
                    if warning:
                        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, error['Message'][15:], error['Count'])
                    elif severe:
                        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, error['Message'][15:], error['Count'])
                
                if hasattr(state.dataGlobal, 'errorCallback') and state.dataGlobal.errorCallback:
                    level = 'Warning'
                    if severe:
                        level = 'Severe'
                    state.dataGlobal.errorCallback(level, error['Message'])
                    state.dataGlobal.errorCallback('Continue', "")
            
            stat_message = ""
            if error['ReportMax']:
                max_out = f"{error['MaxValue']:.6f}"
                stat_message += f"  Max={max_out}"
                if error['MaxUnits']:
                    stat_message += f" {error['MaxUnits']}"
            if error['ReportMin']:
                min_out = f"{error['MinValue']:.6f}"
                stat_message += f"  Min={min_out}"
                if error['MinUnits']:
                    stat_message += f" {error['MinUnits']}"
            if error['ReportSum']:
                sum_out = f"{error['SumValue']:.6f}"
                stat_message += f"  Sum={sum_out}"
                if error['SumUnits']:
                    stat_message += f" {error['SumUnits']}"
            
            if error['ReportMax'] or error['ReportMin'] or error['ReportSum']:
                show_message(state, f" **   ~~~   ** {stat_message}")
        
        show_message(state, "")

def abort_energy_plus(state: Any) -> int:
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteSimulationRecord(True, False)
    
    state.dataErrTracking.AbortProcessing = True
    
    if state.dataErrTracking.AskForConnectionsReport:
        state.dataErrTracking.AskForConnectionsReport = False
        show_message(state, "Fatal error -- final processing.  More error messages may appear.")
        
        err_found = False
        terminal_error = False
        test_branch_integrity(state, err_found)
        if err_found:
            terminal_error = True
        test_air_path_integrity(state, err_found)
        if err_found:
            terminal_error = True
        check_marked_nodes(state, err_found)
        if err_found:
            terminal_error = True
        check_node_connections(state, err_found)
        if err_found:
            terminal_error = True
        test_comp_set_inlet_outlet_nodes(state, err_found)
        if err_found:
            terminal_error = True
        
        if not terminal_error:
            report_air_loop_connections(state)
            report_loop_connections(state)
    elif not state.dataErrTracking.ExitDuringSimulations:
        show_message(state, "Warning:  Node connection errors not checked - most system input has not been read (see previous warning).")
        show_message(state, "Fatal error -- final processing.  Program exited before simulations began.  See previous error messages.")
    
    if state.dataErrTracking.AskForSurfacesReport:
        report_surfaces(state)
    
    report_surface_errors(state)
    check_plant_on_abort(state)
    show_recurring_errors(state)
    summarize_errors(state)
    close_misc_open_files(state)
    
    num_warnings = str(state.dataErrTracking.TotalWarningErrors)
    num_severe = str(state.dataErrTracking.TotalSevereErrors)
    num_warnings_during_warmup = str(state.dataErrTracking.TotalWarningErrorsDuringWarmup)
    num_severe_during_warmup = str(state.dataErrTracking.TotalSevereErrorsDuringWarmup)
    num_warnings_during_sizing = str(state.dataErrTracking.TotalWarningErrorsDuringSizing)
    num_severe_during_sizing = str(state.dataErrTracking.TotalSevereErrorsDuringSizing)
    
    state.dataSysVars.runtimeTimer.tock()
    elapsed = state.dataSysVars.runtimeTimer.formatAsHourMinSecs()
    
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime(elapsed)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup(num_warnings_during_warmup, num_severe_during_warmup)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing(num_warnings_during_sizing, num_severe_during_sizing)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary(num_warnings, num_severe)
    
    show_message(state, f"EnergyPlus Warmup Error Summary. During Warmup: {num_warnings_during_warmup} Warning; {num_severe_during_warmup} Severe Errors.")
    show_message(state, f"EnergyPlus Sizing Error Summary. During Sizing: {num_warnings_during_sizing} Warning; {num_severe_during_sizing} Severe Errors.")
    show_message(state, f"EnergyPlus Terminated--Fatal Error Detected. {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed}")
    display_string(state, f"EnergyPlus Run Time={elapsed}")
    
    try:
        with open(state.files.endFile, 'w') as f:
            f.write(f"EnergyPlus Terminated--Fatal Error Detected. {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed}\n")
    except Exception:
        display_string(state, f"AbortEnergyPlus: Could not open file {state.files.endFile} for output (write).")
    
    state.dataResultsFramework.resultsFramework.writeOutputs(state)
    
    print("Program terminated: EnergyPlus Terminated--Error(s) Detected.", file=sys.stderr)
    
    if state.dataExternalInterface.NumExternalInterfaces > 0:
        close_socket(state, -1)
    
    if state.dataGlobal.eplusRunningViaAPI:
        state.files.flushAll()
    
    state.files.audit.close()
    
    return 1

def close_misc_open_files(state: Any) -> None:
    close_report_illum_maps(state)
    close_dfs_file(state)
    
    if state.dataReportFlag.DebugOutput or (hasattr(state.files, 'debug') and state.files.debug.position() > 0):
        state.files.debug.close()
    else:
        state.files.debug.delete()

def end_energy_plus(state: Any) -> int:
    if hasattr(state, 'dataSQLiteProcedures') and state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteSimulationRecord(True, True)
    
    report_surface_errors(state)
    show_recurring_errors(state)
    summarize_errors(state)
    close_misc_open_files(state)
    
    num_warnings = str(state.dataErrTracking.TotalWarningErrors).strip()
    num_severe = str(state.dataErrTracking.TotalSevereErrors).strip()
    num_warnings_during_warmup = str(state.dataErrTracking.TotalWarningErrorsDuringWarmup).strip()
    num_severe_during_warmup = str(state.dataErrTracking.TotalSevereErrorsDuringWarmup).strip()
    num_warnings_during_sizing = str(state.dataErrTracking.TotalWarningErrorsDuringSizing).strip()
    num_severe_during_sizing = str(state.dataErrTracking.TotalSevereErrorsDuringSizing).strip()
    
    state.dataSysVars.runtimeTimer.tock()
    
    if state.dataGlobal.createPerfLog:
        append_perf_log(state, "Run Time [seconds]", f"{state.dataSysVars.runtimeTimer.elapsedSeconds():.2f}")
    
    elapsed = state.dataSysVars.runtimeTimer.formatAsHourMinSecs()
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime(elapsed)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup(num_warnings_during_warmup, num_severe_during_warmup)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing(num_warnings_during_sizing, num_severe_during_sizing)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary(num_warnings, num_severe)
    
    if state.dataGlobal.createPerfLog:
        append_perf_log(state, "Run Time [string]", elapsed)
        append_perf_log(state, "Number of Warnings", num_warnings)
        append_perf_log(state, "Number of Severe", num_severe, True)
    
    show_message(state, f"EnergyPlus Warmup Error Summary. During Warmup: {num_warnings_during_warmup} Warning; {num_severe_during_warmup} Severe Errors.")
    show_message(state, f"EnergyPlus Sizing Error Summary. During Sizing: {num_warnings_during_sizing} Warning; {num_severe_during_sizing} Severe Errors.")
    show_message(state, f"EnergyPlus Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed}")
    display_string(state, f"EnergyPlus Run Time={elapsed}")
    
    try:
        with open(state.files.endFile, 'w') as f:
            f.write(f"EnergyPlus Completed Successfully-- {num_warnings} Warning; {num_severe} Severe Errors; Elapsed Time={elapsed}\n")
    except Exception:
        display_string(state, f"EndEnergyPlus: Could not open file {state.files.endFile} for output (write).")
    
    state.dataResultsFramework.resultsFramework.writeOutputs(state)
    
    if state.dataGlobal.printConsoleOutput:
        print("EnergyPlus Completed Successfully.")
    
    if state.dataExternalInterface.NumExternalInterfaces > 0 and state.dataExternalInterface.haveExternalInterfaceBCVTB:
        close_socket(state, 1)
    
    if state.dataGlobal.fProgressPtr is not None:
        state.dataGlobal.fProgressPtr(100)
    if state.dataGlobal.progressCallback is not None:
        state.dataGlobal.progressCallback(100)
    
    if state.dataGlobal.eplusRunningViaAPI:
        state.files.flushAll()
    
    state.files.audit.close()
    
    return 0

def show_severe_duplicate_name(state: Any, eoh: ErrorObjectHeader) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}, duplicate name.")

def show_severe_empty_field(state: Any, eoh: ErrorObjectHeader, field_name: str, dep_field_name: str = "", 
                            dep_field_value: str = "") -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    suffix = "" if not dep_field_name else f" when {dep_field_name} = {dep_field_value}"
    show_continue_error(state, f"{field_name} cannot be empty{suffix}.")

def show_severe_item_not_found(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, item not found.")

def show_detailed_severe_item_not_found(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {field_name} = {field_value}, item not found.")
    show_continue_error(state, f"{field_name} = {field_value}, item not found.")

def show_severe_item_not_found_audit(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}", state.files.audit)
    show_continue_error(state, f"{field_name} = {field_value}, item not found.", state.files.audit)

def show_severe_duplicate_assignment(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, 
                                     prev_value: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, field previously assigned to {prev_value}.")

def show_severe_invalid_key(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, 
                           msg: str = "") -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, invalid key.")
    if msg:
        show_continue_error(state, msg)

def show_severe_invalid_bool(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, invalid boolean (\"Yes\"/\"No\").")

def show_severe_custom(state: Any, eoh: ErrorObjectHeader, msg: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, msg)

def show_severe_custom_field(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, msg: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, {msg}")

def show_severe_custom_audit(state: Any, eoh: ErrorObjectHeader, msg: str) -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}", state.files.audit)
    show_continue_error(state, msg, state.files.audit)

def show_severe_bad_min(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_min: Clusive,
                       min_val: float, msg: str = "") -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op = ">=" if clu_min == Clusive.In else ">"
    show_continue_error(state, f"{field_name} = {field_val}, but must be {op} {min_val}")
    if msg:
        show_continue_error(state, msg)

def show_severe_bad_max(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_max: Clusive,
                       max_val: float, msg: str = "") -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, f"{field_name} = {field_val}, but must be {op} {max_val}")
    if msg:
        show_continue_error(state, msg)

def show_severe_bad_min_max(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_min: Clusive,
                           min_val: float, clu_max: Clusive, max_val: float, msg: str = "") -> None:
    show_severe_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op_min = ">=" if clu_min == Clusive.In else ">"
    op_max = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, f"{field_name} = {field_val}, but must be {op_min} {min_val} and {op_max} {max_val}")
    if msg:
        show_continue_error(state, msg)

def show_warning_item_not_found(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, 
                               default_value: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    if not default_value:
        show_continue_error(state, f"{field_name} = {field_value}, item not found.")
    else:
        show_continue_error(state, f"{field_name} = {field_value}, item not found, {default_value} will be used.")

def show_warning_custom(state: Any, eoh: ErrorObjectHeader, msg: str) -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, msg)

def show_warning_custom_field(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, msg: str) -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, {msg}")

def show_warning_invalid_key(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, 
                            default_value: str, msg: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, invalid key, {default_value} will be used.")
    if msg:
        show_continue_error(state, msg)

def show_warning_invalid_bool(state: Any, eoh: ErrorObjectHeader, field_name: str, field_value: str, 
                             default_value: str) -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} = {field_value}, invalid boolean (\"Yes\"/\"No\"), {default_value} will be used.")

def show_warning_empty_field(state: Any, eoh: ErrorObjectHeader, field_name: str, default_value: str = "", 
                            dep_field_name: str = "", dep_field_value: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} is empty.")
    
    if dep_field_name:
        show_continue_error(state, f"Cannot be empty when {dep_field_name} = {dep_field_value}")
    if default_value:
        show_continue_error(state, f"{default_value} will be used.")

def show_warning_non_empty_field(state: Any, eoh: ErrorObjectHeader, field_name: str, dep_field_name: str = "", 
                                dep_field_value: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    show_continue_error(state, f"{field_name} is not empty.")
    if dep_field_name:
        show_continue_error(state, f"{field_name} is ignored when {dep_field_name} = {dep_field_value}.")

def show_warning_bad_min(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_min: Clusive,
                        min_val: float, msg: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op = ">=" if clu_min == Clusive.In else ">"
    show_continue_error(state, f"{field_name} = {field_val:.2f}, but must be {op} {min_val:.2f}")
    if msg:
        show_continue_error(state, msg)

def show_warning_bad_max(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_max: Clusive,
                        max_val: float, msg: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, f"{field_name} = {field_val:.2f}, but must be {op} {max_val:.2f}")
    if msg:
        show_continue_error(state, msg)

def show_warning_bad_min_max(state: Any, eoh: ErrorObjectHeader, field_name: str, field_val: float, clu_min: Clusive,
                            min_val: float, clu_max: Clusive, max_val: float, msg: str = "") -> None:
    show_warning_error(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    op_min = ">=" if clu_min == Clusive.In else ">"
    op_max = "<=" if clu_max == Clusive.In else "<"
    show_continue_error(state, f"{field_name} = {field_val}, but must be {op_min} {min_val} and {op_max} {max_val}")
    if msg:
        show_continue_error(state, msg)

def fclamp(v: float, min_val: float, max_val: float) -> float:
    if v < min_val:
        return min_val
    elif v > max_val:
        return max_val
    return v

def get_enum_value(s_list: List[str], s: str) -> int:
    for i, item in enumerate(s_list):
        if item == s:
            return i
    return -1

def get_yes_no_value(s: str) -> int:
    return get_enum_value(YES_NO_NAMES_UC, s)

class FatalError(Exception):
    pass

def display_string(state: Any, msg: str) -> None:
    print(msg, file=sys.stderr)

def has(text: str, substring: str) -> bool:
    return substring in text

def equali(a: str, b: str) -> bool:
    return a.upper() == b.upper()

def lessthani(a: str, b: str) -> bool:
    return a.upper() < b.upper()

def create_sys_time_interval_string(state: Any) -> str:
    return ""

def test_branch_integrity(state: Any, err_found: bool) -> None:
    pass

def test_air_path_integrity(state: Any, err_found: bool) -> None:
    pass

def check_marked_nodes(state: Any, err_found: bool) -> None:
    pass

def check_node_connections(state: Any, err_found: bool) -> None:
    pass

def test_comp_set_inlet_outlet_nodes(state: Any, err_found: bool) -> None:
    pass

def report_air_loop_connections(state: Any) -> None:
    pass

def report_loop_connections(state: Any) -> None:
    pass

def report_surfaces(state: Any) -> None:
    pass

def report_surface_errors(state: Any) -> None:
    pass

def check_plant_on_abort(state: Any) -> None:
    pass

def close_report_illum_maps(state: Any) -> None:
    pass

def close_dfs_file(state: Any) -> None:
    pass

def close_socket(state: Any, flag: int) -> None:
    pass
