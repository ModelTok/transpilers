# EXTERNAL DEPS (to wire in glue):
# - CSpecularCell - from SpecularCell.hpp
# - CBSDFHemisphere - from BSDFLayer.hpp
# - CBeamDirection - from BeamDirection.hpp
# - FenestrationCommon::Side - from WCECommon.hpp

from typing import Any


struct CBSDFLayer:
    var m_Cell: Any
    
    fn __init__(inout self, cell: Any, hemisphere: Any):
        self.m_Cell = cell


struct CSpecularBSDFLayer(CBSDFLayer):
    fn __init__(inout self, t_Cell: Any, t_Hemisphere: Any):
        super().__init__(t_Cell, t_Hemisphere)
    
    fn cellAsSpecular(self) -> Any:
        var a_cell = self.m_Cell
        assert a_cell is not None
        return a_cell
    
    fn calcDiffuseDistribution(self, aSide: Any, t_Direction: Any, t_DirectionIndex: Int) -> None:
        # No diffuse calculations are necessary for specular layer.
        pass
    
    fn calcDiffuseDistribution_wv(self, aSide: Any, t_Direction: Any, t_DirectionIndex: Int) -> None:
        # No diffuse calculations are necessary for specular layer.
        pass
