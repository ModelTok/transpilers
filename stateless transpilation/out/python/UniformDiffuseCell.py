# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import Side, Property
# from single_layer_optics import ICellDescription, CBeamDirection, CMaterial, CBaseCell

from typing import List, Optional
from dataclasses import dataclass

@dataclass
class CUniformDiffuseCell:
    material_properties: Optional[CMaterial] = None
    cell: Optional[ICellDescription] = None
    rotation: float = 0.0

    def __post_init__(self):
        self.material_properties = self.material_properties
        self.cell = self.cell
        self.rotation = self.rotation

    def T_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return self.getMaterialProperty(Property.T, t_Side, t_Direction)

    def R_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return ((1 - self.T_dir_dir(t_Side, t_Direction))
                * self.material_properties.getProperty(Property.R, t_Side))

    def T_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[float]:
        return self.getMaterialProperties(Property.T, t_Side, t_Direction)

    def R_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[float]:
        return self.getMaterialProperties(Property.R, t_Side, t_Direction)

    def getMaterialProperty(self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return ((1 - self.T_dir_dir(t_Side, t_Direction)) * self.material_properties.getProperty(t_Property, t_Side))

    def getMaterialProperties(self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> List[float]:
        materialCoverFraction = 1 - self.T_dir_dir(t_Side, t_Direction)
        aMaterialProperties = self.material_properties.getBandProperties(t_Property, t_Side)
        aProperty = []
        for materialProperty in aMaterialProperties:
            aProperty.append(materialCoverFraction * materialProperty)
        return aProperty
