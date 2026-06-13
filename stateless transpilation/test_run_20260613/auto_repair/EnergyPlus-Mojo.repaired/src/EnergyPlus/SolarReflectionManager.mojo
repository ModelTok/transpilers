// Mojo translation of SolarReflectionManager.cc and SolarReflectionManager.hh

from DataHeatBalance import (
    SurfaceClass,
    Shadowing,
    SolarDistribution,
)
from DataSurfaces import (
    Surface,
    SurfShadowRecSurfNum,
    SurfReflFacBmToDiffSolObs,
    SurfReflFacBmToDiffSolGnd,
    SurfReflFacBmToBmSolObs,
    SurfReflFacSkySolObs,
    SurfReflFacSkySolGnd,
    SurfCosIncAveBmToBmSolObs,
    MaxRecPts,
    MaxReflRays,
    TotSurfaces,
    CalcSolRefl,
    AllShadowPossObstrSurfaceList,
    SurfShadowDiffuseSolRefl,
    SurfDaylightingShelfInd,
    SurfShadowGlazingFrac,
    SurfShadowGlazingConstruct,
    ShadingTransmittanceVaries,
    AltAngStepsForSolReflCalc,
    AzimAngStepsForSolReflCalc,
)
from DataEnvironment import (
    IgnoreSolarRadiation,
    GndReflectance,
    SunIsUpValue,
)
from DataVectorTypes import (
    Vector3,
    dot,
    cross,
    distance,
    distance_squared,
)
from DataGlobals import (
    BeginSimFlag,
    HourOfDay,
)
from UtilityRoutines import (
    ShowWarningError,
    ShowContinueError,
    DisplayString,
)
from PierceSurface import PierceSurface
from Window import POLYF  # Assuming Window module provides POLYF
from Construction import Construct  # Assuming Construction module
from ScheduleManager import *  # not used directly but needed for compilation
from General import *  # for format
from DataSystemVariables import DetailedSolarTimestepIntegration, DetailedSkyDiffuseAlgorithm
from DataHeatBalance import SurfSunlitFrac, SolarDistribution as HD_SolarDistribution  # if needed
from DataShading import SurfDifShdgRatioIsoSky, SurfDifShdgRatioIsoSkyHRTS  # assuming

from DataVectorTypes import Vector3  # already imported

// Global constants (from Constant namespace assumed)
struct Constant:
    static let Pi: Float64 = 3.141592653589793
    static let PiOvr2: Float64 = Pi / 2.0
    static let OneMillionth: Float64 = 1.0e-6

// Struct for SolReflRecSurfData
struct SolReflRecSurfData:
    var SurfNum: Int = 0
    var SurfName: String = ""
    var NumRecPts: Int = 0
    var RecPt: Array1D_Vector3 = Array1D_Vector3()
    var NormVec: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ThetaNormVec: Float64 = 0.0
    var PhiNormVec: Float64 = 0.0
    var NumReflRays: Int = 0
    var RayVec: Array1D_Vector3 = Array1D_Vector3()
    var CosIncAngRay: Array1D_Float64 = Array1D_Float64()
    var dOmegaRay: Array1D_Float64 = Array1D_Float64()
    var HitPt: Array2D_Vector3 = Array2D_Vector3()
    var HitPtSurfNum: Array2D_Int = Array2D_Int()
    var HitPtSolRefl: Array2D_Float64 = Array2D_Float64()
    var RecPtHitPtDis: Array2D_Float64 = Array2D_Float64()
    var HitPtNormVec: Array2D_Vector3 = Array2D_Vector3()
    var PossibleObsSurfNums: Array1D_Int = Array1D_Int()
    var NumPossibleObs: Int = 0

    def __init__(inout self):
        self.SurfNum = 0
        self.NumRecPts = 0
        self.NormVec = Vector3(0.0, 0.0, 0.0)
        self.ThetaNormVec = 0.0
        self.PhiNormVec = 0.0
        self.NumReflRays = 0
        self.NumPossibleObs = 0

// Global data struct (SolarReflectionManagerData)
struct SolarReflectionManagerData:
    var TotSolReflRecSurf: Int = 0
    var TotPhiReflRays: Int = 0
    var TotThetaReflRays: Int = 0
    var SolReflRecSurf: Array1D_SolReflRecSurfData = Array1D_SolReflRecSurfData()
    var IHr: Int = 0
    var SunVec: Vector3 = Vector3(0.0, 0.0, 0.0)
    var RecSurfNum: Int = 0
    var SurfNum: Int = 0
    var RecPtNum: Int = 0
    var NumRecPts: Int = 0
    var HitPtSurfNum: Int = 0
    var RayNum: Int = 0
    var OriginThisRay: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ObsHitPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ObsSurfNum: Int = 0
    var CosIncBmAtHitPt: Float64 = 0.0
    var CosIncBmAtHitPt2: Float64 = 0.0
    var BmReflSolRadiance: Float64 = 0.0
    var dReflBeamToDiffSol: Float64 = 0.0
    var SunLitFract: Float64 = 0.0
    var NumHr: Int = 0
    var SunVect: Vector3 = Vector3(0.0, 0.0, 0.0)
    var SunVecMir: Vector3 = Vector3(0.0, 0.0, 0.0)
    var RecPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var HitPtRefl: Vector3 = Vector3(0.0, 0.0, 0.0)
    var HitPtObs: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ReflNorm: Vector3 = Vector3(0.0, 0.0, 0.0)
    var SpecReflectance: Float64 = 0.0
    var ConstrNumRefl: Int = 0
    var CosIncAngRefl: Float64 = 0.0
    var CosIncAngRec: Float64 = 0.0
    var ReflFac: Float64 = 0.0
    var CosIncWeighted: Float64 = 0.0
    var iRecSurfNum: Int = 0
    var iSurfNum: Int = 0
    var iObsSurfNum: Int = 0
    var iRecPtNum: Int = 0
    var iNumRecPts: Int = 0
    var HitPntSurfNum: Int = 0
    var HitPtSurfNumX: Int = 0
    var iRayNum: Int = 0
    var HitPntRefl: Vector3 = Vector3(0.0, 0.0, 0.0)
    var HitPntObs: Vector3 = Vector3(0.0, 0.0, 0.0)
    var SkyReflSolRadiance: Float64 = 0.0
    var dReflSkySol: Float64 = 0.0
    var URay: Vector3 = Vector3(0.0, 0.0, 0.0)
    var SurfVertToGndPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var SurfVert: Vector3 = Vector3(0.0, 0.0, 0.0)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.IHr = 0
        self.SunVec = Vector3(0.0, 0.0, 0.0)
        self.RecSurfNum = 0
        self.SurfNum = 0
        self.RecPtNum = 0
        self.NumRecPts = 0
        self.HitPtSurfNum = 0
        self.RayNum = 0
        self.OriginThisRay = Vector3(0.0, 0.0, 0.0)
        self.ObsHitPt = Vector3(0.0, 0.0, 0.0)
        self.ObsSurfNum = 0
        self.CosIncBmAtHitPt = 0.0
        self.CosIncBmAtHitPt2 = 0.0
        self.BmReflSolRadiance = 0.0
        self.dReflBeamToDiffSol = 0.0
        self.SunLitFract = 0.0
        self.NumHr = 0
        self.SunVect = Vector3(0.0, 0.0, 0.0)
        self.SunVecMir = Vector3(0.0, 0.0, 0.0)
        self.RecPt = Vector3(0.0, 0.0, 0.0)
        self.HitPtRefl = Vector3(0.0, 0.0, 0.0)
        self.HitPtObs = Vector3(0.0, 0.0, 0.0)
        self.ReflNorm = Vector3(0.0, 0.0, 0.0)
        self.SpecReflectance = 0.0
        self.ConstrNumRefl = 0
        self.CosIncAngRefl = 0.0
        self.CosIncAngRec = 0.0
        self.ReflFac = 0.0
        self.CosIncWeighted = 0.0
        self.iRecSurfNum = 0
        self.iSurfNum = 0
        self.iObsSurfNum = 0
        self.iRecPtNum = 0
        self.iNumRecPts = 0
        self.HitPntSurfNum = 0
        self.HitPtSurfNumX = 0
        self.iRayNum = 0
        self.HitPntRefl = Vector3(0.0, 0.0, 0.0)
        self.HitPntObs = Vector3(0.0, 0.0, 0.0)
        self.SkyReflSolRadiance = 0.0
        self.dReflSkySol = 0.0
        self.URay = Vector3(0.0, 0.0, 0.0)
        self.SurfVertToGndPt = Vector3(0.0, 0.0, 0.0)
        self.SurfVert = Vector3(0.0, 0.0, 0.0)

// Helper array types (simplified wrappers to mimic ObjexxFCL)
struct Array1D_Float64:
    var data: List[Float64]
    def __init__(inout self, size: Int = 0, init: Float64 = 0.0):
        self.data = List[Float64]()
        for i in range(size):
            self.data.append(init)

    def allocate(inout self, size: Int, init: Float64 = 0.0):
        self.data = List[Float64]()
        for i in range(size):
            self.data.append(init)

    def dimension(inout self, size1: Int, init: Float64):
        self.data = List[Float64]()
        for i in range(size1):
            self.data.append(init)

    def __getitem__(self, index: Int) -> Float64:
        return self.data[index - 1]  // Convert 1-based to 0-based

    def __setitem__(inout self, index: Int, value: Float64):
        self.data[index - 1] = value

struct Array1D_Int:
    var data: List[Int]
    def __init__(inout self, size: Int = 0, init: Int = 0):
        self.data = List[Int]()
        for i in range(size):
            self.data.append(init)

    def dimension(inout self, size1: Int, init: Int):
        self.data = List[Int]()
        for i in range(size1):
            self.data.append(init)

    def __getitem__(self, index: Int) -> Int:
        return self.data[index - 1]

    def __setitem__(inout self, index: Int, value: Int):
        self.data[index - 1] = value

struct Array1D_Vector3:
    var data: List[Vector3]
    def __init__(inout self, size: Int = 0, init: Vector3 = Vector3(0.0, 0.0, 0.0)):
        self.data = List[Vector3]()
        for i in range(size):
            self.data.append(init)

    def dimension(inout self, size1: Int, init: Vector3):
        self.data = List[Vector3]()
        for i in range(size1):
            self.data.append(init)

    def __getitem__(self, index: Int) -> Vector3:
        return self.data[index - 1]

    def __setitem__(inout self, index: Int, value: Vector3):
        self.data[index - 1] = value

struct Array2D_Float64:
    var data: List[List[Float64]]
    def __init__(inout self, size1: Int = 0, size2: Int = 0, init: Float64 = 0.0):
        self.data = List[List[Float64]]()
        for i in range(size1):
            var row = List[Float64]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def dimension(inout self, size1: Int, size2: Int, init: Float64):
        self.data = List[List[Float64]]()
        for i in range(size1):
            var row = List[Float64]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def __getitem__(self, index1: Int, index2: Int) -> Float64:
        return self.data[index1 - 1][index2 - 1]

    def __setitem__(inout self, index1: Int, index2: Int, value: Float64):
        self.data[index1 - 1][index2 - 1] = value

struct Array2D_Int:
    var data: List[List[Int]]
    def __init__(inout self, size1: Int = 0, size2: Int = 0, init: Int = 0):
        self.data = List[List[Int]]()
        for i in range(size1):
            var row = List[Int]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def dimension(inout self, size1: Int, size2: Int, init: Int):
        self.data = List[List[Int]]()
        for i in range(size1):
            var row = List[Int]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def __getitem__(self, index1: Int, index2: Int) -> Int:
        return self.data[index1 - 1][index2 - 1]

    def __setitem__(inout self, index1: Int, index2: Int, value: Int):
        self.data[index1 - 1][index2 - 1] = value

struct Array2D_Vector3:
    var data: List[List[Vector3]]
    def __init__(inout self, size1: Int = 0, size2: Int = 0, init: Vector3 = Vector3(0.0, 0.0, 0.0)):
        self.data = List[List[Vector3]]()
        for i in range(size1):
            var row = List[Vector3]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def dimension(inout self, size1: Int, size2: Int, init: Vector3):
        self.data = List[List[Vector3]]()
        for i in range(size1):
            var row = List[Vector3]()
            for j in range(size2):
                row.append(init)
            self.data.append(row)

    def __getitem__(self, index1: Int, index2: Int) -> Vector3:
        return self.data[index1 - 1][index2 - 1]

    def __setitem__(inout self, index1: Int, index2: Int, value: Vector3):
        self.data[index1 - 1][index2 - 1] = value

struct Array1D_SolReflRecSurfData:
    var data: List[SolReflRecSurfData]
    def __init__(inout self, size: Int = 0):
        self.data = List[SolReflRecSurfData]()
        for i in range(size):
            self.data.append(SolReflRecSurfData())

    def allocate(inout self, size: Int):
        self.data = List[SolReflRecSurfData]()
        for i in range(size):
            self.data.append(SolReflRecSurfData())

    def __getitem__(self, index: Int) -> SolReflRecSurfData:
        return self.data[index - 1]

    def __setitem__(inout self, index: Int, value: SolReflRecSurfData):
        self.data[index - 1] = value

// EnergyPlusData placeholder (actual struct assumed elsewhere)
struct EnergyPlusData:
    var dataSolarReflectionManager: SolarReflectionManagerData
    var dataSurface: SurfaceData  // assume exists
    var dataEnvrn: EnvironmentData
    var dataConstruction: ConstructionData
    var dataHeatBal: HeatBalanceData
    var dataSysVars: SystemVariablesData
    var dataGlobal: GlobalData
    var dataSolarShading: SolarShadingData

// Placeholder for other data structs (must be defined elsewhere)
struct SurfaceData:
    var Surface: List[SurfaceInfo]  // 1-based indexed, we'll use list but adjust indices
    var TotSurfaces: Int
    var GroundLevelZ: Float64
    var CalcSolRefl: Bool
    var MaxRecPts: Int
    var MaxReflRays: Int
    var SurfReflFacBmToDiffSolObs: Array2D_Float64
    var SurfReflFacBmToDiffSolGnd: Array2D_Float64
    var SurfReflFacBmToBmSolObs: Array2D_Float64
    var SurfReflFacSkySolObs: Array1D_Float64
    var SurfReflFacSkySolGnd: Array1D_Float64
    var SurfCosIncAveBmToBmSolObs: Array2D_Float64
    var SurfShadowRecSurfNum: Array1D_Int
    var SurfDaylightingShelfInd: Array1D_Int
    var SurfShadowDiffuseSolRefl: Array1D_Float64
    var SurfShadowGlazingFrac: Array1D_Float64
    var SurfShadowGlazingConstruct: Array1D_Int
    var AllShadowPossObstrSurfaceList: List[Int]
    var SurfSunCosHourly: List[Vector3]  // for hour 1..24
    var SurfSunlitFrac: Array2D_Float64  // (hour, 1, surf)
    var ShadingTransmittanceVaries: Bool
    // etc.

struct SurfaceInfo:
    var ExtSolar: Bool
    var Name: String
    var Sides: Int
    var Vertex: List[Vector3]  // 1-based
    var OutNormVec: Vector3
    var BaseSurf: Int
    var HeatTransSurf: Bool
    var ExtBoundCond: Int
    var Class: SurfaceClass
    var Construction: Int
    var IsShadowing: Bool
    var MirrorSurf: Bool
    var ViewFactorSky: Float64
    var Tilt: Float64
    var CosTilt: Float64

struct EnvironmentData:
    var IgnoreSolarRadiation: Bool
    var GndReflectance: Float64

struct ConstructionData:
    var Construct: List[ConstructionInfo]

struct ConstructionInfo:
    var TypeIsWindow: Bool
    var OutsideAbsorpSolar: Float64
    var ReflSolBeamFrontCoef: List[Float64]

struct HeatBalanceData:
    var SurfSunlitFrac: Array2D_Float64
    var SolarDistribution: Shadowing

struct SystemVariablesData:
    var DetailedSolarTimestepIntegration: Bool
    var DetailedSkyDiffuseAlgorithm: Bool

struct GlobalData:
    var BeginSimFlag: Bool
    var HourOfDay: Int

struct SolarShadingData:
    var SurfDifShdgRatioIsoSky: Array1D_Float64
    var SurfDifShdgRatioIsoSkyHRTS: Array3D_Float64

// Helper to access Surface array with 1-based index
def getSurface(inout state: EnergyPlusData, surfNum: Int) -> SurfaceInfo:
    return state.dataSurface.Surface[surfNum - 1]

// -----------------------------------------------------------------------------
// Functions
// -----------------------------------------------------------------------------
def InitSolReflRecSurf(inout state: EnergyPlusData):
    var SurfNum: Int = 0
    var RecSurfNum: Int = 0
    var loop: Int = 0
    var loop1: Int = 0
    var loopA: Int = 0
    var loopB: Int = 0
    var ObsSurfNum: Int = 0
    var ObsBehindRec: Bool = False
    var ObsHasView: Bool = False
    var RecVec: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ObsVec: Vector3 = Vector3(0.0, 0.0, 0.0)
    var VecAB: Vector3 = Vector3(0.0, 0.0, 0.0)
    var HitPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var DotProd: Float64 = 0.0
    var RecPtNum: Int = 0
    var PhiSurf: Float64 = 0.0
    var ThetaSurf: Float64 = 0.0
    var PhiMin: Float64 = 0.0
    var PhiMax: Float64 = 0.0
    var ThetaMin: Float64 = 0.0
    var ThetaMax: Float64 = 0.0
    var Phi: Float64 = 0.0
    var DPhi: Float64 = 0.0
    var SPhi: Float64 = 0.0
    var CPhi: Float64 = 0.0
    var Theta: Float64 = 0.0
    var DTheta: Float64 = 0.0
    var IPhi: Int = 0
    var ITheta: Int = 0
    var RayNum: Int = 0
    var URay: Vector3 = Vector3(0.0, 0.0, 0.0)
    var CosIncAngRay: Float64 = 0.0
    var dOmega: Float64 = 0.0
    var hit: Bool = False
    var TotObstructionsHit: Int = 0
    var HitDistance: Float64 = 0.0
    var NearestHitSurfNum: Int = 0
    var NearestHitPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var NearestHitDistance: Float64 = 0.0
    var ObsSurfNumToSkip: Int = 0
    var RecPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var RayVec: Vector3 = Vector3(0.0, 0.0, 0.0)
    var Vec1: Vector3 = Vector3(0.0, 0.0, 0.0)
    var Vec2: Vector3 = Vector3(0.0, 0.0, 0.0)
    var VNorm: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ObsConstrNum: Int = 0
    var Alfa: Float64 = 0.0
    var Beta: Float64 = 0.0
    var HorDis: Float64 = 0.0
    var GroundHitPt: Vector3 = Vector3(0.0, 0.0, 0.0)
    var ACosTanTan: Float64 = 0.0
    var J: Int = 0
    var K: Int = 0
    var NumRecPts: Int = 0
    var VertexWt: Float64 = 0.0
    var unit_z: Vector3 = Vector3(0.0, 0.0, 1.0)
    var zero3: Vector3 = Vector3(0.0, 0.0, 0.0)

    state.dataSolarReflectionManager.TotSolReflRecSurf = 0
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        if getSurface(state, SurfNum).ExtSolar:
            state.dataSolarReflectionManager.TotSolReflRecSurf += 1

    if state.dataSolarReflectionManager.TotSolReflRecSurf == 0:
        ShowWarningError(state, "Calculation of solar reflected from obstructions has been requested but there")
        ShowContinueError(state, "are no building surfaces that can receive reflected solar. Calculation will not be done.")
        state.dataSurface.CalcSolRefl = False
        return

    if state.dataEnvrn.IgnoreSolarRadiation:
        state.dataSolarReflectionManager.TotSolReflRecSurf = 0
        state.dataSurface.CalcSolRefl = False
        return

    // allocate arrays
    state.dataSolarReflectionManager.SolReflRecSurf.allocate(state.dataSolarReflectionManager.TotSolReflRecSurf)
    state.dataSurface.SurfReflFacBmToDiffSolObs.dimension(24, state.dataSurface.TotSurfaces, 0.0)
    state.dataSurface.SurfReflFacBmToDiffSolGnd.dimension(24, state.dataSurface.TotSurfaces, 0.0)
    state.dataSurface.SurfReflFacBmToBmSolObs.dimension(24, state.dataSurface.TotSurfaces, 0.0)
    state.dataSurface.SurfReflFacSkySolObs.dimension(state.dataSurface.TotSurfaces, 0.0)
    state.dataSurface.SurfReflFacSkySolGnd.dimension(state.dataSurface.TotSurfaces, 0.0)
    state.dataSurface.SurfCosIncAveBmToBmSolObs.dimension(24, state.dataSurface.TotSurfaces, 0.0)

    RecSurfNum = 0
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        state.dataSurface.SurfShadowRecSurfNum[SurfNum] = 0
        if getSurface(state, SurfNum).ExtSolar:
            RecSurfNum += 1
            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfNum = SurfNum
            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfName = getSurface(state, SurfNum).Name
            state.dataSurface.SurfShadowRecSurfNum[SurfNum] = RecSurfNum
            for loop in range(1, getSurface(state, SurfNum).Sides + 1):
                if getSurface(state, SurfNum).Vertex[loop].z < state.dataSurface.GroundLevelZ:
                    ShowWarningError(state, EnergyPlus.format("Calculation of reflected solar onto surface={} may be inaccurate", getSurface(state, SurfNum).Name))
                    ShowContinueError(state, "because it has one or more vertices below ground level.")
                    break

    state.dataSurface.MaxRecPts = 1
    for RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts = getSurface(state, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfNum).Sides
        if state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts > state.dataSurface.MaxRecPts:
            state.dataSurface.MaxRecPts = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts

    state.dataSurface.MaxReflRays = AltAngStepsForSolReflCalc * AzimAngStepsForSolReflCalc

    for RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec = Vector3(0.0, 0.0, 0.0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt.dimension(state.dataSurface.MaxRecPts, zero3)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RayVec.dimension(state.dataSurface.MaxReflRays, zero3)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].CosIncAngRay.dimension(state.dataSurface.MaxReflRays, 0.0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].dOmegaRay.dimension(state.dataSurface.MaxReflRays, 0.0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPt.dimension(state.dataSurface.MaxReflRays, state.dataSurface.MaxRecPts, zero3)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSurfNum.dimension(state.dataSurface.MaxReflRays, state.dataSurface.MaxRecPts, 0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSolRefl.dimension(state.dataSurface.MaxReflRays, state.dataSurface.MaxRecPts, 0.0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPtHitPtDis.dimension(state.dataSurface.MaxReflRays, state.dataSurface.MaxRecPts, 0.0)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtNormVec.dimension(state.dataSurface.MaxReflRays, state.dataSurface.MaxRecPts, zero3)
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PossibleObsSurfNums.dimension(state.dataSurface.TotSurfaces, 0)

    for RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        SurfNum = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfNum
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec = getSurface(state, SurfNum).OutNormVec
        RecVec = getSurface(state, SurfNum).Vertex[1]
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs = 0
        for ObsSurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            if ObsSurfNum == SurfNum or ObsSurfNum == getSurface(state, SurfNum).BaseSurf:
                continue
            if getSurface(state, ObsSurfNum).HeatTransSurf and getSurface(state, ObsSurfNum).ExtBoundCond != 0:
                continue

            ObsBehindRec = True
            for loop in range(1, getSurface(state, ObsSurfNum).Sides + 1):
                ObsVec = getSurface(state, ObsSurfNum).Vertex[loop]
                DotProd = dot(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec, ObsVec - RecVec)
                if DotProd > Constant.OneMillionth:
                    ObsBehindRec = False
                    break
            if ObsBehindRec:
                continue

            if getSurface(state, ObsSurfNum).HeatTransSurf:
                ObsHasView = False
                for loopA in range(1, getSurface(state, SurfNum).Sides + 1):
                    for loopB in range(1, getSurface(state, ObsSurfNum).Sides + 1):
                        VecAB = getSurface(state, ObsSurfNum).Vertex[loopB] - getSurface(state, SurfNum).Vertex[loopA]
                        if dot(VecAB, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec) > 0.0 and \
                           dot(VecAB, getSurface(state, ObsSurfNum).OutNormVec) < 0.0:
                            ObsHasView = True
                            break
                    if ObsHasView:
                        break
                if not ObsHasView:
                    continue

            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs += 1
            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PossibleObsSurfNums[state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs] = ObsSurfNum

        NumRecPts = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts
        for J in range(1, NumRecPts + 1):
            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[J] = Vector3(0.0, 0.0, 0.0)
            for K in range(1, NumRecPts + 1):
                if NumRecPts == 3:
                    VertexWt = 0.2
                    if K == J:
                        VertexWt = 0.6
                else:
                    VertexWt = 1.0 / (2.0 * NumRecPts)
                    if K == J:
                        VertexWt = (NumRecPts + 1.0) / (2.0 * NumRecPts)

                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[J].x += \
                    VertexWt * getSurface(state, SurfNum).Vertex[K].x
                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[J].y += \
                    VertexWt * getSurface(state, SurfNum).Vertex[K].y
                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[J].z += \
                    VertexWt * getSurface(state, SurfNum).Vertex[K].z

        PhiSurf = Float64(Math.asin(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec.z))
        let tan_PhiSurf: Float64 = Math.tan(PhiSurf)
        let sin_PhiSurf: Float64 = Math.sin(PhiSurf)
        let cos_PhiSurf: Float64 = Math.cos(PhiSurf)

        if Math.abs(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec.x) > 1.0e-5 or \
           Math.abs(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec.y) > 1.0e-5:
            ThetaSurf = Math.atan2(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec.y,
                                   state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec.x)
        else:
            ThetaSurf = 0.0

        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PhiNormVec = PhiSurf
        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].ThetaNormVec = ThetaSurf

        PhiMin = max(-Constant.PiOvr2, PhiSurf - Constant.PiOvr2)
        PhiMax = min(Constant.PiOvr2, PhiSurf + Constant.PiOvr2)
        DPhi = (PhiMax - PhiMin) / AltAngStepsForSolReflCalc

        RayNum = 0
        for IPhi in range(1, AltAngStepsForSolReflCalc + 1):
            Phi = PhiMin + (IPhi - 0.5) * DPhi
            SPhi = Math.sin(Phi)
            CPhi = Math.cos(Phi)
            URay.z = SPhi
            if PhiSurf >= 0.0:
                if Phi >= Constant.PiOvr2 - PhiSurf:
                    ThetaMin = -Constant.Pi
                    ThetaMax = Constant.Pi
                else:
                    ACosTanTan = Math.acos(-Math.tan(Phi) * tan_PhiSurf)
                    ThetaMin = ThetaSurf - Math.abs(ACosTanTan)
                    ThetaMax = ThetaSurf + Math.abs(ACosTanTan)
            else:
                if Phi <= -PhiSurf - Constant.PiOvr2:
                    ThetaMin = -Constant.Pi
                    ThetaMax = Constant.Pi
                else:
                    ACosTanTan = Math.acos(-Math.tan(Phi) * tan_PhiSurf)
                    ThetaMin = ThetaSurf - Math.abs(ACosTanTan)
                    ThetaMax = ThetaSurf + Math.abs(ACosTanTan)

            DTheta = (ThetaMax - ThetaMin) / AzimAngStepsForSolReflCalc
            dOmega = CPhi * DTheta * DPhi

            for ITheta in range(1, AzimAngStepsForSolReflCalc + 1):
                Theta = ThetaMin + (ITheta - 0.5) * DTheta
                URay.x = CPhi * Math.cos(Theta)
                URay.y = CPhi * Math.sin(Theta)
                CosIncAngRay = SPhi * sin_PhiSurf + CPhi * cos_PhiSurf * Math.cos(Theta - ThetaSurf)
                if CosIncAngRay < 0.0:
                    continue
                RayNum += 1
                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RayVec[RayNum] = URay
                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].CosIncAngRay[RayNum] = CosIncAngRay
                state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].dOmegaRay[RayNum] = dOmega

        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumReflRays = RayNum

    // End of loop over receiving surfaces

    for RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        SurfNum = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfNum
        for RecPtNum in range(1, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts + 1):
            RecPt = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[RecPtNum]
            for RayNum in range(1, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumReflRays + 1):
                TotObstructionsHit = 0
                NearestHitSurfNum = 0
                NearestHitDistance = 1.0e+8
                ObsSurfNumToSkip = 0
                RayVec = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RayVec[RayNum]

                for loop1 in range(1, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs + 1):
                    ObsSurfNum = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PossibleObsSurfNums[loop1]
                    if ObsSurfNum == ObsSurfNumToSkip:
                        continue
                    hit = PierceSurface(state, ObsSurfNum, RecPt, RayVec, HitPt)
                    if hit:
                        if getSurface(state, ObsSurfNum).Class == SurfaceClass.Window:
                            ObsSurfNumToSkip = getSurface(state, ObsSurfNum).BaseSurf
                        if getSurface(state, ObsSurfNum).Class == SurfaceClass.Window and \
                           getSurface(state, ObsSurfNum).BaseSurf == NearestHitSurfNum:
                            NearestHitSurfNum = ObsSurfNum
                        else:
                            TotObstructionsHit += 1
                            HitDistance = distance(HitPt, RecPt)
                            if HitDistance < NearestHitDistance:
                                NearestHitDistance = HitDistance
                                NearestHitSurfNum = ObsSurfNum
                                NearestHitPt = HitPt
                            elif HitDistance == NearestHitDistance:
                                if dot(getSurface(state, ObsSurfNum).OutNormVec, RayVec) <= 0.0:
                                    NearestHitSurfNum = ObsSurfNum

                // End of loop over possible obstructions

                if TotObstructionsHit > 0:
                    state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSurfNum[RayNum, RecPtNum] = NearestHitSurfNum
                    state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPtHitPtDis[RayNum, RecPtNum] = NearestHitDistance
                    state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPt[RayNum, RecPtNum] = NearestHitPt
                    Vec1 = getSurface(state, NearestHitSurfNum).Vertex[1] - getSurface(state, NearestHitSurfNum).Vertex[3]
                    Vec2 = getSurface(state, NearestHitSurfNum).Vertex[2] - getSurface(state, NearestHitSurfNum).Vertex[3]
                    VNorm = cross(Vec1, Vec2)
                    VNorm.normalize()  // Do Handle magnitude==0
                    if dot(VNorm, -RayVec) < 0.0:
                        VNorm = -VNorm
                    state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtNormVec[RayNum, RecPtNum] = VNorm
                    ObsConstrNum = getSurface(state, NearestHitSurfNum).Construction
                    if ObsConstrNum > 0:
                        if not state.dataConstruction.Construct[ObsConstrNum].TypeIsWindow:
                            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSolRefl[RayNum, RecPtNum] = \
                                1.0 - state.dataConstruction.Construct[ObsConstrNum].OutsideAbsorpSolar
                        else:
                            state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSolRefl[RayNum, RecPtNum] = 0.0
                    else:
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSolRefl[RayNum, RecPtNum] = \
                            state.dataSurface.SurfShadowDiffuseSolRefl[NearestHitSurfNum]
                else:
                    state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSurfNum[RayNum, RecPtNum] = 0
                    if RayVec.z < 0.0 and \
                       state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[RecPtNum].z > state.dataSurface.GroundLevelZ:
                        Alfa = Math.acos(-RayVec.z)
                        Beta = Math.atan2(RayVec.y, RayVec.x)
                        HorDis = (RecPt.z - state.dataSurface.GroundLevelZ) * Math.tan(Alfa)
                        GroundHitPt.z = state.dataSurface.GroundLevelZ
                        GroundHitPt.x = RecPt.x + HorDis * Math.cos(Beta)
                        GroundHitPt.y = RecPt.y + HorDis * Math.sin(Beta)
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPt[RayNum, RecPtNum] = GroundHitPt
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSurfNum[RayNum, RecPtNum] = -1
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPtHitPtDis[RayNum, RecPtNum] = \
                            (RecPt.z - state.dataSurface.GroundLevelZ) / (-RayVec.z)
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtSolRefl[RayNum, RecPtNum] = \
                            state.dataEnvrn.GndReflectance
                        state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].HitPtNormVec[RayNum, RecPtNum] = unit_z

// End of InitSolReflRecSurf

def CalcBeamSolDiffuseReflFactors(inout state: EnergyPlusData):
    if not state.dataSysVars.DetailedSolarTimestepIntegration:
        if state.dataGlobal.BeginSimFlag:
            DisplayString(state, "Calculating Beam-to-Diffuse Exterior Solar Reflection Factors")
        else:
            DisplayString(state, "Updating Beam-to-Diffuse Exterior Solar Reflection Factors")
        // Reset arrays
        for ihour in range(1, 25):
            for surf in range(1, state.dataSurface.TotSurfaces + 1):
                state.dataSurface.SurfReflFacBmToDiffSolObs[ihour, surf] = 0.0
                state.dataSurface.SurfReflFacBmToDiffSolGnd[ihour, surf] = 0.0
        for state.dataSolarReflectionManager.IHr = 1; state.dataSolarReflectionManager.IHr <= 24; state.dataSolarReflectionManager.IHr += 1:
            FigureBeamSolDiffuseReflFactors(state, state.dataSolarReflectionManager.IHr)
    else:
        // timestep integrated solar, use current hour of day
        for surf in range(1, state.dataSurface.TotSurfaces + 1):
            state.dataSurface.SurfReflFacBmToDiffSolObs[state.dataGlobal.HourOfDay, surf] = 0.0
            state.dataSurface.SurfReflFacBmToDiffSolGnd[state.dataGlobal.HourOfDay, surf] = 0.0
        FigureBeamSolDiffuseReflFactors(state, state.dataGlobal.HourOfDay)

def FigureBeamSolDiffuseReflFactors(inout state: EnergyPlusData, iHour: Int):
    var ReflBmToDiffSolObs: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var ReflBmToDiffSolGnd: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var hit: Bool = False

    ReflBmToDiffSolObs.dimension(state.dataSurface.MaxRecPts, 0.0)
    ReflBmToDiffSolGnd.dimension(state.dataSurface.MaxRecPts, 0.0)

    state.dataSolarReflectionManager.SunVec = state.dataSurface.SurfSunCosHourly[iHour - 1]  // hour index 0-based in list

    for state.dataSolarReflectionManager.RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        state.dataSolarReflectionManager.SurfNum = \
            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum].SurfNum
        for state.dataSolarReflectionManager.RecPtNum in range(1, \
                state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum].NumRecPts + 1):
            ReflBmToDiffSolObs[state.dataSolarReflectionManager.RecPtNum] = 0.0
            ReflBmToDiffSolGnd[state.dataSolarReflectionManager.RecPtNum] = 0.0
            for state.dataSolarReflectionManager.RayNum in range(1, \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum].NumReflRays + 1):
                state.dataSolarReflectionManager.HitPtSurfNum = \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                        HitPtSurfNum[state.dataSolarReflectionManager.RayNum, state.dataSolarReflectionManager.RecPtNum]
                if state.dataSolarReflectionManager.HitPtSurfNum == 0:
                    continue
                if state.dataSolarReflectionManager.HitPtSurfNum > 0:
                    if state.dataSurface.SurfDaylightingShelfInd[state.dataSolarReflectionManager.HitPtSurfNum] > 0:
                        continue
                    if getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum).Class == SurfaceClass.Window or \
                       getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum).Class == SurfaceClass.GlassDoor:
                        continue
                    state.dataSolarReflectionManager.SunLitFract = \
                        state.dataHeatBal.SurfSunlitFrac[iHour, 1, state.dataSolarReflectionManager.HitPtSurfNum]
                    if state.dataSolarReflectionManager.SunLitFract < 0.01:
                        continue

                state.dataSolarReflectionManager.OriginThisRay = \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                        HitPt[state.dataSolarReflectionManager.RayNum, state.dataSolarReflectionManager.RecPtNum]
                state.dataSolarReflectionManager.CosIncBmAtHitPt = \
                    dot(state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                            HitPtNormVec[state.dataSolarReflectionManager.RayNum, state.dataSolarReflectionManager.RecPtNum],
                        state.dataSolarReflectionManager.SunVec)
                if state.dataSolarReflectionManager.CosIncBmAtHitPt <= 0.0:
                    continue

                if state.dataSolarReflectionManager.HitPtSurfNum > 0:
                    if getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum).IsShadowing:
                        if (state.dataSolarReflectionManager.HitPtSurfNum + 1) < state.dataSurface.TotSurfaces:
                            if getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum + 1).IsShadowing and \
                               getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum + 1).MirroredSurf:
                                state.dataSolarReflectionManager.CosIncBmAtHitPt2 = \
                                    dot(getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum + 1).OutNormVec,
                                        state.dataSolarReflectionManager.SunVec)
                                if state.dataSolarReflectionManager.CosIncBmAtHitPt2 >= 0.0:
                                    continue

                hit = False
                for state.dataSolarReflectionManager.ObsSurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                    if state.dataSolarReflectionManager.HitPtSurfNum > 0:
                        if getSurface(state, state.dataSolarReflectionManager.HitPtSurfNum).MirroredSurf:
                            if state.dataSolarReflectionManager.ObsSurfNum == state.dataSolarReflectionManager.HitPtSurfNum - 1:
                                continue
                    if state.dataSolarReflectionManager.ObsSurfNum == state.dataSolarReflectionManager.HitPtSurfNum:
                        continue
                    if getSurface(state, state.dataSolarReflectionManager.ObsSurfNum).MirroredSurf:
                        continue
                    if getSurface(state, state.dataSolarReflectionManager.ObsSurfNum).ExtBoundCond >= 1:
                        continue
                    hit = PierceSurface(state,
                                        state.dataSolarReflectionManager.ObsSurfNum,
                                        state.dataSolarReflectionManager.OriginThisRay,
                                        state.dataSolarReflectionManager.SunVec,
                                        state.dataSolarReflectionManager.ObsHitPt)
                    if hit:
                        break

                if hit:
                    continue

                state.dataSolarReflectionManager.BmReflSolRadiance = \
                    state.dataSolarReflectionManager.CosIncBmAtHitPt * \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                        HitPtSolRefl[state.dataSolarReflectionManager.RayNum, state.dataSolarReflectionManager.RecPtNum]

                if state.dataSolarReflectionManager.BmReflSolRadiance > 0.0:
                    if state.dataSolarReflectionManager.HitPtSurfNum > 0:
                        state.dataSolarReflectionManager.dReflBeamToDiffSol = \
                            state.dataSolarReflectionManager.BmReflSolRadiance * \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                                dOmegaRay[state.dataSolarReflectionManager.RayNum] * \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                                CosIncAngRay[state.dataSolarReflectionManager.RayNum] / Constant.Pi
                        ReflBmToDiffSolObs[state.dataSolarReflectionManager.RecPtNum] += state.dataSolarReflectionManager.dReflBeamToDiffSol
                    else:
                        state.dataSolarReflectionManager.dReflBeamToDiffSol = \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                                dOmegaRay[state.dataSolarReflectionManager.RayNum] * \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum]. \
                                CosIncAngRay[state.dataSolarReflectionManager.RayNum] / Constant.Pi
                        ReflBmToDiffSolGnd[state.dataSolarReflectionManager.RecPtNum] += state.dataSolarReflectionManager.dReflBeamToDiffSol

            // End of loop over rays from receiving point

        state.dataSurface.SurfReflFacBmToDiffSolObs[iHour, state.dataSolarReflectionManager.SurfNum] = 0.0
        state.dataSurface.SurfReflFacBmToDiffSolGnd[iHour, state.dataSolarReflectionManager.SurfNum] = 0.0
        state.dataSolarReflectionManager.NumRecPts = \
            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.RecSurfNum].NumRecPts
        for state.dataSolarReflectionManager.RecPtNum in range(1, state.dataSolarReflectionManager.NumRecPts + 1):
            state.dataSurface.SurfReflFacBmToDiffSolObs[iHour, state.dataSolarReflectionManager.SurfNum] += \
                ReflBmToDiffSolObs[state.dataSolarReflectionManager.RecPtNum]
            state.dataSurface.SurfReflFacBmToDiffSolGnd[iHour, state.dataSolarReflectionManager.SurfNum] += \
                ReflBmToDiffSolGnd[state.dataSolarReflectionManager.RecPtNum]

        state.dataSurface.SurfReflFacBmToDiffSolObs[iHour, state.dataSolarReflectionManager.SurfNum] /= \
            state.dataSolarReflectionManager.NumRecPts
        state.dataSurface.SurfReflFacBmToDiffSolGnd[iHour, state.dataSolarReflectionManager.SurfNum] /= \
            state.dataSolarReflectionManager.NumRecPts
        state.dataSurface.SurfReflFacBmToDiffSolGnd[iHour, state.dataSolarReflectionManager.SurfNum] = \
            min(0.5 * (1.0 - getSurface(state, state.dataSolarReflectionManager.SurfNum).CosTilt),
                state.dataSurface.SurfReflFacBmToDiffSolGnd[iHour, state.dataSolarReflectionManager.SurfNum])

def CalcBeamSolSpecularReflFactors(inout state: EnergyPlusData):
    if not state.dataSysVars.DetailedSolarTimestepIntegration:
        if state.dataGlobal.BeginSimFlag:
            DisplayString(state, "Calculating Beam-to-Beam Exterior Solar Reflection Factors")
        else:
            DisplayString(state, "Updating Beam-to-Beam Exterior Solar Reflection Factors")
        for ihour in range(1, 25):
            for surf in range(1, state.dataSurface.TotSurfaces + 1):
                state.dataSurface.SurfReflFacBmToBmSolObs[ihour, surf] = 0.0
                state.dataSurface.SurfCosIncAveBmToBmSolObs[ihour, surf] = 0.0
        for state.dataSolarReflectionManager.NumHr in range(1, 25):
            FigureBeamSolSpecularReflFactors(state, state.dataSolarReflectionManager.NumHr)
    else:
        for surf in range(1, state.dataSurface.TotSurfaces + 1):
            state.dataSurface.SurfReflFacBmToBmSolObs[state.dataGlobal.HourOfDay, surf] = 0.0
            state.dataSurface.SurfCosIncAveBmToBmSolObs[state.dataGlobal.HourOfDay, surf] = 0.0
        FigureBeamSolSpecularReflFactors(state, state.dataGlobal.HourOfDay)

def FigureBeamSolSpecularReflFactors(inout state: EnergyPlusData, iHour: Int):
    var ReflBmToDiffSolObs: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var hitRefl: Bool = False
    var hitObs: Bool = False
    var hitObsRefl: Bool = False
    var ReflBmToBmSolObs: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var ReflDistanceSq: Float64 = 0.0
    var ReflDistance: Float64 = 0.0
    var ReflFacTimesCosIncSum: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)

    ReflBmToDiffSolObs.dimension(state.dataSurface.MaxRecPts, 0.0)
    ReflFacTimesCosIncSum.dimension(state.dataSurface.MaxRecPts, 0.0)

    if state.dataSurface.SurfSunCosHourly[iHour - 1].z < SunIsUpValue:
        return

    state.dataSolarReflectionManager.SunVect = state.dataSurface.SurfSunCosHourly[iHour - 1]

    for RecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        let SurfNum: Int = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].SurfNum
        if state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs > 0:
            ReflBmToBmSolObs.dimension(state.dataSurface.MaxRecPts, 0.0)
            ReflFacTimesCosIncSum.dimension(state.dataSurface.MaxRecPts, 0.0)
            let NumRecPts: Int = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumRecPts
            for loop in range(1, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs + 1):
                let ReflSurfNum: Int = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PossibleObsSurfNums[loop]
                if ((getSurface(state, ReflSurfNum).Class == SurfaceClass.Window and getSurface(state, ReflSurfNum).ExtSolar) or \
                    (state.dataSurface.SurfShadowGlazingFrac[ReflSurfNum] > 0.0 and getSurface(state, ReflSurfNum).IsShadowing)):
                    if getSurface(state, ReflSurfNum).Class == SurfaceClass.Window and \
                       state.dataHeatBal.SurfSunlitFrac[iHour, 1, ReflSurfNum] < 0.01:
                        continue
                    state.dataSolarReflectionManager.ReflNorm = getSurface(state, ReflSurfNum).OutNormVec
                    state.dataSolarReflectionManager.CosIncAngRefl = dot(state.dataSolarReflectionManager.SunVect, state.dataSolarReflectionManager.ReflNorm)
                    if state.dataSolarReflectionManager.CosIncAngRefl < 0.0:
                        continue
                    state.dataSolarReflectionManager.SunVecMir = \
                        state.dataSolarReflectionManager.SunVect - \
                        2.0 * dot(state.dataSolarReflectionManager.SunVect, state.dataSolarReflectionManager.ReflNorm) * \
                        state.dataSolarReflectionManager.ReflNorm
                    state.dataSolarReflectionManager.CosIncAngRec = \
                        dot(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec, state.dataSolarReflectionManager.SunVecMir)
                    if state.dataSolarReflectionManager.CosIncAngRec <= 0.0:
                        continue
                    for RecPtNum in range(1, NumRecPts + 1):
                        state.dataSolarReflectionManager.RecPt = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].RecPt[RecPtNum]
                        hitRefl = PierceSurface(state,
                                                ReflSurfNum,
                                                state.dataSolarReflectionManager.RecPt,
                                                state.dataSolarReflectionManager.SunVecMir,
                                                state.dataSolarReflectionManager.HitPtRefl)
                        if hitRefl:
                            ReflDistanceSq = distance_squared(state.dataSolarReflectionManager.HitPtRefl, state.dataSolarReflectionManager.RecPt)
                            ReflDistance = Math.sqrt(ReflDistanceSq)
                            hitObsRefl = False
                            for loop2 in range(1, state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NumPossibleObs + 1):
                                let ObsSurfNum: Int = state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].PossibleObsSurfNums[loop2]
                                if ObsSurfNum == ReflSurfNum or ObsSurfNum == getSurface(state, ReflSurfNum).BaseSurf:
                                    continue
                                hitObs = PierceSurface(state,
                                                       ObsSurfNum,
                                                       state.dataSolarReflectionManager.RecPt,
                                                       state.dataSolarReflectionManager.SunVecMir,
                                                       ReflDistance,
                                                       state.dataSolarReflectionManager.HitPtObs)
                                if hitObs:
                                    if distance_squared(state.dataSolarReflectionManager.HitPtObs, state.dataSolarReflectionManager.RecPt) < ReflDistanceSq:
                                        hitObsRefl = True
                                        break
                            if hitObsRefl:
                                continue
                            hitObs = False
                            if getSurface(state, ReflSurfNum).Class == SurfaceClass.Window:
                                let ReflSurfRecNum: Int = state.dataSurface.SurfShadowRecSurfNum[ReflSurfNum]
                                if ReflSurfRecNum > 0:
                                    for loop2 in range(1, state.dataSolarReflectionManager.SolReflRecSurf[ReflSurfRecNum].NumPossibleObs + 1):
                                        let ObsSurfNum: Int = state.dataSolarReflectionManager.SolReflRecSurf[ReflSurfRecNum].PossibleObsSurfNums[loop2]
                                        hitObs = PierceSurface(state,
                                                               ObsSurfNum,
                                                               state.dataSolarReflectionManager.HitPtRefl,
                                                               state.dataSolarReflectionManager.SunVect,
                                                               state.dataSolarReflectionManager.HitPtObs)
                                        if hitObs:
                                            break
                            else:
                                for ObsSurfNum in state.dataSurface.AllShadowPossObstrSurfaceList:
                                    if ObsSurfNum == ReflSurfNum:
                                        continue
                                    if getSurface(state, ObsSurfNum).MirroredSurf:
                                        continue
                                    if getSurface(state, ReflSurfNum).MirroredSurf:
                                        if ObsSurfNum == ReflSurfNum - 1:
                                            continue
                                    hitObs = PierceSurface(state,
                                                           ObsSurfNum,
                                                           state.dataSolarReflectionManager.HitPtRefl,
                                                           state.dataSolarReflectionManager.SunVect,
                                                           state.dataSolarReflectionManager.HitPtObs)
                                    if hitObs:
                                        break
                            if hitObs:
                                continue
                            state.dataSolarReflectionManager.SpecReflectance = 0.0
                            if getSurface(state, ReflSurfNum).Class == SurfaceClass.Window:
                                state.dataSolarReflectionManager.ConstrNumRefl = getSurface(state, ReflSurfNum).Construction
                                state.dataSolarReflectionManager.SpecReflectance = \
                                    POLYF(Math.abs(state.dataSolarReflectionManager.CosIncAngRefl),
                                          state.dataConstruction.Construct[state.dataSolarReflectionManager.ConstrNumRefl].ReflSolBeamFrontCoef)
                            if getSurface(state, ReflSurfNum).IsShadowing and \
                               state.dataSurface.SurfShadowGlazingConstruct[ReflSurfNum] > 0:
                                state.dataSolarReflectionManager.ConstrNumRefl = state.dataSurface.SurfShadowGlazingConstruct[ReflSurfNum]
                                state.dataSolarReflectionManager.SpecReflectance = \
                                    state.dataSurface.SurfShadowGlazingFrac[ReflSurfNum] * \
                                    POLYF(Math.abs(state.dataSolarReflectionManager.CosIncAngRefl),
                                          state.dataConstruction.Construct[state.dataSolarReflectionManager.ConstrNumRefl].ReflSolBeamFrontCoef)
                            state.dataSolarReflectionManager.CosIncAngRec = \
                                dot(state.dataSolarReflectionManager.SolReflRecSurf[RecSurfNum].NormVec,
                                    state.dataSolarReflectionManager.SunVecMir)
                            state.dataSolarReflectionManager.ReflFac = \
                                state.dataSolarReflectionManager.SpecReflectance * state.dataSolarReflectionManager.CosIncAngRec
                            ReflBmToBmSolObs[RecPtNum] += state.dataSolarReflectionManager.ReflFac
                            ReflFacTimesCosIncSum[RecPtNum] += \
                                state.dataSolarReflectionManager.ReflFac * state.dataSolarReflectionManager.CosIncAngRec
                        // End of check if reflecting surface was hit
                    // End of loop over receiving points
                // End of check if valid reflecting surface
            // End of loop over obstructing surfaces
            for RecPtNum in range(1, NumRecPts + 1):
                if ReflBmToBmSolObs[RecPtNum] != 0.0:
                    state.dataSolarReflectionManager.CosIncWeighted = ReflFacTimesCosIncSum[RecPtNum] / ReflBmToBmSolObs[RecPtNum]
                else:
                    state.dataSolarReflectionManager.CosIncWeighted = 0.0
                state.dataSurface.SurfCosIncAveBmToBmSolObs[iHour, SurfNum] += state.dataSolarReflectionManager.CosIncWeighted
                state.dataSurface.SurfReflFacBmToBmSolObs[iHour, SurfNum] += ReflBmToBmSolObs[RecPtNum]

            state.dataSurface.SurfReflFacBmToBmSolObs[iHour, SurfNum] /= Float64(NumRecPts)
            state.dataSurface.SurfCosIncAveBmToBmSolObs[iHour, SurfNum] /= Float64(NumRecPts)
        // End of check if number of possible obstructions > 0
    // End of loop over receiving surfaces

def CalcSkySolDiffuseReflFactors(inout state: EnergyPlusData):
    var ReflSkySolObs: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var ReflSkySolGnd: Array1D_Float64 = Array1D_Float64(state.dataSurface.MaxRecPts, 0.0)
    var hitObs: Bool = False
    let DPhi: Float64 = Constant.PiOvr2 / (AltAngStepsForSolReflCalc / 2.0)
    let DTheta: Float64 = 2.0 * Constant.Pi / Float64(2 * AzimAngStepsForSolReflCalc)

    var sin_Phi: List[Float64] = List[Float64]()
    sin_Phi.append(-1.0)
    var cos_Phi: List[Float64] = List[Float64]()
    cos_Phi.append(-1.0)
    for IPhi in range(1, (AltAngStepsForSolReflCalc // 2) + 1):
        let Phi: Float64 = (Float64(IPhi) - 0.5) * DPhi
        sin_Phi.append(Math.sin(Phi))
        cos_Phi.append(Math.cos(Phi))

    var sin_Theta: List[Float64] = List[Float64]()
    sin_Theta.append(-1.0)
    var cos_Theta: List[Float64] = List[Float64]()
    cos_Theta.append(-1.0)
    for ITheta in range(1, 2 * AzimAngStepsForSolReflCalc + 1):
        let Theta: Float64 = (Float64(ITheta) - 0.5) * DTheta
        sin_Theta.append(Math.sin(Theta))
        cos_Theta.append(Math.cos(Theta))

    DisplayString(state, "Calculating Sky Diffuse Exterior Solar Reflection Factors")

    for state.dataSolarReflectionManager.iRecSurfNum in range(1, state.dataSolarReflectionManager.TotSolReflRecSurf + 1):
        state.dataSolarReflectionManager.iSurfNum = \
            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum].SurfNum
        for state.dataSolarReflectionManager.iRecPtNum in range(1, \
                state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum].NumRecPts + 1):
            ReflSkySolObs[state.dataSolarReflectionManager.iRecPtNum] = 0.0
            ReflSkySolGnd[state.dataSolarReflectionManager.iRecPtNum] = 0.0
            for state.dataSolarReflectionManager.iRayNum in range(1, \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum].NumReflRays + 1):
                state.dataSolarReflectionManager.HitPntSurfNum = \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                        HitPtSurfNum[state.dataSolarReflectionManager.iRayNum, state.dataSolarReflectionManager.iRecPtNum]
                if state.dataSolarReflectionManager.HitPntSurfNum == 0:
                    continue
                state.dataSolarReflectionManager.HitPntRefl = \
                    state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                        HitPt[state.dataSolarReflectionManager.iRayNum, state.dataSolarReflectionManager.iRecPtNum]
                if state.dataSolarReflectionManager.HitPntSurfNum > 0:
                    if state.dataSurface.SurfDaylightingShelfInd[state.dataSolarReflectionManager.HitPntSurfNum] > 0:
                        continue
                    state.dataSolarReflectionManager.HitPtSurfNumX = state.dataSolarReflectionManager.HitPntSurfNum
                    if getSurface(state, state.dataSolarReflectionManager.HitPntSurfNum).IsShadowing:
                        if dot(state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                                RayVec[state.dataSolarReflectionManager.iRayNum],
                               getSurface(state, state.dataSolarReflectionManager.HitPntSurfNum).OutNormVec) > 0.0:
                            if (state.dataSolarReflectionManager.HitPntSurfNum + 1) < state.dataSurface.TotSurfaces:
                                state.dataSolarReflectionManager.HitPtSurfNumX = state.dataSolarReflectionManager.HitPntSurfNum + 1
                            if state.dataSurface.SurfDaylightingShelfInd[state.dataSolarReflectionManager.HitPtSurfNumX] > 0:
                                continue
                    if not state.dataSysVars.DetailedSkyDiffuseAlgorithm or not state.dataSurface.ShadingTransmittanceVaries or \
                       state.dataHeatBal.SolarDistribution == HD_SolarDistribution.Minimal:
                        state.dataSolarReflectionManager.SkyReflSolRadiance = \
                            getSurface(state, state.dataSolarReflectionManager.HitPtSurfNumX).ViewFactorSky * \
                            state.dataSolarShading.SurfDifShdgRatioIsoSky[state.dataSolarReflectionManager.HitPtSurfNumX] * \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                                HitPtSolRefl[state.dataSolarReflectionManager.iRayNum, state.dataSolarReflectionManager.iRecPtNum]
                    else:
                        state.dataSolarReflectionManager.SkyReflSolRadiance = \
                            getSurface(state, state.dataSolarReflectionManager.HitPtSurfNumX).ViewFactorSky * \
                            state.dataSolarShading.SurfDifShdgRatioIsoSkyHRTS[1, 1, state.dataSolarReflectionManager.HitPtSurfNumX] * \
                            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                                HitPtSolRefl[state.dataSolarReflectionManager.iRayNum, state.dataSolarReflectionManager.iRecPtNum]
                    state.dataSolarReflectionManager.dReflSkySol = \
                        state.dataSolarReflectionManager.SkyReflSolRadiance * \
                        state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                            dOmegaRay[state.dataSolarReflectionManager.iRayNum] * \
                        state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                            CosIncAngRay[state.dataSolarReflectionManager.iRayNum] / Constant.Pi
                    ReflSkySolObs[state.dataSolarReflectionManager.iRecPtNum] += state.dataSolarReflectionManager.dReflSkySol
                else:
                    var dReflSkyGnd: Float64 = 0.0
                    for IPhi in range(1, (AltAngStepsForSolReflCalc // 2) + 1):
                        state.dataSolarReflectionManager.URay.z = sin_Phi[IPhi]
                        let dOmega: Float64 = cos_Phi[IPhi] * DTheta * DPhi
                        let CosIncAngRayToSky: Float64 = sin_Phi[IPhi]
                        for ITheta in range(1, 2 * AzimAngStepsForSolReflCalc + 1):
                            state.dataSolarReflectionManager.URay.x = cos_Phi[IPhi] * cos_Theta[ITheta]
                            state.dataSolarReflectionManager.URay.y = cos_Phi[IPhi] * sin_Theta[ITheta]
                            hitObs = False
                            for ObsSurfNum in state.dataSurface.AllShadowPossObstrSurfaceList:
                                state.dataSolarReflectionManager.iObsSurfNum = ObsSurfNum
                                if getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).Tilt < 5.0:
                                    continue
                                if not getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).IsShadowing:
                                    if dot(state.dataSolarReflectionManager.URay,
                                           getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).OutNormVec) >= 0.0:
                                        continue
                                    if getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).Tilt > 89.0 and \
                                       getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).Tilt < 91.0:
                                        state.dataSolarReflectionManager.SurfVert = \
                                            getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).Vertex[2]
                                        state.dataSolarReflectionManager.SurfVertToGndPt = \
                                            state.dataSolarReflectionManager.HitPntRefl - state.dataSolarReflectionManager.SurfVert
                                        if dot(state.dataSolarReflectionManager.SurfVertToGndPt,
                                               getSurface(state, state.dataSolarReflectionManager.iObsSurfNum).OutNormVec) < 0.0:
                                            continue
                                hitObs = PierceSurface(state,
                                                       state.dataSolarReflectionManager.iObsSurfNum,
                                                       state.dataSolarReflectionManager.HitPntRefl,
                                                       state.dataSolarReflectionManager.URay,
                                                       state.dataSolarReflectionManager.HitPntObs)
                                if hitObs:
                                    break
                            if hitObs:
                                continue
                            dReflSkyGnd += CosIncAngRayToSky * dOmega / Constant.Pi
                    // End of azimuth loop
                    // End of altitude loop
                    ReflSkySolGnd[state.dataSolarReflectionManager.iRecPtNum] += \
                        dReflSkyGnd * \
                        state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                            dOmegaRay[state.dataSolarReflectionManager.iRayNum] * \
                        state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum]. \
                            CosIncAngRay[state.dataSolarReflectionManager.iRayNum] / Constant.Pi
                // End of check if ray from receiving point hits obstruction or ground
            // End of loop over rays from receiving point
        // End of loop over receiving points

        state.dataSurface.SurfReflFacSkySolObs[state.dataSolarReflectionManager.iSurfNum] = 0.0
        state.dataSurface.SurfReflFacSkySolGnd[state.dataSolarReflectionManager.iSurfNum] = 0.0
        state.dataSolarReflectionManager.iNumRecPts = \
            state.dataSolarReflectionManager.SolReflRecSurf[state.dataSolarReflectionManager.iRecSurfNum].NumRecPts
        for state.dataSolarReflectionManager.iRecPtNum in range(1, state.dataSolarReflectionManager.iNumRecPts + 1):
            state.dataSurface.SurfReflFacSkySolObs[state.dataSolarReflectionManager.iSurfNum] += \
                ReflSkySolObs[state.dataSolarReflectionManager.iRecPtNum]
            state.dataSurface.SurfReflFacSkySolGnd[state.dataSolarReflectionManager.iSurfNum] += \
                ReflSkySolGnd[state.dataSolarReflectionManager.iRecPtNum]

        state.dataSurface.SurfReflFacSkySolObs[state.dataSolarReflectionManager.iSurfNum] /= state.dataSolarReflectionManager.iNumRecPts
        state.dataSurface.SurfReflFacSkySolGnd[state.dataSolarReflectionManager.iSurfNum] /= state.dataSolarReflectionManager.iNumRecPts
        state.dataSurface.SurfReflFacSkySolGnd[state.dataSolarReflectionManager.iSurfNum] = \
            min(0.5 * (1.0 - getSurface(state, state.dataSolarReflectionManager.iSurfNum).CosTilt),
                state.dataSurface.SurfReflFacSkySolGnd[state.dataSolarReflectionManager.iSurfNum])
    // End of loop over receiving surfaces

// End of SolarReflectionManager namespace

// -----------------------------------------------------------------------------
// End of file