/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from bsplinebasis.h import BSplineBasis1D
from definitions import *
from mykroneckerproduct import kroneckerProductVectors, myKroneckerProduct
from unsupported.Eigen.KroneckerProduct import kroneckerProduct
from iostream import *
from vector import *
from memory import *

@value
struct BSplineBasis:
    var bases: List[BSplineBasis1D]
    var numVariables: UInt

    def __init__(inout self):
        self.bases = List[BSplineBasis1D]()
        self.numVariables = 0

    def __init__(inout self, knotVectors: List[List[Float64]], basisDegrees: List[UInt]):
        self.numVariables = knotVectors.size
        if knotVectors.size != basisDegrees.size:
            raise Exception("BSplineBasis::BSplineBasis: Incompatible sizes. Number of knot vectors is not equal to size of degree vector.")
        self.bases = List[BSplineBasis1D]()
        for i in range(self.numVariables):
            self.bases.append(BSplineBasis1D(knotVectors[i], basisDegrees[i]))
            if self.numVariables > 2:
                self.bases[i].setNumBasisFunctionsTarget((basisDegrees[i]+1)+1) // Minimum degree+1

    def eval(self, x: DenseVector) -> SparseVector:
        var basisFunctionValues = List[SparseVector]()
        for var in range(x.size):
            basisFunctionValues.append(self.bases[var].eval(x[var]))
        return kroneckerProductVectors(basisFunctionValues)

    def evalBasisJacobianOld(self, x: DenseVector) -> DenseMatrix:
        var J = DenseMatrix()
        J.setZero(self.getNumBasisFunctions(), self.numVariables)
        for i in range(self.numVariables):
            var bi = DenseVector()
            bi.setOnes(1)
            for j in range(self.numVariables):
                var temp = bi
                var xi = DenseVector()
                if j == i:
                    xi = self.bases[j].evalFirstDerivative(x[j])
                else:
                    xi = self.bases[j].eval(x[j])
                bi = kroneckerProduct(temp, xi)
            J.block(0, i, bi.rows(), 1) = bi.block(0, 0, bi.rows(), 1)
        return J

    def evalBasisJacobian(self, x: DenseVector) -> SparseMatrix:
        var J = SparseMatrix(self.getNumBasisFunctions(), self.numVariables)
        for i in range(self.numVariables):
            var values = List[SparseVector](self.numVariables)
            for j in range(self.numVariables):
                if j == i:
                    values[j] = self.bases[j].evalDerivative(x[j], 1)
                else:
                    values[j] = self.bases[j].eval(x[j])
            var Ji = kroneckerProductVectors(values)
            for k in range(Ji.outerSize()):
                for it in Ji.innerIterator(k):
                    if it.value() != 0:
                        J.insert(it.row(), i) = it.value()
        J.makeCompressed()
        return J

    def evalBasisJacobian2(self, x: DenseVector) -> SparseMatrix:
        var J = SparseMatrix(self.getNumBasisFunctions(), self.numVariables)
        var funcValues = List[SparseVector](self.numVariables)
        var gradValues = List[SparseVector](self.numVariables)
        for i in range(self.numVariables):
            funcValues[i] = self.bases[i].eval(x[i])
            gradValues[i] = self.bases[i].evalFirstDerivative(x[i])
        for i in range(self.numVariables):
            var values = List[SparseVector](self.numVariables)
            for j in range(self.numVariables):
                if j == i:
                    values[j] = gradValues[j] // Differentiated basis
                else:
                    values[j] = funcValues[j] // Normal basis
            var Ji = kroneckerProductVectors(values)
            for it in Ji.innerIterator():
                J.insert(it.row(), i) = it.value()
        return J

    def evalBasisHessian(self, x: DenseVector) -> SparseMatrix:
        /* Hij = B1 x ... x DBi x ... x DBj x ... x Bn
         * (Hii = B1 x ... x DDBi x ... x Bn)
         * Where B are basis functions evaluated at x,
         * DB are the derivative of the basis functions,
         * and x is the kronecker product.
         * Hij is in R^(numBasisFunctions x 1)
         * so that basis hessian H is in R^(numBasisFunctions*numInputs x numInputs)
         * The real B-spline Hessian is calculated as (c^T x 1^(numInputs x 1))*H
         */
        var H = SparseMatrix(self.getNumBasisFunctions()*self.numVariables, self.numVariables)
        for i in range(self.numVariables): // row
            for j in range(i+1): // col
                var Hi = SparseMatrix(1, 1)
                Hi.insert(0, 0) = 1
                for k in range(self.numVariables):
                    var temp = Hi
                    var Bk = SparseMatrix()
                    if i == j and k == i:
                        Bk = self.bases[k].evalDerivative(x[k], 2)
                    elif k == i or k == j:
                        Bk = self.bases[k].evalDerivative(x[k], 1)
                    else:
                        Bk = self.bases[k].eval(x[k])
                    Hi = kroneckerProduct(temp, Bk)
                for k in range(Hi.outerSize()):
                    for it in Hi.innerIterator(k):
                        if it.value() != 0:
                            var row = i*self.getNumBasisFunctions()+it.row()
                            var col = j
                            H.insert(row, col) = it.value()
        H.makeCompressed()
        return H

    def insertKnots(self, tau: Float64, dim: UInt, multiplicity: UInt = 1) -> SparseMatrix:
        var A = SparseMatrix(1, 1)
        A.insert(0, 0) = 1
        for i in range(self.numVariables):
            var temp = A
            var Ai = SparseMatrix()
            if i == dim:
                Ai = self.bases[i].insertKnots(tau, multiplicity)
            else:
                var m = self.bases[i].getNumBasisFunctions()
                Ai.resize(m, m)
                Ai.setIdentity()
            A = myKroneckerProduct(temp, Ai)
        A.makeCompressed()
        return A

    def refineKnots(self) -> SparseMatrix:
        var A = SparseMatrix(1, 1)
        A.insert(0, 0) = 1
        for i in range(self.numVariables):
            var temp = A
            var Ai = self.bases[i].refineKnots()
            A = myKroneckerProduct(temp, Ai)
        A.makeCompressed()
        return A

    def refineKnotsLocally(self, x: DenseVector) -> SparseMatrix:
        var A = SparseMatrix(1, 1)
        A.insert(0, 0) = 1
        for i in range(self.numVariables):
            var temp = A
            var Ai = self.bases[i].refineKnotsLocally(x[i])
            A = myKroneckerProduct(temp, Ai)
        A.makeCompressed()
        return A

    def decomposeToBezierForm(self) -> SparseMatrix:
        var A = SparseMatrix(1, 1)
        A.insert(0, 0) = 1
        for i in range(self.numVariables):
            var temp = A
            var Ai = self.bases[i].decomposeToBezierForm()
            A = myKroneckerProduct(temp, Ai)
        A.makeCompressed()
        return A

    def reduceSupport(self, lb: List[Float64], ub: List[Float64]) -> SparseMatrix:
        if lb.size != ub.size or lb.size != self.numVariables:
            raise Exception("BSplineBasis::reduceSupport: Incompatible dimension of domain bounds.")
        var A = SparseMatrix(1, 1)
        A.insert(0, 0) = 1
        for i in range(self.numVariables):
            var temp = A
            var Ai = SparseMatrix()
            Ai = self.bases[i].reduceSupport(lb[i], ub[i])
            A = myKroneckerProduct(temp, Ai)
        A.makeCompressed()
        return A

    def getBasisDegrees(self) -> List[UInt]:
        var degrees = List[UInt]()
        for basis in self.bases:
            degrees.append(basis.getBasisDegree())
        return degrees

    def getBasisDegree(self, dim: UInt) -> UInt:
        return self.bases[dim].getBasisDegree()

    def getNumBasisFunctions(self, dim: UInt) -> UInt:
        return self.bases[dim].getNumBasisFunctions()

    def getNumBasisFunctions(self) -> UInt:
        var prod: UInt = 1
        for dim in range(self.numVariables):
            prod *= self.bases[dim].getNumBasisFunctions()
        return prod

    def getSingleBasis(self, dim: Int) -> BSplineBasis1D:
        return self.bases[dim]

    def getKnotVector(self, dim: Int) -> List[Float64]:
        return self.bases[dim].getKnotVector()

    def getKnotVectors(self) -> List[List[Float64]]:
        var knots = List[List[Float64]]()
        for i in range(self.numVariables):
            knots.append(self.bases[i].getKnotVector())
        return knots

    def getKnotMultiplicity(self, dim: UInt, tau: Float64) -> UInt:
        return self.bases[dim].knotMultiplicity(tau)

    def getKnotValue(self, dim: Int, index: Int) -> Float64:
        return self.bases[dim].getKnotValue(index)

    def getLargestKnotInterval(self, dim: UInt) -> UInt:
        return self.bases[dim].indexLongestInterval()

    def getNumBasisFunctionsTarget(self) -> List[UInt]:
        var ret = List[UInt]()
        for dim in range(self.numVariables):
            ret.append(self.bases[dim].getNumBasisFunctionsTarget())
        return ret

    def supportedPrInterval(self) -> Int:
        var ret: Int = 1
        for dim in range(self.numVariables):
            ret *= (self.bases[dim].getBasisDegree() + 1)
        return ret

    def insideSupport(self, x: DenseVector) -> Bool:
        for dim in range(self.numVariables):
            if not self.bases[dim].insideSupport(x[dim]):
                return False
        return True

    def getSupportLowerBound(self) -> List[Float64]:
        var lb = List[Float64]()
        for dim in range(self.numVariables):
            var knots = self.bases[dim].getKnotVector()
            lb.append(knots.front())
        return lb

    def getSupportUpperBound(self) -> List[Float64]:
        var ub = List[Float64]()
        for dim in range(self.numVariables):
            var knots = self.bases[dim].getKnotVector()
            ub.append(knots.back())
        return ub