from memory import shared_ptr
from stdexcept import *
from gtest.gtest.h import *
from WCETarcog.hpp import *

class TestIndoorEnvironment(testing.Test):
    private:
        var m_Indoor: shared_ptr[Tarcog.ISO15099.CEnvironment]
        var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]
    protected:
        def SetUp(self) raises:
            var airTemperature = 300.0   # Kelvins
            var airSpeed = 5.5           # meters per second
            var tSky = 270.0             # Kelvins
            var solarRadiation = 0.0
            var Outdoor = Tarcog.ISO15099.Environments.outdoor(
              airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
            ASSERT_TRUE(Outdoor != None)
            Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
            var roomTemperature = 294.15
            self.m_Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
            ASSERT_TRUE(self.m_Indoor != None)
            var solidLayerThickness = 0.003048   # [m]
            var solidLayerConductance = 100.0
            var solidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            ASSERT_TRUE(solidLayer != None)
            var windowWidth = 1.0
            var windowHeight = 1.0
            var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
            aIGU.addLayer(solidLayer)
            self.m_TarcogSystem = shared_ptr[Tarcog.ISO15099.CSingleSystem](Tarcog.ISO15099.CSingleSystem(aIGU, self.m_Indoor, Outdoor))
            self.m_TarcogSystem.solve()
            ASSERT_TRUE(self.m_TarcogSystem != None)
    public:
        def GetIndoors(self) -> shared_ptr[Tarcog.ISO15099.CEnvironment]:
            return self.m_Indoor

def TestIndoorEnvironment_IndoorRadiosity() raises:
    SCOPED_TRACE("Begin Test: Indoors -> Radiosity")
    var aIndoor = TestIndoorEnvironment().GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var radiosity = aIndoor.getEnvironmentIR()
    EXPECT_NEAR(424.458749869075, radiosity, 1e-6)

def TestIndoorEnvironment_IndoorConvection() raises:
    SCOPED_TRACE("Begin Test: Indoors -> Convection Flow")
    var aIndoor = TestIndoorEnvironment().GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var convectionFlow = aIndoor.getConvectionConductionFlow()
    EXPECT_NEAR(-5.826845, convectionFlow, 1e-6)

def TestIndoorEnvironment_IndoorHc() raises:
    SCOPED_TRACE("Begin Test: Indoors -> Convection Coefficient")
    var aIndoor = TestIndoorEnvironment().GetIndoors()
    ASSERT_TRUE(aIndoor != None)
    var hc = aIndoor.getHc()
    EXPECT_NEAR(1.913874, hc, 1e-6)