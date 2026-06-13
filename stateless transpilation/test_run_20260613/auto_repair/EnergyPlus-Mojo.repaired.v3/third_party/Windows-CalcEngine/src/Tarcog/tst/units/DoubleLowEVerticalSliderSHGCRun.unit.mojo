from memory import pointer
from WCETarcog import *
from WCECommon import *
from testing import *

class TestDoubleLowEVerticalSliderSHGCRun(Testing):
    var m_Window: Tarcog.ISO15099.DualVisionVertical

    def SetUp(self):
        let airTemperature: Float64 = 305.15   # Kelvins
        let airSpeed: Float64 = 2.75           # meters per second
        let tSky: Float64 = 305.15             # Kelvins
        let solarRadiation: Float64 = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assertTrue(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature: Float64 = 297.15
        let Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assertTrue(Indoor != None)
        let solidLayerThickness1: Float64 = 0.00318   # [m]
        let solidLayerConductance1: Float64 = 1.0
        let tIR1: Float64 = 0.0
        let frontEmissivity1: Float64 = 0.84
        let backEmissivity1: Float64 = 0.046578168869
        let layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                    solidLayerConductance1,
                                                    frontEmissivity1,
                                                    tIR1,
                                                    backEmissivity1,
                                                    tIR1)
        assertTrue(layer1 != None)
        layer1.setSolarAbsorptance(0.194422408938, solarRadiation)
        let gapThickness: Float64 = 0.0127
        var gap: Tarcog.ISO15099.Layers.gap(gapThickness)
        let solidLayerThickness2: Float64 = 0.005715   # [m]
        let solidLayerConductance2: Float64 = 1.0
        let layer2 =
          Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        assertTrue(layer2 != None)
        layer2.setSolarAbsorptance(0.054760526866, solarRadiation)
        let iguWidth: Float64 = 1.0
        let iguHeight: Float64 = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers(List(layer1, gap, layer2))
        let igu = pointer[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        let uValue: Float64 = 2.134059
        let edgeUValue: Float64 = 2.251039
        let projectedFrameDimension: Float64 = 0.050813
        let wettedLength: Float64 = 0.05633282
        let absorptance: Float64 = 0.3
        let frameData: Tarcog.ISO15099.FrameData = Tarcog.ISO15099.FrameData(
          uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        let windowWidth: Float64 = 1.2
        let windowHeight: Float64 = 1.5
        let tVis: Float64 = 0.6385
        let tSol: Float64 = 0.371589958668
        self.m_Window = Tarcog.ISO15099.DualVisionVertical(
          windowWidth, windowHeight, tVis, tSol, igu, tVis, tSol, igu)
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameTopLeft(frameData)
        self.m_Window.setFrameTopRight(frameData)
        self.m_Window.setFrameBottomLeft(frameData)
        self.m_Window.setFrameBottomRight(frameData)
        self.m_Window.setFrameMeetingRail(frameData)

    def getWindow(self) -> Tarcog.ISO15099.DualVisionVertical:
        return self.m_Window

def Test1():
    SCOPED_TRACE("Begin Test: Double Low-e with Vertical Slider - SHGC run")
    let window = TestDoubleLowEVerticalSliderSHGCRun().getWindow()
    let UValue = window.uValue()
    EXPECT_NEAR(UValue, 1.833626, 1e-5)
    let SHGC = window.shgc()
    EXPECT_NEAR(SHGC, 0.359156, 1e-5)
    let vt = window.vt()
    EXPECT_NEAR(vt, 0.525034, 1e-5)