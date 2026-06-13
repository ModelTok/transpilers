# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any, Callable
from enum import Enum, auto
import math

# ============================================================================
# TYPE STUBS (external dependencies)
# ============================================================================

class Schedule(Protocol):
    def getCurrentVal(self) -> float: ...

class RefrigProps(Protocol):
    def getDensity(self, state: Any, temp: float, routine: str) -> float: ...
    def getSpecificHeat(self, state: Any, temp: float, routine: str) -> float: ...
    def getSatDensity(self, state: Any, temp: float, quality: float, routine: str) -> float: ...
    def getSatEnthalpy(self, state: Any, temp: float, quality: float, routine: str) -> float: ...

class Fan(Protocol):
    outletNodeNum: int
    maxAirFlowRate: float
    availSched: Optional[Schedule]
    totalPower: float
    def simulate(self, state: Any, first_hvac_iter: bool, foo: Any, bar: Any) -> None: ...

class PlantComponent(Protocol):
    NodeNumOut: int

class PlantLoop(Protocol):
    glycol: RefrigProps

class PlantLocation(Protocol):
    loopNum: int
    loop: Optional[PlantLoop]
    def getPlantComponent(self, state: Any) -> PlantComponent: ...

class Node(Protocol):
    Temp: float
    Press: float
    HumRat: float
    Enthalpy: float
    MassFlowRate: float
    MassFlowRateMax: float
    MassFlowRateMin: float
    MassFlowRateMaxAvail: float
    MassFlowRateMinAvail: float

class ZoneEqSizing(Protocol):
    SizingMethod: List[int]
    AirVolFlow: float
    SystemAirFlow: bool
    DesHeatingLoad: float
    HeatingCapacity: bool
    MaxHWVolFlow: float

class ZoneSysEnergyDemand(Protocol):
    RemainingOutputReqToHeatSP: float

class ZoneEquipConfig(Protocol):
    IsControlled: bool
    NumExhaustNodes: int
    ExhaustNode: List[int]
    NumInletNodes: int
    InletNode: List[int]

class Zone(Protocol):
    FloorArea: float

class FinalZoneSizing(Protocol):
    DesHeatLoad: float
    DesHeatVolFlow: float

class PlantSizData(Protocol):
    DeltaT: float
    ExitTemp: float

class ZoneHVACSizing(Protocol):
    HeatingSAFMethod: int
    MaxHeatAirVolFlow: float
    HeatingCapMethod: int
    ScaledHeatingCapacity: float

class EnergyPlusData(Protocol):
    dataUnitHeaters: Any
    dataSize: Any
    dataLoopNodes: Any
    dataFans: Any
    dataInputProcessing: Any
    dataAvail: Any
    dataPlnt: Any
    dataGlobal: Any
    dataEnvrn: Any
    dataZoneEquip: Any
    dataZoneEnergyDemand: Any
    dataHVACGlobal: Any
    dataHeatBal: Any
    dataWaterCoils: Any

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class UnitHeaterData:
    """Unit Heater data structure"""
    Name: str = ""
    availSched: Optional[Schedule] = None
    AirInNode: int = 0
    AirOutNode: int = 0
    fanType: int = 0
    FanName: str = ""
    Fan_Index: int = 0
    fanOpModeSched: Optional[Schedule] = None
    fanAvailSched: Optional[Schedule] = None
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    MaxAirVolFlow: float = 0.0
    MaxAirMassFlow: float = 0.0
    FanOperatesDuringNoHeating: str = ""
    FanOutletNode: int = 0
    fanOp: int = 0
    heatCoilType: int = 0
    HCoilTypeCh: str = ""
    HCoilName: str = ""
    HCoil_Index: int = 0
    HeatingCoilType: int = 0
    HCoil_fluid: Optional[RefrigProps] = None
    MaxVolHotWaterFlow: float = 0.0
    MaxVolHotSteamFlow: float = 0.0
    MaxHotWaterFlow: float = 0.0
    MaxHotSteamFlow: float = 0.0
    MinVolHotWaterFlow: float = 0.0
    MinVolHotSteamFlow: float = 0.0
    MinHotWaterFlow: float = 0.0
    MinHotSteamFlow: float = 0.0
    HotControlNode: int = 0
    HotControlOffset: float = 0.0
    HotCoilOutNodeNum: int = 0
    HWplantLoc: Optional[PlantLocation] = None
    PartLoadFrac: float = 0.0
    HeatPower: float = 0.0
    HeatEnergy: float = 0.0
    ElecPower: float = 0.0
    ElecEnergy: float = 0.0
    AvailManagerListName: str = ""
    availStatus: int = 0
    FanOffNoHeating: bool = False
    FanPartLoadRatio: float = 0.0
    ZonePtr: int = 0
    HVACSizingIndex: int = 0
    FirstPass: bool = True
    solveRootStats: Any = field(default_factory=dict)

@dataclass
class UnitHeatNumericFieldData:
    """Unit Heater numeric field data"""
    FieldNames: List[str] = field(default_factory=list)

@dataclass
class UnitHeatersData:
    """Global unit heaters data"""
    cMO_UnitHeater: str = "ZoneHVAC:UnitHeater"
    HCoilOn: bool = False
    NumOfUnitHeats: int = 0
    QZnReq: float = 0.0
    MySizeFlag: List[bool] = field(default_factory=list)
    CheckEquipName: List[bool] = field(default_factory=list)
    InitUnitHeaterOneTimeFlag: bool = True
    GetUnitHeaterInputFlag: bool = True
    ZoneEquipmentListChecked: bool = False
    SetMassFlowRateToZero: bool = False
    UnitHeat: List[UnitHeaterData] = field(default_factory=list)
    UnitHeatNumericFields: List[UnitHeatNumericFieldData] = field(default_factory=list)
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MyPlantScanFlag: List[bool] = field(default_factory=list)
    MyZoneEqFlag: List[bool] = field(default_factory=list)

    def init_constant_state(self, state: EnergyPlusData) -> None:
        pass

    def init_state(self, state: EnergyPlusData) -> None:
        pass

    def clear_state(self) -> None:
        self.HCoilOn = False
        self.NumOfUnitHeats = 0
        self.QZnReq = 0.0
        self.MySizeFlag.clear()
        self.CheckEquipName.clear()
        self.UnitHeat.clear()
        self.UnitHeatNumericFields.clear()
        self.InitUnitHeaterOneTimeFlag = True
        self.GetUnitHeaterInputFlag = True
        self.ZoneEquipmentListChecked = False
        self.SetMassFlowRateToZero = False
        self.MyEnvrnFlag.clear()
        self.MyPlantScanFlag.clear()
        self.MyZoneEqFlag.clear()

# ============================================================================
# EXTERNAL STUBS (signatures only, to be linked)
# ============================================================================

def Util_FindItemInList(name: str, items: List[Any]) -> int:
    """Find item index in list (1-based)"""
    pass

def Util_makeUPPER(s: str) -> str:
    """Convert string to uppercase"""
    pass

def Util_SameString(s1: str, s2: str) -> bool:
    """Case-insensitive string comparison"""
    pass

def Fans_GetFanIndex(state: EnergyPlusData, name: str) -> int:
    """Get fan index by name"""
    pass

def WaterCoils_GetCoilWaterInletNode(state: EnergyPlusData, coil_type: str, coil_name: str, err_flag: bool) -> int:
    """Get water coil inlet node"""
    pass

def WaterCoils_GetCoilWaterOutletNode(state: EnergyPlusData, coil_type: str, coil_name: str, err_flag: bool) -> int:
    """Get water coil outlet node"""
    pass

def WaterCoils_GetWaterCoilIndex(state: EnergyPlusData, coil_type: str, coil_name: str, err_flag: bool) -> int:
    """Get water coil index"""
    pass

def WaterCoils_SetCoilDesFlow(state: EnergyPlusData, coil_type: str, coil_name: str, flow: float, err_flag: bool) -> None:
    """Set coil design flow"""
    pass

def WaterCoils_SimulateWaterCoilComponents(state: EnergyPlusData, name: str, first_hvac: bool, index: int, 
                                           q_coil_req: float = 0.0, fan_op: int = 0, plr: float = 1.0) -> None:
    """Simulate water coil"""
    pass

def SteamCoils_GetSteamCoilIndex(state: EnergyPlusData, coil_type: str, coil_name: str, err_flag: bool) -> int:
    """Get steam coil index"""
    pass

def SteamCoils_GetCoilSteamInletNode(state: EnergyPlusData, index: int, name: str, err_flag: bool) -> int:
    """Get steam coil inlet node"""
    pass

def SteamCoils_SimulateSteamCoilComponents(state: EnergyPlusData, name: str, first_hvac: bool, index: int, 
                                           q_coil_req: float = 0.0, foo: Any = None, fan_op: int = 0, plr: float = 1.0) -> None:
    """Simulate steam coil"""
    pass

def HeatingCoils_SimulateHeatingCoilComponents(state: EnergyPlusData, name: str, first_hvac: bool, q_coil_req: float, 
                                               index: int, foo: Any = None, bar: Any = None, fan_op: int = 0, plr: float = 1.0) -> None:
    """Simulate heating coil"""
    pass

def PlantUtilities_ScanPlantLoopsForObject(state: EnergyPlusData, name: str, coil_type: int, loc: PlantLocation, 
                                           err_flag: bool, *args) -> None:
    """Scan plant loops for object"""
    pass

def PlantUtilities_InitComponentNodes(state: EnergyPlusData, min_flow: float, max_flow: float, inlet: int, outlet: int) -> None:
    """Initialize component nodes"""
    pass

def PlantUtilities_SetComponentFlowRate(state: EnergyPlusData, mdot: float, inlet: int, outlet: int, loc: PlantLocation) -> None:
    """Set component flow rate"""
    pass

def PlantUtilities_MyPlantSizingIndex(state: EnergyPlusData, coil_type: str, name: str, inlet: int, outlet: int, err_flag: bool) -> int:
    """Get plant sizing index"""
    pass

def Psychrometrics_PsyHFnTdbW(tdb: float, w: float) -> float:
    """Psychrometric enthalpy function"""
    pass

def Psychrometrics_PsyCpAirFnW(w: float) -> float:
    """Psychrometric Cp function"""
    pass

def Psychrometrics_CPHW(temp: float) -> float:
    """Specific heat of water"""
    pass

def Fluid_GetSteam(state: EnergyPlusData) -> RefrigProps:
    """Get steam fluid properties"""
    pass

def General_SolveRoot2(state: EnergyPlusData, tol: float, max_iter: int, sol_flag: List[int], 
                       f: Callable[[float], float], x_min: float, x_max: float, stats: Any) -> float:
    """Solve root using bisection/secant method"""
    pass

def ShowFatalError(state: EnergyPlusData, msg: str) -> None:
    """Show fatal error"""
    pass

def ShowSevereError(state: EnergyPlusData, msg: str) -> None:
    """Show severe error"""
    pass

def ShowContinueError(state: EnergyPlusData, msg: str) -> None:
    """Show continue error"""
    pass

def ShowWarningError(state: EnergyPlusData, msg: str) -> None:
    """Show warning error"""
    pass

def ShowMessage(state: EnergyPlusData, msg: str) -> None:
    """Show message"""
    pass

def ValidateComponent(state: EnergyPlusData, coil_type: str, coil_name: str, err_flag: bool, context: str) -> None:
    """Validate component"""
    pass

def Node_GetOnlySingleNode(state: EnergyPlusData, name: str, err_flag: bool, obj_type: int, parent_name: str, 
                           fluid_type: int, conn_type: int, comp_stream: int, obj_is_parent: int) -> int:
    """Get single node"""
    pass

def Node_SetUpCompSets(state: EnergyPlusData, parent: str, parent_name: str, comp_type: str, comp_name: str, 
                       inlet_name: str, outlet_name: str) -> None:
    """Set up component sets"""
    pass

def ControlCompOutput(state: EnergyPlusData, name: str, obj_type: str, index: int, first_hvac: bool, q_req: float,
                      control_node: int, max_flow: float, min_flow: float, offset: float, comp_type: int, 
                      err_index: int, *args, loc: PlantLocation = None) -> None:
    """Control component output"""
    pass

def SetupOutputVariable(state: EnergyPlusData, name: str, units: int, var_ref: Any, time_step: int, 
                        store_type: int, obj_name: str) -> None:
    """Setup output variable"""
    pass

def DataZoneEquipment_CheckZoneEquipmentList(state: EnergyPlusData, obj_type: str, name: str) -> bool:
    """Check zone equipment list"""
    pass

def DataSizing_resetHVACSizingGlobals(state: EnergyPlusData, zone_eq_num: int, zero: int, flag: bool) -> None:
    """Reset HVAC sizing globals"""
    pass

def DataSizing_CheckZoneSizing(state: EnergyPlusData, obj_type: str, name: str) -> None:
    """Check zone sizing"""
    pass

def BaseSizer_reportSizerOutput(state: EnergyPlusData, obj_type: str, obj_name: str, desc1: str, val1: float, 
                                 desc2: str = "", val2: float = 0.0) -> None:
    """Report sizer output"""
    pass

def ReportCoilSelection_setCoilSupplyFanInfo(state: EnergyPlusData, index: int, fan_name: str, fan_type: int, fan_index: int) -> None:
    """Set coil supply fan info"""
    pass

def ReportCoilSelection_getReportIndex(state: EnergyPlusData, coil_name: str, coil_type: int) -> int:
    """Get report index"""
    pass

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

def SimUnitHeater(state: EnergyPlusData, comp_name: str, zone_num: int, first_hvac_iteration: bool, 
                  power_met: List[float], lat_output_provided: List[float], comp_index: List[int]) -> None:
    """Simulate unit heater - main driver routine"""
    
    if state.dataUnitHeaters.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        state.dataUnitHeaters.GetUnitHeaterInputFlag = False
    
    if comp_index[0] == 0:
        unit_heat_num = Util_FindItemInList(comp_name, state.dataUnitHeaters.UnitHeat)
        if unit_heat_num == 0:
            ShowFatalError(state, f"SimUnitHeater: Unit not found={comp_name}")
        comp_index[0] = unit_heat_num
    else:
        unit_heat_num = comp_index[0]
        if unit_heat_num > state.dataUnitHeaters.NumOfUnitHeats or unit_heat_num < 1:
            ShowFatalError(state, f"SimUnitHeater: Invalid CompIndex passed={unit_heat_num}, Number of Units={state.dataUnitHeaters.NumOfUnitHeats}, Entered Unit name={comp_name}")
        if state.dataUnitHeaters.CheckEquipName[unit_heat_num - 1]:
            if comp_name != state.dataUnitHeaters.UnitHeat[unit_heat_num - 1].Name:
                ShowFatalError(state, f"SimUnitHeater: Invalid CompIndex passed={unit_heat_num}, Unit name={comp_name}, stored Unit Name for that index={state.dataUnitHeaters.UnitHeat[unit_heat_num - 1].Name}")
            state.dataUnitHeaters.CheckEquipName[unit_heat_num - 1] = False
    
    state.dataSize.ZoneEqUnitHeater = True
    InitUnitHeater(state, unit_heat_num, zone_num, first_hvac_iteration)
    state.dataSize.ZoneHeatingOnlyFan = True
    CalcUnitHeater(state, unit_heat_num, zone_num, first_hvac_iteration, power_met, lat_output_provided)
    state.dataSize.ZoneHeatingOnlyFan = False
    ReportUnitHeater(state, unit_heat_num)
    state.dataSize.ZoneEqUnitHeater = False

def GetUnitHeaterInput(state: EnergyPlusData) -> None:
    """Get unit heater input from input file"""
    
    routine_name = "GetUnitHeaterInput"
    current_module_object = state.dataUnitHeaters.cMO_UnitHeater
    
    state.dataUnitHeaters.NumOfUnitHeats = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object)
    
    num_fields = 0
    num_alphas = 0
    num_numbers = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, current_module_object, num_fields, num_alphas, num_numbers)
    
    if state.dataUnitHeaters.NumOfUnitHeats > 0:
        state.dataUnitHeaters.UnitHeat = [UnitHeaterData() for _ in range(state.dataUnitHeaters.NumOfUnitHeats)]
        state.dataUnitHeaters.CheckEquipName = [True] * state.dataUnitHeaters.NumOfUnitHeats
        state.dataUnitHeaters.UnitHeatNumericFields = [UnitHeatNumericFieldData() for _ in range(state.dataUnitHeaters.NumOfUnitHeats)]
    
    for unit_heat_num in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
        alphas = [""] * num_alphas
        numbers = [0.0] * num_numbers
        c_alpha_fields = [""] * num_alphas
        c_numeric_fields = [""] * num_numbers
        l_alpha_blanks = [True] * num_alphas
        l_numeric_blanks = [True] * num_numbers
        io_status = 0
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, current_module_object, unit_heat_num, alphas, num_alphas, 
            numbers, num_numbers, io_status, l_numeric_blanks, l_alpha_blanks,
            c_alpha_fields, c_numeric_fields)
        
        unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
        unit_heat.Name = alphas[0]
        
        if l_alpha_blanks[1]:
            unit_heat.availSched = None  # GetScheduleAlwaysOn
        else:
            unit_heat.availSched = None  # GetSchedule(state, alphas[1])
        
        unit_heat.AirInNode = Node_GetOnlySingleNode(
            state, alphas[2], False, 0, alphas[0], 0, 0, 0, 0)
        unit_heat.AirOutNode = Node_GetOnlySingleNode(
            state, alphas[3], False, 0, alphas[0], 0, 0, 0, 0)
        
        unit_heat.fanType = 0  # getEnumValue(HVAC.fanTypeNamesUC, alphas[4])
        unit_heat.FanName = alphas[5]
        unit_heat.MaxAirVolFlow = numbers[0]
        
        unit_heat.Fan_Index = Fans_GetFanIndex(state, unit_heat.FanName)
        if unit_heat.Fan_Index == 0:
            pass  # error handling
        else:
            fan = state.dataFans.fans[unit_heat.Fan_Index - 1]
            unit_heat.FanOutletNode = fan.outletNodeNum
        
        unit_heat.heatCoilType = 0  # getEnumValue(HVAC.coilTypeNamesUC, Util_makeUPPER(alphas[6]))
        unit_heat.HCoilTypeCh = alphas[6]
        unit_heat.HCoilName = alphas[7]
        
        if l_alpha_blanks[8]:
            unit_heat.fanOp = 0  # HVAC.FanOp.Cycling if OnOff else Continuous
        else:
            unit_heat.fanOpModeSched = None  # GetSchedule(state, alphas[8])
        
        unit_heat.FanOperatesDuringNoHeating = alphas[9]
        if Util_SameString(unit_heat.FanOperatesDuringNoHeating, "No"):
            unit_heat.FanOffNoHeating = True
        
        unit_heat.MaxVolHotWaterFlow = numbers[1]
        unit_heat.MinVolHotWaterFlow = numbers[2]
        unit_heat.MaxVolHotSteamFlow = numbers[1]
        unit_heat.MinVolHotSteamFlow = numbers[2]
        
        unit_heat.HotControlOffset = numbers[3]
        if unit_heat.HotControlOffset <= 0.0:
            unit_heat.HotControlOffset = 0.001
        
        if not l_alpha_blanks[10]:
            unit_heat.AvailManagerListName = alphas[10]
        
        unit_heat.HVACSizingIndex = 0
        if not l_alpha_blanks[11]:
            unit_heat.HVACSizingIndex = Util_FindItemInList(alphas[11], state.dataSize.ZoneHVACSizing)
        
        state.dataUnitHeaters.UnitHeatNumericFields[unit_heat_num - 1].FieldNames = c_numeric_fields[:]

def InitUnitHeater(state: EnergyPlusData, unit_heat_num: int, zone_num: int, first_hvac_iteration: bool) -> None:
    """Initialize unit heater"""
    
    routine_name = "InitUnitHeater"
    
    if state.dataUnitHeaters.InitUnitHeaterOneTimeFlag:
        state.dataUnitHeaters.MyEnvrnFlag = [True] * state.dataUnitHeaters.NumOfUnitHeats
        state.dataUnitHeaters.MySizeFlag = [True] * state.dataUnitHeaters.NumOfUnitHeats
        state.dataUnitHeaters.MyPlantScanFlag = [True] * state.dataUnitHeaters.NumOfUnitHeats
        state.dataUnitHeaters.MyZoneEqFlag = [True] * state.dataUnitHeaters.NumOfUnitHeats
        state.dataUnitHeaters.InitUnitHeaterOneTimeFlag = False
    
    unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
    in_node = unit_heat.AirInNode
    out_node = unit_heat.AirOutNode
    
    if state.dataUnitHeaters.MyPlantScanFlag[unit_heat_num - 1]:
        if unit_heat.HeatingCoilType in [1, 2]:  # Water or Steam
            err_flag = False
            PlantUtilities_ScanPlantLoopsForObject(state, unit_heat.HCoilName, unit_heat.HeatingCoilType, 
                                                    unit_heat.HWplantLoc, err_flag)
            if err_flag:
                ShowFatalError(state, "InitUnitHeater: Program terminated due to previous condition(s).")
        state.dataUnitHeaters.MyPlantScanFlag[unit_heat_num - 1] = False
    
    if not state.dataUnitHeaters.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataUnitHeaters.ZoneEquipmentListChecked = True
        for loop in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
            if not DataZoneEquipment_CheckZoneEquipmentList(state, "ZoneHVAC:UnitHeater", 
                                                             state.dataUnitHeaters.UnitHeat[loop - 1].Name):
                ShowSevereError(state, f"InitUnitHeater: Unit=[UNIT HEATER,{state.dataUnitHeaters.UnitHeat[loop - 1].Name}] is not on any ZoneHVAC:EquipmentList. It will not be simulated.")
    
    if not state.dataGlobal.SysSizingCalc and state.dataUnitHeaters.MySizeFlag[unit_heat_num - 1] and \
       not state.dataUnitHeaters.MyPlantScanFlag[unit_heat_num - 1]:
        SizeUnitHeater(state, unit_heat_num)
        state.dataUnitHeaters.MySizeFlag[unit_heat_num - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataUnitHeaters.MyEnvrnFlag[unit_heat_num - 1] and \
       not state.dataUnitHeaters.MyPlantScanFlag[unit_heat_num - 1]:
        rho_air = state.dataEnvrn.StdRhoAir
        unit_heat.MaxAirMassFlow = rho_air * unit_heat.MaxAirVolFlow
        
        state.dataLoopNodes.Node[out_node].MassFlowRateMax = unit_heat.MaxAirMassFlow
        state.dataLoopNodes.Node[out_node].MassFlowRateMin = 0.0
        state.dataLoopNodes.Node[in_node].MassFlowRateMax = unit_heat.MaxAirMassFlow
        state.dataLoopNodes.Node[in_node].MassFlowRateMin = 0.0
        
        if unit_heat.heatCoilType == 0:  # HeatingWater
            rho = unit_heat.HWplantLoc.loop.glycol.getDensity(state, 60.0, routine_name)
            unit_heat.MaxHotWaterFlow = rho * unit_heat.MaxVolHotWaterFlow
            unit_heat.MinHotWaterFlow = rho * unit_heat.MinVolHotWaterFlow
            PlantUtilities_InitComponentNodes(state, unit_heat.MinHotWaterFlow, unit_heat.MaxHotWaterFlow,
                                              unit_heat.HotControlNode, unit_heat.HotCoilOutNodeNum)
        
        state.dataUnitHeaters.MyEnvrnFlag[unit_heat_num - 1] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataUnitHeaters.MyEnvrnFlag[unit_heat_num - 1] = True
    
    state.dataUnitHeaters.QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num - 1].RemainingOutputReqToHeatSP
    
    state.dataUnitHeaters.SetMassFlowRateToZero = False
    if unit_heat.availSched and unit_heat.availSched.getCurrentVal() > 0:
        if (unit_heat.fanAvailSched and unit_heat.fanAvailSched.getCurrentVal() > 0 or state.dataHVACGlobal.TurnFansOn) and \
           not state.dataHVACGlobal.TurnFansOff:
            if unit_heat.FanOffNoHeating and \
               (state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num - 1].RemainingOutputReqToHeatSP < 100.0 or
                state.dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num - 1]):
                state.dataUnitHeaters.SetMassFlowRateToZero = True
        else:
            state.dataUnitHeaters.SetMassFlowRateToZero = True
    else:
        state.dataUnitHeaters.SetMassFlowRateToZero = True
    
    if state.dataUnitHeaters.SetMassFlowRateToZero:
        state.dataLoopNodes.Node[in_node].MassFlowRate = 0.0
        state.dataLoopNodes.Node[out_node].MassFlowRate = 0.0
    else:
        state.dataLoopNodes.Node[in_node].MassFlowRate = unit_heat.MaxAirMassFlow
        state.dataLoopNodes.Node[out_node].MassFlowRate = unit_heat.MaxAirMassFlow
    
    state.dataLoopNodes.Node[out_node].Temp = state.dataLoopNodes.Node[in_node].Temp
    state.dataLoopNodes.Node[out_node].HumRat = state.dataLoopNodes.Node[in_node].HumRat

def SizeUnitHeater(state: EnergyPlusData, unit_heat_num: int) -> None:
    """Size unit heater"""
    
    routine_name = "SizeUnitHeater"
    unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
    
    cur_zone_eq_num = state.dataSize.CurZoneEqNum
    
    state.dataSize.DataZoneNumber = unit_heat.ZonePtr
    state.dataSize.DataFanType = unit_heat.fanType
    state.dataSize.DataFanIndex = unit_heat.Fan_Index
    state.dataSize.DataFanPlacement = 1  # BlowThru
    
    if cur_zone_eq_num > 0:
        if unit_heat.HVACSizingIndex > 0:
            pass  # Scalable sizing logic
        else:
            pass  # Standard sizing logic
    
    is_auto_size = unit_heat.MaxVolHotWaterFlow == 9999.0  # AutoSize constant
    
    if unit_heat.heatCoilType == 0:  # HeatingWater
        if cur_zone_eq_num > 0:
            if not is_auto_size:
                BaseSizer_reportSizerOutput(state, "ZoneHVAC:UnitHeater", unit_heat.Name,
                                           "User-Specified Maximum Hot Water Flow [m3/s]", unit_heat.MaxVolHotWaterFlow)
    else:
        unit_heat.MaxVolHotWaterFlow = 0.0
    
    is_auto_size = unit_heat.MaxVolHotSteamFlow == 9999.0
    
    if unit_heat.heatCoilType == 1:  # HeatingSteam
        if cur_zone_eq_num > 0:
            if not is_auto_size:
                BaseSizer_reportSizerOutput(state, "ZoneHVAC:UnitHeater", unit_heat.Name,
                                           "User-Specified Maximum Steam Flow [m3/s]", unit_heat.MaxVolHotSteamFlow)
    else:
        unit_heat.MaxVolHotSteamFlow = 0.0
    
    WaterCoils_SetCoilDesFlow(state, unit_heat.HCoilTypeCh, unit_heat.HCoilName, unit_heat.MaxAirVolFlow, False)

def CalcUnitHeater(state: EnergyPlusData, unit_heat_num: int, zone_num: int, first_hvac_iteration: bool,
                   power_met: List[float], lat_output_provided: List[float]) -> None:
    """Calculate unit heater operation"""
    
    unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
    inlet_node = unit_heat.AirInNode
    outlet_node = unit_heat.AirOutNode
    control_node = unit_heat.HotControlNode
    control_offset = unit_heat.HotControlOffset
    fan_op = unit_heat.fanOp
    
    q_unit_out = 0.0
    no_output = 0.0
    full_output = 0.0
    latent_output = 0.0
    max_water_flow = 0.0
    min_water_flow = 0.0
    part_load_frac = 0.0
    
    if fan_op != 1:  # Not cycling
        if unit_heat.availSched and unit_heat.availSched.getCurrentVal() <= 0:
            state.dataUnitHeaters.HCoilOn = False
            mdot = 0.0
            PlantUtilities_SetComponentFlowRate(state, mdot, unit_heat.HotControlNode, 
                                                unit_heat.HotCoilOutNodeNum, unit_heat.HWplantLoc)
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_unit_out)
        elif state.dataUnitHeaters.QZnReq < 100.0 or state.dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num - 1]:
            if not unit_heat.FanOffNoHeating:
                state.dataUnitHeaters.HCoilOn = False
                mdot = 0.0
                PlantUtilities_SetComponentFlowRate(state, mdot, unit_heat.HotControlNode,
                                                    unit_heat.HotCoilOutNodeNum, unit_heat.HWplantLoc)
                CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_unit_out)
            else:
                state.dataUnitHeaters.HCoilOn = False
                mdot = 0.0
                if unit_heat.HWplantLoc.loopNum > 0:
                    PlantUtilities_SetComponentFlowRate(state, mdot, unit_heat.HotControlNode,
                                                        unit_heat.HotCoilOutNodeNum, unit_heat.HWplantLoc)
                CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_unit_out)
        else:
            if unit_heat.heatCoilType == 0:  # HeatingWater
                if first_hvac_iteration:
                    max_water_flow = unit_heat.MaxHotWaterFlow
                    min_water_flow = unit_heat.MinHotWaterFlow
                else:
                    max_water_flow = state.dataLoopNodes.Node[control_node].MassFlowRateMaxAvail
                    min_water_flow = state.dataLoopNodes.Node[control_node].MassFlowRateMinAvail
                ControlCompOutput(state, unit_heat.Name, state.dataUnitHeaters.cMO_UnitHeater,
                                unit_heat_num, first_hvac_iteration, state.dataUnitHeaters.QZnReq,
                                control_node, max_water_flow, min_water_flow, control_offset,
                                unit_heat.ControlCompTypeNum, unit_heat.CompErrIndex, loc=unit_heat.HWplantLoc)
        
        if state.dataLoopNodes.Node[inlet_node].MassFlowRateMax > 0.0:
            unit_heat.FanPartLoadRatio = state.dataLoopNodes.Node[inlet_node].MassFlowRate / \
                                         state.dataLoopNodes.Node[inlet_node].MassFlowRateMax
    else:
        if state.dataUnitHeaters.QZnReq < 100.0 or state.dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num - 1] or \
           (unit_heat.availSched and unit_heat.availSched.getCurrentVal() <= 0):
            part_load_frac = 0.0
            state.dataUnitHeaters.HCoilOn = False
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_unit_out, fan_op, part_load_frac)
            if state.dataLoopNodes.Node[inlet_node].MassFlowRateMax > 0.0:
                unit_heat.FanPartLoadRatio = state.dataLoopNodes.Node[inlet_node].MassFlowRate / \
                                             state.dataLoopNodes.Node[inlet_node].MassFlowRateMax
        else:
            state.dataUnitHeaters.HCoilOn = True
            part_load_frac = 0.0
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, no_output, fan_op, part_load_frac)
            if (no_output - state.dataUnitHeaters.QZnReq) < 100.0:
                part_load_frac = 1.0
                CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, full_output, fan_op, part_load_frac)
                if (full_output - state.dataUnitHeaters.QZnReq) > 100.0:
                    def f(plr: float) -> float:
                        q_out = [0.0]
                        CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_out, fan_op, plr)
                        if state.dataUnitHeaters.QZnReq != 0.0:
                            return (q_out[0] - state.dataUnitHeaters.QZnReq) / state.dataUnitHeaters.QZnReq
                        return 0.0
                    sol_flag = [0]
                    part_load_frac = General_SolveRoot2(state, 0.001, 100, sol_flag, f, 0.0, 1.0, unit_heat.solveRootStats)
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, q_unit_out, fan_op, part_load_frac)
        
        unit_heat.PartLoadFrac = part_load_frac
        unit_heat.FanPartLoadRatio = part_load_frac
        state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
    
    spec_hum_out = state.dataLoopNodes.Node[outlet_node].HumRat
    spec_hum_in = state.dataLoopNodes.Node[inlet_node].HumRat
    latent_output = state.dataLoopNodes.Node[outlet_node].MassFlowRate * (spec_hum_out - spec_hum_in)
    
    q_unit_out = state.dataLoopNodes.Node[outlet_node].MassFlowRate * \
                 (Psychrometrics_PsyHFnTdbW(state.dataLoopNodes.Node[outlet_node].Temp, state.dataLoopNodes.Node[inlet_node].HumRat) -
                  Psychrometrics_PsyHFnTdbW(state.dataLoopNodes.Node[inlet_node].Temp, state.dataLoopNodes.Node[inlet_node].HumRat))
    
    unit_heat.HeatPower = max(0.0, q_unit_out)
    unit_heat.ElecPower = state.dataFans.fans[unit_heat.Fan_Index - 1].totalPower
    
    power_met[0] = q_unit_out
    lat_output_provided[0] = latent_output

def CalcUnitHeaterComponents(state: EnergyPlusData, unit_heat_num: int, first_hvac_iteration: bool, 
                             load_met: List[float], fan_op: int = 0, part_load_ratio: float = 1.0) -> None:
    """Calculate unit heater components"""
    
    unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
    inlet_node = unit_heat.AirInNode
    outlet_node = unit_heat.AirOutNode
    
    if fan_op != 1:  # Not cycling
        state.dataFans.fans[unit_heat.Fan_Index - 1].simulate(state, first_hvac_iteration, None, None)
        
        if unit_heat.heatCoilType == 0:  # HeatingWater
            WaterCoils_SimulateWaterCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration, unit_heat.HCoil_Index)
        elif unit_heat.heatCoilType == 1:  # HeatingSteam
            q_coil_req = 0.0
            if state.dataUnitHeaters.HCoilOn:
                h_coil_in_air_node = unit_heat.FanOutletNode
                cp_air = Psychrometrics_PsyCpAirFnW(state.dataLoopNodes.Node[unit_heat.AirInNode].HumRat)
                q_coil_req = state.dataUnitHeaters.QZnReq - \
                             state.dataLoopNodes.Node[h_coil_in_air_node].MassFlowRate * cp_air * \
                             (state.dataLoopNodes.Node[h_coil_in_air_node].Temp - 
                              state.dataLoopNodes.Node[unit_heat.AirInNode].Temp)
            if q_coil_req < 0.0:
                q_coil_req = 0.0
            SteamCoils_SimulateSteamCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration,
                                                   unit_heat.HCoil_Index, q_coil_req)
        elif unit_heat.heatCoilType in [2, 3]:  # Electric or Gas
            q_coil_req = 0.0
            if state.dataUnitHeaters.HCoilOn:
                h_coil_in_air_node = unit_heat.FanOutletNode
                cp_air = Psychrometrics_PsyCpAirFnW(state.dataLoopNodes.Node[unit_heat.AirInNode].HumRat)
                q_coil_req = state.dataUnitHeaters.QZnReq - \
                             state.dataLoopNodes.Node[h_coil_in_air_node].MassFlowRate * cp_air * \
                             (state.dataLoopNodes.Node[h_coil_in_air_node].Temp -
                              state.dataLoopNodes.Node[unit_heat.AirInNode].Temp)
            if q_coil_req < 0.0:
                q_coil_req = 0.0
            HeatingCoils_SimulateHeatingCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration,
                                                       q_coil_req, unit_heat.HCoil_Index)
        
        air_mass_flow = state.dataLoopNodes.Node[outlet_node].MassFlowRate
        state.dataLoopNodes.Node[inlet_node].MassFlowRate = state.dataLoopNodes.Node[outlet_node].MassFlowRate
    
    else:  # OnOff fan cycling
        state.dataLoopNodes.Node[inlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRateMax * part_load_ratio
        air_mass_flow = state.dataLoopNodes.Node[inlet_node].MassFlowRate
        state.dataLoopNodes.Node[inlet_node].MassFlowRateMaxAvail = air_mass_flow
        
        state.dataFans.fans[unit_heat.Fan_Index - 1].simulate(state, first_hvac_iteration, None, None)
        
        if unit_heat.heatCoilType == 0:  # HeatingWater
            mdot = 0.0
            q_coil_req = 0.0
            if state.dataUnitHeaters.HCoilOn:
                h_coil_in_air_node = unit_heat.FanOutletNode
                cp_air = Psychrometrics_PsyCpAirFnW(state.dataLoopNodes.Node[unit_heat.AirInNode].HumRat)
                q_coil_req = state.dataUnitHeaters.QZnReq - \
                             state.dataLoopNodes.Node[h_coil_in_air_node].MassFlowRate * cp_air * \
                             (state.dataLoopNodes.Node[h_coil_in_air_node].Temp -
                              state.dataLoopNodes.Node[unit_heat.AirInNode].Temp)
                mdot = unit_heat.MaxHotWaterFlow * part_load_ratio
            if q_coil_req < 0.0:
                q_coil_req = 0.0
            PlantUtilities_SetComponentFlowRate(state, mdot, unit_heat.HotControlNode,
                                                unit_heat.HotCoilOutNodeNum, unit_heat.HWplantLoc)
            WaterCoils_SimulateWaterCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration,
                                                   unit_heat.HCoil_Index, q_coil_req, fan_op, part_load_ratio)
        elif unit_heat.heatCoilType == 1:  # HeatingSteam
            mdot = 0.0
            q_coil_req = 0.0
            if state.dataUnitHeaters.HCoilOn:
                h_coil_in_air_node = unit_heat.FanOutletNode
                cp_air = Psychrometrics_PsyCpAirFnW(state.dataLoopNodes.Node[unit_heat.AirInNode].HumRat)
                q_coil_req = state.dataUnitHeaters.QZnReq - \
                             state.dataLoopNodes.Node[h_coil_in_air_node].MassFlowRate * cp_air * \
                             (state.dataLoopNodes.Node[h_coil_in_air_node].Temp -
                              state.dataLoopNodes.Node[unit_heat.AirInNode].Temp)
                mdot = unit_heat.MaxHotSteamFlow * part_load_ratio
            if q_coil_req < 0.0:
                q_coil_req = 0.0
            PlantUtilities_SetComponentFlowRate(state, mdot, unit_heat.HotControlNode,
                                                unit_heat.HotCoilOutNodeNum, unit_heat.HWplantLoc)
            SteamCoils_SimulateSteamCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration,
                                                   unit_heat.HCoil_Index, q_coil_req, None, fan_op, part_load_ratio)
        elif unit_heat.heatCoilType in [2, 3]:  # Electric or Gas
            q_coil_req = 0.0
            if state.dataUnitHeaters.HCoilOn:
                h_coil_in_air_node = unit_heat.FanOutletNode
                cp_air = Psychrometrics_PsyCpAirFnW(state.dataLoopNodes.Node[unit_heat.AirInNode].HumRat)
                q_coil_req = state.dataUnitHeaters.QZnReq - \
                             state.dataLoopNodes.Node[h_coil_in_air_node].MassFlowRate * cp_air * \
                             (state.dataLoopNodes.Node[h_coil_in_air_node].Temp -
                              state.dataLoopNodes.Node[unit_heat.AirInNode].Temp)
            if q_coil_req < 0.0:
                q_coil_req = 0.0
            HeatingCoils_SimulateHeatingCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration,
                                                       q_coil_req, unit_heat.HCoil_Index, None, None, fan_op, part_load_ratio)
        
        state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
    
    load_met[0] = air_mass_flow * (Psychrometrics_PsyHFnTdbW(state.dataLoopNodes.Node[outlet_node].Temp, 
                                                               state.dataLoopNodes.Node[inlet_node].HumRat) -
                                    Psychrometrics_PsyHFnTdbW(state.dataLoopNodes.Node[inlet_node].Temp,
                                                               state.dataLoopNodes.Node[inlet_node].HumRat))

def ReportUnitHeater(state: EnergyPlusData, unit_heat_num: int) -> None:
    """Report unit heater results"""
    
    unit_heat = state.dataUnitHeaters.UnitHeat[unit_heat_num - 1]
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    
    unit_heat.HeatEnergy = unit_heat.HeatPower * time_step_sys_sec
    unit_heat.ElecEnergy = unit_heat.ElecPower * time_step_sys_sec
    
    if unit_heat.FirstPass:
        if not state.dataGlobal.SysSizingCalc:
            DataSizing_resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, 0, unit_heat.FirstPass)

def getUnitHeaterIndex(state: EnergyPlusData, comp_name: str) -> int:
    """Get unit heater index by name"""
    
    if state.dataUnitHeaters.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        state.dataUnitHeaters.GetUnitHeaterInputFlag = False
    
    for unit_heat_num in range(1, state.dataUnitHeaters.NumOfUnitHeats + 1):
        if Util_SameString(state.dataUnitHeaters.UnitHeat[unit_heat_num - 1].Name, comp_name):
            return unit_heat_num
    
    return 0
