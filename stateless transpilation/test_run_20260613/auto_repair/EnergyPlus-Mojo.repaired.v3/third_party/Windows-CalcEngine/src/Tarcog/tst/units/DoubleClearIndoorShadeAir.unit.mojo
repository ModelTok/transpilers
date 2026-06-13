from memory import unique_ptr
from stdexcept import runtime_error
from gtest.gtest import *
from string import String
from WCETarcog import *
from WCECommon import *

class TestDoubleClearIndoorShadeAir(Test):
    var m_TarcogSystem: unique_ptr[Tarcog.ISO15099.CSingleSystem]

    def SetUp(self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 295.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        ASSERT_TRUE(Indoor != None)
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        ASSERT_TRUE(layer1 != None)
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        var shadeLayerThickness = 0.01
        var shadeLayerConductance = 160.0
        var dtop = 0.1
        var dbot = 0.1
        var dleft = 0.1
        var dright = 0.1
        var Afront = 0.2
        var openness = EffectiveLayers.ShadeOpenness{Afront, dleft, dright, dtop, dbot}
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayer = EffectiveLayers.EffectiveLayerOther{
          windowWidth, windowHeight, shadeLayerThickness, openness}
        var effOpenness = EffectiveLayers.EffectiveOpenness{effectiveLayer.getEffectiveOpenness()}
        var layer3 = Tarcog.ISO15099.Layers.shading(
          shadeLayerThickness, shadeLayerConductance, effOpenness)
        ASSERT_TRUE(layer3 != None)
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(gap1 != None)
        var gap2 = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(gap2 != None)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers({layer1, gap1, layer2, gap2, layer3})
        self.m_TarcogSystem = unique_ptr[Tarcog.ISO15099.CSingleSystem](Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor))
        ASSERT_TRUE(self.m_TarcogSystem != None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return *self.m_TarcogSystem

def TestDoubleClearIndoorShadeAir_Test1():
    SCOPED_TRACE("Begin Test: Indoor Shade - Air")
    var aSystem = TestDoubleClearIndoorShadeAir().GetSystem()
    var temperature = aSystem.getTemperatures()
    var radiosity = aSystem.getRadiosities()
    var correctTemp = List[Float64](
      258.226548, 258.740345, 276.199456, 276.713252, 288.115819, 288.119712)
    var correctJ = List[Float64](
      250.206503, 264.568471, 319.491011, 340.451996, 382.649045, 397.036105)
    EXPECT_EQ(correctTemp.size(), temperature.size())
    EXPECT_EQ(correctJ.size(), radiosity.size())
    for i in range(temperature.size()):
        EXPECT_NEAR(correctTemp[i], temperature[i], 1e-5)
        EXPECT_NEAR(correctJ[i], radiosity[i], 1e-5)
    var ventilatedFlow = aSystem.getVentilationFlow(Tarcog.ISO15099.Environment.Indoor)
    EXPECT_NEAR(40.068458, ventilatedFlow, 1e-5)