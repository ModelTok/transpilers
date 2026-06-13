/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from serializer import Serializer, DataPoint, DataTable, BSpline, BSplineBasis, BSplineBasis1D, DenseMatrix, DenseVector, SparseMatrix, SparseVector, Exception
from definitions import *
from datapoint import DataPoint
from datatable import DataTable
from bspline import BSpline
from bsplinebasis import BSplineBasis
from bsplinebasis1d import BSplineBasis1D
import os
import sys

@value
struct StreamType:
    var data: List[UInt8]

@value
class Serializer:
    var stream: StreamType
    var write: Int
    var read: Int

    def __init__(inout self):
        self.stream = StreamType(List[UInt8]())
        self.write = 0
        self.read = 0

    def __init__(inout self, fileName: String):
        self.stream = StreamType(List[UInt8]())
        self.loadFromFile(fileName)

    def saveToFile(inout self, fileName: String):
        var fs = open(fileName, "wb")
        for byte in self.stream.data:
            fs.write(bytes([byte]))
        fs.close()

    def loadFromFile(inout self, fileName: String):
        var ifs = open(fileName, "rb")
        if not ifs:
            var error_message = "Serializer::loadFromFile: Unable to open file \""
            error_message += fileName
            error_message += "\" for deserializing."
            raise Exception(error_message)
        var data = ifs.read()
        self.stream.data = List[UInt8](data)
        self.read = 0

    def _serialize[T](inout self, obj: T):

    def _serialize(inout self, obj: DataPoint):
        self._serialize(obj.x)
        self._serialize(obj.y)

    def _serialize(inout self, obj: DataTable):
        self._serialize(obj.allowDuplicates)
        self._serialize(obj.allowIncompleteGrid)
        self._serialize(obj.numDuplicates)
        self._serialize(obj.numVariables)
        self._serialize(obj.samples)
        self._serialize(obj.grid)

    def _serialize(inout self, obj: BSpline):
        self._serialize(obj.basis)
        self._serialize(obj.knotaverages)
        self._serialize(obj.coefficients)
        self._serialize(obj.numVariables)

    def _serialize(inout self, obj: BSplineBasis):
        self._serialize(obj.bases)
        self._serialize(obj.numVariables)

    def _serialize(inout self, obj: BSplineBasis1D):
        self._serialize(obj.degree)
        self._serialize(obj.knots)
        self._serialize(obj.targetNumBasisfunctions)

    def _serialize(inout self, obj: DenseMatrix):
        self._serialize(obj.rows())
        self._serialize(obj.cols())
        for i in range(obj.rows()):
            for j in range(obj.cols()):
                self._serialize(obj[i, j])

    def _serialize(inout self, obj: DenseVector):
        self._serialize(obj.rows())
        for i in range(obj.rows()):
            self._serialize(obj[i])

    def _serialize(inout self, obj: SparseMatrix):
        var temp = DenseMatrix(obj)
        self._serialize(temp)

    def _serialize(inout self, obj: SparseVector):
        var temp = DenseVector(obj)
        self._serialize(temp)

    def deserialize[T](inout self, inout obj: T):

    def deserialize(inout self, inout obj: DataPoint):
        self.deserialize(obj.x)
        self.deserialize(obj.y)

    def deserialize(inout self, inout obj: DataTable):
        self.deserialize(obj.allowDuplicates)
        self.deserialize(obj.allowIncompleteGrid)
        self.deserialize(obj.numDuplicates)
        self.deserialize(obj.numVariables)
        self.deserialize(obj.samples)
        self.deserialize(obj.grid)

    def deserialize(inout self, inout obj: BSpline):
        self.deserialize(obj.basis)
        self.deserialize(obj.knotaverages)
        self.deserialize(obj.coefficients)
        self.deserialize(obj.numVariables)

    def deserialize(inout self, inout obj: BSplineBasis):
        self.deserialize(obj.bases)
        self.deserialize(obj.numVariables)

    def deserialize(inout self, inout obj: BSplineBasis1D):
        self.deserialize(obj.degree)
        self.deserialize(obj.knots)
        self.deserialize(obj.targetNumBasisfunctions)

    def deserialize(inout self, inout obj: DenseMatrix):
        var rows: size_t
        self.deserialize(rows)
        var cols: size_t
        self.deserialize(cols)
        obj.resize(rows, cols)
        for i in range(rows):
            for j in range(cols):
                self.deserialize(obj[i, j])

    def deserialize(inout self, inout obj: DenseVector):
        var rows: size_t
        self.deserialize(rows)
        obj.resize(rows)
        for i in range(rows):
            self.deserialize(obj[i])

    def deserialize(inout self, inout obj: SparseMatrix):
        var temp = DenseMatrix(obj)
        self.deserialize(temp)
        obj = temp.sparseView()

    def deserialize(inout self, inout obj: SparseVector):
        var temp = DenseVector(obj)
        self.deserialize(temp)
        obj = temp.sparseView()

    def serialize[T](inout self, obj: T):
        var writeIndex = self.stream.data.size
        self.stream.data.resize(self.stream.data.size + get_size(obj))
        self.write = writeIndex
        self._serialize(obj)

    def deserialize[T](inout self, inout obj: T):
        if self.read + sizeof[T] > self.stream.data.size:
            raise Exception("Serializer::deserialize: Stream is missing bytes!")
        var objPtr = pointer[UInt8](address_of(obj))
        for i in range(sizeof[T]):
            self.stream.data[self.read + i] = objPtr[i]
        self.read += sizeof[T]

    def deserialize(inout self, inout obj: List[T]):
        var size: size_t
        self.deserialize(size)
        obj.resize(size)
        for i in range(size):
            self.deserialize(obj[i])

    def deserialize(inout self, inout obj: Set[T]):
        var size: size_t
        self.deserialize(size)
        var elem: T
        for i in range(size):
            self.deserialize(elem)
            obj.insert(elem)

    def deserialize(inout self, inout obj: Multiset[T]):
        var size: size_t
        self.deserialize(size)
        var elem: T
        for i in range(size):
            self.deserialize(elem)
            obj.insert(elem)

def get_size[T](obj: T) -> size_t:
    return sizeof[T]

def get_size(obj: DataPoint) -> size_t:
    return get_size(obj.x) + get_size(obj.y)

def get_size(obj: DataTable) -> size_t:
    return get_size(obj.allowDuplicates) \
           + get_size(obj.allowIncompleteGrid) \
           + get_size(obj.numDuplicates) \
           + get_size(obj.numVariables) \
           + get_size(obj.samples) \
           + get_size(obj.grid)

def get_size(obj: BSpline) -> size_t:
    return get_size(obj.basis) \
           + get_size(obj.knotaverages) \
           + get_size(obj.coefficients) \
           + get_size(obj.numVariables)

def get_size(obj: BSplineBasis) -> size_t:
    return get_size(obj.bases) \
           + get_size(obj.numVariables)

def get_size(obj: BSplineBasis1D) -> size_t:
    return get_size(obj.degree) \
           + get_size(obj.knots) \
           + get_size(obj.targetNumBasisfunctions)

def get_size(obj: DenseMatrix) -> size_t:
    var size: size_t = sizeof[obj.rows()]
    size += sizeof[obj.cols()]
    var numElements: size_t = obj.rows() * obj.cols()
    if numElements > 0:
        size += numElements * sizeof[obj[0, 0]]
    return size

def get_size(obj: DenseVector) -> size_t:
    var size: size_t = sizeof[obj.rows()]
    var numElements: size_t = obj.rows()
    if numElements > 0:
        size += numElements * sizeof[obj[0]]
    return size

def get_size(obj: SparseMatrix) -> size_t:
    var temp = DenseMatrix(obj)
    return get_size(temp)

def get_size(obj: SparseVector) -> size_t:
    var temp = DenseVector(obj)
    return get_size(temp)

def get_size[T](obj: List[T]) -> size_t:
    var size: size_t = sizeof[size_t]
    for elem in obj:
        size += get_size(elem)
    return size

def get_size[T](obj: Set[T]) -> size_t:
    var size: size_t = sizeof[size_t]
    for elem in obj:
        size += get_size(elem)
    return size

def get_size[T](obj: Multiset[T]) -> size_t:
    var size: size_t = sizeof[size_t]
    for elem in obj:
        size += get_size(elem)
    return size