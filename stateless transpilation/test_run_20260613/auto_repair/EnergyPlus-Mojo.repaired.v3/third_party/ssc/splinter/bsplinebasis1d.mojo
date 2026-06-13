/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from definitions import SparseVector, SparseMatrix, DenseMatrix
from knots import isKnotVectorRegular, isKnotVectorRefinement
from utilities import assertNear
from math import gamma, nextafter
from bisect import bisect_left, bisect_right

namespace SPLINTER:

    class BSplineBasis1D:
        var degree: UInt
        var knots: List[Float64]
        var targetNumBasisfunctions: UInt

        def __init__(self):

        def __init__(self, knots: List[Float64], degree: UInt):
            self.degree = degree
            self.knots = knots
            self.targetNumBasisfunctions = (degree + 1) + 2 * degree + 1  # Minimum p+1
            if not isKnotVectorRegular(knots, degree):
                raise Error("BSplineBasis1D::BSplineBasis1D: Knot vector is not regular.")

        def eval(self, x: Float64) -> SparseVector:
            var values = SparseVector(self.getNumBasisFunctions())
            if not self.insideSupport(x):
                return values
            self.supportHack(x)
            var indexSupported = self.indexSupportedBasisfunctions(x)
            values.reserve(len(indexSupported))
            for it in indexSupported:
                var val = self.deBoorCox(x, it, self.degree)
                if abs(val) > 1e-12:
                    values.insert(it) = val
            return values

        def evalDerivative(self, x: Float64, r: Int) -> SparseVector:
            var p = self.degree
            if p <= r:
                var DB = SparseVector(self.getNumBasisFunctions())
                return DB
            self.supportHack(x)
            var knotIndex = self.indexHalfopenInterval(x)
            var B = SparseMatrix(1, 1)
            B.insert(0, 0) = 1
            for i in range(1, p - r + 1):
                var R = self.buildBasisMatrix(x, knotIndex, i)
                B = B * R
            for i in range(p - r + 1, p + 1):
                var DR = self.buildBasisMatrix(x, knotIndex, i, True)
                B = B * DR
            var factorial = gamma(p + 1) / gamma(p - r + 1)
            B = B * factorial
            if B.cols() != p + 1:
                raise Error("BSplineBasis1D::evalDerivative: Wrong number of columns of B matrix.")
            var DB = SparseVector(self.getNumBasisFunctions())
            DB.reserve(p + 1)
            var i = knotIndex - p  # First insertion index
            for k in range(B.outerSize()):
                for it in B.innerIterator(k):
                    DB.insert(i + it.col()) = it.value()
            return DB

        def evalFirstDerivative(self, x: Float64) -> SparseVector:
            var values = SparseVector(self.getNumBasisFunctions())
            self.supportHack(x)
            var supportedBasisFunctions = self.indexSupportedBasisfunctions(x)
            for i in supportedBasisFunctions:
                var b1 = self.deBoorCox(x, i, self.degree - 1)
                var b2 = self.deBoorCox(x, i + 1, self.degree - 1)
                var t11 = self.knots[i]
                var t12 = self.knots[i + self.degree]
                var t21 = self.knots[i + 1]
                var t22 = self.knots[i + self.degree + 1]
                if t12 == t11:
                    b1 = 0
                else:
                    b1 = b1 / (t12 - t11)
                if t22 == t21:
                    b2 = 0
                else:
                    b2 = b2 / (t22 - t21)
                values.insert(i) = self.degree * (b1 - b2)
            return values

        def buildBasisMatrix(self, x: Float64, u: UInt, k: UInt, diff: Bool = False) -> SparseMatrix:
            """ Build B-spline Matrix
             * R_k in R^(k,k+1)
             * or, if diff = true, the differentiated basis matrix
             * DR_k in R^(k,k+1)
             """
            if not (k >= 1 and k <= self.getBasisDegree()):
                raise Error("BSplineBasis1D::buildBasisMatrix: Incorrect input paramaters!")
            var rows = k
            var cols = k + 1
            var R = SparseMatrix(rows, cols)
            R.reserve([2] * cols)
            for i in range(rows):
                var dk = self.knots[u + 1 + i] - self.knots[u + 1 + i - k]
                if dk == 0:
                    continue
                else:
                    if diff:
                        R.insert(i, i) = -1 / dk
                        R.insert(i, i + 1) = 1 / dk
                    else:
                        var a = (self.knots[u + 1 + i] - x) / dk
                        if a != 0:
                            R.insert(i, i) = a
                        var b = (x - self.knots[u + 1 + i - k]) / dk
                        if b != 0:
                            R.insert(i, i + 1) = b
            R.makeCompressed()
            return R

        def deBoorCox(self, x: Float64, i: Int, k: Int) -> Float64:
            if k == 0:
                if self.inHalfopenInterval(x, self.knots[i], self.knots[i + 1]):
                    return 1
                else:
                    return 0
            else:
                var s1: Float64
                var s2: Float64
                var r1: Float64
                var r2: Float64
                s1 = self.deBoorCoxCoeff(x, self.knots[i], self.knots[i + k])
                s2 = self.deBoorCoxCoeff(x, self.knots[i + 1], self.knots[i + k + 1])
                r1 = self.deBoorCox(x, i, k - 1)
                r2 = self.deBoorCox(x, i + 1, k - 1)
                return s1 * r1 + (1 - s2) * r2

        def deBoorCoxCoeff(self, x: Float64, x_min: Float64, x_max: Float64) -> Float64:
            if x_min < x_max and x_min <= x and x <= x_max:
                return (x - x_min) / (x_max - x_min)
            return 0

        def insertKnots(self, tau: Float64, multiplicity: UInt = 1) -> SparseMatrix:
            if not self.insideSupport(tau):
                raise Error("BSplineBasis1D::insertKnots: Cannot insert knot outside domain!")
            if self.knotMultiplicity(tau) + multiplicity > self.degree + 1:
                raise Error("BSplineBasis1D::insertKnots: Knot multiplicity is too high!")
            var index = self.indexHalfopenInterval(tau)
            var extKnots = self.knots
            for i in range(multiplicity):
                extKnots.insert(extKnots.begin() + index + 1, tau)
            if not isKnotVectorRegular(extKnots, self.degree):
                raise Error("BSplineBasis1D::insertKnots: New knot vector is not regular!")
            var A = self.buildKnotInsertionMatrix(extKnots)
            self.knots = extKnots
            return A

        def refineKnots(self) -> SparseMatrix:
            var refinedKnots = self.knots
            var targetNumKnots = self.targetNumBasisfunctions + self.degree + 1
            while len(refinedKnots) < targetNumKnots:
                var index = self.indexLongestInterval(refinedKnots)
                var newKnot = (refinedKnots[index] + refinedKnots[index + 1]) / 2.0
                refinedKnots.insert(bisect_left(refinedKnots, newKnot), newKnot)
            if not isKnotVectorRegular(refinedKnots, self.degree):
                raise Error("BSplineBasis1D::refineKnots: New knot vector is not regular!")
            if not isKnotVectorRefinement(self.knots, refinedKnots):
                raise Error("BSplineBasis1D::refineKnots: New knot vector is not a proper refinement!")
            var A = self.buildKnotInsertionMatrix(refinedKnots)
            self.knots = refinedKnots
            return A

        def refineKnotsLocally(self, x: Float64) -> SparseMatrix:
            if not self.insideSupport(x):
                raise Error("BSplineBasis1D::refineKnotsLocally: Cannot refine outside support!")
            if self.getNumBasisFunctions() >= self.getNumBasisFunctionsTarget() or assertNear(self.knots.front(), self.knots.back()):
                var n = self.getNumBasisFunctions()
                var A = DenseMatrix.Identity(n, n)
                return A.sparseView()
            var refinedKnots = self.knots
            var upper = bisect_left(refinedKnots, x)
            if upper == 0:
                upper = self.degree + 1
            var lower = upper - 1
            if assertNear(refinedKnots[upper], refinedKnots[lower]):
                var n = self.getNumBasisFunctions()
                var A = DenseMatrix.Identity(n, n)
                return A.sparseView()
            var insertVal = x
            if self.knotMultiplicity(x) > 0 or assertNear(refinedKnots[upper], x, 1e-6, 1e-6) or assertNear(refinedKnots[lower], x, 1e-6, 1e-6):
                insertVal = (refinedKnots[upper] + refinedKnots[lower]) / 2.0
            refinedKnots.insert(upper, insertVal)
            if not isKnotVectorRegular(refinedKnots, self.degree):
                raise Error("BSplineBasis1D::refineKnotsLocally: New knot vector is not regular!")
            if not isKnotVectorRefinement(self.knots, refinedKnots):
                raise Error("BSplineBasis1D::refineKnotsLocally: New knot vector is not a proper refinement!")
            var A = self.buildKnotInsertionMatrix(refinedKnots)
            self.knots = refinedKnots
            return A

        def decomposeToBezierForm(self) -> SparseMatrix:
            var refinedKnots = self.knots
            var knoti = 0
            while knoti < len(refinedKnots):
                var mult = self.degree + 1 - self.knotMultiplicity(refinedKnots[knoti])
                if mult > 0:
                    var newKnots = [refinedKnots[knoti]] * mult
                    for nk in newKnots:
                        refinedKnots.insert(knoti, nk)
                knoti = bisect_right(refinedKnots, refinedKnots[knoti])
            if not isKnotVectorRegular(refinedKnots, self.degree):
                raise Error("BSplineBasis1D::refineKnots: New knot vector is not regular!")
            if not isKnotVectorRefinement(self.knots, refinedKnots):
                raise Error("BSplineBasis1D::refineKnots: New knot vector is not a proper refinement!")
            var A = self.buildKnotInsertionMatrix(refinedKnots)
            self.knots = refinedKnots
            return A

        def buildKnotInsertionMatrix(self, refinedKnots: List[Float64]) -> SparseMatrix:
            if not isKnotVectorRegular(refinedKnots, self.degree):
                raise Error("BSplineBasis1D::buildKnotInsertionMatrix: New knot vector is not regular!")
            if not isKnotVectorRefinement(self.knots, refinedKnots):
                raise Error("BSplineBasis1D::buildKnotInsertionMatrix: New knot vector is not a proper refinement!")
            var knotsAug = refinedKnots
            var n = len(self.knots) - self.degree - 1
            var m = len(knotsAug) - self.degree - 1
            var A = SparseMatrix(m, n)
            A.reserve([self.degree + 1] * n)
            for i in range(m):
                var u = self.indexHalfopenInterval(knotsAug[i])
                var R = SparseMatrix(1, 1)
                R.insert(0, 0) = 1
                for j in range(1, self.degree + 1):
                    var Ri = self.buildBasisMatrix(knotsAug[i + j], u, j)
                    R = R * Ri
                if R.rows() != 1 or R.cols() != self.degree + 1:
                    raise Error("BSplineBasis1D::buildKnotInsertionMatrix: Incorrect matrix dimensions!")
                var j = u - self.degree  # First insertion index
                for k in range(R.outerSize()):
                    for it in R.innerIterator(k):
                        A.insert(i, j + it.col()) = it.value()
            A.makeCompressed()
            return A

        def supportHack(self, x: inout Float64):
            if x == self.knots.back():
                x = nextafter(x, Float64.lowest)

        def indexHalfopenInterval(self, x: Float64) -> Int:
            if x < self.knots.front() or x > self.knots.back():
                raise Error("BSplineBasis1D::indexHalfopenInterval: x outside knot interval!")
            var it = bisect_right(self.knots, x)
            var index = it
            return index - 1

        def reduceSupport(self, lb: Float64, ub: Float64) -> SparseMatrix:
            if lb < self.knots.front() or ub > self.knots.back():
                raise Error("BSplineBasis1D::reduceSupport: Cannot increase support!")
            var k = self.degree + 1
            var index_lower = self.indexSupportedBasisfunctions(lb).front()
            var index_upper = self.indexSupportedBasisfunctions(ub).back()
            if k != self.knotMultiplicity(self.knots[index_lower]):
                var suggested_index = index_lower - 1
                if 0 <= suggested_index:
                    index_lower = suggested_index
                else:
                    raise Error("BSplineBasis1D::reduceSupport: Suggested index is negative!")
            if self.knotMultiplicity(ub) == k and self.knots[index_upper] == ub:
                index_upper -= k
            var si: List[Float64] = []
            si.insert(si.begin(), self.knots.begin() + index_lower, self.knots.begin() + index_upper + k + 1)
            var numOld = len(self.knots) - k  # Current number of basis functions
            var numNew = len(si) - k  # Number of basis functions after update
            if numOld < numNew:
                raise Error("BSplineBasis1D::reduceSupport: Number of basis functions is increased instead of reduced!")
            var Ad = DenseMatrix.Zero(numOld, numNew)
            Ad.block(index_lower, 0, numNew, numNew) = DenseMatrix.Identity(numNew, numNew)
            var A = Ad.sparseView()
            self.knots = si
            return A

        def getKnotValue(self, index: UInt) -> Float64:
            return self.knots[index]

        def knotMultiplicity(self, tau: Float64) -> UInt:
            return self.knots.count(tau)

        def inHalfopenInterval(self, x: Float64, x_min: Float64, x_max: Float64) -> Bool:
            return (x_min <= x) and (x < x_max)

        def insideSupport(self, x: Float64) -> Bool:
            return (self.knots.front() <= x) and (x <= self.knots.back())

        def getNumBasisFunctions(self) -> UInt:
            return len(self.knots) - (self.degree + 1)

        def getNumBasisFunctionsTarget(self) -> UInt:
            return self.targetNumBasisfunctions

        def indexSupportedBasisfunctions(self, x: Float64) -> List[Int]:
            var ret: List[Int] = []
            if self.insideSupport(x):
                var last = self.indexHalfopenInterval(x)
                if last < 0:
                    last = len(self.knots) - 1 - (self.degree + 1)
                var first = max(last - self.degree, 0)
                for i in range(first, last + 1):
                    ret.append(i)
            return ret

        def indexLongestInterval(self) -> UInt:
            return self.indexLongestInterval(self.knots)

        def indexLongestInterval(self, vec: List[Float64]) -> UInt:
            var longest = 0.0
            var interval = 0.0
            var index: UInt = 0
            for i in range(len(vec) - 1):
                interval = vec[i + 1] - vec[i]
                if longest < interval:
                    longest = interval
                    index = i
            return index

        def setNumBasisFunctionsTarget(self, target: UInt):
            self.targetNumBasisfunctions = max(self.degree + 1, target)

        def getBasisDegree(self) -> UInt:
            return self.degree

        def getKnotVector(self) -> List[Float64]:
            return self.knots