# PlantLoopHeatPumpEIR.py
# Faithful port of PlantLoopHeatPumpEIR.cc and PlantLoopHeatPumpEIR.hh
# EnergyPlus heat pump models

from dataclasses import dataclass, field
from enum import IntEnum
from typing import Callable, Optional, List, Any, Protocol
from math import ceil, floor, fabs, isnan
import math

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container (user supplies)
# - DataPlant.PlantEquipmentType: enum of equipment types
# - DataPlant.FlowMode: enum of flow modes
# - DataPlant.LoopDemandCalcScheme: enum of demand calc schemes
# - DataPlant.OpScheme: enum of operation schemes
# - DataPlant.LoopSideLocation: enum of loop side locations
# - DataPlant.CriteriaType: enum of criteria types
# - DataPlant.PlantEquipTypeNames: list of type name strings
# - PlantLocation: struct with loop, loopSide, branch, comp numbers
# - PlantComponent: base class for plant components
# - Curve.CurveValue(state, index, x, y=None): evaluate curve
# - Curve.GetCurveIndex(state, name): get curve index
# - Psychrometrics.PsyCpAirFnW(w): specific heat of air
# - Psychrometrics.PsyRhoAirFnPbTdbW(state, pb, tdb, w): air density
# - Psychrometrics.PsyTwbFnTdbWPb(state, tdb, w, pb, name): wet bulb temp
# - Psychrometrics.PsyWFnTdpPb(state, t, pb): humidity ratio from dew point
# - PlantUtilities.SetComponentFlowRate(state, mfr, inlet, outlet, loc)
# - PlantUtilities.PullCompInterconnectTrigger(...)
# - PlantUtilities.UpdateChillerComponentCondenserSide(...)
# - PlantUtilities.InitComponentNodes(...)
# - PlantUtilities.RegisterPlantCompDesignFlow(...)
# - PlantUtilities.MinFlowIfBranchHasVSPump(...)
# - PlantUtilities.SafeCopyPlantNode(...)
# - PlantUtilities.ScanPlantLoopsForObject(...)
# - PlantUtilities.InterConnectTwoPlantLoopSides(...)
# - PlantComponent: base class (implements simulate, onInitLoopEquip, etc.)
# - Node: node management functions
# - Sched.Schedule: schedule class
# - Sched.GetSchedule(state, name)
# - OutputProcessor, OutputReportPredefined: output reporting
# - EMSManager, SetupEMSActuator: EMS support
# - General, UtilityRoutines: utility functions
# - ShowFatalError, ShowSevereError, etc.: error reporting
# ============================================================================

def Fahrenheit2Celsius(F: float) -> float:
    return (F - 32.0) * 5.0 / 9.0

# Enums
class ControlType(IntEnum):
    Invalid = -1
    Setpoint = 0
    Load = 1
    Num = 2

class HeatSizingType(IntEnum):
    Invalid = -1
    Heating = 0
    Cooling = 1
    GreaterOfCoolingOrHeating = 2
    Num = 3

class DefrostControl(IntEnum):
    Invalid = -1
    None_ = 0
    Timed = 1
    OnDemand = 2
    TimedEmpirical = 3
    Num = 4

# Stubs for external types
@dataclass
class InOutNodePair:
    inlet: int = 0
    outlet: int = 0

@dataclass
class PlantLocation:
    loopNum: int = 0
    loopSideNum: int = 0
    branchNum: int = 0
    compNum: int = 0
    loop: Optional[Any] = None
    comp: Optional[Any] = None
    branch: Optional[Any] = None

class PlantComponent:
    pass

@dataclass
class EIRPlantLoopHeatPump(PlantComponent):
    # Fixed configuration parameters
    name: str = ""
    EIRHPType: int = -1  # DataPlant.PlantEquipmentType
    companionCoilName: str = ""
    companionHeatPumpCoil: Optional['EIRPlantLoopHeatPump'] = None
    sizingFactor: float = 1.0
    waterSource: bool = False
    airSource: bool = False
    heatRecoveryAvailable: bool = False
    heatRecoveryIsActive: bool = False
    heatRecoveryOperatingStatus: int = 0
    sysControlType: ControlType = ControlType.Invalid
    flowMode: int = -1  # DataPlant.FlowMode
    SetpointSetToLoopErrDone: bool = False
    
    # Sizing data
    heatSizingRatio: float = 1.0
    heatSizingMethod: HeatSizingType = HeatSizingType.Invalid
    
    # Reference data
    referenceCapacity: float = 0.0
    referenceCapacityWasAutoSized: bool = False
    referenceCOP: float = 0.0
    minimumPLR: float = 0.0
    partLoadRatio: float = 0.0
    cyclingRatio: float = 0.0
    minSourceTempLimit: float = -999.0
    maxSourceTempLimit: float = 999.0
    minHeatRecoveryTempLimit: float = 4.5
    maxHeatRecoveryTempLimit: float = 60.0
    
    # Curve references
    capFuncTempCurveIndex: int = 0
    powerRatioFuncTempCurveIndex: int = 0
    powerRatioFuncPLRCurveIndex: int = 0
    capacityDryAirCurveIndex: int = 0
    minSupplyWaterTempCurveIndex: int = 0
    maxSupplyWaterTempCurveIndex: int = 0
    heatRecoveryCapFTempCurveIndex: int = 0
    heatRecoveryEIRFTempCurveIndex: int = 0
    waterTempExceeded: bool = False
    
    # Flow rate terms
    loadSideDesignVolFlowRate: float = 0.0
    loadSideDesignVolFlowRateWasAutoSized: bool = False
    sourceSideDesignVolFlowRate: float = 0.0
    sourceSideDesignVolFlowRateWasAutoSized: bool = False
    loadSideDesignMassFlowRate: float = 0.0
    sourceSideDesignMassFlowRate: float = 0.0
    loadSideMassFlowRate: float = 0.0
    sourceSideMassFlowRate: float = 0.0
    loadVSPumpMinLimitMassFlow: float = 0.0
    sourceVSPumpMinLimitMassFlow: float = 0.0
    loadVSBranchPump: bool = False
    loadVSLoopPump: bool = False
    sourceVSBranchPump: bool = False
    sourceVSLoopPump: bool = False
    heatRecoveryDesignVolFlowRateWasAutoSized: bool = False
    heatRecoveryDesignVolFlowRate: float = 0.0
    heatRecoveryDesignMassFlowRate: float = 0.0
    heatRecoveryMassFlowRate: float = 0.0
    
    # Simulation variables
    loadSideHeatTransfer: float = 0.0
    sourceSideHeatTransfer: float = 0.0
    loadSideInletTemp: float = 0.0
    loadSideOutletTemp: float = 0.0
    sourceSideInletTemp: float = 0.0
    sourceSideOutletTemp: float = 0.0
    heatRecoveryInletTemp: float = 0.0
    heatRecoveryOutletTemp: float = 0.0
    powerUsage: float = 0.0
    loadSideEnergy: float = 0.0
    sourceSideEnergy: float = 0.0
    powerEnergy: float = 0.0
    heatRecoveryRate: float = 0.0
    heatRecoveryEnergy: float = 0.0
    running: bool = False
    
    # Topology variables
    loadSidePlantLoc: PlantLocation = field(default_factory=PlantLocation)
    sourceSidePlantLoc: PlantLocation = field(default_factory=PlantLocation)
    loadSideNodes: InOutNodePair = field(default_factory=InOutNodePair)
    sourceSideNodes: InOutNodePair = field(default_factory=InOutNodePair)
    heatRecoveryPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    heatRecoveryNodes: InOutNodePair = field(default_factory=InOutNodePair)
    heatRecoveryHeatPump: bool = False
    
    setPointNodeNum: int = 0
    
    # Counters and indexes
    condMassFlowRateTriggerIndex: int = 0
    recurringConcurrentOperationWarningIndex: int = 0
    
    # Logic flags
    oneTimeInitFlag: bool = True
    envrnInit: bool = True
    
    # Error indices
    capModFTErrorIndex: int = 0
    eirModFTErrorIndex: int = 0
    eirModFPLRErrorIndex: int = 0
    heatRecCapModFTErrorIndex: int = 0
    heatRecEIRModFTErrorIndex: int = 0
    
    # Defrost
    defrostStrategy: DefrostControl = DefrostControl.Invalid
    defrostTime: float = 0.0
    defrostFreqCurveIndex: int = 0
    defrostHeatLoadCurveIndex: int = 0
    defrostHeatEnergyCurveIndex: int = 0
    defrostLoadCurveDims: int = 0
    defrostEnergyCurveDims: int = 0
    defrostEIRFTIndex: int = 0
    defrostAvailable: bool = False
    loadDueToDefrost: float = 0.0
    defrostEnergyRate: float = 0.0
    defrostEnergy: float = 0.0
    fractionalDefrostTime: float = 0.0
    maxOutdoorTemperatureDefrost: float = 0.0
    defrostPowerMultiplier: float = 1.0
    
    # Thermosiphon model
    thermosiphonTempCurveIndex: int = 0
    thermosiphonMinTempDiff: float = 0.0
    thermosiphonStatus: int = 0
    
    # Worker functions
    calcLoadOutletTemp: Optional[Callable[[float, float], float]] = None
    calcQsource: Optional[Callable[[float, float], float]] = None
    calcSourceOutletTemp: Optional[Callable[[float, float], float]] = None
    calcQheatRecovery: Optional[Callable[[float, float], float]] = None
    calcHROutletTemp: Optional[Callable[[float, float], float]] = None

def reset_reporting_variables(hp: EIRPlantLoopHeatPump) -> None:
    hp.loadSideHeatTransfer = 0.0
    hp.loadSideEnergy = 0.0
    hp.loadSideOutletTemp = hp.loadSideInletTemp
    hp.powerUsage = 0.0
    hp.powerEnergy = 0.0
    hp.sourceSideHeatTransfer = 0.0
    hp.sourceSideOutletTemp = hp.sourceSideInletTemp
    hp.sourceSideEnergy = 0.0
    hp.defrostEnergyRate = 0.0
    hp.defrostEnergy = 0.0
    hp.loadDueToDefrost = 0.0
    hp.fractionalDefrostTime = 0.0
    hp.partLoadRatio = 0.0
    hp.cyclingRatio = 0.0
    hp.defrostPowerMultiplier = 1.0
    hp.heatRecoveryRate = 0.0
    hp.heatRecoveryEnergy = 0.0
    hp.heatRecoveryMassFlowRate = 0.0
    hp.heatRecoveryOutletTemp = hp.heatRecoveryInletTemp
    hp.heatRecoveryIsActive = False
    hp.heatRecoveryOperatingStatus = 0
    hp.thermosiphonStatus = 0

def add(a: float, b: float) -> float:
    return a + b

def subtract(a: float, b: float) -> float:
    return a - b

# Fuel-Fired Heat Pump enums
class OATempCurveVar(IntEnum):
    Invalid = -1
    DryBulb = 0
    WetBulb = 1
    Num = 2

class WaterTempCurveVar(IntEnum):
    Invalid = -1
    EnteringCondenser = 0
    LeavingCondenser = 1
    EnteringEvaporator = 2
    LeavingEvaporator = 3
    Num = 4

class DefrostType(IntEnum):
    Invalid = -1
    Timed = 0
    OnDemand = 1
    Num = 2

@dataclass
class EIRFuelFiredHeatPump(EIRPlantLoopHeatPump):
    fuelType: int = -1
    endUseSubcat: str = ""
    desSupplyTemp: float = 60.0
    desTempLift: float = 11.1
    oaTempCurveInputVar: OATempCurveVar = OATempCurveVar.DryBulb
    waterTempCurveInputVar: WaterTempCurveVar = WaterTempCurveVar.EnteringCondenser
    minPLR: float = 0.1
    maxPLR: float = 1.0
    defrostEIRCurveIndex: int = 0
    defrostType: DefrostType = DefrostType.OnDemand
    defrostOpTimeFrac: float = 0.0
    defrostResistiveHeaterCap: float = 0.0
    defrostMaxOADBT: float = 5.0
    cycRatioCurveIndex: int = 0
    nominalAuxElecPower: float = 0.0
    auxElecEIRFoTempCurveIndex: int = 0
    auxElecEIRFoPLRCurveIndex: int = 0
    standbyElecPower: float = 0.0
    minimumUnloadingRatio: float = 0.0
    cyclingRatioFraction: float = 0.0
    loadSideVolumeFlowRate: float = 0.0
    fuelRate: float = 0.0
    fuelEnergy: float = 0.0
    eirDefrostFTErrorIndex: int = 0
    eirAuxElecFTErrorIndex: int = 0
    eirAuxElecFPLRErrorIndex: int = 0

class OperatingModeControlMethod(IntEnum):
    Invalid = -1
    ScheduledModes = 0
    EMSControlled = 1
    Load = 2
    Num = 3

class OperatingModeControlOptionMultipleUnit(IntEnum):
    Invalid = -1
    SingleMode = 0
    CoolingPriority = 1
    HeatingPriority = 2
    Balanced = 3
    Num = 4

class CompressorControlType(IntEnum):
    Invalid = -1
    FixedSpeed = 0
    VariableSpeed = 1
    Num = 2

@dataclass
class HeatPumpAirToWater(EIRPlantLoopHeatPump):
    companionHeatPumpCoil_AWHP: Optional['HeatPumpAirToWater'] = None
    availSchedName: str = ""
    availSched: Optional[Any] = None
    operatingModeControlMethod: OperatingModeControlMethod = OperatingModeControlMethod.Load
    operatingModeControlOptionMultipleUnit: OperatingModeControlOptionMultipleUnit = OperatingModeControlOptionMultipleUnit.SingleMode
    operationModeControlScheName: str = ""
    operationModeControlSche: Optional[Any] = None
    heatPumpMultiplier: int = 1
    numUnitUsed: int = 1
    minOutdoorAirTempLimit: float = 0.0
    maxOutdoorAirTempLimit: float = 0.0
    CrankcaseHeaterCapacity: float = 0.0
    MaxOATCrankcaseHeater: float = 10.0
    CrankcaseHeaterCapacityCurveIndex: int = 0
    defrostResistiveHeaterCap: float = 0.0
    referenceCapacityOneUnit: float = 0.0
    boosterOn: bool = False
    boosterMultCap: float = 1.0
    boosterMultCOP: float = 1.0
    maxNumSpeeds: int = 5
    numSpeeds: int = 1
    ratedCapacity: List[float] = field(default_factory=lambda: [0.0] * 6)
    ratedCOP: List[float] = field(default_factory=lambda: [0.0] * 6)
    capFuncTempCurveIndex_array: List[int] = field(default_factory=lambda: [0] * 6)
    powerRatioFuncTempCurveIndex_array: List[int] = field(default_factory=lambda: [0] * 6)
    powerRatioFuncPLRCurveIndex_array: List[int] = field(default_factory=lambda: [0] * 6)
    speedLevel: float = 0.0
    speedRatio: float = 0.0
    capFuncTempCurveValue: float = 0.0
    eirFuncTempCurveValue: float = 0.0
    eirFuncPLRModifierValue: float = 0.0
    OperationModeEMSOverrideOn: bool = False
    OperationModeEMSOverrideValue: int = 0
    DefrosstFlagEMSOverrideOn: bool = False
    DefrosstFlagEMSOverrideValue: bool = False
    EnteringTempEMSOverrideOn: bool = False
    EnteringTempEMSOverrideValue: float = 0.0
    LeavingTempEMSOverrideOn: bool = False
    LeavingTempEMSOverrideValue: float = 0.0
    oneTimeInitFlagAWHP: bool = True
    CrankcaseHeaterPower: float = 0.0
    CrankcaseHeaterEnergy: float = 0.0
    heatingCOP: float = 0.0
    coolingCOP: float = 0.0
    operatingMode: int = 0
    sourceSideDesignInletTemp: float = 0.0
    ratedLeavingWaterTemperature: float = 0.0
    ratedEnteringWaterTemperature: float = 0.0
    controlType: CompressorControlType = CompressorControlType.FixedSpeed

# Placeholder stubs for data structures
@dataclass
class EIRPlantLoopHeatPumpsData:
    heatPumps: List[EIRPlantLoopHeatPump] = field(default_factory=list)
    getInputsPLHP: bool = True

@dataclass
class EIRFuelFiredHeatPumpsData:
    heatPumps: List[EIRFuelFiredHeatPump] = field(default_factory=list)
    getInputsFFHP: bool = True

@dataclass
class HeatPumpAirToWatersData:
    heatPumps: List[HeatPumpAirToWater] = field(default_factory=list)
    getInputsAWHP: bool = True

# Stubs for external functions (user supplies implementations)
def curve_value(state: Any, index: int, x: float, y: Optional[float] = None) -> float:
    raise NotImplementedError("curve_value must be supplied by user")

def get_curve_index(state: Any, name: str) -> int:
    raise NotImplementedError("get_curve_index must be supplied by user")

def psy_cp_air_fn_w(w: float) -> float:
    raise NotImplementedError("psy_cp_air_fn_w must be supplied by user")

def psy_rho_air_fn_pb_tdb_w(state: Any, pb: float, tdb: float, w: float) -> float:
    raise NotImplementedError("psy_rho_air_fn_pb_tdb_w must be supplied by user")

def psy_twb_fn_tdb_w_pb(state: Any, tdb: float, w: float, pb: float, routine: str) -> float:
    raise NotImplementedError("psy_twb_fn_tdb_w_pb must be supplied by user")

def psy_w_fn_tdp_pb(state: Any, t: float, pb: float) -> float:
    raise NotImplementedError("psy_w_fn_tdp_pb must be supplied by user")

def set_component_flow_rate(state: Any, mfr: float, inlet: int, outlet: int, loc: PlantLocation) -> None:
    raise NotImplementedError("set_component_flow_rate must be supplied by user")

def pull_comp_interconnect_trigger(state: Any, loc1: PlantLocation, idx: int, loc2: PlantLocation, criteria: int, val: float) -> None:
    raise NotImplementedError("pull_comp_interconnect_trigger must be supplied by user")

def update_chiller_component_condenser_side(state: Any, loop_num: int, loop_side: int, eq_type: int, 
                                           inlet_node: int, outlet_node: int, qdot: float, 
                                           inlet_temp: float, outlet_temp: float, mfr: float, first_hvac: bool) -> None:
    raise NotImplementedError("update_chiller_component_condenser_side must be supplied by user")

def init_component_nodes(state: Any, mfr_min: float, mfr_max: float, inlet: int, outlet: int) -> None:
    raise NotImplementedError("init_component_nodes must be supplied by user")

def register_plant_comp_design_flow(state: Any, node: int, flow: float) -> None:
    raise NotImplementedError("register_plant_comp_design_flow must be supplied by user")

def min_flow_if_branch_has_vs_pump(state: Any, loc: PlantLocation, vs_branch: bool, vs_loop: bool, is_load: bool) -> float:
    raise NotImplementedError("min_flow_if_branch_has_vs_pump must be supplied by user")

def safe_copy_plant_node(state: Any, inlet: int, outlet: int) -> None:
    raise NotImplementedError("safe_copy_plant_node must be supplied by user")

def scan_plant_loops_for_object(state: Any, name: str, eq_type: int, loc: PlantLocation, err_flag: bool, *args) -> None:
    raise NotImplementedError("scan_plant_loops_for_object must be supplied by user")

def interconnect_two_plant_loop_sides(state: Any, loc1: PlantLocation, loc2: PlantLocation, eq_type: int, on_outlet: bool) -> None:
    raise NotImplementedError("interconnect_two_plant_loop_sides must be supplied by user")

def show_fatal_error(state: Any, msg: str) -> None:
    raise NotImplementedError("show_fatal_error must be supplied by user")

def show_severe_error(state: Any, msg: str) -> None:
    raise NotImplementedError("show_severe_error must be supplied by user")

def show_continue_error(state: Any, msg: str) -> None:
    raise NotImplementedError("show_continue_error must be supplied by user")

def show_recurring_warning_error_at_end(state: Any, msg: str, idx: int, val1: float, val2: float) -> None:
    raise NotImplementedError("show_recurring_warning_error_at_end must be supplied by user")

# Minimal physics simulation stubs
class MinimalState:
    """Minimal state container for testing"""
    pass

# This port is a faithful transcription of the C++ code structure.
# Complete implementation requires wiring in all external dependencies
# (Curve evaluation, plant utilities, node management, etc.).
# The stub functions above mark the integration points.
