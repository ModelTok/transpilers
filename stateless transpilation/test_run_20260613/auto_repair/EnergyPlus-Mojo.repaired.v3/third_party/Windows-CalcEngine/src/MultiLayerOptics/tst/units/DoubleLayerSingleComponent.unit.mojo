from memory import shared_ptr, make_shared
from WCEMultiLayerOptics import CEquivalentLayerSingleComponent
from WCECommon import Property, Side

class TestDoubleLayerSingleComponent:
    var m_DoubleBack: shared_ptr[CEquivalentLayerSingleComponent]
    var m_DoubleFront: shared_ptr[CEquivalentLayerSingleComponent]

    def __init__(self):
        self.m_DoubleBack = make_shared[CEquivalentLayerSingleComponent](0.46, 0.52, 0.64, 0.22)
        self.m_DoubleBack.addLayer(0.56, 0.34, 0.49, 0.39)
        self.m_DoubleFront = make_shared[CEquivalentLayerSingleComponent](0.46, 0.52, 0.64, 0.22)
        self.m_DoubleFront.addLayer(0.56, 0.34, 0.49, 0.39, Side.Front)

    def getDoubleBack(self) -> shared_ptr[CEquivalentLayerSingleComponent]:
        return self.m_DoubleBack

    def getDoubleFront(self) -> shared_ptr[CEquivalentLayerSingleComponent]:
        return self.m_DoubleFront

def TestPropertiesBackSide():
    print("Begin Test: Double pane equivalent layer properties (additonal layer on back side).")
    var doubleLayer: CEquivalentLayerSingleComponent = *TestDoubleLayerSingleComponent().getDoubleBack()
    var Tf: Float64 = doubleLayer.getProperty(Property.T, Side.Front)
    assert abs(0.278426286 - Tf) < 1e-6
    var Rf: Float64 = doubleLayer.getProperty(Property.R, Side.Front)
    assert abs(0.6281885 - Rf) < 1e-6
    var Af: Float64 = doubleLayer.getProperty(Property.Abs, Side.Front)
    assert abs(0.093385214 - Af) < 1e-6
    var Tb: Float64 = doubleLayer.getProperty(Property.T, Side.Back)
    assert abs(0.33895374 - Tb) < 1e-6
    var Rb: Float64 = doubleLayer.getProperty(Property.R, Side.Back)
    assert abs(0.455248595 - Rb) < 1e-6
    var Ab: Float64 = doubleLayer.getProperty(Property.Abs, Side.Back)
    assert abs(0.205797665 - Ab) < 1e-6

def TestPropertiesFrontSide():
    print("Begin Test: Double pane equivalent layer properties (additonal layer on front side).")
    var doubleLayer: CEquivalentLayerSingleComponent = *TestDoubleLayerSingleComponent().getDoubleFront()
    var Tf: Float64 = doubleLayer.getProperty(Property.T, Side.Front)
    assert abs(0.323130958 - Tf) < 1e-6
    var Rf: Float64 = doubleLayer.getProperty(Property.R, Side.Front)
    assert abs(0.518986453 - Rf) < 1e-6
    var Af: Float64 = doubleLayer.getProperty(Property.Abs, Side.Front)
    assert abs(0.157882589 - Af) < 1e-6
    var Tb: Float64 = doubleLayer.getProperty(Property.T, Side.Back)
    assert abs(0.393376819 - Tb) < 1e-6
    var Rb: Float64 = doubleLayer.getProperty(Property.R, Side.Back)
    assert abs(0.364024084 - Rb) < 1e-6
    var Ab: Float64 = doubleLayer.getProperty(Property.Abs, Side.Back)
    assert abs(0.242599097 - Ab) < 1e-6