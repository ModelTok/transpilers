from typing import *
from energyplus import *

class TestPhiLimits2(unittest.TestCase):
    def GetLimits(self) -> CPhiLimits:
        return CPhiLimits(1)

    def test_BSDFRingCreation(self):
        aLimits = self.GetLimits()
        results = aLimits.getPhiLimits()
        correctResults = [0, 360]
        self.assertEqual(len(results), len(correctResults))
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correctResults[i], places=6)
