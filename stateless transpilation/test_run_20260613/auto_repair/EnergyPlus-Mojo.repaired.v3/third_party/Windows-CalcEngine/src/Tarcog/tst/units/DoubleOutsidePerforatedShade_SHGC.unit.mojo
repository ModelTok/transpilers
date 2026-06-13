from memory import unique_ptr
from stdexcept import raise_exception
from gtest.gtest import Test, TestFixture, EXPECT_NEAR, EXPECT_EQ, ASSERT_TRUE, SCOPED_TRACE
from WCEGases import *
from WCETarcog import *
from WCECommon import *

class TestDoubleOutsidePerforatedShade_SHGC(TestFixture):
    var m_TarcogSystem: unique_ptr[Tarcog.ISO15099.CSystem]

    def SetUp(self):
        var airTemperature = 305.15   # Kelvins
        var airSpeed = 2.75           # meters per second
        var tSky = 305.15             # Kelvins
        var solarRadiation = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 297.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        ASSERT_TRUE(Indoor != None)
        var shadeLayerConductance = 0.12
        var thickness_31111 = 0.00023
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
          windowWidth, windowHeight, thickness_31111, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(
          effectiveLayerPerforated.getEffectiveOpenness())
        var effectiveThickness = effectiveLayerPerforated.effectiveThickness()
        var Ef = 0.640892
        var Eb = 0.623812
        var Tirf = 0.257367
        var Tirb = 0.257367
        var aLayer1 = Tarcog.ISO15099.Layers.shading(
          effectiveThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        aLayer1.setSolarAbsorptance(0.106659, solarRadiation)
        var gapThickness = 0.0127
        var GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(GapLayer1 != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        ASSERT_TRUE(aLayer2 != None)
        aLayer2.setSolarAbsorptance(0.034677, solarRadiation)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2])
        self.m_TarcogSystem = unique_ptr[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        ASSERT_TRUE(self.m_TarcogSystem != None)

    def GetSystem(self) -> Tarcog.ISO15099.CSystem:
        return self.m_TarcogSystem.get()

def TestDoubleOutsidePerforatedShade_SHGC_Test1():
    SCOPED_TRACE("Begin Test: Outside perforated shade.")
    var aSystem = TestDoubleOutsidePerforatedShade_SHGC().GetSystem()
    var uval = aSystem.getUValue()
    EXPECT_NEAR(3.193057, uval, 1e-6)
    var effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(Tarcog.ISO15099.System.Uvalue)
    var correctEffectConductivites = [0.115592, 1]
    EXPECT_EQ(correctEffectConductivites.size(), effectiveLayerConductivities.size())
    for i in range(correctEffectConductivites.size()):
        EXPECT_NEAR(correctEffectConductivites[i], effectiveLayerConductivities[i], 1e-6)
    var totSol = 0.315236
    var shgc = aSystem.getSHGC(totSol)
    EXPECT_NEAR(0.348647, shgc, 1e-6)
    var heatflow = aSystem.getHeatFlow(Tarcog.ISO15099.System.SHGC, Tarcog.ISO15099.Environment.Indoor)
    EXPECT_NEAR(-51.705046, heatflow, 1e-6)