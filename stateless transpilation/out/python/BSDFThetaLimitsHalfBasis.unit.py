# EXTERNAL DEPS (to wire in glue):
# - CThetaLimits: from WCESingleLayerOptics

import unittest
import math


class TestBSDFThetaLimtisHalfBasis(unittest.TestCase):
    """Test BSDF Theta Limits - Half Basis"""

    def setUp(self) -> None:
        """Setup called before each test"""
        from WCESingleLayerOptics import CThetaLimits
        theta_angles = [0, 13, 26, 39, 52, 65, 80.75]
        self.m_thetas = CThetaLimits(theta_angles)

    def get_limits(self):
        """Get the theta limits object"""
        return self.m_thetas

    def test_half_basis(self) -> None:
        """Test: Theta limits - half basis."""
        a_limits = self.get_limits()
        results = a_limits.getThetaLimits()
        correct_results = [0, 6.5, 19.5, 32.5, 45.5, 58.5, 71.5, 90]

        self.assertEqual(len(results), len(correct_results))

        for i in range(len(results)):
            self.assertTrue(
                math.isclose(results[i], correct_results[i], abs_tol=1e-6)
            )


if __name__ == "__main__":
    unittest.main()
