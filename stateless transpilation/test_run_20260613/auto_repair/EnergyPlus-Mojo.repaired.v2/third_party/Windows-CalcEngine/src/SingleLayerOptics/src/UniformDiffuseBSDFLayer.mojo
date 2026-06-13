from ..BSDFLayer import CBSDFLayer
from ..UniformDiffuseCell import CUniformDiffuseCell
from ..BSDFIntegrator import CBSDFIntegrator
from ..BSDFDirections import CBSDFDirections, BSDFDirection
from ..WCECommon import Side, PropertySimple, ConstantsData
from ..BeamDirection import CBeamDirection
from memory import Arc

struct CUniformDiffuseBSDFLayer(CBSDFLayer):
    def __init__(inout self, t_Cell: Arc[CUniformDiffuseCell], t_Hemisphere: CBSDFHemisphere):
        CBSDFLayer.__init__(self, t_Cell, t_Hemisphere)

    def cellAsUniformDiffuse(self) -> Arc[CUniformDiffuseCell]:
        var aCell = self.m_Cell as Arc[CUniformDiffuseCell]
        assert(aCell is not None, "aCell is None")
        return aCell

    def calcDiffuseDistribution(inout self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: UInt):
        var aCell = self.cellAsUniformDiffuse()
        var Tau = self.m_Results.getMatrix(aSide, PropertySimple.T)
        var Rho = self.m_Results.getMatrix(aSide, PropertySimple.R)
        var aTau = aCell.T_dir_dif(aSide, t_Direction)
        var Ref = aCell.R_dir_dif(aSide, t_Direction)
        var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
        var size = aDirections.size()
        for j in range(size):
            Tau[j][t_DirectionIndex] += aTau / ConstantsData.WCE_PI
            Rho[j][t_DirectionIndex] += Ref / ConstantsData.WCE_PI

    def calcDiffuseDistribution_wv(inout self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: UInt):
        var aCell = self.cellAsUniformDiffuse()
        var aTau = aCell.T_dir_dif_band(aSide, t_Direction)
        var Ref = aCell.R_dir_dif_band(aSide, t_Direction)
        var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
        var size = aDirections.size()
        for i in range(size):
            var numWV = aTau.size
            for j in range(numWV):
                var aResults = self.m_WVResults[j]
                assert(aResults is not None, "aResults is null")
                var tau = aResults.getMatrix(aSide, PropertySimple.T)
                var rho = aResults.getMatrix(aSide, PropertySimple.R)
                tau[i][t_DirectionIndex] += aTau[j] / ConstantsData.WCE_PI
                rho[i][t_DirectionIndex] += Ref[j] / ConstantsData.WCE_PI