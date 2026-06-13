from BSDFIntegrator import CBSDFIntegrator
from BSDFDirections import CBSDFDirections
from BSDFPatch import BSDFPatch
from WCECommon import SquareMatrix, Side, PropertySimple, EnumSide, EnumPropertySimple, ConstantsData, mmap

@value
struct CBSDFIntegrator:
    var m_Directions: CBSDFDirections
    var m_DimMatrices: size_t
    var m_Matrix: Map[pair_Side_PropertySimple, SquareMatrix]
    var m_Hem: Map[pair_Side_PropertySimple, std.vector[float64]]
    var m_Abs: Map[Side, std.vector[float64]]
    var m_HemisphericalCalculated: bool
    var m_DiffuseDiffuseCalculated: bool
    var m_MapDiffDiff: mmap[float64, Side, PropertySimple]

    def __init__(inout self, t_Integrator: std.shared_ptr[CBSDFIntegrator]):
        self.m_Directions = t_Integrator.m_Directions
        self.m_DimMatrices = self.m_Directions.size()
        self.m_HemisphericalCalculated = False
        self.m_DiffuseDiffuseCalculated = False
        for t_Side in EnumSide():
            for t_Property in EnumPropertySimple():
                self.m_Matrix[std.make_pair(t_Side, t_Property)] = SquareMatrix(self.m_DimMatrices)
                self.m_Hem[std.make_pair(t_Side, t_Property)] = std.vector[float64](self.m_DimMatrices)

    def __init__(inout self, t_Directions: CBSDFDirections):
        self.m_Directions = t_Directions
        self.m_DimMatrices = self.m_Directions.size()
        self.m_HemisphericalCalculated = False
        self.m_DiffuseDiffuseCalculated = False
        for t_Side in EnumSide():
            for t_Property in EnumPropertySimple():
                self.m_Matrix[std.make_pair(t_Side, t_Property)] = SquareMatrix(self.m_DimMatrices)
                self.m_Hem[std.make_pair(t_Side, t_Property)] = std.vector[float64](self.m_DimMatrices)

    def DiffDiff(inout self, t_Side: Side, t_Property: PropertySimple) -> float64:
        self.calcDiffuseDiffuse()
        return self.m_MapDiffDiff.at(t_Side, t_Property)

    def getMatrix(inout self, t_Side: Side, t_Property: PropertySimple) -> SquareMatrix:
        return self.m_Matrix[std.make_pair(t_Side, t_Property)]

    def at(self, t_Side: Side, t_Property: PropertySimple) -> SquareMatrix:
        return self.m_Matrix.at(std.make_pair(t_Side, t_Property))

    def setResultMatrices(inout self, t_Tau: SquareMatrix, t_Rho: SquareMatrix, t_Side: Side):
        self.m_Matrix[std.make_pair(t_Side, PropertySimple.T)] = t_Tau
        self.m_Matrix[std.make_pair(t_Side, PropertySimple.R)] = t_Rho

    def DirDir(self, t_Side: Side, t_Property: PropertySimple, t_Theta: float64 = 0, t_Phi: float64 = 0) -> float64:
        var index = self.m_Directions.getNearestBeamIndex(t_Theta, t_Phi)
        var lambda = self.m_Directions.lambdaVector()[index]
        var tau = self.at(t_Side, t_Property)(index, index)
        return tau * lambda

    def DirDir(self, t_Side: Side, t_Property: PropertySimple, Index: size_t) -> float64:
        var lambda = self.m_Directions.lambdaVector()[Index]
        var tau = self.at(t_Side, t_Property)(Index, Index)
        return tau * lambda

    def DirHem(inout self, t_Side: Side, t_Property: PropertySimple) -> std.vector[float64]:
        self.calcHemispherical()
        return self.m_Hem.at(std.make_pair(t_Side, t_Property))

    def Abs(inout self, t_Side: Side) -> std.vector[float64]:
        self.calcHemispherical()
        return self.m_Abs.at(t_Side)

    def DirHem(inout self, t_Side: Side, t_Property: PropertySimple, t_Theta: float64, t_Phi: float64) -> float64:
        var index = self.m_Directions.getNearestBeamIndex(t_Theta, t_Phi)
        return self.DirHem(t_Side, t_Property)[index]

    def Abs(inout self, t_Side: Side, t_Theta: float64, t_Phi: float64) -> float64:
        var index = self.m_Directions.getNearestBeamIndex(t_Theta, t_Phi)
        return self.Abs(t_Side)[index]

    def Abs(inout self, t_Side: Side, Index: size_t) -> float64:
        return self.Abs(t_Side)[Index]

    def lambdaVector(self) -> std.vector[float64]:
        return self.m_Directions.lambdaVector()

    def lambdaMatrix(self) -> SquareMatrix:
        return self.m_Directions.lambdaMatrix()

    def integrate(self, t_Matrix: SquareMatrix) -> float64:
        var sum: float64 = 0
        for i in range(self.m_DimMatrices):
            for j in range(self.m_DimMatrices):
                sum += t_Matrix(i, j) * self.m_Directions[i].lambda() * self.m_Directions[j].lambda()
        return sum / ConstantsData.WCE_PI

    def calcDiffuseDiffuse(inout self):
        if not self.m_DiffuseDiffuseCalculated:
            for t_Side in EnumSide():
                for t_Property in EnumPropertySimple():
                    self.m_MapDiffDiff(t_Side, t_Property) = self.integrate(self.getMatrix(t_Side, t_Property))
            self.m_DiffuseDiffuseCalculated = True

    def getNearestBeamIndex(self, t_Theta: float64, t_Phi: float64) -> size_t:
        return self.m_Directions.getNearestBeamIndex(t_Theta, t_Phi)

    def calcHemispherical(inout self):
        if not self.m_HemisphericalCalculated:
            for t_Side in EnumSide():
                for t_Property in EnumPropertySimple():
                    self.m_Hem[std.make_pair(t_Side, t_Property)] = self.m_Directions.lambdaVector() * self.m_Matrix.at(std.make_pair(t_Side, t_Property))
                self.m_Abs[t_Side] = std.vector[float64]()
            var size = self.m_Hem[std.make_pair(Side.Front, PropertySimple.T)].size()
            for i in range(size):
                for t_Side in EnumSide():
                    self.m_Abs.at(t_Side).push_back(1.0 - self.m_Hem.at(std.make_pair(t_Side, PropertySimple.T))[i] - self.m_Hem.at(std.make_pair(t_Side, PropertySimple.R))[i])
            self.m_HemisphericalCalculated = True

    def AbsDiffDiff(inout self, t_Side: Side) -> float64:
        return 1 - self.DiffDiff(t_Side, PropertySimple.T) - self.DiffDiff(t_Side, PropertySimple.R)