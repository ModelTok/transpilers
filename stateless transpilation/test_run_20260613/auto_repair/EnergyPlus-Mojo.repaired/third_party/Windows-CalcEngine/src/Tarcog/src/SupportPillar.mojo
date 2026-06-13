from IGUGapLayer import CIGUGapLayer
from WCETarcog import CBaseIGULayer
from ConstantsData import ConstantsData
from std import SharedPtr, make_shared, dynamic_pointer_cast

class CSupportPillar(CIGUGapLayer):
    def __init__(self, t_Layer: CIGUGapLayer, t_Conductivity: float):
        super().__init__(t_Layer)
        self.m_Conductivity = t_Conductivity

    def calculateConvectionOrConductionFlow(self):
        super().calculateConvectionOrConductionFlow()
        if not self.isCalculated():
            self.m_ConductiveConvectiveCoeff += self.conductivityOfPillarArray()

    def conductivityOfPillarArray(self) -> float:
        raise NotImplementedError("Abstract method")


class CCircularPillar(CSupportPillar):
    def __init__(
        self,
        t_Gap: CIGUGapLayer,
        t_Conductivity: float,
        t_Spacing: float,
        t_Radius: float,
    ):
        super().__init__(t_Gap, t_Conductivity)
        self.m_Spacing = t_Spacing
        self.m_Radius = t_Radius

    def conductivityOfPillarArray(self) -> float:
        using ConstantsData.WCE_PI
        var cond1 = dynamic_pointer_cast[CBaseIGULayer](self.m_PreviousLayer).getConductivity()
        var cond2 = dynamic_pointer_cast[CBaseIGULayer](self.m_NextLayer).getConductivity()
        var aveCond = (cond1 + cond2) / 2.0
        var cond = (2.0 * aveCond * self.m_Radius) / (pow(self.m_Spacing, 2))
        cond *= 1.0 / (1.0 + (2.0 * self.m_Thickness * aveCond) / (self.m_Conductivity * ConstantsData.WCE_PI * self.m_Radius))
        return cond

    def clone(self) -> SharedPtr[CBaseLayer]:
        return make_shared[CCircularPillar](self)