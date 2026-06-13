from ...ConvectionConstants import *
from ...Data.BaseData import *
from ...DataGlobals import *
from ...DataSurfaces import *
from ...EnergyPlus import *
from ...UtilityRoutines import *
from ...Construction import *
from ...CurveManager import *
from ...Data.EnergyPlusData import *
from ...DataEnvironment import *
from ...DataErrorTracking import *
from ...DataHVACGlobals import *
from ...DataHeatBalSurface import *
from ...DataHeatBalance import *
from ...DataIPShortCuts import *
from ...DataLoopNode import *
from ...DataRoomAirModel import *
from ...DataZoneEnergyDemands import *
from ...DataZoneEquipment import *
from ...General import *
from ...InputProcessing.InputProcessor import *
from ...Material import *
from ...Psychrometrics import *
from ...ScheduleManager import *
from ...SurfaceGeometry import *
from ...Vectors import *
from ...ZoneTempPredictorCorrector import *
from ...ObjexxFCL.Array import Array1D, Array1S, Optional
alias Real64 = Float64
alias bool = Bool
alias int = Int
alias std = name? # not used, but we'll keep the structure
var RoughnessMultiplier: StaticTuple[Float64, 6] = StaticTuple(2.17, 1.67, 1.52, 1.13, 1.11, 1.0)
var RefTempNamesUC: StaticTuple[String, 3] = StaticTuple("MEANAIRTEMPERATURE", "ADJACENTAIRTEMPERATURE", "SUPPLYAIRTEMPERATURE")
var RefWindNamesUC: StaticTuple[String, 4] = StaticTuple(
    "WEATHERFILE", "HEIGHTADJUST", "PARALLELCOMPONENT", "PARALLELCOMPONENTHEIGHTADJUST"
)
enum ConvSurfDeltaT:
    Invalid = -1
    Positive
    Zero
    Negative
    Num
enum InConvFlowRegime:
    Invalid = -1
    A1
    A2
    A3
    B
    C
    D
    E
    Num
struct HcIntUserCurve:
    var Name: String
    var refTempType: RefTemp = RefTemp.Invalid
    var hcFnTempDiffCurveNum: Int = 0
    var hcFnTempDiffDivHeightCurveNum: Int = 0
    var hcFnACHCurveNum: Int = 0
    var hcFnACHDivPerimLengthCurveNum: Int = 0
struct HcExtUserCurve:
    var Name: String
    var refTempType: RefTemp = RefTemp.Invalid
    var suppressRainChange: Bool = False
    var windSpeedType: RefWind = RefWind.Invalid
    var hfFnWindSpeedCurveNum: Int = 0
    var hnFnTempDiffCurveNum: Int = 0
    var hnFnTempDiffDivHeightCurveNum: Int = 0
struct IntAdaptiveConvAlgo:
    var Name: String
    var intConvClassEqNums: StaticTuple[HcInt, IntConvClass.Num.__enum_member_count__()] = StaticTuple(
        HcInt.FohannoPolidoriVerticalWall,
        HcInt.AlamdariHammondStableHorizontal,
        HcInt.AlamdariHammondUnstableHorizontal,
        HcInt.WaltonStableHorizontalOrTilt,
        HcInt.WaltonUnstableHorizontalOrTilt,
        HcInt.ISO15099Windows,
        HcInt.KhalifaEq3WallAwayFromHeat,
        HcInt.AlamdariHammondStableHorizontal,
        HcInt.KhalifaEq4CeilingAwayFromHeat,
        HcInt.AwbiHattonHeatedFloor,
        HcInt.KaradagChilledCeiling,
        HcInt.WaltonStableHorizontalOrTilt,
        HcInt.WaltonUnstableHorizontalOrTilt,
        HcInt.ISO15099Windows,
        HcInt.KhalifaEq6NonHeatedWalls,
        HcInt.AwbiHattonHeatedWall,
        HcInt.AlamdariHammondStableHorizontal,
        HcInt.KhalifaEq7Ceiling,
        HcInt.WaltonStableHorizontalOrTilt,
        HcInt.WaltonUnstableHorizontalOrTilt,
        HcInt.ISO15099Windows,
        HcInt.FohannoPolidoriVerticalWall,
        HcInt.KhalifaEq5WallNearHeat,
        HcInt.AlamdariHammondStableHorizontal,
        HcInt.KhalifaEq7Ceiling,
        HcInt.WaltonStableHorizontalOrTilt,
        HcInt.WaltonUnstableHorizontalOrTilt,
        HcInt.ISO15099Windows,
        HcInt.GoldsteinNovoselacCeilingDiffuserWalls,
        HcInt.FisherPedersenCeilDiffuserCeiling,
        HcInt.GoldsteinNovoselacCeilingDiffuserFloor,
        HcInt.GoldsteinNovoselacCeilingDiffuserWindow,
        HcInt.KhalifaEq3WallAwayFromHeat,
        HcInt.AlamdariHammondStableHorizontal,
        HcInt.KhalifaEq4CeilingAwayFromHeat,
        HcInt.WaltonStableHorizontalOrTilt,
        HcInt.WaltonUnstableHorizontalOrTilt,
        HcInt.ISO15099Windows,
        HcInt.BeausoleilMorrisonMixedAssistingWall,
        HcInt.BeausoleilMorrisonMixedOppossingWall,
        HcInt.BeausoleilMorrisonMixedStableFloor,
        HcInt.BeausoleilMorrisonMixedUnstableFloor,
        HcInt.BeausoleilMorrisonMixedStableCeiling,
        HcInt.BeausoleilMorrisonMixedUnstableCeiling,
        HcInt.GoldsteinNovoselacCeilingDiffuserWindow
    )
    var intConvClassUserCurveNums: StaticTuple[Int, IntConvClass.Num.__enum_member_count__()] = StaticTuple(
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
struct ExtAdaptiveConvAlgo:
    var Name: String
    var suppressRainChange: Bool = False
    var extConvClass2EqNums: StaticTuple[HcExt, ExtConvClass2.Num.__enum_member_count__()] = StaticTuple(
        HcExt.SparrowWindward,
        HcExt.SparrowLeeward,
        HcExt.ClearRoof,
        HcExt.NaturalASHRAEVerticalWall,
        HcExt.NaturalWaltonStableHorizontalOrTilt,
        HcExt.NaturalWaltonUnstableHorizontalOrTilt
    )
    var extConvClass2UserCurveNums: StaticTuple[Int, ExtConvClass2.Num.__enum_member_count__()] = StaticTuple(
        0, 0, 0, 0, 0, 0
    )
struct ConvectionCoefficientsData(BaseGlobalStruct):
    var GetUserSuppliedConvectionCoeffs: Bool = True
    var CubeRootOfOverallBuildingVolume: Float64 = 0.0
    var RoofLongAxisOutwardAzimuth: Float64 = 0.0
    var BMMixedAssistedWallErrorIDX1: Int = 0
    var BMMixedAssistedWallErrorIDX2: Int = 0
    var BMMixedOpposingWallErrorIDX1: Int = 0
    var BMMixedOpposingWallErrorIDX2: Int = 0
    var BMMixedStableFloorErrorIDX1: Int = 0
    var BMMixedStableFloorErrorIDX2: Int = 0
    var BMMixedUnstableFloorErrorIDX1: Int = 0
    var BMMixedUnstableFloorErrorIDX2: Int = 0
    var BMMixedStableCeilingErrorIDX1: Int = 0
    var BMMixedStableCeilingErrorIDX2: Int = 0
    var BMMixedUnstableCeilingErrorIDX1: Int = 0
    var BMMixedUnstableCeilingErrorIDX2: Int = 0
    var AHUnstableHorizontalErrorIDX: Int = 0
    var AHStableHorizontalErrorIDX: Int = 0
    var AHVerticalWallErrorIDX: Int = 0
    var CalcFohannoPolidoriVerticalWallErrorIDX: Int = 0
    var CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX1: Int = 0
    var CalcGoldsteinNovoselacCeilingDiffuserWindowErrorIDX2: Int = 0
    var CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX1: Int = 0
    var CalcGoldsteinNovoselacCeilingDiffuserWallErrorIDX2: Int = 0
    var CalcGoldsteinNovoselacCeilingDiffuserFloorErrorIDX: Int = 0
    var CalcSparrowWindwardErrorIDX: Int = 0
    var CalcSparrowLeewardErrorIDX: Int = 0
    var CalcBlockenWindwardErrorIDX: Int = 0
    var CalcClearRoofErrorIDX: Int = 0
    var CalcMitchellErrorIDX: Int = 0
    var NodeCheck: Bool = True
    var ActiveSurfaceCheck: Bool = True
    var MyEnvirnFlag: Bool = True
    var FirstRoofSurf: Bool = True
    var intAdaptiveConvAlgo: IntAdaptiveConvAlgo
    var extAdaptiveConvAlgo: ExtAdaptiveConvAlgo
    var hcIntUserCurve: Array1D[HcIntUserCurve]
    var hcExtUserCurve: Array1D[HcExtUserCurve]
    def init_constant_state(ref self, state: EnergyPlusData):

    def init_state(ref self, state: EnergyPlusData):

    def clear_state(ref self):
        self = ConvectionCoefficientsData()
def InitIntConvCoeff(
    ref state: EnergyPlusData,
    SurfaceTemperatures: Array1D[Float64],
    ZoneToResimulate: Optional[Int] = None
):

def InitExtConvCoeff(
    ref state: EnergyPlusData,
    SurfNum: Int,
    HMovInsul: Float64,
    Roughness: Material.SurfaceRoughness,
    AbsExt: Float64,
    TempExt: Float64,
    ref HExt: Float64,
    ref HSky: Float64,
    ref HGround: Float64,
    ref HAir: Float64,
    ref HSrdSurf: Float64
):

def SurroundingSurfacesRadCoeffAverage(
    ref state: EnergyPlusData,
    SurfNum: Int,
    TempExtK: Float64,
    AbsExt: Float64
) -> Float64:
    return 0.0
def CalcHfExteriorSparrow(
    SurfWindSpeed: Float64,
    GrossArea: Float64,
    Perimeter: Float64,
    CosTilt: Float64,
    Azimuth: Float64,
    Roughness: Material.SurfaceRoughness,
    WindDirection: Float64
) -> Float64:
    return 0.0
def Windward(
    CosTilt: Float64,
    Azimuth: Float64,
    WindDirection: Float64
) -> Bool:
    return True
def GetUserConvCoeffs(ref state: EnergyPlusData):

def ApplyIntConvValue(
    ref state: EnergyPlusData,
    surfNum: Int,
    model: HcInt,
    userNum: Int
):

def ApplyExtConvValue(
    ref state: EnergyPlusData,
    surfNum: Int,
    model: HcExt,
    userNum: Int
):

def ApplyIntConvValueMulti(
    ref state: EnergyPlusData,
    surfaceFilter: DataSurfaces.SurfaceFilter,
    model: HcInt,
    userNum: Int
):

def ApplyExtConvValueMulti(
    ref state: EnergyPlusData,
    surfaceFilter: DataSurfaces.SurfaceFilter,
    model: HcExt,
    userNum: Int
):

def CalcASHRAESimpExtConvCoeff(
    Roughness: Material.SurfaceRoughness,
    SurfWindSpeed: Float64
) -> Float64:
    var D: StaticTuple[Float64, 6] = StaticTuple(11.58, 12.49, 10.79, 8.23, 10.22, 8.23)
    var E: StaticTuple[Float64, 6] = StaticTuple(5.894, 4.065, 4.192, 4.00, 3.100, 3.33)
    var F: StaticTuple[Float64, 6] = StaticTuple(0.0, 0.028, 0.0, -0.057, 0.0, -0.036)
    var r = Int(Roughness)
    return D[r] + E[r] * SurfWindSpeed + F[r] * SurfWindSpeed * SurfWindSpeed
def CalcASHRAESimpleIntConvCoeff(
    Tsurf: Float64,
    Tamb: Float64,
    cosTilt: Float64
) -> Float64:
    if abs(cosTilt) < 0.3827:
        return 3.076
    var DeltaTempCosTilt = (Tamb - Tsurf) * cosTilt
    if abs(cosTilt) >= 0.9239:
        if DeltaTempCosTilt > 0.0:
            return 4.040
        elif DeltaTempCosTilt < 0.0:
            return 0.948
        else:
            return 3.076
    else:
        if DeltaTempCosTilt > 0.0:
            return 3.870
        elif DeltaTempCosTilt < 0.0:
            return 2.281
        else:
            return 3.076
def CalcASHRAESimpleIntConvCoeff(
    ref state: EnergyPlusData,
    SurfNum: Int,
    SurfaceTemperature: Float64,
    ZoneMeanAirTemperature: Float64
):

def CalcASHRAETARPNatural(
    Tsurf: Float64,
    Tamb: Float64,
    cosTilt: Float64
) -> Float64:
    var DeltaTemp = Tsurf - Tamb
    if (DeltaTemp == 0.0) or (cosTilt == 0.0):
        return CalcASHRAEVerticalWall(DeltaTemp)
    if ((DeltaTemp < 0.0) and (cosTilt < 0.0)) or ((DeltaTemp > 0.0) and (cosTilt > 0.0)):
        return CalcWaltonUnstableHorizontalOrTilt(DeltaTemp, cosTilt)
    return CalcWaltonStableHorizontalOrTilt(DeltaTemp, cosTilt)
def CalcASHRAEDetailedIntConvCoeff(
    ref state: EnergyPlusData,
    SurfNum: Int,
    SurfaceTemperature: Float64,
    ZoneMeanAirTemperature: Float64
):

def CalcDetailedHcInForDVModel(
    ref state: EnergyPlusData,
    SurfNum: Int,
    SurfaceTemperatures: Array1D[Float64],
    ref HcIn: Array1D[Float64],
    Vhc: Optional[Array1S[Float64]] = None
):

def CalcZoneSupplyAirTemp(ref state: EnergyPlusData, ZoneNum: Int) -> Float64: return 0.0
def CalcZoneSystemVolFlowRate(ref state: EnergyPlusData, ZoneNum: Int) -> Float64: return 0.0
def CalcZoneSystemACH(ref state: EnergyPlusData, ZoneNum: Int) -> Float64: return 0.0
def CalcCeilingDiffuserACH(ref state: EnergyPlusData, ZoneNum: Int) -> Float64: return 0.0
def CalcCeilingDiffuserIntConvCoeff(
    ref state: EnergyPlusData,
    ACH: Float64,
    Tsurf: Float64,
    Tair: Float64,
    cosTilt: Float64,
    humRat: Float64,
    height: Float64,
    isWindow: Bool = False
) -> Float64:
    return 0.0
def CalcCeilingDiffuserIntConvCoeff(
    ref state: EnergyPlusData,
    ZoneNum: Int,
    SurfaceTemperatures: Array1D[Float64]
):

def CalcCeilingDiffuserInletCorr(
    ref state: EnergyPlusData,
    ZoneNum: Int,
    SurfaceTemperatures: Array1S[Float64]
):

def CalcTrombeWallIntConvCoeff(
    ref state: EnergyPlusData,
    ZoneNum: Int,
    SurfaceTemperatures: Array1D[Float64]
):

def CalcNusselt(
    ref state: EnergyPlusData,
    SurfNum: Int,
    asp: Float64,
    tso: Float64,
    tsi: Float64,
    gr: Float64,
    pr: Float64
) -> Float64:
    return 0.0
def SetExtConvCoeff(ref state: EnergyPlusData, SurfNum: Int) -> Float64: return 0.0
def SetIntConvCoeff(ref state: EnergyPlusData, SurfNum: Int) -> Float64: return 0.0
def CalcISO15099WindowIntConvCoeff(
    ref state: EnergyPlusData,
    SurfaceTemperature: Float64,
    AirTemperature: Float64,
    AirHumRat: Float64,
    Height: Float64,
    TiltDeg: Float64,
    sineTilt: Float64
) -> Float64:
    return 0.0
def CalcISO15099WindowIntConvCoeff(
    ref state: EnergyPlusData,
    SurfNum: Int,
    SurfaceTemperature: Float64,
    AirTemperature: Float64
):

def SetupAdaptiveConvStaticMetaData(ref state: EnergyPlusData): pass
def SetupAdaptiveConvRadiantSurfaceData(ref state: EnergyPlusData): pass
def ManageIntAdaptiveConvAlgo(ref state: EnergyPlusData, SurfNum: Int): pass
def ManageExtAdaptiveConvAlgo(ref state: EnergyPlusData, SurfNum: Int) -> Float64: return 0.0
def EvaluateIntHcModels(ref state: EnergyPlusData, SurfNum: Int, ConvModelEquationNum: HcInt) -> Float64: return 0.0
def EvaluateExtHcModels(ref state: EnergyPlusData, SurfNum: Int, NaturalConvModelEqNum: HcExt, ForcedConvModelEqNum: HcExt) -> Float64: return 0.0
def DynamicExtConvSurfaceClassification(ref state: EnergyPlusData, SurfNum: Int): pass
def MapExtConvClassToHcModels(ref state: EnergyPlusData, SurfNum: Int): pass
def DynamicIntConvSurfaceClassification(ref state: EnergyPlusData, SurfNum: Int): pass
def MapIntConvClassToHcModels(ref state: EnergyPlusData, SurfNum: Int): pass
def CalcUserDefinedIntHcModel(ref state: EnergyPlusData, SurfNum: Int, UserCurveNum: Int) -> Float64: return 0.0
def CalcUserDefinedExtHcModel(ref state: EnergyPlusData, SurfNum: Int, UserCurveNum: Int) -> Float64: return 0.0
def ShowWarningHydraulicDiameterZero(ref state: EnergyPlusData, ref errorIdx: Int, eoh: ErrorObjectHeader): pass
def ShowWarningDeltaTempZero(ref state: EnergyPlusData, ref errorIdx: Int, eoh: ErrorObjectHeader): pass
def ShowWarningWindowLocation(ref state: EnergyPlusData, ref errorIdx: Int, eoh: ErrorObjectHeader, winLoc: IntConvWinLoc): pass
def ShowWarningPerimeterLengthZero(ref state: EnergyPlusData, ref errorIdx: Int, eoh: ErrorObjectHeader): pass
def ShowWarningFaceAreaZero(ref state: EnergyPlusData, ref errorIdx: Int, eoh: ErrorObjectHeader): pass
def CalcASHRAEVerticalWall(DeltaTemp: Float64) -> Float64:
    return 1.31 * pow(abs(DeltaTemp), 1.0/3.0)
def CalcWaltonUnstableHorizontalOrTilt(DeltaTemp: Float64, CosineTilt: Float64) -> Float64:
    return 9.482 * pow(abs(DeltaTemp), 1.0/3.0) / (7.238 - abs(CosineTilt))
def CalcWaltonStableHorizontalOrTilt(DeltaTemp: Float64, CosineTilt: Float64) -> Float64:
    return 1.810 * pow(abs(DeltaTemp), 1.0/3.0) / (1.382 + abs(CosineTilt))
def CalcFisherPedersenCeilDiffuserFloor(
    ref state: EnergyPlusData,
    ACH: Float64,
    Tsurf: Float64,
    Tair: Float64,
    cosTilt: Float64,
    humRat: Float64,
    height: Float64,
    isWindow: Bool = False
) -> Float64:
    return 0.0
def CalcFisherPedersenCeilDiffuserCeiling(
    ref state: EnergyPlusData,
    ACH: Float64,
    Tsurf: Float64,
    Tair: Float64,
    cosTilt: Float64,
    humRat: Float64,
    height: Float64,
    isWindow: Bool = False
) -> Float64:
    return 0.0
def CalcFisherPedersenCeilDiffuserWalls(
    ref state: EnergyPlusData,
    ACH: Float64,
    Tsurf: Float64,
    Tair: Float64,
    cosTilt: Float64,
    humRat: Float64,
    height: Float64,
    isWindow: Bool = False
) -> Float64:
    return 0.0
def CalcFisherPedersenCeilDiffuserNatConv(
    ref state: EnergyPlusData,
    Hforced: Float64,
    ACH: Float64,
    Tsurf: Float64,
    Tair: Float64,
    cosTilt: Float64,
    humRat: Float64,
    height: Float64,
    isWindow: Bool
) -> Float64:
    return 0.0
def CalcAlamdariHammondUnstableHorizontal(
    DeltaTemp: Float64,
    HydraulicDiameter: Float64
) -> Float64:
    return pow(pow__6(1.4 * pow(abs(DeltaTemp) / HydraulicDiameter, 0.25)) + (1.63 * DeltaTemp * DeltaTemp), 1.0/6.0)
def CalcAlamdariHammondUnstableHorizontal(
    ref state: EnergyPlusData,
    DeltaTemp: Float64,
    HydraulicDiameter: Float64,
    SurfNum: Int
) -> Float64:
    if HydraulicDiameter > 0.0:
        return CalcAlamdariHammondUnstableHorizontal(DeltaTemp, HydraulicDiameter)
    var routineName = "CalcAlamdariHammondUnstableHorizontal"
    var eoh = ErrorObjectHeader(routineName, "Surface", state.dataSurface.Surface[SurfNum].Name)
    ShowWarningHydraulicDiameterZero(state, state.dataConvect.AHUnstableHorizontalErrorIDX, eoh)
    return 9.999
def CalcAlamdariHammondStableHorizontal(
    DeltaTemp: Float64,
    HydraulicDiameter: Float64
) -> Float64:
    return 0.6 * pow(abs(DeltaTemp) / (HydraulicDiameter * HydraulicDiameter), 0.2)
def CalcAlamdariHammondStableHorizontal(
    ref state: EnergyPlusData,
    DeltaTemp: Float64,
    HydraulicDiameter: Float64,
    SurfNum: Int
) -> Float64:
    if HydraulicDiameter > 0.0:
        return CalcAlamdariHammondStableHorizontal(DeltaTemp, HydraulicDiameter)
    var routineName = "CalcAlamdariHammondStableHorizontal"
    var eoh = ErrorObjectHeader(routineName, "Surface", state.dataSurface.Surface[SurfNum].Name)
    ShowWarningHydraulicDiameterZero(state, state.dataConvect.AHStableHorizontalErrorIDX, eoh)
    if DeltaTemp == 0.0 and not state.dataGlobal.WarmupFlag:
        ShowWarningDeltaTempZero(state, state.dataConvect.BMMixedAssistedWallErrorIDX1, eoh)
    return 9.999
def CalcAlamdariHammondVerticalWall(
    DeltaTemp: Float64,
    Height: Float64
) -> Float64:
    return pow(pow__6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + (1.23 * DeltaTemp * DeltaTemp), 1.0/6.0)
def CalcAlamdariHammondVerticalWall(
    ref state: EnergyPlusData,
    DeltaTemp: Float64,
    Height: Float64,
    SurfNum: Int
) -> Float64:
    if Height > 0.0:
        return CalcAlamdariHammondVerticalWall(DeltaTemp, Height)
    var routineName = "CalcAlamdariHammondVerticalWall"
    var eoh = ErrorObjectHeader(routineName, "Surface", state.dataSurface.Surface[SurfNum].Name)
    ShowWarningHydraulicDiameterZero(state, state.dataConvect.AHVerticalWallErrorIDX, eoh)
    return 9.999
def CalcKhalifaEq3WallAwayFromHeat(DeltaTemp: Float64) -> Float64:
    return 2.07 * pow(abs(DeltaTemp), 0.23)
def CalcKhalifaEq4CeilingAwayFromHeat(DeltaTemp: Float64) -> Float64:
    return 2.72 * pow(abs(DeltaTemp), 0.13)
def CalcKhalifaEq5WallsNearHeat(DeltaTemp: Float64) -> Float64:
    return 1.98 * pow(abs(DeltaTemp), 0.32)
def CalcKhalifaEq6NonHeatedWalls(DeltaTemp: Float64) -> Float64:
    return 2.30 * pow(abs(DeltaTemp), 0.24)
def CalcKhalifaEq7Ceiling(DeltaTemp: Float64) -> Float64:
    return 3.10 * pow(abs(DeltaTemp), 0.17)
def CalcAwbiHattonHeatedFloor(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    if HydraulicDiameter > 1.0:
        return 2.175 * pow(abs(DeltaTemp), 0.308) / pow(HydraulicDiameter, 0.076)
    var pow_fac = 2.175 / pow(1.0, 0.076)
    return pow_fac * pow(abs(DeltaTemp), 0.308)
def CalcAwbiHattonHeatedWall(DeltaTemp: Float64, HydraulicDiameter: Float64) -> Float64:
    return 1.823 * pow(abs(DeltaTemp), 0.293) / pow(max(HydraulicDiameter, 1.0), 0.121)
def CalcBeausoleilMorrisonMixedAssistedWall(
    DeltaTemp: Float64,
    Height: Float64,
    SurfTemp: Float64,
    SupplyAirTemp: Float64,
    AirChangeRate: Float64
) -> Float64:
    var cofpow = sqrt(pow__6(1.5 * pow(abs(DeltaTemp) / Height, 0.25)) + pow(1.23 * DeltaTemp * DeltaTemp, 1.0/6.0)) + pow__3(((SurfTemp - SupplyAirTemp) / abs(DeltaTemp)) * (-0.199 + 0.190 * pow(AirChangeRate, 0.8)))
    var Hc = pow(abs(cofpow), 1.0/3.0)
    if cofpow < 0.0:
        Hc = -Hc
    return Hc
def CalcBeausoleilMorrisonMixedAssistedWall(
    ref state: EnergyPlusData,
    DeltaTemp: Float64,
    Height: Float64,
    SurfTemp: Float64,
    ZoneNum: Int
) -> Float64:
    if (abs(DeltaTemp) > HVAC.SmallTempDiff) and (Height != 0.0):
        var SupplyAirTemp = CalcZoneSupplyAirTemp(state, ZoneNum)
        var AirChangeRate = CalcZoneSystemACH(state, ZoneNum)
        return CalcBeausoleilMorrisonMixedAssistedWall(DeltaTemp, Height, SurfTemp, SupplyAirTemp, AirChangeRate)
    var routineName = "CalcBeausoleilMorrisonMixedAssistedWall"
    var eoh = ErrorObjectHeader(routineName, "Zone", state.dataHeatBal.Zone[ZoneNum].Name)
    if Height == 0.0:
        ShowWarningHydraulicDiameterZero(state, state.dataConvect.BMMixedAssistedWallErrorIDX2, eoh)
    if DeltaTemp == 0.0 and not state.dataGlobal.WarmupFlag:
        ShowWarningDeltaTempZero(state, state.dataConvect.BMMixedAssistedWallErrorIDX1, eoh)
    return 9.999