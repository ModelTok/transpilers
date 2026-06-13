from typing import Optional, Protocol, List, Any
from dataclasses import dataclass, field
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state.data_plant_valves, state.data_input_processing, state.data_loop_nodes, 
#                 state.data_plnt, state.data_global (BeginEnvrnFlag, KickOffSimulation)
# PlantComponent: base class for TemperValveData (simulate, getDesignCapacities, oneTimeInit, oneTimeInit_new)
# PlantLocation: location identifier with loop_num, side attributes
# Node module: GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
# DataPlant: PlantEquipmentType, FlowLock, ScanPlantLoopsForObject, PlantEquipmentTypeIsPump
# DataBranchAirLoopPlant: ControlType
# InputProcessor: getNumObjectsFound, getObjectItem
# NodeInputManager/Node functions: GetOnlySingleNode, TestCompSet
# OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# PlantUtilities: SafeCopyPlantNode, SetComponentFlowRate, InitComponentNodes
# UtilityRoutines: ShowFatalError, ShowSevereError, ShowContinueError, format
# Constant: Units

@dataclass
class PlantLocation:
    loop_num: int = 0
    loop_side_num: int = 0
    branch_num: int = 0
    comp_num: int = 0
    side: Optional[Any] = None

@dataclass
class TemperValveData:
    name: str = ""
    plt_inlet_node_num: int = 0
    plt_outlet_node_num: int = 0
    plt_stream2_node_num: int = 0
    plt_setpoint_node_num: int = 0
    plt_pump_outlet_node_num: int = 0
    environment_init: bool = True
    flow_div_fract: float = 0.0
    stream2_source_temp: float = 0.0
    inlet_temp: float = 0.0
    setpoint_temp: float = 0.0
    mixed_mass_flow_rate: float = 0.0
    plant_loc: PlantLocation = field(default_factory=PlantLocation)
    comp_delayed_init_flag: bool = True

    @staticmethod
    def factory(state: Any, object_name: str) -> Optional['TemperValveData']:
        if state.data_plant_valves.get_tempering_valves:
            get_plant_valves_input(state)
            state.data_plant_valves.get_tempering_valves = False
        
        for valve in state.data_plant_valves.temper_valve:
            if valve.name == object_name:
                return valve
        
        from EnergyPlus.UtilityRoutines import ShowFatalError, format as ep_format
        ShowFatalError(state, ep_format("TemperValveDataFactory: Error getting inputs for valve named: {}", object_name))
        return None

    def simulate(self, state: Any, called_from_location: Any, first_hvac_iteration: bool, 
                 cur_load: float, run_flag: bool) -> None:
        self.initialize(state)
        self.calculate(state)
        
        from EnergyPlus.PlantUtilities import SafeCopyPlantNode, SetComponentFlowRate
        SafeCopyPlantNode(state, self.plt_inlet_node_num, self.plt_outlet_node_num)
        mdot = self.mixed_mass_flow_rate * self.flow_div_fract
        if self.plant_loc.loop_num > 0:
            SetComponentFlowRate(state, mdot, self.plt_inlet_node_num, self.plt_outlet_node_num, self.plant_loc)

    def get_design_capacities(self, state: Any, called_from_location: Any) -> tuple:
        max_load = 0.0
        min_load = 0.0
        opt_load = 0.0
        return (max_load, min_load, opt_load)

    def initialize(self, state: Any) -> None:
        inlet_node = self.plt_inlet_node_num
        outlet_node = self.plt_outlet_node_num
        strm2_node = self.plt_stream2_node_num
        set_pnt_node = self.plt_setpoint_node_num
        pump_out_node = self.plt_pump_outlet_node_num

        if state.data_plant_valves.one_time_init_flag:
            state.data_plant_valves.one_time_init_flag = False
        else:
            if self.comp_delayed_init_flag:
                from EnergyPlus.PlantUtilities import ScanPlantLoopsForObject
                from EnergyPlus.DataPlant import PlantEquipmentType
                from EnergyPlus.UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, format as ep_format
                
                err_flag = False
                ScanPlantLoopsForObject(state, self.name, PlantEquipmentType.ValveTempering, self.plant_loc, err_flag)
                
                if err_flag:
                    ShowFatalError(state, "InitPlantValves: Program terminated due to previous condition(s).")
                
                errors_found = False
                in_node_on_splitter = False
                pump_out_node_okay = False
                two_branches_betwn = False
                set_point_node_okay = False
                stream2_node_okay = False
                is_branch_active = False

                for this_plant_loop in state.data_plnt.plant_loop:
                    for this_loop_side in this_plant_loop.loop_side:
                        branch_ctr = 0
                        for this_branch in this_loop_side.branch:
                            branch_ctr += 1
                            for this_comp in this_branch.comp:
                                from EnergyPlus.DataPlant import PlantEquipmentType
                                if (this_comp.type == PlantEquipmentType.ValveTempering and 
                                    this_comp.name == self.name):
                                    
                                    from EnergyPlus.DataBranchAirLoopPlant import ControlType
                                    if this_branch.control_type == ControlType.Active:
                                        is_branch_active = True
                                    
                                    if this_loop_side.splitter and hasattr(this_loop_side.splitter, 'node_num_out'):
                                        if this_loop_side.splitter.node_num_out:
                                            if self.plt_inlet_node_num in this_loop_side.splitter.node_num_out:
                                                in_node_on_splitter = True
                                        
                                        if this_loop_side.splitter.total_outlet_nodes == 2:
                                            two_branches_betwn = True
                                    
                                    if this_loop_side.mixer and hasattr(this_loop_side.mixer, 'node_num_in'):
                                        if self.plt_stream2_node_num in this_loop_side.mixer.node_num_in:
                                            inner_branch_ctr = 0
                                            for this_inner_branch in this_loop_side.branch:
                                                inner_branch_ctr += 1
                                                if branch_ctr == inner_branch_ctr:
                                                    continue
                                                for this_inner_comp in this_inner_branch.comp:
                                                    if this_inner_comp.node_num_out == self.plt_stream2_node_num:
                                                        stream2_node_okay = True
                                    
                                    for this_inner_branch in this_loop_side.branch:
                                        if this_inner_branch.node_num_out == self.plt_pump_outlet_node_num:
                                            for this_inner_comp in this_inner_branch.comp:
                                                from EnergyPlus.DataPlant import PlantEquipmentTypeIsPump
                                                if PlantEquipmentTypeIsPump[int(this_inner_comp.type)]:
                                                    pump_out_node_okay = True
                                    
                                    if this_plant_loop.temp_set_point_node_num == self.plt_setpoint_node_num:
                                        set_point_node_okay = True

                if not is_branch_active:
                    ShowSevereError(state, "TemperingValve object needs to be on an ACTIVE branch")
                    errors_found = True
                
                if not in_node_on_splitter:
                    ShowSevereError(state, "TemperingValve object needs to be between a Splitter and Mixer")
                    errors_found = True
                
                if not pump_out_node_okay:
                    ShowSevereError(state, "TemperingValve object needs to reference a node that is the outlet of a pump on its loop")
                    errors_found = True
                
                if not two_branches_betwn:
                    ShowSevereError(state, "TemperingValve object needs exactly two branches between a Splitter and Mixer")
                    errors_found = True
                
                if not set_point_node_okay:
                    ShowSevereError(state, "TemperingValve object setpoint node not valid.  Check Setpoint manager for Plant Loop Temp Setpoint")
                    errors_found = True
                
                if not stream2_node_okay:
                    ShowSevereError(state, "TemperingValve object stream 2 source node not valid.")
                    ShowContinueError(state, "Check that node is a component outlet, enters a mixer, and on the other branch")
                    errors_found = True
                
                if errors_found:
                    ShowFatalError(state, ep_format("Errors found in input, TemperingValve object {}", self.name))
                
                self.comp_delayed_init_flag = False

        if state.data_global.begin_envr_flag and self.environment_init:
            if inlet_node > 0 and outlet_node > 0:
                from EnergyPlus.PlantUtilities import InitComponentNodes
                InitComponentNodes(state, 0.0, state.data_loop_nodes.node[pump_out_node - 1].mass_flow_rate_max,
                                   self.plt_inlet_node_num, self.plt_outlet_node_num)
            self.environment_init = False
        
        if not state.data_global.begin_envr_flag:
            self.environment_init = True
        
        if inlet_node > 0:
            self.inlet_temp = state.data_loop_nodes.node[inlet_node - 1].temp
        if strm2_node > 0:
            self.stream2_source_temp = state.data_loop_nodes.node[strm2_node - 1].temp
        if set_pnt_node > 0:
            self.setpoint_temp = state.data_loop_nodes.node[set_pnt_node - 1].temp_set_point
        if pump_out_node > 0:
            self.mixed_mass_flow_rate = state.data_loop_nodes.node[pump_out_node - 1].mass_flow_rate

    def calculate(self, state: Any) -> None:
        if state.data_global.kick_off_simulation:
            return
        
        from EnergyPlus.DataPlant import FlowLock
        
        if self.plant_loc.side.flow_lock == FlowLock.Unlocked:
            tin = self.inlet_temp
            tset = self.setpoint_temp
            ts2 = self.stream2_source_temp
            
            if ts2 <= tset:
                self.flow_div_fract = 0.0
            else:
                if tin < ts2:
                    self.flow_div_fract = (ts2 - tset) / (ts2 - tin)
                else:
                    self.flow_div_fract = 1.0
        elif self.plant_loc.side.flow_lock == FlowLock.Locked:
            if self.mixed_mass_flow_rate > 0.0:
                self.flow_div_fract = state.data_loop_nodes.node[self.plt_outlet_node_num - 1].mass_flow_rate / self.mixed_mass_flow_rate
            else:
                self.flow_div_fract = 0.0
        
        if self.flow_div_fract < 0.0:
            self.flow_div_fract = 0.0
        if self.flow_div_fract > 1.0:
            self.flow_div_fract = 1.0

    def one_time_init(self, state: Any) -> None:
        pass

    def one_time_init_new(self, state: Any) -> None:
        pass


def get_plant_valves_input(state: Any) -> None:
    from EnergyPlus.Node import GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
    from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
    from EnergyPlus.OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
    from EnergyPlus.UtilityRoutines import ShowFatalError, format as ep_format
    from EnergyPlus import Constant
    
    current_module_object = "TemperingValve"
    state.data_plant_valves.num_tempering_valves = state.data_input_processing.input_processor.get_num_objects_found(
        state, current_module_object)
    
    state.data_plant_valves.temper_valve = [TemperValveData() for _ in range(state.data_plant_valves.num_tempering_valves)]
    
    for item in range(state.data_plant_valves.num_tempering_valves):
        alphas = [""] * 6
        numbers = [0.0] * 1
        num_alphas = 0
        num_numbers = 0
        io_status = 0
        
        state.data_input_processing.input_processor.get_object_item(
            state, current_module_object, item + 1, alphas, num_alphas, numbers, num_numbers, io_status)
        
        errors_found = False
        state.data_plant_valves.temper_valve[item].name = alphas[0]
        
        state.data_plant_valves.temper_valve[item].plt_inlet_node_num = GetOnlySingleNode(
            state, alphas[1], errors_found, ConnectionObjectType.TemperingValve, alphas[0],
            FluidType.Water, ConnectionType.Inlet, CompFluidStream.Primary, ObjectIsNotParent)
        
        state.data_plant_valves.temper_valve[item].plt_outlet_node_num = GetOnlySingleNode(
            state, alphas[2], errors_found, ConnectionObjectType.TemperingValve, alphas[0],
            FluidType.Water, ConnectionType.Outlet, CompFluidStream.Primary, ObjectIsNotParent)
        
        state.data_plant_valves.temper_valve[item].plt_stream2_node_num = GetOnlySingleNode(
            state, alphas[3], errors_found, ConnectionObjectType.TemperingValve, alphas[0],
            FluidType.Water, ConnectionType.Sensor, CompFluidStream.Primary, ObjectIsNotParent)
        
        state.data_plant_valves.temper_valve[item].plt_setpoint_node_num = GetOnlySingleNode(
            state, alphas[4], errors_found, ConnectionObjectType.TemperingValve, alphas[0],
            FluidType.Water, ConnectionType.SetPoint, CompFluidStream.Primary, ObjectIsNotParent)
        
        state.data_plant_valves.temper_valve[item].plt_pump_outlet_node_num = GetOnlySingleNode(
            state, alphas[5], errors_found, ConnectionObjectType.TemperingValve, alphas[0],
            FluidType.Water, ConnectionType.Sensor, CompFluidStream.Primary, ObjectIsNotParent)
        
        TestCompSet(state, current_module_object, alphas[0], alphas[1], alphas[2], "Supply Side Water Nodes")
    
    for item in range(state.data_plant_valves.num_tempering_valves):
        SetupOutputVariable(state, "Tempering Valve Flow Fraction", Constant.Units.None,
                           state.data_plant_valves.temper_valve[item].flow_div_fract,
                           TimeStepType.System, StoreType.Average,
                           state.data_plant_valves.temper_valve[item].name)
    
    errors_found = False
    for item in range(state.data_plant_valves.num_tempering_valves):
        if errors_found:
            break
    
    if errors_found:
        ShowFatalError(state, ep_format("GetPlantValvesInput: {} Errors found in input", current_module_object))


@dataclass
class PlantValvesData:
    get_tempering_valves: bool = True
    one_time_init_flag: bool = True
    num_tempering_valves: int = 0
    temper_valve: List[TemperValveData] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.get_tempering_valves = True
        self.one_time_init_flag = True
        self.num_tempering_valves = 0
        self.temper_valve.clear()
