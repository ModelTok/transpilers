"""
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
from function import Function
from bsplinebasis import BSplineBasis
from mykroneckerproduct import kroneckerProduct
from linearsolvers import *
from serializer import Serializer
from utilities import *
from memory import DenseVector, DenseMatrix, SparseVector, SparseMatrix
from python import Python
from sys import Exception

@value
class BSpline(Function):
    enum class Smoothing:

    enum class KnotSpacing:

    def __init__(self):
        Function.__init__(self, 1)

    def __init__(self, numVariables: UInt):
        Function.__init__(self, numVariables)

    """
    * Constructors for multivariate B-spline using data
    """
    def __init__(self, knotVectors: List[List[Float64]], basisDegrees: List[UInt]):
        Function.__init__(self, knotVectors.size())
        self.basis = BSplineBasis(knotVectors, basisDegrees)
        self.coefficients = DenseVector.Zero(1)
        self.knotaverages = self.computeKnotAverages()
        self.setCoefficients(DenseVector.Ones(self.basis.getNumBasisFunctions()))
        self.checkControlPoints()

    def __init__(self, coefficients: List[Float64], knotVectors: List[List[Float64]], basisDegrees: List[UInt]):
        self = BSpline(vectorToDenseVector(coefficients), knotVectors, basisDegrees)

    def __init__(self, coefficients: DenseVector, knotVectors: List[List[Float64]], basisDegrees: List[UInt]):
        Function.__init__(self, knotVectors.size())
        self.basis = BSplineBasis(knotVectors, basisDegrees)
        self.coefficients = coefficients
        self.knotaverages = self.computeKnotAverages()
        self.setCoefficients(coefficients)
        self.checkControlPoints()

    """
    * Construct from saved data
    """
    def __init__(self, fileName: StringRef):
        Function.__init__(self, 1)
        self.load(fileName)

    """
    * Returns the function value at x
    """
    def eval(self, x: DenseVector) -> Float64:
        self.checkInput(x)
        var res: DenseVector = self.coefficients.transpose() * self.evalBasis(x)
        return res[0]

    """
    * Returns the (1 x numVariables) Jacobian evaluated at x
    """
    def evalJacobian(self, x: DenseVector) -> DenseMatrix:
        self.checkInput(x)
        return self.coefficients.transpose() * self.evalBasisJacobian(x)

    """
    * Returns the Hessian evaluated at x.
    * The Hessian is an n x n matrix,
    * where n is the dimension of x.
    """
    def evalHessian(self, x: DenseVector) -> DenseMatrix:
        self.checkInput(x)
        #ifndef NDEBUG
        #if !self.pointInDomain(x):
        #    raise Exception("BSpline::evalHessian: Evaluation at point outside domain.")
        #endif // NDEBUG
        var H: DenseMatrix = DenseMatrix.Zero(1, 1)
        var identity: DenseMatrix = DenseMatrix.Identity(self.numVariables, self.numVariables)
        var caug: DenseMatrix = kroneckerProduct(identity, self.coefficients.transpose())
        var DB: DenseMatrix = self.basis.evalBasisHessian(x)
        H = caug * DB
        for i in range(self.numVariables):
            for j in range(i + 1, self.numVariables):
                H[i, j] = H[j, i]
        return H

    def evalBasis(self, x: DenseVector) -> SparseVector:
        #ifndef NDEBUG
        #if !self.pointInDomain(x):
        #    raise Exception("BSpline::evalBasis: Evaluation at point outside domain.")
        #endif // NDEBUG
        return self.basis.eval(x)

    def evalBasisJacobian(self, x: DenseVector) -> SparseMatrix:
        #ifndef NDEBUG
        #if !self.pointInDomain(x):
        #    raise Exception("BSpline::evalBasisJacobian: Evaluation at point outside domain.")
        #endif // NDEBUG
        var Bi: DenseMatrix = self.basis.evalBasisJacobianOld(x)  # Old Jacobian implementation
        return Bi.sparseView()

    def getNumBasisFunctionsPerVariable(self) -> List[UInt]:
        var ret: List[UInt] = List[UInt]()
        for i in range(self.numVariables):
            ret.append(self.basis.getNumBasisFunctions(i))
        return ret

    def getNumBasisFunctions(self) -> UInt:
        return self.basis.getNumBasisFunctions()

    def getKnotVectors(self) -> List[List[Float64]]:
        return self.basis.getKnotVectors()

    def getBasisDegrees(self) -> List[UInt]:
        return self.basis.getBasisDegrees()

    def getDomainUpperBound(self) -> List[Float64]:
        return self.basis.getSupportUpperBound()

    def getDomainLowerBound(self) -> List[Float64]:
        return self.basis.getSupportLowerBound()

    def getControlPoints(self) -> DenseMatrix:
        var nc: Int = self.coefficients.size()
        var controlPoints: DenseMatrix = DenseMatrix.Zero(nc, self.numVariables + 1)
        controlPoints.block(0, 0, nc, self.numVariables) = self.knotaverages
        controlPoints.block(0, self.numVariables, nc, 1) = self.coefficients
        return controlPoints

    def getNumCoefficients(self) -> UInt:
        return UInt(self.coefficients.size())

    def getNumControlPoints(self) -> UInt:
        return UInt(self.coefficients.size())

    def setCoefficients(self, coefficients: DenseVector):
        if coefficients.size() != self.getNumBasisFunctions():
            raise Exception("BSpline::setControlPoints: Incompatible size of coefficient vector.")
        self.coefficients = coefficients
        self.checkControlPoints()

    def setControlPoints(self, controlPoints: DenseMatrix):
        if controlPoints.cols() != self.numVariables + 1:
            raise Exception("BSpline::setControlPoints: Incompatible size of control point matrix.")
        var nc: Int = controlPoints.rows()
        self.knotaverages = controlPoints.block(0, 0, nc, self.numVariables)
        self.coefficients = controlPoints.block(0, self.numVariables, nc, 1)
        self.checkControlPoints()

    def updateControlPoints(self, A: DenseMatrix):
        if A.cols() != self.coefficients.rows() or A.cols() != self.knotaverages.rows():
            raise Exception("BSpline::updateControlPoints: Incompatible size of linear transformation matrix.")
        self.coefficients = A * self.coefficients
        self.knotaverages = A * self.knotaverages

    def checkControlPoints(self):
        if self.coefficients.rows() != self.knotaverages.rows():
            raise Exception("BSpline::checkControlPoints: Inconsistent size of coefficients and knot averages matrices.")
        if self.knotaverages.cols() != self.numVariables:
            raise Exception("BSpline::checkControlPoints: Inconsistent size of knot averages matrix.")

    def pointInDomain(self, x: DenseVector) -> Bool:
        return self.basis.insideSupport(x)

    def reduceSupport(self, lb: List[Float64], ub: List[Float64], doRegularizeKnotVectors: Bool = True):
        if lb.size() != self.numVariables or ub.size() != self.numVariables:
            raise Exception("BSpline::reduceSupport: Inconsistent vector sizes!")
        var sl: List[Float64] = self.basis.getSupportLowerBound()
        var su: List[Float64] = self.basis.getSupportUpperBound()
        for dim in range(self.numVariables):
            if ub[dim] <= lb[dim] or lb[dim] >= su[dim] or ub[dim] <= sl[dim]:
                raise Exception("BSpline::reduceSupport: Cannot reduce B-spline domain to empty set!")
            if su[dim] < ub[dim] or sl[dim] > lb[dim]:
                raise Exception("BSpline::reduceSupport: Cannot expand B-spline domain!")
            sl[dim] = lb[dim]
            su[dim] = ub[dim]
        if doRegularizeKnotVectors:
            self.regularizeKnotVectors(sl, su)
        if not self.removeUnsupportedBasisFunctions(sl, su):
            raise Exception("BSpline::reduceSupport: Failed to remove unsupported basis functions!")

    def globalKnotRefinement(self):
        var A: SparseMatrix = self.basis.refineKnots()
        self.updateControlPoints(A)

    def localKnotRefinement(self, x: DenseVector):
        var A: SparseMatrix = self.basis.refineKnotsLocally(x)
        self.updateControlPoints(A)

    def decomposeToBezierForm(self):
        var A: SparseMatrix = self.basis.decomposeToBezierForm()
        self.updateControlPoints(A)

    def computeKnotAverages(self) -> DenseMatrix:
        var mu_vectors: List[DenseVector] = List[DenseVector]()
        for i in range(self.numVariables):
            var knots: List[Float64] = self.basis.getKnotVector(i)
            var mu: DenseVector = DenseVector.Zero(self.basis.getNumBasisFunctions(i))
            for j in range(self.basis.getNumBasisFunctions(i)):
                var knotAvg: Float64 = 0.0
                for k in range(j + 1, j + self.basis.getBasisDegree(i) + 1):
                    knotAvg += knots[k]
                mu[j] = knotAvg / Float64(self.basis.getBasisDegree(i))
            mu_vectors.append(mu)

        var knotOnes: List[DenseVector] = List[DenseVector]()
        for i in range(self.numVariables):
            knotOnes.append(DenseVector.Ones(mu_vectors[i].rows()))

        var knot_averages: DenseMatrix = DenseMatrix.Zero(self.basis.getNumBasisFunctions(), self.numVariables)
        for i in range(self.numVariables):
            var mu_ext: DenseMatrix = DenseMatrix.Zero(1, 1)
            mu_ext[0, 0] = 1.0
            for j in range(self.numVariables):
                var temp: DenseMatrix = mu_ext
                if i == j:
                    mu_ext = Eigen.kroneckerProduct(temp, mu_vectors[j])
                else:
                    mu_ext = Eigen.kroneckerProduct(temp, knotOnes[j])
            if mu_ext.rows() != self.basis.getNumBasisFunctions():
                raise Exception("BSpline::computeKnotAverages: Incompatible size of knot average matrix.")
            knot_averages.block(0, i, self.basis.getNumBasisFunctions(), 1) = mu_ext
        return knot_averages

    def insertKnots(self, tau: Float64, dim: UInt, multiplicity: UInt = 1):
        var A: SparseMatrix = self.basis.insertKnots(tau, dim, multiplicity)
        self.updateControlPoints(A)

    def regularizeKnotVectors(self, lb: List[Float64], ub: List[Float64]):
        if not (lb.size() == self.numVariables and ub.size() == self.numVariables):
            raise Exception("BSpline::regularizeKnotVectors: Inconsistent vector sizes.")
        for dim in range(self.numVariables):
            var multiplicityTarget: UInt = self.basis.getBasisDegree(dim) + 1
            var numKnotsLB: Int = Int(multiplicityTarget) - self.basis.getKnotMultiplicity(dim, lb[dim])
            if numKnotsLB > 0:
                self.insertKnots(lb[dim], dim, UInt(numKnotsLB))
            var numKnotsUB: Int = Int(multiplicityTarget) - self.basis.getKnotMultiplicity(dim, ub[dim])
            if numKnotsUB > 0:
                self.insertKnots(ub[dim], dim, UInt(numKnotsUB))

    def removeUnsupportedBasisFunctions(self, lb: List[Float64], ub: List[Float64]) -> Bool:
        if lb.size() != self.numVariables or ub.size() != self.numVariables:
            raise Exception("BSpline::removeUnsupportedBasisFunctions: Incompatible dimension of domain bounds.")
        var A: SparseMatrix = self.basis.reduceSupport(lb, ub)
        if self.coefficients.size() != A.rows():
            return False
        self.updateControlPoints(A.transpose())
        return True

    def save(self, fileName: StringRef):
        var s: Serializer = Serializer()
        s.serialize(self)
        s.saveToFile(fileName)

    def load(self, fileName: StringRef):
        var s: Serializer = Serializer(fileName)
        s.deserialize(self)

    def getDescription(self) -> String:
        var description: String = String("BSpline of degree")
        var degrees: List[UInt] = self.getBasisDegrees()
        var equal: Bool = True
        for i in range(1, degrees.size()):
            equal = equal and (degrees[i] == degrees[i - 1])
        if equal:
            description.append(" ")
            description.append(String(degrees[0]))
        else:
            description.append("s (")
            for i in range(degrees.size()):
                description.append(String(degrees[i]))
                if i + 1 < degrees.size():
                    description.append(", ")
            description.append(")")
        return description

    def clone(self) -> BSpline:
        return BSpline(self)