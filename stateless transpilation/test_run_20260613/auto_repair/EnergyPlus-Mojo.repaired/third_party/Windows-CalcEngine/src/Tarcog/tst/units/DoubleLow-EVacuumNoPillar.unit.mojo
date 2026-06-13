from memory import shared_ptr, make_shared
from gtest import Test, TestWithParam, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NE, EXPECT_NEAR, ASSERT_TRUE, ASSERT_EQ, SCOPED_TRACE
from WCETarcog import Tarcog
from WCECommon import WCECommon

class DoubleLowEVacuumNoPillar(Test):
    var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSingleSystem]

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
        var solidLayerThickness = 0.004   # [m]
        var solidLayerConductance = 1.0
        var TransmittanceIR = 0.0
        var emissivityFrontIR = 0.84
        var emissivityBackIR = 0.036749500781
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness,
                                                      solidLayerConductance,
                                                      emissivityFrontIR,
                                                      TransmittanceIR,
                                                      emissivityBackIR,
                                                      TransmittanceIR)
        solidLayerThickness = 0.003962399904
        emissivityBackIR = 0.84
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness,
                                                      solidLayerConductance,
                                                      emissivityFrontIR,
                                                      TransmittanceIR,
                                                      emissivityBackIR,
                                                      TransmittanceIR)
        var gapThickness = 0.0001
        var gapPressure = 0.1333
        var m_GapLayer = Tarcog.ISO15099.Layers.gap(gapThickness, gapPressure)
        ASSERT_TRUE(m_GapLayer != None)
        var windowWidth = 1.0   #[m]
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers({layer1, m_GapLayer, layer2})
        self.m_TarcogSystem = make_shared[Tarcog.ISO15099.CSingleSystem](aIGU, Indoor, Outdoor)
        ASSERT_TRUE(self.m_TarcogSystem != None)
        self.m_TarcogSystem.solve()

    def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSingleSystem]:
        return self.m_TarcogSystem

def Test1(self: DoubleLowEVacuumNoPillar):
    SCOPED_TRACE("Begin Test: Double Low-E - vacuum with no pillar support")
    var aSystem = self.GetSystem()
    ASSERT_TRUE(aSystem != None)
    var Temperature = aSystem.getTemperatures()
    var correctTemperature = List[Float64](255.501938, 255.543003, 292.514948, 292.555627)
    ASSERT_EQ(correctTemperature.size, Temperature.size)
    for i in range(correctTemperature.size):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)

    var Radiosity = aSystem.getRadiosities()
    var correctRadiosity = List[Float64](241.409657, 407.569595, 413.894817, 416.791085)
    ASSERT_EQ(correctRadiosity.size, Radiosity.size)
    for i in range(correctRadiosity.size):
        EXPECT_NEAR(correctRadiosity[i], Radiosity[i], 1e-5)

    var numOfIter = aSystem.getNumberOfIterations()
    EXPECT_EQ(30, numOfIter)