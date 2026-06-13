from gtest import Test, TestFixture, Expect, Assert
from EnergyPlus.ConfiguredFunctions import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.ElectricPowerServiceManager import *
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import *
from EnergyPlus.GroundTemperatureModeling.FiniteDifferenceGroundTemperatureModel import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.WeatherManager import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from math import sin, Pi
from memory import Pointer
from os import Path
from utils import delimited_string, compare_err_stream, process_idf, configured_source_directory, createFacilityElectricPowerServiceObject

@fixture
class FiniteDiffGroundTempModelTest(EnergyPlusFixture):

@fixture
class FiniteDiffGroundTempModel_GetWeather_NoWeather(EnergyPlusFixture):

@fixture
class FiniteDiffGroundTempModel_GetWeather_Weather(EnergyPlusFixture):

def test_FiniteDiffGroundTempModelTest():
    var thisModel = GroundTemp.FiniteDiffGroundTempsModel()
    thisModel.modelType = GroundTemp.ModelType.FiniteDiff
    thisModel.Name = "Test"
    thisModel.baseConductivity = 1.08
    thisModel.baseDensity = 962.0
    thisModel.baseSpecificHeat = 2576.0
    thisModel.waterContent = 30.0 / 100.0
    thisModel.saturatedWaterContent = 50.0 / 100.0
    thisModel.evapotransCoeff = 0.408
    Expect.NEAR(2.0, thisModel.interpolate(2.0, 3.0, 1.0, 3.0, 1.0), 0.0000001)
    thisModel.developMesh()
    thisModel.weatherDataArray.dimension(state.dataWeather.NumDaysInYear)
    var drybulb_minTemp: Float64 = 5
    var drybulb_amp: Float64 = 10
    var relHum_const: Float64 = 0.5
    var windSpeed_const: Float64 = 3.0
    var solar_min: Float64 = 100
    var solar_amp: Float64 = 100
    for day in range(1, state.dataWeather.NumDaysInYear + 1):
        var tdwd = thisModel.weatherDataArray[day] # "This day weather data"
        var theta: Float64 = 2 * Pi * day / state.dataWeather.NumDaysInYear
        var omega: Float64 = 2 * Pi * 130 / state.dataWeather.NumDaysInYear # Shifts min to around the end of Jan
        tdwd.dryBulbTemp = drybulb_amp * sin(theta - omega) + (drybulb_minTemp + drybulb_amp)
        tdwd.relativeHumidity = relHum_const
        tdwd.windSpeed = windSpeed_const
        tdwd.horizontalRadiation = solar_amp * sin(theta - omega) + (solar_min + solar_amp)
        tdwd.airDensity = 1.2
    thisModel.annualAveAirTemp = 15.0
    thisModel.maxDailyAirTemp = 25.0
    thisModel.minDailyAirTemp = 5.0
    thisModel.dayOfMinDailyAirTemp = 30
    thisModel.performSimulation(state[])
    Expect.NEAR(4.51, thisModel.getGroundTempAtTimeInMonths(state[], 0.0, 1), 0.01)
    Expect.NEAR(19.14, thisModel.getGroundTempAtTimeInMonths(state[], 0.0, 6), 0.01)
    Expect.NEAR(7.96, thisModel.getGroundTempAtTimeInMonths(state[], 0.0, 12), 0.01)
    Expect.NEAR(3.46, thisModel.getGroundTempAtTimeInMonths(state[], 0.0, 14), 0.01)
    Expect.NEAR(14.36, thisModel.getGroundTempAtTimeInMonths(state[], 3.0, 1), 0.01)
    Expect.NEAR(11.78, thisModel.getGroundTempAtTimeInMonths(state[], 3.0, 6), 0.01)
    Expect.NEAR(15.57, thisModel.getGroundTempAtTimeInMonths(state[], 3.0, 12), 0.01)
    Expect.NEAR(14.58, thisModel.getGroundTempAtTimeInMonths(state[], 25.0, 1), 0.01)
    Expect.NEAR(14.55, thisModel.getGroundTempAtTimeInMonths(state[], 25.0, 6), 0.01)
    Expect.NEAR(14.53, thisModel.getGroundTempAtTimeInMonths(state[], 25.0, 12), 0.01)
    Expect.NEAR(5.04, thisModel.getGroundTempAtTimeInSeconds(state[], 0.0, 0.0), 0.01)
    Expect.NEAR(19.28, thisModel.getGroundTempAtTimeInSeconds(state[], 0.0, 14342400), 0.01)
    Expect.NEAR(7.32, thisModel.getGroundTempAtTimeInSeconds(state[], 0.0, 30153600), 0.01)
    Expect.NEAR(3.53, thisModel.getGroundTempAtTimeInSeconds(state[], 0.0, 35510400), 0.01)
    Expect.NEAR(14.36, thisModel.getGroundTempAtTimeInSeconds(state[], 3.0, 1296000), 0.01)
    Expect.NEAR(11.80, thisModel.getGroundTempAtTimeInSeconds(state[], 3.0, 14342400), 0.01)
    Expect.NEAR(15.46, thisModel.getGroundTempAtTimeInSeconds(state[], 3.0, 30153600), 0.01)
    Expect.NEAR(14.52, thisModel.getGroundTempAtTimeInSeconds(state[], 25.0, 0.0), 0.01)
    Expect.NEAR(14.55, thisModel.getGroundTempAtTimeInSeconds(state[], 25.0, 14342400), 0.01)
    Expect.NEAR(14.52, thisModel.getGroundTempAtTimeInSeconds(state[], 25.0, 30153600), 0.01)

def test_FiniteDiffGroundTempModel_GetWeather_NoWeather():
    var thisModel = GroundTemp.FiniteDiffGroundTempsModel()
    thisModel.modelType = GroundTemp.ModelType.FiniteDiff
    thisModel.Name = "Test"
    thisModel.baseConductivity = 1.08
    thisModel.baseDensity = 962.0
    thisModel.baseSpecificHeat = 2576.0
    thisModel.waterContent = 30.0 / 100.0
    thisModel.saturatedWaterContent = 50.0 / 100.0
    thisModel.evapotransCoeff = 0.408
    Assert.THROW(thisModel.getWeatherData(state[]), RuntimeError)
    var error_string: String = delimited_string(
        {"   ** Severe  ** Site:GroundTemperature:Undisturbed:FiniteDifference -- using this model requires specification of a weather file.",
         "   **   ~~~   ** Either place in.epw in the working directory or specify a weather file on the command line using -w /path/to/weather.epw",
         "   **  Fatal  ** Simulation halted due to input error in ground temperature model.",
         "   ...Summary of Errors that led to program termination:",
         "   ..... Reference severe error count=1",
         "   ..... Last severe error=Site:GroundTemperature:Undisturbed:FiniteDifference -- using this model requires specification of a weather "
         "file."})
    Expect.TRUE(compare_err_stream(error_string, True))

def test_FiniteDiffGroundTempModel_GetWeather_Weather():
    var idf_objects: String = delimited_string({
        "Timestep,4;"
        "SimulationControl,",
        "  Yes,                     !- Do Zone Sizing Calculation",
        "  Yes,                     !- Do System Sizing Calculation",
        "  No,                      !- Do Plant Sizing Calculation",
        "  Yes,                     !- Run Simulation for Sizing Periods",
        "  No;                      !- Run Simulation for Weather File Run Periods",
        "RunPeriod,",
        "  January,                 !- Name",
        "  1,                       !- Begin Month",
        "  1,                       !- Begin Day of Month",
        "  ,                        !- Begin Year",
        "  1,                       !- End Month",
        "  31,                      !- End Day of Month",
        "  ,                        !- End Year",
        "  Tuesday,                 !- Day of Week for Start Day",
        "  Yes,                     !- Use Weather File Holidays and Special Days",
        "  Yes,                     !- Use Weather File Daylight Saving Period",
        "  No,                      !- Apply Weekend Holiday Rule",
        "  Yes,                     !- Use Weather File Rain Indicators",
        "  Yes;                     !- Use Weather File Snow Indicators",
        "Site:Location,",
        "  CHICAGO_IL_USA TMY2-94846,  !- Name",
        "  41.78,                   !- Latitude {deg}",
        "  -87.75,                  !- Longitude {deg}",
        "  -6.00,                   !- Time Zone {hr}",
        "  190.00;                  !- Elevation {m}",
        "SizingPeriod:DesignDay,",
        "  CHICAGO_IL_USA Annual Cooling 1% Design Conditions DB/MCWB,  !- Name",
        "  7,                       !- Month",
        "  21,                      !- Day of Month",
        "  SummerDesignDay,         !- Day Type",
        "  31.5,                    !- Maximum Dry-Bulb Temperature {C}",
        "  10.7,                    !- Daily Dry-Bulb Temperature Range {deltaC}",
        "  ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "  ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "  Wetbulb,                 !- Humidity Condition Type",
        "  23.0,                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "  ,                        !- Humidity Condition Day Schedule Name",
        "  ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "  ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "  ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "  99063.,                  !- Barometric Pressure {Pa}",
        "  5.3,                     !- Wind Speed {m/s}",
        "  230,                     !- Wind Direction {deg}",
        "  No,                      !- Rain Indicator",
        "  No,                      !- Snow Indicator",
        "  No,                      !- Daylight Saving Time Indicator",
        "  ASHRAEClearSky,          !- Solar Model Indicator",
        "  ,                        !- Beam Solar Day Schedule Name",
        "  ,                        !- Diffuse Solar Day Schedule Name",
        "  ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "  ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "  1.0;                     !- Sky Clearness",
        "SizingPeriod:DesignDay,",
        "  CHICAGO_IL_USA Annual Heating 99% Design Conditions DB,  !- Name",
        "  1,                       !- Month",
        "  21,                      !- Day of Month",
        "  WinterDesignDay,         !- Day Type",
        "  -17.3,                   !- Maximum Dry-Bulb Temperature {C}",
        "  0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}",
        "  ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "  ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "  Wetbulb,                 !- Humidity Condition Type",
        "  -17.3,                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "  ,                        !- Humidity Condition Day Schedule Name",
        "  ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "  ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "  ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "  99063.,                  !- Barometric Pressure {Pa}",
        "  4.9,                     !- Wind Speed {m/s}",
        "  270,                     !- Wind Direction {deg}",
        "  No,                      !- Rain Indicator",
        "  No,                      !- Snow Indicator",
        "  No,                      !- Daylight Saving Time Indicator",
        "  ASHRAEClearSky,          !- Solar Model Indicator",
        "  ,                        !- Beam Solar Day Schedule Name",
        "  ,                        !- Diffuse Solar Day Schedule Name",
        "  ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "  ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "  0.0;                     !- Sky Clearness",
    })
    Assert.TRUE(process_idf(idf_objects))
    state.dataWeather.WeatherFileExists = True
    state.files.inputWeatherFilePath.filePath = Path(configured_source_directory()) / "weather/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
    state.dataGlobal.BeginSimFlag = True
    SimulationManager.GetProjectData(state[])
    Expect.EQ(state.dataGlobal.TimeStepsInHour, 4)
    createFacilityElectricPowerServiceObject(state[])
    var ErrorsFound: Bool = False
    SimulationManager.SetupSimulation(state[], ErrorsFound)
    Assert.FALSE(ErrorsFound)
    Expect.EQ(state.dataWeather.NumOfEnvrn, 3)
    Expect.EQ(state.dataEnvrn.TotDesDays, 2)
    Expect.EQ(state.dataWeather.TotRunPers, 1)
    var thisModel = GroundTemp.FiniteDiffGroundTempsModel()
    thisModel.modelType = GroundTemp.ModelType.FiniteDiff
    thisModel.Name = "Test"
    thisModel.baseConductivity = 1.08
    thisModel.baseDensity = 962.0
    thisModel.baseSpecificHeat = 2576.0
    thisModel.waterContent = 30.0 / 100.0
    thisModel.saturatedWaterContent = 50.0 / 100.0
    thisModel.evapotransCoeff = 0.408
    thisModel.getWeatherData(state[])
    Expect.EQ(state.dataWeather.NumOfEnvrn, 3)
    Expect.EQ(state.dataEnvrn.TotDesDays, 2)
    Expect.EQ(state.dataWeather.TotRunPers, 1)
    Expect.EQ(365, thisModel.weatherDataArray.size())
    var firstDay = thisModel.weatherDataArray[1]
    Expect.DOUBLE_EQ(firstDay.dryBulbTemp, -5.4)
    Expect.NEAR(firstDay.relativeHumidity, 0.7083, 0.005)
    Expect.NEAR(firstDay.windSpeed, 2.8083, 0.001)
    Expect.NEAR(firstDay.horizontalRadiation, 68, 2)