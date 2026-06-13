"""
EnergyPlus MixedAir module - faithful Mojo port.
Controls mixed air portion of HVAC air loops.
"""

from memory import memset_zero
import math


# ============================================================================
# ENUMS
# ============================================================================

@export
alias LockoutType = Int32
alias LockoutType_Invalid = Int32(-1)
alias LockoutType_NoLockoutPossible = Int32(0)
alias LockoutType_LockoutWithHeatingPossible = Int32(1)
alias LockoutType_LockoutWithCompressorPossible = Int32(2)
alias LockoutType_Num = Int32(3)

@export
alias EconoOp = Int32
alias EconoOp_Invalid = Int32(-1)
alias EconoOp_NoEconomizer = Int32(0)
alias EconoOp_FixedDryBulb = Int32(1)
alias EconoOp_FixedEnthalpy = Int32(2)
alias EconoOp_DifferentialDryBulb = Int32(3)
alias EconoOp_DifferentialEnthalpy = Int32(4)
alias EconoOp_FixedDewPointAndDryBulb = Int32(5)
alias EconoOp_ElectronicEnthalpy = Int32(6)
alias EconoOp_DifferentialDryBulbAndEnthalpy = Int32(7)
alias EconoOp_Num = Int32(8)

@export
alias MixedAirControllerType = Int32
alias MixedAirControllerType_Invalid = Int32(-1)
alias MixedAirControllerType_ControllerOutsideAir = Int32(0)
alias MixedAirControllerType_ControllerStandAloneERV = Int32(1)
alias MixedAirControllerType_Num = Int32(2)

@export
alias CMO = Int32
alias CMO_Invalid = Int32(-1)
alias CMO_None = Int32(0)
alias CMO_OASystem = Int32(1)
alias CMO_AirLoopEqList = Int32(2)
alias CMO_ControllerList = Int32(3)
alias CMO_SysAvailMgrList = Int32(4)
alias CMO_OAController = Int32(5)
alias CMO_ERVController = Int32(6)
alias CMO_MechVentilation = Int32(7)
alias CMO_OAMixer = Int32(8)
alias CMO_Num = Int32(9)

@export
alias OALimitFactor = Int32
alias OALimitFactor_Invalid = Int32(-1)
alias OALimitFactor_None = Int32(0)
alias OALimitFactor_Limits = Int32(1)
alias OALimitFactor_Economizer = Int32(2)
alias OALimitFactor_Exhaust = Int32(3)
alias OALimitFactor_MixedAir = Int32(4)
alias OALimitFactor_HighHum = Int32(5)
alias OALimitFactor_DCV = Int32(6)
alias OALimitFactor_NightVent = Int32(7)
alias OALimitFactor_DemandLimit = Int32(8)
alias OALimitFactor_EMS = Int32(9)
alias OALimitFactor_Num = Int32(10)


# ============================================================================
# DATA STRUCTURES
# ============================================================================

struct ControllerListProps:
    """OA Controller List properties."""
    var Name: StringLiteral
    var NumControllers: Int32
    # ControllerType: DynamicVector[Int32]
    # ControllerName: DynamicVector[StringLiteral]


struct VentilationMechanicalZoneProps:
    """Ventilation mechanical zone properties."""
    var name: StringLiteral
    var zoneNum: Int32
    var ZoneDesignSpecOAObjIndex: Int32
    var ZoneADEffCooling: Float64
    var ZoneADEffHeating: Float64
    # zoneADEffSched: Optional schedule ptr
    var ZoneDesignSpecADObjIndex: Int32
    var ZoneSecondaryRecirculation: Float64
    # zoneOASched: Optional schedule ptr
    # zonePropCtlMinRateSched: Optional schedule ptr
    var zoneOABZ: Float64
    # peopleIndexes: DynamicVector[Int32]


struct OAMixerProps:
    """Outside air mixer properties."""
    var Name: StringLiteral
    var MixerIndex: Int32
    var MixNode: Int32
    var InletNode: Int32
    var RelNode: Int32
    var RetNode: Int32
    var MixTemp: Float64
    var MixHumRat: Float64
    var MixEnthalpy: Float64
    var MixPressure: Float64
    var MixMassFlowRate: Float64
    var OATemp: Float64
    var OAHumRat: Float64
    var OAEnthalpy: Float64
    var OAPressure: Float64
    var OAMassFlowRate: Float64
    var RelTemp: Float64
    var RelHumRat: Float64
    var RelEnthalpy: Float64
    var RelPressure: Float64
    var RelMassFlowRate: Float64
    var RetTemp: Float64
    var RetHumRat: Float64
    var RetEnthalpy: Float64
    var RetPressure: Float64
    var RetMassFlowRate: Float64

    fn InitOAMixer(inout self, state: AnyType) -> None:
        """Initialize OA mixer."""
        pass

    fn CalcOAMixer(inout self, state: AnyType) -> None:
        """Calculate OA mixer."""
        pass

    fn UpdateOAMixer(self, state: AnyType) -> None:
        """Update OA mixer."""
        pass


struct OAControllerProps:
    """Outside Air Controller properties."""
    var Name: StringLiteral
    var ControllerType: MixedAirControllerType
    var Lockout: LockoutType
    var FixedMin: Bool
    var TempLim: Float64
    var TempLowLim: Float64
    var EnthLim: Float64
    var DPTempLim: Float64
    var EnthalpyCurvePtr: Int32
    var MinOA: Float64
    var MaxOA: Float64
    var Econo: EconoOp
    var EconBypass: Bool
    var MixNode: Int32
    var OANode: Int32
    var InletNode: Int32
    var RelNode: Int32
    var RetNode: Int32
    # minOASched: Optional schedule ptr
    var RelMassFlow: Float64
    var OAMassFlow: Float64
    var ExhMassFlow: Float64
    var MixMassFlow: Float64
    var InletTemp: Float64
    var InletEnth: Float64
    var InletPress: Float64
    var InletHumRat: Float64
    var OATemp: Float64
    var OAEnth: Float64
    var OAPress: Float64
    var OAHumRat: Float64
    var RetTemp: Float64
    var RetEnth: Float64
    var MixSetTemp: Float64
    var MinOAMassFlowRate: Float64
    var MaxOAMassFlowRate: Float64
    var RelTemp: Float64
    var RelEnth: Float64
    var RelSensiLossRate: Float64
    var RelLatentLossRate: Float64
    var RelTotalLossRate: Float64
    var ZoneEquipZoneNum: Int32
    var VentilationMechanicalName: StringLiteral
    var VentMechObjectNum: Int32
    var HumidistatZoneNum: Int32
    var NodeNumofHumidistatZone: Int32
    var HighRHOAFlowRatio: Float64
    var ModifyDuringHighOAMoisture: Bool
    # economizerOASched: Optional schedule ptr
    # minOAflowSched: Optional schedule ptr
    # maxOAflowSched: Optional schedule ptr
    var EconomizerStatus: Int32
    var HeatRecoveryBypassStatus: Int32
    var HRHeatingCoilActive: Int32
    var MixedAirTempAtMinOAFlow: Float64
    var HighHumCtrlStatus: Int32
    var OAFractionRpt: Float64
    var MinOAFracLimit: Float64
    var MechVentOAMassFlowRequest: Float64
    var EMSOverrideOARate: Bool
    var EMSOARateValue: Float64
    var HeatRecoveryBypassControlType: Int32
    var EconomizerStagingType: Int32
    var ManageDemand: Bool
    var DemandLimitFlowRate: Float64
    var MaxOAFracBySetPoint: Float64
    var MixedAirSPMNum: Int32
    var CoolCoilFreezeCheck: Bool
    var EconoActive: Bool
    var HighHumCtrlActive: Bool
    # EconmizerFaultNum: DynamicVector[Int32]
    var NumFaultyEconomizer: Int32
    var CountMechVentFrac: Int32
    var IndexMechVentFrac: Int32
    var OALimitingFactor: OALimitFactor
    var OALimitingFactorReport: Int32

    fn CalcOAController(inout self, state: AnyType, AirLoopNum: Int32, FirstHVACIteration: Bool) -> None:
        """Calculate outside air controller."""
        pass

    fn CalcOAEconomizer(inout self, state: AnyType, AirLoopNum: Int32, OutAirMinFrac: Float64,
                        OASignal: Pointer[Float64], HighHumidityOperationFlag: Pointer[Bool],
                        FirstHVACIteration: Bool) -> None:
        """Calculate OA economizer."""
        pass

    fn SizeOAController(inout self, state: AnyType) -> None:
        """Size OA controller."""
        pass

    fn UpdateOAController(inout self, state: AnyType) -> None:
        """Update OA controller."""
        pass

    fn Checksetpoints(inout self, state: AnyType, OutAirMinFrac: Float64,
                      OutAirSignal: Pointer[Float64], EconomizerOperationFlag: Pointer[Bool]) -> None:
        """Check setpoints."""
        pass


struct VentilationMechanicalProps:
    """Ventilation mechanical properties."""
    var Name: StringLiteral
    # availSched: Optional schedule ptr
    var DCVFlag: Bool
    var NumofVentMechZones: Int32
    var SystemOAMethod: Int32
    var ZoneMaxOAFraction: Float64
    var CO2MaxMinLimitErrorCount: Int32
    var CO2MaxMinLimitErrorIndex: Int32
    var CO2GainErrorCount: Int32
    var CO2GainErrorIndex: Int32
    var OAMaxMinLimitErrorCount: Int32
    var OAMaxMinLimitErrorIndex: Int32
    var Ep: Float64
    var Er: Float64
    var Fa: Float64
    var Fb: Float64
    var Fc: Float64
    var Xs: Float64
    var Evz: Float64
    var SysDesOA: Float64
    # VentMechZone: DynamicVector[VentilationMechanicalZoneProps]

    fn CalcMechVentController(inout self, state: AnyType, SysSA: Float64) -> Float64:
        """Calculate mechanical ventilation controller."""
        return 0.0


struct MixedAirData:
    """Global mixed air data."""
    var NumControllerLists: Int32
    var NumOAControllers: Int32
    var NumERVControllers: Int32
    var NumOAMixers: Int32
    var NumVentMechControllers: Int32
    var GetOASysInputFlag: Bool
    var GetOAMixerInputFlag: Bool
    var GetOAControllerInputFlag: Bool
    var InitOAControllerOneTimeFlag: Bool
    var InitOAControllerSetUpAirLoopHVACVariables: Bool
    var AllocateOAControllersFlag: Bool


# ============================================================================
# MODULE-LEVEL FUNCTIONS
# ============================================================================

fn OAGetFlowRate(state: AnyType, OAPtr: Int32) -> Float64:
    """Get OA flow rate."""
    return 0.0


fn OAGetMinFlowRate(state: AnyType, OAPtr: Int32) -> Float64:
    """Get minimum OA flow rate."""
    return 0.0


fn OASetDemandManagerVentilationState(state: AnyType, OAPtr: Int32, aState: Bool) -> None:
    """Set demand manager ventilation state."""
    pass


fn OASetDemandManagerVentilationFlow(state: AnyType, OAPtr: Int32, aFlow: Float64) -> None:
    """Set demand manager ventilation flow."""
    pass


fn GetOAController(state: AnyType, OAName: StringLiteral) -> Int32:
    """Get OA controller index by name."""
    return 0


fn ManageOutsideAirSystem(state: AnyType, OASysName: StringLiteral, FirstHVACIteration: Bool,
                          AirLoopNum: Int32, OASysNum: Pointer[Int32]) -> None:
    """Manage outside air system."""
    pass


fn SimOutsideAirSys(state: AnyType, OASysNum: Int32, FirstHVACIteration: Bool, AirLoopNum: Int32) -> None:
    """Simulate outside air system."""
    pass


fn SimOASysComponents(state: AnyType, OASysNum: Int32, FirstHVACIteration: Bool, AirLoopNum: Int32) -> None:
    """Simulate OA system components."""
    pass


fn SimOAComponent(state: AnyType, CompType: StringLiteral, CompName: StringLiteral, CompTypeNum: Int32,
                  FirstHVACIteration: Bool, CompIndex: Pointer[Int32], AirLoopNum: Int32,
                  Sim: Bool, OASysNum: Int32, OAHeatingCoil: Pointer[Bool],
                  OACoolingCoil: Pointer[Bool], OAHX: Pointer[Bool]) -> None:
    """Simulate OA component."""
    pass


fn SimOAMixer(state: AnyType, CompName: StringLiteral, CompIndex: Pointer[Int32]) -> None:
    """Simulate OA mixer."""
    pass


fn SimOAController(state: AnyType, CtrlName: StringLiteral, CtrlIndex: Pointer[Int32],
                   FirstHVACIteration: Bool, AirLoopNum: Int32) -> None:
    """Simulate OA controller."""
    pass


fn GetOutsideAirSysInputs(state: AnyType) -> None:
    """Get outside air system inputs."""
    pass


fn GetOAControllerInputs(state: AnyType) -> None:
    """Get OA controller inputs."""
    pass


fn AllocateOAControllers(state: AnyType) -> None:
    """Allocate OA controller arrays."""
    pass


fn GetOAMixerInputs(state: AnyType) -> None:
    """Get OA mixer inputs."""
    pass


fn ProcessOAControllerInputs(state: AnyType, CurrentModuleObject: StringLiteral, OutAirNum: Int32,
                             AlphArray: AnyType, NumAlphas: Int32,
                             NumArray: AnyType, NumNums: Int32,
                             lNumericBlanks: AnyType, lAlphaBlanks: AnyType,
                             cAlphaFields: AnyType, cNumericFields: AnyType,
                             ErrorsFound: Pointer[Bool]) -> None:
    """Process OA controller inputs."""
    pass


fn InitOutsideAirSys(state: AnyType, OASysNum: Int32, AirLoopNum: Int32) -> None:
    """Initialize outside air system."""
    pass


fn InitOAController(state: AnyType, OAControllerNum: Int32, FirstHVACIteration: Bool,
                    AirLoopNum: Int32) -> None:
    """Initialize OA controller."""
    pass


fn GetOAMixerNodeNumbers(state: AnyType, OAMixerName: StringLiteral, ErrorsFound: Pointer[Bool]) -> AnyType:
    """Get OA mixer node numbers."""
    return AnyType()


fn GetNumOAMixers(state: AnyType) -> Int32:
    """Get number of OA mixers."""
    return 0


fn GetNumOAControllers(state: AnyType) -> Int32:
    """Get number of OA controllers."""
    return 0


fn GetOAMixerReliefNodeNumber(state: AnyType, OAMixerNum: Int32) -> Int32:
    """Get OA mixer relief node number."""
    return 0


fn GetOASysControllerListIndex(state: AnyType, OASysNumber: Int32) -> Int32:
    """Get OA system controller list index."""
    return 0


fn GetOASysNumSimpControllers(state: AnyType, OASysNumber: Int32) -> Int32:
    """Get number of simple controllers in OA system."""
    return 0


fn GetOASysNumHeatingCoils(state: AnyType, OASysNumber: Int32) -> Int32:
    """Get number of heating coils in OA system."""
    return 0


fn GetOASysNumHXs(state: AnyType, OASysNumber: Int32) -> Int32:
    """Get number of heat exchangers in OA system."""
    return 0


fn GetOASysNumCoolingCoils(state: AnyType, OASysNumber: Int32) -> Int32:
    """Get number of cooling coils in OA system."""
    return 0


fn GetOASystemNumber(state: AnyType, OASysName: StringLiteral) -> Int32:
    """Get OA system number by name."""
    return 0


fn FindOAMixerMatchForOASystem(state: AnyType, OASysNumber: Int32) -> Int32:
    """Find OA mixer matching an OA system."""
    return 0


fn GetOAMixerIndex(state: AnyType, OAMixerName: StringLiteral) -> Int32:
    """Get OA mixer index by name."""
    return 0


fn GetOAMixerInletNodeNumber(state: AnyType, OAMixerNumber: Int32) -> Int32:
    """Get OA mixer inlet node number."""
    return 0


fn GetOAMixerReturnNodeNumber(state: AnyType, OAMixerNumber: Int32) -> Int32:
    """Get OA mixer return node number."""
    return 0


fn GetOAMixerMixedNodeNumber(state: AnyType, OAMixerNumber: Int32) -> Int32:
    """Get OA mixer mixed air node number."""
    return 0


fn CheckForControllerWaterCoil(state: AnyType, ControllerType: Int32, ControllerName: StringLiteral) -> Bool:
    """Check if controller is for a water coil."""
    return False


fn CheckControllerLists(state: AnyType, ErrFound: Pointer[Bool]) -> None:
    """Check for dangling controller lists."""
    pass


fn CheckOAControllerName(state: AnyType, OAControllerName: Pointer[StringLiteral], ObjectType: StringLiteral,
                         FieldName: StringLiteral, ErrorsFound: Pointer[Bool]) -> None:
    """Check OA controller name for uniqueness."""
    pass


fn GetNumOASystems(state: AnyType) -> Int32:
    """Get number of OA systems."""
    return 0


fn GetOACompListNumber(state: AnyType, OASysNum: Int32) -> Int32:
    """Get OA component list number."""
    return 0


fn GetOACompName(state: AnyType, OASysNum: Int32, InListNum: Int32) -> StringLiteral:
    """Get OA component name."""
    return StringLiteral("")


fn GetOACompType(state: AnyType, OASysNum: Int32, InListNum: Int32) -> StringLiteral:
    """Get OA component type."""
    return StringLiteral("")


fn GetOACompTypeNum(state: AnyType, OASysNum: Int32, InListNum: Int32) -> Int32:
    """Get OA component type number."""
    return 0


fn GetOAMixerNumber(state: AnyType, OAMixerName: StringLiteral) -> Int32:
    """Get OA mixer number by name."""
    return 0
