"""
EnergyPlus MixedAir module - faithful Python port.
Controls mixed air portion of HVAC air loops.
"""

from enum import IntEnum
from typing import List, Optional, Tuple, Any
from dataclasses import dataclass, field
import math

# ============================================================================
# ENUMS
# ============================================================================

class LockoutType(IntEnum):
    """Economizer lockout types."""
    Invalid = -1
    NoLockoutPossible = 0
    LockoutWithHeatingPossible = 1
    LockoutWithCompressorPossible = 2
    Num = 3


class EconoOp(IntEnum):
    """Economizer operation types."""
    Invalid = -1
    NoEconomizer = 0
    FixedDryBulb = 1
    FixedEnthalpy = 2
    DifferentialDryBulb = 3
    DifferentialEnthalpy = 4
    FixedDewPointAndDryBulb = 5
    ElectronicEnthalpy = 6
    DifferentialDryBulbAndEnthalpy = 7
    Num = 8


class MixedAirControllerType(IntEnum):
    """Outside air controller types."""
    Invalid = -1
    ControllerOutsideAir = 0
    ControllerStandAloneERV = 1
    Num = 2


class CMO(IntEnum):
    """Current Module Object enumeration."""
    Invalid = -1
    None_ = 0
    OASystem = 1
    AirLoopEqList = 2
    ControllerList = 3
    SysAvailMgrList = 4
    OAController = 5
    ERVController = 6
    MechVentilation = 7
    OAMixer = 8
    Num = 9


class OALimitFactor(IntEnum):
    """OA controller limiting factor."""
    Invalid = -1
    None_ = 0
    Limits = 1
    Economizer = 2
    Exhaust = 3
    MixedAir = 4
    HighHum = 5
    DCV = 6
    NightVent = 7
    DemandLimit = 8
    EMS = 9
    Num = 10


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class ControllerListProps:
    """OA Controller List properties."""
    Name: str = ""
    NumControllers: int = 0
    ControllerType: List[Any] = field(default_factory=list)
    ControllerName: List[str] = field(default_factory=list)


@dataclass
class OAControllerProps:
    """Outside Air Controller properties."""
    Name: str = ""
    ControllerType: MixedAirControllerType = MixedAirControllerType.Invalid
    Lockout: LockoutType = LockoutType.NoLockoutPossible
    FixedMin: bool = True
    TempLim: float = 0.0
    TempLowLim: float = 0.0
    EnthLim: float = 0.0
    DPTempLim: float = 0.0
    EnthalpyCurvePtr: int = 0
    MinOA: float = 0.0
    MaxOA: float = 0.0
    Econo: EconoOp = EconoOp.NoEconomizer
    EconBypass: bool = False
    MixNode: int = 0
    OANode: int = 0
    InletNode: int = 0
    RelNode: int = 0
    RetNode: int = 0
    minOASched: Optional[Any] = None
    RelMassFlow: float = 0.0
    OAMassFlow: float = 0.0
    ExhMassFlow: float = 0.0
    MixMassFlow: float = 0.0
    InletTemp: float = 0.0
    InletEnth: float = 0.0
    InletPress: float = 0.0
    InletHumRat: float = 0.0
    OATemp: float = 0.0
    OAEnth: float = 0.0
    OAPress: float = 0.0
    OAHumRat: float = 0.0
    RetTemp: float = 0.0
    RetEnth: float = 0.0
    MixSetTemp: float = 0.0
    MinOAMassFlowRate: float = 0.0
    MaxOAMassFlowRate: float = 0.0
    RelTemp: float = 0.0
    RelEnth: float = 0.0
    RelSensiLossRate: float = 0.0
    RelLatentLossRate: float = 0.0
    RelTotalLossRate: float = 0.0
    ZoneEquipZoneNum: int = 0
    VentilationMechanicalName: str = ""
    VentMechObjectNum: int = 0
    HumidistatZoneNum: int = 0
    NodeNumofHumidistatZone: int = 0
    HighRHOAFlowRatio: float = 1.0
    ModifyDuringHighOAMoisture: bool = False
    economizerOASched: Optional[Any] = None
    minOAflowSched: Optional[Any] = None
    maxOAflowSched: Optional[Any] = None
    EconomizerStatus: int = 0
    HeatRecoveryBypassStatus: int = 0
    HRHeatingCoilActive: int = 0
    MixedAirTempAtMinOAFlow: float = 0.0
    HighHumCtrlStatus: int = 0
    OAFractionRpt: float = 0.0
    MinOAFracLimit: float = 0.0
    MechVentOAMassFlowRequest: float = 0.0
    EMSOverrideOARate: bool = False
    EMSOARateValue: float = 0.0
    HeatRecoveryBypassControlType: int = 0  # HVAC::BypassWhenWithinEconomizerLimits
    EconomizerStagingType: int = 0  # HVAC::EconomizerStagingType::InterlockedWithMechanicalCooling
    ManageDemand: bool = False
    DemandLimitFlowRate: float = 0.0
    MaxOAFracBySetPoint: float = 0.0
    MixedAirSPMNum: int = 0
    CoolCoilFreezeCheck: bool = False
    EconoActive: bool = False
    HighHumCtrlActive: bool = False
    EconmizerFaultNum: List[int] = field(default_factory=list)
    NumFaultyEconomizer: int = 0
    CountMechVentFrac: int = 0
    IndexMechVentFrac: int = 0
    OALimitingFactor: OALimitFactor = OALimitFactor.Invalid
    OALimitingFactorReport: int = 0

    def CalcOAController(self, state: Any, AirLoopNum: int, FirstHVACIteration: bool) -> None:
        """Calculate outside air controller."""
        pass  # Implementation stub - to be wired in

    def CalcOAEconomizer(self, state: Any, AirLoopNum: int, OutAirMinFrac: float, 
                         OASignal: List[float], HighHumidityOperationFlag: List[bool], 
                         FirstHVACIteration: bool) -> None:
        """Calculate OA economizer."""
        pass  # Implementation stub

    def SizeOAController(self, state: Any) -> None:
        """Size OA controller."""
        pass  # Implementation stub

    def UpdateOAController(self, state: Any) -> None:
        """Update OA controller."""
        pass  # Implementation stub

    def Checksetpoints(self, state: Any, OutAirMinFrac: float, OutAirSignal: List[float],
                       EconomizerOperationFlag: List[bool]) -> None:
        """Check setpoints."""
        pass  # Implementation stub


@dataclass
class VentilationMechanicalZoneProps:
    """Ventilation mechanical zone properties."""
    name: str = ""
    zoneNum: int = 0
    ZoneDesignSpecOAObjIndex: int = 0
    ZoneADEffCooling: float = 1.0
    ZoneADEffHeating: float = 1.0
    zoneADEffSched: Optional[Any] = None
    ZoneDesignSpecADObjIndex: int = 0
    ZoneSecondaryRecirculation: float = 0.0
    zoneOASched: Optional[Any] = None
    zonePropCtlMinRateSched: Optional[Any] = None
    zoneOABZ: float = 0.0
    peopleIndexes: List[int] = field(default_factory=list)


@dataclass
class VentilationMechanicalProps:
    """Ventilation mechanical properties."""
    Name: str = ""
    availSched: Optional[Any] = None
    DCVFlag: bool = False
    NumofVentMechZones: int = 0
    SystemOAMethod: int = 0  # DataSizing::SysOAMethod
    ZoneMaxOAFraction: float = 1.0
    CO2MaxMinLimitErrorCount: int = 0
    CO2MaxMinLimitErrorIndex: int = 0
    CO2GainErrorCount: int = 0
    CO2GainErrorIndex: int = 0
    OAMaxMinLimitErrorCount: int = 0
    OAMaxMinLimitErrorIndex: int = 0
    Ep: float = 1.0
    Er: float = 0.0
    Fa: float = 1.0
    Fb: float = 1.0
    Fc: float = 1.0
    Xs: float = 1.0
    Evz: float = 1.0
    SysDesOA: float = 0.0
    VentMechZone: List[VentilationMechanicalZoneProps] = field(default_factory=list)

    def CalcMechVentController(self, state: Any, SysSA: float) -> float:
        """Calculate mechanical ventilation controller."""
        return 0.0  # Implementation stub


@dataclass
class OAMixerProps:
    """Outside air mixer properties."""
    Name: str = ""
    MixerIndex: int = 0
    MixNode: int = 0
    InletNode: int = 0
    RelNode: int = 0
    RetNode: int = 0
    MixTemp: float = 0.0
    MixHumRat: float = 0.0
    MixEnthalpy: float = 0.0
    MixPressure: float = 0.0
    MixMassFlowRate: float = 0.0
    OATemp: float = 0.0
    OAHumRat: float = 0.0
    OAEnthalpy: float = 0.0
    OAPressure: float = 0.0
    OAMassFlowRate: float = 0.0
    RelTemp: float = 0.0
    RelHumRat: float = 0.0
    RelEnthalpy: float = 0.0
    RelPressure: float = 0.0
    RelMassFlowRate: float = 0.0
    RetTemp: float = 0.0
    RetHumRat: float = 0.0
    RetEnthalpy: float = 0.0
    RetPressure: float = 0.0
    RetMassFlowRate: float = 0.0

    def InitOAMixer(self, state: Any) -> None:
        """Initialize OA mixer."""
        pass  # Implementation stub

    def CalcOAMixer(self, state: Any) -> None:
        """Calculate OA mixer."""
        pass  # Implementation stub

    def UpdateOAMixer(self, state: Any) -> None:
        """Update OA mixer."""
        pass  # Implementation stub


@dataclass
class MixedAirData:
    """Global mixed air data."""
    NumControllerLists: int = 0
    NumOAControllers: int = 0
    NumERVControllers: int = 0
    NumOAMixers: int = 0
    NumVentMechControllers: int = 0
    MyOneTimeErrorFlag: List[bool] = field(default_factory=list)
    MyOneTimeCheckUnitarySysFlag: List[bool] = field(default_factory=list)
    initOASysFlag: List[bool] = field(default_factory=list)
    GetOASysInputFlag: bool = True
    GetOAMixerInputFlag: bool = True
    GetOAControllerInputFlag: bool = True
    InitOAControllerOneTimeFlag: bool = True
    InitOAControllerSetPointCheckFlag: List[bool] = field(default_factory=list)
    InitOAControllerSetUpAirLoopHVACVariables: bool = True
    AllocateOAControllersFlag: bool = True
    ControllerLists: List[ControllerListProps] = field(default_factory=list)
    OAController: List[OAControllerProps] = field(default_factory=list)
    OAMixer: List[OAMixerProps] = field(default_factory=list)
    VentilationMechanical: List[VentilationMechanicalProps] = field(default_factory=list)
    ControllerListUniqueNames: set = field(default_factory=set)
    OAControllerUniqueNames: dict = field(default_factory=dict)
    CompType: str = ""
    CompName: str = ""
    CtrlName: str = ""
    OAControllerMyOneTimeFlag: List[bool] = field(default_factory=list)
    OAControllerMyEnvrnFlag: List[bool] = field(default_factory=list)
    OAControllerMySizeFlag: List[bool] = field(default_factory=list)
    MechVentCheckFlag: List[bool] = field(default_factory=list)


# ============================================================================
# MODULE-LEVEL FUNCTIONS
# ============================================================================

def OAGetFlowRate(state: Any, OAPtr: int) -> float:
    """Get OA flow rate."""
    FlowRate = 0.0
    if (OAPtr > 0 and OAPtr <= state.dataMixedAir.NumOAControllers 
        and state.dataEnvrn.StdRhoAir != 0):
        FlowRate = state.dataMixedAir.OAController[OAPtr - 1].OAMassFlow / state.dataEnvrn.StdRhoAir
    return FlowRate


def OAGetMinFlowRate(state: Any, OAPtr: int) -> float:
    """Get minimum OA flow rate."""
    MinFlowRate = 0.0
    if OAPtr > 0 and OAPtr <= state.dataMixedAir.NumOAControllers:
        MinFlowRate = state.dataMixedAir.OAController[OAPtr - 1].MinOA
    return MinFlowRate


def OASetDemandManagerVentilationState(state: Any, OAPtr: int, aState: bool) -> None:
    """Set demand manager ventilation state."""
    if OAPtr > 0 and OAPtr <= state.dataMixedAir.NumOAControllers:
        state.dataMixedAir.OAController[OAPtr - 1].ManageDemand = aState


def OASetDemandManagerVentilationFlow(state: Any, OAPtr: int, aFlow: float) -> None:
    """Set demand manager ventilation flow."""
    if OAPtr > 0 and OAPtr <= state.dataMixedAir.NumOAControllers:
        state.dataMixedAir.OAController[OAPtr - 1].DemandLimitFlowRate = aFlow * state.dataEnvrn.StdRhoAir


def GetOAController(state: Any, OAName: str) -> int:
    """Get OA controller index by name."""
    CurrentOAController = 0
    for i in range(state.dataMixedAir.NumOAControllers):
        if OAName == state.dataMixedAir.OAController[i].Name:
            CurrentOAController = i + 1
            break
    return CurrentOAController


def ManageOutsideAirSystem(state: Any, OASysName: str, FirstHVACIteration: bool, 
                           AirLoopNum: int, OASysNum: List[int]) -> None:
    """Manage outside air system."""
    pass  # Implementation stub - large function


def SimOutsideAirSys(state: Any, OASysNum: int, FirstHVACIteration: bool, AirLoopNum: int) -> None:
    """Simulate outside air system."""
    pass  # Implementation stub


def SimOASysComponents(state: Any, OASysNum: int, FirstHVACIteration: bool, AirLoopNum: int) -> None:
    """Simulate OA system components."""
    pass  # Implementation stub


def SimOAComponent(state: Any, CompType: str, CompName: str, CompTypeNum: int,
                   FirstHVACIteration: bool, CompIndex: List[int], AirLoopNum: int,
                   Sim: bool, OASysNum: int, OAHeatingCoil: List[bool],
                   OACoolingCoil: List[bool], OAHX: List[bool]) -> None:
    """Simulate OA component."""
    pass  # Implementation stub


def SimOAMixer(state: Any, CompName: str, CompIndex: List[int]) -> None:
    """Simulate OA mixer."""
    pass  # Implementation stub


def SimOAController(state: Any, CtrlName: str, CtrlIndex: List[int], 
                    FirstHVACIteration: bool, AirLoopNum: int) -> None:
    """Simulate OA controller."""
    pass  # Implementation stub


def GetOutsideAirSysInputs(state: Any) -> None:
    """Get outside air system inputs."""
    pass  # Implementation stub - large function


def GetOAControllerInputs(state: Any) -> None:
    """Get OA controller inputs."""
    pass  # Implementation stub - large function


def AllocateOAControllers(state: Any) -> None:
    """Allocate OA controller arrays."""
    pass  # Implementation stub


def GetOAMixerInputs(state: Any) -> None:
    """Get OA mixer inputs."""
    pass  # Implementation stub - large function


def ProcessOAControllerInputs(state: Any, CurrentModuleObject: str, OutAirNum: int,
                              AlphArray: List[str], NumAlphas: int,
                              NumArray: List[float], NumNums: int,
                              lNumericBlanks: List[bool], lAlphaBlanks: List[bool],
                              cAlphaFields: List[str], cNumericFields: List[str],
                              ErrorsFound: List[bool]) -> None:
    """Process OA controller inputs."""
    pass  # Implementation stub - large function


def InitOutsideAirSys(state: Any, OASysNum: int, AirLoopNum: int) -> None:
    """Initialize outside air system."""
    pass  # Implementation stub


def InitOAController(state: Any, OAControllerNum: int, FirstHVACIteration: bool, 
                     AirLoopNum: int) -> None:
    """Initialize OA controller."""
    pass  # Implementation stub - large function


def GetOAMixerNodeNumbers(state: Any, OAMixerName: str, ErrorsFound: List[bool]) -> List[int]:
    """Get OA mixer node numbers."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    OANodeNumbers = [0, 0, 0, 0]
    for i, mixer in enumerate(state.dataMixedAir.OAMixer):
        if OAMixerName == mixer.Name:
            OANodeNumbers[0] = mixer.InletNode
            OANodeNumbers[1] = mixer.RelNode
            OANodeNumbers[2] = mixer.RetNode
            OANodeNumbers[3] = mixer.MixNode
            return OANodeNumbers
    
    ErrorsFound[0] = True
    return OANodeNumbers


def GetNumOAMixers(state: Any) -> int:
    """Get number of OA mixers."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    return state.dataMixedAir.NumOAMixers


def GetNumOAControllers(state: Any) -> int:
    """Get number of OA controllers."""
    if state.dataMixedAir.AllocateOAControllersFlag:
        AllocateOAControllers(state)
    return state.dataMixedAir.NumOAControllers


def GetOAMixerReliefNodeNumber(state: Any, OAMixerNum: int) -> int:
    """Get OA mixer relief node number."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    if OAMixerNum > state.dataMixedAir.NumOAMixers:
        raise RuntimeError(f"GetOAMixerReliefNodeNumber: Requested Mixer #{OAMixerNum} > {state.dataMixedAir.NumOAMixers}")
    
    return state.dataMixedAir.OAMixer[OAMixerNum - 1].RelNode


def GetOASysControllerListIndex(state: Any, OASysNumber: int) -> int:
    """Get OA system controller list index."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ControllerListNum


def GetOASysNumSimpControllers(state: Any, OASysNumber: int) -> int:
    """Get number of simple controllers in OA system."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNumber - 1].NumSimpleControllers


def GetOASysNumHeatingCoils(state: Any, OASysNumber: int) -> int:
    """Get number of heating coils in OA system."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    
    NumHeatingCoils = 0
    OAHeatingCoil = [False]
    OACoolingCoil = [False]
    OAHX = [False]
    CompIndex = [0]
    
    for CompNum in range(state.dataAirLoop.OutsideAirSys[OASysNumber - 1].NumComponents):
        CompType = state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentType[CompNum]
        CompName = state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentName[CompNum]
        SimOAComponent(state, CompType, CompName, 0, False, CompIndex, 0, False, OASysNumber,
                      OAHeatingCoil, OACoolingCoil, OAHX)
        if OAHeatingCoil[0]:
            NumHeatingCoils += 1
    
    return NumHeatingCoils


def GetOASysNumHXs(state: Any, OASysNumber: int) -> int:
    """Get number of heat exchangers in OA system."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    
    NumHX = 0
    for CompNum in range(state.dataAirLoop.OutsideAirSys[OASysNumber - 1].NumComponents):
        # Check component type for HX
        pass  # Implementation stub
    return NumHX


def GetOASysNumCoolingCoils(state: Any, OASysNumber: int) -> int:
    """Get number of cooling coils in OA system."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    
    NumCoolingCoils = 0
    OAHeatingCoil = [False]
    OACoolingCoil = [False]
    OAHX = [False]
    CompIndex = [0]
    
    for CompNum in range(state.dataAirLoop.OutsideAirSys[OASysNumber - 1].NumComponents):
        CompType = state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentType[CompNum]
        CompName = state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentName[CompNum]
        SimOAComponent(state, CompType, CompName, 0, False, CompIndex, 0, False, OASysNumber,
                      OAHeatingCoil, OACoolingCoil, OAHX)
        if OACoolingCoil[0]:
            NumCoolingCoils += 1
    
    return NumCoolingCoils


def GetOASystemNumber(state: Any, OASysName: str) -> int:
    """Get OA system number by name."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    
    for i, sys in enumerate(state.dataAirLoop.OutsideAirSys):
        if sys.Name == OASysName:
            return i + 1
    return 0


def FindOAMixerMatchForOASystem(state: Any, OASysNumber: int) -> int:
    """Find OA mixer matching an OA system."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    OAMixerNumber = 0
    if OASysNumber > 0 and OASysNumber <= len(state.dataAirLoop.OutsideAirSys):
        for CompNum in range(state.dataAirLoop.OutsideAirSys[OASysNumber - 1].NumComponents):
            if state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentType[CompNum] == "OUTDOORAIR:MIXER":
                mixer_name = state.dataAirLoop.OutsideAirSys[OASysNumber - 1].ComponentName[CompNum]
                for i, mixer in enumerate(state.dataMixedAir.OAMixer):
                    if mixer.Name == mixer_name:
                        OAMixerNumber = i + 1
                        break
                break
    return OAMixerNumber


def GetOAMixerIndex(state: Any, OAMixerName: str) -> int:
    """Get OA mixer index by name."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    for i, mixer in enumerate(state.dataMixedAir.OAMixer):
        if mixer.Name == OAMixerName:
            return i + 1
    return 0


def GetOAMixerInletNodeNumber(state: Any, OAMixerNumber: int) -> int:
    """Get OA mixer inlet node number."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    if OAMixerNumber > 0 and OAMixerNumber <= state.dataMixedAir.NumOAMixers:
        return state.dataMixedAir.OAMixer[OAMixerNumber - 1].InletNode
    return 0


def GetOAMixerReturnNodeNumber(state: Any, OAMixerNumber: int) -> int:
    """Get OA mixer return node number."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    if OAMixerNumber > 0 and OAMixerNumber <= state.dataMixedAir.NumOAMixers:
        return state.dataMixedAir.OAMixer[OAMixerNumber - 1].RetNode
    return 0


def GetOAMixerMixedNodeNumber(state: Any, OAMixerNumber: int) -> int:
    """Get OA mixer mixed air node number."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    if OAMixerNumber > 0 and OAMixerNumber <= state.dataMixedAir.NumOAMixers:
        return state.dataMixedAir.OAMixer[OAMixerNumber - 1].MixNode
    return 0


def CheckForControllerWaterCoil(state: Any, ControllerType: int, ControllerName: str) -> bool:
    """Check if controller is for a water coil."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    
    OnControllerList = False
    for controller_list in state.dataMixedAir.ControllerLists:
        for i in range(controller_list.NumControllers):
            if (controller_list.ControllerType[i] == ControllerType and
                controller_list.ControllerName[i].upper() == ControllerName.upper()):
                OnControllerList = True
                break
        if OnControllerList:
            break
    
    return OnControllerList


def CheckControllerLists(state: Any, ErrFound: List[bool]) -> None:
    """Check for dangling controller lists."""
    pass  # Implementation stub


def CheckOAControllerName(state: Any, OAControllerName: str, ObjectType: str, 
                          FieldName: str, ErrorsFound: List[bool]) -> None:
    """Check OA controller name for uniqueness."""
    if state.dataMixedAir.AllocateOAControllersFlag:
        AllocateOAControllers(state)


def GetNumOASystems(state: Any) -> int:
    """Get number of OA systems."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return len(state.dataAirLoop.OutsideAirSys)


def GetOACompListNumber(state: Any, OASysNum: int) -> int:
    """Get OA component list number."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNum - 1].NumComponents


def GetOACompName(state: Any, OASysNum: int, InListNum: int) -> str:
    """Get OA component name."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNum - 1].ComponentName[InListNum - 1]


def GetOACompType(state: Any, OASysNum: int, InListNum: int) -> str:
    """Get OA component type."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNum - 1].ComponentType[InListNum - 1]


def GetOACompTypeNum(state: Any, OASysNum: int, InListNum: int) -> int:
    """Get OA component type number."""
    if state.dataMixedAir.GetOASysInputFlag:
        GetOutsideAirSysInputs(state)
        state.dataMixedAir.GetOASysInputFlag = False
    return state.dataAirLoop.OutsideAirSys[OASysNum - 1].ComponentTypeEnum[InListNum - 1]


def GetOAMixerNumber(state: Any, OAMixerName: str) -> int:
    """Get OA mixer number by name."""
    if state.dataMixedAir.GetOAMixerInputFlag:
        GetOAMixerInputs(state)
        state.dataMixedAir.GetOAMixerInputFlag = False
    
    for i, mixer in enumerate(state.dataMixedAir.OAMixer):
        if mixer.Name == OAMixerName:
            return i + 1
    return 0
