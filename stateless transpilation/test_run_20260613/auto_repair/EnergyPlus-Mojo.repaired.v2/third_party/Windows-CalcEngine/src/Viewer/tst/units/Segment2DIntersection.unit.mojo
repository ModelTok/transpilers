from WCEViewer import CPoint2D, CSegment2D

struct TestSegment2DIntersection:
    def SetUp(self):

@test
def Segment2DTest1():
    # SCOPED_TRACE("Begin Test: Segment 2D - intersection point (1).")
    var aStartPoint1 = CPoint2D(0, 0)
    var aEndPoint1 = CPoint2D(10, 10)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(1, 0)
    var aEndPoint2 = CPoint2D(10, 10)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt

@test
def Segment2DTest2():
    # SCOPED_TRACE("Begin Test: Segment 2D - intersection point (2).")
    var aStartPoint1 = CPoint2D(4, 2)
    var aEndPoint1 = CPoint2D(8, 1)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(1, 3)
    var aEndPoint2 = CPoint2D(5, 7)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt

@test
def Segment2DTest3():
    # SCOPED_TRACE("Begin Test: Segment 2D - parallel lines (no intersection).")
    var aStartPoint1 = CPoint2D(0, 0)
    var aEndPoint1 = CPoint2D(0, 1)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(1, 0)
    var aEndPoint2 = CPoint2D(1, 1)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt

@test
def Segment2DTest4():
    # SCOPED_TRACE("Begin Test: Segment 2D - parallel lines (Total overlap).")
    var aStartPoint1 = CPoint2D(0, 0)
    var aEndPoint1 = CPoint2D(0, 1)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(0, 0)
    var aEndPoint2 = CPoint2D(0, 2)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt

@test
def Segment2DTest5():
    # SCOPED_TRACE("Begin Test: Segment 2D - parallel lines (Total overlap - different directions).")
    var aStartPoint1 = CPoint2D(0, 0)
    var aEndPoint1 = CPoint2D(0, 1)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(0, 2)
    var aEndPoint2 = CPoint2D(0, 0)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt

@test
def Segment2DTest6():
    # SCOPED_TRACE("Begin Test: Segment 2D - parallel lines (Total overlap - same directions, different lengths).")
    var aStartPoint1 = CPoint2D(0, 10)
    var aEndPoint1 = CPoint2D(10, 0)
    var aSegment1 = CSegment2D(aStartPoint1, aEndPoint1)
    var aStartPoint2 = CPoint2D(0, 10)
    var aEndPoint2 = CPoint2D(5, 5)
    var aSegment2 = CSegment2D(aStartPoint2, aEndPoint2)
    var isInt = aSegment1.intersectionWithSegment(aSegment2)
    assert not isInt