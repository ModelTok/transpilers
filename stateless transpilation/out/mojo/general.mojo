from memory import memcpy
from memory.unsafe import DTypePointer
from math import exp, abs, floor, fabs
from collections import InlineArray

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state struct with all module contexts
# - Weather::DateType: enum for date type classification
# - Weather::ReportPeriodData: struct with startJulianDate, startHour, endJulianDate, endHour, startYear
# - Weather::computeJulianDate(year, month, day): returns Julian day number
# - DataEnvironment: state.dataEnvrn with CurrentYearIsLeapYear, RunPeriodStartDayOfWeek, Year, Month, DayOfMonth
# - DataHVACGlobals: state.dataHVACGlobal with SysTimeElapsed, TimeStepSys
# - DataGlobal: state.dataGlobal with CurrentTime, TimeStepZone, HourOfDay, ShowDecayCurvesInEIO
# - DataIPShortCuts: state.dataIPShortCut with cAlphaArgs, rNumericArgs, lNumericFieldBlanks, etc.
# - InputProcessor: state.dataInputProcessing.inputProcessor methods
# - UtilityRoutines: ShowSevereError, ShowWarningError, ShowContinueError, FindItemInList, SameString, makeUPPER, ProcessNumber
# - HVACSystemRootFindingAlgorithm: RootAlgo enum with values
# - DataRuntimeLanguage: state.dataRuntimeLang with EMS output flags
# - Util module: string/number processing utilities

alias SOLVEROOT_ERROR_INIT = -2
alias SOLVEROOT_ERROR_ITER = -1

@value
struct RootAlgo:
    var value: Int
    
    @staticmethod
    fn RegulaFalsi() -> Int:
        return 0
    
    @staticmethod
    fn Bisection() -> Int:
        return 1
    
    @staticmethod
    fn RegulaFalsiThenBisection() -> Int:
        return 2
    
    @staticmethod
    fn BisectionThenRegulaFalsi() -> Int:
        return 3
    
    @staticmethod
    fn Alternation() -> Int:
        return 4
    
    @staticmethod
    fn ShortBisectionThenRegulaFalsi() -> Int:
        return 5
    
    @staticmethod
    fn Num() -> Int:
        return 6


@value
struct ReportType:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Int:
        return -1
    
    @staticmethod
    fn DXF() -> Int:
        return 0
    
    @staticmethod
    fn DXFWireFrame() -> Int:
        return 1
    
    @staticmethod
    fn VRML() -> Int:
        return 2
    
    @staticmethod
    fn Num() -> Int:
        return 3


@value
struct AvailRpt:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Int:
        return -1
    
    @staticmethod
    fn None_() -> Int:
        return 0
    
    @staticmethod
    fn NotByUniqueKeyNames() -> Int:
        return 1
    
    @staticmethod
    fn Verbose() -> Int:
        return 2
    
    @staticmethod
    fn Num() -> Int:
        return 3


@value
struct ERLdebugOutputLevel:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Int:
        return -1
    
    @staticmethod
    fn None_() -> Int:
        return 0
    
    @staticmethod
    fn ErrorsOnly() -> Int:
        return 1
    
    @staticmethod
    fn Verbose() -> Int:
        return 2
    
    @staticmethod
    fn Num() -> Int:
        return 3


@value
struct ReportName:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Int:
        return -1
    
    @staticmethod
    fn Constructions() -> Int:
        return 0
    
    @staticmethod
    fn Viewfactorinfo() -> Int:
        return 1
    
    @staticmethod
    fn Variabledictionary() -> Int:
        return 2
    
    @staticmethod
    fn Surfaces() -> Int:
        return 3
    
    @staticmethod
    fn Energymanagementsystem() -> Int:
        return 4
    
    @staticmethod
    fn Num() -> Int:
        return 5


@value
struct RptKey:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Int:
        return -1
    
    @staticmethod
    fn Costinfo() -> Int:
        return 0
    
    @staticmethod
    fn DXF() -> Int:
        return 1
    
    @staticmethod
    fn DXFwireframe() -> Int:
        return 2
    
    @staticmethod
    fn VRML() -> Int:
        return 3
    
    @staticmethod
    fn Vertices() -> Int:
        return 4
    
    @staticmethod
    fn Details() -> Int:
        return 5
    
    @staticmethod
    fn DetailsWithVertices() -> Int:
        return 6
    
    @staticmethod
    fn Lines() -> Int:
        return 7
    
    @staticmethod
    fn Num() -> Int:
        return 8


struct SolveRootStats:
    var algo: Int
    var counts: Int
    var algo_counts: InlineArray[Int, 6]
    var algo_iters: InlineArray[Int, 6]
    
    fn __init__(inout self):
        self.algo = 0
        self.counts = 0
        self.algo_counts = InlineArray[Int, 6](fill=0)
        self.algo_iters = InlineArray[Int, 6](fill=0)


struct InterpCoeffs:
    var x1: Float64
    var x2: Float64
    
    fn __init__(inout self):
        self.x1 = 0.0
        self.x2 = 0.0


struct BilinearInterpCoeffs:
    var denom: Float64
    var x1y1: Float64
    var x1y2: Float64
    var x2y1: Float64
    var x2y2: Float64
    
    fn __init__(inout self):
        self.denom = 0.0
        self.x1y1 = 0.0
        self.x1y2 = 0.0
        self.x2y1 = 0.0
        self.x2y2 = 0.0


struct GeneralData:
    var get_report_input: Bool
    var surf_vert: Bool
    var surf_det: Bool
    var surf_det_w_vert: Bool
    var dxf_report: Bool
    var dxf_wf_report: Bool
    var vrml_report: Bool
    var cost_info: Bool
    var view_factor_info: Bool
    var constructions: Bool
    var materials: Bool
    var line_rpt: Bool
    var var_dict: Bool
    var ems_output: Bool
    var x_next: Float64
    var dxf_option1: String
    var dxf_option2: String
    var dxf_wf_option1: String
    var dxf_wf_option2: String
    var vrml_option1: String
    var vrml_option2: String
    var view_rpt_option1: String
    var line_rpt_option1: String
    var var_dict_option1: String
    var var_dict_option2: String
    
    fn __init__(inout self):
        self.get_report_input = True
        self.surf_vert = False
        self.surf_det = False
        self.surf_det_w_vert = False
        self.dxf_report = False
        self.dxf_wf_report = False
        self.vrml_report = False
        self.cost_info = False
        self.view_factor_info = False
        self.constructions = False
        self.materials = False
        self.line_rpt = False
        self.var_dict = False
        self.ems_output = False
        self.x_next = 0.0
        self.dxf_option1 = ""
        self.dxf_option2 = ""
        self.dxf_wf_option1 = ""
        self.dxf_wf_option2 = ""
        self.vrml_option1 = ""
        self.vrml_option2 = ""
        self.view_rpt_option1 = ""
        self.line_rpt_option1 = ""
        self.var_dict_option1 = ""
        self.var_dict_option2 = ""


@always_inline
fn interp(lower: Float64, upper: Float64, interp_fac: Float64) -> Float64:
    return lower + interp_fac * (upper - lower)


fn get_interp_coeffs(x: Float64, x1: Float64, x2: Float64) -> InterpCoeffs:
    var c = InterpCoeffs()
    c.x1 = (x - x1) / (x2 - x1)
    c.x2 = (x2 - x) / (x2 - x1)
    return c


@always_inline
fn interp2(fx1: Float64, fx2: Float64, c: InterpCoeffs) -> Float64:
    return c.x1 * fx1 + c.x2 * fx2


fn get_bilinear_interp_coeffs(x: Float64, y: Float64, x1: Float64, x2: Float64, y1: Float64, y2: Float64) -> BilinearInterpCoeffs:
    var coeffs = BilinearInterpCoeffs()
    if x1 == x2 and y1 == y2:
        coeffs.denom = 1.0
        coeffs.x1y1 = 1.0
        coeffs.x1y2 = 0.0
        coeffs.x2y1 = 0.0
        coeffs.x2y2 = 0.0
    elif x1 == x2:
        coeffs.denom = (y2 - y1)
        coeffs.x1y1 = (y2 - y)
        coeffs.x1y2 = (y - y1)
        coeffs.x2y1 = 0.0
        coeffs.x2y2 = 0.0
    elif y1 == y2:
        coeffs.denom = (x2 - x1)
        coeffs.x1y1 = (x2 - x)
        coeffs.x2y1 = (x - x1)
        coeffs.x1y2 = 0.0
        coeffs.x2y2 = 0.0
    else:
        coeffs.denom = (x2 - x1) * (y2 - y1)
        coeffs.x1y1 = (x2 - x) * (y2 - y)
        coeffs.x2y1 = (x - x1) * (y2 - y)
        coeffs.x1y2 = (x2 - x) * (y - y1)
        coeffs.x2y2 = (x - x1) * (y - y1)
    return coeffs


@always_inline
fn bilinear_interp(fx1y1: Float64, fx1y2: Float64, fx2y1: Float64, fx2y2: Float64, coeffs: BilinearInterpCoeffs) -> Float64:
    return (coeffs.x1y1 * fx1y1 + coeffs.x2y1 * fx2y1 + coeffs.x1y2 * fx1y2 + coeffs.x2y2 * fx2y2) / coeffs.denom


@always_inline
fn epexp(numerator: Float64, denominator: Float64) -> Float64:
    if denominator == 0.0:
        return 0.0
    return exp(numerator / denominator)


fn solve_root(state: DTypePointer[DType.float64], eps: Float64, max_ite: Int, f: fn(Float64) -> Float64, x_0: Float64, x_1: Float64) -> Tuple[Int, Float64]:
    alias SMALL = 1.0e-10
    var x0 = x_0
    var x1 = x_1
    var xtemp = x0
    var nite = 0
    var alt_ite = 0

    var y0 = f(x0)
    var y1 = f(x1)

    if y0 * y1 > 0:
        return (SOLVEROOT_ERROR_INIT, x0)

    var xres = xtemp

    while True:
        var dy = y0 - y1
        if abs(dy) < SMALL:
            dy = SMALL
        if abs(x1 - x0) < SMALL:
            break

        let root_algo = 0

        if root_algo == 0:
            xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == 1:
            xtemp = (x1 + x0) / 2.0
        elif root_algo == 2:
            if nite > 0:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == 3:
            if nite <= 0:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == 4:
            if alt_ite > 0:
                xtemp = (x1 + x0) / 2.0
                if alt_ite >= 0:
                    alt_ite = 0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        elif root_algo == 5:
            if nite < 3:
                xtemp = (x1 + x0) / 2.0
            else:
                xtemp = (y0 * x1 - y1 * x0) / dy
        else:
            xtemp = (y0 * x1 - y1 * x0) / dy

        let ytemp = f(xtemp)
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


fn solve_root2(state: DTypePointer[DType.float64], eps: Float64, max_iters: Int, f: fn(Float64) -> Float64, x_0: Float64, x_1: Float64, inout stats: SolveRootStats) -> Tuple[Int, Float64]:
    let algo_temp = stats.algo
    stats.algo = 0

    let sol_flag_xres = solve_root(state, eps, max_iters, f, x_0, x_1)
    let sol_flag = sol_flag_xres[0]
    let xres = sol_flag_xres[1]

    stats.algo = algo_temp

    if sol_flag > 0:
        stats.counts += 1
        stats.algo_counts[stats.algo] += 1
        stats.algo_iters[stats.algo] += sol_flag

        alias TRIALS_PER_COUNT = 5

        if stats.counts < TRIALS_PER_COUNT * 6:
            stats.algo += 1
            if stats.algo == 6:
                stats.algo = 0
        elif stats.counts == TRIALS_PER_COUNT * 6:
            var min_iters = max_iters * TRIALS_PER_COUNT
            stats.algo = -1
            for i in range(6):
                if stats.algo_iters[i] < min_iters:
                    stats.algo = i
                    min_iters = stats.algo_iters[i]

    return (sol_flag, xres)


fn moving_avg(inout data_in: DynamicVector[Float64], num_items_in_avg: Int) -> None:
    if num_items_in_avg <= 1:
        return

    let size = data_in.size
    var temp_data = DynamicVector[Float64](capacity=2 * size)
    for _ in range(2 * size):
        temp_data.push_back(0.0)

    for i in range(size):
        temp_data[i] = data_in[i]
        temp_data[size + i] = data_in[i]
        data_in[i] = 0.0

    for i in range(size):
        for j in range(1, num_items_in_avg + 1):
            data_in[i] += temp_data[size - num_items_in_avg + i + j]
        data_in[i] /= Float64(num_items_in_avg)


fn ordinal_day(month: Int, day: Int, leap_year_value: Int) -> Int:
    let end_day_of_month = InlineArray[Int, 12](31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)

    if month == 1:
        return day
    elif month == 2:
        return day + end_day_of_month[0]
    elif month >= 3 and month <= 12:
        return day + end_day_of_month[month - 2] + leap_year_value
    else:
        return 0


fn inv_ordinal_day(number: Int, leap_yr: Int) -> Tuple[Int, Int]:
    let end_of_month = InlineArray[Int, 13](0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)

    if number < 0 or number > 366:
        return (0, 0)

    for w_month in range(1, 13):
        var leap_add_prev = 0
        var leap_add_cur = 0

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
            let p_day = number - (end_of_month[w_month - 1] + leap_add_cur)
            return (w_month, p_day)

    return (0, 0)


fn between_date_hours_left_inclusive(test_date: Int, test_hour: Int, start_date: Int, start_hour: Int, end_date: Int, end_hour: Int) -> Bool:
    let test_ratio_of_day = Float64(test_hour) / 24.0
    let start_ratio_of_day = Float64(start_hour) / 24.0
    let end_ratio_of_day = Float64(end_hour) / 24.0

    if Float64(start_date) + start_ratio_of_day <= Float64(end_date) + end_ratio_of_day:
        return ((Float64(start_date) + start_ratio_of_day <= Float64(test_date) + test_ratio_of_day) and 
                (Float64(test_date) + test_ratio_of_day <= Float64(end_date) + end_ratio_of_day))
    else:
        return ((Float64(end_date) + end_ratio_of_day <= Float64(test_date) + test_ratio_of_day) and 
                (Float64(test_date) + test_ratio_of_day <= Float64(start_date) + start_ratio_of_day))


fn between_dates(test_date: Int, start_date: Int, end_date: Int) -> Bool:
    var between_dates_result = False

    if start_date <= end_date:
        if test_date >= start_date and test_date <= end_date:
            between_dates_result = True
    else:
        if test_date <= end_date or test_date >= start_date:
            between_dates_result = True

    return between_dates_result


fn create_sys_time_interval_string(state: DTypePointer[DType.float64]) -> String:
    let sys_time_elapsed = 0.0
    let time_step_sys = 0.0
    alias FRAC_TO_MIN = 60.0
    alias TOLERANCE_TIME = 0.0001

    var actual_time_s: Float64
    var actual_time_e: Float64

    if sys_time_elapsed == 0.0:
        actual_time_e = 0.0
        actual_time_s = actual_time_e - 0.0
    elif abs(0.0 - sys_time_elapsed) <= TOLERANCE_TIME:
        actual_time_e = 0.0
        actual_time_s = actual_time_e - time_step_sys
    else:
        actual_time_s = 0.0 - 0.0 + sys_time_elapsed
        actual_time_e = actual_time_s + time_step_sys

    var actual_time_hr_s = Int(actual_time_s)
    var actual_time_min_s = Int((actual_time_s - Float64(actual_time_hr_s)) * FRAC_TO_MIN + 0.5)

    if actual_time_min_s == 60:
        actual_time_hr_s += 1
        actual_time_min_s = 0

    var time_stmp_s = String("")
    let minutes = ((actual_time_e - Float64(Int(actual_time_e))) * FRAC_TO_MIN)

    var time_stmp_e = String("")

    return time_stmp_s + " - " + time_stmp_e


fn nth_day_of_week_of_month(state: DTypePointer[DType.float64], day_of_week: Int, nth_time: Int, month_number: Int) -> Int:
    let first_day_of_month = ordinal_day(month_number, 1, 0)
    let day_of_week_for_first_day = (0 + first_day_of_month - 1) % 7
    if day_of_week >= day_of_week_for_first_day:
        return first_day_of_month + (day_of_week - day_of_week_for_first_day) + 7 * (nth_time - 1)
    else:
        return first_day_of_month + ((day_of_week + 7) - day_of_week_for_first_day) + 7 * (nth_time - 1)


fn safe_divide(a: Float64, b: Float64) -> Float64:
    alias SMALL = 1.0e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        return a / (SMALL if b >= 0 else -SMALL)


fn iterate(tol: Float64, x0: Float64, y0: Float64, inout x1_ref: Float64, inout y1_ref: Float64, iter_num: Int) -> Tuple[Float64, Int]:
    alias SMALL = 1.0e-9
    alias PERTURB = 0.1

    var result_x: Float64
    var cnvg = 0

    if iter_num != 1:
        if abs(x0 - x1_ref) < tol or y0 == 0.0:
            x1_ref = x0
            y1_ref = y0
            return (x0, 1)

    cnvg = 0
    if iter_num == 1:
        if abs(x0) > SMALL:
            result_x = x0 * (1.0 + PERTURB)
        else:
            result_x = PERTURB
    else:
        var dy = y0 - y1_ref
        if abs(dy) < SMALL:
            dy = SMALL
        result_x = (y0 * x1_ref - y1_ref * x0) / dy

    x1_ref = x0
    y1_ref = y0

    return (result_x, cnvg)


fn find_number_in_list(which_number: Int, list_of_items: DynamicVector[Int], num_items: Int) -> Int:
    for count in range(num_items):
        if which_number == list_of_items[count]:
            return count + 1
    return 0


fn decode_mon_day_hr_min(item: Int) -> Tuple[Int, Int, Int, Int]:
    alias DEC_MON = 100 * 100 * 100
    alias DEC_DAY = 100 * 100
    alias DEC_HR = 100

    var tmp_item = item
    let month = tmp_item // DEC_MON
    tmp_item = tmp_item - month * DEC_MON
    let day = tmp_item // DEC_DAY
    tmp_item -= day * DEC_DAY
    let hour = tmp_item // DEC_HR
    let minute = tmp_item % DEC_HR

    return (month, day, hour, minute)


fn encode_mon_day_hr_min(month: Int, day: Int, hour: Int, minute: Int) -> Int:
    return ((month * 100 + day) * 100 + hour) * 100 + minute


fn create_time_string(time: Float64) -> String:
    let parse_result = parse_time(time)
    let hours = parse_result[0]
    let minutes = parse_result[1]
    let seconds = parse_result[2]
    return String("")


fn parse_time(time: Float64) -> Tuple[Int, Int, Float64]:
    alias MIN_TO_SEC = 60
    alias HOUR_TO_SEC = 60 * 60

    let hours = Int(time) // HOUR_TO_SEC
    var remainder = time - Float64(hours) * Float64(HOUR_TO_SEC)
    let minutes = Int(remainder) // MIN_TO_SEC
    remainder -= Float64(minutes) * Float64(MIN_TO_SEC)
    let seconds = remainder

    return (hours, minutes, seconds)


fn ordinal_day_overload(month: Int, day: Int, leap_year_value: Int) -> Int:
    return ordinal_day(month, day, leap_year_value)


fn between_dates_overload(test_date: Int, start_date: Int, end_date: Int) -> Bool:
    return between_dates(test_date, start_date, end_date)


fn between_date_hours_overload(test_date: Int, test_hour: Int, start_date: Int, start_hour: Int, end_date: Int, end_hour: Int) -> Bool:
    return between_date_hours_left_inclusive(test_date, test_hour, start_date, start_hour, end_date, end_hour)


fn rot_azm_diff_deg(azm_a: Float64, azm_b: Float64) -> Float64:
    var diff = azm_b - azm_a
    if diff > 180.0:
        diff = 360.0 - diff
    elif diff < -180.0:
        diff = 360.0 + diff
    return abs(diff)
