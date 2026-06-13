# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from WCESingleLayerOptics (external module)

from collections import List


struct CBSDFPhiAngles:
    var num_angles: Int
    
    fn __init__(inout self, num_angles: Int):
        self.num_angles = num_angles
    
    fn phiAngles(self) -> List[Float64]:
        raise Error("CBSDFPhiAngles.phiAngles must be provided by WCESingleLayerOptics")


struct TestPhisAngles1:
    var m_BasisRing: CBSDFPhiAngles
    
    fn __init__(inout self):
        self.m_BasisRing = CBSDFPhiAngles(8)
    
    fn setUp(inout self):
        self.m_BasisRing = CBSDFPhiAngles(8)
    
    fn get_ring(self) -> CBSDFPhiAngles:
        return self.m_BasisRing
    
    fn test_bsdf_ring_creation(self) raises:
        var a_ring = self.get_ring()
        var results = a_ring.phiAngles()
        
        var correct_results = List[Float64](8)
        correct_results.append(0)
        correct_results.append(45)
        correct_results.append(90)
        correct_results.append(135)
        correct_results.append(180)
        correct_results.append(225)
        correct_results.append(270)
        correct_results.append(315)
        
        if len(results) != len(correct_results):
            raise Error("Expected size " + str(len(correct_results)) + " but got " + str(len(results)))
        
        for i in range(len(results)):
            var diff = abs(results[i] - correct_results[i])
            if diff > 1e-6:
                raise Error("Mismatch at index " + str(i) + ": expected " + str(correct_results[i]) + " but got " + str(results[i]))


fn main():
    var test = TestPhisAngles1()
    test.test_bsdf_ring_creation()
