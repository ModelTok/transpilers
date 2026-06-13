# EXTERNAL DEPS (to wire in glue):
# - IIGUSystem: abstract base class from IGUConfigurations
# - System: enum from IGUConfigurations
# - Environment: enum from IGUConfigurations

from abc import ABC, abstractmethod
from enum import Enum


class System(Enum):
    NONE = 0


class Environment(Enum):
    NONE = 0


class IIGUSystem(ABC):
    
    @abstractmethod
    def getUValue(self) -> float:
        pass
    
    @abstractmethod
    def getSHGC(self, t_TotSol: float) -> float:
        pass
    
    @abstractmethod
    def getH(self, system: System, environment: Environment) -> float:
        pass
    
    @abstractmethod
    def setWidth(self, width: float) -> None:
        pass
    
    @abstractmethod
    def setHeight(self, height: float) -> None:
        pass
    
    @abstractmethod
    def setTilt(self, tilt: float) -> None:
        pass
    
    @abstractmethod
    def setWidthAndHeight(self, width: float, height: float) -> None:
        pass
    
    @abstractmethod
    def setInteriorAndExteriorSurfacesHeight(self, height: float) -> None:
        pass


class SimpleIGU(IIGUSystem):
    
    def __init__(self, uValue: float, shgc: float, h: float):
        self.m_UValue = uValue
        self.m_SHGC = shgc
        self.m_H = h
    
    def getUValue(self) -> float:
        return self.m_UValue
    
    def getSHGC(self, t_TotSol: float) -> float:
        return self.m_SHGC
    
    def getH(self, system: System, environment: Environment) -> float:
        return self.m_H
    
    def setWidth(self, width: float) -> None:
        pass
    
    def setHeight(self, height: float) -> None:
        pass
    
    def setTilt(self, tilt: float) -> None:
        pass
    
    def setWidthAndHeight(self, width: float, height: float) -> None:
        pass
    
    def setInteriorAndExteriorSurfacesHeight(self, height: float) -> None:
        pass
