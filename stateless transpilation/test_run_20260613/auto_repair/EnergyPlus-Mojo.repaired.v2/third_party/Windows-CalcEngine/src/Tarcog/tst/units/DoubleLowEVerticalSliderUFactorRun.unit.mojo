from WCETarcog import *
from WCECommon import *
from memory import shared_ptr
from math import abs

class TestDoubleLowEVerticalSliderUFactorRun(inherits testing::Test):
    var m_Window: Tarcog::ISO15099::DualVisionVertical

    def SetUp(self) raises:
        let airTemperature: Float64 = 255.15   # Kelvins
        let airSpeed: Float64 = 5.5            # meters per second
        let tSky: Float64 = 255.15             # Kelvins
        let solarRadiation: Float64 = 0.0
        var Outdoor = Tarcog::ISO15099::Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog::ISO15099::SkyModel.AllSpecified)
        assert(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog::ISO15099::BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature: Float64 = 294.15
        let Indoor = Tarcog::ISO15099::Environments.indoor(roomTemperature)
        assert(Indoor != None)
        let solidLayerThickness1: Float64 = 0.00318   # [m]
        let solidLayerConductance1: Float64 = 1.0
        let tIR1: Float64 = 0.0
        let frontEmissivity1: Float64 = 0.84
        let backEmissivity1: Float64 = 0.046578168869
        let layer1 = Tarcog::ISO15099::Layers.solid(solidLayerThickness1,
                                                    solidLayerConductance1,
                                                    frontEmissivity1,
                                                    tIR1,
                                                    backEmissivity1,
                                                    tIR1)
        assert(layer1 != None)
        let gapThickness: Float64 = 0.0127
        var gap = Tarcog::ISO15099::Layers.gap(gapThickness)
        let solidLayerThickness2: Float64 = 0.005715   # [m]
        let solidLayerConductance2: Float64 = 1.0
        let layer2 = Tarcog::ISO15099::Layers.solid(solidLayerThickness2, solidLayerConductance2)
        let iguWidth: Float64 = 1.0
        let iguHeight: Float64 = 1.0
        var aIGU = Tarcog::ISO15099::CIGU(iguWidth, iguHeight)
        aIGU.addLayers({layer1, gap, layer2})
        let igu: shared_ptr[Tarcog::ISO15099::CSystem] = shared_ptr[Tarcog::ISO15099::CSystem](Tarcog::ISO15099::CSystem(aIGU, Indoor, Outdoor))
        let uValue: Float64 = 2.134059
        let edgeUValue: Float64 = 2.251039
        let projectedFrameDimension: Float64 = 0.050813
        let wettedLength: Float64 = 0.05633282
        let absorptance: Float64 = 0.3
        let frameData: Tarcog::ISO15099::FrameData = Tarcog::ISO15099::FrameData(
          uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        let windowWidth: Float64 = 1.2
        let windowHeight: Float64 = 1.5
        let tVis: Float64 = 0.6385
        let tSol: Float64 = 0.371589958668
        self.m_Window = Tarcog::ISO15099::DualVisionVertical(
          windowWidth, windowHeight, tVis, tSol, igu, tVis, tSol, igu)
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameTopLeft(frameData)
        self.m_Window.setFrameTopRight(frameData)
        self.m_Window.setFrameBottomLeft(frameData)
        self.m_Window.setFrameBottomRight(frameData)
        self.m_Window.setFrameMeetingRail(frameData)

    def getWindow(self) -> Tarcog::ISO15099::DualVisionVertical:
        return self.m_Window

@testing::TEST_F(TestDoubleLowEVerticalSliderUFactorRun, Test1)
def TestDoubleLowEVerticalSliderUFactorRun_Test1_Test():
    SCOPED_TRACE("Begin Test: Double Low-e with Vertical Slider - U-value run")
    let window = getWindow()
    let UValue = window.uValue()
    assert(abs(UValue - 1.886103) < 1e-5)
    let UValueCOG = window.uValueCOGAverage()
    assert(abs(UValueCOG - 1.667878) < 1e-5)
    let SHGC = window.shgc()
    assert(abs(SHGC - 0.003514) < 1e-5)
    let vt = window.vt()
    assert(abs(vt - 0.525034) < 1e-5)