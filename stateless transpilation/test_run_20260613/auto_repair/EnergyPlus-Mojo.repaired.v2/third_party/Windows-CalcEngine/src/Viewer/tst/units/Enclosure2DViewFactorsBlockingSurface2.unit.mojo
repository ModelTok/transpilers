from memory import shared_ptr, make_shared
from WCEViewer import CGeometry2D, CPoint2D, CViewSegment2D
from WCECommon import SquareMatrix
from testing import Test, Expect

@register_test()
class TestEnclosure2DViewFactorsBlockingSurface2(Test):
    private:
        var m_Enclosure2D: shared_ptr[CGeometry2D]

    protected:
        def SetUp() raises:
            self.m_Enclosure2D = make_shared[CGeometry2D]()
            var aStartPoint1 = make_shared[CPoint2D](0, 0)
            var aEndPoint1 = make_shared[CPoint2D](0, 10)
            var aSegment1 = make_shared[CViewSegment2D](aStartPoint1, aEndPoint1)
            self.m_Enclosure2D.appendSegment(aSegment1)
            var aStartPoint2 = make_shared[CPoint2D](10, 10)
            var aEndPoint2 = make_shared[CPoint2D](10, 0)
            var aSegment2 = make_shared[CViewSegment2D](aStartPoint2, aEndPoint2)
            self.m_Enclosure2D.appendSegment(aSegment2)
            var aStartPoint3 = make_shared[CPoint2D](10, 0)
            var aEndPoint3 = make_shared[CPoint2D](9, 1)
            var aSegment3 = make_shared[CViewSegment2D](aStartPoint3, aEndPoint3)
            self.m_Enclosure2D.appendSegment(aSegment3)

    public:
        def getEnclosure() -> shared_ptr[CGeometry2D]:
            return self.m_Enclosure2D

@register_test()
def TestEnclosure2DViewFactorsBlockingSurface2_Enclosure2DViewFactors() raises:
    print("Begin Test: 2D Enclosure - View Factors (blocking surface sharp angle).")
    var aEnclosure = TestEnclosure2DViewFactorsBlockingSurface2().getEnclosure()
    var viewFactors = SquareMatrix(aEnclosure.viewFactors())
    Expect.near(0.000000000, viewFactors[0][0], 1e-6)
    Expect.near(0.391219268, viewFactors[0][1], 1e-6)
    Expect.near(0.000000000, viewFactors[0][2], 1e-6)
    Expect.near(0.391219268, viewFactors[1][0], 1e-6)
    Expect.near(0.000000000, viewFactors[1][1], 1e-6)
    Expect.near(0.117941421, viewFactors[1][2], 1e-6)
    Expect.near(0.000000000, viewFactors[2][0], 1e-6)
    Expect.near(0.833971787, viewFactors[2][1], 1e-6)
    Expect.near(0.000000000, viewFactors[2][2], 1e-6)