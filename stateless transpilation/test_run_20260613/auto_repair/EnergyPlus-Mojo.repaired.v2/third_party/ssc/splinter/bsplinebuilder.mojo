"""
This file is part of the SPLINTER library.
Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""

from datatable import DataTable
from bspline import BSpline
from mykroneckerproduct import *
from unsupported.Eigen.KroneckerProduct import *
from linearsolvers import SparseLU, DenseQR, DenseMatrix, DenseVector
from serializer import *  # Not used but keep import
from utilities import *
from builtin import print
from math import *
from memory import *
from random import *

# Helper functions not present in Mojo stdlib
def linspace(a: Float64, b: Float64, n: Int) -> List[Float64]:
    var step = (b - a) / Float64(max(1, n - 1))
    var result = List[Float64]()
    for i in range(n):
        result.append(a + Float64(i) * step)
    return result

def extract_unique_sorted(values: List[Float64]) -> List[Float64]:
    var unique = List[Float64](values)
    unique.sort()
    var it = unique.begin()
    var write_pos = 0
    for i in range(unique.size):
        if i == 0 or unique[i] != unique[i - 1]:
            unique[write_pos] = unique[i]
            write_pos += 1
    unique.resize(write_pos)
    return unique

def getBSplineDegrees(numVars: Int, degree: Int) -> List[Int]:
    if degree > 5:
        raise Exception("BSpline::Builder: Only degrees in range [0, 5] are supported.")
    var vec = List[Int]()
    vec.resize(numVars, degree)
    return vec

# Enums (equivalent to BSpline::Smoothing and BSpline::KnotSpacing)
enum Smoothing:
    NONE = 0
    IDENTITY = 1
    PSPLINE = 2

enum KnotSpacing:
    AS_SAMPLED = 0
    EQUIDISTANT = 1
    EXPERIMENTAL = 2

# Struct for BSpline::Builder (translated as top-level struct)
struct Builder:
    var _data: DataTable
    var _degrees: List[Int]
    var _numBasisFunctions: List[Int]
    var _knotSpacing: KnotSpacing
    var _smoothing: Smoothing
    var _alpha: Float64

    def __init__(inout self, data: DataTable):
        self._data = data
        self._degrees = getBSplineDegrees(data.getNumVariables(), 3)
        var nVars = data.getNumVariables()
        self._numBasisFunctions = List[Int]()
        self._numBasisFunctions.resize(nVars, 0)
        self._knotSpacing = KnotSpacing.AS_SAMPLED
        self._smoothing = Smoothing.NONE
        self._alpha = 0.1

    def alpha(inout self, alpha: Float64) -> Self:
        if alpha < 0:
            raise Exception("BSpline::Builder::alpha: alpha must be non-negative.")
        self._alpha = alpha
        return self

    def degree(inout self, degree: Int) -> Self:
        self._degrees = getBSplineDegrees(self._data.getNumVariables(), degree)
        return self

    def degree_vector(inout self, degrees: List[Int]) -> Self:
        if degrees.size != self._data.getNumVariables():
            raise Exception("BSpline::Builder: Inconsistent length on degree vector.")
        self._degrees = degrees
        return self

    def numBasisFunctions(inout self, numBasisFunctions: Int) -> Self:
        self._numBasisFunctions = List[Int]()
        self._numBasisFunctions.resize(self._data.getNumVariables(), numBasisFunctions)
        return self

    def numBasisFunctions_vector(inout self, numBasisFunctions: List[Int]) -> Self:
        if numBasisFunctions.size != self._data.getNumVariables():
            raise Exception("BSpline::Builder: Inconsistent length on numBasisFunctions vector.")
        self._numBasisFunctions = numBasisFunctions
        return self

    def knotSpacing(inout self, knotSpacing: KnotSpacing) -> Self:
        self._knotSpacing = knotSpacing
        return self

    def smoothing(inout self, smoothing: Smoothing) -> Self:
        self._smoothing = smoothing
        return self

    def build(self) -> BSpline:
        if not self._data.isGridComplete():
            raise Exception("BSpline::Builder::build: Cannot create B-spline from irregular (incomplete) grid.")
        var knotVectors = self.computeKnotVectors()
        var bspline = BSpline(knotVectors, self._degrees)
        var coefficients = self.computeCoefficients(bspline)
        bspline.setCoefficients(coefficients)
        return bspline

    def computeCoefficients(self, bspline: BSpline) -> DenseVector:
        var B = self.computeBasisFunctionMatrix(bspline)
        var A = B
        var b = self.getSamplePointValues()

        if self._smoothing == Smoothing.IDENTITY:
            var Bt = B.transpose()
            A = Bt * B
            b = Bt * b
            var I = SparseMatrix(A.cols(), A.cols())
            I.setIdentity()
            A += self._alpha * I
        elif self._smoothing == Smoothing.PSPLINE:
            var numSamples = self._data.getNumSamples()
            var Bt = B.transpose()
            var W = SparseMatrix(numSamples, numSamples)
            W.setIdentity()
            var D = self.getSecondOrderFiniteDifferenceMatrix(bspline)
            A = Bt * W * B + self._alpha * D.transpose() * D
            b = Bt * W * b

        var x: DenseVector
        var numEquations = A.rows()
        var maxNumEquations = 100
        var solveAsDense = (numEquations < maxNumEquations)

        if not solveAsDense:
            print("BSpline::Builder::computeBSplineCoefficients: Computing B-spline control points using sparse solver.")
            var s = SparseLU()
            solveAsDense = not s.solve(A, b, x)

        if solveAsDense:
            print("BSpline::Builder::computeBSplineCoefficients: Computing B-spline control points using dense solver.")
            var Ad = A.toDense()
            var s = DenseQR[DenseVector]()
            if not s.solve(Ad, b, x):
                raise Exception("BSpline::Builder::computeBSplineCoefficients: Failed to solve for B-spline coefficients.")

        return x

    def computeBasisFunctionMatrix(self, bspline: BSpline) -> SparseMatrix:
        var numVariables = self._data.getNumVariables()
        var numSamples = self._data.getNumSamples()
        var A = SparseMatrix(numSamples, bspline.getNumBasisFunctions())
        var i = 0
        for it in self._data.cbegin() to self._data.cend():
            var xi = DenseVector(numVariables)
            xi.setZero()
            var xv = it.getX()
            for j in range(numVariables):
                xi(j) = xv[j]
            var basisValues = bspline.evalBasis(xi)
            for it2 in basisValues.innerIterator():
                A.insert(i, it2.index()) = it2.value()
            i += 1
        A.makeCompressed()
        return A

    def getSamplePointValues(self) -> DenseVector:
        var B = DenseVector.Zero(self._data.getNumSamples())
        var i = 0
        for it in self._data.cbegin() to self._data.cend():
            B(i) = it.getY()
            i += 1
        return B

    def getSecondOrderFiniteDifferenceMatrix(self, bspline: BSpline) -> SparseMatrix:
        var numVariables = bspline.getNumVariables()
        var numCols = bspline.getNumBasisFunctions()
        var numBasisFunctions = bspline.getNumBasisFunctionsPerVariable()
        var dims = List[Int]()
        for i in range(numVariables):
            dims.append(numBasisFunctions[i])
        dims.reverse()
        for i in range(numVariables):
            if numBasisFunctions[i] < 3:
                raise Exception("BSpline::Builder::getSecondOrderDifferenceMatrix: Need at least three coefficients/basis function per variable.")
        var numRows = 0
        var numBlkRows = List[Int]()
        for i in range(numVariables):
            var prod = 1
            for j in range(numVariables):
                if i == j:
                    prod *= (dims[j] - 2)
                else:
                    prod *= dims[j]
            numRows += prod
            numBlkRows.append(prod)
        var D = SparseMatrix(numRows, numCols)
        D.reserve(DenseVector.Constant(numCols, 2 * numVariables))
        var i = 0
        for d in range(numVariables):
            var leftProd = 1
            var rightProd = 1
            for k in range(d):
                leftProd *= dims[k]
            for k in range(d + 1, numVariables):
                rightProd *= dims[k]
            for j in range(rightProd):
                var blkBaseCol = j * leftProd * dims[d]
                for l in range(dims[d] - 2):
                    if d == 0:
                        var k = j * leftProd * dims[d] + l
                        D.insert(i, k) = 1.0
                        k += leftProd
                        D.insert(i, k) = -2.0
                        k += leftProd
                        D.insert(i, k) = 1.0
                        i += 1
                    else:
                        for n in range(leftProd):
                            var k = blkBaseCol + l * leftProd + n
                            D.insert(i, k) = 1.0
                            k += leftProd
                            D.insert(i, k) = -2.0
                            k += leftProd
                            D.insert(i, k) = 1.0
                            i += 1
        D.makeCompressed()
        return D

    def computeKnotVectors(self) -> List[List[Float64]]:
        if self._data.getNumVariables() != self._degrees.size:
            raise Exception("BSpline::Builder::computeKnotVectors: Inconsistent sizes on input vectors.")
        var grid = self._data.getTableX()
        var knotVectors = List[List[Float64]]()
        for i in range(self._data.getNumVariables()):
            var knotVec = self.computeKnotVector(grid[i], self._degrees[i], self._numBasisFunctions[i])
            knotVectors.append(knotVec)
        return knotVectors

    def computeKnotVector(self, values: List[Float64], degree: Int, numBasisFunctions: Int) -> List[Float64]:
        if self._knotSpacing == KnotSpacing.AS_SAMPLED:
            return self.knotVectorMovingAverage(values, degree)
        elif self._knotSpacing == KnotSpacing.EQUIDISTANT:
            return self.knotVectorEquidistant(values, degree, numBasisFunctions)
        elif self._knotSpacing == KnotSpacing.EXPERIMENTAL:
            return self.knotVectorBuckets(values, degree)
        else:
            return self.knotVectorMovingAverage(values, degree)

    def knotVectorMovingAverage(self, values: List[Float64], degree: Int) -> List[Float64]:
        var unique = extract_unique_sorted(values)
        var n = unique.size
        var k = degree - 1
        var w = k + 3
        if n < degree + 1:
            var e = String("knotVectorMovingAverage: Only ") + str(n) + String(" unique interpolation points are given. A minimum of degree+1 = ") + str(degree + 1) + String(" unique points are required to build a B-spline basis of degree ") + str(degree) + String(".")
            raise Exception(e)
        var knots = List[Float64]()
        for i in range(n - k - 2):
            var ma = 0.0
            for j in range(w):
                ma += unique[i + j]
            knots.append(ma / Float64(w))
        for i in range(degree + 1):
            knots.insert(0, unique.front())
        for i in range(degree + 1):
            knots.append(unique.back())
        return knots

    def knotVectorEquidistant(self, values: List[Float64], degree: Int, numBasisFunctions: Int = 0) -> List[Float64]:
        var unique = extract_unique_sorted(values)
        var n = unique.size
        if numBasisFunctions > 0:
            n = numBasisFunctions
        var k = degree - 1
        if n < degree + 1:
            var e = String("knotVectorMovingAverage: Only ") + str(n) + String(" unique interpolation points are given. A minimum of degree+1 = ") + str(degree + 1) + String(" unique points are required to build a B-spline basis of degree ") + str(degree) + String(".")
            raise Exception(e)
        var numIntKnots = n - k - 2
        if numIntKnots < 0:
            numIntKnots = 0
        if numIntKnots > 10:
            numIntKnots = 10
        var knots = linspace(unique.front(), unique.back(), numIntKnots)
        for i in range(degree):
            knots.insert(0, unique.front())
        for i in range(degree):
            knots.append(unique.back())
        return knots

    def knotVectorBuckets(self, values: List[Float64], degree: Int, maxSegments: Int = 10) -> List[Float64]:
        var unique = extract_unique_sorted(values)
        if unique.size < degree + 1:
            var e = String("BSpline::Builder::knotVectorBuckets: Only ") + str(unique.size) + String(" unique sample points are given. A minimum of degree+1 = ") + str(degree + 1) + String(" unique points are required to build a B-spline basis of degree ") + str(degree) + String(".")
            raise Exception(e)
        var ni = unique.size - degree - 1
        var ns = ni + degree + 1
        if ns > maxSegments and maxSegments >= degree + 1:
            ns = maxSegments
            ni = ns - degree - 1
        if ni > unique.size - degree - 1:
            raise Exception("BSpline::Builder::knotVectorBuckets: Invalid number of internal knots!")
        var w: Int = 0
        if ni > 0:
            w = unique.size // ni
        var res = unique.size - w * ni
        var windows = List[Int]()
        for i in range(ni):
            windows.append(w)
        for i in range(res):
            windows[i] += 1
        var knots = List[Float64]()
        for i in range(ni):
            knots.append(0.0)
        var index = 0
        for i in range(ni):
            for j in range(windows[i]):
                knots[i] += unique[index + j]
            knots[i] /= Float64(windows[i])
            index += windows[i]
        for i in range(degree + 1):
            knots.insert(0, unique.front())
        for i in range(degree + 1):
            knots.append(unique.back())
        return knots

    def extractUniqueSorted(self, values: List[Float64]) -> List[Float64]:
        return extract_unique_sorted(values)