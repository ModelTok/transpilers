from BaseCell import CBaseCell
from MaterialDescription import CMaterial
from CellDescription import ICellDescription
from BeamDirection import CBeamDirection
from FenestrationCommon import Side, Property
from WCECommon import *  # Import any needed symbols from WCECommon (e.g., T_dir_dir usage)

class CUniformDiffuseCell(CBaseCell):
    def __init__(inout self,
                t_MaterialProperties: shared_ptr[CMaterial],
                t_Cell: shared_ptr[ICellDescription],
                rotation: Float64 = 0.0):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell, rotation)

    def T_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return self.getMaterialProperty(Property.T, t_Side, t_Direction)

    def R_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return ((1 - self.T_dir_dir(t_Side, t_Direction))
                * self.m_Material.getProperty(Property.R, t_Side))

    def T_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        return self.getMaterialProperties(Property.T, t_Side, t_Direction)

    def R_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        return self.getMaterialProperties(Property.R, t_Side, t_Direction)

    def getMaterialProperty(self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return ((1 - self.T_dir_dir(t_Side, t_Direction)) * self.m_Material.getProperty(t_Property, t_Side))

    def getMaterialProperties(self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        var materialCoverFraction: Float64 = 1 - self.T_dir_dir(t_Side, t_Direction)
        var aMaterialProperties: List[Float64] = self.m_Material.getBandProperties(t_Property, t_Side)
        var aProperty: List[Float64] = List[Float64]()
        aProperty.reserve(len(aMaterialProperties))
        for materialProperty in aMaterialProperties:
            aProperty.append(materialCoverFraction * materialProperty)
        return aProperty