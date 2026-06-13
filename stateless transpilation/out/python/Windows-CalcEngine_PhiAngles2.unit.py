from typing import *
from energyplus import *

class TestPhisAngles2(unittest.TestCase):
    def setUp(self):
        self.basis_ring = CBSDFPhiAngles(12)

    def test_bsdfring_creation(self):
        results = self.basis_ring.phi_angles()
        correct_results = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
        self.assertEqual(len(results), len(correct_results))
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)
