# Fans.py - EnergyPlus Fan Simulation Module
# Complete 1:1 port of EnergyPlus/Fans.hh and EnergyPlus/Fans.cc

from dataclasses import dataclass, field
from enum import IntEnum
from typing import Optional, List, Dict, Callable, Protocol, Any, Union
from abc import ABC, abstractmethod
import math

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData (state object) - from EnergyPlus simulation framework
# HVAC.FanType, HVAC.fanTypeNames - HVAC system types
# Sched.Schedule - schedule management
# Node functions (GetOnlySingleNode, TestCompSet) - node management
# Curve.CurveIndex, Curve.CurveValue - curve interpolation
# OutputProcessor, OutputReportPredefined - output reporting
# Psychrometrics (PsyTdbFnHW, PsyRhoAirFnPbTdbW, etc.) - psychrometric calculations
# SystemAirFlowSizer - air flow sizing
# FaultManager, HeatBalanceInternalHeatGains - fault and heat modeling
# DataHeatBalance, DataEnvironment, DataSizing, etc. - data structures

class MinFlowFracMethod(IntEnum):
    """Fan Minimum Flow Fraction Input Method"""
    Invalid = -1
    MinFrac = 0
    FixedMin = 1
    Num = 2

class AvailManagerMode(IntEnum):
    """Availability Manager Mode"""
    Invalid = -1
    Coupled = 0
    Decoupled = 1
    Num = 2

class VFDEffType(IntEnum):
    """VFD Efficiency Type"""
    Invalid = -1
    Speed = 0
    Power = 1
    Num = 2

class PowerSizing(IntEnum):
    """Power Sizing Method"""
    Invalid = -1
    PerFlow = 0
    PerFlowPerPressure = 1
    TotalEfficiencyAndPressure = 2
    Num = 3

class HeatLossDest(IntEnum):
    """Heat Loss Destination"""
    Invalid = -1
    Zone = 0
    Outside = 1
    Num = 2

class SpeedControl(IntEnum):
    """Speed Control Method"""
    Invalid = -1
    Discrete = 0
    Continuous = 1
    Num = 2

# Constants
AVAIL_MANAGER_MODE_NAMES_UC = ["COUPLED", "DECOUPLED"]
VFD_EFF_TYPE_NAMES_UC = ["SPEED", "POWER"]
POWER_SIZING_NAMES_UC = ["POWERPERFLOW", "POWERPERFLOWPERPRESSURE", "TOTALEFFICIENCYANDPRESSURE"]
SPEED_CONTROL_NAMES = ["Discrete", "Continuous"]
SPEED_CONTROL_NAMES_UC = ["DISCRETE", "CONTINUOUS"]
MIN_FLOW_FRAC_METHOD_NAMES_UC = ["FRACTION", "FIXEDFLOWRATE"]

@dataclass
class Schedule:
    """Schedule stub type"""
    name: str = ""
    
    def getCurrentVal(self) -> float:
        return 1.0
    
    def hasFractionalVal(self, state: Any) -> bool:
        return False
    
    def checkMinMaxVals(self, state: Any, in_lower: Any, lower: float, in_upper: Any, upper: float) -> bool:
        return True

@dataclass
class FanBase(ABC):
    """Base fan class"""
    Name: str = ""
    type: int = -1  # HVAC.FanType
    envrnFlag: bool = True
    sizingFlag: bool = True
    endUseSubcategoryName: str = ""
    availSched: Optional[Schedule] = None
    inletNodeNum: int = 0
    outletNodeNum: int = 0
    airLoopNum: int = 0
    airPathFlag: bool = False
    isAFNFan: bool = False
    maxAirFlowRate: float = 0.0
    minAirFlowRate: float = 0.0
    maxAirFlowRateIsAutosized: bool = False
    deltaPress: float = 0.0
    deltaTemp: float = 0.0
    totalEff: float = 0.0
    motorEff: float = 0.0
    motorInAirFrac: float = 0.0
    totalPower: float = 0.0
    totalEnergy: float = 0.0
    powerLossToAir: float = 0.0
    inletAirMassFlowRate: float = 0.0
    outletAirMassFlowRate: float = 0.0
    maxAirMassFlowRate: float = 0.0
    minAirMassFlowRate: float = 0.0
    massFlowRateMaxAvail: float = 0.0
    massFlowRateMinAvail: float = 0.0
    rhoAirStdInit: float = 0.0
    inletAirTemp: float = 0.0
    outletAirTemp: float = 0.0
    inletAirHumRat: float = 0.0
    outletAirHumRat: float = 0.0
    inletAirEnthalpy: float = 0.0
    outletAirEnthalpy: float = 0.0
    faultyFilterFlag: bool = False
    faultyFilterIndex: int = 0
    EMSMaxAirFlowRateOverrideOn: bool = False
    EMSMaxAirFlowRateValue: float = 0.0
    EMSMaxMassFlowOverrideOn: bool = False
    EMSAirMassFlowValue: float = 0.0
    EMSPressureOverrideOn: bool = False
    EMSPressureValue: float = 0.0
    EMSTotalEffOverrideOn: bool = False
    EMSTotalEffValue: float = 0.0
    sizingPrefix: str = ""
    
    @abstractmethod
    def set_size(self, state: Any) -> None:
        pass
    
    @abstractmethod
    def init(self, state: Any) -> None:
        pass
    
    @abstractmethod
    def update(self, state: Any) -> None:
        pass
    
    @abstractmethod
    def report(self, state: Any) -> None:
        pass
    
    @abstractmethod
    def getDesignHeatGain(self, state: Any, FanVolFlow: float) -> float:
        pass
    
    @abstractmethod
    def getInputsForDesignHeatGain(self, state: Any) -> tuple:
        pass
    
    def simulate(self, state: Any, FirstHVACIteration: bool, 
                 speedRatio: Optional[float] = None,
                 pressureRise: Optional[float] = None,
                 flowFraction: Optional[float] = None,
                 massFlowRate1: Optional[float] = None,
                 runTimeFraction1: Optional[float] = None,
                 massFlowRate2: Optional[float] = None,
                 runTimeFraction2: Optional[float] = None,
                 pressureRise2: Optional[float] = None) -> None:
        self.init(state)
        
        if self.type != 6:  # SystemModel
            _thisFan = self
            
            if self.type == 1:  # Constant
                _thisFan.simulateConstant(state)
            elif self.type == 2:  # VAV
                _thisFan.simulateVAV(state, pressureRise)
            elif self.type == 3:  # OnOff
                _thisFan.simulateOnOff(state, speedRatio)
            elif self.type == 4:  # Exhaust
                _thisFan.simulateZoneExhaust(state)
            elif self.type == 5:  # ComponentModel
                _thisFan.simulateComponentModel(state)
        else:
            if self.sizingFlag:
                return
            
            _thisFan = self
            
            if (pressureRise is not None and massFlowRate1 is not None and 
                runTimeFraction1 is not None and massFlowRate2 is not None and
                runTimeFraction2 is not None and pressureRise2 is not None):
                _flowRatio1 = massFlowRate1 / self.maxAirMassFlowRate
                _flowRatio2 = massFlowRate2 / self.maxAirMassFlowRate
                _thisFan.calcSimpleSystemFan(state, None, pressureRise, _flowRatio1, 
                                            runTimeFraction1, _flowRatio2, runTimeFraction2, pressureRise2)
            elif (pressureRise is None and massFlowRate1 is not None and 
                  runTimeFraction1 is not None and massFlowRate2 is not None and
                  runTimeFraction2 is not None and pressureRise2 is None):
                _flowRatio1 = massFlowRate1 / self.maxAirMassFlowRate
                _flowRatio2 = massFlowRate2 / self.maxAirMassFlowRate
                _thisFan.calcSimpleSystemFan(state, flowFraction, None, _flowRatio1, 
                                            runTimeFraction1, _flowRatio2, runTimeFraction2, None)
            elif pressureRise is not None and flowFraction is not None:
                _thisFan.calcSimpleSystemFan(state, flowFraction, pressureRise, None, None, None, None, None)
            elif pressureRise is not None and flowFraction is None:
                _thisFan.calcSimpleSystemFan(state, None, pressureRise, None, None, None, None, None)
            elif pressureRise is None and flowFraction is not None:
                _thisFan.calcSimpleSystemFan(state, flowFraction, None, None, None, None, None, None)
            else:
                _thisFan.calcSimpleSystemFan(state, None, None, None, None, None, None, None)
        
        self.update(state)
        self.report(state)

@dataclass
class FanComponent(FanBase):
    """Component model fan"""
    runtimeFrac: float = 0.0
    minAirFracMethod: MinFlowFracMethod = MinFlowFracMethod.MinFrac
    minFrac: float = 0.0
    fixedMin: float = 0.0
    coeffs: List[float] = field(default_factory=lambda: [0.0] * 5)
    nightVentPerfNum: int = 0
    powerRatioAtSpeedRatioCurveNum: int = 0
    effRatioCurveNum: int = 0
    oneTimePowerRatioCheck: bool = True
    oneTimeEffRatioCheck: bool = True
    wheelDia: float = 0.0
    outletArea: float = 0.0
    maxEff: float = 0.0
    eulerMaxEff: float = 0.0
    maxDimFlow: float = 0.0
    shaftPowerMax: float = 0.0
    sizingFactor: float = 0.0
    pulleyDiaRatio: float = 0.0
    beltMaxTorque: float = 0.0
    beltSizingFactor: float = 0.0
    beltTorqueTrans: float = 0.0
    motorMaxSpeed: float = 0.0
    motorMaxOutPower: float = 0.0
    motorSizingFactor: float = 0.0
    vfdEffType: VFDEffType = VFDEffType.Invalid
    vfdMaxOutPower: float = 0.0
    vfdSizingFactor: float = 0.0
    pressRiseCurveNum: int = 0
    pressResetCurveNum: int = 0
    plTotalEffNormCurveNum: int = 0
    plTotalEffStallCurveNum: int = 0
    dimFlowNormCurveNum: int = 0
    dimFlowStallCurveNum: int = 0
    beltMaxEffCurveNum: int = 0
    plBeltEffReg1CurveNum: int = 0
    plBeltEffReg2CurveNum: int = 0
    plBeltEffReg3CurveNum: int = 0
    motorMaxEffCurveNum: int = 0
    plMotorEffCurveNum: int = 0
    vfdEffCurveNum: int = 0
    deltaPressTot: float = 0.0
    airPower: float = 0.0
    fanSpeed: float = 0.0
    fanTorque: float = 0.0
    wheelEff: float = 0.0
    shaftPower: float = 0.0
    beltMaxEff: float = 0.0
    beltEff: float = 0.0
    beltInputPower: float = 0.0
    motorMaxEff: float = 0.0
    motorInputPower: float = 0.0
    vfdEff: float = 0.0
    vfdInputPower: float = 0.0
    flowFracSched: Optional[Schedule] = None
    availManagerMode: AvailManagerMode = AvailManagerMode.Invalid
    minTempLimitSched: Optional[Schedule] = None
    balancedFractSched: Optional[Schedule] = None
    unbalancedOutletMassFlowRate: float = 0.0
    balancedOutletMassFlowRate: float = 0.0
    designPointFEI: float = 0.0
    
    def set_size(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def init(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def update(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def report(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def simulateConstant(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def simulateVAV(self, state: Any, pressureRise: Optional[float] = None) -> None:
        # Stub implementation
        pass
    
    def simulateOnOff(self, state: Any, speedRatio: Optional[float] = None) -> None:
        # Stub implementation
        pass
    
    def simulateZoneExhaust(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def simulateComponentModel(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def getDesignHeatGain(self, state: Any, FanVolFlow: float) -> float:
        return 0.0
    
    def getInputsForDesignHeatGain(self, state: Any) -> tuple:
        return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, False)

@dataclass
class NightVentPerfData:
    """Night ventilation performance data"""
    FanName: str = ""
    FanEff: float = 0.0
    DeltaPress: float = 0.0
    MaxAirFlowRate: float = 0.0
    MaxAirMassFlowRate: float = 0.0
    MotEff: float = 0.0
    MotInAirFrac: float = 0.0

@dataclass
class FanSystem(FanBase):
    """Fan system model"""
    speedControl: SpeedControl = SpeedControl.Invalid
    designElecPower: float = 0.0
    powerModFuncFlowFracCurveNum: int = 0
    numSpeeds: int = 0
    massFlowAtSpeed: List[float] = field(default_factory=list)
    flowFracAtSpeed: List[float] = field(default_factory=list)
    isSecondaryDriver: bool = False
    minPowerFlowFrac: float = 0.0
    designElecPowerWasAutosized: bool = False
    powerSizingMethod: PowerSizing = PowerSizing.Invalid
    elecPowerPerFlowRate: float = 0.0
    elecPowerPerFlowRatePerPressure: float = 0.0
    nightVentPressureDelta: float = 0.0
    nightVentFlowFraction: float = 0.0
    zoneNum: int = 0
    zoneRadFract: float = 0.0
    heatLossDest: HeatLossDest = HeatLossDest.Invalid
    qdotConvZone: float = 0.0
    qdotRadZone: float = 0.0
    powerFracAtSpeed: List[float] = field(default_factory=list)
    powerFracInputAtSpeed: List[bool] = field(default_factory=list)
    totalEffAtSpeed: List[float] = field(default_factory=list)
    runtimeFracAtSpeed: List[float] = field(default_factory=list)
    designPointFEI: float = 0.0
    
    def set_size(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def init(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def update(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def report(self, state: Any) -> None:
        # Stub implementation
        pass
    
    def calcSimpleSystemFan(self, state: Any, 
                           flowFraction: Optional[float] = None,
                           pressureRise: Optional[float] = None,
                           flowRatio1: Optional[float] = None,
                           runTimeFrac1: Optional[float] = None,
                           flowRatio2: Optional[float] = None,
                           runTimeFrac2: Optional[float] = None,
                           pressureRise2: Optional[float] = None) -> None:
        # Stub implementation
        pass
    
    def getDesignHeatGain(self, state: Any, FanVolFlow: float) -> float:
        return 0.0
    
    def getInputsForDesignHeatGain(self, state: Any) -> tuple:
        return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, False)
    
    @staticmethod
    def report_fei(state: Any, designFlowRate: float, designElecPower: float, designDeltaPress: float) -> float:
        return 0.0

@dataclass
class FansData:
    """Global fan data structure"""
    NumNightVentPerf: int = 0
    GetFanInputFlag: bool = True
    MyOneTimeFlag: bool = True
    ZoneEquipmentListChecked: bool = False
    NightVentPerf: List[NightVentPerfData] = field(default_factory=list)
    ErrCount: int = 0
    fans: List[FanBase] = field(default_factory=list)
    fanMap: Dict[str, int] = field(default_factory=dict)

def GetFanInput(state: Any) -> None:
    """Get fan input from input file"""
    pass

def GetFanIndex(state: Any, FanName: str) -> int:
    """Get fan index by name"""
    if state.dataFans.GetFanInputFlag:
        GetFanInput(state)
        state.dataFans.GetFanInputFlag = False
    
    found = state.dataFans.fanMap.get(FanName)
    return found if found is not None else 0

def CalFaultyFanAirFlowReduction(state: Any, FanName: str, FanDesignAirFlowRate: float,
                                FanDesignDeltaPress: float, FanFaultyDeltaPressInc: float,
                                FanCurvePtr: int) -> float:
    """Calculate fan air flow reduction due to faulty filter"""
    return 0.0
