from memory import unique_ptr
from stdexcept import *
from gtest.gtest.h import *
from WCEGases import *
from WCETarcog import *
from WCECommon import *

class TestDoubleOutsideVenetianShade_SHGC(Test):
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
        var shadeLayerConductance = 160.0
        var matThickness = 0.0001   # m
        var slatWidth = 0.0148      # m
        var slatSpacing = 0.0127    # m
        var slatTiltAngle = 0.0
        var curvatureRadius = 0.0331305656433105   # m
        var frontOpenness = ThermalPermeability.Venetian.openness(
          slatTiltAngle, slatSpacing, matThickness, curvatureRadius, slatWidth)
        var dl = 0.0
        var dr = 0.0
        var dtop = 0.0
        var dbot = 0.0
        var openness = EffectiveLayers.ShadeOpenness(frontOpenness, dl, dr, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveVenetian = EffectiveLayers.EffectiveHorizontalVenetian(
          windowWidth, windowHeight, matThickness, openness, slatTiltAngle, slatWidth)
        var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveVenetian.getEffectiveOpenness())
        var effectiveThickness = effectiveVenetian.effectiveThickness()
        var Ef = 0.5564947806702053
        var Eb = 0.5564947806702053
        var Tirf = 0.42293224373137134
        var Tirb = 0.42293224373137134
        var aLayer1 = Tarcog.ISO15099.Layers.shading(
          effectiveThickness, shadeLayerConductance, effOpenness, Ef, Tirf, Eb, Tirb)
        aLayer1.setSolarAbsorptance(0.030609361, solarRadiation)
        var gapThickness = 0.0127
        var GapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(GapLayer1 != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        ASSERT_TRUE(aLayer2 != None)
        aLayer2.setSolarAbsorptance(0.08669346, solarRadiation)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aLayer1, GapLayer1, aLayer2])
        self.m_TarcogSystem = unique_ptr[Tarcog.ISO15099.CSystem](
          Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        ASSERT_TRUE(self.m_TarcogSystem != None)

    def GetSystem(self) -> Tarcog.ISO15099.CSystem:
        return self.m_TarcogSystem.get()

def TestDoubleOutsideVenetianShade_SHGC_Test1():
    SCOPED_TRACE("Begin Test: Outside venetian shade.")
    var aSystem = GetSystem()
    var uval = aSystem.getUValue()
    EXPECT_NEAR(3.352152, uval, 1e-6)
    var effectiveLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(Tarcog.ISO15099.System.Uvalue)
    var correctEffectConductivites = [2.045130, 1]
    EXPECT_EQ(correctEffectConductivites.size(), effectiveLayerConductivities.size())
    for i in range(correctEffectConductivites.size()):
        EXPECT_NEAR(correctEffectConductivites[i], effectiveLayerConductivities[i], 1e-6)
    var totSol = 0.789689322
    var shgc = aSystem.getSHGC(totSol)
    EXPECT_NEAR(0.841574, shgc, 1e-6)
    var heatflow = aSystem.getHeatFlow(Tarcog.ISO15099.System.SHGC, Tarcog.ISO15099.Environment.Indoor)
    EXPECT_NEAR(-67.442678, heatflow, 1e-6)