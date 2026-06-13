# EXTERNAL DEPS (to wire in glue):
# - CIGUGapLayer (from IGUGapLayer.py)
# - CBaseLayer (from BaseLayer.py)
# - CBaseIGULayer (from BaseIGULayer.py)
# - ConstantsData (from ConstantsData.py)

from abc import ABC, abstractmethod
from typing import Optional, TypeVar, Generic, Protocol, Any
from math import pi, pow

T = TypeVar('T')

class CIGUGapLayer(ABC):
    def __init__(self, layer: Any):
        self.layer = layer

    def calculateConvectionOrConductionFlow(self):
        pass

    def isCalculated(self) -> bool:
        pass

    @property
    def m_ConductiveConvectiveCoeff(self) -> float:
        pass

    @m_ConductiveConvectiveCoeff.setter
    def m_ConductiveConvectiveCoeff(self, value: float):
        pass

    @property
    def m_PreviousLayer(self) -> Any:
        pass

    @property
    def m_NextLayer(self) -> Any:
        pass

    @property
    def m_Thickness(self) -> float:
        pass

class CSupportPillar(CIGUGapLayer, ABC):
    def __init__(self, t_Layer: CIGUGapLayer, t_Conductivity: float):
        super().__init__(t_Layer)
        self.m_Conductivity = t_Conductivity

    def calculateConvectionOrConductionFlow(self):
        super().calculateConvectionOrConductionFlow()
        if not self.isCalculated():
            self.m_ConductiveConvectiveCoeff += self.conductivityOfPillarArray()

    @abstractmethod
    def conductivityOfPillarArray(self) -> float:
        pass

class CCircularPillar(CSupportPillar):
    def __init__(self, t_Gap: CIGUGapLayer, t_Conductivity: float, t_Spacing: float, t_Radius: float):
        super().__init__(t_Gap, t_Conductivity)
        self.m_Spacing = t_Spacing
        self.m_Radius = t_Radius

    def clone(self) -> 'CCircularPillar':
        return CCircularPillar(self.layer, self.m_Conductivity, self.m_Spacing, self.m_Radius)

    def conductivityOfPillarArray(self) -> float:
        from ConstantsData import WCE_PI

        cond1 = self.m_PreviousLayer.getConductivity()
        cond2 = self.m_NextLayer.getConductivity()
        aveCond = (cond1 + cond2) / 2

        cond = 2 * aveCond * self.m_Radius / (pow(self.m_Spacing, 2))
        cond *= 1 / (1 + 2 * self.m_Thickness * aveCond / (self.m_Conductivity * WCE_PI * self.m_Radius))

        return cond
