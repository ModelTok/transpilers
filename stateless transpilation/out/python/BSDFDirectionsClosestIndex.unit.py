"""
Python port of BSDFDirectionsClosestIndex.unit

Faithful translation of the gtest file using Python's unittest framework.
The fixture TestBSDFDirectionsClosestIndex mirrors the gtest fixture, and
each TEST_F maps to a TestCase class that inherits from the fixture,
mirroring gtest's TEST_F semantics of a fresh fixture per test via setUp.
"""

import unittest

# EXTERNAL DEPS (to wire in glue):
# - CBSDFHemisphere (from WCESingleLayerOptics): hemisphere with directions
#   - static method create(BSDFBasis) -> CBSDFHemisphere
#   - getDirections(BSDFDirection) -> CBSDFDirections
# - CBSDFDirections (from WCESingleLayerOptics): direction set
#   - getNearestBeamIndex(theta: float, phi: float) -> int
# - BSDFDirection (from WCESingleLayerOptics): enum with Incoming
# - BSDFBasis (from WCESingleLayerOptics): enum with Quarter
from WCESingleLayerOptics import (
    CBSDFHemisphere,
    CBSDFDirections,
    BSDFDirection,
    BSDFBasis,
)


class TestBSDFDirectionsClosestIndex(unittest.TestCase):
    """
    Test fixture for BSDF directions closest index.
    Mirrors the gtest fixture TestBSDFDirectionsClosestIndex.
    """

    def setUp(self):
        """
        Initialize BSDFHemisphere with Quarter basis (one per test method).
        Mirrors the C++ in-class member init:
            CBSDFHemisphere m_BSDFHemisphere{
                CBSDFHemisphere::create(BSDFBasis::Quarter)};
        """
        self.m_BSDFHemisphere = CBSDFHemisphere.create(BSDFBasis.Quarter)

    def GetDirections(self, t_Side):
        """
        Return directions for the given side.
        Mirrors the C++ method:
            const CBSDFDirections & GetDirections(const BSDFDirection t_Side) const
        """
        return self.m_BSDFHemisphere.getDirections(t_Side)


class TestClosestIndex1(TestBSDFDirectionsClosestIndex):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex1)
    with SCOPED_TRACE("Begin Test: Find closest index 1.").
    """

    def test_closest_index_1(self):
        aDirections = self.GetDirections(BSDFDirection.Incoming)

        theta = 15.0
        phi = 270.0

        beamIndex = aDirections.getNearestBeamIndex(theta, phi)

        self.assertEqual(int(beamIndex), 7)


class TestClosestIndex2(TestBSDFDirectionsClosestIndex):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex2)
    with SCOPED_TRACE("Begin Test: Find closest index 2.").
    """

    def test_closest_index_2(self):
        aDirections = self.GetDirections(BSDFDirection.Incoming)

        theta = 70.0
        phi = 175.0

        beamIndex = aDirections.getNearestBeamIndex(theta, phi)

        self.assertEqual(int(beamIndex), 37)


class TestClosestIndex3(TestBSDFDirectionsClosestIndex):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex3)
    with SCOPED_TRACE("Begin Test: Find closest index 3.").
    """

    def test_closest_index_3(self):
        aDirections = self.GetDirections(BSDFDirection.Incoming)

        theta = 55.0
        phi = 60.0

        beamIndex = aDirections.getNearestBeamIndex(theta, phi)

        self.assertEqual(int(beamIndex), 23)


class TestClosestIndex4(TestBSDFDirectionsClosestIndex):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex4)
    with SCOPED_TRACE("Begin Test: Find closest index 4.").
    """

    def test_closest_index_4(self):
        aDirections = self.GetDirections(BSDFDirection.Incoming)

        theta = 0.0
        phi = 0.0

        beamIndex = aDirections.getNearestBeamIndex(theta, phi)

        self.assertEqual(int(beamIndex), 0)


class TestClosestIndex5(TestBSDFDirectionsClosestIndex):
    """
    Mirrors gtest TEST_F(TestBSDFDirectionsClosestIndex, TestClosestIndex5)
    with SCOPED_TRACE("Begin Test: Find closest index 5.").
    """

    def test_closest_index_5(self):
        aDirections = self.GetDirections(BSDFDirection.Incoming)

        theta = 71.2163
        phi = 349.744251

        beamIndex = aDirections.getNearestBeamIndex(theta, phi)

        self.assertEqual(int(beamIndex), 33)


if __name__ == "__main__":
    unittest.main()
