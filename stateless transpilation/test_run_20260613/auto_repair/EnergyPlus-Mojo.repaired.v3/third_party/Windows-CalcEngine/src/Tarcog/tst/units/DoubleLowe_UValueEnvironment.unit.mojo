from memory import shared_ptr, make_shared
from stdexcept import *
from gtest import *
from WCETarcog import *
from WCECommon import *

class TestDoubleLoweUValueEnvironment(testing.Test):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSystem]

    def SetUp(self):
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
        var solidLayerThickness1 = 0.00318   # [m]
        var solidLayerConductance1 = 1.0
        var tIR1 = 0.0
        var frontEmissivity1 = 0.84
        var backEmissivity1 = 0.046578168869
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                            solidLayerConductance1,
                                                            frontEmissivity1,
                                                            tIR1,
                                                            backEmissivity1,
                                                            tIR1)
        ASSERT_TRUE(layer1 != None)
        var gapThickness = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        var solidLayerThickness2 = 0.005715   # [m]
        var solidLayerConductance2 = 1.0
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        var iguWidth = 1.0
        var iguHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers({layer1, gap, layer2})
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
        ASSERT_TRUE(self.m_TarcogSystem != None)

    def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

TEST_F(TestDoubleLoweUValueEnvironment, Test1):
    SCOPED_TRACE("Begin Test: Double Clear - Surface temperatures")
    var aSystem = GetSystem()
    ASSERT_TRUE(aSystem != None)
    var aRun = Tarcog.ISO15099.System.Uvalue
    var Temperature = aSystem.getTemperatures(aRun)
    var correctTemperature = List[Float64](257.398283, 257.607096, 284.597919, 284.973191)
    ASSERT_EQ(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)

    var SolidLayerConductivities = aSystem.getSolidEffectiveLayerConductivities(aRun)
    var correctSolidConductivities = List[Float64](1, 1)
    EXPECT_EQ(SolidLayerConductivities.size, correctSolidConductivities.size)
    for i in range(SolidLayerConductivities.size):
        EXPECT_NEAR(correctSolidConductivities[i], SolidLayerConductivities[i], 1e-6)

    var GapLayerConductivities = aSystem.getGapEffectiveLayerConductivities(aRun)
    var correctGapConductivities = List[Float64](0.030897)
    EXPECT_EQ(GapLayerConductivities.size, correctGapConductivities.size)
    for i in range(GapLayerConductivities.size):
        EXPECT_NEAR(correctGapConductivities[i], GapLayerConductivities[i], 1e-6)

    var Radiosity = aSystem.getRadiosities(aRun)
    var correctRadiosity = List[Float64](247.502661, 365.231909, 370.876831, 382.004324)
    ASSERT_EQ(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)

    var effectiveSystemConductivity = aSystem.getEffectiveSystemConductivity(aRun)
    EXPECT_NEAR(0.051424, effectiveSystemConductivity, 1e-6)
    var thickness = aSystem.thickness(aRun)
    EXPECT_NEAR(0.021595, thickness, 1e-6)
    var numOfIter = aSystem.getNumberOfIterations(aRun)
    EXPECT_EQ(21, int(numOfIter))
    var Uvalue = aSystem.getUValue()
    EXPECT_NEAR(Uvalue, 1.683701, 1e-5)
    var SHGC = aSystem.getSHGC(0.3716)
    EXPECT_NEAR(SHGC, 0.0, 1e-5)