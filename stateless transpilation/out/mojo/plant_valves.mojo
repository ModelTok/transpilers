from collections import OptionalReg
from collections.optional import Optional

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state.data_plant_valves, state.data_input_processing, state.data_loop_nodes,
#                 state.data_plnt, state.data_global (BeginEnvrnFlag, KickOffSimulation)
# PlantComponent: base struct for TemperValveData (simulate, getDesignCapacities, oneTimeInit, oneTimeInit_new)
# PlantLocation: location identifier with loop_num, side attributes
# Node module: GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
# DataPlant: PlantEquipmentType, FlowLock, ScanPlantLoopsForObject, PlantEquipmentTypeIsPump
# DataBranchAirLoopPlant: ControlType
# InputProcessor: getNumObjectsFound, getObjectItem
# OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# PlantUtilities: SafeCopyPlantNode, SetComponentFlowRate, InitComponentNodes
# UtilityRoutines: ShowFatalError, ShowSevereError, ShowContinueError, format
# Constant: Units

struct PlantLocation:
    var loop_num: Int = 0
    var loop_side_num: Int = 0
    var branch_num: Int = 0
    var comp_num: Int = 0
    var side: UnsafePointer[Byte] = UnsafePointer[Byte]()

struct TemperValveData:
    var name: String = ""
    var plt_inlet_node_num: Int = 0
    var plt_outlet_node_num: Int = 0
    var plt_stream2_node_num: Int = 0
    var plt_setpoint_node_num: Int = 0
    var plt_pump_outlet_node_num: Int = 0
    var environment_init: Bool = True
    var flow_div_fract: Float64 = 0.0
    var stream2_source_temp: Float64 = 0.0
    var inlet_temp: Float64 = 0.0
    var setpoint_temp: Float64 = 0.0
    var mixed_mass_flow_rate: Float64 = 0.0
    var plant_loc: PlantLocation = PlantLocation()
    var comp_delayed_init_flag: Bool = True

    fn factory(state: UnsafePointer[Byte], object_name: String) -> Optional[UnsafePointer[TemperValveData]]:
        var plant_valves = UnsafePointer[PlantValvesData](state).pointee.data_plant_valves
        if plant_valves.get_tempering_valves:
            get_plant_valves_input(state)
            plant_valves.get_tempering_valves = False
        
        for i in range(plant_valves.num_tempering_valves):
            if plant_valves.temper_valve[i].name == object_name:
                return Optional(UnsafePointer(plant_valves.temper_valve.data) + i)
        
        return Optional[UnsafePointer[TemperValveData]]()

    fn simulate(inout self, state: UnsafePointer[Byte], called_from_location: UnsafePointer[Byte], 
                first_hvac_iteration: Bool, inout cur_load: Float64, run_flag: Bool) -> None:
        self.initialize(state)
        self.calculate(state)
        
        var mdot = self.mixed_mass_flow_rate * self.flow_div_fract
        if self.plant_loc.loop_num > 0:
            pass

    fn get_design_capacities(self, state: UnsafePointer[Byte], called_from_location: UnsafePointer[Byte],
                            inout max_load: Float64, inout min_load: Float64, inout opt_load: Float64) -> None:
        max_load = 0.0
        min_load = 0.0
        opt_load = 0.0

    fn initialize(inout self, state: UnsafePointer[Byte]) -> None:
        var inlet_node = self.plt_inlet_node_num
        var outlet_node = self.plt_outlet_node_num
        var strm2_node = self.plt_stream2_node_num
        var set_pnt_node = self.plt_setpoint_node_num
        var pump_out_node = self.plt_pump_outlet_node_num

        var state_ref = state.bitcast[PlantValvesState]()
        if state_ref[].one_time_init_flag:
            state_ref[].one_time_init_flag = False
        else:
            if self.comp_delayed_init_flag:
                var errors_found = False
                var in_node_on_splitter = False
                var pump_out_node_okay = False
                var two_branches_betwn = False
                var set_point_node_okay = False
                var stream2_node_okay = False
                var is_branch_active = False

                for plant_loop_idx in range(64):
                    pass

                if not is_branch_active:
                    pass
                
                self.comp_delayed_init_flag = False

        if inlet_node > 0:
            self.inlet_temp = 0.0
        if strm2_node > 0:
            self.stream2_source_temp = 0.0
        if set_pnt_node > 0:
            self.setpoint_temp = 0.0
        if pump_out_node > 0:
            self.mixed_mass_flow_rate = 0.0

    fn calculate(inout self, state: UnsafePointer[Byte]) -> None:
        var tin = self.inlet_temp
        var tset = self.setpoint_temp
        var ts2 = self.stream2_source_temp
        
        if ts2 <= tset:
            self.flow_div_fract = 0.0
        else:
            if tin < ts2:
                self.flow_div_fract = (ts2 - tset) / (ts2 - tin)
            else:
                self.flow_div_fract = 1.0
        
        if self.flow_div_fract < 0.0:
            self.flow_div_fract = 0.0
        if self.flow_div_fract > 1.0:
            self.flow_div_fract = 1.0

    fn one_time_init(inout self, state: UnsafePointer[Byte]) -> None:
        pass

    fn one_time_init_new(inout self, state: UnsafePointer[Byte]) -> None:
        pass


fn get_plant_valves_input(state: UnsafePointer[Byte]) -> None:
    var current_module_object = "TemperingValve"
    pass


struct PlantValvesData:
    var get_tempering_valves: Bool = True
    var one_time_init_flag: Bool = True
    var num_tempering_valves: Int = 0
    var temper_valve: DynamicVector[TemperValveData]

    fn init_constant_state(inout self, state: UnsafePointer[Byte]) -> None:
        pass

    fn init_state(inout self, state: UnsafePointer[Byte]) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.get_tempering_valves = True
        self.one_time_init_flag = True
        self.num_tempering_valves = 0
        self.temper_valve.resize(0)


struct PlantValvesState:
    var data_plant_valves: PlantValvesData
