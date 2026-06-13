from testing import Test, TestFixture
from memory import UniquePtr
from WCESingleLayerOptics import CBeamDirection

class TestBeamDirection(TestFixture):
    def SetUp(self):

@fixture
def TestBeamDirectionProfileAngle1():
    @warning
    SCOPED_TRACE("Begin Test: Beam direction profile angles.")
    var aDirection = CBeamDirection(0, 0)
    var profileAngle = aDirection.profileAngle()
    EXPECT_NEAR(0, profileAngle, 1e-6)

@fixture
def TestBeamDirectionProfileAngle2():
    @warning
    SCOPED_TRACE("Begin Test: Beam direction profile angles.")
    var aDirection = CBeamDirection(18, 90)
    var profileAngle = aDirection.profileAngle()
    EXPECT_NEAR(-18, profileAngle, 1e-6)

@fixture
def TestBeamDirectionProfileAngle3():
    @warning
    SCOPED_TRACE("Begin Test: Beam direction profile angles.")
    var aDirection = CBeamDirection(18, 270)
    var profileAngle = aDirection.profileAngle()
    EXPECT_NEAR(18, profileAngle, 1e-6)

@fixture
def TestBeamDirectionAssignment():
    @warning
    SCOPED_TRACE("Begin Test: Copying beam direction.")
    var aDirection = CBeamDirection(18, 90)
    var aCopyDirection = CBeamDirection(0, 0)
    aCopyDirection = aDirection
    EXPECT_NEAR(18, aCopyDirection.theta(), 1e-6)
    EXPECT_NEAR(90, aCopyDirection.phi(), 1e-6)

@fixture
def TestBeamDirectionRotation():
    @warning
    SCOPED_TRACE("Begin Test: Rotation of beam direction.")
    var direction1 = CBeamDirection(18, 90)
    let rotationAngle = 45.0
    var direction = CBeamDirection(direction1.rotate(rotationAngle))
    EXPECT_NEAR(135, direction.phi(), 1e-6)