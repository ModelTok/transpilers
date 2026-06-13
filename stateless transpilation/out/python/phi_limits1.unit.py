from typing import List

class CPhiLimits:
    def __init__(self, n: int):
        self.m_num_divisions = n
        self.m_phi_limits = self._calculate_phi_limits()
    
    def _calculate_phi_limits(self) -> List[float]:
        step = 360.0 / self.m_num_divisions
        start = -step / 2.0
        limits = []
        for i in range(self.m_num_divisions + 1):
            limits.append(start + i * step)
        return limits
    
    def get_phi_limits(self) -> List[float]:
        return self.m_phi_limits

class TestPhiLimits1:
    def __init__(self):
        self.m_phi_limits = CPhiLimits(8)
    
    def get_limits(self) -> CPhiLimits:
        return self.m_phi_limits
    
    def test_bsdf_ring_creation(self):
        a_limits = self.get_limits()
        results = a_limits.get_phi_limits()
        
        correct_results = [-22.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5]
        assert len(results) == len(correct_results)
        
        for i in range(len(results)):
            assert abs(results[i] - correct_results[i]) < 1e-6
