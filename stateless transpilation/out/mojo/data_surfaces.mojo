# data_surfaces.mojo
# EnergyPlus Data Surfaces module - faithful Mojo port

from collections import Dict, List
from memory import Arc
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter with nested data containers
# - Vector, Vector2D, Vector3, Vector4: vector types
# - BSDFWindowDescript: BSDF window descriptor
# - HcInt, HcExt enums
# - Schedule, Material, ShapeCat types

@value
struct Compass4:
    alias Invalid = -1
    alias North = 0
    alias East = 1
    alias South = 2
    alias West = 3
    alias Num = 4

var compass4Names = ("North", "East", "South", "West")
var Compass4AzimuthLo = (315.0, 45.0, 135.0, 225.0)
var Compass4AzimuthHi = (45.0, 135.0, 225.0, 315.0)

@value
struct Compass8:
    alias Invalid = -1
    alias North = 0
    alias NorthEast = 1
    alias East = 2
    alias SouthEast = 3
    alias South = 4
    alias SouthWest = 5
    alias West = 6
    alias NorthWest = 7
    alias Num = 8

var compass8Names = ("North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest")
var Compass8AzimuthLo = (337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5)
var Compass8AzimuthHi = (22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5)

@value
struct SurfaceShape:
    alias Invalid = -1
    alias None_ = 0
    alias Triangle = 1
    alias Quadrilateral = 2
    alias Rectangle = 3
    alias RectangularDoorWindow = 4
    alias RectangularOverhang = 5
    alias RectangularLeftFin = 6
    alias RectangularRightFin = 7
    alias TriangularWindow = 8
    alias TriangularDoor = 9
    alias Polygonal = 10
    alias Num = 11

@value
struct SurfaceClass:
    alias Invalid = -1
    alias None_ = 0
    alias Wall = 1
    alias Floor = 2
    alias Roof = 3
    alias IntMass = 4
    alias Detached_B = 5
    alias Detached_F = 6
    alias Window = 7
    alias GlassDoor = 8
    alias Door = 9
    alias Shading = 10
    alias Overhang = 11
    alias Fin = 12
    alias TDD_Dome = 13
    alias TDD_Diffuser = 14
    alias Num = 15

@value
struct FWC:
    alias Invalid = -1
    alias Floor = 0
    alias Wall = 1
    alias Ceiling = 2
    alias Num = 3

var iFWC_Floor = 0
var iFWC_Wall = 1
var iFWC_Ceiling = 2

@value
struct SurfaceFilter:
    alias Invalid = -1
    alias AllExteriorSurfaces = 0
    alias AllExteriorWindows = 1
    alias AllExteriorWalls = 2
    alias AllExteriorRoofs = 3
    alias AllExteriorFloors = 4
    alias AllInteriorSurfaces = 5
    alias AllInteriorWindows = 6
    alias AllInteriorWalls = 7
    alias AllInteriorRoofs = 8
    alias AllInteriorCeilings = 9
    alias AllInteriorFloors = 10
    alias Num = 11

var SurfaceFilterNamesUC = (
    "ALLEXTERIORSURFACES", "ALLEXTERIORWINDOWS", "ALLEXTERIORWALLS", "ALLEXTERIORROOFS",
    "ALLEXTERIORFLOORS", "ALLINTERIORSURFACES", "ALLINTERIORWINDOWS", "ALLINTERIORWALLS",
    "ALLINTERIORROOFS", "ALLINTERIORCEILINGS", "ALLINTERIORFLOORS"
)

@value
struct WinCover:
    alias Invalid = -1
    alias Bare = 0
    alias Shaded = 1
    alias Num = 2

var iWinCover_Bare = 0
var iWinCover_Shaded = 1

@value
struct WinShadingType:
    alias Invalid = -1
    alias NoShade = 0
    alias ShadeOff = 1
    alias IntShade = 2
    alias SwitchableGlazing = 3
    alias ExtShade = 4
    alias ExtScreen = 5
    alias IntBlind = 6
    alias ExtBlind = 7
    alias BGShade = 8
    alias BGBlind = 9
    alias IntShadeConditionallyOff = 10
    alias GlassConditionallyLightened = 11
    alias ExtShadeConditionallyOff = 12
    alias IntBlindConditionallyOff = 13
    alias ExtBlindConditionallyOff = 14
    alias BGShadeConditionallyOff = 15
    alias BGBlindConditionallyOff = 16
    alias Num = 17

@value
struct WindowShadingControlType:
    alias Invalid = -1
    alias AlwaysOn = 0
    alias AlwaysOff = 1
    alias OnIfScheduled = 2
    alias HiSolar = 3
    alias HiHorzSolar = 4
    alias HiOutAirTemp = 5
    alias HiZoneAirTemp = 6
    alias HiZoneCooling = 7
    alias HiGlare = 8
    alias MeetDaylIlumSetp = 9
    alias OnNightLoOutTemp_OffDay = 10
    alias OnNightLoInTemp_OffDay = 11
    alias OnNightIfHeating_OffDay = 12
    alias OnNightLoOutTemp_OnDayCooling = 13
    alias OnNightIfHeating_OnDayCooling = 14
    alias OffNight_OnDay_HiSolarWindow = 15
    alias OnNight_OnDay_HiSolarWindow = 16
    alias OnHiOutTemp_HiSolarWindow = 17
    alias OnHiOutTemp_HiHorzSolar = 18
    alias OnHiZoneTemp_HiSolarWindow = 19
    alias OnHiZoneTemp_HiHorzSolar = 20
    alias HiSolar_HiLumin_OffMidNight = 21
    alias HiSolar_HiLumin_OffSunset = 22
    alias HiSolar_HiLumin_OffNextMorning = 23
    alias Num = 24

@value
struct RefAirTemp:
    alias Invalid = -1
    alias ZoneMeanAirTemp = 0
    alias AdjacentAirTemp = 1
    alias ZoneSupplyAirTemp = 2
    alias Num = 3

var SurfTAirRefReportVals = (1, 2, 3)

var ExternalEnvironment = 0
var Ground = -1
var OtherSideCoefNoCalcExt = -2
var OtherSideCoefCalcExt = -3
var OtherSideCondModeledExt = -4
var GroundFCfactorMethod = -5
var KivaFoundation = -6

var UpperLeftCorner = 1
var LowerLeftCorner = 2
var LowerRightCorner = 3
var UpperRightCorner = 4

var AltAngStepsForSolReflCalc = 10
var AzimAngStepsForSolReflCalc = 9

@value
struct HeatTransferModel:
    alias Invalid = -1
    alias None_ = 0
    alias CTF = 1
    alias EMPD = 2
    alias CondFD = 3
    alias HAMT = 4
    alias Window5 = 5
    alias ComplexFenestration = 6
    alias TDD = 7
    alias Kiva = 8
    alias AirBoundaryNoHT = 9
    alias Num = 10

var HeatTransAlgoStrs = (
    "None",
    "CTF - ConductionTransferFunction",
    "EMPD - MoisturePenetrationDepthConductionTransferFunction",
    "CondFD - ConductionFiniteDifference",
    "HAMT - CombinedHeatAndMoistureFiniteElement",
    "Window5 Detailed Fenestration",
    "Window7 Complex Fenestration",
    "Tubular Daylighting Device",
    "KivaFoundation - TwoDimensionalFiniteDifference",
    "Air Boundary - No Heat Transfer"
)

@value
struct Lum:
    alias Invalid = -1
    alias Illum = 0
    alias Back = 1
    alias Source = 2
    alias Num = 3

var iLum_Illum = 0
var iLum_Back = 1
var iLum_Source = 2

@always_inline
fn NOT_SHADED(ShadingFlag: Int) -> Bool:
    return ShadingFlag == WinShadingType.NoShade or ShadingFlag == WinShadingType.ShadeOff

@always_inline
fn IS_SHADED(ShadingFlag: Int) -> Bool:
    return not NOT_SHADED(ShadingFlag)

@always_inline
fn IS_SHADED_NO_GLARE_CTRL(ShadingFlag: Int) -> Bool:
    return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.SwitchableGlazing or
            ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.ExtScreen or
            ShadingFlag == WinShadingType.IntBlind or ShadingFlag == WinShadingType.ExtBlind or
            ShadingFlag == WinShadingType.BGShade or ShadingFlag == WinShadingType.BGBlind)

@always_inline
fn ANY_SHADE(ShadingFlag: Int) -> Bool:
    return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.ExtShade or
            ShadingFlag == WinShadingType.BGShade)

@always_inline
fn ANY_SHADE_SCREEN(ShadingFlag: Int) -> Bool:
    return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.ExtShade or
            ShadingFlag == WinShadingType.BGShade or ShadingFlag == WinShadingType.ExtScreen)

@always_inline
fn ANY_BLIND(ShadingFlag: Int) -> Bool:
    return (ShadingFlag == WinShadingType.IntBlind or ShadingFlag == WinShadingType.ExtBlind or
            ShadingFlag == WinShadingType.BGBlind)

@always_inline
fn ANY_INTERIOR_SHADE_BLIND(ShadingFlag: Int) -> Bool:
    return ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.IntBlind

@always_inline
fn ANY_EXTERIOR_SHADE_BLIND_SCREEN(ShadingFlag: Int) -> Bool:
    return (ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.ExtBlind or
            ShadingFlag == WinShadingType.ExtScreen)

@always_inline
fn ANY_BETWEENGLASS_SHADE_BLIND(ShadingFlag: Int) -> Bool:
    return ShadingFlag == WinShadingType.BGShade or ShadingFlag == WinShadingType.BGBlind

@value
struct SlatAngleControl:
    alias Invalid = -1
    alias Fixed = 0
    alias Scheduled = 1
    alias BlockBeamSolar = 2
    alias Num = 3

@value
struct WindowAirFlowSource:
    alias Invalid = -1
    alias Indoor = 0
    alias Outdoor = 1
    alias Num = 2

@value
struct WindowAirFlowDestination:
    alias Invalid = -1
    alias Indoor = 0
    alias Outdoor = 1
    alias Return = 2
    alias Num = 3

@value
struct WindowAirFlowControlType:
    alias Invalid = -1
    alias MaxFlow = 0
    alias AlwaysOff = 1
    alias Schedule = 2
    alias Num = 3

@value
struct WindowModel:
    alias Invalid = -1
    alias Detailed = 0
    alias BSDF = 1
    alias EQL = 2
    alias Num = 3

@value
struct NfrcProductOptions:
    alias Invalid = -1
    alias CasementDouble = 0
    alias CasementSingle = 1
    alias DualAction = 2
    alias Fixed = 3
    alias Garage = 4
    alias Greenhouse = 5
    alias HingedEscape = 6
    alias HorizontalSlider = 7
    alias Jal = 8
    alias Pivoted = 9
    alias ProjectingSingle = 10
    alias ProjectingDual = 11
    alias DoorSidelite = 12
    alias Skylight = 13
    alias SlidingPatioDoor = 14
    alias CurtainWall = 15
    alias SpandrelPanel = 16
    alias SideHingedDoor = 17
    alias DoorTransom = 18
    alias TropicalAwning = 19
    alias TubularDaylightingDevice = 20
    alias VerticalSlider = 21
    alias Num = 22

@value
struct NfrcVisionType:
    alias Invalid = -1
    alias Single = 0
    alias DualVertical = 1
    alias DualHorizontal = 2
    alias Num = 3

@value
struct FrameDividerType:
    alias Invalid = -1
    alias DividedLite = 0
    alias Suspended = 1
    alias Num = 2

@value
struct MultiSurfaceControl:
    alias Invalid = -1
    alias Sequential = 0
    alias Group = 1
    alias Num = 2

var nVerticesBig = 20

var cExtBoundCondition = ("KivaFoundation", "FCGround", "OSCM", "OSC", "OSC", "Ground", "ExternalEnvironment")

@value
struct Surface2DSlab:
    var yl: Float64
    var yu: Float64
    var xl: Float64
    var xu: Float64
    var edges: List[Int]
    var edgesXY: List[Float64]

@value
struct Surface2D:
    var axis: Int
    var vertices: List[Tuple[Float64, Float64]]
    var vl: Tuple[Float64, Float64]
    var vu: Tuple[Float64, Float64]
    var edges: List[Tuple[Float64, Float64]]
    var s1: Float64
    var s3: Float64
    var slabYs: List[Float64]
    var slabs: List[Surface2DSlab]
    
    fn bb_contains(self, v: Tuple[Float64, Float64]) -> Bool:
        return (self.vl[0] <= v[0]) and (v[0] <= self.vu[0]) and (self.vl[1] <= v[1]) and (v[1] <= self.vu[1])

@value
struct SurfaceCalcHashKey:
    var Construction: Int
    var Azimuth: Float64
    var Tilt: Float64
    var Height: Float64
    var Zone: Int
    var EnclIndex: Int
    var TAirRef: Int
    var ExtZone: Int
    var ExtCond: Int
    var ExtEnclIndex: Int
    var ExtSolar: Bool
    var ExtWind: Bool
    var ViewFactorGround: Float64
    var ViewFactorSky: Float64
    var ViewFactorSrdSurfs: Float64
    var HeatTransferAlgorithm: Int
    var intConvModel: Int
    var intConvUserModelNum: Int
    var extConvModel: Int
    var extConvUserModelNum: Int
    var OSCPtr: Int
    var OSCMPtr: Int
    var FrameDivider: Int
    var SurfWinStormWinConstr: Int
    var MaterialMovInsulExt: Int
    var MaterialMovInsulInt: Int
    var movInsulExtSchedNum: Int
    var movInsulIntSchedNum: Int
    var externalShadingSchedNum: Int
    var SurroundingSurfacesNum: Int
    var LinkedOutAirNode: Int
    var outsideHeatSourceTermSchedNum: Int
    var insideHeatSourceTermSchedNum: Int
    
    fn hash_combine(self, current_hash: Int, new_hash: Int) -> Int:
        return current_hash ^ new_hash + 0x9e3779b9 + (current_hash << 6) + (current_hash >> 2)
    
    fn get_hash(self) -> Int:
        var combined = 0
        combined = self.hash_combine(combined, hash(self.Construction))
        combined = self.hash_combine(combined, hash(self.Azimuth))
        combined = self.hash_combine(combined, hash(self.Tilt))
        combined = self.hash_combine(combined, hash(self.Height))
        combined = self.hash_combine(combined, hash(self.Zone))
        combined = self.hash_combine(combined, hash(self.EnclIndex))
        combined = self.hash_combine(combined, hash(self.TAirRef))
        combined = self.hash_combine(combined, hash(self.ExtZone))
        combined = self.hash_combine(combined, hash(self.ExtCond))
        combined = self.hash_combine(combined, hash(self.ExtEnclIndex))
        combined = self.hash_combine(combined, hash(self.ExtSolar))
        combined = self.hash_combine(combined, hash(self.ExtWind))
        combined = self.hash_combine(combined, hash(self.ViewFactorGround))
        combined = self.hash_combine(combined, hash(self.ViewFactorSky))
        combined = self.hash_combine(combined, hash(self.HeatTransferAlgorithm))
        combined = self.hash_combine(combined, hash(self.intConvModel))
        combined = self.hash_combine(combined, hash(self.extConvModel))
        combined = self.hash_combine(combined, hash(self.intConvUserModelNum))
        combined = self.hash_combine(combined, hash(self.extConvUserModelNum))
        combined = self.hash_combine(combined, hash(self.OSCPtr))
        combined = self.hash_combine(combined, hash(self.OSCMPtr))
        combined = self.hash_combine(combined, hash(self.FrameDivider))
        combined = self.hash_combine(combined, hash(self.SurfWinStormWinConstr))
        combined = self.hash_combine(combined, hash(self.MaterialMovInsulExt))
        combined = self.hash_combine(combined, hash(self.MaterialMovInsulInt))
        combined = self.hash_combine(combined, hash(self.movInsulExtSchedNum))
        combined = self.hash_combine(combined, hash(self.movInsulIntSchedNum))
        combined = self.hash_combine(combined, hash(self.externalShadingSchedNum))
        combined = self.hash_combine(combined, hash(self.SurroundingSurfacesNum))
        combined = self.hash_combine(combined, hash(self.LinkedOutAirNode))
        combined = self.hash_combine(combined, hash(self.outsideHeatSourceTermSchedNum))
        combined = self.hash_combine(combined, hash(self.insideHeatSourceTermSchedNum))
        return combined

@value
struct SurfaceWindowRefPt:
    var solidAng: Float64
    var solidAngWtd: Float64
    var lums: InlineArray[InlineArray[Float64, 2], 3]
    var illumFromWinRep: Float64
    var lumWinRep: Float64

@value
struct SurfaceWindowCalc:
    var refPts: List[SurfaceWindowRefPt]
    var WinCenter: Tuple[Float64, Float64, Float64]
    var theta: Float64
    var phi: Float64
    var rhoCeilingWall: Float64
    var rhoFloorWall: Float64
    var fractionUpgoing: Float64
    var glazedFrac: Float64
    var centerGlassArea: Float64
    var edgeGlassCorrFac: Float64
    var screenNum: Int
    var lightWellEff: Float64
    var thetaFace: InlineArray[Float64, 11]
    var OutProjSLFracMult: InlineArray[Float64, 25]
    var InOutProjSLFracMult: InlineArray[Float64, 25]
    var EnclAreaMinusThisSurf: InlineArray[Float64, 3]
    var EnclAreaReflProdMinusThisSurf: InlineArray[Float64, 3]
    var ComplexFen: Int
    var hasShade: Bool
    var hasBlind: Bool
    var hasScreen: Bool

@value
struct BlindProperties:
    var matNum: Int
    var movableSlats: Bool
    var slatAng: Float64
    var slatAngDeg: Float64
    var slatAngDegEMSon: Bool
    var slatAngDegEMSValue: Float64
    var slatBlockBeam: Bool
    var slatAngIdxLo: Int
    var slatAngIdxHi: Int
    var slatAngInterpFac: Float64
    var profAng: Float64
    var profAngIdxLo: Int
    var profAngIdxHi: Int
    var profAngInterpFac: Float64
    var bmBmTrans: Float64
    var airFlowPermeability: Float64
    var TAR: Int

@value
struct GlassProperties:
    var epsIR: Float64
    var rhoIR: Float64

@value
struct SurfaceShade:
    var blind: BlindProperties
    var glass: GlassProperties
    var effShadeEmi: Float64
    var effGlassEmi: Float64

@value
struct SurfaceWindowFrameDiv:
    pass

@value
struct FrameDividerProperties:
    var Name: String
    var FrameWidth: Float64
    var FrameProjectionOut: Float64
    var FrameProjectionIn: Float64
    var FrameConductance: Float64
    var FrameEdgeWidth: Float64
    var FrEdgeToCenterGlCondRatio: Float64
    var FrameSolAbsorp: Float64
    var FrameVisAbsorp: Float64
    var FrameEmis: Float64
    var DividerType: Int
    var DividerWidth: Float64
    var HorDividers: Int
    var VertDividers: Int
    var DividerProjectionOut: Float64
    var DividerProjectionIn: Float64
    var DividerEdgeWidth: Float64
    var DividerConductance: Float64
    var DivEdgeToCenterGlCondRatio: Float64
    var DividerSolAbsorp: Float64
    var DividerVisAbsorp: Float64
    var DividerEmis: Float64
    var MullionOrientation: Int
    var NfrcProductType: Int
    var OutsideRevealSolAbs: Float64
    var InsideSillDepth: Float64
    var InsideReveal: Float64
    var InsideSillSolAbs: Float64
    var InsideRevealSolAbs: Float64

@value
struct StormWindowData:
    var BaseWindowNum: Int
    var StormWinMaterialNum: Int
    var StormWinDistance: Float64
    var DateOn: Int
    var MonthOn: Int
    var DayOfMonthOn: Int
    var DateOff: Int
    var MonthOff: Int
    var DayOfMonthOff: Int

@value
struct WindowShadingControlData:
    var Name: String
    var ZoneIndex: Int
    var SequenceNumber: Int
    var ShadingType: Int
    var getInputShadedConstruction: Int
    var ShadingDevice: Int
    var shadingControlType: Int
    var sched: Int
    var SetPoint: Float64
    var SetPoint2: Float64
    var ShadingControlIsScheduled: Bool
    var GlareControlIsActive: Bool
    var slatAngleSched: Int
    var slatAngleControl: Int
    var DaylightingControlName: String
    var DaylightControlIndex: Int
    var multiSurfaceControl: Int
    var FenestrationCount: Int
    var FenestrationName: List[String]
    var FenestrationIndex: List[Int]

@value
struct OSCData:
    var Name: String
    var ConstTemp: Float64
    var ConstTempCoef: Float64
    var ExtDryBulbCoef: Float64
    var GroundTempCoef: Float64
    var SurfFilmCoef: Float64
    var WindSpeedCoef: Float64
    var ZoneAirTempCoef: Float64
    var ConstTempScheduleName: String
    var constTempSched: Int
    var SinusoidalConstTempCoef: Bool
    var SinusoidPeriod: Float64
    var TPreviousCoef: Float64
    var TOutsideSurfPast: Float64
    var MinTempLimit: Float64
    var MaxTempLimit: Float64
    var MinLimitPresent: Bool
    var MaxLimitPresent: Bool
    var OSCTempCalc: Float64

@value
struct OSCMData:
    var Name: String
    var Class: String
    var TConv: Float64
    var EMSOverrideOnTConv: Bool
    var EMSOverrideTConvValue: Float64
    var HConv: Float64
    var EMSOverrideOnHConv: Bool
    var EMSOverrideHConvValue: Float64
    var TRad: Float64
    var EMSOverrideOnTRad: Bool
    var EMSOverrideTRadValue: Float64
    var HRad: Float64
    var EMSOverrideOnHrad: Bool
    var EMSOverrideHradValue: Float64

@value
struct ConvectionCoefficient:
    var WhichSurface: Int
    var SurfaceName: String
    var overrideType: Int
    var OverrideValue: Float64
    var sched: Int
    var UserCurveIndex: Int
    var HcIntModelEq: Int
    var HcExtModelEq: Int

@value
struct ShadingVertexData:
    var NVert: Int
    var XV: List[Float64]
    var YV: List[Float64]
    var ZV: List[Float64]

@value
struct SurfaceSolarIncident:
    var Name: String
    var SurfPtr: Int
    var ConstrPtr: Int
    var sched: Int

@value
struct SurfaceIncidentSolarMultiplier:
    var Name: String
    var SurfaceIdx: Int
    var Scaler: Float64
    var sched: Int

@value
struct FenestrationSolarAbsorbed:
    var Name: String
    var SurfPtr: Int
    var ConstrPtr: Int
    var NumOfSched: Int
    var scheds: List[Int]

@value
struct GroundSurfacesData:
    var Name: String
    var ViewFactor: Float64
    var tempSched: Int
    var reflSched: Int

@value
struct GroundSurfacesProperty:
    var Name: String
    var NumGndSurfs: Int
    var GndSurfs: List[GroundSurfacesData]
    var SurfsTempAvg: Float64
    var SurfsReflAvg: Float64
    var SurfsViewFactorSum: Float64
    var IsGroundViewFactorSet: Bool

@value
struct SurfaceLocalEnvironment:
    var Name: String
    var SurfPtr: Int
    var sunlitFracSched: Int
    var SurroundingSurfsPtr: Int
    var OutdoorAirNodePtr: Int
    var GroundSurfsPtr: Int

@value
struct SurroundingSurfProperty:
    var Name: String
    var ViewFactor: Float64
    var tempSched: Int

@value
struct SurroundingSurfacesProperty:
    var Name: String
    var SkyViewFactor: Float64
    var GroundViewFactor: Float64
    var SurfsViewFactorSum: Float64
    var skyTempSched: Int
    var groundTempSched: Int
    var TotSurroundingSurface: Int
    var IsSkyViewFactorSet: Bool
    var IsGroundViewFactorSet: Bool
    var SurroundingSurfs: List[SurroundingSurfProperty]

@value
struct IntMassObject:
    var Name: String
    var ZoneOrZoneListName: String
    var ZoneOrZoneListPtr: Int
    var NumOfZones: Int
    var Construction: Int
    var GrossArea: Float64
    var ZoneListActive: Bool
    var spaceOrSpaceListName: String
    var spaceOrSpaceListPtr: Int
    var numOfSpaces: Int
    var spaceListActive: Bool

@value
struct SurfIntConv:
    var convClass: Int
    var convClassRpt: Int
    var model: Int
    var userModelNum: Int
    var hcModelEq: Int
    var hcModelEqRpt: Int
    var hcUserCurveNum: Int
    var zoneWallHeight: Float64
    var zonePerimLength: Float64
    var zoneHorizHydrDiam: Float64
    var windowWallRatio: Float64
    var windowLocation: Int
    var getsRadiantHeat: Bool
    var hasActiveInIt: Bool

@value
struct SurfExtConv:
    var convClass: Int
    var convClassRpt: Int
    var model: Int
    var userModelNum: Int
    var hfModelEq: Int
    var hfModelEqRpt: Int
    var hfUserCurveNum: Int
    var hnModelEq: Int
    var hnModelEqRpt: Int
    var hnUserCurveNum: Int
    var faceArea: Float64
    var facePerimeter: Float64
    var faceHeight: Float64

@value
struct MovInsul:
    var present: Bool
    var presentPrevTS: Bool
    var H: Float64
    var matNum: Int
    var sched: Int

@value
struct SurfaceData:
    var Name: String
    var Construction: Int
    var RepresentativeCalcSurfNum: Int
    var ConstituentSurfaceNums: List[Int]
    var ConstructionStoredInputValue: Int
    var Class: Int
    var OriginalClass: Int
    var Shape: Int
    var Sides: Int
    var Area: Float64
    var GrossArea: Float64
    var NetAreaShadowCalc: Float64
    var Perimeter: Float64
    var Azimuth: Float64
    var Height: Float64
    var Reveal: Float64
    var Tilt: Float64
    var Width: Float64
    var shapeCat: Int
    var plane: Tuple[Float64, Float64, Float64, Float64]
    var surface2d: Surface2D
    var NewVertex: List[Tuple[Float64, Float64, Float64]]
    var Vertex: List[Tuple[Float64, Float64, Float64]]
    var Centroid: Tuple[Float64, Float64, Float64]
    var lcsx: Tuple[Float64, Float64, Float64]
    var lcsy: Tuple[Float64, Float64, Float64]
    var lcsz: Tuple[Float64, Float64, Float64]
    var NewellAreaVector: Tuple[Float64, Float64, Float64]
    var NewellSurfaceNormalVector: Tuple[Float64, Float64, Float64]
    var OutNormVec: Tuple[Float64, Float64, Float64]
    var SinAzim: Float64
    var CosAzim: Float64
    var SinTilt: Float64
    var CosTilt: Float64
    var IsConvex: Bool
    var IsDegenerate: Bool
    var VerticesProcessed: Bool
    var XShift: Float64
    var YShift: Float64
    var HeatTransSurf: Bool
    var outsideHeatSourceTermSched: Int
    var insideHeatSourceTermSched: Int
    var HeatTransferAlgorithm: Int
    var BaseSurfName: String
    var BaseSurf: Int
    var NumSubSurfaces: Int
    var ZoneName: String
    var Zone: Int
    var spaceNum: Int
    var ExtBoundCondName: String
    var ExtBoundCond: Int
    var ExtSolar: Bool
    var ExtWind: Bool
    var hasIncSolMultiplier: Bool
    var IncSolMultiplier: Float64
    var ViewFactorGround: Float64
    var ViewFactorSky: Float64
    var ViewFactorGroundIR: Float64
    var ViewFactorSkyIR: Float64
    var OSCPtr: Int
    var OSCMPtr: Int
    var MirroredSurf: Bool
    var IsShadowing: Bool
    var IsShadowPossibleObstruction: Bool
    var shadowSurfSched: Int
    var IsTransparent: Bool
    var SchedMinValue: Float64
    var activeWindowShadingControl: Int
    var windowShadingControlList: List[Int]
    var HasShadeControl: Bool
    var activeShadedConstruction: Int
    var activeShadedConstructionPrev: Int
    var shadedConstructionList: List[Int]
    var shadedStormWinConstructionList: List[Int]
    var FrameDivider: Int
    var Multiplier: Float64
    var RadEnclIndex: Int
    var SolarEnclIndex: Int
    var SolarEnclSurfIndex: Int
    var IsAirBoundarySurf: Bool
    var convOrientation: Int
    var calcHashKey: SurfaceCalcHashKey
    var IsSurfPropertyGndSurfacesDefined: Bool
    var SurfPropertyGndSurfIndex: Int
    var UseSurfPropertyGndSurfTemp: Bool
    var UseSurfPropertyGndSurfRefl: Bool
    var GndReflSolarRad: Float64
    var SurfHasSurroundingSurfProperty: Bool
    var SurfSchedExternalShadingFrac: Bool
    var SurfSurroundingSurfacesNum: Int
    var surfExternalShadingSched: Int
    var SurfLinkedOutAirNode: Int
    var AE: Float64
    var enclAESum: Float64
    var SrdSurfTemp: Float64
    var ViewFactorSrdSurfs: Float64

@value
struct SurfacesData:
    var TotSurfaces: Int
    var TotWindows: Int
    var TotStormWin: Int
    var TotWinShadingControl: Int
    var TotUserIntConvModels: Int
    var TotUserExtConvModels: Int
    var TotOSC: Int
    var TotOSCM: Int
    var TotExtVentCav: Int
    var TotSurfIncSolSSG: Int
    var TotSurfIncSolMultiplier: Int
    var TotFenLayAbsSSG: Int
    var TotSurfLocalEnv: Int
    var TotSurfPropGndSurfs: Int
    var Corner: Int
    var MaxVerticesPerSurface: Int
    var BuildingShadingCount: Int
    var FixedShadingCount: Int
    var AttachedShadingCount: Int
    var ShadingSurfaceFirst: Int
    var ShadingSurfaceLast: Int
    var AspectTransform: Bool
    var CalcSolRefl: Bool
    var CCW: Bool
    var WorldCoordSystem: Bool
    var DaylRefWorldCoordSystem: Bool
    var MaxRecPts: Int
    var MaxReflRays: Int
    var GroundLevelZ: Float64
    var AirflowWindows: Bool
    var ShadingTransmittanceVaries: Bool
    var UseRepresentativeSurfaceCalculations: Bool
    var AnyMovableInsulation: Bool
    var AnyMovableSlat: Bool
    var SurfAdjacentZone: List[Int]
    var X0: List[Float64]
    var Y0: List[Float64]
    var Z0: List[Float64]
    var RepresentativeSurfaceMap: Dict[SurfaceCalcHashKey, Int]
    var AllHTSurfaceList: List[Int]
    var AllExtSolarSurfaceList: List[Int]
    var AllExtSolAndShadingSurfaceList: List[Int]
    var AllShadowPossObstrSurfaceList: List[Int]
    var AllIZSurfaceList: List[Int]
    var AllHTNonWindowSurfaceList: List[Int]
    var AllHTWindowSurfaceList: List[Int]
    var AllExtSolWindowSurfaceList: List[Int]
    var AllExtSolWinWithFrameSurfaceList: List[Int]
    var AllHTKivaSurfaceList: List[Int]
    var AllSurfaceListReportOrder: List[Int]
    var AllVaryAbsOpaqSurfaceList: List[Int]
    var allInsideSourceSurfaceList: List[Int]
    var allOutsideSourceSurfaceList: List[Int]
    var allGetsRadiantHeatSurfaceList: List[Int]
    var intMovInsulSurfNums: List[Int]
    var extMovInsulSurfNums: List[Int]
    var SurfaceFilterLists: InlineArray[List[Int], 11]
    var SurfOutDryBulbTemp: List[Float64]
    var SurfOutWetBulbTemp: List[Float64]
    var SurfOutWindSpeed: List[Float64]
    var SurfOutWindDir: List[Float64]
    var SurfGenericContam: List[Float64]
    var SurfLowTempErrCount: List[Int]
    var SurfHighTempErrCount: List[Int]
    var SurfAirSkyRadSplit: List[Float64]
    var SurfSunCosHourly: List[Tuple[Float64, Float64, Float64]]
    var SurfSunlitArea: List[Float64]
    var SurfSunlitFrac: List[Float64]
    var SurfSkySolarInc: List[Float64]
    var SurfGndSolarInc: List[Float64]
    var SurfBmToBmReflFacObs: List[Float64]
    var SurfBmToDiffReflFacObs: List[Float64]
    var SurfBmToDiffReflFacGnd: List[Float64]
    var SurfSkyDiffReflFacGnd: List[Float64]
    var SurfOpaqAI: List[Float64]
    var SurfOpaqAO: List[Float64]
    var SurfPenumbraID: List[Int]
    var SurfReflFacBmToDiffSolObs: List[List[Float64]]
    var SurfReflFacBmToDiffSolGnd: List[List[Float64]]
    var SurfReflFacBmToBmSolObs: List[List[Float64]]
    var SurfReflFacSkySolObs: List[Float64]
    var SurfReflFacSkySolGnd: List[Float64]
    var SurfCosIncAveBmToBmSolObs: List[List[Float64]]
    var SurfShadowDiffuseSolRefl: List[Float64]
    var SurfShadowDiffuseVisRefl: List[Float64]
    var SurfShadowGlazingFrac: List[Float64]
    var SurfShadowGlazingConstruct: List[Int]
    var SurfShadowRecSurfNum: List[Int]
    var SurfShadowDisabledZoneList: List[List[Int]]
    var SurfEMSConstructionOverrideON: List[Bool]
    var SurfEMSConstructionOverrideValue: List[Int]
    var SurfEMSOverrideIntConvCoef: List[Bool]
    var SurfEMSValueForIntConvCoef: List[Float64]
    var SurfEMSOverrideExtConvCoef: List[Bool]
    var SurfEMSValueForExtConvCoef: List[Float64]
    var SurfOutDryBulbTempEMSOverrideOn: List[Bool]
    var SurfOutDryBulbTempEMSOverrideValue: List[Float64]
    var SurfOutWetBulbTempEMSOverrideOn: List[Bool]
    var SurfOutWetBulbTempEMSOverrideValue: List[Float64]
    var SurfWindSpeedEMSOverrideOn: List[Bool]
    var SurfWindSpeedEMSOverrideValue: List[Float64]
    var SurfViewFactorGroundEMSOverrideOn: List[Bool]
    var SurfViewFactorGroundEMSOverrideValue: List[Float64]
    var SurfWindDirEMSOverrideOn: List[Bool]
    var SurfWindDirEMSOverrideValue: List[Float64]
    var SurfDaylightingShelfInd: List[Int]
    var SurfExtEcoRoof: List[Bool]
    var SurfExtCavityPresent: List[Bool]
    var SurfExtCavNum: List[Int]
    var SurfIsPV: List[Bool]
    var SurfIsICS: List[Bool]
    var SurfIsPool: List[Bool]
    var SurfICSPtr: List[Int]
    var SurfIsRadSurfOrVentSlabOrPool: List[Bool]
    var SurfTAirRef: List[Int]
    var SurfTAirRefRpt: List[Int]
    var surfIntConv: List[SurfIntConv]
    var surfExtConv: List[SurfExtConv]
    var SurfWinInsideGlassCondensationFlag: List[Int]
    var SurfWinInsideFrameCondensationFlag: List[Int]
    var SurfWinInsideDividerCondensationFlag: List[Int]
    var SurfWinA: List[List[Float64]]
    var SurfWinADiffFront: List[List[Float64]]
    var SurfWinACFOverlap: List[List[Float64]]
    var SurfWinTransSolar: List[Float64]
    var SurfWinBmSolar: List[Float64]
    var SurfWinBmBmSolar: List[Float64]
    var SurfWinBmDifSolar: List[Float64]
    var SurfWinDifSolar: List[Float64]
    var SurfWinHeatGain: List[Float64]
    var SurfWinHeatGainRep: List[Float64]
    var SurfWinHeatLossRep: List[Float64]
    var SurfWinGainConvGlazToZoneRep: List[Float64]
    var SurfWinGainIRGlazToZoneRep: List[Float64]
    var SurfWinLossSWZoneToOutWinRep: List[Float64]
    var SurfWinGainFrameDividerToZoneRep: List[Float64]
    var SurfWinGainConvShadeToZoneRep: List[Float64]
    var SurfWinGainIRShadeToZoneRep: List[Float64]
    var SurfWinGapConvHtFlowRep: List[Float64]
    var SurfWinShadingAbsorbedSolar: List[Float64]
    var SurfWinSysSolTransmittance: List[Float64]
    var SurfWinSysSolReflectance: List[Float64]
    var SurfWinSysSolAbsorptance: List[Float64]
    var SurfWinTransSolarEnergy: List[Float64]
    var SurfWinBmSolarEnergy: List[Float64]
    var SurfWinBmBmSolarEnergy: List[Float64]
    var SurfWinBmDifSolarEnergy: List[Float64]
    var SurfWinDifSolarEnergy: List[Float64]
    var SurfWinHeatGainRepEnergy: List[Float64]
    var SurfWinHeatLossRepEnergy: List[Float64]
    var SurfWinShadingAbsorbedSolarEnergy: List[Float64]
    var SurfWinGapConvHtFlowRepEnergy: List[Float64]
    var SurfWinHeatTransferRepEnergy: List[Float64]
    var SurfWinIRfromParentZone: List[Float64]
    var SurfWinFrameQRadOutAbs: List[Float64]
    var SurfWinFrameQRadInAbs: List[Float64]
    var SurfWinDividerQRadOutAbs: List[Float64]
    var SurfWinDividerQRadInAbs: List[Float64]
    var SurfWinExtBeamAbsByShade: List[Float64]
    var SurfWinExtDiffAbsByShade: List[Float64]
    var SurfWinIntBeamAbsByShade: List[Float64]
    var SurfWinIntSWAbsByShade: List[Float64]
    var SurfWinInitialDifSolAbsByShade: List[Float64]
    var SurfWinIntLWAbsByShade: List[Float64]
    var SurfWinConvHeatFlowNatural: List[Float64]
    var SurfWinConvHeatGainToZoneAir: List[Float64]
    var SurfWinRetHeatGainToZoneAir: List[Float64]
    var SurfWinDividerHeatGain: List[Float64]
    var SurfWinBlTsolBmBm: List[Float64]
    var SurfWinBlTsolBmDif: List[Float64]
    var SurfWinBlTsolDifDif: List[Float64]
    var SurfWinBlGlSysTsolBmBm: List[Float64]
    var SurfWinBlGlSysTsolDifDif: List[Float64]
    var SurfWinScTsolBmBm: List[Float64]
    var SurfWinScTsolBmDif: List[Float64]
    var SurfWinScTsolDifDif: List[Float64]
    var SurfWinScGlSysTsolBmBm: List[Float64]
    var SurfWinScGlSysTsolDifDif: List[Float64]
    var SurfWinGlTsolBmBm: List[Float64]
    var SurfWinGlTsolBmDif: List[Float64]
    var SurfWinGlTsolDifDif: List[Float64]
    var SurfWinBmSolTransThruIntWinRep: List[Float64]
    var SurfWinBmSolAbsdOutsReveal: List[Float64]
    var SurfWinBmSolRefldOutsRevealReport: List[Float64]
    var SurfWinBmSolAbsdInsReveal: List[Float64]
    var SurfWinBmSolRefldInsReveal: List[Float64]
    var SurfWinBmSolRefldInsRevealReport: List[Float64]
    var SurfWinOutsRevealDiffOntoGlazing: List[Float64]
    var SurfWinInsRevealDiffOntoGlazing: List[Float64]
    var SurfWinInsRevealDiffIntoZone: List[Float64]
    var SurfWinOutsRevealDiffOntoFrame: List[Float64]
    var SurfWinInsRevealDiffOntoFrame: List[Float64]
    var SurfWinInsRevealDiffOntoGlazingReport: List[Float64]
    var SurfWinInsRevealDiffIntoZoneReport: List[Float64]
    var SurfWinInsRevealDiffOntoFrameReport: List[Float64]
    var SurfWinBmSolAbsdInsRevealReport: List[Float64]
    var SurfWinBmSolTransThruIntWinRepEnergy: List[Float64]
    var SurfWinBmSolRefldOutsRevealRepEnergy: List[Float64]
    var SurfWinBmSolRefldInsRevealRepEnergy: List[Float64]
    var SurfWinProfileAngHor: List[Float64]
    var SurfWinProfileAngVert: List[Float64]
    var SurfWinShadingFlag: List[Int]
    var SurfWinShadingFlagEMSOn: List[Bool]
    var SurfWinShadingFlagEMSValue: List[Int]
    var SurfWinStormWinFlag: List[Int]
    var SurfWinStormWinFlagPrevDay: List[Int]
    var SurfWinFracTimeShadingDeviceOn: List[Float64]
    var SurfWinExtIntShadePrevTS: List[Int]
    var SurfWinHasShadeOrBlindLayer: List[Bool]
    var SurfWinSurfDayLightInit: List[Bool]
    var SurfWinDaylFacPoint: List[Int]
    var SurfWinVisTransSelected: List[Float64]
    var SurfWinSwitchingFactor: List[Float64]
    var SurfWinVisTransRatio: List[Float64]
    var SurfWinFrameArea: List[Float64]
    var SurfWinFrameConductance: List[Float64]
    var SurfWinFrameSolAbsorp: List[Float64]
    var SurfWinFrameVisAbsorp: List[Float64]
    var SurfWinFrameEmis: List[Float64]
    var SurfWinFrEdgeToCenterGlCondRatio: List[Float64]
    var SurfWinFrameEdgeArea: List[Float64]
    var SurfWinFrameTempIn: List[Float64]
    var SurfWinFrameTempInOld: List[Float64]
    var SurfWinFrameTempSurfOut: List[Float64]
    var SurfWinProjCorrFrOut: List[Float64]
    var SurfWinProjCorrFrIn: List[Float64]
    var SurfWinDividerType: List[Int]
    var SurfWinDividerArea: List[Float64]
    var SurfWinDividerConductance: List[Float64]
    var SurfWinDividerSolAbsorp: List[Float64]
    var SurfWinDividerVisAbsorp: List[Float64]
    var SurfWinDividerEmis: List[Float64]
    var SurfWinDivEdgeToCenterGlCondRatio: List[Float64]
    var SurfWinDividerEdgeArea: List[Float64]
    var SurfWinDividerTempIn: List[Float64]
    var SurfWinDividerTempInOld: List[Float64]
    var SurfWinDividerTempSurfOut: List[Float64]
    var SurfWinProjCorrDivOut: List[Float64]
    var SurfWinProjCorrDivIn: List[Float64]
    var SurfWinShadeAbsFacFace1: List[Float64]
    var SurfWinShadeAbsFacFace2: List[Float64]
    var SurfWinConvCoeffWithShade: List[Float64]
    var SurfWinOtherConvHeatGain: List[Float64]
    var SurfWinEffInsSurfTemp: List[Float64]
    var SurfWinTotGlazingThickness: List[Float64]
    var SurfWinTanProfileAngHor: List[Float64]
    var SurfWinTanProfileAngVert: List[Float64]
    var SurfWinInsideSillDepth: List[Float64]
    var SurfWinInsideReveal: List[Float64]
    var SurfWinInsideSillSolAbs: List[Float64]
    var SurfWinInsideRevealSolAbs: List[Float64]
    var SurfWinOutsideRevealSolAbs: List[Float64]
    var SurfWinAirflowSource: List[Int]
    var SurfWinAirflowDestination: List[Int]
    var SurfWinAirflowReturnNodePtr: List[Int]
    var SurfWinMaxAirflow: List[Float64]
    var SurfWinAirflowControlType: List[Int]
    var SurfWinAirflowHasSchedule: List[Bool]
    var SurfWinAirflowScheds: List[Int]
    var SurfWinAirflowThisTS: List[Float64]
    var SurfWinTAirflowGapOutlet: List[Float64]
    var SurfWinWindowCalcIterationsRep: List[Int]
    var SurfWinVentingOpenFactorMultRep: List[Float64]
    var SurfWinInsideTempForVentingRep: List[Float64]
    var SurfWinVentingAvailabilityRep: List[Float64]
    var SurfWinSkyGndSolarInc: List[Float64]
    var SurfWinBmGndSolarInc: List[Float64]
    var SurfWinSolarDiffusing: List[Bool]
    var SurfWinFrameHeatGain: List[Float64]
    var SurfWinFrameHeatLoss: List[Float64]
    var SurfWinDividerHeatLoss: List[Float64]
    var SurfWinTCLayerTemp: List[Float64]
    var SurfWinSpecTemp: List[Float64]
    var SurfWinWindowModelType: List[Int]
    var SurfWinTDDPipeNum: List[Float64]
    var SurfWinStormWinConstr: List[Int]
    var SurfActiveConstruction: List[Int]
    var SurfWinActiveShadedConstruction: List[Int]
    var intMovInsuls: List[MovInsul]
    var extMovInsuls: List[MovInsul]
    var Surface: List[SurfaceData]
    var SurfaceWindow: List[SurfaceWindowCalc]
    var surfShades: List[SurfaceShade]
    var FrameDivider: List[FrameDividerProperties]
    var StormWindow: List[StormWindowData]
    var WindowShadingControl: List[WindowShadingControlData]
    var OSC: List[OSCData]
    var OSCM: List[OSCMData]
    var userIntConvModels: List[ConvectionCoefficient]
    var userExtConvModels: List[ConvectionCoefficient]
    var ShadeV: List[ShadingVertexData]
    var SurfIncSolSSG: List[SurfaceSolarIncident]
    var SurfIncSolMultiplier: List[SurfaceIncidentSolarMultiplier]
    var FenLayAbsSSG: List[FenestrationSolarAbsorbed]
    var SurfLocalEnvironment: List[SurfaceLocalEnvironment]
    var SurroundingSurfsProperty: List[SurroundingSurfacesProperty]
    var IntMassObjects: List[IntMassObject]
    var GroundSurfsProperty: List[GroundSurfacesProperty]

fn azimuth_to_compass4(azimuth: Float64) -> Int:
    debug_assert(0.0 <= azimuth and azimuth < 360.0)
    for c4 in range(int(Compass4.Num)):
        var lo = Compass4AzimuthLo[c4]
        var hi = Compass4AzimuthHi[c4]
        if lo > hi:
            if azimuth >= lo or azimuth < hi:
                return c4
        else:
            if azimuth >= lo and azimuth < hi:
                return c4
    debug_assert(False)
    return int(Compass4.Invalid)

fn azimuth_to_compass8(azimuth: Float64) -> Int:
    debug_assert(0.0 <= azimuth and azimuth < 360.0)
    for c8 in range(int(Compass8.Num)):
        var lo = Compass8AzimuthLo[c8]
        var hi = Compass8AzimuthHi[c8]
        if lo > hi:
            if azimuth >= lo or azimuth < hi:
                return c8
        else:
            if azimuth >= lo and azimuth < hi:
                return c8
    debug_assert(False)
    return int(Compass8.Invalid)

fn c_surface_class(ClassNo: Int) -> String:
    if ClassNo == int(SurfaceClass.Wall):
        return "Wall"
    elif ClassNo == int(SurfaceClass.Floor):
        return "Floor"
    elif ClassNo == int(SurfaceClass.Roof):
        return "Roof"
    elif ClassNo == int(SurfaceClass.Window):
        return "Window"
    elif ClassNo == int(SurfaceClass.GlassDoor):
        return "Glass Door"
    elif ClassNo == int(SurfaceClass.Door):
        return "Door"
    elif ClassNo == int(SurfaceClass.TDD_Dome):
        return "TubularDaylightDome"
    elif ClassNo == int(SurfaceClass.TDD_Diffuser):
        return "TubularDaylightDiffuser"
    elif ClassNo == int(SurfaceClass.IntMass):
        return "Internal Mass"
    elif ClassNo == int(SurfaceClass.Shading):
        return "Shading"
    elif ClassNo == int(SurfaceClass.Detached_B):
        return "Detached Shading:Building"
    elif ClassNo == int(SurfaceClass.Detached_F):
        return "Detached Shading:Fixed"
    else:
        return "Invalid/Unknown"

fn abs_front_side(state: AnyType, SurfNum: Int) -> Float64:
    var AbsorptanceFromExteriorFrontSide = (
        (state.dataSurface.SurfWinExtBeamAbsByShade[SurfNum] + state.dataSurface.SurfWinExtDiffAbsByShade[SurfNum]) *
        state.dataSurface.SurfWinShadeAbsFacFace1[SurfNum]
    )
    var AbsorptanceFromInteriorFrontSide = (
        (state.dataSurface.SurfWinIntBeamAbsByShade[SurfNum] + state.dataSurface.SurfWinIntSWAbsByShade[SurfNum]) *
        state.dataSurface.SurfWinShadeAbsFacFace2[SurfNum]
    )
    return AbsorptanceFromExteriorFrontSide + AbsorptanceFromInteriorFrontSide

fn abs_back_side(state: AnyType, SurfNum: Int) -> Float64:
    var AbsorptanceFromInteriorBackSide = (
        (state.dataSurface.SurfWinIntBeamAbsByShade[SurfNum] + state.dataSurface.SurfWinIntSWAbsByShade[SurfNum]) *
        state.dataSurface.SurfWinShadeAbsFacFace1[SurfNum]
    )
    var AbsorptanceFromExteriorBackSide = (
        (state.dataSurface.SurfWinExtBeamAbsByShade[SurfNum] + state.dataSurface.SurfWinExtDiffAbsByShade[SurfNum]) *
        state.dataSurface.SurfWinShadeAbsFacFace2[SurfNum]
    )
    return AbsorptanceFromExteriorBackSide + AbsorptanceFromInteriorBackSide

fn set_surface_out_bulb_temp_at(state: AnyType) -> None:
    if state.dataEnvrn.SiteTempGradient == 0.0:
        for SurfNum in range(state.dataSurface.TotSurfaces):
            state.dataSurface.SurfOutDryBulbTemp[SurfNum] = state.dataEnvrn.OutDryBulbTemp
            state.dataSurface.SurfOutWetBulbTemp[SurfNum] = state.dataEnvrn.OutWetBulbTemp
    else:
        var BaseDryTemp = state.dataEnvrn.OutDryBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
        var BaseWetTemp = state.dataEnvrn.OutWetBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
        var EarthRadius = 6371000.0
        for SurfNum in range(state.dataSurface.TotSurfaces):
            var Z = state.dataSurface.Surface[SurfNum].Centroid[2]
            if Z <= 0.0:
                state.dataSurface.SurfOutDryBulbTemp[SurfNum] = BaseDryTemp
                state.dataSurface.SurfOutWetBulbTemp[SurfNum] = BaseWetTemp
            else:
                var GradientDividend = state.dataEnvrn.SiteTempGradient * EarthRadius * Z
                var GradientDivisor = EarthRadius + Z
                state.dataSurface.SurfOutDryBulbTemp[SurfNum] = BaseDryTemp - GradientDividend / GradientDivisor
                state.dataSurface.SurfOutWetBulbTemp[SurfNum] = BaseWetTemp - GradientDividend / GradientDivisor

fn check_surface_out_bulb_temp_at(state: AnyType) -> None:
    var minBulb = 0.0
    for SurfNum in range(state.dataSurface.TotSurfaces):
        minBulb = min(minBulb, state.dataSurface.SurfOutDryBulbTemp[SurfNum], state.dataSurface.SurfOutWetBulbTemp[SurfNum])
        if minBulb < -100.0:
            raise Error("Surface outside bulb temperature is too low")

fn set_surface_wind_speed_at(state: AnyType) -> None:
    var fac = state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff * math.pow(state.dataEnvrn.SiteWindBLHeight, -state.dataEnvrn.SiteWindExp)
    
    if state.dataEnvrn.SiteWindExp == 0.0:
        for SurfNum in range(state.dataSurface.TotSurfaces):
            state.dataSurface.SurfOutWindSpeed[SurfNum] = state.dataEnvrn.WindSpeed
    else:
        for SurfNum in range(state.dataSurface.TotSurfaces):
            if not state.dataSurface.Surface[SurfNum].ExtWind:
                continue
            var Z = state.dataSurface.Surface[SurfNum].Centroid[2]
            if Z <= 0.0:
                state.dataSurface.SurfOutWindSpeed[SurfNum] = 0.0
            else:
                state.dataSurface.SurfOutWindSpeed[SurfNum] = fac * math.pow(Z, state.dataEnvrn.SiteWindExp)

fn set_surface_wind_dir_at(state: AnyType) -> None:
    for SurfNum in range(state.dataSurface.TotSurfaces):
        state.dataSurface.SurfOutWindDir[SurfNum] = state.dataEnvrn.WindDir

fn get_variable_absorptance_surface_list(state: AnyType) -> None:
    if not state.dataMaterial.AnyVariableAbsorptance:
        return
    
    for surfNum in state.dataSurface.AllHTSurfaceList:
        var thisSurface = state.dataSurface.Surface[surfNum]
        var thisConstruct = state.dataConstruction.Construct[thisSurface.Construction]
        
        if thisConstruct.TotLayers == 0:
            continue
        if thisConstruct.LayerPoint[0] == 0:
            continue
        
        var mat = state.dataMaterial.materials[thisConstruct.LayerPoint[0]]
        if mat.group != 0:
            continue
        
        if mat.absorpVarCtrlSignal != -1:
            if thisSurface.ExtBoundCond != ExternalEnvironment:
                pass
            else:
                state.dataSurface.AllVaryAbsOpaqSurfaceList.append(surfNum)
    
    for ConstrNum in range(state.dataHeatBal.TotConstructs):
        var thisConstruct = state.dataConstruction.Construct[ConstrNum]
        for Layer in range(1, thisConstruct.TotLayers):
            var mat = state.dataMaterial.materials[thisConstruct.LayerPoint[Layer]]
            if mat.group != 0:
                continue
            if mat.absorpVarCtrlSignal != -1:
                pass
