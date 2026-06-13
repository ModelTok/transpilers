from WCECommon import Property, Side, oppositeSide
from WCESingleLayerOptics import CLayerSingleComponent
from memory import Pointer
from utils import String

@value
struct CEquivalentLayerSingleComponent:
    var m_EquivalentLayer: Pointer[CLayerSingleComponent]

    def __init__(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64):
        self.m_EquivalentLayer = Pointer[CLayerSingleComponent].alloc(1)
        self.m_EquivalentLayer.store(CLayerSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb))

    def __init__(inout self, t_Layer: CLayerSingleComponent):
        let Tf = t_Layer.getProperty(Property.T, Side.Front)
        let Rf = t_Layer.getProperty(Property.R, Side.Front)
        let Tb = t_Layer.getProperty(Property.T, Side.Back)
        let Rb = t_Layer.getProperty(Property.R, Side.Back)
        self.m_EquivalentLayer = Pointer[CLayerSingleComponent].alloc(1)
        self.m_EquivalentLayer.store(CLayerSingleComponent(Tf, Rf, Tb, Rb))

    def addLayer(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: Side = Side.Back):
        var firstLayer: Pointer[CLayerSingleComponent] = Pointer[CLayerSingleComponent]()
        var secondLayer: Pointer[CLayerSingleComponent] = Pointer[CLayerSingleComponent]()
        if t_Side == Side.Front:
            firstLayer = Pointer[CLayerSingleComponent].alloc(1)
            firstLayer.store(CLayerSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb))
            secondLayer = self.m_EquivalentLayer
        elif t_Side == Side.Back:
            firstLayer = self.m_EquivalentLayer
            secondLayer = Pointer[CLayerSingleComponent].alloc(1)
            secondLayer.store(CLayerSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb))
        else:
            assert(False, "Error in selection of side in double layer calculations.")
        let Tf = self.T(firstLayer.load(), secondLayer.load(), Side.Front)
        let Tb = self.T(firstLayer.load(), secondLayer.load(), Side.Back)
        let Rf = self.R(firstLayer.load(), secondLayer.load(), Side.Front)
        let Rb = self.R(firstLayer.load(), secondLayer.load(), Side.Back)
        self.m_EquivalentLayer.store(CLayerSingleComponent(Tf, Rf, Tb, Rb))

    def addLayer(inout self, t_Layer: CLayerSingleComponent, t_Side: Side = Side.Back):
        let Tf = t_Layer.getProperty(Property.T, Side.Front)
        let Rf = t_Layer.getProperty(Property.R, Side.Front)
        let Tb = t_Layer.getProperty(Property.T, Side.Back)
        let Rb = t_Layer.getProperty(Property.R, Side.Back)
        self.addLayer(Tf, Rf, Tb, Rb, t_Side)

    def getProperty(self, t_Property: Property, t_Side: Side) -> Float64:
        return self.m_EquivalentLayer.load().getProperty(t_Property, t_Side)

    def getLayer(self) -> CLayerSingleComponent:
        return self.m_EquivalentLayer.load()

    def interreflectance(self, t_Layer1: CLayerSingleComponent, t_Layer2: CLayerSingleComponent) -> Float64:
        return 1.0 / (1.0 - t_Layer1.getProperty(Property.R, Side.Back) * t_Layer2.getProperty(Property.R, Side.Front))

    def T(self, t_Layer1: CLayerSingleComponent, t_Layer2: CLayerSingleComponent, t_Side: Side) -> Float64:
        return t_Layer1.getProperty(Property.T, t_Side) * t_Layer2.getProperty(Property.T, t_Side) * self.interreflectance(t_Layer1, t_Layer2)

    def R(self, t_Layer1: CLayerSingleComponent, t_Layer2: CLayerSingleComponent, t_Side: Side) -> Float64:
        var firstLayer: CLayerSingleComponent
        var secondLayer: CLayerSingleComponent
        if t_Side == Side.Front:
            firstLayer = t_Layer1
            secondLayer = t_Layer2
        elif t_Side == Side.Back:
            firstLayer = t_Layer2
            secondLayer = t_Layer1
        else:
            assert(False, "Impossible selection of side in double layer calculations.")
        let opposite = oppositeSide(t_Side)
        return firstLayer.getProperty(Property.R, t_Side) + firstLayer.getProperty(Property.T, t_Side) * firstLayer.getProperty(Property.T, opposite) * secondLayer.getProperty(Property.R, t_Side) * self.interreflectance(t_Layer1, t_Layer2)