from Data.EnergyPlusData import EnergyPlusData
from Data.DataGlobalConstants import DataGlobalConstants as Constant
from Data.DataGlobals import DataGlobals
from Data.DataHeatBalance import DataHeatBalance
from Data.DataHVACGlobals import DataHVACGlobals
from Data.DataIPShortCuts import DataIPShortCuts
from Data.DataLoopNode import DataLoopNode
from Data.DataPrecisionGlobals import DataPrecisionGlobals
from Data.DataEnvironment import DataEnvironment, OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt
from BranchNodeConnections import BranchNodeConnections
from ConductionTransferFunction import ConductionTransferFunction
from Construction import Construction
from ConvectionCoefficients import ConvectionCoefficients as Convect
from FluidProperties import FluidProperties
from General import General as Util
from InputProcessing.InputProcessor import InputProcessor
from Material import Material
from NodeInputManager import NodeInputManager as Node
from OutputProcessor import OutputProcessor
from Plant.DataPlant import DataPlant
from Plant.PlantLocation import PlantLocation
from Plant.PlantUtilities import PlantUtilities
from PlantComponent import PlantComponent
from UtilityRoutines import UtilityRoutines

def pow_2(x: Float64) -> Float64:
    return x * x

def pow_4(x: Float64) -> Float64:
    return x * x * x * x

def max(a: Float64, b: Float64) -> Float64:
    if a > b:
        return a
    return b

def min(a: Float64, b: Float64) -> Float64:
    if a < b:
        return a
    return b

def std_abs(x: Float64) -> Float64:
    if x < 0.0:
        return -x
    return x

alias SmallNum: Float64 = 1.0e-30
alias StefBoltzmann: Float64 = 5.6697e-08
alias SurfaceHXHeight: Float64 = 0.0
alias SurfCond_Ground: Int32 = 1
alias SurfCond_Exposed: Int32 = 2

struct SurfaceGroundHeatExchangerData:
    var Name: String
    var ConstructionName: String
    var InletNode: String
    var OutletNode: String
    var DesignMassFlowRate: Float64
    var TubeDiameter: Float64
    var TubeSpacing: Float64
    var SurfaceLength: Float64
    var SurfaceWidth: Float64
    var TopThermAbs: Float64
    var TopSolarAbs: Float64
    var BtmThermAbs: Float64
    var LowerSurfCond: Int32
    var TubeCircuits: Int32
    var ConstructionNum: Int32
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var TopRoughness: Material.SurfaceRoughness
    var BtmRoughness: Material.SurfaceRoughness
    var FrozenErrIndex1: Int32
    var FrozenErrIndex2: Int32
    var ConvErrIndex1: Int32
    var ConvErrIndex2: Int32
    var ConvErrIndex3: Int32
    var plantLoc: PlantLocation
    var TsrcConstCoef: Float64
    var TsrcVarCoef: Float64
    var QbtmConstCoef: Float64
    var QbtmVarCoef: Float64
    var QtopConstCoef: Float64
    var QtopVarCoef: Float64
    var NumCTFTerms: Int32
    var CTFin: List[Float64]
    var CTFout: List[Float64]
    var CTFcross: List[Float64]
    var CTFflux: List[Float64]
    var CTFSourceIn: List[Float64]
    var CTFSourceOut: List[Float64]
    var CTFTSourceOut: List[Float64]
    var CTFTSourceIn: List[Float64]
    var CTFTSourceQ: List[Float64]
    var TbtmHistory: List[Float64]
    var TtopHistory: List[Float64]
    var TsrcHistory: List[Float64]
    var QbtmHistory: List[Float64]
    var QtopHistory: List[Float64]
    var QsrcHistory: List[Float64]
    var QSrc: Float64
    var QSrcAvg: Float64
    var LastQSrc: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64
    var InletTemp: Float64
    var OutletTemp: Float64
    var MassFlowRate: Float64
    var TopSurfaceTemp: Float64
    var BtmSurfaceTemp: Float64
    var TopSurfaceFlux: Float64
    var BtmSurfaceFlux: Float64
    var HeatTransferRate: Float64
    var SurfHeatTransferRate: Float64
    var Energy: Float64
    var SurfEnergy: Float64
    var SourceTemp: Float64
    var MyFlag: Bool
    var InitQTF: Bool
    var MyEnvrnFlag: Bool
    var SurfaceArea: Float64
    var firstTimeThrough: Bool

    def __init__(inout self):
        self.Name = ""
        self.ConstructionName = ""
        self.InletNode = ""
        self.OutletNode = ""
        self.DesignMassFlowRate = 0.0
        self.TubeDiameter = 0.0
        self.TubeSpacing = 0.0
        self.SurfaceLength = 0.0
        self.SurfaceWidth = 0.0
        self.TopThermAbs = 0.0
        self.TopSolarAbs = 0.0
        self.BtmThermAbs = 0.0
        self.LowerSurfCond = 0
        self.TubeCircuits = 0
        self.ConstructionNum = 0
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.TopRoughness = Material.SurfaceRoughness.Invalid
        self.BtmRoughness = Material.SurfaceRoughness.Invalid
        self.FrozenErrIndex1 = 0
        self.FrozenErrIndex2 = 0
        self.ConvErrIndex1 = 0
        self.ConvErrIndex2 = 0
        self.ConvErrIndex3 = 0
        self.plantLoc = PlantLocation()
        self.TsrcConstCoef = 0.0
        self.TsrcVarCoef = 0.0
        self.QbtmConstCoef = 0.0
        self.QbtmVarCoef = 0.0
        self.QtopConstCoef = 0.0
        self.QtopVarCoef = 0.0
        self.NumCTFTerms = 0
        self.CTFin = []
        self.CTFout = []
        self.CTFcross = []
        self.CTFflux = []
        self.CTFSourceIn = []
        self.CTFSourceOut = []
        self.CTFTSourceOut = []
        self.CTFTSourceIn = []
        self.CTFTSourceQ = []
        self.TbtmHistory = []
        self.TtopHistory = []
        self.TsrcHistory = []
        self.QbtmHistory = []
        self.QtopHistory = []
        self.QsrcHistory = []
        self.QSrc = 0.0
        self.QSrcAvg = 0.0
        self.LastQSrc = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.MassFlowRate = 0.0
        self.TopSurfaceTemp = 0.0
        self.BtmSurfaceTemp = 0.0
        self.TopSurfaceFlux = 0.0
        self.BtmSurfaceFlux = 0.0
        self.HeatTransferRate = 0.0
        self.SurfHeatTransferRate = 0.0
        self.Energy = 0.0
        self.SurfEnergy = 0.0
        self.SourceTemp = 0.0
        self.MyFlag = True
        self.InitQTF = True
        self.MyEnvrnFlag = True
        self.SurfaceArea = 0.0
        self.firstTimeThrough = True

    def __del__(owned self):

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        self.InitSurfaceGroundHeatExchanger(state)
        self.CalcSurfaceGroundHeatExchanger(state, FirstHVACIteration)
        self.UpdateSurfaceGroundHeatExchngr(state)
        self.ReportSurfaceGroundHeatExchngr(state)

    @staticmethod
    def factory(state: EnergyPlusData, objectType: DataPlant.PlantEquipmentType, objectName: String) -> PlantComponent:
        if state.dataSurfaceGroundHeatExchangers.GetInputFlag:
            GetSurfaceGroundHeatExchanger(state)
            state.dataSurfaceGroundHeatExchangers.GetInputFlag = False
        for i in range(len(state.dataSurfaceGroundHeatExchangers.SurfaceGHE)):
            var ghx = state.dataSurfaceGroundHeatExchangers.SurfaceGHE[i]
            if ghx.Name == objectName:
                return ghx
        ShowFatalError(state, "Surface Ground Heat Exchanger: Error getting inputs for pipe named: " + objectName)
        return null

    def InitSurfaceGroundHeatExchanger(inout self, state: EnergyPlusData):
        var OutDryBulb: Float64
        if self.InitQTF:
            for Cons in range(1, state.dataHeatBal.TotConstructs + 1):
                if Util.SameString(state.dataConstruction.Construct[Cons].Name, self.ConstructionName):
                    var LayerNum = state.dataConstruction.Construct[Cons].TotLayers
                    self.NumCTFTerms = state.dataConstruction.Construct[Cons].NumCTFTerms
                    self.CTFin = state.dataConstruction.Construct[Cons].CTFInside
                    self.CTFout = state.dataConstruction.Construct[Cons].CTFOutside
                    self.CTFcross = state.dataConstruction.Construct[Cons].CTFCross
                    for i in range(1, len(state.dataConstruction.Construct[Cons].CTFFlux)):
                        self.CTFflux[i] = state.dataConstruction.Construct[Cons].CTFFlux[i]
                    self.CTFSourceIn = state.dataConstruction.Construct[Cons].CTFSourceIn
                    self.CTFSourceOut = state.dataConstruction.Construct[Cons].CTFSourceOut
                    self.CTFTSourceOut = state.dataConstruction.Construct[Cons].CTFTSourceOut
                    self.CTFTSourceIn = state.dataConstruction.Construct[Cons].CTFTSourceIn
                    self.CTFTSourceQ = state.dataConstruction.Construct[Cons].CTFTSourceQ
                    self.ConstructionNum = Cons
                    var thisMaterialLayer = state.dataMaterial.materials[state.dataConstruction.Construct[Cons].LayerPoint(LayerNum)]
                    self.BtmRoughness = thisMaterialLayer.Roughness
                    self.TopThermAbs = thisMaterialLayer.AbsorpThermal
                    var thisMaterial1 = state.dataMaterial.materials[state.dataConstruction.Construct[Cons].LayerPoint(1)]
                    self.TopRoughness = thisMaterial1.Roughness
                    self.TopThermAbs = thisMaterial1.AbsorpThermal
                    self.TopSolarAbs = thisMaterial1.AbsorpSolar
            self.InitQTF = False
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            OutDryBulb = OutDryBulbTempAt(state, SurfaceHXHeight)
            self.CTFflux[0] = 0.0
            for i in range(len(self.TsrcHistory)):
                self.TsrcHistory[i] = OutDryBulb
            for i in range(len(self.TbtmHistory)):
                self.TbtmHistory[i] = OutDryBulb
            for i in range(len(self.TtopHistory)):
                self.TtopHistory[i] = OutDryBulb
            for i in range(len(self.TsrcHistory)):
                self.TsrcHistory[i] = OutDryBulb
            for i in range(len(self.QbtmHistory)):
                self.QbtmHistory[i] = 0.0
            for i in range(len(self.QtopHistory)):
                self.QtopHistory[i] = 0.0
            for i in range(len(self.QsrcHistory)):
                self.QsrcHistory[i] = 0.0
            self.TsrcConstCoef = 0.0
            self.TsrcVarCoef = 0.0
            self.QbtmConstCoef = 0.0
            self.QbtmVarCoef = 0.0
            self.QtopConstCoef = 0.0
            self.QtopVarCoef = 0.0
            self.QSrc = 0.0
            self.QSrcAvg = 0.0
            self.LastQSrc = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
            state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state.dataEnvrn.BeamSolarRad
            state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state.dataEnvrn.SOLCOS[3]
            state.dataSurfaceGroundHeatExchangers.PastDifSolarRad = state.dataEnvrn.DifSolarRad
            state.dataSurfaceGroundHeatExchangers.PastGroundTemp = state.dataEnvrn.GroundTemp[Int32(DataEnvironment.GroundTempType.Shallow)]
            state.dataSurfaceGroundHeatExchangers.PastIsRain = state.dataEnvrn.IsRain
            state.dataSurfaceGroundHeatExchangers.PastIsSnow = state.dataEnvrn.IsSnow
            state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = OutDryBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = OutWetBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastSkyTemp = state.dataEnvrn.SkyTemp
            state.dataSurfaceGroundHeatExchangers.PastWindSpeed = WindSpeedAt(state, SurfaceHXHeight)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.SurfaceArea = self.SurfaceLength * self.SurfaceWidth
        var DesignFlow = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesignMassFlowRate)
        PlantUtilities.SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        state.dataSurfaceGroundHeatExchangers.FlowRate = state.dataLoopNodes.Node[self.InletNodeNum].MassFlowRate

    def CalcSurfaceGroundHeatExchanger(inout self, state: EnergyPlusData, FirstHVACIteration: Bool):
        alias SurfFluxTol: Float64 = 0.001
        alias SrcFluxTol: Float64 = 0.001
        alias RelaxT: Float64 = 0.1
        alias Maxiter: Int32 = 100
        alias Maxiter1: Int32 = 100
        var PastFluxTop: Float64
        var PastFluxBtm: Float64
        var PastTempBtm: Float64
        var PastTempTop: Float64
        var OldPastFluxTop: Float64
        var OldPastFluxBtm: Float64
        var TempT: Float64
        var TempB: Float64
        var OldFluxTop: Float64
        var OldFluxBtm: Float64
        var OldSourceFlux: Float64
        if FirstHVACIteration and not state.dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            var FluxTop = state.dataSurfaceGroundHeatExchangers.FluxTop
            var FluxBtm = state.dataSurfaceGroundHeatExchangers.FluxBtm
            var TempBtm = state.dataSurfaceGroundHeatExchangers.TempBtm
            var TempTop = state.dataSurfaceGroundHeatExchangers.TempTop
            self.firstTimeThrough = False
            state.dataSurfaceGroundHeatExchangers.SourceFlux = self.QSrcAvg
            PastTempBtm = self.TbtmHistory[1]
            PastTempTop = self.TtopHistory[1]
            OldPastFluxTop = 1.0e+30
            OldPastFluxBtm = 1.0e+30
            TempB = 0.0
            TempT = 0.0
            var iter: Int32 = 0
            while True:
                iter += 1
                CalcTopFluxCoefficents(inout self, PastTempBtm, PastTempTop)
                PastFluxTop = self.QtopConstCoef + self.QtopVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                CalcTopSurfTemp(self, -PastFluxTop, inout TempT,
                    state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                    state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                    state.dataSurfaceGroundHeatExchangers.PastSkyTemp,
                    state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                    state.dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                    state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                    state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                    state.dataSurfaceGroundHeatExchangers.PastIsRain,
                    state.dataSurfaceGroundHeatExchangers.PastIsSnow)
                PastTempTop = PastTempTop * (1.0 - RelaxT) + RelaxT * TempT
                CalcBottomFluxCoefficents(inout self, PastTempBtm, PastTempTop)
                PastFluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                if std_abs((OldPastFluxTop - PastFluxTop) / OldPastFluxTop) <= SurfFluxTol and std_abs((OldPastFluxBtm - PastFluxBtm) / OldPastFluxBtm) <= SurfFluxTol:
                    break
                CalcBottomSurfTemp(self, PastFluxBtm, inout TempB,
                    state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                    state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                    state.dataSurfaceGroundHeatExchangers.PastGroundTemp)
                PastTempBtm = PastTempBtm * (1.0 - RelaxT) + RelaxT * TempB
                OldPastFluxTop = PastFluxTop
                OldPastFluxBtm = PastFluxBtm
                if iter > Maxiter:
                    if self.ConvErrIndex1 == 0:
                        ShowWarningMessage(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 1), Iterations=" + String(Maxiter))
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 1)", self.ConvErrIndex1)
                    break
            if not state.dataSurfaceGroundHeatExchangers.InitializeTempTop:
                TempTop = TempT
                TempBtm = TempB
                FluxTop = PastFluxTop
                FluxBtm = PastFluxBtm
                state.dataSurfaceGroundHeatExchangers.InitializeTempTop = True
            state.dataSurfaceGroundHeatExchangers.TopSurfTemp = TempTop
            state.dataSurfaceGroundHeatExchangers.BtmSurfTemp = TempBtm
            state.dataSurfaceGroundHeatExchangers.TopSurfFlux = -FluxTop
            state.dataSurfaceGroundHeatExchangers.BtmSurfFlux = FluxBtm
            CalcSourceTempCoefficents(inout self, PastTempBtm, PastTempTop)
            self.SourceTemp = self.TsrcConstCoef + self.TsrcVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
            UpdateHistories(self, PastFluxTop, PastFluxBtm, state.dataSurfaceGroundHeatExchangers.SourceFlux, self.SourceTemp)
            self.QSrcAvg = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
            state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state.dataEnvrn.BeamSolarRad
            state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state.dataEnvrn.SOLCOS[3]
            state.dataSurfaceGroundHeatExchangers.PastDifSolarRad = state.dataEnvrn.DifSolarRad
            state.dataSurfaceGroundHeatExchangers.PastGroundTemp = state.dataEnvrn.GroundTemp[Int32(DataEnvironment.GroundTempType.Shallow)]
            state.dataSurfaceGroundHeatExchangers.PastIsRain = state.dataEnvrn.IsRain
            state.dataSurfaceGroundHeatExchangers.PastIsSnow = state.dataEnvrn.IsSnow
            state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = OutDryBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = OutWetBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastSkyTemp = state.dataEnvrn.SkyTemp
            state.dataSurfaceGroundHeatExchangers.PastWindSpeed = WindSpeedAt(state, SurfaceHXHeight)
            TempBtm = self.TbtmHistory[1]
            TempTop = self.TtopHistory[1]
            OldFluxTop = 1.0e+30
            OldFluxBtm = 1.0e+30
            OldSourceFlux = 1.0e+30
            state.dataSurfaceGroundHeatExchangers.SourceFlux = CalcSourceFlux(self, state)
            iter = 0
            while True:
                iter += 1
                var iter1: Int32 = 0
                while True:
                    iter1 += 1
                    CalcTopFluxCoefficents(inout self, TempBtm, TempTop)
                    FluxTop = self.QtopConstCoef + self.QtopVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                    CalcTopSurfTemp(self, -FluxTop, inout TempT,
                        state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                        state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                        state.dataSurfaceGroundHeatExchangers.PastSkyTemp,
                        state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                        state.dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                        state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                        state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                        state.dataSurfaceGroundHeatExchangers.PastIsRain,
                        state.dataSurfaceGroundHeatExchangers.PastIsSnow)
                    TempTop = TempTop * (1.0 - RelaxT) + RelaxT * TempT
                    CalcBottomFluxCoefficents(inout self, TempBtm, TempTop)
                    FluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                    if std_abs((OldFluxTop - FluxTop) / OldFluxTop) <= SurfFluxTol and std_abs((OldFluxBtm - FluxBtm) / OldFluxBtm) <= SurfFluxTol:
                        break
                    CalcBottomSurfTemp(self, FluxBtm, inout TempB,
                        state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                        state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                        state.dataEnvrn.GroundTemp[Int32(DataEnvironment.GroundTempType.Shallow)])
                    TempBtm = TempBtm * (1.0 - RelaxT) + RelaxT * TempB
                    OldFluxBtm = FluxBtm
                    OldFluxTop = FluxTop
                    if iter1 > Maxiter1:
                        if self.ConvErrIndex2 == 0:
                            ShowWarningMessage(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 2), Iterations=" + String(Maxiter))
                            ShowContinueErrorTimeStamp(state, "")
                        ShowRecurringWarningErrorAtEnd(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 2)", self.ConvErrIndex2)
                        break
                CalcSourceTempCoefficents(inout self, TempBtm, TempTop)
                state.dataSurfaceGroundHeatExchangers.SourceFlux = CalcSourceFlux(self, state)
                if std_abs((OldSourceFlux - state.dataSurfaceGroundHeatExchangers.SourceFlux) / (1.0e-20 + OldSourceFlux)) <= SrcFluxTol:
                    break
                OldSourceFlux = state.dataSurfaceGroundHeatExchangers.SourceFlux
                if iter > Maxiter:
                    if self.ConvErrIndex3 == 0:
                        ShowWarningMessage(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 3), Iterations=" + String(Maxiter))
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "CalcSurfaceGroundHeatExchanger=\"" + self.Name + "\", Did not converge (part 3)", self.ConvErrIndex3)
                    break
        elif not FirstHVACIteration:
            self.firstTimeThrough = True
            state.dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)

    def CalcBottomFluxCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop
        self.QbtmConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.QbtmConstCoef += (-self.CTFin[Term] * self.TbtmHistory[Term]) + (self.CTFcross[Term] * self.TtopHistory[Term]) + \
                                   (self.CTFflux[Term] * self.QbtmHistory[Term]) + (self.CTFSourceIn[Term] * self.QsrcHistory[Term])
        self.QbtmConstCoef -= self.CTFSourceIn[0] * self.QsrcHistory[0]
        self.QbtmVarCoef = self.CTFSourceIn[0]

    def CalcTopFluxCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop
        self.QtopConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.QtopConstCoef += (self.CTFout[Term] * self.TtopHistory[Term]) - (self.CTFcross[Term] * self.TbtmHistory[Term]) + \
                                   (self.CTFflux[Term] * self.QtopHistory[Term]) + (self.CTFSourceOut[Term] * self.QsrcHistory[Term])
        self.QtopConstCoef -= (self.CTFSourceOut[0] * self.QsrcHistory[0])
        self.QtopVarCoef = self.CTFSourceOut[0]

    def CalcSourceTempCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop
        self.TsrcConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.TsrcConstCoef += (self.CTFTSourceIn[Term] * self.TbtmHistory[Term]) + (self.CTFTSourceOut[Term] * self.TtopHistory[Term]) + \
                                   (self.CTFflux[Term] * self.TsrcHistory[Term]) + (self.CTFTSourceQ[Term] * self.QsrcHistory[Term])
        self.TsrcConstCoef -= self.CTFTSourceQ[0] * self.QsrcHistory[0]
        self.TsrcVarCoef = self.CTFTSourceQ[0]

    def CalcSourceFlux(inout self, state: EnergyPlusData) -> Float64:
        var CalcSourceFluxVal: Float64
        var EpsMdotCp: Float64
        if state.dataSurfaceGroundHeatExchangers.FlowRate > 0.0:
            EpsMdotCp = self.CalcHXEffectTerm(state, self.InletTemp, state.dataSurfaceGroundHeatExchangers.FlowRate)
            CalcSourceFluxVal = (self.InletTemp - self.TsrcConstCoef) / (self.SurfaceArea / EpsMdotCp + self.TsrcVarCoef)
        else:
            CalcSourceFluxVal = 0.0
        return CalcSourceFluxVal

    def UpdateHistories(inout self, TopFlux: Float64, BottomFlux: Float64, sourceFlux: Float64, sourceTemp: Float64):
        self.TtopHistory = eoshiftArray(self.TtopHistory, -1, 0.0)
        self.TbtmHistory = eoshiftArray(self.TbtmHistory, -1, 0.0)
        self.TsrcHistory = eoshiftArray(self.TsrcHistory, -1, 0.0)
        self.TsrcHistory[1] = sourceTemp
        self.QbtmHistory = eoshiftArray(self.QbtmHistory, -1, 0.0)
        self.QbtmHistory[1] = BottomFlux
        self.QtopHistory = eoshiftArray(self.QtopHistory, -1, 0.0)
        self.QtopHistory[1] = TopFlux
        self.QsrcHistory = eoshiftArray(self.QsrcHistory, -1, 0.0)
        self.QsrcHistory[1] = sourceFlux

    def CalcHXEffectTerm(inout self, state: EnergyPlusData, Temperature: Float64, WaterMassFlow: Float64) -> Float64:
        alias MaxLaminarRe: Float64 = 2300.0
        alias NumOfPropDivisions: Int32 = 13
        var Temps: StaticArray[NumOfPropDivisions, Float64] = [1.85, 6.85, 11.85, 16.85, 21.85, 26.85, 31.85, 36.85, 41.85, 46.85, 51.85, 56.85, 61.85]
        var Mu: StaticArray[NumOfPropDivisions, Float64] = [0.001652, 0.001422, 0.001225, 0.00108, 0.000959, 0.000855, 0.000769, 0.000695, 0.000631, 0.000577, 0.000528, 0.000489, 0.000453]
        var Conductivity: StaticArray[NumOfPropDivisions, Float64] = [0.574, 0.582, 0.590, 0.598, 0.606, 0.613, 0.620, 0.628, 0.634, 0.640, 0.645, 0.650, 0.656]
        var Pr: StaticArray[NumOfPropDivisions, Float64] = [12.22, 10.26, 8.81, 7.56, 6.62, 5.83, 5.20, 4.62, 4.16, 3.77, 3.42, 3.15, 2.88]
        alias WaterIndex: Int32 = 1
        var Index: Int32
        var InterpFrac: Float64
        var NuD: Float64
        var ReD: Float64
        var NTU: Float64
        var CpWater: Float64
        var Kactual: Float64
        var MUactual: Float64
        var PRactual: Float64
        var PipeLength: Float64
        Index = 0
        while Index < NumOfPropDivisions:
            if Temperature < Temps[Index]:
                break
            Index += 1
        if Index == 0:
            MUactual = Mu[Index]
            Kactual = Conductivity[Index]
            PRactual = Pr[Index]
        elif Index > NumOfPropDivisions - 1:
            Index = NumOfPropDivisions - 1
            MUactual = Mu[Index]
            Kactual = Conductivity[Index]
            PRactual = Pr[Index]
        else:
            InterpFrac = (Temperature - Temps[Index - 1]) / (Temps[Index] - Temps[Index - 1])
            MUactual = Mu[Index - 1] + InterpFrac * (Mu[Index] - Mu[Index - 1])
            Kactual = Conductivity[Index - 1] + InterpFrac * (Conductivity[Index] - Conductivity[Index - 1])
            PRactual = Pr[Index - 1] + InterpFrac * (Pr[Index] - Pr[Index - 1])
        if Temperature < 0.0:
            if self.plantLoc.loop.FluidIndex == WaterIndex:
                if self.FrozenErrIndex1 == 0:
                    ShowWarningMessage(state, "GroundHeatExchanger:Surface=\"" + self.Name + "\", water is frozen; Model not valid. Calculated Water Temperature=[" + String(self.InletTemp) + "] C")
                    ShowContinueErrorTimeStamp(state, "")
                ShowRecurringWarningErrorAtEnd(state, "GroundHeatExchanger:Surface=\"" + self.Name + "\", water is frozen", self.FrozenErrIndex1, self.InletTemp, self.InletTemp, "", "[C]", "[C]")
                self.InletTemp = max(self.InletTemp, 0.0)
        CpWater = self.plantLoc.loop.glycol.getSpecificHeat(state, Temperature, "SurfaceGroundHeatExchanger:CalcHXEffectTerm")
        ReD = 4.0 * WaterMassFlow / (Constant.Pi * MUactual * self.TubeDiameter * self.TubeCircuits)
        if ReD >= MaxLaminarRe:
            NuD = 0.023 * (ReD**0.8) * (PRactual**(1.0/3.0))
        else:
            NuD = 3.66
        PipeLength = self.SurfaceLength * self.SurfaceWidth / self.TubeSpacing
        NTU = Constant.Pi * Kactual * NuD * PipeLength / (WaterMassFlow * CpWater)
        if -NTU >= DataPrecisionGlobals.EXP_LowerLimit:
            CalcHXEffectTerm = (1.0 - Float64.exp(-NTU)) * WaterMassFlow * CpWater
        else:
            CalcHXEffectTerm = 1.0 * WaterMassFlow * CpWater
        return CalcHXEffectTerm

    def CalcTopSurfTemp(inout self, FluxTop: Float64, inout TempTop: Float64, ThisDryBulb: Float64, ThisWetBulb: Float64, ThisSkyTemp: Float64, ThisBeamSolarRad: Float64, ThisDifSolarRad: Float64, ThisSolarDirCosVert: Float64, ThisWindSpeed: Float64, ThisIsRain: Bool, ThisIsSnow: Bool):
        var ConvCoef: Float64
        var RadCoef: Float64
        var ExternalTemp: Float64
        var OldSurfTemp: Float64
        var QSolAbsorbed: Float64
        var SurfTempAbs: Float64
        var SkyTempAbs: Float64
        if ThisIsSnow or ThisIsRain:
            ExternalTemp = ThisWetBulb
        else:
            ExternalTemp = ThisDryBulb
        OldSurfTemp = self.TtopHistory[1]
        SurfTempAbs = OldSurfTemp + Constant.Kelvin
        SkyTempAbs = ThisSkyTemp + Constant.Kelvin
        ConvCoef = Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)
        if std_abs(SurfTempAbs - SkyTempAbs) > SmallNum:
            RadCoef = StefBoltzmann * self.TopThermAbs * (pow_4(SurfTempAbs) - pow_4(SkyTempAbs)) / (SurfTempAbs - SkyTempAbs)
        else:
            RadCoef = 0.0
        QSolAbsorbed = self.TopSolarAbs * (max(ThisSolarDirCosVert, 0.0) * ThisBeamSolarRad + ThisDifSolarRad)
        TempTop = (FluxTop + ConvCoef * ExternalTemp + RadCoef * ThisSkyTemp + QSolAbsorbed) / (ConvCoef + RadCoef)

    def CalcBottomSurfTemp(inout self, FluxBtm: Float64, inout TempBtm: Float64, ThisDryBulb: Float64, ThisWindSpeed: Float64, ThisGroundTemp: Float64):
        var ConvCoef: Float64
        var RadCoef: Float64
        var OldSurfTemp: Float64
        var SurfTempAbs: Float64
        var ExtTempAbs: Float64
        if self.LowerSurfCond == SurfCond_Exposed:
            OldSurfTemp = self.TbtmHistory[1]
            SurfTempAbs = OldSurfTemp + Constant.Kelvin
            ExtTempAbs = ThisDryBulb + Constant.Kelvin
            ConvCoef = Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)
            if std_abs(SurfTempAbs - ExtTempAbs) > SmallNum:
                RadCoef = StefBoltzmann * self.TopThermAbs * (pow_4(SurfTempAbs) - pow_4(ExtTempAbs)) / (SurfTempAbs - ExtTempAbs)
            else:
                RadCoef = 0.0
            TempBtm = (FluxBtm + ConvCoef * ThisDryBulb + RadCoef * ThisDryBulb) / (ConvCoef + RadCoef)
        else:
            TempBtm = ThisGroundTemp

    def UpdateSurfaceGroundHeatExchngr(inout self, state: EnergyPlusData):
        var SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
        var TimeStepSys = state.dataHVACGlobal.TimeStepSys
        var CpFluid: Float64
        self.QSrc = state.dataSurfaceGroundHeatExchangers.SourceFlux
        if self.LastSysTimeElapsed == SysTimeElapsed:
            self.QSrcAvg -= self.LastQSrc * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
            self.QSrcAvg += self.QSrc * TimeStepSys / state.dataGlobal.TimeStepZone
            self.LastQSrc = state.dataSurfaceGroundHeatExchangers.SourceFlux
            self.LastSysTimeElapsed = SysTimeElapsed
            self.LastTimeStepSys = TimeStepSys
        if self.plantLoc.loop.FluidName == "WATER":
            if self.InletTemp < 0.0:
                ShowRecurringWarningErrorAtEnd(state, "UpdateSurfaceGroundHeatExchngr: Water is frozen in Surf HX=" + self.Name, self.FrozenErrIndex2, self.InletTemp, self.InletTemp)
            self.InletTemp = max(self.InletTemp, 0.0)
        CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, "SurfaceGroundHeatExchanger:Update")
        PlantUtilities.SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        if (CpFluid > 0.0) and (state.dataSurfaceGroundHeatExchangers.FlowRate > 0.0):
            state.dataLoopNodes.Node[self.OutletNodeNum].Temp = self.InletTemp - self.SurfaceArea * state.dataSurfaceGroundHeatExchangers.SourceFlux / (state.dataSurfaceGroundHeatExchangers.FlowRate * CpFluid)
            state.dataLoopNodes.Node[self.OutletNodeNum].Enthalpy = state.dataLoopNodes.Node[self.OutletNodeNum].Temp * CpFluid

    def ReportSurfaceGroundHeatExchngr(inout self, state: EnergyPlusData):
        var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.OutletTemp = state.dataLoopNodes.Node[self.OutletNodeNum].Temp
        self.MassFlowRate = state.dataLoopNodes.Node[self.InletNodeNum].MassFlowRate
        self.HeatTransferRate = state.dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea
        self.SurfHeatTransferRate = self.SurfaceArea * (state.dataSurfaceGroundHeatExchangers.TopSurfFlux + state.dataSurfaceGroundHeatExchangers.BtmSurfFlux)
        self.Energy = state.dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea * TimeStepSysSec
        self.TopSurfaceTemp = state.dataSurfaceGroundHeatExchangers.TopSurfTemp
        self.BtmSurfaceTemp = state.dataSurfaceGroundHeatExchangers.BtmSurfTemp
        self.TopSurfaceFlux = state.dataSurfaceGroundHeatExchangers.TopSurfFlux
        self.BtmSurfaceFlux = state.dataSurfaceGroundHeatExchangers.BtmSurfFlux
        self.SurfEnergy = self.SurfaceArea * (state.dataSurfaceGroundHeatExchangers.TopSurfFlux + state.dataSurfaceGroundHeatExchangers.BtmSurfFlux) * TimeStepSysSec

    def oneTimeInit_new(inout self, state: EnergyPlusData):
        alias DesignVelocity: Float64 = 0.5
        var rho: Float64
        var errFlag: Bool
        errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.GrndHtExchgSurface, self.plantLoc, errFlag, None, None, None, None, None)
        if errFlag:
            ShowFatalError(state, "InitSurfaceGroundHeatExchanger: Program terminated due to previous condition(s).")
        rho = self.plantLoc.loop.glycol.getDensity(state, 0.0, "InitSurfaceGroundHeatExchanger")
        self.DesignMassFlowRate = Constant.Pi / 4.0 * pow_2(self.TubeDiameter) * DesignVelocity * rho * self.TubeCircuits
        PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)

    def oneTimeInit(inout self, state: EnergyPlusData):

def eoshiftArray(a: List[Float64], shift: Int32, initialValue: Float64) -> List[Float64]:
    var o = List[Float64]()
    for i in range(len(a)):
        o.append(initialValue)
    var b = 0 + max(shift, 0)
    var e = len(a) - 1 + min(shift, 0)
    var j = max(0 - shift, 0)
    var i = b
    while i <= e:
        o[j] = a[i]
        i += 1
        j += 1
    return o

def GetSurfaceGroundHeatExchanger(state: EnergyPlusData):
    var ErrorsFound: Bool = False
    var IOStatus: Int32
    var Item: Int32
    var NumAlphas: Int32
    var NumNumbers: Int32
    var cCurrentModuleObject = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "GroundHeatExchanger:Surface"
    var NumOfSurfaceGHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if len(state.dataSurfaceGroundHeatExchangers.SurfaceGHE) > 0:
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE.clear()
    for _ in range(NumOfSurfaceGHEs):
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE.append(SurfaceGroundHeatExchangerData())
    if len(state.dataSurfaceGroundHeatExchangers.CheckEquipName) > 0:
        state.dataSurfaceGroundHeatExchangers.CheckEquipName.clear()
    for _ in range(NumOfSurfaceGHEs):
        state.dataSurfaceGroundHeatExchangers.CheckEquipName.append(True)
    for Item in range(1, NumOfSurfaceGHEs + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            cCurrentModuleObject,
            Item,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus,
            "ignored",
            "ignored",
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames)
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name = state.dataIPShortCut.cAlphaArgs[1]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].ConstructionName = state.dataIPShortCut.cAlphaArgs[2]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].ConstructionNum = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs[2], state.dataConstruction.Construct)
        if state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].ConstructionNum == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[2] + "=" + state.dataIPShortCut.cAlphaArgs[2])
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ErrorsFound = True
        if not state.dataConstruction.Construct[state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].ConstructionNum].SourceSinkPresent:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[2] + "=" + state.dataIPShortCut.cAlphaArgs[2])
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Construction must have internal source/sink and be referenced by a ConstructionProperty:InternalHeatSource object")
            ErrorsFound = True
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].InletNode = state.dataIPShortCut.cAlphaArgs[3]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].InletNodeNum = Node.GetOnlySingleNode(state,
            state.dataIPShortCut.cAlphaArgs[3],
            ErrorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSurface,
            state.dataIPShortCut.cAlphaArgs[1],
            Node.FluidType.Water,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        if state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].InletNodeNum == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[3] + "=" + state.dataIPShortCut.cAlphaArgs[3])
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ErrorsFound = True
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].OutletNode = state.dataIPShortCut.cAlphaArgs[4]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].OutletNodeNum = Node.GetOnlySingleNode(state,
            state.dataIPShortCut.cAlphaArgs[4],
            ErrorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSurface,
            state.dataIPShortCut.cAlphaArgs[1],
            Node.FluidType.Water,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        if state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].OutletNodeNum == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[4] + "=" + state.dataIPShortCut.cAlphaArgs[4])
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ErrorsFound = True
        Node.TestCompSet(state,
            cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[3],
            state.dataIPShortCut.cAlphaArgs[4],
            "Condenser Water Nodes")
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].TubeDiameter = state.dataIPShortCut.rNumericArgs[1]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].TubeCircuits = state.dataIPShortCut.rNumericArgs[2]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].TubeSpacing = state.dataIPShortCut.rNumericArgs[3]
        if state.dataIPShortCut.rNumericArgs[2] == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[2] + "=" + String(state.dataIPShortCut.rNumericArgs[2]))
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[3] == 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[3] + "=" + String(state.dataIPShortCut.rNumericArgs[3]))
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].SurfaceLength = state.dataIPShortCut.rNumericArgs[4]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].SurfaceWidth = state.dataIPShortCut.rNumericArgs[5]
        if state.dataIPShortCut.rNumericArgs[4] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[4] + "=" + String(state.dataIPShortCut.rNumericArgs[4]))
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[5] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[5] + "=" + String(state.dataIPShortCut.rNumericArgs[5]))
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if Util.SameString(state.dataIPShortCut.cAlphaArgs[5], "GROUND"):
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].LowerSurfCond = SurfCond_Ground
        elif Util.SameString(state.dataIPShortCut.cAlphaArgs[5], "EXPOSED"):
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].LowerSurfCond = SurfCond_Exposed
        else:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[5] + "=" + state.dataIPShortCut.cAlphaArgs[5])
            ShowContinueError(state, "Entered in " + cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Only \"Ground\" or \"Exposed\" is allowed.")
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing input for " + cCurrentModuleObject)
    for Item in range(1, NumOfSurfaceGHEs + 1):
        SetupOutputVariable(state,
            "Ground Heat Exchanger Heat Transfer Rate",
            Constant.Units.W,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].HeatTransferRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Surface Heat Transfer Rate",
            Constant.Units.W,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].SurfHeatTransferRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Heat Transfer Energy",
            Constant.Units.J,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Mass Flow Rate",
            Constant.Units.kg_s,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].MassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Inlet Temperature",
            Constant.Units.C,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].InletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Outlet Temperature",
            Constant.Units.C,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].OutletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Top Surface Temperature",
            Constant.Units.C,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].TopSurfaceTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Bottom Surface Temperature",
            Constant.Units.C,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].BtmSurfaceTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Top Surface Heat Transfer Energy per Area",
            Constant.Units.J_m2,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].TopSurfaceFlux,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Bottom Surface Heat Transfer Energy per Area",
            Constant.Units.J_m2,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].BtmSurfaceFlux,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Surface Heat Transfer Energy",
            Constant.Units.J,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].SurfEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
        SetupOutputVariable(state,
            "Ground Heat Exchanger Source Temperature",
            Constant.Units.C,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].SourceTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item].Name)
    if state.dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning:
        if not state.dataEnvrn.GroundTempInputs[Int32(DataEnvironment.GroundTempType.Shallow)]:
            ShowWarningError(state, "GetSurfaceGroundHeatExchanger: No \"Site:GroundTemperature:Shallow\" were input.")
            ShowContinueError(state, "Defaults, constant throughout the year of (" + String(state.dataEnvrn.GroundTemp[Int32(DataEnvironment.GroundTempType.Shallow)]) + ") will be used.")
            state.dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning = False

struct SurfaceGroundHeatExchangersData:
    var NoSurfaceGroundTempObjWarning: Bool = True
    var FlowRate: Float64 = 0.0
    var TopSurfTemp: Float64 = 0.0
    var BtmSurfTemp: Float64 = 0.0
    var TopSurfFlux: Float64 = 0.0
    var BtmSurfFlux: Float64 = 0.0
    var SourceFlux: Float64 = 0.0
    var CheckEquipName: List[Bool]
    var PastBeamSolarRad: Float64 = 0.0
    var PastSolarDirCosVert: Float64 = 0.0
    var PastDifSolarRad: Float64 = 0.0
    var PastGroundTemp: Float64 = 0.0
    var PastIsRain: Bool = False
    var PastIsSnow: Bool = False
    var PastOutDryBulbTemp: Float64 = 0.0
    var PastOutWetBulbTemp: Float64 = 0.0
    var PastSkyTemp: Float64 = 0.0
    var PastWindSpeed: Float64 = 0.0
    var GetInputFlag: Bool = True
    var QRadSysSrcAvg: List[Float64]
    var LastSysTimeElapsed: List[Float64]
    var LastTimeStepSys: List[Float64]
    var InitializeTempTop: Bool = False
    var SurfaceGHE: List[SurfaceGroundHeatExchangerData]
    var FluxTop: Float64
    var FluxBtm: Float64
    var TempBtm: Float64
    var TempTop: Float64

    def __init__(inout self):
        self.NoSurfaceGroundTempObjWarning = True
        self.FlowRate = 0.0
        self.TopSurfTemp = 0.0
        self.BtmSurfTemp = 0.0
        self.TopSurfFlux = 0.0
        self.BtmSurfFlux = 0.0
        self.SourceFlux = 0.0
        self.CheckEquipName = []
        self.PastBeamSolarRad = 0.0
        self.PastSolarDirCosVert = 0.0
        self.PastDifSolarRad = 0.0
        self.PastGroundTemp = 0.0
        self.PastIsRain = False
        self.PastIsSnow = False
        self.PastOutDryBulbTemp = 0.0
        self.PastOutWetBulbTemp = 0.0
        self.PastSkyTemp = 0.0
        self.PastWindSpeed = 0.0
        self.GetInputFlag = True
        self.QRadSysSrcAvg = []
        self.LastSysTimeElapsed = []
        self.LastTimeStepSys = []
        self.InitializeTempTop = False
        self.SurfaceGHE = []
        self.FluxTop = 0.0
        self.FluxBtm = 0.0
        self.TempBtm = 0.0
        self.TempTop = 0.0

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NoSurfaceGroundTempObjWarning = True
        self.FlowRate = 0.0
        self.TopSurfTemp = 0.0
        self.BtmSurfTemp = 0.0
        self.TopSurfFlux = 0.0
        self.BtmSurfFlux = 0.0
        self.SourceFlux = 0.0
        self.CheckEquipName.clear()
        self.PastBeamSolarRad = 0.0
        self.PastSolarDirCosVert = 0.0
        self.PastDifSolarRad = 0.0
        self.PastGroundTemp = 0.0
        self.PastIsRain = False
        self.PastIsSnow = False
        self.PastOutDryBulbTemp = 0.0
        self.PastOutWetBulbTemp = 0.0
        self.PastSkyTemp = 0.0
        self.PastWindSpeed = 0.0
        self.GetInputFlag = True
        self.QRadSysSrcAvg.clear()
        self.LastSysTimeElapsed.clear()
        self.LastTimeStepSys.clear()
        self.InitializeTempTop = False
        self.SurfaceGHE.clear()