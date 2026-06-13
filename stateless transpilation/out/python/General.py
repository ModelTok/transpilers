from typing import Callable, Optional, List, Protocol, Any, Dict
from dataclasses import dataclass, field
from enum import Enum
import math
from array import array

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object with all module contexts
# - Weather.DateType: enum for date type classification
# - Weather.ReportPeriodData: struct with startJulianDate, startHour, endJulianDate, endHour, startYear
# - Weather.computeJulianDate(year, month, day): returns Julian day number
# - DataEnvironment: state.dataEnvrn with CurrentYearIsLeapYear, RunPeriodStartDayOfWeek, Year, Month, DayOfMonth
# - DataHVACGlobals: state.dataHVACGlobal with SysTimeElapsed, TimeStepSys
# - DataGlobal: state.dataGlobal with CurrentTime, TimeStepZone, HourOfDay, ShowDecayCurvesInEIO
# - DataIPShortCuts: state.dataIPShortCut with cAlphaArgs, rNumericArgs, lNumericFieldBlanks, etc.
# - InputProcessor: state.dataInputProcessing.inputProcessor methods
# - UtilityRoutines: ShowSevereError, ShowWarningError, ShowContinueError, FindItemInList, SameString, makeUPPER, ProcessNumber
# - HVACSystemRootFindingAlgorithm: RootAlgo enum with values
# - DataRuntimeLanguage: state.dataRuntimeLang with EMS output flags
# - Util module: string/number processing utilities

SOLVEROOT_ERROR_INIT = -2
SOLVEROOT_ERROR_ITER = -1


class RootAlgo(Enum):
    RegulaFalsi = 0
    Bisection = 1
    RegulaFalsiThenBisection = 2
    BisectionThenRegulaFalsi = 3
    Alternation = 4
    ShortBisectionThenRegulaFalsi = 5
    Num = 6
    Invalid = -1


class ReportType(Enum):
    Invalid = -1
    DXF = 0
    DXFWireFrame = 1
    VRML = 2
    Num = 3


class AvailRpt(Enum):
    Invalid = -1
    None_ = 0
    NotByUniqueKeyNames = 1
    Verbose = 2
    Num = 3


class ERLdebugOutputLevel(Enum):
    Invalid = -1
    None_ = 0
    ErrorsOnly = 1
    Verbose = 2
    Num = 3


class ReportName(Enum):
    Invalid = -1
    Constructions = 0
    Viewfactorinfo = 1
    Variabledictionary = 2
    Surfaces = 3
    Energymanagementsystem = 4
    Num = 5


class RptKey(Enum):
    Invalid = -1
    Costinfo = 0
    DXF = 1
    DXFwireframe = 2
    VRML = 3
    Vertices = 4
    Details = 5
    DetailsWithVertices = 6
    Lines = 7
    Num = 8


REPORT_TYPE_NAMES_UC = ["DXF", "DXF:WIREFRAME", "VRML"]
AVAIL_RPT_NAMES_UC = ["NONE", "NOTBYUNIQUEKEYNAMES", "VERBOSE"]
ERL_DEBUG_OUTPUT_LEVEL_NAMES_UC = ["NONE", "ERRORSONLY", "VERBOSE"]
REPORT_NAMES_UC = ["CONSTRUCTIONS", "VIEWFACTORINFO", "VARIABLEDICTIONARY", "SURFACES", "ENERGYMANAGEMENTSYSTEM"]
RPT_KEY_NAMES_UC = ["COSTINFO", "DXF", "DXF:WIREFRAME", "VRML", "VERTICES", "DETAILS", "DETAILSWITHVERTICES", "LINES"]


@dataclass
class SolveRootStats:
    algo: RootAlgo = RootAlgo.RegulaFalsi
    counts: int = 0
    algo_counts: List[int] = field(default_factory=lambda: [0] * int(RootAlgo.Num))
    algo_iters: List[int] = field(default_factory=lambda: [0] * int(RootAlgo.Num))


@dataclass
class InterpCoeffs:
    x1: float = 0.0
    x2: float = 0.0


@dataclass
class BilinearInterpCoeffs:
    denom: float = 0.0
    x1y1: float = 0.0
    x1y2: float = 0.0
    x2y1: float = 0.0
    x2y2: float = 0.0


@dataclass
class GeneralData:
    get_report_input: bool = True
    surf_vert: bool = False
    surf_det: bool = False
    surf_det_w_vert: bool = False
    dxf_report: bool = False
    dxf_wf_report: bool = False
    vrml_report: bool = False
    cost_info: bool = False
    view_factor_info: bool = False
    constructions: bool = False
    materials: bool = False
    line_rpt: bool = False
    var_dict: bool = False
    ems_output: bool = False
    x_next: float = 0.0
    dxf_option1: str = ""
    dxf_option2: str = ""
    dxf_wf_option1: str = ""
    dxf_wf_option2: str = ""
    vrml_option1: str = ""
    vrml_option2: str = ""
    view_rpt_option1: str = ""
    line_rpt_option1: str = ""
    var_dict_option1: str = ""
    var_dict_option2: str = ""


def interp(lower: float, upper: float, interp_fac: float) -> float:
    return lower + interp_fac * (upper - lower)


def get_interp_coeffs(x: float, x1: float, x2: float) -> InterpCoeffs:
    c = InterpCoeffs()
    c.x1 = (x - x1) / (x2 - x1)
    c.x2 = (x2 - x) / (x2 - x1)
    return c


def interp2(fx1: float, fx2: float, c: InterpCoeffs) -> float:
    return c.x1 * fx1 + c.x2 * fx2


def get_bilinear_interp_coeffs(x: float, y: float, x1: float, x2: float, y1: float, y2: float) -> BilinearInterpCoeffs:
    coeffs = BilinearInterpCoeffs()
    if x1 == x2 and y1 == y2:
        coeffs.denom = coeffs.x1y1 = 1.0
        coeffs.x1y2 = coeffs.x2y1 = coeffs.x2y2 = 0.0
    elif x1 == x2:
        coeffs.denom = (y2 - y1)
        coeffs.x1y1 = (y2 - y)
        coeffs.x1y2 = (y - y1)
        coeffs.x2y1 = coeffs.x2y2 = 0.0
    elif y1 == y2:
        coeffs.denom = (x2 - x1)
        coeffs.x1y1 = (x2 - x)
        coeffs.x2y1 = (x - x1)
        coeffs.x1y2 = coeffs.x2y2 = 0.0
    else:
        coeffs.denom = (x2 - x1) * (y2 - y1)
        coeffs.x1y1 = (x2 - x) * (y2 - y)
        coeffs.x2y1 = (x - x1) * (y2 - y)
        coeffs.x1y2 = (x2 - x) * (y - y1)
        coeffs.x2y2 = (x - x1) * (y - y1)
    return coeffs


def bilinear_interp(fx1y1: float, fx1y2: float, fx2y1: float, fx2y2: float, coeffs: BilinearInterpCoeffs) -> float:
    return (coeffs.x1y1 * fx1y1 + coeffs.x2y1 * fx2y1 + coeffs.x1y2 * fx1y2 + coeffs.x2y2 * fx2y2) / coeffs.denom


def epexp(numerator: float, denominator: float) -> float:
    if denominator == 0.0:
        return 0.0
    return math.exp(numerator / denominator)


def solve_root(state: Any, eps: float, max_ite: int, f: Callable[[float], float], x_0: float, x_1: float) -> tuple:
    small = 1.0e-10
    x0 = x_0
    x1 = x_1
    xtemp = x0
    nite = 0
    alt_ite = 0

    y0 = f(x0)
    y1 = f(x1)

    if y0 * y1 > 0:
        return (SOLVEROOT_ERROR_INIT, x0)

    xres = xtemp

    while True:
        dy = y0 - y1
        if abs(dy) < small:
            dy = small
        if abs(x1 - x0) < small:
            break

        root_algo = state.dataRootFinder.root_algo
        if root_algo == RootAlgo.RegulaFalsi:
            xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == RootAlgo.Bisection:
            xtemp = (x1 + x0) / 2.0
        elif root_algo == RootAlgo.RegulaFalsiThenBisection:
            if nite > state.dataRootFinder.num_of_iter:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == RootAlgo.BisectionThenRegulaFalsi:
            if nite <= state.dataRootFinder.num_of_iter:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == RootAlgo.Alternation:
            if alt_ite > state.dataRootFinder.num_of_iter:
                xtemp = (x1 + x0) / 2.0
                if alt_ite >= 2 * state.dataRootFinder.num_of_iter:
                    alt_ite = 0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == RootAlgo.ShortBisectionThenRegulaFalsi:
            if nite < 3:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        else:
            xtemp = (y0 * x1 - y1 * x0) / dy

        ytemp = f(xtemp)
        nite += 1
        alt_ite += 1

        if abs(ytemp) < eps:
            return (nite, xtemp)

        if nite > max_ite:
            break

        if y0 < 0.0:
            if ytemp < 0.0:
                x0 = xtemp
                y0 = ytemp
            else:
                x1 = xtemp
                y1 = ytemp
        else:
            if ytemp < 0.0:
                x1 = xtemp
                y1 = ytemp
            else:
                x0 = xtemp
                y0 = ytemp

    return (SOLVEROOT_ERROR_ITER, xtemp)


def solve_root2(state: Any, eps: float, max_iters: int, f: Callable[[float], float], x_0: float, x_1: float, stats: SolveRootStats) -> tuple:
    algo_temp = state.dataRootFinder.root_algo
    state.dataRootFinder.root_algo = stats.algo

    sol_flag, xres = solve_root(state, eps, max_iters, f, x_0, x_1)

    state.dataRootFinder.root_algo = algo_temp

    if sol_flag > 0:
        stats.counts += 1
        stats.algo_counts[int(stats.algo.value)] += 1
        stats.algo_iters[int(stats.algo.value)] += sol_flag

        TRIALS_PER_COUNT = 5

        if stats.counts < TRIALS_PER_COUNT * int(RootAlgo.Num.value):
            stats.algo = RootAlgo(int(stats.algo.value) + 1)
            if stats.algo == RootAlgo.Num:
                stats.algo = RootAlgo.RegulaFalsi
        elif stats.counts == TRIALS_PER_COUNT * int(RootAlgo.Num.value):
            min_iters = max_iters * TRIALS_PER_COUNT
            stats.algo = RootAlgo.Invalid
            for i in range(int(RootAlgo.Num.value)):
                if stats.algo_iters[i] < min_iters:
                    stats.algo = RootAlgo(i)
                    min_iters = stats.algo_iters[i]

    return (sol_flag, xres)


def moving_avg(data_in: List[float], num_items_in_avg: int) -> None:
    if num_items_in_avg <= 1:
        return

    temp_data = [0.0] * (2 * len(data_in))

    for i in range(len(data_in)):
        temp_data[i] = data_in[i]
        temp_data[len(data_in) + i] = data_in[i]
        data_in[i] = 0.0

    for i in range(len(data_in)):
        for j in range(1, num_items_in_avg + 1):
            data_in[i] += temp_data[len(data_in) - num_items_in_avg + i + j]
        data_in[i] /= num_items_in_avg


def ordinal_day(month: int, day: int, leap_year_value: int) -> int:
    end_day_of_month = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]

    if month == 1:
        return day
    if month == 2:
        return day + end_day_of_month[0]
    if 3 <= month <= 12:
        return day + end_day_of_month[month - 2] + leap_year_value
    return 0


def inv_ordinal_day(number: int, leap_yr: int) -> tuple:
    end_of_month = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]

    if number < 0 or number > 366:
        return (0, 0)

    for w_month in range(1, 13):
        if w_month == 1:
            leap_add_prev = 0
            leap_add_cur = 0
        elif w_month == 2:
            leap_add_prev = 0
            leap_add_cur = leap_yr
        else:
            leap_add_prev = leap_yr
            leap_add_cur = leap_yr

        if (number > (end_of_month[w_month - 1] + leap_add_prev) and 
            number <= (end_of_month[w_month] + leap_add_cur)):
            p_month = w_month
            p_day = number - (end_of_month[w_month - 1] + leap_add_cur)
            return (p_month, p_day)

    return (0, 0)


def between_date_hours_left_inclusive(test_date: int, test_hour: int, start_date: int, start_hour: int, end_date: int, end_hour: int) -> bool:
    test_ratio_of_day = test_hour / 24.0
    start_ratio_of_day = start_hour / 24.0
    end_ratio_of_day = end_hour / 24.0

    if start_date + start_ratio_of_day <= end_date + end_ratio_of_day:
        return ((start_date + start_ratio_of_day <= test_date + test_ratio_of_day) and 
                (test_date + test_ratio_of_day <= end_date + end_ratio_of_day))
    return ((end_date + end_ratio_of_day <= test_date + test_ratio_of_day) and 
            (test_date + test_ratio_of_day <= start_date + start_ratio_of_day))


def between_dates(test_date: int, start_date: int, end_date: int) -> bool:
    between_dates_result = False

    if start_date <= end_date:
        if test_date >= start_date and test_date <= end_date:
            between_dates_result = True
    else:
        if test_date <= end_date or test_date >= start_date:
            between_dates_result = True

    return between_dates_result


def create_sys_time_interval_string(state: Any) -> str:
    sys_time_elapsed = state.dataHVACGlobal.sys_time_elapsed
    time_step_sys = state.dataHVACGlobal.time_step_sys
    frac_to_min = 60.0

    tolerance_time = 0.0001

    if sys_time_elapsed == 0.0:
        actual_time_e = state.dataGlobal.current_time
        actual_time_s = actual_time_e - state.dataGlobal.time_step_zone
    elif abs(state.dataGlobal.time_step_zone - sys_time_elapsed) <= tolerance_time:
        actual_time_e = state.dataGlobal.current_time
        actual_time_s = actual_time_e - time_step_sys
    else:
        actual_time_s = state.dataGlobal.current_time - state.dataGlobal.time_step_zone + sys_time_elapsed
        actual_time_e = actual_time_s + time_step_sys

    actual_time_hr_s = int(actual_time_s)
    actual_time_min_s = round((actual_time_s - actual_time_hr_s) * frac_to_min)

    if actual_time_min_s == 60:
        actual_time_hr_s += 1
        actual_time_min_s = 0

    time_stmp_s = f"{actual_time_hr_s:02d}:{actual_time_min_s:02d}"
    minutes = ((actual_time_e - int(actual_time_e)) * frac_to_min)
    time_stmp_e = f"{int(actual_time_e):02d}:{minutes:2.0f}"

    if time_stmp_e[3] == ' ':
        time_stmp_e = time_stmp_e[:3] + '0' + time_stmp_e[4:]

    return time_stmp_s + " - " + time_stmp_e


def nth_day_of_week_of_month(state: Any, day_of_week: int, nth_time: int, month_number: int) -> int:
    first_day_of_month = ordinal_day(month_number, 1, int(state.dataEnvrn.current_year_is_leap_year))
    day_of_week_for_first_day = (state.dataEnvrn.run_period_start_day_of_week + first_day_of_month - 1) % 7
    if day_of_week >= day_of_week_for_first_day:
        return first_day_of_month + (day_of_week - day_of_week_for_first_day) + 7 * (nth_time - 1)
    return first_day_of_month + ((day_of_week + 7) - day_of_week_for_first_day) + 7 * (nth_time - 1)


def safe_divide(a: float, b: float) -> float:
    SMALL = 1.0e-10
    if abs(b) >= SMALL:
        return a / b
    return a / (SMALL if b >= 0 else -SMALL)


def iterate(tol: float, x0: float, y0: float, x1_ref: List[float], y1_ref: List[float], iter_num: int) -> tuple:
    small = 1.0e-9
    perturb = 0.1

    if iter_num != 1:
        if abs(x0 - x1_ref[0]) < tol or y0 == 0.0:
            return (x0, 1)

    cnvg = 0
    if iter_num == 1:
        if abs(x0) > small:
            result_x = x0 * (1.0 + perturb)
        else:
            result_x = perturb
    else:
        dy = y0 - y1_ref[0]
        if abs(dy) < small:
            dy = small
        result_x = (y0 * x1_ref[0] - y1_ref[0] * x0) / dy

    x1_ref[0] = x0
    y1_ref[0] = y0

    return (result_x, cnvg)


def find_number_in_list(which_number: int, list_of_items: List[int], num_items: int) -> int:
    for count in range(num_items):
        if which_number == list_of_items[count]:
            return count + 1
    return 0


def decode_mon_day_hr_min(item: int) -> tuple:
    dec_mon = 100 * 100 * 100
    dec_day = 100 * 100
    dec_hr = 100

    tmp_item = item
    month = tmp_item // dec_mon
    tmp_item = tmp_item - month * dec_mon
    day = tmp_item // dec_day
    tmp_item -= day * dec_day
    hour = tmp_item // dec_hr
    minute = tmp_item % dec_hr

    return (month, day, hour, minute)


def encode_mon_day_hr_min(month: int, day: int, hour: int, minute: int) -> int:
    return ((month * 100 + day) * 100 + hour) * 100 + minute


def create_time_string(time: float) -> str:
    hours, minutes, seconds = parse_time(time)
    return f"{hours:02d}:{minutes:02d}:{seconds:04.1f}"


def parse_time(time: float) -> tuple:
    min_to_sec = 60
    hour_to_sec = 60 * 60

    hours = int(time) // hour_to_sec
    remainder = time - hours * hour_to_sec
    minutes = int(remainder) // min_to_sec
    remainder -= minutes * min_to_sec
    seconds = remainder

    return (hours, minutes, seconds)


def safe_string_index(s: str, substr: str) -> int:
    try:
        return s.index(substr)
    except ValueError:
        return -1


def determine_date_tokens(state: Any, string: str) -> tuple:
    single_chars = ["/", ":", "-"]
    double_chars = ["ST ", "ND ", "RD ", "TH ", "OF ", "IN "]
    months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    current_string = string
    num_tokens = 0
    token_day = 0
    token_month = 0
    token_weekday = 0
    token_year = 0
    date_type = None
    errors_found = False
    internal_error = False
    wk_day_in_month = False

    for char in single_chars:
        while char in current_string:
            current_string = current_string.replace(char, ' ')

    for char in double_chars:
        while char in current_string:
            current_string = current_string.replace(char, '  ', 1)
            wk_day_in_month = True

    current_string = current_string.strip()

    if current_string == "":
        errors_found = True
    else:
        fields = []
        loop = 0
        while loop < 3 and current_string:
            pos = current_string.find(' ')
            loop += 1
            if pos == -1:
                pos = len(current_string)
            fields.append(current_string[:pos])
            current_string = current_string[pos:].lstrip()

        if current_string.strip():
            errors_found = True
        elif loop == 2:
            internal_error = False
            num_field1_str = fields[0]
            try:
                num_field1 = int(float(num_field1_str))
                err_flag = False
            except:
                err_flag = True

            if err_flag:
                try:
                    num_field2 = int(float(fields[1]))
                    token_day = num_field2
                except:
                    errors_found = True
                    internal_error = True

                month_idx = next((i for i, m in enumerate(months) if fields[0][:3].upper() == m), -1)
                token_month = month_idx + 1 if month_idx != -1 else 0

                if not internal_error:
                    date_type = "MonthDay"
                    num_tokens = 2
                else:
                    errors_found = True
            else:
                try:
                    num_field2 = int(float(fields[1]))
                    token_month = num_field1
                    token_day = num_field2
                    date_type = "MonthDay"
                except:
                    token_day = num_field1
                    month_idx = next((i for i, m in enumerate(months) if fields[1][:3].upper() == m), -1)
                    token_month = month_idx + 1 if month_idx != -1 else 0
                    date_type = "MonthDay"
                    num_tokens = 2

        elif loop == 3:
            if wk_day_in_month:
                try:
                    num_field1 = int(float(fields[0]))
                    token_day = num_field1
                    weekday_idx = next((i for i, w in enumerate(weekdays) if fields[1][:3].upper() == w), -1)
                    token_weekday = weekday_idx + 1 if weekday_idx != -1 else 0

                    if token_weekday == 0:
                        month_idx = next((i for i, m in enumerate(months) if fields[1][:3].upper() == m), -1)
                        token_month = month_idx + 1 if month_idx != -1 else 0
                        weekday_idx = next((i for i, w in enumerate(weekdays) if fields[2][:3].upper() == w), -1)
                        token_weekday = weekday_idx + 1 if weekday_idx != -1 else 0
                        if token_month == 0 or token_weekday == 0:
                            internal_error = True
                    else:
                        month_idx = next((i for i, m in enumerate(months) if fields[2][:3].upper() == m), -1)
                        token_month = month_idx + 1 if month_idx != -1 else 0
                        if token_month == 0:
                            internal_error = True

                    date_type = "NthDayInMonth"
                    num_tokens = 3
                    if token_day < 0 or token_day > 5:
                        internal_error = True

                except:
                    if fields[0] == "LA":
                        date_type = "LastDayInMonth"
                        num_tokens = 3
                        weekday_idx = next((i for i, w in enumerate(weekdays) if fields[1][:3].upper() == w), -1)
                        token_weekday = weekday_idx + 1 if weekday_idx != -1 else 0

                        if token_weekday == 0:
                            month_idx = next((i for i, m in enumerate(months) if fields[1][:3].upper() == m), -1)
                            token_month = month_idx + 1 if month_idx != -1 else 0
                            weekday_idx = next((i for i, w in enumerate(weekdays) if fields[2][:3].upper() == w), -1)
                            token_weekday = weekday_idx + 1 if weekday_idx != -1 else 0
                            if token_month == 0 or token_weekday == 0:
                                internal_error = True
                        else:
                            month_idx = next((i for i, m in enumerate(months) if fields[2][:3].upper() == m), -1)
                            token_month = month_idx + 1 if month_idx != -1 else 0
                            if token_month == 0:
                                internal_error = True
                    else:
                        errors_found = True
            else:
                try:
                    num_field1 = int(float(fields[0]))
                    num_field2 = int(float(fields[1]))
                    num_field3 = int(float(fields[2]))
                    date_type = "MonthDay"

                    if num_field1 > 100:
                        token_year = num_field1
                        token_month = num_field2
                        token_day = num_field3
                    elif num_field3 > 100:
                        token_year = num_field3
                        token_month = num_field1
                        token_day = num_field2
                except:
                    errors_found = True
        else:
            errors_found = True

    if internal_error:
        date_type = None
        errors_found = True

    return (num_tokens, token_day, token_month, token_weekday, date_type, errors_found, token_year)


def validate_month_day(state: Any, string: str, day: int, month: int) -> bool:
    end_month_day = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    internal_error = False
    if month < 1 or month > 12:
        internal_error = True
    if not internal_error:
        if day < 1 or day > end_month_day[month - 1]:
            internal_error = True

    return not internal_error


def process_date_string(state: Any, string: str, p_year_ref: List[Optional[int]] = None) -> tuple:
    from Util import ProcessNumber

    p_month = 0
    p_day = 0
    p_weekday = 0
    date_type = None
    errors_found = False

    fst_num, err_flag = ProcessNumber(string)
    fst_num = int(fst_num)

    if not err_flag:
        if fst_num == 0:
            p_month = 0
            p_day = 0
            date_type = "MonthDay"
        elif fst_num < 0 or fst_num > 366:
            errors_found = True
        else:
            p_month, p_day = inv_ordinal_day(fst_num, 0)
            date_type = "LastDayInMonth"
    else:
        num_tokens, token_day, token_month, token_weekday, dt, errs, token_year = determine_date_tokens(state, string)
        if dt == "MonthDay":
            p_day = token_day
            p_month = token_month
        elif dt in ("NthDayInMonth", "LastDayInMonth"):
            p_day = token_day
            p_month = token_month
            p_weekday = token_weekday

        if p_year_ref is not None:
            p_year_ref[0] = token_year
        date_type = dt
        errors_found = errs

    return (p_month, p_day, p_weekday, date_type, errors_found)


def scan_for_reports(state: Any, report_name: str) -> tuple:
    do_report = False
    report_key = None
    option1 = None
    option2 = None

    if state.dataGeneral.get_report_input:
        state.dataGeneral.get_report_input = False

    report_name_uc = report_name.upper()

    if report_name_uc == "CONSTRUCTIONS":
        do_report = state.dataGeneral.constructions
    elif report_name_uc == "VIEWFACTORINFO":
        do_report = state.dataGeneral.view_factor_info
        option1 = state.dataGeneral.view_rpt_option1
    elif report_name_uc == "VARIABLEDICTIONARY":
        do_report = state.dataGeneral.var_dict
        option1 = state.dataGeneral.var_dict_option1
        option2 = state.dataGeneral.var_dict_option2
    elif report_name_uc == "SURFACES":
        pass
    elif report_name_uc == "ENERGYMANAGEMENTSYSTEM":
        do_report = state.dataGeneral.ems_output

    return (do_report, option1, option2)


def check_created_zone_item_name(state: Any, called_from: str, current_object: str, zone_name: str, 
                                  max_zone_name_length: int, item_name: str, item_names: List[str], 
                                  num_items: int) -> tuple:
    err_flag = False
    item_name_length = len(item_name)
    item_length = len(zone_name) + item_name_length
    result_name = zone_name + ' ' + item_name
    too_long = False

    MAX_NAME_LENGTH = 200
    if item_length > MAX_NAME_LENGTH:
        too_long = True

    found_item = 0
    for i in range(num_items):
        if result_name == item_names[i]:
            found_item = i + 1
            break

    if found_item != 0:
        result_name = "xxxxxxx"
        err_flag = True

    return (result_name, err_flag)


def is_report_period_beginning(state: Any, period_idx: int) -> bool:
    report_start_date = state.dataWeather.report_period_input[period_idx].start_julian_date
    report_start_hour = state.dataWeather.report_period_input[period_idx].start_hour

    if state.dataWeather.report_period_input[period_idx].start_year > 0:
        from Weather import computeJulianDate
        current_date = computeJulianDate(state.dataEnvrn.year, state.dataEnvrn.month, state.dataEnvrn.day_of_month)
    else:
        from Weather import computeJulianDate
        current_date = computeJulianDate(0, state.dataEnvrn.month, state.dataEnvrn.day_of_month)

    return (current_date == report_start_date and state.dataGlobal.hour_of_day == report_start_hour)


def find_report_period_idx(state: Any, report_period_input_data: List[Any], n_report_periods: int) -> List[bool]:
    in_report_period_flags = [False] * (n_report_periods + 1)

    for i in range(1, n_report_periods + 1):
        report_start_date = report_period_input_data[i].start_julian_date
        report_start_hour = report_period_input_data[i].start_hour
        report_end_date = report_period_input_data[i].end_julian_date
        report_end_hour = report_period_input_data[i].end_hour

        if report_period_input_data[i].start_year > 0:
            from Weather import computeJulianDate
            current_date = computeJulianDate(state.dataEnvrn.year, state.dataEnvrn.month, state.dataEnvrn.day_of_month)
        else:
            from Weather import computeJulianDate
            current_date = computeJulianDate(0, state.dataEnvrn.month, state.dataEnvrn.day_of_month)

        if between_date_hours_left_inclusive(current_date, state.dataGlobal.hour_of_day, 
                                              report_start_date, report_start_hour, 
                                              report_end_date, report_end_hour):
            in_report_period_flags[i] = True

    return in_report_period_flags


def rot_azm_diff_deg(azm_a: float, azm_b: float) -> float:
    diff = azm_b - azm_a
    if diff > 180.0:
        diff = 360.0 - diff
    elif diff < -180.0:
        diff = 360.0 + diff
    return abs(diff)
