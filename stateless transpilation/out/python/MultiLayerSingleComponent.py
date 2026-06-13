# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side - source: WCECommon.hpp
# - FenestrationCommon.Property - source: WCECommon.hpp
# - CInterRefSingleComponent - source: MultiLayerInterRefSingleComponent.hpp
# - CEquivalentLayerSingleComponent - source: EquivalentLayerSingleComponent.hpp

from typing import Any


class CMultiLayerSingleComponent:
    """Class to calculate multilayer optical properties for single component (direct or diffuse)"""

    def __init__(
        self,
        inter_ref: Any,
        equivalent_layer: Any,
        t_Tf: float = 0,
        t_Rf: float = 0,
        t_Tb: float = 0,
        t_Rb: float = 0,
    ) -> None:
        self.m_Inter = inter_ref
        self.m_Equivalent = equivalent_layer

    def addLayer(
        self,
        t_Tf: float,
        t_Rf: float,
        t_Tb: float,
        t_Rb: float,
        t_Side: Any = None,
    ) -> None:
        """Adding layer to front or back side of composition"""
        self.m_Inter.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)
        self.m_Equivalent.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)

    def getProperty(self, t_Property: Any, t_Side: Any) -> float:
        """Get optical properties of equivalent layer"""
        return self.m_Equivalent.getProperty(t_Property, t_Side)

    def getLayerAbsorptance(self, Index: int, t_Side: Any) -> float:
        return self.m_Inter.getLayerAbsorptance(Index, t_Side)
