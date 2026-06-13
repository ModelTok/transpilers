from Tarcog.ISO15099 import (
    CIGU,
    CSystem,
    Environments,
    FrameData,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel,
    WindowSingleVision,
)
from memory import Pointer
from testing import assert_approx_equal

class TestDoubleLowESingleVisionSHGCRun:
    var m_Window: WindowSingleVision

    def SetUp(inout self):
        const airTemperature: Float64 = 305.15   # Kelvins
        const airSpeed: Float64 = 2.75           # meters per second
        const tSky: Float64 = 305.15             # Kelvins
        const solarRadiation: Float64 = 783.0
        var Outdoor = Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified)
        assert Outdoor is not None
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        const roomTemperature: Float64 = 297.15
        const Indoor = Environments.indoor(roomTemperature)
        assert Indoor is not None
        const solidLayerThickness1: Float64 = 0.00318   # [m]
        const solidLayerConductance1: Float64 = 1.0
        const tIR1: Float64 = 0.0
        const frontEmissivity1: Float64 = 0.84
        const backEmissivity1: Float64 = 0.046578168869
        var layer1 = Layers.solid(solidLayerThickness1,
                                  solidLayerConductance1,
                                  frontEmissivity1,
                                  tIR1,
                                  backEmissivity1,
                                  tIR1)
        assert layer1 is not None
        layer1.setSolarAbsorptance(0.194422408938, solarRadiation)
        const gapThickness: Float64 = 0.0127
        var gap = Layers.gap(gapThickness)
        const solidLayerThickness2: Float64 = 0.005715   # [m]
        const solidLayerConductance2: Float64 = 1.0
        var layer2 = Layers.solid(solidLayerThickness2, solidLayerConductance2)
        assert layer2 is not None
        layer2.setSolarAbsorptance(0.054760526866, solarRadiation)
        const iguWidth: Float64 = 1.0
        const iguHeight: Float64 = 1.0
        var aIGU = CIGU(iguWidth, iguHeight)
        aIGU.addLayers(layer1, gap, layer2)
        var igu = Pointer[CSystem](CSystem(aIGU, Indoor, Outdoor))
        const uValue: Float64 = 2.134059
        const edgeUValue: Float64 = 2.251039
        const projectedFrameDimension: Float64 = 0.050813
        const wettedLength: Float64 = 0.05633282
        const absorptance: Float64 = 0.3
        var frameData = FrameData(
          uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        const windowWidth: Float64 = 1.2
        const windowHeight: Float64 = 1.5
        const tVis: Float64 = 0.6385
        const tSol: Float64 = 0.371589958668
        self.m_Window = WindowSingleVision(windowWidth, windowHeight, tVis, tSol, igu.take())
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameLeft(frameData)
        self.m_Window.setFrameRight(frameData)

    def getWindow(self) -> WindowSingleVision:
        return self.m_Window

def test_TestDoubleLowESingleVisionSHGCRun_Test1():
    print("Begin Test: Double Low-e with Single Vision - SHGC run")
    var testObj = TestDoubleLowESingleVisionSHGCRun()
    testObj.SetUp()
    var window = testObj.getWindow()
    var UValue = window.uValue()
    assert_approx_equal(UValue, 1.772762, abs_tol=1e-5)
    var SHGC = window.shgc()
    assert_approx_equal(SHGC, 0.371641, abs_tol=1e-5)
    var vt = window.vt()
    assert_approx_equal(vt, 0.544831, abs_tol=1e-5)