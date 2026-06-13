/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from definitions import *
from saveable import Saveable
from utilities import vectorToDenseVector, denseVectorToVector, denseMatrixToVectorVector, vectorVectorToDenseMatrix
from Exception import Exception

@value
struct SPLINTER_API:

trait Function(Saveable):
    var numVariables: UInt

    def __init__(inout self):
        self.numVariables = 1

    def __init__(inout self, numVariables: UInt):
        self.numVariables = numVariables

    def __del__(owned self):

    def eval(self, x: DenseVector) -> Float64:
        ...

    def eval(self, x: List[Float64]) -> Float64:
        var denseX = vectorToDenseVector(x)
        return self.eval(denseX)

    def evalJacobian(self, x: DenseVector) -> DenseMatrix:
        return self.centralDifference(x)

    def evalJacobian(self, x: List[Float64]) -> List[Float64]:
        var denseX = vectorToDenseVector(x)
        return denseVectorToVector(self.evalJacobian(denseX))

    def evalHessian(self, x: DenseVector) -> DenseMatrix:
        var vec = denseVectorToVector(x)
        var hessian = self.evalHessian(vec)
        return vectorVectorToDenseMatrix(hessian)

    def evalHessian(self, x: List[Float64]) -> List[List[Float64]]:
        var denseX = vectorToDenseVector(x)
        return denseMatrixToVectorVector(self.secondOrderCentralDifference(denseX))

    def getNumVariables(self) -> UInt:
        return self.numVariables

    def checkInput(self, x: DenseVector):
        if x.size() != self.numVariables:
            raise Exception("Function::checkInput: Wrong dimension on evaluation point x.")

    def centralDifference(self, x: List[Float64]) -> List[Float64]:
        var denseX = vectorToDenseVector(x)
        var dx = self.centralDifference(denseX)
        return denseVectorToVector(dx)

    def centralDifference(self, x: DenseVector) -> DenseMatrix:
        var dx = DenseMatrix(1, x.size())
        var h: Float64 = 1e-6
        var hForward: Float64 = 0.5 * h
        var hBackward: Float64 = 0.5 * h
        for i in range(self.getNumVariables()):
            var xForward = DenseVector(x)
            xForward[i] = xForward[i] + hForward
            var xBackward = DenseVector(x)
            xBackward[i] = xBackward[i] - hBackward
            var yForward: Float64 = self.eval(xForward)
            var yBackward: Float64 = self.eval(xBackward)
            dx[0, i] = (yForward - yBackward) / (hBackward + hForward)
        return dx

    def secondOrderCentralDifference(self, x: List[Float64]) -> List[List[Float64]]:
        var denseX = vectorToDenseVector(x)
        var ddx = self.secondOrderCentralDifference(denseX)
        return denseMatrixToVectorVector(ddx)

    def secondOrderCentralDifference(self, x: DenseVector) -> DenseMatrix:
        var ddx = DenseMatrix(self.getNumVariables(), self.getNumVariables())
        var h: Float64 = 1e-6
        var hForward: Float64 = 0.5 * h
        var hBackward: Float64 = 0.5 * h
        for i in range(self.getNumVariables()):
            for j in range(self.getNumVariables()):
                var x0 = DenseVector(x)
                var x1 = DenseVector(x)
                var x2 = DenseVector(x)
                var x3 = DenseVector(x)
                x0[i] = x0[i] + hForward
                x0[j] = x0[j] + hForward
                x1[i] = x1[i] - hBackward
                x1[j] = x1[j] + hForward
                x2[i] = x2[i] + hForward
                x2[j] = x2[j] - hBackward
                x3[i] = x3[i] - hBackward
                x3[j] = x3[j] - hBackward
                ddx[i, j] = (self.eval(x0) - self.eval(x1) - self.eval(x2) + self.eval(x3)) / (h * h)
        return ddx

    def getDescription(self) -> String:
        return ""