from memory import shared_ptr, make_shared
from testing import Test, Expect
from WCEViewer import CGeometry2D, CPoint2D, CViewSegment2D
from WCECommon import SquareMatrix

class TestEnclosure2DViewFactors2(Test):
    private:
        var m_Enclosure2D: shared_ptr[CGeometry2D]

    protected:
        def SetUp() raises:
            self.m_Enclosure2D = make_shared[CGeometry2D]()
            var aStartPoint1 = make_shared[CPoint2D](0, 0)
            var aEndPoint1 = make_shared[CPoint2D](0.5, 3)
            var aSegment1 = make_shared[CViewSegment2D](aStartPoint1, aEndPoint1)
            self.m_Enclosure2D.appendSegment(aSegment1)
            var aStartPoint2 = make_shared[CPoint2D](0.5, 3)
            var aEndPoint2 = make_shared[CPoint2D](1.5, 2)
            var aSegment2 = make_shared[CViewSegment2D](aStartPoint2, aEndPoint2)
            self.m_Enclosure2D.appendSegment(aSegment2)
            var aStartPoint3 = make_shared[CPoint2D](1.5, 2)
            var aEndPoint3 = make_shared[CPoint2D](2, 0.5)
            var aSegment3 = make_shared[CViewSegment2D](aStartPoint3, aEndPoint3)
            self.m_Enclosure2D.appendSegment(aSegment3)
            var aStartPoint4 = make_shared[CPoint2D](2, 0.5)
            var aEndPoint4 = make_shared[CPoint2D](0, 0)
            var aSegment4 = make_shared[CViewSegment2D](aStartPoint4, aEndPoint4)
            self.m_Enclosure2D.appendSegment(aSegment4)

    public:
        def getEnclosure() -> shared_ptr[CGeometry2D]:
            return self.m_Enclosure2D

def TestEnclosure2DViewFactors2_Enclosure2DViewFactors():
    var aEnclosure = TestEnclosure2DViewFactors2().getEnclosure()
    var viewFactors = SquareMatrix(aEnclosure.viewFactors())
    Expect.near(0.000000000, viewFactors[0][0], 1e-6)
    Expect.near(0.321497809, viewFactors[0][1], 1e-6)
    Expect.near(0.318886289, viewFactors[0][2], 1e-6)
    Expect.near(0.359615901, viewFactors[0][3], 1e-6)
    Expect.near(0.691407182, viewFactors[1][0], 1e-6)
    Expect.near(0.000000000, viewFactors[1][1], 1e-6)
    Expect.near(0.028240588, viewFactors[1][2], 1e-6)
    Expect.near(0.280352230, viewFactors[1][3], 1e-6)
    Expect.near(0.613390025, viewFactors[2][0], 1e-6)
    Expect.near(0.025259150, viewFactors[2][1], 1e-6)
    Expect.near(0.000000000, viewFactors[2][2], 1e-6)
    Expect.near(0.361350825, viewFactors[2][3], 1e-6)
    Expect.near(0.530536525, viewFactors[3][0], 1e-6)
    Expect.near(0.192320043, viewFactors[3][1], 1e-6)
    Expect.near(0.277143432, viewFactors[3][2], 1e-6)
    Expect.near(0.000000000, viewFactors[3][3], 1e-6)