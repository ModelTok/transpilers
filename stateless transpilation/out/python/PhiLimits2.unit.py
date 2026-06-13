# EXTERNAL DEPS (to wire in glue):
# - CPhiLimits from WCESingleLayerOptics.hpp — struct with __init__(int), getPhiLimits() -> list[float]

from typing import List
import unittest


class CPhiLimits:
    """External class from WCESingleLayerOptics.hpp"""
    def __init__(self, val: int):
        self.val = val
    
    def getPhiLimits(self) -> List[float]:
        return [0.0, 360.0]


class TestPhiLimits2(unittest.TestCase):
    def setUp(self):
        self.m_phi_limits = CPhiLimits(1)
    
    def get_limits(self) -> CPhiLimits:
        return self.m_phi_limits
    
    def test_bsdf_ring_creation(self):
        a_limits = self.get_limits()
        
        results = a_limits.getPhiLimits()
        
        correct_results = [0.0, 360.0]
        self.assertEqual(len(results), len(correct_results))
        
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)


if __name__ == "__main__":
    unittest.main()
