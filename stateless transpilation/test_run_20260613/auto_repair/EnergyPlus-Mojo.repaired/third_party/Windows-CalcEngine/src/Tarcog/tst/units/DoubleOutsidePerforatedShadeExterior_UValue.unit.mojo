from memory import unique_ptr
from gtest import Test, EXPECT_NEAR, EXPECT_EQ, SCOPED_TRACE
from WCETarcog import (
    Tarcog, ISO15099, CSystem, Environments, SkyModel, BoundaryConditionsCoeffModel,
    Layers, CIGU, System, Environment
)
from ThermalPermeability import ThermalPermeability
from EffectiveLayers import EffectiveLayers

class TestDoubleOutsidePerforatedShadeExterior_UValue(Test):
    var m_TarcogSystem: UniquePtr[Tarcog.ISO15099.CSystem]

    def __init__(inout self):
        self.m_TarcogSystem = UniquePtr[Tarcog.ISO15099.CSystem]()

    def SetUp(inout self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        ASSERT_TRUE(Indoor != None)
        var shadeLayerConductance = 0.3
        var thickness_31006 = 0.0006
        var x = 0.00169        # m
        var y = 0.00169        # m
        var radius = 0.00058   # m
        var CellDimension = ThermalPermeability.Perforated.diameterToXYDimension(2 * radius)
        var frontOpenness = ThermalPermeability.Perforated.openness(
          ThermalPermeability.Perforated.Geometry.Circular,
          x,
          y,
          CellDimension.x,
          CellDimension.y)
        var dl = 0.0
        var dr = 0.0
        var dtop = 0.0
        var dbot = 0.0
        var openness = EffectiveLayers.ShadeOpenness(frontOpenness, dl, dr, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayerPerforated = EffectiveLayers.EffectiveLayerPerforated(
          windowWidth, windowHeight, thickness_31006, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(
          effectiveLayerPerforated.getEffectiveOpenness())
        var effectiveThickness = effectiveLayerPerforated.effectiveThickness()
        var Ef = 0.752239525318
        var Eb = 0.752239525318
        var Tirf = 0.164178311825
        var Tirb = 0.164178311825
        var aLayer1 = Tarcog.ISO15099.Layers.shading(
          effectiveThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        aLayer1.setSolarAbsorptance(0.324484854937, solarRadiation)
        var gapThickness = 0.0127
        var GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(GapLayer1 != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        ASSERT_TRUE(aLayer2 != None)
        aLayer2.setSolarAbsorptance(0.034704498947, solarRadiation)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2])
        self.m_TarcogSystem = UniquePtr[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        ASSERT_TRUE(self.m_TarcogSystem != None)

    def GetSystem(self) -> Tarcog.ISO15099.CSystem:
        return self.m_TarcogSystem.get()

def TestDoubleOutsidePerforatedShadeExterior_UValue_Test1():
    SCOPED_TRACE("Begin Test: Outside perforated shade.")
    var aSystem = GetSystem()
    var uval = aSystem.getUValue()
    EXPECT_NEAR(3.215808, uval, 1e-6)
    var effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(Tarcog.ISO15099.System.Uvalue)
    var correctEffectConductivites = List[Float64](0.230300, 1)
    EXPECT_EQ(correctEffectConductivites.size(), effectiveLayerConductivities.size())
    for var i in range(correctEffectConductivites.size()):
        EXPECT_NEAR(correctEffectConductivites[i], effectiveLayerConductivities[i], 1e-6)
    var heatflow = aSystem.getHeatFlow(Tarcog.ISO15099.System.Uvalue, Tarcog.ISO15099.Environment.Indoor)
    EXPECT_NEAR(125.416522, heatflow, 1e-6)