from EnergyPlus.DataIPShortCuts import delimited_string
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import GroundTemp
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData

def KusudaAchenbachGroundTempModelTest1():
    var fixture = EnergyPlusFixture()
    var idf_objects = delimited_string((
        "Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
        "	Test,	!- Name of ground temperature object",
        "	1.08,		!- Soil Thermal Conductivity",
        "	980,		!- Soil Density",
        "	2570,		!- Soil Specific Heat",
        "	15.0,		!- Average Surface Temperature",
        "	5.0,		!- Average Amplitude of Surface Temperature",
        "	1;			!- Phase Shift of Minimum Surface Temperature",
    ))
    assert(fixture.process_idf(idf_objects))
    var thisModel = GroundTemp.GetGroundTempModelAndInit(fixture.state, GroundTemp.ModelType.Kusuda, "TEST")
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 0.0) - 10.0) <= 0.01)      // Jan 1
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 15768000) - 20.0) <= 0.01) // June 1
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 31449600) - 10.0) <= 0.01) // Dec 30
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 100.0, 0.0) - 15.0) <= 0.01)    // Very deep
    assert(abs(thisModel.getGroundTempAtTimeInMonths(fixture.state, 0.0, 1) - 10.15) <= 0.01) // January
    assert(abs(thisModel.getGroundTempAtTimeInMonths(fixture.state, 0.0, 6) - 19.75) <= 0.01) // June

def KusudaAchenbachGroundTempModelTest2(): // lNumericFieldBlanks not working correctly for this test
    var fixture = EnergyPlusFixture()
    var idf_objects = delimited_string((
        "Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
        "	Test,	!- Name of ground temperature object",
        "	1.08,		!- Soil Thermal Conductivity",
        "	980,		!- Soil Density",
        "	2570,		!- Soil Specific Heat",
        "	,			!- Average Surface Temperature",
        "	,			!- Average Amplitude of Surface Temperature",
        "	;			!- Phase Shift of Minimum Surface Temperature",
        "Site:GroundTemperature:Shallow,",
        "	16.00,	!- January",
        "	15.00,	!- February",
        "	16.00,	!- March",
        "	17.00,	!- April",
        "	18.00,	!- May",
        "	19.00,	!- June",
        "	20.00,	!- July",
        "	21.00,	!- August",
        "	20.00,	!- September",
        "	19.00,	!- October",
        "	18.00,	!- November",
        "	17.00;	!- December",
    ))
    assert(fixture.process_idf(idf_objects))
    var thisModel = GroundTemp.GetGroundTempModelAndInit(fixture.state, GroundTemp.ModelType.Kusuda, "TEST")
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 0.0) - 16.46) <= 0.01)      // Jan 1
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 11664000) - 17.17) <= 0.01) // May 15
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 24883200) - 20.12) <= 0.01) // Oct 15
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 0.0, 31536000) - 16.46) <= 0.01) // Dec 31
    assert(abs(thisModel.getGroundTempAtTimeInSeconds(fixture.state, 100.0, 24883200) - 18.0) <= 0.01) // Oct 15--deep