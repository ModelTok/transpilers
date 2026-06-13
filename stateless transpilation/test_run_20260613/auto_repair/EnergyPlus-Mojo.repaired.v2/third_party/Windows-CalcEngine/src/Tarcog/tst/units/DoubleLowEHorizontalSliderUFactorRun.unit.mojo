from memory import std_make_shared
from gtest import testing, Test, TestFixture
from WCETarcog import Tarcog
from WCECommon import WCECommon

class TestDoubleLowEHorizontalSliderUFactorRun(TestFixture):
    var m_Window: Tarcog.ISO15099.DualVisionHorizontal

    def __init__(inout self):
        super().__init__()
        self.m_Window = Tarcog.ISO15099.DualVisionHorizontal()

    def SetUp(inout self):
        let airTemperature = 255.15   # Kelvins
        let airSpeed = 5.5            # meters per second
        let tSky = 255.15             # Kelvins
        let solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        testing.Assert(Outdoor is not None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature = 294.15
        let Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        testing.Assert(Indoor is not None)
        let solidLayerThickness1 = 0.00318   # [m]
        let solidLayerConductance1 = 1.0
        let tIR1 = 0.0
        let frontEmissivity1 = 0.84
        let backEmissivity1 = 0.046578168869
        let layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                   solidLayerConductance1,
                                                   frontEmissivity1,
                                                   tIR1,
                                                   backEmissivity1,
                                                   tIR1)
        testing.Assert(layer1 is not None)
        let gapThickness = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        let solidLayerThickness2 = 0.005715   # [m]
        let solidLayerConductance2 = 1.0
        let layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        let iguWidth = 1.0
        let iguHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        let igu = std_make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
        let uValue = 2.134059
        let edgeUValue = 2.251039
        let projectedFrameDimension = 0.050813
        let wettedLength = 0.05633282
        let absorptance = 0.3
        let frameData = Tarcog.ISO15099.FrameData(
          uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        let windowWidth = 1.5
        let windowHeight = 1.2
        let tVis = 0.6385
        let tSol = 0.371589958668
        self.m_Window = Tarcog.ISO15099.DualVisionHorizontal(
          windowWidth, windowHeight, tVis, tSol, igu, tVis, tSol, igu)
        self.m_Window.setFrameLeft(frameData)
        self.m_Window.setFrameRight(frameData)
        self.m_Window.setFrameBottomLeft(frameData)
        self.m_Window.setFrameBottomRight(frameData)
        self.m_Window.setFrameTopLeft(frameData)
        self.m_Window.setFrameTopRight(frameData)
        self.m_Window.setFrameMeetingRail(frameData)

    def getWindow(self) -> Tarcog.ISO15099.DualVisionHorizontal:
        return self.m_Window

@testing.fixture
def Test1():
    testing.SCOPED_TRACE("Begin Test: Double Low-e with Horizontal Slider - U-value run")
    let window = TestDoubleLowEHorizontalSliderUFactorRun.getWindow()
    let UValue = window.uValue()
    testing.ExpectNear(UValue, 1.891190, 1e-5)
    let SHGC = window.shgc()
    testing.ExpectNear(SHGC, 0.003514, 1e-5)
    let vt = window.vt()
    testing.ExpectNear(vt, 0.525034, 1e-5)