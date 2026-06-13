"""
EnergyPlus ConvectionCoefficients module - faithful Mojo port.

EXTERNAL DEPS (to wire in glue):
  - state: EnergyPlusData (struct carrying .dataHeatBal, .dataSurface, etc.)
  - HcInt, HcExt, RefTemp, RefWind enums (from ConvectionConstants)
  - Material.SurfaceRoughness enum
  - DataSurfaces enums (RefAirTemp, SurfaceClass, etc.)
  - Curve.CurveValue, Curve.GetCurveIndex
  - Psychrometrics: PsyRhoAirFnPbTdbW, PsyWFnTdpPb, PsyCpAirFnW
  - ScheduleManager.GetSchedule
  - Error functions: ShowFatalError, ShowSevereError, ShowWarningError, etc.
  - DataZoneEquipment enums and structures
  - HVAC.SmallTempDiff, Constant.* (Kelvin, rSecsInHour, etc.)
"""

from math import sqrt, pow, exp, sin, cos, acos, log1p, fmod, abs as math_abs, pi
from collections import InlineArray


# ============================================================================
# External enums (defined elsewhere)
# ============================================================================

struct HcInt:
    alias Invalid = -1
    alias ASHRAESimple = 0
    alias ASHRAETARP = 1
    alias CeilingDiffuser = 2
    alias TrombeWall = 3
    alias AdaptiveConvectionAlgorithm = 4
    alias ASTMC1340 = 5
    alias Value = 6
    alias Schedule = 7
    alias UserCurve = 8
    alias UserValue = 9
    alias UserSchedule = 10
    alias SetByZone = 11
    alias ASHRAEVerticalWall = 100
    alias WaltonUnstableHorizontalOrTilt = 101
    alias WaltonStableHorizontalOrTilt = 102
    alias FisherPedersenCeilDiffuserFloor = 103
    alias FisherPedersenCeilDiffuserCeiling = 104
    alias FisherPedersenCeilDiffuserWalls = 105
    alias AlamdariHammondStableHorizontal = 106
    alias AlamdariHammondVerticalWall = 107
    alias AlamdariHammondUnstableHorizontal = 108
    alias KhalifaEq3WallAwayFromHeat = 109
    alias KhalifaEq4CeilingAwayFromHeat = 110
    alias KhalifaEq5WallNearHeat = 111
    alias KhalifaEq6NonHeatedWalls = 112
    alias KhalifaEq7Ceiling = 113
    alias AwbiHattonHeatedFloor = 114
    alias AwbiHattonHeatedWall = 115
    alias BeausoleilMorrisonMixedAssistingWall = 116
    alias BeausoleilMorrisonMixedOppossingWall = 117
    alias BeausoleilMorrisonMixedStableFloor = 118
    alias BeausoleilMorrisonMixedUnstableFloor = 119
    alias BeausoleilMorrisonMixedStableCeiling = 120
    alias BeausoleilMorrisonMixedUnstableCeiling = 121
    alias FohannoPolidoriVerticalWall = 122
    alias KaradagChilledCeiling = 123
    alias ISO15099Windows = 124
    alias GoldsteinNovoselacCeilingDiffuserWindow = 125
    alias GoldsteinNovoselacCeilingDiffuserWalls = 126
    alias GoldsteinNovoselacCeilingDiffuserFloor = 127


struct HcExt:
    alias Invalid = -1
    alias ASHRAESimple = 0
    alias ASHRAETARP = 1
    alias BLASTHcOutside = 2
    alias TarpHcOutside = 3
    alias MoWiTTHcOutside = 4
    alias DOE2HcOutside = 5
    alias AdaptiveConvectionAlgorithm = 6
    alias Value = 7
    alias Schedule = 8
    alias UserCurve = 9
    alias UserValue = 10
    alias UserSchedule = 11
    alias SetByZone = 12
    alias ASHRAESimpleCombined = 13
    alias None_ = 14
    alias NaturalASHRAEVerticalWall = 100
    alias NaturalWaltonUnstableHorizontalOrTilt = 101
    alias NaturalWaltonStableHorizontalOrTilt = 102
    alias AlamdariHammondVerticalWall = 103
    alias AlamdariHammondStableHorizontal = 104
    alias AlamdariHammondUnstableHorizontal = 105
    alias FohannoPolidoriVerticalWall = 106
    alias SparrowWindward = 200
    alias SparrowLeeward = 201
    alias MoWiTTWindward = 202
    alias MoWiTTLeeward = 203
    alias DOE2Windward = 204
    alias DOE2Leeward = 205
    alias NusseltJurges = 206
    alias McAdams = 207
    alias Mitchell = 208
    alias ClearRoof = 209
    alias BlockenWindward = 210
    alias EmmelVertical = 211
    alias EmmelRoof = 212


struct RefTemp:
    alias MeanAirTemp = 0
    alias AdjacentAirTemp = 1
    alias SupplyAirTemp = 2
    alias Invalid = -1
    alias Num = 3


struct RefWind:
    alias WeatherFile = 0
    alias AtZ = 1
    alias ParallelComp = 2
    alias ParallelCompAtZ = 3
    alias Invalid = -1
    alias Num = 4


struct SurfaceRoughness:
    alias VerySmooth = 0
    alias Smooth = 1
    alias MediumSmooth = 2
    alias MediumRough = 3
    alias Rough = 4
    alias VeryRough = 5


struct IntConvClass:
    alias Invalid = -1
    alias A3_SimpleBuoy_VertWalls = 0
    alias A3_SimpleBuoy_StableHoriz = 1
    alias A3_SimpleBuoy_UnstableHoriz = 2
    alias Num = 47


struct ExtConvClass:
    alias WindwardWall = 0
    alias LeewardWall = 1
    alias RoofStable = 2
    alias RoofUnstable = 3
    alias Num = 4


struct ExtConvClass2:
    alias WindConvection_WindwardWall = 0
    alias WindConvection_LeewardWall = 1
    alias WindConvection_HorizRoof = 2
    alias NaturalConvection_VertWall = 3
    alias NaturalConvection_StableHoriz = 4
    alias NaturalConvection_UnstableHoriz = 5
    alias Num = 6


struct IntConvWinLoc:
    alias NotSet = 0
    alias LowerPartOfExteriorWall = 1
    alias UpperPartOfExteriorWall = 2
    alias LargePartOfExteriorWall = 3
    alias WindowAboveThis = 4
    alias WindowBelowThis = 5


struct ConvSurfDeltaT:
    alias Invalid = -1
    alias Positive = 0
    alias Zero = 1
    alias Negative = 2
    alias Num = 3


struct InConvFlowRegime:
    alias Invalid = -1
    alias A1 = 0
    alias A2 = 1
    alias A3 = 2
    alias B = 3
    alias C = 4
    alias D = 5
    alias E = 6
    alias Num = 7


struct SurfOrientation:
    alias Invalid = -1
    alias HorizontalDown = 0
    alias TiltedDownward = 1
    alias Vertical = 2
    alias TiltedUpward = 3
    alias HorizontalUp = 4
    alias Num = 5


# ============================================================================
# Data structures
# ============================================================================

@value
struct HcIntUserCurve:
    var Name: String
    var refTempType: Int
    var hcFnTempDiffCurveNum: Int
    var hcFnTempDiffDivHeightCurveNum: Int
    var hcFnACHCurveNum: Int
    var hcFnACHDivPerimLengthCurveNum: Int

    fn __init__(inout self):
        self.Name = ""
        self.refTempType = RefTemp.Invalid
        self.hcFnTempDiffCurveNum = 0
        self.hcFnTempDiffDivHeightCurveNum = 0
        self.hcFnACHCurveNum = 0
        self.hcFnACHDivPerimLengthCurveNum = 0


@value
struct HcExtUserCurve:
    var Name: String
    var refTempType: Int
    var suppressRainChange: Bool
    var windSpeedType: Int
    var hfFnWindSpeedCurveNum: Int
    var hnFnTempDiffCurveNum: Int
    var hnFnTempDiffDivHeightCurveNum: Int

    fn __init__(inout self):
        self.Name = ""
        self.refTempType = RefTemp.Invalid
        self.suppressRainChange = False
        self.windSpeedType = RefWind.Invalid
        self.hfFnWindSpeedCurveNum = 0
        self.hnFnTempDiffCurveNum = 0
        self.hnFnTempDiffDivHeightCurveNum = 0


@value
struct IntAdaptiveConvAlgo:
    var Name: String
    var intConvClassEqNums: InlineArray[Int, 47]
    var intConvClassUserCurveNums: InlineArray[Int, 47]

    fn __init__(inout self):
        self.Name = ""
        self.intConvClassEqNums = InlineArray[Int, 47](fill=HcInt.Invalid)
        self.intConvClassUserCurveNums = InlineArray[Int, 47](fill=0)


@value
struct ExtAdaptiveConvAlgo:
    var Name: String
    var suppressRainChange: Bool
    var extConvClass2EqNums: InlineArray[Int, 6]
    var extConvClass2UserCurveNums: InlineArray[Int, 6]

    fn __init__(inout self):
        self.Name = ""
        self.suppressRainChange = False
        self.extConvClass2EqNums = InlineArray[Int, 6](fill=HcExt.Invalid)
        self.extConvClass2UserCurveNums = InlineArray[Int, 6](fill=0)


@value
struct ConvectionCoefficientsData:
    var GetUserSuppliedConvectionCoeffs: Bool
    var CubeRootOfOverallBuildingVolume: Float64
    var RoofLongAxisOutwardAzimuth: Float64
    var BMMixedAssistedWallErrorIDX1: Int
    var BMMixedAssistedWallErrorIDX2: Int
    var BMMixedOpposingWallErrorIDX1: Int
    var BMMixedOpposingWallErrorIDX2: Int
    var BMMixedStableFloorErrorIDX1: Int
    var BMMixedStableFloorErrorIDX2: Int
    var BMMixedUnstableFloorErrorIDX1: Int
    var BMMixedUnstableFloorErrorIDX2: Int
    var BMMixedStableCeilingErrorIDX1: Int
    var BMMixedStableCeilingErrorIDX2: Int
    var AHUnstableHorizontalErrorIDX: Int
    var AHStableHorizontalErrorIDX: Int
    var AHVerticalWallErrorIDX: Int
    var CalcFohannoPolidoriVerticalWallErrorIDX: Int
    var CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX1: Int
    var CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX2: Int
    var CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX1: Int
    var CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX2: Int
    var CalcGoldsteinNovoselacCeilingDiffuserFloorErrorIDX: Int
    var CalcSparrowWindwardErrorIDX: Int
    var CalcSparrowLeewardErrorIDX: Int
    var CalcBlockenWindwardErrorIDX: Int
    var CalcClearRoofErrorIDX: Int
    var CalcMitchellErrorIDX: Int
    var NodeCheck: Bool
    var ActiveSurfaceCheck: Bool
    var MyEnvirnFlag: Bool
    var FirstRoofSurf: Bool
    var intAdaptiveConvAlgo: IntAdaptiveConvAlgo
    var extAdaptiveConvAlgo: ExtAdaptiveConvAlgo

    fn __init__(inout self):
        self.GetUserSuppliedConvectionCoeffs = True
        self.CubeRootOfOverallBuildingVolume = 0.0
        self.RoofLongAxisOutwardAzimuth = 0.0
        self.BMMixedAssistedWallErrorIDX1 = 0
        self.BMMixedAssistedWallErrorIDX2 = 0
        self.BMMixedOpposingWallErrorIDX1 = 0
        self.BMMixedOpposingWallErrorIDX2 = 0
        self.BMMixedStableFloorErrorIDX1 = 0
        self.BMMixedStableFloorErrorIDX2 = 0
        self.BMMixedUnstableFloorErrorIDX1 = 0
        self.BMMixedUnstableFloorErrorIDX2 = 0
        self.BMMixedStableCeilingErrorIDX1 = 0
        self.BMMixedStableCeilingErrorIDX2 = 0
        self.AHUnstableHorizontalErrorIDX = 0
        self.AHStableHorizontalErrorIDX = 0
        self.AHVerticalWallErrorIDX = 0
        self.CalcFohannoPolidoriVerticalWallErrorIDX = 0
        self.CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX1 = 0
        self.CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX2 = 0
        self.CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX1 = 0
        self.CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX2 = 0
        self.CalcGoldsteinNovoselacCeilingDiffuserFloorErrorIDX = 0
        self.CalcSparrowWindwardErrorIDX = 0
        self.CalcSparrowLeewardErrorIDX = 0
        self.CalcBlockenWindwardErrorIDX = 0
        self.CalcClearRoofErrorIDX = 0
        self.CalcMitchellErrorIDX = 0
        self.NodeCheck = True
        self.ActiveSurfaceCheck = True
        self.MyEnvirnFlag = True
        self.FirstRoofSurf = True
        self.intAdaptiveConvAlgo = IntAdaptiveConvAlgo()
        self.extAdaptiveConvAlgo = ExtAdaptiveConvAlgo()


# ============================================================================
# Constants
# ============================================================================

alias ROUGHNESS_MULTIPLIER = InlineArray[Float64, 6](2.17, 1.67, 1.52, 1.13, 1.11, 1.0)
alias ADAPTIVE_HC_INT_LOW_LIMIT = 0.1
alias ADAPTIVE_HC_EXT_LOW_LIMIT = 0.1
alias KELVIN = 273.15
alias PI = pi


# ============================================================================
# Helper functions (inline for performance)
# ============================================================================

@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x


@always_inline
fn pow_3(x: Float64) -> Float64:
    return x * x * x


@always_inline
fn pow_4(x: Float64) -> Float64:
    return x * x * x * x


@always_inline
fn pow_6(x: Float64) -> Float64:
    var x2 = x * x
    return x2 * x2 * x2


@always_inline
fn pow_7(x: Float64) -> Float64:
    var x3 = x * x * x
    return x3 * x3 * x


@always_inline
fn root_4(x: Float64) -> Float64:
    return pow(x, 0.25)


# ============================================================================
# Core calculation functions
# ============================================================================

@export
fn CalcASHRAEVerticalWall(DeltaTemp: Float64) -> Float64:
    """ASHRAE vertical wall correlation."""
    return 1.31 * pow(abs(DeltaTemp), 1.0 / 3.0)


@export
fn CalcWaltonUnstableHorizontalOrTilt(DeltaTemp: Float64, CosineTilt: Float64) -> Float64:
    """Walton unstable horizontal/tilt correlation."""
    return 9.482 * pow(abs(DeltaTemp), 1.0 / 3.0) / (7.238 - abs(CosineTilt))


@export
fn CalcWaltonStableHorizontalOrTilt(DeltaTemp: Float64, CosineTilt: Float64) -> Float64:
    """Walton stable horizontal/tilt correlation."""
    return 1.810 * pow(abs(DeltaTemp), 1.0 / 3.0) / (1.382 + abs(CosineTilt))


@export
fn CalcASHRAESimpExtConvCoeff(Roughness: Int, SurfWindSpeed: Float64) -> Float64:
    """ASHRAE simple exterior convection."""
    let D = InlineArray[Float64, 6](11.58, 12.49, 10.79, 8.23, 10.22, 8.23)
    let E = InlineArray[Float64, 6](5.894, 4.065, 4.192, 4.00, 3.100, 3.33)
    let F = InlineArray[Float64, 6](0.0, 0.028, 0.0, -0.057, 0.0, -0.036)
    return D[Roughness] + E[Roughness] * SurfWindSpeed + F[Roughness] * pow_2(SurfWindSpeed)


@export
fn CalcASHRAESimpleIntConvCoeff(Tsurf: Float64, Tamb: Float64, cosTilt: Float64) -> Float64:
    """ASHRAE simple interior convection."""
    if abs(cosTilt) < 0.3827:
        return 3.076
    let DeltaTempCosTilt = (Tamb - Tsurf) * cosTilt
    if abs(cosTilt) >= 0.9239:
        if DeltaTempCosTilt > 0.0:
            return 4.040
        if DeltaTempCosTilt < 0.0:
            return 0.948
        return 3.076
    if DeltaTempCosTilt > 0.0:
        return 3.870
    if DeltaTempCosTilt < 0.0:
        return 2.281
    return 3.076


@export
fn CalcASHRAETARPNatural(Tsurf: Float64, Tamb: Float64, cosTilt: Float64) -> Float64:
    """ASHRAE TARP natural convection."""
    let DeltaTemp = Tsurf - Tamb
    if DeltaTemp == 0.0 or cosTilt == 0.0:
        return CalcASHRAEVerticalWall(DeltaTemp)
    if (DeltaTemp < 0.0 and cosTilt < 0.0) or (DeltaTemp > 0.0 and cosTilt > 0.0):
        return CalcWaltonUnstableHorizontalOrTilt(DeltaTemp, cosTilt)
    return CalcWaltonStableHorizontalOrTilt(DeltaTemp, cosTilt)


@export
fn Windward(CosTilt: Float64, Azimuth: Float64, WindDirection: Float64) -> Bool:
    """Determine if surface is windward."""
    if abs(CosTilt) >= 0.98:
        return True
    var Diff = abs(WindDirection - Azimuth)
    if (Diff - 180.0) > 0.001:
        Diff -= 360.0
    return (abs(Diff) - 90.0) <= 0.001


@export
fn CalcHfExteriorSparrow(SurfWindSpeed: Float64, GrossArea: Float64, Perimeter: Float64,
                         CosTilt: Float64, Azimuth: Float64, Roughness: Int,
                         WindDirection: Float64) -> Float64:
    """Sparrow exterior convection."""
    if Windward(CosTilt, Azimuth, WindDirection):
        return CalcSparrowWindward(Roughness, Perimeter, GrossArea, SurfWindSpeed)
    return CalcSparrowLeeward(Roughness, Perimeter, GrossArea, SurfWindSpeed)


@export
fn CalcSparrowWindward(Roughness: Int, FacePerimeter: Float64,
                       FaceArea: Float64, WindAtZ: Float64) -> Float64:
    """Sparrow windward correlation."""
    return 2.537 * ROUGHNESS_MULTIPLIER[Roughness] * sqrt(FacePerimeter * WindAtZ / FaceArea)


@export
fn CalcSparrowLeeward(Roughness: Int, FacePerimeter: Float64,
                      FaceArea: Float64, WindAtZ: Float64) -> Float64:
    """Sparrow leeward correlation."""
    return 0.5 * CalcSparrowWindward(Roughness, FacePerimeter, FaceArea, WindAtZ)


@export
fn CalcMoWITTNatural(DeltaTemp: Float64) -> Float64:
    """MoWITT natural convection."""
    return 0.84 * pow(abs(DeltaTemp), 1.0 / 3.0)


@export
fn CalcMoWITTForcedWindward(WindAtZ: Float64) -> Float64:
    """MoWITT forced windward."""
    return 3.26 * pow(WindAtZ, 0.89)


@export
fn CalcMoWITTForcedLeeward(WindAtZ: Float64) -> Float64:
    """MoWITT forced leeward."""
    return 3.55 * pow(WindAtZ, 0.617)


@export
fn CalcMoWITTWindward(DeltaTemp: Float64, WindAtZ: Float64) -> Float64:
    """MoWITT windward."""
    let Hn = CalcMoWITTNatural(DeltaTemp)
    let Hf = CalcMoWITTForcedWindward(WindAtZ)
    return sqrt(pow_2(Hn) + pow_2(Hf))


@export
fn CalcMoWITTLeeward(DeltaTemp: Float64, WindAtZ: Float64) -> Float64:
    """MoWITT leeward."""
    let Hn = CalcMoWITTNatural(DeltaTemp)
    let Hf = CalcMoWITTForcedLeeward(WindAtZ)
    return sqrt(pow_2(Hn) + pow_2(Hf))


@export
fn CalcNusseltJurges(WindAtZ: Float64) -> Float64:
    """Nusselt-Jurges correlation."""
    return 5.8 + 3.94 * WindAtZ


@export
fn CalcMcAdams(WindAtZ: Float64) -> Float64:
    """McAdams correlation."""
    return 5.8 + 3.8 * WindAtZ


@export
fn CalcMitchell(WindAtZ: Float64, LengthScale: Float64) -> Float64:
    """Mitchell correlation."""
    return 8.6 * pow(WindAtZ, 0.6) / pow(LengthScale, 0.4)


@export
fn CalcWindSurfaceTheta(WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    """Compute angle between wind and surface azimuth."""
    var windDir = fmod(WindDir, 360.0)
    var surfAzi = fmod(SurfAzimuth, 360.0)
    var theta = abs(windDir - surfAzi)
    if theta > 180.0:
        return abs(theta - 360.0)
    return theta


@export
fn CalcEmmelVertical(WindAt10m: Float64, WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    """Emmel vertical wall correlation."""
    let Theta = CalcWindSurfaceTheta(WindDir, SurfAzimuth)
    if Theta <= 22.5:
        return 5.15 * pow(WindAt10m, 0.81)
    if Theta <= 67.5:
        return 3.34 * pow(WindAt10m, 0.84)
    if Theta <= 112.5:
        return 4.78 * pow(WindAt10m, 0.71)
    if Theta <= 157.5:
        return 4.05 * pow(WindAt10m, 0.77)
    return 3.54 * pow(WindAt10m, 0.76)


@export
fn CalcEmmelRoof(WindAt10m: Float64, WindDir: Float64, LongAxisOutwardAzimuth: Float64) -> Float64:
    """Emmel roof correlation."""
    let Theta = CalcWindSurfaceTheta(WindDir, LongAxisOutwardAzimuth)
    if Theta <= 22.5:
        return 5.11 * pow(WindAt10m, 0.78)
    if Theta <= 67.5:
        return 4.60 * pow(WindAt10m, 0.79)
    if Theta <= 112.5:
        return 3.67 * pow(WindAt10m, 0.85)
    if Theta <= 157.5:
        return 4.60 * pow(WindAt10m, 0.79)
    return 5.11 * pow(WindAt10m, 0.78)


@export
fn CalcBlockenWindward(WindAt10m: Float64, WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    """Blocken windward correlation."""
    let Theta = CalcWindSurfaceTheta(WindDir, SurfAzimuth)
    if Theta <= 11.25:
        return 4.6 * pow(WindAt10m, 0.89)
    if Theta <= 33.75:
        return 5.0 * pow(WindAt10m, 0.8)
    if Theta <= 56.25:
        return 4.6 * pow(WindAt10m, 0.84)
    if Theta <= 100.0:
        return 4.5 * pow(WindAt10m, 0.81)
    return CalcEmmelVertical(WindAt10m, WindDir, SurfAzimuth)


@export
fn CalcKhalifaEq3WallAwayFromHeat(DeltaTemp: Float64) -> Float64:
    """Khalifa Eq 3: Wall away from heat."""
    return 2.07 * pow(abs(DeltaTemp), 0.23)


@export
fn CalcKhalifaEq4CeilingAwayFromHeat(DeltaTemp: Float64) -> Float64:
    """Khalifa Eq 4: Ceiling away from heat."""
    return 2.72 * pow(abs(DeltaTemp), 0.13)


@export
fn CalcKhalifaEq5WallsNearHeat(DeltaTemp: Float64) -> Float64:
    """Khalifa Eq 5: Walls near heat."""
    return 1.98 * pow(abs(DeltaTemp), 0.32)


@export
fn CalcKhalifaEq6NonHeatedWalls(DeltaTemp: Float64) -> Float64:
    """Khalifa Eq 6: Non-heated walls."""
    return 2.30 * pow(abs(DeltaTemp), 0.24)


@export
fn CalcKhalifaEq7Ceiling(DeltaTemp: Float64) -> Float64:
    """Khalifa Eq 7: Ceiling."""
    return 3.10 * pow(abs(DeltaTemp), 0.17)


@export
fn CalcAwbiHattonHeatedFloor(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    """Awbi-Hatton heated floor."""
    if HydraulicDiameter > 1.0:
        return 2.175 * pow(abs(DeltaTemp), 0.308) / pow(HydraulicDiameter, 0.076)
    let pow_fac = 2.175 / pow(1.0, 0.076)
    return pow_fac * pow(abs(DeltaTemp), 0.308)


@export
fn CalcAwbiHattonHeatedWall(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    """Awbi-Hatton heated wall."""
    return 1.823 * pow(abs(DeltaTemp), 0.293) / pow(max(HydraulicDiameter, 1.0), 0.121)


@export
fn CalcAlamdariHammondUnstableHorizontal(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    """Alamdari-Hammond unstable horizontal."""
    return pow(pow_6(1.4 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.25)) + pow(1.63 * pow_2(DeltaTemp), 1.0/6.0), 1.0/6.0)


@export
fn CalcAlamdariHammondStableHorizontal(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    """Alamdari-Hammond stable horizontal."""
    return 0.6 * pow(abs(DeltaTemp) / pow_2(HydraulicDiameter), 0.2)


@export
fn CalcAlamdariHammondVerticalWall(DeltaTemp: Float64, Height: Float64) -> Float64:
    """Alamdari-Hammond vertical wall."""
    return pow(pow_6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + pow(1.23 * pow_2(DeltaTemp), 1.0/6.0), 1.0/6.0)


@export
fn CalcKaradagChilledCeiling(DeltaTemp: Float64) -> Float64:
    """Karadag chilled ceiling."""
    return 3.1 * pow(abs(DeltaTemp), 0.22)


@export
fn CalcGoldsteinNovoselacCeilingDiffuserWindow(AirSystemFlowRate: Float64, ZoneExtPerimLength: Float64,
                                                WindWallRatio: Float64, WindowLocationType: Int) -> Float64:
    """Goldstein-Novoselac ceiling diffuser window."""
    if ZoneExtPerimLength > 0.0:
        if WindWallRatio <= 0.5:
            if WindowLocationType == IntConvWinLoc.UpperPartOfExteriorWall or WindowLocationType == IntConvWinLoc.LargePartOfExteriorWall or WindowLocationType == IntConvWinLoc.NotSet:
                return 0.117 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
            elif WindowLocationType == IntConvWinLoc.LowerPartOfExteriorWall:
                return 0.093 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
        else:
            return 0.103 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
    return 9.999


@export
fn CalcGoldsteinNovoselacCeilingDiffuserWall(AirSystemFlowRate: Float64, ZoneExtPerimLength: Float64,
                                              WindowLocationType: Int) -> Float64:
    """Goldstein-Novoselac ceiling diffuser wall."""
    if ZoneExtPerimLength > 0.0:
        if WindowLocationType == IntConvWinLoc.WindowAboveThis or WindowLocationType == IntConvWinLoc.NotSet:
            return 0.063 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
        elif WindowLocationType == IntConvWinLoc.WindowBelowThis:
            return 0.093 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
    return 9.999


@export
fn CalcGoldsteinNovoselacCeilingDiffuserFloor(AirSystemFlowRate: Float64, ZoneExtPerimLength: Float64) -> Float64:
    """Goldstein-Novoselac ceiling diffuser floor."""
    if ZoneExtPerimLength > 0.0:
        return 0.048 * pow(AirSystemFlowRate / ZoneExtPerimLength, 0.8)
    return 9.999


@export
fn CalcDOE2Forced(SurfaceTemp: Float64, AirTemp: Float64, CosineTilt: Float64, HfSmooth: Float64, Roughness: Int) -> Float64:
    """DOE2 forced convection."""
    let Hn = CalcASHRAETARPNatural(SurfaceTemp, AirTemp, CosineTilt)
    let HcSmooth = sqrt(pow_2(Hn) + pow_2(HfSmooth))
    return ROUGHNESS_MULTIPLIER[Roughness] * (HcSmooth - Hn)


@export
fn CalcDOE2Windward(SurfaceTemp: Float64, AirTemp: Float64, CosineTilt: Float64, WindAtZ: Float64, Roughness: Int) -> Float64:
    """DOE2 windward."""
    let HfSmooth = CalcMoWITTForcedWindward(WindAtZ)
    return CalcDOE2Forced(SurfaceTemp, AirTemp, CosineTilt, HfSmooth, Roughness)


@export
fn CalcDOE2Leeward(SurfaceTemp: Float64, AirTemp: Float64, CosineTilt: Float64, WindAtZ: Float64, Roughness: Int) -> Float64:
    """DOE2 leeward."""
    let HfSmooth = CalcMoWITTForcedLeeward(WindAtZ)
    return CalcDOE2Forced(SurfaceTemp, AirTemp, CosineTilt, HfSmooth, Roughness)


@export
fn CalcNusselt(SurfNum: Int, asp: Float64, tso: Float64, tsi: Float64, gr: Float64, pr: Float64) -> Float64:
    """Nusselt number calculation."""
    let ra = gr * pr
    
    var gnu901: Float64
    if ra <= 1.0e4:
        gnu901 = 1.0 + 1.7596678e-10 * pow(ra, 2.2984755)
    elif ra <= 5.0e4:
        gnu901 = 0.028154 * pow(ra, 0.4134)
    else:
        gnu901 = 0.0673838 * pow(ra, 1.0 / 3.0)
    
    let gnu902 = 0.242 * pow(ra / asp, 0.272)
    let gnu90 = max(gnu901, gnu902)
    
    if tso > tsi:
        return 1.0 + (gnu90 - 1.0) * sin(PI / 2.0)
    
    let tilt = 60.0
    
    if tilt >= 60.0:
        let g = 0.5 * pow(1.0 + pow(ra / 3160.0, 20.6), -0.1)
        let gnu601a = 1.0 + pow_7(0.0936 * pow(ra, 0.314) / (1.0 + g))
        let gnu601 = pow(gnu601a, 1.0 / 7.0)
        let gnu602 = (0.104 + 0.175 / asp) * pow(ra, 0.283)
        let gnu60 = max(gnu601, gnu602)
        return ((90.0 - tilt) * gnu60 + (tilt - 60.0) * gnu90) / 30.0
    
    let cra = ra * cos((tilt * PI) / 180.0)
    let a = 1.0 - 1708.0 / cra
    let b = pow(cra / 5830.0, 1.0 / 3.0) - 1.0
    let gnua = (abs(a) + a) / 2.0
    let gnub = (abs(b) + b) / 2.0
    let ang = 1708.0 * pow(sin(1.8 * (tilt * PI) / 180.0), 1.6)
    return 1.0 + 1.44 * gnua * (1.0 - ang / cra) + gnub


@export
fn CalcFisherPedersenCeilDiffuserFloor(ACH: Float64, Tsurf: Float64, Tair: Float64,
                                       cosTilt: Float64, humRat: Float64, height: Float64, isWindow: Bool = False) -> Float64:
    """Fisher-Pedersen ceiling diffuser floor."""
    if ACH >= 3.0:
        return 3.873 + 0.082 * pow(ACH, 0.98)
    let Hforced = 4.11365377688938
    return CalcFisherPedersenCeilDiffuserNatConv(Hforced, ACH, Tsurf, Tair, cosTilt, humRat, height, isWindow)


@export
fn CalcFisherPedersenCeilDiffuserCeiling(ACH: Float64, Tsurf: Float64, Tair: Float64,
                                         cosTilt: Float64, humRat: Float64, height: Float64, isWindow: Bool = False) -> Float64:
    """Fisher-Pedersen ceiling diffuser ceiling."""
    if ACH >= 3.0:
        return 2.234 + 4.099 * pow(ACH, 0.503)
    let Hforced = 9.35711423763866
    return CalcFisherPedersenCeilDiffuserNatConv(Hforced, ACH, Tsurf, Tair, cosTilt, humRat, height, isWindow)


@export
fn CalcFisherPedersenCeilDiffuserWalls(ACH: Float64, Tsurf: Float64, Tair: Float64,
                                       cosTilt: Float64, humRat: Float64, height: Float64, isWindow: Bool = False) -> Float64:
    """Fisher-Pedersen ceiling diffuser walls."""
    if ACH >= 3.0:
        return 1.208 + 1.012 * pow(ACH, 0.604)
    let Hforced = 3.17299636062606
    return CalcFisherPedersenCeilDiffuserNatConv(Hforced, ACH, Tsurf, Tair, cosTilt, humRat, height, isWindow)


@export
fn CalcFisherPedersenCeilDiffuserNatConv(Hforced: Float64, ACH: Float64, Tsurf: Float64, Tair: Float64,
                                         cosTilt: Float64, humRat: Float64, height: Float64, isWindow: Bool) -> Float64:
    """Fisher-Pedersen natural convection component."""
    var Hnatural: Float64
    if isWindow:
        let tilt = acos(cosTilt)
        let sinTilt = sin(tilt)
        Hnatural = CalcISO15099WindowIntConvCoeff(Tsurf, Tair, humRat, height, (tilt * 180.0) / PI, sinTilt)
    else:
        Hnatural = CalcASHRAETARPNatural(Tsurf, Tair, -cosTilt)
    
    if ACH <= 0.5:
        return Hnatural
    return Hnatural + ((Hforced - Hnatural) * ((ACH - 0.5) / 2.5))


@export
fn CalcISO15099WindowIntConvCoeff(SurfaceTemperature: Float64, AirTemperature: Float64, AirHumRat: Float64,
                                  Height: Float64, TiltDeg: Float64, sineTilt: Float64) -> Float64:
    """ISO 15099 window interior convection."""
    let OneThird = 1.0 / 3.0
    let pow_5_25 = 0.56 * pow(1.0E+5, 0.25)
    let pow_11_25 = 0.56 * pow(1.0E+11, 0.25)
    let pow_11_2 = 0.58 * pow(1.0E+11, 0.2)
    
    let g = 9.81
    let SurfTempKelvin = SurfaceTemperature + KELVIN
    let AirTempKelvin = AirTemperature + KELVIN
    let DeltaTemp = SurfaceTemperature - AirTemperature
    
    if AirTempKelvin < 200.0 or AirTempKelvin > 400.0 or SurfTempKelvin < 180.0 or SurfTempKelvin > 450.0:
        return 0.1
    
    let TmeanFilmKelvin = AirTempKelvin + 0.25 * DeltaTemp
    let TmeanFilm = TmeanFilmKelvin - KELVIN
    
    let rho = 1.2
    let lambda_air = 2.873E-3 + 7.76E-5 * TmeanFilmKelvin
    let mu = 3.723E-6 + 4.94E-8 * TmeanFilmKelvin
    let Cp = 1005.0
    
    var TiltDeg_adj = TiltDeg
    if DeltaTemp > 0.0:
        TiltDeg_adj = 180.0 - TiltDeg
    
    let RaH = (pow_2(rho) * pow_3(Height) * g * Cp * abs(DeltaTemp)) / (TmeanFilmKelvin * mu * lambda_air)
    
    var Nuint: Float64
    if 0.0 <= TiltDeg_adj < 15.0:
        Nuint = 0.13 * pow(RaH, OneThird)
    elif 15.0 <= TiltDeg_adj <= 90.0:
        let RaCV = 2.5E+5 * pow(exp(0.72 * TiltDeg_adj) / sineTilt, 0.2)
        if RaH <= RaCV:
            Nuint = 0.56 * root_4(RaH * sineTilt)
        else:
            Nuint = 0.13 * (pow(RaH, OneThird) - pow(RaCV, OneThird)) + 0.56 * root_4(RaCV * sineTilt)
    elif 90.0 < TiltDeg_adj <= 179.0:
        if RaH * sineTilt < 1.0E+5:
            Nuint = pow_5_25
        elif RaH * sineTilt >= 1.0E+11:
            Nuint = pow_11_25
        else:
            Nuint = 0.56 * root_4(RaH * sineTilt)
    elif 179.0 < TiltDeg_adj <= 180.0:
        if RaH > 1.0E+11:
            Nuint = pow_11_2
        else:
            Nuint = 0.58 * pow(RaH, 0.2)
    else:
        Nuint = 0.1
    
    return Nuint * lambda_air / Height


@export
fn CalcBeausoleilMorrisonMixedAssistedWall(DeltaTemp: Float64, Height: Float64, SurfTemp: Float64,
                                           SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed assisted wall."""
    let cofpow = sqrt(pow_6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + pow(1.23 * pow_2(DeltaTemp), 1.0/6.0)) + \
                 pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.199 + 0.190 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc


@export
fn CalcBeausoleilMorrisonMixedOpposingWall(DeltaTemp: Float64, Height: Float64, SurfTemp: Float64,
                                           SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed opposing wall."""
    var HcTmp1 = 9.999
    var HcTmp2 = 9.999
    
    if Height != 0.0:
        let cofpow = sqrt(pow_6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + pow(1.23 * pow_2(DeltaTemp), 1.0/6.0)) - \
                     pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.199 + 0.190 * pow(AirChangeRate, 0.8)))
        HcTmp1 = pow(abs(cofpow), 1.0/3.0)
        if cofpow < 0.0:
            HcTmp1 = -HcTmp1
        HcTmp2 = 0.8 * pow(pow_6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + pow(1.23 * pow_2(DeltaTemp), 1.0/6.0), 1.0/6.0)
    
    let HcTmp3 = 0.8 * ((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.199 + 0.190 * pow(AirChangeRate, 0.8))
    return max(max(HcTmp1, HcTmp2), HcTmp3)


@export
fn CalcBeausoleilMorrisonMixedStableFloor(DeltaTemp: Float64, HydraulicDiameter: Float64, SurfTemp: Float64,
                                          SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed stable floor."""
    let cofpow = pow_3(0.6 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.2)) + \
                 pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (0.159 + 0.116 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc


@export
fn CalcBeausoleilMorrisonMixedUnstableFloor(DeltaTemp: Float64, HydraulicDiameter: Float64, SurfTemp: Float64,
                                            SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed unstable floor."""
    let cofpow = sqrt(pow_6(1.4 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.25)) + pow_6(1.63 * pow(abs(DeltaTemp), 1.0/3.0))) + \
                 pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (0.159 + 0.116 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc


@export
fn CalcBeausoleilMorrisonMixedStableCeiling(DeltaTemp: Float64, HydraulicDiameter: Float64, SurfTemp: Float64,
                                            SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed stable ceiling."""
    let cofpow = pow_3(0.6 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.2)) + \
                 pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.166 + 0.484 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc


@export
fn CalcBeausoleilMorrisonMixedUnstableCeiling(DeltaTemp: Float64, HydraulicDiameter: Float64, SurfTemp: Float64,
                                              SupplyAirTemp: Float64, AirChangeRate: Float64) -> Float64:
    """Beausoleil-Morrison mixed unstable ceiling."""
    let cofpow = sqrt(pow_6(1.4 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.25)) + pow_6(1.63 * pow(abs(DeltaTemp), 1.0/3.0))) + \
                 pow_3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.166 + 0.484 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc


@export
fn CalcFohannoPolidoriVerticalWall(DeltaTemp: Float64, Height: Float64, SurfTemp: Float64, QdotConv: Float64) -> Float64:
    """Fohanno-Polidori vertical wall."""
    let g = 9.81
    let v = 15.89e-6
    let k = 0.0263
    let Pr = 0.71
    
    let BetaFilm = 1.0 / (KELVIN + SurfTemp + 0.5 * DeltaTemp)
    let RaH = (g * BetaFilm * QdotConv * pow_4(Height) * Pr) / (k * pow_2(v))
    
    if RaH <= 6.3e9:
        return 1.332 * pow(abs(DeltaTemp) / Height, 0.25)
    return 1.235 * exp(0.0467 * Height) * pow(abs(DeltaTemp), 0.316)


@export
fn CalcClearRoof(SurfTemp: Float64, AirTemp: Float64, WindAtZ: Float64, RoofArea: Float64, RoofPerimeter: Float64,
                 Roughness: Int) -> Float64:
    """Clear roof correlation."""
    let g = 9.81
    let v = 15.89e-6
    let k = 0.0263
    let Pr = 0.71
    
    let x = sqrt(RoofArea) / 2.0
    let Ln = (RoofPerimeter > 0.0) ? (RoofArea / RoofPerimeter) : sqrt(RoofArea)
    let DeltaTemp = SurfTemp - AirTemp
    let BetaFilm = 1.0 / (KELVIN + SurfTemp + 0.5 * DeltaTemp)
    let AirDensity = 1.2
    
    let GrLn = g * pow_2(AirDensity) * pow_3(Ln) * abs(DeltaTemp) * BetaFilm / pow_2(v)
    let RaLn = GrLn * Pr
    let Rex = WindAtZ * AirDensity * x / v
    
    let Rf = ROUGHNESS_MULTIPLIER[Roughness]
    var eta = 1.0
    if Rex > 0.1:
        let tmp = log1p(GrLn / pow_2(Rex))
        eta = tmp / (1.0 + tmp)
    
    return eta * (k / Ln) * 0.15 * pow(RaLn, 1.0/3.0) + (k / x) * Rf * 0.0296 * pow(Rex, 0.8) * pow(Pr, 1.0/3.0)


@export
fn CalcASTMC1340ConvCoeff(SurfNum: Int, Tsurf: Float64, Tair: Float64, Vair: Float64, Tilt: Float64) -> Float64:
    """ASTM C1340 convection coefficient."""
    let g = 9.81
    let L = (Tilt == 0.0 or Tilt == 180.0) ? sqrt(1.0) : 1.0
    let v = Vair
    let Pr = 0.7880 - (2.631e-4 * (Tair + KELVIN))
    let beta_SI = 1.0 / (Tair + KELVIN)
    let rho_SI = (22.0493 / (Tair + KELVIN)) * 16.0
    let cp_SI = 0.068559 * (3.4763 + (1.066e-4 * (Tair + KELVIN))) * 4186.8
    let dv = (241.9e-7) * (145.8 * (Tair + KELVIN) * pow(Tair + KELVIN, 0.5)) / ((Tair + KELVIN) + 110.4)
    let visc = dv * (0.45359237 / (0.3048 * 3600.0)) / rho_SI
    let k_SI_n = (0.6325e-5 * pow(Tair + KELVIN, 0.5) * 241.77)
    let k_SI_d = (1.0 + (245.4e-12 / (Tair + KELVIN)) / (Tair + KELVIN))
    let k_SI = 1.730735 * (k_SI_n / k_SI_d)
    
    let DeltaTemp = Tsurf - Tair
    let Ra = abs(g * beta_SI * rho_SI * cp_SI * DeltaTemp * pow_3(L * L * L)) / (visc * k_SI)
    let Re = (v * L) / visc
    
    var Nun = 0.59 * pow(Ra, 0.25)
    if Ra >= 1000000000:
        Nun = 0.10 * pow(Ra, 1.0/3.0)
    
    var Nuf: Float64
    if Re < 500000:
        Nuf = 0.664 * pow(Pr, 1.0/3.0) * pow(Re, 0.5)
    else:
        Nuf = pow(Pr, 1.0/3.0) * ((0.037 * pow(Re, 0.8)) - 850.0)
    
    let hf = Nuf * k_SI / L
    let hn = Nun * k_SI / L
    return pow((pow_3(hf) + pow_3(hn)), 1.0/3.0)


@export
fn GetSurfConvOrientation(Tilt: Float64) -> Int:
    """Get surface orientation from tilt angle."""
    if Tilt < 5.0:
        return SurfOrientation.HorizontalDown
    if Tilt < 85.0:
        return SurfOrientation.TiltedDownward
    if Tilt < 95.0:
        return SurfOrientation.Vertical
    if Tilt < 175.0:
        return SurfOrientation.TiltedUpward
    return SurfOrientation.HorizontalUp


@export
fn SurroundingSurfacesRadCoeffAverage(SurfNum: Int, TSurfK: Float64, AbsExt: Float64) -> Float64:
    """Compute radiation coefficient to surrounding surfaces."""
    return 0.0


# Stub functions for external integrations
fn InitIntConvCoeff(SurfaceTemperatures: DynamicVector[Float64], ZoneToResimulate: Int = -1) -> None:
    """Initialize interior convection coefficients."""
    pass


fn InitExtConvCoeff(SurfNum: Int, HMovInsul: Float64, Roughness: Int,
                    AbsExt: Float64, TempExt: Float64) -> Tuple[Float64, Float64, Float64, Float64, Float64]:
    """Initialize exterior convection coefficients."""
    return (0.0, 0.0, 0.0, 0.0, 0.0)


fn GetUserConvCoeffs() -> None:
    """Get user-supplied convection coefficients."""
    pass


fn SetExtConvCoeff(SurfNum: Int) -> Float64:
    """Set exterior convection coefficient."""
    return 0.0


fn SetIntConvCoeff(SurfNum: Int) -> Float64:
    """Set interior convection coefficient."""
    return 0.0
