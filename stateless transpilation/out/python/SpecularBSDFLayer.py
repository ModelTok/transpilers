# EXTERNAL DEPS (to wire in glue):
# - CSpecularCell - from SpecularCell.hpp
# - CBSDFHemisphere - from BSDFLayer.hpp
# - CBeamDirection - from BeamDirection.hpp
# - FenestrationCommon::Side - from WCECommon.hpp

from typing import Any
from abc import ABC, abstractmethod


class CBSDFLayer(ABC):
    def __init__(self, cell: Any, hemisphere: Any):
        self.m_Cell = cell
    
    @abstractmethod
    def calcDiffuseDistribution(self, aSide: Any, t_Direction: Any, t_DirectionIndex: int) -> None:
        pass
    
    @abstractmethod
    def calcDiffuseDistribution_wv(self, aSide: Any, t_Direction: Any, t_DirectionIndex: int) -> None:
        pass


class CSpecularBSDFLayer(CBSDFLayer):
    def __init__(self, t_Cell: Any, t_Hemisphere: Any):
        super().__init__(t_Cell, t_Hemisphere)
    
    def cellAsSpecular(self) -> Any:
        a_cell = self.m_Cell
        assert a_cell is not None
        return a_cell
    
    def calcDiffuseDistribution(self, aSide: Any, t_Direction: Any, t_DirectionIndex: int) -> None:
        # No diffuse calculations are necessary for specular layer.
        pass
    
    def calcDiffuseDistribution_wv(self, aSide: Any, t_Direction: Any, t_DirectionIndex: int) -> None:
        # No diffuse calculations are necessary for specular layer.
        pass
