from memory import shared_ptr, make_shared
from WCETarcog import (
    Tarcog,
    ISO15099,
    CSingleSystem,
    Environments,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel,
    CIGU,
    Environment,
)
from WCECommon import (
    std_vector_double,
)
from testing import *

@register_test
class TestDoubleClearSingleSystemWithSun:
    var m_TarcogSystem: shared_ptr[CSingleSystem]

    def __init__(inout self):
        self.m_TarcogSystem = shared_ptr[CSingleSystem]()

    def SetUp(inout self):
        var airTemperature = 305.15   # Kelvins
        var airSpeed = 2.75           # meters per second
        var tSky = 305.15             # Kelvins
        var solarRadiation = 783.0
        var Outdoor = Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified
        )
        assert_true(Outdoor is not None)
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 297.15
        var Indoor = Environments.indoor(roomTemperature)
        assert_true(Indoor is not None)
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var solarAbsorptance = 0.187443971634
        var layer1 = Layers.solid(solidLayerThickness, solidLayerConductance)
        layer1.setSolarAbsorptance(solarAbsorptance, solarRadiation)
        solarAbsorptance = 0.054178960621
        var layer2 = Layers.solid(solidLayerThickness, solidLayerConductance)
        layer2.setSolarAbsorptance(solarAbsorptance, solarRadiation)
        var gapThickness = 0.012
        var m_GapLayer = Layers.gap(gapThickness)
        assert_true(m_GapLayer is not None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, m_GapLayer, layer2])
        self.m_TarcogSystem = make_shared[CSingleSystem](aIGU, Indoor, Outdoor)
        assert_true(self.m_TarcogSystem is not None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> shared_ptr[CSingleSystem]:
        return self.m_TarcogSystem

@register_test
def Test1():
    SCOPED_TRACE("Begin Test: Double Clear Single System - Surface temperatures")
    var test_instance = TestDoubleClearSingleSystemWithSun()
    test_instance.SetUp()
    var aSystem = test_instance.GetSystem()
    assert_true(aSystem is not None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = std_vector_double([310.818074, 311.064868, 306.799522, 306.505704])
    assert_eq(correctTemperature.size(), Temperature.size())
    for i in range(correctTemperature.size()):
        expect_near(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = std_vector_double([523.148794, 526.906252, 506.252171, 491.059753])
    assert_eq(correctRadiosity.size(), Radiosity.size())
    for i in range(correctRadiosity.size()):
        expect_near(correctRadiosity[i], Radiosity[i], 1e-5)
    var heatFlow = aSystem.getHeatFlow(Environment.Indoor)
    expect_near(-72.622787, heatFlow, 1e-5)
    var Uvalue = aSystem.getUValue()
    expect_near(9.077848, Uvalue, 1e-5)
    var numOfIter = aSystem.getNumberOfIterations()
    expect_eq(20, numOfIter)