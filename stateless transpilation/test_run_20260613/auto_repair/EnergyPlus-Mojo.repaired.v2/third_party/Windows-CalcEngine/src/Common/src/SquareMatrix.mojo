from memory.unsafe import Pointer
from math import abs
from utils import Vector as std_vector
from utils import InitializerList as std_initializer_list
from SquareMatrix import SquareMatrix

@value
struct SquareMatrix:
    var m_size: UInt
    var m_Matrix: std_vector[std_vector[Float64]]

    def __init__(inout self, tSize: UInt = 0):
        self.m_size = tSize
        self.m_Matrix = std_vector[std_vector[Float64]](tSize, std_vector[Float64](tSize, 0.0))

    def __init__(inout self, tInput: std_initializer_list[std_vector[Float64]]):
        self.m_size = tInput.size()
        self.m_Matrix = std_vector[std_vector[Float64]](self.m_size, std_vector[Float64](self.m_size, 0.0))
        var i: UInt = 0
        for vec in tInput:
            for j in range(vec.size()):
                self.m_Matrix[i][j] = vec[j]
            i += 1

    def __init__(inout self, tInput: std_vector[std_vector[Float64]]):
        self.m_size = tInput.size()
        self.m_Matrix = tInput

    def __init__(inout self, tInput: std_vector[std_vector[Float64]]):
        self.m_size = tInput.size()
        self.m_Matrix = tInput

    def size(self) -> UInt:
        return self.m_size

    def setZeros(inout self):
        self.m_Matrix.assign(self.m_size, std_vector[Float64](self.m_size, 0.0))

    def setIdentity(inout self):
        self.setZeros()
        for i in range(self.m_size):
            self.m_Matrix[i][i] = 1.0

    def setDiagonal(inout self, tInput: std_vector[Float64]):
        if tInput.size() != self.m_size:
            raise Error("Matrix and vector must be same size.")
        self.setZeros()
        for i in range(self.m_size):
            self.m_Matrix[i][i] = tInput[i]

    def inverse(self) -> SquareMatrix:
        var aLu = self.LU()
        var invMat = SquareMatrix(self.m_size)
        var d = std_vector[Float64](self.m_size)
        var y = std_vector[Float64](self.m_size)
        var size = self.m_size - 1
        for m in range(size + 1):
            for i in range(d.size()):
                d[i] = 0.0
            for i in range(y.size()):
                y[i] = 0.0
            d[m] = 1.0
            for i in range(size + 1):
                var x: Float64 = 0.0
                for j in range(i):
                    x = x + aLu(UInt(i), UInt(j)) * y[j]
                y[i] = (d[i] - x)
            for i in range(Int(size), -1, -1):
                var x: Float64 = 0.0
                for j in range(i + 1, Int(size) + 1):
                    x = x + aLu(UInt(i), UInt(j)) * invMat(UInt(j), UInt(m))
                invMat(UInt(i), UInt(m)) = (y[i] - x) / aLu(UInt(i), UInt(i))
        return invMat

    def __call__(self, i: UInt, j: UInt) -> Float64:
        return self.m_Matrix[i][j]

    def __call__(inout self, i: UInt, j: UInt) -> Float64:
        return self.m_Matrix[i][j]

    def LU(self) -> SquareMatrix:
        var D = SquareMatrix(self.m_Matrix)
        for k in range(self.m_size - 1):
            for j in range(k + 1, self.m_size):
                var x = D(j, k) / D(k, k)
                for i in range(k, self.m_size):
                    D(j, i) = D(j, i) - x * D(k, i)
                D(j, k) = x
        return D

    def checkSingularity(self) -> std_vector[Float64]:
        var vv = std_vector[Float64]()
        for i in range(self.m_size):
            var aamax: Float64 = 0.0
            for j in range(self.m_size):
                var absCellValue = abs(self.m_Matrix[i][j])
                if absCellValue > aamax:
                    aamax = absCellValue
            if aamax == 0.0:
                debug_assert(aamax != 0.0, "Singular matrix")
            vv.push_back(1.0 / aamax)
        return vv

    def makeUpperTriangular(inout self) -> std_vector[UInt]:
        var TINY: Float64 = 1e-20
        var index = std_vector[UInt](self.m_size)
        var vv = self.checkSingularity()
        var d: Int = 1
        for j in range(self.m_size):
            for i in range(Int(j)):
                var sum = self.m_Matrix[i][j]
                for k in range(i):
                    sum = sum - self.m_Matrix[i][k] * self.m_Matrix[k][j]
                self.m_Matrix[i][j] = sum
            var aamax: Float64 = 0.0
            var imax: Int = 0
            for i in range(j, self.m_size):
                var sum = self.m_Matrix[i][j]
                for k in range(Int(j)):
                    sum = sum - self.m_Matrix[i][k] * self.m_Matrix[k][j]
                self.m_Matrix[i][j] = sum
                var dum = vv[i] * abs(sum)
                if dum >= aamax:
                    imax = i
                    aamax = dum
            if Int(j) != imax:
                for k in range(self.m_size):
                    var dum = self.m_Matrix[imax][k]
                    self.m_Matrix[imax][k] = self.m_Matrix[j][k]
                    self.m_Matrix[j][k] = dum
                d = -d
                vv[imax] = vv[j]
            index[j] = imax
            if self.m_Matrix[j][j] == 0.0:
                self.m_Matrix[j][j] = TINY
            if j != (self.m_size - 1):
                var dum = 1.0 / self.m_Matrix[j][j]
                for i in range(j + 1, self.m_size):
                    self.m_Matrix[i][j] = self.m_Matrix[i][j] * dum
        return index

    def mmultRows(self, tInput: std_vector[Float64]) -> SquareMatrix:
        if self.m_size != tInput.size():
            raise Error("Vector and matrix do not have same size.")
        var res = SquareMatrix(self.m_size)
        for i in range(self.m_size):
            for j in range(self.m_size):
                res(j, i) = self.m_Matrix[j][i] * tInput[i]
        return res

    def getMatrix(self) -> std_vector[std_vector[Float64]]:
        return self.m_Matrix

def __mul__(first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    if first.size() != second.size():
        raise Error("Matrices must be identical in size.")
    var aMatrix = SquareMatrix(first.size())
    for i in range(aMatrix.size()):
        for k in range(aMatrix.size()):
            for j in range(aMatrix.size()):
                aMatrix(i, j) += first(i, k) * second(k, j)
    return aMatrix

def __imul__(inout first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    first = first * second
    return first

def __add__(first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    if first.size() != second.size():
        raise Error("Matrices must be identical in size.")
    var aMatrix = SquareMatrix(first.size())
    for i in range(aMatrix.size()):
        for j in range(aMatrix.size()):
            aMatrix(i, j) = first(i, j) + second(i, j)
    return aMatrix

def __iadd__(inout first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    first = first + second
    return first

def __sub__(first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    if first.size() != second.size():
        raise Error("Matrices must be identical in size.")
    var aMatrix = SquareMatrix(first.size())
    for i in range(aMatrix.size()):
        for j in range(aMatrix.size()):
            aMatrix(i, j) = first(i, j) - second(i, j)
    return aMatrix

def __isub__(inout first: SquareMatrix, second: SquareMatrix) -> SquareMatrix:
    first = first - second
    return first

def __mul__(first: std_vector[Float64], second: SquareMatrix) -> std_vector[Float64]:
    if first.size() != second.size():
        raise Error("Vector and matrix do not have same size.")
    var res = std_vector[Float64](first.size(), 0.0)
    for i in range(first.size()):
        for j in range(first.size()):
            res[i] += first[j] * second(j, i)
    return res

def __mul__(first: SquareMatrix, second: std_vector[Float64]) -> std_vector[Float64]:
    if first.size() != second.size():
        raise Error("Vector and matrix do not have same size.")
    var res = std_vector[Float64](second.size(), 0.0)
    for i in range(second.size()):
        for j in range(second.size()):
            res[i] += second[j] * first(i, j)
    return res