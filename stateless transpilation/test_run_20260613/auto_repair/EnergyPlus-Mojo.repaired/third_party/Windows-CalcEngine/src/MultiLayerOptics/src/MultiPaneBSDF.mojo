from memory import Pointer
from math import sqrt, cos, sin, acos, atan2, pi, floor, ceil, abs, min, max, pow, exp, log
from utils import String
from vector import DynamicVector, StaticVector
from dict import Dict
from list import List
from WCECommon import CSeries, SquareMatrix, Side, PropertySimple, IntegrationType, Scattering, ScatteringSimple, EnumSide, EnumPropertySimple, CCommonWavelengths, Combine, CMatrixSeries, ConstantsData
from WCESingleLayerOptics import CBSDFLayer, CBSDFIntegrator, BSDFDirection, IScatteringLayer
from EquivalentBSDFLayer import CEquivalentBSDFLayer

@value
struct p_VectorSeries:
    var data: Pointer[CSeries]

    def __init__(inout self, ptr: Pointer[CSeries]):
        self.data = ptr

    def __copyinit__(inout self, other: p_VectorSeries):
        self.data = other.data

    def __moveinit__(inout self, owned other: p_VectorSeries):
        self.data = other.data

    @staticmethod
    def create(size: Int) -> p_VectorSeries:
        return p_VectorSeries(Pointer[CSeries].alloc(size))

    def __getitem__(self, idx: Int) -> CSeries:
        return self.data.load(idx)

    def __setitem__(self, idx: Int, val: CSeries):
        self.data.store(idx, val)

    def size(self) -> Int:
        return 0  # placeholder, actual size tracking needed

class CMultiPaneBSDF(IScatteringLayer):
    var m_Layer: CEquivalentBSDFLayer
    var m_SolarRadiationInit: CSeries
    var m_IncomingSpectra: p_VectorSeries
    var m_IncomingSolar: DynamicVector[Float64]
    var m_Results: Pointer[CBSDFIntegrator]
    var m_Abs: Dict[Side, DynamicVector[DynamicVector[Float64]]]
    var m_AbsHem: Dict[Side, Pointer[DynamicVector[Float64]]]
    var m_Calculated: Bool
    var m_MinLambdaCalculated: Float64
    var m_MaxLambdaCalculated: Float64
    var m_Integrator: IntegrationType
    var m_NormalizationCoefficient: Float64

    def __init__(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries, t_CommonWavelengths: DynamicVector[Float64]):
        self.m_Layer = CEquivalentBSDFLayer(t_CommonWavelengths, t_Layer[0])
        self.m_Results = Pointer[CBSDFIntegrator].alloc(1)
        self.m_Results.store(0, CBSDFIntegrator(t_Layer[0].load().getDirections(BSDFDirection.Incoming)))
        self.m_Calculated = False
        self.m_MinLambdaCalculated = 0.0
        self.m_MaxLambdaCalculated = 0.0
        self.m_Integrator = IntegrationType.Trapezoidal
        self.m_NormalizationCoefficient = 1.0
        self.initialize(t_Layer, t_SolarRadiation, t_DetectorData)

    def __init__(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_CommonWavelengths: DynamicVector[Float64]):
        self.m_Layer = CEquivalentBSDFLayer(t_CommonWavelengths, t_Layer[0])
        self.m_Results = Pointer[CBSDFIntegrator].alloc(1)
        self.m_Results.store(0, CBSDFIntegrator(t_Layer[0].load().getDirections(BSDFDirection.Incoming)))
        self.m_Calculated = False
        self.m_MinLambdaCalculated = 0.0
        self.m_MaxLambdaCalculated = 0.0
        self.m_Integrator = IntegrationType.Trapezoidal
        self.m_NormalizationCoefficient = 1.0
        self.initialize(t_Layer, t_SolarRadiation)

    def initialize(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries = CSeries()):
        var solarRadiation = t_SolarRadiation
        if t_DetectorData.size() > 0:
            var commonWavelengths = solarRadiation.getXArray()
            solarRadiation = solarRadiation * t_DetectorData.interpolate(commonWavelengths)
        self.m_SolarRadiationInit = solarRadiation
        for aSide in EnumSide():
            self.m_AbsHem[aSide] = Pointer[DynamicVector[Float64]].alloc(1)
            self.m_AbsHem[aSide].store(0, DynamicVector[Float64]())
        self.m_Layer.setSolarRadiation(self.m_SolarRadiationInit)
        var directionsSize = t_Layer[0].load().getDirections(BSDFDirection.Incoming).size()
        self.m_IncomingSolar = DynamicVector[Float64](directionsSize)
        self.m_IncomingSpectra = p_VectorSeries.create(directionsSize)
        for i in range(directionsSize):
            self.m_IncomingSpectra[i] = solarRadiation
        for j in range(1, t_Layer.size()):
            self.addLayer(t_Layer[j])

    def __init__(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries):
        self.__init__(t_Layer, t_SolarRadiation, self.getCommonWavelengths(t_Layer))

    def __init__(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries):
        self.__init__(t_Layer, t_SolarRadiation, t_DetectorData, self.getCommonWavelengths(t_Layer))

    def getMatrix(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple) -> SquareMatrix:
        self.calculate(minLambda, maxLambda)
        return self.m_Results.load().getMatrix(t_Side, t_Property)

    def DirDir(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, t_Theta: Float64, t_Phi: Float64) -> Float64:
        self.calculate(minLambda, maxLambda)
        return self.m_Results.load().DirDir(t_Side, t_Property, t_Theta, t_Phi)

    def DirDir(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, Index: Int) -> Float64:
        self.calculate(minLambda, maxLambda)
        return self.m_Results.load().DirDir(t_Side, t_Property, Index)

    def calculate(inout self, minLambda: Float64, maxLambda: Float64):
        if not self.m_Calculated or minLambda != self.m_MinLambdaCalculated or maxLambda != self.m_MaxLambdaCalculated:
            self.m_IncomingSolar.clear()
            for i in range(self.m_IncomingSpectra.size()):
                var aSpectra = self.m_IncomingSpectra[i]
                aSpectra = aSpectra.interpolate(self.m_Layer.getCommonWavelengths())
                var iTotalSolar = aSpectra.integrate(self.m_Integrator, self.m_NormalizationCoefficient)
                self.m_IncomingSolar.push_back(iTotalSolar.sum(minLambda, maxLambda))
            var aResults = Dict[Tuple[Side, PropertySimple], SquareMatrix]()
            for aSide in EnumSide():
                var aTotalA = self.m_Layer.getTotalA(aSide)
                aTotalA.mMult(self.m_IncomingSpectra)
                aTotalA.integrate(self.m_Integrator, self.m_NormalizationCoefficient)
                self.m_Abs[aSide] = aTotalA.getSums(minLambda, maxLambda, self.m_IncomingSolar)
                for aProprerty in EnumPropertySimple():
                    var aTot = self.m_Layer.getTotal(aSide, aProprerty)
                    aTot.mMult(self.m_IncomingSpectra)
                    aTot.integrate(self.m_Integrator, self.m_NormalizationCoefficient)
                    aResults[(aSide, aProprerty)] = aTot.getSquaredMatrixSums(minLambda, maxLambda, self.m_IncomingSolar)
                self.m_Results.load().setResultMatrices(aResults[(aSide, PropertySimple.T)], aResults[(aSide, PropertySimple.R)], aSide)
            for aSide in EnumSide():
                self.calcHemisphericalAbs(aSide)
            self.m_MinLambdaCalculated = minLambda
            self.m_MaxLambdaCalculated = maxLambda
            self.m_Calculated = True

    def calcHemisphericalAbs(inout self, t_Side: Side):
        var numOfLayers = self.m_Abs[t_Side].size()
        var aLambdas = self.m_Results.load().lambdaVector()
        for layNum in range(numOfLayers):
            var aAbs = self.m_Abs[t_Side][layNum]
            var mult = DynamicVector[Float64](aLambdas.size())
            for i in range(aLambdas.size()):
                mult[i] = aLambdas[i] * aAbs[i]
            var sum = 0.0
            for i in range(mult.size()):
                sum += mult[i]
            sum = sum / ConstantsData.WCE_PI
            self.m_AbsHem[t_Side].load().push_back(sum)

    def getCommonWavelengths(inout self, t_Layer: DynamicVector[Pointer[CBSDFLayer]]) -> DynamicVector[Float64]:
        var cw = CCommonWavelengths()
        for layer in t_Layer:
            cw.addWavelength(layer.load().getBandWavelengths())
        return cw.getCombinedWavelengths(Combine.Interpolate)

    def Abs(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, Index: Int) -> DynamicVector[Float64]:
        self.calculate(minLambda, maxLambda)
        return self.m_Abs[t_Side][Index - 1]

    def DirHem(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple) -> DynamicVector[Float64]:
        self.calculate(minLambda, maxLambda)
        return self.m_Results.load().DirHem(t_Side, t_Property)

    def DirHem(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, t_Theta: Float64, t_Phi: Float64) -> Float64:
        var aIndex = self.m_Results.load().getNearestBeamIndex(t_Theta, t_Phi)
        return self.DirHem(minLambda, maxLambda, t_Side, t_Property)[aIndex]

    def DirHem(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, Index: Int) -> Float64:
        return self.DirHem(minLambda, maxLambda, t_Side, t_Property)[Index]

    def Abs(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, layerIndex: Int, t_Theta: Float64, t_Phi: Float64) -> Float64:
        var aIndex = self.m_Results.load().getNearestBeamIndex(t_Theta, t_Phi)
        return self.Abs(minLambda, maxLambda, t_Side, layerIndex)[aIndex]

    def Abs(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, layerIndex: Int, beamIndex: Int) -> Float64:
        return self.Abs(minLambda, maxLambda, t_Side, layerIndex)[beamIndex]

    def DiffDiff(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple) -> Float64:
        self.calculate(minLambda, maxLambda)
        return self.m_Results.load().DiffDiff(t_Side, t_Property)

    def AbsDiff(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_LayerIndex: Int) -> Float64:
        self.calculate(minLambda, maxLambda)
        return self.m_AbsHem[t_Side].load()[t_LayerIndex - 1]

    def energy(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, t_Theta: Float64, t_Phi: Float64) -> Float64:
        self.calculate(minLambda, maxLambda)
        var aIndex = self.m_Results.load().getNearestBeamIndex(t_Theta, t_Phi)
        var solarRadiation = self.m_IncomingSolar[aIndex]
        var dirHem = self.DirHem(minLambda, maxLambda, t_Side, t_Property)[aIndex]
        return dirHem * solarRadiation

    def energyAbs(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, Index: Int, t_Theta: Float64, t_Phi: Float64) -> Float64:
        self.calculate(minLambda, maxLambda)
        var aIndex = self.m_Results.load().getNearestBeamIndex(t_Theta, t_Phi)
        var solarRadiation = self.m_IncomingSolar[aIndex]
        var abs = self.Abs(minLambda, maxLambda, t_Side, Index)[aIndex]
        return abs * solarRadiation

    def setIntegrationType(inout self, t_type: IntegrationType, normalizationCoefficient: Float64):
        self.m_NormalizationCoefficient = normalizationCoefficient
        self.m_Integrator = t_type

    def addLayer(inout self, t_Layer: Pointer[CBSDFLayer]):
        self.m_Layer.addLayer(t_Layer)
        self.m_Layer.setSolarRadiation(self.m_SolarRadiationInit)

    @staticmethod
    def create(t_Layer: Pointer[CBSDFLayer], t_SolarRadiation: CSeries, t_CommonWavelengths: DynamicVector[Float64]) -> Pointer[CMultiPaneBSDF]:
        var layers = DynamicVector[Pointer[CBSDFLayer]]()
        layers.push_back(t_Layer)
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(layers, t_SolarRadiation, t_CommonWavelengths))
        return ptr

    @staticmethod
    def create(t_Layer: Pointer[CBSDFLayer], t_SolarRadiation: CSeries, t_DetectorData: CSeries, t_CommonWavelengths: DynamicVector[Float64]) -> Pointer[CMultiPaneBSDF]:
        var layers = DynamicVector[Pointer[CBSDFLayer]]()
        layers.push_back(t_Layer)
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(layers, t_SolarRadiation, t_DetectorData, t_CommonWavelengths))
        return ptr

    @staticmethod
    def create(t_Layers: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_CommonWavelengths: DynamicVector[Float64]) -> Pointer[CMultiPaneBSDF]:
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(t_Layers, t_SolarRadiation, t_CommonWavelengths))
        return ptr

    @staticmethod
    def create(t_Layers: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries, t_CommonWavelengths: DynamicVector[Float64]) -> Pointer[CMultiPaneBSDF]:
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(t_Layers, t_SolarRadiation, t_DetectorData, t_CommonWavelengths))
        return ptr

    @staticmethod
    def create(t_Layer: Pointer[CBSDFLayer], t_SolarRadiation: CSeries) -> Pointer[CMultiPaneBSDF]:
        var layers = DynamicVector[Pointer[CBSDFLayer]]()
        layers.push_back(t_Layer)
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(layers, t_SolarRadiation))
        return ptr

    @staticmethod
    def create(t_Layer: Pointer[CBSDFLayer], t_SolarRadiation: CSeries, t_DetectorData: CSeries) -> Pointer[CMultiPaneBSDF]:
        var layers = DynamicVector[Pointer[CBSDFLayer]]()
        layers.push_back(t_Layer)
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(layers, t_SolarRadiation, t_DetectorData))
        return ptr

    @staticmethod
    def create(t_Layers: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries) -> Pointer[CMultiPaneBSDF]:
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(t_Layers, t_SolarRadiation))
        return ptr

    @staticmethod
    def create(t_Layers: DynamicVector[Pointer[CBSDFLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries) -> Pointer[CMultiPaneBSDF]:
        var ptr = Pointer[CMultiPaneBSDF].alloc(1)
        ptr.store(0, CMultiPaneBSDF(t_Layers, t_SolarRadiation, t_DetectorData))
        return ptr

    def getPropertySimple(inout self, minLambda: Float64, maxLambda: Float64, t_Property: PropertySimple, t_Side: Side, t_Scattering: Scattering, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0) -> Float64:
        var result: Float64 = 0.0
        if t_Scattering == Scattering.DirectDirect:
            result = self.DirDir(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi)
        elif t_Scattering == Scattering.DirectDiffuse:
            result = self.DirHem(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi) - self.DirDir(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi)
        elif t_Scattering == Scattering.DirectHemispherical:
            result = self.DirHem(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi)
        elif t_Scattering == Scattering.DiffuseDiffuse:
            result = self.DiffDiff(minLambda, maxLambda, t_Side, t_Property)
        return result

    def getWavelengths(self) -> DynamicVector[Float64]:
        return self.m_Layer.getCommonWavelengths()

    def getMinLambda(self) -> Float64:
        return self.m_Layer.getMinLambda()

    def getMaxLambda(self) -> Float64:
        return self.m_Layer.getMaxLambda()

    def getAbsorptanceLayers(inout self, minLambda: Float64, maxLambda: Float64, side: Side, scattering: ScatteringSimple, theta: Float64 = 0.0, phi: Float64 = 0.0) -> DynamicVector[Float64]:
        var abs = DynamicVector[Float64]()
        var absSize = self.m_Abs[Side.Front].size()
        for i in range(1, absSize + 1):
            if scattering == ScatteringSimple.Direct:
                abs.push_back(self.Abs(minLambda, maxLambda, side, i, theta, phi))
            elif scattering == ScatteringSimple.Diffuse:
                abs.push_back(self.AbsDiff(minLambda, maxLambda, side, i))
        return abs

    def DirDiff(inout self, minLambda: Float64, maxLambda: Float64, t_Side: Side, t_Property: PropertySimple, t_Theta: Float64, t_Phi: Float64) -> Float64:
        return self.DirHem(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi) - self.DirDir(minLambda, maxLambda, t_Side, t_Property, t_Theta, t_Phi)