from WCEViewer import CGeometry2D, CViewSegment2D, CPoint2D
from WCECommon import SquareMatrix

def EXPECT_NEAR(actual: Float64, expected: Float64, tolerance: Float64):
    assert abs(actual - expected) < tolerance

struct TestEnclosure2DViewFactorsBlockingSurface1:
    var m_Enclosure2D: CGeometry2D

    def __init__(inout self):
        self.m_Enclosure2D = CGeometry2D()

    def SetUp(inout self):
        var aStartPoint1 = CPoint2D(10, 0)
        var aEndPoint1 = CPoint2D(0, 0)
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        self.m_Enclosure2D.appendSegment(aSegment1)

        var aStartPoint2 = CPoint2D(0, 5)
        var aEndPoint2 = CPoint2D(10, 5)
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        self.m_Enclosure2D.appendSegment(aSegment2)

        var aStartPoint3 = CPoint2D(5, 2)
        var aEndPoint3 = CPoint2D(0, 2)
        var aSegment3 = CViewSegment2D(aStartPoint3, aEndPoint3)
        self.m_Enclosure2D.appendSegment(aSegment3)

    def getEnclosure(self) -> CGeometry2D:
        return self.m_Enclosure2D

def main():
    var testObj = TestEnclosure2DViewFactorsBlockingSurface1()
    testObj.SetUp()
    var aEnclosure = testObj.getEnclosure()
    var viewFactors = aEnclosure.viewFactors()
    print("Begin Test: 2D Enclosure - View Factors (blocking surface).")
    EXPECT_NEAR(0.000000000, viewFactors[0,0], 1e-6)
    EXPECT_NEAR(0.309016994, viewFactors[0,1], 1e-6)
    EXPECT_NEAR(0.000000000, viewFactors[0,2], 1e-6)
    EXPECT_NEAR(0.309016994, viewFactors[1,0], 1e-6)
    EXPECT_NEAR(0.000000000, viewFactors[1,1], 1e-6)
    EXPECT_NEAR(0.372015325, viewFactors[1,2], 1e-6)
    EXPECT_NEAR(0.000000000, viewFactors[2,0], 1e-6)
    EXPECT_NEAR(0.744030651, viewFactors[2,1], 1e-6)
    EXPECT_NEAR(0.000000000, viewFactors[2,2], 1e-6)
    print("Test passed.")