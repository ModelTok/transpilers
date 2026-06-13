from LinearSolver import CLinearSolver
from SquareMatrix import SquareMatrix
from memory import Pointer
from math import isclose
from sys import info

@staticmethod
def solveSystem(t_MatrixA: SquareMatrix, t_VectorB: List[Float64]) -> List[Float64]:
    if t_MatrixA.size() != len(t_VectorB):
        raise Error("Matrix and vector for system of linear equations are not same size.")
    var index: List[Int] = t_MatrixA.makeUpperTriangular()
    var size: Int = t_MatrixA.size()
    var ii: Int = -1
    for i in range(size):
        var ll: Int = index[i]
        var sum: Float64 = t_VectorB[ll]
        t_VectorB[ll] = t_VectorB[i]
        if ii != -1:
            for j in range(ii, i):
                sum -= t_MatrixA[i][j] * t_VectorB[j]
        elif not isclose(sum, 0.0):
            ii = i
        t_VectorB[i] = sum
    for i in range(size - 1, -1, -1):
        var sum: Float64 = t_VectorB[i]
        for j in range(i + 1, size):
            sum -= t_MatrixA[i][j] * t_VectorB[j]
        t_VectorB[i] = sum / t_MatrixA[i][i]
    return t_VectorB