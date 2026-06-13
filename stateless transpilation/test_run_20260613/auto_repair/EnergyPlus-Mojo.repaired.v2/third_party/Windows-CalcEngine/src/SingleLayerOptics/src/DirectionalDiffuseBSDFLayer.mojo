from DirectionalDiffuseCell import CDirectionalDiffuseCell
from BSDFIntegrator import CBSDFIntegrator
from BSDFDirections import CBSDFDirections, BSDFDirection
from BeamDirection import CBeamDirection
from BSDFPatch import CBSDFPatch
from WCECommon import ConstantsData
from FenestrationCommon import Side, PropertySimple
from BSDFLayer import CBSDFLayer, CBSDFHemisphere
from builtin import Arc, List

class CDirectionalBSDFLayer(CBSDFLayer):
    def __init__(self, t_Cell: Arc[CDirectionalDiffuseCell], t_Hemisphere: CBSDFHemisphere):
        CBSDFLayer.__init__(self, t_Cell, t_Hemisphere)

    def cellAsDirectionalDiffuse(self) -> Arc[CDirectionalDiffuseCell]:
        aCell = self.m_Cell.as[CDirectionalDiffuseCell]()
        assert aCell is not None
        return aCell

    def calcDiffuseDistribution(self, aSide: Side, incomingDirection: CBeamDirection, incomingDirectionIndex: Int) override:
        aCell = self.cellAsDirectionalDiffuse()
        var tau = self.m_Results.getMatrix(aSide, PropertySimple.T)
        var Rho = self.m_Results.getMatrix(aSide, PropertySimple.R)
        var jDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Outgoing)
        var size = jDirections.size()
        for outgoingDirectionIndex in range(size):
            var jDirection = jDirections[outgoingDirectionIndex].centerPoint()
            var aTau = aCell.T_dir_dif(aSide, incomingDirection, jDirection)
            var aRho = aCell.R_dir_dif(aSide, incomingDirection, jDirection)
            tau[outgoingDirectionIndex, incomingDirectionIndex] += aTau * self.diffuseDistributionScalar(outgoingDirectionIndex)
            Rho[outgoingDirectionIndex, incomingDirectionIndex] += aRho * self.diffuseDistributionScalar(outgoingDirectionIndex)

    def calcDiffuseDistribution_wv(self, aSide: Side, incomingDirection: CBeamDirection, incomingDirectionIndex: Int) override:
        aCell = self.cellAsDirectionalDiffuse()
        var oDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Outgoing)
        var size = oDirections.size()
        for outgoingDirectionIndex in range(size):
            var oDirection = oDirections[outgoingDirectionIndex].centerPoint()
            var aTau = aCell.T_dir_dif_band(aSide, incomingDirection, oDirection)
            var Ref = aCell.R_dir_dif_band(aSide, incomingDirection, oDirection)
            var numWV = aTau.size()
            for j in range(numWV):
                var aResults: Arc[CBSDFIntegrator] = None
                aResults = self.m_WVResults[j]
                assert aResults is not None
                var tau = aResults.getMatrix(aSide, PropertySimple.T)
                var rho = aResults.getMatrix(aSide, PropertySimple.R)
                tau[outgoingDirectionIndex, incomingDirectionIndex] += aTau[j] * self.diffuseDistributionScalar(outgoingDirectionIndex)
                rho[outgoingDirectionIndex, incomingDirectionIndex] += Ref[j] * self.diffuseDistributionScalar(outgoingDirectionIndex)

    def diffuseDistributionScalar(self, outgoingDirection: Int) -> Float64:
        raise NotImplementedError("Pure function")

class CDirectionalDiffuseBSDFLayer(CDirectionalBSDFLayer):
    def __init__(self, t_Cell: Arc[CDirectionalDiffuseCell], t_Hemisphere: CBSDFHemisphere):
        CDirectionalBSDFLayer.__init__(self, t_Cell, t_Hemisphere)

    def diffuseDistributionScalar(self, outgoingDirection: Int) -> Float64 override:
        return 1.0 / ConstantsData.WCE_PI

class CMatrixBSDFLayer(CDirectionalBSDFLayer):
    def __init__(self, t_Cell: Arc[CDirectionalDiffuseCell], t_Hemisphere: CBSDFHemisphere):
        CDirectionalBSDFLayer.__init__(self, t_Cell, t_Hemisphere)

    def diffuseDistributionScalar(self, outgoingDirection: Int) -> Float64 override:
        var lambdas = self.m_BSDFHemisphere.getDirections(BSDFDirection.Outgoing).lambdaVector()
        return 1.0 / lambdas[outgoingDirection]