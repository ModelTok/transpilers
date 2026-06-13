from typing import List


class CBSDFPhiAngles:
    def __init__(self, t_NumOfPhis: int) -> None:
        self.m_PhiAngles: List[float] = []
        self._createPhis(t_NumOfPhis)
    
    def phiAngles(self) -> List[float]:
        return self.m_PhiAngles
    
    def _createPhis(self, t_NumOfPhis: int) -> None:
        phi_delta = 360.0 / t_NumOfPhis
        for i in range(t_NumOfPhis):
            self.m_PhiAngles.append(i * phi_delta)
