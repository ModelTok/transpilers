from WovenCell.hpp import CWovenCellDescription, ICellDescription, CBeamDirection, CWovenBase, CWovenCell
from CellDescription.hpp import CBaseCell
from WovenCellDescription.hpp import CWovenCellDescription
from MaterialDescription.hpp import CMaterial
from WCECommon.hpp import Side, Property, oppositeSide, degrees
from BeamDirection.hpp import CBeamDirection
from memory import shared_ptr
from math import pow, exp, sqrt, abs, max
from vector import DynamicVector
from algorithm import assert

@value
struct CWovenBase(CUniformDiffuseCell):
    var m_MaterialProperties: shared_ptr[CMaterial]
    var m_Cell: shared_ptr[ICellDescription]

    def __init__(inout self, t_MaterialProperties: shared_ptr[CMaterial], t_Cell: shared_ptr[ICellDescription]):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell)
        CUniformDiffuseCell.__init__(self, t_MaterialProperties, t_Cell)
        self.m_MaterialProperties = t_MaterialProperties
        self.m_Cell = t_Cell

    def getCellAsWoven(self) -> shared_ptr[CWovenCellDescription]:
        if dynamic_pointer_cast[CWovenCellDescription](self.m_CellDescription) is None:
            assert("Incorrectly assigned cell description.")
        var aCell: shared_ptr[CWovenCellDescription] = dynamic_pointer_cast[CWovenCellDescription](self.m_CellDescription)
        return aCell

@value
struct CWovenCell(CWovenBase):
    def __init__(inout self, t_MaterialProperties: shared_ptr[CMaterial], t_Cell: shared_ptr[ICellDescription]):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell)
        CWovenBase.__init__(self, t_MaterialProperties, t_Cell)

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return self.m_CellDescription.T_dir_dir(t_Side, t_Direction)

    def T_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var T_material: Float64 = CWovenBase.T_dir_dif(self, t_Side, t_Direction)
        var openness: Float64 = CWovenBase.T_dir_dir(self, t_Side, t_Direction)
        var Tsct: Float64 = self.Tscatter_single(t_Side, t_Direction)
        return T_material * (1 - openness) + Tsct

    def R_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var R_material: Float64 = CWovenBase.R_dir_dif(self, t_Side, t_Direction)
        var Tsct: Float64 = self.Tscatter_single(t_Side, t_Direction)
        return R_material - Tsct

    def T_dir_dir_band(self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        return CWovenBase.T_dir_dir_band(self, t_Side, t_Direction)

    def T_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        var T_material: DynamicVector[Float64] = CWovenBase.T_dir_dif_band(self, t_Side, t_Direction)
        var Tsct: DynamicVector[Float64] = self.Tscatter_range(t_Side, t_Direction)
        assert(Tsct.size == T_material.size)
        for i in range(T_material.size):
            T_material[i] = T_material[i] + Tsct[i]
        return T_material

    def R_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        var R_material: DynamicVector[Float64] = CWovenBase.R_dir_dif_band(self, t_Side, t_Direction)
        var Tsct: DynamicVector[Float64] = self.Tscatter_range(t_Side, t_Direction)
        assert(Tsct.size == R_material.size)
        for i in range(R_material.size):
            R_material[i] = R_material[i] - Tsct[i]
        return R_material

    def Tscatter_single(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var aScatterSide: Side = oppositeSide(t_Side)
        var RScatter_mat: Float64 = self.m_Material.getProperty(Property.R, aScatterSide)
        return self.Tscatter(t_Direction, RScatter_mat)

    def Tscatter_range(self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        var aScatterSide: Side = oppositeSide(t_Side)
        var RScatter_mat: DynamicVector[Float64] = self.m_Material.getBandProperties(Property.R, aScatterSide)
        var aTsct: DynamicVector[Float64] = DynamicVector[Float64]()
        for i in range(RScatter_mat.size):
            var aTscatter: Float64 = self.Tscatter(t_Direction, RScatter_mat[i])
            aTsct.push_back(aTscatter)
        return aTsct

    def Tscatter(self, t_Direction: CBeamDirection, Rmat: Float64) -> Float64:
        var Tsct: Float64 = 0
        if Rmat > 0:
            var aAlt: Float64 = degrees(t_Direction.Altitude())
            var aAzm: Float64 = degrees(t_Direction.Azimuth())
            var aCell: shared_ptr[CWovenCellDescription] = self.getCellAsWoven()
            var gamma: Float64 = aCell.gamma()
            if gamma < 1:
                var Tscattermax: Float64 = 0.0229 * gamma + 0.2971 * Rmat - 0.03624 * pow(gamma, 2) + 0.04763 * pow(Rmat, 2) - 0.44416 * gamma * Rmat
                var DeltaMax: Float64 = 89.7 - 10 * gamma / 0.16
                var Delta: Float64 = pow(pow(aAlt, 2) + pow(aAzm, 2), 0.5)
                var PeakRatio: Float64 = 1 / (0.2 * Rmat * (1 - gamma))
                var E: Float64 = 0
                if Delta > DeltaMax:
                    E = -(pow(abs(Delta - DeltaMax), 2.5)) / 600
                    Tsct = -0.2 * Rmat * Tscattermax * (1 - gamma) * max(0.0, (Delta - DeltaMax) / (90 - DeltaMax))
                else:
                    E = -(pow(abs(Delta - DeltaMax), 2)) / 600
                    Tsct = 0
                Tsct = Tsct + 0.2 * Rmat * Tscattermax * (1 - gamma) * (1 + (PeakRatio - 1) * exp(E))
            if Tsct < 0:
                Tsct = 0
        return Tsct