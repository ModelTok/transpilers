"""
Mojo port of BSDFDirectionsClosestIndex.unit

Faithful translation of the gtest file using Mojo's testing module.
The fixture struct TestBSDFDirectionsClosestIndex mirrors the gtest
fixture, and each TEST_F maps to a separate TestSuite that owns a fresh
fixture instance, mirroring gtest's TEST_F semantics of a fresh fixture
per test.
"""

from testing import TestSuite, assert_equal

# EXTERNAL DEPS (to wire in glue):
# - CBSDFHemisphere (from WCESingleLayerOptics): hemisphere with directions
#   - static method create(BSDFBasis) -> CBSDFHemisphere
#   - getDirections(BSDFDirection) -> CBSDFDirections
# - CBSDFDirections (from WCESingleLayerOptics): direction set
#   - getNearestBeamIndex(theta: Float64, phi: Float64) -> Int
# - BSDFDirection (from WCESingleLayerOptics): enum with Incoming
# - BSDFBasis (from WCESingleLayerOptics): enum with Quarter
from WCESingleLayerOptics import (
    CBSDFHemisphere,
    CBSDFDirections,
    BSDFDirection,
    BSDFBasis,
)


struct TestBSDFDirectionsClosestIndex:
    """
    Test fixture for BSDF directions closest index.
    Mirrors the gtest fixture TestBSDFDirectionsClosestIndex.
    """

    var m_BSDFHemisphere: CBSDFHemisphere

    fn __init__(inout self):
        """
        Initialize BSDFHemisphere with Quarter basis.
        Mirrors the C++ in-class member init:
            CBSDFHemisphere m_BSDFHemisphere{
                CBSDFHemisphere::create(BSDFBasis::Quarter)};
        """
        self.m_BSDFHemisphere = CBSDFHemisphere.create(BSDFBasis.Quarter)

    fn GetDirections(borrowed self, t_Side: BSDFDirection) -> CBSDFDirections:
        """
        Return directions for the given side.
        Mirrors the C++ method:
            const CBSDFDirections & GetDirections(const BSDFDirection t_Side) const
        """
        return self.m_BSDFHemisphere.getDirections(t_Side)


struct TestClosestIndex1Suite(TestSuite):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex1)
    with SCOPED_TRACE("Begin Test: Find closest index 1.").
    """
    var fixture: TestBSDFDirectionsClosestIndex

    fn __init__(inout self):
        self.fixture = TestBSDFDirectionsClosestIndex()

    fn test_closest_index_1(self):
        var aDirections = self.fixture.GetDirections(BSDFDirection.Incoming)
        var theta: Float64 = 15.0
        var phi: Float64 = 270.0
        var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
        assert_equal(Int(beamIndex), 7)


struct TestClosestIndex2Suite(TestSuite):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex2)
    with SCOPED_TRACE("Begin Test: Find closest index 2.").
    """
    var fixture: TestBSDFDirectionsClosestIndex

    fn __init__(inout self):
        self.fixture = TestBSDFDirectionsClosestIndex()

    fn test_closest_index_2(self):
        var aDirections = self.fixture.GetDirections(BSDFDirection.Incoming)
        var theta: Float64 = 70.0
        var phi: Float64 = 175.0
        var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
        assert_equal(Int(beamIndex), 37)


struct TestClosestIndex3Suite(TestSuite):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex3)
    with SCOPED_TRACE("Begin Test: Find closest index 3.").
    """
    var fixture: TestBSDFDirectionsClosestIndex

    fn __init__(inout self):
        self.fixture = TestBSDFDirectionsClosestIndex()

    fn test_closest_index_3(self):
        var aDirections = self.fixture.GetDirections(BSDFDirection.Incoming)
        var theta: Float64 = 55.0
        var phi: Float64 = 60.0
        var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
        assert_equal(Int(beamIndex), 23)


struct TestClosestIndex4Suite(TestSuite):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex4)
    with SCOPED_TRACE("Begin Test: Find closest index 4.").
    """
    var fixture: TestBSDFDirectionsClosestIndex

    fn __init__(inout self):
        self.fixture = TestBSDFDirectionsClosestIndex()

    fn test_closest_index_4(self):
        var aDirections = self.fixture.GetDirections(BSDFDirection.Incoming)
        var theta: Float64 = 0.0
        var phi: Float64 = 0.0
        var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
        assert_equal(Int(beamIndex), 0)


struct TestClosestIndex5Suite(TestSuite):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex5)
    with SCOPED_TRACE("Begin Test: Find closest index 5.").
    """
    var fixture: TestBSDFDirectionsClosestIndex

    fn __init__(inout self):
        self.fixture = TestBSDFDirectionsClosestIndex()

    fn test_closest_index_5(self):
        var aDirections = self.fixture.GetDirections(BSDFDirection.Incoming)
        var theta: Float64 = 71.2163
        var phi: Float64 = 349.744251
        var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
        assert_equal(Int(beamIndex), 33)


def main():
    """Run all test suites (mirrors gtest's main() generated by gtest_main)."""
    TestClosestIndex1Suite().run()
    TestClosestIndex2Suite().run()
    TestClosestIndex3Suite().run()
    TestClosestIndex4Suite().run()
    TestClosestIndex5Suite().run()
