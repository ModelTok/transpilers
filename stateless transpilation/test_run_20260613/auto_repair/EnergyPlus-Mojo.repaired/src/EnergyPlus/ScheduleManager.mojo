// Mojo translation of ScheduleManager.cc
// Faithful 1:1 translation, no refactoring.

from Data.BaseData import BaseGlobalStruct
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataGlobals import *
from DataStringGlobals import CharComma, CharSemicolon, CharSpace, CharTab
from DataSystemVariables import CheckForActualFilePath
from EMSManager import SetupEMSActuator
from FileSystem import FileTypes, getFileType, is_flat_file_type, is_all_json_type, readFile, readJSON
from General import ProcessDateString, OrdinalDay, InvOrdinalDay, nthDayOfWeekOfMonth
from InputProcessing.CsvParser import CsvParser
from InputProcessing.InputProcessor import *
from OutputProcessor import SetupOutputVariable, OutputProcessor, Constant as OutputConstant
from StringUtilities import *
from UtilityRoutines import *
from WeatherManager import *
from memory import Pointer, UnsafePointer
from os import Path
from json import JSON

// Helper functions to mimic ObjexxFCL string functions
def has_prefix(s: String, prefix: String) -> Bool:
    return s.startswith(prefix)

def has(s: String, substr: String) -> Bool:
    return substr in s

def strip(s: String) -> String:
    return s.strip()

def index(s: String, substr: String) -> Int:
    return s.find(substr)

// 1-based to 0-based conversion helpers
def one_based_index(i: Int) -> Int:
    return i - 1

// For Array1D_string, we use List[String]
// For Array1D[Real64], we use List[Float64]
// For Array1D_bool, we use List[Bool]
// For Array1S_string, we use List[String] slice

// Constants
alias SchedNum_Invalid: Int = -1
alias SchedNum_AlwaysOff: Int = 0
alias SchedNum_AlwaysOn: Int = 1

enum DayType: Int {
    Invalid = -1,
    Unused = 0,
    Sunday = 1,
    Monday = 2,
    Tuesday = 3,
    Wednesday = 4,
    Thursday = 5,
    Friday = 6,
    Saturday = 7,
    Holiday = 8,
    SummerDesignDay = 9,
    WinterDesignDay = 10,
    CustomDay1 = 11,
    CustomDay2 = 12,
    Num = 13
}

alias iDayType_Sun: Int = 1
alias iDayType_Mon: Int = 2
alias iDayType_Tue: Int = 3
alias iDayType_Wed: Int = 4
alias iDayType_Thu: Int = 5
alias iDayType_Fri: Int = 6
alias iDayType_Sat: Int = 7
alias iDayType_Hol: Int = 8
alias iDayType_SumDes: Int = 9
alias iDayType_WinDes: Int = 10
alias iDayType_Cus1: Int = 11
alias iDayType_Cus2: Int = 12

let dayTypeNames: StaticTuple[StringLiteral, 13] = StaticTuple(
    "Unused",
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Holiday",
    "SummerDesignDay",
    "WinterDesignDay",
    "CustomDay1",
    "CustomDay2"
)

let dayTypeNamesUC: StaticTuple[StringLiteral, 13] = StaticTuple(
    "UNUSED",
    "SUNDAY",
    "MONDAY",
    "TUESDAY",
    "WEDNESDAY",
    "THURSDAY",
    "FRIDAY",
    "SATURDAY",
    "HOLIDAY",
    "SUMMERDESIGNDAY",
    "WINTERDESIGNDAY",
    "CUSTOMDAY1",
    "CUSTOMDAY2"
)

enum DayTypeGroup: Int {
    Invalid = -1,
    Weekday = 0,
    WeekEndHoliday = 1,
    SummerDesignDay = 2,
    WinterDesignDay = 3,
    Num = 4
}

enum SchedType: Int {
    Invalid = -1,
    Year = 0,
    Compact = 1,
    File = 2,
    Constant = 3,
    External = 4,
    Num = 5
}

enum ReportLevel: Int {
    Invalid = -1,
    Hourly = 0,
    TimeStep = 1,
    Num = 2
}

enum Interpolation: Int {
    Invalid = -1,
    No = 0,
    Average = 1,
    Linear = 2,
    Num = 3
}

enum LimitUnits: Int {
    Invalid = -1,
    Dimensionless = 0,
    Temperature = 1,
    DeltaTemperature = 2,
    PrecipitationRate = 3,
    Angle = 4,
    ConvectionCoefficient = 5,
    ActivityLevel = 6,
    Velocity = 7,
    Capacity = 8,
    Power = 9,
    Availability = 10,
    Percent = 11,
    Control = 12,
    Mode = 13,
    Num = 14
}

let limitUnitNamesUC: StaticTuple[StringLiteral, 14] = StaticTuple(
    "DIMENSIONLESS",
    "TEMPERATURE",
    "DELTATEMPERATURE",
    "PRECIPITATIONRATE",
    "ANGLE",
    "CONVECTIONCOEFFICIENT",
    "ACTIVITYLEVEL",
    "VELOCITY",
    "CAPACITY",
    "POWER",
    "AVAILABILITY",
    "PERCENT",
    "CONTROL",
    "MODE"
)

let reportLevelNames: StaticTuple[StringLiteral, 2] = StaticTuple("Hourly", "Timestep")
let reportLevelNamesUC: StaticTuple[StringLiteral, 2] = StaticTuple("HOURLY", "TIMESTEP")
let interpolationNames: StaticTuple[StringLiteral, 3] = StaticTuple("No", "Average", "Linear")
let interpolationNamesUC: StaticTuple[StringLiteral, 3] = StaticTuple("NO", "AVERAGE", "LINEAR")

struct ScheduleType:
    var Name: String
    var Num: Int
    var isLimited: Bool = False
    var minVal: Float64 = 0.0
    var maxVal: Float64 = 0.0
    var isReal: Bool = True
    var limitUnits: LimitUnits = LimitUnits.Invalid

trait ScheduleBase:
    var Name: String
    var Num: Int = SchedNum_Invalid
    var isUsed: Bool = False
    var maxVal: Float64 = 0.0
    var minVal: Float64 = 0.0
    var isMinMaxSet: Bool = False

    def can_instantiate(self) -> None:

    def setMinMaxVals(self, inout state: EnergyPlusData) -> None:

    def getMinVal(self, inout state: EnergyPlusData) -> Float64:
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        return self.minVal

    def getMaxVal(self, inout state: EnergyPlusData) -> Float64:
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        return self.maxVal

    def checkMinMaxVals(self, inout state: EnergyPlusData, cluMin: Clusive, min: Float64, cluMax: Clusive, max: Float64) -> Bool:
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        var minOk: Bool = (cluMin == Clusive.Ex) ? (self.minVal > min) : (FLT_EPSILON >= min - self.minVal)
        var maxOk: Bool = (cluMax == Clusive.Ex) ? (self.maxVal < max) : (self.maxVal - max <= FLT_EPSILON)
        return minOk and maxOk

    def checkMinVal(self, inout state: EnergyPlusData, cluMin: Clusive, min: Float64) -> Bool:
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        return (cluMin == Clusive.In) ? (FLT_EPSILON >= min - self.minVal) : (self.minVal > min)

    def checkMaxVal(self, inout state: EnergyPlusData, cluMax: Clusive, max: Float64) -> Bool:
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        return (cluMax == Clusive.Ex) ? (self.maxVal < max) : (self.maxVal - max <= FLT_EPSILON)

trait DayOrYearSchedule: ScheduleBase:
    def getDayVals(self, inout state: EnergyPlusData, jDay: Int = -1, dayOfWeek: Int = -1) -> List[Float64]:

struct DaySchedule: DayOrYearSchedule:
    var schedTypeNum: Int = SchedNum_Invalid
    var interpolation: Interpolation = Interpolation.No
    var tsVals: List[Float64] = List[Float64]()
    var sumTsVals: Float64 = 0.0

    def can_instantiate(self) -> None:
        assert(False)

    def checkValsForLimitViolations(self, inout state: EnergyPlusData) -> Bool:
        var s_sched = state.dataSched
        if self.schedTypeNum == SchedNum_Invalid:
            return False
        var schedType = s_sched.scheduleTypes[self.schedTypeNum]
        if not schedType.isLimited:
            return False
        for i in range(Constant.iHoursInDay * state.dataGlobal.TimeStepsInHour):
            if self.tsVals[i] < schedType.minVal or self.tsVals[i] > schedType.maxVal:
                return True
        return False

    def checkValsForBadIntegers(self, inout state: EnergyPlusData) -> Bool:
        var s_sched = state.dataSched
        if self.schedTypeNum == SchedNum_Invalid:
            return False
        var schedType = s_sched.scheduleTypes[self.schedTypeNum]
        if schedType.isReal:
            return False
        for i in range(Constant.iHoursInDay * state.dataGlobal.TimeStepsInHour):
            if self.tsVals[i] != Int(self.tsVals[i]):
                return True
        return False

    def populateFromMinuteVals(self, inout state: EnergyPlusData, minuteVals: StaticTuple[Float64, Constant.iMinutesInDay]) -> None:
        var s_glob = state.dataGlobal
        if self.interpolation == Interpolation.Average:
            for hr in range(Constant.iHoursInDay):
                var begMin: Int = 0
                var endMin: Int = s_glob.MinutesInTimeStep - 1
                for ts in range(s_glob.TimeStepsInHour):
                    var accum: Float64 = 0.0
                    for iMin in range(begMin, endMin + 1):
                        accum += minuteVals[hr * Constant.iMinutesInHour + iMin]
                    self.tsVals[hr * s_glob.TimeStepsInHour + ts] = accum / Float64(s_glob.MinutesInTimeStep)
                    self.sumTsVals += self.tsVals[hr * s_glob.TimeStepsInHour + ts]
                    begMin = endMin + 1
                    endMin += s_glob.MinutesInTimeStep
        else:
            for hr in range(Constant.iHoursInDay):
                var endMinute: Int = s_glob.MinutesInTimeStep - 1
                for ts in range(s_glob.TimeStepsInHour):
                    self.tsVals[hr * s_glob.TimeStepsInHour + ts] = minuteVals[hr * Constant.iMinutesInHour + endMinute]
                    self.sumTsVals += self.tsVals[hr * s_glob.TimeStepsInHour + ts]
                    endMinute += s_glob.MinutesInTimeStep

    def getDayVals(self, inout state: EnergyPlusData, jDay: Int = -1, dayOfWeek: Int = -1) -> List[Float64]:
        return self.tsVals

    def setMinMaxVals(self, inout state: EnergyPlusData) -> None:
        assert(not self.isMinMaxSet)
        var s_glob = state.dataGlobal
        self.minVal = self.maxVal = self.tsVals[0]
        for i in range(Constant.iHoursInDay * s_glob.TimeStepsInHour):
            var value: Float64 = self.tsVals[i]
            if value < self.minVal:
                self.minVal = value
            elif value > self.maxVal:
                self.maxVal = value
        self.isMinMaxSet = True

struct WeekSchedule: ScheduleBase:
    var dayScheds: StaticTuple[Pointer[DaySchedule], 13] = StaticTuple[Pointer[DaySchedule], 13]()

    def can_instantiate(self) -> None:
        assert(False)

    def setMinMaxVals(self, inout state: EnergyPlusData) -> None:
        assert(not self.isMinMaxSet)
        var daySched1 = self.dayScheds[1]
        if daySched1.is_null():
            return
        if not daySched1[].isMinMaxSet:
            daySched1[].setMinMaxVals(state)
        self.minVal = daySched1[].minVal
        self.maxVal = daySched1[].maxVal
        var daySchedPrev = daySched1
        for iDay in range(2, 13):
            var daySched = self.dayScheds[iDay]
            if daySched.is_null():
                continue
            if daySched == daySchedPrev:
                continue
            if not daySched[].isMinMaxSet:
                daySched[].setMinMaxVals(state)
            if daySched[].minVal < self.minVal:
                self.minVal = daySched[].minVal
            if daySched[].maxVal > self.maxVal:
                self.maxVal = daySched[].maxVal
            daySchedPrev = daySched
        self.isMinMaxSet = True

trait Schedule: DayOrYearSchedule:
    var type: SchedType = SchedType.Invalid
    var schedTypeNum: Int = SchedNum_Invalid
    var EMSActuatedOn: Bool = False
    var EMSVal: Float64 = 0.0
    var currentVal: Float64 = 0.0

    def __init__(self):
        self.type = SchedType.Constant

    def getCurrentVal(self) -> Float64:
        return self.EMSVal if self.EMSActuatedOn else self.currentVal

    def getHrTsVal(self, inout state: EnergyPlusData, hr: Int, ts: Int = -1) -> Float64:

    def hasVal(self, inout state: EnergyPlusData, val: Float64) -> Bool:

    def hasFractionalVal(self, inout state: EnergyPlusData) -> Bool:

    def getMinMaxValsByDayType(self, inout state: EnergyPlusData, days: DayTypeGroup) -> Tuple[Float64, Float64]:

    def getAverageWeeklyHoursFullLoad(self, inout state: EnergyPlusData, startDayOfWeek: Int, isLeapYear: Bool) -> Float64:
        var WeeksInYear: Float64 = 366.0 / 7.0 if isLeapYear else 365.0 / 7.0
        return self.getAnnualHoursFullLoad(state, startDayOfWeek, isLeapYear) / WeeksInYear

    def getAnnualHoursFullLoad(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isLeapYear: Bool) -> Float64:

    def getAnnualHoursGreaterThan1Percent(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isLeapYear: Bool) -> Float64:

    def getValAndCountOnDay(self, inout state: EnergyPlusData, isSummer: Bool, dayOfWeek: DayType, hourOfDay: Int) -> Tuple[Float64, Int, String]:

struct ScheduleConstant: Schedule:
    var tsVals: List[Float64] = List[Float64]()

    def __init__(self):
        self.type = SchedType.Constant

    def can_instantiate(self) -> None:
        assert(False)

    def getHrTsVal(self, inout state: EnergyPlusData, hr: Int, ts: Int = -1) -> Float64:
        return self.tsVals[0]

    def getDayVals(self, inout state: EnergyPlusData, jDay: Int = -1, dayOfWeek: Int = -1) -> List[Float64]:
        assert(Int(self.tsVals.size()) == Constant.iHoursInDay * state.dataGlobal.TimeStepsInHour)
        return self.tsVals

    def hasVal(self, inout state: EnergyPlusData, val: Float64) -> Bool:
        return val == self.currentVal

    def hasFractionalVal(self, inout state: EnergyPlusData) -> Bool:
        return (self.currentVal > 0.0) and (self.currentVal < 1.0)

    def setMinMaxVals(self, inout state: EnergyPlusData) -> None:
        assert(not self.isMinMaxSet)
        self.minVal = self.maxVal = self.currentVal
        self.isMinMaxSet = True

    def getMinMaxValsByDayType(self, inout state: EnergyPlusData, days: DayTypeGroup) -> Tuple[Float64, Float64]:
        return (self.currentVal, self.currentVal)

    def getAnnualHoursFullLoad(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isLeapYear: Bool) -> Float64:
        if StartDayOfWeek < iDayType_Sun or StartDayOfWeek > iDayType_Sat:
            return 0.0
        var DaysInYear: Int = 366 if isLeapYear else 365
        return Float64(DaysInYear) * Constant.rHoursInDay * self.currentVal

    def getAnnualHoursGreaterThan1Percent(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isItLeapYear: Bool) -> Float64:
        var DaysInYear: Int = 366 if isItLeapYear else 365
        if StartDayOfWeek < iDayType_Sun or StartDayOfWeek > iDayType_Sat:
            return 0.0
        return (Constant.rHoursInDay * Float64(DaysInYear)) if (self.currentVal > 0.0) else 0.0

    def getValAndCountOnDay(self, inout state: EnergyPlusData, isSummer: Bool, dayOfWeek: DayType, hourOfDay: Int) -> Tuple[Float64, Int, String]:
        var month: Int
        if isSummer:
            month = 7 if (state.dataEnvrn.Latitude > 0.0) else 1
        else:
            month = 1 if (state.dataEnvrn.Latitude > 0.0) else 7
        var monthName: String = "January" if month == 1 else "July"
        var DaysInYear: Int = 366 if state.dataEnvrn.CurrentYearIsLeapYear else 365
        return (self.currentVal, DaysInYear, monthName)

struct ScheduleDetailed: Schedule:
    var weekScheds: StaticTuple[Pointer[WeekSchedule], 367] = StaticTuple[Pointer[WeekSchedule], 367]()
    var MaxMinByDayTypeSet: StaticTuple[Bool, 13] = StaticTuple[Bool, 13]()
    var MinByDayType: StaticTuple[Float64, 13] = StaticTuple[Float64, 13]()
    var MaxByDayType: StaticTuple[Float64, 13] = StaticTuple[Float64, 13]()
    var UseDaylightSaving: Bool = True

    def __init__(self):
        self.type = SchedType.Year

    def can_instantiate(self) -> None:
        assert(False)

    def getDayVals(self, inout state: EnergyPlusData, jDay: Int = -1, dayOfWeek: Int = -1) -> List[Float64]:
        var s_env = state.dataEnvrn
        var weekSched = self.weekScheds[(jDay if jDay != -1 else s_env.DayOfYear_Schedule)]
        var daySched: Pointer[DaySchedule]
        if dayOfWeek == -1:
            daySched = weekSched[].dayScheds[(s_env.HolidayIndex if s_env.HolidayIndex > 0 else s_env.DayOfWeek)]
        elif dayOfWeek <= 7 and s_env.HolidayIndex > 0:
            daySched = weekSched[].dayScheds[s_env.HolidayIndex]
        else:
            daySched = weekSched[].dayScheds[dayOfWeek]
        return daySched[].getDayVals(state)

    def hasVal(self, inout state: EnergyPlusData, value: Float64) -> Bool:
        var s_sched = state.dataSched
        var s_glob = state.dataGlobal
        var weekSchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.weekSchedules.size())
        var daySchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.daySchedules.size())
        for iWeek in range(1, 367):
            var weekSched = self.weekScheds[iWeek]
            if weekSched.is_null():
                continue
            if weekSchedChecked[weekSched[].Num]:
                continue
            for iDay in range(1, 13):
                var daySched = weekSched[].dayScheds[iDay]
                if daySched.is_null():
                    continue
                if daySchedChecked[daySched[].Num]:
                    continue
                for i in range(Constant.iHoursInDay * s_glob.TimeStepsInHour):
                    if daySched[].tsVals[i] == value:
                        return True
                daySchedChecked[daySched[].Num] = True
            weekSchedChecked[weekSched[].Num] = True
        return False

    def hasFractionalVal(self, inout state: EnergyPlusData) -> Bool:
        var s_sched = state.dataSched
        var s_glob = state.dataGlobal
        var weekSchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.weekSchedules.size())
        var daySchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.daySchedules.size())
        for iWeek in range(1, 367):
            var weekSched = self.weekScheds[iWeek]
            if weekSched.is_null():
                continue
            if weekSchedChecked[weekSched[].Num]:
                continue
            for iDay in range(1, 13):
                var daySched = weekSched[].dayScheds[iDay]
                if daySched.is_null():
                    continue
                if daySchedChecked[daySched[].Num]:
                    continue
                for i in range(Constant.iHoursInDay * s_glob.TimeStepsInHour):
                    if daySched[].tsVals[i] > 0.0 and daySched[].tsVals[i] < 1.0:
                        return True
                daySchedChecked[daySched[].Num] = True
            weekSchedChecked[weekSched[].Num] = True
        return False

    def setMinMaxVals(self, inout state: EnergyPlusData) -> None:
        assert(not self.isMinMaxSet)
        var weekSched1 = self.weekScheds[1]
        if weekSched1.is_null():
            return
        if not weekSched1[].isMinMaxSet:
            weekSched1[].setMinMaxVals(state)
        self.minVal = weekSched1[].minVal
        self.maxVal = weekSched1[].maxVal
        var weekSchedPrev = weekSched1
        for iWeek in range(2, 367):
            var weekSched = self.weekScheds[iWeek]
            if iWeek == 366 and weekSched.is_null():
                continue
            if weekSched == weekSchedPrev:
                continue
            if not weekSched[].isMinMaxSet:
                weekSched[].setMinMaxVals(state)
            if weekSched[].minVal < self.minVal:
                self.minVal = weekSched[].minVal
            if weekSched[].maxVal > self.maxVal:
                self.maxVal = weekSched[].maxVal
            weekSchedPrev = weekSched
        self.isMinMaxSet = True

    def getHrTsVal(self, inout state: EnergyPlusData, hr: Int, ts: Int = -1) -> Float64:
        var s_glob = state.dataGlobal
        if self.EMSActuatedOn:
            return self.EMSVal
        if hr > Constant.iHoursInDay:
            ShowFatalError(state, f"LookUpScheduleValue called with thisHour={hr}")
        var thisHr: Int = hr + state.dataEnvrn.DSTIndicator * Int(self.UseDaylightSaving)
        var thisDayOfYear: Int = state.dataEnvrn.DayOfYear_Schedule
        var thisDayOfWeek: Int = state.dataEnvrn.DayOfWeek
        var thisHolidayNum: Int = state.dataEnvrn.HolidayIndex
        if thisHr > Constant.iHoursInDay:
            thisDayOfYear += 1
            thisHr -= Constant.iHoursInDay
            thisDayOfWeek = state.dataEnvrn.DayOfWeekTomorrow
            thisHolidayNum = state.dataEnvrn.HolidayIndexTomorrow
        if thisDayOfYear == 367:
            thisDayOfYear = 1
        var weekSched = self.weekScheds[thisDayOfYear]
        var daySched = weekSched[].dayScheds[(thisHolidayNum if thisHolidayNum > 0 else thisDayOfWeek)]
        if ts <= 0:
            ts = s_glob.TimeStepsInHour
        return daySched[].tsVals[(thisHr - 1) * s_glob.TimeStepsInHour + (ts - 1)]

    def getMinMaxValsByDayType(self, inout state: EnergyPlusData, days: DayTypeGroup) -> Tuple[Float64, Float64]:
        let dayTypeFilters: StaticTuple[StaticTuple[Bool, 13], 4] = StaticTuple(
            StaticTuple(False, False, True, True, True, True, True, False, False, False, False, False, False),
            StaticTuple(False, True, False, False, False, False, False, True, True, False, False, False, False),
            StaticTuple(False, False, False, False, False, False, False, False, False, True, False, False, False),
            StaticTuple(False, False, False, False, False, False, False, False, False, False, True, False, False)
        )
        var s_sched = state.dataSched
        if not self.isMinMaxSet:
            self.setMinMaxVals(state)
        if not self.MaxMinByDayTypeSet[Int(days)]:
            var firstSet: Bool = True
            var dayTypeFilter = dayTypeFilters[Int(days)]
            var weekSchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.weekSchedules.size())
            var daySchedChecked: List[Bool] = List[Bool](repeating=False, count=s_sched.daySchedules.size())
            self.MinByDayType[Int(days)] = self.MaxByDayType[Int(days)] = 0.0
            for iDay in range(1, 367):
                var weekSched = self.weekScheds[iDay]
                if weekSched.is_null():
                    continue
                if weekSchedChecked[weekSched[].Num]:
                    continue
                for jDayType in range(1, 13):
                    if not dayTypeFilter[jDayType]:
                        continue
                    var daySched = weekSched[].dayScheds[jDayType]
                    if daySched.is_null():
                        continue
                    if daySchedChecked[daySched[].Num]:
                        continue
                    if not daySched[].isMinMaxSet:
                        daySched[].setMinMaxVals(state)
                    if firstSet:
                        self.MinByDayType[Int(days)] = daySched[].minVal
                        self.MaxByDayType[Int(days)] = daySched[].maxVal
                        firstSet = False
                    else:
                        self.MinByDayType[Int(days)] = min(self.MinByDayType[Int(days)], daySched[].minVal)
                        self.MaxByDayType[Int(days)] = max(self.MaxByDayType[Int(days)], daySched[].maxVal)
                    daySchedChecked[daySched[].Num] = True
                weekSchedChecked[weekSched[].Num] = True
            self.MaxMinByDayTypeSet[Int(days)] = True
        return (self.MinByDayType[Int(days)], self.MaxByDayType[Int(days)])

    def getAnnualHoursFullLoad(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isLeapYear: Bool) -> Float64:
        var s_glob = state.dataGlobal
        var DaysInYear: Int = 366 if isLeapYear else 365
        var DayT: Int = StartDayOfWeek
        var TotalHours: Float64 = 0.0
        if DayT < iDayType_Sun or DayT > iDayType_Sat:
            return TotalHours
        for iDay in range(1, DaysInYear + 1):
            var weekSched = self.weekScheds[iDay]
            var daySched = weekSched[].dayScheds[DayT]
            TotalHours += daySched[].sumTsVals / Float64(s_glob.TimeStepsInHour)
            DayT += 1
            if DayT > iDayType_Sat:
                DayT = iDayType_Sun
        return TotalHours

    def getAnnualHoursGreaterThan1Percent(self, inout state: EnergyPlusData, StartDayOfWeek: Int, isItLeapYear: Bool) -> Float64:
        var s_glob = state.dataGlobal
        var DaysInYear: Int = 366 if isItLeapYear else 365
        var DayT: Int = StartDayOfWeek
        var TotalHours: Float64 = 0.0
        if DayT < iDayType_Sun or DayT > iDayType_Sat:
            return TotalHours
        for iDay in range(1, DaysInYear + 1):
            var weekSched = self.weekScheds[iDay]
            var daySched = weekSched[].dayScheds[DayT]
            for i in range(Constant.iHoursInDay * s_glob.TimeStepsInHour):
                if daySched[].tsVals[i] > 0.0:
                    TotalHours += s_glob.TimeStepZone
            DayT += 1
            if DayT > iDayType_Sat:
                DayT = iDayType_Sun
        return TotalHours

    def getValAndCountOnDay(self, inout state: EnergyPlusData, isSummer: Bool, dayOfWeek: DayType, hourOfDay: Int) -> Tuple[Float64, Int, String]:
        var s_glob = state.dataGlobal
        var month: Int
        if isSummer:
            month = 7 if (state.dataEnvrn.Latitude > 0.0) else 1
        else:
            month = 1 if (state.dataEnvrn.Latitude > 0.0) else 7
        var monthName: String = "January" if month == 1 else "July"
        var jdateSelect: Int = nthDayOfWeekOfMonth(state, Int(dayOfWeek), 1, month)
        var DaysInYear: Int = 366 if state.dataEnvrn.CurrentYearIsLeapYear else 365
        var hourSelect: Int = hourOfDay + state.dataWeather.DSTIndicator(jdateSelect)
        let firstTimeStep: Int = 1
        var weekSched = self.weekScheds[jdateSelect]
        var daySched = weekSched[].dayScheds[Int(dayOfWeek)]
        var value: Float64 = daySched[].tsVals[(hourSelect - 1) * state.dataGlobal.TimeStepsInHour + (firstTimeStep - 1)]
        var countOfSame: Int = 0
        for jdateOfYear in range(1, DaysInYear + 1):
            var wSched = self.weekScheds[jdateOfYear]
            if wSched == weekSched:
                countOfSame += 1
                continue
            var dSched = wSched[].dayScheds[Int(dayOfWeek)]
            if dSched == daySched:
                countOfSame += 1
                continue
            if dSched[].tsVals[(hourSelect - 1) * s_glob.TimeStepsInHour + (firstTimeStep - 1)] == value:
                countOfSame += 1
        return (value, countOfSame, monthName)

// Free functions
def GetScheduleTypeNum(state: EnergyPlusData, name: String) -> Int:
    var s_sched = state.dataSched
    for i in range(s_sched.scheduleTypes.size()):
        if s_sched.scheduleTypes[i].Name == name:
            return i
    return SchedNum_Invalid

def AddScheduleConstant(inout state: EnergyPlusData, name: String, value: Float64 = 0.0) -> Pointer[ScheduleConstant]:
    var s_sched = state.dataSched
    var s_glob = state.dataGlobal
    var sched = Pointer[ScheduleConstant].alloc()
    sched[].Name = name
    sched[].type = SchedType.Constant
    sched[].Num = Int(s_sched.schedules.size())
    sched[].currentVal = value
    sched[].tsVals = List[Float64](repeating=value, count=Constant.iHoursInDay * max(1, s_glob.TimeStepsInHour))
    s_sched.schedules.append(Pointer[Schedule](sched))
    s_sched.scheduleMap[Util.makeUPPER(sched[].Name)] = sched[].Num
    return sched

def AddScheduleDetailed(inout state: EnergyPlusData, name: String) -> Pointer[ScheduleDetailed]:
    var s_sched = state.dataSched
    var sched = Pointer[ScheduleDetailed].alloc()
    sched[].Name = name
    sched[].Num = Int(s_sched.schedules.size())
    s_sched.schedules.append(Pointer[Schedule](sched))
    s_sched.scheduleMap[Util.makeUPPER(sched[].Name)] = sched[].Num
    sched[].type = SchedType.Year
    return sched

def AddDaySchedule(inout state: EnergyPlusData, name: String) -> Pointer[DaySchedule]:
    var s_glob = state.dataGlobal
    var s_sched = state.dataSched
    var daySched = Pointer[DaySchedule].alloc()
    daySched[].Name = name
    daySched[].Num = Int(s_sched.daySchedules.size())
    s_sched.daySchedules.append(daySched)
    s_sched.dayScheduleMap[Util.makeUPPER(daySched[].Name)] = daySched[].Num
    daySched[].tsVals = List[Float64](repeating=0.0, count=Constant.iHoursInDay * max(1, s_glob.TimeStepsInHour))
    return daySched

def AddWeekSchedule(inout state: EnergyPlusData, name: String) -> Pointer[WeekSchedule]:
    var s_sched = state.dataSched
    var weekSched = Pointer[WeekSchedule].alloc()
    weekSched[].Name = name
    for iDayType in range(1, 13):
        weekSched[].dayScheds[iDayType] = s_sched.daySchedules[SchedNum_AlwaysOff]
    weekSched[].Num = Int(s_sched.weekSchedules.size())
    s_sched.weekSchedules.append(weekSched)
    s_sched.weekScheduleMap[Util.makeUPPER(weekSched[].Name)] = weekSched[].Num
    return weekSched

def InitConstantScheduleData(inout state: EnergyPlusData) -> None:
    var schedOff = AddScheduleConstant(state, "Constant-0.0", 0.0)
    assert(schedOff[].Num == SchedNum_AlwaysOff)
    schedOff[].isUsed = True
    var schedOn = AddScheduleConstant(state, "Constant-1.0", 1.0)
    assert(schedOn[].Num == SchedNum_AlwaysOn)
    schedOn[].isUsed = True
    var missingDaySchedule = AddDaySchedule(state, "MissingDaySchedule-0.0")
    assert(missingDaySchedule[].Num == SchedNum_AlwaysOff)
    missingDaySchedule[].isUsed = True

def ProcessScheduleInput(inout state: EnergyPlusData) -> None:
    using DataStringGlobals.CharComma
    using DataStringGlobals.CharSemicolon
    using DataStringGlobals.CharSpace
    using DataStringGlobals.CharTab
    using DataSystemVariables.CheckForActualFilePath
    using General.ProcessDateString
    let routineName: StringLiteral = "ProcessScheduleInput"
    var Alphas: List[String] = List[String]()
    var cAlphaFields: List[String] = List[String]()
    var cNumericFields: List[String] = List[String]()
    var Numbers: List[Float64] = List[Float64]()
    var lAlphaBlanks: List[Bool] = List[Bool]()
    var lNumericBlanks: List[Bool] = List[Bool]()
    var NumAlphas: Int = 0
    var NumNumbers: Int = 0
    var Status: Int = 0
    var EndMonth: Int = 0
    var EndDay: Int = 0
    var StartPointer: Int = 0
    var EndPointer: Int = 0
    var ErrorsFound: Bool = False
    var minuteVals: StaticTuple[Float64, Constant.iMinutesInDay] = StaticTuple[Float64, Constant.iMinutesInDay]()
    var setMinuteVals: StaticTuple[Bool, Constant.iMinutesInDay] = StaticTuple[Bool, Constant.iMinutesInDay]()
    var NumFields: Int = 0
    var MinutesPerItem: Int = 0
    var NumExpectedItems: Int = 0
    var allDays: StaticTuple[Bool, 13] = StaticTuple[Bool, 13]()
    var theseDays: StaticTuple[Bool, 13] = StaticTuple[Bool, 13]()
    var ErrorHere: Bool = False
    var SchNum: Int = 0
    var WkCount: Int = 0
    var DyCount: Int = 0
    var NumField: Int = 0
    var Count: Int = 0
    var PDateType: Weather.DateType
    var PWeekDay: Int = 0
    var ThruField: Int = 0
    var UntilFld: Int = 0
    var xxcount: Int = 0
    var CurrentThrough: String = ""
    var LastFor: String = ""
    var rowCnt: Int = 0
    var MaxNums1: Int = 0
    var ColumnSep: String = ""
    var rowLimitCount: Int = 0
    var skiprowCount: Int = 0
    var curcolCount: Int = 0
    var numerrors: Int = 0
    var s_glob = state.dataGlobal
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_sched = state.dataSched
    if s_sched.ScheduleInputProcessed:
        return
    s_sched.ScheduleInputProcessed = True
    var MaxNums: Int = 1
    var MaxAlps: Int = 0
    var CurrentModuleObject: String = "ScheduleTypeLimits"
    var NumScheduleTypes: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumScheduleTypes > 0:
        var Count: Int = 0
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Day:Hourly"
    var NumHrDaySchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumHrDaySchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Day:Interval"
    var NumIntDaySchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumIntDaySchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Day:List"
    var NumLstDaySchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumLstDaySchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Week:Daily"
    var NumRegWeekSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumRegWeekSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Week:Compact"
    var NumCptWeekSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumCptWeekSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Year"
    var NumRegSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumRegSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Compact"
    var NumCptSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumCptSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas + 1)
    CurrentModuleObject = "Schedule:File"
    var NumCommaFileSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumCommaFileSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "Schedule:Constant"
    var NumConstantSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumConstantSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas)
    CurrentModuleObject = "ExternalInterface:Schedule"
    var NumExternalInterfaceSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumExternalInterfaceSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas + 1)
    CurrentModuleObject = "ExternalInterface:FunctionalMockupUnitImport:To:Schedule"
    var NumExternalInterfaceFunctionalMockupUnitImportSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumExternalInterfaceFunctionalMockupUnitImportSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas + 1)
    CurrentModuleObject = "ExternalInterface:FunctionalMockupUnitExport:To:Schedule"
    var NumExternalInterfaceFunctionalMockupUnitExportSchedules: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumExternalInterfaceFunctionalMockupUnitExportSchedules > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
        MaxNums = max(MaxNums, NumNumbers)
        MaxAlps = max(MaxAlps, NumAlphas + 1)
    CurrentModuleObject = "Output:Schedules"
    s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, Count, NumAlphas, NumNumbers)
    MaxNums = max(MaxNums, NumNumbers)
    MaxAlps = max(MaxAlps, NumAlphas)
    Alphas = List[String](repeating="", count=MaxAlps)
    cAlphaFields = List[String](repeating="", count=MaxAlps)
    cNumericFields = List[String](repeating="", count=MaxNums)
    Numbers = List[Float64](repeating=0.0, count=MaxNums)
    lAlphaBlanks = List[Bool](repeating=True, count=MaxAlps)
    lNumericBlanks = List[Bool](repeating=True, count=MaxNums)
    CurrentModuleObject = "Schedule:Compact"
    MaxNums1 = 0
    for LoopIndex in range(1, NumCptSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, LoopIndex, Alphas, NumAlphas, Numbers, NumNumbers, Status)
        for Count in range(3, NumAlphas + 1):
            if has_prefix(Alphas[one_based_index(Count)], "UNTIL"):
                MaxNums1 += 1
    if MaxNums1 > MaxNums:
        MaxNums = MaxNums1
        cNumericFields = List[String](repeating="", count=MaxNums)
        Numbers = List[Float64](repeating=0.0, count=MaxNums)
        lNumericBlanks = List[Bool](repeating=True, count=MaxNums)
    CurrentModuleObject = "Schedule:File:Shading"
    var NumCommaFileShading: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    NumAlphas = 0
    NumNumbers = 0
    if NumCommaFileShading > 1:
        ShowWarningError(state, f"More than 1 occurrence of this object found, only first will be used. {CurrentModuleObject}")
    var schedule_file_shading_result: Dict[String, JSON] = Dict[String, JSON]()
    if NumCommaFileShading != 0:
        s_ip.getObjectItem(state, CurrentModuleObject, 1, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var ShadingSunlitFracFileName: String = Alphas[0]
        var contextString: String = CurrentModuleObject + ", " + cAlphaFields[0] + ": "
        state.files.TempFullFilePath.filePath = CheckForActualFilePath(state, ShadingSunlitFracFileName, contextString)
        if state.files.TempFullFilePath.filePath == "":
            ShowFatalError(state, "Program terminates due to previous condition.")
        if state.dataEnvrn.CurrentYearIsLeapYear:
            rowLimitCount = 366 * Constant.iHoursInDay * s_glob.TimeStepsInHour
        else:
            rowLimitCount = 365 * Constant.iHoursInDay * s_glob.TimeStepsInHour
        ColumnSep = CharComma
        var filePath: String = state.files.TempFullFilePath.filePath
        if filePath not in s_sched.UniqueProcessedExternalFiles:
            var ext: FileTypes = getFileType(filePath)
            if is_flat_file_type(ext):
                var schedule_data: String = readFile(filePath)
                var csvParser: CsvParser = CsvParser()
                skiprowCount = 1
                var it: Tuple[String, JSON] = (filePath, csvParser.decode(schedule_data, ColumnSep, skiprowCount))
                s_sched.UniqueProcessedExternalFiles[it[0]] = it[1]
                if csvParser.hasErrors():
                    for (error, isContinued) in csvParser.errors():
                        if isContinued:
                            ShowContinueError(state, error)
                        else:
                            ShowSevereError(state, error)
                    ShowContinueError(state, f"Error Occurred in {filePath}")
                    ShowFatalError(state, "Program terminates due to previous condition.")
                for (warning, isContinued) in csvParser.warnings():
                    if isContinued:
                        ShowContinueError(state, warning)
                    else:
                        ShowWarningError(state, warning)
                schedule_file_shading_result = it
            elif is_all_json_type(ext):
                var schedule_data: JSON = readJSON(filePath)
                s_sched.UniqueProcessedExternalFiles[filePath] = schedule_data
                schedule_file_shading_result = (filePath, schedule_data)
            else:
                var isCSV: Bool = False
                var isJSON: Bool = False
                try:
                    var schedule_data: String = readFile(filePath)
                    var csvParser: CsvParser = CsvParser()
                    skiprowCount = 1
                    var it: Tuple[String, JSON] = (filePath, csvParser.decode(schedule_data, ColumnSep, skiprowCount))
                    if not csvParser.hasErrors():
                        isCSV = True
                        ShowWarningMessage(state, f"Extension of file {filePath} is unrecognized, but parsed as CSV successfully")
                        schedule_file_shading_result = it
                except:
                    isCSV = False
                try:
                    var schedule_data: JSON = readJSON(filePath)
                    s_sched.UniqueProcessedExternalFiles[filePath] = schedule_data
                    schedule_file_shading_result = (filePath, schedule_data)
                    ShowWarningMessage(state, f"Extension of file {filePath} is unrecognized, but parsed as JSON successfully")
                    isJSON = True
                except:
                    isJSON = False
                if not isCSV and not isJSON:
                    ShowSevereError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\", {cAlphaFields[2]}=\"{Alphas[2]}\" has an unknown file extension and cannot be read by this program.")
                    ShowFatalError(state, "Program terminates due to previous condition.")
        else:
            schedule_file_shading_result = (filePath, s_sched.UniqueProcessedExternalFiles[filePath])
        var column_json: JSON = schedule_file_shading_result[1]["values"][0]
        rowCnt = column_json.size()
        if schedule_file_shading_result[1]["header"][-1].get[String]() == "()":
            var NumCSVAllColumnsSchedules: Int = schedule_file_shading_result[1]["header"].get[Set[String]]().size() - 1
            ShowWarningError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\" Removing last column of the CSV since it has '()' for the surface name.")
            ShowContinueError(state, "This was a problem in E+ 22.2.0 and below, consider removing it from the file to suppress this warning.")
            schedule_file_shading_result[1]["header"].pop(-1)
            assert(schedule_file_shading_result[1]["header"].size() == schedule_file_shading_result[1]["values"].size())
        if rowCnt != rowLimitCount:
            if rowCnt < rowLimitCount:
                ShowSevereError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\" {rowCnt} data values read.")
            elif rowCnt > rowLimitCount:
                ShowSevereError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\" too many data values read.")
            ShowContinueError(state, f"Number of rows in the shading file must be a full year multiplied by the simulation TimeStep: {rowLimitCount}.")
            ShowFatalError(state, "Program terminates due to previous condition.")
        s_sched.ScheduleFileShadingProcessed = True
        if numerrors > 0:
            ShowWarningError(state, f"{routineName}:{CurrentModuleObject}=\"{Alphas[0]}\" {numerrors} records had errors - these values are set to 0.")
    print(state.files.audit.ensure_open(state, "ProcessScheduleInput", state.files.outputControl.audit), "  Processing Schedule Input -- Start")
    CurrentModuleObject = "ScheduleTypeLimits"
    for Loop in range(1, NumScheduleTypes + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleTypeMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var schedType: Pointer[ScheduleType] = Pointer[ScheduleType].alloc()
        schedType[].Name = Alphas[0]
        schedType[].Num = Int(s_sched.scheduleTypes.size())
        s_sched.scheduleTypes.append(schedType)
        s_sched.scheduleTypeMap[schedType[].Name] = schedType[].Num
        schedType[].isLimited = not lNumericBlanks[0] and not lNumericBlanks[1]
        if not lNumericBlanks[0]:
            schedType[].minVal = Numbers[0]
        if not lNumericBlanks[1]:
            schedType[].maxVal = Numbers[1]
        if schedType[].isLimited:
            if Alphas[1] == "DISCRETE" or Alphas[1] == "INTEGER":
                schedType[].isReal = False
            elif Alphas[1] == "CONTINUOUS" or Alphas[1] == "REAL":
                schedType[].isReal = True
            else:
                ShowSevereInvalidKey(state, eoh, cAlphaFields[1], Alphas[1])
                ErrorsFound = True
        if NumAlphas >= 3 and not lAlphaBlanks[2]:
            schedType[].limitUnits = LimitUnits(getEnumValue(limitUnitNamesUC, Alphas[2]))
            if schedType[].limitUnits == LimitUnits.Invalid:
                ShowSevereInvalidKey(state, eoh, cAlphaFields[2], Alphas[2])
                ErrorsFound = True
        if schedType[].isLimited and schedType[].minVal > schedType[].maxVal:
            if schedType[].isReal:
                ShowSevereCustom(state, eoh, f"{cNumericFields[0]} [{schedType[].minVal:.2R}] > {cNumericFields[1]} [{schedType[].maxVal:.2R}].")
            else:
                ShowSevereCustom(state, eoh, f"{cNumericFields[0]} [{schedType[].minVal:.0R}] > {cNumericFields[1]} [{schedType[].maxVal:.0R}].")
            ShowContinueError(state, "  Other warning/severes about schedule values may appear.")
    Count = 0
    CurrentModuleObject = "Schedule:Day:Hourly"
    for Loop in range(1, NumHrDaySchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.dayScheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, Alphas[0])
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (daySched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        daySched[].interpolation = Interpolation.No
        for hr in range(Constant.iHoursInDay):
            for ts in range(s_glob.TimeStepsInHour):
                daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts] = Numbers[hr]
                daySched[].sumTsVals += daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts]
        if daySched[].checkValsForLimitViolations(state):
            ShowWarningCustom(state, eoh, f"Values are outside of range for {cAlphaFields[1]}={Alphas[1]}")
        if daySched[].checkValsForBadIntegers(state):
            ShowWarningCustom(state, eoh, f"One or more values are not integer in {cAlphaFields[1]}={Alphas[1]}")
    CurrentModuleObject = "Schedule:Day:Interval"
    for Loop in range(1, NumIntDaySchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.dayScheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, Alphas[0])
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (daySched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        NumFields = NumAlphas - 3
        if NumFields == 0:
            ShowSevereCustom(state, eoh, f"Insufficient data entered for a full schedule day.Number of interval fields == [{NumFields}].")
            ErrorsFound = True
        daySched[].interpolation = Interpolation(getEnumValue(interpolationNamesUC, Alphas[2]))
        if daySched[].interpolation == Interpolation.Invalid:
            ShowSevereInvalidKey(state, eoh, cAlphaFields[2], Alphas[2])
            ErrorsFound = True
        ProcessIntervalFields(state, Alphas[3:], Numbers, NumFields, NumNumbers, minuteVals, setMinuteVals, ErrorsFound, Alphas[0], CurrentModuleObject, daySched[].interpolation)
        daySched[].populateFromMinuteVals(state, minuteVals)
        if daySched[].checkValsForLimitViolations(state):
            ShowWarningCustom(state, eoh, f"Values are outside of range for {cAlphaFields[1]}={Alphas[1]}")
        if daySched[].checkValsForBadIntegers(state):
            ShowWarningCustom(state, eoh, f"One or more values are not integer in {cAlphaFields[1]}={Alphas[1]}")
    CurrentModuleObject = "Schedule:Day:List"
    for Loop in range(1, NumLstDaySchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.dayScheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, Alphas[0])
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (daySched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        daySched[].interpolation = Interpolation(getEnumValue(interpolationNamesUC, Alphas[2]))
        if Numbers[0] <= 0.0:
            ShowSevereCustom(state, eoh, f"Insufficient data entered for a full schedule day....Minutes per Item field = [{Numbers[0]}].")
            ErrorsFound = True
            continue
        if NumNumbers < 25:
            ShowSevereCustom(state, eoh, f"Insufficient data entered for a full schedule day....Minutes per Item field = [{Numbers[0]}] and only [{NumNumbers - 1}] to apply to list fields.")
            ErrorsFound = True
            continue
        MinutesPerItem = Int(Numbers[0])
        NumExpectedItems = 1440 / MinutesPerItem
        if (NumNumbers - 1) != NumExpectedItems:
            ShowSevereCustom(state, eoh, f"Number of Entered Items={NumNumbers - 1} not equal number of expected items={NumExpectedItems} based on {cNumericFields[0]}={MinutesPerItem}")
            ErrorsFound = True
            continue
        if Constant.iMinutesInHour % MinutesPerItem != 0:
            ShowSevereCustom(state, eoh, f"{cNumericFields[0]}={MinutesPerItem} not evenly divisible into 60")
            ErrorsFound = True
            continue
        var hr: Int = 0
        var begMin: Int = 0
        var endMin: Int = MinutesPerItem - 1
        for fieldNum in range(2, NumNumbers + 1):
            for iMin in range(begMin, endMin + 1):
                minuteVals[hr * Constant.iMinutesInHour + iMin] = Numbers[fieldNum - 1]
            begMin = endMin + 1
            endMin += MinutesPerItem
            if endMin >= Constant.iMinutesInHour:
                endMin = MinutesPerItem - 1
                begMin = 0
                hr += 1
        daySched[].populateFromMinuteVals(state, minuteVals)
        if daySched[].checkValsForLimitViolations(state):
            ShowWarningCustom(state, eoh, f"Values are outside of range for {cAlphaFields[1]}={Alphas[1]}")
        if daySched[].checkValsForBadIntegers(state):
            ShowWarningCustom(state, eoh, f"One or more values are not integer for {cAlphaFields[1]}={Alphas[1]}")
    CurrentModuleObject = "Schedule:Week:Daily"
    for Loop in range(1, NumRegWeekSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.weekScheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, Alphas[0])
        for iDayType in range(1, 13):
            var daySched: Pointer[DaySchedule] = GetDaySchedule(state, Alphas[iDayType])
            if daySched.is_null():
                ShowSevereItemNotFoundAudit(state, eoh, cAlphaFields[iDayType], Alphas[iDayType])
                ErrorsFound = True
            else:
                weekSched[].dayScheds[iDayType] = daySched
    Count = NumRegWeekSchedules
    CurrentModuleObject = "Schedule:Week:Compact"
    for Loop in range(1, NumCptWeekSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.weekScheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, Alphas[0])
        allDays.fill(False)
        for idx in range(2, NumAlphas + 1, 2):
            var daySched: Pointer[DaySchedule] = GetDaySchedule(state, Alphas[idx])
            if daySched.is_null():
                ShowSevereItemNotFoundAudit(state, eoh, cAlphaFields[idx], Alphas[idx])
                ShowContinueError(state, f"ref: {cAlphaFields[idx - 1]} \"{Alphas[idx - 1]}\"")
                ErrorsFound = True
            else:
                theseDays.fill(False)
                ErrorHere = False
                ProcessForDayTypes(state, Alphas[idx - 1], theseDays, allDays, ErrorHere)
                if ErrorHere:
                    ShowContinueError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\"")
                    ErrorsFound = True
                else:
                    for iDayType in range(1, 13):
                        if theseDays[iDayType]:
                            weekSched[].dayScheds[iDayType] = daySched
        for iDayType in range(iDayType_Sun, 13):
            if allDays[iDayType]:
                continue
            ShowSevereError(state, f"{routineName}: {CurrentModuleObject}=\"{Alphas[0]}\", Missing some day assignments")
            ErrorsFound = True
            break
    NumRegWeekSchedules = Count
    CurrentModuleObject = "Schedule:Year"
    for Loop in range(1, NumRegSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        var NumPointer: Int = 0
        var daysInYear: StaticTuple[Int, 367] = StaticTuple[Int, 367]()
        daysInYear.fill(0)
        for idx in range(3, NumAlphas + 1):
            var weekSched: Pointer[WeekSchedule] = GetWeekSchedule(state, Alphas[idx - 1])
            if weekSched.is_null():
                ShowSevereItemNotFoundAudit(state, eoh, cAlphaFields[idx - 1], Alphas[idx - 1])
                ErrorsFound = True
                continue
            var StartMonth: Int = Int(Numbers[NumPointer])
            var StartDay: Int = Int(Numbers[NumPointer + 1])
            var endMonth: Int = Int(Numbers[NumPointer + 2])
            var endDay: Int = Int(Numbers[NumPointer + 3])
            NumPointer += 4
            var startPointer: Int = OrdinalDay(StartMonth, StartDay, 1)
            var endPointer: Int = OrdinalDay(endMonth, endDay, 1)
            if startPointer <= endPointer:
                for day in range(startPointer, endPointer + 1):
                    daysInYear[day] += 1
                    sched[].weekScheds[day] = weekSched
            else:
                for day in range(startPointer, 367):
                    daysInYear[day] += 1
                    sched[].weekScheds[day] = weekSched
                for day in range(1, endPointer + 1):
                    daysInYear[day] += 1
                    sched[].weekScheds[day] = weekSched
        if daysInYear[60] == 0:
            daysInYear[60] = daysInYear[59]
            sched[].weekScheds[60] = sched[].weekScheds[59]
        for iDay in range(1, 367):
            if daysInYear[iDay] == 0:
                ShowSevereCustomAudit(state, eoh, "has missing days in its schedule pointers")
                ErrorsFound = True
                break
            if daysInYear[iDay] > 1:
                ShowSevereCustomAudit(state, eoh, "has overlapping days in its schedule pointers")
                ErrorsFound = True
                break
        if s_glob.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Schedule:Year", sched[].Name, "Schedule Value", "[ ]", sched[].EMSActuatedOn, sched[].EMSVal)
    var daySchedAlwaysOff: Pointer[DaySchedule] = s_sched.daySchedules[SchedNum_AlwaysOff]
    daySchedAlwaysOff[].tsVals = List[Float64](repeating=0.0, count=Constant.iHoursInDay * s_glob.TimeStepsInHour)
    SchNum = NumRegSchedules
    CurrentModuleObject = "Schedule:Compact"
    for Loop in range(1, NumCptSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        sched[].type = SchedType.Compact
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        var daysInYear: StaticTuple[Int, 367] = StaticTuple[Int, 367]()
        daysInYear.fill(0)
        NumField = 3
        StartPointer = 1
        WkCount = 0
        DyCount = 0
        var FullYearSet: Bool = False
        while NumField < NumAlphas:
            if not has_prefix(Alphas[NumField - 1], "THROUGH:") and not has_prefix(Alphas[NumField - 1], "THROUGH"):
                ShowSevereCustom(state, eoh, f"Expecting \"Through:\" date, instead found entry={Alphas[NumField - 1]}")
                ErrorsFound = True
                goto Through_exit
            var sPos: Int = 8 if Alphas[NumField - 1][7] == ':' else 7
            Alphas[NumField - 1] = Alphas[NumField - 1][sPos:]
            Alphas[NumField - 1] = strip(Alphas[NumField - 1])
            CurrentThrough = Alphas[NumField - 1]
            ErrorHere = False
            ProcessDateString(state, Alphas[NumField - 1], EndMonth, EndDay, PWeekDay, PDateType, ErrorHere)
            if PDateType == Weather.DateType.NthDayInMonth or PDateType == Weather.DateType.LastDayInMonth:
                ShowSevereCustom(state, eoh, f"Invalid \"Through:\" date, found entry={Alphas[NumField - 1]}")
                ErrorsFound = True
                goto Through_exit
            if ErrorHere:
                ShowSevereCustom(state, eoh, "Invalid \"Through:\" date")
                ErrorsFound = True
                goto Through_exit
            EndPointer = OrdinalDay(EndMonth, EndDay, 1)
            if EndPointer == 366:
                if FullYearSet:
                    ShowSevereCustom(state, eoh, f"New \"Through\" entry when \"full year\" already set \"Through\" field={CurrentThrough}")
                    ErrorsFound = True
                FullYearSet = True
            WkCount += 1
            var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{Alphas[0]}_wk_{WkCount}")
            weekSched[].isUsed = True
            for iDay in range(StartPointer, EndPointer + 1):
                sched[].weekScheds[iDay] = weekSched
                daysInYear[iDay] += 1
            StartPointer = EndPointer + 1
            ThruField = NumField
            allDays.fill(False)
            NumField += 1
            while NumField < NumAlphas:
                if has_prefix(Alphas[NumField - 1], "THROUGH"):
                    goto For_exit
                if not has_prefix(Alphas[NumField - 1], "FOR"):
                    ShowSevereCustom(state, eoh, f"Looking for \"For\" field, found={Alphas[NumField - 1]}")
                    ErrorsFound = True
                    goto Through_exit
                DyCount += 1
                var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{Alphas[0]}_dy_{DyCount}")
                daySched[].schedTypeNum = sched[].schedTypeNum
                daySched[].isUsed = True
                theseDays.fill(False)
                ErrorHere = False
                LastFor = Alphas[NumField - 1]
                ProcessForDayTypes(state, Alphas[NumField - 1], theseDays, allDays, ErrorHere)
                if ErrorHere:
                    ShowContinueError(state, f"ref {CurrentModuleObject}=\"{Alphas[0]}\"")
                    ShowContinueError(state, f"ref Through field={Alphas[ThruField - 1]}")
                    ErrorsFound = True
                else:
                    for iDayType in range(1, 13):
                        if theseDays[iDayType]:
                            weekSched[].dayScheds[iDayType] = daySched
                NumField += 1
                if has_prefix(Alphas[NumField - 1], "INTERPOLATE") or not has_prefix(Alphas[NumField - 1], "UNTIL"):
                    if has(Alphas[NumField - 1], "NO"):
                        daySched[].interpolation = Interpolation.No
                    elif has(Alphas[NumField - 1], "AVERAGE"):
                        daySched[].interpolation = Interpolation.Average
                    elif has(Alphas[NumField - 1], "LINEAR"):
                        daySched[].interpolation = Interpolation.Linear
                    else:
                        ShowSevereInvalidKey(state, eoh, cAlphaFields[NumField - 1], Alphas[NumField - 1])
                        ErrorsFound = True
                    NumField += 1
                NumNumbers = 0
                xxcount = 0
                UntilFld = NumField
                while True:
                    if has_prefix(Alphas[NumField - 1], "FOR"):
                        break
                    if has_prefix(Alphas[NumField - 1], "THROUGH"):
                        break
                    if has_prefix(Alphas[NumField - 1], "UNTIL"):
                        NumField += 1
                        xxcount += 1
                        NumNumbers += 1
                        Numbers[NumNumbers - 1] = Util.ProcessNumber(Alphas[NumField - 1], ErrorHere)
                        if ErrorHere:
                            ShowSevereCustom(state, eoh, f"Until field=[{Alphas[NumField - 2]}] has illegal value field=[{Alphas[NumField - 1]}].")
                            ErrorsFound = True
                        NumField += 1
                        Alphas[UntilFld - 1 + xxcount] = Alphas[NumField - 1]
                    else:
                        ShowSevereCustom(state, eoh, f"Looking for \"Until\" field, found={Alphas[NumField - 1]}")
                        ErrorsFound = True
                        goto Through_exit
                    if Alphas[NumField - 1] == "":
                        break
                if NumNumbers > 0:
                    NumFields = NumNumbers
                    ErrorHere = False
                    ProcessIntervalFields(state, Alphas[UntilFld - 1:], Numbers, NumFields, NumNumbers, minuteVals, setMinuteVals, ErrorHere, daySched[].Name, CurrentModuleObject + " DaySchedule Fields", daySched[].interpolation)
                    if ErrorHere:
                        ShowContinueError(state, f"ref {CurrentModuleObject}=\"{Alphas[0]}\"")
                        ErrorsFound = True
                    daySched[].populateFromMinuteVals(state, minuteVals)
            For_exit:
            for iDayType in range(iDayType_Sun, 13):
                if allDays[iDayType]:
                    continue
                ShowWarningCustom(state, eoh, f"has missing day types in Through={CurrentThrough}")
                ShowContinueError(state, f"Last \"For\" field={LastFor}")
                var errmsg: String = "Missing day types=,"
                for kDayType in range(iDayType_Sun, 13):
                    if allDays[kDayType]:
                        continue
                    errmsg = errmsg[:-1]
                    errmsg = f"{errmsg} \"{dayTypeNames[kDayType]}\",-"
                errmsg = errmsg[:-2]
                ShowContinueError(state, errmsg)
                ShowContinueError(state, "Missing day types will have 0.0 as Schedule Values")
                break
        Through_exit:
        if daysInYear[60] == 0:
            daysInYear[60] = daysInYear[59]
            sched[].weekScheds[60] = sched[].weekScheds[59]
        if 0 in daysInYear[1:]:
            ShowSevereCustomAudit(state, eoh, "has missing days in its schedule pointers")
            ErrorsFound = True
        if any(d > 1 for d in daysInYear[1:]):
            ShowSevereCustomAudit(state, eoh, "has overlapping days in its schedule pointers")
            ErrorsFound = True
        if s_glob.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Schedule:Compact", sched[].Name, "Schedule Value", "[ ]", sched[].EMSActuatedOn, sched[].EMSVal)
    CurrentModuleObject = "Schedule:File"
    for Loop in range(1, NumCommaFileSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        sched[].type = SchedType.File
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        curcolCount = Int(Numbers[0])
        skiprowCount = Int(Numbers[1])
        if Numbers[2] == 0.0:
            Numbers[2] = 8760.0
        if Numbers[2] != 8760.0 and Numbers[2] != 8784.0:
            ShowSevereCustom(state, eoh, f"{cNumericFields[2]} must = 8760 or 8784 (for a leap year).  Value = {Numbers[2]:.0f}, Schedule not processed.")
            ErrorsFound = True
            continue
        if lAlphaBlanks[3] or Util.SameString(Alphas[3], "comma"):
            ColumnSep = CharComma
            Alphas[3] = "comma"
        elif Util.SameString(Alphas[3], "semicolon"):
            ColumnSep = CharSemicolon
        elif Util.SameString(Alphas[3], "tab"):
            ColumnSep = CharTab
        elif Util.SameString(Alphas[3], "space"):
            ColumnSep = CharSpace
        else:
            ShowSevereInvalidKey(state, eoh, cAlphaFields[3], Alphas[3], "..must be Comma, Semicolon, Tab, or Space.")
            ErrorsFound = True
            continue
        var interp: Interpolation = Interpolation.No
        if not lAlphaBlanks[4]:
            var bs: BooleanSwitch = getYesNoValue(Alphas[4])
            if bs != BooleanSwitch.Invalid:
                interp = Interpolation.Average if Bool(bs) else Interpolation.Linear
            else:
                ShowSevereInvalidKey(state, eoh, cAlphaFields[4], Alphas[4])
                ErrorsFound = True
        sched[].UseDaylightSaving = True
        if Alphas[5] == "NO":
            sched[].UseDaylightSaving = False
        var minutesPerItem: Int = Constant.iMinutesInHour
        if NumNumbers > 3:
            minutesPerItem = Int(Numbers[3])
            if Constant.iMinutesInHour % minutesPerItem != 0:
                ShowSevereCustom(state, eoh, f"Requested {cNumericFields[3]} field value ({minutesPerItem}) not evenly divisible into 60")
                ErrorsFound = True
                continue
        var numHourlyValues: Int = Int(Numbers[2])
        var rowLimitCnt: Int = (Int(Numbers[2]) * Constant.rMinutesInHour) / minutesPerItem
        var hrLimitCount: Int = Constant.iMinutesInHour / minutesPerItem
        var contextString: String = f"{CurrentModuleObject}=\"{Alphas[0]}\", {cAlphaFields[2]}: "
        state.files.TempFullFilePath.filePath = CheckForActualFilePath(state, Alphas[2], contextString)
        if state.files.TempFullFilePath.filePath == "":
            ErrorsFound = True
        else:
            var filePath: String = state.files.TempFullFilePath.filePath
            var result: Tuple[String, JSON]
            if filePath not in s_sched.UniqueProcessedExternalFiles:
                var ext: FileTypes = getFileType(filePath)
                if is_flat_file_type(ext):
                    var schedule_data: String = readFile(filePath)
                    var csvParser: CsvParser = CsvParser()
                    var it: Tuple[String, JSON] = (filePath, csvParser.decode(schedule_data, ColumnSep, skiprowCount))
                    s_sched.UniqueProcessedExternalFiles[it[0]] = it[1]
                    if csvParser.hasErrors():
                        for (error, isContinued) in csvParser.errors():
                            if isContinued:
                                ShowContinueError(state, error)
                            else:
                                ShowSevereCustom(state, eoh, error)
                        ShowContinueError(state, f"Error Occurred in {filePath}")
                        ShowFatalError(state, "Program terminates due to previous condition.")
                    for (warning, isContinued) in csvParser.warnings():
                        if isContinued:
                            ShowContinueError(state, warning)
                        else:
                            ShowWarningCustom(state, eoh, warning)
                    result = it
                elif is_all_json_type(ext):
                    var schedule_data: JSON = readJSON(filePath)
                    s_sched.UniqueProcessedExternalFiles[filePath] = schedule_data
                    result = (filePath, schedule_data)
                else:
                    var isCSV: Bool = False
                    var isJSON: Bool = False
                    try:
                        var schedule_data: String = readFile(filePath)
                        var csvParser: CsvParser = CsvParser()
                        var it: Tuple[String, JSON] = (filePath, csvParser.decode(schedule_data, ColumnSep, skiprowCount))
                        if not csvParser.hasErrors():
                            result = it
                            isCSV = True
                            ShowWarningMessage(state, f"Extension of file {filePath} is unrecognized, but parsed as CSV successfully")
                    except:
                        isCSV = False
                    if not isCSV:
                        try:
                            var schedule_data: JSON = readJSON(filePath)
                            s_sched.UniqueProcessedExternalFiles[filePath] = schedule_data
                            result = (filePath, schedule_data)
                            ShowWarningMessage(state, f"Extension of file {filePath} is unrecognized, but parsed as JSON successfully")
                            isJSON = True
                        except:
                            isJSON = False
                    if not isCSV and not isJSON:
                        ShowSevereCustom(state, eoh, f"{cAlphaFields[2]} = {Alphas[2]} has an unknown file extension and cannot be read by this program.")
                        ShowFatalError(state, "Program terminates due to previous condition.")
            else:
                result = (filePath, s_sched.UniqueProcessedExternalFiles[filePath])
            if curcolCount > result[1]["values"].size():
                ShowSevereCustom(state, eoh, f"Requested column number {curcolCount}, but found only {result[1]['values'].size()} columns.")
                ShowContinueError(state, f"Error Occurred in {filePath}")
                ShowFatalError(state, "Program terminates due to previous condition.")
            var column_json: JSON = result[1]["values"][curcolCount - 1]
            rowCnt = column_json.size()
            var column_values: List[Float64] = List[Float64]()
            try:
                column_values = column_json.get[List[Float64]]()
            except e:
                ShowSevereCustom(state, eoh, f"Column number {curcolCount} has non-numeric data.")
                ShowContinueError(state, e.what())
                ShowContinueError(state, f"Error Occurred in {filePath}")
                ShowFatalError(state, "Program terminates due to previous condition.")
            if numerrors > 0:
                ShowWarningCustom(state, eoh, f"{numerrors} records had errors - these values are set to 0. Use Output:Diagnostics,DisplayExtraWarnings; to see individual records in error.")
            if rowCnt < rowLimitCnt:
                ShowWarningCustom(state, eoh, f"less than {numHourlyValues} hourly values read from file...Number read={(rowCnt * Constant.iMinutesInHour) / minutesPerItem}.")
            var iDay: Int = 0
            var hDay: Int = 0
            var ifld: Int = 0
            while True:
                iDay += 1
                hDay += 1
                if iDay > 366:
                    break
                var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{Alphas[0]}_dy_{iDay}")
                daySched[].schedTypeNum = sched[].schedTypeNum
                var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{Alphas[0]}_wk_{iDay}")
                for kDayType in range(1, 13):
                    weekSched[].dayScheds[kDayType] = daySched
                sched[].weekScheds[iDay] = weekSched
                if minutesPerItem == Constant.iMinutesInHour:
                    for hr in range(Constant.iHoursInDay):
                        var curHrVal: Float64 = column_values[ifld]
                        ifld += 1
                        for ts in range(s_glob.TimeStepsInHour):
                            daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts] = curHrVal
                            daySched[].sumTsVals += daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts]
                else:
                    for hr in range(Constant.iHoursInDay):
                        var endMin: Int = minutesPerItem - 1
                        var begMin: Int = 0
                        for fieldIdx in range(1, hrLimitCount + 1):
                            for iMin in range(begMin, endMin + 1):
                                minuteVals[hr * Constant.iMinutesInHour + iMin] = column_values[ifld]
                            ifld += 1
                            begMin = endMin + 1
                            endMin += minutesPerItem
                    daySched[].interpolation = interp
                    daySched[].populateFromMinuteVals(state, minuteVals)
                if iDay == 59 and rowCnt < 8784 * hrLimitCount:
                    iDay += 1
                    sched[].weekScheds[iDay] = sched[].weekScheds[iDay - 1]
        if s_glob.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Schedule:File", sched[].Name, "Schedule Value", "[ ]", sched[].EMSActuatedOn, sched[].EMSVal)
    if NumCommaFileShading != 0:
        var values_json: JSON = schedule_file_shading_result[1]["values"]
        var headers: List[String] = schedule_file_shading_result[1]["header"].get[List[String]]()
        var headers_set: Set[String] = schedule_file_shading_result[1]["header"].get[Set[String]]()
        var shadingFileName: String = Path(schedule_file_shading_result[0]).filename().string()
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, "Schedule:File:Shading", shadingFileName)
        for header in headers_set:
            var column: Int = 0
            var column_it: Int = headers.find(header)
            if column_it != -1:
                column = column_it
            if column == 0:
                continue
            if column >= values_json.size():
                ShowSevereCustom(state, eoh, f"For header '{header}', Requested column number {column + 1}, but found only {values_json.size()} columns.")
                ShowContinueError(state, f"Error Occurred in {schedule_file_shading_result[0]}")
                ShowFatalError(state, "Program terminates due to previous condition.")
            var column_values: List[Float64] = List[Float64]()
            try:
                column_values = values_json[column].get[List[Float64]]()
            except e:
                ShowSevereCustom(state, eoh, f"Column number {column + 1} has non-numeric data.")
                ShowContinueError(state, e.what())
                ShowContinueError(state, f"Error Occurred in {schedule_file_shading_result[0]}")
                ShowFatalError(state, "Program terminates due to previous condition.")
            var curName: String = f"{header}_shading"
            var curNameUC: String = Util.makeUPPER(curName)
            if curNameUC in s_sched.scheduleMap:
                ShowSevereError(state, f"Duplicate schedule name {curName}")
                ErrorsFound = True
                continue
            var schedShading: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, curName)
            schedShading[].type = SchedType.File
            var iDay: Int = 0
            var ifld: Int = 0
            while True:
                iDay += 1
                if iDay > 366:
                    break
                var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{curName}_dy_{iDay}")
                daySched[].schedTypeNum = schedShading[].schedTypeNum
                var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{curName}_wk_{iDay}")
                for kDayType in range(1, 13):
                    weekSched[].dayScheds[kDayType] = daySched
                schedShading[].weekScheds[iDay] = weekSched
                for hr in range(Constant.iHoursInDay):
                    for ts in range(s_glob.TimeStepsInHour):
                        daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts] = column_values[ifld]
                        ifld += 1
                if iDay == 59 and not state.dataEnvrn.CurrentYearIsLeapYear:
                    iDay += 1
                    schedShading[].weekScheds[iDay] = schedShading[].weekScheds[iDay - 1]
    CurrentModuleObject = "Schedule:Constant"
    for Loop in range(1, NumConstantSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleConstant] = AddScheduleConstant(state, Alphas[0], Numbers[0])
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        if s_glob.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Schedule:Constant", sched[].Name, "Schedule Value", "[ ]", sched[].EMSActuatedOn, sched[].EMSVal)
    var schedAlwaysOff: Pointer[ScheduleConstant] = Pointer[ScheduleConstant](s_sched.schedules[SchedNum_AlwaysOff])
    schedAlwaysOff[].tsVals = List[Float64](repeating=0.0, count=Constant.iHoursInDay * s_glob.TimeStepsInHour)
    var schedAlwaysOn: Pointer[ScheduleConstant] = Pointer[ScheduleConstant](s_sched.schedules[SchedNum_AlwaysOn])
    schedAlwaysOn[].tsVals = List[Float64](repeating=1.0, count=Constant.iHoursInDay * s_glob.TimeStepsInHour)
    CurrentModuleObject = "ExternalInterface:Schedule"
    for Loop in range(1, NumExternalInterfaceSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        sched[].type = SchedType.External
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{Alphas[0]}_xi_dy_")
        daySched[].isUsed = True
        daySched[].schedTypeNum = sched[].schedTypeNum
        if NumNumbers < 1:
            ShowWarningCustom(state, eoh, "Initial value is not numeric or is missing. Fix idf file.")
        ExternalInterfaceSetSchedule(state, daySched[].Num, Numbers[0])
        var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{Alphas[0]}_xi_wk_")
        weekSched[].isUsed = True
        for iDayType in range(1, 13):
            weekSched[].dayScheds[iDayType] = daySched
        for iDay in range(1, 367):
            sched[].weekScheds[iDay] = weekSched
    CurrentModuleObject = "ExternalInterface:FunctionalMockupUnitImport:To:Schedule"
    for Loop in range(1, NumExternalInterfaceFunctionalMockupUnitImportSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            if NumExternalInterfaceSchedules >= 1:
                ShowContinueError(state, f"{cAlphaFields[0]} defined as an ExternalInterface:Schedule and ExternalInterface:FunctionalMockupUnitImport:To:Schedule. This will cause the schedule to be overwritten by PtolemyServer and FunctionalMockUpUnitImport)")
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        sched[].type = SchedType.External
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{Alphas[0]}_xi_dy_")
        daySched[].isUsed = True
        daySched[].schedTypeNum = sched[].schedTypeNum
        if NumNumbers < 1:
            ShowWarningCustom(state, eoh, "Initial value is not numeric or is missing. Fix idf file.")
        ExternalInterfaceSetSchedule(state, daySched[].Num, Numbers[0])
        var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{Alphas[0]}_xi_wk_")
        weekSched[].isUsed = True
        for iDayType in range(1, 13):
            weekSched[].dayScheds[iDayType] = daySched
        for iDay in range(1, 367):
            sched[].weekScheds[iDay] = weekSched
    CurrentModuleObject = "ExternalInterface:FunctionalMockupUnitExport:To:Schedule"
    for Loop in range(1, NumExternalInterfaceFunctionalMockupUnitExportSchedules + 1):
        s_ip.getObjectItem(state, CurrentModuleObject, Loop, Alphas, NumAlphas, Numbers, NumNumbers, Status, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        if Alphas[0] in s_sched.scheduleMap:
            ShowSevereDuplicateName(state, eoh)
            if NumExternalInterfaceSchedules >= 1:
                ShowContinueError(state, f"{cAlphaFields[0]} defined as an ExternalInterface:Schedule and ExternalInterface:FunctionalMockupUnitImport:To:Schedule. This will cause the schedule to be overwritten by PtolemyServer and FunctionalMockUpUnitImport)")
            ErrorsFound = True
            continue
        var sched: Pointer[ScheduleDetailed] = AddScheduleDetailed(state, Alphas[0])
        sched[].type = SchedType.External
        if lAlphaBlanks[1]:
            ShowWarningEmptyField(state, eoh, cAlphaFields[1])
            ShowContinueError(state, "Schedule will not be validated.")
        elif (sched[].schedTypeNum = GetScheduleTypeNum(state, Alphas[1])) == SchedNum_Invalid:
            ShowWarningItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
            ShowContinueError(state, "Schedule will not be validated.")
        var daySched: Pointer[DaySchedule] = AddDaySchedule(state, f"{Alphas[0]}_xi_dy_")
        daySched[].isUsed = True
        daySched[].schedTypeNum = sched[].schedTypeNum
        if NumNumbers < 1:
            ShowWarningCustom(state, eoh, "Initial value is not numeric or is missing. Fix idf file.")
        ExternalInterfaceSetSchedule(state, daySched[].Num, Numbers[0])
        var weekSched: Pointer[WeekSchedule] = AddWeekSchedule(state, f"{Alphas[0]}_xi_wk_")
        weekSched[].isUsed = True
        for iDayType in range(1, 13):
            weekSched[].dayScheds[iDayType] = daySched
        for iDay in range(1, 367):
            sched[].weekScheds[iDay] = weekSched
    for sched in s_sched.schedules:
        if sched[].schedTypeNum == SchedNum_Invalid:
            continue
        var schedType = s_sched.scheduleTypes[sched[].schedTypeNum]
        if not schedType[].isLimited:
            continue
        if not sched[].checkMinMaxVals(state, Clusive.In, schedType[].minVal, Clusive.In, schedType[].maxVal):
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, "Schedule", sched[].Name)
            ShowSevereBadMinMax(state, eoh, "", "", Clusive.In, schedType[].minVal, Clusive.In, schedType[].maxVal)
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, f"{routineName}: Preceding Errors cause termination.")
    if s_sched.scheduleTypes.size() + s_sched.daySchedules.size() + s_sched.weekSchedules.size() + s_sched.schedules.size() > 0:
        CurrentModuleObject = "Output:Schedules"
        NumFields = s_ip.getNumObjectsFound(state, CurrentModuleObject)
        if NumFields > 0:
            ReportScheduleTypeLimits(state)
        var reportLevelSet: Set[ReportLevel] = Set[ReportLevel]()
        for count in range(1, NumFields + 1):
            s_ip.getObjectItem(state, CurrentModuleObject, count, Alphas, NumAlphas, Numbers, NumNumbers, Status)
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
            var reportLevel: ReportLevel = ReportLevel(getEnumValue(reportLevelNamesUC, Alphas[0]))
            if reportLevel == ReportLevel.Invalid:
                ShowWarningInvalidKey(state, eoh, cAlphaFields[0], Alphas[0], "HOURLY report will be done")
                reportLevel = ReportLevel.Hourly
            if reportLevel not in reportLevelSet:
                reportLevelSet.add(reportLevel)
                ReportScheduleDetails(state, reportLevel)
            else:
                ShowWarningCustom(state, eoh, f"Report level {reportLevelNames[Int(reportLevel)]} has already been processed. This report level will not be processed again.")
                continue
    Alphas = List[String]()
    cAlphaFields = List[String]()
    cNumericFields = List[String]()
    Numbers = List[Float64]()
    lAlphaBlanks = List[Bool]()
    lNumericBlanks = List[Bool]()
    print(state.files.audit, "  Processing Schedule Input -- Complete")

def ReportScheduleTypeLimits(inout state: EnergyPlusData) -> None:
    var YesNoLimited: String
    var minValStr: String
    var maxValStr: String
    var YesNoContinous: String
    let scheduleTypeLimitTableName: StringLiteral = "ScheduleTypeLimits"
    print(state.files.eio, f"! <{scheduleTypeLimitTableName}>,Name,Limited? {{Yes/No}},Minimum,Maximum,Continuous? {{Yes/No - Discrete}}")
    for schedType in state.dataSched.scheduleTypes:
        if schedType[].isLimited:
            YesNoLimited = "Yes"
            minValStr = f"{schedType[].minVal:.2R}"
            minValStr = strip(minValStr)
            maxValStr = f"{schedType[].maxVal:.2R}"
            maxValStr = strip(maxValStr)
            if schedType[].isReal:
                YesNoContinous = "Yes"
            else:
                YesNoContinous = "No"
                minValStr = String(Int(schedType[].minVal))
                maxValStr = String(Int(schedType[].maxVal))
        else:
            YesNoLimited = "No"
            minValStr = "N/A"
            maxValStr = "N/A"
            YesNoContinous = "N/A"
        print(state.files.eio, f"{scheduleTypeLimitTableName},{schedType[].Name},{YesNoLimited},{minValStr},{maxValStr},{YesNoContinous}")

def ReportScheduleDetails(inout state: EnergyPlusData, LevelOfDetail: ReportLevel) -> None:
    assert(LevelOfDetail != ReportLevel.Invalid)
    let Months: StaticTuple[StringLiteral, 12] = StaticTuple("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
    let HrField: StaticTuple[StringLiteral, 25] = StaticTuple("00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24")
    var s_glob = state.dataGlobal
    var s_sched = state.dataSched
    var times: List[String] = List[String]()
    var NumTimesInDay: Int = (s_glob.TimeStepsInHour * Constant.iHoursInDay) if LevelOfDetail == ReportLevel.TimeStep else Constant.iHoursInDay
    if LevelOfDetail == ReportLevel.TimeStep:
        times.reserve(NumTimesInDay)
    elif LevelOfDetail == ReportLevel.Hourly:
        times.reserve(NumTimesInDay)
    else:
        assert(False)
    for hr in range(Constant.iHoursInDay):
        if LevelOfDetail == ReportLevel.TimeStep:
            for ts in range(s_glob.TimeStepsInHour - 1):
                times.append(f"{HrField[hr]}:{(ts + 1) * s_glob.MinutesInTimeStep:02}")
        times.append(f"{HrField[hr + 1]}:00")
    assert(Int(times.size()) == NumTimesInDay)
    var reportLevelName: StringLiteral = reportLevelNames[Int(LevelOfDetail)]
    var dayScheduleTableName: String = f"Day Schedule - {reportLevelName}"
    var weekScheduleTableName: String = f"WeekSchedule - {reportLevelName}"
    var scheduleTableName: String = f"Schedule - {reportLevelName}"
    print(state.files.eio, f"! Schedule Details Report={reportLevelName} =====================")
    print(state.files.eio, f"! <{dayScheduleTableName}>,Name,ScheduleType,Interpolated {{Average/Linear/No}},Time (HH:MM) =>", end="")
    for time in times:
        print(state.files.eio, f",{time}", end="")
    print(state.files.eio, "")
    print(state.files.eio, f"! <{weekScheduleTableName}>,Name", end="")
    for Count in range(1, 13):
        print(state.files.eio, f",{dayTypeNames[Count]}", end="")
    print(state.files.eio, "")
    print(state.files.eio, f"! <{scheduleTableName}>,Name,ScheduleType,Until Date 1,WeekSchedule 1,Until Date 2,WeekSchedule 2,Until Date 3,WeekSchedule 3,Until Date 4,WeekSchedule 4,Until Date 5,WeekSchedule 5,Until Date 6,WeekSchedule 6,Until Date 7,WeekSchedule 7,Until Date 8,WeekSchedule 8,Until Date 9,WeekSchedule 9,")
    for daySched in s_sched.daySchedules:
        print(state.files.eio, f"{dayScheduleTableName},{daySched[].Name},{(s_sched.scheduleTypes[daySched[].schedTypeNum].Name if daySched[].schedTypeNum != SchedNum_Invalid else '')},{interpolationNames[Int(daySched[].interpolation)]},Values:", end="")
        if LevelOfDetail == ReportLevel.Hourly:
            for hr in range(Constant.iHoursInDay):
                print(state.files.eio, f",{daySched[].tsVals[(hr + 1) * s_glob.TimeStepsInHour - 1]:.2R}", end="")
        elif LevelOfDetail == ReportLevel.TimeStep:
            for hr in range(Constant.iHoursInDay):
                for ts in range(s_glob.TimeStepsInHour):
                    print(state.files.eio, f",{daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts]:.2R}", end="")
        else:
            assert(False)
        print(state.files.eio, "")
    for weekSched in s_sched.weekSchedules:
        print(state.files.eio, f"{weekScheduleTableName},{weekSched[].Name}", end="")
        for DayNum in range(1, 13):
            print(state.files.eio, f",{weekSched[].dayScheds[DayNum][].Name}", end="")
        print(state.files.eio, "")
    for sched in s_sched.schedules:
        if sched[].type == SchedType.Constant:
            continue
        var schedDetailed: Pointer[ScheduleDetailed] = Pointer[ScheduleDetailed](sched)
        assert(not schedDetailed.is_null())
        print(state.files.eio, f"{scheduleTableName},{schedDetailed[].Name},{(s_sched.scheduleTypes[sched[].schedTypeNum].Name if sched[].schedTypeNum != SchedNum_Invalid else '')}", end="")
        var PMon: Int = 0
        var PDay: Int = 0
        let ThruFmt: StringLiteral = ",Through {} {:02},{}"
        var DayNum: Int = 1
        while DayNum <= 366:
            var weekSched = schedDetailed[].weekScheds[DayNum]
            while DayNum <= 366 and schedDetailed[].weekScheds[DayNum] == weekSched:
                if DayNum == 366:
                    InvOrdinalDay(DayNum, PMon, PDay, 1)
                    print(state.files.eio, f",Through {Months[PMon - 1]} {PDay:02},{weekSched[].Name}", end="")
                DayNum += 1
                if DayNum > 366:
                    break
            if DayNum <= 366:
                InvOrdinalDay(DayNum - 1, PMon, PDay, 1)
                print(state.files.eio, f",Through {Months[PMon - 1]} {PDay:02},{weekSched[].Name}", end="")
        print(state.files.eio, "")

def GetCurrentScheduleValue(state: EnergyPlusData, schedNum: Int) -> Float64:
    return state.dataSched.schedules[schedNum][].getCurrentVal()

def UpdateScheduleVals(inout state: EnergyPlusData) -> None:
    var s_sched = state.dataSched
    var s_glob = state.dataGlobal
    for sched in s_sched.schedules:
        if sched[].EMSActuatedOn:
            sched[].currentVal = sched[].EMSVal
        else:
            sched[].currentVal = sched[].getHrTsVal(state, s_glob.HourOfDay, s_glob.TimeStep)

def GetScheduleAlwaysOn(state: EnergyPlusData) -> Pointer[Schedule]:
    return state.dataSched.schedules[SchedNum_AlwaysOn]

def GetScheduleAlwaysOff(state: EnergyPlusData) -> Pointer[Schedule]:
    return state.dataSched.schedules[SchedNum_AlwaysOff]

def GetSchedule(inout state: EnergyPlusData, name: String) -> Pointer[Schedule]:
    var s_sched = state.dataSched
    var found: Optional[Int] = s_sched.scheduleMap.get(name)
    if not found:
        return Pointer[Schedule]()
    var schedNum: Int = found.value()
    var sched: Pointer[Schedule] = s_sched.schedules[schedNum]
    if not sched[].isUsed:
        sched[].isUsed = True
        if sched[].type != SchedType.Constant:
            var schedDetailed: Pointer[ScheduleDetailed] = Pointer[ScheduleDetailed](sched)
            assert(not schedDetailed.is_null())
            schedDetailed[].isUsed = True
            for iWeek in range(1, 367):
                var weekSched = schedDetailed[].weekScheds[iWeek]
                if not weekSched.is_null():
                    if weekSched[].isUsed:
                        continue
                    weekSched[].isUsed = True
                    for iDayType in range(1, 13):
                        var daySched = weekSched[].dayScheds[iDayType]
                        daySched[].isUsed = True
    return sched

def GetScheduleNum(inout state: EnergyPlusData, name: String) -> Int:
    var sched: Pointer[Schedule] = GetSchedule(state, name)
    return sched[].Num if not sched.is_null() else -1

def GetWeekSchedule(inout state: EnergyPlusData, name: String) -> Pointer[WeekSchedule]:
    var s_sched = state.dataSched
    var found: Optional[Int] = s_sched.weekScheduleMap.get(name)
    if not found:
        return Pointer[WeekSchedule]()
    var weekSchedNum: Int = found.value()
    var weekSched: Pointer[WeekSchedule] = s_sched.weekSchedules[weekSchedNum]
    if not weekSched[].isUsed:
        weekSched[].isUsed = True
        for iDayType in range(1, 13):
            var daySched = weekSched[].dayScheds[iDayType]
            daySched[].isUsed = True
    return weekSched

def GetWeekScheduleNum(inout state: EnergyPlusData, name: String) -> Int:
    var weekSched: Pointer[WeekSchedule] = GetWeekSchedule(state, name)
    return weekSched[].Num if not weekSched.is_null() else -1

def GetDaySchedule(inout state: EnergyPlusData, name: String) -> Pointer[DaySchedule]:
    var s_sched = state.dataSched
    var found: Optional[Int] = s_sched.dayScheduleMap.get(name)
    if not found:
        return Pointer[DaySchedule]()
    var daySchedNum: Int = found.value()
    var daySched: Pointer[DaySchedule] = s_sched.daySchedules[daySchedNum]
    daySched[].isUsed = True
    return daySched

def GetDayScheduleNum(inout state: EnergyPlusData, name: String) -> Int:
    var daySched: Pointer[DaySchedule] = GetDaySchedule(state, name)
    return daySched[].Num if not daySched.is_null() else -1

def ExternalInterfaceSetSchedule(inout state: EnergyPlusData, schedNum: Int, value: Float64) -> None:
    var s_glob = state.dataGlobal
    var s_sched = state.dataSched
    var daySched: Pointer[DaySchedule] = s_sched.daySchedules[schedNum]
    for hr in range(Constant.iHoursInDay):
        for ts in range(s_glob.TimeStepsInHour):
            daySched[].tsVals[hr * s_glob.TimeStepsInHour + ts] = value

def ProcessIntervalFields(inout state: EnergyPlusData, Untils: List[String], Numbers: List[Float64], NumUntils: Int, NumNumbers: Int, inout minuteVals: StaticTuple[Float64, Constant.iMinutesInDay], inout setMinuteVals: StaticTuple[Bool, Constant.iMinutesInDay], inout ErrorsFound: Bool, DayScheduleName: String, ErrContext: String, interpolation: Interpolation) -> None:
    var HHField: Int = 0
    var MMField: Int = 0
    var begHr: Int = 0
    var begMin: Int = 0
    var endHr: Int = -1
    var endMin: Int = -1
    var sFld: Int = 0
    var totalMinutes: Int = 0
    var incrementPerMinute: Float64 = 0.0
    var curValue: Float64 = 0.0
    minuteVals.fill(0.0)
    setMinuteVals.fill(False)
    sFld = 0
    var StartValue: Float64 = 0.0
    var EndValue: Float64 = 0.0
    if NumUntils != NumNumbers:
        ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, number of Time fields does not match number of value fields, {ErrContext}={DayScheduleName}")
        ErrorsFound = True
        return
    for Count in range(1, NumUntils + 1):
        var until: String = Untils[Count - 1]
        var Pos: Int = index(until, "UNTIL")
        if Pos == 0:
            if until[5] == ':':
                sFld = 6
            else:
                sFld = 5
            DecodeHHMMField(state, until[sFld:], HHField, MMField, ErrorsFound, DayScheduleName, until, interpolation)
        elif Pos == -1:
            DecodeHHMMField(state, until, HHField, MMField, ErrorsFound, DayScheduleName, until, interpolation)
        else:
            ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, Invalid \"Until\" field encountered={until}")
            ShowContinueError(state, f"Occurred in Day Schedule={DayScheduleName}")
            ErrorsFound = True
            continue
        if HHField < 0 or HHField > Constant.iHoursInDay or MMField < 0 or MMField > Constant.iMinutesInHour:
            ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, Invalid \"Until\" field encountered={until}")
            ShowContinueError(state, f"Occurred in Day Schedule={DayScheduleName}")
            ErrorsFound = True
            continue
        if HHField == Constant.iHoursInDay and MMField > 0 and MMField < Constant.iMinutesInHour:
            ShowWarningError(state, f"ProcessScheduleInput: ProcessIntervalFields, Invalid \"Until\" field encountered={Untils[Count - 1]}")
            ShowContinueError(state, f"Occurred in Day Schedule={DayScheduleName}")
            ShowContinueError(state, "Terminating the field at 24:00")
            MMField = 0
        if MMField == 0:
            endHr = HHField - 1
            endMin = Constant.iMinutesInHour - 1
        elif MMField < Constant.iMinutesInHour:
            endHr = HHField
            endMin = MMField - 1
        if interpolation == Interpolation.Linear:
            totalMinutes = (endHr - begHr) * Constant.iMinutesInHour + (endMin - begMin) + 1
            if totalMinutes == 0:
                totalMinutes = 1
            if Count == 1:
                StartValue = Numbers[Count - 1]
                EndValue = Numbers[Count - 1]
            else:
                StartValue = EndValue
                EndValue = Numbers[Count - 1]
            incrementPerMinute = (EndValue - StartValue) / Float64(totalMinutes)
            curValue = StartValue + incrementPerMinute
        if begHr > endHr:
            if begHr == endHr + 1 and begMin == 0 and endMin == Constant.iMinutesInHour - 1:
                ShowWarningError(state, f"ProcessScheduleInput: ProcessIntervalFields, Processing time fields, zero time interval detected, {ErrContext}={DayScheduleName}")
            else:
                ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, Processing time fields, overlapping times detected, {ErrContext}={DayScheduleName}")
                ErrorsFound = True
        elif begHr == endHr:
            for iMin in range(begMin, endMin + 1):
                if setMinuteVals[begHr * Constant.iMinutesInHour + iMin]:
                    ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, Processing time fields, overlapping times detected, {ErrContext}={DayScheduleName}")
                    ErrorsFound = True
                    goto UntilLoop_exit
            if interpolation == Interpolation.Linear:
                for iMin in range(begMin, endMin + 1):
                    minuteVals[begHr * Constant.iMinutesInHour + iMin] = curValue
                    curValue += incrementPerMinute
                    setMinuteVals[begHr * Constant.iMinutesInHour + iMin] = True
            else:
                for iMin in range(begMin, endMin + 1):
                    minuteVals[begHr * Constant.iMinutesInHour + iMin] = Numbers[Count - 1]
                    setMinuteVals[begHr * Constant.iMinutesInHour + iMin] = True
            begMin = endMin + 1
            if begMin >= Constant.iMinutesInHour:
                begHr += 1
                begMin = 0
        else:
            if interpolation == Interpolation.Linear:
                for iMin in range(begMin, Constant.iMinutesInHour):
                    minuteVals[begHr * Constant.iMinutesInHour + iMin] = curValue
                    curValue += incrementPerMinute
                    setMinuteVals[begHr * Constant.iMinutesInHour + iMin] = True
                for iHr in range(begHr + 1, endHr):
                    for iMin in range(Constant.iMinutesInHour):
                        minuteVals[iHr * Constant.iMinutesInHour + iMin] = curValue
                        curValue += incrementPerMinute
                        setMinuteVals[iHr * Constant.iMinutesInHour + iMin] = True
                for iMin in range(endMin + 1):
                    minuteVals[endHr * Constant.iMinutesInHour + iMin] = curValue
                    curValue += incrementPerMinute
                    setMinuteVals[endHr * Constant.iMinutesInHour + iMin] = True
            else:
                for iMin in range(begMin, Constant.iMinutesInHour):
                    minuteVals[begHr * Constant.iMinutesInHour + iMin] = Numbers[Count - 1]
                    setMinuteVals[begHr * Constant.iMinutesInHour + iMin] = True
                if (begHr + 1) <= (endHr - 1):
                    for iHr in range(begHr + 1, endHr):
                        for iMin in range(Constant.iMinutesInHour):
                            minuteVals[iHr * Constant.iMinutesInHour + iMin] = Numbers[Count - 1]
                            setMinuteVals[iHr * Constant.iMinutesInHour + iMin] = True
                for iMin in range(endMin + 1):
                    minuteVals[endHr * Constant.iMinutesInHour + iMin] = Numbers[Count - 1]
                    setMinuteVals[endHr * Constant.iMinutesInHour + iMin] = True
            begHr = endHr
            begMin = endMin + 1
            if begMin >= Constant.iMinutesInHour:
                begHr += 1
                begMin = 0
    UntilLoop_exit:
    for iMin in range(Constant.iMinutesInDay):
        if not setMinuteVals[iMin]:
            ShowSevereError(state, f"ProcessScheduleInput: ProcessIntervalFields, Processing time fields, incomplete day detected, {ErrContext}={DayScheduleName}")
            ErrorsFound = True

def DecodeHHMMField(inout state: EnergyPlusData, FieldValue: String, inout RetHH: Int, inout RetMM: Int, inout ErrorsFound: Bool, DayScheduleName: String, FullFieldValue: String, interpolation: Interpolation) -> None:
    var String: String = strip(FieldValue)
    var Pos: Int = index(String, ':')
    var nonIntegral: Bool = False
    var s_glob = state.dataGlobal
    if Pos == -1:
        ShowSevereError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field submitted (no : separator in hh:mm)={strip(FullFieldValue)}")
        ShowContinueError(state, f"Occurred in Day Schedule={DayScheduleName}")
        ErrorsFound = True
        return
    if Pos == 0:
        RetHH = 0
    else:
        var error: Bool = False
        var rRetHH: Float64 = Util.ProcessNumber(String[:Pos], error)
        RetHH = Int(rRetHH)
        if Float64(RetHH) != rRetHH or error or rRetHH < 0.0:
            if Float64(RetHH) != rRetHH and rRetHH >= 0.0:
                ShowWarningError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field submitted (non-integer numeric in HH)={strip(FullFieldValue)}")
                ShowContinueError(state, f"Other errors may result. Occurred in Day Schedule={DayScheduleName}")
                nonIntegral = True
            else:
                ShowSevereError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field submitted (invalid numeric in HH)={strip(FullFieldValue)}")
                ShowContinueError(state, f"Field values must be integer and represent hours:minutes. Occurred in Day Schedule={DayScheduleName}")
                ErrorsFound = True
                return
    String = String[Pos + 1:]
    var error: Bool = False
    var rRetMM: Float64 = Util.ProcessNumber(String, error)
    RetMM = Int(rRetMM)
    if Float64(RetMM) != rRetMM or error or rRetMM < 0.0:
        if Float64(RetMM) != rRetMM and rRetMM >= 0.0:
            ShowWarningError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field submitted (non-integer numeric in MM)={strip(FullFieldValue)}")
            ShowContinueError(state, f"Other errors may result. Occurred in Day Schedule={DayScheduleName}")
            nonIntegral = True
        else:
            ShowSevereError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field submitted (invalid numeric in MM)={strip(FullFieldValue)}")
            ShowContinueError(state, f"Field values must be integer and represent hours:minutes. Occurred in Day Schedule={DayScheduleName}")
            ErrorsFound = True
            return
    if nonIntegral:
        var hHour: String = ""
        var mMinute: String = ""
        ShowContinueError(state, f"Until value to be used will be: {hHour:2.2F}:{mMinute:2.2F}")
    if interpolation == Interpolation.No:
        if not isMinuteMultipleOfTimestep(RetMM, s_glob.MinutesInTimeStep):
            ShowWarningError(state, f"ProcessScheduleInput: DecodeHHMMField, Invalid \"until\" field value is not a multiple of the minutes for each timestep: {strip(FullFieldValue)}")
            ShowContinueError(state, f"Other errors may result. Occurred in Day Schedule={DayScheduleName}")

def isMinuteMultipleOfTimestep(minute: Int, numMinutesPerTimestep: Int) -> Bool:
    if minute != 0:
        return minute % numMinutesPerTimestep == 0
    return True

def ProcessForDayTypes(inout state: EnergyPlusData, ForDayField: String, inout these: StaticTuple[Bool, 13], inout already: StaticTuple[Bool, 13], inout ErrorsFound: Bool) -> None:
    var OneValid: Bool = False
    var DupAssignment: Bool = False
    if has(ForDayField, "WEEKDAY"):
        these[iDayType_Mon] = these[iDayType_Tue] = these[iDayType_Wed] = these[iDayType_Thu] = these[iDayType_Fri] = True
        if already[iDayType_Mon] or already[iDayType_Tue] or already[iDayType_Wed] or already[iDayType_Thu] or already[iDayType_Fri]:
            DupAssignment = True
        already[iDayType_Mon] = already[iDayType_Tue] = already[iDayType_Wed] = already[iDayType_Thu] = already[iDayType_Fri] = True
        OneValid = True
    if has(ForDayField, "MONDAY"):
        these[iDayType_Mon] = True
        if already[iDayType_Mon]:
            DupAssignment = True
        else:
            already[iDayType_Mon] = True
        OneValid = True
    if has(ForDayField, "TUESDAY"):
        these[iDayType_Tue] = True
        if already[iDayType_Tue]:
            DupAssignment = True
        else:
            already[iDayType_Tue] = True
        OneValid = True
    if has(ForDayField, "WEDNESDAY"):
        these[iDayType_Wed] = True
        if already[iDayType_Wed]:
            DupAssignment = True
        else:
            already[iDayType_Wed] = True
        OneValid = True
    if has(ForDayField, "THURSDAY"):
        these[iDayType_Thu] = True
        if already[iDayType_Thu]:
            DupAssignment = True
        else:
            already[iDayType_Thu] = True
        OneValid = True
    if has(ForDayField, "FRIDAY"):
        these[iDayType_Fri] = True
        if already[iDayType_Fri]:
            DupAssignment = True
        else:
            already[iDayType_Fri] = True
        OneValid = True
    if has(ForDayField, "WEEKEND"):
        these[iDayType_Sun] = these[iDayType_Sat] = True
        if already[iDayType_Sun] or already[iDayType_Sat]:
            DupAssignment = True
        already[iDayType_Sun] = already[iDayType_Sat] = True
        OneValid = True
    if has(ForDayField, "SATURDAY"):
        these[iDayType_Sat] = True
        if already[iDayType_Sat]:
            DupAssignment = True
        else:
            already[iDayType_Sat] = True
        OneValid = True
    if has(ForDayField, "SUNDAY"):
        these[iDayType_Sun] = True
        if already[iDayType_Sun]:
            DupAssignment = True
        else:
            already[iDayType_Sun] = True
        OneValid = True
    if has(ForDayField, "CUSTOMDAY1"):
        these[iDayType_Cus1] = True
        if already[iDayType_Cus1]:
            DupAssignment = True
        else:
            already[iDayType_Cus1] = True
        OneValid = True
    if has(ForDayField, "CUSTOMDAY2"):
        these[iDayType_Cus2] = True
        if already[iDayType_Cus2]:
            DupAssignment = True
        else:
            already[iDayType_Cus2] = True
        OneValid = True
    if has(ForDayField, "ALLDAY"):
        for iDay in range(13):
            these[iDay] = True
            if already[iDay]:
                DupAssignment = True
            else:
                already[iDay] = True
        OneValid = True
    if has(ForDayField, "HOLIDAY"):
        these[iDayType_Hol] = True
        if already[iDayType_Hol]:
            DupAssignment = True
        else:
            already[iDayType_Hol] = True
        OneValid = True
    if has(ForDayField, "SUMMER"):
        these[iDayType_SumDes] = True
        if already[iDayType_SumDes]:
            DupAssignment = True
        else:
            already[iDayType_SumDes] = True
        OneValid = True
    if has(ForDayField, "WINTER"):
        these[iDayType_WinDes] = True
        if already[iDayType_WinDes]:
            DupAssignment = True
        else:
            already[iDayType_WinDes] = True
        OneValid = True
    if has(ForDayField, "ALLOTHERDAY"):
        for iDay in range(13):
            if not already[iDay]:
                these[iDay] = already[iDay] = True
        OneValid = True
    if DupAssignment:
        ShowSevereError(state, f"ProcessForDayTypes: Duplicate assignment attempted in \"for\" days field={ForDayField}")
        ErrorsFound = True
    if not OneValid:
        ShowSevereError(state, f"ProcessForDayTypes: No valid day assignments found in \"for\" days field={ForDayField}")
        ErrorsFound = True

def CheckScheduleValueMin(inout state: EnergyPlusData, schedNum: Int, clu: Clusive, min: Float64) -> Bool:
    return state.dataSched.schedules[schedNum][].checkMinVal(state, clu, min)

def CheckScheduleValueMinMax(inout state: EnergyPlusData, schedNum: Int, cluMin: Clusive, min: Float64, cluMax: Clusive, max: Float64) -> Bool:
    return state.dataSched.schedules[schedNum][].checkMinMaxVals(state, cluMin, min, cluMax, max)

def CheckScheduleValue(inout state: EnergyPlusData, schedNum: Int, value: Float64) -> Bool:
    return state.dataSched.schedules[schedNum][].hasVal(state, value)

def CheckDayScheduleMinValues(inout state: EnergyPlusData, schedNum: Int, cluMin: Clusive, min: Float64) -> Bool:
    return state.dataSched.daySchedules[schedNum][].checkMinVal(state, cluMin, min)

def ReportScheduleVals(inout state: EnergyPlusData) -> None:
    var s_sched = state.dataSched
    if s_sched.DoScheduleReportingSetup:
        for sched in s_sched.schedules:
            if sched[].Num == SchedNum_AlwaysOff or sched[].Num == SchedNum_AlwaysOn:
                continue
            SetupOutputVariable(state, "Schedule Value", OutputConstant.Units.None, sched[].currentVal, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, sched[].Name)
        s_sched.DoScheduleReportingSetup = False
    UpdateScheduleVals(state)

def ReportOrphanSchedules(inout state: EnergyPlusData) -> None:
    var NeedOrphanMessage: Bool = True
    var NeedUseMessage: Bool = False
    var NumCount: Int = 0
    var s_sched = state.dataSched
    var s_glob = state.dataGlobal
    for sched in s_sched.schedules:
        if sched[].isUsed:
            continue
        if NeedOrphanMessage and s_glob.DisplayUnusedSchedules:
            ShowWarningError(state, "The following schedule names are \"Unused Schedules\".  These schedules are in the idf")
            ShowContinueError(state, " file but are never obtained by the simulation and therefore are NOT used.")
            NeedOrphanMessage = False
        if s_glob.DisplayUnusedSchedules:
            ShowMessage(state, f"Schedule:Year or Schedule:Compact or Schedule:File or Schedule:Constant={sched[].Name}")
        else:
            NumCount += 1
    if NumCount > 0:
        ShowMessage(state, f"There are {NumCount} unused schedules in input.")
        NeedUseMessage = True
    NeedOrphanMessage = True
    NumCount = 0
    for weekSched in s_sched.weekSchedules:
        if weekSched[].isUsed:
            continue
        if weekSched[].Name == "":
            continue
        if NeedOrphanMessage and s_glob.DisplayUnusedSchedules:
            ShowWarningError(state, "The following week schedule names are \"Unused Schedules\".  These schedules are in the idf")
            ShowContinueError(state, " file but are never obtained by the simulation and therefore are NOT used.")
            NeedOrphanMessage = False
        if s_glob.DisplayUnusedSchedules:
            ShowMessage(state, f"Schedule:Week:Daily or Schedule:Week:Compact={weekSched[].Name}")
        else:
            NumCount += 1
    if NumCount > 0:
        ShowMessage(state, f"There are {NumCount} unused week schedules in input.")
        NeedUseMessage = True
    NeedOrphanMessage = True
    NumCount = 0
    for daySched in s_sched.daySchedules:
        if daySched[].isUsed:
            continue
        if daySched[].Name == "":
            continue
        if NeedOrphanMessage and s_glob.DisplayUnusedSchedules:
            ShowWarningError(state, "The following day schedule names are \"Unused Schedules\".  These schedules are in the idf")
            ShowContinueError(state, " file but are never obtained by the simulation and therefore are NOT used.")
            NeedOrphanMessage = False
        if s_glob.DisplayUnusedSchedules:
            ShowMessage(state, f"Schedule:Day:Hourly or Schedule:Day:Interval or Schedule:Day:List={daySched[].Name}")
        else:
            NumCount += 1
    if NumCount > 0:
        ShowMessage(state, f"There are {NumCount} unused day schedules in input.")
        NeedUseMessage = True
    if NeedUseMessage:
        ShowMessage(state, "Use Output:Diagnostics,DisplayUnusedSchedules; to see them.")

def ShowSevereBadMin(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMin: Clusive, minVal: Float64, msg: StringLiteral = "") -> None:
    ShowSevereError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'<' if cluMin == Clusive.In else '<='} {minVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

def ShowSevereBadMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMax: Clusive, maxVal: Float64, msg: StringLiteral = "") -> None:
    ShowSevereError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'>' if cluMax == Clusive.In else '>='} {maxVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

def ShowSevereBadMinMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMin: Clusive, minVal: Float64, cluMax: Clusive, maxVal: Float64, msg: StringLiteral = "") -> None:
    ShowSevereError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'<' if cluMin == Clusive.In else '<='} {minVal} and/or {'>' if cluMax == Clusive.In else '>='} {maxVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

def ShowWarningBadMin(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMin: Clusive, minVal: Float64, msg: StringLiteral = "") -> None:
    ShowWarningError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'<' if cluMin == Clusive.In else '<='} {minVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

def ShowWarningBadMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMax: Clusive, maxVal: Float64, msg: StringLiteral = "") -> None:
    ShowWarningError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'>' if cluMax == Clusive.In else '>='} {maxVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

def ShowWarningBadMinMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, cluMin: Clusive, minVal: Float64, cluMax: Clusive, maxVal: Float64, msg: StringLiteral = "") -> None:
    ShowWarningError(state, f"{eoh.routineName}: {eoh.objectType} = {eoh.objectName}")
    ShowContinueError(state, f"{fieldName} = {fieldVal}, schedule contains values that are {'<' if cluMin == Clusive.In else '<='} {minVal} and/or {'>' if cluMax == Clusive.In else '>='} {maxVal}")
    if msg != "":
        ShowContinueError(state, f"{msg}")

// ScheduleManagerData struct
struct ScheduleManagerData: BaseGlobalStruct:
    var CheckScheduleValMinMaxRunOnceOnly: Bool = True
    var DoScheduleReportingSetup: Bool = True
    var UniqueProcessedExternalFiles: Dict[String, JSON] = Dict[String, JSON]()
    var ScheduleInputProcessed: Bool = False
    var ScheduleFileShadingProcessed: Bool = False
    var scheduleTypes: List[Pointer[ScheduleType]] = List[Pointer[ScheduleType]]()
    var schedules: List[Pointer[Schedule]] = List[Pointer[Schedule]]()
    var daySchedules: List[Pointer[DaySchedule]] = List[Pointer[DaySchedule]]()
    var weekSchedules: List[Pointer[WeekSchedule]] = List[Pointer[WeekSchedule]]()
    var scheduleTypeMap: Dict[String, Int] = Dict[String, Int]()
    var scheduleMap: Dict[String, Int] = Dict[String, Int]()
    var dayScheduleMap: Dict[String, Int] = Dict[String, Int]()
    var weekScheduleMap: Dict[String, Int] = Dict[String, Int]()

    def init_constant_state(self, inout state: EnergyPlusData) -> None:
        InitConstantScheduleData(state)

    def init_state(self, inout state: EnergyPlusData) -> None:
        ProcessScheduleInput(state)

    def clear_state(self) -> None:
        self.CheckScheduleValMinMaxRunOnceOnly = True
        self.UniqueProcessedExternalFiles.clear()
        self.DoScheduleReportingSetup = True
        self.ScheduleInputProcessed = False
        self.ScheduleFileShadingProcessed = False
        for scheduleType in self.scheduleTypes:
            Pointer[ScheduleType].free(scheduleType)
        self.scheduleTypes.clear()
        self.scheduleTypeMap.clear()
        for schedule in self.schedules:
            Pointer[Schedule].free(schedule)
        self.schedules.clear()
        self.scheduleMap.clear()
        for daySchedule in self.daySchedules:
            Pointer[DaySchedule].free(daySchedule)
        self.daySchedules.clear()
        self.dayScheduleMap.clear()
        for weekSchedule in self.weekSchedules:
            Pointer[WeekSchedule].free(weekSchedule)
        self.weekSchedules.clear()
        self.weekScheduleMap.clear()