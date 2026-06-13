from DirectionalDiffuseCell.hpp import CDirectionalDiffuseCell, CBaseCell, ICellDescription, CBeamDirection, CMaterial
from MaterialDescription.hpp import CMaterial as MaterialDescription
from FenestrationCommon import Side, Property

@value
struct CDirectionalDiffuseCell(CBaseCell):
    var m_Material: CMaterial

    def __init__(inout self, t_MaterialProperties: CMaterial, t_Cell: ICellDescription, rotation: Float64 = 0):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell, rotation)
        self.m_Material = t_MaterialProperties

    def T_dir_dif(inout self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        var cellT: Float64 = CBaseCell.T_dir_dir(self, t_Side, t_IncomingDirection)
        var materialT: Float64 = self.m_Material.getProperty(Property.T, t_Side, t_IncomingDirection, t_OutgoingDirection)
        var t: Float64 = cellT + (1 - cellT) * materialT
        return t

    def R_dir_dif(inout self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        var cellT: Float64 = CBaseCell.T_dir_dir(self, t_Side, t_IncomingDirection)
        var cellR: Float64 = CBaseCell.R_dir_dir(self, t_Side, t_IncomingDirection)
        var materialR: Float64 = self.m_Material.getProperty(Property.R, t_Side, t_IncomingDirection, t_OutgoingDirection)
        var r: Float64 = cellR + (1 - cellT) * materialR
        return r

    def T_dir_dif_band(inout self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> List[Float64]:
        var cellT: Float64 = CBaseCell.T_dir_dir(self, t_Side, t_IncomingDirection)
        var materialBandValues: List[Float64] = self.m_Material.getBandProperties(Property.T, t_Side, t_IncomingDirection, t_OutgoingDirection)
        var result: List[Float64] = List[Float64]()
        result.reserve(len(materialBandValues))
        for materialBandValue in materialBandValues:
            result.append(cellT + (1 - cellT) * materialBandValue)
        return result

    def R_dir_dif_band(inout self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> List[Float64]:
        var cellT: Float64 = CBaseCell.T_dir_dir(self, t_Side, t_IncomingDirection)
        var cellR: Float64 = CBaseCell.R_dir_dir(self, t_Side, t_IncomingDirection)
        var materialBandValues: List[Float64] = self.m_Material.getBandProperties(Property.R, t_Side, t_IncomingDirection, t_OutgoingDirection)
        var result: List[Float64] = List[Float64]()
        result.reserve(len(materialBandValues))
        for materialBandValue in materialBandValues:
            result.append(cellR + (1 - cellT) * materialBandValue)
        return result