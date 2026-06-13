from testing import Test
from memory import SharedPtr
from WCETarcog import *
from math import isclose

class TestSingleVisionWindow(Test):
    def SetUp(self):

    @staticmethod
    def getCOG() -> SharedPtr[Tarcog.ISO15099.CSystem]:
        var airTemperature = 305.15  # Kelvins
        var airSpeed = 2.75  # meters per second
        var tSky = 305.15  # Kelvins
        var solarRadiation = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
            airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        var roomTemperature = 297.15
        var Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        var solidLayerThickness = 0.003048  # [m]
        var solidLayerConductance = 1.0
        var aSolidLayer = Tarcog.ISO15099.Layers.solid(solidLayerThickness, solidLayerConductance)
        aSolidLayer.setSolarAbsorptance(0.0914, solarRadiation)
        var windowWidth = 2.0
        var windowHeight = 2.0
        var aIGU = Tarcog.ISO15099.CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        return SharedPtr[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)

@register_test(TestSingleVisionWindow, "PredefinedCOGValues")
def test_PredefinedCOGValues():
    # SCOPED_TRACE("Begin Test: Single vision window with predefined COG values.")
    var uValue = 5.68
    var edgeUValue = 5.575
    var projectedFrameDimension = 0.05715
    var wettedLength = 0.05715
    var absorptance = 0.9
    var frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    var width = 2.0
    var height = 2.0
    var iguUValue = 5.575
    var shgc = 0.86
    var tVis = 0.899
    var tSol = 0.8338
    var hout = 20.42635
    var window = Tarcog.ISO15099.WindowSingleVision(
        width,
        height,
        tVis,
        tSol,
        SharedPtr[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout))
    window.setFrameTop(frameData)
    window.setFrameBottom(frameData)
    window.setFrameLeft(frameData)
    window.setFrameRight(frameData)
    var vt = window.vt()
    assert isclose(0.799180, vt, rel_tol=1e-6, abs_tol=1e-6)
    var uvalue = window.uValue()
    assert isclose(5.586659, uvalue, rel_tol=1e-6, abs_tol=1e-6)
    var windowSHGC = window.shgc()
    assert isclose(0.792299, windowSHGC, rel_tol=1e-6, abs_tol=1e-6)

@register_test(TestSingleVisionWindow, "CalculatedCOG")
def test_CalculatedCOG():
    # SCOPED_TRACE("Begin Test: Single vision window with calculated COG values.")
    var uValue = 5.68
    var edgeUValue = 5.575
    var projectedFrameDimension = 0.05715
    var wettedLength = 0.05715
    var absorptance = 0.9
    var frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    var width = 2.0
    var height = 2.0
    var tVis = 0.899
    var tSol = 0.8338
    var window = Tarcog.ISO15099.WindowSingleVision(width, height, tVis, tSol, TestSingleVisionWindow.getCOG())
    window.setFrameTop(frameData)
    window.setFrameBottom(frameData)
    window.setFrameLeft(frameData)
    window.setFrameRight(frameData)
    var vt = window.vt()
    assert isclose(0.799181, vt, rel_tol=1e-6, abs_tol=1e-6)
    var uvalue = window.uValue()
    assert isclose(5.255746, uvalue, rel_tol=1e-6, abs_tol=1e-6)
    var windowSHGC = window.shgc()
    assert isclose(0.791895, windowSHGC, rel_tol=1e-6, abs_tol=1e-6)