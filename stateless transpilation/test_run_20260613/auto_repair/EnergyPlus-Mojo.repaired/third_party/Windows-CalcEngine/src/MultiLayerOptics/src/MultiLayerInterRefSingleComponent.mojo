from WCECommon import Side, EnergyFlow, EnumSide, EnumEnergyFlow, getFlowFromSide
from WCESingleLayerOptics import CLayerSingleComponent, Property
from EquivalentLayerSingleComponent import CEquivalentLayerSingleComponent

class CSurfaceEnergy:
    var m_IEnergy: Dict[Tuple[Side, EnergyFlow], List[Float64]]

    def __init__(inout self):
        self.m_IEnergy = Dict[Tuple[Side, EnergyFlow], List[Float64]]()
        for t_Side in EnumSide():
            for t_EnergyFlow in EnumEnergyFlow():
                self.m_IEnergy[(t_Side, t_EnergyFlow)] = List[Float64]()

    def addEnergy(inout self, t_Side: Side, t_EnergySide: EnergyFlow, t_Value: Float64):
        self.m_IEnergy[(t_Side, t_EnergySide)].append(t_Value)

    def IEnergy(self, Index: Int, t_Side: Side, t_EnergyFlow: EnergyFlow) -> Float64:
        return self.m_IEnergy[(t_Side, t_EnergyFlow)][Index - 1]

class CInterRefSingleComponent:
    var m_Layers: List[CLayerSingleComponent]
    var m_IEnergy: CSurfaceEnergy
    var m_StateCalculated: Bool

    def __init__(inout self, t_Tf: Float64 = 0, t_Rf: Float64 = 0, t_Tb: Float64 = 0, t_Rb: Float64 = 0):
        self.m_StateCalculated = False
        self.initialize(t_Tf, t_Rf, t_Tb, t_Rb)

    def __init__(inout self, t_Layer: CLayerSingleComponent):
        self.m_StateCalculated = False
        let Tf = t_Layer.getProperty(Property.T, Side.Front)
        let Rf = t_Layer.getProperty(Property.R, Side.Front)
        let Tb = t_Layer.getProperty(Property.T, Side.Back)
        let Rb = t_Layer.getProperty(Property.R, Side.Back)
        self.initialize(Tf, Rf, Tb, Rb)

    def addLayer(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64, t_Side: Side = Side.Back):
        let aLayer = CLayerSingleComponent(t_Tf, t_Rf, t_Tb, t_Rb)
        if t_Side == Side.Front:
            self.m_Layers.insert(0, aLayer)
        elif t_Side == Side.Back:
            self.m_Layers.append(aLayer)
        else:
            assert(False, "Impossible side selection when adding new layer.")
        self.m_StateCalculated = False

    def addLayer(inout self, tLayer: CLayerSingleComponent, t_Side: Side = Side.Back):
        let Tf = tLayer.getProperty(Property.T, Side.Front)
        let Rf = tLayer.getProperty(Property.R, Side.Front)
        let Tb = tLayer.getProperty(Property.T, Side.Back)
        let Rb = tLayer.getProperty(Property.R, Side.Back)
        self.addLayer(Tf, Rf, Tb, Rb, t_Side)

    def getEnergyToSurface(self, Index: Int, t_Side: Side, t_EnergyFlow: EnergyFlow) -> Float64:
        self.calculateEnergies()
        return self.m_IEnergy.IEnergy(Index, t_Side, t_EnergyFlow)

    def getSurfaceEnergy(self) -> CSurfaceEnergy:
        self.calculateEnergies()
        return self.m_IEnergy

    def getLayerAbsorptance(self, Index: Int, t_Side: Side) -> Float64:
        let aFlow = getFlowFromSide(t_Side)
        var absTot: Float64 = 0
        for aSide in EnumSide():
            absTot += self.m_Layers[Index - 1].getProperty(Property.Abs, aSide) * self.getEnergyToSurface(Index, aSide, aFlow)
        return absTot

    def initialize(inout self, t_Tf: Float64, t_Rf: Float64, t_Tb: Float64, t_Rb: Float64):
        self.m_StateCalculated = False
        self.addLayer(t_Tf, t_Rf, t_Tb, t_Rb)

    def calculateEnergies(inout self):
        if not self.m_StateCalculated:
            let forwardLayers = self.calculateForwardLayers()
            let backwardLayers = self.calculateBackwardLayers()
            for i in range(0, len(self.m_Layers) + 1):
                let aForwardLayer = forwardLayers[i]
                let aBackwardLayer = backwardLayers[i]
                let Tf = aForwardLayer.getProperty(Property.T, Side.Front)
                let Tb = aBackwardLayer.getProperty(Property.T, Side.Back)
                let Rf = aBackwardLayer.getProperty(Property.R, Side.Front)
                let Rb = aForwardLayer.getProperty(Property.R, Side.Back)
                let iReflectance = 1 / (1 - Rf * Rb)
                if i != len(self.m_Layers):
                    self.m_IEnergy.addEnergy(Side.Front, EnergyFlow.Forward, Tf * iReflectance)
                    self.m_IEnergy.addEnergy(Side.Front, EnergyFlow.Backward, Tb * Rb * iReflectance)
                if i != 0:
                    self.m_IEnergy.addEnergy(Side.Back, EnergyFlow.Forward, Tf * Rf * iReflectance)
                    self.m_IEnergy.addEnergy(Side.Back, EnergyFlow.Backward, Tb * iReflectance)
            self.m_StateCalculated = True

    def calculateForwardLayers(self) -> List[CLayerSingleComponent]:
        var forwardLayers = List[CLayerSingleComponent]()
        var aLayer = CLayerSingleComponent(1, 0, 1, 0)
        forwardLayers.append(aLayer)
        aLayer = self.m_Layers[0]
        forwardLayers.append(aLayer)
        var aEqLayer = CEquivalentLayerSingleComponent(aLayer)
        for i in range(1, len(self.m_Layers)):
            aEqLayer.addLayer(self.m_Layers[i])
            let layer = aEqLayer.getLayer()
            forwardLayers.append(layer)
        return forwardLayers

    def calculateBackwardLayers(self) -> List[CLayerSingleComponent]:
        var backwardLayers = List[CLayerSingleComponent]()
        var aLayer = CLayerSingleComponent(1, 0, 1, 0)
        backwardLayers.append(aLayer)
        let size = len(self.m_Layers) - 1
        aLayer = self.m_Layers[size]
        backwardLayers.insert(0, aLayer)
        var aEqLayer = CEquivalentLayerSingleComponent(aLayer)
        for i in range(size, 0, -1):
            aEqLayer.addLayer(self.m_Layers[i - 1], Side.Front)
            let layer = aEqLayer.getLayer()
            backwardLayers.insert(0, layer)
        return backwardLayers