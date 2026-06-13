from memory import shared_ptr, make_shared
from gtest import Test, EXPECT_NEAR, SCOPED_TRACE
from WCETarcog import (
    Tarcog,
    ISO15099,
    DualVisionHorizontal,
    CSystem,
    CIGU,
    FrameData,
    Environments,
    Layers,
    SkyModel,
    BoundaryConditionsCoeffModel,
)
from WCECommon import *

class TestDoubleLowEHorizontalSliderSHGCRun(Test):
    var m_Window: Tarcog.ISO15099.DualVisionHorizontal

    def SetUp(self):
        const airTemperature = 305.15   # Kelvins
        const airSpeed = 2.75           # meters per second
        const tSky = 305.15             # Kelvins
        const solarRadiation = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        ASSERT_TRUE(Outdoor != None)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        const roomTemperature = 297.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        ASSERT_TRUE(Indoor != None)
        const solidLayerThickness1 = 0.00318   # [m]
        const solidLayerConductance1 = 1.0
        const tIR1 = 0.0
        const frontEmissivity1 = 0.84
        const backEmissivity1 = 0.046578168869
        var layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                  solidLayerConductance1,
                                                  frontEmissivity1,
                                                  tIR1,
                                                  backEmissivity1,
                                                  tIR1)
        ASSERT_TRUE(layer1 != None)
        layer1.setSolarAbsorptance(0.194422408938, solarRadiation)
        const gapThickness = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        const solidLayerThickness2 = 0.005715   # [m]
        const solidLayerConductance2 = 1.0
        var layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        ASSERT_TRUE(layer2 != None)
        layer2.setSolarAbsorptance(0.054760526866, solarRadiation)
        const iguWidth = 1.0
        const iguHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        var igu = make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
        const uValue = 2.134059
        const edgeUValue = 2.251039
        const projectedFrameDimension = 0.050813
        const wettedLength = 0.05633282
        const absorptance = 0.3
        const frameData = Tarcog.ISO15099.FrameData(
            uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
        const windowWidth = 1.5
        const windowHeight = 1.2
        const tVis = 0.6385
        const tSol = 0.371589958668
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

def Test1():
    SCOPED_TRACE("Begin Test: Double Low-e with Horizontal Slider - SHGC run")
    var window = TestDoubleLowEHorizontalSliderSHGCRun().getWindow()
    var UValue = window.uValue()
    EXPECT_NEAR(UValue, 1.836425, 1e-5)
    var SHGC = window.shgc()
    EXPECT_NEAR(SHGC, 0.359329, 1e-5)
    var vt = window.vt()
    EXPECT_NEAR(vt, 0.525034, 1e-5)