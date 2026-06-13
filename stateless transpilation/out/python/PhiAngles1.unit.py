# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from WCESingleLayerOptics.hpp

import unittest
from typing import List


class CBSDFPhiAngles:
    """Stub interface - to be wired to actual WCESingleLayerOptics implementation"""
    
    def __init__(self, num_angles: int):
        self.num_angles = num_angles
    
    def phiAngles(self) -> List[float]:
        raise NotImplementedError("CBSDFPhiAngles.phiAngles must be provided by WCESingleLayerOptics")


class TestPhisAngles1(unittest.TestCase):
    
    def setUp(self) -> None:
        self.m_BasisRing = CBSDFPhiAngles(8)
    
    def get_ring(self) -> CBSDFPhiAngles:
        return self.m_BasisRing
    
    def test_bsdf_ring_creation(self) -> None:
        a_ring = self.get_ring()
        results = a_ring.phiAngles()
        
        correct_results = [0, 45, 90, 135, 180, 225, 270, 315]
        self.assertEqual(len(results), len(correct_results))
        
        for i in range(len(results)):
            self.assertAlmostEqual(results[i], correct_results[i], places=6)


if __name__ == '__main__':
    unittest.main()
