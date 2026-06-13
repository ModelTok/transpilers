from CoilCoolingDXFixture import CoilCoolingDXTest, process_idf
from CoilCoolingDXCurveFitPerformance import CoilCoolingDXCurveFitPerformance
from DataHVACGlobals import HVAC
from testing import test

@test
def CoilCoolingDXCurveFitPerformanceInput():
    var fixture = CoilCoolingDXTest()
    var idf_objects: String = fixture.getPerformanceObjectString("coilPerformance", False, 2)
    assert process_idf(idf_objects, False)
    fixture.state.init_state(fixture.state)
    var thisPerf = CoilCoolingDXCurveFitPerformance(fixture.state, "coilPerformance")
    assert thisPerf.name == "COILPERFORMANCE"
    assert thisPerf.normalMode.name == "BASEOPERATINGMODE"
    assert int(thisPerf.maxAvailCoilMode) == int(HVAC.CoilMode.Normal)

@test
def CoilCoolingDXCurveFitPerformanceInputAlternateMode():
    var fixture = CoilCoolingDXTest()
    var idf_objects: String = fixture.getPerformanceObjectString("coilPerformance", True, 2)
    assert process_idf(idf_objects, False)
    fixture.state.init_state(fixture.state)
    var thisPerf = CoilCoolingDXCurveFitPerformance(fixture.state, "coilPerformance")
    assert thisPerf.name == "COILPERFORMANCE"
    assert thisPerf.normalMode.name == "BASEOPERATINGMODE"
    assert int(thisPerf.maxAvailCoilMode) == int(HVAC.CoilMode.Enhanced)