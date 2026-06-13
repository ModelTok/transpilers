from memory import pointer
from stdexcept import raise_error
from testing import Test, expect, expect_near, scoped_trace
from WCETarcog import (
    Tarcog,
    ISO15099,
    WindowSingleVision,
    CSystem,
    CIGU,
    FrameData,
    Environments,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel
)
from WCECommon import *

@value
class TestDoubleLowESingleVisionSHGCRunWithDividers(Test):
    var m_Window: Tarcog.ISO15099.WindowSingleVision

    def __init__(inout self):
        self.m_Window = Tarcog.ISO15099.WindowSingleVision()

    def SetUp(inout self):
        const airTemperature = 305.15   # Kelvins
        const airSpeed = 2.75           # meters per second
        const tSky = 305.15             # Kelvins
        const solarRadiation = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        expect(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        const roomTemperature = 297.15
        const Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        expect(Indoor != None)
        const solidLayerThickness1 = 0.00318   # [m]
        const solidLayerConductance1 = 1.0
        const tIR1 = 0.0
        const frontEmissivity1 = 0.84
        const backEmissivity1 = 0.046578168869
        const layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                            solidLayerConductance1,
                                                            frontEmissivity1,
                                                            tIR1,
                                                            backEmissivity1,
                                                            tIR1)
        expect(layer1 != None)
        layer1.setSolarAbsorptance(0.194422408938, solarRadiation)
        const gapThickness = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        const solidLayerThickness2 = 0.005715   # [m]
        const solidLayerConductance2 = 1.0
        const layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        expect(layer2 != None)
        layer2.setSolarAbsorptance(0.054760526866, solarRadiation)
        const iguWidth = 1.0
        const iguHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        const igu = pointer[Tarcog.ISO15099.CSystem](Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))
        const uValue = 2.134059
        const edgeUValue = 2.251039
        const projectedFrameDimension = 0.050813
        const wettedLength = 0.05633282
        const absorptance = 0.3
        var frameData = Tarcog.ISO15099.FrameData(
          uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        const windowWidth = 1.2
        const windowHeight = 1.5
        const tVis = 0.6385
        const tSol = 0.371589958668
        self.m_Window = Tarcog.ISO15099.WindowSingleVision(windowWidth, windowHeight, tVis, tSol, igu)
        self.m_Window.setFrameTop(frameData)
        self.m_Window.setFrameBottom(frameData)
        self.m_Window.setFrameLeft(frameData)
        self.m_Window.setFrameRight(frameData)
        var nVertical = 2
        var nHorizontal = 3
        self.m_Window.setDividers(frameData, nHorizontal, nVertical)

    def getWindow(self) -> Tarcog.ISO15099.WindowSingleVision:
        return self.m_Window

def TestDoubleLowESingleVisionSHGCRunWithDividers_Test1():
    scoped_trace("Begin Test: Double Low-e with Single Vision with dividers - SHGC run")
    const window = TestDoubleLowESingleVisionSHGCRunWithDividers().getWindow()
    const UValue = window.uValue()
    expect_near(UValue, 2.045111, 1e-5)
    const SHGC = window.shgc()
    expect_near(SHGC, 0.305860, 1e-5)
    const vt = window.vt()
    expect_near(vt, 0.440524, 1e-5)