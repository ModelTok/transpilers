from Array import *
from Math import *
from Memory import *
from Python import *
from Sys import *
from Time import *
from BranchNodeConnections import *
from .Data.EnergyPlusData import *
from DataEnvironment import *
from DataHVACGlobals import *
from .DataHeatBalSurface import *
from DataHeatBalance import *
from .DataIPShortCuts import *
from .DataLoopNode import *
from DataSurfaces import *
from FluidProperties import *
from General import *
from GlobalNames import *
from .GroundTemperatureModeling.GroundTemperatureModelManager import *
from .InputProcessing.InputProcessor import *
from Material import *
from NodeInputManager import *
from OutputProcessor import *
from .Plant.DataPlant import *
from .Plant.Enums import *
from .Plant.PlantLocation import *
from .PlantComponent import *
from PlantUtilities import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from ObjexxFCL.Array.functions import *
from ObjexxFCL.Fmath import *
from ObjexxFCL.floops import *
from ObjexxFCL.string.functions import *
from .DataGlobals import *
from .EnergyPlus import *
from .GroundTemperatureModeling.BaseGroundTemperatureModel import *
from .Constant import Constant

# Helper function for ObjexxFCL pow_2
def pow_2(x: Float64) -> Float64:
    return x * x

# Helper function for mod (C++ floating-point remainder)
def mod(x: Float64, y: Float64) -> Float64:
    return x - Float64(Int64(x / y)) * y

# Helper for isize
def isize[T](lst: List[T]) -> Int:
    return len(lst)

# Simple 2D array struct to mimic ObjexxFCL Array2D
struct Array2D[T: AnyType]:
    var data: List[List[T]]
    var lb1: Int
    var ub1: Int
    var lb2: Int
    var ub2: Int

    def __init__(inout self):
        self.lb1 = 0
        self.ub1 = -1
        self.lb2 = 0
        self.ub2 = -1
        self.data = List[List[T]]()

    def allocate(inout self, range1: Tuple[Int, Int], range2: Tuple[Int, Int]):
        self.lb1 = range1[0]
        self.ub1 = range1[1]
        self.lb2 = range2[0]
        self.ub2 = range2[1]
        self.data = List[List[T]](size=self.ub1 - self.lb1 + 1)
        for i in range(len(self.data)):
            self.data[i] = List[T](size=self.ub2 - self.lb2 + 1)

    def __getitem__(self, idx: Tuple[Int, Int]) -> T:
        return self.data[idx[0] - self.lb1][idx[1] - self.lb2]

    def __setitem__(self, idx: Tuple[Int, Int], val: T):
        self.data[idx[0] - self.lb1][idx[1] - self.lb2] = val

# Simple 3D array struct to mimic ObjexxFCL Array3D
struct Array3D[T: AnyType]:
    var data: List[List[List[T]]]
    var lb1: Int
    var ub1: Int
    var lb2: Int
    var ub2: Int
    var lb3: Int
    var ub3: Int

    def __init__(inout self):
        self.lb1 = 0
        self.ub1 = -1
        self.lb2 = 0
        self.ub2 = -1
        self.lb3 = 0
        self.ub3 = -1
        self.data = List[List[List[T]]]()

    def allocate(inout self, range1: Tuple[Int, Int], range2: Tuple[Int, Int], range3: Tuple[Int, Int]):
        self.lb1 = range1[0]
        self.ub1 = range1[1]
        self.lb2 = range2[0]
        self.ub2 = range2[1]
        self.lb3 = range3[0]
        self.ub3 = range3[1]
        self.data = List[List[List[T]]](size=self.ub1 - self.lb1 + 1)
        for i in range(len(self.data)):
            self.data[i] = List[List[T]](size=self.ub2 - self.lb2 + 1)
            for j in range(len(self.data[i])):
                self.data[i][j] = List[T](size=self.ub3 - self.lb3 + 1)

    def __getitem__(self, idx: Tuple[Int, Int, Int]) -> T:
        return self.data[idx[0] - self.lb1][idx[1] - self.lb2][idx[2] - self.lb3]

    def __setitem__(self, idx: Tuple[Int, Int, Int], val: T):
        self.data[idx[0] - self.lb1][idx[1] - self.lb2][idx[2] - self.lb3] = val

    def lbound(self, dim: Int) -> Int:
        if dim == 1:
            return self.lb1
        elif dim == 2:
            return self.lb2
        else:
            return self.lb3

    def ubound(self, dim: Int) -> Int:
        if dim == 1:
            return self.ub1
        elif dim == 2:
            return self.ub2
        else:
            return self.ub3

enum SegmentFlow:
    Invalid = -1
    IncreasingZ
    DecreasingZ
    Num

enum MeshDistribution:
    Invalid = -1
    Uniform
    SymmetricGeometric
    Geometric
    Num

enum RegionType:
    Invalid = -1
    Pipe
    BasementWall
    BasementFloor
    XDirection
    YDirection
    ZDirection
    XSide
    XSideWall
    ZSide
    ZSideWall
    FloorInside
    UnderFloor
    HorizInsXSide
    HorizInsZSide
    VertInsLowerEdge
    Num

enum Direction:
    Invalid = -1
    PositiveY
    NegativeY
    PositiveX
    NegativeX
    PositiveZ
    NegativeZ
    Num

enum PartitionType:
    Invalid = -1
    BasementWall
    BasementFloor
    Pipe
    Slab
    XSide
    XSideWall
    ZSide
    ZSideWall
    FloorInside
    UnderFloor
    HorizInsXSide
    VertInsLowerEdge
    HorizInsZSide
    Num

enum CellType:
    Invalid = -1
    Pipe
    GeneralField
    GroundSurface
    FarfieldBoundary
    BasementWall
    BasementFloor
    BasementCorner
    BasementCutaway
    Slab
    HorizInsulation
    VertInsulation
    ZoneGroundInterface
    Num

enum SlabPosition:
    Invalid = -1
    InGrade
    OnGrade
    Num

enum HorizInsulation:
    Invalid = -1
    None
    Perimeter
    Full
    Num

struct BaseThermalPropertySet:
    var Conductivity: Float64 = 0.0  # W/mK
    var Density: Float64 = 0.0      # kg/m3
    var SpecificHeat: Float64 = 0.0 # J/kgK

    def diffusivity(self) -> Float64:
        return self.Conductivity / (self.Density * self.SpecificHeat)

struct ExtendedFluidProperties(BaseThermalPropertySet):
    var Viscosity: Float64 = 0.0  # kg/m-s
    var Prandtl: Float64 = 0.0    # -

struct BaseCell:
    var Temperature: Float64 = 0.0               # C
    var Temperature_PrevIteration: Float64 = 0.0 # C
    var Temperature_PrevTimeStep: Float64 = 0.0  # C
    var Beta: Float64 = 0.0                      # K/W
    var Properties: BaseThermalPropertySet

struct RadialSizing:
    var InnerDia: Float64 = 0.0
    var OuterDia: Float64 = 0.0

    def thickness(self) -> Float64:
        return (self.OuterDia - self.InnerDia) / 2.0

struct RadialCellInformation(BaseCell):
    var RadialCentroid: Float64 = 0.0
    var InnerRadius: Float64 = 0.0
    var OuterRadius: Float64 = 0.0

    def XY_CrossSectArea(self) -> Float64:
        return Constant.Pi * (pow_2(self.OuterRadius) - pow_2(self.InnerRadius))

struct FluidCellInformation(BaseCell):
    var Volume: Float64 = 0.0
    var Properties: ExtendedFluidProperties

struct CartesianPipeCellInformation:
    var Soil: List[RadialCellInformation]
    var Insulation: RadialCellInformation
    var Pipe: RadialCellInformation
    var Fluid: FluidCellInformation
    var RadialSliceWidth: Float64 = 0.0
    var InterfaceVolume: Float64 = 0.0

struct Point:
    var X: Int = 0
    var Y: Int = 0

struct PointF:
    var X: Float64 = 0.0
    var Y: Float64 = 0.0

struct Point3DInteger:
    var X: Int = 0
    var Y: Int = 0
    var Z: Int = 0

struct Point3DReal:
    var X: Float64 = 0.0
    var Y: Float64 = 0.0
    var Z: Float64 = 0.0

struct MeshPartition:
    var rDimension: Float64 = 0.0
    var partitionType: PartitionType = PartitionType.Pipe
    var TotalWidth: Float64 = 0.0

    def __eq__(self, a: Float64) -> Bool:
        return self.rDimension == a

struct GridRegion:
    var Min: Float64 = 0.0
    var Max: Float64 = 0.0
    var thisRegionType: RegionType = RegionType.Pipe
    var CellWidths: List[Float64]

struct RectangleF:
    var X_min: Float64 = 0.0
    var Y_min: Float64 = 0.0
    var Width: Float64 = 0.0
    var Height: Float64 = 0.0

    def contains(self, p: PointF) -> Bool:
        return ((self.X_min <= p.X) and (p.X < (self.X_min + self.Width)) and (self.Y_min <= p.Y) and (p.Y < (self.Y_min + self.Height)))

struct NeighborInformation:
    var ThisCentroidToNeighborWall: Float64 = 0.0
    var ThisWallToNeighborCentroid: Float64 = 0.0
    var adiabaticMultiplier: Float64 = 1.0
    var direction: Direction = Direction.NegativeX

struct CartesianCell(BaseCell):
    var X_index: Int = 0
    var Y_index: Int = 0
    var Z_index: Int = 0
    var X_min: Float64 = 0.0
    var X_max: Float64 = 0.0
    var Y_min: Float64 = 0.0
    var Y_max: Float64 = 0.0
    var Z_min: Float64 = 0.0
    var Z_max: Float64 = 0.0
    var Centroid: Point3DReal
    var cellType: CellType = CellType.Invalid
    var NeighborInfo: Dict[Direction, NeighborInformation]
    var PipeCellData: CartesianPipeCellInformation

    def width(self) -> Float64:
        return self.X_max - self.X_min

    def height(self) -> Float64:
        return self.Y_max - self.Y_min

    def depth(self) -> Float64:
        return self.Z_max - self.Z_min

    def XNormalArea(self) -> Float64:
        return self.depth() * self.height()

    def YNormalArea(self) -> Float64:
        return self.depth() * self.width()

    def ZNormalArea(self) -> Float64:
        return self.width() * self.height()

    def volume(self) -> Float64:
        return self.width() * self.depth() * self.height()

    def normalArea(self, direction: Direction) -> Float64:
        if direction == Direction.PositiveY or direction == Direction.NegativeY:
            return self.YNormalArea()
        elif direction == Direction.PositiveX or direction == Direction.NegativeX:
            return self.XNormalArea()
        elif direction == Direction.PositiveZ or direction == Direction.NegativeZ:
            return self.ZNormalArea()
        else:
            assert(False)
        return 0.0

    def EvaluateNeighborCoordinates(self, CurDirection: Direction, inout NX: Int, inout NY: Int, inout NZ: Int):
        var X = self.X_index
        var Y = self.Y_index
        var Z = self.Z_index
        if CurDirection == Direction.PositiveY:
            NX = X; NY = Y + 1; NZ = Z
        elif CurDirection == Direction.NegativeY:
            NX = X; NY = Y - 1; NZ = Z
        elif CurDirection == Direction.PositiveX:
            NX = X + 1; NY = Y; NZ = Z
        elif CurDirection == Direction.NegativeX:
            NX = X - 1; NY = Y; NZ = Z
        elif CurDirection == Direction.PositiveZ:
            NX = X; NY = Y; NZ = Z + 1
        elif CurDirection == Direction.NegativeZ:
            NX = X; NY = Y; NZ = Z - 1
        else:
            assert(False)

struct MeshExtents:
    var xMax: Float64 = 0.0
    var yMax: Float64 = 0.0
    var zMax: Float64 = 0.0

struct CellExtents(MeshExtents):
    var Xmin: Float64
    var Ymin: Float64
    var Zmin: Float64

struct DistributionStructure:
    var thisMeshDistribution: MeshDistribution = MeshDistribution.Uniform
    var RegionMeshCount: Int = 0
    var GeometricSeriesCoefficient: Float64 = 0.0

struct MeshProperties:
    var X: DistributionStructure
    var Y: DistributionStructure
    var Z: DistributionStructure

struct SimulationControl:
    var MinimumTemperatureLimit: Float64 = -1000.0
    var MaximumTemperatureLimit: Float64 = 1000.0
    var Convergence_CurrentToPrevIteration: Float64 = 0.0
    var MaxIterationsPerTS: Int = 0

struct BasementZoneInfo:
    var Depth: Float64 = 0.0  # m
    var Width: Float64 = 0.0  # m
    var Length: Float64 = 0.0 # m
    var ShiftPipesByWidth: Bool = False
    var WallBoundaryOSCMName: String = ""
    var WallBoundaryOSCMIndex: Int = 0
    var FloorBoundaryOSCMName: String = ""
    var FloorBoundaryOSCMIndex: Int = 0
    var WallSurfacePointers: List[Int]
    var FloorSurfacePointers: List[Int]
    var BasementWallXIndex: Int = -1
    var BasementFloorYIndex: Int = -1

struct MeshPartitions:
    var X: List[MeshPartition]
    var Y: List[MeshPartition]
    var Z: List[MeshPartition]

struct MoistureInfo:
    var Theta_liq: Float64 = 0.3  # volumetric moisture content of the soil
    var Theta_sat: Float64 = 0.5  # volumetric moisture content of soil at saturation
    var GroundCoverCoefficient: Float64 = 0.408
    var rhoCP_soil_liq: Float64 = 0.0
    var rhoCP_soil_transient: Float64 = 0.0
    var rhoCP_soil_ice: Float64 = 0.0
    var rhoCp_soil_liq_1: Float64 = 0.0

struct CurSimConditionsInfo:
    var PrevSimTimeSeconds: Float64 = -1.0
    var CurSimTimeSeconds: Float64 = 0.0
    var CurSimTimeStepSize: Float64 = 0.0
    var CurAirTemp: Float64 = 10.0
    var CurWindSpeed: Float64 = 2.6
    var CurIncidentSolar: Float64 = 0.0
    var CurRelativeHumidity: Float64 = 100.0

struct Segment:
    var Name: String = ""
    var PipeLocation: PointF
    var PipeCellCoordinates: Point
    var FlowDirection: SegmentFlow = SegmentFlow.IncreasingZ
    var InletTemperature: Float64 = 0.0
    var OutletTemperature: Float64 = 0.0
    var FluidHeatLoss: Float64 = 0.0
    var PipeCellCoordinatesSet: Bool = False
    var IsActuallyPartOfAHorizontalTrench: Bool = False

    def initPipeCells(inout self, x: Int, y: Int):
        self.PipeCellCoordinates.X = x
        self.PipeCellCoordinates.Y = y
        self.PipeCellCoordinatesSet = True

    def __eq__(self, a: String) -> Bool:
        return self.Name == a

    @staticmethod
    def factory(state: EnergyPlusData, segmentName: String) -> Segment:
        if state.dataPlantPipingSysMgr.GetSegmentInputFlag:
            var errorsFound = False
            ReadPipeSegmentInputs(state, errorsFound)
            state.dataPlantPipingSysMgr.GetSegmentInputFlag = False
        for segment in state.dataPlantPipingSysMgr.segments:
            if segment.Name == segmentName:
                return segment
        ShowFatalError(state, String.format("PipeSegmentInfoFactory: Error getting inputs for segment named: {}", segmentName))
        return Segment()  # unreachable

struct Circuit(PlantComponent):
    var Name: String = ""
    var InletNodeName: String = ""
    var OutletNodeName: String = ""
    var InletNodeNum: Int = 0
    var OutletNodeNum: Int = 0
    var CircuitInletCell: Point3DInteger
    var CircuitOutletCell: Point3DInteger
    var pipeSegments: List[Segment]
    var ParentDomainIndex: Int = 0
    var PipeSize: RadialSizing
    var InsulationSize: RadialSizing
    var RadialMeshThickness: Float64 = 0.0
    var HasInsulation: Bool = False
    var DesignVolumeFlowRate: Float64 = 0.0
    var DesignMassFlowRate: Float64 = 0.0
    var Convergence_CurrentToPrevIteration: Float64 = 0.0
    var MaxIterationsPerTS: Int = 0
    var NumRadialCells: Int = 0
    var PipeProperties: BaseThermalPropertySet
    var InsulationProperties: BaseThermalPropertySet
    var NeedToFindOnPlantLoop: Bool = True
    var IsActuallyPartOfAHorizontalTrench: Bool = False
    var plantLoc: PlantLocation
    var CurFluidPropertySet: ExtendedFluidProperties  # is_used
    var CurCircuitInletTemp: Float64 = 23.0
    var CurCircuitFlowRate: Float64 = 0.1321
    var CurCircuitConvectionCoefficient: Float64 = 0.0
    var InletTemperature: Float64 = 0.0
    var OutletTemperature: Float64 = 0.0
    var FluidHeatLoss: Float64 = 0.0

    def initInOutCells(inout self, in_: CartesianCell, out_: CartesianCell):
        self.CircuitInletCell = Point3DInteger(in_.X_index, in_.Y_index, in_.Z_index)
        self.CircuitOutletCell = Point3DInteger(out_.X_index, out_.Y_index, out_.Z_index)

    @staticmethod
    def factory(state: EnergyPlusData, objectType: PlantEquipmentType, objectName: String) -> PlantComponent:
        if state.dataPlantPipingSysMgr.GetInputFlag:
            GetPipingSystemsAndGroundDomainsInput(state)
            state.dataPlantPipingSysMgr.GetInputFlag = False
        for circuit in state.dataPlantPipingSysMgr.circuits:
            if circuit.Name == objectName:
                return circuit
        ShowFatalError(state, String.format("PipeCircuitInfoFactory: Error getting inputs for circuit named: {}", objectName))
        return Circuit()  # unreachable

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        var thisDomain = state.dataPlantPipingSysMgr.domains[self.ParentDomainIndex]
        thisDomain.InitPipingSystems(state, self)
        thisDomain.PerformIterationLoop(state, self)
        thisDomain.UpdatePipingSystems(state, self)

    @staticmethod
    def factory(state: EnergyPlusData, circuitName: String, inout errorsFound: Bool) -> Circuit:
        if state.dataPlantPipingSysMgr.GetCircuitInputFlag:
            ReadPipeCircuitInputs(state, errorsFound)
            state.dataPlantPipingSysMgr.GetCircuitInputFlag = False
        for circuit in state.dataPlantPipingSysMgr.circuits:
            if circuit.Name == circuitName:
                return circuit
        ShowFatalError(state, String.format("PipeCircuitInfoFactory: Error getting inputs for circuit named: {}", circuitName))
        return Circuit()  # unreachable

    def oneTimeInit(inout self, state: EnergyPlusData):

    def oneTimeInit_new(inout self, state: EnergyPlusData):

struct ZoneCoupledSurfaceData:
    var Name: String = ""
    var IndexInSurfaceArray: Int = 0
    var SurfaceArea: Float64 = 0.0
    var Width: Float64 = 0.0
    var Length: Float64 = 0.0
    var Depth: Float64 = 0.0
    var Conductivity: Float64 = 0.0
    var Density: Float64 = 0.0
    var InsulationConductivity: Float64 = 0.0
    var InsulationDensity: Float64 = 0.0
    var Zone: Int = 0

struct Domain:
    var Name: String = ""
    var circuits: List[Circuit]
    var MaxIterationsPerTS: Int = 10
    var OneTimeInit: Bool = True
    var BeginSimInit: Bool = True
    var BeginSimEnvironment: Bool = True
    var DomainNeedsSimulation: Bool = True
    var DomainNeedsToBeMeshed: Bool = True
    var IsActuallyPartOfAHorizontalTrench: Bool = False
    var HasAPipeCircuit: Bool = True
    var HasZoneCoupledSlab: Bool = False
    var HasZoneCoupledBasement: Bool = False
    var Extents: MeshExtents
    var Mesh: MeshProperties
    var GroundProperties: BaseThermalPropertySet
    var SlabProperties: BaseThermalPropertySet
    var BasementInterfaceProperties: BaseThermalPropertySet
    var HorizInsProperties: BaseThermalPropertySet
    var VertInsProperties: BaseThermalPropertySet
    var SimControls: SimulationControl
    var groundTempModel: BaseGroundTempsModel  # non-owning pointer (reference)
    var BasementZone: BasementZoneInfo
    var Moisture: MoistureInfo
    var Partitions: MeshPartitions
    var Cur: CurSimConditionsInfo
    var HasBasement: Bool = False
    var ZoneCoupledSurfaces: List[ZoneCoupledSurfaceData]
    var ZoneCoupledOSCMIndex: Int = 0
    var PerimeterOffset: Float64 = 0.0
    var slabPosition: SlabPosition = SlabPosition.Invalid
    var SlabMaterialNum: Int = 0
    var SlabArea: Float64 = 0.0
    var SlabWidth: Float64 = 0.0
    var SlabLength: Float64 = 0.0
    var SlabThickness: Float64 = 0.0
    var XIndex: Int = 0
    var YIndex: Int = 0
    var ZIndex: Int = 0
    var x_max_index: Int = 0
    var y_max_index: Int = 0
    var z_max_index: Int = 0
    var HorizIns: HorizInsulation = HorizInsulation.Invalid
    var HorizInsMaterialNum: Int = 0
    var HorizInsThickness: Float64 = 0.0254
    var HorizInsWidth: Float64 = 0.0
    var HeatFlux: Float64 = 0.0
    var WallHeatFlux: Float64 = 0.0
    var FloorHeatFlux: Float64 = 0.0
    var AggregateHeatFlux: Float64 = 0.0
    var AggregateWallHeatFlux: Float64 = 0.0
    var AggregateFloorHeatFlux: Float64 = 0.0
    var NumHeatFlux: Int = 0
    var ResetHeatFluxFlag: Bool = True
    var ConvectionCoefficient: Float64 = 0.0
    var VertInsPresentFlag: Bool = False
    var VertInsMaterialNum: Int = 0
    var VertInsThickness: Float64 = 0.0254
    var VertInsDepth: Float64 = 0.0
    var XWallIndex: Int = 0
    var YFloorIndex: Int = 0
    var ZWallIndex: Int = 0
    var InsulationXIndex: Int = 0
    var InsulationYIndex: Int = 0
    var InsulationZIndex: Int = 0
    var ZoneCoupledSurfaceTemp: Float64 = 0.0
    var BasementWallTemp: Float64 = 0.0
    var BasementFloorTemp: Float64 = 0.0
    var NumDomainCells: Int = 0
    var NumGroundSurfCells: Int = 0
    var NumInsulationCells: Int = 0
    var NumSlabCells: Int = 0
    var WeightingFactor: Array2D[Float64]
    var WeightedHeatFlux: Array2D[Float64]
    var TotalEnergyUniformHeatFlux: Float64 = 0.0
    var TotalEnergyWeightedHeatFlux: Float64 = 0.0
    var HeatFluxWeightingFactor: Float64 = 0.0
    var XRegions: List[GridRegion]
    var YRegions: List[GridRegion]
    var ZRegions: List[GridRegion]
    var Cells: Array3D[CartesianCell]
    var NeighborFieldCells: List[Direction]
    var NeighborBoundaryCells: List[Direction]

    def __init__(inout self):
        self.NeighborFieldCells = List[Direction](size=6)
        self.NeighborBoundaryCells = List[Direction](size=6)
        self.XRegions = List[GridRegion]()
        self.YRegions = List[GridRegion]()
        self.ZRegions = List[GridRegion]()
        self.circuits = List[Circuit]()
        self.ZoneCoupledSurfaces = List[ZoneCoupledSurfaceData]()

    def developMesh(inout self, state: EnergyPlusData):
        self.createPartitionCenterList(state)
        var XPartitionsExist = not self.Partitions.X.empty()
        var XPartitionRegions = self.createPartitionRegionList(state, self.Partitions.X, XPartitionsExist, self.Extents.xMax)
        var YPartitionsExist = not self.Partitions.Y.empty()
        var YPartitionRegions = self.createPartitionRegionList(state, self.Partitions.Y, YPartitionsExist, self.Extents.yMax)
        var ZPartitionsExist = not self.Partitions.Z.empty()
        var ZPartitionRegions = self.createPartitionRegionList(state, self.Partitions.Z, ZPartitionsExist, self.Extents.zMax)
        if self.HasZoneCoupledBasement:
            self.createRegionList(self.XRegions, XPartitionRegions, self.Extents.xMax, RegionType.XDirection, XPartitionsExist, _, _, self.XIndex, self.XWallIndex, self.InsulationXIndex)
            self.createRegionList(self.YRegions, YPartitionRegions, self.Extents.yMax, RegionType.YDirection, YPartitionsExist, _, _, _, _, _, self.YIndex, self.YFloorIndex, self.InsulationYIndex)
            self.createRegionList(self.ZRegions, ZPartitionRegions, self.Extents.zMax, RegionType.ZDirection, ZPartitionsExist, _, _, _, _, _, _, _, _, self.ZIndex, self.ZWallIndex, self.InsulationZIndex)
        elif self.HasZoneCoupledSlab:
            self.createRegionList(self.XRegions, XPartitionRegions, self.Extents.xMax, RegionType.XDirection, XPartitionsExist, _, _, self.XIndex, _, self.InsulationXIndex)
            self.createRegionList(self.YRegions, YPartitionRegions, self.Extents.yMax, RegionType.YDirection, YPartitionsExist, _, _, _, _, _, self.YIndex, _, self.InsulationYIndex)
            self.createRegionList(self.ZRegions, ZPartitionRegions, self.Extents.zMax, RegionType.ZDirection, ZPartitionsExist, _, _, _, _, _, _, _, _, self.ZIndex, _, self.InsulationZIndex)
        else:
            self.createRegionList(self.XRegions, XPartitionRegions, self.Extents.xMax, RegionType.XDirection, XPartitionsExist, self.BasementZone.BasementWallXIndex)
            self.createRegionList(self.YRegions, YPartitionRegions, self.Extents.yMax, RegionType.YDirection, YPartitionsExist, _, self.BasementZone.BasementFloorYIndex)
            self.createRegionList(self.ZRegions, ZPartitionRegions, self.Extents.zMax, RegionType.ZDirection, ZPartitionsExist)
        var XBoundaryPoints = CreateBoundaryList(self.XRegions, self.Extents.xMax, RegionType.XDirection)
        var YBoundaryPoints = CreateBoundaryList(self.YRegions, self.Extents.yMax, RegionType.YDirection)
        var ZBoundaryPoints = CreateBoundaryList(self.ZRegions, self.Extents.zMax, RegionType.ZDirection)
        self.createCellArray(XBoundaryPoints, YBoundaryPoints, ZBoundaryPoints)
        self.setupCellNeighbors()
        self.setupPipeCircuitInOutCells()

    def createPartitionCenterList(inout self, state: EnergyPlusData):
        var BasementCellFraction = 0.001
        var BasementDistFromBottom: Float64
        var FloorLocation: Float64
        var UnderFloorLocation: Float64
        var PipeCellWidth: Float64
        var SurfCellWidth: Float64
        var SideXLocation: Float64
        var SideXWallLocation: Float64
        var SideXInsulationLocation: Float64
        var SideZLocation: Float64
        var SideZWallLocation: Float64
        var SideZInsulationLocation: Float64
        var SlabDistFromBottom: Float64
        var YInsulationLocation: Float64
        var CellWidth = 0.0
        var InterfaceCellWidth = 0.008
        var ThisSegment: Segment
        for thisCircuit in self.circuits:
            if not thisCircuit.HasInsulation:
                PipeCellWidth = thisCircuit.PipeSize.OuterDia
            else:
                PipeCellWidth = thisCircuit.InsulationSize.OuterDia
            PipeCellWidth += 2 * thisCircuit.RadialMeshThickness
            for segment in thisCircuit.pipeSegments:
                if segment.PipeLocation.X not in self.Partitions.X:
                    self.Partitions.X.append(MeshPartition(rDimension=segment.PipeLocation.X, partitionType=PartitionType.Pipe, TotalWidth=PipeCellWidth))
                if segment.PipeLocation.Y not in self.Partitions.Y:
                    self.Partitions.Y.append(MeshPartition(rDimension=segment.PipeLocation.Y, partitionType=PartitionType.Pipe, TotalWidth=PipeCellWidth))
        if not self.HasZoneCoupledBasement:
            if self.HasBasement:
                if self.BasementZone.Width > 0:
                    SurfCellWidth = self.Extents.xMax * BasementCellFraction
                    if self.BasementZone.Width not in self.Partitions.X:
                        self.Partitions.X.append(MeshPartition(rDimension=self.BasementZone.Width, partitionType=PartitionType.BasementWall, TotalWidth=SurfCellWidth))
                if self.BasementZone.Depth > 0:
                    SurfCellWidth = self.Extents.yMax * BasementCellFraction
                    BasementDistFromBottom = self.Extents.yMax - self.BasementZone.Depth
                    if BasementDistFromBottom not in self.Partitions.Y:
                        self.Partitions.Y.append(MeshPartition(rDimension=BasementDistFromBottom, partitionType=PartitionType.BasementFloor, TotalWidth=SurfCellWidth))
        else:
            if self.BasementZone.Width > 0:
                CellWidth = self.VertInsThickness
                SideXLocation = self.PerimeterOffset - InterfaceCellWidth - CellWidth / 2.0
                SideXWallLocation = self.PerimeterOffset - InterfaceCellWidth / 2.0
                if self.HorizIns == HorizInsulation.Perimeter:
                    SideXInsulationLocation = self.PerimeterOffset + self.HorizInsWidth + InterfaceCellWidth / 2.0
                else:
                    SideXInsulationLocation = -1.0
                if self.BasementZone.Width not in self.Partitions.X:
                    if self.HorizIns == HorizInsulation.Perimeter:
                        self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
                        self.Partitions.X.append(MeshPartition(rDimension=SideXWallLocation, partitionType=PartitionType.XSideWall, TotalWidth=InterfaceCellWidth))
                        self.Partitions.X.append(MeshPartition(rDimension=SideXInsulationLocation, partitionType=PartitionType.HorizInsXSide, TotalWidth=InterfaceCellWidth))
                    elif self.HorizIns == HorizInsulation.Full:
                        self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
                        self.Partitions.X.append(MeshPartition(rDimension=SideXWallLocation, partitionType=PartitionType.XSideWall, TotalWidth=InterfaceCellWidth))
                    else:
                        self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
                        self.Partitions.X.append(MeshPartition(rDimension=SideXWallLocation, partitionType=PartitionType.XSideWall, TotalWidth=InterfaceCellWidth))
            if self.BasementZone.Depth > 0:
                CellWidth = self.HorizInsThickness
                FloorLocation = self.Extents.yMax - self.BasementZone.Depth - InterfaceCellWidth / 2.0
                UnderFloorLocation = self.Extents.yMax - self.BasementZone.Depth - InterfaceCellWidth - CellWidth / 2.0
                if self.VertInsPresentFlag:
                    YInsulationLocation = self.Extents.yMax - self.VertInsDepth - InterfaceCellWidth / 2.0
                else:
                    YInsulationLocation = -1.0
                if FloorLocation not in self.Partitions.Y:
                    if self.VertInsPresentFlag and YInsulationLocation > FloorLocation + CellWidth:
                        self.Partitions.Y.append(MeshPartition(rDimension=FloorLocation, partitionType=PartitionType.FloorInside, TotalWidth=InterfaceCellWidth))
                        self.Partitions.Y.append(MeshPartition(rDimension=UnderFloorLocation, partitionType=PartitionType.UnderFloor, TotalWidth=CellWidth))
                        self.Partitions.Y.append(MeshPartition(rDimension=YInsulationLocation, partitionType=PartitionType.VertInsLowerEdge, TotalWidth=InterfaceCellWidth))
                    else:
                        self.Partitions.Y.append(MeshPartition(rDimension=FloorLocation, partitionType=PartitionType.FloorInside, TotalWidth=InterfaceCellWidth))
                        self.Partitions.Y.append(MeshPartition(rDimension=UnderFloorLocation, partitionType=PartitionType.UnderFloor, TotalWidth=CellWidth))
            if self.BasementZone.Width > 0:
                CellWidth = self.VertInsThickness
                SideZLocation = self.PerimeterOffset - InterfaceCellWidth - CellWidth / 2.0
                SideZWallLocation = self.PerimeterOffset - InterfaceCellWidth / 2.0
                if self.HorizIns == HorizInsulation.Perimeter:
                    SideZInsulationLocation = self.PerimeterOffset + self.HorizInsWidth + InterfaceCellWidth / 2.0
                else:
                    SideZInsulationLocation = -1.0
                if self.BasementZone.Width not in self.Partitions.Z:
                    if self.HorizIns == HorizInsulation.Perimeter:
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZWallLocation, partitionType=PartitionType.ZSideWall, TotalWidth=InterfaceCellWidth))
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZInsulationLocation, partitionType=PartitionType.HorizInsZSide, TotalWidth=InterfaceCellWidth))
                    elif self.HorizIns == HorizInsulation.Full:
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZWallLocation, partitionType=PartitionType.ZSideWall, TotalWidth=InterfaceCellWidth))
                    else:
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
                        self.Partitions.Z.append(MeshPartition(rDimension=SideZWallLocation, partitionType=PartitionType.ZSideWall, TotalWidth=InterfaceCellWidth))
        if self.HasZoneCoupledSlab:
            CellWidth = self.VertInsThickness
            SideXLocation = self.PerimeterOffset - CellWidth / 2.0
            if self.HorizIns == HorizInsulation.Perimeter:
                SideXInsulationLocation = SideXLocation + self.HorizInsWidth
            else:
                SideXInsulationLocation = -1.0
            if self.SlabWidth not in self.Partitions.X:
                if self.HorizIns == HorizInsulation.Perimeter:
                    self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
                    self.Partitions.X.append(MeshPartition(rDimension=SideXInsulationLocation, partitionType=PartitionType.HorizInsXSide, TotalWidth=CellWidth))
                elif self.HorizIns == HorizInsulation.Full:
                    self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
                else:
                    self.Partitions.X.append(MeshPartition(rDimension=SideXLocation, partitionType=PartitionType.XSide, TotalWidth=CellWidth))
            CellWidth = self.HorizInsThickness
            if self.VertInsPresentFlag:
                YInsulationLocation = self.Extents.yMax - self.VertInsDepth + CellWidth / 2.0
            else:
                YInsulationLocation = -1.0
            if self.slabPosition == SlabPosition.InGrade:
                SlabDistFromBottom = self.Extents.yMax - self.SlabThickness - CellWidth / 2.0
                if SlabDistFromBottom not in self.Partitions.Y:
                    if self.VertInsPresentFlag:
                        self.Partitions.Y.append(MeshPartition(rDimension=SlabDistFromBottom, partitionType=PartitionType.UnderFloor, TotalWidth=CellWidth))
                        self.Partitions.Y.append(MeshPartition(rDimension=YInsulationLocation, partitionType=PartitionType.VertInsLowerEdge, TotalWidth=CellWidth))
                    else:
                        self.Partitions.Y.append(MeshPartition(rDimension=SlabDistFromBottom, partitionType=PartitionType.UnderFloor, TotalWidth=CellWidth))
            else:
                if YInsulationLocation not in self.Partitions.Y:
                    if self.VertInsPresentFlag:
                        self.Partitions.Y.append(MeshPartition(rDimension=YInsulationLocation, partitionType=PartitionType.VertInsLowerEdge, TotalWidth=CellWidth))
            CellWidth = self.VertInsThickness
            SideZLocation = self.PerimeterOffset - CellWidth / 2.0
            if self.HorizIns == HorizInsulation.Perimeter:
                SideZInsulationLocation = SideZLocation + self.HorizInsWidth
            else:
                SideZInsulationLocation = -1.0
            if self.SlabWidth not in self.Partitions.Z:
                if self.HorizIns == HorizInsulation.Perimeter:
                    self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
                    self.Partitions.Z.append(MeshPartition(rDimension=SideZInsulationLocation, partitionType=PartitionType.HorizInsZSide, TotalWidth=CellWidth))
                elif self.HorizIns == HorizInsulation.Full:
                    self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
                else:
                    self.Partitions.Z.append(MeshPartition(rDimension=SideZLocation, partitionType=PartitionType.ZSide, TotalWidth=CellWidth))
        # sort
        self.Partitions.X.sort(key = lambda mp: mp.rDimension)
        self.Partitions.Y.sort(key = lambda mp: mp.rDimension)
        self.Partitions.Z.sort(key = lambda mp: mp.rDimension)

    def createPartitionRegionList(inout self, state: EnergyPlusData, ThesePartitionCenters: List[MeshPartition], PartitionsExist: Bool, DirExtentMax: Float64) -> List[GridRegion]:
        var ThesePartitionRegions = List[GridRegion]()
        if not PartitionsExist:
            return ThesePartitionRegions
        for Index in range(len(ThesePartitionCenters)):
            var thisPartitionCenter = ThesePartitionCenters[Index]
            var ThisCellWidthBy2 = thisPartitionCenter.TotalWidth / 2.0
            var ThisPartitionType = thisPartitionCenter.partitionType
            var CellLeft = thisPartitionCenter.rDimension - ThisCellWidthBy2
            var CellRight = thisPartitionCenter.rDimension + ThisCellWidthBy2
            if CellLeft < 0.0 or CellRight > DirExtentMax:
                ShowSevereError(state, String.format("PlantPipingSystems::CreatePartitionRegionList: Invalid partition location in domain."))
                ShowContinueError(state, String.format("Occurs during mesh development for domain={}", self.Name))
                ShowContinueError(state, "A pipe or basement is located outside of the domain extents.")
                ShowFatalError(state, "Preceding error causes program termination.")
            for SubIndex in range(Index):
                var thisPartitionRegionSubIndex = ThesePartitionRegions[SubIndex]
                if self.HasZoneCoupledBasement and Index == 1:
                    if IsInRange_BasementModel(CellLeft, thisPartitionRegionSubIndex.Min, thisPartitionRegionSubIndex.Max) or IsInRangeReal(CellRight, thisPartitionRegionSubIndex.Min, thisPartitionRegionSubIndex.Max):
                        ShowSevereError(state, String.format("PlantPipingSystems::CreatePartitionRegionList: Invalid partition location in domain."))
                        ShowContinueError(state, String.format("Occurs during mesh development for domain={}", self.Name))
                        ShowContinueError(state, "A mesh conflict was encountered where partitions were overlapping.")
                        ShowContinueError(state, "Ensure that all pipes exactly line up or are separated to allow meshing in between them")
                        ShowContinueError(state, "Also verify the pipe and basement dimensions to avoid conflicts there.")
                        ShowFatalError(state, "Preceding error causes program termination")
                else:
                    if IsInRangeReal(CellLeft, thisPartitionRegionSubIndex.Min, thisPartitionRegionSubIndex.Max) or IsInRangeReal(CellRight, thisPartitionRegionSubIndex.Min, thisPartitionRegionSubIndex.Max):
                        ShowSevereError(state, String.format("PlantPipingSystems::CreatePartitionRegionList: Invalid partition location in domain."))
                        ShowContinueError(state, String.format("Occurs during mesh development for domain={}", self.Name))
                        ShowContinueError(state, "A mesh conflict was encountered where partitions were overlapping.")
                        ShowContinueError(state, "Ensure that all pipes exactly line up or are separated to allow meshing in between them")
                        ShowContinueError(state, "Also verify the pipe and basement dimensions to avoid conflicts there.")
                        ShowFatalError(state, "Preceding error causes program termination")
            ThesePartitionRegions.append(GridRegion())
            var thisNewPartitionRegion = ThesePartitionRegions[Index]
            thisNewPartitionRegion.Min = CellLeft
            thisNewPartitionRegion.Max = CellRight
            if ThisPartitionType == PartitionType.BasementWall:
                thisNewPartitionRegion.thisRegionType = RegionType.BasementWall
            elif ThisPartitionType == PartitionType.BasementFloor:
                thisNewPartitionRegion.thisRegionType = RegionType.BasementFloor
            elif ThisPartitionType == PartitionType.Pipe:
                thisNewPartitionRegion.thisRegionType = RegionType.Pipe
            elif ThisPartitionType == PartitionType.XSide:
                thisNewPartitionRegion.thisRegionType = RegionType.XSide
            elif ThisPartitionType == PartitionType.XSideWall:
                thisNewPartitionRegion.thisRegionType = RegionType.XSideWall
            elif ThisPartitionType == PartitionType.HorizInsXSide:
                thisNewPartitionRegion.thisRegionType = RegionType.HorizInsXSide
            elif ThisPartitionType == PartitionType.ZSide:
                thisNewPartitionRegion.thisRegionType = RegionType.ZSide
            elif ThisPartitionType == PartitionType.ZSideWall:
                thisNewPartitionRegion.thisRegionType = RegionType.ZSideWall
            elif ThisPartitionType == PartitionType.HorizInsZSide:
                thisNewPartitionRegion.thisRegionType = RegionType.HorizInsZSide
            elif ThisPartitionType == PartitionType.FloorInside:
                thisNewPartitionRegion.thisRegionType = RegionType.FloorInside
            elif ThisPartitionType == PartitionType.UnderFloor:
                thisNewPartitionRegion.thisRegionType = RegionType.UnderFloor
            elif ThisPartitionType == PartitionType.VertInsLowerEdge:
                thisNewPartitionRegion.thisRegionType = RegionType.VertInsLowerEdge
            else:

        return ThesePartitionRegions

    def createRegionList(inout self, inout Regions: List[GridRegion], ThesePartitionRegions: List[GridRegion], DirExtentMax: Float64, DirDirection: RegionType, PartitionsExist: Bool, BasementWallXIndex: Optional[Int] = _, BasementFloorYIndex: Optional[Int] = _, XIndex: Optional[Int] = _, XWallIndex: Optional[Int] = _, InsulationXIndex: Optional[Int] = _, YIndex: Optional[Int] = _, YFloorIndex: Optional[Int] = _, InsulationYIndex: Optional[Int] = _, ZIndex: Optional[Int] = _, ZWallIndex: Optional[Int] = _, InsulationZIndex: Optional[Int] = _):
        var tempCellWidths = List[Float64]()
        if PartitionsExist:
            var cellCountUpToNow = 0
            for i in range(len(ThesePartitionRegions)):
                var thisPartition = ThesePartitionRegions[i]
                if i == 0:
                    var tempRegion = GridRegion(Min=0.0, Max=thisPartition.Min, thisRegionType=DirDirection, CellWidths=tempCellWidths)
                    var potentialCellWidthsCount = self.getCellWidthsCount(DirDirection)
                    if (thisPartition.Min - 0.0) < 0.00001:
                        cellCountUpToNow += 1
                    else:
                        cellCountUpToNow += potentialCellWidthsCount
                    self.getCellWidths(tempRegion, tempRegion.thisRegionType)
                    Regions.append(tempRegion)
                elif i == 1 and self.HasZoneCoupledBasement:
                    cellCountUpToNow += 1
                else:
                    cellCountUpToNow += 1
                    var leftPartition = ThesePartitionRegions[i - 1]
                    var tempRegion = GridRegion(Min=leftPartition.Max, Max=thisPartition.Min, thisRegionType=DirDirection, CellWidths=tempCellWidths)
                    var potentialCellWidthsCount = self.getCellWidthsCount(DirDirection)
                    if (thisPartition.Min - leftPartition.Max) < 0.00001:
                        cellCountUpToNow += 1
                    else:
                        cellCountUpToNow += potentialCellWidthsCount
                    self.getCellWidths(tempRegion, tempRegion.thisRegionType)
                    Regions.append(tempRegion)
                if thisPartition.thisRegionType == RegionType.BasementWall:
                    if BasementWallXIndex:
                        BasementWallXIndex.set(cellCountUpToNow)
                elif thisPartition.thisRegionType == RegionType.BasementFloor:
                    if BasementFloorYIndex:
                        BasementFloorYIndex.set(cellCountUpToNow)
                elif thisPartition.thisRegionType == RegionType.XSide:
                    if XIndex:
                        XIndex.set(cellCountUpToNow)
                    self.XIndex = XIndex.value()
                elif thisPartition.thisRegionType == RegionType.XSideWall:
                    if XWallIndex:
                        XWallIndex.set(cellCountUpToNow)
                    self.XWallIndex = XWallIndex.value()
                elif thisPartition.thisRegionType == RegionType.ZSide:
                    if ZIndex:
                        ZIndex.set(cellCountUpToNow)
                    self.ZIndex = ZIndex.value()
                elif thisPartition.thisRegionType == RegionType.ZSideWall:
                    if ZWallIndex:
                        ZWallIndex.set(cellCountUpToNow)
                    self.ZWallIndex = ZWallIndex.value()
                elif thisPartition.thisRegionType == RegionType.HorizInsXSide:
                    if InsulationXIndex:
                        InsulationXIndex.set(cellCountUpToNow)
                    self.InsulationXIndex = InsulationXIndex.value()
                elif thisPartition.thisRegionType == RegionType.HorizInsZSide:
                    if InsulationZIndex:
                        InsulationZIndex.set(cellCountUpToNow)
                    self.InsulationZIndex = InsulationZIndex.value()
                elif thisPartition.thisRegionType == RegionType.FloorInside:
                    if YFloorIndex:
                        YFloorIndex.set(cellCountUpToNow)
                    self.YFloorIndex = YFloorIndex.value()
                elif thisPartition.thisRegionType == RegionType.UnderFloor:
                    if YIndex:
                        YIndex.set(cellCountUpToNow)
                    self.YIndex = YIndex.value()
                elif thisPartition.thisRegionType == RegionType.VertInsLowerEdge:
                    if InsulationYIndex:
                        InsulationYIndex.set(cellCountUpToNow)
                    self.InsulationYIndex = InsulationYIndex.value()
                var tempRegion2 = GridRegion(Min=thisPartition.Min, Max=thisPartition.Max, thisRegionType=thisPartition.thisRegionType, CellWidths=tempCellWidths)
                self.getCellWidths(tempRegion2, tempRegion2.thisRegionType)
                Regions.append(tempRegion2)
            var lastPartition = ThesePartitionRegions[len(ThesePartitionRegions)-1]
            var tempRegion3 = GridRegion(Min=lastPartition.Max, Max=DirExtentMax, thisRegionType=DirDirection, CellWidths=tempCellWidths)
            self.getCellWidths(tempRegion3, tempRegion3.thisRegionType)
            Regions.append(tempRegion3)
        else:
            var tempRegion = GridRegion(Min=0.0, Max=DirExtentMax, thisRegionType=DirDirection, CellWidths=tempCellWidths)
            self.getCellWidths(tempRegion, tempRegion.thisRegionType)
            Regions.append(tempRegion)

    def createCellArray(inout self, XBoundaryPoints: List[Float64], YBoundaryPoints: List[Float64], ZBoundaryPoints: List[Float64]):
        var TotNumCells = 0
        var NumCutawayBasementCells = 0
        var NumInsulationCells = 0
        var NumGroundSurfaceCells = 0
        self.x_max_index = len(XBoundaryPoints) - 2
        self.y_max_index = len(YBoundaryPoints) - 2
        self.z_max_index = len(ZBoundaryPoints) - 2
        self.Cells.allocate((0, self.x_max_index), (0, self.y_max_index), (0, self.z_max_index))
        var MaxBasementXNodeIndex = self.BasementZone.BasementWallXIndex
        var MinBasementYNodeIndex = self.BasementZone.BasementFloorYIndex
        var MinXIndex = self.XIndex
        var YIndex = self.YIndex
        var MinZIndex = self.ZIndex
        var XWallIndex = self.XWallIndex
        var YFloorIndex = self.YFloorIndex
        var ZWallIndex = self.ZWallIndex
        var InsulationXIndex = self.InsulationXIndex
        var InsulationYIndex = self.InsulationYIndex
        var InsulationZIndex = self.InsulationZIndex
        var cells = self.Cells
        # Loop
        for X in range(self.x_max_index+1):
            for Y in range(self.y_max_index+1):
                for Z in range(self.z_max_index+1):
                    var cell = cells[(X, Y, Z)]
                    var CellXIndex = X
                    var CellXMinValue = XBoundaryPoints[X]
                    var CellXMaxValue = XBoundaryPoints[X + 1]
                    var CellXCenter = (CellXMinValue + CellXMaxValue) / 2.0
                    var CellWidth = CellXMaxValue - CellXMinValue
                    var CellYIndex = Y
                    var CellYMinValue = YBoundaryPoints[Y]
                    var CellYMaxValue = YBoundaryPoints[Y + 1]
                    var CellYCenter = (CellYMinValue + CellYMaxValue) / 2.0
                    var CellHeight = CellYMaxValue - CellYMinValue
                    var CellZIndex = Z
                    var CellZMinValue = ZBoundaryPoints[Z]
                    var CellZMaxValue = ZBoundaryPoints[Z + 1]
                    var CellZCenter = (CellZMinValue + CellZMaxValue) / 2.0
                    var theseCellExtents = CellExtents(CellXMaxValue, CellYMaxValue, CellZMaxValue, CellXMinValue, CellYMinValue, CellZMinValue)
                    var Centroid = Point3DReal(CellXCenter, CellYCenter, CellZCenter)
                    var CellIndeces = Point3DInteger(CellXIndex, CellYIndex, CellZIndex)
                    var XYRectangle = RectangleF(CellXMinValue, CellYMinValue, CellWidth, CellHeight)
                    var cellType = CellType.Invalid
                    var pipeCell = False
                    var NumRadialCells = -1
                    var ZWallCellType = CellType.FarfieldBoundary
                    var UnderBasementBoundary = CellType.FarfieldBoundary
                    if self.HasZoneCoupledSlab:
                        if CellXIndex == MinXIndex and CellZIndex >= MinZIndex:
                            if self.VertInsPresentFlag:
                                if CellYIndex <= self.y_max_index and CellYIndex >= InsulationYIndex:
                                    cellType = CellType.VertInsulation
                                    NumInsulationCells += 1
                            elif CellYIndex == self.y_max_index:
                                cellType = CellType.GroundSurface
                                NumGroundSurfaceCells += 1
                        elif CellZIndex == MinZIndex and CellXIndex >= MinXIndex:
                            if self.VertInsPresentFlag:
                                if CellYIndex <= self.y_max_index and CellYIndex >= InsulationYIndex:
                                    cellType = CellType.VertInsulation
                                    NumInsulationCells += 1
                            elif CellYIndex == self.y_max_index:
                                cellType = CellType.GroundSurface
                                NumGroundSurfaceCells += 1
                        elif CellYIndex == self.y_max_index:
                            if CellXIndex <= MinXIndex or CellZIndex <= Min