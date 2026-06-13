# Mojo unit test conversion of CoilCoolingDXCurveFitSpeed.unit.cc
# Faithful 1:1 translation, no refactoring.

from gtest import expect_true, expect_eq, expect_near
# Note: For Mojo we define simple test assertions; they may be replaced with a proper testing framework.

from EnergyPlus.Coils.CoilCoolingDXCurveFitOperatingMode import CoilCoolingDXCurveFitOperatingMode
from EnergyPlus.Coils.CoilCoolingDXCurveFitSpeed import CoilCoolingDXCurveFitSpeed
from EnergyPlus.DataLoopNode import Node
from ...Coils.CoilCoolingDXFixture import CoilCoolingDXTest, process_idf

struct CoilCoolingDXTestWrapper:

def CoilCoolingDXCurveFitSpeedInput():
    var test_fixture = CoilCoolingDXTest()
    var idf_objects: String = test_fixture.getSpeedObjectString("speed1")
    expect_true(process_idf(idf_objects, False))
    test_fixture.state.init_state(test_fixture.state)
    var thisSpeed = CoilCoolingDXCurveFitSpeed(test_fixture.state, "speed1")
    expect_eq(thisSpeed.name, "SPEED1")

def CoilCoolingDXCurveFitSpeedTest():
    var test_fixture = CoilCoolingDXTest()
    var idf_objects: String = test_fixture.getSpeedObjectString("speed1")
    expect_true(process_idf(idf_objects, False))
    test_fixture.state.init_state(test_fixture.state)
    var thisSpeed = CoilCoolingDXCurveFitSpeed(test_fixture.state, "speed1")
    expect_eq(thisSpeed.name, "SPEED1")

    var thisMode = CoilCoolingDXCurveFitOperatingMode()
    thisMode.ratedGrossTotalCap = 12000
    thisMode.ratedEvapAirFlowRate = 100
    thisMode.ratedCondAirFlowRate = 200

    var inletNode = Node.NodeData()
    inletNode.Temp = 20.0
    inletNode.HumRat = 0.008
    inletNode.Enthalpy = 40000.0

    var outletNode = Node.NodeData()

    thisSpeed.PLR = 1.0
    thisSpeed.ambPressure = 101325.0
    inletNode.Press = thisSpeed.ambPressure
    thisSpeed.AirFF = 1.0
    thisSpeed.rated_total_capacity = 3000.0
    thisSpeed.RatedAirMassFlowRate = 1.0
    thisSpeed.grossRatedSHR = 0.75
    thisSpeed.RatedCBF = 0.09
    thisSpeed.RatedEIR = 0.30
    thisSpeed.AirMassFlow = 1.0

    var fanOp = HVAC.FanOp.Invalid
    var condInletTemp: Float64 = 24.0
    thisSpeed.CalcSpeedOutput(test_fixture.state, inletNode, outletNode, thisSpeed.PLR, fanOp, condInletTemp)

    expect_near(outletNode.Temp, 17.791, 0.001)
    expect_near(outletNode.HumRat, 0.00754, 0.0001)
    expect_near(outletNode.Enthalpy, 37000.0, 0.1)
    expect_near(thisSpeed.fullLoadPower, 900.0, 0.1)
    expect_near(thisSpeed.RTF, 1.0, 0.01)

# Note: The original C++ used TEST_F, which creates an implicit test class.
# Here we simply define the test bodies as standalone functions.
# To run the tests, a test harness should call these functions.