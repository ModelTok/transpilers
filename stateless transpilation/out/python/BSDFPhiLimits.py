from typing import List

# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from BSDFPhiAngles module, constructor(int), phiAngles() -> List[float]


class CPhiLimits:
    def __init__(self, t_NumOfPhis: int) -> None:
        if t_NumOfPhis == 0:
            raise RuntimeError(
                "Number of phi angles for BSDF definition must be greater than zero."
            )
        
        aPhiAngles = CBSDFPhiAngles(t_NumOfPhis)
        self.m_PhiLimits: List[float] = []
        self._createLimits(aPhiAngles.phiAngles())
    
    def getPhiLimits(self) -> List[float]:
        return self.m_PhiLimits
    
    def _createLimits(self, t_PhiAngles: List[float]) -> None:
        deltaPhi = 360.0 / len(t_PhiAngles)
        currentLimit = -deltaPhi / 2.0
        if len(t_PhiAngles) == 1:
            currentLimit = 0.0
        
        for i in range(len(t_PhiAngles) + 1):
            self.m_PhiLimits.append(currentLimit)
            currentLimit = currentLimit + deltaPhi
