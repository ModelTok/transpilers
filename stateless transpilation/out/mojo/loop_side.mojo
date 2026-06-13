# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state param) :: source: EnergyPlus.Data.EnergyPlusData
# - BranchData, ConnectedLoopData, LoopSidePumpInformation, MixerData, SplitterData, PlantConvergencePoint, PlantLocation :: source: EnergyPlus.Plant.DataPlant
# - LoopSideLocation, FlowLock, LoopFlowStatus, OpScheme, PlantEquipmentType, CommonPipeType, LoopDemandCalcScheme, PressureCall :: source: EnergyPlus.Plant.DataPlant
# - DataLoopNode.Node, DataLoopNode.FluidType :: source: EnergyPlus.DataLoopNode
# - DataBranchAirLoopPlant.MassFlowTolerance, DataBranchAirLoopPlant.ControlType :: source: EnergyPlus.DataBranchAirLoopPlant
# - HVAC.SmallLoad, HVAC.VerySmallMassFlow :: source: EnergyPlus.DataHVACGlobals
# - PlantCondLoopOperation.InitLoadDistribution, PlantCondLoopOperation.ManagePlantLoadDistribution :: source: EnergyPlus.PlantCondLoopOperation
# - PlantPressureSystem.SimPressureDropSystem :: source: EnergyPlus.PlantPressureSystem
# - PlantUtilities functions :: source: EnergyPlus.PlantUtilities
# - Pumps.SimPumps :: source: EnergyPlus.Pumps
# - HVACInterfaceManager.UpdatePlantLoopInterface :: source: EnergyPlus.HVACInterfaceManager
# - UtilityRoutines (ShowSevereError, ShowContinueError, ShowFatalError, ShowContinueErrorTimeStamp) :: source: EnergyPlus.UtilityRoutines

from math import abs, max, min

struct LoopSidePumpInformation:
    var pump_name: String
    var pump_heat_to_fluid: Float64
    var current_min_avail: Float64
    var current_max_avail: Float64
    var branch_num: Int32
    var comp_num: Int32
    var pump_outlet_node: Int32
    var index_in_loop_side_pumps: Int32

struct PlantConvergencePoint:
    var temperature_history: InlineArray[Float64, 8]
    var mass_flow_rate_history: InlineArray[Float64, 8]

struct PlantLocation:
    var loop_num: Int32
    var loop_side_num: Int32
    var branch_num: Int32
    var comp_num: Int32

struct HalfLoopData:
    var sim_loop_side_needed: Bool
    var sim_zone_equip_needed: Bool
    var sim_air_loops_needed: Bool
    var sim_non_zone_equip_needed: Bool
    var sim_elect_load_centr_needed: Bool
    var once_per_time_step_operations: Bool
    var time_elapsed: Float64
    var flow_request: Float64
    var flow_request_temperature: Float64
    var temp_set_point: Float64
    var temp_set_point_hi: Float64
    var temp_set_point_lo: Float64
    var temp_interface_tank_outlet: Float64
    var last_temp_interface_tank_outlet: Float64
    var branch_list: String
    var connect_list: String
    var total_branches: Int32
    var node_num_in: Int32
    var node_name_in: String
    var node_num_out: Int32
    var node_name_out: String
    var total_pumps: Int32
    var branch_pumps_exist: Bool
    var pumps: DynamicVector[LoopSidePumpInformation]
    var total_pump_heat: Float64
    var bypass_exists: Bool
    var inlet_node_set_pt: Bool
    var outlet_node_set_pt: Bool
    var ems_ctrl: Bool
    var ems_value: Float64
    var flow_restriction_flag: Bool
    var flow_lock: Int32
    var total_connected: Int32
    var has_pressure_components: Bool
    var has_parallel_press_comps: Bool
    var pressure_drop: Float64
    var pressure_effective_k: Float64
    var err_count_load_wasnt_dist: Int32
    var err_index_load_wasnt_dist: Int32
    var err_count_load_remains: Int32
    var err_index_load_remains: Int32
    var loop_side_inlet_tank_temp: Float64
    var loop_side_inlet_mdot_cp_delta_t: Float64
    var loop_side_inlet_mcp_dt_dt: Float64
    var loop_side_inlet_cap_excess_storage_time: Float64
    var loop_side_inlet_cap_excess_storage_time_report: Float64
    var loop_side_inlet_total_time: Float64
    var inlet_node: PlantConvergencePoint
    var outlet_node: PlantConvergencePoint
    var flow_request_need_if_on: Float64
    var flow_request_need_and_turn_on: Float64
    var flow_request_final: Float64
    var has_const_speed_branch_pumps: Bool
    var no_load_constant_speed_branch_flow_rate_steps: DynamicVector[Float64]
    var initial_demand_to_loop_set_point: Float64
    var current_alterations_to_demand: Float64
    var updated_demand_to_loop_set_point: Float64
    var load_to_loop_set_point_that_wasnt_met: Float64
    var initial_demand_to_loop_set_point_saved: Float64
    var loop_side_description: String
    var loop_set_pt_demand_at_inlet: Float64
    var this_side_load_alterations: Float64
    var plant_loc: PlantLocation

    fn __init__(inout self):
        self.sim_loop_side_needed = True
        self.sim_zone_equip_needed = True
        self.sim_air_loops_needed = True
        self.sim_non_zone_equip_needed = True
        self.sim_elect_load_centr_needed = True
        self.once_per_time_step_operations = True
        self.time_elapsed = 0.0
        self.flow_request = 0.0
        self.flow_request_temperature = 0.0
        self.temp_set_point = -999.0
        self.temp_set_point_hi = -999.0
        self.temp_set_point_lo = -999.0
        self.temp_interface_tank_outlet = 0.0
        self.last_temp_interface_tank_outlet = 0.0
        self.branch_list = String()
        self.connect_list = String()
        self.total_branches = 0
        self.node_num_in = 0
        self.node_name_in = String()
        self.node_num_out = 0
        self.node_name_out = String()
        self.total_pumps = 0
        self.branch_pumps_exist = False
        self.pumps = DynamicVector[LoopSidePumpInformation]()
        self.total_pump_heat = 0.0
        self.bypass_exists = False
        self.inlet_node_set_pt = False
        self.outlet_node_set_pt = False
        self.ems_ctrl = False
        self.ems_value = 0.0
        self.flow_restriction_flag = False
        self.flow_lock = 0
        self.total_connected = 0
        self.has_pressure_components = False
        self.has_parallel_press_comps = False
        self.pressure_drop = 0.0
        self.pressure_effective_k = 0.0
        self.err_count_load_wasnt_dist = 0
        self.err_index_load_wasnt_dist = 0
        self.err_count_load_remains = 0
        self.err_index_load_remains = 0
        self.loop_side_inlet_tank_temp = 0.0
        self.loop_side_inlet_mdot_cp_delta_t = 0.0
        self.loop_side_inlet_mcp_dt_dt = 0.0
        self.loop_side_inlet_cap_excess_storage_time = 0.0
        self.loop_side_inlet_cap_excess_storage_time_report = 0.0
        self.loop_side_inlet_total_time = 0.0
        var hist_temp = InlineArray[Float64, 8](fill=0.0)
        var hist_flow = InlineArray[Float64, 8](fill=0.0)
        self.inlet_node = PlantConvergencePoint(hist_temp, hist_flow)
        self.outlet_node = PlantConvergencePoint(hist_temp, hist_flow)
        self.flow_request_need_if_on = 0.0
        self.flow_request_need_and_turn_on = 0.0
        self.flow_request_final = 0.0
        self.has_const_speed_branch_pumps = False
        self.no_load_constant_speed_branch_flow_rate_steps = DynamicVector[Float64]()
        self.initial_demand_to_loop_set_point = 0.0
        self.current_alterations_to_demand = 0.0
        self.updated_demand_to_loop_set_point = 0.0
        self.load_to_loop_set_point_that_wasnt_met = 0.0
        self.initial_demand_to_loop_set_point_saved = 0.0
        self.loop_side_description = String()
        self.loop_set_pt_demand_at_inlet = 0.0
        self.this_side_load_alterations = 0.0
        self.plant_loc = PlantLocation(0, 0, 0, 0)

    fn validate_flow_control_paths(inout self, state: EnergyPlusData) -> None:
        let parallel = 1
        let outlet = 2
        var encountered_lrb = False
        var encountered_non_lrb_after_lrb = False
        let num_parallel_paths = self.total_branches - 2
        
        let first_branch_index = 0
        for comp_index in range(len(self.branch[first_branch_index].comp)):
            let this_component = self.branch[first_branch_index].comp[comp_index]
            let cur_op_scheme_type = this_component.cur_op_scheme_type
            
            if cur_op_scheme_type == OpScheme.HeatingRB or cur_op_scheme_type == OpScheme.CoolingRB:
                if encountered_non_lrb_after_lrb:
                    pass
                else:
                    encountered_lrb = True
            elif cur_op_scheme_type == OpScheme.Pump:
                pass
            elif cur_op_scheme_type == OpScheme.NoControl:
                pass
            else:
                if encountered_lrb:
                    encountered_non_lrb_after_lrb = True
        
        if num_parallel_paths <= 0:
            return
        
        for path_counter in range(num_parallel_paths):
            for parallel_or_outlet_index in range(parallel, outlet + 1):
                var branch_index: Int32
                if parallel_or_outlet_index == parallel:
                    branch_index = path_counter + 1
                else:
                    branch_index = self.total_branches - 1
                
                for comp_index in range(len(self.branch[branch_index].comp)):
                    let this_component = self.branch[branch_index].comp[comp_index]
                    let cur_op_scheme_type = this_component.cur_op_scheme_type
                    
                    if cur_op_scheme_type == OpScheme.HeatingRB or cur_op_scheme_type == OpScheme.CoolingRB:
                        if encountered_non_lrb_after_lrb:
                            pass
                        else:
                            encountered_lrb = True
                    elif cur_op_scheme_type == OpScheme.NoControl:
                        pass
                    elif cur_op_scheme_type == OpScheme.Pump:
                        pass
                    else:
                        if encountered_lrb:
                            encountered_non_lrb_after_lrb = True

    fn check_plant_convergence(self, first_hvac_iteration: Bool) -> Bool:
        if first_hvac_iteration:
            return False
        
        var inlet_avg_temp: Float64 = 0.0
        var count: Float64 = 0.0
        for i in range(8):
            inlet_avg_temp += self.inlet_node.temperature_history[i]
            count += 1.0
        inlet_avg_temp = inlet_avg_temp / count
        
        for i in range(8):
            if abs(self.inlet_node.temperature_history[i] - inlet_avg_temp) > 1e-6:
                return False
        
        var inlet_avg_mdot: Float64 = 0.0
        for i in range(8):
            inlet_avg_mdot += self.inlet_node.mass_flow_rate_history[i]
        inlet_avg_mdot = inlet_avg_mdot / count
        
        for i in range(8):
            if abs(self.inlet_node.mass_flow_rate_history[i] - inlet_avg_mdot) > 1e-6:
                return False
        
        var outlet_avg_temp: Float64 = 0.0
        for i in range(8):
            outlet_avg_temp += self.outlet_node.temperature_history[i]
        outlet_avg_temp = outlet_avg_temp / count
        
        for i in range(8):
            if abs(self.outlet_node.temperature_history[i] - outlet_avg_temp) > 1e-6:
                return False
        
        var outlet_avg_mdot: Float64 = 0.0
        for i in range(8):
            outlet_avg_mdot += self.outlet_node.mass_flow_rate_history[i]
        outlet_avg_mdot = outlet_avg_mdot / count
        
        for i in range(8):
            if abs(self.outlet_node.mass_flow_rate_history[i] - outlet_avg_mdot) > 1e-6:
                return False
        
        return True

    fn push_branch_flow_characteristics(inout self, state: EnergyPlusData, branch_num: Int32, value_to_push: Float64, first_hvac_iteration: Bool) -> None:
        let this_branch = self.branch[branch_num]
        let branch_inlet_node = this_branch.node_num_in
        
        let mass_flow = value_to_push
        let plant_is_rigid = self.check_plant_convergence(first_hvac_iteration)
        
        for comp_counter in range(len(this_branch.comp)):
            var this_comp = this_branch.comp[comp_counter]
            let component_inlet_node = this_comp.node_num_in
            let component_outlet_node = this_comp.node_num_out
            let mass_flow_rate_found = state.data_loop_nodes.node[component_outlet_node].mass_flow_rate
            let component_type = this_comp.type
            
            state.data_loop_nodes.node[component_outlet_node].mass_flow_rate = mass_flow
            
            if plant_is_rigid:
                state.data_loop_nodes.node[component_inlet_node].mass_flow_rate_min_avail = mass_flow
                state.data_loop_nodes.node[component_inlet_node].mass_flow_rate_max_avail = mass_flow
                state.data_loop_nodes.node[component_outlet_node].mass_flow_rate_min_avail = mass_flow
                state.data_loop_nodes.node[component_outlet_node].mass_flow_rate_max_avail = mass_flow
            
            if abs(mass_flow - mass_flow_rate_found) < 1e-10:
                continue

    fn turn_on_all_loop_side_branches(inout self) -> None:
        for branch_num in range(1, self.total_branches - 1):
            var branch = self.branch[branch_num]
            branch.disable_override_for_cs_branch_pumping = False

    fn disable_any_branch_pumps_connected_to_unloaded_equipment(inout self) -> None:
        for branch_num in range(1, self.total_branches - 1):
            var branch = self.branch[branch_num]
            var total_dispatched_load_on_branch: Float64 = 0.0
            for comp_num in range(len(branch.comp)):
                let component = branch.comp[comp_num]
                let t = component.type
                if t not in [PlantEquipmentType.PumpConstantSpeed, PlantEquipmentType.PumpBankConstantSpeed,
                            PlantEquipmentType.PumpVariableSpeed, PlantEquipmentType.PumpBankVariableSpeed]:
                    total_dispatched_load_on_branch += component.my_load
            if abs(total_dispatched_load_on_branch) < 0.001:
                branch.disable_override_for_cs_branch_pumping = True

    fn evaluate_loop_set_point_load(self, state: EnergyPlusData, first_branch_num: Int32, last_branch_num: Int32, this_loop_side_flow: Float64) -> Float64:
        var load_to_loop_set_point: Float64 = 0.0
        var sum_mdot_times_temp: Float64 = 0.0
        var sum_mdot: Float64 = 0.0
        
        let this_plant_loop = state.data_plnt.plant_loop[self.plant_loc.loop_num]
        
        var branch_index: Int32 = 0
        for branch_counter in range(first_branch_num, last_branch_num + 1):
            branch_index += 1
            let starting_component = self.branch[branch_counter].last_component_simulated
            let entering_node_num = self.branch[branch_counter].comp[starting_component].node_num_in
            
            let entering_temperature = state.data_loop_nodes.node[entering_node_num].temp
            let mass_flow_rate = state.data_loop_nodes.node[entering_node_num].mass_flow_rate
            
            sum_mdot_times_temp += entering_temperature * mass_flow_rate
            sum_mdot += mass_flow_rate
        
        if sum_mdot < 1e-8:
            return 0.0
        
        let weighted_inlet_temp = sum_mdot_times_temp / sum_mdot
        
        if this_plant_loop.fluid_type == 1:
            let cp = this_plant_loop.glycol.get_specific_heat(state, weighted_inlet_temp, "PlantLoopSolver::EvaluateLoopSetPointLoad")
            
            if this_plant_loop.loop_demand_calc_scheme == 1:
                let loop_set_point_temperature = self.temp_set_point
                let delta_temp = loop_set_point_temperature - weighted_inlet_temp
                load_to_loop_set_point = sum_mdot * cp * delta_temp
        
        if abs(load_to_loop_set_point) < 0.1:
            load_to_loop_set_point = 0.0
        
        return load_to_loop_set_point

    fn calc_other_side_demand(self, state: EnergyPlusData, this_loop_side_flow: Float64) -> Float64:
        return self.evaluate_loop_set_point_load(state, 0, 0, this_loop_side_flow)

    fn setup_loop_flow_request(inout self, state: EnergyPlusData, other_side: Int32) -> Float64:
        var loop_flow: Float64 = 0.0
        let loop = state.data_plnt.plant_loop[self.plant_loc.loop_num]
        return loop_flow

    fn do_flow_and_load_solution_pass(inout self, state: EnergyPlusData, other_side: Int32, this_side_inlet_node: Int32, first_hvac_iteration: Bool) -> None:
        var loop_shut_down_flag = False
        
        let this_loop_side_flow_request = self.setup_loop_flow_request(state, other_side)
        let this_loop_side_flow = self.determine_loop_side_flow_rate(state, this_side_inlet_node, this_loop_side_flow_request)
        
        for i in range(len(self.branch)):
            var branch = self.branch[i]
            branch.last_component_simulated = 0
        
        self.initial_demand_to_loop_set_point = self.calc_other_side_demand(state, this_loop_side_flow)
        self.updated_demand_to_loop_set_point = self.initial_demand_to_loop_set_point
        self.load_to_loop_set_point_that_wasnt_met = 0.0
        
        self.flow_lock = 0
        self.simulate_all_loop_side_branches(state, this_loop_side_flow, first_hvac_iteration, loop_shut_down_flag)
        self.resolve_parallel_flows(state, this_loop_side_flow, first_hvac_iteration)
        
        self.initial_demand_to_loop_set_point_saved = self.initial_demand_to_loop_set_point
        self.current_alterations_to_demand = 0.0
        self.updated_demand_to_loop_set_point = self.initial_demand_to_loop_set_point
        
        self.flow_lock = 1
        self.simulate_all_loop_side_branches(state, this_loop_side_flow, first_hvac_iteration, loop_shut_down_flag)

    fn resolve_parallel_flows(inout self, state: EnergyPlusData, this_loop_side_flow: Float64, first_hvac_iteration: Bool) -> None:
        pass

    fn simulate_all_loop_side_branches(inout self, state: EnergyPlusData, this_loop_side_flow: Float64, first_hvac_iteration: Bool, inout loop_shut_down_flag: Bool) -> None:
        pass

    fn adjust_pump_flow_request_by_ems_controls(inout self, branch_num: Int32, comp_num: Int32, inout flow_to_request: Float64) -> None:
        let this_branch = self.branch[branch_num]
        let this_comp = this_branch.comp[comp_num]
        
        if (self.ems_ctrl) and (self.ems_value <= 0.0):
            flow_to_request = 0.0
            return
        
        if ((this_branch.ems_ctrl_override_on) and (this_branch.ems_ctrl_override_value <= 0.0)):
            flow_to_request = 0.0
            return
        
        if this_comp.ems_load_override_on:
            if this_comp.ems_load_override_value == 0.0:
                flow_to_request = 0.0

    fn simulate_loop_side_branch_group(inout self, state: EnergyPlusData, first_branch_num: Int32, last_branch_num: Int32, 
                                       flow_request: Float64, first_hvac_iteration: Bool, inout loop_shut_down_flag: Bool) -> None:
        pass

    fn update_any_loop_demand_alterations(inout self, state: EnergyPlusData, branch_num: Int32, comp_num: Int32) -> None:
        var component_mass_flow_rate: Float64 = 0.0
        let this_comp = self.branch[branch_num].comp[comp_num]
        let inlet_node = this_comp.node_num_in
        let outlet_node = this_comp.node_num_out
        
        if self.flow_lock == 0:
            if this_comp.cur_op_scheme_type not in [OpScheme.HeatingRB, OpScheme.CoolingRB]:
                component_mass_flow_rate = state.data_loop_nodes.node[inlet_node].mass_flow_rate_request
        elif self.flow_lock == 1:
            if this_comp.cur_op_scheme_type not in [OpScheme.HeatingRB, OpScheme.CoolingRB]:
                component_mass_flow_rate = state.data_loop_nodes.node[outlet_node].mass_flow_rate
        
        if component_mass_flow_rate < 1e-8:
            return
        
        let inlet_temp = state.data_loop_nodes.node[inlet_node].temp
        let outlet_temp = state.data_loop_nodes.node[outlet_node].temp
        let average_temp = (inlet_temp + outlet_temp) / 2.0
        let component_cp = state.data_plnt.plant_loop[self.plant_loc.loop_num].glycol.get_specific_heat(state, average_temp, "PlantLoopSolver::UpdateAnyLoopDemandAlterations")
        
        let load_alteration = component_mass_flow_rate * component_cp * (outlet_temp - inlet_temp)
        
        self.current_alterations_to_demand += load_alteration
        self.updated_demand_to_loop_set_point = self.initial_demand_to_loop_set_point - self.current_alterations_to_demand

    fn simulate_single_pump(inout self, state: EnergyPlusData, specific_pump_location: PlantLocation, inout specific_pump_flow_rate: Float64) -> None:
        let loop = state.data_plnt.plant_loop[specific_pump_location.loop_num]
        var loop_side = loop.loop_side(specific_pump_location.loop_side_num)
        var loop_side_branch = loop_side.branch[specific_pump_location.branch_num]
        var comp = loop_side_branch.comp[specific_pump_location.comp_num]
        let pump_index = comp.index_in_loop_side_pumps
        var pump = loop_side.pumps[pump_index]
        
        self.adjust_pump_flow_request_by_ems_controls(specific_pump_location.branch_num, specific_pump_location.comp_num, specific_pump_flow_rate)
        
        var dummy_this_pump_running = False
        pass

    fn simulate_all_loop_side_pumps(inout self, state: EnergyPlusData, specific_pump_location: Optional[PlantLocation] = None, 
                                    specific_pump_flow_rate: Optional[Float64] = None) -> None:
        pass

    fn determine_loop_side_flow_rate(inout self, state: EnergyPlusData, this_side_inlet_node: Int32, this_side_loop_flow_request: Float64) -> Float64:
        var this_loop_side_flow = this_side_loop_flow_request
        var total_pump_min_avail_flow: Float64 = 0.0
        var total_pump_max_avail_flow: Float64 = 0.0
        
        if len(self.pumps) > 0:
            for i in range(len(self.pumps)):
                self.pumps[i].current_min_avail = 0.0
                self.pumps[i].current_max_avail = 0.0
            
            self.flow_lock = 2
            self.simulate_all_loop_side_pumps(state)
            
            for i in range(len(self.pumps)):
                total_pump_min_avail_flow += self.pumps[i].current_min_avail
                total_pump_max_avail_flow += self.pumps[i].current_max_avail
            
            this_loop_side_flow = max(min(this_loop_side_flow, total_pump_max_avail_flow), total_pump_min_avail_flow)
        
        state.data_loop_nodes.node[this_side_inlet_node].mass_flow_rate = this_loop_side_flow
        return this_loop_side_flow

    fn update_plant_mixer(inout self, state: EnergyPlusData) -> None:
        let mixer_outlet_node = self.mixer.node_num_out
        let splitter_in_node = self.splitter.node_num_in
        
        var mixer_outlet_temp: Float64 = 0.0
        var mixer_outlet_mass_flow: Float64 = 0.0
        var mixer_outlet_mass_flow_max_avail: Float64 = 0.0
        var mixer_outlet_mass_flow_min_avail: Float64 = 0.0
        var mixer_outlet_press: Float64 = 0.0
        var mixer_outlet_quality: Float64 = 0.0
        
        for inlet_node_num in range(self.mixer.total_inlet_nodes):
            let mixer_inlet_node = self.mixer.node_num_in(inlet_node_num)
            mixer_outlet_mass_flow += state.data_loop_nodes.node[mixer_inlet_node].mass_flow_rate
        
        for inlet_node_num in range(self.mixer.total_inlet_nodes):
            let mixer_inlet_node = self.mixer.node_num_in(inlet_node_num)
            if mixer_outlet_mass_flow > 0.0:
                let mixer_inlet_mass_flow = state.data_loop_nodes.node[mixer_inlet_node].mass_flow_rate
                let mass_frac = mixer_inlet_mass_flow / mixer_outlet_mass_flow
                mixer_outlet_temp += mass_frac * state.data_loop_nodes.node[mixer_inlet_node].temp
                mixer_outlet_quality += mass_frac * state.data_loop_nodes.node[mixer_inlet_node].quality
                mixer_outlet_mass_flow_max_avail += state.data_loop_nodes.node[mixer_inlet_node].mass_flow_rate_max_avail
                mixer_outlet_mass_flow_min_avail += state.data_loop_nodes.node[mixer_inlet_node].mass_flow_rate_min_avail
                mixer_outlet_press = max(mixer_outlet_press, state.data_loop_nodes.node[mixer_inlet_node].press)
            else:
                mixer_outlet_temp = state.data_loop_nodes.node[splitter_in_node].temp
                mixer_outlet_quality = state.data_loop_nodes.node[splitter_in_node].quality
                mixer_outlet_mass_flow_max_avail = state.data_loop_nodes.node[splitter_in_node].mass_flow_rate_max_avail
                mixer_outlet_mass_flow_min_avail = state.data_loop_nodes.node[splitter_in_node].mass_flow_rate_min_avail
                mixer_outlet_press = state.data_loop_nodes.node[splitter_in_node].press
                break
        
        state.data_loop_nodes.node[mixer_outlet_node].mass_flow_rate = mixer_outlet_mass_flow
        state.data_loop_nodes.node[mixer_outlet_node].temp = mixer_outlet_temp
        if not state.data_plnt.plant_loop[self.plant_loc.loop_num].has_pressure_components:
            state.data_loop_nodes.node[mixer_outlet_node].press = mixer_outlet_press
        state.data_loop_nodes.node[mixer_outlet_node].quality = mixer_outlet_quality
        
        state.data_loop_nodes.node[mixer_outlet_node].mass_flow_rate_max_avail = min(mixer_outlet_mass_flow_max_avail, 
                                                                                      state.data_loop_nodes.node[splitter_in_node].mass_flow_rate_max_avail)
        state.data_loop_nodes.node[mixer_outlet_node].mass_flow_rate_min_avail = max(mixer_outlet_mass_flow_min_avail, 
                                                                                      state.data_loop_nodes.node[splitter_in_node].mass_flow_rate_min_avail)

    fn update_plant_splitter(inout self, state: EnergyPlusData) -> None:
        if self.splitter.exists:
            let splitter_inlet_node = self.splitter.node_num_in
            
            for cur_node in range(self.splitter.total_outlet_nodes):
                let splitter_outlet_node = self.splitter.node_num_out(cur_node)
                
                state.data_loop_nodes.node[splitter_outlet_node].temp = state.data_loop_nodes.node[splitter_inlet_node].temp
                state.data_loop_nodes.node[splitter_outlet_node].temp_min = state.data_loop_nodes.node[splitter_inlet_node].temp_min
                state.data_loop_nodes.node[splitter_outlet_node].temp_max = state.data_loop_nodes.node[splitter_inlet_node].temp_max
                if not state.data_plnt.plant_loop[self.plant_loc.loop_num].has_pressure_components:
                    state.data_loop_nodes.node[splitter_outlet_node].press = state.data_loop_nodes.node[splitter_inlet_node].press
                state.data_loop_nodes.node[splitter_outlet_node].quality = state.data_loop_nodes.node[splitter_inlet_node].quality
                
                state.data_loop_nodes.node[splitter_outlet_node].mass_flow_rate_max_avail = min(
                    state.data_loop_nodes.node[splitter_inlet_node].mass_flow_rate_max_avail, 
                    state.data_loop_nodes.node[splitter_outlet_node].mass_flow_rate_max)
                state.data_loop_nodes.node[splitter_outlet_node].mass_flow_rate_min_avail = 0.0
                
                if self.splitter.total_outlet_nodes == 1:
                    state.data_loop_nodes.node[splitter_outlet_node].mass_flow_rate_min_avail = state.data_loop_nodes.node[splitter_inlet_node].mass_flow_rate_min_avail

    fn solve(inout self, state: EnergyPlusData, first_hvac_iteration: Bool, inout re_sim_other_side_needed: Bool) -> None:
        let this_plant_loop = state.data_plnt.plant_loop[self.plant_loc.loop_num]
        let this_side_inlet_node = self.node_num_in
        
        self.initial_demand_to_loop_set_point = 0.0
        self.current_alterations_to_demand = 0.0
        self.updated_demand_to_loop_set_point = 0.0
        
        if state.data_global.begin_time_step_flag and self.once_per_time_step_operations:
            self.validate_flow_control_paths(state)
            self.once_per_time_step_operations = False
        else:
            self.once_per_time_step_operations = True
        
        if self.plant_loc.loop_side_num == 1:
            pass
        
        self.turn_on_all_loop_side_branches()
        
        let other_loop_side = 2 - self.plant_loc.loop_side_num
        self.do_flow_and_load_solution_pass(state, other_loop_side, this_side_inlet_node, first_hvac_iteration)
        
        if self.has_const_speed_branch_pumps:
            self.disable_any_branch_pumps_connected_to_unloaded_equipment()
            self.do_flow_and_load_solution_pass(state, other_loop_side, this_side_inlet_node, first_hvac_iteration)
        
        if self.plant_loc.loop_side_num == 1:
            pass
        else:
            pass
