from WCECommon import CGeometry2DBeam, CGeometry2D, CPoint2D, CViewSegment2D, Side, BeamViewFactor
from WCEViewer import CGeometry2DBeam as ViewerCGeometry2DBeam  # already imported, but keep for clarity

# Simple testing utilities to replace gtest macros
def expect_eq[T: Equatable](lhs: T, rhs: T, msg: String = ""):
    if lhs != rhs:
        print("FAIL: expect_eq: ", msg)
        abort()

def expect_near(lhs: Float64, rhs: Float64, tol: Float64, msg: String = ""):
    if abs(lhs - rhs) > tol:
        print("FAIL: expect_near: ", msg, " | diff = ", abs(lhs - rhs))
        abort()

class TestEnclosure2DBeam1:
    private var m_Enclosures2DBeam: CGeometry2DBeam

    def SetUp(self):
        self.m_Enclosures2DBeam = CGeometry2DBeam()
        var aEnclosure1 = CGeometry2D()
        var aStartPoint1 = CPoint2D(3, 2)
        var aEndPoint1 = CPoint2D(5, 5)
        var aSegment1 = CViewSegment2D(aStartPoint1, aEndPoint1)
        aEnclosure1.appendSegment(aSegment1)
        var aStartPoint2 = CPoint2D(5, 5)
        var aEndPoint2 = CPoint2D(8, 4)
        var aSegment2 = CViewSegment2D(aStartPoint2, aEndPoint2)
        aEnclosure1.appendSegment(aSegment2)
        var aStartPoint3 = CPoint2D(8, 4)
        var aEndPoint3 = CPoint2D(9, 9)
        var aSegment3 = CViewSegment2D(aStartPoint3, aEndPoint3)
        aEnclosure1.appendSegment(aSegment3)
        self.m_Enclosures2DBeam.appendGeometry2D(aEnclosure1)
        var aEnclosure2 = CGeometry2D()
        var aStartPoint4 = CPoint2D(3, 10)
        var aEndPoint4 = CPoint2D(7, 11)
        var aSegment4 = CViewSegment2D(aStartPoint4, aEndPoint4)
        aEnclosure2.appendSegment(aSegment4)
        var aStartPoint5 = CPoint2D(7, 11)
        var aEndPoint5 = CPoint2D(6, 14)
        var aSegment5 = CViewSegment2D(aStartPoint5, aEndPoint5)
        aEnclosure2.appendSegment(aSegment5)
        var aStartPoint6 = CPoint2D(6, 14)
        var aEndPoint6 = CPoint2D(12, 16)
        var aSegment6 = CViewSegment2D(aStartPoint6, aEndPoint6)
        aEnclosure2.appendSegment(aSegment6)
        self.m_Enclosures2DBeam.appendGeometry2D(aEnclosure2)

    def getEnclosure(self) -> CGeometry2DBeam:
        return self.m_Enclosures2DBeam
;

def Enclosure2DBeam1():
    print("Begin Test: 2D Enclosure - Test incoming beam view factors and "
          "direct-direct component (45 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = 45
    var aSide: Side = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_near(0.5, aEnclosure.directToDirect(profileAngle, aSide), 1e-6)
    var correctSize: Int = 2
    expect_eq(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 1
    var segmentIndex: Int = 0
    var viewFactor: Float64 = 0.375
    var percentHit: Float64 = 1
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 0
    segmentIndex = 0
    viewFactor = 0.125
    percentHit = 1
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    for i in range(correctResults.size()):
        expect_eq(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        expect_eq(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        expect_near(correctResults[i].value, aViewFactors[i].value, 1e-6)
        expect_near(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def Enclosure2DBeam2():
    print("Begin Test: 2D Enclosure - Test incoming beam view factors and "
          "direct-direct component (0 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = 0
    var aSide: Side = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_eq(0.125, aEnclosure.directToDirect(profileAngle, aSide))
    var correctSize: Int = 2
    expect_eq(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 0
    var segmentIndex: Int = 2
    var viewFactor: Float64 = 0.5
    var percentHit: Float64 = 0.8
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 0
    segmentIndex = 0
    viewFactor = 0.375
    percentHit = 1
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    for i in range(correctResults.size()):
        expect_eq(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        expect_eq(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        expect_near(correctResults[i].value, aViewFactors[i].value, 1e-6)
        expect_near(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def Enclosure2DBeam3():
    print("Begin Test: 2D Enclosure - Test incoming beam view factors and "
          "direct-direct component (-45 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = -45
    var aSide: Side = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_eq(0.0, aEnclosure.directToDirect(profileAngle, aSide))
    var correctSize: Int = 3
    expect_eq(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 0
    var segmentIndex: Int = 2
    var viewFactor: Float64 = 0.125
    var percentHit: Float64 = 0.16666666666666666
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 0
    segmentIndex = 1
    viewFactor = 0.25
    percentHit = 1
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    enclosureIndex = 0
    segmentIndex = 0
    viewFactor = 0.625
    percentHit = 1
    var aVF3 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF3)
    for i in range(correctResults.size()):
        expect_eq(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        expect_eq(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        expect_near(correctResults[i].value, aViewFactors[i].value, 1e-6)
        expect_near(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def Enclosure2DBeam4():
    print("Begin Test: 2D Enclosure - Test outgoing beam view factors and "
          "direct-direct component (45 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = 45
    var aSide: Side = Side.Back
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_eq(1, aEnclosure.directToDirect(profileAngle, aSide))
    var correctSize: Int = 0
    expect_eq(correctSize, aViewFactors.size())

def Enclosure2DBeam5():
    print("Begin Test: 2D Enclosure - Test outgoing beam view factors and "
          "direct-direct component (0 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = 0
    var aSide: Side = Side.Back
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_near(1.0 / 7.0, aEnclosure.directToDirect(profileAngle, aSide), 1e-6)
    var correctSize: Int = 3
    expect_eq(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 1
    var segmentIndex: Int = 2
    var viewFactor: Float64 = 2.0 / 7.0
    var percentHit: Float64 = 1
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 1
    segmentIndex = 1
    viewFactor = 3.0 / 7.0
    percentHit = 1
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    enclosureIndex = 1
    segmentIndex = 0
    viewFactor = 1.0 / 7.0
    percentHit = 1
    var aVF3 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF3)
    for i in range(correctResults.size()):
        expect_eq(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        expect_eq(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        expect_near(correctResults[i].value, aViewFactors[i].value, 1e-6)
        expect_near(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def Enclosure2DBeam6():
    print("Begin Test: 2D Enclosure - Test outgoing beam view factors and "
          "direct-direct component (-45 deg).")
    var test = TestEnclosure2DBeam1()
    test.SetUp()
    var aEnclosure = test.getEnclosure()
    var profileAngle: Float64 = -45
    var aSide: Side = Side.Back
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    expect_eq(0.0, aEnclosure.directToDirect(profileAngle, aSide))
    var correctSize: Int = 2
    expect_eq(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 1
    var segmentIndex: Int = 2
    var viewFactor: Float64 = 0.8
    var percentHit: Float64 = 1
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 1
    segmentIndex = 1
    viewFactor = 0.2
    percentHit = 1
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    for i in range(correctResults.size()):
        expect_eq(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        expect_eq(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        expect_near(correctResults[i].value, aViewFactors[i].value, 1e-6)
        expect_near(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)
<<<FILE>>>