from memory import shared_ptr, make_shared
from WCEViewer import CGeometry2D, CPoint2D, CViewSegment2D
from WCECommon import SquareMatrix
from testing import *

class TestEnclosure2DViewFactorsBlockingSurface3:
    var m_Enclosure2D: shared_ptr[CGeometry2D]

    def __init__(inout self):
        self.m_Enclosure2D = shared_ptr[CGeometry2D]()

    def SetUp(inout self):
        self.m_Enclosure2D = make_shared[CGeometry2D]()
        var aStartPoint1 = make_shared[CPoint2D](10, 0)
        var aEndPoint1 = make_shared[CPoint2D](0, 0)
        var aSegment1 = make_shared[CViewSegment2D](aStartPoint1, aEndPoint1)
        self.m_Enclosure2D.appendSegment(aSegment1)
        var aStartPoint2 = make_shared[CPoint2D](0, 5)
        var aEndPoint2 = make_shared[CPoint2D](10, 5)
        var aSegment2 = make_shared[CViewSegment2D](aStartPoint2, aEndPoint2)
        self.m_Enclosure2D.appendSegment(aSegment2)
        var aStartPoint3 = make_shared[CPoint2D](8, 2)
        var aEndPoint3 = make_shared[CPoint2D](2, 2)
        var aSegment3 = make_shared[CViewSegment2D](aStartPoint3, aEndPoint3)
        self.m_Enclosure2D.appendSegment(aSegment3)

    def getEnclosure(self) -> shared_ptr[CGeometry2D]:
        return self.m_Enclosure2D

def test_Enclosure2DViewFactorsBlockingSurface3_Enclosure2DViewFactors():
    var aEnclosure = TestEnclosure2DViewFactorsBlockingSurface3()
    aEnclosure.SetUp()
    var enclosure = aEnclosure.getEnclosure()
    var viewFactors = SquareMatrix(enclosure.viewFactors())
    expect_almost_equal(0.000000000, viewFactors[0][0], 1e-6)
    expect_almost_equal(0.140312424, viewFactors[0][1], 1e-6)
    expect_almost_equal(0.000000000, viewFactors[0][2], 1e-6)
    expect_almost_equal(0.140312424, viewFactors[1][0], 1e-6)
    expect_almost_equal(0.000000000, viewFactors[1][1], 1e-6)
    expect_almost_equal(0.493845247, viewFactors[1][2], 1e-6)
    expect_almost_equal(0.000000000, viewFactors[2][0], 1e-6)
    expect_almost_equal(0.823075412, viewFactors[2][1], 1e-6)
    expect_almost_equal(0.000000000, viewFactors[2][2], 1e-6)