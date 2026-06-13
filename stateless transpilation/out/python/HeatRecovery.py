# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state object (Protocol with dataHeatRecovery, dataLoopNodes, dataDXCoils, dataVariableSpeedCoils, dataCoilCoolingDX, etc.)
# - HVAC enums and constants (HXType, CoilType, FanOp, etc.)
# - Psychrometrics functions (PsyCpAirFnW, PsyRhoAirFnPbTdbW, PsyHFnTdbW, PsyTsatFnHPb, PsyWFnTdbH, PsyWFnTdpPb, PsyRhFnTdbWPb)
# - Curve evaluation (CurveValue, GetCurveIndex)
# - Schedule management (GetScheduleAlwaysOn, GetSchedule)
# - Node utilities (GetOnlySingleNode, TestCompSet, etc.)
# - General utilities (FindItemInList, SameString, ShowWarningError, etc.)
# - Sched::Schedule type (pointer-like)

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any
import math

KELVZERO = 273.16
SMALL = 1.0e-10

class HXConfiguration(IntEnum):
    Invalid = -1
    CounterFlow = 0
    ParallelFlow = 1
    CrossFlowBothUnmixed = 2
    CrossFlowOther = 3
    Num = 4

class HXExchConfigType(IntEnum):
    Invalid = -1
    Plate = 0
    Rotary = 1
    Num = 2

class FrostControlOption(IntEnum):
    Invalid = -1
    None_ = 0
    ExhaustOnly = 1
    ExhaustAirRecirculation = 2
    MinimumExhaustTemperature = 3
    Num = 4

class CalculateNTUBoundsErrors(IntEnum):
    Invalid = -1
    NoError = 0
    MassFlowRatio = 1
    NominalEffectiveness1 = 2
    NominalEffectiveness2 = 3
    Quantity = 4
    NominalEffectiveness3 = 5
    Num = 6

class HXOperation(IntEnum):
    Invalid = -1
    WhenFansOn = 0
    Scheduled = 1
    WhenOutsideEconomizerLimits = 2
    WhenMinOA = 3
    Num = 4

@dataclass
class ErrorTracker:
    print_flag: bool = False
    index: int = 0
    count: int = 0
    buffer1: str = ""
    buffer2: str = ""
    buffer3: str = ""
    last: float = 0.0

@dataclass
class BalancedDesDehumPerfData:
    Name: str = ""
    PerfType: str = ""
    NomSupAirVolFlow: float = 0.0
    NomProcAirFaceVel: float = 0.0
    NomElecPower: float = 0.0
    B: List[float] = field(default_factory=lambda: [0.0] * 8)
    T_MinRegenAirInTemp: float = 0.0
    T_MaxRegenAirInTemp: float = 0.0
    T_MinRegenAirInHumRat: float = 0.0
    T_MaxRegenAirInHumRat: float = 0.0
    T_MinProcAirInTemp: float = 0.0
    T_MaxProcAirInTemp: float = 0.0
    T_MinProcAirInHumRat: float = 0.0
    T_MaxProcAirInHumRat: float = 0.0
    T_MinFaceVel: float = 0.0
    T_MaxFaceVel: float = 0.0
    MinRegenAirOutTemp: float = 0.0
    MaxRegenAirOutTemp: float = 0.0
    T_MinRegenAirInRelHum: float = 0.0
    T_MaxRegenAirInRelHum: float = 0.0
    T_MinProcAirInRelHum: float = 0.0
    T_MaxProcAirInRelHum: float = 0.0
    C: List[float] = field(default_factory=lambda: [0.0] * 8)
    H_MinRegenAirInTemp: float = 0.0
    H_MaxRegenAirInTemp: float = 0.0
    H_MinRegenAirInHumRat: float = 0.0
    H_MaxRegenAirInHumRat: float = 0.0
    H_MinProcAirInTemp: float = 0.0
    H_MaxProcAirInTemp: float = 0.0
    H_MinProcAirInHumRat: float = 0.0
    H_MaxProcAirInHumRat: float = 0.0
    H_MinFaceVel: float = 0.0
    H_MaxFaceVel: float = 0.0
    MinRegenAirOutHumRat: float = 0.0
    MaxRegenAirOutHumRat: float = 0.0
    H_MinRegenAirInRelHum: float = 0.0
    H_MaxRegenAirInRelHum: float = 0.0
    H_MinProcAirInRelHum: float = 0.0
    H_MaxProcAirInRelHum: float = 0.0
    regenInRelHumTempErr: ErrorTracker = field(default_factory=ErrorTracker)
    procInRelHumTempErr: ErrorTracker = field(default_factory=ErrorTracker)
    regenInRelHumHumRatErr: ErrorTracker = field(default_factory=ErrorTracker)
    procInRelHumHumRatErr: ErrorTracker = field(default_factory=ErrorTracker)
    regenOutHumRatFailedErr: ErrorTracker = field(default_factory=ErrorTracker)
    imbalancedFlowErr: ErrorTracker = field(default_factory=ErrorTracker)
    T_RegenInTempError: ErrorTracker = field(default_factory=ErrorTracker)
    T_RegenInHumRatError: ErrorTracker = field(default_factory=ErrorTracker)
    T_ProcInTempError: ErrorTracker = field(default_factory=ErrorTracker)
    T_ProcInHumRatError: ErrorTracker = field(default_factory=ErrorTracker)
    T_FaceVelError: ErrorTracker = field(default_factory=ErrorTracker)
    regenOutTempError: ErrorTracker = field(default_factory=ErrorTracker)
    regenOutTempFailedError: ErrorTracker = field(default_factory=ErrorTracker)
    H_RegenInTempError: ErrorTracker = field(default_factory=ErrorTracker)
    H_RegenInHumRatError: ErrorTracker = field(default_factory=ErrorTracker)
    H_ProcInTempError: ErrorTracker = field(default_factory=ErrorTracker)
    H_ProcInHumRatError: ErrorTracker = field(default_factory=ErrorTracker)
    H_FaceVelError: ErrorTracker = field(default_factory=ErrorTracker)
    regenOutHumRatError: ErrorTracker = field(default_factory=ErrorTracker)
    NumericFieldNames: List[str] = field(default_factory=list)

@dataclass
class ErrorTracker2:
    OutputChar: str = ""
    OutputCharLo: str = ""
    OutputCharHi: str = ""
    CharValue: str = ""
    TimeStepSysLast: float = 0.0
    CurrentEndTime: float = 0.0
    CurrentEndTimeLast: float = 0.0

@dataclass
class HeatExchCond:
    Name: str = ""
    type: Any = None
    HeatExchPerfName: str = ""
    availSched: Optional[Any] = None
    FlowArr: HXConfiguration = HXConfiguration.Invalid
    EconoLockOut: bool = False
    hARatio: float = 0.0
    NomSupAirVolFlow: float = 0.0
    NomSupAirInTemp: float = 0.0
    NomSupAirOutTemp: float = 0.0
    NomSecAirVolFlow: float = 0.0
    NomSecAirInTemp: float = 0.0
    NomElecPower: float = 0.0
    UA0: float = 0.0
    mTSup0: float = 0.0
    mTSec0: float = 0.0
    NomSupAirMassFlow: float = 0.0
    NomSecAirMassFlow: float = 0.0
    SupInletNode: int = 0
    SupOutletNode: int = 0
    SecInletNode: int = 0
    SecOutletNode: int = 0
    SupInTemp: float = 0.0
    SupInHumRat: float = 0.0
    SupInEnth: float = 0.0
    SupInMassFlow: float = 0.0
    SecInTemp: float = 0.0
    SecInHumRat: float = 0.0
    SecInEnth: float = 0.0
    SecInMassFlow: float = 0.0
    PerfDataIndex: int = 0
    FaceArea: float = 0.0
    HeatEffectSensible100: float = 0.0
    HeatEffectLatent100: float = 0.0
    CoolEffectSensible100: float = 0.0
    CoolEffectLatent100: float = 0.0
    HeatEffectSensibleCurveIndex: int = 0
    HeatEffectLatentCurveIndex: int = 0
    CoolEffectSensibleCurveIndex: int = 0
    CoolEffectLatentCurveIndex: int = 0
    ExchConfig: HXExchConfigType = HXExchConfigType.Invalid
    FrostControlType: FrostControlOption = FrostControlOption.Invalid
    ThresholdTemperature: float = 0.0
    InitialDefrostTime: float = 0.0
    RateofDefrostTimeIncrease: float = 0.0
    DefrostFraction: float = 0.0
    ControlToTemperatureSetPoint: bool = False
    SupOutTemp: float = 0.0
    SupOutHumRat: float = 0.0
    SupOutEnth: float = 0.0
    SupOutMassFlow: float = 0.0
    SecOutTemp: float = 0.0
    SecOutHumRat: float = 0.0
    SecOutEnth: float = 0.0
    SecOutMassFlow: float = 0.0
    SensHeatingRate: float = 0.0
    SensHeatingEnergy: float = 0.0
    LatHeatingRate: float = 0.0
    LatHeatingEnergy: float = 0.0
    TotHeatingRate: float = 0.0
    TotHeatingEnergy: float = 0.0
    SensCoolingRate: float = 0.0
    SensCoolingEnergy: float = 0.0
    LatCoolingRate: float = 0.0
    LatCoolingEnergy: float = 0.0
    TotCoolingRate: float = 0.0
    TotCoolingEnergy: float = 0.0
    ElecUseEnergy: float = 0.0
    ElecUseRate: float = 0.0
    SensEffectiveness: float = 0.0
    LatEffectiveness: float = 0.0
    SupBypassMassFlow: float = 0.0
    SecBypassMassFlow: float = 0.0
    LowFlowErrCount: int = 0
    LowFlowErrIndex: int = 0
    UnBalancedErrCount: int = 0
    UnBalancedErrIndex: int = 0
    myEnvrnFlag: bool = True
    SensEffectivenessFlag: bool = False
    LatEffectivenessFlag: bool = False
    NumericFieldNames: List[str] = field(default_factory=list)
    MySetPointTest: bool = True
    MySizeFlag: bool = True
    hasZoneERVController: bool = False

    def initialize(self, state: Any, CompanionCoilIndex: int, companionCoilType: Any) -> None:
        pass

    def size(self, state: Any) -> None:
        pass

    def CalcAirToAirPlateHeatExch(self, state: Any, HXUnitOn: bool, EconomizerFlag: Optional[bool] = None, HighHumCtrlFlag: Optional[bool] = None) -> None:
        pass

    def CalcAirToAirGenericHeatExch(self, state: Any, HXUnitOn: bool, FirstHVACIteration: bool, fanOp: Any, EconomizerFlag: Optional[bool] = None, HighHumCtrlFlag: Optional[bool] = None, HXPartLoadRatio: Optional[float] = None) -> None:
        pass

    def CalcDesiccantBalancedHeatExch(self, state: Any, HXUnitOn: bool, FirstHVACIteration: bool, fanOp: Any, PartLoadRatio: float, CompanionCoilIndex: int, companionCoilType: Any, RegenInletIsOANode: bool, EconomizerFlag: Optional[bool] = None, HighHumCtrlFlag: Optional[bool] = None) -> None:
        pass

    def FrostControl(self, state: Any) -> None:
        pass

    def UpdateHeatRecovery(self, state: Any) -> None:
        pass

    def ReportHeatRecovery(self, state: Any) -> None:
        pass

    def CheckModelBoundsTempEq(self, state: Any, T_RegenInTemp: float, T_RegenInHumRat: float, T_ProcInTemp: float, T_ProcInHumRat: float, T_FaceVel: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckModelBoundsHumRatEq(self, state: Any, H_RegenInTemp: float, H_RegenInHumRat: float, H_ProcInTemp: float, H_ProcInHumRat: float, H_FaceVel: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckModelBoundOutput_Temp(self, state: Any, RegenInTemp: float, RegenOutTemp: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckModelBoundOutput_HumRat(self, state: Any, RegenInHumRat: float, RegenOutHumRat: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckModelBoundsRH_TempEq(self, state: Any, T_RegenInTemp: float, T_RegenInHumRat: float, T_ProcInTemp: float, T_ProcInHumRat: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckModelBoundsRH_HumRatEq(self, state: Any, H_RegenInTemp: float, H_RegenInHumRat: float, H_ProcInTemp: float, H_ProcInHumRat: float, FirstHVACIteration: bool) -> None:
        pass

    def CheckForBalancedFlow(self, state: Any, ProcessInMassFlow: float, RegenInMassFlow: float, FirstHVACIteration: bool) -> None:
        pass

def SimHeatRecovery(state: Any, CompName: str, FirstHVACIteration: bool, CompIndex: int, fanOp: Any, HXPartLoadRatio: Optional[float] = None, HXUnitEnable: Optional[bool] = None, CompanionCoilIndex: Optional[int] = None, RegenInletIsOANode: Optional[bool] = None, EconomizerFlag: Optional[bool] = None, HighHumCtrlFlag: Optional[bool] = None, coilTypeOpt: Optional[Any] = None) -> int:
    pass

def GetHeatRecoveryInput(state: Any) -> None:
    pass

def SafeDiv(a: float, b: float) -> float:
    if abs(b) < SMALL:
        return a / (SMALL if b >= 0 else -SMALL)
    return a / b

def CalculateEpsFromNTUandZ(state: Any, NTU: float, Z: float, FlowArr: HXConfiguration) -> float:
    pass

def CalculateNTUfromEpsAndZ(state: Any, NTU: float, Err: CalculateNTUBoundsErrors, Z: float, FlowArr: HXConfiguration, Eps: float) -> None:
    pass

def GetNTUforCrossFlowBothUnmixed(state: Any, Eps: float, Z: float) -> float:
    pass

def GetSupplyInletNode(state: Any, HXName: str, ErrorsFound: bool) -> int:
    pass

def GetSupplyOutletNode(state: Any, HXName: str, ErrorsFound: bool) -> int:
    pass

def GetSecondaryInletNode(state: Any, HXName: str, ErrorsFound: bool) -> int:
    pass

def GetSecondaryOutletNode(state: Any, HXName: str, ErrorsFound: bool) -> int:
    pass

def GetSupplyAirFlowRate(state: Any, HXName: str, ErrorsFound: bool) -> float:
    pass

def GetHeatExchangerObjectTypeNum(state: Any, HXName: str, WhichHX: int, ErrorsFound: bool) -> Any:
    pass
