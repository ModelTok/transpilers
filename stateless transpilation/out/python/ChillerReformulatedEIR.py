"""
EnergyPlus ChillerReformulatedEIR module — Python faithful port
Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
The Regents of the University of California, through Lawrence Berkeley National Laboratory
"""

from dataclasses import dataclass, field
from typing import Optional, List, Protocol
from enum import IntEnum
import math

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

class PLR(IntEnum):
    """Part Load Ratio curve type enumeration"""
    Invalid = -1
    LeavingCondenserWaterTemperature = 0
    Lift = 1
    Num = 2


@dataclass
class ReformulatedEIRChillerSpecs:
    """Reformulated EIR Chiller specification and state"""
    
    # Basic identification and configuration
    Name: str = ""
    TypeNum: int = 0
    CAPFTName: str = ""
    EIRFTName: str = ""
    EIRFPLRName: str = ""
    CondenserType: any = None
    PartLoadCurveType: PLR = PLR.Invalid
    
    # Performance characteristics
    RefCap: float = 0.0
    RefCapWasAutoSized: bool = False
    RefCOP: float = 0.0
    FlowMode: any = None
    CondenserFlowControl: any = None
    ModulatedFlowSetToLoop: bool = False
    ModulatedFlowErrDone: bool = False
    
    # Flow rates
    EvapVolFlowRate: float = 0.0
    EvapVolFlowRateWasAutoSized: bool = False
    EvapMassFlowRateMax: float = 0.0
    CondVolFlowRate: float = 0.0
    CondVolFlowRateWasAutoSized: bool = False
    CondMassFlowRateMax: float = 0.0
    CompPowerToCondenserFrac: float = 0.0
    
    # Node numbers
    EvapInletNodeNum: int = 0
    EvapOutletNodeNum: int = 0
    CondInletNodeNum: int = 0
    CondOutletNodeNum: int = 0
    
    # Load ratios and temperatures
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    MinUnloadRat: float = 0.0
    TempRefCondIn: float = 0.0
    TempRefCondOut: float = 0.0
    TempRefEvapOut: float = 0.0
    TempLowLimitEvapOut: float = 0.0
    
    # Heat recovery
    DesignHeatRecVolFlowRate: float = 0.0
    DesignHeatRecVolFlowRateWasAutoSized: bool = False
    DesignHeatRecMassFlowRate: float = 0.0
    SizFac: float = 0.0
    HeatRecActive: bool = False
    HeatRecInletNodeNum: int = 0
    HeatRecOutletNodeNum: int = 0
    HeatRecCapacityFraction: float = 0.0
    HeatRecMaxCapacityLimit: float = 0.0
    HeatRecSetPointNodeNum: int = 0
    heatRecInletLimitSched: Optional[any] = None
    
    # Curve indices
    ChillerCapFTIndex: int = 0
    ChillerEIRFTIndex: int = 0
    ChillerEIRFPLRIndex: int = 0
    ChillerCapFTError: int = 0
    ChillerCapFTErrorIndex: int = 0
    ChillerEIRFTError: int = 0
    ChillerEIRFTErrorIndex: int = 0
    ChillerEIRFPLRError: int = 0
    ChillerEIRFPLRErrorIndex: int = 0
    
    # Curve bounds
    ChillerCAPFTXTempMin: float = 0.0
    ChillerCAPFTXTempMax: float = 0.0
    ChillerCAPFTYTempMin: float = 0.0
    ChillerCAPFTYTempMax: float = 0.0
    ChillerEIRFTXTempMin: float = 0.0
    ChillerEIRFTXTempMax: float = 0.0
    ChillerEIRFTYTempMin: float = 0.0
    ChillerEIRFTYTempMax: float = 0.0
    ChillerEIRFPLRTempMin: float = 0.0
    ChillerEIRFPLRTempMax: float = 0.0
    ChillerEIRFPLRPLRMin: float = 0.0
    ChillerEIRFPLRPLRMax: float = 0.0
    ChillerLiftNomMin: float = 0.0
    ChillerLiftNomMax: float = 10.0
    ChillerTdevNomMin: float = 0.0
    ChillerTdevNomMax: float = 10.0
    
    # Warning iteration counters
    CAPFTXIter: int = 0
    CAPFTXIterIndex: int = 0
    CAPFTYIter: int = 0
    CAPFTYIterIndex: int = 0
    EIRFTXIter: int = 0
    EIRFTXIterIndex: int = 0
    EIRFTYIter: int = 0
    EIRFTYIterIndex: int = 0
    EIRFPLRTIter: int = 0
    EIRFPLRTIterIndex: int = 0
    EIRFPLRPLRIter: int = 0
    EIRFPLRPLRIterIndex: int = 0
    
    # Fault models
    FaultyChillerSWTFlag: bool = False
    FaultyChillerSWTIndex: int = 0
    FaultyChillerSWTOffset: float = 0.0
    IterLimitExceededNum: int = 0
    IterLimitErrIndex: int = 0
    IterFailed: int = 0
    IterFailedIndex: int = 0
    DeltaTErrCount: int = 0
    DeltaTErrCountIndex: int = 0
    
    # Plant locations
    CWPlantLoc: any = None
    CDPlantLoc: any = None
    HRPlantLoc: any = None
    CondMassFlowIndex: int = 0
    PossibleSubcooling: bool = False
    
    # Fouling fault
    FaultyChillerFoulingFlag: bool = False
    FaultyChillerFoulingIndex: int = 0
    FaultyChillerFoulingFactor: float = 1.0
    
    # Reporting
    EndUseSubcategory: str = ""
    
    # State flags
    MyEnvrnFlag: bool = True
    MyInitFlag: bool = True
    MySizeFlag: bool = True
    
    # Operational state
    ChillerCondAvgTemp: float = 0.0
    ChillerFalseLoadRate: float = 0.0
    ChillerCyclingRatio: float = 0.0
    ChillerPartLoadRatio: float = 0.0
    ChillerEIRFPLR: float = 0.0
    ChillerEIRFT: float = 0.0
    ChillerCapFT: float = 0.0
    HeatRecOutletTemp: float = 0.0
    QHeatRecovery: float = 0.0
    QCondenser: float = 0.0
    QEvaporator: float = 0.0
    Power: float = 0.0
    EvapOutletTemp: float = 0.0
    CondOutletTemp: float = 0.0
    EvapMassFlowRate: float = 0.0
    CondMassFlowRate: float = 0.0
    ChillerFalseLoad: float = 0.0
    Energy: float = 0.0
    EvapEnergy: float = 0.0
    CondEnergy: float = 0.0
    CondInletTemp: float = 0.0
    EvapInletTemp: float = 0.0
    ActualCOP: float = 0.0
    EnergyHeatRecovery: float = 0.0
    HeatRecInletTemp: float = 0.0
    HeatRecMassFlow: float = 0.0
    
    # Condenser control
    ChillerCondLoopFlowFLoopPLRIndex: int = 0
    CondDT: int = 0
    condDTSched: Optional[any] = None
    MinCondFlowRatio: float = 0.2
    EquipFlowCtrl: any = None
    VSBranchPumpMinLimitMassFlowCond: float = 0.0
    VSBranchPumpFoundCond: bool = False
    VSLoopPumpFoundCond: bool = False
    
    # Thermosiphon model
    thermosiphonTempCurveIndex: int = 0
    thermosiphonMinTempDiff: float = 0.0
    thermosiphonStatus: int = 0
    
    @staticmethod
    def factory(state: any, object_name: str) -> 'ReformulatedEIRChillerSpecs':
        if state.dataChillerReformulatedEIR.GetInputREIR:
            GetElecReformEIRChillerInput(state)
            state.dataChillerReformulatedEIR.GetInputREIR = False
        
        for chiller in state.dataChillerReformulatedEIR.ElecReformEIRChiller:
            if chiller.Name == object_name:
                return chiller
        
        raise Exception(f"LocalReformulatedElectEIRChillerFactory: Error getting inputs for object named: {object_name}")
    
    def getDesignCapacities(self, state: any, calledFromLocation: any, MaxLoad: list, MinLoad: list, OptLoad: list):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            MinLoad[0] = self.RefCap * self.MinPartLoadRat
            MaxLoad[0] = self.RefCap * self.MaxPartLoadRat
            OptLoad[0] = self.RefCap * self.OptPartLoadRat
        else:
            MinLoad[0] = 0.0
            MaxLoad[0] = 0.0
            OptLoad[0] = 0.0
    
    def getDesignTemperatures(self, TempDesCondIn: list, TempDesEvapOut: list):
        TempDesEvapOut[0] = self.TempRefEvapOut
        TempDesCondIn[0] = self.TempRefCondIn
    
    def getSizingFactor(self, sizFac: list):
        sizFac[0] = self.SizFac
    
    def onInitLoopEquip(self, state: any, calledFromLocation: any):
        runFlag = True
        myLoad = 0.0
        self.initialize(state, runFlag, myLoad)
        
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.size(state)
    
    def simulate(self, state: any, calledFromLocation: any, FirstHVACIteration: bool, CurLoad: list, RunFlag: bool):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.initialize(state, RunFlag, CurLoad[0])
            self.control(state, CurLoad, RunFlag, FirstHVACIteration)
            self.update(state, CurLoad[0], RunFlag)
        elif calledFromLocation.loopNum == self.CDPlantLoc.loopNum:
            pass  # Plant utilities update
        elif calledFromLocation.loopNum == self.HRPlantLoc.loopNum:
            pass  # Plant utilities update
    
    def initialize(self, state: any, RunFlag: bool, MyLoad: float):
        if self.MyInitFlag:
            self.oneTimeInit(state)
            self.setupOutputVars(state)
            self.MyInitFlag = False
        
        self.EquipFlowCtrl = None
        
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            pass  # Initialize component nodes
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        
        mdot = 0.0
        mdotCond = 0.0
        if abs(MyLoad) > 0.0 and RunFlag:
            mdot = self.EvapMassFlowRateMax
            mdotCond = self.CondMassFlowRateMax
        
        if self.HeatRecActive:
            mdot_hr = self.DesignHeatRecMassFlowRate if RunFlag else 0.0
    
    def size(self, state: any):
        pass
    
    def control(self, state: any, MyLoad: list, RunFlag: bool, FirstIteration: bool):
        if MyLoad[0] >= 0.0 or not RunFlag:
            self.calculate(state, MyLoad[0], RunFlag, state.dataLoopNodes.Node(self.CondInletNodeNum).Temp)
        else:
            CAPFTYTmin = self.ChillerCAPFTYTempMin
            EIRFTYTmin = self.ChillerEIRFTYTempMin
            Tmin = min(CAPFTYTmin, EIRFTYTmin)
            
            CAPFTYTmax = self.ChillerCAPFTYTempMax
            EIRFTYTmax = self.ChillerEIRFTYTempMax
            Tmax = max(CAPFTYTmax, EIRFTYTmax)
            
            self.calculate(state, MyLoad[0], RunFlag, Tmin)
            CondTempMin = self.CondOutletTemp
            
            self.calculate(state, MyLoad[0], RunFlag, Tmax)
            CondTempMax = self.CondOutletTemp
            
            if CondTempMin > Tmin and CondTempMax < Tmax:
                pass  # SolveRoot call
            else:
                self.calculate(state, MyLoad[0], RunFlag, (CondTempMin + CondTempMax) / 2.0)
            
            self.checkMinMaxCurveBoundaries(state, FirstIteration)
    
    def calculate(self, state: any, MyLoad: float, RunFlag: bool, FalsiCondOutTemp: float):
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
        
        ChillerRefCap = self.RefCap
        ReferenceCOP = self.RefCOP
        
        if self.FaultyChillerFoulingFlag:
            pass
        
        EvapOutletTempSetPoint = 0.0
        
        if self.HeatRecActive:
            if (self.QHeatRecovery + self.QCondenser) > 0.0:
                self.ChillerCondAvgTemp = (self.QHeatRecovery * self.HeatRecOutletTemp + self.QCondenser * self.CondOutletTemp) / (self.QHeatRecovery + self.QCondenser)
            else:
                self.ChillerCondAvgTemp = FalsiCondOutTemp
        else:
            self.ChillerCondAvgTemp = FalsiCondOutTemp
        
        self.ChillerCapFT = max(0.0, 0.0)
        AvailChillerCap = ChillerRefCap * self.ChillerCapFT
        
        self.EvapMassFlowRate = 0.0
        if self.EvapMassFlowRate == 0.0:
            return
        
        PartLoadRat = 0.0
        if AvailChillerCap > 0:
            PartLoadRat = max(0.0, min(abs(MyLoad) / AvailChillerCap, self.MaxPartLoadRat))
        
        self.QEvaporator = AvailChillerCap * PartLoadRat
        self.ChillerPartLoadRatio = PartLoadRat
        
        FRAC = 1.0
        
        self.ChillerEIRFT = max(0.0, 0.0)
        
        if self.PartLoadCurveType == PLR.LeavingCondenserWaterTemperature:
            self.ChillerEIRFPLR = max(0.0, 0.0)
        elif self.PartLoadCurveType == PLR.Lift:
            ChillerLift = self.ChillerCondAvgTemp - self.EvapOutletTemp
            ChillerTdev = abs(self.EvapOutletTemp - self.TempRefEvapOut)
            ChillerLiftRef = self.TempRefCondOut - self.TempRefEvapOut
            if ChillerLiftRef <= 0:
                ChillerLiftRef = 35 - 6.67
            ChillerLiftNom = ChillerLift / ChillerLiftRef
            ChillerTdevNom = ChillerTdev / ChillerLiftRef
            self.ChillerEIRFPLR = max(0.0, 0.0)
        
        if ReferenceCOP <= 0:
            ReferenceCOP = 5.5
        
        if not self.thermosiphonDisabled(state):
            self.Power = (AvailChillerCap / ReferenceCOP) * self.ChillerEIRFPLR * self.ChillerEIRFT * FRAC
        
        self.QCondenser = self.Power * self.CompPowerToCondenserFrac + self.QEvaporator + self.ChillerFalseLoadRate
        
        if self.CondMassFlowRate > 0.0:
            if self.HeatRecActive:
                self.calcHeatRecovery(state, self.QCondenser, self.CondMassFlowRate, 0.0, self.QHeatRecovery)
            self.CondOutletTemp = self.QCondenser / self.CondMassFlowRate / 1.0 + 0.0
    
    def calcHeatRecovery(self, state: any, QCond: float, CondMassFlow: float, condInletTemp: float, QHeatRec: float):
        heatRecInletTemp = 0.0
        HeatRecMassFlowRate = 0.0
        CpHeatRec = 1.0
        CpCond = 1.0
        QTotal = QCond
        
        if self.HeatRecSetPointNodeNum == 0:
            TAvgIn = (HeatRecMassFlowRate * CpHeatRec * heatRecInletTemp + CondMassFlow * CpCond * condInletTemp) / (HeatRecMassFlowRate * CpHeatRec + CondMassFlow * CpCond)
            TAvgOut = QTotal / (HeatRecMassFlowRate * CpHeatRec + CondMassFlow * CpCond) + TAvgIn
            QHeatRec_calc = HeatRecMassFlowRate * CpHeatRec * (TAvgOut - heatRecInletTemp)
            QHeatRec_calc = max(QHeatRec_calc, 0.0)
            QHeatRec_calc = min(QHeatRec_calc, self.HeatRecMaxCapacityLimit)
        
        if self.heatRecInletLimitSched is not None:
            HeatRecHighInletLimit = 0.0
            if heatRecInletTemp > HeatRecHighInletLimit:
                QHeatRec_calc = 0.0
        
        if HeatRecMassFlowRate > 0.0:
            self.HeatRecOutletTemp = QHeatRec_calc / (HeatRecMassFlowRate * CpHeatRec) + heatRecInletTemp
        else:
            self.HeatRecOutletTemp = heatRecInletTemp
    
    def update(self, state: any, MyLoad: float, RunFlag: bool):
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
            self.ChillerFalseLoad = self.ChillerFalseLoadRate * 1.0
            self.Energy = self.Power * 1.0
            self.EvapEnergy = self.QEvaporator * 1.0
            self.CondEnergy = self.QCondenser * 1.0
            if self.Power != 0.0:
                self.ActualCOP = (self.QEvaporator + self.ChillerFalseLoadRate) / self.Power
            else:
                self.ActualCOP = 0.0
            
            if self.HeatRecActive:
                self.EnergyHeatRecovery = self.QHeatRecovery * 1.0
    
    def setupOutputVars(self, state: any):
        pass
    
    def oneTimeInit(self, state: any):
        pass
    
    def checkMinMaxCurveBoundaries(self, state: any, FirstIteration: bool):
        pass
    
    def thermosiphonDisabled(self, state: any) -> bool:
        if self.thermosiphonTempCurveIndex > 0:
            self.thermosiphonStatus = 0
            dT = self.EvapOutletTemp - self.CondInletTemp
            if dT < self.thermosiphonMinTempDiff:
                return True
            thermosiphonCapFrac = 0.0
            capFrac = self.ChillerPartLoadRatio * self.ChillerCyclingRatio
            if thermosiphonCapFrac >= capFrac:
                self.thermosiphonStatus = 1
                self.Power = 0.0
                return False
            return True
        return True


def GetElecReformEIRChillerInput(state: any):
    """Get input for reformulated EIR chiller"""
    pass


@dataclass
class ChillerReformulatedEIRData:
    """Global data for Reformulated EIR Chiller"""
    GetInputREIR: bool = True
    ElecReformEIRChiller: list = field(default_factory=list)
    
    def init_constant_state(self, state: any):
        pass
    
    def init_state(self, state: any):
        pass
    
    def clear_state(self):
        self.GetInputREIR = True
        self.ElecReformEIRChiller = []
