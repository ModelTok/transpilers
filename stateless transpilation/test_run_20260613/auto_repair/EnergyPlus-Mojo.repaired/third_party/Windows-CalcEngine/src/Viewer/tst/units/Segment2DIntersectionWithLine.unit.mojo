from WCEViewer import CPoint2D, CSegment2D, IntersectionStatus
from collections.rc import Rc
from testing import expect_equal

struct TestSegment2DIntersectionWithLine:
    def SetUp(self):

@test
def Segment2DTest1():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - intersection point (1).")
    var aStartPoint1 = Rc(CPoint2D(0, 0))
    var aEndPoint1 = Rc(CPoint2D(10, 10))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(1, 0))
    var aEndPoint2 = Rc(CPoint2D(10, 10))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment1[].intersectionWithLine(aSegment2[])
    expect_equal(isInt, IntersectionStatus.Point)

@test
def Segment2DTest2():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - intersection point (2).")
    var aStartPoint1 = Rc(CPoint2D(4, 2))
    var aEndPoint1 = Rc(CPoint2D(8, 1))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(1, 3))
    var aEndPoint2 = Rc(CPoint2D(5, 7))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment1[].intersectionWithLine(aSegment2[])
    expect_equal(isInt, IntersectionStatus.No)

@test
def Segment2DTest3():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - parallel lines (no intersection).")
    var aStartPoint1 = Rc(CPoint2D(0, 0))
    var aEndPoint1 = Rc(CPoint2D(0, 1))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(1, 0))
    var aEndPoint2 = Rc(CPoint2D(1, 1))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment1[].intersectionWithLine(aSegment2[])
    expect_equal(isInt, IntersectionStatus.No)

@test
def Segment2DTest4():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - parallel lines (Total overlap).")
    var aStartPoint1 = Rc(CPoint2D(0, 0))
    var aEndPoint1 = Rc(CPoint2D(0, 1))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(0, 0))
    var aEndPoint2 = Rc(CPoint2D(0, 2))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment1[].intersectionWithLine(aSegment2[])
    expect_equal(isInt, IntersectionStatus.No)

@test
def Segment2DTest5():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - parallel lines (Total overlap - different directions).")
    var aStartPoint1 = Rc(CPoint2D(0, 0))
    var aEndPoint1 = Rc(CPoint2D(0, 1))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(0, 2))
    var aEndPoint2 = Rc(CPoint2D(0, 0))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment1[].intersectionWithLine(aSegment2[])
    expect_equal(isInt, IntersectionStatus.No)

@test
def Segment2DTest6():
    TestSegment2DIntersectionWithLine().SetUp()
    print("Begin Test: Segment 2D - normal segments (Not touching but intersects on the segment).")
    var aStartPoint1 = Rc(CPoint2D(0, 10))
    var aEndPoint1 = Rc(CPoint2D(10, 0))
    var aSegment1 = Rc(CSegment2D(aStartPoint1, aEndPoint1))
    var aStartPoint2 = Rc(CPoint2D(0, 0))
    var aEndPoint2 = Rc(CPoint2D(1, 1))
    var aSegment2 = Rc(CSegment2D(aStartPoint2, aEndPoint2))
    var isInt = aSegment2[].intersectionWithLine(aSegment1[])
    expect_equal(isInt, IntersectionStatus.Segment)