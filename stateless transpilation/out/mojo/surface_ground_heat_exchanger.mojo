"""
EnergyPlus Surface Ground Heat Exchanger module (Mojo)
Faithful Mojo port of SurfaceGroundHeatExchanger.cc
"""

from math import pow, exp, max as math_max
from collections.deque import deque

alias SmallNum = 1.0e-30
alias StefBoltzmann = 5.6697e-08
alias SurfaceHXHeight = 0.0
alias SurfCond_Ground = 1
alias SurfCond_Exposed = 2
alias MaxCTFTerms = 20


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object struct (main global data bundle)
# - PlantLocation: struct with loop field (has glycol, FluidName, FluidIndex) and PlantLoop chain
# - PlantComponent: base struct interface (factory, simulate, oneTimeInit, oneTimeInit_new)
# - BaseGlobalStruct: base struct for global data containers
# - Material.SurfaceRoughness: enum type (Invalid, Smooth, Rough, MediumRough, MediumSmooth)
# - Construction.MaxCTFTerms: compile-time constant (integer array dimension)
# - DataPlant.PlantEquipmentType: enum including GrndHtExchgSurface
# - Constant.Kelvin: SIMD[Float64, 1] = 273.15
# - Constant.Pi: SIMD[Float64, 1] = 3.14159265358979323846
# - Constant.Units: output units registry struct
# - OutputProcessor.TimeStepType, StoreType: enums
# - Node.GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent: functions and enums
# - InputProcessor.getObjectItem, getNumObjectsFound: methods on inputProcessor
# - Util.FindItemInList, SameString: functions
# - Convect.CalcASHRAESimpExtConvCoeff: function
# - DataEnvironment: module with GroundTempType enum, OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt functions
# - DataPrecisionGlobals.EXP_LowerLimit: Float64 constant
# - PlantUtilities: RegulateCondenserCompFlowReqOp, SetComponentFlowRate, SafeCopyPlantNode, InitComponentNodes, RegisterPlantCompDesignFlow, ScanPlantLoopsForObject functions
# - OutputProcessor.SetupOutputVariable: function
# - General/UtilityRoutines: ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningMessage, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowWarningError functions


fn eoshiftArray(a: List[Float64], shift: Int, initialValue: Float64) -> List[Float64]:
    """Shift array by shift positions, filling with initialValue."""
    let size = len(a)
    var o = List[Float64](capacity=size)
    for _ in range(size):
        o.append(initialValue)
    
    let b = max(shift, 0)
    let e = size - 1 + min(shift, 0)
    var j = max(-shift, 0)
    for i in range(b, e + 1):
        o[j] = a[i]
        j += 1
    return o


@value
struct SurfaceGroundHeatExchangerData:
    """Surface Ground Heat Exchanger data structure."""
    
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
    var TopRoughness: Int32
    var BtmRoughness: Int32
    var FrozenErrIndex1: Int32
    var FrozenErrIndex2: Int32
    var ConvErrIndex1: Int32
    var ConvErrIndex2: Int32
    var ConvErrIndex3: Int32
    var plantLoc: UnsafePointer[PlantLocation]
    
    var TsrcConstCoef: Float64
    var TsrcVarCoef: Float64
    var QbtmConstCoef: Float64
    var QbtmVarCoef: Float64
    var QtopConstCoef: Float64
    var QtopVarCoef: Float64
    var NumCTFTerms: Int32
    
    var CTFin: InlineArray[Float64, MaxCTFTerms]
    var CTFout: InlineArray[Float64, MaxCTFTerms]
    var CTFcross: InlineArray[Float64, MaxCTFTerms]
    var CTFflux: InlineArray[Float64, MaxCTFTerms]
    var CTFSourceIn: InlineArray[Float64, MaxCTFTerms]
    var CTFSourceOut: InlineArray[Float64, MaxCTFTerms]
    var CTFTSourceOut: InlineArray[Float64, MaxCTFTerms]
    var CTFTSourceIn: InlineArray[Float64, MaxCTFTerms]
    var CTFTSourceQ: InlineArray[Float64, MaxCTFTerms]
    
    var TbtmHistory: InlineArray[Float64, MaxCTFTerms]
    var TtopHistory: InlineArray[Float64, MaxCTFTerms]
    var TsrcHistory: InlineArray[Float64, MaxCTFTerms]
    var QbtmHistory: InlineArray[Float64, MaxCTFTerms]
    var QtopHistory: InlineArray[Float64, MaxCTFTerms]
    var QsrcHistory: InlineArray[Float64, MaxCTFTerms]
    
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

    fn __init__(inout self):
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
        self.TopRoughness = 0
        self.BtmRoughness = 0
        self.FrozenErrIndex1 = 0
        self.FrozenErrIndex2 = 0
        self.ConvErrIndex1 = 0
        self.ConvErrIndex2 = 0
        self.ConvErrIndex3 = 0
        self.plantLoc = UnsafePointer[PlantLocation]()
        
        self.TsrcConstCoef = 0.0
        self.TsrcVarCoef = 0.0
        self.QbtmConstCoef = 0.0
        self.QbtmVarCoef = 0.0
        self.QtopConstCoef = 0.0
        self.QtopVarCoef = 0.0
        self.NumCTFTerms = 0
        
        self.CTFin = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFout = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFcross = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFflux = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFSourceIn = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFSourceOut = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTSourceOut = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTSourceIn = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTSourceQ = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        
        self.TbtmHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.TtopHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.TsrcHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.QbtmHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.QtopHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.QsrcHistory = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        
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

    fn simulate(inout self, state: UnsafePointer[EnergyPlusData],
                calledFromLocation: PlantLocation,
                FirstHVACIteration: Bool,
                inout CurLoad: Float64,
                RunFlag: Bool):
        """Main simulate routine."""
        self.InitSurfaceGroundHeatExchanger(state)
        self.CalcSurfaceGroundHeatExchanger(state, FirstHVACIteration)
        self.UpdateSurfaceGroundHeatExchngr(state)
        self.ReportSurfaceGroundHeatExchngr(state)

    fn InitSurfaceGroundHeatExchanger(inout self, state: UnsafePointer[EnergyPlusData]):
        """Initialize surface ground heat exchanger."""
        if self.InitQTF:
            let num_constructs = state[].dataHeatBal.TotConstructs
            for Cons in range(1, num_constructs + 1):
                if state[].dataConstruction.Construct[Cons - 1].Name == self.ConstructionName:
                    let LayerNum = state[].dataConstruction.Construct[Cons - 1].TotLayers
                    self.NumCTFTerms = state[].dataConstruction.Construct[Cons - 1].NumCTFTerms
                    let ctr = state[].dataConstruction.Construct[Cons - 1]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFInside)))):
                        self.CTFin[i] = ctr.CTFInside[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFOutside)))):
                        self.CTFout[i] = ctr.CTFOutside[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFCross)))):
                        self.CTFcross[i] = ctr.CTFCross[i]
                    for i in range(1, min(int(MaxCTFTerms), int(len(ctr.CTFFlux)))):
                        self.CTFflux[i] = ctr.CTFFlux[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFSourceIn)))):
                        self.CTFSourceIn[i] = ctr.CTFSourceIn[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFSourceOut)))):
                        self.CTFSourceOut[i] = ctr.CTFSourceOut[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFTSourceOut)))):
                        self.CTFTSourceOut[i] = ctr.CTFTSourceOut[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFTSourceIn)))):
                        self.CTFTSourceIn[i] = ctr.CTFTSourceIn[i]
                    for i in range(min(int(MaxCTFTerms), int(len(ctr.CTFTSourceQ)))):
                        self.CTFTSourceQ[i] = ctr.CTFTSourceQ[i]
                    self.ConstructionNum = Cons
            self.InitQTF = False

        if self.MyEnvrnFlag and state[].dataGlobal.BeginEnvrnFlag:
            let OutDryBulb = state[].dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            self.CTFflux[0] = 0.0
            for i in range(MaxCTFTerms):
                self.TsrcHistory[i] = OutDryBulb
                self.TbtmHistory[i] = OutDryBulb
                self.TtopHistory[i] = OutDryBulb
                self.QbtmHistory[i] = 0.0
                self.QtopHistory[i] = 0.0
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
            
            state[].dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state[].dataEnvrn.BeamSolarRad
            state[].dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state[].dataEnvrn.SOLCOS[2]
            state[].dataSurfaceGroundHeatExchangers.PastDifSolarRad = state[].dataEnvrn.DifSolarRad
            state[].dataSurfaceGroundHeatExchangers.PastGroundTemp = state[].dataEnvrn.GroundTemp[int(state[].dataEnvrn.GroundTempType.Shallow)]
            state[].dataSurfaceGroundHeatExchangers.PastIsRain = state[].dataEnvrn.IsRain
            state[].dataSurfaceGroundHeatExchangers.PastIsSnow = state[].dataEnvrn.IsSnow
            state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = state[].dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            state[].dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = state[].dataEnvrn.OutWetBulbTempAt(state, SurfaceHXHeight)
            state[].dataSurfaceGroundHeatExchangers.PastSkyTemp = state[].dataEnvrn.SkyTemp
            state[].dataSurfaceGroundHeatExchangers.PastWindSpeed = state[].dataEnvrn.WindSpeedAt(state, SurfaceHXHeight)
            self.MyEnvrnFlag = False

        if not state[].dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        self.SurfaceArea = self.SurfaceLength * self.SurfaceWidth
        let DesignFlow = state[].PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc[], self.DesignMassFlowRate)
        state[].PlantUtilities.SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc[])
        state[].dataSurfaceGroundHeatExchangers.FlowRate = state[].dataLoopNodes.Node[self.InletNodeNum - 1].MassFlowRate

    fn CalcSurfaceGroundHeatExchanger(inout self, state: UnsafePointer[EnergyPlusData], FirstHVACIteration: Bool):
        """Calculate surface ground heat exchanger."""
        let SurfFluxTol = 0.001
        let SrcFluxTol = 0.001
        let RelaxT = 0.1
        let Maxiter = 100
        let Maxiter1 = 100

        if FirstHVACIteration and not state[].dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            var FluxTop = state[].dataSurfaceGroundHeatExchangers.FluxTop
            var FluxBtm = state[].dataSurfaceGroundHeatExchangers.FluxBtm
            var TempBtm = state[].dataSurfaceGroundHeatExchangers.TempBtm
            var TempTop = state[].dataSurfaceGroundHeatExchangers.TempTop

            self.firstTimeThrough = False
            state[].dataSurfaceGroundHeatExchangers.SourceFlux = self.QSrcAvg
            
            var PastTempBtm = self.TbtmHistory[1]
            var PastTempTop = self.TtopHistory[1]
            var OldPastFluxTop = 1.0e+30
            var OldPastFluxBtm = 1.0e+30
            var TempB = 0.0
            var TempT = 0.0
            var iter_count = 0
            
            while True:
                iter_count += 1
                self.CalcTopFluxCoefficents(PastTempBtm, PastTempTop)
                var PastFluxTop = self.QtopConstCoef + self.QtopVarCoef * state[].dataSurfaceGroundHeatExchangers.SourceFlux
                
                self.CalcTopSurfTemp(-PastFluxTop, inout TempT,
                                     state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                     state[].dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                                     state[].dataSurfaceGroundHeatExchangers.PastSkyTemp,
                                     state[].dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                                     state[].dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                                     state[].dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                                     state[].dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                     state[].dataSurfaceGroundHeatExchangers.PastIsRain,
                                     state[].dataSurfaceGroundHeatExchangers.PastIsSnow)
                PastTempTop = PastTempTop * (1.0 - RelaxT) + RelaxT * TempT

                self.CalcBottomFluxCoefficents(PastTempBtm, PastTempTop)
                var PastFluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state[].dataSurfaceGroundHeatExchangers.SourceFlux

                if (abs((OldPastFluxTop - PastFluxTop) / OldPastFluxTop) <= SurfFluxTol and
                    abs((OldPastFluxBtm - PastFluxBtm) / OldPastFluxBtm) <= SurfFluxTol):
                    break

                self.CalcBottomSurfTemp(PastFluxBtm, inout TempB,
                                       state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                       state[].dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                       state[].dataSurfaceGroundHeatExchangers.PastGroundTemp)
                PastTempBtm = PastTempBtm * (1.0 - RelaxT) + RelaxT * TempB
                OldPastFluxTop = PastFluxTop
                OldPastFluxBtm = PastFluxBtm

                if iter_count > Maxiter:
                    break

            if not state[].dataSurfaceGroundHeatExchangers.InitializeTempTop:
                TempTop = TempT
                TempBtm = TempB
                FluxTop = OldPastFluxTop
                FluxBtm = OldPastFluxBtm
                state[].dataSurfaceGroundHeatExchangers.InitializeTempTop = True

            state[].dataSurfaceGroundHeatExchangers.TopSurfTemp = TempTop
            state[].dataSurfaceGroundHeatExchangers.BtmSurfTemp = TempBtm
            state[].dataSurfaceGroundHeatExchangers.TopSurfFlux = -FluxTop
            state[].dataSurfaceGroundHeatExchangers.BtmSurfFlux = FluxBtm

            self.CalcSourceTempCoefficents(PastTempBtm, PastTempTop)
            self.SourceTemp = self.TsrcConstCoef + self.TsrcVarCoef * state[].dataSurfaceGroundHeatExchangers.SourceFlux
            self.UpdateHistories(state, PastFluxTop, PastFluxBtm, state[].dataSurfaceGroundHeatExchangers.SourceFlux, self.SourceTemp)

            self.QSrcAvg = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0

            state[].dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state[].dataEnvrn.BeamSolarRad
            state[].dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state[].dataEnvrn.SOLCOS[2]
            state[].dataSurfaceGroundHeatExchangers.PastDifSolarRad = state[].dataEnvrn.DifSolarRad
            state[].dataSurfaceGroundHeatExchangers.PastGroundTemp = state[].dataEnvrn.GroundTemp[int(state[].dataEnvrn.GroundTempType.Shallow)]
            state[].dataSurfaceGroundHeatExchangers.PastIsRain = state[].dataEnvrn.IsRain
            state[].dataSurfaceGroundHeatExchangers.PastIsSnow = state[].dataEnvrn.IsSnow
            state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = state[].dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            state[].dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = state[].dataEnvrn.OutWetBulbTempAt(state, SurfaceHXHeight)
            state[].dataSurfaceGroundHeatExchangers.PastSkyTemp = state[].dataEnvrn.SkyTemp
            state[].dataSurfaceGroundHeatExchangers.PastWindSpeed = state[].dataEnvrn.WindSpeedAt(state, SurfaceHXHeight)

            TempBtm = self.TbtmHistory[1]
            TempTop = self.TtopHistory[1]
            var OldFluxTop = 1.0e+30
            var OldFluxBtm = 1.0e+30
            var OldSourceFlux = 1.0e+30
            state[].dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)
            iter_count = 0
            
            while True:
                iter_count += 1
                var iter1_count = 0
                while True:
                    iter1_count += 1
                    self.CalcTopFluxCoefficents(TempBtm, TempTop)
                    FluxTop = self.QtopConstCoef + self.QtopVarCoef * state[].dataSurfaceGroundHeatExchangers.SourceFlux
                    self.CalcTopSurfTemp(-FluxTop, inout TempT,
                                        state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                        state[].dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                                        state[].dataSurfaceGroundHeatExchangers.PastSkyTemp,
                                        state[].dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                                        state[].dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                                        state[].dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                                        state[].dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                        state[].dataSurfaceGroundHeatExchangers.PastIsRain,
                                        state[].dataSurfaceGroundHeatExchangers.PastIsSnow)
                    TempTop = TempTop * (1.0 - RelaxT) + RelaxT * TempT
                    self.CalcBottomFluxCoefficents(TempBtm, TempTop)
                    FluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state[].dataSurfaceGroundHeatExchangers.SourceFlux
                    
                    if (abs((OldFluxTop - FluxTop) / OldFluxTop) <= SurfFluxTol and
                        abs((OldFluxBtm - FluxBtm) / OldFluxBtm) <= SurfFluxTol):
                        break

                    self.CalcBottomSurfTemp(FluxBtm, inout TempB,
                                           state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                           state[].dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                           state[].dataEnvrn.GroundTemp[int(state[].dataEnvrn.GroundTempType.Shallow)])
                    TempBtm = TempBtm * (1.0 - RelaxT) + RelaxT * TempB
                    OldFluxBtm = FluxBtm
                    OldFluxTop = FluxTop

                    if iter1_count > Maxiter1:
                        break

                self.CalcSourceTempCoefficents(TempBtm, TempTop)
                state[].dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)
                
                if abs((OldSourceFlux - state[].dataSurfaceGroundHeatExchangers.SourceFlux) / (1.0e-20 + OldSourceFlux)) <= SrcFluxTol:
                    break
                OldSourceFlux = state[].dataSurfaceGroundHeatExchangers.SourceFlux

                if iter_count > Maxiter:
                    break

        elif not FirstHVACIteration:
            self.firstTimeThrough = True
            state[].dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)

    fn CalcBottomFluxCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        """Calculate bottom flux coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.QbtmConstCoef = 0.0
        for Term in range(int(self.NumCTFTerms)):
            self.QbtmConstCoef += ((-self.CTFin[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFcross[Term] * self.TtopHistory[Term]) +
                                   (self.CTFflux[Term] * self.QbtmHistory[Term]) +
                                   (self.CTFSourceIn[Term] * self.QsrcHistory[Term]))

        self.QbtmConstCoef -= self.CTFSourceIn[0] * self.QsrcHistory[0]
        self.QbtmVarCoef = self.CTFSourceIn[0]

    fn CalcTopFluxCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        """Calculate top flux coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.QtopConstCoef = 0.0
        for Term in range(int(self.NumCTFTerms)):
            self.QtopConstCoef += ((self.CTFout[Term] * self.TtopHistory[Term]) -
                                   (self.CTFcross[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFflux[Term] * self.QtopHistory[Term]) +
                                   (self.CTFSourceOut[Term] * self.QsrcHistory[Term]))

        self.QtopConstCoef -= self.CTFSourceOut[0] * self.QsrcHistory[0]
        self.QtopVarCoef = self.CTFSourceOut[0]

    fn CalcSourceTempCoefficents(inout self, Tbottom: Float64, Ttop: Float64):
        """Calculate source temperature coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.TsrcConstCoef = 0.0
        for Term in range(int(self.NumCTFTerms)):
            self.TsrcConstCoef += ((self.CTFTSourceIn[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFTSourceOut[Term] * self.TtopHistory[Term]) +
                                   (self.CTFflux[Term] * self.TsrcHistory[Term]) +
                                   (self.CTFTSourceQ[Term] * self.QsrcHistory[Term]))

        self.TsrcConstCoef -= self.CTFTSourceQ[0] * self.QsrcHistory[0]
        self.TsrcVarCoef = self.CTFTSourceQ[0]

    fn CalcSourceFlux(inout self, state: UnsafePointer[EnergyPlusData]) -> Float64:
        """Calculate source flux."""
        if state[].dataSurfaceGroundHeatExchangers.FlowRate > 0.0:
            let EpsMdotCp = self.CalcHXEffectTerm(state, self.InletTemp, state[].dataSurfaceGroundHeatExchangers.FlowRate)
            return (self.InletTemp - self.TsrcConstCoef) / (self.SurfaceArea / EpsMdotCp + self.TsrcVarCoef)
        else:
            return 0.0

    fn UpdateHistories(inout self, state: UnsafePointer[EnergyPlusData], TopFlux: Float64, BottomFlux: Float64, sourceFlux: Float64, sourceTemp: Float64):
        """Update temperature and flux histories."""
        var new_ttop = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        var new_tbtm = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        var new_tsrc = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        var new_qbtm = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        var new_qtop = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        var new_qsrc = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        
        var j = 1
        for i in range(MaxCTFTerms - 1):
            new_ttop[j] = self.TtopHistory[i]
            new_tbtm[j] = self.TbtmHistory[i]
            new_tsrc[j] = self.TsrcHistory[i]
            new_qbtm[j] = self.QbtmHistory[i]
            new_qtop[j] = self.QtopHistory[i]
            new_qsrc[j] = self.QsrcHistory[i]
            j += 1
        
        self.TtopHistory = new_ttop
        self.TbtmHistory = new_tbtm
        self.TsrcHistory = new_tsrc
        self.QbtmHistory = new_qbtm
        self.QtopHistory = new_qtop
        self.QsrcHistory = new_qsrc
        
        self.TsrcHistory[1] = sourceTemp
        self.QbtmHistory[1] = BottomFlux
        self.QtopHistory[1] = TopFlux
        self.QsrcHistory[1] = sourceFlux

    fn CalcHXEffectTerm(inout self, state: UnsafePointer[EnergyPlusData], Temperature: Float64, WaterMassFlow: Float64) -> Float64:
        """Calculate heat exchanger effectiveness term."""
        let MaxLaminarRe = 2300.0
        let WaterIndex = 1
        
        # Temperature table for water properties
        let Temps = InlineArray[Float64, 13](
            1.85, 6.85, 11.85, 16.85, 21.85, 26.85, 31.85, 36.85, 41.85, 46.85, 51.85, 56.85, 61.85)
        let Mu = InlineArray[Float64, 13](
            0.001652, 0.001422, 0.001225, 0.00108, 0.000959, 0.000855, 0.000769, 0.000695, 0.000631, 0.000577, 0.000528, 0.000489, 0.000453)
        let Conductivity = InlineArray[Float64, 13](
            0.574, 0.582, 0.590, 0.598, 0.606, 0.613, 0.620, 0.628, 0.634, 0.640, 0.645, 0.650, 0.656)
        let Pr = InlineArray[Float64, 13](
            12.22, 10.26, 8.81, 7.56, 6.62, 5.83, 5.20, 4.62, 4.16, 3.77, 3.42, 3.15, 2.88)

        var Index = 0
        while Index < 13:
            if Temperature < Temps[Index]:
                break
            Index += 1

        var MUactual: Float64
        var Kactual: Float64
        var PRactual: Float64
        
        if Index == 0:
            MUactual = Mu[0]
            Kactual = Conductivity[0]
            PRactual = Pr[0]
        elif Index >= 13:
            Index = 12
            MUactual = Mu[12]
            Kactual = Conductivity[12]
            PRactual = Pr[12]
        else:
            let InterpFrac = (Temperature - Temps[Index - 1]) / (Temps[Index] - Temps[Index - 1])
            MUactual = Mu[Index - 1] + InterpFrac * (Mu[Index] - Mu[Index - 1])
            Kactual = Conductivity[Index - 1] + InterpFrac * (Conductivity[Index] - Conductivity[Index - 1])
            PRactual = Pr[Index - 1] + InterpFrac * (Pr[Index] - Pr[Index - 1])

        if Temperature < 0.0:
            if self.plantLoc[].loop.FluidIndex == WaterIndex:
                self.InletTemp = max(self.InletTemp, 0.0)

        let CpWater = self.plantLoc[].loop.glycol.getSpecificHeat(state, Temperature, "SurfaceGroundHeatExchanger:CalcHXEffectTerm")
        let Pi = 3.141592653589793

        let ReD = 4.0 * WaterMassFlow / (Pi * MUactual * self.TubeDiameter * Float64(self.TubeCircuits))

        var NuD: Float64
        if ReD >= MaxLaminarRe:
            NuD = 0.023 * pow(ReD, 0.8) * pow(PRactual, 1.0 / 3.0)
        else:
            NuD = 3.66

        let PipeLength = self.SurfaceLength * self.SurfaceWidth / self.TubeSpacing
        let NTU = Pi * Kactual * NuD * PipeLength / (WaterMassFlow * CpWater)
        let EXP_LowerLimit = state[].DataPrecisionGlobals.EXP_LowerLimit
        
        if -NTU >= EXP_LowerLimit:
            return (1.0 - exp(-NTU)) * WaterMassFlow * CpWater
        else:
            return 1.0 * WaterMassFlow * CpWater

    fn CalcTopSurfTemp(inout self, FluxTop: Float64, inout TempTop: Float64, ThisDryBulb: Float64, ThisWetBulb: Float64,
                        ThisSkyTemp: Float64, ThisBeamSolarRad: Float64, ThisDifSolarRad: Float64,
                        ThisSolarDirCosVert: Float64, ThisWindSpeed: Float64, ThisIsRain: Bool, ThisIsSnow: Bool):
        """Calculate top surface temperature."""
        let Kelvin = 273.15
        
        let ExternalTemp = ThisIsSnow or ThisIsRain ? ThisWetBulb : ThisDryBulb

        let OldSurfTemp = self.TtopHistory[1]
        let SurfTempAbs = OldSurfTemp + Kelvin
        let SkyTempAbs = ThisSkyTemp + Kelvin

        let ConvCoef = state[].Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)
        
        var RadCoef: Float64
        if abs(SurfTempAbs - SkyTempAbs) > SmallNum:
            RadCoef = StefBoltzmann * self.TopThermAbs * (pow(SurfTempAbs, 4) - pow(SkyTempAbs, 4)) / (SurfTempAbs - SkyTempAbs)
        else:
            RadCoef = 0.0

        let QSolAbsorbed = self.TopSolarAbs * (max(ThisSolarDirCosVert, 0.0) * ThisBeamSolarRad + ThisDifSolarRad)
        TempTop = (FluxTop + ConvCoef * ExternalTemp + RadCoef * ThisSkyTemp + QSolAbsorbed) / (ConvCoef + RadCoef)

    fn CalcBottomSurfTemp(inout self, FluxBtm: Float64, inout TempBtm: Float64, ThisDryBulb: Float64,
                           ThisWindSpeed: Float64, ThisGroundTemp: Float64):
        """Calculate bottom surface temperature."""
        let Kelvin = 273.15
        
        if self.LowerSurfCond == SurfCond_Exposed:
            let OldSurfTemp = self.TbtmHistory[1]
            let SurfTempAbs = OldSurfTemp + Kelvin
            let ExtTempAbs = ThisDryBulb + Kelvin

            let ConvCoef = state[].Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)

            var RadCoef: Float64
            if abs(SurfTempAbs - ExtTempAbs) > SmallNum:
                RadCoef = StefBoltzmann * self.TopThermAbs * (pow(SurfTempAbs, 4) - pow(ExtTempAbs, 4)) / (SurfTempAbs - ExtTempAbs)
            else:
                RadCoef = 0.0

            TempBtm = (FluxBtm + ConvCoef * ThisDryBulb + RadCoef * ThisDryBulb) / (ConvCoef + RadCoef)
        else:
            TempBtm = ThisGroundTemp

    fn UpdateSurfaceGroundHeatExchngr(inout self, state: UnsafePointer[EnergyPlusData]):
        """Update surface ground heat exchanger."""
        let SysTimeElapsed = state[].dataHVACGlobal.SysTimeElapsed
        let TimeStepSys = state[].dataHVACGlobal.TimeStepSys

        self.QSrc = state[].dataSurfaceGroundHeatExchangers.SourceFlux

        if self.LastSysTimeElapsed == SysTimeElapsed:
            self.QSrcAvg -= self.LastQSrc * self.LastTimeStepSys / state[].dataGlobal.TimeStepZone
            self.QSrcAvg += self.QSrc * TimeStepSys / state[].dataGlobal.TimeStepZone
            self.LastQSrc = state[].dataSurfaceGroundHeatExchangers.SourceFlux
            self.LastSysTimeElapsed = SysTimeElapsed
            self.LastTimeStepSys = TimeStepSys

        if self.plantLoc[].loop.FluidName == "WATER":
            if self.InletTemp < 0.0:
                pass
            self.InletTemp = max(self.InletTemp, 0.0)

        let CpFluid = self.plantLoc[].loop.glycol.getSpecificHeat(state, self.InletTemp, "SurfaceGroundHeatExchanger:Update")

        state[].PlantUtilities.SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        if CpFluid > 0.0 and state[].dataSurfaceGroundHeatExchangers.FlowRate > 0.0:
            state[].dataLoopNodes.Node[self.OutletNodeNum - 1].Temp = (self.InletTemp - self.SurfaceArea *
                                                                      state[].dataSurfaceGroundHeatExchangers.SourceFlux /
                                                                      (state[].dataSurfaceGroundHeatExchangers.FlowRate * CpFluid))
            state[].dataLoopNodes.Node[self.OutletNodeNum - 1].Enthalpy = state[].dataLoopNodes.Node[self.OutletNodeNum - 1].Temp * CpFluid

    fn ReportSurfaceGroundHeatExchngr(inout self, state: UnsafePointer[EnergyPlusData]):
        """Report surface ground heat exchanger."""
        let TimeStepSysSec = state[].dataHVACGlobal.TimeStepSysSec

        self.InletTemp = state[].dataLoopNodes.Node[self.InletNodeNum - 1].Temp
        self.OutletTemp = state[].dataLoopNodes.Node[self.OutletNodeNum - 1].Temp
        self.MassFlowRate = state[].dataLoopNodes.Node[self.InletNodeNum - 1].MassFlowRate

        self.HeatTransferRate = state[].dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea
        self.SurfHeatTransferRate = (self.SurfaceArea *
                                     (state[].dataSurfaceGroundHeatExchangers.TopSurfFlux + state[].dataSurfaceGroundHeatExchangers.BtmSurfFlux))
        self.Energy = state[].dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea * TimeStepSysSec
        self.TopSurfaceTemp = state[].dataSurfaceGroundHeatExchangers.TopSurfTemp
        self.BtmSurfaceTemp = state[].dataSurfaceGroundHeatExchangers.BtmSurfTemp
        self.TopSurfaceFlux = state[].dataSurfaceGroundHeatExchangers.TopSurfFlux
        self.BtmSurfaceFlux = state[].dataSurfaceGroundHeatExchangers.BtmSurfFlux
        self.SurfEnergy = (self.SurfaceArea *
                          (state[].dataSurfaceGroundHeatExchangers.TopSurfFlux + state[].dataSurfaceGroundHeatExchangers.BtmSurfFlux) *
                          TimeStepSysSec)

    fn oneTimeInit(inout self, state: UnsafePointer[EnergyPlusData]):
        """One-time initialization (empty stub)."""
        pass

    fn oneTimeInit_new(inout self, state: UnsafePointer[EnergyPlusData]):
        """One-time initialization new (full implementation)."""
        let DesignVelocity = 0.5
        
        state[].PlantUtilities.ScanPlantLoopsForObject(state, self.Name, 
                                                       state[].DataPlant.PlantEquipmentType.GrndHtExchgSurface,
                                                       inout self.plantLoc)
        let rho = self.plantLoc[].loop.glycol.getDensity(state, 0.0, "InitSurfaceGroundHeatExchanger")
        let Pi = 3.141592653589793
        self.DesignMassFlowRate = (Pi / 4.0 * pow(self.TubeDiameter, 2) *
                                   DesignVelocity * rho * Float64(self.TubeCircuits))
        state[].PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
        state[].PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)


@value
struct SurfaceGroundHeatExchangersData:
    """Global data for surface ground heat exchangers."""
    
    var NoSurfaceGroundTempObjWarning: Bool
    var FlowRate: Float64
    var TopSurfTemp: Float64
    var BtmSurfTemp: Float64
    var TopSurfFlux: Float64
    var BtmSurfFlux: Float64
    var SourceFlux: Float64
    var CheckEquipName: List[Bool]
    
    var PastBeamSolarRad: Float64
    var PastSolarDirCosVert: Float64
    var PastDifSolarRad: Float64
    var PastGroundTemp: Float64
    var PastIsRain: Bool
    var PastIsSnow: Bool
    var PastOutDryBulbTemp: Float64
    var PastOutWetBulbTemp: Float64
    var PastSkyTemp: Float64
    var PastWindSpeed: Float64
    
    var GetInputFlag: Bool
    
    var QRadSysSrcAvg: List[Float64]
    var LastSysTimeElapsed: List[Float64]
    var LastTimeStepSys: List[Float64]
    var InitializeTempTop: Bool
    
    var SurfaceGHE: List[SurfaceGroundHeatExchangerData]
    var FluxTop: Float64
    var FluxBtm: Float64
    var TempBtm: Float64
    var TempTop: Float64

    fn __init__(inout self):
        self.NoSurfaceGroundTempObjWarning = True
        self.FlowRate = 0.0
        self.TopSurfTemp = 0.0
        self.BtmSurfTemp = 0.0
        self.TopSurfFlux = 0.0
        self.BtmSurfFlux = 0.0
        self.SourceFlux = 0.0
        self.CheckEquipName = List[Bool]()
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
        self.QRadSysSrcAvg = List[Float64]()
        self.LastSysTimeElapsed = List[Float64]()
        self.LastTimeStepSys = List[Float64]()
        self.InitializeTempTop = False
        self.SurfaceGHE = List[SurfaceGroundHeatExchangerData]()
        self.FluxTop = 0.0
        self.FluxBtm = 0.0
        self.TempBtm = 0.0
        self.TempTop = 0.0

    fn init_constant_state(inout self, state: UnsafePointer[EnergyPlusData]):
        """Initialize constant state (empty)."""
        pass

    fn init_state(inout self, state: UnsafePointer[EnergyPlusData]):
        """Initialize state (empty)."""
        pass

    fn clear_state(inout self):
        """Clear all state."""
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


fn GetSurfaceGroundHeatExchanger(state: UnsafePointer[EnergyPlusData]):
    """Get input for surface ground heat exchangers."""
    let cCurrentModuleObject = "GroundHeatExchanger:Surface"
    let NumOfSurfaceGHEs = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    
    state[].dataSurfaceGroundHeatExchangers.SurfaceGHE = List[SurfaceGroundHeatExchangerData]()
    for _ in range(NumOfSurfaceGHEs):
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE.append(SurfaceGroundHeatExchangerData())
    
    state[].dataSurfaceGroundHeatExchangers.CheckEquipName = List[Bool](capacity=NumOfSurfaceGHEs)
    for _ in range(NumOfSurfaceGHEs):
        state[].dataSurfaceGroundHeatExchangers.CheckEquipName.append(True)

    var ErrorsFound = False

    for Item in range(1, NumOfSurfaceGHEs + 1):
        state[].dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, Item)
        
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].Name = state[].dataIPShortCut.cAlphaArgs[0]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionName = state[].dataIPShortCut.cAlphaArgs[1]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum = int32(
            state[].Util.FindItemInList(state[].dataIPShortCut.cAlphaArgs[1], state[].dataConstruction.Construct))

        if state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum == 0:
            ErrorsFound = True

        if not state[].dataConstruction.Construct[int(state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum) - 1].SourceSinkPresent:
            ErrorsFound = True

        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].InletNode = state[].dataIPShortCut.cAlphaArgs[2]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].InletNodeNum = int32(
            state[].Node.GetOnlySingleNode(state, state[].dataIPShortCut.cAlphaArgs[2], inout ErrorsFound))

        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].OutletNode = state[].dataIPShortCut.cAlphaArgs[3]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].OutletNodeNum = int32(
            state[].Node.GetOnlySingleNode(state, state[].dataIPShortCut.cAlphaArgs[3], inout ErrorsFound))

        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeDiameter = state[].dataIPShortCut.rNumericArgs[0]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeCircuits = int32(state[].dataIPShortCut.rNumericArgs[1])
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeSpacing = state[].dataIPShortCut.rNumericArgs[2]

        if state[].dataIPShortCut.rNumericArgs[1] == 0:
            ErrorsFound = True

        if state[].dataIPShortCut.rNumericArgs[2] == 0.0:
            ErrorsFound = True

        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].SurfaceLength = state[].dataIPShortCut.rNumericArgs[3]
        state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].SurfaceWidth = state[].dataIPShortCut.rNumericArgs[4]

        if state[].dataIPShortCut.rNumericArgs[3] <= 0.0:
            ErrorsFound = True
        if state[].dataIPShortCut.rNumericArgs[4] <= 0.0:
            ErrorsFound = True

        if state[].Util.SameString(state[].dataIPShortCut.cAlphaArgs[4], "GROUND"):
            state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].LowerSurfCond = SurfCond_Ground
        elif state[].Util.SameString(state[].dataIPShortCut.cAlphaArgs[4], "EXPOSED"):
            state[].dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].LowerSurfCond = SurfCond_Exposed
        else:
            ErrorsFound = True

    if ErrorsFound:
        raise Error("Errors found in processing input for " + cCurrentModuleObject)

    if state[].dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning:
        if not state[].dataEnvrn.GroundTempInputs[int(state[].dataEnvrn.GroundTempType.Shallow)]:
            pass
        state[].dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning = False
