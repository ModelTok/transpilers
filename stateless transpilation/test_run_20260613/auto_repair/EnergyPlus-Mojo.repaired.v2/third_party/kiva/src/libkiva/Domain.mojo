/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from Cell import Cell, ZeroThicknessCell, BoundaryCell, InteriorAirCell, ExteriorAirCell, CellType
from Errors import showMessage, MSG_ERR
from Foundation import Foundation, Surface, Block
from Functions import pointOnPoly, within, isGreaterOrEqual, isLessOrEqual, isGreaterThan, isLessThan, isEqual, Point
from Mesher import Mesher
from memory import Arc
from math import atan
from io import File

let PI: Float64 = 4.0 * atan(1.0)

class Domain:
    var mesh: List[Mesher]
    var dim_lengths: List[Int]
    var stepsize: List[Int]
    var cell: List[Arc[Cell]]
    var dest_index_vector: List[List[Int]]

    def __init__(inout self):
        self.mesh = List[Mesher](3)
        self.dim_lengths = List[Int](3)
        self.stepsize = List[Int](3)
        self.cell = List[Arc[Cell]]()
        self.dest_index_vector = List[List[Int]]()

    def __init__(inout self, foundation: Foundation):
        self.__init__()
        self.setDomain(foundation)

    def setDomain(inout self, foundation: Foundation):
        {
            self.mesh[0] = Mesher(foundation.xMeshData)
            self.mesh[1] = Mesher(foundation.yMeshData)
            self.mesh[2] = Mesher(foundation.zMeshData)
        }
        for dim in range(3):
            self.dim_lengths[dim] = len(self.mesh[dim].centers)

        var dxp_vector: List[Float64] = List[Float64]()
        var dxm_vector: List[Float64] = List[Float64]()
        var dyp_vector: List[Float64] = List[Float64]()
        var dym_vector: List[Float64] = List[Float64]()
        var dzp_vector: List[Float64] = List[Float64]()
        var dzm_vector: List[Float64] = List[Float64]()

        for i in range(self.dim_lengths[0]):
            dxp_vector.append(self.getDistances(i, 0, 1))
            dxm_vector.append(self.getDistances(i, 0, 0))

        for j in range(self.dim_lengths[1]):
            dyp_vector.append(self.getDistances(j, 1, 1))
            dym_vector.append(self.getDistances(j, 1, 0))

        for k in range(self.dim_lengths[2]):
            dzp_vector.append(self.getDistances(k, 2, 1))
            dzm_vector.append(self.getDistances(k, 2, 0))

        self.stepsize[0] = 1
        self.stepsize[1] = self.dim_lengths[0]
        self.stepsize[2] = self.dim_lengths[0] * self.dim_lengths[1]

        var num_cells: Int = self.dim_lengths[0] * self.dim_lengths[1] * self.dim_lengths[2]
        self.cell.reserve(num_cells)
        self.dest_index_vector = List[List[Int]](3)
        for d in range(3):
            self.dest_index_vector[d] = List[Int](num_cells)

        var temp_di: List[Int] = List[Int](3)
        var i: Int
        var j: Int
        var k: Int
        var cellType: CellType

        for index in range(num_cells):
            (i, j, k) = self.getCoordinates(index)
            temp_di = self.getDestIndex(i, j, k)
            for d in range(3):
                self.dest_index_vector[d][index] = temp_di[d]

            cellType = CellType.NORMAL
            var surfacePtr: Surface = Surface()  # placeholder, will be set if found
            var numZeroDims: Int = self.getNumZeroDims(i, j, k)
            var xNotBoundary: Bool = i != 0 and i != self.dim_lengths[0] - 1
            var yNotBoundary: Bool = j != 0 and j != self.dim_lengths[1] - 1
            var zNotBoundary: Bool = k != 0 and k != self.dim_lengths[2] - 1
            var surfaceAssignmentCount: Int = 0

            for ref surface in foundation.surfaces:
                if pointOnPoly(Point(self.mesh[0].centers[i], self.mesh[1].centers[j]), surface.polygon):
                    if isGreaterOrEqual(self.mesh[2].centers[k], surface.zMin) and isLessOrEqual(self.mesh[2].centers[k], surface.zMax):
                        cellType = CellType.BOUNDARY
                        surfacePtr = surface
                        if numZeroDims == 0:
                            showMessage(MSG_ERR, "A normal cell was detected within a surface.")
                        if foundation.numberOfDimensions == 3:
                            if (numZeroDims > 1) and xNotBoundary and yNotBoundary and zNotBoundary:
                                cellType = CellType.ZERO_THICKNESS
                        elif foundation.numberOfDimensions == 2:
                            if (numZeroDims > 1) and xNotBoundary and zNotBoundary:
                                cellType = CellType.ZERO_THICKNESS
                        else:
                            if (numZeroDims > 1) and zNotBoundary:
                                cellType = CellType.ZERO_THICKNESS
                        if cellType == CellType.BOUNDARY:
                            surface.indices.append(index)
                            surfaceAssignmentCount += 1
                            if surfaceAssignmentCount > 1 and numZeroDims <= 1:
                                showMessage(MSG_ERR, "A cell has been assigned to multiple surfaces.")

            if cellType == CellType.ZERO_THICKNESS:
                var sp = Arc.make[ZeroThicknessCell](
                    index, cellType, i, j, k, self.stepsize, foundation, surfacePtr, None, self.mesh)
                self.cell.append(sp)
            elif cellType == CellType.BOUNDARY:
                var sp = Arc.make[BoundaryCell](
                    index, cellType, i, j, k, self.stepsize, foundation, surfacePtr, None, self.mesh)
                self.cell.append(sp)
            else:
                var blockPtr: Block = Block()  # placeholder, will be set if found
                for ref block in foundation.blocks:
                    if within(Point(self.mesh[0].centers[i], self.mesh[1].centers[j]), block.polygon) and isGreaterThan(self.mesh[2].centers[k], block.zMin) and isLessThan(self.mesh[2].centers[k], block.zMax):
                        blockPtr = block
                if blockPtr is not None:
                    if blockPtr.blockType == Block.INTERIOR_AIR:
                        cellType = CellType.INTERIOR_AIR
                        var sp = Arc.make[InteriorAirCell](
                            index, cellType, i, j, k, self.stepsize, foundation, None, blockPtr, self.mesh)
                        self.cell.append(sp)
                    elif blockPtr.blockType == Block.EXTERIOR_AIR:
                        cellType = CellType.EXTERIOR_AIR
                        var sp = Arc.make[ExteriorAirCell](
                            index, cellType, i, j, k, self.stepsize, foundation, None, blockPtr, self.mesh)
                        self.cell.append(sp)
                    else:
                        var sp = Arc.make[Cell](index, cellType, i, j, k, self.stepsize, foundation, None, blockPtr, self.mesh)
                        self.cell.append(sp)
                else:
                    if foundation.numberOfDimensions == 3:
                        if isEqual(self.mesh[0].deltas[i], 0.0) or isEqual(self.mesh[2].deltas[k], 0.0) or isEqual(self.mesh[1].deltas[j], 0.0):
                            cellType = CellType.ZERO_THICKNESS
                    elif foundation.numberOfDimensions == 2:
                        if isEqual(self.mesh[0].deltas[i], 0.0) or isEqual(self.mesh[2].deltas[k], 0.0):
                            cellType = CellType.ZERO_THICKNESS
                    else:
                        if isEqual(self.mesh[2].deltas[k], 0.0):
                            cellType = CellType.ZERO_THICKNESS
                    if cellType == CellType.ZERO_THICKNESS:
                        var sp = Arc.make[ZeroThicknessCell](
                            index, cellType, i, j, k, self.stepsize, foundation, None, None, self.mesh)
                        self.cell.append(sp)
                    else:
                        var sp = Arc.make[Cell](index, cellType, i, j, k, self.stepsize, foundation, None, None, self.mesh)
                        self.cell.append(sp)

        for this_cell in self.cell:
            var index: Int = this_cell.index
            (i, j, k) = self.getCoordinates(index)
            var numZeroDims: Int = self.getNumZeroDims(i, j, k)
            if numZeroDims > 0 and this_cell.cellType != CellType.INTERIOR_AIR and this_cell.cellType != CellType.EXTERIOR_AIR:
                if foundation.numberOfDimensions == 3:
                    if i != 0 and i != self.dim_lengths[0] - 1 and j != 0 and j != self.dim_lengths[1] - 1 and k != 0 and k != self.dim_lengths[2] - 1:
                        self.set3DZeroThicknessCellProperties(index)
                elif foundation.numberOfDimensions == 2:
                    if i != 0 and i != self.dim_lengths[0] - 1 and k != 0 and k != self.dim_lengths[2] - 1:
                        self.set2DZeroThicknessCellProperties(index)
                else:
                    if k != 0 and k != self.dim_lengths[2] - 1:
                        if isEqual(self.mesh[2].deltas[k], 0.0):
                            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
                            pointSet.append(self.cell[index - self.stepsize[2]])
                            pointSet.append(self.cell[index + self.stepsize[2]])
                            this_cell.setZeroThicknessCellProperties(pointSet)

        var dims: List[Int] = List[Int](3)
        dims[0] = 0
        dims[1] = 1
        dims[2] = 2
        if foundation.numberOfDimensions < 3:
            dims[1] = 5
        if foundation.numberOfDimensions == 1:
            dims[0] = 5

        for this_cell in self.cell:
            this_cell.setComputeDims(dims)
            this_cell.setDistances(dxp_vector[this_cell.coords[0]], dxm_vector[this_cell.coords[0]],
                                   dyp_vector[this_cell.coords[1]], dym_vector[this_cell.coords[1]],
                                   dzp_vector[this_cell.coords[2]], dzm_vector[this_cell.coords[2]])
            this_cell.setConductivities(self.cell)
            this_cell.setPDEcoefficients(foundation.numberOfDimensions,
                                         foundation.coordinateSystem == Foundation.CS_CYLINDRICAL)

        var orientation_map: Dict[Surface.Orientation, Tuple[Int, Int, Float64]] = Dict[Surface.Orientation, Tuple[Int, Int, Float64]]()
        orientation_map[Surface.X_POS] = (0, 0, PI / 2 + foundation.orientation)
        orientation_map[Surface.X_NEG] = (0, 1, 3 * PI / 2 + foundation.orientation)
        orientation_map[Surface.Y_POS] = (1, 0, foundation.orientation)
        orientation_map[Surface.Y_NEG] = (1, 1, PI + foundation.orientation)
        orientation_map[Surface.Z_POS] = (2, 0, 0.0)
        orientation_map[Surface.Z_NEG] = (2, 1, 0.0)

        for ref surface in foundation.surfaces:
            surface.calcTilt()
            surface.area = 0
            for index in surface.indices:
                surface.area += self.cell[index].area
            (surface.orientation_dim, surface.orientation_dir, surface.azimuth) = orientation_map[surface.orientation]

    def getDistances(inout self, i: Int, dim: Int, dir: Int) -> Float64:
        if self.dim_lengths[dim] == 1:
            return 0
        elif dir == 0:
            if i == 0:
                return (self.mesh[dim].deltas[i] + self.mesh[dim].deltas[i + 1]) / 2.0
            else:
                return (self.mesh[dim].deltas[i] + self.mesh[dim].deltas[i - 1]) / 2.0
        else:
            if i == self.dim_lengths[dim] - 1:
                return (self.mesh[dim].deltas[i] + self.mesh[dim].deltas[i - 1]) / 2.0
            else:
                return (self.mesh[dim].deltas[i] + self.mesh[dim].deltas[i + 1]) / 2.0

    def set2DZeroThicknessCellProperties(inout self, index: Int):
        if isEqual(self.mesh[0].deltas[self.cell[index].coords[0]], 0.0) and isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[0] + self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[0] - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] - self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif isEqual(self.mesh[0].deltas[self.cell[index].coords[0]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[0]])
            pointSet.append(self.cell[index + self.stepsize[0]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)

    def set3DZeroThicknessCellProperties(inout self, index: Int):
        if (isEqual(self.mesh[0].deltas[self.cell[index].coords[0]], 0.0) and
            isEqual(self.mesh[1].deltas[self.cell[index].coords[1]], 0.0) and
            isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0)):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[0] - self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] - self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[0] - self.stepsize[1] - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] - self.stepsize[1] - self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[0] + self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] + self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[0] + self.stepsize[1] - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] + self.stepsize[1] - self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif (isEqual(self.mesh[0].deltas[self.cell[index].coords[0]], 0.0) and
              isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0)):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[0] + self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[0] - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[0] - self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif (isEqual(self.mesh[1].deltas[self.cell[index].coords[1]], 0.0) and
              isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0)):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index - self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[1] + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[1] - self.stepsize[2]])
            pointSet.append(self.cell[index + self.stepsize[1] - self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif isEqual(self.mesh[0].deltas[self.cell[index].coords[0]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index + self.stepsize[0]])
            pointSet.append(self.cell[index - self.stepsize[0]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif isEqual(self.mesh[1].deltas[self.cell[index].coords[1]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index + self.stepsize[1]])
            pointSet.append(self.cell[index - self.stepsize[1]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)
        elif isEqual(self.mesh[2].deltas[self.cell[index].coords[2]], 0.0):
            var pointSet: List[Arc[Cell]] = List[Arc[Cell]]()
            pointSet.append(self.cell[index + self.stepsize[2]])
            pointSet.append(self.cell[index - self.stepsize[2]])
            self.cell[index].setZeroThicknessCellProperties(pointSet)

    def getNumZeroDims(inout self, i: Int, j: Int, k: Int) -> Int:
        var numZeroDims: Int = 0
        if isEqual(self.mesh[0].deltas[i], 0.0):
            numZeroDims += 1
        if isEqual(self.mesh[1].deltas[j], 0.0):
            numZeroDims += 1
        if isEqual(self.mesh[2].deltas[k], 0.0):
            numZeroDims += 1
        return numZeroDims

    def printCellTypes(inout self):
        var output: File = File()
        output.open("Cells.csv")
        for i in range(self.dim_lengths[0]):
            output.write(", " + str(i))
        output.write("\n")
        for n in range(self.dim_lengths[2], 0, -1):
            var k: Int = n - 1
            output.write(str(k))
            for i in range(self.dim_lengths[0]):
                output.write(", ")
                output.write(str(self.cell[i + (self.dim_lengths[1] / 2) * self.stepsize[1] + k * self.stepsize[2]].cellType))
            output.write("\n")
        output.close()

    def getCoordinates(inout self, index: Int) -> Tuple[Int, Int, Int]:
        var i: Int = index % self.dim_lengths[0]
        var j: Int = ((index - i) % self.dim_lengths[1]) / self.dim_lengths[0]
        var k: Int = (index - i - self.dim_lengths[0] * j) / (self.dim_lengths[0] * self.dim_lengths[1])
        return (i, j, k)

    def getDestIndex(inout self, i: Int, j: Int, k: Int) -> List[Int]:
        var dest_index: List[Int] = List[Int]()
        dest_index.append(i + self.dim_lengths[0] * j + self.dim_lengths[0] * self.dim_lengths[1] * k)
        dest_index.append(j + self.dim_lengths[1] * i + self.dim_lengths[1] * self.dim_lengths[0] * k)
        dest_index.append(k + self.dim_lengths[2] * i + self.dim_lengths[2] * self.dim_lengths[0] * j)
        return dest_index

    def getIndex(inout self, i: Int, j: Int, k: Int) -> Int:
        return i + self.dim_lengths[0] * j + self.dim_lengths[0] * self.dim_lengths[1] * k
<<<FILE>>>