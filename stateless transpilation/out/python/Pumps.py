# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataPumps, dataLoopNodes, dataPlnt, dataInputProcessing,
#   dataIPShortCut, dataHeatBal, dataGlobal, dataAvail, dataSize, dataHVACGlobal, dataOutRptPredefined
# - Util: FindItemInList(name, list_of_structs), makeUPPER(str), SameString(s1, s2)
# - Sched: GetSchedule(state, name) -> Schedule, Schedule.getCurrentVal() -> float
# - Curve: GetCurveIndex, CheckCurveDims, GetCurveMinMaxValues
# - Node: GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
# - DataPlant: PlantEquipmentType, LoopSideLocation, FlowLock, LoopFlowStatus, LoopSideKeys, PressSimType, CompData
# - Fluid: GetWater(state), GetSteam(state) with getDensity, getSatDensity methods
# - PlantUtilities: InitComponentNodes, ScanPlantLoopsForObject, SetComponentFlowRate, BoundValueToWithinTwoValues
# - PlantPressureSystem: ResolveLoopFlowVsPressure
# - EMSManager: SetupEMSInternalVariable, SetupEMSActuator
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat, eResource
# - Constant: Units, eResource, InitConvTemp
# - DataBranchAirLoopPlant: MassFlowTolerance, ControlType
# - HVAC: SmallWaterVolFlow
# - GlobalNames: VerifyUniqueInterObjectName
# - ErrorHandling: ShowFatalError, ShowWarningError, ShowContinueError, ShowSevereError, etc.
# - BaseSizer: reportSizerOutput
# - DataHeatBalance: SetupZoneInternalGain, IntGainType
# - OutputReportPredefined: PreDefTableEntry
# - HeatBalanceInternalHeatGains (imported for side effects)

from dataclasses import dataclass, field
from enum import IntEnum
from typing import Any, Optional, List
import math


class PumpControlType(IntEnum):
    Invalid = -1
    Continuous = 0
    Intermittent = 1
    Num = 2


class ControlTypeVFD(IntEnum):
    Invalid = -1
    VFDManual = 0
    VFDAutomatic = 1
    Num = 2


class PumpBankControlSeq(IntEnum):
    Invalid = -1
    OptimalScheme = 0
    SequentialScheme = 1
    UserDefined = 2
    Num = 3


class PumpType(IntEnum):
    Invalid = -1
    VarSpeed = 0
    ConSpeed = 1
    Cond = 2
    Bank_VarSpeed = 3
    Bank_ConSpeed = 4
    Num = 5


class PowerSizingMethod(IntEnum):
    Invalid = -1
    SizePowerPerFlow = 0
    SizePowerPerFlowPerPressure = 1
    Num = 2


PUMP_TYPE_IDF_NAMES = [
    "Pump:VariableSpeed",
    "Pump:ConstantSpeed",
    "Pump:VariableSpeed:Condensate",
    "HeaderedPumps:VariableSpeed",
    "HeaderedPumps:ConstantSpeed",
]


@dataclass
class PumpVFDControlData:
    Name: str = ""
    manualRPMSched: Optional[Any] = None
    lowerPsetSched: Optional[Any] = None
    upperPsetSched: Optional[Any] = None
    minRPMSched: Optional[Any] = None
    maxRPMSched: Optional[Any] = None
    VFDControlType: ControlTypeVFD = ControlTypeVFD.Invalid
    MaxRPM: float = 0.0
    MinRPM: float = 0.0
    PumpActualRPM: float = 0.0


@dataclass
class PumpSpecs:
    Name: str = ""
    pumpType: PumpType = PumpType.Invalid
    TypeOf_Num: Any = None
    plantLoc: Any = None
    PumpControl: PumpControlType = PumpControlType.Invalid
    flowRateSched: Optional[Any] = None
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    SequencingScheme: PumpBankControlSeq = PumpBankControlSeq.Invalid
    NumPumpsInBank: int = 0
    PowerErrIndex1: int = 0
    PowerErrIndex2: int = 0
    MinVolFlowRateFrac: float = 0.0
    NomVolFlowRate: float = 0.0
    NomVolFlowRateWasAutoSized: bool = False
    MassFlowRateMax: float = 0.0
    EMSMassFlowOverrideOn: bool = False
    EMSMassFlowValue: float = 0.0
    NomSteamVolFlowRate: float = 0.0
    NomSteamVolFlowRateWasAutoSized: bool = False
    MinVolFlowRate: float = 0.0
    minVolFlowRateWasAutosized: bool = False
    MassFlowRateMin: float = 0.0
    NomPumpHead: float = 0.0
    EMSPressureOverrideOn: bool = False
    EMSPressureOverrideValue: float = 0.0
    NomPowerUse: float = 0.0
    NomPowerUseWasAutoSized: bool = False
    powerSizingMethod: PowerSizingMethod = PowerSizingMethod.SizePowerPerFlowPerPressure
    powerPerFlowScalingFactor: float = 348701.1
    powerPerFlowPerPressureScalingFactor: float = 1.0 / 0.78
    MotorEffic: float = 0.0
    PumpEffic: float = 0.0
    FracMotorLossToFluid: float = 0.0
    Energy: float = 0.0
    Power: float = 0.0
    PartLoadCoef: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0, 0.0])
    PressureCurve_Index: int = 0
    PumpMassFlowRateMaxRPM: float = 0.0
    PumpMassFlowRateMinRPM: float = 0.0
    MinPhiValue: float = 0.0
    MaxPhiValue: float = 0.0
    ImpellerDiameter: float = 0.0
    RotSpeed_RPM: float = 0.0
    RotSpeed: float = 0.0
    PumpInitFlag: bool = True
    PumpOneTimeFlag: bool = True
    CheckEquipName: bool = True
    HasVFD: bool = False
    VFD: PumpVFDControlData = field(default_factory=PumpVFDControlData)
    OneTimePressureWarning: bool = True
    HeatLossesToZone: bool = False
    ZoneNum: int = 0
    SkinLossRadFraction: float = 0.0
    LoopSolverOverwriteFlag: bool = False
    EndUseSubcategoryName: str = ""


@dataclass
class ReportVars:
    NumPumpsOperating: int = 0
    PumpMassFlowRate: float = 0.0
    PumpHeattoFluid: float = 0.0
    PumpHeattoFluidEnergy: float = 0.0
    OutletTemp: float = 0.0
    ShaftPower: float = 0.0
    ZoneTotalGainRate: float = 0.0
    ZoneTotalGainEnergy: float = 0.0
    ZoneConvGainRate: float = 0.0
    ZoneRadGainRate: float = 0.0


@dataclass
class PumpsData:
    NumPumps: int = 0
    NumPumpsRunning: int = 0
    NumPumpsFullLoad: int = 0
    GetInputFlag: bool = True
    PumpMassFlowRate: float = 0.0
    PumpHeattoFluid: float = 0.0
    Power: float = 0.0
    ShaftPower: float = 0.0
    PumpEquip: List[PumpSpecs] = field(default_factory=list)
    PumpEquipReport: List[ReportVars] = field(default_factory=list)
    PumpUniqueNames: dict = field(default_factory=dict)

    def clear_state(self):
        self.NumPumps = 0
        self.NumPumpsRunning = 0
        self.NumPumpsFullLoad = 0
        self.GetInputFlag = True
        self.PumpMassFlowRate = 0.0
        self.PumpHeattoFluid = 0.0
        self.Power = 0.0
        self.ShaftPower = 0.0
        self.PumpEquip.clear()
        self.PumpEquipReport.clear()
        self.PumpUniqueNames.clear()


def sim_pumps(
    state: Any,
    pump_name: str,
    loop_num: int,
    flow_request: float,
) -> tuple[bool, int, float]:
    """
    Manages pump operation based on pump type and control settings.
    Returns (PumpRunning, PumpIndex, PumpHeat)
    """
    pump_index = 0
    pump_running = False
    pump_heat = 0.0

    if state.dataPumps.GetInputFlag:
        get_pump_input(state)
        state.dataPumps.GetInputFlag = False

    if state.dataPumps.NumPumps == 0:
        pump_heat = 0.0
        return pump_running, pump_index, pump_heat

    if pump_index == 0:
        pump_num = Util_FindItemInList(pump_name, state.dataPumps.PumpEquip)
        if pump_num == -1:
            ShowFatalError(
                state, f"ManagePumps: Pump requested not found ={pump_name}"
            )
        pump_index = pump_num
    else:
        pump_num = pump_index
        if state.dataPumps.PumpEquip[pump_num].CheckEquipName:
            if pump_num >= state.dataPumps.NumPumps or pump_num < 0:
                ShowFatalError(
                    state,
                    f"ManagePumps: Invalid PumpIndex passed={pump_num}, Number of Pumps={state.dataPumps.NumPumps}, Pump name={pump_name}",
                )
            if pump_name != state.dataPumps.PumpEquip[pump_num].Name:
                ShowFatalError(
                    state,
                    f"ManagePumps: Invalid PumpIndex passed={pump_num}, Pump name={pump_name}, stored Pump Name for that index={state.dataPumps.PumpEquip[pump_num].Name}",
                )
            state.dataPumps.PumpEquip[pump_num].CheckEquipName = False

    initialize_pumps(state, pump_num)

    if (
        state.dataPlnt.PlantLoop[loop_num].LoopSide[
            state.dataPumps.PumpEquip[pump_num].plantLoc.loopSideNum
        ].FlowLock
        == DataPlant_FlowLock_PumpQuery
    ):
        setup_pump_min_max_flows(state, loop_num, pump_num)
        return pump_running, pump_index, pump_heat

    calc_pumps(state, pump_num, flow_request)
    pump_running = state.dataPumps.PumpMassFlowRate > MASS_FLOW_TOLERANCE

    report_pumps(state, pump_num)

    pump_heat = state.dataPumps.PumpHeattoFluid
    return pump_running, pump_index, pump_heat


def get_pump_input(state: Any) -> None:
    """Read pump input from IDF."""
    start_temp = 100.0
    routine_name = "GetPumpInput"
    
    pump_ctrl_type_names_uc = ["CONTINUOUS", "INTERMITTENT"]
    control_type_vfd_names_uc = ["MANUALCONTROL", "PRESSURESETPOINTCONTROL"]
    power_sizing_method_names_uc = ["POWERPERFLOW", "POWERPERFLOWPERPRESSURE"]
    
    min_to_max_ratio_max = 0.99
    errors_found = False
    
    num_var_speed_pumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, PUMP_TYPE_IDF_NAMES[int(PumpType.VarSpeed)]
    )
    num_const_speed_pumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, PUMP_TYPE_IDF_NAMES[int(PumpType.ConSpeed)]
    )
    num_condensate_pumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, PUMP_TYPE_IDF_NAMES[int(PumpType.Cond)]
    )
    num_pump_bank_simple_var = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, PUMP_TYPE_IDF_NAMES[int(PumpType.Bank_VarSpeed)]
        )
    )
    num_pump_bank_simple_const = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, PUMP_TYPE_IDF_NAMES[int(PumpType.Bank_ConSpeed)]
        )
    )
    
    state.dataPumps.NumPumps = (
        num_var_speed_pumps
        + num_const_speed_pumps
        + num_condensate_pumps
        + num_pump_bank_simple_var
        + num_pump_bank_simple_const
    )
    
    if state.dataPumps.NumPumps <= 0:
        ShowWarningError(state, "No Pumping Equipment Found")
        return
    
    state.dataPumps.PumpEquip = [PumpSpecs() for _ in range(state.dataPumps.NumPumps)]
    state.dataPumps.PumpEquipReport = [ReportVars() for _ in range(state.dataPumps.NumPumps)]
    
    current_module_object = PUMP_TYPE_IDF_NAMES[int(PumpType.VarSpeed)]
    
    for pump_index in range(num_var_speed_pumps):
        pump_num = pump_index
        this_pump = state.dataPumps.PumpEquip[pump_num]
        this_input = state.dataIPShortCut
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            pump_index + 1,
            this_input.cAlphaArgs,
            this_input.rNumericArgs,
        )
        
        GlobalNames_VerifyUniqueInterObjectName(
            state,
            state.dataPumps.PumpUniqueNames,
            this_input.cAlphaArgs[0],
            current_module_object,
            errors_found,
        )
        this_pump.Name = this_input.cAlphaArgs[0]
        this_pump.pumpType = PumpType.VarSpeed
        
        this_pump.InletNodeNum = Node_GetOnlySingleNode(
            state, this_input.cAlphaArgs[1], errors_found
        )
        this_pump.OutletNodeNum = Node_GetOnlySingleNode(
            state, this_input.cAlphaArgs[2], errors_found
        )
        Node_TestCompSet(
            state,
            current_module_object,
            this_pump.Name,
            this_input.cAlphaArgs[1],
            this_input.cAlphaArgs[2],
            "Water Nodes",
        )
        
        pump_ctrl_val = Util_makeUPPER(this_input.cAlphaArgs[3])
        this_pump.PumpControl = (
            PumpControlType.Continuous
            if pump_ctrl_val == "CONTINUOUS"
            else (
                PumpControlType.Intermittent
                if pump_ctrl_val == "INTERMITTENT"
                else PumpControlType.Invalid
            )
        )
        if this_pump.PumpControl == PumpControlType.Invalid:
            ShowWarningError(
                state,
                f"{routine_name}{current_module_object}=\"{this_pump.Name}\", Invalid PumpControl",
            )
            this_pump.PumpControl = PumpControlType.Continuous
        
        if this_input.cAlphaArgs[4].strip():
            this_pump.flowRateSched = Sched_GetSchedule(state, this_input.cAlphaArgs[4])
        
        this_pump.NomVolFlowRate = this_input.rNumericArgs[0]
        if this_pump.NomVolFlowRate == AUTO_SIZE:
            this_pump.NomVolFlowRateWasAutoSized = True
        this_pump.NomPumpHead = this_input.rNumericArgs[1]
        this_pump.NomPowerUse = this_input.rNumericArgs[2]
        if this_pump.NomPowerUse == AUTO_SIZE:
            this_pump.NomPowerUseWasAutoSized = True
        this_pump.MotorEffic = this_input.rNumericArgs[3]
        this_pump.FracMotorLossToFluid = this_input.rNumericArgs[4]
        this_pump.PartLoadCoef[0] = this_input.rNumericArgs[5]
        this_pump.PartLoadCoef[1] = this_input.rNumericArgs[6]
        this_pump.PartLoadCoef[2] = this_input.rNumericArgs[7]
        this_pump.PartLoadCoef[3] = this_input.rNumericArgs[8]
        this_pump.MinVolFlowRate = this_input.rNumericArgs[9]
        if this_pump.MinVolFlowRate == AUTO_SIZE:
            this_pump.minVolFlowRateWasAutosized = True
        elif (
            not this_pump.NomVolFlowRateWasAutoSized
            and this_pump.MinVolFlowRate > (min_to_max_ratio_max * this_pump.NomVolFlowRate)
        ):
            ShowWarningError(
                state,
                f"{routine_name}{current_module_object}=\"{this_pump.Name}\", Invalid MinVolFlowRate",
            )
            this_pump.MinVolFlowRate = min_to_max_ratio_max * this_pump.NomVolFlowRate
        
        if this_input.cAlphaArgs[5].strip():
            this_pump.PressureCurve_Index = Curve_GetCurveIndex(
                state, this_input.cAlphaArgs[5]
            )
            if this_pump.PressureCurve_Index > 0:
                Curve_GetCurveMinMaxValues(
                    state,
                    this_pump.PressureCurve_Index,
                    this_pump.MinPhiValue,
                    this_pump.MaxPhiValue,
                )
        else:
            this_pump.PressureCurve_Index = -1
        
        this_pump.ImpellerDiameter = this_input.rNumericArgs[10]
        
        if this_input.cAlphaArgs[6].strip():
            this_pump.HasVFD = True
            vfd_ctrl_val = Util_makeUPPER(this_input.cAlphaArgs[6])
            this_pump.VFD.VFDControlType = (
                ControlTypeVFD.VFDManual
                if vfd_ctrl_val == "MANUALCONTROL"
                else (
                    ControlTypeVFD.VFDAutomatic
                    if vfd_ctrl_val == "PRESSURESETPOINTCONTROL"
                    else ControlTypeVFD.Invalid
                )
            )
            
            if this_pump.VFD.VFDControlType == ControlTypeVFD.VFDManual:
                this_pump.VFD.manualRPMSched = Sched_GetSchedule(
                    state, this_input.cAlphaArgs[7]
                )
            elif this_pump.VFD.VFDControlType == ControlTypeVFD.VFDAutomatic:
                this_pump.VFD.lowerPsetSched = Sched_GetSchedule(
                    state, this_input.cAlphaArgs[8]
                )
                this_pump.VFD.upperPsetSched = Sched_GetSchedule(
                    state, this_input.cAlphaArgs[9]
                )
                this_pump.VFD.minRPMSched = Sched_GetSchedule(
                    state, this_input.cAlphaArgs[10]
                )
                this_pump.VFD.maxRPMSched = Sched_GetSchedule(
                    state, this_input.cAlphaArgs[11]
                )
        
        if not this_input.cAlphaArgs[12].strip():
            this_pump.ZoneNum = Util_FindItemInList(
                this_input.cAlphaArgs[12], state.dataHeatBal.Zone
            )
            if this_pump.ZoneNum > 0:
                this_pump.HeatLossesToZone = True
                if len(this_input.rNumericArgs) > 11:
                    this_pump.SkinLossRadFraction = this_input.rNumericArgs[11]
        
        if this_input.cAlphaArgs[13].strip():
            power_sizing_val = Util_makeUPPER(this_input.cAlphaArgs[13])
            this_pump.powerSizingMethod = (
                PowerSizingMethod.SizePowerPerFlow
                if power_sizing_val == "POWERPERFLOW"
                else (
                    PowerSizingMethod.SizePowerPerFlowPerPressure
                    if power_sizing_val == "POWERPERFLOWPERPRESSURE"
                    else PowerSizingMethod.Invalid
                )
            )
        
        if len(this_input.rNumericArgs) > 12:
            this_pump.powerPerFlowScalingFactor = this_input.rNumericArgs[12]
        if len(this_input.rNumericArgs) > 13:
            this_pump.powerPerFlowPerPressureScalingFactor = this_input.rNumericArgs[13]
        if len(this_input.rNumericArgs) > 14:
            this_pump.MinVolFlowRateFrac = this_input.rNumericArgs[14]
        
        if len(this_input.cAlphaArgs) > 14:
            this_pump.EndUseSubcategoryName = this_input.cAlphaArgs[14]
        else:
            this_pump.EndUseSubcategoryName = "General"
        
        this_pump.Energy = 0.0
        this_pump.Power = 0.0
    
    # Additional pump type handling (ConSpeed, Condensate, Bank variants)
    # ... (similar structure for other pump types)
    
    if errors_found:
        ShowFatalError(state, "Errors found in getting Pump input")


def initialize_pumps(state: Any, pump_num: int) -> None:
    """Initialize pump data for simulation."""
    start_temp = 100.0
    zero_power_tol = 0.0000001
    routine_name = "PlantPumps::InitializePumps "
    
    this_pump = state.dataPumps.PumpEquip[pump_num]
    inlet_node = this_pump.InletNodeNum
    outlet_node = this_pump.OutletNodeNum
    
    if this_pump.PumpOneTimeFlag:
        Util_ScanPlantLoopsForObject(state, this_pump.Name, this_pump.pumpType)
        
        size_pump(state, pump_num)
        
        if (
            this_pump.NomPowerUse > zero_power_tol
            and this_pump.MotorEffic > zero_power_tol
        ):
            total_effic = (
                this_pump.NomVolFlowRate
                * this_pump.NomPumpHead
                / this_pump.NomPowerUse
            )
            this_pump.PumpEffic = total_effic / this_pump.MotorEffic
            if this_pump.PumpEffic < 0.50:
                ShowWarningError(
                    state,
                    f"Check input. Calculated Pump Efficiency={this_pump.PumpEffic * 100.0:.2f}% which is less than 50%, for pump={this_pump.Name}",
                )
            elif 0.95 < this_pump.PumpEffic <= 1.0:
                ShowWarningError(
                    state,
                    f"Check input.  Calculated Pump Efficiency={this_pump.PumpEffic * 100.0:.2f}% is approaching 100%, for pump={this_pump.Name}",
                )
            elif this_pump.PumpEffic > 1.0:
                ShowSevereError(
                    state,
                    f"Check input.  Calculated Pump Efficiency={this_pump.PumpEffic * 100.0:.3f}% which is bigger than 100%, for pump={this_pump.Name}",
                )
                ShowFatalError(state, "Errors found in Pump input")
        else:
            ShowWarningError(
                state,
                f"Check input. Pump nominal power or motor efficiency is set to 0, for pump={this_pump.Name}",
            )
        
        if this_pump.NomVolFlowRate <= SMALL_WATER_VOL_FLOW:
            ShowWarningError(
                state,
                f"Check input. Pump nominal flow rate is set or calculated = 0, for pump={this_pump.Name}",
            )
        
        if this_pump.PumpControl == PumpControlType.Continuous:
            pass
        
        this_pump.PumpOneTimeFlag = False
    
    if state.dataGlobal.RedoSizesHVACSimulation and not state.dataPlnt.PlantReSizingCompleted:
        size_pump(state, pump_num)
    
    if this_pump.PumpInitFlag and state.dataGlobal.BeginEnvrnFlag:
        if this_pump.pumpType == PumpType.Cond:
            temp_water_density = Fluid_GetWater(state).getDensity(
                state, INIT_CONV_TEMP, routine_name
            )
            steam_density = Fluid_GetSteam(state).getSatDensity(
                state, start_temp, 1.0, routine_name
            )
            this_pump.NomVolFlowRate = (
                this_pump.NomSteamVolFlowRate * steam_density / temp_water_density
            )
            mdot_max = this_pump.NomSteamVolFlowRate * steam_density
            mdot_min = 0.0
            PlantUtilities_InitComponentNodes(state, mdot_min, mdot_max, inlet_node, outlet_node)
            this_pump.MassFlowRateMax = mdot_max
            this_pump.MassFlowRateMin = this_pump.MinVolFlowRate * steam_density
        else:
            temp_water_density = this_pump.plantLoc.loop.glycol.getDensity(
                state, INIT_CONV_TEMP, routine_name
            )
            mdot_max = this_pump.NomVolFlowRate * temp_water_density
            mdot_min = 0.0
            PlantUtilities_InitComponentNodes(state, mdot_min, mdot_max, inlet_node, outlet_node)
            this_pump.MassFlowRateMax = mdot_max
            this_pump.MassFlowRateMin = this_pump.MinVolFlowRate * temp_water_density
        
        this_pump.Energy = 0.0
        this_pump.Power = 0.0
        state.dataPumps.PumpEquipReport[pump_num] = ReportVars()
        this_pump.PumpInitFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        this_pump.PumpInitFlag = True
    
    state.dataPumps.PumpMassFlowRate = 0.0
    state.dataPumps.PumpHeattoFluid = 0.0
    state.dataPumps.Power = 0.0
    state.dataPumps.ShaftPower = 0.0


def setup_pump_min_max_flows(state: Any, loop_num: int, pump_num: int) -> None:
    """Setup pump minimum and maximum flow rates."""
    this_pump = state.dataPumps.PumpEquip[pump_num]
    
    inlet_node = this_pump.InletNodeNum
    outlet_node = this_pump.OutletNodeNum
    this_in_node = state.dataLoopNodes.Node[inlet_node]
    this_out_node = state.dataLoopNodes.Node[outlet_node]
    
    inlet_node_max = this_in_node.MassFlowRateMaxAvail
    inlet_node_min = this_in_node.MassFlowRateMinAvail
    
    pump_sched_fraction = (
        min(1.0, max(0.0, this_pump.flowRateSched.getCurrentVal()))
        if this_pump.flowRateSched
        else 1.0
    )
    
    pump_overridable_max_limit = this_pump.MassFlowRateMax
    
    pump_mass_flow_rate_min_limit = (
        0.0
        if this_pump.LoopSolverOverwriteFlag
        else this_pump.MassFlowRateMin
    )
    
    pump_mass_flow_rate_min = max(inlet_node_min, pump_mass_flow_rate_min_limit)
    pump_mass_flow_rate_max = min(
        inlet_node_max, pump_overridable_max_limit * pump_sched_fraction
    )
    
    if pump_mass_flow_rate_min > pump_mass_flow_rate_max:
        pump_mass_flow_rate_min = 0.0
        pump_mass_flow_rate_max = 0.0
    
    if this_pump.pumpType == PumpType.VarSpeed:
        if this_pump.HasVFD:
            if this_pump.VFD.VFDControlType == ControlTypeVFD.VFDManual:
                pump_sched_rpm = this_pump.VFD.manualRPMSched.getCurrentVal()
                this_pump.RotSpeed = pump_sched_rpm / 60.0
            elif this_pump.VFD.VFDControlType == ControlTypeVFD.VFDAutomatic:
                get_required_mass_flow_rate(
                    state,
                    loop_num,
                    pump_num,
                    this_in_node.MassFlowRate,
                    pump_mass_flow_rate_min,
                    pump_mass_flow_rate_max,
                )
        
        if this_pump.PumpControl == PumpControlType.Continuous:
            this_in_node.MassFlowRateRequest = pump_mass_flow_rate_min
    
    elif this_pump.pumpType == PumpType.ConSpeed:
        if this_pump.PumpControl == PumpControlType.Continuous:
            pump_mass_flow_rate_min = pump_mass_flow_rate_max
            this_in_node.MassFlowRateRequest = pump_mass_flow_rate_min
    
    if hasattr(state.dataAvail, 'PlantAvailMgr') and state.dataAvail.PlantAvailMgr:
        if state.dataAvail.PlantAvailMgr[loop_num].availStatus == AVAIL_STATUS_FORCE_OFF:
            pump_mass_flow_rate_max = 0.0
            pump_mass_flow_rate_min = 0.0
    
    if this_pump.EMSMassFlowOverrideOn:
        pump_mass_flow_rate_max = this_pump.EMSMassFlowValue
        pump_mass_flow_rate_min = this_pump.EMSMassFlowValue
    
    this_out_node.MassFlowRateMinAvail = pump_mass_flow_rate_min
    this_out_node.MassFlowRateMaxAvail = pump_mass_flow_rate_max


def calc_pumps(state: Any, pump_num: int, flow_request: float) -> None:
    """Calculate pump power and update outlet conditions."""
    this_pump = state.dataPumps.PumpEquip[pump_num]
    inlet_node = this_pump.InletNodeNum
    outlet_node = this_pump.OutletNodeNum
    pump_type = this_pump.pumpType
    
    this_in_node = state.dataLoopNodes.Node[inlet_node]
    this_out_node = state.dataLoopNodes.Node[outlet_node]
    
    if flow_request > MASS_FLOW_TOLERANCE:
        state.dataPumps.PumpMassFlowRate = flow_request
    else:
        state.dataPumps.PumpMassFlowRate = 0.0
    
    if (
        pump_type == PumpType.VarSpeed
        or pump_type == PumpType.Bank_VarSpeed
        or pump_type == PumpType.Cond
    ):
        if DataPlant_CompData_getFlowCtrl(state, this_pump.plantLoc) == CONTROL_TYPE_SERIES_ACTIVE:
            state.dataPumps.PumpMassFlowRate = 0.0
    
    state.dataPumps.PumpMassFlowRate = min(
        this_pump.MassFlowRateMax, state.dataPumps.PumpMassFlowRate
    )
    state.dataPumps.PumpMassFlowRate = max(
        this_pump.MassFlowRateMin, state.dataPumps.PumpMassFlowRate
    )
    
    PlantUtilities_SetComponentFlowRate(
        state,
        state.dataPumps.PumpMassFlowRate,
        inlet_node,
        outlet_node,
        this_pump.plantLoc,
    )
    
    if state.dataPumps.PumpMassFlowRate <= MASS_FLOW_TOLERANCE:
        this_out_node.Temp = this_in_node.Temp
        this_out_node.Press = this_in_node.Press
        this_out_node.Quality = this_in_node.Quality
        return
    
    loop_density = this_pump.plantLoc.loop.glycol.getDensity(
        state, this_in_node.Temp, "CalcPumps"
    )
    
    if pump_type == PumpType.ConSpeed or pump_type == PumpType.VarSpeed or pump_type == PumpType.Cond:
        vol_flow_rate = state.dataPumps.PumpMassFlowRate / loop_density
        part_load_ratio = min(1.0, vol_flow_rate / this_pump.NomVolFlowRate)
        frac_full_load_power = (
            this_pump.PartLoadCoef[0]
            + this_pump.PartLoadCoef[1] * part_load_ratio
            + this_pump.PartLoadCoef[2] * part_load_ratio**2
            + this_pump.PartLoadCoef[3] * part_load_ratio**3
        )
        state.dataPumps.Power = frac_full_load_power * this_pump.NomPowerUse
    
    elif pump_type == PumpType.Bank_ConSpeed or pump_type == PumpType.Bank_VarSpeed:
        state.dataPumps.NumPumpsFullLoad = state.dataPumps.NumPumpsRunning - 1
        full_load_vol_flow_rate = (
            this_pump.NomVolFlowRate / this_pump.NumPumpsInBank
        )
        part_load_vol_flow_rate = (
            state.dataPumps.PumpMassFlowRate / loop_density
            - full_load_vol_flow_rate * state.dataPumps.NumPumpsFullLoad
        )
        full_load_power = this_pump.NomPowerUse / this_pump.NumPumpsInBank
        full_load_power_ratio = (
            this_pump.PartLoadCoef[0]
            + this_pump.PartLoadCoef[1]
            + this_pump.PartLoadCoef[2]
            + this_pump.PartLoadCoef[3]
        )
        part_load_ratio = min(1.0, part_load_vol_flow_rate / full_load_vol_flow_rate)
        frac_full_load_power = (
            this_pump.PartLoadCoef[0]
            + this_pump.PartLoadCoef[1] * part_load_ratio
            + this_pump.PartLoadCoef[2] * part_load_ratio**2
            + this_pump.PartLoadCoef[3] * part_load_ratio**3
        )
        state.dataPumps.Power = (
            (full_load_power_ratio * state.dataPumps.NumPumpsFullLoad + frac_full_load_power)
            * full_load_power
        )
    
    if state.dataPumps.Power < 0.0:
        state.dataPumps.Power = 0.0
    
    state.dataPumps.ShaftPower = state.dataPumps.Power * this_pump.MotorEffic
    state.dataPumps.PumpHeattoFluid = state.dataPumps.ShaftPower + (
        state.dataPumps.Power - state.dataPumps.ShaftPower
    ) * this_pump.FracMotorLossToFluid
    
    this_pump.Power = state.dataPumps.Power
    
    this_out_node.Temp = this_in_node.Temp
    this_out_node.Press = this_in_node.Press
    this_out_node.Quality = this_in_node.Quality


def size_pump(state: Any, pump_num: int) -> None:
    """Size pump flow and power if autosized."""
    routine_name = "PlantPumps::InitSimVars "
    routine_name_size_pumps = "SizePumps"
    start_temp = 100.0
    
    this_pump = state.dataPumps.PumpEquip[pump_num]
    
    if this_pump.plantLoc.loopNum > 0:
        temp_water_density = this_pump.plantLoc.loop.glycol.getDensity(
            state, INIT_CONV_TEMP, routine_name
        )
    else:
        temp_water_density = Fluid_GetWater(state).getDensity(
            state, INIT_CONV_TEMP, routine_name
        )
    
    if this_pump.NomVolFlowRateWasAutoSized:
        plant_siz_num = (
            this_pump.plantLoc.loop.PlantSizNum
            if this_pump.plantLoc.loopNum > 0
            else 0
        )
        if plant_siz_num > 0:
            plant_size_data = state.dataSize.PlantSizData[plant_siz_num]
            if plant_size_data.DesVolFlowRate >= SMALL_WATER_VOL_FLOW:
                this_pump.NomVolFlowRate = plant_size_data.DesVolFlowRate
    
    if this_pump.NomPowerUseWasAutoSized:
        if this_pump.NomVolFlowRate >= SMALL_WATER_VOL_FLOW:
            if this_pump.powerSizingMethod == PowerSizingMethod.SizePowerPerFlow:
                total_effic = this_pump.NomPumpHead / this_pump.powerPerFlowScalingFactor
            else:
                total_effic = (
                    (1 / this_pump.powerPerFlowPerPressureScalingFactor)
                    * this_pump.MotorEffic
                )
            this_pump.NomPowerUse = (
                this_pump.NomPumpHead * this_pump.NomVolFlowRate / total_effic
            )
        else:
            this_pump.NomPowerUse = 0.0


def report_pumps(state: Any, pump_num: int) -> None:
    """Report pump variables."""
    this_pump = state.dataPumps.PumpEquip[pump_num]
    this_pump_rep = state.dataPumps.PumpEquipReport[pump_num]
    
    pump_type = this_pump.pumpType
    outlet_node = this_pump.OutletNodeNum
    this_out_node = state.dataLoopNodes.Node[outlet_node]
    da_pumps = state.dataPumps
    
    if da_pumps.PumpMassFlowRate <= MASS_FLOW_TOLERANCE:
        state.dataPumps.PumpEquipReport[pump_num] = ReportVars()
        this_pump_rep.OutletTemp = this_out_node.Temp
        this_pump.Power = 0.0
        this_pump.Energy = 0.0
    else:
        this_pump_rep.PumpMassFlowRate = da_pumps.PumpMassFlowRate
        this_pump_rep.PumpHeattoFluid = da_pumps.PumpHeattoFluid
        this_pump_rep.OutletTemp = this_out_node.Temp
        this_pump.Power = da_pumps.Power
        this_pump.Energy = this_pump.Power * state.dataHVACGlobal.TimeStepSysSec
        this_pump_rep.ShaftPower = da_pumps.ShaftPower
        this_pump_rep.PumpHeattoFluidEnergy = (
            da_pumps.PumpHeattoFluid * state.dataHVACGlobal.TimeStepSysSec
        )
        
        if pump_type in [PumpType.ConSpeed, PumpType.VarSpeed, PumpType.Cond]:
            this_pump_rep.NumPumpsOperating = 1
        elif pump_type in [PumpType.Bank_ConSpeed, PumpType.Bank_VarSpeed]:
            this_pump_rep.NumPumpsOperating = da_pumps.NumPumpsRunning
        
        this_pump_rep.ZoneTotalGainRate = da_pumps.Power - da_pumps.PumpHeattoFluid
        this_pump_rep.ZoneTotalGainEnergy = (
            this_pump_rep.ZoneTotalGainRate * state.dataHVACGlobal.TimeStepSysSec
        )
        this_pump_rep.ZoneConvGainRate = (
            (1 - this_pump.SkinLossRadFraction) * this_pump_rep.ZoneTotalGainRate
        )
        this_pump_rep.ZoneRadGainRate = (
            this_pump.SkinLossRadFraction * this_pump_rep.ZoneTotalGainRate
        )


def pump_data_for_table(state: Any, num_pump: int) -> None:
    """Gather pump data for reporting tables."""
    this_pump = state.dataPumps.PumpEquip[num_pump]
    equip_name = this_pump.Name
    
    OutRptPredefined_PreDefTableEntry(
        state,
        "PumpType",
        equip_name,
        PUMP_TYPE_IDF_NAMES[int(this_pump.pumpType)],
    )
    if this_pump.PumpControl == PumpControlType.Continuous:
        OutRptPredefined_PreDefTableEntry(state, "PumpControl", equip_name, "Continuous")
    elif this_pump.PumpControl == PumpControlType.Intermittent:
        OutRptPredefined_PreDefTableEntry(
            state, "PumpControl", equip_name, "Intermittent"
        )
    
    OutRptPredefined_PreDefTableEntry(state, "PumpHead", equip_name, this_pump.NomPumpHead)
    OutRptPredefined_PreDefTableEntry(
        state, "PumpFlow", equip_name, this_pump.NomVolFlowRate, 6
    )
    OutRptPredefined_PreDefTableEntry(state, "PumpPower", equip_name, this_pump.NomPowerUse)
    if this_pump.NomVolFlowRate != 0:
        OutRptPredefined_PreDefTableEntry(
            state,
            "PumpPwrPerFlow",
            equip_name,
            this_pump.NomPowerUse / this_pump.NomVolFlowRate,
        )
    
    OutRptPredefined_PreDefTableEntry(
        state, "PumpEndUse", equip_name, this_pump.EndUseSubcategoryName
    )
    OutRptPredefined_PreDefTableEntry(
        state, "MotEff", equip_name, this_pump.MotorEffic
    )


def get_required_mass_flow_rate(
    state: Any,
    loop_num: int,
    pump_num: int,
    inlet_node_mass_flow_rate: float,
) -> tuple[float, float, float]:
    """Calculate required mass flow rate for VFD automatic control."""
    this_pump = state.dataPumps.PumpEquip[pump_num]
    
    rot_speed_min = this_pump.VFD.minRPMSched.getCurrentVal()
    rot_speed_max = this_pump.VFD.maxRPMSched.getCurrentVal()
    min_press = this_pump.VFD.lowerPsetSched.getCurrentVal()
    max_press = this_pump.VFD.upperPsetSched.getCurrentVal()
    
    pump_mass_flow_rate_max_press = 0.0
    pump_mass_flow_rate_min_press = 0.0
    
    if this_pump.plantLoc.loopNum > 0:
        if this_pump.plantLoc.loop.PressureEffectiveK > 0.0:
            pump_mass_flow_rate_max_press = math.sqrt(
                max_press / this_pump.plantLoc.loop.PressureEffectiveK
            )
            pump_mass_flow_rate_min_press = math.sqrt(
                min_press / this_pump.plantLoc.loop.PressureEffectiveK
            )
    
    if this_pump.PumpMassFlowRateMaxRPM < this_pump.PumpMassFlowRateMinRPM:
        this_pump.PumpMassFlowRateMaxRPM = this_pump.PumpMassFlowRateMinRPM
    
    if this_pump.PumpMassFlowRateMaxRPM > pump_mass_flow_rate_max_press:
        pump_max_mass_flow_rate_vfd_range = pump_mass_flow_rate_max_press
    else:
        pump_max_mass_flow_rate_vfd_range = this_pump.PumpMassFlowRateMaxRPM
    
    if this_pump.PumpMassFlowRateMinRPM > pump_mass_flow_rate_min_press:
        pump_min_mass_flow_rate_vfd_range = this_pump.PumpMassFlowRateMinRPM
    else:
        pump_min_mass_flow_rate_vfd_range = pump_mass_flow_rate_min_press
    
    if inlet_node_mass_flow_rate > pump_min_mass_flow_rate_vfd_range:
        if inlet_node_mass_flow_rate < pump_max_mass_flow_rate_vfd_range:
            actual_flow_rate = inlet_node_mass_flow_rate
        else:
            actual_flow_rate = pump_max_mass_flow_rate_vfd_range
    else:
        actual_flow_rate = pump_min_mass_flow_rate_vfd_range
    
    return (
        actual_flow_rate,
        pump_min_mass_flow_rate_vfd_range,
        pump_max_mass_flow_rate_vfd_range,
    )


# Stub functions for external dependencies
def Util_FindItemInList(name: str, list_obj: List[Any]) -> int:
    """Find index of object in list by name. Returns 0-based index or -1."""
    for i, obj in enumerate(list_obj):
        if hasattr(obj, 'Name') and obj.Name == name:
            return i
    return -1


def Util_makeUPPER(s: str) -> str:
    return s.upper()


def Util_ScanPlantLoopsForObject(state: Any, name: str, type_of: Any) -> None:
    pass


def Sched_GetSchedule(state: Any, name: str) -> Any:
    return None


def Curve_GetCurveIndex(state: Any, name: str) -> int:
    return -1


def Curve_GetCurveMinMaxValues(
    state: Any, index: int, min_val: float, max_val: float
) -> None:
    pass


def Node_GetOnlySingleNode(state: Any, name: str, errors_found: bool) -> int:
    return 0


def Node_TestCompSet(
    state: Any, obj_type: str, name: str, inlet: str, outlet: str, fluid: str
) -> None:
    pass


def GlobalNames_VerifyUniqueInterObjectName(
    state: Any, names_dict: dict, name: str, obj_type: str, errors_found: bool
) -> None:
    pass


def PlantUtilities_InitComponentNodes(
    state: Any, mdot_min: float, mdot_max: float, inlet: int, outlet: int
) -> None:
    pass


def PlantUtilities_SetComponentFlowRate(
    state: Any, mdot: float, inlet: int, outlet: int, plant_loc: Any
) -> None:
    pass


def DataPlant_CompData_getFlowCtrl(state: Any, plant_loc: Any) -> int:
    return 0


def Fluid_GetWater(state: Any) -> Any:
    return None


def Fluid_GetSteam(state: Any) -> Any:
    return None


def ShowWarningError(state: Any, msg: str) -> None:
    print(f"WARNING: {msg}")


def ShowFatalError(state: Any, msg: str) -> None:
    print(f"FATAL: {msg}")
    raise RuntimeError(msg)


def ShowSevereError(state: Any, msg: str) -> None:
    print(f"SEVERE: {msg}")


def ShowContinueError(state: Any, msg: str) -> None:
    print(f"  {msg}")


def OutRptPredefined_PreDefTableEntry(
    state: Any, key: str, equip_name: str, value: Any, precision: int = -1
) -> None:
    pass


# Constants
MASS_FLOW_TOLERANCE = 0.001
SMALL_WATER_VOL_FLOW = 0.00001
INIT_CONV_TEMP = 20.0
AUTO_SIZE = -99999.0
AVAIL_STATUS_FORCE_OFF = 0
CONTROL_TYPE_SERIES_ACTIVE = 1
