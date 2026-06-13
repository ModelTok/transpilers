from WCETarcog import Tarcog
from gtest import testing, TEST_F, ASSERT_TRUE, ASSERT_EQ, EXPECT_NEAR, SCOPED_TRACE

class TestDoubleClearSingleSystemWithInitialGuess(testing.Test):
    private:
        var m_TarcogSystem: Optional[Tarcog.ISO15099.CSingleSystem] = None
    protected:
        def SetUp() raises:
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
            var solidLayerThickness = 0.005715   # [m]
            var solidLayerConductance = 1.0
            var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            var gapThickness = 0.012
            var m_GapLayer = Tarcog.ISO15099.Layers.gap(gapThickness)
            ASSERT_TRUE(m_GapLayer != None)
            var windowWidth = 1.0
            var windowHeight = 1.0
            var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
            aIGU.addLayers([layer1, m_GapLayer, layer2])
            m_TarcogSystem = Some(Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor))
            ASSERT_TRUE(m_TarcogSystem != None)
            var aTemperatures = List[Float64](258.75, 259.36, 279.18, 279.78)
            m_TarcogSystem.get().setInitialGuess(aTemperatures)
            m_TarcogSystem.get().solve()
    public:
        def GetSystem() -> Optional[Tarcog.ISO15099.CSingleSystem]:
            return m_TarcogSystem

TEST_F(TestDoubleClearSingleSystemWithInitialGuess, Test1):
    SCOPED_TRACE("Begin Test: Double Clear Single System (Initial guess) - Surface temperatures")
    var aSystem = GetSystem()
    ASSERT_TRUE(aSystem != None)
    var Temperature = aSystem.get().getTemperatures()
    var correctTemperature = List[Float64](258.756688, 259.359226, 279.178510, 279.781048)
    ASSERT_EQ(correctTemperature.size(), Temperature.size())
    for i in range(correctTemperature.size()):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)
    var Radiosity = aSystem.get().getRadiosities()
    var correctRadiosity = List[Float64](251.950834, 268.667346, 332.299338, 359.731700)
    ASSERT_EQ(correctRadiosity.size(), Radiosity.size())
    for i in range(correctRadiosity.size()):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)
    var numOfIter = aSystem.get().getNumberOfIterations()
    EXPECT_EQ(17, numOfIter)