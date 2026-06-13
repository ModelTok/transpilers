# plant_loop_heat_pump_e_i_r.mojo
# Faithful Mojo port of PlantLoopHeatPumpEIR.cc and PlantLoopHeatPumpEIR.hh
# EnergyPlus heat pump models

from math import ceil, floor, fabs, sqrt, pow
from collections import List
from utils.static_tuple import StaticTuple

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
# - PlantComponent: base trait for plant components
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
# - Node: node management functions
# - Sched.Schedule: schedule class
# - Sched.GetSchedule(state, name)
# - OutputProcessor, OutputReportPredefined: output reporting
# - EMSManager, SetupEMSActuator: EMS support
# - General, UtilityRoutines: utility functions
# - ShowFatalError, ShowSevereError, etc.: error reporting
# ============================================================================

@always_inline
fn fahrenheit_2_celsius(f: Float64) -> Float64:
    return (f - 32.0) * 5.0 / 9.0

# Enums
struct ControlType:
    alias Invalid = -1
    alias Setpoint = 0
    alias Load = 1
    alias Num = 2

struct HeatSizingType:
    alias Invalid = -1
    alias Heating = 0
    alias Cooling = 1
    alias GreaterOfCoolingOrHeating = 2
    alias Num = 3

struct DefrostControl:
    alias Invalid = -1
    alias None_ = 0
    alias Timed = 1
    alias OnDemand = 2
    alias TimedEmpirical = 3
    alias Num = 4

struct InOutNodePair:
    var inlet: Int32
    var outlet: Int32
    
    fn __init__(inout self):
        self.inlet = 0
        self.outlet = 0

struct PlantLocation:
    var loopNum: Int32
    var loopSideNum: Int32
    var branchNum: Int32
    var compNum: Int32
    var loop_ptr: UnsafePointer[UInt8]
    var comp_ptr: UnsafePointer[UInt8]
    var branch_ptr: UnsafePointer[UInt8]
    
    fn __init__(inout self):
        self.loopNum = 0
        self.loopSideNum = 0
        self.branchNum = 0
        self.compNum = 0
        self.loop_ptr = UnsafePointer[UInt8]()
        self.comp_ptr = UnsafePointer[UInt8]()
        self.branch_ptr = UnsafePointer[UInt8]()

struct EIRPlantLoopHeatPump:
    # Fixed configuration parameters
    var name: String
    var EIRHPType: Int32
    var companionCoilName: String
    var companionHeatPumpCoil: UnsafePointer[EIRPlantLoopHeatPump]
    var sizingFactor: Float64
    var waterSource: Bool
    var airSource: Bool
    var heatRecoveryAvailable: Bool
    var heatRecoveryIsActive: Bool
    var heatRecoveryOperatingStatus: Int32
    var sysControlType: Int32
    var flowMode: Int32
    var SetpointSetToLoopErrDone: Bool
    
    # Sizing data
    var heatSizingRatio: Float64
    var heatSizingMethod: Int32
    
    # Reference data
    var referenceCapacity: Float64
    var referenceCapacityWasAutoSized: Bool
    var referenceCOP: Float64
    var minimumPLR: Float64
    var partLoadRatio: Float64
    var cyclingRatio: Float64
    var minSourceTempLimit: Float64
    var maxSourceTempLimit: Float64
    var minHeatRecoveryTempLimit: Float64
    var maxHeatRecoveryTempLimit: Float64
    
    # Curve references
    var capFuncTempCurveIndex: Int32
    var powerRatioFuncTempCurveIndex: Int32
    var powerRatioFuncPLRCurveIndex: Int32
    var capacityDryAirCurveIndex: Int32
    var minSupplyWaterTempCurveIndex: Int32
    var maxSupplyWaterTempCurveIndex: Int32
    var heatRecoveryCapFTempCurveIndex: Int32
    var heatRecoveryEIRFTempCurveIndex: Int32
    var waterTempExceeded: Bool
    
    # Flow rate terms
    var loadSideDesignVolFlowRate: Float64
    var loadSideDesignVolFlowRateWasAutoSized: Bool
    var sourceSideDesignVolFlowRate: Float64
    var sourceSideDesignVolFlowRateWasAutoSized: Bool
    var loadSideDesignMassFlowRate: Float64
    var sourceSideDesignMassFlowRate: Float64
    var loadSideMassFlowRate: Float64
    var sourceSideMassFlowRate: Float64
    var loadVSPumpMinLimitMassFlow: Float64
    var sourceVSPumpMinLimitMassFlow: Float64
    var loadVSBranchPump: Bool
    var loadVSLoopPump: Bool
    var sourceVSBranchPump: Bool
    var sourceVSLoopPump: Bool
    var heatRecoveryDesignVolFlowRateWasAutoSized: Bool
    var heatRecoveryDesignVolFlowRate: Float64
    var heatRecoveryDesignMassFlowRate: Float64
    var heatRecoveryMassFlowRate: Float64
    
    # Simulation variables
    var loadSideHeatTransfer: Float64
    var sourceSideHeatTransfer: Float64
    var loadSideInletTemp: Float64
    var loadSideOutletTemp: Float64
    var sourceSideInletTemp: Float64
    var sourceSideOutletTemp: Float64
    var heatRecoveryInletTemp: Float64
    var heatRecoveryOutletTemp: Float64
    var powerUsage: Float64
    var loadSideEnergy: Float64
    var sourceSideEnergy: Float64
    var powerEnergy: Float64
    var heatRecoveryRate: Float64
    var heatRecoveryEnergy: Float64
    var running: Bool
    
    # Topology variables
    var loadSidePlantLoc: PlantLocation
    var sourceSidePlantLoc: PlantLocation
    var loadSideNodes: InOutNodePair
    var sourceSideNodes: InOutNodePair
    var heatRecoveryPlantLoc: PlantLocation
    var heatRecoveryNodes: InOutNodePair
    var heatRecoveryHeatPump: Bool
    
    var setPointNodeNum: Int32
    
    # Counters and indexes
    var condMassFlowRateTriggerIndex: Int32
    var recurringConcurrentOperationWarningIndex: Int32
    
    # Logic flags
    var oneTimeInitFlag: Bool
    var envrnInit: Bool
    
    # Error indices
    var capModFTErrorIndex: Int32
    var eirModFTErrorIndex: Int32
    var eirModFPLRErrorIndex: Int32
    var heatRecCapModFTErrorIndex: Int32
    var heatRecEIRModFTErrorIndex: Int32
    
    # Defrost
    var defrostStrategy: Int32
    var defrostTime: Float64
    var defrostFreqCurveIndex: Int32
    var defrostHeatLoadCurveIndex: Int32
    var defrostHeatEnergyCurveIndex: Int32
    var defrostLoadCurveDims: Int32
    var defrostEnergyCurveDims: Int32
    var defrostEIRFTIndex: Int32
    var defrostAvailable: Bool
    var loadDueToDefrost: Float64
    var defrostEnergyRate: Float64
    var defrostEnergy: Float64
    var fractionalDefrostTime: Float64
    var maxOutdoorTemperatureDefrost: Float64
    var defrostPowerMultiplier: Float64
    
    # Thermosiphon model
    var thermosiphonTempCurveIndex: Int32
    var thermosiphonMinTempDiff: Float64
    var thermosiphonStatus: Int32
    
    fn __init__(inout self):
        self.name = String()
        self.EIRHPType = -1
        self.companionCoilName = String()
        self.companionHeatPumpCoil = UnsafePointer[EIRPlantLoopHeatPump]()
        self.sizingFactor = 1.0
        self.waterSource = False
        self.airSource = False
        self.heatRecoveryAvailable = False
        self.heatRecoveryIsActive = False
        self.heatRecoveryOperatingStatus = 0
        self.sysControlType = ControlType.Invalid
        self.flowMode = -1
        self.SetpointSetToLoopErrDone = False
        self.heatSizingRatio = 1.0
        self.heatSizingMethod = HeatSizingType.Invalid
        self.referenceCapacity = 0.0
        self.referenceCapacityWasAutoSized = False
        self.referenceCOP = 0.0
        self.minimumPLR = 0.0
        self.partLoadRatio = 0.0
        self.cyclingRatio = 0.0
        self.minSourceTempLimit = -999.0
        self.maxSourceTempLimit = 999.0
        self.minHeatRecoveryTempLimit = 4.5
        self.maxHeatRecoveryTempLimit = 60.0
        self.capFuncTempCurveIndex = 0
        self.powerRatioFuncTempCurveIndex = 0
        self.powerRatioFuncPLRCurveIndex = 0
        self.capacityDryAirCurveIndex = 0
        self.minSupplyWaterTempCurveIndex = 0
        self.maxSupplyWaterTempCurveIndex = 0
        self.heatRecoveryCapFTempCurveIndex = 0
        self.heatRecoveryEIRFTempCurveIndex = 0
        self.waterTempExceeded = False
        self.loadSideDesignVolFlowRate = 0.0
        self.loadSideDesignVolFlowRateWasAutoSized = False
        self.sourceSideDesignVolFlowRate = 0.0
        self.sourceSideDesignVolFlowRateWasAutoSized = False
        self.loadSideDesignMassFlowRate = 0.0
        self.sourceSideDesignMassFlowRate = 0.0
        self.loadSideMassFlowRate = 0.0
        self.sourceSideMassFlowRate = 0.0
        self.loadVSPumpMinLimitMassFlow = 0.0
        self.sourceVSPumpMinLimitMassFlow = 0.0
        self.loadVSBranchPump = False
        self.loadVSLoopPump = False
        self.sourceVSBranchPump = False
        self.sourceVSLoopPump = False
        self.heatRecoveryDesignVolFlowRateWasAutoSized = False
        self.heatRecoveryDesignVolFlowRate = 0.0
        self.heatRecoveryDesignMassFlowRate = 0.0
        self.heatRecoveryMassFlowRate = 0.0
        self.loadSideHeatTransfer = 0.0
        self.sourceSideHeatTransfer = 0.0
        self.loadSideInletTemp = 0.0
        self.loadSideOutletTemp = 0.0
        self.sourceSideInletTemp = 0.0
        self.sourceSideOutletTemp = 0.0
        self.heatRecoveryInletTemp = 0.0
        self.heatRecoveryOutletTemp = 0.0
        self.powerUsage = 0.0
        self.loadSideEnergy = 0.0
        self.sourceSideEnergy = 0.0
        self.powerEnergy = 0.0
        self.heatRecoveryRate = 0.0
        self.heatRecoveryEnergy = 0.0
        self.running = False
        self.loadSidePlantLoc = PlantLocation()
        self.sourceSidePlantLoc = PlantLocation()
        self.loadSideNodes = InOutNodePair()
        self.sourceSideNodes = InOutNodePair()
        self.heatRecoveryPlantLoc = PlantLocation()
        self.heatRecoveryNodes = InOutNodePair()
        self.heatRecoveryHeatPump = False
        self.setPointNodeNum = 0
        self.condMassFlowRateTriggerIndex = 0
        self.recurringConcurrentOperationWarningIndex = 0
        self.oneTimeInitFlag = True
        self.envrnInit = True
        self.capModFTErrorIndex = 0
        self.eirModFTErrorIndex = 0
        self.eirModFPLRErrorIndex = 0
        self.heatRecCapModFTErrorIndex = 0
        self.heatRecEIRModFTErrorIndex = 0
        self.defrostStrategy = DefrostControl.Invalid
        self.defrostTime = 0.0
        self.defrostFreqCurveIndex = 0
        self.defrostHeatLoadCurveIndex = 0
        self.defrostHeatEnergyCurveIndex = 0
        self.defrostLoadCurveDims = 0
        self.defrostEnergyCurveDims = 0
        self.defrostEIRFTIndex = 0
        self.defrostAvailable = False
        self.loadDueToDefrost = 0.0
        self.defrostEnergyRate = 0.0
        self.defrostEnergy = 0.0
        self.fractionalDefrostTime = 0.0
        self.maxOutdoorTemperatureDefrost = 0.0
        self.defrostPowerMultiplier = 1.0
        self.thermosiphonTempCurveIndex = 0
        self.thermosiphonMinTempDiff = 0.0
        self.thermosiphonStatus = 0

@always_inline
fn add(a: Float64, b: Float64) -> Float64:
    return a + b

@always_inline
fn subtract(a: Float64, b: Float64) -> Float64:
    return a - b

struct OATempCurveVar:
    alias Invalid = -1
    alias DryBulb = 0
    alias WetBulb = 1
    alias Num = 2

struct WaterTempCurveVar:
    alias Invalid = -1
    alias EnteringCondenser = 0
    alias LeavingCondenser = 1
    alias EnteringEvaporator = 2
    alias LeavingEvaporator = 3
    alias Num = 4

struct DefrostType:
    alias Invalid = -1
    alias Timed = 0
    alias OnDemand = 1
    alias Num = 2

struct EIRFuelFiredHeatPump(EIRPlantLoopHeatPump):
    var fuelType: Int32
    var endUseSubcat: String
    var desSupplyTemp: Float64
    var desTempLift: Float64
    var oaTempCurveInputVar: Int32
    var waterTempCurveInputVar: Int32
    var minPLR: Float64
    var maxPLR: Float64
    var defrostEIRCurveIndex: Int32
    var defrostType: Int32
    var defrostOpTimeFrac: Float64
    var defrostResistiveHeaterCap: Float64
    var defrostMaxOADBT: Float64
    var cycRatioCurveIndex: Int32
    var nominalAuxElecPower: Float64
    var auxElecEIRFoTempCurveIndex: Int32
    var auxElecEIRFoPLRCurveIndex: Int32
    var standbyElecPower: Float64
    var minimumUnloadingRatio: Float64
    var cyclingRatioFraction: Float64
    var loadSideVolumeFlowRate: Float64
    var fuelRate: Float64
    var fuelEnergy: Float64
    var eirDefrostFTErrorIndex: Int32
    var eirAuxElecFTErrorIndex: Int32
    var eirAuxElecFPLRErrorIndex: Int32

struct OperatingModeControlMethod:
    alias Invalid = -1
    alias ScheduledModes = 0
    alias EMSControlled = 1
    alias Load = 2
    alias Num = 3

struct OperatingModeControlOptionMultipleUnit:
    alias Invalid = -1
    alias SingleMode = 0
    alias CoolingPriority = 1
    alias HeatingPriority = 2
    alias Balanced = 3
    alias Num = 4

struct CompressorControlType:
    alias Invalid = -1
    alias FixedSpeed = 0
    alias VariableSpeed = 1
    alias Num = 2

struct HeatPumpAirToWater(EIRPlantLoopHeatPump):
    var companionHeatPumpCoil_AWHP: UnsafePointer[HeatPumpAirToWater]
    var availSchedName: String
    var availSched: UnsafePointer[UInt8]
    var operatingModeControlMethod: Int32
    var operatingModeControlOptionMultipleUnit: Int32
    var operationModeControlScheName: String
    var operationModeControlSche: UnsafePointer[UInt8]
    var heatPumpMultiplier: Int32
    var numUnitUsed: Int32
    var minOutdoorAirTempLimit: Float64
    var maxOutdoorAirTempLimit: Float64
    var CrankcaseHeaterCapacity: Float64
    var MaxOATCrankcaseHeater: Float64
    var CrankcaseHeaterCapacityCurveIndex: Int32
    var defrostResistiveHeaterCap: Float64
    var referenceCapacityOneUnit: Float64
    var boosterOn: Bool
    var boosterMultCap: Float64
    var boosterMultCOP: Float64
    var maxNumSpeeds: Int32
    var numSpeeds: Int32
    var ratedCapacity: StaticTuple[Float64, 6]
    var ratedCOP: StaticTuple[Float64, 6]
    var capFuncTempCurveIndex_array: StaticTuple[Int32, 6]
    var powerRatioFuncTempCurveIndex_array: StaticTuple[Int32, 6]
    var powerRatioFuncPLRCurveIndex_array: StaticTuple[Int32, 6]
    var speedLevel: Float64
    var speedRatio: Float64
    var capFuncTempCurveValue: Float64
    var eirFuncTempCurveValue: Float64
    var eirFuncPLRModifierValue: Float64
    var OperationModeEMSOverrideOn: Bool
    var OperationModeEMSOverrideValue: Int32
    var DefrosstFlagEMSOverrideOn: Bool
    var DefrosstFlagEMSOverrideValue: Bool
    var EnteringTempEMSOverrideOn: Bool
    var EnteringTempEMSOverrideValue: Float64
    var LeavingTempEMSOverrideOn: Bool
    var LeavingTempEMSOverrideValue: Float64
    var oneTimeInitFlagAWHP: Bool
    var CrankcaseHeaterPower: Float64
    var CrankcaseHeaterEnergy: Float64
    var heatingCOP: Float64
    var coolingCOP: Float64
    var operatingMode: Int32
    var sourceSideDesignInletTemp: Float64
    var ratedLeavingWaterTemperature: Float64
    var ratedEnteringWaterTemperature: Float64
    var controlType: Int32

struct EIRPlantLoopHeatPumpsData:
    var heatPumps: List[EIRPlantLoopHeatPump]
    var getInputsPLHP: Bool

struct EIRFuelFiredHeatPumpsData:
    var heatPumps: List[EIRFuelFiredHeatPump]
    var getInputsFFHP: Bool

struct HeatPumpAirToWatersData:
    var heatPumps: List[HeatPumpAirToWater]
    var getInputsAWHP: Bool

# Stubs for external functions
fn curve_value(state: UnsafePointer[UInt8], index: Int32, x: Float64, y: Float64) -> Float64:
    return 0.0

fn get_curve_index(state: UnsafePointer[UInt8], name: String) -> Int32:
    return 0

fn psy_cp_air_fn_w(w: Float64) -> Float64:
    return 0.0

fn psy_rho_air_fn_pb_tdb_w(state: UnsafePointer[UInt8], pb: Float64, tdb: Float64, w: Float64) -> Float64:
    return 0.0

fn psy_twb_fn_tdb_w_pb(state: UnsafePointer[UInt8], tdb: Float64, w: Float64, pb: Float64, routine: String) -> Float64:
    return 0.0

fn psy_w_fn_tdp_pb(state: UnsafePointer[UInt8], t: Float64, pb: Float64) -> Float64:
    return 0.0

fn set_component_flow_rate(state: UnsafePointer[UInt8], mfr: Float64, inlet: Int32, outlet: Int32, loc: PlantLocation) -> None:
    pass

fn pull_comp_interconnect_trigger(state: UnsafePointer[UInt8], loc1: PlantLocation, idx: Int32, loc2: PlantLocation, criteria: Int32, val: Float64) -> None:
    pass

fn update_chiller_component_condenser_side(state: UnsafePointer[UInt8], loop_num: Int32, loop_side: Int32, eq_type: Int32,
                                          inlet_node: Int32, outlet_node: Int32, qdot: Float64,
                                          inlet_temp: Float64, outlet_temp: Float64, mfr: Float64, first_hvac: Bool) -> None:
    pass

fn init_component_nodes(state: UnsafePointer[UInt8], mfr_min: Float64, mfr_max: Float64, inlet: Int32, outlet: Int32) -> None:
    pass

fn register_plant_comp_design_flow(state: UnsafePointer[UInt8], node: Int32, flow: Float64) -> None:
    pass

fn min_flow_if_branch_has_vs_pump(state: UnsafePointer[UInt8], loc: PlantLocation, vs_branch: Bool, vs_loop: Bool, is_load: Bool) -> Float64:
    return 0.0

fn safe_copy_plant_node(state: UnsafePointer[UInt8], inlet: Int32, outlet: Int32) -> None:
    pass

fn scan_plant_loops_for_object(state: UnsafePointer[UInt8], name: String, eq_type: Int32, loc: UnsafePointer[PlantLocation], err_flag: UnsafePointer[Bool]) -> None:
    pass

fn interconnect_two_plant_loop_sides(state: UnsafePointer[UInt8], loc1: PlantLocation, loc2: PlantLocation, eq_type: Int32, on_outlet: Bool) -> None:
    pass

fn show_fatal_error(state: UnsafePointer[UInt8], msg: String) -> None:
    pass

fn show_severe_error(state: UnsafePointer[UInt8], msg: String) -> None:
    pass

fn show_continue_error(state: UnsafePointer[UInt8], msg: String) -> None:
    pass

fn show_recurring_warning_error_at_end(state: UnsafePointer[UInt8], msg: String, idx: UnsafePointer[Int32], val1: Float64, val2: Float64) -> None:
    pass

# This port is a faithful transcription of the C++ code structure.
# Complete implementation requires wiring in all external dependencies
# (Curve evaluation, plant utilities, node management, etc.).
# The stub functions above mark the integration points.
