from gtest import Test, TestFixture
from WCETarcog import (
    Tarcog, 
    CSystem, 
    Environments, 
    SkyModel, 
    BoundaryConditionsCoeffModel,
    Layers,
    CIGU,
    FrameData,
    DualVisionHorizontal,
    SimpleIGU
)
from memory import Pointer
from math import isclose

class TestHorizontalSliderWindow(TestFixture):
    def SetUp(self) raises:

    @staticmethod
    def getCOG() raises -> Pointer[Tarcog.ISO15099.CSystem]:
        var airTemperature = 300.0   # Kelvins
        var airSpeed = 5.5           # meters per second
        var tSky = 270.0             # Kelvins
        var solarRadiation = 789.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 294.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        var solidLayerThickness = 0.003048   # [m]
        var solidLayerConductance = 1.0
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer.setSolarAbsorptance(0.094189159572, solarRadiation)
        var windowWidth = 1.0
        var windowHeight = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        return Pointer[Tarcog.ISO15099.CSystem].make_ptr(Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))

def TestHorizontalSliderWindow_PredefinedCOGValues(test: Test) raises:
    test.scoped_trace("Begin Test: Horizontal slider window predefined COG.")
    const uValue: Float64 = 2.134059
    const edgeUValue: Float64 = 2.251039
    const projectedFrameDimension: Float64 = 0.050813
    const wettedLength: Float64 = 0.05633282
    const absorptance: Float64 = 0.3
    var frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    const width: Float64 = 1.2
    const height: Float64 = 1.5
    const iguUValue: Float64 = 1.667875
    const shgc: Float64 = 0.430713
    const tVis: Float64 = 0.638525
    const tSol: Float64 = 0.3716
    const hcout: Float64 = 15.0
    var window = Tarcog.ISO15099.DualVisionHorizontal(
        width,
        height,
        tVis,
        tSol,
        Pointer[Tarcog.ISO15099.SimpleIGU].make_ptr(Tarcog.ISO15099.SimpleIGU(iguUValue, shgc, hcout)),
        tVis,
        tSol,
        Pointer[Tarcog.ISO15099.SimpleIGU].make_ptr(Tarcog.ISO15099.SimpleIGU(iguUValue, shgc, hcout)))
    window.setFrameTopLeft(frameData)
    window.setFrameTopRight(frameData)
    window.setFrameMeetingRail(frameData)
    window.setFrameLeft(frameData)
    window.setFrameRight(frameData)
    window.setFrameBottomLeft(frameData)
    window.setFrameBottomRight(frameData)
    const vt: Float64 = window.vt()
    test.expect_near(0.519647, vt, 1e-6)
    const uvalue: Float64 = window.uValue()
    test.expect_near(1.902392, uvalue, 1e-6)
    const windowSHGC: Float64 = window.shgc()
    test.expect_near(0.357692, windowSHGC, 1e-6)

def TestHorizontalSliderWindow_CalculatedCOG(test: Test) raises:
    test.scoped_trace("Begin Test: Horizontal slider window calculated COG.")
    const uValue: Float64 = 2.134059
    const edgeUValue: Float64 = 2.251039
    const projectedFrameDimension: Float64 = 0.050813
    const wettedLength: Float64 = 0.05633282
    const absorptance: Float64 = 0.3
    var frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    const width: Float64 = 1.2
    const height: Float64 = 1.5
    const tVis: Float64 = 0.638525
    const tSol: Float64 = 0.3716
    var window = Tarcog.ISO15099.DualVisionHorizontal(
        width, height, tVis, tSol, TestHorizontalSliderWindow.getCOG(), tVis, tSol, TestHorizontalSliderWindow.getCOG())
    window.setFrameTopLeft(frameData)
    window.setFrameTopRight(frameData)
    window.setFrameMeetingRail(frameData)
    window.setFrameLeft(frameData)
    window.setFrameRight(frameData)
    window.setFrameBottomLeft(frameData)
    window.setFrameBottomRight(frameData)
    const vt: Float64 = window.vt()
    test.expect_near(0.519647, vt, 1e-6)
    const uvalue: Float64 = window.uValue()
    test.expect_near(3.980813, uvalue, 1e-6)
    const windowSHGC: Float64 = window.shgc()
    test.expect_near(0.321015, windowSHGC, 1e-6)