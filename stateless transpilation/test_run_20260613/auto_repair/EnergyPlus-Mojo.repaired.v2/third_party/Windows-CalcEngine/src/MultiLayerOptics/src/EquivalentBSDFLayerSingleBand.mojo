from WCECommon import SquareMatrix, Side, PropertySimple, EnumSide
from WCESingleLayerOptics import CBSDFIntegrator
from memory import Pointer
from utils import Vector, Map, make_shared

@value
struct CInterReflectance:
    var m_InterRefl: SquareMatrix

    def __init__(inout self, t_Lambda: SquareMatrix, t_Rb: SquareMatrix, t_Rf: SquareMatrix):
        var size = t_Lambda.size()
        var lRb = t_Lambda * t_Rb
        var lRf = t_Lambda * t_Rf
        self.m_InterRefl = lRb * lRf
        var I = SquareMatrix(size)
        I.setIdentity()
        self.m_InterRefl = I - self.m_InterRefl
        self.m_InterRefl = self.m_InterRefl.inverse()

    def value(self) -> SquareMatrix:
        return self.m_InterRefl

@value
struct CBSDFDoubleLayer:
    var m_Results: Pointer[CBSDFIntegrator]
    var m_Tf: SquareMatrix
    var m_Tb: SquareMatrix
    var m_Rf: SquareMatrix
    var m_Rb: SquareMatrix

    def __init__(inout self, t_FrontLayer: CBSDFIntegrator, t_BackLayer: CBSDFIntegrator):
        var aLambda = t_FrontLayer.lambdaMatrix()
        var InterRefl1 = CInterReflectance(aLambda,
                                           t_FrontLayer.at(Side.Back, PropertySimple.R),
                                           t_BackLayer.at(Side.Front, PropertySimple.R))
        var InterRefl2 = CInterReflectance(aLambda,
                                           t_BackLayer.at(Side.Front, PropertySimple.R),
                                           t_FrontLayer.at(Side.Back, PropertySimple.R))
        self.m_Tf = CBSDFDoubleLayer.equivalentT(t_BackLayer.at(Side.Front, PropertySimple.T),
                                                 InterRefl1.value(),
                                                 aLambda,
                                                 t_FrontLayer.at(Side.Front, PropertySimple.T))
        self.m_Tb = CBSDFDoubleLayer.equivalentT(t_FrontLayer.at(Side.Back, PropertySimple.T),
                                                 InterRefl2.value(),
                                                 aLambda,
                                                 t_BackLayer.at(Side.Back, PropertySimple.T))
        self.m_Rf = CBSDFDoubleLayer.equivalentR(t_FrontLayer.at(Side.Front, PropertySimple.R),
                                                 t_FrontLayer.at(Side.Front, PropertySimple.T),
                                                 t_FrontLayer.at(Side.Back, PropertySimple.T),
                                                 t_BackLayer.at(Side.Front, PropertySimple.R),
                                                 InterRefl2.value(),
                                                 aLambda)
        self.m_Rb = CBSDFDoubleLayer.equivalentR(t_BackLayer.at(Side.Back, PropertySimple.R),
                                                 t_BackLayer.at(Side.Back, PropertySimple.T),
                                                 t_BackLayer.at(Side.Front, PropertySimple.T),
                                                 t_FrontLayer.at(Side.Back, PropertySimple.R),
                                                 InterRefl1.value(),
                                                 aLambda)
        self.m_Results = make_shared[CBSDFIntegrator](t_FrontLayer)
        self.m_Results.setResultMatrices(self.m_Tf, self.m_Rf, Side.Front)
        self.m_Results.setResultMatrices(self.m_Tb, self.m_Rb, Side.Back)

    def value(self) -> Pointer[CBSDFIntegrator]:
        return self.m_Results

    @staticmethod
    def equivalentT(t_Tf2: SquareMatrix, t_InterRefl: SquareMatrix, t_Lambda: SquareMatrix, t_Tf1: SquareMatrix) -> SquareMatrix:
        var TinterRefl = t_Tf2 * t_InterRefl
        var lambdaTf1 = t_Lambda * t_Tf1
        return TinterRefl * lambdaTf1

    @staticmethod
    def equivalentR(t_Rf1: SquareMatrix, t_Tf1: SquareMatrix, t_Tb1: SquareMatrix, t_Rf2: SquareMatrix, t_InterRefl: SquareMatrix, t_Lambda: SquareMatrix) -> SquareMatrix:
        var TinterRefl = t_Tb1 * t_InterRefl
        var lambdaRf2 = t_Lambda * t_Rf2
        var lambdaTf1 = t_Lambda * t_Tf1
        TinterRefl = TinterRefl * lambdaRf2
        TinterRefl = TinterRefl * lambdaTf1
        return t_Rf1 + TinterRefl

@value
struct CEquivalentBSDFLayerSingleBand:
    var m_EquivalentLayer: Pointer[CBSDFIntegrator]
    var m_Layers: Vector[Pointer[CBSDFIntegrator]]
    var m_Forward: Vector[Pointer[CBSDFIntegrator]]
    var m_Backward: Vector[Pointer[CBSDFIntegrator]]
    var m_A: Map[Side, Vector[Vector[Float64]]]
    var m_PropertiesCalculated: Bool
    var m_Lambda: SquareMatrix

    def __init__(inout self, t_Layer: Pointer[CBSDFIntegrator]):
        self.m_PropertiesCalculated = False
        self.m_EquivalentLayer = make_shared[CBSDFIntegrator](t_Layer)
        for aSide in EnumSide():
            self.m_A[aSide] = Vector[Vector[Float64]]()
        self.m_Layers.push_back(t_Layer)
        self.m_Lambda = t_Layer.lambdaMatrix()

    def getMatrix(self, t_Side: Side, t_Property: PropertySimple) -> SquareMatrix:
        self.calcEquivalentProperties()
        return self.m_EquivalentLayer.getMatrix(t_Side, t_Property)

    def getProperty(self, t_Side: Side, t_Property: PropertySimple) -> SquareMatrix:
        return self.getMatrix(t_Side, t_Property)

    def getLayerAbsorptances(self, Index: Int, t_Side: Side) -> Vector[Float64]:
        self.calcEquivalentProperties()
        return self.m_A[t_Side][Index - 1]

    def getNumberOfLayers(self) -> Int:
        return self.m_Layers.size()

    def addLayer(inout self, t_Layer: Pointer[CBSDFIntegrator]):
        self.m_Layers.push_back(t_Layer)
        self.m_PropertiesCalculated = False
        for aSide in EnumSide():
            self.m_A[aSide].clear()

    def calcEquivalentProperties(inout self):
        if self.m_PropertiesCalculated:
            return
        var size = self.m_Layers.size()
        self.m_EquivalentLayer = self.m_Layers[0]
        self.m_Forward.push_back(self.m_EquivalentLayer)
        for i in range(1, size):
            self.m_EquivalentLayer = CBSDFDoubleLayer(self.m_EquivalentLayer[], self.m_Layers[i][]).value()
            self.m_Forward.push_back(self.m_EquivalentLayer)
        self.m_Backward.push_back(self.m_EquivalentLayer)
        var bLayer: Pointer[CBSDFIntegrator] = self.m_Layers[size - 1]
        for i in range(size - 1, 1, -1):
            bLayer = CBSDFDoubleLayer(self.m_Layers[i - 1][], bLayer[]).value()
            self.m_Backward.push_back(bLayer)
        self.m_Backward.push_back(self.m_Layers[size - 1])
        var matrixSize = self.m_Lambda.size()
        var zeros = Vector[Float64](matrixSize, 0.0)
        var Ap1f: Vector[Float64]
        var Ap2f: Vector[Float64]
        var Ap1b: Vector[Float64]
        var Ap2b: Vector[Float64]
        for i in range(size):
            if i == size - 1:
                Ap2f = zeros
                Ap1b = self.m_Layers[i].Abs(Side.Back)
            else:
                var Layer1 = self.m_Backward[i + 1][]
                var Layer2 = self.m_Forward[i][]
                var InterRefl2 = CInterReflectance(self.m_Lambda,
                                                   Layer1.at(Side.Front, PropertySimple.R),
                                                   Layer2.at(Side.Back, PropertySimple.R))
                var Ab = self.m_Layers[i].Abs(Side.Back)
                Ap1b = self.absTerm1(Ab, InterRefl2.value(), Layer1.getMatrix(Side.Back, PropertySimple.T))
                Ap2f = self.absTerm2(Ab,
                                     InterRefl2.value(),
                                     Layer1.getMatrix(Side.Front, PropertySimple.R),
                                     Layer2.getMatrix(Side.Front, PropertySimple.T))
            if i == 0:
                Ap1f = self.m_Layers[i].Abs(Side.Front)
                Ap2b = zeros
            else:
                var Layer1 = self.m_Forward[i - 1][]
                var Layer2 = self.m_Backward[i][]
                var InterRefl1 = CInterReflectance(self.m_Lambda,
                                                   Layer1.at(Side.Back, PropertySimple.R),
                                                   Layer2.at(Side.Front, PropertySimple.R))
                var Af = self.m_Layers[i].Abs(Side.Front)
                Ap1f = self.absTerm1(Af, InterRefl1.value(), Layer1.at(Side.Front, PropertySimple.T))
                Ap2b = self.absTerm2(Af,
                                     InterRefl1.value(),
                                     Layer1.at(Side.Back, PropertySimple.R),
                                     Layer2.at(Side.Back, PropertySimple.T))
            var aTotal: Map[Side, Vector[Float64]]
            for aSide in EnumSide():
                aTotal[aSide] = Vector[Float64]()
            for j in range(matrixSize):
                aTotal[Side.Front].push_back(Ap1f[j] + Ap2f[j])
                aTotal[Side.Back].push_back(Ap1b[j] + Ap2b[j])
            for aSide in EnumSide():
                self.m_A[aSide].push_back(aTotal[aSide])
        self.m_PropertiesCalculated = True

    def absTerm1(self, t_Alpha: Vector[Float64], t_InterRefl: SquareMatrix, t_T: SquareMatrix) -> Vector[Float64]:
        var part1 = t_Alpha * t_InterRefl
        var part2 = self.m_Lambda * t_T
        part1 = part1 * part2
        return part1

    def absTerm2(self, t_Alpha: Vector[Float64], t_InterRefl: SquareMatrix, t_R: SquareMatrix, t_T: SquareMatrix) -> Vector[Float64]:
        var part1 = t_Alpha * t_InterRefl
        var part2 = self.m_Lambda * t_R
        var part3 = self.m_Lambda * t_T
        part1 = part1 * part2
        part1 = part1 * part3
        return part1