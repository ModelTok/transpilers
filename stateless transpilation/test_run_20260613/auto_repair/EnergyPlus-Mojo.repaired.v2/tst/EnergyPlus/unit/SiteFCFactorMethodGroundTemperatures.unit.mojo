from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import GroundTemp
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData

@test
def SiteFCFactorMethodGroundTempTest():
    var idf_objects: String = delimited_string(
        List[String](
            "Site:GroundTemperature:FCFactorMethod,",
            "	21.00,	!- January",
            "	22.00,	!- February",
            "	23.00,	!- March",
            "	24.00,	!- April",
            "	25.00,	!- May",
            "	26.00,	!- June",
            "	27.00,	!- July",
            "	28.00,	!- August",
            "	29.00,	!- Septeber",
            "	30.00,	!- October",
            "	31.00,	!- November",
            "	32.00;	!- December",
        )
    )
    assert_true(process_idf(idf_objects))
    var thisModel = GroundTemp.GetGroundTempModelAndInit(*state, GroundTemp.ModelType.SiteFCFactorMethod, "TEST")
    assert_approx_equal(21.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 1), 0.1)   // January
    assert_approx_equal(32.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 12), 0.1)  // December
    assert_approx_equal(22.0, thisModel.getGroundTempAtTimeInMonths(*state, 0.0, 14), 0.1)   // Feb of next year
    assert_approx_equal(23.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 6393600), 0.1)   // March 15
    assert_approx_equal(29.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 22291200), 0.1)  // Sept 15
    assert_approx_equal(22.0, thisModel.getGroundTempAtTimeInSeconds(*state, 0.0, 35510400), 0.1)  // Feb 15 of next year