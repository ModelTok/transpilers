from testing import *
from memory import *
from WCETarcog import *
from math import *

class TestVerticalSliderWindow(Test):
    def SetUp(self):

    @staticmethod
    def getCOG() -> SharedPtr[Tarcog.ISO15099.CSystem]:
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
        return make_shared[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)

@fixture(scope="class")
def TestVerticalSliderWindow_PredefinedCOGValues():
    SCOPED_TRACE("Begin Test: Vertical slider window with predefined COG values.")
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
    var window = Tarcog.ISO15099.DualVisionVertical(
      width,
      height,
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hcout),
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hcout))
    window.setFrameTop(frameData)
    window.setFrameTopLeft(frameData)
    window.setFrameTopRight(frameData)
    window.setFrameMeetingRail(frameData)
    window.setFrameBottomLeft(frameData)
    window.setFrameBottomRight(frameData)
    window.setFrameBottom(frameData)
    const vt: Float64 = window.vt()
    EXPECT_NEAR(0.525054, vt, 1e-6)
    const uvalue: Float64 = window.uValue()
    EXPECT_NEAR(1.886101, uvalue, 1e-6)
    const windowSHGC: Float64 = window.shgc()
    EXPECT_NEAR(0.361014, windowSHGC, 1e-6)

@fixture(scope="class")
def TestVerticalSliderWindow_CalculatedCOG():
    SCOPED_TRACE("Begin Test: Vertical slider window with calculated COG.")
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
    var window = Tarcog.ISO15099.DualVisionVertical(
      width, height, tVis, tSol, TestVerticalSliderWindow.getCOG(), tVis, tSol, TestVerticalSliderWindow.getCOG())
    window.setFrameTop(frameData)
    window.setFrameTopLeft(frameData)
    window.setFrameTopRight(frameData)
    window.setFrameMeetingRail(frameData)
    window.setFrameBottomLeft(frameData)
    window.setFrameBottomRight(frameData)
    window.setFrameBottom(frameData)
    const vt: Float64 = window.vt()
    EXPECT_NEAR(0.525054, vt, 1e-6)
    const uvalue: Float64 = window.uValue()
    EXPECT_NEAR(4.074413, uvalue, 1e-6)
    const windowSHGC: Float64 = window.shgc()
    EXPECT_NEAR(0.324160, windowSHGC, 1e-6)

@fixture(scope="class")
def TestVerticalSliderWindow_CalculatedSHGC01VT01():
    var uValue: Float64 = 3.123
    var edgeUValue: Float64 = 1.241
    var projectedFrameDimension: Float64 = 0.063824
    var wettedLength: Float64 = 0.134467
    var absorptance: Float64 = 0.3
    var bottomSill = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 3.336
    edgeUValue = 1.238
    projectedFrameDimension = 0.063916
    wettedLength = 0.098926
    absorptance = 0.3
    var topSill = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 5.306
    edgeUValue = 1.308
    projectedFrameDimension = 0.036
    wettedLength = 0.098123
    absorptance = 0.3
    var meetingRail = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 2.753
    edgeUValue = 1.269
    projectedFrameDimension = 0.071711
    wettedLength = 0.264335
    absorptance = 0.3
    var lowerJamb = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 2.454
    edgeUValue = 1.329
    projectedFrameDimension = 0.083681
    wettedLength = 0.11389
    absorptance = 0.3
    var upperJamb = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    const width: Float64 = 1.2
    const height: Float64 = 1.5
    var iguUValue: Float64 = 1.154808
    var shgc: Float64 = 0.0
    var tVis: Float64 = 0.0
    var tSol: Float64 = 0.3716
    var hout: Float64 = 20.6077232
    var window = Tarcog.ISO15099.DualVisionVertical(
      width,
      height,
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout),
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout))
    window.setFrameTop(topSill)
    window.setFrameTopLeft(upperJamb)
    window.setFrameTopRight(upperJamb)
    window.setFrameMeetingRail(meetingRail)
    window.setFrameBottomLeft(lowerJamb)
    window.setFrameBottomRight(lowerJamb)
    window.setFrameBottom(bottomSill)
    const VT0: Float64 = window.vt()
    EXPECT_NEAR(0.0, VT0, 1e-6)
    const SHGC0: Float64 = window.shgc()
    EXPECT_NEAR(0.005074, SHGC0, 1e-6)
    iguUValue = 1.154808
    shgc = 1.0
    tVis = 1.0
    window = Tarcog.ISO15099.DualVisionVertical(
      width,
      height,
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout),
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout))
    window.setFrameTop(topSill)
    window.setFrameTopLeft(upperJamb)
    window.setFrameTopRight(upperJamb)
    window.setFrameMeetingRail(meetingRail)
    window.setFrameBottomLeft(lowerJamb)
    window.setFrameBottomRight(lowerJamb)
    window.setFrameBottom(bottomSill)
    const VT1: Float64 = window.vt()
    EXPECT_NEAR(0.775483, VT1, 1e-6)
    const SHGC1: Float64 = window.shgc()
    EXPECT_NEAR(0.780556, SHGC1, 1e-6)

@fixture(scope="class")
def TestVerticalSliderWindow_CalculatedSHGC01VT01GenericDividers():
    var uValue: Float64 = 3.123
    var edgeUValue: Float64 = 1.241
    var projectedFrameDimension: Float64 = 0.063824
    var wettedLength: Float64 = 0.134467
    var absorptance: Float64 = 0.3
    var bottomSill = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 3.336
    edgeUValue = 1.238
    projectedFrameDimension = 0.063916
    wettedLength = 0.098926
    absorptance = 0.3
    var topSill = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 5.306
    edgeUValue = 1.308
    projectedFrameDimension = 0.036
    wettedLength = 0.098123
    absorptance = 0.3
    var meetingRail = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 2.753
    edgeUValue = 1.269
    projectedFrameDimension = 0.071711
    wettedLength = 0.264335
    absorptance = 0.3
    var lowerJamb = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 2.454
    edgeUValue = 1.329
    projectedFrameDimension = 0.083681
    wettedLength = 0.11389
    absorptance = 0.3
    var upperJamb = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    uValue = 2.2713050842285156
    edgeUValue = 2.2713050842285156
    projectedFrameDimension = 0.01905
    wettedLength = 0.01905
    absorptance = 0.3
    var divider = Tarcog.ISO15099.FrameData(
      uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance)
    const width: Float64 = 1.2
    const height: Float64 = 1.5
    const nHorizontal: UInt = 2
    const nVertical: UInt = 3
    var iguUValue: Float64 = 1.154808
    var shgc: Float64 = 0.0
    var tVis: Float64 = 0.0
    var tSol: Float64 = 0.3716
    var hout: Float64 = 20.6077232
    var window = Tarcog.ISO15099.DualVisionVertical(
      width,
      height,
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout),
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout))
    window.setFrameTop(topSill)
    window.setFrameTopLeft(upperJamb)
    window.setFrameTopRight(upperJamb)
    window.setFrameMeetingRail(meetingRail)
    window.setFrameBottomLeft(lowerJamb)
    window.setFrameBottomRight(lowerJamb)
    window.setFrameBottom(bottomSill)
    window.setDividers(divider, nHorizontal, nVertical)
    const VT0: Float64 = window.vt()
    EXPECT_NEAR(0.0, VT0, 1e-6)
    const SHGC0: Float64 = window.shgc()
    EXPECT_NEAR(0.007859, SHGC0, 1e-6)
    iguUValue = 1.154808
    shgc = 1.0
    tVis = 1.0
    window = Tarcog.ISO15099.DualVisionVertical(
      width,
      height,
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout),
      tVis,
      tSol,
      make_shared[Tarcog.ISO15099.SimpleIGU](iguUValue, shgc, hout))
    window.setFrameTop(topSill)
    window.setFrameTopLeft(upperJamb)
    window.setFrameTopRight(upperJamb)
    window.setFrameMeetingRail(meetingRail)
    window.setFrameBottomLeft(lowerJamb)
    window.setFrameBottomRight(lowerJamb)
    window.setFrameBottom(bottomSill)
    window.setDividers(divider, nHorizontal, nVertical)
    const VT1: Float64 = window.vt()
    EXPECT_NEAR(0.691254, VT1, 1e-6)
    const SHGC1: Float64 = window.shgc()
    EXPECT_NEAR(0.699113, SHGC1, 1e-6)