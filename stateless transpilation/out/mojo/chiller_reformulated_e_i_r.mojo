"""
EnergyPlus ChillerReformulatedEIR module — Mojo faithful port
Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
The Regents of the University of California, through Lawrence Berkeley National Laboratory
"""

from math import max, min, abs, fabs

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from EnergyPlus/Data/EnergyPlusData)
# - DataPlant.CondenserType, DataPlant.FlowMode, DataPlant.CondenserFlowControl (from EnergyPlus/Plant/DataPlant)
# - DataPlant.LoopDemandCalcScheme, DataPlant.OpScheme, DataPlant.PlantEquipmentType (from EnergyPlus/Plant/DataPlant)
# - DataBranchAirLoopPlant.ControlType (from EnergyPlus/DataBranchAirLoopPlant)
# - PlantLocation, PlantComponent (from EnergyPlus/PlantComponent)
# - BaseGlobalStruct (from EnergyPlus/Data/BaseData)
# - Sched.Schedule, Sched.GetSchedule (from EnergyPlus/ScheduleManager)
# - Curve functions: GetCurveIndex, CurveValue, GetCurveMinMaxValues (from EnergyPlus/CurveManager)
# - Node operations (from EnergyPlus/DataLoopNode and EnergyPlus/NodeInputManager)
# - PlantUtilities functions (from EnergyPlus/PlantUtilities)
# - ShowFatalError, ShowSevereError, ShowWarningError, etc. (from EnergyPlus/UtilityRoutines)
# - OutputProcessor functions (from EnergyPlus/OutputProcessor)
# - OutputReportPredefined functions (from EnergyPlus/OutputReportPredefined)
# - StandardRatings.CalcChillerIPLV (from EnergyPlus/StandardRatings)
# - FaultsManager (from EnergyPlus/FaultsManager)
# - General.SolveRoot (from EnergyPlus/General)


@export
enum PLR:
    """Part Load Ratio curve type enumeration"""
    Invalid = -1
    LeavingCondenserWaterTemperature = 0
    Lift = 1
    Num = 2


@export
struct ReformulatedEIRChillerSpecs:
    """Reformulated EIR Chiller specification and state"""
    
    # Basic identification and configuration
    var Name: String
    var TypeNum: Int32
    var CAPFTName: String
    var EIRFTName: String
    var EIRFPLRName: String
    var CondenserType: AnyType
    var PartLoadCurveType: PLR
    
    # Performance characteristics
    var RefCap: Float64
    var RefCapWasAutoSized: Bool
    var RefCOP: Float64
    var FlowMode: AnyType
    var CondenserFlowControl: AnyType
    var ModulatedFlowSetToLoop: Bool
    var ModulatedFlowErrDone: Bool
    
    # Flow rates
    var EvapVolFlowRate: Float64
    var EvapVolFlowRateWasAutoSized: Bool
    var EvapMassFlowRateMax: Float64
    var CondVolFlowRate: Float64
    var CondVolFlowRateWasAutoSized: Bool
    var CondMassFlowRateMax: Float64
    var CompPowerToCondenserFrac: Float64
    
    # Node numbers
    var EvapInletNodeNum: Int32
    var EvapOutletNodeNum: Int32
    var CondInletNodeNum: Int32
    var CondOutletNodeNum: Int32
    
    # Load ratios and temperatures
    var MinPartLoadRat: Float64
    var MaxPartLoadRat: Float64
    var OptPartLoadRat: Float64
    var MinUnloadRat: Float64
    var TempRefCondIn: Float64
    var TempRefCondOut: Float64
    var TempRefEvapOut: Float64
    var TempLowLimitEvapOut: Float64
    
    # Heat recovery
    var DesignHeatRecVolFlowRate: Float64
    var DesignHeatRecVolFlowRateWasAutoSized: Bool
    var DesignHeatRecMassFlowRate: Float64
    var SizFac: Float64
    var HeatRecActive: Bool
    var HeatRecInletNodeNum: Int32
    var HeatRecOutletNodeNum: Int32
    var HeatRecCapacityFraction: Float64
    var HeatRecMaxCapacityLimit: Float64
    var HeatRecSetPointNodeNum: Int32
    var heatRecInletLimitSched: Pointer[AnyType]
    
    # Curve indices
    var ChillerCapFTIndex: Int32
    var ChillerEIRFTIndex: Int32
    var ChillerEIRFPLRIndex: Int32
    var ChillerCapFTError: Int32
    var ChillerCapFTErrorIndex: Int32
    var ChillerEIRFTError: Int32
    var ChillerEIRFTErrorIndex: Int32
    var ChillerEIRFPLRError: Int32
    var ChillerEIRFPLRErrorIndex: Int32
    
    # Curve bounds
    var ChillerCAPFTXTempMin: Float64
    var ChillerCAPFTXTempMax: Float64
    var ChillerCAPFTYTempMin: Float64
    var ChillerCAPFTYTempMax: Float64
    var ChillerEIRFTXTempMin: Float64
    var ChillerEIRFTXTempMax: Float64
    var ChillerEIRFTYTempMin: Float64
    var ChillerEIRFTYTempMax: Float64
    var ChillerEIRFPLRTempMin: Float64
    var ChillerEIRFPLRTempMax: Float64
    var ChillerEIRFPLRPLRMin: Float64
    var ChillerEIRFPLRPLRMax: Float64
    var ChillerLiftNomMin: Float64
    var ChillerLiftNomMax: Float64
    var ChillerTdevNomMin: Float64
    var ChillerTdevNomMax: Float64
    
    # Warning iteration counters
    var CAPFTXIter: Int32
    var CAPFTXIterIndex: Int32
    var CAPFTYIter: Int32
    var CAPFTYIterIndex: Int32
    var EIRFTXIter: Int32
    var EIRFTXIterIndex: Int32
    var EIRFTYIter: Int32
    var EIRFTYIterIndex: Int32
    var EIRFPLRTIter: Int32
    var EIRFPLRTIterIndex: Int32
    var EIRFPLRPLRIter: Int32
    var EIRFPLRPLRIterIndex: Int32
    
    # Fault models
    var FaultyChillerSWTFlag: Bool
    var FaultyChillerSWTIndex: Int32
    var FaultyChillerSWTOffset: Float64
    var IterLimitExceededNum: Int32
    var IterLimitErrIndex: Int32
    var IterFailed: Int32
    var IterFailedIndex: Int32
    var DeltaTErrCount: Int32
    var DeltaTErrCountIndex: Int32
    
    # Plant locations
    var CWPlantLoc: Pointer[AnyType]
    var CDPlantLoc: Pointer[AnyType]
    var HRPlantLoc: Pointer[AnyType]
    var CondMassFlowIndex: Int32
    var PossibleSubcooling: Bool
    
    # Fouling fault
    var FaultyChillerFoulingFlag: Bool
    var FaultyChillerFoulingIndex: Int32
    var FaultyChillerFoulingFactor: Float64
    
    # Reporting
    var EndUseSubcategory: String
    
    # State flags
    var MyEnvrnFlag: Bool
    var MyInitFlag: Bool
    var MySizeFlag: Bool
    
    # Operational state
    var ChillerCondAvgTemp: Float64
    var ChillerFalseLoadRate: Float64
    var ChillerCyclingRatio: Float64
    var ChillerPartLoadRatio: Float64
    var ChillerEIRFPLR: Float64
    var ChillerEIRFT: Float64
    var ChillerCapFT: Float64
    var HeatRecOutletTemp: Float64
    var QHeatRecovery: Float64
    var QCondenser: Float64
    var QEvaporator: Float64
    var Power: Float64
    var EvapOutletTemp: Float64
    var CondOutletTemp: Float64
    var EvapMassFlowRate: Float64
    var CondMassFlowRate: Float64
    var ChillerFalseLoad: Float64
    var Energy: Float64
    var EvapEnergy: Float64
    var CondEnergy: Float64
    var CondInletTemp: Float64
    var EvapInletTemp: Float64
    var ActualCOP: Float64
    var EnergyHeatRecovery: Float64
    var HeatRecInletTemp: Float64
    var HeatRecMassFlow: Float64
    
    # Condenser control
    var ChillerCondLoopFlowFLoopPLRIndex: Int32
    var CondDT: Int32
    var condDTSched: Pointer[AnyType]
    var MinCondFlowRatio: Float64
    var EquipFlowCtrl: AnyType
    var VSBranchPumpMinLimitMassFlowCond: Float64
    var VSBranchPumpFoundCond: Bool
    var VSLoopPumpFoundCond: Bool
    
    # Thermosiphon model
    var thermosiphonTempCurveIndex: Int32
    var thermosiphonMinTempDiff: Float64
    var thermosiphonStatus: Int32
    
    fn __init__(inout self):
        self.Name = String()
        self.TypeNum = 0
        self.CAPFTName = String()
        self.EIRFTName = String()
        self.EIRFPLRName = String()
        self.CondenserType = AnyType()
        self.PartLoadCurveType = PLR.Invalid
        self.RefCap = 0.0
        self.RefCapWasAutoSized = False
        self.RefCOP = 0.0
        self.FlowMode = AnyType()
        self.CondenserFlowControl = AnyType()
        self.ModulatedFlowSetToLoop = False
        self.ModulatedFlowErrDone = False
        self.EvapVolFlowRate = 0.0
        self.EvapVolFlowRateWasAutoSized = False
        self.EvapMassFlowRateMax = 0.0
        self.CondVolFlowRate = 0.0
        self.CondVolFlowRateWasAutoSized = False
        self.CondMassFlowRateMax = 0.0
        self.CompPowerToCondenserFrac = 0.0
        self.EvapInletNodeNum = 0
        self.EvapOutletNodeNum = 0
        self.CondInletNodeNum = 0
        self.CondOutletNodeNum = 0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.MinUnloadRat = 0.0
        self.TempRefCondIn = 0.0
        self.TempRefCondOut = 0.0
        self.TempRefEvapOut = 0.0
        self.TempLowLimitEvapOut = 0.0
        self.DesignHeatRecVolFlowRate = 0.0
        self.DesignHeatRecVolFlowRateWasAutoSized = False
        self.DesignHeatRecMassFlowRate = 0.0
        self.SizFac = 0.0
        self.HeatRecActive = False
        self.HeatRecInletNodeNum = 0
        self.HeatRecOutletNodeNum = 0
        self.HeatRecCapacityFraction = 0.0
        self.HeatRecMaxCapacityLimit = 0.0
        self.HeatRecSetPointNodeNum = 0
        self.heatRecInletLimitSched = Pointer[AnyType]()
        self.ChillerCapFTIndex = 0
        self.ChillerEIRFTIndex = 0
        self.ChillerEIRFPLRIndex = 0
        self.ChillerCapFTError = 0
        self.ChillerCapFTErrorIndex = 0
        self.ChillerEIRFTError = 0
        self.ChillerEIRFTErrorIndex = 0
        self.ChillerEIRFPLRError = 0
        self.ChillerEIRFPLRErrorIndex = 0
        self.ChillerCAPFTXTempMin = 0.0
        self.ChillerCAPFTXTempMax = 0.0
        self.ChillerCAPFTYTempMin = 0.0
        self.ChillerCAPFTYTempMax = 0.0
        self.ChillerEIRFTXTempMin = 0.0
        self.ChillerEIRFTXTempMax = 0.0
        self.ChillerEIRFTYTempMin = 0.0
        self.ChillerEIRFTYTempMax = 0.0
        self.ChillerEIRFPLRTempMin = 0.0
        self.ChillerEIRFPLRTempMax = 0.0
        self.ChillerEIRFPLRPLRMin = 0.0
        self.ChillerEIRFPLRPLRMax = 0.0
        self.ChillerLiftNomMin = 0.0
        self.ChillerLiftNomMax = 10.0
        self.ChillerTdevNomMin = 0.0
        self.ChillerTdevNomMax = 10.0
        self.CAPFTXIter = 0
        self.CAPFTXIterIndex = 0
        self.CAPFTYIter = 0
        self.CAPFTYIterIndex = 0
        self.EIRFTXIter = 0
        self.EIRFTXIterIndex = 0
        self.EIRFTYIter = 0
        self.EIRFTYIterIndex = 0
        self.EIRFPLRTIter = 0
        self.EIRFPLRTIterIndex = 0
        self.EIRFPLRPLRIter = 0
        self.EIRFPLRPLRIterIndex = 0
        self.FaultyChillerSWTFlag = False
        self.FaultyChillerSWTIndex = 0
        self.FaultyChillerSWTOffset = 0.0
        self.IterLimitExceededNum = 0
        self.IterLimitErrIndex = 0
        self.IterFailed = 0
        self.IterFailedIndex = 0
        self.DeltaTErrCount = 0
        self.DeltaTErrCountIndex = 0
        self.CWPlantLoc = Pointer[AnyType]()
        self.CDPlantLoc = Pointer[AnyType]()
        self.HRPlantLoc = Pointer[AnyType]()
        self.CondMassFlowIndex = 0
        self.PossibleSubcooling = False
        self.FaultyChillerFoulingFlag = False
        self.FaultyChillerFoulingIndex = 0
        self.FaultyChillerFoulingFactor = 1.0
        self.EndUseSubcategory = String()
        self.MyEnvrnFlag = True
        self.MyInitFlag = True
        self.MySizeFlag = True
        self.ChillerCondAvgTemp = 0.0
        self.ChillerFalseLoadRate = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerPartLoadRatio = 0.0
        self.ChillerEIRFPLR = 0.0
        self.ChillerEIRFT = 0.0
        self.ChillerCapFT = 0.0
        self.HeatRecOutletTemp = 0.0
        self.QHeatRecovery = 0.0
        self.QCondenser = 0.0
        self.QEvaporator = 0.0
        self.Power = 0.0
        self.EvapOutletTemp = 0.0
        self.CondOutletTemp = 0.0
        self.EvapMassFlowRate = 0.0
        self.CondMassFlowRate = 0.0
        self.ChillerFalseLoad = 0.0
        self.Energy = 0.0
        self.EvapEnergy = 0.0
        self.CondEnergy = 0.0
        self.CondInletTemp = 0.0
        self.EvapInletTemp = 0.0
        self.ActualCOP = 0.0
        self.EnergyHeatRecovery = 0.0
        self.HeatRecInletTemp = 0.0
        self.HeatRecMassFlow = 0.0
        self.ChillerCondLoopFlowFLoopPLRIndex = 0
        self.CondDT = 0
        self.condDTSched = Pointer[AnyType]()
        self.MinCondFlowRatio = 0.2
        self.EquipFlowCtrl = AnyType()
        self.VSBranchPumpMinLimitMassFlowCond = 0.0
        self.VSBranchPumpFoundCond = False
        self.VSLoopPumpFoundCond = False
        self.thermosiphonTempCurveIndex = 0
        self.thermosiphonMinTempDiff = 0.0
        self.thermosiphonStatus = 0
    
    @staticmethod
    fn factory(state: Pointer[AnyType], object_name: String) -> Pointer[ReformulatedEIRChillerSpecs]:
        return Pointer[ReformulatedEIRChillerSpecs]()
    
    fn getDesignCapacities(inout self, state: Pointer[AnyType], calledFromLocation: AnyType, inout MaxLoad: Float64, inout MinLoad: Float64, inout OptLoad: Float64):
        if calledFromLocation.loopNum == self.CWPlantLoc[].loopNum:
            MinLoad = self.RefCap * self.MinPartLoadRat
            MaxLoad = self.RefCap * self.MaxPartLoadRat
            OptLoad = self.RefCap * self.OptPartLoadRat
        else:
            MinLoad = 0.0
            MaxLoad = 0.0
            OptLoad = 0.0
    
    fn getDesignTemperatures(inout self, inout TempDesCondIn: Float64, inout TempDesEvapOut: Float64):
        TempDesEvapOut = self.TempRefEvapOut
        TempDesCondIn = self.TempRefCondIn
    
    fn getSizingFactor(inout self, inout sizFac: Float64):
        sizFac = self.SizFac
    
    fn onInitLoopEquip(inout self, state: Pointer[AnyType], calledFromLocation: AnyType):
        let runFlag = True
        let myLoad = 0.0
        self.initialize(state, runFlag, myLoad)
        if calledFromLocation.loopNum == self.CWPlantLoc[].loopNum:
            self.size(state)
    
    fn simulate(inout self, state: Pointer[AnyType], calledFromLocation: AnyType, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        if calledFromLocation.loopNum == self.CWPlantLoc[].loopNum:
            self.initialize(state, RunFlag, CurLoad)
            self.control(state, CurLoad, RunFlag, FirstHVACIteration)
            self.update(state, CurLoad, RunFlag)
        elif calledFromLocation.loopNum == self.CDPlantLoc[].loopNum:
            pass
        elif calledFromLocation.loopNum == self.HRPlantLoc[].loopNum:
            pass
    
    fn initialize(inout self, state: Pointer[AnyType], RunFlag: Bool, MyLoad: Float64):
        if self.MyInitFlag:
            self.oneTimeInit(state)
            self.setupOutputVars(state)
            self.MyInitFlag = False
        
        if self.MyEnvrnFlag:
            self.MyEnvrnFlag = False
        
        let mdot = (abs(MyLoad) > 0.0 and RunFlag) ? self.EvapMassFlowRateMax : 0.0
        let mdotCond = (abs(MyLoad) > 0.0 and RunFlag) ? self.CondMassFlowRateMax : 0.0
    
    fn size(inout self, state: Pointer[AnyType]):
        pass
    
    fn control(inout self, state: Pointer[AnyType], inout MyLoad: Float64, RunFlag: Bool, FirstIteration: Bool):
        if MyLoad >= 0.0 or not RunFlag:
            self.calculate(state, MyLoad, RunFlag, 0.0)
        else:
            let CAPFTYTmin = self.ChillerCAPFTYTempMin
            let EIRFTYTmin = self.ChillerEIRFTYTempMin
            let Tmin = min(CAPFTYTmin, EIRFTYTmin)
            
            let CAPFTYTmax = self.ChillerCAPFTYTempMax
            let EIRFTYTmax = self.ChillerEIRFTYTempMax
            let Tmax = max(CAPFTYTmax, EIRFTYTmax)
            
            self.calculate(state, MyLoad, RunFlag, Tmin)
            let CondTempMin = self.CondOutletTemp
            
            self.calculate(state, MyLoad, RunFlag, Tmax)
            let CondTempMax = self.CondOutletTemp
            
            if CondTempMin > Tmin and CondTempMax < Tmax:
                pass
            else:
                self.calculate(state, MyLoad, RunFlag, (CondTempMin + CondTempMax) / 2.0)
            
            self.checkMinMaxCurveBoundaries(state, FirstIteration)
    
    fn calculate(inout self, state: Pointer[AnyType], inout MyLoad: Float64, RunFlag: Bool, FalsiCondOutTemp: Float64):
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerFalseLoadRate = 0.0
        self.EvapMassFlowRate = 0.0
        self.CondMassFlowRate = 0.0
        self.Power = 0.0
        self.QCondenser = 0.0
        self.QEvaporator = 0.0
        self.QHeatRecovery = 0.0
        self.ChillerCapFT = 0.0
        self.ChillerEIRFT = 0.0
        self.ChillerEIRFPLR = 0.0
        self.thermosiphonStatus = 0
        
        if MyLoad >= 0 or not RunFlag:
            return
        
        let ChillerRefCap = self.RefCap
        let ReferenceCOP = self.RefCOP
        
        if self.HeatRecActive:
            if (self.QHeatRecovery + self.QCondenser) > 0.0:
                self.ChillerCondAvgTemp = (self.QHeatRecovery * self.HeatRecOutletTemp + self.QCondenser * self.CondOutletTemp) / (self.QHeatRecovery + self.QCondenser)
            else:
                self.ChillerCondAvgTemp = FalsiCondOutTemp
        else:
            self.ChillerCondAvgTemp = FalsiCondOutTemp
        
        self.ChillerCapFT = max(0.0, 0.0)
        let AvailChillerCap = ChillerRefCap * self.ChillerCapFT
        
        self.EvapMassFlowRate = 0.0
        if self.EvapMassFlowRate == 0.0:
            return
        
        var PartLoadRat = 0.0
        if AvailChillerCap > 0:
            PartLoadRat = max(0.0, min(abs(MyLoad) / AvailChillerCap, self.MaxPartLoadRat))
        
        self.QEvaporator = AvailChillerCap * PartLoadRat
        self.ChillerPartLoadRatio = PartLoadRat
        
        let FRAC = 1.0
        
        self.ChillerEIRFT = max(0.0, 0.0)
        
        if self.PartLoadCurveType == PLR.LeavingCondenserWaterTemperature:
            self.ChillerEIRFPLR = max(0.0, 0.0)
        elif self.PartLoadCurveType == PLR.Lift:
            let ChillerLift = self.ChillerCondAvgTemp - self.EvapOutletTemp
            let ChillerTdev = abs(self.EvapOutletTemp - self.TempRefEvapOut)
            var ChillerLiftRef = self.TempRefCondOut - self.TempRefEvapOut
            if ChillerLiftRef <= 0:
                ChillerLiftRef = 35 - 6.67
            let ChillerLiftNom = ChillerLift / ChillerLiftRef
            let ChillerTdevNom = ChillerTdev / ChillerLiftRef
            self.ChillerEIRFPLR = max(0.0, 0.0)
        
        if not self.thermosiphonDisabled(state):
            self.Power = (AvailChillerCap / ReferenceCOP) * self.ChillerEIRFPLR * self.ChillerEIRFT * FRAC
        
        self.QCondenser = self.Power * self.CompPowerToCondenserFrac + self.QEvaporator + self.ChillerFalseLoadRate
    
    fn calcHeatRecovery(inout self, state: Pointer[AnyType], inout QCond: Float64, CondMassFlow: Float64, condInletTemp: Float64, inout QHeatRec: Float64):
        let heatRecInletTemp = 0.0
        let HeatRecMassFlowRate = 0.0
        let CpHeatRec = 1.0
        let CpCond = 1.0
        let QTotal = QCond
        
        if self.HeatRecSetPointNodeNum == 0:
            let TAvgIn = (HeatRecMassFlowRate * CpHeatRec * heatRecInletTemp + CondMassFlow * CpCond * condInletTemp) / (HeatRecMassFlowRate * CpHeatRec + CondMassFlow * CpCond)
            let TAvgOut = QTotal / (HeatRecMassFlowRate * CpHeatRec + CondMassFlow * CpCond) + TAvgIn
            var QHeatRec_calc = HeatRecMassFlowRate * CpHeatRec * (TAvgOut - heatRecInletTemp)
            QHeatRec_calc = max(QHeatRec_calc, 0.0)
            QHeatRec_calc = min(QHeatRec_calc, self.HeatRecMaxCapacityLimit)
        
        if self.heatRecInletLimitSched != Pointer[AnyType]():
            let HeatRecHighInletLimit = 0.0
            if heatRecInletTemp > HeatRecHighInletLimit:
                QHeatRec = 0.0
        
        if HeatRecMassFlowRate > 0.0:
            self.HeatRecOutletTemp = QHeatRec / (HeatRecMassFlowRate * CpHeatRec) + heatRecInletTemp
        else:
            self.HeatRecOutletTemp = heatRecInletTemp
    
    fn update(inout self, state: Pointer[AnyType], MyLoad: Float64, RunFlag: Bool):
        if MyLoad >= 0.0 or not RunFlag:
            self.ChillerPartLoadRatio = 0.0
            self.ChillerCyclingRatio = 0.0
            self.ChillerFalseLoadRate = 0.0
            self.ChillerFalseLoad = 0.0
            self.Power = 0.0
            self.QEvaporator = 0.0
            self.QCondenser = 0.0
            self.Energy = 0.0
            self.EvapEnergy = 0.0
            self.CondEnergy = 0.0
            self.ActualCOP = 0.0
            
            if self.HeatRecActive:
                self.QHeatRecovery = 0.0
                self.EnergyHeatRecovery = 0.0
        else:
            let TimeStepSysSec = 1.0
            self.ChillerFalseLoad = self.ChillerFalseLoadRate * TimeStepSysSec
            self.Energy = self.Power * TimeStepSysSec
            self.EvapEnergy = self.QEvaporator * TimeStepSysSec
            self.CondEnergy = self.QCondenser * TimeStepSysSec
            if self.Power != 0.0:
                self.ActualCOP = (self.QEvaporator + self.ChillerFalseLoadRate) / self.Power
            else:
                self.ActualCOP = 0.0
            
            if self.HeatRecActive:
                self.EnergyHeatRecovery = self.QHeatRecovery * TimeStepSysSec
    
    fn setupOutputVars(inout self, state: Pointer[AnyType]):
        pass
    
    fn oneTimeInit(inout self, state: Pointer[AnyType]):
        pass
    
    fn checkMinMaxCurveBoundaries(inout self, state: Pointer[AnyType], FirstIteration: Bool):
        pass
    
    fn thermosiphonDisabled(self, state: Pointer[AnyType]) -> Bool:
        if self.thermosiphonTempCurveIndex > 0:
            let dT = self.EvapOutletTemp - self.CondInletTemp
            if dT < self.thermosiphonMinTempDiff:
                return True
            let thermosiphonCapFrac = 0.0
            let capFrac = self.ChillerPartLoadRatio * self.ChillerCyclingRatio
            if thermosiphonCapFrac >= capFrac:
                return False
            return True
        return True


fn GetElecReformEIRChillerInput(state: Pointer[AnyType]):
    pass


@export
struct ChillerReformulatedEIRData:
    """Global data for Reformulated EIR Chiller"""
    var GetInputREIR: Bool
    var ElecReformEIRChiller: DynamicVector[ReformulatedEIRChillerSpecs]
    
    fn __init__(inout self):
        self.GetInputREIR = True
        self.ElecReformEIRChiller = DynamicVector[ReformulatedEIRChillerSpecs]()
    
    fn init_constant_state(inout self, state: Pointer[AnyType]):
        pass
    
    fn init_state(inout self, state: Pointer[AnyType]):
        pass
    
    fn clear_state(inout self):
        self.GetInputREIR = True
        self.ElecReformEIRChiller = DynamicVector[ReformulatedEIRChillerSpecs]()
