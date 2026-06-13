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

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Tuple, Set, Dict, Any
import math

# Constants
SCHED_NUM_INVALID = -1
SCHED_NUM_ALWAYS_OFF = 0
SCHED_NUM_ALWAYS_ON = 1

class DayType(IntEnum):
    INVALID = -1
    UNUSED = 0
    SUNDAY = 1
    MONDAY = 2
    TUESDAY = 3
    WEDNESDAY = 4
    THURSDAY = 5
    FRIDAY = 6
    SATURDAY = 7
    HOLIDAY = 8
    SUMMER_DESIGN_DAY = 9
    WINTER_DESIGN_DAY = 10
    CUSTOM_DAY1 = 11
    CUSTOM_DAY2 = 12
    NUM = 13

IDAY_TYPE_SUN = int(DayType.SUNDAY)
IDAY_TYPE_MON = int(DayType.MONDAY)
IDAY_TYPE_TUE = int(DayType.TUESDAY)
IDAY_TYPE_WED = int(DayType.WEDNESDAY)
IDAY_TYPE_THU = int(DayType.THURSDAY)
IDAY_TYPE_FRI = int(DayType.FRIDAY)
IDAY_TYPE_SAT = int(DayType.SATURDAY)
IDAY_TYPE_HOL = int(DayType.HOLIDAY)
IDAY_TYPE_SUM_DES = int(DayType.SUMMER_DESIGN_DAY)
IDAY_TYPE_WIN_DES = int(DayType.WINTER_DESIGN_DAY)
IDAY_TYPE_CUS1 = int(DayType.CUSTOM_DAY1)
IDAY_TYPE_CUS2 = int(DayType.CUSTOM_DAY2)

DAY_TYPE_NAMES = ["Unused", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
                  "Holiday", "SummerDesignDay", "WinterDesignDay", "CustomDay1", "CustomDay2"]
DAY_TYPE_NAMES_UC = ["UNUSED", "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY",
                     "HOLIDAY", "SUMMERDESIGNDAY", "WINTERDESIGNDAY", "CUSTOMDAY1", "CUSTOMDAY2"]

class DayTypeGroup(IntEnum):
    INVALID = -1
    WEEKDAY = 0
    WEEKEND_HOLIDAY = 1
    SUMMER_DESIGN_DAY = 2
    WINTER_DESIGN_DAY = 3
    NUM = 4

class SchedType(IntEnum):
    INVALID = -1
    YEAR = 0
    COMPACT = 1
    FILE = 2
    CONSTANT = 3
    EXTERNAL = 4
    NUM = 5

class ReportLevel(IntEnum):
    INVALID = -1
    HOURLY = 0
    TIMESTEP = 1
    NUM = 2

class Interpolation(IntEnum):
    INVALID = -1
    NO = 0
    AVERAGE = 1
    LINEAR = 2
    NUM = 3

class LimitUnits(IntEnum):
    INVALID = -1
    DIMENSIONLESS = 0
    TEMPERATURE = 1
    DELTA_TEMPERATURE = 2
    PRECIPITATION_RATE = 3
    ANGLE = 4
    CONVECTION_COEFFICIENT = 5
    ACTIVITY_LEVEL = 6
    VELOCITY = 7
    CAPACITY = 8
    POWER = 9
    AVAILABILITY = 10
    PERCENT = 11
    CONTROL = 12
    MODE = 13
    NUM = 14

LIMIT_UNIT_NAMES_UC = ["DIMENSIONLESS", "TEMPERATURE", "DELTATEMPERATURE", "PRECIPITATIONRATE", "ANGLE",
                       "CONVECTIONCOEFFICIENT", "ACTIVITYLEVEL", "VELOCITY", "CAPACITY", "POWER",
                       "AVAILABILITY", "PERCENT", "CONTROL", "MODE"]

REPORT_LEVEL_NAMES = ["Hourly", "Timestep"]
REPORT_LEVEL_NAMES_UC = ["HOURLY", "TIMESTEP"]

INTERPOLATION_NAMES = ["No", "Average", "Linear"]
INTERPOLATION_NAMES_UC = ["NO", "AVERAGE", "LINEAR"]

@dataclass
class ScheduleType:
    name: str = ""
    num: int = SCHED_NUM_INVALID
    is_limited: bool = False
    min_val: float = 0.0
    max_val: float = 0.0
    is_real: bool = True
    limit_units: LimitUnits = LimitUnits.INVALID

@dataclass
class ScheduleBase:
    name: str = ""
    num: int = SCHED_NUM_INVALID
    is_used: bool = False
    max_val: float = 0.0
    min_val: float = 0.0
    is_min_max_set: bool = False

    def set_min_max_vals(self, state):
        raise NotImplementedError("Subclass must implement")

    def get_min_val(self, state):
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return self.min_val

    def get_max_val(self, state):
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return self.max_val

    def check_min_max_vals(self, state, clu_min, min_val, clu_max, max_val):
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        min_ok = (clu_min == "Ex") and (self.min_val > min_val) or (clu_min == "In") and (abs(min_val - self.min_val) < 1e-6)
        max_ok = (clu_max == "Ex") and (self.max_val < max_val) or (clu_max == "In") and (abs(self.max_val - max_val) < 1e-6)
        return min_ok and max_ok

    def check_min_val(self, state, clu_min, min_val):
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return ((clu_min == "In") and (abs(min_val - self.min_val) < 1e-6)) or ((clu_min == "Ex") and (self.min_val > min_val))

    def check_max_val(self, state, clu_max, max_val):
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        return ((clu_max == "Ex") and (self.max_val < max_val)) or ((clu_max == "In") and (abs(self.max_val - max_val) < 1e-6))

@dataclass
class DayOrYearSchedule(ScheduleBase):
    def get_day_vals(self, state, j_day=-1, day_of_week=-1):
        raise NotImplementedError("Subclass must implement")

@dataclass
class DaySchedule(DayOrYearSchedule):
    sched_type_num: int = SCHED_NUM_INVALID
    interpolation: Interpolation = Interpolation.NO
    ts_vals: List[float] = field(default_factory=list)
    sum_ts_vals: float = 0.0

    def check_vals_for_limit_violations(self, state) -> bool:
        s_sched = state.dataSched
        if self.sched_type_num == SCHED_NUM_INVALID:
            return False
        sched_type = s_sched.schedule_types[self.sched_type_num]
        if not sched_type.is_limited:
            return False
        hours_in_day = 24
        for i in range(hours_in_day * state.dataGlobal.TimeStepsInHour):
            if self.ts_vals[i] < sched_type.min_val or self.ts_vals[i] > sched_type.max_val:
                return True
        return False

    def check_vals_for_bad_integers(self, state) -> bool:
        s_sched = state.dataSched
        if self.sched_type_num == SCHED_NUM_INVALID:
            return False
        sched_type = s_sched.schedule_types[self.sched_type_num]
        if sched_type.is_real:
            return False
        hours_in_day = 24
        for i in range(hours_in_day * state.dataGlobal.TimeStepsInHour):
            if self.ts_vals[i] != int(self.ts_vals[i]):
                return True
        return False

    def populate_from_minute_vals(self, state, minute_vals):
        s_glob = state.dataGlobal
        hours_in_day = 24
        minutes_in_hour = 60
        minutes_in_timestep = s_glob.MinutesInTimeStep
        if self.interpolation == Interpolation.AVERAGE:
            for hr in range(hours_in_day):
                beg_min = 0
                end_min = minutes_in_timestep - 1
                for ts in range(s_glob.TimeStepsInHour):
                    accum = 0.0
                    for i_min in range(beg_min, end_min + 1):
                        accum += minute_vals[hr * minutes_in_hour + i_min]
                    self.ts_vals[hr * s_glob.TimeStepsInHour + ts] = accum / minutes_in_timestep
                    self.sum_ts_vals += self.ts_vals[hr * s_glob.TimeStepsInHour + ts]
                    beg_min = end_min + 1
                    end_min += minutes_in_timestep
        else:
            for hr in range(hours_in_day):
                end_minute = minutes_in_timestep - 1
                for ts in range(s_glob.TimeStepsInHour):
                    self.ts_vals[hr * s_glob.TimeStepsInHour + ts] = minute_vals[hr * minutes_in_hour + end_minute]
                    self.sum_ts_vals += self.ts_vals[hr * s_glob.TimeStepsInHour + ts]
                    end_minute += minutes_in_timestep

    def get_day_vals(self, state, j_day=-1, day_of_week=-1):
        return self.ts_vals

    def set_min_max_vals(self, state):
        assert not self.is_min_max_set
        s_glob = state.dataGlobal
        hours_in_day = 24
        self.min_val = self.max_val = self.ts_vals[0]
        for i in range(hours_in_day * s_glob.TimeStepsInHour):
            value = self.ts_vals[i]
            if value < self.min_val:
                self.min_val = value
            elif value > self.max_val:
                self.max_val = value
        self.is_min_max_set = True

@dataclass
class WeekSchedule(ScheduleBase):
    day_scheds: List[Optional['DaySchedule']] = field(default_factory=lambda: [None] * int(DayType.NUM))

    def set_min_max_vals(self, state):
        assert not self.is_min_max_set
        day_sched1 = self.day_scheds[1]
        if day_sched1 is None:
            return
        if not day_sched1.is_min_max_set:
            day_sched1.set_min_max_vals(state)
        self.min_val = day_sched1.min_val
        self.max_val = day_sched1.max_val
        day_sched_prev = day_sched1
        for i_day in range(2, int(DayType.NUM)):
            day_sched = self.day_scheds[i_day]
            if day_sched == day_sched_prev:
                continue
            if not day_sched.is_min_max_set:
                day_sched.set_min_max_vals(state)
            if day_sched.min_val < self.min_val:
                self.min_val = day_sched.min_val
            if day_sched.max_val > self.max_val:
                self.max_val = day_sched.max_val
            day_sched_prev = day_sched
        self.is_min_max_set = True

@dataclass
class Schedule(DayOrYearSchedule):
    type: SchedType = SchedType.INVALID
    sched_type_num: int = SCHED_NUM_INVALID
    ems_actuated_on: bool = False
    ems_val: float = 0.0
    current_val: float = 0.0

    def __post_init__(self):
        self.type = SchedType.CONSTANT

    def get_current_val(self) -> float:
        return self.ems_val if self.ems_actuated_on else self.current_val

    def get_hr_ts_val(self, state, hr, ts=-1) -> float:
        raise NotImplementedError("Subclass must implement")

    def has_val(self, state, val) -> bool:
        raise NotImplementedError("Subclass must implement")

    def has_fractional_val(self, state) -> bool:
        raise NotImplementedError("Subclass must implement")

    def get_min_max_vals_by_day_type(self, state, days):
        raise NotImplementedError("Subclass must implement")

    def get_annual_hours_full_load(self, state, start_day_of_week, is_leap_year) -> float:
        raise NotImplementedError("Subclass must implement")

    def get_annual_hours_greater_than_1_percent(self, state, start_day_of_week, is_leap_year) -> float:
        raise NotImplementedError("Subclass must implement")

    def get_val_and_count_on_day(self, state, is_summer, day_of_week, hour_of_day) -> Tuple[float, int, str]:
        raise NotImplementedError("Subclass must implement")

    def get_average_weekly_hours_full_load(self, state, start_day_of_week, is_leap_year) -> float:
        weeks_in_year = 366.0 / 7.0 if is_leap_year else 365.0 / 7.0
        return self.get_annual_hours_full_load(state, start_day_of_week, is_leap_year) / weeks_in_year

    def get_day_vals(self, state, j_day=-1, day_of_week=-1):
        raise NotImplementedError("Subclass must implement")

@dataclass
class ScheduleConstant(Schedule):
    ts_vals: List[float] = field(default_factory=list)

    def __post_init__(self):
        self.type = SchedType.CONSTANT

    def get_hr_ts_val(self, state, hr, ts=-1) -> float:
        return self.ts_vals[0] if self.ts_vals else 0.0

    def get_day_vals(self, state, j_day=-1, day_of_week=-1):
        return self.ts_vals

    def has_val(self, state, val) -> bool:
        return val == self.current_val

    def has_fractional_val(self, state) -> bool:
        return (self.current_val > 0.0) and (self.current_val < 1.0)

    def set_min_max_vals(self, state):
        assert not self.is_min_max_set
        self.min_val = self.max_val = self.current_val
        self.is_min_max_set = True

    def get_min_max_vals_by_day_type(self, state, days):
        return (self.current_val, self.current_val)

    def get_annual_hours_full_load(self, state, start_day_of_week, is_leap_year) -> float:
        if start_day_of_week < IDAY_TYPE_SUN or start_day_of_week > IDAY_TYPE_SAT:
            return 0.0
        days_in_year = 366 if is_leap_year else 365
        return days_in_year * 24 * self.current_val

    def get_annual_hours_greater_than_1_percent(self, state, start_day_of_week, is_leap_year) -> float:
        days_in_year = 366 if is_leap_year else 365
        if start_day_of_week < IDAY_TYPE_SUN or start_day_of_week > IDAY_TYPE_SAT:
            return 0.0
        return (24 * days_in_year) if (self.current_val > 0.0) else 0

    def get_val_and_count_on_day(self, state, is_summer, day_of_week, hour_of_day) -> Tuple[float, int, str]:
        month = 7 if is_summer else 1
        if state.dataEnvrn.Latitude <= 0.0:
            month = 1 if is_summer else 7
        month_name = "January" if month == 1 else "July"
        days_in_year = 366 if state.dataEnvrn.CurrentYearIsLeapYear else 365
        return (self.current_val, days_in_year, month_name)

@dataclass
class ScheduleDetailed(Schedule):
    week_scheds: List[Optional[WeekSchedule]] = field(default_factory=lambda: [None] * 367)
    max_min_by_day_type_set: List[bool] = field(default_factory=lambda: [False] * int(DayTypeGroup.NUM))
    min_by_day_type: List[float] = field(default_factory=lambda: [0.0] * int(DayTypeGroup.NUM))
    max_by_day_type: List[float] = field(default_factory=lambda: [0.0] * int(DayTypeGroup.NUM))
    use_daylight_saving: bool = True

    def __post_init__(self):
        self.type = SchedType.YEAR

    def get_day_vals(self, state, j_day=-1, day_of_week=-1):
        s_env = state.dataEnvrn
        j_day_val = state.dataEnvrn.DayOfYear_Schedule if j_day == -1 else j_day
        week_sched = self.week_scheds[j_day_val]
        day_sched = None
        if day_of_week == -1:
            day_of_week_val = s_env.HolidayIndex if s_env.HolidayIndex > 0 else s_env.DayOfWeek
            day_sched = week_sched.day_scheds[day_of_week_val]
        elif day_of_week <= 7 and s_env.HolidayIndex > 0:
            day_sched = week_sched.day_scheds[s_env.HolidayIndex]
        else:
            day_sched = week_sched.day_scheds[day_of_week]
        return day_sched.get_day_vals(state)

    def has_val(self, state, val) -> bool:
        s_sched = state.dataSched
        s_glob = state.dataGlobal
        week_sched_checked = [False] * len(s_sched.week_schedules)
        day_sched_checked = [False] * len(s_sched.day_schedules)
        for i_week in range(1, 367):
            week_sched = self.week_scheds[i_week]
            if week_sched_checked[week_sched.num]:
                continue
            for i_day in range(1, int(DayType.NUM)):
                day_sched = week_sched.day_scheds[i_day]
                if day_sched_checked[day_sched.num]:
                    continue
                for i in range(24 * s_glob.TimeStepsInHour):
                    if day_sched.ts_vals[i] == val:
                        return True
                day_sched_checked[day_sched.num] = True
            week_sched_checked[week_sched.num] = True
        return False

    def has_fractional_val(self, state) -> bool:
        s_sched = state.dataSched
        s_glob = state.dataGlobal
        week_sched_checked = [False] * len(s_sched.week_schedules)
        day_sched_checked = [False] * len(s_sched.day_schedules)
        for i_week in range(1, 367):
            week_sched = self.week_scheds[i_week]
            if week_sched_checked[week_sched.num]:
                continue
            for i_day in range(1, int(DayType.NUM)):
                day_sched = week_sched.day_scheds[i_day]
                if day_sched_checked[day_sched.num]:
                    continue
                for i in range(24 * s_glob.TimeStepsInHour):
                    if 0.0 < day_sched.ts_vals[i] < 1.0:
                        return True
                day_sched_checked[day_sched.num] = True
            week_sched_checked[week_sched.num] = True
        return False

    def set_min_max_vals(self, state):
        assert not self.is_min_max_set
        week_sched1 = self.week_scheds[1]
        if week_sched1 is None:
            return
        if not week_sched1.is_min_max_set:
            week_sched1.set_min_max_vals(state)
        self.min_val = week_sched1.min_val
        self.max_val = week_sched1.max_val
        week_sched_prev = week_sched1
        for i_week in range(2, 367):
            week_sched = self.week_scheds[i_week]
            if i_week == 366 and week_sched is None:
                continue
            if week_sched == week_sched_prev:
                continue
            if not week_sched.is_min_max_set:
                week_sched.set_min_max_vals(state)
            if week_sched.min_val < self.min_val:
                self.min_val = week_sched.min_val
            if week_sched.max_val > self.max_val:
                self.max_val = week_sched.max_val
            week_sched_prev = week_sched
        self.is_min_max_set = True

    def get_hr_ts_val(self, state, hr, ts=-1) -> float:
        s_glob = state.dataGlobal
        if self.ems_actuated_on:
            return self.ems_val
        if hr > 24:
            raise RuntimeError(f"LookUpScheduleValue called with thisHour={hr}")
        this_hr = hr + state.dataEnvrn.DSTIndicator * (1 if self.use_daylight_saving else 0)
        this_day_of_year = state.dataEnvrn.DayOfYear_Schedule
        this_day_of_week = state.dataEnvrn.DayOfWeek
        this_holiday_num = state.dataEnvrn.HolidayIndex
        if this_hr > 24:
            this_day_of_year += 1
            this_hr -= 24
            this_day_of_week = state.dataEnvrn.DayOfWeekTomorrow
            this_holiday_num = state.dataEnvrn.HolidayIndexTomorrow
        if this_day_of_year == 367:
            this_day_of_year = 1
        week_sched = self.week_scheds[this_day_of_year]
        if this_holiday_num > 0:
            day_sched = week_sched.day_scheds[this_holiday_num]
        else:
            day_sched = week_sched.day_scheds[this_day_of_week]
        if ts <= 0:
            ts = s_glob.TimeStepsInHour
        return day_sched.ts_vals[(this_hr - 1) * s_glob.TimeStepsInHour + (ts - 1)]

    def get_min_max_vals_by_day_type(self, state, days):
        day_type_filters = [
            [False, False, True, True, True, True, True, False, False, False, False, False, False],
            [False, True, False, False, False, False, False, True, True, False, False, False, False],
            [False, False, False, False, False, False, False, False, False, True, False, False, False],
            [False, False, False, False, False, False, False, False, False, False, True, False, False]
        ]
        s_sched = state.dataSched
        if not self.is_min_max_set:
            self.set_min_max_vals(state)
        if not self.max_min_by_day_type_set[int(days)]:
            first_set = True
            day_type_filter = day_type_filters[int(days)]
            week_sched_checked = [False] * len(s_sched.week_schedules)
            day_sched_checked = [False] * len(s_sched.day_schedules)
            self.min_by_day_type[int(days)] = self.max_by_day_type[int(days)] = 0.0
            for i_day in range(1, 367):
                week_sched = self.week_scheds[i_day]
                if week_sched_checked[week_sched.num]:
                    continue
                for j_day_type in range(1, int(DayType.NUM)):
                    if not day_type_filter[j_day_type]:
                        continue
                    day_sched = week_sched.day_scheds[j_day_type]
                    if day_sched_checked[day_sched.num]:
                        continue
                    if not day_sched.is_min_max_set:
                        day_sched.set_min_max_vals(state)
                    if first_set:
                        self.min_by_day_type[int(days)] = day_sched.min_val
                        self.max_by_day_type[int(days)] = day_sched.max_val
                        first_set = False
                    else:
                        self.min_by_day_type[int(days)] = min(self.min_by_day_type[int(days)], day_sched.min_val)
                        self.max_by_day_type[int(days)] = max(self.max_by_day_type[int(days)], day_sched.max_val)
                    day_sched_checked[day_sched.num] = True
                week_sched_checked[week_sched.num] = True
            self.max_min_by_day_type_set[int(days)] = True
        return (self.min_by_day_type[int(days)], self.max_by_day_type[int(days)])

    def get_annual_hours_full_load(self, state, start_day_of_week, is_leap_year) -> float:
        s_glob = state.dataGlobal
        days_in_year = 366 if is_leap_year else 365
        day_t = start_day_of_week
        total_hours = 0.0
        if day_t < IDAY_TYPE_SUN or day_t > IDAY_TYPE_SAT:
            return total_hours
        for i_day in range(1, days_in_year + 1):
            week_sched = self.week_scheds[i_day]
            day_sched = week_sched.day_scheds[day_t]
            total_hours += day_sched.sum_ts_vals / s_glob.TimeStepsInHour
            day_t += 1
            if day_t > IDAY_TYPE_SAT:
                day_t = IDAY_TYPE_SUN
        return total_hours

    def get_annual_hours_greater_than_1_percent(self, state, start_day_of_week, is_leap_year) -> float:
        s_glob = state.dataGlobal
        days_in_year = 366 if is_leap_year else 365
        day_t = start_day_of_week
        total_hours = 0.0
        if day_t < IDAY_TYPE_SUN or day_t > IDAY_TYPE_SAT:
            return total_hours
        for i_day in range(1, days_in_year + 1):
            week_sched = self.week_scheds[i_day]
            day_sched = week_sched.day_scheds[day_t]
            for i in range(24 * s_glob.TimeStepsInHour):
                if day_sched.ts_vals[i] > 0.0:
                    total_hours += s_glob.TimeStepZone
            day_t += 1
            if day_t > IDAY_TYPE_SAT:
                day_t = IDAY_TYPE_SUN
        return total_hours

    def get_val_and_count_on_day(self, state, is_summer, day_of_week, hour_of_day) -> Tuple[float, int, str]:
        s_glob = state.dataGlobal
        month = 7 if is_summer else 1
        if state.dataEnvrn.Latitude <= 0.0:
            month = 1 if is_summer else 7
        month_name = "January" if month == 1 else "July"
        j_date_select = state.General.nthDayOfWeekOfMonth(state, int(day_of_week), 1, month)
        days_in_year = 366 if state.dataEnvrn.CurrentYearIsLeapYear else 365
        hour_select = hour_of_day + state.dataWeather.DSTIndex[j_date_select]
        first_time_step = 1
        week_sched = self.week_scheds[j_date_select]
        day_sched = week_sched.day_scheds[int(day_of_week)]
        value = day_sched.ts_vals[(hour_select - 1) * s_glob.TimeStepsInHour + (first_time_step - 1)]
        count_of_same = 0
        for j_date_of_year in range(1, days_in_year + 1):
            w_sched = self.week_scheds[j_date_of_year]
            if w_sched == week_sched:
                count_of_same += 1
                continue
            d_sched = w_sched.day_scheds[int(day_of_week)]
            if d_sched == day_sched:
                count_of_same += 1
                continue
            if d_sched.ts_vals[(hour_select - 1) * s_glob.TimeStepsInHour + (first_time_step - 1)] == value:
                count_of_same += 1
        return (value, count_of_same, month_name)

@dataclass
class ScheduleManagerData:
    check_schedule_val_min_max_run_once_only: bool = True
    do_schedule_reporting_setup: bool = True
    unique_processed_external_files: Dict[str, Any] = field(default_factory=dict)
    schedule_input_processed: bool = False
    schedule_file_shading_processed: bool = False
    schedule_types: List[ScheduleType] = field(default_factory=list)
    schedules: List[Schedule] = field(default_factory=list)
    day_schedules: List[DaySchedule] = field(default_factory=list)
    week_schedules: List[WeekSchedule] = field(default_factory=list)
    schedule_type_map: Dict[str, int] = field(default_factory=dict)
    schedule_map: Dict[str, int] = field(default_factory=dict)
    day_schedule_map: Dict[str, int] = field(default_factory=dict)
    week_schedule_map: Dict[str, int] = field(default_factory=dict)

def get_schedule_type_num(state, name: str) -> int:
    s_sched = state.dataSched
    for i in range(len(s_sched.schedule_types)):
        if s_sched.schedule_types[i].name == name:
            return i
    return SCHED_NUM_INVALID

def add_schedule_constant(state, name: str, value: float = 0.0) -> ScheduleConstant:
    s_sched = state.dataSched
    s_glob = state.dataGlobal
    sched = ScheduleConstant(name=name, num=len(s_sched.schedules), type=SchedType.CONSTANT, current_val=value)
    sched.ts_vals = [value] * (24 * max(1, s_glob.TimeStepsInHour))
    s_sched.schedules.append(sched)
    s_sched.schedule_map[name.upper()] = sched.num
    return sched

def add_schedule_detailed(state, name: str) -> ScheduleDetailed:
    s_sched = state.dataSched
    sched = ScheduleDetailed(name=name, num=len(s_sched.schedules), type=SchedType.YEAR)
    s_sched.schedules.append(sched)
    s_sched.schedule_map[name.upper()] = sched.num
    return sched

def add_day_schedule(state, name: str) -> DaySchedule:
    s_glob = state.dataGlobal
    s_sched = state.dataSched
    day_sched = DaySchedule(name=name, num=len(s_sched.day_schedules))
    day_sched.ts_vals = [0.0] * (24 * max(1, s_glob.TimeStepsInHour))
    s_sched.day_schedules.append(day_sched)
    s_sched.day_schedule_map[name.upper()] = day_sched.num
    return day_sched

def add_week_schedule(state, name: str) -> WeekSchedule:
    s_sched = state.dataSched
    week_sched = WeekSchedule(name=name, num=len(s_sched.week_schedules))
    for i_day_type in range(1, int(DayType.NUM)):
        week_sched.day_scheds[i_day_type] = s_sched.day_schedules[SCHED_NUM_ALWAYS_OFF]
    s_sched.week_schedules.append(week_sched)
    s_sched.week_schedule_map[name.upper()] = week_sched.num
    return week_sched

def init_constant_schedule_data(state):
    sched_off = add_schedule_constant(state, "Constant-0.0", 0.0)
    assert sched_off.num == SCHED_NUM_ALWAYS_OFF
    sched_off.is_used = True
    sched_on = add_schedule_constant(state, "Constant-1.0", 1.0)
    assert sched_on.num == SCHED_NUM_ALWAYS_ON
    sched_on.is_used = True
    missing_day_schedule = add_day_schedule(state, "MissingDaySchedule-0.0")
    assert missing_day_schedule.num == SCHED_NUM_ALWAYS_OFF
    missing_day_schedule.is_used = True

def process_schedule_input(state):
    pass

def report_schedule_type_limits(state):
    pass

def report_schedule_details(state, level_of_detail):
    pass

def report_schedule_vals(state):
    pass

def report_orphan_schedules(state):
    pass

def update_schedule_vals(state):
    s_sched = state.dataSched
    s_glob = state.dataGlobal
    for sched in s_sched.schedules:
        if sched.ems_actuated_on:
            sched.current_val = sched.ems_val
        else:
            sched.current_val = sched.get_hr_ts_val(state, s_glob.HourOfDay, s_glob.TimeStep)

def get_current_schedule_value(state, sched_num: int) -> float:
    return state.dataSched.schedules[sched_num].get_current_val()

def get_schedule_num(state, name: str) -> int:
    sched = get_schedule(state, name)
    return sched.num if sched is not None else -1

def get_schedule(state, name: str) -> Optional[Schedule]:
    s_sched = state.dataSched
    found = s_sched.schedule_map.get(name.upper())
    if found is None:
        return None
    sched = s_sched.schedules[found]
    if not sched.is_used:
        sched.is_used = True
        if sched.type != SchedType.CONSTANT:
            sched_detailed = sched
            sched_detailed.is_used = True
            for i_week in range(1, 367):
                week_sched = sched_detailed.week_scheds[i_week]
                if week_sched is not None:
                    if week_sched.is_used:
                        continue
                    week_sched.is_used = True
                    for i_day_type in range(1, int(DayType.NUM)):
                        day_sched = week_sched.day_scheds[i_day_type]
                        day_sched.is_used = True
    return sched

def get_schedule_always_on(state) -> Schedule:
    return state.dataSched.schedules[SCHED_NUM_ALWAYS_ON]

def get_schedule_always_off(state) -> Schedule:
    return state.dataSched.schedules[SCHED_NUM_ALWAYS_OFF]

def get_week_schedule_num(state, name: str) -> int:
    week_sched = get_week_schedule(state, name)
    return week_sched.num if week_sched is not None else -1

def get_week_schedule(state, name: str) -> Optional[WeekSchedule]:
    s_sched = state.dataSched
    found = s_sched.week_schedule_map.get(name.upper())
    if found is None:
        return None
    week_sched = s_sched.week_schedules[found]
    if not week_sched.is_used:
        week_sched.is_used = True
        for i_day_type in range(1, int(DayType.NUM)):
            day_sched = week_sched.day_scheds[i_day_type]
            day_sched.is_used = True
    return week_sched

def get_day_schedule_num(state, name: str) -> int:
    day_sched = get_day_schedule(state, name)
    return day_sched.num if day_sched is not None else -1

def get_day_schedule(state, name: str) -> Optional[DaySchedule]:
    s_sched = state.dataSched
    found = s_sched.day_schedule_map.get(name.upper())
    if found is None:
        return None
    day_sched = s_sched.day_schedules[found]
    day_sched.is_used = True
    return day_sched

def external_interface_set_schedule(state, sched_num: int, value: float):
    s_glob = state.dataGlobal
    s_sched = state.dataSched
    day_sched = s_sched.day_schedules[sched_num]
    for hr in range(24):
        for ts in range(s_glob.TimeStepsInHour):
            day_sched.ts_vals[hr * s_glob.TimeStepsInHour + ts] = value

def process_interval_fields(state, untils, numbers, num_untils, num_numbers, minute_vals, set_minute_vals, day_schedule_name, err_context, interpolation):
    pass

def decode_hhmm_field(state, field_value, day_schedule_name, full_field_value, interpolation):
    pass

def is_minute_multiple_of_timestep(minute: int, num_minutes_per_timestep: int) -> bool:
    if minute != 0:
        return (minute % num_minutes_per_timestep) == 0
    return True

def process_for_day_types(state, for_day_field, these_days, already_days):
    pass

def check_schedule_value_min(state, sched_num: int, clu, min_val: float) -> bool:
    return state.dataSched.schedules[sched_num].check_min_val(state, clu, min_val)

def check_schedule_value_min_max(state, sched_num: int, clu_min, min_val, clu_max, max_val) -> bool:
    return state.dataSched.schedules[sched_num].check_min_max_vals(state, clu_min, min_val, clu_max, max_val)

def check_schedule_value(state, sched_num: int, value: float) -> bool:
    return state.dataSched.schedules[sched_num].has_val(state, value)

def check_day_schedule_min_values(state, sched_num: int, clu_min, min_val: float) -> bool:
    return state.dataSched.day_schedules[sched_num].check_min_val(state, clu_min, min_val)

def show_severe_bad_min(state, eoh, field_name, field_val, clu_min, min_val, msg=""):
    pass

def show_severe_bad_max(state, eoh, field_name, field_val, clu_max, max_val, msg=""):
    pass

def show_severe_bad_min_max(state, eoh, field_name, field_val, clu_min, min_val, clu_max, max_val, msg=""):
    pass

def show_warning_bad_min(state, eoh, field_name, field_val, clu_min, min_val, msg=""):
    pass

def show_warning_bad_max(state, eoh, field_name, field_val, clu_max, max_val, msg=""):
    pass

def show_warning_bad_min_max(state, eoh, field_name, field_val, clu_min, min_val, clu_max, max_val, msg=""):
    pass
