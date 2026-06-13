from WCETarcog import (
    CSingleSystem,
    Environments,
    Layers,
    CIGU,
    SkyModel,
    BoundaryConditionsCoeffModel,
    Environment,
)
from testing import assert_true, assert_eq, assert_approx_eq

struct TestDoubleClearSingleSystemNoSun:
    var m_TarcogSystem: Optional[CSingleSystem]

    def __init__(inout self):
        self.m_TarcogSystem = None
        self.SetUp()

    def SetUp(inout self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        assert_true(Outdoor is not None)
        Outdoor.value().setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        assert_true(Indoor is not None)
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Layers.solid(solidLayerThickness, solidLayerConductance)
        var layer2 = Layers.solid(solidLayerThickness, solidLayerConductance)
        var gapThickness = 0.012
        var m_GapLayer = Layers.gap(gapThickness)
        assert_true(m_GapLayer is not None)
        assert_true(layer1 is not None)
        assert_true(layer2 is not None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1.value(), m_GapLayer.value(), layer2.value()])
        self.m_TarcogSystem = Some(CSingleSystem(aIGU, Indoor.value(), Outdoor.value()))
        assert_true(self.m_TarcogSystem is not None)
        self.m_TarcogSystem.value().solve()

    def GetSystem(self) -> Optional[CSingleSystem]:
        return self.m_TarcogSystem

def Test1():
    # SCOPED_TRACE("Begin Test: Double Clear Single System - Surface temperatures")
    var fixture = TestDoubleClearSingleSystemNoSun()
    var aSystem = fixture.GetSystem()
    assert_true(aSystem is not None)
    var Temperature = aSystem.value().getTemperatures()
    var correctTemperature = List[Float64](258.756688, 259.359226, 279.178510, 279.781048)
    assert_eq(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        assert_approx_eq(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.value().getRadiosities()
    var correctRadiosity = List[Float64](251.950834, 268.667346, 332.299338, 359.731700)
    assert_eq(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        assert_approx_eq(correctRadiosity[i], Radiosity[i], 1e-5)
    var heatFlow = aSystem.value().getHeatFlow(Environment.Indoor)
    assert_approx_eq(105.431019, heatFlow, 1e-5)
    var Uvalue = aSystem.value().getUValue()
    assert_approx_eq(2.703359, Uvalue, 1e-5)
    var numOfIter = aSystem.value().getNumberOfIterations()
    assert_eq(20, numOfIter)

Test1()