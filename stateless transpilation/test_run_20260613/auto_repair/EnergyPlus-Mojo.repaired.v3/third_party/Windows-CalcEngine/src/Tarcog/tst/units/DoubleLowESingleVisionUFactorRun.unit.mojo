from memory import Rc
from testing import *
from WCETarcog import (
    WindowSingleVision,
    Environments,
    Layers,
    CIGU,
    CSystem,
    FrameData,
    SkyModel,
    BoundaryConditionsCoeffModel,
)

struct TestDoubleLowESingleVisionUFactorRun:
    var m_Window: WindowSingleVision

    def set_up(self):
        let airTemperature = 255.15   # Kelvins
        let airSpeed = 5.5            # meters per second
        let tSky = 255.15             # Kelvins
        let solarRadiation = 0.0
        let Outdoor = Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, SkyModel.AllSpecified
        )
        assert_true(Outdoor is not None)
        Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.CalculateH)
        let roomTemperature = 294.15
        let Indoor = Environments.indoor(roomTemperature)
        assert_true(Indoor is not None)
        let solidLayerThickness1 = 0.00318   # [m]
        let solidLayerConductance1 = 1.0
        let tIR1 = 0.0
        let frontEmissivity1 = 0.84
        let backEmissivity1 = 0.046578168869
        let layer1 = Layers.solid(
            solidLayerThickness1,
            solidLayerConductance1,
            frontEmissivity1,
            tIR1,
            backEmissivity1,
            tIR1,
        )
        assert_true(layer1 is not None)
        let gapThickness = 0.0127
        let gap = Layers.gap(gapThickness)
        let solidLayerThickness2 = 0.005715   # [m]
        let solidLayerConductance2 = 1.0
        let layer2 = Layers.solid(solidLayerThickness2, solidLayerConductance2)
        let iguWidth = 1.0
        let iguHeight = 1.0
        let aIGU = CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        let igu = Rc.new(CSystem(aIGU, Indoor, Outdoor))
        let uValue = 2.134059
        let edgeUValue = 2.251039
        let projectedFrameDimension = 0.050813
        let wettedLength = 0.05633282
        let absorptance = 0.3
        let frameData = FrameData{
            uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance
        }
        let windowWidth = 1.2
        let windowHeight = 1.5
        let tVis = 0.6385
        let tSol = 0.371589958668
        self.m_Window = WindowSingleVision(windowWidth, windowHeight, tVis, tSol, igu)
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameLeft(frameData)
        self.m_Window.setFrameRight(frameData)

    def get_window(self) -> WindowSingleVision:
        return self.m_Window

@test
def Test1():
    SCOPED_TRACE("Begin Test: Double Low-e with Single Vision - U-value run")
    let fixture = TestDoubleLowESingleVisionUFactorRun()
    fixture.set_up()
    let window = fixture.get_window()
    let UValue = window.uValue()
    expect_near(UValue, 1.833771, 1e-5)
    let UValueCOG = window.uValueCOGAverage()
    expect_near(UValueCOG, 1.667878, 1e-5)
    let SHGC = window.shgc()
    expect_near(SHGC, 0.002901, 1e-5)
    let vt = window.vt()
    expect_near(vt, 0.544831, 1e-5)