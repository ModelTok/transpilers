from DataBSDFWindow import (
    BasisElemDescr, BasisStruct, BSDFDaylghtPosition, BSDFGeomDescr, BSDFStateDescr,
    BSDFWindowGeomDescr, BSDFWindowInputStruct, Basis, BasisSymmetry, Condition
)
from DataVectorTypes import Vector
from DataSurfaces import SurfaceClass, WindowModel, WinShadingType, WindowAirFlowDestination, WindowAirFlowSource
from DataHeatBalance import ANY_INTERIOR_SHADE_BLIND
from DataShadowingCombinations import ShadowComb
from DataEnvironment import SunIsUpValue
from DataSystemVariables import DetailedSolarTimestepIntegration
from DataGlobal import TimeStepsInHour, HourOfDay, TimeStep, KickOffSizing, KickOffSimulation
from DataConstruction import Construct
from DataMaterial import Material, MaterialGlass, MaterialComplexShade, MaterialComplexWindowGap, gases, GasType
from DataHeatBalSurface import SurfHConvInt, SurfQdotRadHVACInPerArea
from DataViewFactorInformation import EnclRadInfo
from DataZoneEquipment import ZoneHeatBalance
from DataLoopNode import ...
from DataZoneTempPredictorCorrector import zoneHeatBalance
from PierceSurface import PierceSurface
from Psychrometrics import PsyCpAirFnW, PsyTdpFnWPb
from ScheduleManager import ...
from TARCOGMain import TARCOG90
from TARCOGParams import TARCOGLayerType, DeflectionCalculation, TARCOGThermalModel, maxlay, maxlay1
from TARCOGGassesParams import maxgas, Stdrd
from UtilityRoutines import ShowFatalError, ShowWarningError, ShowSevereError, ShowContinueError, ShowContinueErrorTimeStamp, format
from Vectors import dot, magnitude, magnitude_squared, pow_2, root_4
from math import abs, sqrt, sin, cos, atan, asin, atan2, floor, pow, min, max, sum
from stdlib import DynamicVector, List, Int32, Int64, Float64, Bool, String, print

# Constants
const sigma: Float64 = 5.6697e-8
const PressureDefault: Float64 = 101325.0
const Calculate_Geometry: Int32 = 1
const Copy_Geometry: Int32 = 2
const TmpLen: Int32 = 20

# Global constants (from Constant namespace)
const Pi: Float64 = 3.141592653589793
const PiOvr2: Float64 = Pi / 2.0
const DegToRad: Float64 = Pi / 180.0
const Kelvin: Float64 = 273.15
const StefanBoltzmann: Float64 = 5.6697e-8
const rTinyValue: Float64 = 1.0e-10

# Enums
enum RayIdentificationType: Int32 {
    Invalid = -1
    Front_Incident
    Front_Transmitted
    Front_Reflected
    Back_Incident
    Back_Transmitted
    Back_Reflected
    Num
}

# Structs
struct WindowIndex:
    var NumStates: Int32
    var SurfNo: Int32
    def __init__(inout self):
        self.NumStates = 0
        self.SurfNo = 0

struct WindowStateIndex:
    var InitInc: Int32 = 0
    var IncBasisIndx: Int32 = 0
    var CopyIncState: Int32 = 0
    var InitTrn: Int32 = 0
    var TrnBasisIndx: Int32 = 0
    var CopyTrnState: Int32 = 0
    var Konst: Int32 = 0

struct TempBasisIdx:
    var Basis: Int32
    var State: Int32
    def __init__(inout self):
        self.Basis = 0
        self.State = 0

struct BackHitList:
    var KBkSurf: Int32
    var HitSurf: Int32
    var HitPt: Vector
    var HitDsq: Float64
    def __init__(inout self):
        self.KBkSurf = 0
        self.HitSurf = 0
        self.HitPt = Vector(0.0, 0.0, 0.0)
        self.HitDsq = 0.0

# Data structure (WindowComplexManagerData)
struct WindowComplexManagerData:
    var sigma: Float64
    var PressureDefault: Float64
    var Calculate_Geometry: Int32
    var Copy_Geometry: Int32
    var TmpLen: Int32
    var NumComplexWind: Int32
    var BasisList: DynamicVector[BasisStruct]
    var WindowList: DynamicVector[WindowIndex]
    var WindowStateList: DynamicVector[DynamicVector[WindowStateIndex]]
    var InitComplexWindowsOnce: Bool
    var InitBSDFWindowsOnce: Bool
    var NumBasis: Int32
    var MatrixNo: Int32
    var gap: DynamicVector[Float64]
    var thick: DynamicVector[Float64]
    var scon: DynamicVector[Float64]
    var tir: DynamicVector[Float64]
    var emis: DynamicVector[Float64]
    var SupportPlr: DynamicVector[Int32]
    var PillarSpacing: DynamicVector[Float64]
    var PillarRadius: DynamicVector[Float64]
    var asol: DynamicVector[Float64]
    var presure: DynamicVector[Float64]
    var GapDefMax: DynamicVector[Float64]
    var YoungsMod: DynamicVector[Float64]
    var PoissonsRat: DynamicVector[Float64]
    var LayerDef: DynamicVector[Float64]
    var iprop: DynamicVector[DynamicVector[Int32]]
    var frct: DynamicVector[DynamicVector[Float64]]
    var gcon: DynamicVector[DynamicVector[Float64]]
    var gvis: DynamicVector[DynamicVector[Float64]]
    var gcp: DynamicVector[DynamicVector[Float64]]
    var wght: DynamicVector[Float64]
    var gama: DynamicVector[Float64]
    var nmix: DynamicVector[Int32]
    var ibc: DynamicVector[Int32]
    var Atop: DynamicVector[Float64]
    var Abot: DynamicVector[Float64]
    var Al: DynamicVector[Float64]
    var Ar: DynamicVector[Float64]
    var Ah: DynamicVector[Float64]
    var SlatThick: DynamicVector[Float64]
    var SlatWidth: DynamicVector[Float64]
    var SlatAngle: DynamicVector[Float64]
    var SlatCond: DynamicVector[Float64]
    var SlatSpacing: DynamicVector[Float64]
    var SlatCurve: DynamicVector[Float64]
    var vvent: DynamicVector[Float64]
    var tvent: DynamicVector[Float64]
    var LayerType: DynamicVector[TARCOGLayerType]
    var nslice: DynamicVector[Int32]
    var LaminateA: DynamicVector[Float64]
    var LaminateB: DynamicVector[Float64]
    var sumsol: DynamicVector[Float64]
    var theta: DynamicVector[Float64]
    var q: DynamicVector[Float64]
    var qprim: DynamicVector[Float64]
    var qv: DynamicVector[Float64]
    var hcgap: DynamicVector[Float64]
    var hrgap: DynamicVector[Float64]
    var hg: DynamicVector[Float64]
    var hr: DynamicVector[Float64]
    var hs: DynamicVector[Float64]
    var Ra: DynamicVector[Float64]
    var Nu: DynamicVector[Float64]
    var Keff: DynamicVector[Float64]
    var ShadeGapKeffConv: DynamicVector[Float64]
    var deltaTemp: DynamicVector[Float64]
    var iMinDT: DynamicVector[Int32]
    var IDConst: DynamicVector[Int32]

    def __init__(inout self):
        self.sigma = 5.6697e-8
        self.PressureDefault = 101325.0
        self.Calculate_Geometry = 1
        self.Copy_Geometry = 2
        self.TmpLen = 20
        self.NumComplexWind = 0
        self.NumBasis = 0
        self.MatrixNo = 0
        self.InitComplexWindowsOnce = True
        self.InitBSDFWindowsOnce = True
        # Initialize arrays with default sizes (maxlay, maxlay+1, etc.)
        self.gap = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.thick = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.scon = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.tir = DynamicVector[Float64](TARCOGParams.maxlay * 2, 0.0)
        self.emis = DynamicVector[Float64](TARCOGParams.maxlay * 2, 0.0)
        self.SupportPlr = DynamicVector[Int32](TARCOGParams.maxlay, 0)
        self.PillarSpacing = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.PillarRadius = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.asol = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.presure = DynamicVector[Float64](TARCOGParams.maxlay + 1, 0.0)
        self.GapDefMax = DynamicVector[Float64](TARCOGParams.maxlay - 1, 0.0)
        self.YoungsMod = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.PoissonsRat = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.LayerDef = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.iprop = DynamicVector[DynamicVector[Int32]](TARCOGParams.maxlay + 1)
        for i in range(TARCOGParams.maxlay + 1):
            self.iprop[i] = DynamicVector[Int32](TARCOGGassesParams.maxgas, 1)
        self.frct = DynamicVector[DynamicVector[Float64]](TARCOGParams.maxlay + 1)
        for i in range(TARCOGParams.maxlay + 1):
            self.frct[i] = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.gcon = DynamicVector[DynamicVector[Float64]](3)
        for i in range(3):
            self.gcon[i] = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.gvis = DynamicVector[DynamicVector[Float64]](3)
        for i in range(3):
            self.gvis[i] = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.gcp = DynamicVector[DynamicVector[Float64]](3)
        for i in range(3):
            self.gcp[i] = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.wght = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.gama = DynamicVector[Float64](TARCOGGassesParams.maxgas, 0.0)
        self.nmix = DynamicVector[Int32](TARCOGParams.maxlay + 1, 0)
        self.ibc = DynamicVector[Int32](2, 0)
        self.Atop = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.Abot = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.Al = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.Ar = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.Ah = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatThick = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatWidth = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatAngle = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatCond = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatSpacing = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.SlatCurve = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.vvent = DynamicVector[Float64](TARCOGParams.maxlay + 1, 0.0)
        self.tvent = DynamicVector[Float64](TARCOGParams.maxlay + 1, 0.0)
        self.LayerType = DynamicVector[TARCOGLayerType](TARCOGParams.maxlay, TARCOGLayerType.SPECULAR)
        self.nslice = DynamicVector[Int32](TARCOGParams.maxlay, 0)
        self.LaminateA = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.LaminateB = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.sumsol = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.theta = DynamicVector[Float64](TARCOGParams.maxlay * 2, 0.0)
        self.q = DynamicVector[Float64](TARCOGParams.maxlay * 2 + 1, 0.0)
        self.qprim = DynamicVector[Float64](TARCOGParams.maxlay1, 0.0)
        self.qv = DynamicVector[Float64](TARCOGParams.maxlay1, 0.0)
        self.hcgap = DynamicVector[Float64](TARCOGParams.maxlay1, 0.0)
        self.hrgap = DynamicVector[Float64](TARCOGParams.maxlay1, 0.0)
        self.hg = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.hr = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.hs = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.Ra = DynamicVector[Float64](TARCOGParams.maxlay + 1, 0.0)
        self.Nu = DynamicVector[Float64](TARCOGParams.maxlay + 1, 0.0)
        self.Keff = DynamicVector[Float64](TARCOGParams.maxlay, 0.0)
        self.ShadeGapKeffConv = DynamicVector[Float64](TARCOGParams.maxlay - 1, 0.0)
        self.deltaTemp = DynamicVector[Float64](100, 0.0)
        self.iMinDT = DynamicVector[Int32](1, 0)
        self.IDConst = DynamicVector[Int32](100, 0)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumComplexWind = 0
        self.BasisList = DynamicVector[BasisStruct]()
        self.WindowList = DynamicVector[WindowIndex]()
        self.WindowStateList = DynamicVector[DynamicVector[WindowStateIndex]]()
        self.InitComplexWindowsOnce = True
        self.InitBSDFWindowsOnce = True
        self.NumBasis = 0
        self.MatrixNo = 0
        self.LayerType = DynamicVector[TARCOGLayerType](TARCOGParams.maxlay, TARCOGLayerType.SPECULAR)

# Helper functions for linear indexing (since arrays are 0-based but original used 1-based multi-dim)
def linear_index_2d(hour: Int32, ts: Int32, nTS: Int32) -> Int32:
    return (hour - 1) * nTS + (ts - 1)

def linear_index_3d(hour: Int32, ts: Int32, i: Int32, nTS: Int32) -> Int32:
    return ((hour - 1) * nTS + (ts - 1)) * (some_dim) + (i - 1)  # need dim info

# We'll implement the functions as methods on a module-level struct or as free functions.
# For simplicity, we'll define them as free functions in the module.

def InitBSDFWindows(inout state: EnergyPlusData):
    using Vectors
    var BaseSurf: Int32
    var NumStates: Int32
    var Thetas: DynamicVector[Float64]
    var NPhis: DynamicVector[Int32]
    var V: DynamicVector[Float64] = DynamicVector[Float64](3, 0.0)
    var VLen: Float64
    var NHold: Int32
    var IHold: DynamicVector[TempBasisIdx]

    if state.dataBSDFWindow.TotComplexFenStates <= 0:
        return

    state.dataWindowComplexManager.BasisList = DynamicVector[BasisStruct](state.dataBSDFWindow.TotComplexFenStates)
    for IConst in range(state.dataBSDFWindow.FirstBSDF, state.dataBSDFWindow.FirstBSDF + state.dataBSDFWindow.TotComplexFenStates):
        state.dataWindowComplexManager.MatrixNo = state.dataConstruction.Construct[IConst].BSDFInput.BasisMatIndex
        if state.dataWindowComplexManager.NumBasis == 0:
            state.dataWindowComplexManager.NumBasis = 1
            ConstructBasis(state, IConst, state.dataWindowComplexManager.BasisList[0])
        else:
            var found: Bool = False
            for IBasis in range(state.dataWindowComplexManager.NumBasis):
                if state.dataWindowComplexManager.MatrixNo == state.dataWindowComplexManager.BasisList[IBasis].BasisMatIndex:
                    found = True
                    break
            if not found:
                state.dataWindowComplexManager.NumBasis += 1
                ConstructBasis(state, IConst, state.dataWindowComplexManager.BasisList[state.dataWindowComplexManager.NumBasis - 1])

    state.dataWindowComplexManager.BasisList = state.dataWindowComplexManager.BasisList[:state.dataWindowComplexManager.NumBasis]
    state.dataBSDFWindow.ComplexWind = DynamicVector[BSDFWindowGeomDescr](state.dataSurface.TotSurfaces)
    state.dataWindowComplexManager.WindowList = DynamicVector[WindowIndex](state.dataSurface.TotSurfaces)
    state.dataWindowComplexManager.WindowStateList = DynamicVector[DynamicVector[WindowStateIndex]](state.dataBSDFWindow.TotComplexFenStates)
    for i in range(state.dataBSDFWindow.TotComplexFenStates):
        state.dataWindowComplexManager.WindowStateList[i] = DynamicVector[WindowStateIndex](state.dataSurface.TotSurfaces)

    for ISurf in range(1, state.dataSurface.TotSurfaces + 1):
        var IConst: Int32 = state.dataSurface.Surface[ISurf - 1].Construction
        if IConst == 0:
            continue
        if not (state.dataConstruction.Construct[IConst - 1].TypeIsWindow and state.dataConstruction.Construct[IConst - 1].WindowTypeBSDF):
            continue
        state.dataSurface.SurfWinWindowModelType[ISurf - 1] = WindowModel.BSDF
        state.dataHeatBal.AnyBSDF = True
        state.dataWindowComplexManager.NumComplexWind += 1
        NumStates = 1
        state.dataWindowComplexManager.WindowList[state.dataWindowComplexManager.NumComplexWind - 1].NumStates = 1
        state.dataWindowComplexManager.WindowList[state.dataWindowComplexManager.NumComplexWind - 1].SurfNo = ISurf
        state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitInc = state.dataWindowComplexManager.Calculate_Geometry
        state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitTrn = state.dataWindowComplexManager.Calculate_Geometry
        state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyIncState = 0
        state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyTrnState = 0
        state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].Konst = IConst
        for I in range(state.dataWindowComplexManager.NumBasis):
            if state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMatIndex == state.dataWindowComplexManager.BasisList[I].BasisMatIndex:
                state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].IncBasisIndx = I + 1
                state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].TrnBasisIndx = I + 1
        if state.dataWindowComplexManager.WindowStateList[NumStates - 1][state.dataWindowComplexManager.NumComplexWind - 1].IncBasisIndx <= 0:
            ShowFatalError(state, "Complex Window Init: Window Basis not in BasisList.")

    for IWind in range(1, state.dataWindowComplexManager.NumComplexWind + 1):
        if state.dataWindowComplexManager.WindowList[IWind - 1].NumStates > 1:
            IHold = DynamicVector[TempBasisIdx](state.dataWindowComplexManager.WindowList[IWind - 1].NumStates)
            NHold = 1
            IHold[0].State = 1
            IHold[0].Basis = state.dataWindowComplexManager.WindowStateList[0][IWind - 1].IncBasisIndx
            for K in range(state.dataWindowComplexManager.NumBasis):
                if K + 1 > NHold:
                    break
                var KBasis: Int32 = IHold[K].Basis
                var J: Int32 = IHold[K].State
                state.dataWindowComplexManager.InitBSDFWindowsOnce = True
                for I in range(J + 1, state.dataWindowComplexManager.WindowList[IWind - 1].NumStates + 1):
                    if (state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitInc == state.dataWindowComplexManager.Calculate_Geometry) and (state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].IncBasisIndx == KBasis):
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitInc = state.dataWindowComplexManager.Copy_Geometry
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitTrn = state.dataWindowComplexManager.Copy_Geometry
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyIncState = J
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyTrnState = J
                    elif state.dataWindowComplexManager.InitBSDFWindowsOnce:
                        state.dataWindowComplexManager.InitBSDFWindowsOnce = False
                        NHold += 1
                        IHold[NHold - 1].State = I
                        IHold[NHold - 1].Basis = state.dataWindowComplexManager.WindowStateList[I - 1][IWind - 1].IncBasisIndx
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].InitTrn = state.dataWindowComplexManager.Calculate_Geometry
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyIncState = 0
                        state.dataWindowComplexManager.WindowStateList[I - 1][state.dataWindowComplexManager.NumComplexWind - 1].CopyTrnState = 0
            IHold = DynamicVector[TempBasisIdx]()

    for IWind in range(1, state.dataWindowComplexManager.NumComplexWind + 1):
        var ISurf: Int32 = state.dataWindowComplexManager.WindowList[IWind - 1].SurfNo
        NumStates = state.dataWindowComplexManager.WindowList[IWind - 1].NumStates
        state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.NumStates = NumStates
        state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State = DynamicVector[BSDFStateDescr](NumStates)
        state.dataBSDFWindow.ComplexWind[ISurf - 1].NumStates = NumStates
        state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom = DynamicVector[BSDFGeomDescr](NumStates)
        BaseSurf = state.dataSurface.Surface[ISurf - 1].BaseSurf
        var NBkSurf: Int32 = state.dataShadowComb.ShadowComb[BaseSurf - 1].NumBackSurf
        state.dataBSDFWindow.ComplexWind[ISurf - 1].NBkSurf = NBkSurf
        state.dataBSDFWindow.ComplexWind[ISurf - 1].sWinSurf = DynamicVector[Vector](NBkSurf)
        state.dataBSDFWindow.ComplexWind[ISurf - 1].sdotN = DynamicVector[Float64](NBkSurf)
        for KBkSurf in range(1, NBkSurf + 1):
            BaseSurf = state.dataSurface.Surface[ISurf - 1].BaseSurf
            var JSurf: Int32 = state.dataShadowComb.ShadowComb[BaseSurf - 1].BackSurf[KBkSurf - 1]
            V[0] = state.dataSurface.Surface[JSurf - 1].Centroid.x - state.dataSurface.Surface[ISurf - 1].Centroid.x
            V[1] = state.dataSurface.Surface[JSurf - 1].Centroid.y - state.dataSurface.Surface[ISurf - 1].Centroid.y
            V[2] = state.dataSurface.Surface[JSurf - 1].Centroid.z - state.dataSurface.Surface[ISurf - 1].Centroid.z
            VLen = magnitude(V)
            state.dataBSDFWindow.ComplexWind[ISurf - 1].sWinSurf[KBkSurf - 1] = Vector(V[0]/VLen, V[1]/VLen, V[2]/VLen)
            state.dataBSDFWindow.ComplexWind[ISurf - 1].sdotN[KBkSurf - 1] = dot(V, state.dataSurface.Surface[JSurf - 1].OutNormVec) / VLen
        for IState in range(1, NumStates + 1):
            var IConst: Int32 = state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].Konst
            state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1].Konst = IConst
            if state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].InitInc == state.dataWindowComplexManager.Calculate_Geometry:
                state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1].Inc = state.dataWindowComplexManager.BasisList[state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].IncBasisIndx - 1]
                state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1].Trn = state.dataWindowComplexManager.BasisList[state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].TrnBasisIndx - 1]
                SetupComplexWindowStateGeometry(state, ISurf, IState, IConst, state.dataBSDFWindow.ComplexWind[ISurf - 1], state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1], state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1])
            else:
                state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1] = state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].CopyIncState - 1]
                state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1].Konst = IConst
                state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1] = state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].CopyIncState - 1]

    for IWind in range(1, state.dataWindowComplexManager.NumComplexWind + 1):
        var ISurf: Int32 = state.dataWindowComplexManager.WindowList[IWind - 1].SurfNo
        NumStates = state.dataWindowComplexManager.WindowList[IWind - 1].NumStates
        for IState in range(1, NumStates + 1):
            AllocateCFSStateHourlyData(state, ISurf, IState)

def AllocateCFSStateHourlyData(inout state: EnergyPlusData, iSurf: Int32, iState: Int32):
    var NLayers: Int32 = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].NLayers
    var NBkSurf: Int32 = state.dataBSDFWindow.ComplexWind[iSurf - 1].NBkSurf
    var nTS: Int32 = state.dataGlobal.TimeStepsInHour
    state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[iState - 1].SolBmGndWt = DynamicVector[Float64](24 * nTS * state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[iState - 1].NGnd)
    state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[iState - 1].SolBmIndex = DynamicVector[Int32](24 * nTS)
    state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[iState - 1].ThetaBm = DynamicVector[Float64](24 * nTS)
    state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[iState - 1].PhiBm = DynamicVector[Float64](24 * nTS)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinDirHemiTrans = DynamicVector[Float64](24 * nTS)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinDirSpecTrans = DynamicVector[Float64](24 * nTS)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinBmGndTrans = DynamicVector[Float64](24 * nTS)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinBmFtAbs = DynamicVector[Float64](24 * nTS * NLayers)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinBmGndAbs = DynamicVector[Float64](24 * nTS * NLayers)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].WinToSurfBmTrans = DynamicVector[Float64](24 * nTS * NBkSurf)
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].BkSurf = DynamicVector[BSDFBackSurfState](NBkSurf)
    for KBkSurf in range(1, NBkSurf + 1):
        state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].BkSurf[KBkSurf - 1].WinDHBkRefl = DynamicVector[Float64](24 * nTS)
        state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1].BkSurf[KBkSurf - 1].WinDirBkAbs = DynamicVector[Float64](24 * nTS * NLayers)

def ExpandComplexState(inout state: EnergyPlusData, iSurf: Int32, iConst: Int32):
    var NumOfStates: Int32 = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.NumStates
    state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom = state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[:NumOfStates + 1]
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[:NumOfStates + 1]
    if state.dataBSDFWindow.ComplexWind[iSurf - 1].DaylightingInitialized:
        state.dataBSDFWindow.ComplexWind[iSurf - 1].DaylghtGeom = state.dataBSDFWindow.ComplexWind[iSurf - 1].DaylghtGeom[:NumOfStates + 1]
        state.dataBSDFWindow.ComplexWind[iSurf - 1].DaylightingInitialized = False
    else:
        state.dataBSDFWindow.ComplexWind[iSurf - 1].DaylghtGeom = DynamicVector[BSDFDaylghtGeomDescr](NumOfStates + 1)
    NumOfStates += 1
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.NumStates = NumOfStates
    state.dataBSDFWindow.ComplexWind[iSurf - 1].NumStates = NumOfStates
    state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[NumOfStates - 1].Konst = iConst
    ConstructBasis(state, iConst, state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[NumOfStates - 1].Inc)
    ConstructBasis(state, iConst, state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[NumOfStates - 1].Trn)
    SetupComplexWindowStateGeometry(state, iSurf, NumOfStates, iConst, state.dataBSDFWindow.ComplexWind[iSurf - 1], state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[NumOfStates - 1], state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[NumOfStates - 1])
    AllocateCFSStateHourlyData(state, iSurf, NumOfStates)
    CalcWindowStaticProperties(state, iSurf, NumOfStates, state.dataBSDFWindow.ComplexWind[iSurf - 1], state.dataBSDFWindow.ComplexWind[iSurf - 1].Geom[NumOfStates - 1], state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[NumOfStates - 1])
    CFSShadeAndBeamInitialization(state, iSurf, NumOfStates)

def CheckCFSStates(inout state: EnergyPlusData, iSurf: Int32):
    var StateFound: Bool = False
    var CurrentCFSState: Int32 = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.CurrentState
    if state.dataSurface.Surface[iSurf - 1].Construction != state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[CurrentCFSState - 1].Konst:
        var NumOfStates: Int32 = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.NumStates
        for i in range(1, NumOfStates + 1):
            if state.dataSurface.Surface[iSurf - 1].Construction == state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[i - 1].Konst:
                StateFound = True
                state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.CurrentState = i
    else:
        StateFound = True
    if not StateFound:
        ExpandComplexState(state, iSurf, state.dataSurface.Surface[iSurf - 1].Construction)
        state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.CurrentState = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.NumStates

def InitComplexWindows(inout state: EnergyPlusData):
    if state.dataWindowComplexManager.InitComplexWindowsOnce:
        state.dataWindowComplexManager.InitComplexWindowsOnce = False
        InitBSDFWindows(state)
        CalcStaticProperties(state)

def UpdateComplexWindows(inout state: EnergyPlusData):
    if state.dataWindowComplexManager.NumComplexWind == 0:
        return
    if state.dataGlobal.KickOffSizing or state.dataGlobal.KickOffSimulation:
        return
    for IWind in range(1, state.dataWindowComplexManager.NumComplexWind + 1):
        var ISurf: Int32 = state.dataWindowComplexManager.WindowList[IWind - 1].SurfNo
        var NumStates: Int32 = state.dataBSDFWindow.ComplexWind[ISurf - 1].NumStates
        for IState in range(1, NumStates + 1):
            CFSShadeAndBeamInitialization(state, ISurf, IState)

def CFSShadeAndBeamInitialization(inout state: EnergyPlusData, iSurf: Int32, iState: Int32):
    using Vectors
    var SunDir: Vector = Vector(0.0, 0.0, 1.0)
    var HitPt: Vector = Vector(0.0, 0.0, 1.0)
    if state.dataGlobal.KickOffSizing or state.dataGlobal.KickOffSimulation:
        return
    var IncRay: Int32
    var Theta: Float64
    var Phi: Float64
    var hit: Bool
    var TotHits: Int32
    var complexWindow = state.dataBSDFWindow.ComplexWind[iSurf - 1]
    var complexWindowGeom = complexWindow.Geom[iState - 1]
    var surfaceWindowState = state.dataSurface.SurfaceWindow[iSurf - 1].ComplexFen.State[iState - 1]
    var nTS: Int32 = state.dataGlobal.TimeStepsInHour
    if not state.dataSysVars.DetailedSolarTimestepIntegration:
        var lHT: Int32 = 0
        var lHTI: Int32 = 0
        for Hour in range(1, 25):
            for TS in range(1, nTS + 1):
                SunDir = state.dataBSDFWindow.SUNCOSTS[TS - 1][Hour - 1]
                Theta = 0.0
                Phi = 0.0
                if state.dataBSDFWindow.SUNCOSTS[TS - 1][Hour - 1].z > SunIsUpValue:
                    IncRay = FindInBasis(state, SunDir, RayIdentificationType.Front_Incident, iSurf, iState, complexWindowGeom.Inc, Theta, Phi)
                    complexWindowGeom.ThetaBm[lHT] = Theta
                    complexWindowGeom.PhiBm[lHT] = Phi
                else:
                    complexWindowGeom.ThetaBm[lHT] = 0.0
                    complexWindowGeom.PhiBm[lHT] = 0.0
                    IncRay = 0
                if IncRay > 0:
                    complexWindowGeom.SolBmIndex[lHT] = IncRay
                else:
                    complexWindowGeom.SolBmIndex[lHT] = 0
                for I in range(1, complexWindowGeom.NGnd + 1):
                    TotHits = 0
                    var gndPt: Vector = complexWindowGeom.GndPt[I - 1]
                    for JSurf in range(1, state.dataSurface.TotSurfaces + 1):
                        if state.dataSurface.Surface[JSurf - 1].HeatTransSurf and state.dataSurface.Surface[JSurf - 1].ExtBoundCond != ExternalEnvironment:
                            continue
                        if dot(SunDir, state.dataSurface.Surface[JSurf - 1].NewellSurfaceNormalVector) >= 0.0:
                            continue
                        hit = PierceSurface(state, JSurf, gndPt, SunDir, HitPt)
                        if hit:
                            TotHits += 1
                            break
                    if TotHits > 0:
                        complexWindowGeom.SolBmGndWt[lHTI] = 0.0
                    else:
                        complexWindowGeom.SolBmGndWt[lHTI] = 1.0
                    lHTI += 1
                CalculateWindowBeamProperties(state, iSurf, iState, complexWindow, complexWindowGeom, surfaceWindowState, Hour, TS)
                lHT += 1
    else:
        var lHT: Int32 = linear_index_2d(state.dataGlobal.HourOfDay, state.dataGlobal.TimeStep, nTS)
        SunDir = state.dataBSDFWindow.SUNCOSTS[state.dataGlobal.TimeStep - 1][state.dataGlobal.HourOfDay - 1]
        Theta = 0.0
        Phi = 0.0
        if state.dataBSDFWindow.SUNCOSTS[state.dataGlobal.TimeStep - 1][state.dataGlobal.HourOfDay - 1].z > SunIsUpValue:
            IncRay = FindInBasis(state, SunDir, RayIdentificationType.Front_Incident, iSurf, iState, complexWindowGeom.Inc, Theta, Phi)
            complexWindowGeom.ThetaBm[lHT] = Theta
            complexWindowGeom.PhiBm[lHT] = Phi
        else:
            complexWindowGeom.ThetaBm[lHT] = 0.0
            complexWindowGeom.PhiBm[lHT] = 0.0
            IncRay = 0
        if IncRay > 0:
            complexWindowGeom.SolBmIndex[lHT] = IncRay
        else:
            complexWindowGeom.SolBmIndex[lHT] = 0
        var lHTI: Int32 = linear_index_3d(state.dataGlobal.HourOfDay, state.dataGlobal.TimeStep, 1, nTS)  # need NGnd dim
        for I in range(1, complexWindowGeom.NGnd + 1):
            TotHits = 0
            var gndPt: Vector = complexWindowGeom.GndPt[I - 1]
            for JSurf in range(1, state.dataSurface.TotSurfaces + 1):
                if state.dataSurface.Surface[JSurf - 1].HeatTransSurf and state.dataSurface.Surface[JSurf - 1].ExtBoundCond != ExternalEnvironment:
                    continue
                if dot(SunDir, state.dataSurface.Surface[JSurf - 1].NewellSurfaceNormalVector) >= 0.0:
                    continue
                hit = PierceSurface(state, JSurf, gndPt, SunDir, HitPt)
                if hit:
                    TotHits += 1
                    break
            if TotHits > 0:
                complexWindowGeom.SolBmGndWt[lHTI] = 0.0
            else:
                complexWindowGeom.SolBmGndWt[lHTI] = 1.0
            lHTI += 1
        CalculateWindowBeamProperties(state, iSurf, iState, complexWindow, complexWindowGeom, surfaceWindowState, state.dataGlobal.HourOfDay, state.dataGlobal.TimeStep)

def CalculateWindowBeamProperties(inout state: EnergyPlusData, ISurf: Int32, IState: Int32, Window: BSDFWindowGeomDescr, Geom: BSDFGeomDescr, inout State: BSDFStateDescr, Hour: Int32, TS: Int32):
    using Vectors
    var IConst: Int32
    var J: Int32
    var JRay: Int32
    var Theta: Float64
    var Phi: Float64
    var M: Int32
    var L: Int32
    var KBkSurf: Int32
    var Sum1: Float64
    var Sum2: Float64
    var IBm: Int32
    var RegWindFnd: Bool
    var RegWinIndex: DynamicVector[Int32]
    var NRegWin: Int32 = 0
    var Refl: Float64
    var Absorb: DynamicVector[Float64]
    var SunDir: Vector
    IConst = state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1].Konst
    IBm = Geom.SolBmIndex[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)]
    if IBm <= 0:
        # Set to zero
        for i in range(Window.NBkSurf):
            State.WinToSurfBmTrans[linear_index_3d(Hour, TS, i+1, state.dataGlobal.TimeStepsInHour)] = 0.0
        State.WinDirHemiTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = 0.0
        State.WinDirSpecTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = 0.0
        for L in range(1, State.NLayers + 1):
            State.WinBmFtAbs[linear_index_3d(Hour, TS, L, state.dataGlobal.TimeStepsInHour)] = 0.0
    else:
        for I in range(1, Window.NBkSurf + 1):
            Sum1 = 0.0
            for J in range(1, Geom.NSurfInt[I - 1] + 1):
                Sum1 += Geom.Trn.Lamda[Geom.SurfInt[J - 1][I - 1] - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.SolFrtTrans[IBm - 1][Geom.SurfInt[J - 1][I - 1] - 1]
            State.WinToSurfBmTrans[linear_index_3d(Hour, TS, I, state.dataGlobal.TimeStepsInHour)] = Sum1
        Sum1 = 0.0
        for J in range(1, Geom.Trn.NBasis + 1):
            Sum1 += Geom.Trn.Lamda[J - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.SolFrtTrans[IBm - 1][J - 1]
        State.WinDirHemiTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = Sum1
        State.WinDirSpecTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = Geom.Trn.Lamda[IBm - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.SolFrtTrans[IBm - 1][IBm - 1]
        for L in range(1, State.NLayers + 1):
            State.WinBmFtAbs[linear_index_3d(Hour, TS, L, state.dataGlobal.TimeStepsInHour)] = state.dataConstruction.Construct[IConst - 1].BSDFInput.Layer[L - 1].FrtAbs[IBm - 1][0]
    Sum1 = 0.0
    Sum2 = 0.0
    for J in range(1, Geom.NGnd + 1):
        JRay = Geom.GndIndex[J - 1]
        if Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] > 0.0:
            Sum2 += Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] * Geom.Inc.Lamda[JRay - 1]
            for M in range(1, Geom.Trn.NBasis + 1):
                Sum1 += Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] * Geom.Inc.Lamda[JRay - 1] * Geom.Trn.Lamda[M - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.SolFrtTrans[JRay - 1][M - 1]
    if Sum2 > 0.0:
        State.WinBmGndTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = Sum1 / Sum2
    else:
        State.WinBmGndTrans[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = 0.0
    for L in range(1, State.NLayers + 1):
        Sum1 = 0.0
        Sum2 = 0.0
        for J in range(1, Geom.NGnd + 1):
            JRay = Geom.GndIndex[J - 1]
            if Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] > 0.0:
                Sum2 += Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] * Geom.Inc.Lamda[JRay - 1]
                Sum1 += Geom.SolBmGndWt[linear_index_3d(Hour, TS, J, state.dataGlobal.TimeStepsInHour)] * Geom.Inc.Lamda[JRay - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.Layer[L - 1].FrtAbs[JRay - 1][0]
        if Sum2 > 0.0:
            State.WinBmGndAbs[linear_index_3d(Hour, TS, L, state.dataGlobal.TimeStepsInHour)] = Sum1 / Sum2
        else:
            State.WinBmGndAbs[linear_index_3d(Hour, TS, L, state.dataGlobal.TimeStepsInHour)] = 0.0
    RegWindFnd = False
    NRegWin = 0
    RegWinIndex = DynamicVector[Int32](Window.NBkSurf)
    for KBkSurf in range(1, Window.NBkSurf + 1):
        var BaseSurf: Int32 = state.dataSurface.Surface[ISurf - 1].BaseSurf
        var JSurf: Int32 = state.dataShadowComb.ShadowComb[BaseSurf - 1].BackSurf[KBkSurf - 1]
        if state.dataSurface.SurfWinWindowModelType[JSurf - 1] == WindowModel.BSDF:
            continue
        if not (state.dataSurface.Surface[JSurf - 1].Class == SurfaceClass.Window or state.dataSurface.Surface[JSurf - 1].Class == SurfaceClass.GlassDoor):
            continue
        if not (state.dataSurface.Surface[JSurf - 1].HeatTransSurf and state.dataSurface.Surface[JSurf - 1].ExtBoundCond == ExternalEnvironment and state.dataSurface.Surface[JSurf - 1].ExtSolar):
            continue
        RegWindFnd = True
        NRegWin += 1
        RegWinIndex[NRegWin - 1] = KBkSurf
    if RegWindFnd:
        Absorb = DynamicVector[Float64](State.NLayers)
        SunDir = state.dataBSDFWindow.SUNCOSTS[TS - 1][Hour - 1]
        var BkIncRay: Int32 = FindInBasis(state, SunDir, RayIdentificationType.Back_Incident, ISurf, IState, state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1].Trn, Theta, Phi)
        if BkIncRay > 0:
            Sum1 = 0.0
            for J in range(1, Geom.Trn.NBasis + 1):
                Sum1 += Geom.Trn.Lamda[J - 1] * state.dataConstruction.Construct[IConst - 1].BSDFInput.SolBkRefl[BkIncRay - 1][J - 1]
            Refl = Sum1
            for L in range(1, State.NLayers + 1):
                Absorb[L - 1] = state.dataConstruction.Construct[IConst - 1].BSDFInput.Layer[L - 1].BkAbs[BkIncRay - 1][0]
        else:
            Refl = 0.0
            for L in range(1, State.NLayers + 1):
                Absorb[L - 1] = 0.0
        for KRegWin in range(1, NRegWin + 1):
            KBkSurf = RegWinIndex[KRegWin - 1]
            State.BkSurf[KBkSurf - 1].WinDHBkRefl[linear_index_2d(Hour, TS, state.dataGlobal.TimeStepsInHour)] = Refl
            for L in range(1, State.NLayers + 1):
                State.BkSurf[KBkSurf - 1].WinDirBkAbs[linear_index_3d(Hour, TS, L, state.dataGlobal.TimeStepsInHour)] = Absorb[L - 1]
    if len(Absorb) > 0:
        Absorb = DynamicVector[Float64]()
    RegWinIndex = DynamicVector[Int32]()

def CalcStaticProperties(inout state: EnergyPlusData):
    using Vectors
    for IWind in range(1, state.dataWindowComplexManager.NumComplexWind + 1):
        var ISurf: Int32 = state.dataWindowComplexManager.WindowList[IWind - 1].SurfNo
        var NumStates: Int32 = state.dataWindowComplexManager.WindowList[IWind - 1].NumStates
        for IState in range(1, NumStates + 1):
            state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1].Konst = state.dataWindowComplexManager.WindowStateList[IState - 1][IWind - 1].Konst
            CalcWindowStaticProperties(state, ISurf, IState, state.dataBSDFWindow.ComplexWind[ISurf - 1], state.dataBSDFWindow.ComplexWind[ISurf - 1].Geom[IState - 1], state.dataSurface.SurfaceWindow[ISurf - 1].ComplexFen.State[IState - 1])

def CalculateBasisLength(inout state: EnergyPlusData, Input: BSDFWindowInputStruct, IConst: Int32, inout NBasis: Int32):
    if Input.BasisMatNcols == 1:
        NBasis = Input.BasisMatNrows
        return
    NBasis = 1
    for I in range(2, Input.BasisMatNrows + 1):
        NBasis += floor(state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMat[1][I - 1] + 0.001)

def ConstructBasis(inout state: EnergyPlusData, IConst: Int32, inout Basis: BasisStruct):
    var NThetas: Int32 = 0
    var Theta: Float64 = 0.0
    var Phi: Float64 = 0.0
    var DTheta: Float64 = 0.0
    var DPhi: Float64 = 0.0
    var HalfDTheta: Float64 = 0.0
    var Lamda: Float64 = 0.0
    var SolAng: Float64 = 0.0
    var NextTheta: Float64 = 0.0
    var LastTheta: Float64 = 0.0
    var LowerTheta: Float64 = 0.0
    var UpperTheta: Float64 = 0.0
    var Thetas: DynamicVector[Float64]
    var NPhis: DynamicVector[Int32]
    NThetas = state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMatNrows
    Basis.NThetas = NThetas
    Basis.BasisMatIndex = state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMatIndex
    Basis.NBasis = state.dataConstruction.Construct[IConst - 1].BSDFInput.NBasis
    Basis.Grid = DynamicVector[BasisElemDescr](Basis.NBasis)
    Thetas = DynamicVector[Float64](NThetas + 1)
    NPhis = DynamicVector[Int32](NThetas + 1)
    Basis.Thetas = DynamicVector[Float64](NThetas + 1)
    Basis.NPhis = DynamicVector[Int32](NThetas + 1)
    Basis.Lamda = DynamicVector[Float64](state.dataConstruction.Construct[IConst - 1].BSDFInput.NBasis)
    Basis.SolAng = DynamicVector[Float64](state.dataConstruction.Construct[IConst - 1].BSDFInput.NBasis)
    if state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisType == Basis.WINDOW:
        var I: Int32 = 0
        var NumElem: Int32 = 0
        var ElemNo: Int32 = 0
        Basis.BasisType = Basis.WINDOW
        if state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisSymmetryType == BasisSymmetry.None:
            Basis.BasisSymmetryType = BasisSymmetry.None
            Thetas[0] = 0.0
            Thetas[NThetas] = 0.5 * Pi
            NPhis[0] = 1
            NumElem = 1
            for I in range(2, NThetas + 1):
                Thetas[I - 1] = state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMat[0][I - 1] * DegToRad
                NPhis[I - 1] = floor(state.dataConstruction.Construct[IConst - 1].BSDFInput.BasisMat[1][I - 1] + 0.001)
                if NPhis[I - 1] <= 0:
                    ShowFatalError(state, "WindowComplexManager: incorrect input, no. phis must be positive.")
                NumElem += NPhis[I - 1]
            var MaxNPhis: Int32 = max(NPhis[:NThetas])
            Basis.Phis = DynamicVector[DynamicVector[Float64]](NThetas)
            for i in range(NThetas):
                Basis.Phis[i] = DynamicVector[Float64](MaxNPhis + 1, 0.0)
            Basis.BasisIndex = DynamicVector[DynamicVector[Int32]](MaxNPhis)
            for i