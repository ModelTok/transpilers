from MultiLayerInterRef import CInterRef
from EquivalentScatteringLayer import CEquivalentScatteringLayer
from WCESingleLayerOptics import CScatteringLayer, IScatteringLayer
from WCECommon import CSeries, PropertySimple, Side, Scattering, ScatteringSimple
from memory import Pointer
from utils import Vector
from math import abs as math_abs

@value
struct CMultiLayerScattered(IScatteringLayer):
    var m_InterRef: Pointer[CInterRef]
    var m_Layer: Pointer[CEquivalentScatteringLayer]
    var m_Layers: Vector[CScatteringLayer]
    var m_Calculated: Bool
    var m_Theta: Float64
    var m_Phi: Float64

    def __init__(inout self, t_Tf_dir_dir: Float64 = 0, t_Rf_dir_dir: Float64 = 0, t_Tb_dir_dir: Float64 = 0, t_Rb_dir_dir: Float64 = 0, t_Tf_dir_dif: Float64 = 0, t_Rf_dir_dif: Float64 = 0, t_Tb_dir_dif: Float64 = 0, t_Rb_dir_dif: Float64 = 0, t_Tf_dif_dif: Float64 = 0, t_Rf_dif_dif: Float64 = 0, t_Tb_dif_dif: Float64 = 0, t_Rb_dif_dif: Float64 = 0):
        self.m_Calculated = False
        self.m_Theta = 0
        self.m_Phi = 0
        var aLayer = CScatteringLayer(t_Tf_dir_dir, t_Rf_dir_dir, t_Tb_dir_dir, t_Rb_dir_dir, t_Tf_dir_dif, t_Rf_dir_dif, t_Tb_dir_dif, t_Rb_dir_dif, t_Tf_dif_dif, t_Rf_dif_dif, t_Tb_dif_dif, t_Rb_dif_dif)
        self.initialize(aLayer)

    def __init__(inout self, t_Layer: CScatteringLayer):
        self.m_Calculated = False
        self.m_Theta = 0
        self.m_Phi = 0
        self.initialize(t_Layer)

    def __init__(inout self, layers: Vector[CScatteringLayer]):
        for layer in layers:
            self.addLayer(layer)

    @staticmethod
    def create(t_Layer: CScatteringLayer) -> Pointer[CMultiLayerScattered]:
        return Pointer[CMultiLayerScattered].alloc(CMultiLayerScattered(t_Layer))

    @staticmethod
    def create(layers: Vector[CScatteringLayer]) -> Pointer[CMultiLayerScattered]:
        return Pointer[CMultiLayerScattered].alloc(CMultiLayerScattered(layers))

    def addLayer(inout self, t_Tf_dir_dir: Float64, t_Rf_dir_dir: Float64, t_Tb_dir_dir: Float64, t_Rb_dir_dir: Float64, t_Tf_dir_dif: Float64, t_Rf_dir_dif: Float64, t_Tb_dir_dif: Float64, t_Rb_dir_dif: Float64, t_Tf_dif_dif: Float64, t_Rf_dif_dif: Float64, t_Tb_dif_dif: Float64, t_Rb_dif_dif: Float64, t_Side: Side = Side.Back):
        var aLayer = CScatteringLayer(t_Tf_dir_dir, t_Rf_dir_dir, t_Tb_dir_dir, t_Rb_dir_dir, t_Tf_dir_dif, t_Rf_dir_dif, t_Tb_dir_dif, t_Rb_dir_dif, t_Tf_dif_dif, t_Rf_dif_dif, t_Tb_dif_dif, t_Rb_dif_dif)
        self.addLayer(aLayer, t_Side)

    def addLayer(inout self, t_Layer: CScatteringLayer, t_Side: Side = Side.Back):
        if t_Side == Side.Front:
            self.m_Layers.insert(0, t_Layer)
        elif t_Side == Side.Back:
            self.m_Layers.push_back(t_Layer)
        else:
            print("Incorrect side selected.")
        self.m_Calculated = False

    def setSourceData(inout self, t_SourceData: CSeries):
        for layer in self.m_Layers:
            layer.setSourceData(t_SourceData)
            self.m_Calculated = False

    def getNumOfLayers(self) -> Int:
        return self.m_Layers.size()

    def getPropertySimple(self, minLambda: Float64, maxLambda: Float64, t_Property: PropertySimple, t_Side: Side, t_Scattering: Scattering, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64:
        self.calculateState(t_Theta, t_Phi)
        return self.m_Layer[].getPropertySimple(t_Property, t_Side, t_Scattering, t_Theta, t_Phi)

    def getAbsorptanceLayer(self, Index: Int, t_Side: Side, t_Scattering: ScatteringSimple, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64:
        return self.getAbsorptanceLayer(0, 0, Index, t_Side, t_Scattering, t_Theta, t_Phi)

    def getAbsorptanceLayer(self, minLambda: Float64, maxLambda: Float64, Index: Int, t_Side: Side, t_Scattering: ScatteringSimple, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64:
        self.calculateState(t_Theta, t_Phi)
        return self.m_InterRef[].getAbsorptance(Index, t_Side, t_Scattering, t_Theta, t_Phi)

    def getAbsorptanceLayers(self, minLambda: Float64, maxLambda: Float64, side: Side, scattering: ScatteringSimple, theta: Float64 = 0, phi: Float64 = 0) -> Vector[Float64]:
        var abs: Vector[Float64] = Vector[Float64]()
        for i in range(self.m_Layers.size()):
            abs.push_back(self.getAbsorptanceLayer(minLambda, maxLambda, i, side, scattering, theta, phi))
        return abs

    def getAbsorptance(self, t_Side: Side, t_Scattering: ScatteringSimple, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64:
        self.calculateState(t_Theta, t_Phi)
        var aAbs: Float64 = 0
        for i in range(self.m_InterRef[].size()):
            aAbs += self.m_InterRef[].getAbsorptance(i + 1, t_Side, t_Scattering, t_Theta, t_Phi)
        return aAbs

    def initialize(inout self, t_Layer: CScatteringLayer):
        self.m_Layers.push_back(t_Layer)

    def calculateState(inout self, t_Theta: Float64, t_Phi: Float64):
        if not self.m_Calculated or (t_Theta != self.m_Theta) or (t_Phi != self.m_Phi):
            self.m_Layer = Pointer[CEquivalentScatteringLayer].alloc(CEquivalentScatteringLayer(self.m_Layers[0], t_Theta, t_Phi))
            self.m_InterRef = Pointer[CInterRef].alloc(CInterRef(self.m_Layers[0], t_Theta, t_Phi))
            for i in range(1, self.m_Layers.size()):
                self.m_Layer[].addLayer(self.m_Layers[i], Side.Back, t_Theta, t_Phi)
                self.m_InterRef[].addLayer(self.m_Layers[i], Side.Back, t_Theta, t_Phi)
            self.m_Calculated = True
            self.m_Theta = t_Theta
            self.m_Phi = t_Phi

    def getWavelengths(self) -> Vector[Float64]:
        return self.m_Layers[0].getWavelengths()

    def getMinLambda(self) -> Float64:
        return self.m_Layers[0].getMinLambda()

    def getMaxLambda(self) -> Float64:
        return self.m_Layers[0].getMaxLambda()