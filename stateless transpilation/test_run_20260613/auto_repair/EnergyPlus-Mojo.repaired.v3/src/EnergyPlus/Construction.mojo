from .Data.BaseData import BaseGlobalStruct, EnergyPlusData
from DataBSDFWindow import BSDFWindowInputStruct
from DataHeatBalance import (
    HighDiffusivityThreshold,
    ThinMaterialLayerThreshold,
    MaxSolidWinLayers,
)
from DataWindowEquivalentLayer import CFSMAXNL, Orientation
from  import Constant, DataConversions
from Material import (
    BlindDfTAR,
    BlindDfTARGS,
    Group,
    MaxSlatAngs,
    SurfaceRoughness,
    surfaceRoughnessNames,
    Material as MaterialClass,
)
from WindowManager import Window as WindowClass
from Sched import Schedule
from OutputReportPredefined import PreDefTableEntry
from DisplayRoutines import DisplayString
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
from memory import memset_zero
from math import sqrt, log, pow, abs, max
namespace EnergyPlus.Construction:
    let MaxLayersInConstruct: Int = 11
    let MaxCTFTerms: Int = 19
    struct BlindSolVis:
        var Sol: struct:
            var Ft: struct:
                var Df: BlindDfTARGS
            var Bk: struct:
                var Df: BlindDfTAR
        var Vis: struct:
            var Ft: struct:
                var Df: BlindDfTAR
            var Bk: struct:
                var Df: BlindDfTAR
    struct BlindSolDfAbs:
        var Sol: struct:
            var Ft: struct:
                var Df: struct:
                    var Abs: Float64 = 0.0
                    var AbsGnd: Float64 = 0.0
                    var AbsSky: Float64 = 0.0
            var Bk: struct:
                var Df: struct:
                    var Abs: Float64 = 0.0
    struct TCLayer:
        var constrNum: Int
        var specTemp: Float64
    struct ConstructionProps:
        var Name: String = ""
        var TotLayers: Int = 0
        var TotSolidLayers: Int = 0
        var TotGlassLayers: Int = 0
        var LayerPoint: List[Int]
        var IsUsed: Bool = false
        var IsUsedCTF: Bool = false
        var IsCondFD: Bool = false
        var InsideAbsorpVis: Float64 = 0.0
        var OutsideAbsorpVis: Float64 = 0.0
        var InsideAbsorpSolar: Float64 = 0.0
        var OutsideAbsorpSolar: Float64 = 0.0
        var InsideAbsorpThermal: Float64 = 0.0
        var OutsideAbsorpThermal: Float64 = 0.0
        var OutsideRoughness: SurfaceRoughness = SurfaceRoughness.Invalid
        var DayltPropPtr: Int = 0
        var W5FrameDivider: Int = 0
        var CTFCross: List[Float64]
        var CTFFlux: List[Float64]
        var CTFInside: List[Float64]
        var CTFOutside: List[Float64]
        var CTFSourceIn: List[Float64]
        var CTFSourceOut: List[Float64]
        var CTFTimeStep: Float64 = 0.0
        var CTFTSourceOut: List[Float64]
        var CTFTSourceIn: List[Float64]
        var CTFTSourceQ: List[Float64]
        var CTFTUserOut: List[Float64]
        var CTFTUserIn: List[Float64]
        var CTFTUserSource: List[Float64]
        var NumHistories: Int = 0
        var NumCTFTerms: Int = 0
        var UValue: Float64 = 0.0
        var SolutionDimensions: Int = 0
        var SourceAfterLayer: Int = 0
        var TempAfterLayer: Int = 0
        var ThicknessPerpend: Float64 = 0.0
        var userTemperatureLocationPerpendicular: Float64 = 0.0
        var AbsDiffIn: Float64 = 0.0
        var AbsDiffOut: Float64 = 0.0
        var AbsDiff: List[Float64]
        var effShadeBlindEmi: List[Float64]
        var effGlassEmi: List[Float64]
        var blindTARs: List[BlindSolVis]
        var layerSlatBlindDfAbs: List[List[BlindSolDfAbs]]
        var AbsDiffBack: List[Float64]
        var AbsDiffShade: Float64 = 0.0
        var AbsDiffBackShade: Float64 = 0.0
        var ShadeAbsorpThermal: Float64 = 0.0
        var AbsBeamCoef: List[List[Float64]]
        var AbsBeamBackCoef: List[List[Float64]]
        var AbsBeamShadeCoef: List[Float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var TransDiff: Float64 = 0.0
        var TransDiffVis: Float64 = 0.0
        var ReflectSolDiffBack: Float64 = 0.0
        var ReflectSolDiffFront: Float64 = 0.0
        var ReflectVisDiffBack: Float64 = 0.0
        var ReflectVisDiffFront: Float64 = 0.0
        var TransSolBeamCoef: List[Float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var TransVisBeamCoef: List[Float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var ReflSolBeamFrontCoef: List[Float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var ReflSolBeamBackCoef: List[Float64] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var tBareSolCoef: List[List[Float64]]
        var tBareVisCoef: List[List[Float64]]
        var rfBareSolCoef: List[List[Float64]]
        var rfBareVisCoef: List[List[Float64]]
        var rbBareSolCoef: List[List[Float64]]
        var rbBareVisCoef: List[List[Float64]]
        var afBareSolCoef: List[List[Float64]]
        var abBareSolCoef: List[List[Float64]]
        var tBareSolDiff: List[Float64]
        var tBareVisDiff: List[Float64]
        var rfBareSolDiff: List[Float64]
        var rfBareVisDiff: List[Float64]
        var rbBareSolDiff: List[Float64]
        var rbBareVisDiff: List[Float64]
        var afBareSolDiff: List[Float64]
        var abBareSolDiff: List[Float64]
        var FromWindow5DataFile: Bool = false
        var W5FileMullionWidth: Float64 = 0.0
        var W5FileMullionOrientation: Orientation = Orientation.Invalid
        var W5FileGlazingSysWidth: Float64 = 0.0
        var W5FileGlazingSysHeight: Float64 = 0.0
        var SummerSHGC: Float64 = 0.0
        var VisTransNorm: Float64 = 0.0
        var SolTransNorm: Float64 = 0.0
        var SourceSinkPresent: Bool = false
        var TypeIsWindow: Bool = false
        var WindowTypeBSDF: Bool = false
        var TypeIsEcoRoof: Bool = false
        var TypeIsIRT: Bool = false
        var TypeIsCfactorWall: Bool = false
        var TypeIsFfactorFloor: Bool = false
        var isTCWindow: Bool = false
        var isTCMaster: Bool = false
        var TCMasterConstrNum: Int = 0
        var TCMasterMatNum: Int = 0
        var TCLayerNum: Int = 0
        var TCGlassNum: Int = 0
        var numTCChildConstrs: Int
        var TCChildConstrs: List[TCLayer]
        var specTemp: Float64
        var CFactor: Float64 = 0.0
        var Height: Float64 = 0.0
        var FFactor: Float64 = 0.0
        var Area: Float64 = 0.0
        var PerimeterExposed: Float64 = 0.0
        var ReverseConstructionNumLayersWarning: Bool = false
        var ReverseConstructionLayersOrderWarning: Bool = false
        var BSDFInput: BSDFWindowInputStruct
        var WindowTypeEQL: Bool = false
        var EQLConsPtr: Int = 0
        var AbsDiffFrontEQL: List[Float64]
        var AbsDiffBackEQL: List[Float64]
        var TransDiffFrontEQL: Float64 = 0.0
        var TransDiffBackEQL: Float64 = 0.0
        var TypeIsAirBoundary: Bool = false
        var TypeIsAirBoundaryMixing: Bool = false
        var AirBoundaryACH: Float64 = 0.0
        var airBoundaryMixingSched: Schedule? = None
        var rcmax: Int = 0
        var AExp: List[List[Float64]]
        var AInv: List[List[Float64]]
        var AMat: List[List[Float64]]
        var BMat: List[Float64]
        var CMat: List[Float64]
        var DMat: List[Float64]
        var e: List[Float64]
        var Gamma1: List[List[Float64]]
        var Gamma2: List[List[Float64]]
        var s: List[List[List[Float64]]]
        var s0: List[List[Float64]]
        var IdenMatrix: List[List[Float64]]
        var NumOfPerpendNodes: Int = 7
        var NodeSource: Int = 0
        var NodeUserTemp: Int = 0
        @staticmethod
        def __new__():
            var self = ConstructionProps{__type = ConstructionProps}
            self.CTFCross = [0.0] * MaxCTFTerms
            self.CTFFlux = [0.0] * MaxCTFTerms
            self.CTFInside = [0.0] * MaxCTFTerms
            self.CTFOutside = [0.0] * MaxCTFTerms
            self.CTFSourceIn = [0.0] * MaxCTFTerms
            self.CTFSourceOut = [0.0] * MaxCTFTerms
            self.CTFTSourceOut = [0.0] * MaxCTFTerms
            self.CTFTSourceIn = [0.0] * MaxCTFTerms
            self.CTFTSourceQ = [0.0] * MaxCTFTerms
            self.CTFTUserOut = [0.0] * MaxCTFTerms
            self.CTFTUserIn = [0.0] * MaxCTFTerms
            self.CTFTUserSource = [0.0] * MaxCTFTerms
            self.LayerPoint = [0] * MaxLayersInConstruct
            self.TransDiffVis = 0.0
            self.tBareSolDiff = [0.0] * 5
            self.tBareVisDiff = [0.0] * 5
            self.rfBareSolDiff = [0.0] * 5
            self.rfBareVisDiff = [0.0] * 5
            self.rbBareSolDiff = [0.0] * 5
            self.rbBareVisDiff = [0.0] * 5
            self.afBareSolDiff = [0.0] * 5
            self.abBareSolDiff = [0.0] * 5
            self.AbsDiffFrontEQL = [0.0] * CFSMAXNL
            self.AbsDiffBackEQL = [0.0] * CFSMAXNL
            self.BMat = [0.0] * 3
            self.CMat = [0.0] * 2
            self.DMat = [0.0] * 2
            self.s0 = [[0.0 for _ in range(4)] for _ in range(3)]
            return self
        def calculateTransferFunction(self, state: EnergyPlusData, ErrorsFound: Bool, DoCTFErrorReport: Bool):
        def calculateExponentialMatrix(self):
        def calculateInverseMatrix(self):
        def calculateGammas(self):
        def calculateFinalCoefficients(self):
        def reportTransferFunction(self, state: EnergyPlusData, cCounter: Int):
        def reportLayers(self, state: EnergyPlusData):
        def isGlazingConstruction(self, state: EnergyPlusData) -> Bool:
        def setThicknessPerpendicular(self, state: EnergyPlusData, userValue: Float64) -> Float64:
        def setUserTemperatureLocationPerpendicular(self, state: EnergyPlusData, userValue: Float64) -> Float64:
        def setNodeSourceAndUserTemp(self, Nodes: List[Int]):
        def setArraysBasedOnMaxSolidWinLayers(self, state: EnergyPlusData):
} // namespace EnergyPlus.Construction
struct ConstructionData(BaseGlobalStruct):
    var Construct: List[Construction.ConstructionProps]
    var LayerPoint: List[Int] = [0] * Construction.MaxLayersInConstruct
    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        self = ConstructionData{__type = ConstructionData}