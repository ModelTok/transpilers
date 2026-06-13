from memory import shared_ptr, make_shared
from gtest import Test, TestFixture, ASSERT_TRUE, EXPECT_NEAR, SCOPED_TRACE
from WCETarcog import (
    Tarcog,
    ISO15099,
    CSystem,
    Environments,
    Layers,
    CIGU,
    SkyModel,
    BoundaryConditionsCoeffModel,
    System,
)
from WCECommon import *

class TestTripleClearDeflectionWithLoad(TestFixture):
    private:
        var m_TarcogSystem: shared_ptr[Tarcog.ISO15099.CSystem]

    protected:
        def SetUp(self) raises:
            const airTemperature: Float64 = 250.0
            const airSpeed: Float64 = 5.5
            const tSky: Float64 = 255.15
            const solarRadiation: Float64 = 0.0
            var Outdoor = Tarcog.ISO15099.Environments.outdoor(
                airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified
            )
            ASSERT_TRUE(Outdoor != None)
            Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
            const roomTemperature: Float64 = 293.0
            var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
            ASSERT_TRUE(Indoor != None)
            const solidLayerThickness: Float64 = 0.003048
            const solidLayerConductance: Float64 = 1.0
            var aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            aSolidLayer1.setSolarAbsorptance(0.099839858711, solarRadiation)
            var aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            aSolidLayer2.setSolarAbsorptance(0.076627746224, solarRadiation)
            var aSolidLayer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
            aSolidLayer3.setSolarAbsorptance(0.058234799653, solarRadiation)
            const gapThickness1: Float64 = 0.006
            const gapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness1)
            ASSERT_TRUE(gapLayer1 != None)
            const gapThickness2: Float64 = 0.025
            const gapLayer2 = Tarcog.ISO15099.Layers.gap(gapThickness2)
            ASSERT_TRUE(gapLayer2 != None)
            const windowWidth: Float64 = 1.0
            const windowHeight: Float64 = 1.0
            var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
            aIGU.addLayers([aSolidLayer1, gapLayer1, aSolidLayer2, gapLayer2, aSolidLayer3])
            m_TarcogSystem = make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
            m_TarcogSystem.setAppliedLoad([0, 0, 100000])
            m_TarcogSystem.setDeflectionProperties(273, 101325)
            ASSERT_TRUE(m_TarcogSystem != None)

    public:
        def GetSystem(self) -> shared_ptr[Tarcog.ISO15099.CSystem]:
            return m_TarcogSystem

def TestTripleClearDeflectionWithLoad_Test1() raises:
    SCOPED_TRACE("Begin Test: Double Clear - Surface temperatures")
    var aSystem = TestTripleClearDeflectionWithLoad().GetSystem()
    ASSERT_TRUE(aSystem != None)
    var aRun = Tarcog.ISO15099.System.Uvalue
    var Temperature = aSystem.getTemperatures(aRun)
    var correctTemperature = List[Float64](253.314583, 253.583839, 265.810776, 266.080031, 280.499960, 280.769216)
    ASSERT_EQ(len(correctTemperature), len(Temperature))
    for i in range(len(correctTemperature)):
        EXPECT_NEAR(correctTemperature[i], Temperature[i], 1e-5)
    var correctDeflection = List[Float64](22.784211e-3, 24.460877e-3, 63.338034e-3)
    var deflection = aSystem.getMaxDeflections(Tarcog.ISO15099.System.Uvalue)
    for i in range(len(correctDeflection)):
        EXPECT_NEAR(correctDeflection[i], deflection[i], 1e-8)