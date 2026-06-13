/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from Functions import isEqual, isGreaterOrEqual, isLessOrEqual, isLessThan, isGreaterThan, isOdd, showMessage, MSG_ERR
from Errors import *
from math import pow
from memory import Pointer
from utils import List

struct Interval:
    var maxGrowthCoeff: Float64
    var minCellDim: Float64
    enum Growth:
        FORWARD = 0
        BACKWARD = 1
        UNIFORM = 2
        CENTERED = 3
    var growthDir: Growth

struct MeshData:
    var points: List[Float64]
    var intervals: List[Interval]

@value
struct Mesher:
    var data: MeshData
    var dividers: List[Float64] # center is between divider[i] and divider[i+1]
    var deltas: List[Float64]
    var centers: List[Float64]

    def __init__(inout self):
        self.data = MeshData(points=List[Float64](), intervals=List[Interval]())
        self.dividers = List[Float64]()
        self.deltas = List[Float64]()
        self.centers = List[Float64]()

    def __init__(inout self, data: MeshData):
        self.data = data
        self.dividers = List[Float64]()
        self.deltas = List[Float64]()
        self.centers = List[Float64]()
        self.dividers.append(data.points[0])
        if data.points.size <= 3:
            self.dividers.append(1.0)
            self.deltas.append(1.0)
            self.centers.append(0.5)
            return
        for i in range(data.points.size - 1):
            var min: Float64 = data.points[i]
            var max: Float64 = data.points[i + 1]
            var length: Float64 = max - min
            var cellWidth: Float64
            var numCells: Int = 0
            if isEqual(length, 0.0):
                self.dividers.append(max)
                self.deltas.append(0.0)
                self.centers.append(max)
            else:
                if data.intervals[i].growthDir == Interval.Growth.UNIFORM:
                    numCells = Int(length / data.intervals[i].minCellDim)
                    if numCells == 0:
                        numCells = 1
                    if isEqual(length / (numCells + 1), data.intervals[i].minCellDim):
                        cellWidth = data.intervals[i].minCellDim
                        numCells = numCells + 1
                    else:
                        cellWidth = length / numCells
                    for j in range(1, numCells + 1):
                        self.dividers.append(min + j * cellWidth)
                        self.deltas.append(cellWidth)
                        self.centers.append(min + j * cellWidth - cellWidth / 2.0)
                else:
                    var temp: List[Float64] = List[Float64]()
                    if isGreaterOrEqual(data.intervals[i].minCellDim, length):
                        temp.append(length)
                        numCells = 1
                    else:
                        if data.intervals[i].growthDir == Interval.Growth.CENTERED:
                            var search: Bool = True
                            var N: Int = 1
                            var multiplier: Float64
                            var nTerm: Float64
                            var seriesTerm: Float64
                            var previousMultiplier: Float64 = 1.0
                            while search:
                                seriesTerm = 0.0
                                if isOdd(N):
                                    nTerm = pow(data.intervals[i].maxGrowthCoeff, (N - 1) / 2)
                                    for j in range((N - 1) / 2):
                                        seriesTerm += 2 * pow(data.intervals[i].maxGrowthCoeff, j)
                                else:
                                    nTerm = 0
                                    for j in range(N / 2):
                                        seriesTerm += 2 * pow(data.intervals[i].maxGrowthCoeff, j)
                                multiplier = seriesTerm + nTerm
                                if data.intervals[i].minCellDim * multiplier > length:
                                    numCells = N - 1
                                    multiplier = previousMultiplier
                                    search = False
                                else:
                                    previousMultiplier = multiplier
                                    N += 1
                            var initialCellWidth: Float64 = length / previousMultiplier
                            temp.append(initialCellWidth)
                            for j in range(1, numCells):
                                if isOdd(numCells):
                                    if j <= (numCells - 1) / 2:
                                        temp.append(temp[j - 1] * data.intervals[i].maxGrowthCoeff)
                                    else:
                                        temp.append(temp[j - 1] / data.intervals[i].maxGrowthCoeff)
                                else:
                                    if j < numCells / 2:
                                        temp.append(temp[j - 1] * data.intervals[i].maxGrowthCoeff)
                                    elif j == numCells / 2:
                                        temp.append(temp[j - 1])
                                    else:
                                        temp.append(temp[j - 1] / data.intervals[i].maxGrowthCoeff)
                        else:
                            var search: Bool = True
                            var N: Int = 0
                            var multiplier: Float64 = 0
                            while search:
                                multiplier = 0.0
                                for j in range(N + 1):
                                    multiplier += pow(data.intervals[i].maxGrowthCoeff, j)
                                if data.intervals[i].minCellDim * multiplier > length:
                                    numCells = N
                                    multiplier -= pow(data.intervals[i].maxGrowthCoeff, N)
                                    search = False
                                else:
                                    N += 1
                            var initialCellWidth: Float64 = length / multiplier
                            temp.append(initialCellWidth)
                            for j in range(1, numCells):
                                temp.append(temp[j - 1] * data.intervals[i].maxGrowthCoeff)
                    if data.intervals[i].growthDir == Interval.Growth.FORWARD:
                        var position: Float64 = min
                        for j in range(numCells):
                            self.dividers.append(position + temp[j])
                            self.deltas.append(temp[j])
                            self.centers.append(position + temp[j] / 2.0)
                            position += temp[j]
                    elif data.intervals[i].growthDir == Interval.Growth.BACKWARD:
                        var position: Float64 = min
                        for j in range(1, numCells + 1):
                            self.dividers.append(position + temp[numCells - j])
                            self.deltas.append(temp[numCells - j])
                            self.centers.append(position + temp[numCells - j] / 2.0)
                            position += temp[numCells - j]
                    else:
                        var position: Float64 = min
                        for j in range(numCells):
                            self.dividers.append(position + temp[j])
                            self.deltas.append(temp[j])
                            self.centers.append(position + temp[j] / 2.0)
                            position += temp[j]

    def getNearestIndex(self, position: Float64) -> Int:
        if isLessOrEqual(position, self.centers[0]):
            return 0
        elif isGreaterOrEqual(position, self.centers[self.centers.size - 1]):
            return self.centers.size - 1
        else:
            for i in range(1, self.centers.size):
                if isGreaterOrEqual(position, self.centers[i - 1]) and isLessOrEqual(position, self.centers[i]):
                    var diffDown: Float64 = position - self.centers[i - 1]
                    var diffUp: Float64 = self.centers[i] - position
                    if isLessOrEqual(diffDown, diffUp):
                        return i - 1
                    else:
                        return i
            showMessage(MSG_ERR, "Could not find the nearest Index.")
            return 0

    def getNextIndex(self, position: Float64) -> Int:
        if isLessThan(position, self.centers[0]):
            return 0
        elif isGreaterOrEqual(position, self.centers[self.centers.size - 1]):
            return self.centers.size - 1
        else:
            for i in range(self.centers.size - 1):
                if isGreaterOrEqual(position, self.centers[i]) and isLessThan(position, self.centers[i + 1]):
                    return i + 1
            showMessage(MSG_ERR, "Could not find the next Index.")
            return 0

    def getPreviousIndex(self, position: Float64) -> Int:
        if isLessOrEqual(position, self.centers[0]):
            return 0
        elif isGreaterThan(position, self.centers[self.centers.size - 1]):
            return self.centers.size - 1
        else:
            for i in range(1, self.centers.size):
                if isGreaterThan(position, self.centers[i - 1]) and isLessOrEqual(position, self.centers[i]):
                    return i - 1
            showMessage(MSG_ERR, "Could not find the previous Index.")
            return 0