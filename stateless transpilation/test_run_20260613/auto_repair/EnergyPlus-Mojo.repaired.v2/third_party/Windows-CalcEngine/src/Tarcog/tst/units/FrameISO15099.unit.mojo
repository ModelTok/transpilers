from testing import assert_almost_equal
from WCETarcog import (
    Tarcog,
    ISO15099,
    FrameData,
    Frame,
    FrameType,
    FrameSide,
)

struct TestFrameISO15099:
    def SetUp(self):

@test
def ExteriorFrameLeftSideFrameExterior():
    SCOPED_TRACE("Begin Test: Left side frame exterior.")
    let uValue = 1.0
    let edgeUValue = 1.0
    let projectedFrameDimension = 0.2
    let wettedLength = 0.3
    let absorptance = 0.3
    let frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance,
    )
    let frameLength = 1.0
    var frame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Exterior, frameData,
    )
    let leftFrame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Exterior, frameData,
    )
    frame.assignFrame(leftFrame, Tarcog.ISO15099.FrameSide.Left)
    let projectedArea = frame.projectedArea()
    assert_almost_equal(0.18, projectedArea, 1e-6)
    let eogArea = frame.edgeOfGlassArea()
    assert_almost_equal(0.048783875, eogArea, 1e-6)
    let wettedArea = frame.wettedArea()
    assert_almost_equal(0.27, wettedArea, 1e-6)

@test
def ExteriorFrameLeftSideFrameInterior():
    SCOPED_TRACE("Begin Test: Left side frame assigned.")
    let uValue = 1.0
    let edgeUValue = 1.0
    let projectedFrameDimension = 0.2
    let wettedLength = 0.3
    let absorptance = 0.3
    let frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance,
    )
    let frameLength = 1.0
    var frame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Exterior, frameData,
    )
    let leftFrame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Interior, frameData,
    )
    frame.assignFrame(leftFrame, Tarcog.ISO15099.FrameSide.Left)
    let projectedArea = frame.projectedArea()
    assert_almost_equal(0.2, projectedArea, 1e-6)
    let eogArea = frame.edgeOfGlassArea()
    assert_almost_equal(0.0508, eogArea, 1e-6)
    let wettedArea = frame.wettedArea()
    assert_almost_equal(0.3, wettedArea, 1e-6)

@test
def InteriorFrameLeftandRightSideFramesExterior():
    SCOPED_TRACE(
        "Begin Test: Frame is interior and left and right frames are exterior.",
    )
    let uValue = 1.0
    let edgeUValue = 1.0
    let projectedFrameDimension = 0.2
    let wettedLength = 0.3
    let absorptance = 0.3
    let frameData = Tarcog.ISO15099.FrameData(
        uValue, edgeUValue, projectedFrameDimension, wettedLength, absorptance,
    )
    let frameLength = 1.0
    var frame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Interior, frameData,
    )
    let leftFrame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Exterior, frameData,
    )
    let rightFrame = Tarcog.ISO15099.Frame(
        frameLength, Tarcog.ISO15099.FrameType.Exterior, frameData,
    )
    frame.assignFrame(leftFrame, Tarcog.ISO15099.FrameSide.Left)
    frame.assignFrame(rightFrame, Tarcog.ISO15099.FrameSide.Right)
    let projectedArea = frame.projectedArea()
    assert_almost_equal(0.12, projectedArea, 1e-6)
    let eogArea = frame.edgeOfGlassArea()
    assert_almost_equal(0.0300355, eogArea, 1e-6)
    let wettedArea = frame.wettedArea()
    assert_almost_equal(0.18, wettedArea, 1e-6)
    let frameSHGC = frameData.shgc(15)
    assert_almost_equal(0.013333, frameSHGC, 1e-6)