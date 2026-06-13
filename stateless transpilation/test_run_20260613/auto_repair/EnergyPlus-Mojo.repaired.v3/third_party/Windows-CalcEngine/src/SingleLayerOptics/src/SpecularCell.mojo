from BaseCell import CBaseCell
from MaterialDescription import CMaterial
from SpecularCellDescription import CSpecularCellDescription
from ICellDescription import ICellDescription
from BeamDirection import CBeamDirection
from WCECommon import Side, Property

@value
class CSpecularCell(CBaseCell):
    var m_Material: CMaterial
    var m_CellDescription: ICellDescription

    def __init__(self, t_MaterialProperties: CMaterial, t_Cell: ICellDescription):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell)
        self.m_Material = t_MaterialProperties
        self.m_CellDescription = t_Cell

    def __init__(self, t_MaterialProperties: CMaterial):
        CBaseCell.__init__(self, t_MaterialProperties, CSpecularCellDescription())
        self.m_Material = t_MaterialProperties
        self.m_CellDescription = CSpecularCellDescription()

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return self.m_Material.getProperty(Property.T, t_Side, t_Direction)

    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return self.m_Material.getProperty(Property.R, t_Side, t_Direction)

    def T_dir_dir_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        return self.m_Material.getBandProperties(Property.T, t_Side, t_Direction)

    def R_dir_dir_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        return self.m_Material.getBandProperties(Property.R, t_Side, t_Direction)

    def getCellAsSpecular(self) -> CSpecularCellDescription:
        if (self.m_CellDescription as CSpecularCellDescription) is None:
            assert("Incorrectly assigned cell description.")
        var aCell: CSpecularCellDescription = self.m_CellDescription as CSpecularCellDescription
        return aCell