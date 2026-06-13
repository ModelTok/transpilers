from SpecularBSDFLayer.hpp import CSpecularBSDFLayer, CBSDFLayer, CSpecularCell, CBSDFHemisphere
from SpecularCell.hpp import CSpecularCell
from BSDFDirections.hpp import CBeamDirection
from WCECommon.hpp import FenestrationCommon
from BeamDirection.hpp import CBeamDirection
from memory import shared_ptr
from cassert import assert

@value
struct CSpecularBSDFLayer(CBSDFLayer):
    var m_Cell: shared_ptr[CSpecularCell]

    def __init__(inout self, t_Cell: shared_ptr[CSpecularCell], t_Hemisphere: CBSDFHemisphere):
        CBSDFLayer.__init__(self, t_Cell, t_Hemisphere)

    def cellAsSpecular(self) -> shared_ptr[CSpecularCell]:
        var aCell: shared_ptr[CSpecularCell] = shared_ptr[CSpecularCell](self.m_Cell)
        assert(aCell is not None)
        return aCell

    def calcDiffuseDistribution(inout self, aSide: FenestrationCommon.Side, t_Direction: CBeamDirection, t_DirectionIndex: size_t):

    def calcDiffuseDistribution_wv(inout self, aSide: FenestrationCommon.Side, t_Direction: CBeamDirection, t_DirectionIndex: size_t):
