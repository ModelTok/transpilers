from memory import Arc, arc
from gtest import *
from WCEViewer import CGeometry2DBeam, CGeometry2D, CPoint2D, CViewSegment2D, BeamViewFactor, Side
from WCECommon import *

struct TestEnclosure2DBeam2:
    private:
        var m_Enclosures2DBeam: Arc[CGeometry2DBeam]

    def SetUp(inout self) raises:
        self.m_Enclosures2DBeam = arc(CGeometry2DBeam())
        var aEnclosure1 = arc(CGeometry2D())
        var aStartPoint1_1 = arc(CPoint2D(8, 12))
        var aEndPoint1_1 = arc(CPoint2D(9, 17))
        var aSegment1_1 = arc(CViewSegment2D(aStartPoint1_1, aEndPoint1_1))
        aEnclosure1.appendSegment(aSegment1_1)
        var aStartPoint1_2 = arc(CPoint2D(9, 17))
        var aEndPoint1_2 = arc(CPoint2D(7, 10))
        var aSegment1_2 = arc(CViewSegment2D(aStartPoint1_2, aEndPoint1_2))
        aEnclosure1.appendSegment(aSegment1_2)
        var aStartPoint1_3 = arc(CPoint2D(7, 10))
        var aEndPoint1_3 = arc(CPoint2D(4, 17))
        var aSegment1_3 = arc(CViewSegment2D(aStartPoint1_3, aEndPoint1_3))
        aEnclosure1.appendSegment(aSegment1_3)
        var aStartPoint1_4 = arc(CPoint2D(4, 17))
        var aEndPoint1_4 = arc(CPoint2D(3, 12))
        var aSegment1_4 = arc(CViewSegment2D(aStartPoint1_4, aEndPoint1_4))
        aEnclosure1.appendSegment(aSegment1_4)
        self.m_Enclosures2DBeam.appendGeometry2D(aEnclosure1)
        var aEnclosure2 = arc(CGeometry2D())
        var aStartPoint2_1 = arc(CPoint2D(9, 13))
        var aEndPoint2_1 = arc(CPoint2D(8, 2))
        var aSegment2_1 = arc(CViewSegment2D(aStartPoint2_1, aEndPoint2_1))
        aEnclosure2.appendSegment(aSegment2_1)
        var aStartPoint2_2 = arc(CPoint2D(8, 2))
        var aEndPoint2_2 = arc(CPoint2D(5, 10))
        var aSegment2_2 = arc(CViewSegment2D(aStartPoint2_2, aEndPoint2_2))
        aEnclosure2.appendSegment(aSegment2_2)
        var aStartPoint2_3 = arc(CPoint2D(5, 10))
        var aEndPoint2_3 = arc(CPoint2D(3, 3))
        var aSegment2_3 = arc(CViewSegment2D(aStartPoint2_3, aEndPoint2_3))
        aEnclosure2.appendSegment(aSegment2_3)
        self.m_Enclosures2DBeam.appendGeometry2D(aEnclosure2)

    def getEnclosure(self) -> Arc[CGeometry2DBeam]:
        return self.m_Enclosures2DBeam

def TEST_F_Enclosure2DBeam2_Enclosure2DBeam1() raises:
    SCOPED_TRACE("Begin Test: 2D Enclosure - Test incoming beam view factors and direct-direct "
                 "component (45 deg).")
    var testObj = TestEnclosure2DBeam2()
    testObj.SetUp()
    var aEnclosure = testObj.getEnclosure()
    var profileAngle = 45.0
    var aSide = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    EXPECT_EQ(aEnclosure.directToDirect(profileAngle, aSide), 0.0)
    var correctSize: Int = 2
    EXPECT_EQ(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 0
    var segmentIndex: Int = 2
    var viewFactor = 4.0 / 9.0
    var percentHit = 0.4
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 1
    segmentIndex = 2
    viewFactor = 5.0 / 9.0
    percentHit = 1.0
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    for i in range(correctResults.size()):
        EXPECT_EQ(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        EXPECT_EQ(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        EXPECT_NEAR(correctResults[i].value, aViewFactors[i].value, 1e-6)
        EXPECT_NEAR(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def TEST_F_Enclosure2DBeam2_Enclosure2DBeam2() raises:
    SCOPED_TRACE("Begin Test: 2D Enclosure - Test incoming beam view factors and direct-direct "
                 "component (0 deg).")
    var testObj = TestEnclosure2DBeam2()
    testObj.SetUp()
    var aEnclosure = testObj.getEnclosure()
    var profileAngle = 0.0
    var aSide = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    EXPECT_EQ(aEnclosure.directToDirect(profileAngle, aSide), 0.0)
    var correctSize: Int = 2
    EXPECT_EQ(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 0
    var segmentIndex: Int = 2
    var viewFactor = 2.0 / 9.0
    var percentHit = 2.0 / 7.0
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    enclosureIndex = 1
    segmentIndex = 2
    viewFactor = 7.0 / 9.0
    percentHit = 1.0
    var aVF2 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF2)
    for i in range(correctResults.size()):
        EXPECT_EQ(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        EXPECT_EQ(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        EXPECT_NEAR(correctResults[i].value, aViewFactors[i].value, 1e-6)
        EXPECT_NEAR(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def TEST_F_Enclosure2DBeam2_Enclosure2DBeam3() raises:
    SCOPED_TRACE(
      "Begin Test: 2D Enclosure - Test beam view factors and direct-direct component (-45 deg).")
    var testObj = TestEnclosure2DBeam2()
    testObj.SetUp()
    var aEnclosure = testObj.getEnclosure()
    var profileAngle = -45.0
    var aSide = Side.Front
    var aViewFactors = aEnclosure.beamViewFactors(profileAngle, aSide)
    var correctSize: Int = 1
    EXPECT_EQ(correctSize, aViewFactors.size())
    var correctResults = List[BeamViewFactor]()
    var enclosureIndex: Int = 1
    var segmentIndex: Int = 2
    var viewFactor = 1.0
    var percentHit = 1.0
    var aVF1 = BeamViewFactor(enclosureIndex, segmentIndex, viewFactor, percentHit)
    correctResults.append(aVF1)
    for i in range(correctResults.size()):
        EXPECT_EQ(correctResults[i].enclosureIndex, aViewFactors[i].enclosureIndex)
        EXPECT_EQ(correctResults[i].segmentIndex, aViewFactors[i].segmentIndex)
        EXPECT_NEAR(correctResults[i].value, aViewFactors[i].value, 1e-6)
        EXPECT_NEAR(correctResults[i].percentHit, aViewFactors[i].percentHit, 1e-6)

def main() raises:
    TEST_F_Enclosure2DBeam2_Enclosure2DBeam1()
    TEST_F_Enclosure2DBeam2_Enclosure2DBeam2()
    TEST_F_Enclosure2DBeam2_Enclosure2DBeam3()