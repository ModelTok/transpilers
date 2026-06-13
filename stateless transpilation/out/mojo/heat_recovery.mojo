from math import exp, log, fabs, pow, min as math_min, max as math_max
from collections import InlineArray

alias KELVZERO = 273.16
alias SMALL = 1.0e-10

enum HXConfiguration:
    Invalid
    CounterFlow
    ParallelFlow
    CrossFlowBothUnmixed
    CrossFlowOther
    Num

enum HXExchConfigType:
    Invalid
    Plate
    Rotary
    Num

enum FrostControlOption:
    Invalid
    None_
    ExhaustOnly
    ExhaustAirRecirculation
    MinimumExhaustTemperature
    Num

enum CalculateNTUBoundsErrors:
    Invalid
    NoError
    MassFlowRatio
    NominalEffectiveness1
    NominalEffectiveness2
    Quantity
    NominalEffectiveness3
    Num

enum HXOperation:
    Invalid
    WhenFansOn
    Scheduled
    WhenOutsideEconomizerLimits
    WhenMinOA
    Num

@dataclass
struct ErrorTracker:
    var print_flag: Bool
    var index: Int32
    var count: Int32
    var buffer1: String
    var buffer2: String
    var buffer3: String
    var last: Float64

    fn __init__(inout self):
        self.print_flag = False
        self.index = 0
        self.count = 0
        self.buffer1 = ""
        self.buffer2 = ""
        self.buffer3 = ""
        self.last = 0.0

@dataclass
struct BalancedDesDehumPerfData:
    var Name: String
    var PerfType: String
    var NomSupAirVolFlow: Float64
    var NomProcAirFaceVel: Float64
    var NomElecPower: Float64
    var B: InlineArray[Float64, 8]
    var T_MinRegenAirInTemp: Float64
    var T_MaxRegenAirInTemp: Float64
    var T_MinRegenAirInHumRat: Float64
    var T_MaxRegenAirInHumRat: Float64
    var T_MinProcAirInTemp: Float64
    var T_MaxProcAirInTemp: Float64
    var T_MinProcAirInHumRat: Float64
    var T_MaxProcAirInHumRat: Float64
    var T_MinFaceVel: Float64
    var T_MaxFaceVel: Float64
    var MinRegenAirOutTemp: Float64
    var MaxRegenAirOutTemp: Float64
    var T_MinRegenAirInRelHum: Float64
    var T_MaxRegenAirInRelHum: Float64
    var T_MinProcAirInRelHum: Float64
    var T_MaxProcAirInRelHum: Float64
    var C: InlineArray[Float64, 8]
    var H_MinRegenAirInTemp: Float64
    var H_MaxRegenAirInTemp: Float64
    var H_MinRegenAirInHumRat: Float64
    var H_MaxRegenAirInHumRat: Float64
    var H_MinProcAirInTemp: Float64
    var H_MaxProcAirInTemp: Float64
    var H_MinProcAirInHumRat: Float64
    var H_MaxProcAirInHumRat: Float64
    var H_MinFaceVel: Float64
    var H_MaxFaceVel: Float64
    var MinRegenAirOutHumRat: Float64
    var MaxRegenAirOutHumRat: Float64
    var H_MinRegenAirInRelHum: Float64
    var H_MaxRegenAirInRelHum: Float64
    var H_MinProcAirInRelHum: Float64
    var H_MaxProcAirInRelHum: Float64
    var regenInRelHumTempErr: ErrorTracker
    var procInRelHumTempErr: ErrorTracker
    var regenInRelHumHumRatErr: ErrorTracker
    var procInRelHumHumRatErr: ErrorTracker
    var regenOutHumRatFailedErr: ErrorTracker
    var imbalancedFlowErr: ErrorTracker
    var T_RegenInTempError: ErrorTracker
    var T_RegenInHumRatError: ErrorTracker
    var T_ProcInTempError: ErrorTracker
    var T_ProcInHumRatError: ErrorTracker
    var T_FaceVelError: ErrorTracker
    var regenOutTempError: ErrorTracker
    var regenOutTempFailedError: ErrorTracker
    var H_RegenInTempError: ErrorTracker
    var H_RegenInHumRatError: ErrorTracker
    var H_ProcInTempError: ErrorTracker
    var H_ProcInHumRatError: ErrorTracker
    var H_FaceVelError: ErrorTracker
    var regenOutHumRatError: ErrorTracker
    var NumericFieldNames: List[String]

    fn __init__(inout self):
        self.Name = ""
        self.PerfType = ""
        self.NomSupAirVolFlow = 0.0
        self.NomProcAirFaceVel = 0.0
        self.NomElecPower = 0.0
        self.B = InlineArray[Float64, 8](fill=0.0)
        self.T_MinRegenAirInTemp = 0.0
        self.T_MaxRegenAirInTemp = 0.0
        self.T_MinRegenAirInHumRat = 0.0
        self.T_MaxRegenAirInHumRat = 0.0
        self.T_MinProcAirInTemp = 0.0
        self.T_MaxProcAirInTemp = 0.0
        self.T_MinProcAirInHumRat = 0.0
        self.T_MaxProcAirInHumRat = 0.0
        self.T_MinFaceVel = 0.0
        self.T_MaxFaceVel = 0.0
        self.MinRegenAirOutTemp = 0.0
        self.MaxRegenAirOutTemp = 0.0
        self.T_MinRegenAirInRelHum = 0.0
        self.T_MaxRegenAirInRelHum = 0.0
        self.T_MinProcAirInRelHum = 0.0
        self.T_MaxProcAirInRelHum = 0.0
        self.C = InlineArray[Float64, 8](fill=0.0)
        self.H_MinRegenAirInTemp = 0.0
        self.H_MaxRegenAirInTemp = 0.0
        self.H_MinRegenAirInHumRat = 0.0
        self.H_MaxRegenAirInHumRat = 0.0
        self.H_MinProcAirInTemp = 0.0
        self.H_MaxProcAirInTemp = 0.0
        self.H_MinProcAirInHumRat = 0.0
        self.H_MaxProcAirInHumRat = 0.0
        self.H_MinFaceVel = 0.0
        self.H_MaxFaceVel = 0.0
        self.MinRegenAirOutHumRat = 0.0
        self.MaxRegenAirOutHumRat = 0.0
        self.H_MinRegenAirInRelHum = 0.0
        self.H_MaxRegenAirInRelHum = 0.0
        self.H_MinProcAirInRelHum = 0.0
        self.H_MaxProcAirInRelHum = 0.0
        self.regenInRelHumTempErr = ErrorTracker()
        self.procInRelHumTempErr = ErrorTracker()
        self.regenInRelHumHumRatErr = ErrorTracker()
        self.procInRelHumHumRatErr = ErrorTracker()
        self.regenOutHumRatFailedErr = ErrorTracker()
        self.imbalancedFlowErr = ErrorTracker()
        self.T_RegenInTempError = ErrorTracker()
        self.T_RegenInHumRatError = ErrorTracker()
        self.T_ProcInTempError = ErrorTracker()
        self.T_ProcInHumRatError = ErrorTracker()
        self.T_FaceVelError = ErrorTracker()
        self.regenOutTempError = ErrorTracker()
        self.regenOutTempFailedError = ErrorTracker()
        self.H_RegenInTempError = ErrorTracker()
        self.H_RegenInHumRatError = ErrorTracker()
        self.H_ProcInTempError = ErrorTracker()
        self.H_ProcInHumRatError = ErrorTracker()
        self.H_FaceVelError = ErrorTracker()
        self.regenOutHumRatError = ErrorTracker()
        self.NumericFieldNames = List[String]()

@dataclass
struct ErrorTracker2:
    var OutputChar: String
    var OutputCharLo: String
    var OutputCharHi: String
    var CharValue: String
    var TimeStepSysLast: Float64
    var CurrentEndTime: Float64
    var CurrentEndTimeLast: Float64

    fn __init__(inout self):
        self.OutputChar = ""
        self.OutputCharLo = ""
        self.OutputCharHi = ""
        self.CharValue = ""
        self.TimeStepSysLast = 0.0
        self.CurrentEndTime = 0.0
        self.CurrentEndTimeLast = 0.0

@dataclass
struct HeatExchCond:
    var Name: String
    var type: AnyType
    var HeatExchPerfName: String
    var availSched: Optional[AnyPointer]
    var FlowArr: HXConfiguration
    var EconoLockOut: Bool
    var hARatio: Float64
    var NomSupAirVolFlow: Float64
    var NomSupAirInTemp: Float64
    var NomSupAirOutTemp: Float64
    var NomSecAirVolFlow: Float64
    var NomSecAirInTemp: Float64
    var NomElecPower: Float64
    var UA0: Float64
    var mTSup0: Float64
    var mTSec0: Float64
    var NomSupAirMassFlow: Float64
    var NomSecAirMassFlow: Float64
    var SupInletNode: Int32
    var SupOutletNode: Int32
    var SecInletNode: Int32
    var SecOutletNode: Int32
    var SupInTemp: Float64
    var SupInHumRat: Float64
    var SupInEnth: Float64
    var SupInMassFlow: Float64
    var SecInTemp: Float64
    var SecInHumRat: Float64
    var SecInEnth: Float64
    var SecInMassFlow: Float64
    var PerfDataIndex: Int32
    var FaceArea: Float64
    var HeatEffectSensible100: Float64
    var HeatEffectLatent100: Float64
    var CoolEffectSensible100: Float64
    var CoolEffectLatent100: Float64
    var HeatEffectSensibleCurveIndex: Int32
    var HeatEffectLatentCurveIndex: Int32
    var CoolEffectSensibleCurveIndex: Int32
    var CoolEffectLatentCurveIndex: Int32
    var ExchConfig: HXExchConfigType
    var FrostControlType: FrostControlOption
    var ThresholdTemperature: Float64
    var InitialDefrostTime: Float64
    var RateofDefrostTimeIncrease: Float64
    var DefrostFraction: Float64
    var ControlToTemperatureSetPoint: Bool
    var SupOutTemp: Float64
    var SupOutHumRat: Float64
    var SupOutEnth: Float64
    var SupOutMassFlow: Float64
    var SecOutTemp: Float64
    var SecOutHumRat: Float64
    var SecOutEnth: Float64
    var SecOutMassFlow: Float64
    var SensHeatingRate: Float64
    var SensHeatingEnergy: Float64
    var LatHeatingRate: Float64
    var LatHeatingEnergy: Float64
    var TotHeatingRate: Float64
    var TotHeatingEnergy: Float64
    var SensCoolingRate: Float64
    var SensCoolingEnergy: Float64
    var LatCoolingRate: Float64
    var LatCoolingEnergy: Float64
    var TotCoolingRate: Float64
    var TotCoolingEnergy: Float64
    var ElecUseEnergy: Float64
    var ElecUseRate: Float64
    var SensEffectiveness: Float64
    var LatEffectiveness: Float64
    var SupBypassMassFlow: Float64
    var SecBypassMassFlow: Float64
    var LowFlowErrCount: Int32
    var LowFlowErrIndex: Int32
    var UnBalancedErrCount: Int32
    var UnBalancedErrIndex: Int32
    var myEnvrnFlag: Bool
    var SensEffectivenessFlag: Bool
    var LatEffectivenessFlag: Bool
    var NumericFieldNames: List[String]
    var MySetPointTest: Bool
    var MySizeFlag: Bool
    var hasZoneERVController: Bool

    fn __init__(inout self):
        self.Name = ""
        self.type = AnyType()
        self.HeatExchPerfName = ""
        self.availSched = None
        self.FlowArr = HXConfiguration.Invalid
        self.EconoLockOut = False
        self.hARatio = 0.0
        self.NomSupAirVolFlow = 0.0
        self.NomSupAirInTemp = 0.0
        self.NomSupAirOutTemp = 0.0
        self.NomSecAirVolFlow = 0.0
        self.NomSecAirInTemp = 0.0
        self.NomElecPower = 0.0
        self.UA0 = 0.0
        self.mTSup0 = 0.0
        self.mTSec0 = 0.0
        self.NomSupAirMassFlow = 0.0
        self.NomSecAirMassFlow = 0.0
        self.SupInletNode = 0
        self.SupOutletNode = 0
        self.SecInletNode = 0
        self.SecOutletNode = 0
        self.SupInTemp = 0.0
        self.SupInHumRat = 0.0
        self.SupInEnth = 0.0
        self.SupInMassFlow = 0.0
        self.SecInTemp = 0.0
        self.SecInHumRat = 0.0
        self.SecInEnth = 0.0
        self.SecInMassFlow = 0.0
        self.PerfDataIndex = 0
        self.FaceArea = 0.0
        self.HeatEffectSensible100 = 0.0
        self.HeatEffectLatent100 = 0.0
        self.CoolEffectSensible100 = 0.0
        self.CoolEffectLatent100 = 0.0
        self.HeatEffectSensibleCurveIndex = 0
        self.HeatEffectLatentCurveIndex = 0
        self.CoolEffectSensibleCurveIndex = 0
        self.CoolEffectLatentCurveIndex = 0
        self.ExchConfig = HXExchConfigType.Invalid
        self.FrostControlType = FrostControlOption.Invalid
        self.ThresholdTemperature = 0.0
        self.InitialDefrostTime = 0.0
        self.RateofDefrostTimeIncrease = 0.0
        self.DefrostFraction = 0.0
        self.ControlToTemperatureSetPoint = False
        self.SupOutTemp = 0.0
        self.SupOutHumRat = 0.0
        self.SupOutEnth = 0.0
        self.SupOutMassFlow = 0.0
        self.SecOutTemp = 0.0
        self.SecOutHumRat = 0.0
        self.SecOutEnth = 0.0
        self.SecOutMassFlow = 0.0
        self.SensHeatingRate = 0.0
        self.SensHeatingEnergy = 0.0
        self.LatHeatingRate = 0.0
        self.LatHeatingEnergy = 0.0
        self.TotHeatingRate = 0.0
        self.TotHeatingEnergy = 0.0
        self.SensCoolingRate = 0.0
        self.SensCoolingEnergy = 0.0
        self.LatCoolingRate = 0.0
        self.LatCoolingEnergy = 0.0
        self.TotCoolingRate = 0.0
        self.TotCoolingEnergy = 0.0
        self.ElecUseEnergy = 0.0
        self.ElecUseRate = 0.0
        self.SensEffectiveness = 0.0
        self.LatEffectiveness = 0.0
        self.SupBypassMassFlow = 0.0
        self.SecBypassMassFlow = 0.0
        self.LowFlowErrCount = 0
        self.LowFlowErrIndex = 0
        self.UnBalancedErrCount = 0
        self.UnBalancedErrIndex = 0
        self.myEnvrnFlag = True
        self.SensEffectivenessFlag = False
        self.LatEffectivenessFlag = False
        self.NumericFieldNames = List[String]()
        self.MySetPointTest = True
        self.MySizeFlag = True
        self.hasZoneERVController = False

    fn initialize(inout self, state: AnyPointer, CompanionCoilIndex: Int32, companionCoilType: AnyType) -> None:
        pass

    fn size(inout self, state: AnyPointer) -> None:
        pass

    fn CalcAirToAirPlateHeatExch(inout self, state: AnyPointer, HXUnitOn: Bool, EconomizerFlag: Optional[Bool] = None, HighHumCtrlFlag: Optional[Bool] = None) -> None:
        pass

    fn CalcAirToAirGenericHeatExch(inout self, state: AnyPointer, HXUnitOn: Bool, FirstHVACIteration: Bool, fanOp: AnyType, EconomizerFlag: Optional[Bool] = None, HighHumCtrlFlag: Optional[Bool] = None, HXPartLoadRatio: Optional[Float64] = None) -> None:
        pass

    fn CalcDesiccantBalancedHeatExch(inout self, state: AnyPointer, HXUnitOn: Bool, FirstHVACIteration: Bool, fanOp: AnyType, PartLoadRatio: Float64, CompanionCoilIndex: Int32, companionCoilType: AnyType, RegenInletIsOANode: Bool, EconomizerFlag: Optional[Bool] = None, HighHumCtrlFlag: Optional[Bool] = None) -> None:
        pass

    fn FrostControl(inout self, state: AnyPointer) -> None:
        pass

    fn UpdateHeatRecovery(inout self, state: AnyPointer) -> None:
        pass

    fn ReportHeatRecovery(inout self, state: AnyPointer) -> None:
        pass

    fn CheckModelBoundsTempEq(self, state: AnyPointer, T_RegenInTemp: Float64, T_RegenInHumRat: Float64, T_ProcInTemp: Float64, T_ProcInHumRat: Float64, T_FaceVel: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckModelBoundsHumRatEq(self, state: AnyPointer, H_RegenInTemp: Float64, H_RegenInHumRat: Float64, H_ProcInTemp: Float64, H_ProcInHumRat: Float64, H_FaceVel: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckModelBoundOutput_Temp(self, state: AnyPointer, RegenInTemp: Float64, RegenOutTemp: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckModelBoundOutput_HumRat(self, state: AnyPointer, RegenInHumRat: Float64, RegenOutHumRat: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckModelBoundsRH_TempEq(self, state: AnyPointer, T_RegenInTemp: Float64, T_RegenInHumRat: Float64, T_ProcInTemp: Float64, T_ProcInHumRat: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckModelBoundsRH_HumRatEq(self, state: AnyPointer, H_RegenInTemp: Float64, H_RegenInHumRat: Float64, H_ProcInTemp: Float64, H_ProcInHumRat: Float64, FirstHVACIteration: Bool) -> None:
        pass

    fn CheckForBalancedFlow(self, state: AnyPointer, ProcessInMassFlow: Float64, RegenInMassFlow: Float64, FirstHVACIteration: Bool) -> None:
        pass

fn SimHeatRecovery(state: AnyPointer, CompName: StringRef, FirstHVACIteration: Bool, inout CompIndex: Int32, fanOp: AnyType, HXPartLoadRatio: Optional[Float64] = None, HXUnitEnable: Optional[Bool] = None, CompanionCoilIndex: Optional[Int32] = None, RegenInletIsOANode: Optional[Bool] = None, EconomizerFlag: Optional[Bool] = None, HighHumCtrlFlag: Optional[Bool] = None, coilTypeOpt: Optional[AnyType] = None) -> None:
    pass

fn GetHeatRecoveryInput(state: AnyPointer) -> None:
    pass

fn SafeDiv(a: Float64, b: Float64) -> Float64:
    if fabs(b) < SMALL:
        return a / (SMALL if b >= 0.0 else -SMALL)
    return a / b

fn CalculateEpsFromNTUandZ(state: AnyPointer, NTU: Float64, Z: Float64, FlowArr: HXConfiguration) -> Float64:
    return 0.0

fn CalculateNTUfromEpsAndZ(state: AnyPointer, inout NTU: Float64, inout Err: CalculateNTUBoundsErrors, Z: Float64, FlowArr: HXConfiguration, Eps: Float64) -> None:
    pass

fn GetNTUforCrossFlowBothUnmixed(state: AnyPointer, Eps: Float64, Z: Float64) -> Float64:
    return 0.0

fn GetSupplyInletNode(state: AnyPointer, HXName: StringRef, inout ErrorsFound: Bool) -> Int32:
    return 0

fn GetSupplyOutletNode(state: AnyPointer, HXName: StringRef, inout ErrorsFound: Bool) -> Int32:
    return 0

fn GetSecondaryInletNode(state: AnyPointer, HXName: StringRef, inout ErrorsFound: Bool) -> Int32:
    return 0

fn GetSecondaryOutletNode(state: AnyPointer, HXName: StringRef, inout ErrorsFound: Bool) -> Int32:
    return 0

fn GetSupplyAirFlowRate(state: AnyPointer, HXName: StringRef, inout ErrorsFound: Bool) -> Float64:
    return 0.0

fn GetHeatExchangerObjectTypeNum(state: AnyPointer, HXName: StringRef, inout WhichHX: Int32, inout ErrorsFound: Bool) -> AnyType:
    return AnyType()
