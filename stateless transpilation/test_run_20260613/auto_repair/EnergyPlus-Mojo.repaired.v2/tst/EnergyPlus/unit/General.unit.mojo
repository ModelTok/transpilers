from gtest import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.string.functions import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.General import *
from EnergyPlus.HVACSystemRootFindingAlgorithm import *
from EnergyPlus.WeatherManager import *

def General_ParseTime():
    var Hours: Int
    var Minutes: Int
    var Seconds: Float64
    { # Time = 0
        General.ParseTime(0, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(0, Seconds)
    }
    { # Time = 1
        General.ParseTime(1, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(1, Seconds)
    }
    { # Time = 59
        General.ParseTime(59, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(59, Seconds)
    }
    { # Time = 59.9
        General.ParseTime(59.9, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(59.9, Seconds)
    }
    { # Time = 59.99
        General.ParseTime(59.99, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(59.99, Seconds)
    }
    { # Time = 59.999
        General.ParseTime(59.999, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(59.999, Seconds)
    }
    { # Time = 60
        General.ParseTime(60, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(1, Minutes)
        EXPECT_DOUBLE_EQ(0, Seconds)
    }
    { # Time = 61
        General.ParseTime(61, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(1, Minutes)
        EXPECT_DOUBLE_EQ(1, Seconds)
    }
    { # Time = 3599
        General.ParseTime(3599, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(59, Minutes)
        EXPECT_DOUBLE_EQ(59, Seconds)
    }
    { # Time = 3600
        General.ParseTime(3600, Hours, Minutes, Seconds)
        EXPECT_EQ(1, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(0, Seconds)
    }
    { # Time = 3601
        General.ParseTime(3601, Hours, Minutes, Seconds)
        EXPECT_EQ(1, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(1, Seconds)
    }
    { # Time = 3661
        General.ParseTime(3661, Hours, Minutes, Seconds)
        EXPECT_EQ(1, Hours)
        EXPECT_EQ(1, Minutes)
        EXPECT_DOUBLE_EQ(1, Seconds)
    }
    { # Time = 86399
        General.ParseTime(86399, Hours, Minutes, Seconds)
        EXPECT_EQ(23, Hours)
        EXPECT_EQ(59, Minutes)
        EXPECT_DOUBLE_EQ(59, Seconds)
    }
    { # Time = 86400
        General.ParseTime(86400, Hours, Minutes, Seconds)
        EXPECT_EQ(24, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(0, Seconds)
    }
    { # Time = 86401
        General.ParseTime(86401, Hours, Minutes, Seconds)
        EXPECT_EQ(24, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(1, Seconds)
    }
    { # Time = -1
        General.ParseTime(-1, Hours, Minutes, Seconds)
        EXPECT_EQ(0, Hours)
        EXPECT_EQ(0, Minutes)
        EXPECT_DOUBLE_EQ(-1, Seconds)
    }

def General_CreateTimeString():
    { # Time = 0
        EXPECT_EQ("00:00:00.0", General.CreateTimeString(0))
    }
    { # Time = 1
        EXPECT_EQ("00:00:01.0", General.CreateTimeString(1))
    }
    { # Time = 59
        EXPECT_EQ("00:00:59.0", General.CreateTimeString(59))
    }
    { # Time = 59.9
        EXPECT_EQ("00:00:59.9", General.CreateTimeString(59.9))
    }
    { # Time = 59.99
        EXPECT_EQ("00:00:60.0", General.CreateTimeString(59.99))
    }
    { # Time = 59.999
        EXPECT_EQ("00:00:60.0", General.CreateTimeString(59.999))
    }
    { # Time = 60
        EXPECT_EQ("00:01:00.0", General.CreateTimeString(60))
    }
    { # Time = 61
        EXPECT_EQ("00:01:01.0", General.CreateTimeString(61))
    }
    { # Time = 3600
        EXPECT_EQ("01:00:00.0", General.CreateTimeString(3600))
    }
    { # Time = 3599
        EXPECT_EQ("00:59:59.0", General.CreateTimeString(3599))
    }
    { # Time = 3601
        EXPECT_EQ("01:00:01.0", General.CreateTimeString(3601))
    }
    { # Time = 3661
        EXPECT_EQ("01:01:01.0", General.CreateTimeString(3661))
    }
    { # Time = 86399
        EXPECT_EQ("23:59:59.0", General.CreateTimeString(86399))
    }
    { # Time = 86400
        EXPECT_EQ("24:00:00.0", General.CreateTimeString(86400))
    }
    { # Time = 86401
        EXPECT_EQ("24:00:01.0", General.CreateTimeString(86401))
    }
    { # Time = -1
        EXPECT_EQ("00:00:-1.0", General.CreateTimeString(-1))
    }

def General_SolveRootTest():
    var ErrorToler: Float64 = 0.00001
    var MaxIte: Int = 30
    var SolFla: Int
    var Frac: Float64
    var residual = fn(Frac: Float64) -> Float64:
        var Request: Float64 = 1.10
        var Actual: Float64 = 1.0 + 2.0 * Frac + 10.0 * Frac * Frac
        return (Actual - Request) / Request
    
    var residual_test = fn(Frac: Float64) -> Float64:
        var Request: Float64 = 1.0 + 1.0e-12
        var Actual: Float64 = 1.0 + 2.0 * Frac + 10.0 * Frac * Frac
        return (Actual - Request) / Request
    
    General.SolveRoot(*state, ErrorToler, MaxIte, SolFla, Frac, residual, 0.0, 1.0)
    EXPECT_EQ(-1, SolFla)
    state.dataRootFinder.rootAlgo = RootAlgo.RegulaFalsiThenBisection
    state.dataRootFinder.NumOfIter = 10
    General.SolveRoot(*state, ErrorToler, MaxIte, SolFla, Frac, residual, 0.0, 1.0)
    EXPECT_EQ(28, SolFla)
    EXPECT_NEAR(0.041420287, Frac, ErrorToler)
    state.dataRootFinder.rootAlgo = RootAlgo.Bisection
    General.SolveRoot(*state, ErrorToler, 40, SolFla, Frac, residual, 0.0, 1.0)
    EXPECT_EQ(17, SolFla)
    EXPECT_NEAR(0.041420287, Frac, ErrorToler)
    state.dataRootFinder.rootAlgo = RootAlgo.BisectionThenRegulaFalsi
    General.SolveRoot(*state, ErrorToler, 40, SolFla, Frac, residual, 0.0, 1.0)
    EXPECT_EQ(12, SolFla)
    EXPECT_NEAR(0.041420287, Frac, ErrorToler)
    state.dataRootFinder.rootAlgo = RootAlgo.Alternation
    state.dataRootFinder.NumOfIter = 3
    General.SolveRoot(*state, ErrorToler, 40, SolFla, Frac, residual, 0.0, 1.0)
    EXPECT_EQ(15, SolFla)
    EXPECT_NEAR(0.041420287, Frac, ErrorToler)
    state.dataRootFinder.rootAlgo = RootAlgo.RegulaFalsi
    var small: Float64 = 1.0e-11
    General.SolveRoot(*state, ErrorToler, 40, SolFla, Frac, residual_test, 0.0, small)
    EXPECT_EQ(-1, SolFla)

def General_SolveRoot2():
    var solveRootStats: SolveRootStats
    var maxIters: Int = 30
    var SolFla: Int
    for i in range(100):
        var Request: Float64 = Float64((i % 13) + 0.172)
        var residual = fn(Frac: Float64) -> Float64:
            var Actual: Float64 = 1.0 + 2.0 * Frac + 10.0 * Frac * Frac
            return (Actual - Request) / Request
        
        General.SolveRoot2(*state, 0.001, maxIters, SolFla, residual, 0.0, 1.0, solveRootStats)
    
    EXPECT_ENUM_EQ(solveRootStats.algo, RootAlgo.ShortBisectionThenRegulaFalsi)
    for i in range(100):
        var Request: Float64 = Float64(1.00 / (i + 1))
        var residual = fn(Frac: Float64) -> Float64:
            var Actual: Float64 = 1.0 + 1.0 / (1.0 + Frac)
            return (Actual - Request) / Request
        
        General.SolveRoot2(*state, 0.001, maxIters, SolFla, residual, 0.0, 1.0, solveRootStats)
    
    EXPECT_ENUM_EQ(solveRootStats.algo, RootAlgo.ShortBisectionThenRegulaFalsi)

def nthDayOfWeekOfMonth_test():
    state.dataEnvrn.CurrentYearIsLeapYear = False # based on 2017
    state.dataEnvrn.RunPeriodStartDayOfWeek = 1   # sunday
    EXPECT_EQ(1, nthDayOfWeekOfMonth(*state, 1, 1, 1))  # first sunday of january
    EXPECT_EQ(8, nthDayOfWeekOfMonth(*state, 1, 2, 1))  # second sunday of january
    EXPECT_EQ(15, nthDayOfWeekOfMonth(*state, 1, 3, 1)) # third sunday of january
    EXPECT_EQ(22, nthDayOfWeekOfMonth(*state, 1, 4, 1)) # fourth sunday of january
    EXPECT_EQ(2, nthDayOfWeekOfMonth(*state, 2, 1, 1))  # first monday of january
    EXPECT_EQ(10, nthDayOfWeekOfMonth(*state, 3, 2, 1)) # second tuesday of january
    EXPECT_EQ(19, nthDayOfWeekOfMonth(*state, 5, 3, 1)) # third thursday of january
    EXPECT_EQ(28, nthDayOfWeekOfMonth(*state, 7, 4, 1)) # fourth saturday of january
    EXPECT_EQ(32, nthDayOfWeekOfMonth(*state, 4, 1, 2)) # first wednesday of february
    EXPECT_EQ(60, nthDayOfWeekOfMonth(*state, 4, 1, 3)) # first wednesday of march
    state.dataEnvrn.CurrentYearIsLeapYear = True
    state.dataEnvrn.RunPeriodStartDayOfWeek = 1 # sunday
    EXPECT_EQ(32, nthDayOfWeekOfMonth(*state, 4, 1, 2)) # first wednesday of february
    EXPECT_EQ(61, nthDayOfWeekOfMonth(*state, 5, 1, 3)) # first thursday of march
    EXPECT_EQ(67, nthDayOfWeekOfMonth(*state, 4, 1, 3)) # first wednesday of march
    state.dataEnvrn.CurrentYearIsLeapYear = True # based on 2016
    state.dataEnvrn.RunPeriodStartDayOfWeek = 6  # friday
    EXPECT_EQ(3, nthDayOfWeekOfMonth(*state, 1, 1, 1))  # first sunday of january
    EXPECT_EQ(10, nthDayOfWeekOfMonth(*state, 1, 2, 1)) # second sunday of january
    EXPECT_EQ(17, nthDayOfWeekOfMonth(*state, 1, 3, 1)) # third sunday of january
    EXPECT_EQ(24, nthDayOfWeekOfMonth(*state, 1, 4, 1)) # fourth sunday of january
    EXPECT_EQ(31, nthDayOfWeekOfMonth(*state, 1, 5, 1)) # fifth sunday of january
    EXPECT_EQ(1, nthDayOfWeekOfMonth(*state, 6, 1, 1))  # first friday of january
    EXPECT_EQ(8, nthDayOfWeekOfMonth(*state, 6, 2, 1))  # second friday of january
    EXPECT_EQ(15, nthDayOfWeekOfMonth(*state, 6, 3, 1)) # third friday of january
    EXPECT_EQ(22, nthDayOfWeekOfMonth(*state, 6, 4, 1)) # fourth friday of january
    EXPECT_EQ(34, nthDayOfWeekOfMonth(*state, 4, 1, 2)) # first wednesday of february
    EXPECT_EQ(62, nthDayOfWeekOfMonth(*state, 4, 1, 3)) # first wednesday of march

def General_EpexpTest():
    var x: Float64
    var d: Float64 = 1.0
    var y: Float64
    x = -69.0
    y = epexp(x, d)
    EXPECT_NEAR(0.0, y, 1.0E-20)
    x = -700.0
    y = epexp(x, d)
    EXPECT_NEAR(0.0, y, 1.0E-20)
    x = -1000.0 # Will cause underflow
    y = epexp(x, d)
    EXPECT_EQ(0.0, y)
    d = 0.0
    x = -1000.0
    y = epexp(x, d)
    EXPECT_EQ(0.0, y)
    d = 0.0
    x = 1000.0
    y = epexp(x, d)
    EXPECT_EQ(0.0, y)

def General_MovingAvg():
    var numItem: Int = 12
    var inputData: Array1D[Float64]
    var saveData: Array1D[Float64]
    inputData.allocate(numItem)
    saveData.allocate(numItem)
    for i in range(1, numItem + 1):
        inputData[i - 1] = Float64(i) * Float64(i)
    
    saveData = inputData
    var avgWindowWidth: Int = 1
    MovingAvg(inputData, avgWindowWidth)
    for i in range(1, numItem + 1):
        ASSERT_EQ(saveData[i - 1], inputData[i - 1]) # averaged data has not changed since window = 1
    
    avgWindowWidth = 2
    MovingAvg(inputData, avgWindowWidth)
    ASSERT_EQ(inputData[0], (saveData[0] + saveData[numItem - 1]) / avgWindowWidth)
    for j in range(2, numItem + 1):
        ASSERT_EQ(inputData[j - 1], (saveData[j - 1] + saveData[j - 2]) / avgWindowWidth)
    
    inputData = saveData # reset for next test
    avgWindowWidth = 4
    MovingAvg(inputData, avgWindowWidth)
    EXPECT_NEAR(inputData[0], (saveData[0] + saveData[11] + saveData[10] + saveData[9]) / avgWindowWidth, 1E-9)
    EXPECT_NEAR(inputData[1], (saveData[1] + saveData[0] + saveData[11] + saveData[10]) / avgWindowWidth, 1E-9)
    EXPECT_NEAR(inputData[2], (saveData[2] + saveData[1] + saveData[0] + saveData[11]) / avgWindowWidth, 1E-9)
    for j in range(4, numItem + 1):
        EXPECT_NEAR(inputData[j - 1], (saveData[j - 1] + saveData[j - 2] + saveData[j - 3] + saveData[j - 4]) / avgWindowWidth, 1E-9)
    

def General_BetweenDateHoursLeftInclusive():
    var currentYear: Int = 2018
    var currentMonth: Int = 5
    var currentDay: Int = 13
    var currentHour: Int = 8
    var currentDate: Int = Weather.computeJulianDate(currentYear, currentMonth, currentDay)
    var startYear: Int = 2018
    var startMonth: Int = 3
    var startDay: Int = 13
    var startHour: Int = 8
    var startDate: Int = Weather.computeJulianDate(startYear, startMonth, startDay)
    var endYear: Int = 2018
    var endMonth: Int = 5
    var endDay: Int = 13
    var endHour: Int = 9
    var endDate: Int = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_TRUE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))
    startYear = 2018
    startMonth = 3
    startDay = 13
    startHour = 8
    startDate = Weather.computeJulianDate(startYear, startMonth, startDay)
    endYear = 2018
    endMonth = 5
    endDay = 13
    endHour = 8
    endDate = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_TRUE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))
    startYear = 2018
    startMonth = 6
    startDay = 13
    startHour = 8
    startDate = Weather.computeJulianDate(startYear, startMonth, startDay)
    endYear = 2018
    endMonth = 8
    endDay = 13
    endHour = 8
    endDate = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_FALSE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))
    startYear = 2018
    startMonth = 5
    startDay = 13
    startHour = 8
    startDate = Weather.computeJulianDate(startYear, startMonth, startDay)
    endYear = 2018
    endMonth = 7
    endDay = 15
    endHour = 2
    endDate = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_TRUE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))
    startYear = 2017
    startMonth = 5
    startDay = 13
    startHour = 8
    startDate = Weather.computeJulianDate(startYear, startMonth, startDay)
    endYear = 2019
    endMonth = 2
    endDay = 15
    endHour = 2
    endDate = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_TRUE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))
    startYear = 2019
    startMonth = 2
    startDay = 15
    startHour = 2
    startDate = Weather.computeJulianDate(startYear, startMonth, startDay)
    endYear = 2017
    endMonth = 5
    endDay = 13
    endHour = 8
    endDate = Weather.computeJulianDate(endYear, endMonth, endDay)
    EXPECT_TRUE(BetweenDateHoursLeftInclusive(currentDate, currentHour, startDate, startHour, endDate, endHour))

def General_isReportPeriodBeginning():
    state.dataWeather.TotReportPers = 1
    state.dataWeather.ReportPeriodInput.allocate(state.dataWeather.TotReportPers)
    var periodIdx: Int = 1
    state.dataWeather.ReportPeriodInput[periodIdx - 1].startYear = 0
    state.dataWeather.ReportPeriodInput[periodIdx - 1].startMonth = 1
    state.dataWeather.ReportPeriodInput[periodIdx - 1].startDay = 1
    state.dataWeather.ReportPeriodInput[periodIdx - 1].startHour = 8
    state.dataWeather.ReportPeriodInput[periodIdx - 1].startJulianDate = Weather.computeJulianDate(state.dataWeather.ReportPeriodInput[periodIdx - 1].startYear, state.dataWeather.ReportPeriodInput[periodIdx - 1].startMonth, state.dataWeather.ReportPeriodInput[periodIdx - 1].startDay)
    state.dataWeather.ReportPeriodInput[periodIdx - 1].endYear = 0
    state.dataWeather.ReportPeriodInput[periodIdx - 1].endMonth = 1
    state.dataWeather.ReportPeriodInput[periodIdx - 1].endDay = 3
    state.dataWeather.ReportPeriodInput[periodIdx - 1].endHour = 18
    state.dataWeather.ReportPeriodInput[periodIdx - 1].endJulianDate = Weather.computeJulianDate(state.dataWeather.ReportPeriodInput[periodIdx - 1].endYear, state.dataWeather.ReportPeriodInput[periodIdx - 1].endMonth, state.dataWeather.ReportPeriodInput[periodIdx - 1].endDay)
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 8
    EXPECT_TRUE(isReportPeriodBeginning(*state, periodIdx))
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 10
    state.dataGlobal.HourOfDay = 8
    EXPECT_FALSE(isReportPeriodBeginning(*state, periodIdx))
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 15
    EXPECT_FALSE(isReportPeriodBeginning(*state, periodIdx))
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 5
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 8
    EXPECT_FALSE(isReportPeriodBeginning(*state, periodIdx))

def General_findReportPeriodIdx():
    state.dataWeather.TotThermalReportPers = 2
    state.dataWeather.ThermalReportPeriodInput.allocate(state.dataWeather.TotThermalReportPers)
    state.dataWeather.ThermalReportPeriodInput[0].startYear = 0
    state.dataWeather.ThermalReportPeriodInput[0].startMonth = 1
    state.dataWeather.ThermalReportPeriodInput[0].startDay = 1
    state.dataWeather.ThermalReportPeriodInput[0].startHour = 8
    state.dataWeather.ThermalReportPeriodInput[0].startJulianDate = Weather.computeJulianDate(state.dataWeather.ThermalReportPeriodInput[0].startYear, state.dataWeather.ThermalReportPeriodInput[0].startMonth, state.dataWeather.ThermalReportPeriodInput[0].startDay)
    state.dataWeather.ThermalReportPeriodInput[0].endYear = 0
    state.dataWeather.ThermalReportPeriodInput[0].endMonth = 1
    state.dataWeather.ThermalReportPeriodInput[0].endDay = 10
    state.dataWeather.ThermalReportPeriodInput[0].endHour = 18
    state.dataWeather.ThermalReportPeriodInput[0].endJulianDate = Weather.computeJulianDate(state.dataWeather.ThermalReportPeriodInput[0].endYear, state.dataWeather.ThermalReportPeriodInput[0].endMonth, state.dataWeather.ThermalReportPeriodInput[0].endDay)
    state.dataWeather.ThermalReportPeriodInput[1].startYear = 0
    state.dataWeather.ThermalReportPeriodInput[1].startMonth = 2
    state.dataWeather.ThermalReportPeriodInput[1].startDay = 1
    state.dataWeather.ThermalReportPeriodInput[1].startHour = 8
    state.dataWeather.ThermalReportPeriodInput[1].startJulianDate = Weather.computeJulianDate(state.dataWeather.ThermalReportPeriodInput[1].startYear, state.dataWeather.ThermalReportPeriodInput[1].startMonth, state.dataWeather.ThermalReportPeriodInput[1].startDay)
    state.dataWeather.ThermalReportPeriodInput[1].endYear = 0
    state.dataWeather.ThermalReportPeriodInput[1].endMonth = 3
    state.dataWeather.ThermalReportPeriodInput[1].endDay = 10
    state.dataWeather.ThermalReportPeriodInput[1].endHour = 18
    state.dataWeather.ThermalReportPeriodInput[1].endJulianDate = Weather.computeJulianDate(state.dataWeather.ThermalReportPeriodInput[1].endYear, state.dataWeather.ThermalReportPeriodInput[1].endMonth, state.dataWeather.ThermalReportPeriodInput[1].endDay)
    var reportPeriodFlags: Array1D[Bool]
    reportPeriodFlags.allocate(state.dataWeather.TotThermalReportPers)
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 5
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 8
    state.dataGlobal.HourOfDay = 6
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_TRUE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 15
    state.dataGlobal.HourOfDay = 21
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 3
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 11
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_TRUE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 5
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 11
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataWeather.ThermalReportPeriodInput[0].endYear = 0
    state.dataWeather.ThermalReportPeriodInput[0].endMonth = 2
    state.dataWeather.ThermalReportPeriodInput[0].endDay = 10
    state.dataWeather.ThermalReportPeriodInput[0].endHour = 18
    state.dataWeather.ThermalReportPeriodInput[0].endJulianDate = Weather.computeJulianDate(state.dataWeather.ThermalReportPeriodInput[0].endYear, state.dataWeather.ThermalReportPeriodInput[0].endMonth, state.dataWeather.ThermalReportPeriodInput[0].endDay)
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 5
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 8
    state.dataGlobal.HourOfDay = 6
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_TRUE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 2
    state.dataEnvrn.DayOfMonth = 5
    state.dataGlobal.HourOfDay = 21
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_TRUE(reportPeriodFlags[0])
    EXPECT_TRUE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 3
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 11
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_TRUE(reportPeriodFlags[1])
    state.dataEnvrn.Year = 0
    state.dataEnvrn.Month = 5
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 11
    reportPeriodFlags = False
    findReportPeriodIdx(*state, state.dataWeather.ThermalReportPeriodInput, state.dataWeather.TotThermalReportPers, reportPeriodFlags)
    EXPECT_FALSE(reportPeriodFlags[0])
    EXPECT_FALSE(reportPeriodFlags[1])

def General_CreateSysTimeIntervalString_Test():
    var dHVACG = state.dataHVACGlobal
    var dGlo = state.dataGlobal
    var resultingString: String
    var expectedString: String
    dHVACG.SysTimeElapsed = 0.10
    dHVACG.TimeStepSys = 0.05
    dGlo.CurrentTime = 10.6
    dGlo.TimeStepZone = 0.2
    expectedString = "10:30 - 10:33"
    resultingString = CreateSysTimeIntervalString(*state)
    EXPECT_EQ(resultingString, expectedString)
    dHVACG.SysTimeElapsed = 0.10
    dHVACG.TimeStepSys = 0.10
    dGlo.CurrentTime = 0.10
    dGlo.TimeStepZone = 0.10
    expectedString = "00:00 - 00:06"
    resultingString = CreateSysTimeIntervalString(*state)
    EXPECT_EQ(resultingString, expectedString)
    dHVACG.SysTimeElapsed = 0.2
    dHVACG.TimeStepSys = 0.2
    dGlo.CurrentTime = 24.0
    dGlo.TimeStepZone = 0.2
    expectedString = "23:48 - 24:00"
    resultingString = CreateSysTimeIntervalString(*state)
    EXPECT_EQ(resultingString, expectedString)
    dHVACG.SysTimeElapsed = 0.0
    dHVACG.TimeStepSys = 0.1
    dGlo.CurrentTime = 10.9
    dGlo.TimeStepZone = 0.1
    expectedString = "10:48 - 10:54"
    resultingString = CreateSysTimeIntervalString(*state)
    EXPECT_EQ(resultingString, expectedString)