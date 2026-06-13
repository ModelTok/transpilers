# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side - source: WCECommon.hpp
# - FenestrationCommon.Property - source: WCECommon.hpp
# - CInterRefSingleComponent - source: MultiLayerInterRefSingleComponent.hpp
# - CEquivalentLayerSingleComponent - source: EquivalentLayerSingleComponent.hpp


trait InterRefSingleComponentInterface:
    fn addLayer(
        inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: AnyType
    ) -> None:
        ...

    fn getLayerAbsorptance(self, Index: Int, t_Side: AnyType) -> Float64:
        ...


trait EquivalentLayerSingleComponentInterface:
    fn addLayer(
        inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: AnyType
    ) -> None:
        ...

    fn getProperty(self, t_Property: AnyType, t_Side: AnyType) -> Float64:
        ...


struct CMultiLayerSingleComponent:
    var m_Inter: InterRefSingleComponentInterface
    var m_Equivalent: EquivalentLayerSingleComponentInterface

    fn __init__(
        inout self,
        inter_ref: InterRefSingleComponentInterface,
        equivalent_layer: EquivalentLayerSingleComponentInterface,
        t_Tf: Float64 = 0,
        t_Rf: Float64 = 0,
        t_Tb: Float64 = 0,
        t_Rb: Float64 = 0,
    ) -> None:
        self.m_Inter = inter_ref
        self.m_Equivalent = equivalent_layer

    fn addLayer(
        self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: AnyType = None
    ) -> None:
        """Adding layer to front or back side of composition"""
        self.m_Inter.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)
        self.m_Equivalent.addLayer(t_Tf, t_Rf, t_Tb, t_Rb, t_Side)

    fn getProperty(self, t_Property: AnyType, t_Side: AnyType) -> Float64:
        """Get optical properties of equivalent layer"""
        return self.m_Equivalent.getProperty(t_Property, t_Side)

    fn getLayerAbsorptance(self, Index: Int, t_Side: AnyType) -> Float64:
        return self.m_Inter.getLayerAbsorptance(Index, t_Side)
