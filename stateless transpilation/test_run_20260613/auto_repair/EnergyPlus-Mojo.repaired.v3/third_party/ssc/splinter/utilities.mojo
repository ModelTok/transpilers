/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from definitions import *
from utils import *
from memory import *
from random import *
from math import *

struct SPLINTER:

def assertNear[T: AnyType](x: T, y: T, tolAbs: Float64 = 1e-8, tolRel: Float64 = 1e-8) -> Bool:
    var dx: Float64 = abs(x - y)
    var xAbs: Float64 = 0.5 * (abs(x) + abs(y))
    var err: Float64 = max(tolAbs, tolRel * xAbs)
    return dx < err

def denseVectorToVector(denseVec: DenseVector) -> List[Float64]:
    var vec = List[Float64](denseVec.size())
    for i in range(denseVec.size()):
        vec[i] = denseVec[i]
    return vec

def vectorToDenseVector(vec: List[Float64]) -> DenseVector:
    var denseVec = DenseVector(len(vec))
    for i in range(len(vec)):
        denseVec[i] = vec[i]
    return denseVec

def denseMatrixToVectorVector(mat: DenseMatrix) -> List[List[Float64]]:
    var vec = List[List[Float64]](mat.rows())
    for i in range(mat.rows()):
        for j in range(mat.cols()):
            vec[i].append(mat[i, j])
    return vec

def vectorVectorToDenseMatrix(vec: List[List[Float64]]) -> DenseMatrix:
    var numRows: Int = len(vec)
    var numCols: Int = numRows > 0 ? len(vec[0]) : 0
    var mat = DenseMatrix(numRows, numCols)
    for i in range(numRows):
        for j in range(numCols):
            mat[i, j] = vec[i][j]
    return mat

def linspace(start: Float64, stop: Float64, num: UInt32) -> List[Float64]:
    var ret = List[Float64]()
    var dx: Float64 = 0.0
    if num > 1:
        dx = (stop - start) / (num - 1)
    for i in range(num):
        ret.append(start + i * dx)
    return ret