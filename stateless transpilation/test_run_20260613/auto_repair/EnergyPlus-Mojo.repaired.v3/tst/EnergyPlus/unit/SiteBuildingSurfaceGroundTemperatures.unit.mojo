from gtest import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string
from EnergyPlus.Data.EnergyPlusData import *
using EnergyPlus

@fixture(EnergyPlusFixture)
def SiteBuildingSurfaceGroundTempTest():
    let idf_objects = delimited_string({
        "Site:GroundTemperature:BuildingSurface,",
        "	21.00,	!- January",
        "	22.00,	!- February",
        "	23.00,	!- March",
        "	24.00,	!- April",
        "	25.00,	!- May",
        "	26.00,	!- June",
        "	27.00,	!- July",
        "	28.00,	!- August",
        "	29.00,	!- September",
        "	30.00,	!- October",
        "	31.00,	!- November",
        "	32.00;	!- December",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    var thisModel = GroundTemp.GetGroundTempModelAndInit(*state, GroundTemp.ModelType.SiteBuildingSurface, "TEST")
    EXPECT_NEAR(21.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 1), 0.1)  // January
    EXPECT_NEAR(32.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 12), 0.1) // December
    EXPECT_NEAR(22.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 14), 0.1) // Feb of next year
    EXPECT_NEAR(23.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 6393600), 0.1)  // March 15
    EXPECT_NEAR(29.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 22291200), 0.1) // Sept 15
    EXPECT_NEAR(22.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 35510400), 0.1) // Feb 15 of next year
