/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

from datapoint import DataPoint
from serializer import Serializer

# Simulate multiset with a sorted list
struct Multiset[T: Comparable]():
    var _data: List[T]
    
    def __init__(inout self):
        self._data = List[T]()
    
    def insert(inout self, value: T):
        # Insert in sorted order (linear search, preserves duplicates)
        var i: Int = 0
        while i < len(self._data):
            if self._data[i] > value:
                break
            i += 1
        self._data.insert(i, value)
    
    def count(inout self, value: T) -> Int:
        var c: Int = 0
        for v in self._data:
            if v == value:
                c += 1
        return c
    
    def size(self) -> Int:
        return len(self._data)
    
    def cbegin(self) -> Int:
        return 0
    
    def cend(self) -> Int:
        return len(self._data)
    
    def __getitem__(self, idx: Int) -> T:
        return self._data[idx]
    
    def __iter__(self) -> _MultisetIter[T]:
        return _MultisetIter[T](self._data, 0)
    
    def get_samples(self) -> Self:
        return self

struct _MultisetIter[T: Comparable]():
    var data: List[T]
    var index: Int
    
    def __init__(inout self, data: List[T], idx: Int):
        self.data = data
        self.index = idx
    
    def __iter__(inout self) -> Self:
        return self
    
    def __next__(inout self) -> T:
        if self.index >= len(self.data):
            raise("StopIteration")
        var result = self.data[self.index]
        self.index += 1
        return result

# Simulate set for grid
# We use a List and maintain uniqueness manually (simple approach)
struct SetWrapper[T: Comparable]():
    var _data: List[T]
    
    def __init__(inout self):
        self._data = List[T]()
    
    def insert(inout self, value: T):
        for v in self._data:
            if v == value:
                return
        self._data.append(value)
    
    def size(self) -> Int:
        return len(self._data)
    
    def __iter__(self) -> _SetIter[T]:
        return _SetIter[T](self._data, 0)

struct _SetIter[T: Comparable]():
    var data: List[T]
    var index: Int
    
    def __init__(inout self, data: List[T], idx: Int):
        self.data = data
        self.index = idx
    
    def __iter__(inout self) -> Self:
        return self
    
    def __next__(inout self) -> T:
        if self.index >= len(self.data):
            raise("StopIteration")
        var result = self.data[self.index]
        self.index += 1
        return result

# Simulate vector<set<double>> -> List[SetWrapper[Float64]]
@value
struct SPLINTER:

@value
struct DataTable:
    var allowDuplicates: Bool
    var allowIncompleteGrid: Bool
    var numDuplicates: UInt
    var numVariables: UInt
    var samples: Multiset[DataPoint]
    var grid: List[SetWrapper[Float64]]

    def __init__(inout self):
        self = DataTable(false, false)
    
    def __init__(inout self, allowDuplicates: Bool):
        self = DataTable(allowDuplicates, false)
    
    def __init__(inout self, allowDuplicates: Bool, allowIncompleteGrid: Bool):
        self.allowDuplicates = allowDuplicates
        self.allowIncompleteGrid = allowIncompleteGrid
        self.numDuplicates = 0
        self.numVariables = 0
        self.samples = Multiset[DataPoint]()
        self.grid = List[SetWrapper[Float64]]()
    
    def __init__(inout self, fileName: String):
        self.load(fileName)
    
    def __init__(inout self, fileName: StringLiteral):
        self.load(String(fileName))
    
    def addSample[inout self](sample: DataPoint):
        if self.getNumSamples() == 0:
            self.numVariables = sample.getDimX()
            self.initDataStructures()
        if sample.getDimX() != self.numVariables:
            raise Exception("Datatable::addSample: Dimension of new sample is inconsistent with previous samples!")
        if self.samples.count(sample) > 0:
            if not self.allowDuplicates:
                #ifndef NDEBUG
                print("Discarding duplicate sample because allowDuplicates is false!")
                print("Initialise with DataTable(true) to set it to true.")
                #endif // NDEBUG
                return
            self.numDuplicates += 1
        self.samples.insert(sample)
        self.recordGridPoint(sample)
    
    def addSample(inout self, x: Float64, y: Float64):
        self.addSample(DataPoint(x, y))
    
    def addSample(inout self, x: List[Float64], y: Float64):
        self.addSample(DataPoint(x, y))
    
    def addSample(inout self, x: DenseVector, y: Float64):
        self.addSample(DataPoint(x, y))
    
    def addSample(inout self, samples: List[DataPoint]):
        for sample in samples:
            self.addSample(sample)
    
    def recordGridPoint(inout self, sample: DataPoint):
        for i in range(self.getNumVariables()):
            self.grid.at(i).insert(sample.getX().at(i))
    
    def getNumSamplesRequired(self) -> UInt:
        var samplesRequired: ULong = 1
        var i: UInt = 0
        for variable in self.grid:
            samplesRequired *= ULong(variable.size())
            i += 1
        return UInt(samplesRequired) if i > 0 else 0
    
    def isGridComplete(self) -> Bool:
        return self.samples.size() > 0 and (self.samples.size() - self.numDuplicates) == self.getNumSamplesRequired()
    
    def initDataStructures(inout self):
        for i in range(self.getNumVariables()):
            self.grid.push_back(SetWrapper[Float64]())
    
    def gridCompleteGuard(self) -> Bool:
        if not (self.isGridComplete() or self.allowIncompleteGrid):
            raise Exception("DataTable::gridCompleteGuard: The grid is not complete yet!")
        return True
    
    def save(self, fileName: String):
        var s = Serializer()
        s.serialize(self)
        s.saveToFile(fileName)
    
    def load(inout self, fileName: String):
        var s = Serializer(fileName)
        s.deserialize(self)
    
    # Getters for iterators
    def cbegin(self) -> Int:
        return self.samples.cbegin()
    
    def cend(self) -> Int:
        return self.samples.cend()
    
    def getNumVariables(self) -> UInt:
        return self.numVariables
    
    def getNumSamples(self) -> UInt:
        return UInt(self.samples.size())
    
    def getSamples(self) -> Multiset[DataPoint]:
        return self.samples
    
    def getGrid(self) -> List[SetWrapper[Float64]]:
        return self.grid
    
    # Get table of samples x-values
    def getTableX(self) -> List[List[Float64]]:
        self.gridCompleteGuard()
        var table: List[List[Float64]] = List[List[Float64]]()
        for i in range(self.numVariables):
            var xi = List[Float64]()
            for j in range(self.getNumSamples()):
                xi.append(0.0)
            table.append(xi)
        var i: Int = 0
        for s in self.samples:
            var x = s.getX()
            for j in range(self.numVariables):
                table.at(j).at(i) = x.at(j)
            i += 1
        return table
    
    def getVectorY(self) -> List[Float64]:
        var y = List[Float64]()
        var it: Int = self.cbegin()
        while it != self.cend():
            y.append(self.samples[it].getY())
            it += 1
        return y
    
    def clear(inout self):
        self.samples = Multiset[DataPoint]()
        self.grid = List[SetWrapper[Float64]]()
    
    def __add__(self, other: DataTable) -> DataTable:
        if self.getNumVariables() != other.getNumVariables():
            raise Exception("operator+(DataTable, DataTable): trying to add two DataTable's of different dimensions!")
        var result = DataTable()
        for it in range(self.cbegin(), self.cend()):
            result.addSample(self.samples[it])
        for it in range(other.cbegin(), other.cend()):
            result.addSample(other.samples[it])
        return result
    
    def __sub__(self, other: DataTable) -> DataTable:
        if self.getNumVariables() != other.getNumVariables():
            raise Exception("operator-(DataTable, DataTable): trying to subtract two DataTable's of different dimensions!")
        var result = DataTable()
        var rhsSamples = other.getSamples()
        for it in range(self.cbegin(), self.cend()):
            var sample = self.samples[it]
            if rhsSamples.count(sample) == 0:
                result.addSample(sample)
        return result

# Free functions not needed as we used __add__ and __sub__ inside the struct.
# The following are kept for compatibility but are not used in original code? Actually they are defined in the original.
# We'll skip them as they are duplicates of the methods.

# DataTable operator+(const DataTable &lhs, const DataTable &rhs) is implemented as __add__
# DataTable operator-(const DataTable &lhs, const DataTable &rhs) is implemented as __sub__

# Note: The original also defines operator<<? Not present in this file.

# Helper for DenseVector (assume imported)
# The original uses DenseVector from elsewhere.
# We'll assume it is defined in datapoint.h or elsewhere.
# For now, we'll treat it as a List[Float64] compatible.
@value
struct DenseVector:
    var data: List[Float64]

# Exception class (assume exists)
struct Exception:
    var msg: String
    def __init__(inout self, msg: String):
        self.msg = msg
    def __str__(self) -> String:
        return self.msg

# End of translation.