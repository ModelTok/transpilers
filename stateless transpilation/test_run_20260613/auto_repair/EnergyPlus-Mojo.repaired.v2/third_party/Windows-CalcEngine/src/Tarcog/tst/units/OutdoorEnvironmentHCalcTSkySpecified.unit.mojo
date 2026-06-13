from memory import shared_ptr, make_shared
from gtest import Test, EXPECT_NEAR, ASSERT_TRUE, SCOPED_TRACE
from WCETarcog import (
    Tarcog,
    CEnvironment,
    CSingleSystem,
    CIGU,
    Environments,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel,
)

class TestOutdoorEnvironmentHCalcTSkySpecified(Test):
    var Outdoor: shared_ptr[CEnvironment]
    var m_TarcogSystem: shared_ptr[CSingleSystem]

    def SetUp(self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 0.0
        self.Outdoor = Environments.outdoor(
            airTemperature,
            airSpeed,
            solarRadiation,
            tSky,
            SkyModel.TSkySpecified,
        )
        ASSERT_TRUE(self.Outdoor != None)
        self.Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Environments.indoor(roomTemperature)
        ASSERT_TRUE(Indoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 100.0
        var aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        ASSERT_TRUE(aSolidLayer != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = make_shared[CSingleSystem](aIGU, Indoor, self.Outdoor)
        self.m_TarcogSystem.solve()
        ASSERT_TRUE(self.m_TarcogSystem != None)

    def GetOutdoors(self) -> shared_ptr[CEnvironment]:
        return self.Outdoor

def TEST_F_TestOutdoorEnvironmentHCalcTSkySpecified_CalculateH_TSkySpecified():
    SCOPED_TRACE("Begin Test: Outdoors -> H model = Calculate; Sky Model = TSky specified")
    var test = TestOutdoorEnvironmentHCalcTSkySpecified()
    test.SetUp()
    var aOutdoor = test.GetOutdoors()
    ASSERT_TRUE(aOutdoor != None)
    var radiosity = aOutdoor.getEnvironmentIR()
    EXPECT_NEAR(380.278401885, radiosity, 1e-6)
    var hc = aOutdoor.getHc()
    EXPECT_NEAR(26, hc, 1e-6)
    var outIR = aOutdoor.getRadiationFlow()
    EXPECT_NEAR(52.1067777, outIR, 1e-6)
    var outConvection = aOutdoor.getConvectionConductionFlow()
    EXPECT_NEAR(-72.92573417, outConvection, 1e-6)
    var totalHeatFlow = aOutdoor.getHeatFlow()
    EXPECT_NEAR(-20.81895645, totalHeatFlow, 1e-6)