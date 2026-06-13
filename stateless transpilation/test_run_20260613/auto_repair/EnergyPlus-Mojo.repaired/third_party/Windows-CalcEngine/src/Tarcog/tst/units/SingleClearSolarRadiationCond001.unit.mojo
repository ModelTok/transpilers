from memory import unique_ptr
from stdexcept import *
from gtest.gtest.mojo import *
from WCETarcog import *
from WCECommon import *

class TestSingleClearSolarCond100(Test):
    var m_TarcogSystem: UniquePtr[Tarcog.ISO15099.CSingleSystem]

    def SetUp(self):
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 1000.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var aIndoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        ASSERT_TRUE(aIndoor != None)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 0.01
        var solarAbsorptance = 0.094189159572
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer.setSolarAbsorptance(solarAbsorptance, solarRadiation)
        ASSERT_TRUE(aSolidLayer != None)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = UniquePtr[Tarcog.ISO15099.CSingleSystem](
          Tarcog.ISO15099.CSingleSystem(aIGU, aIndoor, Outdoor))
        ASSERT_TRUE(self.m_TarcogSystem != None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> Tarcog.ISO15099.CSingleSystem:
        return self.m_TarcogSystem.get()

@TestFixture[TestSingleClearSolarCond100]
def TestTempAndRad(reg: TestRegistration, test: TestSingleClearSolarCond100):
    SCOPED_TRACE("Begin Test: Single Clear (Solar Radiation) - Temperatures and Radiosity.")
    var aSystem = test.GetSystem()
    ASSERT_TRUE(aSystem != None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](299.465898, 300.261869)
    ASSERT_EQ(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)

    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](443.871080, 455.028488)
    ASSERT_EQ(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)

@TestFixture[TestSingleClearSolarCond100]
def TestIndoor(reg: TestRegistration, test: TestSingleClearSolarCond100):
    SCOPED_TRACE("Begin Test: Single Clear (Solar Radiation) - Indoor heat flow.")
    var aSystem = test.GetSystem()
    var convectiveHF = aSystem.getConvectiveHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    var radiativeHF = aSystem.getRadiationHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    var totalHF = aSystem.getHeatFlow(Tarcog.ISO15099.Environment.Indoor)
    EXPECT_NEAR(-13.913388, convectiveHF, 1e-5)
    EXPECT_NEAR(-30.569739, radiativeHF, 1e-5)
    EXPECT_NEAR(-44.483127, totalHF, 1e-5)