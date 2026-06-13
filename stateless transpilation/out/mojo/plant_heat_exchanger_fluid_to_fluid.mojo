"""
PlantHeatExchangerFluidToFluid - Plant Heat Exchanger Fluid to Fluid Component

Ports EnergyPlus HeatExchanger:FluidToFluid model
"""

import math
from collections import InlineArray


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data structures
# - PlantLocation: base location descriptor
# - PlantComponent: base component class
# - BaseGlobalStruct: base data structure
# - Sched: Schedule manager (GetSchedule, GetScheduleAlwaysOn, getCurrentVal)
# - Node: Node manager (GetOnlySingleNode, TestCompSet, SensedNodeFlagValue, etc.)
# - PlantUtilities: (SetComponentFlowRate, InitComponentNodes, RegisterPlantCompDesignFlow, etc.)
# - OutputProcessor: (SetupOutputVariable, TimeStepType, StoreType, EndUseCat, Group, eResource)
# - EMSManager: (CheckIfNodeSetPointManagedByEMS)
# - DataPlant: enums and structures (PlantEquipmentType, LoopSideLocation, etc.)
# - DataSizing: (AutoSize, PlantSizData, TypeOfPlantLoop)
# - General: (SolveRoot)
# - FluidProperties: fluid property getters (getDensity, getSpecificHeat)
# - DataBranchAirLoopPlant: (MassFlowTolerance)
# - HVAC: (SmallLoad, SmallWaterVolFlow)
# - DataEnvironment: (OutWetBulbTemp, OutDryBulbTemp)
# - DataLoopNode: (Node array/dict)
# - DataPrecisionGlobals: (EXP_UpperLimit, EXP_LowerLimit)
# - OutputReportPredefined: (PreDefTableEntry)
# - BaseSizer: (reportSizerOutput)
# - Error functions: (ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, etc.)
# - Constant: (InitConvTemp, Units, eResource, EndUseCat, iHoursInDay)
# - ErrorObjectHeader: error tracking


alias FluidHXType = Int32
alias ControlType = Int32
alias CtrlTempType = Int32
alias HXAction = Int32

struct FluidHXTypeEnum:
    alias Invalid = Int32(-1)
    alias CrossFlowBothUnMixed = Int32(0)
    alias CrossFlowBothMixed = Int32(1)
    alias CrossFlowSupplyLoopMixedDemandLoopUnMixed = Int32(2)
    alias CrossFlowSupplyLoopUnMixedDemandLoopMixed = Int32(3)
    alias CounterFlow = Int32(4)
    alias ParallelFlow = Int32(5)
    alias Ideal = Int32(6)
    alias Num = Int32(7)


struct ControlTypeEnum:
    alias Invalid = Int32(-1)
    alias UncontrolledOn = Int32(0)
    alias OperationSchemeModulated = Int32(1)
    alias OperationSchemeOnOff = Int32(2)
    alias HeatingSetPointModulated = Int32(3)
    alias HeatingSetPointOnOff = Int32(4)
    alias CoolingSetPointModulated = Int32(5)
    alias CoolingSetPointOnOff = Int32(6)
    alias DualDeadBandSetPointModulated = Int32(7)
    alias DualDeadBandSetPointOnOff = Int32(8)
    alias CoolingDifferentialOnOff = Int32(9)
    alias CoolingSetPointOnOffWithComponentOverride = Int32(10)
    alias TrackComponentOnOff = Int32(11)
    alias Num = Int32(12)


struct CtrlTempTypeEnum:
    alias Invalid = Int32(-1)
    alias WetBulbTemperature = Int32(0)
    alias DryBulbTemperature = Int32(1)
    alias LoopTemperature = Int32(2)
    alias Num = Int32(3)


struct HXActionEnum:
    alias Invalid = Int32(-1)
    alias HeatingSupplySideLoop = Int32(0)
    alias CoolingSupplySideLoop = Int32(1)
    alias Num = Int32(2)


alias COMPONENT_CLASS_NAME = "HeatExchanger:FluidToFluid"


@always_inline
fn init_fluid_hx_type_names() -> InlineArray[StringRef, 7]:
    var names = InlineArray[StringRef, 7](fill="")
    names[0] = "CrossFlowBothUnMixed"
    names[1] = "CrossFlowBothMixed"
    names[2] = "CrossFlowSupplyMixedDemandUnMixed"
    names[3] = "CrossFlowSupplyUnMixedDemandMixed"
    names[4] = "CounterFlow"
    names[5] = "ParallelFlow"
    names[6] = "Ideal"
    return names


@always_inline
fn init_fluid_hx_type_names_uc() -> InlineArray[StringRef, 7]:
    var names = InlineArray[StringRef, 7](fill="")
    names[0] = "CROSSFLOWBOTHUNMIXED"
    names[1] = "CROSSFLOWBOTHMIXED"
    names[2] = "CROSSFLOWSUPPLYMIXEDDEMANDUNMIXED"
    names[3] = "CROSSFLOWSUPPLYUNMIXEDDEMANDMIXED"
    names[4] = "COUNTERFLOW"
    names[5] = "PARALLELFLOW"
    names[6] = "IDEAL"
    return names


@always_inline
fn init_control_type_names() -> InlineArray[StringRef, 12]:
    var names = InlineArray[StringRef, 12](fill="")
    names[0] = "UncontrolledOn"
    names[1] = "OperationSchemeModulated"
    names[2] = "OperationSchemeOnOff"
    names[3] = "HeatingSetpointModulated"
    names[4] = "HeatingSetpointOnOff"
    names[5] = "CoolingSetpointModulated"
    names[6] = "CoolingSetpointOnOff"
    names[7] = "DualDeadbandSetpointModulated"
    names[8] = "DualDeadbandSetpointOnOff"
    names[9] = "CoolingDifferentialOnOff"
    names[10] = "CoolingSetpointOnOffWithComponentOverride"
    names[11] = "TrackComponentOnOff"
    return names


@always_inline
fn init_control_type_names_uc() -> InlineArray[StringRef, 12]:
    var names = InlineArray[StringRef, 12](fill="")
    names[0] = "UNCONTROLLEDON"
    names[1] = "OPERATIONSCHEMEMODULATED"
    names[2] = "OPERATIONSCHEMEONOFF"
    names[3] = "HEATINGSETPOINTMODULATED"
    names[4] = "HEATINGSETPOINTONOFF"
    names[5] = "COOLINGSETPOINTMODULATED"
    names[6] = "COOLINGSETPOINTONOFF"
    names[7] = "DUALDEADBANDSETPOINTMODULATED"
    names[8] = "DUALDEADBANDSETPOINTONOFF"
    names[9] = "COOLINGDIFFERENTIALONOFF"
    names[10] = "COOLINGSETPOINTONOFFWITHCOMPONENTOVERRIDE"
    names[11] = "TRACKCOMPONENTONOFF"
    return names


@always_inline
fn init_ctrl_temp_type_names() -> InlineArray[StringRef, 3]:
    var names = InlineArray[StringRef, 3](fill="")
    names[0] = "WetBulbTemperature"
    names[1] = "DryBulbTemperature"
    names[2] = "Loop"
    return names


@always_inline
fn init_ctrl_temp_type_names_uc() -> InlineArray[StringRef, 3]:
    var names = InlineArray[StringRef, 3](fill="")
    names[0] = "WETBULBTEMPERATURE"
    names[1] = "DRYBULBTEMPERATURE"
    names[2] = "LOOP"
    return names


struct PlantConnectionStruct:
    var inlet_node_num: Int32
    var outlet_node_num: Int32
    var mass_flow_rate_min: Float64
    var mass_flow_rate_max: Float64
    var design_volume_flow_rate: Float64
    var design_volume_flow_rate_was_auto_sized: Bool
    var my_load: Float64
    var min_load: Float64
    var max_load: Float64
    var opt_load: Float64
    var inlet_temp: Float64
    var inlet_mass_flow_rate: Float64
    var outlet_temp: Float64
    var loop_num: Int32
    var loop_side_num: Int32
    var branch_num: Int32
    var comp_num: Int32
    var loop: AnyType
    var comp: AnyType

    fn __init__(inout self):
        self.inlet_node_num = 0
        self.outlet_node_num = 0
        self.mass_flow_rate_min = 0.0
        self.mass_flow_rate_max = 0.0
        self.design_volume_flow_rate = 0.0
        self.design_volume_flow_rate_was_auto_sized = False
        self.my_load = 0.0
        self.min_load = 0.0
        self.max_load = 0.0
        self.opt_load = 0.0
        self.inlet_temp = 0.0
        self.inlet_mass_flow_rate = 0.0
        self.outlet_temp = 0.0
        self.loop_num = 0
        self.loop_side_num = 0
        self.branch_num = 0
        self.comp_num = 0


struct PlantLocatorStruct:
    var inlet_node_num: Int32
    var loop_num: Int32
    var loop_side_num: Int32
    var branch_num: Int32
    var comp_num: Int32
    var comp: AnyType

    fn __init__(inout self):
        self.inlet_node_num = 0
        self.loop_num = 0
        self.loop_side_num = 0
        self.branch_num = 0
        self.comp_num = 0


struct HeatExchangerStruct:
    var name: String
    var avail_sched: AnyType
    var heat_exchange_model_type: FluidHXType
    var ua: Float64
    var ua_was_auto_sized: Bool
    var control_mode: ControlType
    var set_point_node_num: Int32
    var temp_control_tol: Float64
    var control_signal_temp: CtrlTempType
    var min_operation_temp: Float64
    var max_operation_temp: Float64
    var demand_side_loop: PlantConnectionStruct
    var supply_side_loop: PlantConnectionStruct
    var heat_transfer_metering_end_use: AnyType
    var component_user_name: String
    var component_type: AnyType
    var other_comp_supply_side_loop: PlantLocatorStruct
    var other_comp_demand_side_loop: PlantLocatorStruct
    var sizing_factor: Float64
    var heat_transfer_rate: Float64
    var heat_transfer_energy: Float64
    var effectiveness: Float64
    var operation_status: Float64
    var dmd_side_modulate_solv_no_converge_error_count: Int32
    var dmd_side_modulate_solv_no_converge_error_index: Int32
    var dmd_side_modulate_solv_fail_error_count: Int32
    var dmd_side_modulate_solv_fail_error_index: Int32
    var my_one_time_flag: Bool
    var my_flag: Bool
    var my_envrnflag: Bool

    fn __init__(inout self):
        self.name = ""
        self.heat_exchange_model_type = FluidHXTypeEnum.Invalid
        self.ua = 0.0
        self.ua_was_auto_sized = False
        self.control_mode = ControlTypeEnum.Invalid
        self.set_point_node_num = 0
        self.temp_control_tol = 0.0
        self.control_signal_temp = CtrlTempTypeEnum.Invalid
        self.min_operation_temp = -99999.0
        self.max_operation_temp = 99999.0
        self.demand_side_loop = PlantConnectionStruct()
        self.supply_side_loop = PlantConnectionStruct()
        self.component_user_name = ""
        self.sizing_factor = 1.0
        self.heat_transfer_rate = 0.0
        self.heat_transfer_energy = 0.0
        self.effectiveness = 0.0
        self.operation_status = 0.0
        self.dmd_side_modulate_solv_no_converge_error_count = 0
        self.dmd_side_modulate_solv_no_converge_error_index = 0
        self.dmd_side_modulate_solv_fail_error_count = 0
        self.dmd_side_modulate_solv_fail_error_index = 0
        self.my_one_time_flag = True
        self.my_flag = True
        self.my_envrnflag = True
        self.other_comp_supply_side_loop = PlantLocatorStruct()
        self.other_comp_demand_side_loop = PlantLocatorStruct()

    @staticmethod
    fn factory(state: AnyType, object_name: StringRef) -> AnyType:
        # Process input if not yet done
        if state.data_plant_hx_fluid_to_fluid.get_input:
            get_fluid_heat_exchanger_input(state)
            state.data_plant_hx_fluid_to_fluid.get_input = False
        
        # Search for object
        for obj in state.data_plant_hx_fluid_to_fluid.fluid_hx:
            if obj.name == object_name:
                return obj
        
        # Not found - fatal error
        return None

    fn on_init_loop_equip(inout self, state: AnyType, called_from_location: AnyType) -> None:
        self.initialize(state)

    fn get_design_capacities(inout self, state: AnyType, called_from_location: AnyType) -> (Float64, Float64, Float64):
        if called_from_location.loop_num == self.demand_side_loop.loop_num:
            return (self.demand_side_loop.max_load, 0.0, self.demand_side_loop.max_load * 0.9)
        elif called_from_location.loop_num == self.supply_side_loop.loop_num:
            self.size(state)
            return (self.supply_side_loop.max_load, 0.0, self.supply_side_loop.max_load * 0.9)
        return (0.0, 0.0, 0.0)

    fn simulate(inout self, state: AnyType, called_from_location: AnyType, 
                first_hvac_iteration: Bool, cur_load: Float64, run_flag: Bool) -> None:
        self.initialize(state)
        
        if ((self.control_mode == ControlTypeEnum.OperationSchemeModulated) or 
            (self.control_mode == ControlTypeEnum.OperationSchemeOnOff)):
            if called_from_location.loop_num == self.supply_side_loop.loop_num:
                self.control(state, cur_load, first_hvac_iteration)
        else:
            self.control(state, cur_load, first_hvac_iteration)
        
        let sup_mdot = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].mass_flow_rate
        let dmd_mdot = state.data_loop_nodes[self.demand_side_loop.inlet_node_num].mass_flow_rate
        self.calculate(state, sup_mdot, dmd_mdot)

    fn setup_output_vars(inout self, state: AnyType) -> None:
        pass

    fn initialize(inout self, state: AnyType) -> None:
        self.one_time_init(state)
        
        if (state.data_global.begin_envrnflag and self.my_envrnflag and 
            state.data_plnt.plant_first_sizes_okay_to_finalize):
            
            let rho = self.demand_side_loop.loop.glycol.get_density(state, 273.15)
            self.demand_side_loop.mass_flow_rate_max = rho * self.demand_side_loop.design_volume_flow_rate
            
            let rho2 = self.supply_side_loop.loop.glycol.get_density(state, 273.15)
            self.supply_side_loop.mass_flow_rate_max = rho2 * self.supply_side_loop.design_volume_flow_rate
            
            self.my_envrnflag = False
        
        if not state.data_global.begin_envrnflag:
            self.my_envrnflag = True
        
        self.demand_side_loop.inlet_temp = state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp
        self.supply_side_loop.inlet_temp = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp
        
        if self.control_mode == ControlTypeEnum.CoolingSetPointOnOffWithComponentOverride:
            self.other_comp_supply_side_loop.comp.free_cool_cntrl_min_cntrl_temp = (
                state.data_loop_nodes[self.set_point_node_num].temp_set_point - self.temp_control_tol
            )

    fn size(inout self, state: AnyType) -> None:
        pass

    fn control(inout self, state: AnyType, my_load: Float64, first_hvac_iteration: Bool) -> None:
        let avail_sched_value = self.avail_sched.get_current_val()
        let scheduled_off = avail_sched_value <= 0
        
        var limit_tripped_off = False
        if (state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp < self.min_operation_temp or
            state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp < self.min_operation_temp):
            limit_tripped_off = True
        if (state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp > self.max_operation_temp or
            state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp > self.max_operation_temp):
            limit_tripped_off = True

    fn calculate(inout self, state: AnyType, sup_side_mdot: Float64, dmd_side_mdot: Float64) -> None:
        let sup_side_loop_inlet_temp = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp
        let dmd_side_loop_inlet_temp = state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp
        
        let sup_side_loop_inlet_cp = self.supply_side_loop.loop.glycol.get_specific_heat(state, sup_side_loop_inlet_temp)
        let dmd_side_loop_inlet_cp = self.demand_side_loop.loop.glycol.get_specific_heat(state, dmd_side_loop_inlet_temp)
        
        let sup_side_cap_rate = sup_side_mdot * sup_side_loop_inlet_cp
        let dmd_side_cap_rate = dmd_side_mdot * dmd_side_loop_inlet_cp
        let min_cap_rate = min(sup_side_cap_rate, dmd_side_cap_rate)
        let max_cap_rate = max(sup_side_cap_rate, dmd_side_cap_rate)
        
        if min_cap_rate > 0.0:
            if self.heat_exchange_model_type == FluidHXTypeEnum.Ideal:
                self.effectiveness = 1.0
            else:
                self.effectiveness = 0.0
        else:
            self.effectiveness = 0.0
        
        self.heat_transfer_rate = self.effectiveness * min_cap_rate * (sup_side_loop_inlet_temp - dmd_side_loop_inlet_temp)
        
        if sup_side_mdot > 0.0:
            self.supply_side_loop.outlet_temp = sup_side_loop_inlet_temp - self.heat_transfer_rate / (sup_side_loop_inlet_cp * sup_side_mdot)
        else:
            self.supply_side_loop.outlet_temp = sup_side_loop_inlet_temp
        
        if dmd_side_mdot > 0.0:
            self.demand_side_loop.outlet_temp = dmd_side_loop_inlet_temp + self.heat_transfer_rate / (dmd_side_loop_inlet_cp * dmd_side_mdot)
        else:
            self.demand_side_loop.outlet_temp = dmd_side_loop_inlet_temp
        
        self.supply_side_loop.inlet_temp = sup_side_loop_inlet_temp
        self.supply_side_loop.inlet_mass_flow_rate = sup_side_mdot
        self.demand_side_loop.inlet_temp = dmd_side_loop_inlet_temp
        self.demand_side_loop.inlet_mass_flow_rate = dmd_side_mdot
        
        state.data_loop_nodes[self.demand_side_loop.outlet_node_num].temp = self.demand_side_loop.outlet_temp
        state.data_loop_nodes[self.supply_side_loop.outlet_node_num].temp = self.supply_side_loop.outlet_temp
        
        self.heat_transfer_energy = self.heat_transfer_rate * state.data_hvac_global.time_step_sys_sec
        
        if (abs(self.heat_transfer_rate) > 0.01 and self.demand_side_loop.inlet_mass_flow_rate > 0.0 and
            self.supply_side_loop.inlet_mass_flow_rate > 0.0):
            self.operation_status = 1.0
        else:
            self.operation_status = 0.0

    fn find_demand_side_loop_flow(inout self, state: AnyType, 
                                   target_supply_side_loop_leaving_temp: Float64, 
                                   hx_action_mode: HXAction) -> None:
        let sup_side_mdot = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].mass_flow_rate
        
        let dmd_side_mdot_min = self.demand_side_loop.mass_flow_rate_min
        self.calculate(state, sup_side_mdot, dmd_side_mdot_min)
        let leaving_temp_min_flow = self.supply_side_loop.outlet_temp
        
        let dmd_side_mdot_max = self.demand_side_loop.mass_flow_rate_max
        self.calculate(state, sup_side_mdot, dmd_side_mdot_max)
        let leaving_temp_full_flow = self.supply_side_loop.outlet_temp

    fn one_time_init(inout self, state: AnyType) -> None:
        if self.my_one_time_flag:
            self.setup_output_vars(state)
            self.my_flag = True
            self.my_envrnflag = True
            self.my_one_time_flag = False
        
        if self.my_flag:
            self.my_flag = False

    fn update_comp_flow_data(inout self, state: AnyType) -> None:
        pass

    fn has_supply_side_tes(inout self, state: AnyType) -> Bool:
        return False


struct PlantHeatExchangerFluidToFluidData:
    var number_of_plant_fluid_hxs: Int32
    var get_input: Bool
    var fluid_hx: DynamicVector[HeatExchangerStruct]

    fn __init__(inout self):
        self.number_of_plant_fluid_hxs = 0
        self.get_input = True


fn get_fluid_heat_exchanger_input(state: AnyType) -> None:
    state.data_plant_hx_fluid_to_fluid.number_of_plant_fluid_hxs = 0
