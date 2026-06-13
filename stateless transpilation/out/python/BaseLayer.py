# EXTERNAL DEPS (to wire in glue):
# - LayerInterfaces (from wherever it comes from)

from typing import Optional, Protocol, TypeVar, Generic
from abc import ABC, abstractmethod

class CLayerGeometry(Protocol):
    pass

class CLayerHeatFlow(Protocol):
    pass

class CState(Protocol):
    pass

class FenestrationCommon:
    class Side:
        pass

class Tarcog:
    class ISO15099:
        class CBaseLayer(CLayerGeometry, CLayerHeatFlow, ABC):
            def __init__(self):
                self.m_PreviousLayer: Optional['CBaseLayer'] = None
                self.m_NextLayer: Optional['CBaseLayer'] = None

            def getPreviousLayer(self) -> Optional['CBaseLayer']:
                return self.m_PreviousLayer

            def getNextLayer(self) -> Optional['CBaseLayer']:
                return self.m_NextLayer

            def connectToBackSide(self, t_Layer: 'CBaseLayer') -> None:
                self.m_NextLayer = t_Layer
                t_Layer.m_PreviousLayer = self

            def tearDownConnections(self) -> None:
                self.m_PreviousLayer = None
                self.m_NextLayer = None

            @abstractmethod
            def calculateConvectionOrConductionFlow(self) -> None:
                pass

            def calculateRadiationFlow(self) -> None:
                pass

            @abstractmethod
            def clone(self) -> 'CBaseLayer':
                pass

            def getThickness(self) -> float:
                return 0

            def isPermeable(self) -> bool:
                return False
