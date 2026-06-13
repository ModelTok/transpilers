# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from WCESingleLayerOptics

import unittest
from WCESingleLayerOptics import CBSDFPhiAngles


class TestPhisAngles2(unittest.TestCase):
    def setUp(self):
        self.m_basis_ring = CBSDFPhiAngles(12)

    def get_ring(self):
        return self.m_basis_ring

    def test_bsdf_ring_creation(self):
        a_ring = self.get_ring()
        results = a_ring.phiAngles()

        correct_results = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
        self.assertEqual(len(results), len(correct_results))

        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)


if __name__ == '__main__':
    unittest.main()
