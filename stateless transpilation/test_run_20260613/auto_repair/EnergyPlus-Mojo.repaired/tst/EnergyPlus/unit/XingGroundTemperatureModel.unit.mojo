from testing import TestFixture, expect_equal, expect_near
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData

@fixture
def EnergyPlusFixture():
    return EnergyPlusFixture()

def test_XingGroundTempsModelTest(fixture: EnergyPlusFixture):
    state = fixture.state
    idf_objects = delimited_string([
        "Site:GroundTemperature:Undisturbed:Xing,",
        "	Test,			!- Name of object",
        "	1.08,			!- Soil Thermal Conductivity {W/m-K}",
        "	962,			!- Soil Density {kg/m3}",
        "	2576,			!- Soil Specific Heat {J/kg-K}",
        "	11.1,			!- Average Soil Surface Temperature {C}",
        "	13.4,			!- Soil Surface Temperature Amplitude 1 {deltaC}",
        "	0.7,			!- Soil Surface Temperature Amplitude 2 {deltaC}",
        "	25,			!- Phase Shift of Temperature Amplitude 1 {days}",
        "	30;			!- Phase Shift of Temperature Amplitude 2 {days}",
    ])
    expect_true(process_idf(idf_objects))
    thisModel = GroundTemp.GetGroundTempModelAndInit(*state, GroundTemp.ModelType.Xing, "TEST")
    expect_near(-1.43, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 0.0), 0.01)
    expect_near(2.15, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 6393600), 0.1)   # March 15
    expect_near(19.74, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 22291200), 0.1) # Sept 15
    expect_near(-2.03, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 35510400), 0.1) # Feb 15 of next year
    expect_near(-2.71, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 1), 0.1)  # January
    expect_near(23.61, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 7), 0.1)  # July
    expect_near(1.62, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 12), 0.1)  # December
    expect_near(-2.12, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 14), 0.1) # Feb of next year
    expect_near(11.1, thisModel.getGroundTempAtTimeInMonths(*state, 100.0, 1), 0.1) # January--deep

def test_XingGroundTempsGetInputTest(fixture: EnergyPlusFixture):
    state = fixture.state
    idf_objects = delimited_string([
        "Site:GroundTemperature:Undisturbed:Xing,",
        "    Test1,   !- Name of object",
        "    1.0,     !- Soil Thermal Conductivity {W/m-K}",
        "    1000.0,  !- Soil Density {kg/m3}",
        "    2500,    !- Soil Specific Heat {J/kg-K}",
        "    10.0,    !- Average Soil Surface Temperature {C}",
        "    12.0,    !- Soil Surface Temperature Amplitude 1 {deltaC}",
        "    1.0,     !- Soil Surface Temperature Amplitude 2 {deltaC}",
        "    25,      !- Phase Shift of Temperature Amplitude 1 {days}",
        "    30;      !- Phase Shift of Temperature Amplitude 2 {days}",
        "",
        "Site:GroundTemperature:Undisturbed:Xing,",
        "    Test2,   !- Name of object",
        "    2.0,     !- Soil Thermal Conductivity {W/m-K}",
        "    1200,    !- Soil Density {kg/m3}",
        "    2400,    !- Soil Specific Heat {J/kg-K}",
        "    11.1,    !- Average Soil Surface Temperature {C}",
        "    22.2,    !- Soil Surface Temperature Amplitude 1 {deltaC}",
        "    2.5,     !- Soil Surface Temperature Amplitude 2 {deltaC}",
        "    20,      !- Phase Shift of Temperature Amplitude 1 {days}",
        "    40;      !- Phase Shift of Temperature Amplitude 2 {days}",
    ])
    expect_true(process_idf(idf_objects))
    thisModel1 = GroundTemp.GetGroundTempModelAndInit(*state, GroundTemp.ModelType.Xing, "TEST1")
    expect_equal(thisModel1.Name, "TEST1")
    expect_equal(thisModel1.modelType, GroundTemp.ModelType.Xing)
    thisModel2 = GroundTemp.GetGroundTempModelAndInit(*state, GroundTemp.ModelType.Xing, "TEST2")
    expect_equal(thisModel2.Name, "TEST2")
    expect_equal(thisModel2.modelType, GroundTemp.ModelType.Xing)