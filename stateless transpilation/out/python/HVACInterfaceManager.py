"""
EnergyPlus HVAC Interface Manager - Python Port
Port of HVACInterfaceManager.hh/.cc
"""

from dataclasses import dataclass, field
from typing import Protocol, List
from enum import IntEnum, Enum
import math
from abc import abstractmethod

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state container, source: EnergyPlus/Data/EnergyPlusData.hh)
# - DataConvergParams (convergence parameters, source: EnergyPlus/DataConvergParams.hh)
# - DataLoopNodes (loop nodes, source: EnergyPlus/DataLoopNodes.hh)
# - DataPlant (plant loop data, source: EnergyPlus/Plant/DataPlant.hh)
# - DataAirLoop (air loop data, source: EnergyPlus/DataAirLoop.hh)
# - DataContaminantBalance (contaminant balance, source: EnergyPlus/DataContaminantBalance.hh)
# - DataHVACGlobals (HVAC globals, source: EnergyPlus/DataHVACGlobals.hh)
# - DataBranchAirLoopPlant (branch constants, source: EnergyPlus/DataBranchAirLoopPlant.hh)
# - FluidProperties (glycol properties, source: EnergyPlus/FluidProperties.hh)
# - PlantUtilities (SetActuatedBranchFlowRate, source: EnergyPlus/PlantUtilities.hh)
# - OutputProcessor (SetupOutputVariable, source: EnergyPlus/OutputProcessor.hh)
# - UtilityRoutines (ShowWarningError, source: EnergyPlus/UtilityRoutines.hh)
# - PlantLocation (struct, source: EnergyPlus/Plant/PlantLocation.hh)

# Constants for Common Pipe Recirc Flow Directions
NoRecircFlow = 0
PrimaryRecirc = 1
SecondaryRecirc = 2


class FlowType(IntEnum):
    """Flow type enumeration for pump types"""
    Invalid = -1
    Constant = 0
    Variable = 1
    Num = 2


class LoopSideLocation(IntEnum):
    """Loop side location enumeration"""
    Supply = 0
    Demand = 1


class CommonPipeType(IntEnum):
    """Common pipe type enumeration"""
    No = 0
    Single = 1
    TwoWay = 2


@dataclass
class CommonPipeData:
    """Common pipe data structure for reporting and calculations"""
    CommonPipeType: CommonPipeType = CommonPipeType.No
    SupplySideInletPumpType: FlowType = FlowType.Invalid
    DemandSideInletPumpType: FlowType = FlowType.Invalid
    FlowDir: int = 0  # Direction in which flow is in Common Pipe
    Flow: float = 0.0  # Flow in the Common Pipe
    Temp: float = 0.0  # Temperature in Common Pipe
    SecCPLegFlow: float = 0.0  # Mass flow in secondary side Common pipe leg
    PriCPLegFlow: float = 0.0  # Mass flow in primary side Common pipe leg
    SecToPriFlow: float = 0.0  # Mass flow from Secondary to primary side
    PriToSecFlow: float = 0.0  # Mass flow from primary to Secondary side
    PriInTemp: float = 0.0  # Temperature at primary inlet node
    PriOutTemp: float = 0.0  # Temperature at primary outlet node
    SecInTemp: float = 0.0  # Temperature at secondary inlet node
    SecOutTemp: float = 0.0  # Temperature at secondary outlet node
    PriInletSetPoint: float = 0.0  # Setpoint at Primary inlet node
    SecInletSetPoint: float = 0.0  # Setpoint at Secondary inlet node
    PriInletControlled: bool = False  # True if Primary inlet node is controlled
    SecInletControlled: bool = False  # True if secondary inlet is controlled
    PriFlowRequest: float = 0.0  # total flow request on supply side
    MyEnvrnFlag: bool = True


@dataclass
class HVACInterfaceManagerData:
    """Global data for HVAC Interface Manager"""
    CommonPipeSetupFinished: bool = False
    PlantCommonPipe: List[CommonPipeData] = field(default_factory=list)
    TmpRealARR: List[float] = field(default_factory=list)


# External dependency protocols/interfaces
class Node(Protocol):
    """Protocol for loop node access"""
    @property
    def MassFlowRate(self) -> float: ...
    @MassFlowRate.setter
    def MassFlowRate(self, val: float) -> None: ...
    
    @property
    def MassFlowRateMinAvail(self) -> float: ...
    @MassFlowRateMinAvail.setter
    def MassFlowRateMinAvail(self, val: float) -> None: ...
    
    @property
    def MassFlowRateMaxAvail(self) -> float: ...
    @MassFlowRateMaxAvail.setter
    def MassFlowRateMaxAvail(self, val: float) -> None: ...
    
    @property
    def Temp(self) -> float: ...
    @Temp.setter
    def Temp(self, val: float) -> None: ...
    
    @property
    def HumRat(self) -> float: ...
    @HumRat.setter
    def HumRat(self, val: float) -> None: ...
    
    @property
    def Enthalpy(self) -> float: ...
    @Enthalpy.setter
    def Enthalpy(self, val: float) -> None: ...
    
    @property
    def Quality(self) -> float: ...
    @Quality.setter
    def Quality(self, val: float) -> None: ...
    
    @property
    def Press(self) -> float: ...
    @Press.setter
    def Press(self, val: float) -> None: ...
    
    @property
    def CO2(self) -> float: ...
    @CO2.setter
    def CO2(self, val: float) -> None: ...
    
    @property
    def GenContam(self) -> float: ...
    @GenContam.setter
    def GenContam(self, val: float) -> None: ...
    
    @property
    def TempSetPoint(self) -> float: ...
    @TempSetPoint.setter
    def TempSetPoint(self, val: float) -> None: ...


class LoopNodes(Protocol):
    """Protocol for loop nodes container"""
    def Node(self, index: int) -> Node: ...


class AirLoopConvergence(Protocol):
    """Protocol for air loop convergence data"""
    HVACMassFlowNotConverged: List[bool]
    HVACHumRatNotConverged: List[bool]
    HVACTempNotConverged: List[bool]
    HVACEnergyNotConverged: List[bool]
    HVACCO2NotConverged: List[bool]
    HVACGenContamNotConverged: List[bool]
    HVACFlowDemandToSupplyTolValue: List[float]
    HVACHumDemandToSupplyTolValue: List[float]
    HVACTempDemandToSupplyTolValue: List[float]
    HVACEnergyDemandToSupplyTolValue: List[float]
    HVACEnthalpyDemandToSupplyTolValue: List[float]
    HVACPressureDemandToSupplyTolValue: List[float]
    HVACCO2DemandToSupplyTolValue: List[float]
    HVACGenContamDemandToSupplyTolValue: List[float]
    HVACFlowSupplyDeck1ToDemandTolValue: List[float]
    HVACHumSupplyDeck1ToDemandTolValue: List[float]
    HVACTempSupplyDeck1ToDemandTolValue: List[float]
    HVACEnergySupplyDeck1ToDemandTolValue: List[float]
    HVACEnthalpySupplyDeck1ToDemandTolValue: List[float]
    HVACPressureSupplyDeck1ToDemandTolValue: List[float]
    HVACCO2SupplyDeck1ToDemandTolValue: List[float]
    HVACGenContamSupplyDeck1ToDemandTolValue: List[float]
    HVACFlowSupplyDeck2ToDemandTolValue: List[float]
    HVACHumSupplyDeck2ToDemandTolValue: List[float]
    HVACTempSupplyDeck2ToDemandTolValue: List[float]
    HVACEnergySupplyDeck2ToDemandTolValue: List[float]
    HVACEnthalpySupplyDeck2ToDemandTolValue: List[float]
    HVACPressueSupplyDeck2ToDemandTolValue: List[float]
    HVACCO2SupplyDeck2ToDemandTolValue: List[float]
    HVACGenContamSupplyDeck2ToDemandTolValue: List[float]


class PlantConvergence(Protocol):
    """Protocol for plant loop convergence data"""
    PlantMassFlowNotConverged: bool
    PlantTempNotConverged: bool
    PlantFlowDemandToSupplyTolValue: List[float]
    PlantFlowSupplyToDemandTolValue: List[float]
    PlantTempDemandToSupplyTolValue: List[float]
    PlantTempSupplyToDemandTolValue: List[float]


class Contaminant(Protocol):
    """Protocol for contaminant balance data"""
    @property
    def CO2Simulation(self) -> bool: ...
    
    @property
    def GenericContamSimulation(self) -> bool: ...


class Glycol(Protocol):
    """Protocol for fluid properties"""
    def getSpecificHeat(self, state: 'EnergyPlusData', temp: float, routine_name: str) -> float: ...


class LoopSide(Protocol):
    """Protocol for loop side data"""
    NodeNumIn: int
    NodeNumOut: int
    LoopSideInlet_TankTemp: float
    LoopSideInlet_MdotCpDeltaT: float
    LoopSideInlet_McpDTdt: float
    TotalPumpHeat: float
    TimeElapsed: float
    LastTempInterfaceTankOutlet: float
    TempInterfaceTankOutlet: float
    InletNodeSetPt: bool
    Branch: List[any]


class PlantLoop(Protocol):
    """Protocol for plant loop data"""
    Name: str
    Mass: float
    CommonPipeType: CommonPipeType
    HasPressureComponents: bool
    LoopSide: dict
    glycol: Glycol
    
    @abstractmethod
    def LoopSide(self, side: LoopSideLocation) -> LoopSide: ...


class PlantData(Protocol):
    """Protocol for plant data container"""
    TotNumLoops: int
    
    def PlantLoop(self, index: int) -> PlantLoop: ...


class ConvergeParams(Protocol):
    """Protocol for convergence parameters"""
    def AirLoopConvergence(self, index: int) -> AirLoopConvergence: ...
    def PlantConvergence(self, index: int) -> PlantConvergence: ...


class AirToZoneNodeInfo(Protocol):
    """Protocol for air to zone node info"""
    NumSupplyNodes: int
    
    def ZoneEquipSupplyNodeNum(self, index: int) -> int: ...


class AirLoop(Protocol):
    """Protocol for air loop data"""
    def AirToZoneNodeInfo(self, index: int) -> AirToZoneNodeInfo: ...


class ContaminantBalance(Protocol):
    """Protocol for contaminant balance data container"""
    Contaminant: Contaminant


class HVACGlobals(Protocol):
    """Protocol for HVAC global data"""
    SysTimeElapsed: float
    TimeStepSysSec: float


class GlobalData(Protocol):
    """Protocol for global data"""
    HourOfDay: int
    TimeStep: int
    TimeStepZone: float
    BeginEnvrnFlag: bool


class PlantLocation(Protocol):
    """Protocol for plant location"""
    loopNum: int
    loopSideNum: LoopSideLocation


class EnergyPlusData(Protocol):
    """Protocol for EnergyPlus state"""
    dataLoopNodes: LoopNodes
    dataConvergeParams: ConvergeParams
    dataPlnt: PlantData
    dataAirLoop: AirLoop
    dataContaminantBalance: ContaminantBalance
    dataHVACGlobals: HVACGlobals
    dataGlobal: GlobalData
    dataHVACInterfaceMgr: HVACInterfaceManagerData


# Constants from external modules
HVAC_CP_APPROX = 1006.0
HVAC_FLOW_RATE_TOLER = 0.01
HVAC_HUM_RAT_TOLER = 0.0001
HVAC_TEMPERATURE_TOLER = 0.01
HVAC_ENERGY_TOLER = 100000.0
HVAC_ENTHALPY_TOLER = 100000.0
HVAC_PRESS_TOLER = 1.0
HVAC_CO2_TOLER = 0.1
HVAC_GENCONTAM_TOLER = 1e-8
PLANT_FLOW_RATE_TOLER = 0.001
PLANT_TEMPERATURE_TOLER = 0.01
PLANT_DELTA_TEMP_TOL = 0.01
PLANT_MASS_FLOW_TOLERANCE = 0.001
CONVER_LOG_STACK_DEPTH = 6


def rshift1(arr: List[float]) -> None:
    """In-place right shift by 1 of array elements"""
    if len(arr) == 0:
        return
    last_val = arr[-1]
    for i in range(len(arr) - 1, 0, -1):
        arr[i] = arr[i - 1]
    arr[0] = last_val


def update_hvac_interface(state: EnergyPlusData,
                          air_loop_num: int,
                          called_from: int,
                          outlet_node: int,
                          inlet_node: int,
                          out_of_tolerance_flag: List[bool]) -> None:
    """
    Update HVAC interface between air loop sides.
    
    Args:
        state: EnergyPlus state
        air_loop_num: air loop number
        called_from: which side is calling (CalledFrom enum value)
        outlet_node: outlet node number
        inlet_node: inlet node number
        out_of_tolerance_flag: flag indicating if resimulation needed (as list for mutability)
    """
    tmp_real_arr = state.dataHVACInterfaceMgr.TmpRealARR
    air_loop_conv = state.dataConvergeParams.AirLoopConvergence(air_loop_num)
    this_inlet_node = state.dataLoopNodes.Node(inlet_node)
    i_call = called_from
    
    # CalledFrom::AirSystemDemandSide == 1, AirSystemSupplySideDeck1 == 2, AirSystemSupplySideDeck2 == 3
    
    if called_from == 1 and outlet_node == 0:
        # Air loop has no return path - only check mass flow
        air_loop_conv.HVACMassFlowNotConverged[i_call] = False
        air_loop_conv.HVACHumRatNotConverged[i_call] = False
        air_loop_conv.HVACTempNotConverged[i_call] = False
        air_loop_conv.HVACEnergyNotConverged[i_call] = False
        
        tot_demand_side_mass_flow = 0.0
        tot_demand_side_min_avail = 0.0
        tot_demand_side_max_avail = 0.0
        
        air_to_zone_info = state.dataAirLoop.AirToZoneNodeInfo(air_loop_num)
        for dem_in in range(1, air_to_zone_info.NumSupplyNodes + 1):
            dem_in_node = air_to_zone_info.ZoneEquipSupplyNodeNum(dem_in)
            node = state.dataLoopNodes.Node(dem_in_node)
            tot_demand_side_mass_flow += node.MassFlowRate
            tot_demand_side_min_avail += node.MassFlowRateMinAvail
            tot_demand_side_max_avail += node.MassFlowRateMaxAvail
        
        tmp_real_arr[:] = air_loop_conv.HVACFlowDemandToSupplyTolValue[:]
        air_loop_conv.HVACFlowDemandToSupplyTolValue[0] = abs(tot_demand_side_mass_flow - this_inlet_node.MassFlowRate)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACFlowDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        
        if air_loop_conv.HVACFlowDemandToSupplyTolValue[0] > HVAC_FLOW_RATE_TOLER:
            air_loop_conv.HVACMassFlowNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        this_inlet_node.MassFlowRate = tot_demand_side_mass_flow
        this_inlet_node.MassFlowRateMinAvail = tot_demand_side_min_avail
        this_inlet_node.MassFlowRateMaxAvail = tot_demand_side_max_avail
        return
    
    # Calculate approximate energy difference across interface
    delta_energy = (HVAC_CP_APPROX * 
                    (state.dataLoopNodes.Node(outlet_node).MassFlowRate * 
                     state.dataLoopNodes.Node(outlet_node).Temp -
                     this_inlet_node.MassFlowRate * this_inlet_node.Temp))
    
    if called_from == 1 and outlet_node > 0:
        # AirSystemDemandSide with outlet node
        air_loop_conv.HVACMassFlowNotConverged[i_call] = False
        air_loop_conv.HVACHumRatNotConverged[i_call] = False
        air_loop_conv.HVACTempNotConverged[i_call] = False
        air_loop_conv.HVACEnergyNotConverged[i_call] = False
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            air_loop_conv.HVACCO2NotConverged[i_call] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            air_loop_conv.HVACGenContamNotConverged[i_call] = False
        
        tmp_real_arr[:] = air_loop_conv.HVACFlowDemandToSupplyTolValue[:]
        air_loop_conv.HVACFlowDemandToSupplyTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).MassFlowRate - this_inlet_node.MassFlowRate)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACFlowDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACFlowDemandToSupplyTolValue[0] > HVAC_FLOW_RATE_TOLER:
            air_loop_conv.HVACMassFlowNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACHumDemandToSupplyTolValue[:]
        air_loop_conv.HVACHumDemandToSupplyTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).HumRat - this_inlet_node.HumRat)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACHumDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACHumDemandToSupplyTolValue[0] > HVAC_HUM_RAT_TOLER:
            air_loop_conv.HVACHumRatNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACTempDemandToSupplyTolValue[:]
        air_loop_conv.HVACTempDemandToSupplyTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Temp - this_inlet_node.Temp)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACTempDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACTempDemandToSupplyTolValue[0] > HVAC_TEMPERATURE_TOLER:
            air_loop_conv.HVACTempNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnergyDemandToSupplyTolValue[:]
        air_loop_conv.HVACEnergyDemandToSupplyTolValue[0] = abs(delta_energy)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnergyDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if abs(delta_energy) > HVAC_ENERGY_TOLER:
            air_loop_conv.HVACEnergyNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnthalpyDemandToSupplyTolValue[:]
        air_loop_conv.HVACEnthalpyDemandToSupplyTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Enthalpy - this_inlet_node.Enthalpy)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnthalpyDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACEnthalpyDemandToSupplyTolValue[0] > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACPressureDemandToSupplyTolValue[:]
        air_loop_conv.HVACPressureDemandToSupplyTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Press - this_inlet_node.Press)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACPressureDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACPressureDemandToSupplyTolValue[0] > HVAC_PRESS_TOLER:
            out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            tmp_real_arr[:] = air_loop_conv.HVACCO2DemandToSupplyTolValue[:]
            air_loop_conv.HVACCO2DemandToSupplyTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).CO2 - this_inlet_node.CO2)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACCO2DemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACCO2DemandToSupplyTolValue[0] > HVAC_CO2_TOLER:
                air_loop_conv.HVACCO2NotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            tmp_real_arr[:] = air_loop_conv.HVACGenContamDemandToSupplyTolValue[:]
            air_loop_conv.HVACGenContamDemandToSupplyTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).GenContam - this_inlet_node.GenContam)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACGenContamDemandToSupplyTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACGenContamDemandToSupplyTolValue[0] > HVAC_GENCONTAM_TOLER:
                air_loop_conv.HVACGenContamNotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
    
    elif called_from == 2:
        # AirSystemSupplySideDeck1
        air_loop_conv.HVACMassFlowNotConverged[i_call] = False
        air_loop_conv.HVACHumRatNotConverged[i_call] = False
        air_loop_conv.HVACTempNotConverged[i_call] = False
        air_loop_conv.HVACEnergyNotConverged[i_call] = False
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            air_loop_conv.HVACCO2NotConverged[i_call] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            air_loop_conv.HVACGenContamNotConverged[i_call] = False
        
        tmp_real_arr[:] = air_loop_conv.HVACFlowSupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACFlowSupplyDeck1ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).MassFlowRate - this_inlet_node.MassFlowRate)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACFlowSupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACFlowSupplyDeck1ToDemandTolValue[0] > HVAC_FLOW_RATE_TOLER:
            air_loop_conv.HVACMassFlowNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACHumSupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACHumSupplyDeck1ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).HumRat - this_inlet_node.HumRat)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACHumSupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACHumSupplyDeck1ToDemandTolValue[0] > HVAC_HUM_RAT_TOLER:
            air_loop_conv.HVACHumRatNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACTempSupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACTempSupplyDeck1ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Temp - this_inlet_node.Temp)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACTempSupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACTempSupplyDeck1ToDemandTolValue[0] > HVAC_TEMPERATURE_TOLER:
            air_loop_conv.HVACTempNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnergySupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACEnergySupplyDeck1ToDemandTolValue[0] = delta_energy
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnergySupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if abs(delta_energy) > HVAC_ENERGY_TOLER:
            air_loop_conv.HVACEnergyNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnthalpySupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACEnthalpySupplyDeck1ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Enthalpy - this_inlet_node.Enthalpy)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnthalpySupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACEnthalpySupplyDeck1ToDemandTolValue[0] > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACPressureSupplyDeck1ToDemandTolValue[:]
        air_loop_conv.HVACPressureSupplyDeck1ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Press - this_inlet_node.Press)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACPressureSupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACPressureSupplyDeck1ToDemandTolValue[0] > HVAC_PRESS_TOLER:
            out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            tmp_real_arr[:] = air_loop_conv.HVACCO2SupplyDeck1ToDemandTolValue[:]
            air_loop_conv.HVACCO2SupplyDeck1ToDemandTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).CO2 - this_inlet_node.CO2)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACCO2SupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACCO2SupplyDeck1ToDemandTolValue[0] > HVAC_CO2_TOLER:
                air_loop_conv.HVACCO2NotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            tmp_real_arr[:] = air_loop_conv.HVACGenContamSupplyDeck1ToDemandTolValue[:]
            air_loop_conv.HVACGenContamSupplyDeck1ToDemandTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).GenContam - this_inlet_node.GenContam)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACGenContamSupplyDeck1ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACGenContamSupplyDeck1ToDemandTolValue[0] > HVAC_GENCONTAM_TOLER:
                air_loop_conv.HVACGenContamNotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
    
    elif called_from == 3:
        # AirSystemSupplySideDeck2
        air_loop_conv.HVACMassFlowNotConverged[i_call] = False
        air_loop_conv.HVACHumRatNotConverged[i_call] = False
        air_loop_conv.HVACTempNotConverged[i_call] = False
        air_loop_conv.HVACEnergyNotConverged[i_call] = False
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            air_loop_conv.HVACCO2NotConverged[i_call] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            air_loop_conv.HVACGenContamNotConverged[i_call] = False
        
        tmp_real_arr[:] = air_loop_conv.HVACFlowSupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACFlowSupplyDeck2ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).MassFlowRate - this_inlet_node.MassFlowRate)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACFlowSupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACFlowSupplyDeck2ToDemandTolValue[0] > HVAC_FLOW_RATE_TOLER:
            air_loop_conv.HVACMassFlowNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACHumSupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACHumSupplyDeck2ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).HumRat - this_inlet_node.HumRat)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACHumSupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACHumSupplyDeck2ToDemandTolValue[0] > HVAC_HUM_RAT_TOLER:
            air_loop_conv.HVACHumRatNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACTempSupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACTempSupplyDeck2ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Temp - this_inlet_node.Temp)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACTempSupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACTempSupplyDeck2ToDemandTolValue[0] > HVAC_TEMPERATURE_TOLER:
            air_loop_conv.HVACTempNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnergySupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACEnergySupplyDeck2ToDemandTolValue[0] = delta_energy
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnergySupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if abs(delta_energy) > HVAC_ENERGY_TOLER:
            air_loop_conv.HVACEnergyNotConverged[i_call] = True
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACEnthalpySupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACEnthalpySupplyDeck2ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Enthalpy - this_inlet_node.Enthalpy)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACEnthalpySupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACEnthalpySupplyDeck2ToDemandTolValue[0] > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag[0] = True
        
        tmp_real_arr[:] = air_loop_conv.HVACPressueSupplyDeck2ToDemandTolValue[:]
        air_loop_conv.HVACPressueSupplyDeck2ToDemandTolValue[0] = abs(
            state.dataLoopNodes.Node(outlet_node).Press - this_inlet_node.Press)
        for log_index in range(1, CONVER_LOG_STACK_DEPTH):
            air_loop_conv.HVACPressueSupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
        if air_loop_conv.HVACPressueSupplyDeck2ToDemandTolValue[0] > HVAC_PRESS_TOLER:
            out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            tmp_real_arr[:] = air_loop_conv.HVACCO2SupplyDeck2ToDemandTolValue[:]
            air_loop_conv.HVACCO2SupplyDeck2ToDemandTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).CO2 - this_inlet_node.CO2)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACCO2SupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACCO2SupplyDeck2ToDemandTolValue[0] > HVAC_CO2_TOLER:
                air_loop_conv.HVACCO2NotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
        
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            tmp_real_arr[:] = air_loop_conv.HVACGenContamSupplyDeck2ToDemandTolValue[:]
            air_loop_conv.HVACGenContamSupplyDeck2ToDemandTolValue[0] = abs(
                state.dataLoopNodes.Node(outlet_node).GenContam - this_inlet_node.GenContam)
            for log_index in range(1, CONVER_LOG_STACK_DEPTH):
                air_loop_conv.HVACGenContamSupplyDeck2ToDemandTolValue[log_index] = tmp_real_arr[log_index - 1]
            if air_loop_conv.HVACGenContamSupplyDeck2ToDemandTolValue[0] > HVAC_GENCONTAM_TOLER:
                air_loop_conv.HVACGenContamNotConverged[i_call] = True
                out_of_tolerance_flag[0] = True
    
    # Always update inlet conditions
    this_inlet_node.Temp = state.dataLoopNodes.Node(outlet_node).Temp
    this_inlet_node.MassFlowRate = state.dataLoopNodes.Node(outlet_node).MassFlowRate
    this_inlet_node.MassFlowRateMinAvail = state.dataLoopNodes.Node(outlet_node).MassFlowRateMinAvail
    this_inlet_node.MassFlowRateMaxAvail = state.dataLoopNodes.Node(outlet_node).MassFlowRateMaxAvail
    this_inlet_node.Quality = state.dataLoopNodes.Node(outlet_node).Quality
    this_inlet_node.Press = state.dataLoopNodes.Node(outlet_node).Press
    this_inlet_node.Enthalpy = state.dataLoopNodes.Node(outlet_node).Enthalpy
    this_inlet_node.HumRat = state.dataLoopNodes.Node(outlet_node).HumRat
    
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        this_inlet_node.CO2 = state.dataLoopNodes.Node(outlet_node).CO2
    
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        this_inlet_node.GenContam = state.dataLoopNodes.Node(outlet_node).GenContam


def update_plant_loop_interface(state: EnergyPlusData,
                                plant_loc: PlantLocation,
                                this_loop_side_outlet_node: int,
                                other_loop_side_inlet_node: int,
                                out_of_tolerance_flag: List[bool],
                                common_pipe_type: CommonPipeType) -> None:
    """Update plant loop interface"""
    loop_num = plant_loc.loopNum
    this_loop_side_num = plant_loc.loopSideNum
    convergence = state.dataConvergeParams.PlantConvergence(loop_num)
    
    convergence.PlantMassFlowNotConverged = False
    convergence.PlantTempNotConverged = False
    
    this_loop_side_inlet_node = state.dataPlnt.PlantLoop(loop_num).LoopSide(this_loop_side_num).NodeNumIn
    
    old_other_loop_side_inlet_mdot = state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate
    old_tank_outlet_temp = state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp
    
    cp = state.dataPlnt.PlantLoop(loop_num).glycol.getSpecificHeat(state, old_tank_outlet_temp, "UpdatePlantLoopInterface")
    
    state.dataLoopNodes.Node(other_loop_side_inlet_node).Enthalpy = (
        cp * state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp)
    
    flow_demand_to_supply_tol = convergence.PlantFlowDemandToSupplyTolValue
    flow_supply_to_demand_tol = convergence.PlantFlowSupplyToDemandTolValue
    
    if common_pipe_type == CommonPipeType.Single or common_pipe_type == CommonPipeType.TwoWay:
        mixed_outlet_temp = 0.0
        tank_outlet_temp = 0.0
        update_common_pipe(state, plant_loc, common_pipe_type, [mixed_outlet_temp])
        state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp = mixed_outlet_temp
        tank_outlet_temp = mixed_outlet_temp
        
        if this_loop_side_num == LoopSideLocation.Demand:
            rshift1(flow_demand_to_supply_tol)
            flow_demand_to_supply_tol[0] = abs(
                old_other_loop_side_inlet_mdot - state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate)
            if flow_demand_to_supply_tol[0] > PLANT_FLOW_RATE_TOLER:
                convergence.PlantMassFlowNotConverged = True
        else:
            rshift1(flow_supply_to_demand_tol)
            flow_supply_to_demand_tol[0] = abs(
                old_other_loop_side_inlet_mdot - state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate)
            if flow_supply_to_demand_tol[0] > PLANT_FLOW_RATE_TOLER:
                convergence.PlantMassFlowNotConverged = True
        
        state.dataLoopNodes.Node(this_loop_side_inlet_node).MassFlowRate = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRate)
        state.dataLoopNodes.Node(this_loop_side_inlet_node).MassFlowRateMinAvail = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRateMinAvail)
        state.dataLoopNodes.Node(this_loop_side_inlet_node).MassFlowRateMaxAvail = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRateMaxAvail)
    
    else:
        tank_outlet_temp = 0.0
        update_half_loop_inlet_temp(state, loop_num, this_loop_side_num, [tank_outlet_temp])
        state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp = tank_outlet_temp
        
        if this_loop_side_num == LoopSideLocation.Demand:
            rshift1(flow_demand_to_supply_tol)
            flow_demand_to_supply_tol[0] = abs(
                state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRate -
                state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate)
            if flow_demand_to_supply_tol[0] > PLANT_FLOW_RATE_TOLER:
                convergence.PlantMassFlowNotConverged = True
        else:
            rshift1(flow_supply_to_demand_tol)
            flow_supply_to_demand_tol[0] = abs(
                state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRate -
                state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate)
            if flow_supply_to_demand_tol[0] > PLANT_FLOW_RATE_TOLER:
                convergence.PlantMassFlowNotConverged = True
        
        state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRate = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRate)
        state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRateMinAvail = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRateMinAvail)
        state.dataLoopNodes.Node(other_loop_side_inlet_node).MassFlowRateMaxAvail = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).MassFlowRateMaxAvail)
        state.dataLoopNodes.Node(other_loop_side_inlet_node).Quality = (
            state.dataLoopNodes.Node(this_loop_side_outlet_node).Quality)
        
        if state.dataPlnt.PlantLoop(loop_num).HasPressureComponents:
            pass
        else:
            state.dataLoopNodes.Node(other_loop_side_inlet_node).Press = (
                state.dataLoopNodes.Node(this_loop_side_outlet_node).Press)
    
    if this_loop_side_num == LoopSideLocation.Demand:
        temp_demand_to_supply_tol = convergence.PlantTempDemandToSupplyTolValue
        rshift1(temp_demand_to_supply_tol)
        temp_demand_to_supply_tol[0] = abs(
            old_tank_outlet_temp - state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp)
        if temp_demand_to_supply_tol[0] > PLANT_TEMPERATURE_TOLER:
            convergence.PlantTempNotConverged = True
    else:
        temp_supply_to_demand_tol = convergence.PlantTempSupplyToDemandTolValue
        rshift1(temp_supply_to_demand_tol)
        temp_supply_to_demand_tol[0] = abs(
            old_tank_outlet_temp - state.dataLoopNodes.Node(other_loop_side_inlet_node).Temp)
        if temp_supply_to_demand_tol[0] > PLANT_TEMPERATURE_TOLER:
            convergence.PlantTempNotConverged = True
    
    if this_loop_side_num == LoopSideLocation.Demand:
        if convergence.PlantMassFlowNotConverged or convergence.PlantTempNotConverged:
            out_of_tolerance_flag[0] = True
    else:
        if convergence.PlantMassFlowNotConverged:
            out_of_tolerance_flag[0] = True


def update_half_loop_inlet_temp(state: EnergyPlusData,
                                loop_num: int,
                                tank_inlet_loop_side: LoopSideLocation,
                                tank_outlet_temp: List[float]) -> None:
    """Update half loop inlet temperature based on capacitance"""
    sys_time_elapsed = state.dataHVACGlobals.SysTimeElapsed
    
    frac_tot_loop_mass = 0.5
    
    loop_side_other = {LoopSideLocation.Supply: LoopSideLocation.Demand,
                       LoopSideLocation.Demand: LoopSideLocation.Supply}
    tank_outlet_loop_side = loop_side_other[tank_inlet_loop_side]
    
    tank_inlet_node = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_inlet_loop_side).NodeNumOut
    tank_inlet_temp = state.dataLoopNodes.Node(tank_inlet_node).Temp
    
    time_elapsed = ((state.dataGlobal.HourOfDay - 1) + 
                   state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + sys_time_elapsed)
    
    loop_side_obj = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_outlet_loop_side)
    if loop_side_obj.TimeElapsed != time_elapsed:
        loop_side_obj.LastTempInterfaceTankOutlet = loop_side_obj.TempInterfaceTankOutlet
        loop_side_obj.TimeElapsed = time_elapsed
    
    last_tank_outlet_temp = loop_side_obj.LastTempInterfaceTankOutlet
    
    cp = state.dataPlnt.PlantLoop(loop_num).glycol.getSpecificHeat(state, last_tank_outlet_temp, "UpdateHalfLoopInletTemp")
    
    time_step_seconds = state.dataHVACGlobals.TimeStepSysSec
    mass_flow_rate = state.dataLoopNodes.Node(tank_inlet_node).MassFlowRate
    pump_heat = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_outlet_loop_side).TotalPumpHeat
    this_tank_mass = frac_tot_loop_mass * state.dataPlnt.PlantLoop(loop_num).Mass
    
    if this_tank_mass <= 0.0:
        if mass_flow_rate > 0.0:
            tank_final_temp = tank_inlet_temp + pump_heat / (mass_flow_rate * cp)
            tank_average_temp = (tank_final_temp + last_tank_outlet_temp) / 2.0
        else:
            tank_final_temp = last_tank_outlet_temp
            tank_average_temp = last_tank_outlet_temp
    else:
        if mass_flow_rate > 0.0:
            mdot_cp = mass_flow_rate * cp
            mdot_cp_temp_in = mdot_cp * tank_inlet_temp
            tank_mass_cp = this_tank_mass * cp
            exponent_term = mdot_cp / tank_mass_cp * time_step_seconds
            
            if exponent_term >= 700.0:
                tank_final_temp = (mdot_cp * tank_inlet_temp + pump_heat) / mdot_cp
                tank_average_temp = (tank_mass_cp / mdot_cp * 
                                    (last_tank_outlet_temp - (mdot_cp_temp_in + pump_heat) / mdot_cp) / time_step_seconds +
                                    (mdot_cp_temp_in + pump_heat) / mdot_cp)
            else:
                tank_final_temp = ((last_tank_outlet_temp - (mdot_cp_temp_in + pump_heat) / mdot_cp) * 
                                  math.exp(-exponent_term) +
                                  (mdot_cp_temp_in + pump_heat) / (mass_flow_rate * cp))
                tank_average_temp = (tank_mass_cp / mdot_cp * 
                                    (last_tank_outlet_temp - (mdot_cp_temp_in + pump_heat) / mdot_cp) *
                                    (1.0 - math.exp(-exponent_term)) / time_step_seconds +
                                    (mdot_cp_temp_in + pump_heat) / mdot_cp)
        else:
            tank_final_temp = pump_heat / (this_tank_mass * cp) * time_step_seconds + last_tank_outlet_temp
            tank_average_temp = (tank_final_temp + last_tank_outlet_temp) / 2.0
    
    loop_side_obj.TempInterfaceTankOutlet = tank_final_temp
    loop_side_obj.LoopSideInlet_MdotCpDeltaT = (
        (tank_inlet_temp - tank_average_temp) * cp * mass_flow_rate)
    loop_side_obj.LoopSideInlet_McpDTdt = (
        (this_tank_mass * cp * (tank_final_temp - last_tank_outlet_temp)) / time_step_seconds)
    loop_side_obj.LoopSideInlet_TankTemp = tank_average_temp
    
    tank_outlet_temp[0] = tank_average_temp


def update_common_pipe(state: EnergyPlusData,
                      tank_inlet_plant_loc: PlantLocation,
                      common_pipe_type: CommonPipeType,
                      mixed_outlet_temp: List[float]) -> None:
    """Update common pipe temperatures and flow rates"""
    sys_time_elapsed = state.dataHVACGlobals.SysTimeElapsed
    
    loop_num = tank_inlet_plant_loc.loopNum
    tank_inlet_loop_side = tank_inlet_plant_loc.loopSideNum
    loop_side_other = {LoopSideLocation.Supply: LoopSideLocation.Demand,
                       LoopSideLocation.Demand: LoopSideLocation.Supply}
    tank_outlet_loop_side = loop_side_other[tank_inlet_plant_loc.loopSideNum]
    
    tank_inlet_node = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_inlet_loop_side).NodeNumOut
    tank_outlet_node = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_outlet_loop_side).NodeNumIn
    
    tank_inlet_temp = state.dataLoopNodes.Node(tank_inlet_node).Temp
    
    if tank_inlet_loop_side == LoopSideLocation.Demand:
        frac_tot_loop_mass = 0.25
    else:
        frac_tot_loop_mass = 0.75
    
    time_elapsed = ((state.dataGlobal.HourOfDay - 1) + 
                   state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + sys_time_elapsed)
    
    loop_side_obj = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_outlet_loop_side)
    if loop_side_obj.TimeElapsed != time_elapsed:
        loop_side_obj.LastTempInterfaceTankOutlet = loop_side_obj.TempInterfaceTankOutlet
        loop_side_obj.TimeElapsed = time_elapsed
    
    last_tank_outlet_temp = loop_side_obj.LastTempInterfaceTankOutlet
    
    cp = state.dataPlnt.PlantLoop(loop_num).glycol.getSpecificHeat(state, last_tank_outlet_temp, "UpdateCommonPipe")
    
    time_step_seconds = state.dataHVACGlobals.TimeStepSysSec
    mass_flow_rate = state.dataLoopNodes.Node(tank_inlet_node).MassFlowRate
    pump_heat = state.dataPlnt.PlantLoop(loop_num).LoopSide(tank_inlet_loop_side).TotalPumpHeat
    this_tank_mass = frac_tot_loop_mass * state.dataPlnt.PlantLoop(loop_num).Mass
    
    if this_tank_mass <= 0.0:
        if mass_flow_rate > 0.0:
            tank_final_temp = tank_inlet_temp + pump_heat / (mass_flow_rate * cp)
            tank_average_temp = (tank_final_temp + last_tank_outlet_temp) / 2.0
        else:
            tank_final_temp = last_tank_outlet_temp
            tank_average_temp = last_tank_outlet_temp
    else:
        if mass_flow_rate > 0.0:
            tank_final_temp = ((last_tank_outlet_temp - (mass_flow_rate * cp * tank_inlet_temp + pump_heat) / (mass_flow_rate * cp)) *
                              math.exp(-(mass_flow_rate * cp) / (this_tank_mass * cp) * time_step_seconds) +
                              (mass_flow_rate * cp * tank_inlet_temp + pump_heat) / (mass_flow_rate * cp))
            tank_average_temp = (((this_tank_mass * cp) / (mass_flow_rate * cp) *
                                 (last_tank_outlet_temp - (mass_flow_rate * cp * tank_inlet_temp + pump_heat) / (mass_flow_rate * cp)) *
                                 (1.0 - math.exp(-(mass_flow_rate * cp) / (this_tank_mass * cp) * time_step_seconds)) / time_step_seconds) +
                               (mass_flow_rate * cp * tank_inlet_temp + pump_heat) / (mass_flow_rate * cp))
        else:
            tank_final_temp = pump_heat / (this_tank_mass * cp) * time_step_seconds + last_tank_outlet_temp
            tank_average_temp = (tank_final_temp + last_tank_outlet_temp) / 2.0
    
    if common_pipe_type == CommonPipeType.Single:
        manage_single_common_pipe(state, loop_num, tank_outlet_loop_side, tank_average_temp, mixed_outlet_temp)
    elif common_pipe_type == CommonPipeType.TwoWay:
        tank_outlet_plant_loc = type('PlantLocation', (), 
                                    {'loopNum': loop_num, 'loopSideNum': tank_outlet_loop_side})()
        manage_two_way_common_pipe(state, tank_outlet_plant_loc, tank_average_temp)
        mixed_outlet_temp[0] = state.dataLoopNodes.Node(tank_outlet_node).Temp
    
    loop_side_obj.TempInterfaceTankOutlet = tank_final_temp
    loop_side_obj.LoopSideInlet_TankTemp = tank_average_temp


def manage_single_common_pipe(state: EnergyPlusData,
                              loop_num: int,
                              loop_side: LoopSideLocation,
                              tank_outlet_temp: float,
                              mixed_outlet_temp: List[float]) -> None:
    """Manage single common pipe flow and temperature"""
    if not state.dataHVACInterfaceMgr.CommonPipeSetupFinished:
        setup_common_pipes(state)
    
    plant_common_pipe = state.dataHVACInterfaceMgr.PlantCommonPipe[loop_num - 1]
    
    node_num_pri_in = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Supply).NodeNumIn
    node_num_pri_out = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Supply).NodeNumOut
    node_num_sec_in = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Demand).NodeNumIn
    node_num_sec_out = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Demand).NodeNumOut
    
    if plant_common_pipe.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        plant_common_pipe.Flow = 0.0
        plant_common_pipe.Temp = 0.0
        plant_common_pipe.FlowDir = NoRecircFlow
        plant_common_pipe.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        plant_common_pipe.MyEnvrnFlag = True
    
    mdot_sec = state.dataLoopNodes.Node(node_num_sec_out).MassFlowRate
    mdot_pri = state.dataLoopNodes.Node(node_num_pri_out).MassFlowRate
    
    if loop_side == LoopSideLocation.Supply:
        temp_sec_out_tank_out = tank_outlet_temp
        temp_pri_out_tank_out = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Demand).LoopSideInlet_TankTemp
    else:
        temp_pri_out_tank_out = tank_outlet_temp
        temp_sec_out_tank_out = state.dataPlnt.PlantLoop(loop_num).LoopSide(LoopSideLocation.Supply).LoopSideInlet_TankTemp
    
    if mdot_pri > mdot_sec:
        mdot_pri_rc_leg = mdot_pri - mdot_sec
        if mdot_pri_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
            mdot_pri_rc_leg = 0.0
            cp_flow_dir = NoRecircFlow
        else:
            cp_flow_dir = PrimaryRecirc
        mdot_sec_rc_leg = 0.0
        common_pipe_temp = temp_pri_out_tank_out
    elif mdot_pri < mdot_sec:
        mdot_sec_rc_leg = mdot_sec - mdot_pri
        if mdot_sec_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
            mdot_sec_rc_leg = 0.0
            cp_flow_dir = NoRecircFlow
        else:
            cp_flow_dir = SecondaryRecirc
        mdot_pri_rc_leg = 0.0
        common_pipe_temp = temp_sec_out_tank_out
    else:
        mdot_pri_rc_leg = 0.0
        mdot_sec_rc_leg = 0.0
        cp_flow_dir = NoRecircFlow
        common_pipe_temp = (temp_pri_out_tank_out + temp_sec_out_tank_out) / 2.0
    
    if mdot_sec > 0.0:
        temp_sec_inlet = ((mdot_pri * temp_pri_out_tank_out + mdot_sec_rc_leg * temp_sec_out_tank_out -
                          mdot_pri_rc_leg * temp_pri_out_tank_out) / mdot_sec)
    else:
        temp_sec_inlet = temp_pri_out_tank_out
    
    if mdot_pri > 0.0:
        temp_pri_inlet = ((mdot_sec * temp_sec_out_tank_out + mdot_pri_rc_leg * temp_pri_out_tank_out -
                          mdot_sec_rc_leg * temp_sec_out_tank_out) / mdot_pri)
    else:
        temp_pri_inlet = temp_sec_out_tank_out
    
    plant_common_pipe.Flow = max(mdot_pri_rc_leg, mdot_sec_rc_leg)
    plant_common_pipe.Temp = common_pipe_temp
    plant_common_pipe.FlowDir = cp_flow_dir
    state.dataLoopNodes.Node(node_num_sec_in).Temp = temp_sec_inlet
    state.dataLoopNodes.Node(node_num_pri_in).Temp = temp_pri_inlet
    
    if loop_side == LoopSideLocation.Supply:
        mixed_outlet_temp[0] = temp_pri_inlet
    else:
        mixed_outlet_temp[0] = temp_sec_inlet


def manage_two_way_common_pipe(state: EnergyPlusData,
                               plant_loc: PlantLocation,
                               tank_outlet_temp: float) -> None:
    """Manage two-way common pipe with iterative solution"""
    if not state.dataHVACInterfaceMgr.CommonPipeSetupFinished:
        setup_common_pipes(state)
    
    plant_common_pipe = state.dataHVACInterfaceMgr.PlantCommonPipe[plant_loc.loopNum - 1]
    this_plant_loop = state.dataPlnt.PlantLoop(plant_loc.loopNum)
    
    node_num_pri_in = this_plant_loop.LoopSide(LoopSideLocation.Supply).NodeNumIn
    node_num_pri_out = this_plant_loop.LoopSide(LoopSideLocation.Supply).NodeNumOut
    node_num_sec_in = this_plant_loop.LoopSide(LoopSideLocation.Demand).NodeNumIn
    node_num_sec_out = this_plant_loop.LoopSide(LoopSideLocation.Demand).NodeNumOut
    
    if plant_common_pipe.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        plant_common_pipe.PriToSecFlow = 0.0
        plant_common_pipe.SecToPriFlow = 0.0
        plant_common_pipe.PriCPLegFlow = 0.0
        plant_common_pipe.SecCPLegFlow = 0.0
        plant_common_pipe.MyEnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        plant_common_pipe.MyEnvrnFlag = True
    
    mdot_sec = state.dataLoopNodes.Node(node_num_sec_out).MassFlowRate
    temp_cp_primary_cntrl_set_point = state.dataLoopNodes.Node(node_num_pri_in).TempSetPoint
    temp_cp_secondary_cntrl_set_point = state.dataLoopNodes.Node(node_num_sec_in).TempSetPoint
    
    mdot_pri_to_sec = plant_common_pipe.PriToSecFlow
    mdot_pri_rc_leg = plant_common_pipe.PriCPLegFlow
    mdot_sec_rc_leg = plant_common_pipe.SecCPLegFlow
    temp_sec_inlet = state.dataLoopNodes.Node(node_num_sec_in).Temp
    temp_pri_inlet = state.dataLoopNodes.Node(node_num_pri_in).Temp
    mdot_pri = state.dataLoopNodes.Node(node_num_pri_out).MassFlowRate
    
    if plant_loc.loopSideNum == LoopSideLocation.Supply:
        temp_sec_out_tank_out = tank_outlet_temp
        temp_pri_out_tank_out = this_plant_loop.LoopSide(LoopSideLocation.Demand).LoopSideInlet_TankTemp
    else:
        temp_pri_out_tank_out = tank_outlet_temp
        temp_sec_out_tank_out = this_plant_loop.LoopSide(LoopSideLocation.Supply).LoopSideInlet_TankTemp
    
    # Determine calling case
    if plant_loc.loopSideNum == LoopSideLocation.Supply:
        if (this_plant_loop.LoopSide(LoopSideLocation.Supply).InletNodeSetPt and 
            not this_plant_loop.LoopSide(LoopSideLocation.Demand).InletNodeSetPt):
            cur_calling_case = 0  # SupplyLedPrimaryInlet
        elif (not this_plant_loop.LoopSide(LoopSideLocation.Supply).InletNodeSetPt and
              this_plant_loop.LoopSide(LoopSideLocation.Demand).InletNodeSetPt):
            cur_calling_case = 1  # DemandLedPrimaryInlet
        else:
            cur_calling_case = 0
    else:
        if (this_plant_loop.LoopSide(LoopSideLocation.Supply).InletNodeSetPt and 
            not this_plant_loop.LoopSide(LoopSideLocation.Demand).InletNodeSetPt):
            cur_calling_case = 2  # SupplyLedSecondaryInlet
        elif (not this_plant_loop.LoopSide(LoopSideLocation.Supply).InletNodeSetPt and
              this_plant_loop.LoopSide(LoopSideLocation.Demand).InletNodeSetPt):
            cur_calling_case = 3  # DemandLedSecondaryInlet
        else:
            cur_calling_case = 2
    
    if cur_calling_case in [0, 2]:  # SupplyLedPrimaryInlet or SupplyLedSecondaryInlet
        for loop_iter in range(8):
            if abs(temp_sec_out_tank_out - temp_cp_primary_cntrl_set_point) > PLANT_DELTA_TEMP_TOL:
                mdot_pri_to_sec = (mdot_pri_rc_leg * (temp_cp_primary_cntrl_set_point - temp_pri_out_tank_out) /
                                  (temp_sec_out_tank_out - temp_cp_primary_cntrl_set_point))
                if mdot_pri_to_sec < PLANT_MASS_FLOW_TOLERANCE:
                    mdot_pri_to_sec = 0.0
                if mdot_pri_to_sec > mdot_sec:
                    mdot_pri_to_sec = mdot_sec
            else:
                mdot_pri_to_sec = mdot_sec
            
            mdot_pri_rc_leg = mdot_pri - mdot_pri_to_sec
            if mdot_pri_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
                mdot_pri_rc_leg = 0.0
            
            mdot_sec_rc_leg = mdot_sec - mdot_pri_to_sec
            if mdot_sec_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
                mdot_sec_rc_leg = 0.0
            
            if (mdot_pri_to_sec + mdot_sec_rc_leg) > PLANT_MASS_FLOW_TOLERANCE:
                temp_sec_inlet = ((mdot_pri_to_sec * temp_pri_out_tank_out + 
                                  mdot_sec_rc_leg * temp_sec_out_tank_out) /
                                 (mdot_pri_to_sec + mdot_sec_rc_leg))
            else:
                temp_sec_inlet = temp_pri_out_tank_out
            
            if (plant_common_pipe.SupplySideInletPumpType == FlowType.Variable and cur_calling_case == 0):
                if abs(temp_cp_primary_cntrl_set_point) > PLANT_DELTA_TEMP_TOL:
                    mdot_pri = ((mdot_pri_rc_leg * temp_pri_out_tank_out + 
                                mdot_pri_to_sec * temp_sec_out_tank_out) / temp_cp_primary_cntrl_set_point)
                    if mdot_pri < PLANT_MASS_FLOW_TOLERANCE:
                        mdot_pri = 0.0
                else:
                    mdot_pri = mdot_sec
            
            if (mdot_pri_to_sec + mdot_pri_rc_leg) > PLANT_MASS_FLOW_TOLERANCE:
                temp_pri_inlet = ((mdot_pri_to_sec * temp_sec_out_tank_out + 
                                  mdot_pri_rc_leg * temp_pri_out_tank_out) /
                                 (mdot_pri_to_sec + mdot_pri_rc_leg))
            else:
                temp_pri_inlet = temp_sec_out_tank_out
    
    else:  # DemandLedPrimaryInlet or DemandLedSecondaryInlet
        for loop_iter in range(4):
            if abs(temp_pri_out_tank_out - temp_sec_out_tank_out) > PLANT_DELTA_TEMP_TOL:
                mdot_pri_to_sec = (mdot_sec * (temp_cp_secondary_cntrl_set_point - temp_sec_out_tank_out) /
                                  (temp_pri_out_tank_out - temp_sec_out_tank_out))
                if mdot_pri_to_sec < PLANT_MASS_FLOW_TOLERANCE:
                    mdot_pri_to_sec = 0.0
                if mdot_pri_to_sec > mdot_sec:
                    mdot_pri_to_sec = mdot_sec
            else:
                mdot_pri_to_sec = mdot_sec
            
            if (mdot_pri_to_sec + mdot_pri_rc_leg) > PLANT_MASS_FLOW_TOLERANCE:
                temp_pri_inlet = ((mdot_pri_to_sec * temp_sec_out_tank_out + 
                                  mdot_pri_rc_leg * temp_pri_out_tank_out) /
                                 (mdot_pri_to_sec + mdot_pri_rc_leg))
            else:
                temp_pri_inlet = temp_sec_out_tank_out
            
            if (plant_common_pipe.SupplySideInletPumpType == FlowType.Variable and cur_calling_case == 1):
                if abs(temp_pri_out_tank_out - temp_pri_inlet) > PLANT_DELTA_TEMP_TOL:
                    mdot_pri = (mdot_sec * (temp_cp_secondary_cntrl_set_point - temp_sec_out_tank_out) /
                               (temp_pri_out_tank_out - temp_pri_inlet))
                    if mdot_pri < PLANT_MASS_FLOW_TOLERANCE:
                        mdot_pri = 0.0
                else:
                    mdot_pri = mdot_sec
            
            mdot_sec_rc_leg = mdot_sec - mdot_pri_to_sec
            if mdot_sec_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
                mdot_sec_rc_leg = 0.0
            
            mdot_pri_rc_leg = mdot_pri - mdot_pri_to_sec
            if mdot_pri_rc_leg < PLANT_MASS_FLOW_TOLERANCE:
                mdot_pri_rc_leg = 0.0
            
            if (mdot_pri_to_sec + mdot_sec_rc_leg) > PLANT_MASS_FLOW_TOLERANCE:
                temp_sec_inlet = ((mdot_pri_to_sec * temp_pri_out_tank_out + 
                                  mdot_sec_rc_leg * temp_sec_out_tank_out) /
                                 (mdot_pri_to_sec + mdot_sec_rc_leg))
            else:
                temp_sec_inlet = temp_pri_out_tank_out
    
    plant_common_pipe.PriToSecFlow = mdot_pri_to_sec
    plant_common_pipe.SecToPriFlow = mdot_pri_to_sec
    plant_common_pipe.PriCPLegFlow = mdot_pri_rc_leg
    plant_common_pipe.SecCPLegFlow = mdot_sec_rc_leg
    state.dataLoopNodes.Node(node_num_sec_in).Temp = temp_sec_inlet
    state.dataLoopNodes.Node(node_num_pri_in).Temp = temp_pri_inlet


def setup_common_pipes(state: EnergyPlusData) -> None:
    """Set up common pipes and output variables"""
    state.dataHVACInterfaceMgr.PlantCommonPipe = [
        CommonPipeData() for _ in range(state.dataPlnt.TotNumLoops)
    ]
    
    for cur_loop_num in range(1, state.dataPlnt.TotNumLoops + 1):
        this_plant_loop = state.dataPlnt.PlantLoop(cur_loop_num)
        this_common_pipe = state.dataHVACInterfaceMgr.PlantCommonPipe[cur_loop_num - 1]
        
        first_demand_component_type = this_plant_loop.LoopSide(LoopSideLocation.Demand).Branch[0].Comp[0].Type
        first_supply_component_type = this_plant_loop.LoopSide(LoopSideLocation.Supply).Branch[0].Comp[0].Type
        
        if this_plant_loop.CommonPipeType == CommonPipeType.No:
            this_common_pipe.CommonPipeType = CommonPipeType.No
        elif this_plant_loop.CommonPipeType == CommonPipeType.Single:
            this_common_pipe.CommonPipeType = CommonPipeType.Single
        elif this_plant_loop.CommonPipeType == CommonPipeType.TwoWay:
            this_common_pipe.CommonPipeType = CommonPipeType.TwoWay
            
            if first_supply_component_type == 1:  # PumpConstantSpeed
                this_common_pipe.SupplySideInletPumpType = FlowType.Constant
            elif first_supply_component_type == 2:  # PumpVariableSpeed
                this_common_pipe.SupplySideInletPumpType = FlowType.Variable
            
            if first_demand_component_type == 1:  # PumpConstantSpeed
                this_common_pipe.DemandSideInletPumpType = FlowType.Constant
            elif first_demand_component_type == 2:  # PumpVariableSpeed
                this_common_pipe.DemandSideInletPumpType = FlowType.Variable
    
    state.dataHVACInterfaceMgr.CommonPipeSetupFinished = True
