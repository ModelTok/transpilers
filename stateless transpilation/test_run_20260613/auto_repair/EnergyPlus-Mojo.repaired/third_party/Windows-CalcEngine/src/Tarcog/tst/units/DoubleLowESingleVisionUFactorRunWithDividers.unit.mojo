from WCETarcog import Tarcog
from WCECommon import *
from testing import assert_approx_equal, assert

struct TestDoubleLowESingleVisionUFactorRunWithDividers:
    var m_Window: Tarcog.ISO15099.WindowSingleVision

    def SetUp(self):
        let airTemperature = 255.15
        let airSpeed = 5.5
        let tSky = 255.15
        let solarRadiation = 0.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert(Outdoor != None)
        Outdoor[].setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert(Indoor != None)
        let solidLayerThickness1 = 0.00318
        let solidLayerConductance1 = 1.0
        let tIR1 = 0.0
        let frontEmissivity1 = 0.84
        let backEmissivity1 = 0.046578168869
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1, solidLayerConductance1, frontEmissivity1, tIR1, backEmissivity1, tIR1)
        assert(layer1 != None)
        let gapThickness = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        let solidLayerThickness2 = 0.005715
        let solidLayerConductance2 = 1.0
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        let iguWidth = 1.0
        let iguHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        var igu = Arc[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        let uValue = 2.134059
        let edgeUValue = 2.251039
        let projectedFrameDimension = 0.050813
        let wettedLength = 0.05633282
        let absorptance = 0.3
        let frameData = Tarcog.ISO15099.FrameData(uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        let windowWidth = 1.2
        let windowHeight = 1.5
        let tVis = 0.6385
        let tSol = 0.371589958668
        self.m_Window = Tarcog.ISO15099.WindowSingleVision(windowWidth, windowHeight, tVis, tSol, igu)
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameLeft(frameData)
        self.m_Window.setFrameRight(frameData)
        let nVertical: UInt = 2
        let nHorizontal: UInt = 3
        self.m_Window.setDividers(frameData, nHorizontal, nVertical)

    def getWindow(self) -> &Tarcog.ISO15099.WindowSingleVision:
        return self.m_Window

@test
def TestDoubleLowESingleVisionUFactorRunWithDividers_Test1():
    var testFixture = TestDoubleLowESingleVisionUFactorRunWithDividers()
    testFixture.SetUp()
    # SCOPED_TRACE("Begin Test: Double Low-e with Single Vision with dividers - U-value run")
    let window = testFixture.getWindow()
    let UValue = window.uValue()
    assert_approx_equal(UValue, 2.067558, 1e-5)
    let SHGC = window.shgc()
    assert_approx_equal(SHGC, 0.006131, 1e-5)
    let vt = window.vt()
    assert_approx_equal(vt, 0.440524, 1e-5)