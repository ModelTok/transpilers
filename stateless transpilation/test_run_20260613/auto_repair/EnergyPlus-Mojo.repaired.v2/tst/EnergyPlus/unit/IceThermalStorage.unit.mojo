from testing import assert_approx_equal  # use for EXPECT_NEAR
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.CurveManager import AddCurve, CurveType
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.General import General  # if needed
from EnergyPlus.IceThermalStorage import IceThermalStorage, CalcQstar, CurveVars

# Define a simple test runner
def test_IceThermalStorage_CalcQstarTest():
    # Setup similar to TEST_F
    var state = EnergyPlusData()  # assume fixture provides this
    var TotDetailedIce: Int = 4
    var IceStorageCurveType: CurveVars
    var CurveAnswer: F64 = 0.0
    var ExpectedValue: F64 = 0.0
    var Tolerance: F64 = 0.001

    state.dataIceThermalStorage.DetailedIceStorage.allocate(TotDetailedIce)  # equivalent
    state.dataGlobal.BeginEnvrnFlag = False

    IceStorageCurveType = CurveVars.FracChargedLMTD
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.QuadraticLinear
    curve1.inputLimits[0].max = 1.0
    curve1.inputLimits[0].min = 0.0
    curve1.inputLimits[1].max = 10.0
    curve1.inputLimits[1].min = 0.0
    curve1.coeff[0] = 0.1
    curve1.coeff[1] = 0.2
    curve1.coeff[2] = 0.3
    curve1.coeff[3] = 0.4
    curve1.coeff[4] = 0.5
    curve1.coeff[5] = 0.6
    CurveAnswer = CalcQstar(state, curve1.Num, IceStorageCurveType, 0.5, 1.5, 0.25)
    ExpectedValue = 1.475
    assert_approx_equal(ExpectedValue, CurveAnswer, Tolerance)

    IceStorageCurveType = CurveVars.FracDischargedLMTD
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.BiQuadratic
    curve2.inputLimits[0].max = 1.0
    curve2.inputLimits[0].min = 0.0
    curve2.inputLimits[1].max = 10.0
    curve2.inputLimits[1].min = 0.0
    curve2.coeff[0] = 0.1
    curve2.coeff[1] = 0.2
    curve2.coeff[2] = 0.3
    curve2.coeff[3] = 0.4
    curve2.coeff[4] = 0.5
    curve2.coeff[5] = 0.6
    CurveAnswer = CalcQstar(state, curve2.Num, IceStorageCurveType, 0.4, 1.2, 0.25)
    ExpectedValue = 1.960
    assert_approx_equal(ExpectedValue, CurveAnswer, Tolerance)

    IceStorageCurveType = CurveVars.LMTDMassFlow
    var curve3 = AddCurve(state, "Curve3")
    curve3.curveType = CurveType.CubicLinear
    curve3.inputLimits[0].max = 10.0
    curve3.inputLimits[0].min = 0.0
    curve3.inputLimits[1].max = 1.0
    curve3.inputLimits[1].min = 0.0
    curve3.coeff[0] = 0.1
    curve3.coeff[1] = 0.2
    curve3.coeff[2] = 0.3
    curve3.coeff[3] = 0.4
    curve3.coeff[4] = 0.5
    curve3.coeff[5] = 0.6
    CurveAnswer = CalcQstar(state, curve3.Num, IceStorageCurveType, 0.4, 1.2, 0.25)
    ExpectedValue = 1.768
    assert_approx_equal(ExpectedValue, CurveAnswer, Tolerance)

    IceStorageCurveType = CurveVars.LMTDFracCharged
    var curve4 = AddCurve(state, "Curve4")
    curve4.curveType = CurveType.CubicLinear
    curve4.inputLimits[0].max = 10.0
    curve4.inputLimits[0].min = 0.0
    curve4.inputLimits[1].max = 1.0
    curve4.inputLimits[1].min = 0.0
    curve4.coeff[0] = 0.1
    curve4.coeff[1] = 0.2
    curve4.coeff[2] = 0.3
    curve4.coeff[3] = 0.4
    curve4.coeff[4] = 0.5
    curve4.coeff[5] = 0.6
    CurveAnswer = CalcQstar(state, curve4.Num, IceStorageCurveType, 0.4, 1.2, 0.25)
    ExpectedValue = 1.951
    assert_approx_equal(ExpectedValue, CurveAnswer, Tolerance)

# Run the test
def main():
    test_IceThermalStorage_CalcQstarTest()
    print("All IceThermalStorage tests passed.")