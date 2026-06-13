from memory import Pointer
from testing import *
from WCETarcog import Tarcog
from WCECommon import *

struct TestTripleClearDeflection(Testing.Test):
    var m_TarcogSystem: Pointer[Tarcog.ISO15099.CSystem]

    def SetUp() raises:
        let airTemperature: Float64 = 250.0      # Kelvins
        let airSpeed: Float64 = 5.5              # meters per second
        let tSky: Float64 = 255.15               # Kelvins
        let solarRadiation: Float64 = 783.0
        let Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky,
            Tarcog.ISO15099.SkyModel.AllSpecified)
        assert_true(Outdoor)
        Outdoor.setHCoeffModel(
            Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature: Float64 = 293.0
        let Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert_true(Indoor)
        let solidLayerThickness: Float64 = 0.003048  # [m]
        let solidLayerConductance: Float64 = 1.0     # [W/m2K]
        let aSolidLayer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer1.setSolarAbsorptance(0.099839858711, solarRadiation)
        let aSolidLayer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer2.setSolarAbsorptance(0.076627746224, solarRadiation)
        let aSolidLayer3 = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer3.setSolarAbsorptance(0.058234799653, solarRadiation)
        let gapThickness1: Float64 = 0.006
        let gapLayer1 = Tarcog.ISO15099.Layers.gap(gapThickness1)
        assert_true(gapLayer1)
        let gapThickness2: Float64 = 0.025
        let gapLayer2 = Tarcog.ISO15099.Layers.gap(gapThickness2)
        assert_true(gapLayer2)
        let windowWidth: Float64 = 1.0
        let windowHeight: Float64 = 1.0
        let aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayers([aSolidLayer1, gapLayer1, aSolidLayer2, gapLayer2, aSolidLayer3])
        m_TarcogSystem = Pointer[Tarcog.ISO15099.CSystem].init(aIGU, Indoor, Outdoor)
        m_TarcogSystem.setDeflectionProperties(273, 101325)
        assert_true(m_TarcogSystem)

    def GetSystem() -> Pointer[Tarcog.ISO15099.CSystem]:
        return m_TarcogSystem

    # Corresponds to TEST_F(TestTripleClearDeflection, Test1)
    def test_test1() raises:
        #SCOPED_TRACE("Begin Test: Double Clear - Surface temperatures")
        let aSystem = GetSystem()
        assert_true(aSystem)
        var aRun = Tarcog.ISO15099.System.Uvalue
        var Temperature = aSystem.getTemperatures(aRun)
        let correctTemperature: List[Float64] = List[Float64](
            253.145118, 253.399346, 265.491216, 265.745444, 281.162092, 281.416320)
        assert_equal(len(correctTemperature), len(Temperature))
        for i in range(len(correctTemperature)):
            assert_approx_equal(correctTemperature[i], Temperature[i], 1e-5)
        let correctDeflection: List[Float64] = List[Float64](
            -0.421986e-3, 0.265021e-3, 0.167762e-3)
        var deflection = aSystem.getMaxDeflections(Tarcog.ISO15099.System.Uvalue)
        for i in range(len(correctDeflection)):
            assert_approx_equal(correctDeflection[i], deflection[i], 1e-8)
        let numOfIter = aSystem.getNumberOfIterations(aRun)
        assert_equal(20, numOfIter)
        aRun = Tarcog.ISO15099.System.SHGC
        Temperature = aSystem.getTemperatures(aRun)
        let correctTemperature2: List[Float64] = List[Float64](
            257.435790, 257.952362, 276.186799, 276.492794, 289.163055, 289.308119)
        assert_equal(len(correctTemperature2), len(Temperature))
        for i in range(len(correctTemperature2)):
            assert_approx_equal(correctTemperature2[i], Temperature[i], 1e-5)
        let correctDeflection2: List[Float64] = List[Float64](
            -0.421986e-3, 0.265021e-3, 0.167762e-3)
        deflection = aSystem.getMaxDeflections(Tarcog.ISO15099.System.Uvalue)
        for i in range(len(correctDeflection2)):
            assert_approx_equal(correctDeflection2[i], deflection[i], 1e-8)
        let numOfIter2 = aSystem.getNumberOfIterations(aRun)
        assert_equal(21, numOfIter2)
        let Uvalue = aSystem.getUValue()
        assert_approx_equal(Uvalue, 1.9522982371191091, 1e-5)
        let SHGC = aSystem.getSHGC(0.598424255848)
        assert_approx_equal(SHGC, 0.673282, 1e-5)
        let relativeHeatGain = aSystem.relativeHeatGain(0.703296)
        assert_approx_equal(relativeHeatGain, 579.484762, 1e-5)