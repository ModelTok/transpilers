from memory import Arc
from testing import assert_approx_equal
from WCEViewer import CGeometry2D, CViewSegment2D
from WCECommon import CPoint2D, SquareMatrix

struct TestEnclosure2DViewFactors1:
    var m_Enclosure2D: Arc[CGeometry2D]

    def SetUp(inout self):
        self.m_Enclosure2D = Arc[CGeometry2D]()
        var aStartPoint1 = Arc[CPoint2D](0, 0)
        var aEndPoint1 = Arc[CPoint2D](0, 1)
        var aSegment1 = Arc[CViewSegment2D](aStartPoint1, aEndPoint1)
        self.m_Enclosure2D.appendSegment(aSegment1)
        var aStartPoint2 = Arc[CPoint2D](0, 1)
        var aEndPoint2 = Arc[CPoint2D](1, 1)
        var aSegment2 = Arc[CViewSegment2D](aStartPoint2, aEndPoint2)
        self.m_Enclosure2D.appendSegment(aSegment2)
        var aStartPoint3 = Arc[CPoint2D](1, 1)
        var aEndPoint3 = Arc[CPoint2D](1, 0)
        var aSegment3 = Arc[CViewSegment2D](aStartPoint3, aEndPoint3)
        self.m_Enclosure2D.appendSegment(aSegment3)
        var aStartPoint4 = Arc[CPoint2D](1, 0)
        var aEndPoint4 = Arc[CPoint2D](0, 0)
        var aSegment4 = Arc[CViewSegment2D](aStartPoint4, aEndPoint4)
        self.m_Enclosure2D.appendSegment(aSegment4)

    def getEnclosure(self) -> Arc[CGeometry2D]:
        return self.m_Enclosure2D

def Enclosure2DViewFactors():
    # SCOPED_TRACE("Begin Test: 2D Enclosure - View Factors (no blocking).")
    var aEnclosure = TestEnclosure2DViewFactors1()
    aEnclosure.SetUp()
    var enclosure = aEnclosure.getEnclosure()
    var viewFactors = enclosure.viewFactors()
    assert_approx_equal(0.000000000, viewFactors[0][0], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[0][1], 1e-6)
    assert_approx_equal(0.414213562, viewFactors[0][2], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[0][3], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[1][0], 1e-6)
    assert_approx_equal(0.000000000, viewFactors[1][1], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[1][2], 1e-6)
    assert_approx_equal(0.414213562, viewFactors[1][3], 1e-6)
    assert_approx_equal(0.414213562, viewFactors[2][0], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[2][1], 1e-6)
    assert_approx_equal(0.000000000, viewFactors[2][2], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[2][3], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[3][0], 1e-6)
    assert_approx_equal(0.414213562, viewFactors[3][1], 1e-6)
    assert_approx_equal(0.292893219, viewFactors[3][2], 1e-6)
    assert_approx_equal(0.000000000, viewFactors[3][3], 1e-6)