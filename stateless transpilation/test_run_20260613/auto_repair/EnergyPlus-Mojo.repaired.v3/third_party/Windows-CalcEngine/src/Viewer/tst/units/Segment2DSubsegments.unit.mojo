from memory import SharedPointer as shared_ptr
from memory import make_shared
from memory import make_shared as std_make_shared  # not used
from memory import SharedPointer
import testing  # hypothetical Mojo testing module providing TEST_F, EXPECT_NEAR, SCOPED_TRACE
from WCEViewer import CPoint2D, CViewSegment2D

class TestSegment2DSubsegments(testing.Test):
    def SetUp(self):

testing.TEST_F(TestSegment2DSubsegments, Segment2DTest1):
    testing.SCOPED_TRACE("Begin Test: Segment 2D - subsegments creation.")
    let aStartPoint = shared_ptr[CPoint2D](CPoint2D(0, 0))
    let aEndPoint = shared_ptr[CPoint2D](CPoint2D(10, 10))
    let aSegment = CViewSegment2D(aStartPoint, aEndPoint)
    let aSubSegments = aSegment.subSegments(4)
    let correctStartX = [0.0, 2.5, 5.0, 7.5]
    let correctEndX = [2.5, 5.0, 7.5, 10.0]
    let correctStartY = [0.0, 2.5, 5.0, 7.5]
    let correctEndY = [2.5, 5.0, 7.5, 10.0]
    var i: Int = 0
    for aSubSegment in aSubSegments:
        let xStart = aSubSegment.startPoint().x()
        let xEnd = aSubSegment.endPoint().x()
        let yStart = aSubSegment.startPoint().y()
        let yEnd = aSubSegment.endPoint().y()
        testing.EXPECT_NEAR(correctStartX[i], xStart, 1e-6)
        testing.EXPECT_NEAR(correctEndX[i], xEnd, 1e-6)
        testing.EXPECT_NEAR(correctStartY[i], yStart, 1e-6)
        testing.EXPECT_NEAR(correctEndY[i], yEnd, 1e-6)
        i += 1