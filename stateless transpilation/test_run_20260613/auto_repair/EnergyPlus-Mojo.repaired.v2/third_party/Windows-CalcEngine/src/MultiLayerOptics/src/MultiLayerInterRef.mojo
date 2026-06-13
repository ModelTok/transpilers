from WCESingleLayerOptics import CScatteringLayer, CScatteringSurface, CEquivalentScatteringLayer
from WCECommon import (
    Side, Scattering, ScatteringSimple, EnergyFlow, PropertySimple,
    CSurfaceEnergy, EnumEnergyFlow, EnumSide, oppositeSide, getSideFromFlow
)
from MultiLayerInterRefSingleComponent import CInterRefSingleComponent
from memory import Pointer
from utils import Vector, Map, Pair
from math import abs
from sys import info

@value
struct CLayer_List:
    var data: Vector[CScatteringLayer]

    def __init__(inout self):
        self.data = Vector[CScatteringLayer]()

    def __init__(inout self, other: CLayer_List):
        self.data = other.data

    def __copyinit__(inout self, other: CLayer_List):
        self.data = other.data

    def __moveinit__(inout self, owned other: CLayer_List):
        self.data = other.data

    def push_back(inout self, layer: CScatteringLayer):
        self.data.push_back(layer)

    def insert(inout self, pos: Int, layer: CScatteringLayer):
        self.data.insert(pos, layer)

    def __getitem__(self, idx: Int) -> CScatteringLayer:
        return self.data[idx]

    def __setitem__(inout self, idx: Int, val: CScatteringLayer):
        self.data[idx] = val

    def size(self) -> Int:
        return self.data.size

    def __iter__(self) -> ...:
        return self.data.__iter__()

@value
struct CInterRef:
    var m_Layers: Vector[CScatteringLayer]
    var m_StackedLayers: Map[Side, CLayer_List]
    var m_DirectComponent: CInterRefSingleComponent
    var m_DiffuseComponent: CInterRefSingleComponent
    var m_Energy: Map[Scattering, CSurfaceEnergy]
    var m_Abs: Map[Pair[Side, ScatteringSimple], Vector[Float64]]
    var m_StateCalculated: Bool
    var m_Theta: Float64
    var m_Phi: Float64

    def __init__(inout self, t_Layer: CScatteringLayer, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0):
        self.m_StackedLayers = Map[Side, CLayer_List]()
        self.m_StackedLayers[Side.Front] = CLayer_List()
        self.m_StackedLayers[Side.Back] = CLayer_List()
        self.m_DirectComponent = CInterRefSingleComponent(t_Layer.getLayer(Scattering.DirectDirect, t_Theta, t_Phi))
        self.m_DiffuseComponent = CInterRefSingleComponent(t_Layer.getLayer(Scattering.DiffuseDiffuse, t_Theta, t_Phi))
        self.m_Energy = Map[Scattering, CSurfaceEnergy]()
        self.m_Energy[Scattering.DirectDirect] = CSurfaceEnergy()
        self.m_Energy[Scattering.DirectDiffuse] = CSurfaceEnergy()
        self.m_Energy[Scattering.DiffuseDiffuse] = CSurfaceEnergy()
        self.m_Abs = Map[Pair[Side, ScatteringSimple], Vector[Float64]]()
        self.m_Abs[Pair[Side.Front, ScatteringSimple.Diffuse]] = Vector[Float64]()
        self.m_Abs[Pair[Side.Back, ScatteringSimple.Diffuse]] = Vector[Float64]()
        self.m_Abs[Pair[Side.Front, ScatteringSimple.Direct]] = Vector[Float64]()
        self.m_Abs[Pair[Side.Back, ScatteringSimple.Direct]] = Vector[Float64]()
        self.m_StateCalculated = False
        self.m_Theta = t_Theta
        self.m_Phi = t_Phi
        self.m_Layers = Vector[CScatteringLayer]()
        self.m_Layers.push_back(t_Layer)

    def addLayer(inout self, t_Layer: CScatteringLayer, t_Side: Side = Side.Back, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0):
        if t_Side == Side.Front:
            self.m_Layers.insert(0, t_Layer)
        elif t_Side == Side.Back:
            self.m_Layers.push_back(t_Layer)
        else:
            # assert("Impossible side selection when adding new layer.")

        self.m_DirectComponent.addLayer(t_Layer.getLayer(Scattering.DirectDirect, t_Theta, t_Phi), t_Side)
        self.m_DiffuseComponent.addLayer(t_Layer.getLayer(Scattering.DiffuseDiffuse, t_Theta, t_Phi), t_Side)
        self.m_StateCalculated = False

    def getAbsorptance(inout self, Index: Int, t_Side: Side, t_Scattering: ScatteringSimple, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0) -> Float64:
        self.calculateEnergies(t_Theta, t_Phi)
        var aVector: Pointer[Vector[Float64]] = self.m_Abs.get(Pair[Side, ScatteringSimple](t_Side, t_Scattering))
        var vecSize: Int = aVector[].size()
        if vecSize < Index:
            raise Error("Requested layer index is out of range.")
        return aVector[][Index - 1]

    def getEnergyToSurface(inout self, Index: Int, t_SurfaceSide: Side, t_EnergyFlow: EnergyFlow, t_Scattering: Scattering, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0) -> Float64:
        self.calculateEnergies(t_Theta, t_Phi)
        return self.m_Energy[t_Scattering].IEnergy(Index, t_SurfaceSide, t_EnergyFlow)

    def size(self) -> Int:
        return self.m_Layers.size()

    def calculateEnergies(inout self, t_Theta: Float64, t_Phi: Float64):
        if (not self.m_StateCalculated) or (t_Theta != self.m_Theta) or (t_Phi != self.m_Phi):
            self.createForwardLayers(t_Theta, t_Phi)
            self.createBackwardLayers(t_Theta, t_Phi)
            self.m_Energy[Scattering.DirectDirect] = self.m_DirectComponent.getSurfaceEnergy()
            self.m_Energy[Scattering.DiffuseDiffuse] = self.m_DiffuseComponent.getSurfaceEnergy()
            self.m_Energy[Scattering.DirectDiffuse] = self.calcDirectToDiffuseComponent(t_Theta, t_Phi)
            self.calculateAbsroptances(t_Theta, t_Phi)
            self.m_StateCalculated = True
            self.m_Theta = t_Theta
            self.m_Phi = t_Phi

    def createForwardLayers(inout self, t_Theta: Float64, t_Phi: Float64):
        var aLayers: Pointer[CLayer_List] = self.m_StackedLayers.get(Side.Front)
        var aFront: CScatteringSurface = CScatteringSurface(1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        var aBack: CScatteringSurface = CScatteringSurface(1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        var exterior: CScatteringLayer = CScatteringLayer(aFront, aBack)
        aLayers[].push_back(exterior)
        var aLayer: CScatteringLayer = self.m_Layers[0]
        aLayers[].push_back(aLayer)
        var aEqLayer: CEquivalentScatteringLayer = CEquivalentScatteringLayer(aLayer, t_Theta, t_Phi)
        for i in range(1, self.m_Layers.size()):
            aEqLayer.addLayer(self.m_Layers[i], Side.Back, t_Theta, t_Phi)
            aLayers[].push_back(aEqLayer.getLayer())
        aLayers[].push_back(exterior)

    def createBackwardLayers(inout self, t_Theta: Float64, t_Phi: Float64):
        var aLayers: Pointer[CLayer_List] = self.m_StackedLayers.get(Side.Back)
        var aFront: CScatteringSurface = CScatteringSurface(1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        var aBack: CScatteringSurface = CScatteringSurface(1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        var exterior: CScatteringLayer = CScatteringLayer(aFront, aBack)
        aLayers[].push_back(exterior)
        var size: Int = self.m_Layers.size() - 1
        var aLayer: CScatteringLayer = self.m_Layers[size]
        aLayers[].insert(0, aLayer)
        var aEqLayer: CEquivalentScatteringLayer = CEquivalentScatteringLayer(aLayer, t_Theta, t_Phi)
        for i in range(size, 0, -1):
            aEqLayer.addLayer(self.m_Layers[i - 1], Side.Front, t_Theta, t_Phi)
            aLayers[].insert(0, aEqLayer.getLayer())
        aLayers[].insert(0, exterior)

    def calcDiffuseEnergy(inout self, t_Theta: Float64, t_Phi: Float64) -> CSurfaceEnergy:
        var diffSum: CSurfaceEnergy = CSurfaceEnergy()
        for aEnergyFlow in EnumEnergyFlow():
            for i in range(1, self.m_Layers.size() + 1):
                for aSide in EnumSide():
                    var oppSide: Side = oppositeSide(aSide)
                    var beamEnergy: Float64 = 0.0
                    var curLayer: CScatteringLayer = self.m_StackedLayers[oppSide][i]
                    if (aSide == Side.Front and aEnergyFlow == EnergyFlow.Backward) or (aSide == Side.Back and aEnergyFlow == EnergyFlow.Forward):
                        beamEnergy = curLayer.getPropertySimple(curLayer.getMinLambda(), curLayer.getMaxLambda(), PropertySimple.T, oppSide, Scattering.DirectDiffuse, t_Theta, t_Phi)
                    var R: Float64 = curLayer.getPropertySimple(curLayer.getMinLambda(), curLayer.getMaxLambda(), PropertySimple.R, aSide, Scattering.DirectDiffuse, t_Theta, t_Phi)
                    var intEnergy: Float64 = R * self.m_Energy[Scattering.DirectDirect].IEnergy(i, aSide, aEnergyFlow)
                    diffSum.addEnergy(aSide, aEnergyFlow, beamEnergy + intEnergy)
        return diffSum

    def calcDirectToDiffuseComponent(inout self, t_Theta: Float64, t_Phi: Float64) -> CSurfaceEnergy:
        var diffSum: CSurfaceEnergy = self.calcDiffuseEnergy(t_Theta, t_Phi)
        var aScatter: CSurfaceEnergy = CSurfaceEnergy()
        for aEnergyFlow in EnumEnergyFlow():
            for i in range(0, self.m_Layers.size() + 1):
                var fwdLayer: CScatteringLayer = self.m_StackedLayers[Side.Front][i]
                var bkwLayer: CScatteringLayer = self.m_StackedLayers[Side.Back][i + 1]
                var Ib: Float64 = 0.0
                if i != 0:
                    Ib = diffSum.IEnergy(i, Side.Back, aEnergyFlow)
                var If: Float64 = 0.0
                if i != self.m_Layers.size():
                    If = diffSum.IEnergy(i + 1, Side.Front, aEnergyFlow)
                var Rf_bkw: Float64 = bkwLayer.getPropertySimple(bkwLayer.getMinLambda(), bkwLayer.getMaxLambda(), PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
                var Rb_fwd: Float64 = fwdLayer.getPropertySimple(fwdLayer.getMinLambda(), fwdLayer.getMaxLambda(), PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
                var interRef: Float64 = 1.0 / (1.0 - Rf_bkw * Rb_fwd)
                var Ib_tot: Float64 = (Ib * Rf_bkw + If) * interRef
                var If_tot: Float64 = (Ib + Rb_fwd * If) * interRef
                if i != 0:
                    aScatter.addEnergy(Side.Back, aEnergyFlow, Ib_tot)
                if i != self.m_Layers.size():
                    aScatter.addEnergy(Side.Front, aEnergyFlow, If_tot)
        return aScatter

    def calculateAbsroptances(inout self, t_Theta: Float64, t_Phi: Float64):
        for i in range(0, self.m_Layers.size()):
            for aEnergyFlow in EnumEnergyFlow():
                var EnergyDirect: Float64 = 0.0
                var EnergyDiffuse: Float64 = 0.0
                for aSide in EnumSide():
                    var Adir: Float64 = self.m_Layers[i].getAbsorptance(aSide, ScatteringSimple.Direct, t_Theta, t_Phi)
                    EnergyDirect += Adir * self.m_Energy[Scattering.DirectDirect].IEnergy(i + 1, aSide, aEnergyFlow)
                    var Adif: Float64 = self.m_Layers[i].getAbsorptance(aSide, ScatteringSimple.Diffuse, t_Theta, t_Phi)
                    EnergyDirect += Adif * self.m_Energy[Scattering.DirectDiffuse].IEnergy(i + 1, aSide, aEnergyFlow)
                    EnergyDiffuse += Adif * self.m_Energy[Scattering.DiffuseDiffuse].IEnergy(i + 1, aSide, aEnergyFlow)
                var flowSide: Side = getSideFromFlow(aEnergyFlow)
                self.m_Abs[Pair[Side, ScatteringSimple](flowSide, ScatteringSimple.Direct)].push_back(EnergyDirect)
                self.m_Abs[Pair[Side, ScatteringSimple](flowSide, ScatteringSimple.Diffuse)].push_back(EnergyDiffuse)