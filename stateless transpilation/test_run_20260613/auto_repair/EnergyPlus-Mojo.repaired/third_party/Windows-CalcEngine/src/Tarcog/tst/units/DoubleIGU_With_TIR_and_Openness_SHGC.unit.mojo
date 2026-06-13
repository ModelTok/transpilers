from memory import shared_ptr, make_shared
from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_NEAR, SCOPED_TRACE
from WCETarcog import (
    Tarcog,
    ISO15099,
    CSystem,
    Environments,
    SkyModel,
    BoundaryConditionsCoeffModel,
    Layers,
    CIGU,
    System,
)
from WCECommon import EffectiveLayers, ShadeOpenness, EffectiveLayerBSDF, EffectiveOpenness

class DoubleIGU_With_TIR_and_Openness_SHGC(TestFixture):
    var m_TarcogSystem: shared_ptr[CSystem]

    def SetUp(self):
        var airTemperature = 305.15   # Kelvins
        var airSpeed = 2.75           # meters per second
        var tSky = 305.15             # Kelvins
        var solarRadiation = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        EXPECT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 297.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        EXPECT_TRUE(Indoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var layer1 = Tarcog.ISO15099.Layers.shading(solidLayerThickness, solidLayerConductance)
        EXPECT_TRUE(layer1 != None)
        var shadeLayerThickness = 0.001
        var shadeLayerConductance = 0.15
        var emissivity = 0.796259999275
        var tir = 0.10916
        var dtop = 0.0
        var dbot = 0.0
        var dleft = 0.0
        var dright = 0.0
        var Afront = 0.049855
        var openness = EffectiveLayers.ShadeOpenness(Afront, dleft, dright, dtop, dbot)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var effectiveLayer = EffectiveLayers.EffectiveLayerBSDF(
            windowWidth, windowHeight, shadeLayerThickness, openness)
        var effOpenness = EffectiveLayers.EffectiveOpenness(effectiveLayer.getEffectiveOpenness())
        var layer2 = Tarcog.ISO15099.Layers.shading(
            shadeLayerThickness,
            shadeLayerConductance,
            effOpenness,
            emissivity,
            tir,
            emissivity,
            tir)
        EXPECT_TRUE(layer2 != None)
        var gapThickness = 0.0127
        var gap1 = Tarcog.ISO15099.Layers.gap(gapThickness)
        EXPECT_TRUE(gap1 != None)
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([layer1, gap1, layer2])
        self.m_TarcogSystem = make_shared[CSystem](aIGU, Indoor, Outdoor)
        EXPECT_TRUE(self.m_TarcogSystem != None)
        self.m_TarcogSystem.setAbsorptances([0.160476297140, 0.167158290744])

    def getSystem(self) -> shared_ptr[CSystem]:
        return self.m_TarcogSystem

def Test1():
    SCOPED_TRACE("Begin Test: Indoor Shade")
    var aSystem = DoubleIGU_With_TIR_and_Openness_SHGC().getSystem()
    var temperature = aSystem.getTemperatures(Tarcog.ISO15099.System.SHGC)
    var radiosity = aSystem.getRadiosities(Tarcog.ISO15099.System.SHGC)
    var correctTemp = [311.156776, 311.341981, 312.547758, 312.172916]
    var correctJ = [525.089442, 532.199938, 529.393517, 528.645065]
    EXPECT_EQ(correctTemp.size, temperature.size)
    EXPECT_EQ(correctJ.size, radiosity.size)
    for i in range(temperature.size):
        EXPECT_NEAR(correctTemp[i], temperature[i], 1e-6)
        EXPECT_NEAR(correctJ[i], radiosity[i], 1e-6)
    var numOfIter = aSystem.getNumberOfIterations(Tarcog.ISO15099.System.SHGC)
    EXPECT_EQ(1, numOfIter)
    var uValue = aSystem.getUValue()
    EXPECT_NEAR(3.219847, uValue, 1e-6)
    var Ttot_sol = 0.119033947587
    var shgc = aSystem.getSHGC(Ttot_sol)
    EXPECT_NEAR(0.255930, shgc, 1e-6)