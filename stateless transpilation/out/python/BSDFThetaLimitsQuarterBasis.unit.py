import unittest
from typing import List

# EXTERNAL DEPS (to wire in glue):
# WCESingleLayerOptics.hpp

class CThetaLimits:
    def __init__(self, theta_angles: List[float]):
        self.theta_limits = self.calculate_theta_limits(theta_angles)

    def calculate_theta_limits(self, theta_angles: List[float]) -> List[float]:
        results = [0]
        for i in range(len(theta_angles) - 1):
            mid_angle = (theta_angles[i] + theta_angles[i + 1]) / 2
            results.append(mid_angle)
        results.append(90)
        return results

    def get_theta_limits(self) -> List[float]:
        return self.theta_limits

class TestBSDFThetaLimtisQuarterBasis(unittest.TestCase):
    def setUp(self):
        theta_angles = [0, 18, 36, 54, 76.5]
        self.m_thetas = CThetaLimits(theta_angles)

    def test_quarter_basis(self):
        print("Begin Test: Theta limits - quarter basis.")
        a_limits = self.m_thetas
        results = a_limits.get_theta_limits()
        correct_results = [0, 9, 27, 45, 63, 90]
        self.assertEqual(len(results), len(correct_results))
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)

if __name__ == '__main__':
    unittest.main()
