from testing import assert_eq
from WCEViewer import CPoint2D, CViewSegment2D, Shadowing

class TestSegment2DSelfShadowing(testing.Test):
    def SetUp(self):

    def Segment2DNoShadowing(self):
        # SCOPED_TRACE("Begin Test: Segments self shadowing - No shadowing case.")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(0, 1))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(10, 1))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.No, aShadowing)

    def Segment2DTotalShadowing(self):
        # SCOPED_TRACE("Begin Test: Segments self shadowing - Total shadowing case.")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(10, 1))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(0, 1))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.Total, aShadowing)

    def Segment2DNoShadowingSamePoint1(self):
        # SCOPED_TRACE(
        #   "Begin Test: Segments self shadowing - No shadowing case (share same point angle < 180).")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(0, 1))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.No, aShadowing)

    def Segment2DNoShadowingSamePoint2(self):
        # SCOPED_TRACE(
        #   "Begin Test: Segments self shadowing - No shadowing case (share same point, angle > 180).")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(0, -2))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.Total, aShadowing)

    def Segment2DPartialShadowingThis(self):
        # SCOPED_TRACE(
        #   "Begin Test: Segments self shadowing - Partial shadowing case (view blocked by itself).")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(-5, -1))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(-5, 1))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.Partial, aShadowing)

    def Segment2DPartialShadowingOther(self):
        # SCOPED_TRACE("Begin Test: Segments self shadowing - Partial shadowing case (view blocked by "
        #              "viewed surface).")
        var aStartPoint1 = Pointer[CPoint2D](new CPoint2D(10, 0))
        var aEndPoint1 = Pointer[CPoint2D](new CPoint2D(0, 0))
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        var aStartPoint2 = Pointer[CPoint2D](new CPoint2D(5, 5))
        var aEndPoint2 = Pointer[CPoint2D](new CPoint2D(5, 10))
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        var aShadowing = aSegment1.selfShadowing(aSegment2)
        assert_eq(Shadowing.Partial, aShadowing)