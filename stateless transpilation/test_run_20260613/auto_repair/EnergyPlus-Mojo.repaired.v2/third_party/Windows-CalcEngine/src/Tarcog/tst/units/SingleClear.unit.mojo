from testing import test, assert_true, assert_equal
from memory import DynamicVector
from WCETarcog import *
from WCECommon import *

def expect_near(actual: Float64, expected: Float64, tol: Float64 = 1e-5) raises:
    if abs(actual - expected) > tol:
        raise Error(
            "Values differ: actual=" + str(actual) +
            ", expected=" + str(expected) + ", tol=" + str(tol)
        )

struct TestSingleClear:
    var m_TarcogSystem: Tarcog.ISO15099.CSystem

    def SetUp(self inout) raises:
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 789.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky,
            Tarcog.ISO15099.SkyModel.AllSpecified
        )
        assert_true(Outdoor != None)
        Outdoor.setHCoeffModel(
            Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH
        )
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(Indoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(
            solidLayerThickness, solidLayerConductance
        )
        assert_true(aSolidLayer != None)
        aSolidLayer.setSolarAbsorptance(0.094189159572, solarRadiation)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        var system = Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor)
        self.m_TarcogSystem = system
        assert_true(self.m_TarcogSystem != None)

    def GetSystem(self) -> Tarcog.ISO15099.CSystem:
        return self.m_TarcogSystem

@test
def Test1() raises:
    # SCOPED_TRACE("Begin Test: Single Clear - U-value")
    var fixture = TestSingleClear()
    fixture.SetUp()
    var aSystem = fixture.GetSystem()
    assert_true(aSystem != None)
    var Temperature = aSystem.getTemperatures(
        Tarcog.ISO15099.System.Uvalue
    )
    var correctTemperature = DynamicVector[Float64](
        [297.207035, 297.14470]
    )
    assert_equal(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        expect_near(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities(
        Tarcog.ISO15099.System.Uvalue
    )
    var correctRadiosity = DynamicVector[Float64](
        [432.444546, 439.201749]
    )
    assert_equal(len(correctRadiosity), len(Radiosity))
    for i in range(len(correctRadiosity)):
        expect_near(correctRadiosity[i], Radiosity[i], 1e-5)
    var numOfIterations = aSystem.getNumberOfIterations(
        Tarcog.ISO15099.System.Uvalue
    )
    assert_equal(19, numOfIterations)
    Temperature = aSystem.getTemperatures(
        Tarcog.ISO15099.System.SHGC
    )
    correctTemperature = DynamicVector[Float64](
        [299.116601, 299.121730]
    )
    assert_equal(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        expect_near(correctTemperature[i], Temperature[i], 1e-5)
    Radiosity = aSystem.getRadiosities(
        Tarcog.ISO15099.System.SHGC
    )
    correctRadiosity = DynamicVector[Float64](
        [442.087153, 449.182158]
    )
    assert_equal(len(correctRadiosity), len(Radiosity))
    for i in range(len(correctRadiosity)):
        expect_near(correctRadiosity[i], Radiosity[i], 1e-5)
    numOfIterations = aSystem.getNumberOfIterations(
        Tarcog.ISO15099.System.SHGC
    )
    assert_equal(19, numOfIterations)
    var heatFlow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.Uvalue,
        Tarcog.ISO15099.Environment.Indoor
    )
    expect_near(heatFlow, -20.450949, 1e-5)
    heatFlow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.Uvalue,
        Tarcog.ISO15099.Environment.Outdoor
    )
    expect_near(heatFlow, -20.450949, 1e-5)
    heatFlow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.SHGC,
        Tarcog.ISO15099.Environment.Indoor
    )
    expect_near(heatFlow, -35.474878, 1e-5)
    heatFlow = aSystem.getHeatFlow(
        Tarcog.ISO15099.System.SHGC,
        Tarcog.ISO15099.Environment.Outdoor
    )
    expect_near(heatFlow, 38.840370, 1e-5)
    var UValue = aSystem.getUValue()
    expect_near(UValue, 5.493806, 1e-5)
    var SHGC = aSystem.getSHGC(0.831249)
    expect_near(SHGC, 0.850291, 1e-5)