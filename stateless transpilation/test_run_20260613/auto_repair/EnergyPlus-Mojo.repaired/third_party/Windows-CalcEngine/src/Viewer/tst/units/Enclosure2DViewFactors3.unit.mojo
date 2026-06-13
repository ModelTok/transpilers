from memory import shared_ptr, make_shared
from WCEViewer import CGeometry2D, CPoint2D, CViewSegment2D
from WCECommon import SquareMatrix
from testing import Test, expect_near

@register_test("TestEnclosure2DViewFactors3")
struct TestEnclosure2DViewFactors3(Test):
    var m_Enclosure2D: shared_ptr[CGeometry2D]

    def __init__(inout self):
        self.m_Enclosure2D = shared_ptr[CGeometry2D]()

    def SetUp(inout self):
        self.m_Enclosure2D = make_shared[CGeometry2D]()
        var aStartPoint1 = make_shared[CPoint2D](0, 0)
        var aEndPoint1 = make_shared[CPoint2D](0, 10)
        var aSegment1 = make_shared[CViewSegment2D](aStartPoint1, aEndPoint1)
        self.m_Enclosure2D.appendSegment(aSegment1)
        var aStartPoint2 = make_shared[CPoint2D](0, 10)
        var aEndPoint2 = make_shared[CPoint2D](10, 10)
        var aSegment2 = make_shared[CViewSegment2D](aStartPoint2, aEndPoint2)
        self.m_Enclosure2D.appendSegment(aSegment2)
        var aStartPoint3 = make_shared[CPoint2D](10, 10)
        var aEndPoint3 = make_shared[CPoint2D](20, 10)
        var aSegment3 = make_shared[CViewSegment2D](aStartPoint3, aEndPoint3)
        self.m_Enclosure2D.appendSegment(aSegment3)
        var aStartPoint4 = make_shared[CPoint2D](20, 10)
        var aEndPoint4 = make_shared[CPoint2D](0, 0)
        var aSegment4 = make_shared[CViewSegment2D](aStartPoint4, aEndPoint4)
        self.m_Enclosure2D.appendSegment(aSegment4)

    def getEnclosure(self) -> shared_ptr[CGeometry2D]:
        return self.m_Enclosure2D

def test_Enclosure2DViewFactors():
    SCOPED_TRACE("Begin Test: 2D Enclosure - View Factors (no blocking, two surfaces collinear).")
    var aEnclosure = TestEnclosure2DViewFactors3().getEnclosure()
    var viewFactors = SquareMatrix(aEnclosure.viewFactors())
    expect_near(0.000000000, viewFactors[0, 0], 1e-6)
    expect_near(0.292893219, viewFactors[0, 1], 1e-6)
    expect_near(0.089072792, viewFactors[0, 2], 1e-6)
    expect_near(0.618033989, viewFactors[0, 3], 1e-6)
    expect_near(0.292893219, viewFactors[1, 0], 1e-6)
    expect_near(0.000000000, viewFactors[1, 1], 1e-6)
    expect_near(0.000000000, viewFactors[1, 2], 1e-6)
    expect_near(0.707106781, viewFactors[1, 3], 1e-6)
    expect_near(0.089072792, viewFactors[2, 0], 1e-6)
    expect_near(0.000000000, viewFactors[2, 1], 1e-6)
    expect_near(0.000000000, viewFactors[2, 2], 1e-6)
    expect_near(0.910927208, viewFactors[2, 3], 1e-6)
    expect_near(0.276393202, viewFactors[3, 0], 1e-6)
    expect_near(0.316227766, viewFactors[3, 1], 1e-6)
    expect_near(0.407379032, viewFactors[3, 2], 1e-6)
    expect_near(0.000000000, viewFactors[3, 3], 1e-6)