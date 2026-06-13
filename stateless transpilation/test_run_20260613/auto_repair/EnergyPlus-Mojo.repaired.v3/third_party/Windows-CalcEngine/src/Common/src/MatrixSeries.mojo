from SquareMatrix import SquareMatrix
from Series import CSeries
from IntegratorStrategy import IntegrationType
from memory import Pointer
from utils import Vector
from utils import assert as c_assert

struct CMatrixSeries:
    var m_Matrix: Vector[Vector[CSeries]]
    var m_Size1: Int
    var m_Size2: Int

    def __init__(inout self, t_Size1: Int, t_Size2: Int):
        self.m_Size1 = t_Size1
        self.m_Size2 = t_Size2
        self.m_Matrix = Vector[Vector[CSeries]](self.m_Size1)
        for i in range(self.m_Size1):
            self.m_Matrix[i] = Vector[CSeries](self.m_Size2)
            for j in range(self.m_Size2):
                self.m_Matrix[i][j] = CSeries()

    def __copyinit__(inout self, other: CMatrixSeries):
        self = other

    def __moveinit__(inout self, owned other: CMatrixSeries):
        self.m_Size1 = other.m_Size1
        self.m_Size2 = other.m_Size2
        self.m_Matrix = other.m_Matrix^
        other.m_Size1 = 0
        other.m_Size2 = 0

    def __del__(owned self):

    def __assign__(inout self, t_MatrixSeries: CMatrixSeries) -> CMatrixSeries:
        self.m_Size1 = t_MatrixSeries.m_Size1
        self.m_Size2 = t_MatrixSeries.m_Size2
        self.m_Matrix = Vector[Vector[CSeries]](self.m_Size1)
        for i in range(self.m_Size1):
            self.m_Matrix[i] = Vector[CSeries](self.m_Size2)
            for j in range(self.m_Size2):
                self.m_Matrix[i][j] = CSeries(t_MatrixSeries.m_Matrix[i][j])
        return self

    def addProperty(inout self, i: Int, j: Int, t_Wavelength: Float64, t_Value: Float64):
        self.m_Matrix[i][j].addProperty(t_Wavelength, t_Value)

    def addProperties(inout self, i: Int, t_Wavelength: Float64, t_Values: Vector[Float64]):
        for j in range(t_Values.size):
            self.m_Matrix[i][j].addProperty(t_Wavelength, t_Values[j])

    def addProperties(inout self, t_Wavelength: Float64, inout t_Matrix: SquareMatrix):
        for i in range(self.m_Matrix.size):
            c_assert(self.m_Matrix.size == t_Matrix.size())
            for j in range(self.m_Matrix[i].size):
                self.m_Matrix[i][j].addProperty(t_Wavelength, t_Matrix[i, j])

    def mMult(inout self, t_Series: CSeries):
        for i in range(self.m_Matrix.size):
            for j in range(self.m_Matrix[i].size):
                c_assert(t_Series.size() == self.m_Matrix[i][j].size())
                self.m_Matrix[i][j] = self.m_Matrix[i][j] * t_Series

    def mMult(inout self, t_Series: Vector[CSeries]):
        for i in range(self.m_Matrix.size):
            for j in range(self.m_Matrix[i].size):
                self.m_Matrix[i][j] = self.m_Matrix[i][j] * t_Series[i]

    def __getitem__(inout self, index: Int) -> Vector[CSeries]:
        return self.m_Matrix[index]

    def integrate(inout self, t_Integration: IntegrationType, normalizationCoefficient: Float64):
        for i in range(self.m_Matrix.size):
            for j in range(self.m_Matrix[i].size):
                self.m_Matrix[i][j] = self.m_Matrix[i][j].integrate(t_Integration, normalizationCoefficient)[]

    def getSums(self, minLambda: Float64, maxLambda: Float64, t_ScaleValue: Vector[Float64]) -> Vector[Vector[Float64]]:
        var Result = Vector[Vector[Float64]](self.m_Matrix.size)
        for i in range(self.m_Matrix.size):
            if self.m_Matrix[i].size != t_ScaleValue.size:
                raise Error("Size of vector for scaling must be same as size of the matrix.")
            for j in range(self.m_Matrix[i].size):
                var value = self.m_Matrix[i][j].sum(minLambda, maxLambda) / t_ScaleValue[i]
                Result[i].push_back(value)
        return Result

    def getSquaredMatrixSums(self, minLambda: Float64, maxLambda: Float64, t_ScaleValue: Vector[Float64]) -> SquareMatrix:
        c_assert(self.m_Matrix.size == self.m_Matrix[0].size)
        var Res = SquareMatrix(self.m_Matrix.size)
        for i in range(self.m_Matrix.size):
            for j in range(self.m_Matrix[i].size):
                var value = self.m_Matrix[i][j].sum(minLambda, maxLambda) / t_ScaleValue[i]
                Res[i, j] = value
        return Res

    def size1(self) -> Int:
        return self.m_Size1

    def size2(self) -> Int:
        return self.m_Size2