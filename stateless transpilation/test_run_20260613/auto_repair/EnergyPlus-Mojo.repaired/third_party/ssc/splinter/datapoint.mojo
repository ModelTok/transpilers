/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from definitions import *
from datapoint.h import *
from math import sqrt

@value
struct DataPoint:
    var x: List[Float64]
    var y: Float64

    def __init__(inout self):

    def __init__(inout self, x: Float64, y: Float64):
        self.setData(List[Float64](1, x), y)

    def __init__(inout self, x: List[Float64], y: Float64):
        self.setData(x, y)

    def __init__(inout self, x: DenseVector, y: Float64):
        var newX = List[Float64]()
        for i in range(x.size()):
            newX.append(x[i])
        self.setData(newX, y)

    def __lt__(self, rhs: DataPoint) -> Bool:
        if self.getDimX() != rhs.getDimX():
            raise Error("DataPoint::operator<: Cannot compare data points of different dimensions")
        for i in range(self.getDimX()):
            if self.x[i] < rhs.getX()[i]:
                return True
            elif self.x[i] > rhs.getX()[i]:
                return False
        return False

    def getX(self) -> List[Float64]:
        return self.x

    def getY(self) -> Float64:
        return self.y

    def getDimX(self) -> UInt:
        return len(self.x)

    def setData(inout self, x: List[Float64], y: Float64):
        self.x = x
        self.y = y

def dist(x: List[Float64], y: List[Float64]) -> Float64:
    if len(x) != len(y):
        raise Error("DataPoint::dist: Cannot measure distance between two points of different dimension")
    var sum: Float64 = 0.0
    for i in range(len(x)):
        sum += (x[i] - y[i]) * (x[i] - y[i])
    return sqrt(sum)

def dist(x: DataPoint, y: DataPoint) -> Float64:
    return dist(x.getX(), y.getX())

def dist_sort(x: DataPoint, y: DataPoint) -> Bool:
    var zeros = List[Float64](x.getDimX(), 0)
    var origin = DataPoint(zeros, 0.0)
    var x_dist = dist(x, origin)
    var y_dist = dist(y, origin)
    return (x_dist < y_dist)