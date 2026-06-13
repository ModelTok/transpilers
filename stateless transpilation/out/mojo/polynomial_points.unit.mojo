# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import Polynom, PolynomialPoints360deg

import unittest

class PolynomialPointsTest(unittest.TestCase):
    def setUp(self):
        poly1 = Polynom([-6.75, 8.65, -0.75])
        poly2 = Polynom([1.5, -2.5, 0.3])
        poly3 = Polynom([2.4, 20, 1.3, -0.24])

        self.m_Points = PolynomialPoints360deg()
        self.m_Points.storePoint(10, poly1)
        self.m_Points.storePoint(20, poly2)
        self.m_Points.storePoint(30, poly3)

    def getPoints(self):
        return self.m_Points

    def test_closest_point_in_range(self):
        val = self.getPoints().valueAt(15, 12)
        self.assertAlmostEqual(1.875, val, places=6)

    def test_closest_point_on_lower_range(self):
        val = self.getPoints().valueAt(5, 12)
        self.assertAlmostEqual(-10.570147, val, places=6)

    def test_closest_point_higer_range(self):
        val = self.getPoints().valueAt(150, 12)
        self.assertAlmostEqual(5.763529, val, places=6)

if __name__ == '__main__':
    unittest.main()
