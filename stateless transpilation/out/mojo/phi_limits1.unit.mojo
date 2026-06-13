struct CPhiLimits:
    var m_num_divisions: Int
    var m_phi_limits: List[Float64]
    
    fn __init__(inout self, n: Int):
        self.m_num_divisions = n
        self.m_phi_limits = List[Float64]()
        self._calculate_phi_limits()
    
    fn _calculate_phi_limits(inout self):
        var step = 360.0 / Float64(self.m_num_divisions)
        var start = -step / 2.0
        for i in range(self.m_num_divisions + 1):
            self.m_phi_limits.append(start + Float64(i) * step)
    
    fn get_phi_limits(self) -> List[Float64]:
        return self.m_phi_limits

struct TestPhiLimits1:
    var m_phi_limits: CPhiLimits
    
    fn __init__(inout self):
        self.m_phi_limits = CPhiLimits(8)
    
    fn get_limits(self) -> CPhiLimits:
        return self.m_phi_limits
    
    fn test_bsdf_ring_creation(self):
        var a_limits = self.get_limits()
        var results = a_limits.get_phi_limits()
        
        var correct_results = List[Float64]()
        correct_results.append(-22.5)
        correct_results.append(22.5)
        correct_results.append(67.5)
        correct_results.append(112.5)
        correct_results.append(157.5)
        correct_results.append(202.5)
        correct_results.append(247.5)
        correct_results.append(292.5)
        correct_results.append(337.5)
        
        assert len(results) == len(correct_results)
        
        for i in range(len(results)):
            assert abs(results[i] - correct_results[i]) < 1e-6

fn main():
    var test = TestPhiLimits1()
    test.test_bsdf_ring_creation()
