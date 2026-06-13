from memory import shared_ptr, make_shared
from WCEViewer import CPoint2D, CSegment2D

def SCOPED_TRACE(message: StringLiteral):
    print(message)

def EXPECT_NEAR(expected: Float64, actual: Float64, tolerance: Float64):
    if (expected - actual).abs() > tolerance:
        print("FAIL: expected", expected, "actual", actual, "tolerance", tolerance)
        raise Error("Test failed")

struct TestSegment2D:
    def SetUp(inout self):

    def Segment2DTest1(inout self):
        SCOPED_TRACE("Begin Test: Segment 2D - length and normal (1).")
        var aStartPoint = shared_ptr[CPoint2D](make_shared[CPoint2D](0, 0))
        var aEndPoint = shared_ptr[CPoint2D](make_shared[CPoint2D](10, 0))
        var aSegment = CSegment2D(aStartPoint, aEndPoint)
        var length = aSegment.length()
        EXPECT_NEAR(10, length, 1e-6)

    def Segment2DTest2(inout self):
        SCOPED_TRACE("Begin Test: Segment 2D - length and normal (2).")
        var aStartPoint = shared_ptr[CPoint2D](make_shared[CPoint2D](0, 0))
        var aEndPoint = shared_ptr[CPoint2D](make_shared[CPoint2D](10, 10))
        var aSegment = CSegment2D(aStartPoint, aEndPoint)
        var length = aSegment.length()
        EXPECT_NEAR(14.14213562, length, 1e-6)