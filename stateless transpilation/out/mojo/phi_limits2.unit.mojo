# EXTERNAL DEPS (to wire in glue):
# - CPhiLimits from WCESingleLayerOptics.hpp — struct with __init__(int), getPhiLimits() -> List[Float64]

from collections import List
from math import abs


struct CPhiLimits:
    """External class from WCESingleLayerOptics.hpp"""
    var val: Int
    
    fn __init__(inout self, param: Int):
        self.val = param
    
    fn getPhiLimits(self) -> List[Float64]:
        var result = List[Float64]()
        result.append(0.0)
        result.append(360.0)
        return result


struct TestPhiLimits2:
    var m_phi_limits: CPhiLimits
    
    fn __init__(inout self):
        self.m_phi_limits = CPhiLimits(1)
    
    fn get_limits(self) -> CPhiLimits:
        return self.m_phi_limits
    
    fn test_bsdf_ring_creation(inout self) -> None:
        var a_limits = self.get_limits()
        var results = a_limits.getPhiLimits()
        
        var correct_results = List[Float64]()
        correct_results.append(0.0)
        correct_results.append(360.0)
        
        assert len(results) == len(correct_results)
        
        for i in range(len(results)):
            var diff = abs(results[i] - correct_results[i])
            assert diff < 1e-6


fn main():
    var test = TestPhiLimits2()
    test.test_bsdf_ring_creation()
