from memory import shared_ptr, make_shared
from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, ASSERT_TRUE, ASSERT_EQ, SCOPED_TRACE
from WCETarcog import Tarcog
from WCECommon import WCECommon

class TestDoubleClearSHGCEnvironment(TestFixture):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSystem]

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
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0      # [W/m2K]
        var aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        var aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        var gapThickness = 0.0127
        var gapLayer = Tarcog.ISO15099.Layers.gap(gapThickness)
        ASSERT_TRUE(gapLayer != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aSolidLayer1, gapLayer, aSolidLayer2])
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
        ASSERT_TRUE(self.m_TarcogSystem != None)
        self.m_TarcogSystem.setAbsorptances([0.096489921212, 0.072256758809])

    def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def Test1(self: TestDoubleClearSHGCEnvironment):
    SCOPED_TRACE("Begin Test: Double Clear - Surface temperatures")
    var aSystem = self.GetSystem()
    ASSERT_TRUE(aSystem != None)
    var aRun = Tarcog.ISO15099.System.Uvalue
    var Temperature = aSystem.getTemperatures(aRun)
    var correctTemperature = [304.025047, 303.955156, 300.484758, 300.414867]
    ASSERT_EQ(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)
    var SolidLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(aRun)
    var correctSolidConductivities = [1, 1]
    EXPECT_EQ(len(SolidLayerConductivities), len(correctSolidConductivities))
    for i in range(len(SolidLayerConductivities)):
        EXPECT_NEAR(correctSolidConductivities[i], SolidLayerConductivities[i], 1e-6)
    var GapLayerConductivities = aSystem.getGapEffectiveLayerConductivities(aRun)
    var correctGapConductivities = [0.083913]
    EXPECT_EQ(len(GapLayerConductivities), len(correctGapConductivities))
    for i in range(len(GapLayerConductivities)):
        EXPECT_NEAR(correctGapConductivities[i], GapLayerConductivities[i], 1e-6)
    var Radiosity = aSystem.getRadiosities(aRun)
    var correctRadiosity = [485.546128, 480.950664, 465.217923, 458.631346]
    ASSERT_EQ(len(correctRadiosity), len(Radiosity))
    for i in range(len(correctRadiosity)):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)
    var effectiveSystemConductivity = aSystem.getEffectiveSystemConductivity(aRun)
    EXPECT_NEAR(0.119383, effectiveSystemConductivity, 1e-6)
    var thickness = aSystem.thickness(aRun)
    EXPECT_NEAR(0.018796, thickness, 1e-6)
    var numOfIter = aSystem.getNumberOfIterations(aRun)
    EXPECT_EQ(1, numOfIter)
    aRun = Tarcog.ISO15099.System.SHGC
    Temperature = aSystem.getTemperatures(aRun)
    correctTemperature = [308.185604, 308.260088, 306.318284, 306.191403]
    ASSERT_EQ(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)
    SolidLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(aRun)
    correctSolidConductivities = [1, 1]
    EXPECT_EQ(len(SolidLayerConductivities), len(correctSolidConductivities))
    for i in range(len(SolidLayerConductivities)):
        EXPECT_NEAR(correctSolidConductivities[i], SolidLayerConductivities[i], 1e-6)
    GapLayerConductivities = aSystem.getGapEffectiveLayerConductivities(aRun)
    correctGapConductivities = [0.087241]
    EXPECT_EQ(len(GapLayerConductivities), len(correctGapConductivities))
    for i in range(len(GapLayerConductivities)):
        EXPECT_NEAR(correctGapConductivities[i], GapLayerConductivities[i], 1e-6)
    Radiosity = aSystem.getRadiosities(aRun)
    correctRadiosity = [508.280530, 510.189512, 500.936293, 489.338313]
    ASSERT_EQ(len(correctRadiosity), len(Radiosity))
    for i in range(len(correctRadiosity)):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)
    effectiveSystemConductivity = aSystem.getEffectiveSystemConductivity(aRun)
    EXPECT_NEAR(0.658981, effectiveSystemConductivity, 1e-6)
    thickness = aSystem.thickness(aRun)
    EXPECT_NEAR(0.018796, thickness, 1e-6)
    numOfIter = aSystem.getNumberOfIterations(aRun)
    EXPECT_EQ(1, numOfIter)
    var Uvalue = aSystem.getUValue()
    EXPECT_NEAR(Uvalue, 2.866261, 1e-5)
    var SHGC = aSystem.getSHGC(0.703296)
    EXPECT_NEAR(SHGC, 0.763304, 1e-5)
    var relativeHeatGain = aSystem.relativeHeatGain(0.703296)
    EXPECT_NEAR(relativeHeatGain, 575.826177, 1e-5)