from memory import unique_ptr
from utils import TestFixture
from WCEGases import CGas, GasDef
from WCETarcog import (
    CSystem, Environments, SkyModel, BoundaryConditionsCoeffModel, 
    Layers, EffectiveLayers, CIGU, System, Environment
)
from gtest import EXPECT_NEAR, SCOPED_TRACE, TEST_F

class TestTripleShadeInside_UValue(TestFixture):
    var m_TarcogSystem: unique_ptr[CSystem]

    def __init__(inout self):
        self.m_TarcogSystem = unique_ptr[CSystem]()

    def SetUp(inout self):
        var airTemperature = 255.15   # Kelvins
        var airSpeed = 5.5            # meters per second
        var tSky = 255.15             # Kelvins
        var solarRadiation = 0.0
        var Outdoor = Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        # ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        # ASSERT_TRUE(Indoor != None)
        var windowWidth = 2.0
        var windowHeight = 2.0
        var solidLayerThickness = 0.005613400135   # [m]
        var solidLayerConductance = 0.996883
        var frontEmiss = 0.840000
        var frontTIR = 0.0
        var backEmiss = 0.038798544556
        var backTIR = 0.0
        var aLayer1 = Layers.solid(
          solidLayerThickness, solidLayerConductance, frontEmiss, frontTIR, backEmiss, backTIR)
        var gapThickness = 0.0127
        var gas1 = CGas()
        gas1.addGasItem(0.1, GasDef.Air)
        gas1.addGasItem(0.9, GasDef.Argon)
        var GapLayer1 = Layers.gap(gapThickness, gas1)
        solidLayerThickness = 0.005715   # [m]
        solidLayerConductance = 1.0
        frontEmiss = 0.840000
        frontTIR = 0.0
        backEmiss = 0.840000
        backTIR = 0.0
        var aLayer2 = Layers.solid(
          solidLayerThickness, solidLayerConductance, frontEmiss, frontTIR, backEmiss, backTIR)
        gapThickness = 0.0127
        var GapLayer2 = Layers.gap(gapThickness)
        var shadeLayerConductance = 160.0
        var shadeThickness = 0.0006
        var dl = 0.0
        var dr = 0.0
        var dtop = 0.0
        var dbot = 0.0
        var frontOpenness = 0.9
        var openness = EffectiveLayers.ShadeOpenness(frontOpenness, dl, dr, dtop, dbot)
        var effOpenness = EffectiveLayers.EffectiveOpenness(
          frontOpenness, dl, dr, dtop, dbot, frontOpenness)
        var Ef = 0.9
        var Eb = 0.9
        var Tirf = 0
        var Tirb = 0
        var aLayer3 = Layers.shading(
          shadeThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2, GapLayer2, aLayer3])
        self.m_TarcogSystem = unique_ptr[CSystem](
          CSystem(aIGU, Indoor, Outdoor))

    def GetSystem(self) -> CSystem:
        return self.m_TarcogSystem.value()

def Test1(inout self: TestTripleShadeInside_UValue):
    SCOPED_TRACE("Begin Test: Outside venetian shade.")
    var aSystem = self.GetSystem()
    var effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(System.Uvalue)
    var systemKeff = aSystem.getEffectiveSystemConductivity(System.Uvalue)
    EXPECT_NEAR(0.039691, systemKeff, 1e-6)
    var uval = aSystem.getUValue()
    EXPECT_NEAR(1.196599, uval, 1e-6)
    var heatflow = aSystem.getHeatFlow(System.Uvalue, Environment.Indoor)
    EXPECT_NEAR(34.451676, heatflow, 1e-6)

TEST_F(TestTripleShadeInside_UValue, Test1)