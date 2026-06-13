/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
#undef PRNTSURF
from Ground.hpp import Ground as GroundHpp
from Errors.hpp import showMessage, MSG_ERR
from Algorithms.hpp import solveTDM, getSimpleInteriorIRCoeff, getEffectiveExteriorViewFactor
from BoundaryConditions.hpp import BoundaryConditions
from Domain.hpp import Domain
from Foundation.hpp import Foundation
from GroundOutput.hpp import GroundOutput
from Mesher.hpp import Mesher
from math import atan, cos, sin, sqrt, PI
from memory import Pointer
from utils import String
from vector import DynamicVector
from tensor import Tensor
from random import randint

alias PI = 4.0 * atan(1.0)
alias TDMA = True

@value
struct Ground:
    var domain: Domain
    var foundation: Foundation
    var groundOutput: GroundOutput
    var nX: Int
    var nY: Int
    var nZ: Int
    var num_cells: Int
    var TNew: DynamicVector[Float64]
    var TOld: DynamicVector[Float64]
    var timestep: Float64
    var bcs: BoundaryConditions
    var U: DynamicVector[Float64]
    var V: DynamicVector[Float64]
    var a1: DynamicVector[Float64]
    var a2: DynamicVector[Float64]
    var a3: DynamicVector[Float64]
    var b_: DynamicVector[Float64]
    var x_: DynamicVector[Float64]
    var Amat: Tensor[Float64]
    var tripletList: DynamicVector[Tuple[Int, Int, Float64]]
    var b: Tensor[Float64]
    var x: Tensor[Float64]
    var pSolver: Pointer[Eigen.BiCGSTAB[Eigen.SparseMatrix[Float64], Eigen.IncompleteLUT[Float64]]]
    var boundaryLayer: DynamicVector[Tuple[Float64, Float64]]

    def __init__(inout self, foundation: Foundation):
        self.foundation = foundation
        self.pSolver = Pointer[Eigen.BiCGSTAB[Eigen.SparseMatrix[Float64], Eigen.IncompleteLUT[Float64]]].alloc()
        self.pSolver[].setMaxIterations(foundation.maxIterations)
        self.pSolver[].setTolerance(foundation.tolerance)

    def __init__(inout self, foundation: Foundation, outputMap: GroundOutput.OutputMap):
        self.foundation = foundation
        self.groundOutput = GroundOutput(outputMap)
        self.pSolver = Pointer[Eigen.BiCGSTAB[Eigen.SparseMatrix[Float64], Eigen.IncompleteLUT[Float64]]].alloc()
        self.pSolver[].setMaxIterations(foundation.maxIterations)
        self.pSolver[].setTolerance(foundation.tolerance)

    def __del__(owned self):

    def buildDomain(inout self):
        self.foundation.createMeshData()
        self.domain.setDomain(self.foundation)
        self.nX = self.domain.mesh[0].centers.size()
        self.nY = self.domain.mesh[1].centers.size()
        self.nZ = self.domain.mesh[2].centers.size()
        self.num_cells = self.nX * self.nY * self.nZ
        if self.foundation.numericalScheme == Foundation.NS_ADE:
            self.U = DynamicVector[Float64](self.num_cells)
            self.V = DynamicVector[Float64](self.num_cells)
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            self.a1 = DynamicVector[Float64](self.num_cells, 0.0)
            self.a2 = DynamicVector[Float64](self.num_cells, 0.0)
            self.a3 = DynamicVector[Float64](self.num_cells, 0.0)
            self.b_ = DynamicVector[Float64](self.num_cells, 0.0)
            self.x_ = DynamicVector[Float64](self.num_cells)
        self.pSolver[].setMaxIterations(self.foundation.maxIterations)
        self.pSolver[].setTolerance(self.foundation.tolerance)
        self.tripletList = DynamicVector[Tuple[Int, Int, Float64]](self.num_cells * (1 + 2 * self.foundation.numberOfDimensions))
        self.Amat = Tensor[Float64](self.num_cells, self.num_cells)
        self.b = Tensor[Float64](self.num_cells)
        self.x = Tensor[Float64](self.num_cells)
        self.x.fill(283.15)
        self.TNew = DynamicVector[Float64](self.num_cells)
        self.TOld = DynamicVector[Float64](self.num_cells)
        self.link_cells_to_temp()

    def calculateADE(inout self):
        #if defined(_OPENMP)
        #pragma omp parallel sections num_threads(2)
        #endif
        {
            #if defined(_OPENMP)
            #pragma omp section
            #endif
            self.calculateADEUpwardSweep()
            #if defined(_OPENMP)
            #pragma omp section
            #endif
            self.calculateADEDownwardSweep()
        }
        for index in range(self.num_cells):
            self.TNew[index] = 0.5 * (self.U[index] + self.V[index])
            self.TOld[index] = self.TNew[index]

    def calculateADEUpwardSweep(inout self):
        for index in range(self.num_cells):
            var this_cell = self.domain.cell[index]
            this_cell.calcCellADEUp(self.timestep, self.foundation, self.bcs, self.U[index])

    def calculateADEDownwardSweep(inout self):
        for n in range(self.num_cells, 0, -1):
            var index = n - 1
            var this_cell = self.domain.cell[index]
            this_cell.calcCellADEDown(self.timestep, self.foundation, self.bcs, self.V[index])

    def calculateExplicit(inout self):
        for index in range(self.num_cells):
            var this_cell = self.domain.cell[index]
            self.TNew[index] = this_cell.calcCellExplicit(self.timestep, self.foundation, self.bcs)
        self.TOld = self.TNew.copy()

    def calculateMatrix(inout self, scheme: Foundation.NumericalScheme):
        for index in range(self.num_cells):
            var this_cell = self.domain.cell[index]
            var A: Float64
            var bVal: Float64
            var Alt: Tensor[Float64] = Tensor[Float64](3, 2)
            Alt.fill(0.0)
            this_cell.calcCellMatrix(scheme, self.timestep, self.foundation, self.bcs, A, Alt, bVal)
            self.setAmatValue(index, index, A)
            for dim in range(3):
                if Alt[dim, 0] != 0:
                    self.setAmatValue(index, this_cell.index - self.domain.stepsize[dim], Alt[dim, 0])
                if Alt[dim, 1] != 0:
                    self.setAmatValue(index, this_cell.index + self.domain.stepsize[dim], Alt[dim, 1])
            self.setbValue(index, bVal)
        self.solveLinearSystem()
        self.TNew = self.getXvalues()
        self.TOld = self.TNew.copy()
        self.clearAmat()

    def calculateADI(inout self, dim: Int):
        var A: Float64
        var Alt: Tensor[Float64] = Tensor[Float64](2)
        var bVal: Float64
        var dest_index = self.domain.dest_index_vector[dim].begin()
        var cell_iter = self.domain.cell.begin()
        while dest_index < self.domain.dest_index_vector[dim].end():
            A = 0.0
            Alt[0] = 0.0
            Alt[1] = 0.0
            bVal = 0.0
            cell_iter[].calcCellADI(dim, self.timestep, self.foundation, self.bcs, A, Alt, bVal)
            self.setValuesADI(dest_index[], A, Alt, bVal)
            dest_index += 1
            cell_iter += 1
        self.solveLinearSystem()
        var index: Int = 0
        dest_index = self.domain.dest_index_vector[dim].begin()
        while dest_index < self.domain.dest_index_vector[dim].end():
            self.TNew[index] = self.x_[dest_index[]]
            index += 1
            dest_index += 1
        self.TOld = self.TNew.copy()
        self.clearAmat()

    def calculate(inout self, boundaryConditions: BoundaryConditions, ts: Float64 = 0.0):
        self.bcs = boundaryConditions
        self.timestep = ts
        self.setBoundaryConditions()
        if self.foundation.numericalScheme == Foundation.NS_ADE:
            self.calculateADE()
        elif self.foundation.numericalScheme == Foundation.NS_EXPLICIT:
            self.calculateExplicit()
        elif self.foundation.numericalScheme == Foundation.NS_ADI:
            if self.foundation.numberOfDimensions > 1:
                self.calculateADI(0)
            if self.foundation.numberOfDimensions == 3:
                self.calculateADI(1)
            self.calculateADI(2)
        elif self.foundation.numericalScheme == Foundation.NS_IMPLICIT:
            self.calculateMatrix(Foundation.NS_IMPLICIT)
        elif self.foundation.numericalScheme == Foundation.NS_CRANK_NICOLSON:
            self.calculateMatrix(Foundation.NS_CRANK_NICOLSON)
        elif self.foundation.numericalScheme == Foundation.NS_STEADY_STATE:
            self.calculateMatrix(Foundation.NS_STEADY_STATE)

    def setAmatValue(inout self, i: Int, j: Int, val: Float64):
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            if j < i:
                self.a1[i] = val
            elif j == i:
                self.a2[i] = val
            else:
                self.a3[i] = val
        else:
            self.tripletList.push_back((i, j, val))

    def setbValue(inout self, i: Int, val: Float64):
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            self.b_[i] = val
        else:
            self.b[i] = val

    def setValuesADI(inout self, index: Int, A: Float64, Alt: Tensor[Float64], bVal: Float64):
        self.a1[index] = Alt[0]
        self.a2[index] = A
        self.a3[index] = Alt[1]
        self.b_[index] = bVal

    def solveLinearSystem(inout self):
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            solveTDM(self.a1, self.a2, self.a3, self.b_, self.x_)
        else:
            var iters: Int
            var residual: Float64
            var success: Bool
            self.Amat.setFromTriplets(self.tripletList.begin(), self.tripletList.end())
            self.pSolver[].compute(self.Amat)
            self.x = self.pSolver[].solveWithGuess(self.b, self.x)
            var status = self.pSolver[].info()
            success = status == Eigen.Success
            if not success:
                iters = self.pSolver[].iterations()
                residual = self.pSolver[].error()
                var ss = String()
                ss += "Solution did not converge after " + str(iters) + " iterations. The final residual was: ("
                ss += str(residual) + ")."
                showMessage(MSG_ERR, ss)

    def clearAmat(inout self):
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            for i in range(self.a1.size()):
                self.a1[i] = 0.0
            for i in range(self.a2.size()):
                self.a2[i] = 0.0
            for i in range(self.a3.size()):
                self.a3[i] = 0.0
            for i in range(self.b_.size()):
                self.b_[i] = 0.0
        else:
            self.tripletList.clear()
            self.tripletList.reserve(self.nX * self.nY * self.nZ * (1 + 2 * self.foundation.numberOfDimensions))

    def getxValue(inout self, i: Int) -> Float64:
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            return self.x_[i]
        else:
            return self.x[i]

    def getXvalues(inout self) -> DynamicVector[Float64]:
        if (self.foundation.numericalScheme == Foundation.NS_ADI or self.foundation.numberOfDimensions == 1) and TDMA:
            return self.x_
        else:
            var v = DynamicVector[Float64](self.x.size())
            for i in range(self.x.size()):
                v[i] = self.x[i]
            return v

    def getSurfaceArea(inout self, surfaceType: Surface.SurfaceType) -> Float64:
        var totalArea: Float64 = 0
        for surface in self.foundation.surfaces:
            if surface.type == surfaceType:
                totalArea += surface.area
        return totalArea

    def calculateSurfaceAverages(inout self):
        for surfaceType in self.groundOutput.outputMap:
            var constructionRValue: Float64 = 0.0
            var surfaceArea: Float64 = self.foundation.surfaceAreas[surfaceType]
            if surfaceType == Surface.ST_SLAB_CORE:
                constructionRValue = self.foundation.slab.totalResistance()
            elif surfaceType == Surface.ST_SLAB_PERIM:
                constructionRValue = self.foundation.slab.totalResistance()
            elif surfaceType == Surface.ST_WALL_INT:
                constructionRValue = self.foundation.wall.totalResistance()
            var totalQ: Float64 = 0.0
            var totalQc: Float64 = 0.0
            var TA: Float64 = 0
            var hA: Float64 = 0.0
            var hcA: Float64 = 0.0
            var hrA: Float64 = 0.0
            var totalArea: Float64 = 0.0
            var TAconv: Float64 = 0.0
            if self.foundation.hasSurface[surfaceType]:
                for surface in self.foundation.surfaces:
                    if surface.type == surfaceType:
                        var Trad: Float64 = surface.radiantTemperature
                        var Tair: Float64 = surface.temperature
                        #ifdef PRNTSURF
                        #var output = std.ofstream()
                        #output.open("surface.csv")
                        #output << "x, T, h, q, dx\n"
                        #endif
                        for index in surface.indices:
                            var this_cell = self.domain.cell[index]
                            var hc: Float64 = surface.convectionAlgorithm(self.TNew[index], Tair, surface.hfTerm,
                                                                    surface.propPtr.roughness, surface.cosTilt)
                            var hr: Float64 = getSimpleInteriorIRCoeff(surface.propPtr.emissivity, self.TNew[index], Trad)
                            var q: Float64 = this_cell.heatGain
                            var A: Float64 = this_cell.area
                            var Ahc: Float64 = A * hc
                            var Ahr: Float64 = A * hr
                            var Qc: Float64 = Ahc * (Tair - self.TNew[index])
                            var Qr: Float64 = Ahr * (Trad - self.TNew[index])
                            totalArea += A
                            hcA += Ahc
                            hrA += Ahr
                            hA += Ahc + Ahr
                            totalQc += Qc
                            totalQ += Qc + Qr + q * A
                            TA += self.TNew[index] * A
                            TAconv += Tair * A
                            #ifdef PRNTSURF
                            #output << self.domain.mesh[0].centers[i] << ", " << self.TNew[index] << ", " << h << ", "
                            #       << h * (Tair - self.TNew[index]) << ", " << self.domain.mesh[0].deltas[i] << "\n"
                            #endif
                        #ifdef PRNTSURF
                        #output.close()
                        #endif
            if totalArea > 0.0:
                var Tconv: Float64 = TAconv / totalArea
                var Tavg: Float64 = hcA == 0 ? Tconv : Tconv - totalQc / hcA
                var hcAvg: Float64 = hcA / totalArea
                var hrAvg: Float64 = hrA / totalArea
                var hAvg: Float64 = hA / totalArea
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_TEMP)] = Tavg
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_AVG_TEMP)] = TA / totalArea
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_FLUX)] = totalQ / totalArea
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_RATE)] = totalQ / totalArea * surfaceArea
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_CONV)] = hcAvg
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_RAD)] = hrAvg
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_EFF_TEMP)] = Tconv - (totalQ / totalArea) * (constructionRValue + 1 / hAvg) - 273.15
            else:
                var Tconv: Float64 = self.bcs.slabConvectiveTemp
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_TEMP)] = Tconv
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_AVG_TEMP)] = Tconv
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_FLUX)] = 0.0
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_RATE)] = 0.0
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_CONV)] = 0.0
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_RAD)] = 0.0
                self.groundOutput.outputValues[(surfaceType, GroundOutput.OT_EFF_TEMP)] = Tconv - 273.15

    def getSurfaceAverageValue(inout self, output: Tuple[Surface.SurfaceType, GroundOutput.OutputType]) -> Float64:
        return self.groundOutput.outputValues[output]

    def calculateBoundaryLayer(inout self):
        var fd: Foundation = self.foundation
        var preBCs: BoundaryConditions
        preBCs.localWindSpeed = 0
        preBCs.outdoorTemp = 273.15
        preBCs.slabConvectiveTemp = preBCs.wallConvectiveTemp = preBCs.slabRadiantTemp = preBCs.wallRadiantTemp = 293.15
        fd.coordinateSystem = Foundation.CS_CARTESIAN
        fd.numberOfDimensions = 2
        fd.reductionStrategy = Foundation.RS_AP
        fd.numericalScheme = Foundation.NS_STEADY_STATE
        fd.farFieldWidth = 100
        var pre: Ground = Ground(fd)
        pre.buildDomain()
        pre.calculate(preBCs)
        var x2s: DynamicVector[Float64]
        var fluxSums: DynamicVector[Float64]
        var fluxSum: Float64 = 0.0
        var x1_0: Float64 = 0.0
        var firstIndex: Bool = True
        var i_min: Int = pre.domain.mesh[0].getNearestIndex(boost.geometry.area(self.foundation.polygon) / boost.geometry.perimeter(self.foundation.polygon))
        var k: Int = pre.domain.mesh[2].getNearestIndex(0.0)
        var j: Int = pre.nY / 2
        for i in range(i_min, pre.nX):
            var index: Int = pre.domain.getIndex(i, j, k)
            var Qz: Float64 = pre.domain.cell[index].calculateHeatFlux(pre.foundation.numberOfDimensions, pre.TNew[index], pre.nX, pre.nY, pre.nZ, pre.domain.cell)[2]
            var x1: Float64 = pre.domain.mesh[0].dividers[i]
            var x2: Float64 = pre.domain.mesh[0].dividers[i + 1]
            if Qz > 0.0:
                fluxSum += max(Qz, 0.0) * (x2 - x1)
                if firstIndex:
                    x1_0 = x1
                x2s.push_back(x2)
                fluxSums.push_back(fluxSum)
                firstIndex = False
        self.boundaryLayer.push_back((0, 0))
        for i in range(fluxSums.size() - 1):
            self.boundaryLayer.push_back((x2s[i] - x1_0, fluxSums[i] / fluxSum))

    def getBoundaryValue(inout self, dist: Float64) -> Float64:
        var val: Float64 = 0.0
        if dist > self.boundaryLayer[self.boundaryLayer.size() - 1].first:
            val = 1.0
        else:
            for i in range(self.boundaryLayer.size() - 1):
                if dist >= self.boundaryLayer[i].first and dist < self.boundaryLayer[i + 1].first:
                    var m: Float64 = (self.boundaryLayer[i + 1].first - self.boundaryLayer[i].first) / (self.boundaryLayer[i + 1].second - self.boundaryLayer[i].second)
                    val = (dist - self.boundaryLayer[i].first) / m + self.boundaryLayer[i].second
                    continue
        return val

    def getBoundaryDistance(inout self, val: Float64) -> Float64:
        var dist: Float64 = 0.0
        if val > 1.0 or val < 0.0:
            showMessage(MSG_ERR, "Boundary value passed not between 0.0 and 1.0.")
        else:
            for i in range(self.boundaryLayer.size() - 1):
                if val >= self.boundaryLayer[i].second and val < self.boundaryLayer[i + 1].second:
                    var m: Float64 = (self.boundaryLayer[i + 1].second - self.boundaryLayer[i].second) / (self.boundaryLayer[i + 1].first - self.boundaryLayer[i].first)
                    dist = (val - self.boundaryLayer[i].second) / m + self.boundaryLayer[i].first
                    continue
        return dist

    def setNewBoundaryGeometry(inout self):
        var area: Float64 = boost.geometry.area(self.foundation.polygon)
        var perimeter: Float64 = boost.geometry.perimeter(self.foundation.polygon)
        var interiorPerimeter: Float64 = 0.0
        var nV: Int = self.foundation.polygon.outer().size()
        for v in range(nV):
            var vPrev: Int
            var vNext: Int
            var vNext2: Int
            if v == 0:
                vPrev = nV - 1
            else:
                vPrev = v - 1
            if v == nV - 1:
                vNext = 0
            else:
                vNext = v + 1
            if v == nV - 2:
                vNext2 = 0
            elif v == nV - 1:
                vNext2 = 1
            else:
                vNext2 = v + 2
            var p1: Point = self.foundation.polygon.outer()[vPrev]
            var p2: Point = self.foundation.polygon.outer()[v]
            var p3: Point = self.foundation.polygon.outer()[vNext]
            var p4: Point = self.foundation.polygon.outer()[vNext2]
            if self.foundation.isExposedPerimeter[vPrev] and self.foundation.isExposedPerimeter[v] and self.foundation.isExposedPerimeter[vNext]:
                if isEqual(getAngle(p1, p2, p3) + getAngle(p2, p3, p4), PI):
                    var d12: Float64 = getDistance(p1, p2)
                    var d23: Float64 = getDistance(p2, p3)
                    var d43: Float64 = getDistance(p3, p4)
                    var edgeDistance: Float64 = d23
                    var reductionDistance: Float64 = min(d12, d43)
                    var reductionValue: Float64 = 1 - self.getBoundaryValue(edgeDistance)
                    perimeter -= 2 * reductionDistance * reductionValue
            if self.foundation.isExposedPerimeter[vPrev] and self.foundation.isExposedPerimeter[v]:
                var alpha: Float64 = getAngle(p1, p2, p3)
                var d12: Float64 = getDistance(p1, p2)
                var d23: Float64 = getDistance(p2, p3)
                if sin(alpha) > 0:
                    var f: Float64 = self.getBoundaryDistance(1 - sin(alpha / 2) / (1 + cos(alpha / 2))) / sin(alpha / 2)
                    var d: Float64 = f / cos(alpha / 2)
                    if d12 < d or d23 < d:
                        d12 = min(d12, d23)
                        d23 = min(d12, d23)
                    else:
                        d12 = d
                        d23 = d
                    var d13: Float64 = sqrt(d12 * d12 + d23 * d23 - 2 * d12 * d23 * cos(alpha))
                    perimeter += d13 - (d12 + d23)
            if not self.foundation.isExposedPerimeter[v]:
                interiorPerimeter += getDistance(p2, p3)
        self.foundation.reductionStrategy = Foundation.RS_CUSTOM
        self.foundation.twoParameters = False
        self.foundation.reductionLength2 = area / (perimeter - interiorPerimeter)

    def setBoundaryConditions(inout self):
        var azi: Float64 = self.bcs.solarAzimuth
        var alt: Float64 = self.bcs.solarAltitude
        var qDN: Float64 = self.bcs.directNormalFlux
        var qDH: Float64 = self.bcs.diffuseHorizontalFlux
        var qGH: Float64 = cos(PI / 2 - alt) * qDN + qDH
        var cosAlt: Float64 = cos(alt)
        for surface in self.foundation.surfaces:
            if surface.type == Surface.ST_GRADE or surface.type == Surface.ST_WALL_EXT:
                var isWall: Bool = surface.type == Surface.ST_WALL_EXT
                var pssf: Float64
                var q: Float64
                var incidence: Float64 = 0.0
                if surface.orientation == Surface.Z_POS:
                    incidence = cos(PI / 2 - alt)
                elif surface.orientation == Surface.Z_NEG:
                    incidence = cos(PI / 2 - alt - PI)
                else:
                    if self.foundation.numberOfDimensions == 2:
                        incidence = cosAlt / PI
                    else:
                        if self.foundation.numberOfDimensions == 3 and not self.foundation.useSymmetry:
                            incidence = cosAlt * cos(azi - surface.azimuth)
                        else:
                            if surface.orientation == Surface.Y_POS or surface.orientation == Surface.Y_NEG:
                                if self.foundation.isXSymm:
                                    var incidenceYPos: Float64 = cos(alt) * cos(azi - self.foundation.orientation)
                                    if incidenceYPos < 0:
                                        incidenceYPos = 0
                                    var incidenceYNeg: Float64 = cos(alt) * cos(azi - (PI + self.foundation.orientation))
                                    if incidenceYNeg < 0:
                                        incidenceYNeg = 0
                                    incidence = (incidenceYPos + incidenceYNeg) / 2.0
                                else:
                                    incidence = cosAlt * cos(azi - surface.azimuth)
                            if surface.orientation == Surface.X_POS or surface.orientation == Surface.X_NEG:
                                if self.foundation.isYSymm:
                                    var incidenceXPos: Float64 = cosAlt * cos(azi - (PI / 2 + self.foundation.orientation))
                                    if incidenceXPos < 0:
                                        incidenceXPos = 0
                                    var incidenceXNeg: Float64 = cosAlt * cos(azi - (3 * PI / 3 + self.foundation.orientation))
                                    if incidenceXNeg < 0:
                                        incidenceXNeg = 0
                                    incidence = (incidenceXPos + incidenceXNeg) / 2.0
                                else:
                                    incidence = cosAlt * cos(azi - surface.azimuth)
                if sin(alt) < 0:
                    incidence = 0
                if incidence < 0:
                    incidence = 0
                var Fsky: Float64 = (1.0 + surface.cosTilt) / 2.0
                var Fg: Float64 = 1.0 - Fsky
                var rho_g: Float64 = 1.0 - self.foundation.grade.absorptivity
                for index in surface.indices:
                    var this_cell = self.domain.cell[index]
                    var alpha: Float64 = this_cell.surfacePtr.propPtr.absorptivity
                    if qGH > 0.0:
                        pssf = incidence
                        q = alpha * (qDN * pssf + qDH * Fsky + qGH * Fg * rho_g)
                    else:
                        q = 0
                    this_cell.heatGain = q
                var hfFunc: ForcedConvectionTerm = isWall ? self.bcs.extWallForcedTerm : self.bcs.gradeForcedTerm
                surface.hfTerm = hfFunc(surface.cosTilt, surface.azimuth, self.bcs.windDirection, self.bcs.localWindSpeed)
                surface.convectionAlgorithm = isWall ? self.bcs.extWallConvectionAlgorithm : self.bcs.gradeConvectionAlgorithm
                surface.effectiveLWViewFactorQtr = sqrt(sqrt(getEffectiveExteriorViewFactor(self.bcs.skyEmissivity, surface.tilt)))
                surface.temperature = self.bcs.outdoorTemp
            elif surface.type == Surface.ST_SLAB_CORE or surface.type == Surface.ST_SLAB_PERIM or surface.type == Surface.ST_WALL_INT:
                var isWall: Bool = surface.type == Surface.ST_WALL_INT
                var absRadiation: Float64 = isWall ? self.bcs.wallAbsRadiation : self.bcs.slabAbsRadiation
                for index in surface.indices:
                    var this_cell = self.domain.cell[index]
                    this_cell.heatGain = absRadiation
                surface.temperature = isWall ? self.bcs.wallConvectiveTemp : self.bcs.slabConvectiveTemp
                surface.radiantTemperature = isWall ? self.bcs.wallRadiantTemp : self.bcs.slabRadiantTemp
                surface.hfTerm = 0.0
                surface.convectionAlgorithm = isWall ? self.bcs.intWallConvectionAlgorithm : self.bcs.slabConvectionAlgorithm
            elif surface.type == Surface.ST_DEEP_GROUND:
                surface.temperature = self.bcs.deepGroundTemperature

    def link_cells_to_temp(inout self):
        for this_cell in self.domain.cell:
            this_cell.told_ptr = Pointer[Float64](address_of(self.TOld[this_cell.index]))

    def calculateHeatFlux(inout self, index: Int) -> Tensor[Float64, 3]:
        return self.domain.cell[index].calculateHeatFlux(self.foundation.numberOfDimensions, self.TNew[index], self.nX, self.nY, self.nZ, self.domain.cell)

    def writeCSV(inout self, path: String):
        var output = std.ofstream()
        output.open(path)
        var j: Int = self.nY / 2
        for i in range(self.nX):
            output << ", , " << i
        output << "\n, "
        for i in range(self.nX):
            output << ", " << self.domain.mesh[0].centers[i]
        output << "\n"
        for n in range(self.nZ, 0, -1):
            var k: Int = n - 1
            output << k << ", " << self.domain.mesh[2].centers[k]
            for i in range(self.nX):
                var value: Float64
                var index: Int = self.domain.getIndex(i, j, k)
                var Qflux: Tensor[Float64, 3] = self.calculateHeatFlux(index)
                var Qx: Float64 = Qflux[0]
                var Qy: Float64 = Qflux[1]
                var Qz: Float64 = Qflux[2]
                var Qmag: Float64 = sqrt(Qx * Qx + Qy * Qy + Qz * Qz)
                value = Qmag
                value = self.domain.cell[index].surfacePtr ? self.domain.cell[index].surfacePtr.type : -1.0
                output << ", " << value
            output << "\n"
        output.close()