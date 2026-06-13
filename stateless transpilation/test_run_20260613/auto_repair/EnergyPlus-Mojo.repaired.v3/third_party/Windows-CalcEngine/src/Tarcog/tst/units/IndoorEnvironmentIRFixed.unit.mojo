from memory import std
from stdexcept import std
from gtest import *
from WCETarcog import *

class TestIndoorEnvironmentIRFixed(testing.Test):
    private:
        var m_Indoor: std.shared_ptr[Tarcog.ISO15099.CEnvironment]
        var m_TarcogSystem: std.shared_ptr[Tarcog.ISO15099.CSingleSystem]
    protected:
        def SetUp() raises:
            var airTemperature = 300.0   # Kelvins
            var airSpeed = 5.5           # meters per second
            var tSky = 270.0             # Kelvins
            var solarRadiation = 0.0
            var Outdoor = Tarcog.ISO15099.Environments.outdoor(
              airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
            ASSERT_TRUE(Outdoor != None)
            Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
            var roomTemperature = 294.15
            var IRRadiation = 424.458750
            m_Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
            ASSERT_TRUE(m_Indoor != None)
            m_Indoor.setEnvironmentIR(IRRadiation)
            var solidLayerThickness = 0.003048   # [m]
            var solidLayerConductance = 100.0
            var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            ASSERT_TRUE(aSolidLayer != None)
            var windowWidth = 1.0
            var windowHeight = 1.0
            var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
            aIGU.addLayer(aSolidLayer)
            m_TarcogSystem = std.make_shared[Tarcog.ISO15099.CSingleSystem](aIGU, m_Indoor, Outdoor)
            m_TarcogSystem.solve()
            ASSERT_TRUE(m_TarcogSystem != None)
    public:
        def GetIndoors() -> std.shared_ptr[Tarcog.ISO15099.CEnvironment]:
            return m_Indoor

TEST_F(TestIndoorEnvironmentIRFixed, IndoorRadiosity):
    SCOPED_TRACE("Begin Test: Indoors -> Fixed radiosity (user input).")
    var aIndoor = GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var radiosity = aIndoor.getEnvironmentIR()
    EXPECT_NEAR(424.458750, radiosity, 1e-6)

TEST_F(TestIndoorEnvironmentIRFixed, IndoorConvection):
    SCOPED_TRACE("Begin Test: Indoors -> Convection Flow (user input).")
    var aIndoor = GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var convectionFlow = aIndoor.getConvectionConductionFlow()
    EXPECT_NEAR(-5.826845, convectionFlow, 1e-6)

TEST_F(TestIndoorEnvironmentIRFixed, IndoorHc):
    SCOPED_TRACE("Begin Test: Indoors -> Convection Coefficient (user input).")
    var aIndoor = GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var hc = aIndoor.getHc()
    EXPECT_NEAR(1.913874, hc, 1e-6)