/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from Algorithms import *
from Functions import *
from Geometry import *
from Mesher import *
from Errors import *
from math import atan, sqrt, PI as MATH_PI
from memory import DTypePointer
from utils import List, Dict, Map, sort, StringRef
from math import isclose

# Define DBL_EPSILON equivalent
alias DBL_EPSILON: Float64 = 2.2204460492503131e-16

# Define PI constant
alias PI: Float64 = 4.0 * atan(1.0)

@value
struct Material:
    var conductivity: Float64 # [W/m-K] conductivity (boost function of z, t?)
    var density: Float64      # [kg/m3] density
    var specificHeat: Float64 # [J/kg-K] specific heat

    def __init__(inout self):
        self.conductivity = 0.0
        self.density = 0.0
        self.specificHeat = 0.0

    def __init__(inout self, k: Float64, rho: Float64, cp: Float64):
        self.conductivity = k
        self.density = rho
        self.specificHeat = cp

@value
struct Layer:
    var material: Material
    var thickness: Float64 # [m] thickness

@value
struct InputBlock:
    var x: Float64     # [m] block X origin relative to wall interior
    var z: Float64     # [m] block Z origin relative to wall top
    var width: Float64 # [m] block width extending from block X origin outward
    var depth: Float64 # [m] block depth extending from block z origin downward
    var material: Material
    var box: Box

    def __init__(inout self):
        self.x = 0.0
        self.z = 0.0
        self.width = 0.0
        self.depth = 0.0
        self.material = Material()
        self.box = Box(Point(0, 0), Point(0, 0))

@value
struct SurfaceProperties:
    var emissivity: Float64
    var absorptivity: Float64
    var roughness: Float64

    def __init__(inout self):
        self.emissivity = 0.8
        self.absorptivity = 0.8
        self.roughness = 0.00208

    def __init__(inout self, e: Float64, a: Float64, r: Float64):
        self.emissivity = e
        self.absorptivity = a
        self.roughness = r

@value
struct Wall:
    var interior: SurfaceProperties
    var exterior: SurfaceProperties
    var heightAboveGrade: Float64 # [m]
    var depthBelowSlab: Float64   # [m]
    var layers: List[Layer]

    def totalWidth(self) -> Float64:
        var width: Float64 = 0.0
        for n in range(len(self.layers)):
            width += self.layers[n].thickness
        return width

    def totalResistance(self) -> Float64:
        var R: Float64 = 0.0
        for n in range(len(self.layers)):
            R += (self.layers[n].thickness / self.layers[n].material.conductivity)
        return R

@value
struct Slab:
    var interior: SurfaceProperties
    var layers: List[Layer]

    def totalWidth(self) -> Float64:
        var width: Float64 = 0.0
        for n in range(len(self.layers)):
            width += self.layers[n].thickness
        return width

    def totalResistance(self) -> Float64:
        var R: Float64 = 0.0
        for n in range(len(self.layers)):
            R += (self.layers[n].thickness / self.layers[n].material.conductivity)
        return R

@value
struct Mesh:
    var minCellDim: Float64 # [m]
    var maxNearGrowthCoeff: Float64
    var maxDepthGrowthCoeff: Float64
    var maxInteriorGrowthCoeff: Float64
    var maxExteriorGrowthCoeff: Float64

    def __init__(inout self):
        self.minCellDim = 0.02
        self.maxNearGrowthCoeff = 1.5
        self.maxDepthGrowthCoeff = 1.5
        self.maxInteriorGrowthCoeff = 1.5
        self.maxExteriorGrowthCoeff = 1.5

@value
struct Block:
    var polygon: Polygon
    var xMin: Float64
    var xMax: Float64
    var yMin: Float64
    var yMax: Float64
    var zMin: Float64
    var zMax: Float64
    var material: Material
    var blockType: Int32  # 0: SOLID, 1: INTERIOR_AIR, 2: EXTERIOR_AIR

    alias SOLID: Int32 = 0
    alias INTERIOR_AIR: Int32 = 1
    alias EXTERIOR_AIR: Int32 = 2

    def setSquarePolygon(inout self):
        self.polygon.outer().push_back(Point(self.xMin, self.yMin))
        self.polygon.outer().push_back(Point(self.xMin, self.yMax))
        self.polygon.outer().push_back(Point(self.xMax, self.yMax))
        self.polygon.outer().push_back(Point(self.xMax, self.yMin))

@value
struct Surface:
    var polygon: Polygon
    var xMin: Float64
    var xMax: Float64
    var yMin: Float64
    var yMax: Float64
    var zMin: Float64
    var zMax: Float64
    var type: Int32  # SurfaceType
    var propPtr: SurfaceProperties  # Using value instead of pointer
    var boundaryConditionType: Int32  # BoundaryConditionType
    var orientation: Int32  # Orientation
    var orientation_dim: Int
    var orientation_dir: Int
    var indices: List[Int]
    var area: Float64
    var tilt: Float64
    var azimuth: Float64
    var cosTilt: Float64
    var temperature: Float64
    var radiantTemperature: Float64
    var convectionAlgorithm: ConvectionAlgorithm
    var hfTerm: Float64
    var effectiveLWViewFactorQtr: Float64

    # SurfaceType enum values
    alias ST_SLAB_CORE: Int32 = 0
    alias ST_SLAB_PERIM: Int32 = 1
    alias ST_WALL_INT: Int32 = 2
    alias ST_WALL_EXT: Int32 = 3
    alias ST_WALL_TOP: Int32 = 4
    alias ST_GRADE: Int32 = 5
    alias ST_SYMMETRY: Int32 = 6
    alias ST_SYMMETRY_AIR: Int32 = 7
    alias ST_FAR_FIELD: Int32 = 8
    alias ST_FAR_FIELD_AIR: Int32 = 9
    alias ST_DEEP_GROUND: Int32 = 10
    alias ST_TOP_AIR_INT: Int32 = 11
    alias ST_TOP_AIR_EXT: Int32 = 12

    # BoundaryConditionType enum values
    alias ZERO_FLUX: Int32 = 0
    alias INTERIOR_FLUX: Int32 = 1
    alias EXTERIOR_FLUX: Int32 = 2
    alias CONSTANT_TEMPERATURE: Int32 = 3
    alias INTERIOR_TEMPERATURE: Int32 = 4
    alias EXTERIOR_TEMPERATURE: Int32 = 5

    # Orientation enum values
    alias X_POS: Int32 = 0
    alias X_NEG: Int32 = 1
    alias Y_POS: Int32 = 2
    alias Y_NEG: Int32 = 3
    alias Z_POS: Int32 = 4
    alias Z_NEG: Int32 = 5

    def setSquarePolygon(inout self):
        self.polygon.outer().push_back(Point(self.xMin, self.yMin))
        self.polygon.outer().push_back(Point(self.xMin, self.yMax))
        self.polygon.outer().push_back(Point(self.xMax, self.yMax))
        self.polygon.outer().push_back(Point(self.xMax, self.yMin))

    def calcTilt(inout self):
        if self.orientation == Surface.Z_POS:
            self.tilt = 0.0
            self.cosTilt = 1.0
        elif self.orientation == Surface.Z_NEG:
            self.tilt = PI
            self.cosTilt = -1.0
        else:
            self.tilt = PI / 2.0
            self.cosTilt = 0.0

@value
struct RangeType:
    var range: Tuple[Float64, Float64]
    var type: Int32  # Type enum

    # Type enum values
    alias MIN_INTERIOR: Int32 = 0
    alias MID_INTERIOR: Int32 = 1
    alias MIN_EXTERIOR: Int32 = 2
    alias MAX_EXTERIOR: Int32 = 3
    alias DEEP: Int32 = 4
    alias NEAR: Int32 = 5

@value
struct Ranges:
    var ranges: List[RangeType]

    def isType(self, position: Float64, type: Int32) -> Bool:
        for r in range(len(self.ranges)):
            if isGreaterThan(position, self.ranges[r].range.get[0, Float64]()) and isLessOrEqual(position, self.ranges[r].range.get[1, Float64]()):
                if self.ranges[r].type == type:
                    return True
        return False

@value
struct Foundation:
    var deepGroundDepth: Float64 # [m]
    var farFieldWidth: Float64   # [m] distance from outside of wall to the edge
    var foundationDepth: Float64 # [m] below top of wall
    var orientation: Float64     # [radians] from north
    var deepGroundBoundary: Int32  # DeepGroundBoundary enum
    var wallTopInteriorTemperature: Float64
    var wallTopExteriorTemperature: Float64
    var wallTopBoundary: Int32  # WallTopBoundary enum
    var soil: Material
    var grade: SurfaceProperties
    var coordinateSystem: Int32  # CoordinateSystem enum
    var numberOfDimensions: Int32  # 2 or 3
    var useSymmetry: Bool
    var reductionStrategy: Int32  # ReductionStrategy enum
    var twoParameters: Bool
    var reductionLength1: Float64
    var reductionLength2: Float64
    var linearAreaMultiplier: Float64
    var polygon: Polygon
    var isXSymm: Bool
    var isYSymm: Bool
    var isExposedPerimeter: List[Bool]
    var exposedFraction: Float64
    var useDetailedExposedPerimeter: Bool
    var buildingHeight: Float64
    var buildingSurfaces: List[Polygon3]
    var wall: Wall
    var hasWall: Bool
    var slab: Slab
    var hasSlab: Bool
    var inputBlocks: List[InputBlock]
    var perimeterSurfaceWidth: Float64
    var hasPerimeterSurface: Bool
    var mesh: Mesh
    var numericalScheme: Int32  # NumericalScheme enum
    var fADI: Float64
    var tolerance: Float64
    var maxIterations: Int32
    var xMeshData: MeshData
    var yMeshData: MeshData
    var zMeshData: MeshData
    var blocks: List[Block]
    var surfaces: List[Surface]
    var surfaceAreas: Dict[Int32, Float64]
    var hasSurface: Dict[Int32, Bool]
    var netArea: Float64
    var netPerimeter: Float64

    # DeepGroundBoundary enum values
    alias DGB_FIXED_TEMPERATURE: Int32 = 0
    alias DGB_ZERO_FLUX: Int32 = 1

    # WallTopBoundary enum values
    alias WTB_ZERO_FLUX: Int32 = 0
    alias WTB_LINEAR_DT: Int32 = 1

    # CoordinateSystem enum values
    alias CS_CARTESIAN: Int32 = 0
    alias CS_CYLINDRICAL: Int32 = 1

    # ReductionStrategy enum values
    alias RS_AP: Int32 = 0
    alias RS_RR: Int32 = 1
    alias RS_CUSTOM: Int32 = 2
    alias RS_BOUNDARY: Int32 = 3

    # NumericalScheme enum values
    alias NS_ADE: Int32 = 0
    alias NS_EXPLICIT: Int32 = 1
    alias NS_ADI: Int32 = 2
    alias NS_IMPLICIT: Int32 = 3
    alias NS_CRANK_NICOLSON: Int32 = 4
    alias NS_STEADY_STATE: Int32 = 5

    def __init__(inout self):
        self.deepGroundDepth = 40.0
        self.farFieldWidth = 40.0
        self.foundationDepth = 0.0
        self.orientation = 0.0
        self.deepGroundBoundary = Foundation.DGB_ZERO_FLUX
        self.wallTopInteriorTemperature = 0.0
        self.wallTopExteriorTemperature = 0.0
        self.wallTopBoundary = Foundation.WTB_ZERO_FLUX
        self.soil = Material(1.73, 1842, 419)
        self.grade = SurfaceProperties(0.9, 0.9, 0.03)
        self.coordinateSystem = Foundation.CS_CARTESIAN
        self.numberOfDimensions = 2
        self.useSymmetry = True
        self.reductionStrategy = Foundation.RS_BOUNDARY
        self.twoParameters = False
        self.reductionLength1 = 0.0
        self.reductionLength2 = 0.0
        self.linearAreaMultiplier = 0.0
        self.isXSymm = False
        self.isYSymm = False
        self.exposedFraction = 1.0
        self.useDetailedExposedPerimeter = False
        self.buildingHeight = 0.0
        self.hasWall = True
        self.hasSlab = True
        self.perimeterSurfaceWidth = 0.0
        self.hasPerimeterSurface = False
        self.mesh = Mesh()
        self.numericalScheme = Foundation.NS_ADI
        self.fADI = 0.00001
        self.tolerance = 1.0e-6
        self.maxIterations = 100000
        self.netArea = 0.0
        self.netPerimeter = 0.0

    def createMeshData(inout self):
        var nV: Int = len(self.polygon.outer())
        for v in range(nV):
            var thisX: Float64 = self.polygon.outer()[v].get[0, Float64]()
            var thisY: Float64 = self.polygon.outer()[v].get[1, Float64]()
            var nextX: Float64
            var nextY: Float64
            if v < nV - 1:
                nextX = self.polygon.outer()[v + 1].get[0, Float64]()
                nextY = self.polygon.outer()[v + 1].get[1, Float64]()
            else:
                nextX = self.polygon.outer()[0].get[0, Float64]()
                nextY = self.polygon.outer()[0].get[1, Float64]()
            var poly: Polygon3
            poly.outer().push_back(Point3(thisX, thisY, 0.0))
            poly.outer().push_back(Point3(thisX, thisY, self.buildingHeight))
            poly.outer().push_back(Point3(nextX, nextY, self.buildingHeight))
            poly.outer().push_back(Point3(nextX, nextY, 0.0))
            self.buildingSurfaces.push_back(poly)
        if not isCounterClockWise(self.polygon):
            if self.useDetailedExposedPerimeter:
                showMessage(MSG_ERR,
                    "Foundation floor polygon was entered as clockwise using detailed exposed "
                    "perimeter. Unable to automatically reassign perimeter exposures.")
            boost_geometry_correct(self.polygon)
            showMessage(MSG_WARN,
                "Foundation floor polygon was modified to be counterclockwise as required in Kiva.")
        var air: Material
        air.conductivity = 0.02587
        air.density = 1.275
        air.specificHeat = 1007
        var zeroThickness: Interval
        zeroThickness.maxGrowthCoeff = 1.0
        zeroThickness.minCellDim = 1.0
        zeroThickness.growthDir = Interval.UNIFORM
        var near: Interval
        near.maxGrowthCoeff = self.mesh.maxNearGrowthCoeff
        near.minCellDim = self.mesh.minCellDim
        near.growthDir = Interval.CENTERED
        var deep: Interval
        deep.maxGrowthCoeff = self.mesh.maxDepthGrowthCoeff
        deep.minCellDim = self.mesh.minCellDim
        deep.growthDir = Interval.BACKWARD
        var minInterior: Interval
        minInterior.maxGrowthCoeff = self.mesh.maxInteriorGrowthCoeff
        minInterior.minCellDim = self.mesh.minCellDim
        minInterior.growthDir = Interval.BACKWARD
        var midInterior: Interval
        midInterior.maxGrowthCoeff = self.mesh.maxInteriorGrowthCoeff
        midInterior.minCellDim = self.mesh.minCellDim
        midInterior.growthDir = Interval.CENTERED
        var minExterior: Interval
        minExterior.maxGrowthCoeff = self.mesh.maxExteriorGrowthCoeff
        minExterior.minCellDim = self.mesh.minCellDim
        minExterior.growthDir = Interval.BACKWARD
        var maxExterior: Interval
        maxExterior.maxGrowthCoeff = self.mesh.maxExteriorGrowthCoeff
        maxExterior.minCellDim = self.mesh.minCellDim
        maxExterior.growthDir = Interval.FORWARD
        var zGrade: Float64 = 0.0
        var zMax: Float64 = self.wall.heightAboveGrade if self.hasWall else zGrade
        var zMin: Float64 = -self.deepGroundDepth
        var zSlab: Float64 = zMax - self.foundationDepth
        var zSlabBottom: Float64 = (zSlab - self.slab.totalWidth()) if self.hasSlab else zSlab
        var zWall: Float64 = (zSlabBottom - self.wall.depthBelowSlab) if self.hasWall else zGrade
        var xyWallInterior: Float64 = 0.0
        var xyWallExterior: Float64 = self.wall.totalWidth() if self.hasWall else xyWallInterior
        var xyPerimeterSurface: Float64 = -self.perimeterSurfaceWidth if self.hasPerimeterSurface else xyWallInterior
        var xySlabNear: Float64 = xyPerimeterSurface
        var xyGradeNear: Float64 = xyWallExterior
        var surf2D: List[Surface] = List[Surface]()
        var intBoxes: MultiPolygon
        var extBoxes: MultiPolygon
        var xyNearMin: Float64 = xyWallInterior
        var xyNearMax: Float64 = xyWallExterior
        var zNearMin: Float64 = zGrade
        var xyWallTopInterior: Float64 = xyWallInterior
        var xyWallTopExterior: Float64 = xyWallExterior
        for b in self.inputBlocks:
            var bZ1: Float64 = zMax - b.z
            var bX1: Float64 = b.x
            var bZ2: Float64 = bZ1 - b.depth
            var bX2: Float64 = bX1 + b.width
            var bZmin: Float64 = min(bZ1, bZ2)
            var bZmax: Float64 = max(bZ1, bZ2)
            var bXmin: Float64 = min(bX1, bX2)
            var bXmax: Float64 = max(bX1, bX2)
            if bZmin < zMin:
                showMessage(MSG_ERR, "'Material Block' cannot be below the deep ground boundary.")
            if bZmax > zMax:
                showMessage(MSG_ERR, "'Material Block' cannot be above the wall top.")
            if isEqual(bZmax, zMax):
                if isGreaterOrEqual(bXmax, xyWallTopInterior) and isLessThan(bXmin, xyWallTopInterior):
                    if abs(b.width) <= self.wall.totalWidth() / 2.0 or self.foundationDepth > 0.0:
                        xyWallTopInterior = min(bXmin, xyWallTopInterior)
                        if self.foundationDepth == 0.0:
                            xySlabNear = xyWallTopInterior
                if isLessOrEqual(bXmin, xyWallTopExterior) and isGreaterThan(bXmax, xyWallTopExterior):
                    if abs(b.width) <= self.wall.totalWidth() / 2.0 or (self.hasWall and self.wall.heightAboveGrade > 0.0):
                        xyWallTopExterior = max(bXmax, xyWallTopExterior)
                        if self.hasWall and self.wall.heightAboveGrade == 0.0 and isLessOrEqual(bZmin, zGrade):
                            xyGradeNear = xyWallTopExterior
            zNearMin = min(zNearMin, bZmin)
            xyNearMin = min(xyNearMin, bXmin)
            xyNearMax = max(xyNearMax, bXmax)
            b.box = Box(Point(bXmin, bZmin), Point(bXmax, bZmax))
            if bZmax > zSlab and bXmin < xyWallInterior:
                boost_geometry_union(b.box, intBoxes, intBoxes)
            if bZmax > zGrade and bXmax > xyWallExterior:
                boost_geometry_union(b.box, extBoxes, extBoxes)
        if isLessThan(zSlab, zMax):
            var intBound: Box = Box(Point(xyNearMin - 1.0, zSlab), Point(xyWallInterior, zMax))
            var diff: MultiPolygon
            boost_geometry_difference(intBound, intBoxes, diff)
            if len(diff) != 1:
                showMessage(MSG_ERR, "'Material Blocks' cannot create an enclosure.")
            if len(diff[0].inners()) > 0:
                showMessage(MSG_ERR, "'Material Blocks' must touch an existing boundary.")
            var numTops: Int32 = 0
            var xWallMin: Float64 = xyWallTopInterior - 0.3
            var nVs: Int = len(diff[0].outer())
            for v in range(nVs):
                var vNext: Int
                if v == nVs - 1:
                    vNext = 0
                else:
                    vNext = v + 1
                var x1: Float64 = diff[0].outer()[v].get[0, Float64]()
                var x2: Float64 = diff[0].outer()[vNext].get[0, Float64]()
                var z1: Float64 = diff[0].outer()[v].get[1, Float64]()
                var z2: Float64 = diff[0].outer()[vNext].get[1, Float64]()
                var dOut: Int32 = getDirectionOut(diff[0], v)
                var dIn: Int32 = getDirectionIn(diff[0], v)
                if dOut == geom_Y_POS and isEqual(x1, xyNearMin - 1.0):
                    continue
                if dOut == geom_X_POS and isEqual(z1, zMax):
                    if dIn != geom_X_POS:
                        numTops += 1
                    continue
                var surf: Surface
                surf.boundaryConditionType = Surface.INTERIOR_FLUX
                if dOut == geom_Y_NEG:
                    surf.orientation = Surface.X_NEG
                    surf.zMin = z2
                    surf.zMax = z1
                    surf.xMin = x2
                    surf.xMax = x1
                    if x1 > xWallMin or isEqual(z1, zMax):
                        surf.type = Surface.ST_WALL_INT
                        surf.propPtr = self.wall.interior
                        if isEqual(z1, zMax):
                            xyWallTopInterior = x1
                        xWallMin = x1 - 0.3
                    else:
                        if isLessOrEqual(x1, xyPerimeterSurface):
                            surf.type = Surface.ST_SLAB_CORE
                        else:
                            surf.type = Surface.ST_SLAB_PERIM
                        surf.propPtr = self.slab.interior
                elif dOut == geom_X_NEG:
                    surf.orientation = Surface.Z_POS
                    if x2 > xWallMin:
                        surf.type = Surface.ST_WALL_INT
                        surf.propPtr = self.wall.interior
                        surf.xMin = x2
                        surf.xMax = x1
                    else:
                        if isLessOrEqual(x1, xyPerimeterSurface):
                            if isEqual(x2, xyNearMin - 1.0):
                                xySlabNear = x1
                                continue
                            surf.xMin = x2
                            surf.xMax = x1
                            surf.type = Surface.ST_SLAB_CORE
                        elif isGreaterThan(x2, xyPerimeterSurface):
                            surf.xMin = x2
                            surf.xMax = x1
                            surf.type = Surface.ST_SLAB_PERIM
                        else:
                            surf.type = Surface.ST_SLAB_CORE
                            surf.xMin = x2
                            surf.xMax = xyPerimeterSurface
                            var surf2: Surface
                            surf2.boundaryConditionType = Surface.INTERIOR_FLUX
                            surf2.orientation = Surface.Z_POS
                            surf2.zMin = z2
                            surf2.zMax = z2
                            surf2.xMin = xyPerimeterSurface
                            surf2.xMax = x1
                            surf2.type = Surface.ST_SLAB_PERIM
                            surf2.propPtr = self.slab.interior
                            surf2D.push_back(surf2)
                            if isEqual(x2, xyNearMin - 1.0):
                                xySlabNear = xyPerimeterSurface
                                continue
                        surf.propPtr = self.slab.interior
                    surf.zMin = z2
                    surf.zMax = z1
                elif dOut == geom_Y_POS:
                    surf.orientation = Surface.X_POS
                    surf.zMin = z1
                    surf.zMax = z2
                    surf.xMin = x2
                    surf.xMax = x1
                    if isLessOrEqual(x1, xyPerimeterSurface):
                        surf.type = Surface.ST_SLAB_CORE
                    else:
                        surf.type = Surface.ST_SLAB_PERIM
                    surf.propPtr = self.slab.interior
                elif dOut == geom_X_POS:
                    surf.orientation = Surface.Z_NEG
                    surf.xMin = x1
                    surf.xMax = x2
                    surf.type = Surface.ST_WALL_INT
                    surf.zMin = z2
                    surf.zMax = z1
                    surf.propPtr = self.wall.interior
                surf2D.push_back(surf)
            if numTops > 1:
                showMessage(MSG_ERR, "'Material Blocks' must touch the slab, wall, or grade boundary.")
        else:
            if xyPerimeterSurface < xyWallTopInterior:
                var surf: Surface
                surf.boundaryConditionType = Surface.INTERIOR_FLUX
                surf.orientation = Surface.Z_POS
                surf.zMin = zSlab
                surf.zMax = zMax
                surf.xMin = xyPerimeterSurface
                surf.xMax = xyWallTopInterior
                surf.type = Surface.ST_SLAB_PERIM
                surf.propPtr = self.slab.interior
                surf2D.push_back(surf)
                xySlabNear = xyPerimeterSurface
        if isLessThan(zGrade, zMax):
            var extBound: Box = Box(Point(xyWallExterior, zGrade), Point(xyNearMax + 1.0, zMax))
            var diff: MultiPolygon
            boost_geometry_difference(extBound, extBoxes, diff)
            if len(diff) != 1:
                showMessage(MSG_ERR, "'Material Blocks' cannot create an enclosure.")
            if len(diff[0].inners()) > 0:
                showMessage(MSG_ERR, "'Material Blocks' must touch an existing boundary.")
            var numTops: Int32 = 0
            var xWallMin: Float64 = xyWallTopExterior + 0.3
            var nVs: Int = len(diff[0].outer())
            for v in range(nVs):
                var vNext: Int
                if v == nVs - 1:
                    vNext = 0
                else:
                    vNext = v + 1
                var x1: Float64 = diff[0].outer()[v].get[0, Float64]()
                var x2: Float64 = diff[0].outer()[vNext].get[0, Float64]()
                var z1: Float64 = diff[0].outer()[v].get[1, Float64]()
                var z2: Float64 = diff[0].outer()[vNext].get[1, Float64]()
                var dOut: Int32 = getDirectionOut(diff[0], v)
                var dIn: Int32 = getDirectionIn(diff[0], v)
                if dOut == geom_Y_NEG and isEqual(x1, xyNearMax + 1.0):
                    continue
                if dOut == geom_X_POS and isEqual(z1, zMax):
                    if dIn != geom_X_POS:
                        numTops += 1
                    continue
                if dOut == geom_X_NEG and isEqual(x1, xyNearMax + 1.0):
                    xyGradeNear = x2
                    continue
                var surf: Surface
                surf.boundaryConditionType = Surface.EXTERIOR_FLUX
                if dOut == geom_Y_NEG:
                    surf.orientation = Surface.X_NEG
                    surf.zMin = z2
                    surf.zMax = z1
                    surf.xMin = x2
                    surf.xMax = x1
                    surf.type = Surface.ST_GRADE
                    surf.propPtr = self.grade
                elif dOut == geom_X_NEG:
                    surf.orientation = Surface.Z_POS
                    if x1 > xWallMin:
                        surf.type = Surface.ST_GRADE
                        surf.propPtr = self.grade
                    else:
                        surf.type = Surface.ST_WALL_EXT
                        surf.propPtr = self.wall.exterior
                    surf.xMin = x2
                    surf.xMax = x1
                    surf.zMin = z2
                    surf.zMax = z1
                elif dOut == geom_Y_POS:
                    surf.orientation = Surface.X_POS
                    surf.zMin = z1
                    surf.zMax = z2
                    surf.xMin = x2
                    surf.xMax = x1
                    if x1 < xWallMin or isEqual(z2, zMax):
                        surf.type = Surface.ST_WALL_EXT
                        surf.propPtr = self.wall.exterior
                        if isEqual(z2, zMax):
                            xyWallTopExterior = x1
                    else:
                        surf.type = Surface.ST_GRADE
                        surf.propPtr = self.grade
                elif dOut == geom_X_POS:
                    surf.orientation = Surface.Z_NEG
                    surf.xMin = x1
                    surf.xMax = x2
                    surf.type = Surface.ST_WALL_EXT
                    surf.propPtr = self.wall.exterior
                    surf.zMin = z2
                    surf.zMax = z1
                surf2D.push_back(surf)
            if numTops > 1:
                showMessage(MSG_ERR, "'Material Blocks' must touch the slab, wall, or grade boundary.")
        var zNearDeep: Float64 = min(zGrade, zSlab, zSlabBottom, zWall, zNearMin)
        var xyNearInt: Float64 = min(xyWallInterior, xyPerimeterSurface, xyNearMin)
        var xyNearExt: Float64 = max(xyWallExterior, xyNearMax)
        var xMin: Float64
        var xMax: Float64
        var yMin: Float64
        var yMax: Float64
        var xRanges: Ranges
        var yRanges: Ranges
        var zRanges: Ranges
        var zDeepRange: RangeType
        zDeepRange.range = (zMin, zNearDeep)
        zDeepRange.type = RangeType.DEEP
        zRanges.ranges.push_back(zDeepRange)
        var zNearRange: RangeType
        zNearRange.range = (zNearDeep, zMax)
        zNearRange.type = RangeType.NEAR
        zRanges.ranges.push_back(zNearRange)
        var area: Float64 = boost_geometry_area(self.polygon)           # [m2] Area of foundation
        var perimeter: Float64 = boost_geometry_perimeter(self.polygon) # [m] Perimeter of foundation
        var interiorPerimeter: Float64 = 0.0
        if self.useDetailedExposedPerimeter:
            for v in range(nV):
                var vNext: Int
                if v == nV - 1:
                    vNext = 0
                else:
                    vNext = v + 1
                var a: Point = self.polygon.outer()[v]
                var b: Point = self.polygon.outer()[vNext]
                if not self.isExposedPerimeter[v]:
                    interiorPerimeter += getDistance(a, b)
        else:
            interiorPerimeter = perimeter * (1.0 - self.exposedFraction)
        self.netArea = area
        self.netPerimeter = (perimeter - interiorPerimeter)
        self.exposedFraction = self.netPerimeter / perimeter
        var boundingBox: Box
        boost_geometry_envelope(self.polygon, boundingBox)
        var xMinBB: Float64 = boundingBox.min_corner().get[0, Float64]()
        var yMinBB: Float64 = boundingBox.min_corner().get[1, Float64]()
        var xMaxBB: Float64 = boundingBox.max_corner().get[0, Float64]()
        var yMaxBB: Float64 = boundingBox.max_corner().get[1, Float64]()
        xMin = xMinBB - self.farFieldWidth
        yMin = yMinBB - self.farFieldWidth
        xMax = xMaxBB + self.farFieldWidth
        yMax = yMaxBB + self.farFieldWidth
        self.surfaceAreas[Surface.ST_FAR_FIELD_AIR] = 0.0
        self.surfaceAreas[Surface.ST_FAR_FIELD] = 0.0
        self.surfaceAreas[Surface.ST_DEEP_GROUND] = 0.0
        self.surfaceAreas[Surface.ST_SLAB_CORE] = 0.0
        self.surfaceAreas[Surface.ST_GRADE] = 0.0
        self.surfaceAreas[Surface.ST_TOP_AIR_INT] = 0.0
        self.surfaceAreas[Surface.ST_TOP_AIR_EXT] = 0.0
        self.surfaceAreas[Surface.ST_WALL_TOP] = 0.0
        self.surfaceAreas[Surface.ST_SLAB_PERIM] = 0.0
        self.surfaceAreas[Surface.ST_WALL_INT] = 0.0
        self.surfaceAreas[Surface.ST_WALL_EXT] = 0.0
        if isGreaterThan(zMax, 0.0):
            self.surfaceAreas[Surface.ST_FAR_FIELD_AIR] += (yMax - yMin) * (zMax - zGrade) * 2 + (xMax - xMin) * (zMax - zGrade) * 2
        self.surfaceAreas[Surface.ST_FAR_FIELD] += (yMax - yMin) * (zGrade - zMin) * 2 + (xMax - xMin) * (zGrade - zMin) * 2
        self.surfaceAreas[Surface.ST_DEEP_GROUND] += (yMax - yMin) * (xMax - xMin)
        self.surfaceAreas[Surface.ST_SLAB_CORE] += boost_geometry_area(offset(self.polygon, xySlabNear))
        {
            var poly: Polygon
            boost_geometry_convert(boundingBox, poly)
            var inner: Polygon = offset(self.polygon, xyGradeNear)
            var ring: Ring
            boost_geometry_convert(inner, ring)
            boost_geometry_reverse(ring)
            poly.inners().push_back(ring)
            self.surfaceAreas[Surface.ST_GRADE] += boost_geometry_area(poly)
        }
        self.surfaceAreas[Surface.ST_TOP_AIR_INT] += boost_geometry_area(offset(self.polygon, xyWallTopInterior))
        if zMax > zGrade:
            var poly: Polygon
            boost_geometry_convert(boundingBox, poly)
            var inner: Polygon = offset(self.polygon, xyWallTopExterior)
            var ring: Ring
            boost_geometry_convert(inner, ring)
            boost_geometry_reverse(ring)
            poly.inners().push_back(ring)
            self.surfaceAreas[Surface.ST_TOP_AIR_EXT] += boost_geometry_area(poly)
        if self.hasWall:
            var poly: Polygon = offset(self.polygon, xyWallTopExterior)
            var temp: Polygon
            temp = offset(self.polygon, xyWallTopInterior)
            var ring: Ring
            boost_geometry_convert(temp, ring)
            boost_geometry_reverse(ring)
            poly.inners().push_back(ring)
            self.surfaceAreas[Surface.ST_WALL_TOP] += boost_geometry_area(poly)
        for s in surf2D:
            if s.orientation == Surface.X_POS or s.orientation == Surface.X_NEG:
                var poly: Polygon
                poly = offset(self.polygon, s.xMin)
                var nV_poly: Int = len(poly.outer())
                for v in range(nV_poly):
                    var vNext: Int
                    if v == nV_poly - 1:
                        vNext = 0
                    else:
                        vNext = v + 1
                    var a: Point = poly.outer()[v]
                    var b: Point = poly.outer()[vNext]
                    self.surfaceAreas[s.type] += (s.zMax - s.zMin) * getDistance(a, b) * self.exposedFraction
            else:
                var poly: Polygon = offset(self.polygon, s.xMax)
                var temp: Polygon = offset(self.polygon, s.xMin)
                var ring: Ring
                boost_geometry_convert(temp, ring)
                boost_geometry_reverse(ring)
                poly.inners().push_back(ring)
                self.surfaceAreas[s.type] += boost_geometry_area(poly)
        for s in self.surfaceAreas:
            self.hasSurface[s.key()] = s.value() > 0.0
        if isEqual(self.netPerimeter, 0.0):
            self.reductionStrategy = Foundation.RS_AP
            self.numberOfDimensions = 1
            xMin = 0.0
            xMax = 1.0
            yMin = 0.0
            yMax = 1.0
            {
                var surface: Surface
                surface.type = Surface.ST_DEEP_GROUND
                surface.xMin = 0.0
                surface.xMax = 1.0
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zMin
                if self.deepGroundBoundary == Foundation.DGB_FIXED_TEMPERATURE:
                    surface.boundaryConditionType = Surface.CONSTANT_TEMPERATURE
                else:
                    surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.Z_NEG
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_SLAB_CORE
                surface.xMin = 0.0
                surface.xMax = 1.0
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zSlab
                surface.zMax = zSlab
                surface.boundaryConditionType = Surface.INTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.slab.interior
                self.surfaces.push_back(surface)
            }
            if self.foundationDepth > 0.0:
                var surface: Surface
                surface.type = Surface.ST_TOP_AIR_INT
                surface.xMin = 0.0
                surface.xMax = 1.0
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMax
                surface.zMax = zMax
                surface.boundaryConditionType = Surface.INTERIOR_TEMPERATURE
                surface.orientation = Surface.Z_POS
                self.surfaces.push_back(surface)
            {
                var block: Block
                block.material = air
                block.blockType = Block.INTERIOR_AIR
                block.xMin = 0.0
                block.xMax = 1.0
                block.yMin = 0.0
                block.yMax = 1.0
                block.setSquarePolygon()
                block.zMin = zSlab
                block.zMax = zMax
                self.blocks.push_back(block)
            }
            if self.hasSlab:
                var zPosition: Float64 = zSlabBottom
                for n in range(len(self.slab.layers)):
                    var block: Block
                    block.material = self.slab.layers[n].material
                    block.blockType = Block.SOLID
                    block.xMin = 0.0
                    block.xMax = 1.0
                    block.yMin = 0.0
                    block.yMax = 1.0
                    block.setSquarePolygon()
                    block.zMin = zPosition
                    block.zMax = zPosition + self.slab.layers[n].thickness
                    self.blocks.push_back(block)
                    zPosition = block.zMax
        if self.numberOfDimensions == 2:
            self.linearAreaMultiplier = 1.0
            var ap: Float64 = area / (perimeter - interiorPerimeter)
            if self.reductionStrategy == Foundation.RS_AP:
                self.twoParameters = False
                if self.coordinateSystem == Foundation.CS_CYLINDRICAL:
                    self.reductionLength2 = 2.0 * ap
                elif self.coordinateSystem == Foundation.CS_CARTESIAN:
                    self.reductionLength2 = ap
            elif self.reductionStrategy == Foundation.RS_RR:
                self.twoParameters = False
                var rrA: Float64 = (perimeter - sqrt(perimeter * perimeter - 4 * PI * area)) / PI
                var rrB: Float64 = (perimeter - PI * rrA) * 0.5
                self.reductionLength2 = (rrA) * 0.5
                self.linearAreaMultiplier = rrB
            elif self.reductionStrategy != Foundation.RS_CUSTOM:
                showMessage(MSG_ERR, "Invalid two-dimensional transformation strategy.")
            xMin = 0.0
            xMax = self.reductionLength2 + self.farFieldWidth
            yMin = 0.0
            yMax = 1.0
            var xRef2: Float64 = self.reductionLength2
            var xRef1: Float64 = self.reductionLength1
            {
                var surface: Surface
                surface.type = Surface.ST_SYMMETRY
                surface.xMin = xMin
                surface.xMax = xMin
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMin
                if self.twoParameters:
                    surface.zMax = zGrade
                else:
                    surface.zMax = zSlab
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.X_NEG
                self.surfaces.push_back(surface)
            }
            if not self.twoParameters:
                var surface: Surface
                surface.type = Surface.ST_SYMMETRY_AIR
                surface.xMin = xMin
                surface.xMax = xMin
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zSlab
                surface.zMax = zMax
                surface.boundaryConditionType = Surface.INTERIOR_TEMPERATURE
                surface.orientation = Surface.X_NEG
                self.surfaces.push_back(surface)
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD
                surface.xMin = xMax
                surface.xMax = xMax
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.X_POS
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD_AIR
                surface.xMin = xMax
                surface.xMax = xMax
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zGrade
                surface.zMax = zMax
                surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                surface.orientation = Surface.X_POS
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_DEEP_GROUND
                surface.xMin = xMin
                surface.xMax = xMax
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zMin
                if self.deepGroundBoundary == Foundation.DGB_FIXED_TEMPERATURE:
                    surface.boundaryConditionType = Surface.CONSTANT_TEMPERATURE
                else:
                    surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.Z_NEG
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_SLAB_CORE
                if not self.twoParameters:
                    surface.xMin = xMin
                    surface.xMax = xRef2 + xySlabNear
                else:
                    surface.xMin = xRef1 - xySlabNear
                    surface.xMax = xRef2 + xySlabNear
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zSlab
                surface.zMax = zSlab
                surface.boundaryConditionType = Surface.INTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.slab.interior
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_GRADE
                surface.xMin = xRef2 + xyGradeNear
                surface.xMax = xMax
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zGrade
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.EXTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.grade
                self.surfaces.push_back(surface)
            }
            if self.twoParameters:
                var surface: Surface
                surface.type = Surface.ST_GRADE
                surface.xMin = xMin
                surface.xMax = xRef1 - xyGradeNear
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zGrade
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.EXTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.grade
                self.surfaces.push_back(surface)
            if self.foundationDepth > 0.0:
                var surface: Surface
                surface.type = Surface.ST_TOP_AIR_INT
                if not self.twoParameters:
                    surface.xMin = xMin
                    surface.xMax = xRef2 + xyWallTopInterior
                else:
                    surface.xMin = xRef1 - xyWallTopInterior
                    surface.xMax = xRef2 + xyWallTopInterior
                surface.yMin = 0.0
                surface.yMax = 1.0
                surface.setSquarePolygon()
                surface.zMin = zMax
                surface.zMax = zMax
                surface.boundaryConditionType = Surface.INTERIOR_TEMPERATURE
                surface.orientation = Surface.Z_POS
                self.surfaces.push_back(surface)
            if zMax > zGrade:
                {
                    var surface: Surface
                    surface.type = Surface.ST_TOP_AIR_EXT
                    surface.xMin = xRef2 + xyWallTopExterior
                    surface.xMax = xMax
                    surface.yMin = 0.0
                    surface.yMax = 1.0
                    surface.setSquarePolygon()
                    surface.zMin = zMax
                    surface.zMax = zMax
                    surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                    surface.orientation = Surface.Z_POS
                    self.surfaces.push_back(surface)
                }
                if self.twoParameters:
                    var surface: Surface
                    surface.type = Surface.ST_TOP_AIR_EXT
                    surface.xMin = xMin
                    surface.xMax = xRef1 - xyWallTopExterior
                    surface.yMin = 0.0
                    surface.yMax = 1.0
                    surface.setSquarePolygon()
                    surface.zMin = zMax
                    surface.zMax = zMax
                    surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                    surface.orientation = Surface.Z_POS
                    self.surfaces.push_back(surface)
            if self.wallTopBoundary == Foundation.WTB_LINEAR_DT:
                if self.hasWall:
                    {
                        var position: Float64 = 0.0
                        var Tin: Float64 = self.wallTopInteriorTemperature
                        var Tout: Float64 = self.wallTopExteriorTemperature
                        var Tdiff: Float64 = (Tin - Tout)
                        var N: Int = Int((xyWallTopExterior - xyWallTopInterior + DBL_EPSILON) / self.mesh.minCellDim)
                        var temperature: Float64 = Tin - (1.0 / N) / 2 * Tdiff
                        for n in range(1, N + 1):
                            var surface: Surface
                            surface.type = Surface.ST_WALL_TOP
                            surface.xMin = xRef2 + position
                            surface.xMax = xRef2 + position + (xyWallTopExterior - xyWallTopInterior) / N
                            surface.yMin = 0.0
                            surface.yMax = 1.0
                            surface.setSquarePolygon()
                            surface.zMin = zMax
                            surface.zMax = zMax
                            surface.boundaryConditionType = Surface.CONSTANT_TEMPERATURE
                            surface.orientation = Surface.Z_POS
                            surface.temperature = temperature
                            self.surfaces.push_back(surface)
                            position += (xyWallTopExterior - xyWallTopInterior) / N
                            temperature -= (1.0 / N) * Tdiff
                    }
                    if self.twoParameters:
                        var position: Float64 = 0.0
                        var Tin: Float64 = self.wallTopInteriorTemperature
                        var Tout: Float64 = self.wallTopExteriorTemperature
                        var Tdiff: Float64 = (Tin - Tout)
                        var N: Int = Int((xyWallTopExterior - xyWallTopInterior + DBL_EPSILON) / self.mesh.minCellDim)
                        var temperature: Float64 = Tin - (1.0 / N) / 2 * Tdiff
                        for n in range(1, N + 1):
                            var surface: Surface
                            surface.type = Surface.ST_WALL_TOP
                            surface.xMin = xRef1 - position - (xyWallTopExterior - xyWallTopInterior) / N
                            surface.xMax = xRef1 - position
                            surface.yMin = 0.0
                            surface.yMax = 1.0
                            surface.setSquarePolygon()
                            surface.zMin = zMax
                            surface.zMax = zMax
                            surface.boundaryConditionType = Surface.CONSTANT_TEMPERATURE
                            surface.orientation = Surface.Z_POS
                            surface.temperature = temperature
                            self.surfaces.push_back(surface)
                            position += (xyWallTopExterior - xyWallTopInterior) / N
                            temperature -= (1.0 / N) * Tdiff
            else:
                if self.hasWall:
                    {
                        var surface: Surface
                        surface.type = Surface.ST_WALL_TOP
                        surface.xMin = xRef2 + xyWallTopInterior
                        surface.xMax = xRef2 + xyWallTopExterior
                        surface.yMin = 0.0
                        surface.yMax = 1.0
                        surface.setSquarePolygon()
                        surface.zMin = zMax
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.ZERO_FLUX
                        surface.orientation = Surface.Z_POS
                        self.surfaces.push_back(surface)
                    }
                    if self.twoParameters:
                        var surface: Surface
                        surface.type = Surface.ST_WALL_TOP
                        surface.xMin = xRef1 - xyWallTopExterior
                        surface.xMax = xRef1 - xyWallTopInterior
                        surface.yMin = 0.0
                        surface.yMax = 1.0
                        surface.setSquarePolygon()
                        surface.zMin = zMax
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.ZERO_FLUX
                        surface.orientation = Surface.Z_POS
                        self.surfaces.push_back(surface)
            for s in surf2D:
                {
                    var surface: Surface
                    surface.type = s.type
                    surface.xMin = xRef2 + s.xMin
                    surface.xMax = xRef2 + s.xMax
                    surface.yMin = 0.0
                    surface.yMax = 1.0
                    surface.setSquarePolygon()
                    surface.zMin = s.zMin
                    surface.zMax = s.zMax
                    surface.boundaryConditionType = s.boundaryConditionType
                    surface.orientation = s.orientation
                    surface.propPtr = s.propPtr
                    self.surfaces.push_back(surface)
                }
                if self.twoParameters:
                    var surface: Surface
                    surface.type = s.type
                    surface.xMin = xRef1 - s.xMin
                    surface.xMax = xRef1 - s.xMax
                    surface.yMin = 0.0
                    surface.yMax = 1.0
                    surface.setSquarePolygon()
                    surface.zMin = s.zMin
                    surface.zMax = s.zMax
                    surface.boundaryConditionType = s.boundaryConditionType
                    surface.orientation = s.orientation
                    if s.orientation == Surface.X_POS:
                        surface.orientation = Surface.X_NEG
                    elif s.orientation == Surface.X_NEG:
                        surface.orientation = Surface.X_POS
                    surface.propPtr = s.propPtr
                    self.surfaces.push_back(surface)
            {
                var block: Block
                block.material = air
                block.blockType = Block.INTERIOR_AIR
                if self.twoParameters:
                    block.xMin = xRef1 - xyWallInterior
                    block.xMax = xRef2 + xyWallInterior
                else:
                    block.xMin = xMin
                    block.xMax = xRef2 + xyWallInterior
                block.yMin = 0.0
                block.yMax = 1.0
                block.setSquarePolygon()
                block.zMin = zSlab
                block.zMax = zMax
                self.blocks.push_back(block)
            }
            {
                var block: Block
                block.material = air
                block.blockType = Block.EXTERIOR_AIR
                block.xMin = xRef2 + xyWallExterior
                block.xMax = xMax
                block.yMin = 0.0
                block.yMax = 1.0
                block.setSquarePolygon()
                block.zMin = zGrade
                block.zMax = zMax
                self.blocks.push_back(block)
            }
            if self.twoParameters:
                var block: Block
                block.material = air
                block.blockType = Block.EXTERIOR_AIR
                block.xMin = xMin
                block.xMax = xRef1 - xyWallExterior
                block.yMin = 0.0
                block.yMax = 1.0
                block.setSquarePolygon()
                block.zMin = zGrade
                block.zMax = zMax
                self.blocks.push_back(block)
            if self.hasSlab:
                var zPosition: Float64 = zSlabBottom
                for n in range(len(self.slab.layers)):
                    var block: Block
                    block.material = self.slab.layers[n].material
                    block.blockType = Block.SOLID
                    if not self.twoParameters:
                        block.xMin = xMin
                        block.xMax = xRef2
                    else:
                        block.xMin = xRef1
                        block.xMax = xRef2
                    block.yMin = 0.0
                    block.yMax = 1.0
                    block.setSquarePolygon()
                    block.zMin = zPosition
                    block.zMax = zPosition + self.slab.layers[n].thickness
                    self.blocks.push_back(block)
                    zPosition = block.zMax
            if self.hasWall:
                {
                    var xPosition: Float64 = xRef2
                    for n in range(len(self.wall.layers), 0, -1):
                        var index: Int = n - 1
                        var block: Block
                        block.material = self.wall.layers[index].material
                        block.blockType = Block.SOLID
                        block.xMin = xPosition
                        block.xMax = xPosition + self.wall.layers[index].thickness
                        block.yMin = 0.0
                        block.yMax = 1.0
                        block.setSquarePolygon()
                        block.zMin = zWall
                        block.zMax = zMax
                        xPosition = block.xMax
                        self.blocks.push_back(block)
                }
                if self.twoParameters:
                    var xPosition: Float64 = xRef1
                    for n in range(len(self.wall.layers), 0, -1):
                        var index: Int = n - 1
                        var block: Block
                        block.material = self.wall.layers[index].material
                        block.blockType = Block.SOLID
                        block.xMin = xPosition - self.wall.layers[index].thickness
                        block.xMax = xPosition
                        block.yMin = 0.0
                        block.yMax = 1.0
                        block.setSquarePolygon()
                        block.zMin = zWall
                        block.zMax = zMax
                        xPosition = block.xMin
                        self.blocks.push_back(block)
            for b in self.inputBlocks:
                {
                    var block: Block
                    block.material = b.material
                    block.blockType = Block.SOLID
                    block.xMin = xRef2 + b.box.min_corner().get[0, Float64]()
                    block.xMax = xRef2 + b.box.max_corner().get[0, Float64]()
                    block.yMin = 0.0
                    block.yMax = 1.0
                    block.setSquarePolygon()
                    block.zMin = b.box.min_corner().get[1, Float64]()
                    block.zMax = b.box.max_corner().get[1, Float64]()
                    self.blocks.push_back(block)
                }
                if self.twoParameters:
                    var block: Block
                    block.material = b.material
                    block.blockType = Block.SOLID
                    block.xMin = xRef1 - b.box.min_corner().get[0, Float64]()
                    block.xMax = xRef1 - b.box.max_corner().get[0, Float64]()
                    block.yMin = 0.0
                    block.yMax = 1.0
                    block.setSquarePolygon()
                    block.zMin = b.box.min_corner().get[1, Float64]()
                    block.zMax = b.box.max_corner().get[1, Float64]()
                    self.blocks.push_back(block)
            if not self.twoParameters:
                var xInteriorRange: RangeType
                xInteriorRange.range = (xMin, xRef2 + xyNearInt)
                xInteriorRange.type = RangeType.MIN_INTERIOR
                xRanges.ranges.push_back(xInteriorRange)
                var xNearRange: RangeType
                xNearRange.range = (xRef2 + xyNearInt, xRef2 + xyNearExt)
                xNearRange.type = RangeType.NEAR
                xRanges.ranges.push_back(xNearRange)
                var xExteriorRange: RangeType
                xExteriorRange.range = (xRef2 + xyNearExt, xMax)
                xExteriorRange.type = RangeType.MAX_EXTERIOR
                xRanges.ranges.push_back(xExteriorRange)
            else:
                var xMinExteriorRange: RangeType
                xMinExteriorRange.range = (xMin, xRef1 - xyNearExt)
                xMinExteriorRange.type = RangeType.MIN_INTERIOR
                xRanges.ranges.push_back(xMinExteriorRange)
                var xNearRange1: RangeType
                xNearRange1.range = (xRef1 - xyNearExt, xRef1 - xyNearInt)
                xNearRange1.type = RangeType.NEAR
                xRanges.ranges.push_back(xNearRange1)
                var xInteriorRange: RangeType
                xInteriorRange.range = (xRef1 - xyNearInt, xRef2 + xyNearInt)
                xInteriorRange.type = RangeType.MID_INTERIOR
                xRanges.ranges.push_back(xInteriorRange)
                var xNearRange2: RangeType
                xNearRange2.range = (xRef2 + xyNearInt, xRef2 + xyNearExt)
                xNearRange2.type = RangeType.NEAR
                xRanges.ranges.push_back(xNearRange2)
                var xMaxExteriorRange: RangeType
                xMaxExteriorRange.range = (xRef2 + xyNearExt, xMax)
                xMaxExteriorRange.type = RangeType.MAX_EXTERIOR
                xRanges.ranges.push_back(xMaxExteriorRange)
        elif self.numberOfDimensions == 3 and not self.useSymmetry:
            #if defined(KIVA_3D)
            xMin = xMinBB - self.farFieldWidth
            yMin = yMinBB - self.farFieldWidth
            xMax = xMaxBB + self.farFieldWidth
            yMax = yMaxBB + self.farFieldWidth
            if isGreaterThan(zMax, 0.0):
                {
                    {
                        var surface: Surface
                        surface.type = Surface.ST_FAR_FIELD_AIR
                        surface.xMin = xMin
                        surface.xMax = xMin
                        surface.yMin = yMin
                        surface.yMax = yMax
                        surface.setSquarePolygon()
                        surface.zMin = zGrade
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                        surface.orientation = Surface.X_NEG
                        self.surfaces.push_back(surface)
                    }
                    {
                        var surface: Surface
                        surface.type = Surface.ST_FAR_FIELD_AIR
                        surface.xMin = xMax
                        surface.xMax = xMax
                        surface.yMin = yMin
                        surface.yMax = yMax
                        surface.setSquarePolygon()
                        surface.zMin = zGrade
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                        surface.orientation = Surface.X_POS
                        self.surfaces.push_back(surface)
                    }
                    {
                        var surface: Surface
                        surface.type = Surface.ST_FAR_FIELD_AIR
                        surface.xMin = xMin
                        surface.xMax = xMax
                        surface.yMin = yMin
                        surface.yMax = yMin
                        surface.setSquarePolygon()
                        surface.zMin = zGrade
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                        surface.orientation = Surface.Y_NEG
                        self.surfaces.push_back(surface)
                    }
                    {
                        var surface: Surface
                        surface.type = Surface.ST_FAR_FIELD_AIR
                        surface.xMin = xMin
                        surface.xMax = xMax
                        surface.yMin = yMax
                        surface.yMax = yMax
                        surface.setSquarePolygon()
                        surface.zMin = zGrade
                        surface.zMax = zMax
                        surface.boundaryConditionType = Surface.EXTERIOR_TEMPERATURE
                        surface.orientation = Surface.Y_POS
                        self.surfaces.push_back(surface)
                    }
                }
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD
                surface.xMin = xMin
                surface.xMax = xMin
                surface.yMin = yMin
                surface.yMax = yMax
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.X_NEG
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD
                surface.xMin = xMax
                surface.xMax = xMax
                surface.yMin = yMin
                surface.yMax = yMax
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.X_POS
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD
                surface.xMin = xMin
                surface.xMax = xMax
                surface.yMin = yMin
                surface.yMax = yMin
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.Y_NEG
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_FAR_FIELD
                surface.xMin = xMin
                surface.xMax = xMax
                surface.yMin = yMax
                surface.yMax = yMax
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.Y_POS
                self.surfaces.push_back(surface)
            }
            {
                var surface: Surface
                surface.type = Surface.ST_DEEP_GROUND
                surface.xMin = xMin
                surface.xMax = xMax
                surface.yMin = yMin
                surface.yMax = yMax
                surface.setSquarePolygon()
                surface.zMin = zMin
                surface.zMax = zMin
                if self.deepGroundBoundary == Foundation.DGB_FIXED_TEMPERATURE:
                    surface.boundaryConditionType = Surface.CONSTANT_TEMPERATURE
                else:
                    surface.boundaryConditionType = Surface.ZERO_FLUX
                surface.orientation = Surface.Z_NEG
                self.surfaces.push_back(surface)
            }
            {
                var poly: Polygon
                poly = offset(self.polygon, xySlabNear)
                var surface: Surface
                surface.type = Surface.ST_SLAB_CORE
                surface.polygon = poly
                surface.zMin = zSlab
                surface.zMax = zSlab
                surface.boundaryConditionType = Surface.INTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.slab.interior
                self.surfaces.push_back(surface)
            }
            {
                var poly: Polygon
                poly = offset(self.polygon, xyGradeNear)
                var ring: Ring
                boost_geometry_convert(poly, ring)
                boost_geometry_reverse(ring)
                var surface: Surface
                surface.type = Surface.ST_GRADE
                surface.xMin = xMin
                surface.xMax = xMax
                surface.yMin = yMin
                surface.yMax = yMax
                surface.setSquarePolygon()
                surface.polygon.inners().push_back(ring)
                surface.zMin = zGrade
                surface.zMax = zGrade
                surface.boundaryConditionType = Surface.EXTERIOR_FLUX
                surface.orientation = Surface.Z_POS
                surface.propPtr = self.grade
                self.surfaces.push_back(surface)
            }
            if self.f