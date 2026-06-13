from memory import shared_ptr, make_shared
from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_NEAR, SCOPED_TRACE
from WCETarcog import Tarcog
from WCECommon import EffectiveLayers
from math import isclose

class TestDoubleClearOutdoorShadeAir(TestFixture):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]

    def SetUp() raises:
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert Outdoor is not None
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 295.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert Indoor is not None
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var shadeLayerThickness = 0.01
        var shadeLayerConductance = 160.0
        var dtop = 0.1
        var dbot = 0.1
        var dleft = 0.1
        var dright = 0.1
        var Afront = 0.2
        var openness = EffectiveLayers.ShadeOpenness(Afront, dleft, dright, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayer = EffectiveLayers.EffectiveLayerOther(
          windowWidth, windowHeight, shadeLayerThickness, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
        var layer1 = Tarcog.ISO15099.Layers.shading(
          shadeLayerThickness, shadeLayerConductance, effOpenness)
        assert layer1 is not None
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert layer2 is not None
        var layer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert gap1 is not None
        var gap2 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert gap2 is not None
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap1, layer2, gap2, layer3])
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSingleSystem](aIGU, Indoor, Outdoor)
        assert self.m_TarcogSystem is not None
        self.m_TarcogSystem.solve()

    def getSystem() -> shared_ptr[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

def TestDoubleClearOutdoorShadeAir_Test1() raises:
    SCOPED_TRACE("Begin Test: Outdoor Shade - Air")
    var self = TestDoubleClearOutdoorShadeAir()
    self.SetUp()
    var aSystem = self.getSystem()
    var temperature = aSystem.getTemperatures()
    var radiosity = aSystem.getRadiosities()
    var correctTemp = List[Float64](256.984067, 256.988250, 269.437058, 269.879893, 284.039251, 284.482085)
    var correctJ = List[Float64](246.160219, 254.398900, 291.700909, 310.191145, 359.624235, 380.773015)
    EXPECT_EQ(correctTemp.size, temperature.size)
    EXPECT_EQ(correctJ.size, radiosity.size)
    for i in range(temperature.size):
        EXPECT_NEAR(correctTemp[i], temperature[i], 1e-6)
        EXPECT_NEAR(correctJ[i], radiosity[i], 1e-6)
    var numOfIter = aSystem.getNumberOfIterations()
    EXPECT_EQ(23, int(numOfIter))
    var ventilatedFlow = aSystem.getVentilationFlow(Tarcog.ISO15099.Environment.Outdoor)
    EXPECT_NEAR(-23.934154, ventilatedFlow, 1e-6)