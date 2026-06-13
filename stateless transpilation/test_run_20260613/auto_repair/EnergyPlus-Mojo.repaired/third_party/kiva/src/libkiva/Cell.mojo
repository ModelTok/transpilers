/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from math import atan
from pointer import Pointer, UnsafePointer

from Algorithms import *
from BoundaryConditions import *
from Foundation import *
from Functions import *
from Mesher import *
from libkiva_export import *

alias PI: Float64 = 4.0 * atan(1.0)

enum CellType: Int {
    EXTERIOR_AIR = 0
    INTERIOR_AIR = 1
    NORMAL = 2
    BOUNDARY = 3
    ZERO_THICKNESS = 4
}

struct Cell:

    var coords: Array[Int, 3]
    var index: Int
    var stepsize: Pointer[Int]
    var dims: Array[Int, 3]
    var density: Float64
    var specificHeat: Float64
    var conductivity: Float64
    var iHeatCapacity: Float64
    var iHeatCapacityADI: Float64
    var volume: Float64
    var area: Float64
    var r: Float64
    var heatGain: Float64
    var pde: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
    var pde_c: Array[Float64, 2] = Array[Float64, 2](0.0, 0.0)
    var dist: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
    var kcoeff: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
    var told_ptr: Pointer[Float64]
    var cellType: CellType
    var blockPtr: Pointer[Block]
    var surfacePtr: Pointer[Surface]
    var meshPtr: Pointer[Mesher]

    def __init__(inout self, index: Int, cellType: CellType, i: Int, j: Int, k: Int, stepsize: Pointer[Int], foundation: Foundation, surfacePtr: Pointer[Surface], blockPtr: Pointer[Block], meshPtr: Pointer[Mesher]):
        self.coords = Array[Int, 3](i, j, k)
        self.index = index
        self.stepsize = stepsize
        self.cellType = cellType
        self.blockPtr = blockPtr
        self.surfacePtr = surfacePtr
        self.meshPtr = meshPtr
        self.Assemble(foundation)

    def __del__(owned self):

    def Assemble(inout self, foundation: Foundation):
        if self.blockPtr:
            self.density = self.blockPtr[].material.density
            self.specificHeat = self.blockPtr[].material.specificHeat
            self.conductivity = self.blockPtr[].material.conductivity
        else:
            self.density = foundation.soil.density
            self.specificHeat = foundation.soil.specificHeat
            self.conductivity = foundation.soil.conductivity
        self.heatGain = 0.0
        self.volume = self.meshPtr[0].deltas[self.coords[0]] * self.meshPtr[1].deltas[self.coords[1]] * self.meshPtr[2].deltas[self.coords[2]]
        self.iHeatCapacity = 1.0 / (self.density * self.specificHeat)
        self.iHeatCapacityADI = self.iHeatCapacity / foundation.numberOfDimensions
        if foundation.numberOfDimensions == 2:
            self.r = self.meshPtr[0].centers[self.coords[0]]

    def setDistances(inout self, dxp_in: Float64, dxm_in: Float64, dyp_in: Float64, dym_in: Float64, dzp_in: Float64, dzm_in: Float64):
        self.dist[0][1] = dxp_in
        self.dist[0][0] = dxm_in
        self.dist[1][1] = dyp_in
        self.dist[1][0] = dym_in
        self.dist[2][1] = dzp_in
        self.dist[2][0] = dzm_in

    def setConductivities(inout self, cell_v: List[Pointer[Cell]]):
        for dim in range(3):
            if self.coords[dim] == 0:
                self.kcoeff[dim][0] = self.conductivity
            else:
                self.kcoeff[dim][0] = 1.0 / (self.meshPtr[dim].deltas[self.coords[dim]] / (2.0 * self.dist[dim][0] * self.conductivity) + self.meshPtr[dim].deltas[self.coords[dim] - 1] / (2.0 * self.dist[dim][0] * cell_v[self.index - self.stepsize[dim]].[].conductivity))
            if self.coords[dim] == self.meshPtr[dim].centers.size - 1:
                self.kcoeff[dim][1] = self.conductivity
            else:
                self.kcoeff[dim][1] = 1.0 / (self.meshPtr[dim].deltas[self.coords[dim]] / (2.0 * self.dist[dim][1] * self.conductivity) + self.meshPtr[dim].deltas[self.coords[dim] + 1] / (2.0 * self.dist[dim][1] * cell_v[self.index + self.stepsize[dim]].[].conductivity))

    def setPDEcoefficients(inout self, ndims: Int, cylindrical: Bool):
        for dim in self.dims:
            if dim < 5:
                self.pde[dim][1] = self.onePDEcoefficient(dim, 1)
                self.pde[dim][0] = self.onePDEcoefficient(dim, 0)
        if ndims == 2 and cylindrical:
            self.pde_c[1] = (self.dist[0][0] * self.kcoeff[0][1]) / ((self.dist[0][0] + self.dist[0][1]) * self.dist[0][1])
            self.pde_c[0] = (self.dist[0][1] * self.kcoeff[0][0]) / ((self.dist[0][0] + self.dist[0][1]) * self.dist[0][0])

    def onePDEcoefficient(inout self, dim: Int, dir: Int) -> Float64:
        var sign = -1 if dir == 0 else 1
        var c: Float64 = sign * (2.0 * self.kcoeff[dim][dir]) / ((self.dist[dim][0] + self.dist[dim][1]) * self.dist[dim][dir])
        return c

    def setComputeDims(inout self, in_dims: Array[Int, 3]):
        for d in range(3):
            self.dims[d] = in_dims[d]

    def setZeroThicknessCellProperties(inout self, pointSet: List[Pointer[Cell]]):
        var volumes = List[Float64]()
        var densities = List[Float64]()
        var specificHeats = List[Float64]()
        var conductivities = List[Float64]()
        var masses = List[Float64]()
        var capacities = List[Float64]()
        var weightedConductivity = List[Float64]()
        for p_cell in pointSet:
            if p_cell[].cellType != CellType.INTERIOR_AIR and p_cell[].cellType != CellType.EXTERIOR_AIR:
                var vol = p_cell[].volume
                var rho = p_cell[].density
                var cp = p_cell[].specificHeat
                var kth = p_cell[].conductivity
                volumes.append(vol)
                masses.append(vol * rho)
                capacities.append(vol * rho * cp)
                weightedConductivity.append(vol * kth)
        if volumes.size == 0:
            volumes.append(1.0)
            masses.append(1.275)
            capacities.append(1.275 * 1007.0)
            weightedConductivity.append(0.02587)
        var totalVolume = sum(volumes)
        self.density = sum(masses) / totalVolume
        self.specificHeat = sum(capacities) / (totalVolume * self.density)
        self.conductivity = sum(weightedConductivity) / totalVolume

    def calcCellADEUp(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout U: UnsafePointer[Float64]):
        var theta = timestep * self.iHeatCapacity
        var C: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
        self.gatherCCoeffs(theta, foundation.coordinateSystem == Foundation.CS_CYLINDRICAL, C)
        var bit: Float64 = 1.0
        var divisor: Float64 = 1.0
        U[] = self.heatGain * theta
        for dim in self.dims:
            if dim < 5:
                bit -= C[dim][1]
                divisor -= C[dim][0]
                U[] += (self.told_ptr + self.stepsize[dim])[] * C[dim][1] - (U - self.stepsize[dim])[] * C[dim][0]
        U[] = (self.told_ptr[] * bit + U[]) / divisor

    def calcCellADEDown(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout V: UnsafePointer[Float64]):
        var theta = timestep * self.iHeatCapacity
        var C: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
        self.gatherCCoeffs(theta, foundation.coordinateSystem == Foundation.CS_CYLINDRICAL, C)
        var bit: Float64 = 1.0
        var divisor: Float64 = 1.0
        V[] = self.heatGain * theta
        for dim in self.dims:
            if dim < 5:
                bit += C[dim][0]
                divisor += C[dim][1]
                V[] += (V + self.stepsize[dim])[] * C[dim][1] - (self.told_ptr - self.stepsize[dim])[] * C[dim][0]
        V[] = (self.told_ptr[] * bit + V[]) / divisor

    def calcCellExplicit(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions) -> Float64:
        var theta = timestep * self.iHeatCapacity
        var C: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
        self.gatherCCoeffs(theta, foundation.coordinateSystem == Foundation.CS_CYLINDRICAL, C)
        var bit: Float64 = 1.0
        var TNew = self.heatGain * theta
        for dim in self.dims:
            if dim < 5:
                bit += C[dim][0] - C[dim][1]
                TNew += (self.told_ptr + self.stepsize[dim])[] * C[dim][1] - (self.told_ptr - self.stepsize[dim])[] * C[dim][0]
        TNew += self.told_ptr[] * bit
        return TNew

    def calcCellMatrix(inout self, scheme: Foundation.NumericalScheme, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Array[Float64, 2], 3], inout bVal: Float64):
        if scheme == Foundation.NS_STEADY_STATE:
            self.calcCellSteadyState(foundation, A, Alt, bVal)
        else:
            var theta = timestep * self.iHeatCapacity
            var f = 1.0 if scheme == Foundation.NS_IMPLICIT else 0.5
            var cylindrical = (foundation.coordinateSystem == Foundation.CS_CYLINDRICAL)
            var C: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
            self.gatherCCoeffs(theta, cylindrical, C)
            var bit: Float64 = 0.0
            bVal = self.heatGain * theta
            for dim in self.dims:
                if dim < 5:
                    bit += C[dim][1] - C[dim][0]
                    Alt[dim][1] = -f * C[dim][1]
                    Alt[dim][0] = f * C[dim][0]
                    bVal += (self.told_ptr + self.stepsize[dim])[] * (1.0 - f) * C[dim][1] - (self.told_ptr - self.stepsize[dim])[] * (1.0 - f) * C[dim][0]
            A = 1.0 + f * bit
            bVal += self.told_ptr[] * (1.0 - (1.0 - f) * bit)

    def calcCellSteadyState(inout self, foundation: Foundation, inout A: Float64, inout Alt: Array[Array[Float64, 2], 3], inout bVal: Float64):
        A = 0.0
        for dim in self.dims:
            if dim < 5:
                Alt[dim][1] = self.pde[dim][1]
                Alt[dim][0] = -self.pde[dim][0]
                A += Alt[dim][1] + Alt[dim][0]
        if foundation.coordinateSystem == Foundation.CS_CYLINDRICAL and self.coords[0] != 0:
            Alt[0][1] += self.pde_c[1] / self.r
            Alt[0][0] += -self.pde_c[0] / self.r
            A += self.pde_c[1] / self.r - self.pde_c[0] / self.r
        A *= -1.0
        bVal = -self.heatGain

    def calcCellADI(inout self, dim: Int, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Float64, 2], inout bVal: Float64):
        var theta = timestep * self.iHeatCapacityADI
        var Q = self.heatGain * theta
        if foundation.numberOfDimensions == 1:
            A = 1.0 + (self.pde[2][1] - self.pde[2][0]) * theta
            Alt[0] = self.pde[2][0] * theta
            Alt[1] = -self.pde[2][1] * theta
            bVal = self.told_ptr[] + Q
            return
        var f = foundation.fADI
        var multiplier = foundation.numberOfDimensions == 2 ? (2.0 - f) : (3.0 - 2.0 * f)
        var C: Array[Array[Float64, 2], 3] = Array[Array[Float64, 2], 3](Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0), Array[Float64, 2](0.0, 0.0))
        self.gatherCCoeffs(theta, foundation.coordinateSystem == Foundation.CS_CYLINDRICAL, C)
        self.ADImath(dim, Q, f, multiplier, C, A, Alt, bVal)

    def ADImath(inout self, dim: Int, Q: Float64, f: Float64, multiplier: Float64, C: Array[Array[Float64, 2], 3], inout A: Float64, inout Alt: Array[Float64, 2], inout bVal: Float64):
        bVal = Q
        var bit: Float64 = 0.0
        for sdim in self.dims:
            if sdim == dim:
                Alt[0] = multiplier * C[sdim][0]
                Alt[1] = -multiplier * C[sdim][1]
                A = 1.0 - (Alt[0] + Alt[1])
            elif sdim < 5:
                bit += C[sdim][0] - C[sdim][1]
                bVal += (self.told_ptr + self.stepsize[sdim])[] * f * C[sdim][1] - (self.told_ptr - self.stepsize[sdim])[] * f * C[sdim][0]
        bVal += self.told_ptr[] * (1.0 + f * bit)

    def gatherCCoeffs(inout self, theta: Float64, cylindrical: Bool, inout C: Array[Array[Float64, 2], 3]):
        for dim in self.dims:
            if dim < 5:
                C[dim][0] = self.pde[dim][0] * theta
                C[dim][1] = self.pde[dim][1] * theta
        if cylindrical and self.coords[0] != 0:
            C[0][0] += self.pde_c[0] * theta / self.r
            C[0][1] += self.pde_c[1] * theta / self.r

    def calculateHeatFlux(inout self, ndims: Int, inout TNew: Float64, nX: Int, nY: Int, nZ: Int, cell_v: List[Pointer[Cell]]) -> Array[Float64, 3]:
        var CXP: Float64 = 0.0
        var CXM: Float64 = 0.0
        var CYP: Float64 = 0.0
        var CYM: Float64 = 0.0
        var CZP = -self.kcoeff[2][1] * self.dist[2][0] / (self.dist[2][1] + self.dist[2][0]) / self.dist[2][1]
        var CZM = -self.kcoeff[2][0] * self.dist[2][1] / (self.dist[2][1] + self.dist[2][0]) / self.dist[2][0]
        if ndims > 1:
            CXP = -self.kcoeff[0][1] * self.dist[0][0] / (self.dist[0][1] + self.dist[0][0]) / self.dist[0][1]
            CXM = -self.kcoeff[0][0] * self.dist[0][1] / (self.dist[0][1] + self.dist[0][0]) / self.dist[0][0]
        if ndims == 3:
            CYP = -self.kcoeff[1][1] * self.dist[1][0] / (self.dist[1][1] + self.dist[1][0]) / self.dist[1][1]
            CYM = -self.kcoeff[1][0] * self.dist[1][1] / (self.dist[1][1] + self.dist[1][0]) / self.dist[1][0]
        var DTXP: Float64 = 0.0
        var DTXM: Float64 = 0.0
        var DTYP: Float64 = 0.0
        var DTYM: Float64 = 0.0
        var DTZP: Float64 = 0.0
        var DTZM: Float64 = 0.0
        # Using pointer to TNew for neighbor access (TNew is part of contiguous array)
        var pTNew = UnsafePointer[Float64](address_of(TNew))
        if self.coords[0] != nX - 1:
            DTXP = (pTNew + self.stepsize[0])[] - TNew
        if self.coords[0] != 0:
            DTXM = TNew - (pTNew - self.stepsize[0])[]
        if self.coords[1] != nY - 1:
            DTYP = (pTNew + self.stepsize[1])[] - TNew
        if self.coords[1] != 0:
            DTYM = TNew - (pTNew - self.stepsize[1])[]
        if self.coords[2] != nZ - 1:
            DTZP = (pTNew + self.stepsize[2])[] - TNew
        if self.coords[2] != 0:
            DTZM = TNew - (pTNew - self.stepsize[2])[]
        var Qx = CXP * DTXP + CXM * DTXM
        var Qy = CYP * DTYP + CYM * DTYM
        var Qz = CZP * DTZP + CZM * DTZM
        return Array[Float64, 3](Qx, Qy, Qz)

    def doOutdoorTemp(inout self, bcs: BoundaryConditions, inout A: Float64, inout bVal: Float64):
        A = 1.0
        bVal = bcs.outdoorTemp

    def doIndoorTemp(inout self, bcs: BoundaryConditions, inout A: Float64, inout bVal: Float64):
        A = 1.0
        bVal = bcs.slabConvectiveTemp

struct ExteriorAirCell:

    # Inherits from Cell
    var base: Cell

    def __init__(inout self, index: Int, cellType: CellType, i: Int, j: Int, k: Int, stepsize: Pointer[Int], foundation: Foundation, surfacePtr: Pointer[Surface], blockPtr: Pointer[Block], meshPtr: Pointer[Mesher]):
        self.base = Cell(index, cellType, i, j, k, stepsize, foundation, surfacePtr, blockPtr, meshPtr)

    def calcCellADEUp(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout U: UnsafePointer[Float64]):
        U[] = bcs.outdoorTemp

    def calcCellADEDown(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout V: UnsafePointer[Float64]):
        V[] = bcs.outdoorTemp

    def calcCellExplicit(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions) -> Float64:
        return bcs.outdoorTemp

    def calcCellADI(inout self, dim: Int, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Float64, 2], inout bVal: Float64):
        self.base.doOutdoorTemp(bcs, A, bVal)

    def calcCellMatrix(inout self, scheme: Foundation.NumericalScheme, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Array[Float64, 2], 3], inout bVal: Float64):
        self.base.doOutdoorTemp(bcs, A, bVal)

    def calculateHeatFlux(inout self, ndims: Int, inout TNew: Float64, nX: Int, nY: Int, nZ: Int, cell_v: List[Pointer[Cell]]) -> Array[Float64, 3]:
        return Array[Float64, 3](0.0, 0.0, 0.0)

struct InteriorAirCell:

    var base: Cell

    def __init__(inout self, index: Int, cellType: CellType, i: Int, j: Int, k: Int, stepsize: Pointer[Int], foundation: Foundation, surfacePtr: Pointer[Surface], blockPtr: Pointer[Block], meshPtr: Pointer[Mesher]):
        self.base = Cell(index, cellType, i, j, k, stepsize, foundation, surfacePtr, blockPtr, meshPtr)

    def calcCellADEUp(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout U: UnsafePointer[Float64]):
        U[] = bcs.slabConvectiveTemp

    def calcCellADEDown(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout V: UnsafePointer[Float64]):
        V[] = bcs.slabConvectiveTemp

    def calcCellExplicit(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions) -> Float64:
        return bcs.slabConvectiveTemp

    def calcCellADI(inout self, dim: Int, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Float64, 2], inout bVal: Float64):
        self.base.doIndoorTemp(bcs, A, bVal)

    def calcCellMatrix(inout self, scheme: Foundation.NumericalScheme, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Array[Float64, 2], 3], inout bVal: Float64):
        self.base.doIndoorTemp(bcs, A, bVal)

    def calculateHeatFlux(inout self, ndims: Int, inout TNew: Float64, nX: Int, nY: Int, nZ: Int, cell_v: List[Pointer[Cell]]) -> Array[Float64, 3]:
        return Array[Float64, 3](0.0, 0.0, 0.0)

struct BoundaryCell:

    var base: Cell

    def __init__(inout self, index: Int, cellType: CellType, i: Int, j: Int, k: Int, stepsize: Pointer[Int], foundation: Foundation, surfacePtr: Pointer[Surface], blockPtr: Pointer[Block], meshPtr: Pointer[Mesher]):
        self.base = Cell(index, cellType, i, j, k, stepsize, foundation, surfacePtr, blockPtr, meshPtr)
        if foundation.numberOfDimensions == 2 and foundation.coordinateSystem == Foundation.CS_CYLINDRICAL:
            if self.base.surfacePtr[].orientation == Surface.X_POS or self.base.surfacePtr[].orientation == Surface.X_NEG:
                self.base.area = 2.0 * PI * self.base.meshPtr[0].centers[self.base.coords[0]] * self.base.meshPtr[2].deltas[self.base.coords[2]]
            else:
                self.base.area = PI * (self.base.meshPtr[0].dividers[self.base.coords[0] + 1] * self.base.meshPtr[0].dividers[self.base.coords[0] + 1] - self.base.meshPtr[0].dividers[self.base.coords[0]] * self.base.meshPtr[0].dividers[self.base.coords[0]])
        elif foundation.numberOfDimensions == 2 and foundation.coordinateSystem == Foundation.CS_CARTESIAN:
            if self.base.surfacePtr[].orientation == Surface.X_POS or self.base.surfacePtr[].orientation == Surface.X_NEG:
                self.base.area = 2.0 * self.base.meshPtr[2].deltas[self.base.coords[2]] * foundation.linearAreaMultiplier
            else:
                self.base.area = 2.0 * self.base.meshPtr[0].deltas[self.base.coords[0]] * foundation.linearAreaMultiplier
        elif foundation.numberOfDimensions == 3:
            if self.base.surfacePtr[].orientation == Surface.X_POS or self.base.surfacePtr[].orientation == Surface.X_NEG:
                self.base.area = self.base.meshPtr[1].deltas[self.base.coords[1]] * self.base.meshPtr[2].deltas[self.base.coords[2]]
            elif self.base.surfacePtr[].orientation == Surface.Y_POS or self.base.surfacePtr[].orientation == Surface.Y_NEG:
                self.base.area = self.base.meshPtr[0].deltas[self.base.coords[0]] * self.base.meshPtr[2].deltas[self.base.coords[2]]
            else:
                self.base.area = self.base.meshPtr[0].deltas[self.base.coords[0]] * self.base.meshPtr[1].deltas[self.base.coords[1]]
            if foundation.useSymmetry:
                if foundation.isXSymm:
                    self.base.area = 2.0 * self.base.area
                if foundation.isYSymm:
                    self.base.area = 2.0 * self.base.area
        else:
            self.base.area = 1.0

    def calcCellADEUp(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout U: UnsafePointer[Float64]):
        var dim = self.base.surfacePtr[].orientation_dim
        var dir = self.base.surfacePtr[].orientation_dir
        if self.base.surfacePtr[].boundaryConditionType == Surface.ZERO_FLUX:
            self.zfCellADEUp(dim, dir, U)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.CONSTANT_TEMPERATURE:
            U[] = self.base.surfacePtr[].temperature
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_TEMPERATURE:
            U[] = bcs.slabConvectiveTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_TEMPERATURE:
            U[] = bcs.outdoorTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_FLUX:
            self.ifCellADEUp(dim, dir, U)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_FLUX:
            self.efCellADEUp(dim, dir, U)

    def calcCellADEDown(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout V: UnsafePointer[Float64]):
        var dim = self.base.surfacePtr[].orientation_dim
        var dir = self.base.surfacePtr[].orientation_dir
        if self.base.surfacePtr[].boundaryConditionType == Surface.ZERO_FLUX:
            self.zfCellADEDown(dim, dir, V)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.CONSTANT_TEMPERATURE:
            V[] = self.base.surfacePtr[].temperature
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_TEMPERATURE:
            V[] = bcs.slabConvectiveTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_TEMPERATURE:
            V[] = bcs.outdoorTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_FLUX:
            self.ifCellADEDown(dim, dir, V)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_FLUX:
            self.efCellADEDown(dim, dir, V)

    def calcCellExplicit(inout self, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions) -> Float64:
        var dim = self.base.surfacePtr[].orientation_dim
        var dir = self.base.surfacePtr[].orientation_dir
        if self.base.surfacePtr[].boundaryConditionType == Surface.ZERO_FLUX:
            return self.zfCellExplicit(dim, dir)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.CONSTANT_TEMPERATURE:
            return self.base.surfacePtr[].temperature
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_TEMPERATURE:
            return bcs.slabConvectiveTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_TEMPERATURE:
            return bcs.outdoorTemp
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_FLUX:
            return self.ifCellExplicit(dim, dir)
        else:
            return self.efCellExplicit(dim, dir)

    def calcCellADI(inout self, dim: Int, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Float64, 2], inout bVal: Float64):
        var sdim = self.base.surfacePtr[].orientation_dim
        var dir = self.base.surfacePtr[].orientation_dir
        if self.base.surfacePtr[].boundaryConditionType == Surface.ZERO_FLUX:
            self.zfCellADI(dim, sdim, dir, A, Alt[dir], bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.CONSTANT_TEMPERATURE:
            A = 1.0
            bVal = self.base.surfacePtr[].temperature
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_TEMPERATURE:
            self.base.doIndoorTemp(bcs, A, bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_TEMPERATURE:
            self.base.doOutdoorTemp(bcs, A, bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_FLUX:
            self.ifCellADI(dim, sdim, dir, A, Alt[dir], bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_FLUX:
            self.efCellADI(dim, sdim, dir, A, Alt[dir], bVal)

    def calcCellMatrix(inout self, scheme: Foundation.NumericalScheme, timestep: Float64, foundation: Foundation, bcs: BoundaryConditions, inout A: Float64, inout Alt: Array[Array[Float64, 2], 3], inout bVal: Float64):
        var dim = self.base.surfacePtr[].orientation_dim
        var dir = self.base.surfacePtr[].orientation_dir
        if self.base.surfacePtr[].boundaryConditionType == Surface.ZERO_FLUX:
            self.zfCellMatrix(A, Alt[dim][dir], bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.CONSTANT_TEMPERATURE:
            A = 1.0
            bVal = self.base.surfacePtr[].temperature
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_TEMPERATURE:
            self.base.doIndoorTemp(bcs, A, bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_TEMPERATURE:
            self.base.doOutdoorTemp(bcs, A, bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.INTERIOR_FLUX:
            self.ifCellMatrix(dim, dir, A, Alt[dim][dir], bVal)
        elif self.base.surfacePtr[].boundaryConditionType == Surface.EXTERIOR_FLUX:
            self.efCellMatrix(dim, dir, A, Alt[dim][dir], bVal)

    def calculateHeatFlux(inout self, ndims: Int, inout TNew: Float64, nX: Int, nY: Int, nZ: Int, cell_v: List[Pointer[Cell]]) -> Array[Float64, 3]:
        var CXP: Float64 = 0.0
        var CXM: Float64 = 0.0
        var CYP: Float64 = 0.0
        var CYM: Float64 = 0.0
        var CZP = -self.base.kcoeff[2][1] * self.base.dist[2][0] / (self.base.dist[2][1] + self.base.dist[2][0]) / self.base.dist[2][1]
        var CZM = -self.base.kcoeff[2][0] * self.base.dist[2][1] / (self.base.dist[2][1] + self.base.dist[2][0]) / self.base.dist[2][0]
        if ndims > 1:
            CXP = -self.base.kcoeff[0][1] * self.base.dist[0][0] / (self.base.dist[0][1] + self.base.dist[0][0]) / self.base.dist[0][1]
            CXM = -self.base.kcoeff[0][0] * self.base.dist[0][1] / (self.base.dist[0][1] + self.base.dist[0][0]) / self.base.dist[0][0]
        if ndims == 3:
            CYP = -self.base.kcoeff[1][1] * self.base.dist[1][0] / (self.base.dist[1][1] + self.base.dist[1][0]) / self.base.dist[1][1]
            CYM = -self.base.kcoeff[1][0] * self.base.dist[1][1] / (self.base.dist[1][1] + self.base.dist[1][0]) / self.base.dist[1][0]
        var DTXP: Float64 = 0.0
        var DTXM: Float64 = 0.0
        var DTYP: Float64 = 0.0
        var DTYM: Float64 = 0.0
        var DTZP: Float64 = 0.0
        var DTZM: Float64 = 0.0
        var pTNew = UnsafePointer[Float64](address_of(TNew))
        if self.base.coords[0] != nX - 1:
            DTXP = (pTNew + self.base.stepsize[0])[] - TNew
        if self.base.coords[0] != 0:
            DTXM = TNew - (pTNew - self.base.stepsize[0])[]
        if self.base.coords[1] != nY - 1:
            DTYP = (pTNew + self.base.stepsize[1])[] - TNew
        if self.base.coords[1] != 0:
            DTYM = TNew - (pTNew - self.base.stepsize[1])[]
        if self.base.coords[2] != nZ - 1:
            DTZP = (pTNew + self.base.stepsize[2])[] - TNew
        if self.base.coords[2] != 0:
            DTZM = TNew - (pTNew - self.base.stepsize[2])[]
        if self.base.surfacePtr[].orientation == Surface.X_NEG:
            CXP = -self.base.kcoeff[0][1] / self.base.dist[0][1]
            CXM = 0.0
        elif self.base.surfacePtr[].orientation == Surface.X_POS:
            CXP = 0.0
            CXM = -self.base.kcoeff[0][0] / self.base.dist[0][0]
        elif self.base.surfacePtr[].orientation == Surface.Y_NEG:
            CYP = -self.base.kcoeff[1][1] / self.base.dist[1][1]
            CYM = 0.0
        elif self.base.surfacePtr[].orientation == Surface.Y_POS:
            CYP = 0.0
            CYM = -self.base.kcoeff[1][0] / self.base.dist[1][0]
        elif self.base.surfacePtr[].orientation == Surface.Z_NEG:
            CZP = -self.base.kcoeff[2][1] / self.base.dist[2][1]
            CZM = 0.0
        elif self.base.surfacePtr[].orientation == Surface.Z_POS:
            CZP = 0.0
            CZM = -self.base.kcoeff[2][0] / self.base.dist[2][0]
        var Qx = CXP * DTXP + CXM * DTXM
        var Qy = CYP * DTYP + CYM * DTYM
        var Qz = CZP * DTZP + CZM * DTZM
        return Array[Float64, 3](Qx, Qy, Qz)

    # Helper macros expanded as methods
    def INTFLUX_PREFACE(inout self) -> (Float64, Float64, Float64):
        var Tair = self.base.surfacePtr[].temperature
        var Trad = self.base.surfacePtr[].radiantTemperature
        var cosTilt = self.base.surfacePtr[].cosTilt
        var hc = self.base.surfacePtr[].convectionAlgorithm(self.base.told_ptr[], Tair, self.base.surfacePtr[].hfTerm, self.base.surfacePtr[].propPtr[].roughness, cosTilt)
        var hr = getSimpleInteriorIRCoeff(self.base.surfacePtr[].propPtr[].emissivity, self.base.told_ptr[], Trad)
        return (Tair, Trad, hc, hr)

    def EXTFLUX_PREFACE(inout self) -> (Float64, Float64, Float64, Float64):
        var Tair = self.base.surfacePtr[].temperature
        var cosTilt = self.base.surfacePtr[].cosTilt
        var Fqtr = self.base.surfacePtr[].effectiveLWViewFactorQtr
        var hc = self.base.surfacePtr[].convectionAlgorithm(self.base.told_ptr[], Tair, self.base.surfacePtr[].hfTerm, self.base.surfacePtr[].propPtr[].roughness, cosTilt)
        var hr = getExteriorIRCoeff(self.base.surfacePtr[].propPtr[].emissivity, self.base.told_ptr[], Tair, Fqtr)
        return (Tair, cosTilt, Fqtr, hc, hr)

    def zfCellADI(inout self, dim: Int, sdim: Int, sign: Int, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        A = 1.0
        if dim == sdim:
            Alt = -1.0
            bVal = 0.0
        else:
            Alt = 0.0
            bVal = (self.base.told_ptr + sign * self.base.stepsize[sdim])[]

    def ifCellADI(inout self, dim: Int, sdim: Int, dir: Int, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        var (Tair, Trad, hc, hr) = self.INTFLUX_PREFACE()
        var sign = -1 if dir == 0 else 1
        A = self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir] + (hc + hr)
        if dim == sdim:
            Alt = -self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir]
            bVal = hc * Tair + hr * Trad + self.base.heatGain
        else:
            Alt = 0.0
            bVal = (self.base.told_ptr + sign * self.base.stepsize[sdim])[] * self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir] + hc * Tair + hr * Trad + self.base.heatGain

    def efCellADI(inout self, dim: Int, sdim: Int, dir: Int, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        var (Tair, cosTilt, Fqtr, hc, hr) = self.EXTFLUX_PREFACE()
        var sign = -1 if dir == 0 else 1
        A = self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir] + (hc + hr)
        if dim == sdim:
            Alt = -self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir]
            bVal = (hc + hr * Fqtr) * Tair + self.base.heatGain
        else:
            Alt = 0.0
            bVal = (self.base.told_ptr + sign * self.base.stepsize[sdim])[] * self.base.kcoeff[sdim][dir] / self.base.dist[sdim][dir] + (hc + hr * Fqtr) * Tair + self.base.heatGain

    def zfCellMatrix(inout self, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        A = 1.0
        Alt = -1.0
        bVal = 0.0

    def ifCellMatrix(inout self, dim: Int, dir: Int, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        var (Tair, Trad, hc, hr) = self.INTFLUX_PREFACE()
        A = self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr)
        Alt = -self.base.kcoeff[dim][dir] / self.base.dist[dim][dir]
        bVal = hc * Tair + hr * Trad + self.base.heatGain

    def efCellMatrix(inout self, dim: Int, dir: Int, inout A: Float64, inout Alt: Float64, inout bVal: Float64):
        var (Tair, cosTilt, Fqtr, hc, hr) = self.EXTFLUX_PREFACE()
        A = self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr)
        Alt = -self.base.kcoeff[dim][dir] / self.base.dist[dim][dir]
        bVal = (hc + hr * Fqtr) * Tair + self.base.heatGain

    def zfCellADEUp(inout self, dim: Int, dir: Int, inout U: UnsafePointer[Float64]):
        if dir == 1:
            U[] = (self.base.told_ptr + self.base.stepsize[dim])[]
        else:
            U[] = (U - self.base.stepsize[dim])[]

    def ifCellADEUp(inout self, dim: Int, dir: Int, inout U: UnsafePointer[Float64]):
        var (Tair, Trad, hc, hr) = self.INTFLUX_PREFACE()
        var bit: Float64
        if dir == 1:
            bit = (self.base.told_ptr + self.base.stepsize[dim])[]
        else:
            bit = (U - self.base.stepsize[dim])[]
        U[] = (self.base.kcoeff[dim][dir] * bit / self.base.dist[dim][dir] + hc * Tair + hr * Trad + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

    def efCellADEUp(inout self, dim: Int, dir: Int, inout U: UnsafePointer[Float64]):
        var (Tair, cosTilt, Fqtr, hc, hr) = self.EXTFLUX_PREFACE()
        var bit: Float64
        if dir == 1:
            bit = (self.base.told_ptr + self.base.stepsize[dim])[]
        else:
            bit = (U - self.base.stepsize[dim])[]
        U[] = (self.base.kcoeff[dim][dir] * bit / self.base.dist[dim][dir] + (hc + hr * Fqtr) * Tair + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

    def zfCellADEDown(inout self, dim: Int, dir: Int, inout V: UnsafePointer[Float64]):
        if dir == 1:
            V[] = (V + self.base.stepsize[dim])[]
        else:
            V[] = (self.base.told_ptr - self.base.stepsize[dim])[]

    def ifCellADEDown(inout self, dim: Int, dir: Int, inout V: UnsafePointer[Float64]):
        var (Tair, Trad, hc, hr) = self.INTFLUX_PREFACE()
        var bit: Float64
        if dir == 1:
            bit = (V + self.base.stepsize[dim])[]
        else:
            bit = (self.base.told_ptr - self.base.stepsize[dim])[]
        V[] = (self.base.kcoeff[dim][dir] * bit / self.base.dist[dim][dir] + hc * Tair + hr * Trad + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

    def efCellADEDown(inout self, dim: Int, dir: Int, inout V: UnsafePointer[Float64]):
        var (Tair, cosTilt, Fqtr, hc, hr) = self.EXTFLUX_PREFACE()
        var bit: Float64
        if dir == 1:
            bit = (V + self.base.stepsize[dim])[]
        else:
            bit = (self.base.told_ptr - self.base.stepsize[dim])[]
        V[] = (self.base.kcoeff[dim][dir] * bit / self.base.dist[dim][dir] + (hc + hr * Fqtr) * Tair + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

    def zfCellExplicit(inout self, dim: Int, dir: Int) -> Float64:
        var sign = -1 if dir == 0 else 1
        return (self.base.told_ptr + sign * self.base.stepsize[dim])[]

    def ifCellExplicit(inout self, dim: Int, dir: Int) -> Float64:
        var (Tair, Trad, hc, hr) = self.INTFLUX_PREFACE()
        var sign = -1 if dir == 0 else 1
        return (self.base.kcoeff[dim][dir] * (self.base.told_ptr + sign * self.base.stepsize[dim])[] / self.base.dist[dim][dir] + hc * Tair + hr * Trad + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

    def efCellExplicit(inout self, dim: Int, dir: Int) -> Float64:
        var (Tair, cosTilt, Fqtr, hc, hr) = self.EXTFLUX_PREFACE()
        return (self.base.kcoeff[dim][dir] * (self.base.told_ptr + self.base.stepsize[dim])[] / self.base.dist[dim][dir] + (hc + hr * Fqtr) * Tair + self.base.heatGain) / (self.base.kcoeff[dim][dir] / self.base.dist[dim][dir] + (hc + hr))

struct ZeroThicknessCell:

    var base: Cell

    def __init__(inout self, index: Int, cellType: CellType, i: Int, j: Int, k: Int, stepsize: Pointer[Int], foundation: Foundation, surfacePtr: Pointer[Surface], blockPtr: Pointer[Block], meshPtr: Pointer[Mesher]):
        self.base = Cell(index, cellType, i, j, k, stepsize, foundation, surfacePtr, blockPtr, meshPtr)

    def calculateHeatFlux(inout self, ndims: Int, inout TNew: Float64, nX: Int, nY: Int, nZ: Int, cell_v: List[Pointer[Cell]]) -> Array[Float64, 3]:
        var Qm: Array[Float64, 3]
        var Qp: Array[Float64, 3]
        if isEqual(self.base.meshPtr[0].deltas[self.base.coords[0]], 0.0):
            var pTNew = UnsafePointer[Float64](address_of(TNew))
            Qm = cell_v[self.base.index - self.base.stepsize[0]].[].calculateHeatFlux(ndims, (pTNew - self.base.stepsize[0])[], nX, nY, nZ, cell_v)
            Qp = cell_v[self.base.index + self.base.stepsize[0]].[].calculateHeatFlux(ndims, (pTNew + self.base.stepsize[0])[], nX, nY, nZ, cell_v)
        if isEqual(self.base.meshPtr[1].deltas[self.base.coords[1]], 0.0):
            var pTNew = UnsafePointer[Float64](address_of(TNew))
            Qm = cell_v[self.base.index - self.base.stepsize[1]].[].calculateHeatFlux(ndims, (pTNew - self.base.stepsize[1])[], nX, nY, nZ, cell_v)
            Qp = cell_v[self.base.index + self.base.stepsize[1]].[].calculateHeatFlux(ndims, (pTNew + self.base.stepsize[1])[], nX, nY, nZ, cell_v)
        if isEqual(self.base.meshPtr[2].deltas[self.base.coords[2]], 0.0):
            var pTNew = UnsafePointer[Float64](address_of(TNew))
            Qm = cell_v[self.base.index - self.base.stepsize[2]].[].calculateHeatFlux(ndims, (pTNew - self.base.stepsize[2])[], nX, nY, nZ, cell_v)
            Qp = cell_v[self.base.index + self.base.stepsize[2]].[].calculateHeatFlux(ndims, (pTNew + self.base.stepsize[2])[], nX, nY, nZ, cell_v)
        var Qx = (Qm[0] + Qp[0]) * 0.5
        var Qy = (Qm[1] + Qp[1]) * 0.5
        var Qz = (Qm[2] + Qp[2]) * 0.5
        return Array[Float64, 3](Qx, Qy, Qz)

# (end of namespace Kiva)