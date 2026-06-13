from .Fixtures.EnergyPlusFixture import process_idf, compare_err_stream, state
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData  # Not used directly but needed
from EnergyPlus.DataEnvironment import EnvironmentData
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataIPShortCuts import DataIPShortCuts
from EnergyPlus.DataSurfaces import DataSurfaces
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.SurfaceGeometry import SurfaceGeometry
from EnergyPlus.WeatherManager import Weather

from testing import expect_eq, expect_true, expect_false, expect_enum_eq
from utils import delimited_string  # Assuming there is a utility function; if not, define locally

def EXPECT_EQ[T: AnyRegType](a: T, b: T) -> None:
    expect_eq(a, b)

def EXPECT_ENUM_EQ[T: AnyRegType](a: T, b: T) -> None:
    expect_enum_eq(a, b)

def EXPECT_TRUE(cond: Bool) -> None:
    expect_true(cond)

def EXPECT_FALSE(cond: Bool) -> None:
    expect_false(cond)

def ASSERT_TRUE(cond: Bool) -> None:
    if not cond:
        raise Error("Assertion failed")

def ASSERT_FALSE(cond: Bool) -> None:
    if cond:
        raise Error("Assertion failed")

def main() -> None:
    # Test RunPeriod_Defaults
    {
        var runperiod = Weather.RunPeriodData()
        EXPECT_ENUM_EQ(Sched.DayType.Sunday, runperiod.startWeekDay)
        EXPECT_EQ(1, runperiod.startMonth)
        EXPECT_EQ(1, runperiod.startDay)
        EXPECT_EQ(2017, runperiod.startYear)
        EXPECT_EQ(2457755, runperiod.startJulianDate)
        EXPECT_EQ(12, runperiod.endMonth)
        EXPECT_EQ(31, runperiod.endDay)
        EXPECT_EQ(2017, runperiod.endYear)
        EXPECT_EQ(2458119, runperiod.endJulianDate)
        var startDays: StaticTuple[Float64, 12] = StaticTuple[Float64, 12](1.0, 4.0, 4.0, 7.0, 2.0, 5.0, 7.0, 3.0, 6.0, 1.0, 4.0, 6.0)
        for i in range(12):
            EXPECT_EQ(startDays[i], runperiod.monWeekDay[i])
    }

    # Test RunPeriod_YearTests
    {
        var idf_objects = delimited_string([
            "SimulationControl, NO, NO, NO, YES, YES;",
            "Timestep,4;",
            "RunPeriod,",
            "RP1,                     !- Name",
            "2,                       !- Begin Month",
            "29,                      !- Begin Day of Month",
            "2016,                    !- Begin Year",
            "3,                       !- End Month",
            "3,                       !- End Day of Month",
            ",                        !- End Year",
            "Monday,                  !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP2,                     !- Name",
            "2,                       !- Begin Month",
            "29,                      !- Begin Day of Month",
            ",                        !- Begin Year",
            "3,                       !- End Month",
            "3,                       !- End Day of Month",
            ",                        !- End Year",
            "Wednesday,               !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP3,                     !- Name",
            "1,                       !- Begin Month",
            "1,                       !- Begin Day of Month",
            ",                        !- Begin Year",
            "12,                      !- End Month",
            "31,                      !- End Day of Month",
            ",                        !- End Year",
            "Thursday,                !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP4,                     !- Name",
            "1,                       !- Begin Month",
            "1,                       !- Begin Day of Month",
            ",                        !- Begin Year",
            "12,                      !- End Month",
            "31,                      !- End Day of Month",
            ",                        !- End Year",
            ",                        !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP5,                     !- Name",
            "8,                       !- Begin Month",
            "18,                      !- Begin Day of Month",
            ",                        !- Begin Year",
            "12,                      !- End Month",
            "31,                      !- End Day of Month",
            ",                        !- End Year",
            "Wednesday,               !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP6,                     !- Name",
            "2,                       !- Begin Month",
            "29,                      !- Begin Day of Month",
            ",                        !- Begin Year",
            "12,                      !- End Month",
            "31,                      !- End Day of Month",
            ",                        !- End Year",
            "Saturday,                !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "RunPeriod,",
            "RP7,                     !- Name",
            "1,                       !- Begin Month",
            "1,                       !- Begin Day of Month",
            "2016,                    !- Begin Year",
            "3,                       !- End Month",
            "31,                      !- End Day of Month",
            "2020,                    !- End Year",
            ",                        !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "BUILDING, Simple One Zone (Wireframe DXF), 0.0, Suburbs, .04, .004, MinimalShadowing, 30, 6;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var errors_in_input = False
        var totalrps = 7
        Weather.GetRunPeriodData(*state, totalrps, errors_in_input)
        EXPECT_FALSE(errors_in_input)
        EXPECT_ENUM_EQ(Sched.DayType.Monday, state.dataWeather.RunPeriodInput[0].startWeekDay)
        EXPECT_EQ(2016, state.dataWeather.RunPeriodInput[0].startYear)
        EXPECT_EQ(2457448, state.dataWeather.RunPeriodInput[0].startJulianDate)
        EXPECT_EQ(2457451, state.dataWeather.RunPeriodInput[0].endJulianDate)
        EXPECT_ENUM_EQ(Sched.DayType.Wednesday, state.dataWeather.RunPeriodInput[1].startWeekDay)
        EXPECT_EQ(2012, state.dataWeather.RunPeriodInput[1].startYear)
        EXPECT_EQ(2455987, state.dataWeather.RunPeriodInput[1].startJulianDate)
        EXPECT_EQ(2455990, state.dataWeather.RunPeriodInput[1].endJulianDate)
        EXPECT_ENUM_EQ(Sched.DayType.Thursday, state.dataWeather.RunPeriodInput[2].startWeekDay)
        EXPECT_EQ(2015, state.dataWeather.RunPeriodInput[2].startYear)
        EXPECT_EQ(2457024, state.dataWeather.RunPeriodInput[2].startJulianDate)
        EXPECT_EQ(2457388, state.dataWeather.RunPeriodInput[2].endJulianDate)
        EXPECT_ENUM_EQ(Sched.DayType.Sunday, state.dataWeather.RunPeriodInput[3].startWeekDay)
        EXPECT_EQ(2017, state.dataWeather.RunPeriodInput[3].startYear)
        EXPECT_EQ(2457755, state.dataWeather.RunPeriodInput[3].startJulianDate)
        EXPECT_EQ(2458119, state.dataWeather.RunPeriodInput[3].endJulianDate)
        var startDays: StaticTuple[Float64, 12] = StaticTuple[Float64, 12](1.0, 4.0, 4.0, 7.0, 2.0, 5.0, 7.0, 3.0, 6.0, 1.0, 4.0, 6.0)
        for i in range(12):
            EXPECT_EQ(startDays[i], state.dataWeather.RunPeriodInput[3].monWeekDay[i])
        EXPECT_ENUM_EQ(Sched.DayType.Wednesday, state.dataWeather.RunPeriodInput[4].startWeekDay)
        EXPECT_EQ(2010, state.dataWeather.RunPeriodInput[4].startYear)
        EXPECT_EQ(2455427, state.dataWeather.RunPeriodInput[4].startJulianDate)
        EXPECT_EQ(2455562, state.dataWeather.RunPeriodInput[4].endJulianDate)
        EXPECT_ENUM_EQ(Sched.DayType.Saturday, state.dataWeather.RunPeriodInput[5].startWeekDay)
        EXPECT_EQ(1992, state.dataWeather.RunPeriodInput[5].startYear)
        EXPECT_EQ(2448682, state.dataWeather.RunPeriodInput[5].startJulianDate)
        EXPECT_EQ(2448988, state.dataWeather.RunPeriodInput[5].endJulianDate)
        EXPECT_ENUM_EQ(Sched.DayType.Friday, state.dataWeather.RunPeriodInput[6].startWeekDay)
        EXPECT_EQ(2016, state.dataWeather.RunPeriodInput[6].startYear)
        EXPECT_EQ(2457389, state.dataWeather.RunPeriodInput[6].startJulianDate)
        EXPECT_EQ(2458940, state.dataWeather.RunPeriodInput[6].endJulianDate)
    }

    # Test RunPeriod_EndYearOnly
    {
        var idf_objects = delimited_string([
            "SimulationControl, NO, NO, NO, YES, YES;",
            "Timestep,4;",
            "RunPeriod,",
            "RP1,                     !- Name",
            "2,                       !- Begin Month",
            "27,                      !- Begin Day of Month",
            ",                        !- Begin Year",
            "3,                       !- End Month",
            "3,                       !- End Day of Month",
            "1997,                    !- End Year",
            "Tuesday,                 !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "BUILDING, Simple One Zone (Wireframe DXF), 0.0, Suburbs, .04, .004, MinimalShadowing, 30, 6;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var errors_in_input = False
        var totalrps = 1
        Weather.GetRunPeriodData(*state, totalrps, errors_in_input)
        EXPECT_TRUE(errors_in_input)
    }

    # Test RunPeriod_NoName
    {
        var idf_objects = delimited_string([
            "RunPeriod,",
            "  ,                        !- Name",
            "  1,                       !- Begin Month",
            "  1,                       !- Begin Day of Month",
            "  2005,                    !- Begin Year",
            "  12,                      !- End Month",
            "  31,                      !- End Day of Month",
            "  ,                        !- End Year",
            "  Tuesday,                 !- Day of Week for Start Day",
            "  Yes,                     !- Use Weather File Holidays and Special Days",
            "  Yes,                     !- Use Weather File Daylight Saving Period",
            "  No,                      !- Apply Weekend Holiday Rule",
            "  Yes,                     !- Use Weather File Rain Indicators",
            "  Yes;                     !- Use Weather File Snow Indicators",
        ])
        ASSERT_FALSE(process_idf(idf_objects, False))
        var error_string = delimited_string([
            "   ** Severe  ** <root>[RunPeriod] - Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints: ''.",
            "   ** Severe  ** <root>[RunPeriod] - Object name is required and cannot be blank or whitespace"
        ])
        EXPECT_TRUE(compare_err_stream(error_string, True))
    }

    # Test RunPeriod_NameOfPeriodInWarning
    {
        {
            var idf_objects = delimited_string([
                "RunPeriod,",
                "  Jan,                     !- Name",
                "  1,                       !- Begin Month",
                "  1,                       !- Begin Day of Month",
                "  2005,                    !- Begin Year",
                "  12,                      !- End Month",
                "  31,                      !- End Day of Month",
                "  ,                        !- End Year",
                "  Tuesday,                 !- Day of Week for Start Day",
                "  Yes,                     !- Use Weather File Holidays and Special Days",
                "  Yes,                     !- Use Weather File Daylight Saving Period",
                "  No,                      !- Apply Weekend Holiday Rule",
                "  Yes,                     !- Use Weather File Rain Indicators",
                "  Yes;                     !- Use Weather File Snow Indicators",
            ])
            ASSERT_TRUE(process_idf(idf_objects))
            var ErrorsFound = False
            var totalrps = 1
            Weather.GetRunPeriodData(*state, totalrps, ErrorsFound)
            EXPECT_FALSE(ErrorsFound)
            var error_string = delimited_string([
                "   ** Warning ** RunPeriod: object=JAN, start weekday (TUESDAY) does not match the start year (2005), corrected to SATURDAY."
            ])
            EXPECT_TRUE(compare_err_stream(error_string, True))
        }
        {
            var idf_objects = delimited_string([
                "RunPeriod,",
                "  NotLeap,                 !- Name",
                "  2,                       !- Begin Month",
                "  29,                      !- Begin Day of Month",
                "  2005,                    !- Begin Year",
                "  12,                      !- End Month",
                "  31,                      !- End Day of Month",
                "  ,                        !- End Year",
                "  Tuesday,                 !- Day of Week for Start Day",
                "  Yes,                     !- Use Weather File Holidays and Special Days",
                "  Yes,                     !- Use Weather File Daylight Saving Period",
                "  No,                      !- Apply Weekend Holiday Rule",
                "  Yes,                     !- Use Weather File Rain Indicators",
                "  Yes;                     !- Use Weather File Snow Indicators",
            ])
            ASSERT_TRUE(process_idf(idf_objects))
            var ErrorsFound = False
            var totalrps = 1
            Weather.GetRunPeriodData(*state, totalrps, ErrorsFound)
            EXPECT_TRUE(ErrorsFound)
            var error_string = delimited_string([
                "   ** Severe  ** RunPeriod: object=NOTLEAP, start year (2005) is not a leap year but the requested start date is 2/29."
            ])
            EXPECT_TRUE(compare_err_stream(error_string, True))
        }
    }

    # Test SizingPeriod_WeatherFile
    {
        {
            var idf_objects = delimited_string([
                "SizingPeriod:WeatherFileDays,",
                "  Weather File Sizing Period,  !- Name",
                "  4,                       !- Begin Month",
                "  31,                      !- Begin Day of Month",
                "  7,                       !- End Month",
                "  25,                      !- End Day of Month",
                "  SummerDesignDay,         !- Day of Week for Start Day",
                "  No,                      !- Use Weather File Daylight Saving Period",
                "  No;                      !- Use Weather File Rain and Snow Indicators",
            ])
            ASSERT_TRUE(process_idf(idf_objects))
            var ErrorsFound = False
            Weather.GetRunPeriodDesignData(*state, ErrorsFound)
            EXPECT_TRUE(ErrorsFound)
            var error_string = delimited_string([
                "   ** Severe  ** SizingPeriod:WeatherFileDays: object=WEATHER FILE SIZING PERIOD Begin Day of Month invalid (Day of Month) [31]"
            ])
            EXPECT_TRUE(compare_err_stream(error_string, True))
        }
    }

    # Test RunPeriod_BadLeapDayFlagLogic
    {
        var idf_objects = delimited_string([
            "SimulationControl, NO, NO, NO, YES, YES;",
            "Timestep,4;",
            "RunPeriod,",
            "RP3,                     !- Name",
            "1,                       !- Begin Month",
            "1,                       !- Begin Day of Month",
            "2019,                    !- Begin Year",
            "12,                      !- End Month",
            "31,                      !- End Day of Month",
            ",                        !- End Year",
            ",                        !- Day of Week for Start Day",
            "Yes,                     !- Use Weather File Holidays and Special Days",
            "Yes,                     !- Use Weather File Daylight Saving Period",
            "No,                      !- Apply Weekend Holiday Rule",
            "Yes,                     !- Use Weather File Rain Indicators",
            "Yes;                     !- Use Weather File Snow Indicators",
            "BUILDING, Simple One Zone (Wireframe DXF), 0.0, Suburbs, .04, .004, MinimalShadowing, 30, 6;"
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var errors_in_input = False
        var totalrps = 1
        Weather.GetRunPeriodData(*state, totalrps, errors_in_input)
        EXPECT_FALSE(errors_in_input)
        state.dataWeather.Environment.allocate(1)
        state.dataEnvrn.TotDesDays = 0
        state.dataWeather.TotRunPers = 1
        state.dataWeather.TotRunDesPers = 0
        state.dataWeather.WFAllowsLeapYears = True  # This was hitting a bad bit of logic
        Weather.SetupEnvironmentTypes(*state)
        EXPECT_FALSE(state.dataWeather.Environment[0].IsLeapYear)
        EXPECT_EQ(365, state.dataWeather.Environment[0].TotalDays)
        state.dataWeather.Environment.deallocate()
    }