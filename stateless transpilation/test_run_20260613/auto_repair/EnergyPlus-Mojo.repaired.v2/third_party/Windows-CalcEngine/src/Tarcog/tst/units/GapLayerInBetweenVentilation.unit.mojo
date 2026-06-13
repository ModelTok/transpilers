from WCETarcog import Tarcog
from testing import assert_approx_equal

struct TestGapLayerInBetweenVentilation:
    var m_TarcogSystem: Optional[Tarcog.ISO15099.CSingleSystem] = None

    def SetUp(inout self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified
        )
        assert(Outdoor is not None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 295.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert(Indoor is not None)
        var solidLayerThickness = 0.005715   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert(layer1 is not None)
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        assert(layer2 is not None)
        var shadeLayerThickness = 0.01
        var shadeLayerConductance = 160.0
        var Atop = 0.1
        var Abot = 0.1
        var Aleft = 0.1
        var Aright = 0.1
        var Afront = 0.2
        var openness = Tarcog.EffectiveLayers.ShadeOpenness{Afront, Aleft, Aright, Atop, Abot}
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayer = Tarcog.EffectiveLayers.EffectiveLayerOther(
            windowWidth, windowHeight, shadeLayerThickness, openness
        )
        var effOpenness = Tarcog.EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
        var shadeLayer = Tarcog.ISO15099.Layers.shading(
            shadeLayerThickness, shadeLayerConductance, effOpenness
        )
        assert(shadeLayer is not None)
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert(gap1 is not None)
        var gap2 = Tarcog.ISO15099.Layers.gap(gapThickness)
        assert(gap2 is not None)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap1, shadeLayer, gap2, layer2])
        self.m_TarcogSystem = Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor)
        assert(self.m_TarcogSystem is not None)

    def GetGap1(self) -> Optional[Pointer[Tarcog.ISO15099.CBaseIGULayer]]:
        var gaps = self.m_TarcogSystem.value().getGapLayers()
        return gaps[0]

    def GetGap2(self) -> Optional[Pointer[Tarcog.ISO15099.CBaseIGULayer]]:
        var gaps = self.m_TarcogSystem.value().getGapLayers()
        return gaps[1]

@test
def VentilationFlow():
    var fixture = TestGapLayerInBetweenVentilation()
    fixture.SetUp()
    var aLayer = fixture.GetGap1()
    assert(aLayer is not None)
    var gainEnergy = aLayer.value().getGainFlow()
    assert_approx_equal(32.414571203538848, gainEnergy, 1e-4)
    aLayer = fixture.GetGap2()
    assert(aLayer is not None)
    gainEnergy = aLayer.value().getGainFlow()
    assert_approx_equal(-32.414571203538848, gainEnergy, 1e-4)