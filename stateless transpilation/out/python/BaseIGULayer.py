# EXTERNAL DEPS (to wire in glue):
# - BaseLayer (from BaseLayer.py)
# - Surface (from Surface.py)
# - FenestrationCommon (from FenestrationCommon.py)

from typing import Protocol, Optional
from math import fabs

class BaseLayer(Protocol):
    def getSurface(self, t_Position: 'FenestrationCommon.Side') -> 'Surface':
        ...

class Surface(Protocol):
    def getTemperature(self) -> float:
        ...

    def J(self) -> float:
        ...

    def getMaxDeflection(self) -> float:
        ...

    def getMeanDeflection(self) -> float:
        ...

class FenestrationCommon:
    class Side:
        Front = 0
        Back = 1

class CBaseIGULayer(BaseLayer):
    def __init__(self, t_Thickness: float):
        self.m_Thickness = t_Thickness

    def getThickness(self) -> float:
        return self.m_Thickness + self.getSurface(FenestrationCommon.Side.Front).getMeanDeflection() - self.getSurface(FenestrationCommon.Side.Back).getMeanDeflection()

    def getTemperature(self, t_Position: 'FenestrationCommon.Side') -> float:
        return self.getSurface(t_Position).getTemperature()

    def J(self, t_Position: 'FenestrationCommon.Side') -> float:
        return self.getSurface(t_Position).J()

    def getMaxDeflection(self) -> float:
        assert self.getSurface(FenestrationCommon.Side.Front).getMaxDeflection() == self.getSurface(FenestrationCommon.Side.Back).getMaxDeflection()
        return self.getSurface(FenestrationCommon.Side.Front).getMaxDeflection()

    def getMeanDeflection(self) -> float:
        assert self.getSurface(FenestrationCommon.Side.Front).getMeanDeflection() == self.getSurface(FenestrationCommon.Side.Back).getMeanDeflection()
        return self.getSurface(FenestrationCommon.Side.Front).getMeanDeflection()

    def getConductivity(self) -> float:
        return self.getConductionConvectionCoefficient() * self.m_Thickness

    def getEffectiveThermalConductivity(self) -> float:
        return fabs(self.getHeatFlow() * self.m_Thickness / (self.getSurface(FenestrationCommon.Side.Front).getTemperature() - self.getSurface(FenestrationCommon.Side.Back).getTemperature()))

    def layerTemperature(self) -> float:
        return (self.getTemperature(FenestrationCommon.Side.Front) + self.getTemperature(FenestrationCommon.Side.Back)) / 2

    def getConductionConvectionCoefficient(self) -> float:
        # Placeholder for actual implementation
        return 0.0

    def getHeatFlow(self) -> float:
        # Placeholder for actual implementation
        return 0.0
