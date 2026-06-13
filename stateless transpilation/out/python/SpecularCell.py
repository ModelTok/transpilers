# EXTERNAL DEPS (to wire in glue):
# - CMaterial
# - ICellDescription
# - CBeamDirection
# - CBaseCell
# - CSpecularCellDescription
# - FenestrationCommon.Side
# - SpectralAveraging.Property

from typing import List, Optional, Protocol, TypeVar
from abc import ABC, abstractmethod
from math import modf

T = TypeVar('T')

class CMaterial(Protocol):
    def getProperty(self, property: str, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> float:
        pass

    def getBandProperties(self, property: str, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> List[float]:
        pass

class ICellDescription(Protocol):
    pass

class CBeamDirection(Protocol):
    pass

class CBaseCell(ABC):
    def __init__(self, material_properties: 'CMaterial', cell: Optional['ICellDescription'] = None):
        self.m_Material = material_properties
        self.m_CellDescription = cell

    @abstractmethod
    def T_dir_dir(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> float:
        pass

    @abstractmethod
    def R_dir_dir(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> float:
        pass

    @abstractmethod
    def T_dir_dir_band(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> List[float]:
        pass

    @abstractmethod
    def R_dir_dir_band(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> List[float]:
        pass

class CSpecularCellDescription(ICellDescription):
    pass

class FenestrationCommon:
    class Side:
        pass

class SpectralAveraging:
    class Property:
        T = 'T'
        R = 'R'

class SingleLayerOptics:
    class CSpecularCell(CBaseCell):
        def __init__(self, material_properties: 'CMaterial', cell: Optional['ICellDescription'] = None):
            super().__init__(material_properties, cell)

        def __init__(self, material_properties: 'CMaterial'):
            super().__init__(material_properties, CSpecularCellDescription())

        def T_dir_dir(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> float:
            return self.m_Material.getProperty(SpectralAveraging.Property.T, side, direction)

        def R_dir_dir(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> float:
            return self.m_Material.getProperty(SpectralAveraging.Property.R, side, direction)

        def T_dir_dir_band(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> List[float]:
            return self.m_Material.getBandProperties(SpectralAveraging.Property.T, side, direction)

        def R_dir_dir_band(self, side: 'FenestrationCommon.Side', direction: 'CBeamDirection') -> List[float]:
            return self.m_Material.getBandProperties(SpectralAveraging.Property.R, side, direction)

        def getCellAsSpecular(self) -> 'CSpecularCellDescription':
            if not isinstance(self.m_CellDescription, CSpecularCellDescription):
                raise AssertionError("Incorrectly assigned cell description.")
            return self.m_CellDescription
