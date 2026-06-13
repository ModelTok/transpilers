from memory import memset_zero
from memory.buffer import Buffer

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object aggregating dataGlobal, dataSched, dataEnvrn, dataWeather, dataInputProcessing, files, etc.
# UtilityRoutines: ShowError*, ShowWarning*, ShowMessage*, ShowContinue*, SetupEMSActuator, SetupOutputVariable
# General: ProcessDateString, OrdinalDay, InvOrdinalDay, nthDayOfWeekOfMonth
# FileSystem: readFile, readJSON, getFileType, is_flat_file_type, is_all_json_type
# InputProcessing.CsvParser: CsvParser.decode
# StringUtilities: makeUPPER, SameString
# DataStringGlobals: CharComma, CharSemicolon, CharSpace, CharTab
# DataSystemVariables: CheckForActualFilePath
# WeatherManager.DateType: NthDayInMonth, LastDayInMonth
# OutputProcessor: TimeStepType, StoreType, SetupOutputVariable
# Constant: iHoursInDay, iMinutesInDay, iMinutesInHour, iMinutesInDay, rMinutesInHour, rHoursInDay
# ErrorObjectHeader, Clusive (In/Ex), BooleanSwitch

alias Real64 = Float64
alias Int32 = Int32

# Constants
alias SCHED_NUM_INVALID = -1
alias SCHED_NUM_ALWAYS_OFF = 0
alias SCHED_NUM_ALWAYS_ON = 1

@value
struct DayType:
    alias INVALID = -1
    alias UNUSED = 0
    alias SUNDAY = 1
    alias MONDAY = 2
    alias TUESDAY = 3
    alias WEDNESDAY = 4
    alias THURSDAY = 5
    alias FRIDAY = 6
    alias SATURDAY = 7
    alias HOLIDAY = 8
    alias SUMMER_DESIGN_DAY = 9
    alias WINTER_DESIGN_DAY = 10
    alias CUSTOM_DAY1 = 11
    alias CUSTOM_DAY2 = 12
    alias NUM = 13

alias IDAY_TYPE_SUN = DayType.SUNDAY
alias IDAY_TYPE_MON = DayType.MONDAY
alias IDAY_TYPE_TUE = DayType.TUESDAY
alias IDAY_TYPE_WED = DayType.WEDNESDAY
alias IDAY_TYPE_THU = DayType.THURSDAY
alias IDAY_TYPE_FRI = DayType.FRIDAY
alias IDAY_TYPE_SAT = DayType.SATURDAY
alias IDAY_TYPE_HOL = DayType.HOLIDAY
alias IDAY_TYPE_SUM_DES = DayType.SUMMER_DESIGN_DAY
alias IDAY_TYPE_WIN_DES = DayType.WINTER_DESIGN_DAY
alias IDAY_TYPE_CUS1 = DayType.CUSTOM_DAY1
alias IDAY_TYPE_CUS2 = DayType.CUSTOM_DAY2

@value
struct DayTypeGroup:
    alias INVALID = -1
    alias WEEKDAY = 0
    alias WEEKEND_HOLIDAY = 1
    alias SUMMER_DESIGN_DAY = 2
    alias WINTER_DESIGN_DAY = 3
    alias NUM = 4

@value
struct SchedType:
    alias INVALID = -1
    alias YEAR = 0
    alias COMPACT = 1
    alias FILE = 2
    alias CONSTANT = 3
    alias EXTERNAL = 4
    alias NUM = 5

@value
struct ReportLevel:
    alias INVALID = -1
    alias HOURLY = 0
    alias TIMESTEP = 1
    alias NUM = 2

@value
struct Interpolation:
    alias INVALID = -1
    alias NO = 0
    alias AVERAGE = 1
    alias LINEAR = 2
    alias NUM = 3

@value
struct LimitUnits:
    alias INVALID = -1
    alias DIMENSIONLESS = 0
    alias TEMPERATURE = 1
    alias DELTA_TEMPERATURE = 2
    alias PRECIPITATION_RATE = 3
    alias ANGLE = 4
    alias CONVECTION_COEFFICIENT = 5
    alias ACTIVITY_LEVEL = 6
    alias VELOCITY = 7
    alias CAPACITY = 8
    alias POWER = 9
    alias AVAILABILITY = 10
    alias PERCENT = 11
    alias CONTROL = 12
    alias MODE = 13
    alias NUM = 14

struct ScheduleType:
    var name: String
    var num: Int32
    var is_limited: Bool
    var min_val: Real64
    var max_val: Real64
    var is_real: Bool
    var limit_units: Int32

    fn __init__(inout self):
        self.name = ""
        self.num = SCHED_NUM_INVALID
        self.is_limited = False
        self.min_val = 0.0
        self.max_val = 0.0
        self.is_real = True
        self.limit_units = LimitUnits.INVALID

struct ScheduleBase:
    var name: String
    var num: Int32
    var is_used: Bool
    var max_val: Real64
    var min_val: Real64
    var is_min_max_set: Bool

    fn __init__(inout self):
        self.name = ""
        self.num = SCHED_NUM_INVALID
        self.is_used = False
        self.max_val = 0.0
        self.min_val = 0.0
        self.is_min_max_set = False

    fn get_min_val(inout self, state: Pointer[EnergyPlusData]) -> Real64:
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return self.min_val

    fn get_max_val(inout self, state: Pointer[EnergyPlusData]) -> Real64:
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return self.max_val

    fn check_min_val(inout self, state: Pointer[EnergyPlusData], clu: Int32, min_val: Real64) -> Bool:
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        if clu == 0:
            return abs(min_val - self.min_val) < 1e-6
        else:
            return self.min_val > min_val

    fn check_max_val(inout self, state: Pointer[EnergyPlusData], clu_max: Int32, max_val: Real64) -> Bool:
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        if clu_max == 1:
            return self.max_val < max_val
        else:
            return abs(self.max_val - max_val) < 1e-6

    fn check_min_max_vals(inout self, state: Pointer[EnergyPlusData], clu_min: Int32, min_val: Real64, clu_max: Int32, max_val: Real64) -> Bool:
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        var min_ok: Bool = False
        var max_ok: Bool = False
        if clu_min == 1:
            min_ok = self.min_val > min_val
        else:
            min_ok = abs(min_val - self.min_val) < 1e-6
        if clu_max == 1:
            max_ok = self.max_val < max_val
        else:
            max_ok = abs(self.max_val - max_val) < 1e-6
        return min_ok and max_ok

    fn set_min_max_vals(inout self, state: Pointer[EnergyPlusData]):
        pass

struct DayOrYearSchedule(ScheduleBase):
    fn get_day_vals(inout self, state: Pointer[EnergyPlusData], j_day: Int32 = -1, day_of_week: Int32 = -1) -> List[Real64]:
        var empty_list: List[Real64] = List[Real64]()
        return empty_list

struct DaySchedule(DayOrYearSchedule):
    var sched_type_num: Int32
    var interpolation: Int32
    var ts_vals: List[Real64]
    var sum_ts_vals: Real64

    fn __init__(inout self):
        super().__init__()
        self.sched_type_num = SCHED_NUM_INVALID
        self.interpolation = Interpolation.NO
        self.ts_vals = List[Real64]()
        self.sum_ts_vals = 0.0

    fn check_vals_for_limit_violations(inout self, state: Pointer[EnergyPlusData]) -> Bool:
        if self.sched_type_num == SCHED_NUM_INVALID:
            return False
        var sched_type: Pointer[ScheduleType] = UnsafePointer.address_of(state[].dataSched.schedule_types[self.sched_type_num])
        if not sched_type[].is_limited:
            return False
        var hours_in_day: Int32 = 24
        for i in range(hours_in_day * state[].dataGlobal.TimeStepsInHour):
            if self.ts_vals[i] < sched_type[].min_val or self.ts_vals[i] > sched_type[].max_val:
                return True
        return False

    fn check_vals_for_bad_integers(inout self, state: Pointer[EnergyPlusData]) -> Bool:
        if self.sched_type_num == SCHED_NUM_INVALID:
            return False
        var sched_type: Pointer[ScheduleType] = UnsafePointer.address_of(state[].dataSched.schedule_types[self.sched_type_num])
        if sched_type[].is_real:
            return False
        var hours_in_day: Int32 = 24
        for i in range(hours_in_day * state[].dataGlobal.TimeStepsInHour):
            if self.ts_vals[i] != Int32(self.ts_vals[i]):
                return True
        return False

    fn populate_from_minute_vals(inout self, state: Pointer[EnergyPlusData], minute_vals: List[Real64]):
        var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
        var hours_in_day: Int32 = 24
        var minutes_in_hour: Int32 = 60
        var minutes_in_timestep: Int32 = s_glob[].MinutesInTimeStep
        if self.interpolation == Interpolation.AVERAGE:
            for hr in range(hours_in_day):
                var beg_min: Int32 = 0
                var end_min: Int32 = minutes_in_timestep - 1
                for ts in range(s_glob[].TimeStepsInHour):
                    var accum: Real64 = 0.0
                    for i_min in range(beg_min, end_min + 1):
                        accum += minute_vals[hr * minutes_in_hour + i_min]
                    self.ts_vals[hr * s_glob[].TimeStepsInHour + ts] = accum / Real64(minutes_in_timestep)
                    self.sum_ts_vals += self.ts_vals[hr * s_glob[].TimeStepsInHour + ts]
                    beg_min = end_min + 1
                    end_min += minutes_in_timestep
        else:
            for hr in range(hours_in_day):
                var end_minute: Int32 = minutes_in_timestep - 1
                for ts in range(s_glob[].TimeStepsInHour):
                    self.ts_vals[hr * s_glob[].TimeStepsInHour + ts] = minute_vals[hr * minutes_in_hour + end_minute]
                    self.sum_ts_vals += self.ts_vals[hr * s_glob[].TimeStepsInHour + ts]
                    end_minute += minutes_in_timestep

    fn get_day_vals(inout self, state: Pointer[EnergyPlusData], j_day: Int32 = -1, day_of_week: Int32 = -1) -> List[Real64]:
        return self.ts_vals

    fn set_min_max_vals(inout self, state: Pointer[EnergyPlusData]):
        debug_assert(not self.is_min_max_set)
        var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
        var hours_in_day: Int32 = 24
        self.min_val = self.max_val = self.ts_vals[0]
        for i in range(hours_in_day * s_glob[].TimeStepsInHour):
            var value: Real64 = self.ts_vals[i]
            if value < self.min_val:
                self.min_val = value
            elif value > self.max_val:
                self.max_val = value
        self.is_min_max_set = True

struct WeekSchedule(ScheduleBase):
    var day_scheds: InlineArray[Pointer[DaySchedule], 13]

    fn __init__(inout self):
        super().__init__()
        for i in range(13):
            self.day_scheds[i] = Pointer[DaySchedule]()

    fn set_min_max_vals(inout self, state: Pointer[EnergyPlusData]):
        debug_assert(not self.is_min_max_set)
        var day_sched1: Pointer[DaySchedule] = self.day_scheds[1]
        if day_sched1 == Pointer[DaySchedule]():
            return
        if not day_sched1[].is_min_max_set:
            day_sched1[].set_min_max_vals(state)
        self.min_val = day_sched1[].min_val
        self.max_val = day_sched1[].max_val
        var day_sched_prev: Pointer[DaySchedule] = day_sched1
        for i_day in range(2, DayType.NUM):
            var day_sched: Pointer[DaySchedule] = self.day_scheds[i_day]
            if day_sched == day_sched_prev:
                continue
            if not day_sched[].is_min_max_set:
                day_sched[].set_min_max_vals(state)
            if day_sched[].min_val < self.min_val:
                self.min_val = day_sched[].min_val
            if day_sched[].max_val > self.max_val:
                self.max_val = day_sched[].max_val
            day_sched_prev = day_sched
        self.is_min_max_set = True

struct Schedule(DayOrYearSchedule):
    var type: Int32
    var sched_type_num: Int32
    var ems_actuated_on: Bool
    var ems_val: Real64
    var current_val: Real64

    fn __init__(inout self):
        super().__init__()
        self.type = SchedType.CONSTANT
        self.sched_type_num = SCHED_NUM_INVALID
        self.ems_actuated_on = False
        self.ems_val = 0.0
        self.current_val = 0.0

    fn get_current_val(self) -> Real64:
        if self.ems_actuated_on:
            return self.ems_val
        else:
            return self.current_val

    fn get_hr_ts_val(inout self, state: Pointer[EnergyPlusData], hr: Int32, ts: Int32 = -1) -> Real64:
        return 0.0

    fn has_val(inout self, state: Pointer[EnergyPlusData], val: Real64) -> Bool:
        return False

    fn has_fractional_val(inout self, state: Pointer[EnergyPlusData]) -> Bool:
        return False

    fn get_min_max_vals_by_day_type(inout self, state: Pointer[EnergyPlusData], days: Int32) -> Tuple[Real64, Real64]:
        return (0.0, 0.0)

    fn get_annual_hours_full_load(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        return 0.0

    fn get_annual_hours_greater_than_1_percent(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        return 0.0

    fn get_val_and_count_on_day(inout self, state: Pointer[EnergyPlusData], is_summer: Bool, day_of_week: Int32, hour_of_day: Int32) -> Tuple[Real64, Int32, String]:
        return (0.0, 0, "")

    fn get_average_weekly_hours_full_load(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        var weeks_in_year: Real64 = 366.0 / 7.0 if is_leap_year else 365.0 / 7.0
        return self.get_annual_hours_full_load(state, start_day_of_week, is_leap_year) / weeks_in_year

struct ScheduleConstant(Schedule):
    var ts_vals: List[Real64]

    fn __init__(inout self):
        super().__init__()
        self.type = SchedType.CONSTANT
        self.ts_vals = List[Real64]()

    fn get_hr_ts_val(inout self, state: Pointer[EnergyPlusData], hr: Int32, ts: Int32 = -1) -> Real64:
        if len(self.ts_vals) > 0:
            return self.ts_vals[0]
        return 0.0

    fn get_day_vals(inout self, state: Pointer[EnergyPlusData], j_day: Int32 = -1, day_of_week: Int32 = -1) -> List[Real64]:
        return self.ts_vals

    fn has_val(inout self, state: Pointer[EnergyPlusData], val: Real64) -> Bool:
        return val == self.current_val

    fn has_fractional_val(inout self, state: Pointer[EnergyPlusData]) -> Bool:
        return (self.current_val > 0.0) and (self.current_val < 1.0)

    fn set_min_max_vals(inout self, state: Pointer[EnergyPlusData]):
        debug_assert(not self.is_min_max_set)
        self.min_val = self.max_val = self.current_val
        self.is_min_max_set = True

    fn get_min_max_vals_by_day_type(inout self, state: Pointer[EnergyPlusData], days: Int32) -> Tuple[Real64, Real64]:
        return (self.current_val, self.current_val)

    fn get_annual_hours_full_load(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        if start_day_of_week < IDAY_TYPE_SUN or start_day_of_week > IDAY_TYPE_SAT:
            return 0.0
        var days_in_year: Int32 = 366 if is_leap_year else 365
        return Real64(days_in_year * 24) * self.current_val

    fn get_annual_hours_greater_than_1_percent(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        var days_in_year: Int32 = 366 if is_leap_year else 365
        if start_day_of_week < IDAY_TYPE_SUN or start_day_of_week > IDAY_TYPE_SAT:
            return 0.0
        return Real64(24 * days_in_year) if (self.current_val > 0.0) else 0.0

    fn get_val_and_count_on_day(inout self, state: Pointer[EnergyPlusData], is_summer: Bool, day_of_week: Int32, hour_of_day: Int32) -> Tuple[Real64, Int32, String]:
        var month: Int32 = 7 if is_summer else 1
        if state[].dataEnvrn.Latitude <= 0.0:
            month = 1 if is_summer else 7
        var month_name: String = "January" if month == 1 else "July"
        var days_in_year: Int32 = 366 if state[].dataEnvrn.CurrentYearIsLeapYear else 365
        return (self.current_val, days_in_year, month_name)

struct ScheduleDetailed(Schedule):
    var week_scheds: InlineArray[Pointer[WeekSchedule], 367]
    var max_min_by_day_type_set: InlineArray[Bool, 4]
    var min_by_day_type: InlineArray[Real64, 4]
    var max_by_day_type: InlineArray[Real64, 4]
    var use_daylight_saving: Bool

    fn __init__(inout self):
        super().__init__()
        self.type = SchedType.YEAR
        for i in range(367):
            self.week_scheds[i] = Pointer[WeekSchedule]()
        for i in range(4):
            self.max_min_by_day_type_set[i] = False
            self.min_by_day_type[i] = 0.0
            self.max_by_day_type[i] = 0.0
        self.use_daylight_saving = True

    fn get_day_vals(inout self, state: Pointer[EnergyPlusData], j_day: Int32 = -1, day_of_week: Int32 = -1) -> List[Real64]:
        var s_env: Pointer[EnvironData] = UnsafePointer.address_of(state[].dataEnvrn)
        var j_day_val: Int32 = s_env[].DayOfYear_Schedule if j_day == -1 else j_day
        var week_sched: Pointer[WeekSchedule] = self.week_scheds[j_day_val]
        var day_sched: Pointer[DaySchedule]
        if day_of_week == -1:
            var day_of_week_val: Int32 = s_env[].HolidayIndex if s_env[].HolidayIndex > 0 else s_env[].DayOfWeek
            day_sched = week_sched[].day_scheds[day_of_week_val]
        elif day_of_week <= 7 and s_env[].HolidayIndex > 0:
            day_sched = week_sched[].day_scheds[s_env[].HolidayIndex]
        else:
            day_sched = week_sched[].day_scheds[day_of_week]
        return day_sched[].get_day_vals(state)

    fn has_val(inout self, state: Pointer[EnergyPlusData], val: Real64) -> Bool:
        return False

    fn has_fractional_val(inout self, state: Pointer[EnergyPlusData]) -> Bool:
        return False

    fn set_min_max_vals(inout self, state: Pointer[EnergyPlusData]):
        debug_assert(not self.is_min_max_set)
        var week_sched1: Pointer[WeekSchedule] = self.week_scheds[1]
        if week_sched1 == Pointer[WeekSchedule]():
            return
        if not week_sched1[].is_min_max_set:
            week_sched1[].set_min_max_vals(state)
        self.min_val = week_sched1[].min_val
        self.max_val = week_sched1[].max_val
        var week_sched_prev: Pointer[WeekSchedule] = week_sched1
        for i_week in range(2, 367):
            var week_sched: Pointer[WeekSchedule] = self.week_scheds[i_week]
            if i_week == 366 and week_sched == Pointer[WeekSchedule]():
                continue
            if week_sched == week_sched_prev:
                continue
            if not week_sched[].is_min_max_set:
                week_sched[].set_min_max_vals(state)
            if week_sched[].min_val < self.min_val:
                self.min_val = week_sched[].min_val
            if week_sched[].max_val > self.max_val:
                self.max_val = week_sched[].max_val
            week_sched_prev = week_sched
        self.is_min_max_set = True

    fn get_hr_ts_val(inout self, state: Pointer[EnergyPlusData], hr: Int32, ts: Int32 = -1) -> Real64:
        var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
        if self.ems_actuated_on:
            return self.ems_val
        if hr > 24:
            return 0.0
        var this_hr: Int32 = hr + state[].dataEnvrn.DSTIndicator * (1 if self.use_daylight_saving else 0)
        var this_day_of_year: Int32 = state[].dataEnvrn.DayOfYear_Schedule
        var this_day_of_week: Int32 = state[].dataEnvrn.DayOfWeek
        var this_holiday_num: Int32 = state[].dataEnvrn.HolidayIndex
        if this_hr > 24:
            this_day_of_year += 1
            this_hr -= 24
            this_day_of_week = state[].dataEnvrn.DayOfWeekTomorrow
            this_holiday_num = state[].dataEnvrn.HolidayIndexTomorrow
        if this_day_of_year == 367:
            this_day_of_year = 1
        var week_sched: Pointer[WeekSchedule] = self.week_scheds[this_day_of_year]
        var day_sched: Pointer[DaySchedule]
        if this_holiday_num > 0:
            day_sched = week_sched[].day_scheds[this_holiday_num]
        else:
            day_sched = week_sched[].day_scheds[this_day_of_week]
        if ts <= 0:
            ts = s_glob[].TimeStepsInHour
        return day_sched[].ts_vals[(this_hr - 1) * s_glob[].TimeStepsInHour + (ts - 1)]

    fn get_min_max_vals_by_day_type(inout self, state: Pointer[EnergyPlusData], days: Int32) -> Tuple[Real64, Real64]:
        return (0.0, 0.0)

    fn get_annual_hours_full_load(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
        var days_in_year: Int32 = 366 if is_leap_year else 365
        var day_t: Int32 = start_day_of_week
        var total_hours: Real64 = 0.0
        if day_t < IDAY_TYPE_SUN or day_t > IDAY_TYPE_SAT:
            return total_hours
        for i_day in range(1, days_in_year + 1):
            var week_sched: Pointer[WeekSchedule] = self.week_scheds[i_day]
            var day_sched: Pointer[DaySchedule] = week_sched[].day_scheds[day_t]
            total_hours += day_sched[].sum_ts_vals / Real64(s_glob[].TimeStepsInHour)
            day_t += 1
            if day_t > IDAY_TYPE_SAT:
                day_t = IDAY_TYPE_SUN
        return total_hours

    fn get_annual_hours_greater_than_1_percent(inout self, state: Pointer[EnergyPlusData], start_day_of_week: Int32, is_leap_year: Bool) -> Real64:
        var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
        var days_in_year: Int32 = 366 if is_leap_year else 365
        var day_t: Int32 = start_day_of_week
        var total_hours: Real64 = 0.0
        if day_t < IDAY_TYPE_SUN or day_t > IDAY_TYPE_SAT:
            return total_hours
        for i_day in range(1, days_in_year + 1):
            var week_sched: Pointer[WeekSchedule] = self.week_scheds[i_day]
            var day_sched: Pointer[DaySchedule] = week_sched[].day_scheds[day_t]
            for i in range(24 * s_glob[].TimeStepsInHour):
                if day_sched[].ts_vals[i] > 0.0:
                    total_hours += s_glob[].TimeStepZone
            day_t += 1
            if day_t > IDAY_TYPE_SAT:
                day_t = IDAY_TYPE_SUN
        return total_hours

    fn get_val_and_count_on_day(inout self, state: Pointer[EnergyPlusData], is_summer: Bool, day_of_week: Int32, hour_of_day: Int32) -> Tuple[Real64, Int32, String]:
        var month: Int32 = 7 if is_summer else 1
        if state[].dataEnvrn.Latitude <= 0.0:
            month = 1 if is_summer else 7
        var month_name: String = "January" if month == 1 else "July"
        var days_in_year: Int32 = 366 if state[].dataEnvrn.CurrentYearIsLeapYear else 365
        return (0.0, days_in_year, month_name)

struct ScheduleManagerData:
    var check_schedule_val_min_max_run_once_only: Bool
    var do_schedule_reporting_setup: Bool
    var unique_processed_external_files: Dict[String, Int32]
    var schedule_input_processed: Bool
    var schedule_file_shading_processed: Bool
    var schedule_types: List[ScheduleType]
    var schedules: List[Pointer[Schedule]]
    var day_schedules: List[Pointer[DaySchedule]]
    var week_schedules: List[Pointer[WeekSchedule]]
    var schedule_type_map: Dict[String, Int32]
    var schedule_map: Dict[String, Int32]
    var day_schedule_map: Dict[String, Int32]
    var week_schedule_map: Dict[String, Int32]

    fn __init__(inout self):
        self.check_schedule_val_min_max_run_once_only = True
        self.do_schedule_reporting_setup = True
        self.unique_processed_external_files = Dict[String, Int32]()
        self.schedule_input_processed = False
        self.schedule_file_shading_processed = False
        self.schedule_types = List[ScheduleType]()
        self.schedules = List[Pointer[Schedule]]()
        self.day_schedules = List[Pointer[DaySchedule]]()
        self.week_schedules = List[Pointer[WeekSchedule]]()
        self.schedule_type_map = Dict[String, Int32]()
        self.schedule_map = Dict[String, Int32]()
        self.day_schedule_map = Dict[String, Int32]()
        self.week_schedule_map = Dict[String, Int32]()

fn get_schedule_type_num(state: Pointer[EnergyPlusData], name: String) -> Int32:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    for i in range(len(s_sched[].schedule_types)):
        if s_sched[].schedule_types[i].name == name:
            return Int32(i)
    return SCHED_NUM_INVALID

fn add_schedule_constant(state: Pointer[EnergyPlusData], name: String, value: Real64 = 0.0) -> Pointer[ScheduleConstant]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
    var sched: Pointer[ScheduleConstant] = Pointer[ScheduleConstant].alloc(1)
    sched[].name = name
    sched[].num = Int32(len(s_sched[].schedules))
    sched[].type = SchedType.CONSTANT
    sched[].current_val = value
    sched[].ts_vals = List[Real64]()
    for i in range(24 * max(1, s_glob[].TimeStepsInHour)):
        sched[].ts_vals.append(value)
    s_sched[].schedules.append(sched)
    var upper_name: String = name
    s_sched[].schedule_map[upper_name] = sched[].num
    return sched

fn add_schedule_detailed(state: Pointer[EnergyPlusData], name: String) -> Pointer[ScheduleDetailed]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var sched: Pointer[ScheduleDetailed] = Pointer[ScheduleDetailed].alloc(1)
    sched[].name = name
    sched[].num = Int32(len(s_sched[].schedules))
    sched[].type = SchedType.YEAR
    s_sched[].schedules.append(sched)
    var upper_name: String = name
    s_sched[].schedule_map[upper_name] = sched[].num
    return sched

fn add_day_schedule(state: Pointer[EnergyPlusData], name: String) -> Pointer[DaySchedule]:
    var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var day_sched: Pointer[DaySchedule] = Pointer[DaySchedule].alloc(1)
    day_sched[].name = name
    day_sched[].num = Int32(len(s_sched[].day_schedules))
    day_sched[].ts_vals = List[Real64]()
    for i in range(24 * max(1, s_glob[].TimeStepsInHour)):
        day_sched[].ts_vals.append(0.0)
    s_sched[].day_schedules.append(day_sched)
    var upper_name: String = name
    s_sched[].day_schedule_map[upper_name] = day_sched[].num
    return day_sched

fn add_week_schedule(state: Pointer[EnergyPlusData], name: String) -> Pointer[WeekSchedule]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var week_sched: Pointer[WeekSchedule] = Pointer[WeekSchedule].alloc(1)
    week_sched[].name = name
    week_sched[].num = Int32(len(s_sched[].week_schedules))
    for i_day_type in range(1, DayType.NUM):
        week_sched[].day_scheds[i_day_type] = s_sched[].day_schedules[SCHED_NUM_ALWAYS_OFF]
    s_sched[].week_schedules.append(week_sched)
    var upper_name: String = name
    s_sched[].week_schedule_map[upper_name] = week_sched[].num
    return week_sched

fn init_constant_schedule_data(state: Pointer[EnergyPlusData]):
    var sched_off: Pointer[ScheduleConstant] = add_schedule_constant(state, "Constant-0.0", 0.0)
    debug_assert(sched_off[].num == SCHED_NUM_ALWAYS_OFF)
    sched_off[].is_used = True
    var sched_on: Pointer[ScheduleConstant] = add_schedule_constant(state, "Constant-1.0", 1.0)
    debug_assert(sched_on[].num == SCHED_NUM_ALWAYS_ON)
    sched_on[].is_used = True
    var missing_day_schedule: Pointer[DaySchedule] = add_day_schedule(state, "MissingDaySchedule-0.0")
    debug_assert(missing_day_schedule[].num == SCHED_NUM_ALWAYS_OFF)
    missing_day_schedule[].is_used = True

fn process_schedule_input(state: Pointer[EnergyPlusData]):
    pass

fn report_schedule_type_limits(state: Pointer[EnergyPlusData]):
    pass

fn report_schedule_details(state: Pointer[EnergyPlusData], level_of_detail: Int32):
    pass

fn report_schedule_vals(state: Pointer[EnergyPlusData]):
    pass

fn report_orphan_schedules(state: Pointer[EnergyPlusData]):
    pass

fn update_schedule_vals(state: Pointer[EnergyPlusData]):
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
    for sched in s_sched[].schedules:
        if sched[].ems_actuated_on:
            sched[].current_val = sched[].ems_val
        else:
            sched[].current_val = sched[].get_hr_ts_val(state, s_glob[].HourOfDay, s_glob[].TimeStep)

fn get_current_schedule_value(state: Pointer[EnergyPlusData], sched_num: Int32) -> Real64:
    return state[].dataSched.schedules[sched_num][].get_current_val()

fn get_schedule_num(state: Pointer[EnergyPlusData], name: String) -> Int32:
    var sched: Pointer[Schedule] = get_schedule(state, name)
    if sched == Pointer[Schedule]():
        return -1
    return sched[].num

fn get_schedule(state: Pointer[EnergyPlusData], name: String) -> Pointer[Schedule]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var found: Optional[Int32] = s_sched[].schedule_map.get(name.upper())
    if not found:
        return Pointer[Schedule]()
    var sched: Pointer[Schedule] = s_sched[].schedules[found.value()]
    if not sched[].is_used:
        sched[].is_used = True
        if sched[].type != SchedType.CONSTANT:
            var sched_detailed: Pointer[ScheduleDetailed] = Pointer[ScheduleDetailed].alloc(1)
            sched_detailed[].is_used = True
            for i_week in range(1, 367):
                var week_sched: Pointer[WeekSchedule] = sched_detailed[].week_scheds[i_week]
                if week_sched == Pointer[WeekSchedule]():
                    continue
                if week_sched[].is_used:
                    continue
                week_sched[].is_used = True
                for i_day_type in range(1, DayType.NUM):
                    var day_sched: Pointer[DaySchedule] = week_sched[].day_scheds[i_day_type]
                    day_sched[].is_used = True
    return sched

fn get_schedule_always_on(state: Pointer[EnergyPlusData]) -> Pointer[Schedule]:
    return state[].dataSched.schedules[SCHED_NUM_ALWAYS_ON]

fn get_schedule_always_off(state: Pointer[EnergyPlusData]) -> Pointer[Schedule]:
    return state[].dataSched.schedules[SCHED_NUM_ALWAYS_OFF]

fn get_week_schedule_num(state: Pointer[EnergyPlusData], name: String) -> Int32:
    var week_sched: Pointer[WeekSchedule] = get_week_schedule(state, name)
    if week_sched == Pointer[WeekSchedule]():
        return -1
    return week_sched[].num

fn get_week_schedule(state: Pointer[EnergyPlusData], name: String) -> Pointer[WeekSchedule]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var found: Optional[Int32] = s_sched[].week_schedule_map.get(name.upper())
    if not found:
        return Pointer[WeekSchedule]()
    var week_sched: Pointer[WeekSchedule] = s_sched[].week_schedules[found.value()]
    if not week_sched[].is_used:
        week_sched[].is_used = True
        for i_day_type in range(1, DayType.NUM):
            var day_sched: Pointer[DaySchedule] = week_sched[].day_scheds[i_day_type]
            day_sched[].is_used = True
    return week_sched

fn get_day_schedule_num(state: Pointer[EnergyPlusData], name: String) -> Int32:
    var day_sched: Pointer[DaySchedule] = get_day_schedule(state, name)
    if day_sched == Pointer[DaySchedule]():
        return -1
    return day_sched[].num

fn get_day_schedule(state: Pointer[EnergyPlusData], name: String) -> Pointer[DaySchedule]:
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var found: Optional[Int32] = s_sched[].day_schedule_map.get(name.upper())
    if not found:
        return Pointer[DaySchedule]()
    var day_sched: Pointer[DaySchedule] = s_sched[].day_schedules[found.value()]
    day_sched[].is_used = True
    return day_sched

fn external_interface_set_schedule(state: Pointer[EnergyPlusData], sched_num: Int32, value: Real64):
    var s_glob: Pointer[GlobalData] = UnsafePointer.address_of(state[].dataGlobal)
    var s_sched: Pointer[ScheduleManagerData] = UnsafePointer.address_of(state[].dataSched)
    var day_sched: Pointer[DaySchedule] = s_sched[].day_schedules[sched_num]
    for hr in range(24):
        for ts in range(s_glob[].TimeStepsInHour):
            day_sched[].ts_vals[hr * s_glob[].TimeStepsInHour + ts] = value

fn process_interval_fields(state: Pointer[EnergyPlusData], untils: List[String], numbers: List[Real64], num_untils: Int32, num_numbers: Int32, minute_vals: List[Real64], set_minute_vals: List[Bool], day_schedule_name: String, err_context: String, interpolation: Int32):
    pass

fn decode_hhmm_field(state: Pointer[EnergyPlusData], field_value: String, day_schedule_name: String, full_field_value: String, interpolation: Int32) -> Tuple[Int32, Int32]:
    return (0, 0)

fn is_minute_multiple_of_timestep(minute: Int32, num_minutes_per_timestep: Int32) -> Bool:
    if minute != 0:
        return (minute % num_minutes_per_timestep) == 0
    return True

fn process_for_day_types(state: Pointer[EnergyPlusData], for_day_field: String, these_days: List[Bool], already_days: List[Bool]):
    pass

fn check_schedule_value_min(state: Pointer[EnergyPlusData], sched_num: Int32, clu: Int32, min_val: Real64) -> Bool:
    return state[].dataSched.schedules[sched_num][].check_min_val(state, clu, min_val)

fn check_schedule_value_min_max(state: Pointer[EnergyPlusData], sched_num: Int32, clu_min: Int32, min_val: Real64, clu_max: Int32, max_val: Real64) -> Bool:
    return state[].dataSched.schedules[sched_num][].check_min_max_vals(state, clu_min, min_val, clu_max, max_val)

fn check_schedule_value(state: Pointer[EnergyPlusData], sched_num: Int32, value: Real64) -> Bool:
    return state[].dataSched.schedules[sched_num][].has_val(state, value)

fn check_day_schedule_min_values(state: Pointer[EnergyPlusData], sched_num: Int32, clu_min: Int32, min_val: Real64) -> Bool:
    return state[].dataSched.day_schedules[sched_num][].check_min_val(state, clu_min, min_val)

fn show_severe_bad_min(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_min: Int32, min_val: Real64, msg: StringLiteral = ""):
    pass

fn show_severe_bad_max(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_max: Int32, max_val: Real64, msg: StringLiteral = ""):
    pass

fn show_severe_bad_min_max(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_min: Int32, min_val: Real64, clu_max: Int32, max_val: Real64, msg: StringLiteral = ""):
    pass

fn show_warning_bad_min(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_min: Int32, min_val: Real64, msg: StringLiteral = ""):
    pass

fn show_warning_bad_max(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_max: Int32, max_val: Real64, msg: StringLiteral = ""):
    pass

fn show_warning_bad_min_max(state: Pointer[EnergyPlusData], eoh: Any, field_name: StringLiteral, field_val: StringLiteral, clu_min: Int32, min_val: Real64, clu_max: Int32, max_val: Real64, msg: StringLiteral = ""):
    pass
