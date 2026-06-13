"""
PlantHeatExchangerFluidToFluid - Plant Heat Exchanger Fluid to Fluid Component

Ports EnergyPlus HeatExchanger:FluidToFluid model
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, Protocol, Any, List
import math

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


class FluidHXType(IntEnum):
    Invalid = -1
    CrossFlowBothUnMixed = 0
    CrossFlowBothMixed = 1
    CrossFlowSupplyLoopMixedDemandLoopUnMixed = 2
    CrossFlowSupplyLoopUnMixedDemandLoopMixed = 3
    CounterFlow = 4
    ParallelFlow = 5
    Ideal = 6
    Num = 7


class ControlType(IntEnum):
    Invalid = -1
    UncontrolledOn = 0
    OperationSchemeModulated = 1
    OperationSchemeOnOff = 2
    HeatingSetPointModulated = 3
    HeatingSetPointOnOff = 4
    CoolingSetPointModulated = 5
    CoolingSetPointOnOff = 6
    DualDeadBandSetPointModulated = 7
    DualDeadBandSetPointOnOff = 8
    CoolingDifferentialOnOff = 9
    CoolingSetPointOnOffWithComponentOverride = 10
    TrackComponentOnOff = 11
    Num = 12


class CtrlTempType(IntEnum):
    Invalid = -1
    WetBulbTemperature = 0
    DryBulbTemperature = 1
    LoopTemperature = 2
    Num = 3


class HXAction(IntEnum):
    Invalid = -1
    HeatingSupplySideLoop = 0
    CoolingSupplySideLoop = 1
    Num = 2


COMPONENT_CLASS_NAME = "HeatExchanger:FluidToFluid"

FLUID_HX_TYPE_NAMES = [
    "CrossFlowBothUnMixed",
    "CrossFlowBothMixed",
    "CrossFlowSupplyMixedDemandUnMixed",
    "CrossFlowSupplyUnMixedDemandMixed",
    "CounterFlow",
    "ParallelFlow",
    "Ideal"
]

FLUID_HX_TYPE_NAMES_UC = [
    "CROSSFLOWBOTHUNMIXED",
    "CROSSFLOWBOTHMIXED",
    "CROSSFLOWSUPPLYMIXEDDEMANDUNMIXED",
    "CROSSFLOWSUPPLYUNMIXEDDEMANDMIXED",
    "COUNTERFLOW",
    "PARALLELFLOW",
    "IDEAL"
]

CONTROL_TYPE_NAMES = [
    "UncontrolledOn",
    "OperationSchemeModulated",
    "OperationSchemeOnOff",
    "HeatingSetpointModulated",
    "HeatingSetpointOnOff",
    "CoolingSetpointModulated",
    "CoolingSetpointOnOff",
    "DualDeadbandSetpointModulated",
    "DualDeadbandSetpointOnOff",
    "CoolingDifferentialOnOff",
    "CoolingSetpointOnOffWithComponentOverride",
    "TrackComponentOnOff"
]

CONTROL_TYPE_NAMES_UC = [
    "UNCONTROLLEDON",
    "OPERATIONSCHEMEMODULATED",
    "OPERATIONSCHEMEONOFF",
    "HEATINGSETPOINTMODULATED",
    "HEATINGSETPOINTONOFF",
    "COOLINGSETPOINTMODULATED",
    "COOLINGSETPOINTONOFF",
    "DUALDEADBANDSETPOINTMODULATED",
    "DUALDEADBANDSETPOINTONOFF",
    "COOLINGDIFFERENTIALONOFF",
    "COOLINGSETPOINTONOFFWITHCOMPONENTOVERRIDE",
    "TRACKCOMPONENTONOFF"
]

CTRL_TEMP_TYPE_NAMES = [
    "WetBulbTemperature",
    "DryBulbTemperature",
    "Loop"
]

CTRL_TEMP_TYPE_NAMES_UC = [
    "WETBULBTEMPERATURE",
    "DRYBULBTEMPERATURE",
    "LOOP"
]


@dataclass
class PlantConnectionStruct:
    inlet_node_num: int = 0
    outlet_node_num: int = 0
    mass_flow_rate_min: float = 0.0
    mass_flow_rate_max: float = 0.0
    design_volume_flow_rate: float = 0.0
    design_volume_flow_rate_was_auto_sized: bool = False
    my_load: float = 0.0
    min_load: float = 0.0
    max_load: float = 0.0
    opt_load: float = 0.0
    inlet_temp: float = 0.0
    inlet_mass_flow_rate: float = 0.0
    outlet_temp: float = 0.0
    loop_num: int = 0
    loop_side_num: int = 0
    branch_num: int = 0
    comp_num: int = 0
    loop: Optional[Any] = None
    comp: Optional[Any] = None


@dataclass
class PlantLocatorStruct:
    inlet_node_num: int = 0
    loop_num: int = 0
    loop_side_num: int = 0
    branch_num: int = 0
    comp_num: int = 0
    comp: Optional[Any] = None


@dataclass
class HeatExchangerStruct:
    name: str = ""
    avail_sched: Optional[Any] = None
    heat_exchange_model_type: FluidHXType = FluidHXType.Invalid
    ua: float = 0.0
    ua_was_auto_sized: bool = False
    control_mode: ControlType = ControlType.Invalid
    set_point_node_num: int = 0
    temp_control_tol: float = 0.0
    control_signal_temp: CtrlTempType = CtrlTempType.Invalid
    min_operation_temp: float = -99999.0
    max_operation_temp: float = 99999.0
    demand_side_loop: PlantConnectionStruct = field(default_factory=PlantConnectionStruct)
    supply_side_loop: PlantConnectionStruct = field(default_factory=PlantConnectionStruct)
    heat_transfer_metering_end_use: Any = None
    component_user_name: str = ""
    component_type: Any = None
    other_comp_supply_side_loop: PlantLocatorStruct = field(default_factory=PlantLocatorStruct)
    other_comp_demand_side_loop: PlantLocatorStruct = field(default_factory=PlantLocatorStruct)
    sizing_factor: float = 1.0
    heat_transfer_rate: float = 0.0
    heat_transfer_energy: float = 0.0
    effectiveness: float = 0.0
    operation_status: float = 0.0
    dmd_side_modulate_solv_no_converge_error_count: int = 0
    dmd_side_modulate_solv_no_converge_error_index: int = 0
    dmd_side_modulate_solv_fail_error_count: int = 0
    dmd_side_modulate_solv_fail_error_index: int = 0
    my_one_time_flag: bool = True
    my_flag: bool = True
    my_envrnflag: bool = True

    @staticmethod
    def factory(state: Any, object_name: str) -> 'HeatExchangerStruct':
        if state.data_plant_hx_fluid_to_fluid.get_input:
            get_fluid_heat_exchanger_input(state)
            state.data_plant_hx_fluid_to_fluid.get_input = False
        
        for obj in state.data_plant_hx_fluid_to_fluid.fluid_hx:
            if obj.name == object_name:
                return obj
        
        raise RuntimeError(f"LocalPlantFluidHXFactory: Error getting inputs for object named: {object_name}")

    def on_init_loop_equip(self, state: Any, called_from_location: Any) -> None:
        self.initialize(state)

    def get_design_capacities(self, state: Any, called_from_location: Any) -> tuple:
        if called_from_location.loop_num == self.demand_side_loop.loop_num:
            min_load = 0.0
            max_load = self.demand_side_loop.max_load
            opt_load = self.demand_side_loop.max_load * 0.9
        elif called_from_location.loop_num == self.supply_side_loop.loop_num:
            self.size(state)
            min_load = 0.0
            max_load = self.supply_side_loop.max_load
            opt_load = self.supply_side_loop.max_load * 0.9
        return max_load, min_load, opt_load

    def simulate(self, state: Any, called_from_location: Any, first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
        self.initialize(state)
        
        if ((self.control_mode == ControlType.OperationSchemeModulated) or 
            (self.control_mode == ControlType.OperationSchemeOnOff)):
            if called_from_location.loop_num == self.supply_side_loop.loop_num:
                self.control(state, cur_load, first_hvac_iteration)
        else:
            self.control(state, cur_load, first_hvac_iteration)
        
        self.calculate(
            state,
            state.data_loop_nodes[self.supply_side_loop.inlet_node_num].mass_flow_rate,
            state.data_loop_nodes[self.demand_side_loop.inlet_node_num].mass_flow_rate
        )

    def setup_output_vars(self, state: Any) -> None:
        pass

    def initialize(self, state: Any) -> None:
        self.one_time_init(state)
        
        if (state.data_global.begin_envrnflag and self.my_envrnflag and 
            state.data_plnt.plant_first_sizes_okay_to_finalize):
            
            rho = self.demand_side_loop.loop.glycol.get_density(state, 273.15)
            self.demand_side_loop.mass_flow_rate_max = rho * self.demand_side_loop.design_volume_flow_rate
            
            rho = self.supply_side_loop.loop.glycol.get_density(state, 273.15)
            self.supply_side_loop.mass_flow_rate_max = rho * self.supply_side_loop.design_volume_flow_rate
            
            self.my_envrnflag = False
        
        if not state.data_global.begin_envrnflag:
            self.my_envrnflag = True
        
        self.demand_side_loop.inlet_temp = state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp
        self.supply_side_loop.inlet_temp = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp
        
        if self.control_mode == ControlType.CoolingSetPointOnOffWithComponentOverride:
            self.other_comp_supply_side_loop.comp.free_cool_cntrl_min_cntrl_temp = (
                state.data_loop_nodes[self.set_point_node_num].temp_set_point - self.temp_control_tol
            )

    def size(self, state: Any) -> None:
        plt_siz_num_sup_side = self.supply_side_loop.loop.plant_siz_num
        plt_siz_num_dmd_side = self.demand_side_loop.loop.plant_siz_num
        tmp_sup_side_design_vol_flow_rate = self.supply_side_loop.design_volume_flow_rate
        
        if self.supply_side_loop.design_volume_flow_rate_was_auto_sized:
            if plt_siz_num_sup_side > 0:
                if state.data_size.plant_siz_data[plt_siz_num_sup_side].des_vol_flow_rate >= 1e-6:
                    tmp_sup_side_design_vol_flow_rate = (
                        state.data_size.plant_siz_data[plt_siz_num_sup_side].des_vol_flow_rate * self.sizing_factor
                    )
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.supply_side_loop.design_volume_flow_rate = tmp_sup_side_design_vol_flow_rate
                else:
                    tmp_sup_side_design_vol_flow_rate = 0.0
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.supply_side_loop.design_volume_flow_rate = tmp_sup_side_design_vol_flow_rate
        
        tmp_dmd_side_design_vol_flow_rate = self.demand_side_loop.design_volume_flow_rate
        if self.demand_side_loop.design_volume_flow_rate_was_auto_sized:
            if tmp_sup_side_design_vol_flow_rate > 1e-6:
                tmp_dmd_side_design_vol_flow_rate = tmp_sup_side_design_vol_flow_rate
                if state.data_plnt.plant_first_sizes_okay_to_finalize:
                    self.demand_side_loop.design_volume_flow_rate = tmp_dmd_side_design_vol_flow_rate
            else:
                tmp_dmd_side_design_vol_flow_rate = 0.0
                if state.data_plnt.plant_first_sizes_okay_to_finalize:
                    self.demand_side_loop.design_volume_flow_rate = tmp_dmd_side_design_vol_flow_rate
        
        if self.ua_was_auto_sized:
            if plt_siz_num_sup_side > 0 and plt_siz_num_dmd_side > 0:
                loop_type = state.data_size.plant_siz_data[plt_siz_num_sup_side].loop_type
                
                if loop_type in (0, 1):  # Heating or Steam
                    tmp_delta_t_loop_to_loop = abs(
                        (state.data_size.plant_siz_data[plt_siz_num_sup_side].exit_temp - 
                         state.data_size.plant_siz_data[plt_siz_num_sup_side].delta_t) -
                        state.data_size.plant_siz_data[plt_siz_num_dmd_side].exit_temp
                    )
                elif loop_type in (2, 3):  # Cooling or Condenser
                    tmp_delta_t_loop_to_loop = abs(
                        (state.data_size.plant_siz_data[plt_siz_num_sup_side].exit_temp + 
                         state.data_size.plant_siz_data[plt_siz_num_sup_side].delta_t) -
                        state.data_size.plant_siz_data[plt_siz_num_dmd_side].exit_temp
                    )
                
                tmp_delta_t_loop_to_loop = max(2.0, tmp_delta_t_loop_to_loop)
                tmp_delta_t_sup_loop = state.data_size.plant_siz_data[plt_siz_num_sup_side].delta_t
                
                if tmp_sup_side_design_vol_flow_rate >= 1e-6:
                    cp = self.supply_side_loop.loop.glycol.get_specific_heat(state, 273.15)
                    rho = self.supply_side_loop.loop.glycol.get_density(state, 273.15)
                    tmp_des_cap = cp * rho * tmp_delta_t_sup_loop * tmp_sup_side_design_vol_flow_rate
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.ua = tmp_des_cap / tmp_delta_t_loop_to_loop
                else:
                    if state.data_plnt.plant_first_sizes_okay_to_finalize:
                        self.ua = 0.0
        
        if state.data_plnt.plant_first_sizes_okay_to_finalize:
            if plt_siz_num_sup_side > 0:
                loop_type = state.data_size.plant_siz_data[plt_siz_num_sup_side].loop_type
                if loop_type in (0, 1):
                    state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp = (
                        state.data_size.plant_siz_data[plt_siz_num_sup_side].exit_temp -
                        state.data_size.plant_siz_data[plt_siz_num_sup_side].delta_t
                    )
                elif loop_type in (2, 3):
                    state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp = (
                        state.data_size.plant_siz_data[plt_siz_num_sup_side].exit_temp +
                        state.data_size.plant_siz_data[plt_siz_num_sup_side].delta_t
                    )
            else:
                if self.supply_side_loop.loop.loop_demand_calc_scheme == 0:
                    state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp = (
                        state.data_loop_nodes[self.supply_side_loop.loop.temp_set_point_node_num].temp_set_point
                    )
                elif self.supply_side_loop.loop.loop_demand_calc_scheme == 1:
                    state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp = (
                        (state.data_loop_nodes[self.supply_side_loop.loop.temp_set_point_node_num].temp_set_point_hi +
                         state.data_loop_nodes[self.supply_side_loop.loop.temp_set_point_node_num].temp_set_point_lo) / 2.0
                    )
            
            if plt_siz_num_dmd_side > 0:
                state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp = (
                    state.data_size.plant_siz_data[plt_siz_num_dmd_side].exit_temp
                )
            else:
                if self.demand_side_loop.loop.loop_demand_calc_scheme == 0:
                    state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp = (
                        state.data_loop_nodes[self.demand_side_loop.loop.temp_set_point_node_num].temp_set_point
                    )
                elif self.demand_side_loop.loop.loop_demand_calc_scheme == 1:
                    state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp = (
                        (state.data_loop_nodes[self.demand_side_loop.loop.temp_set_point_node_num].temp_set_point_hi +
                         state.data_loop_nodes[self.demand_side_loop.loop.temp_set_point_node_num].temp_set_point_lo) / 2.0
                    )
            
            rho = self.supply_side_loop.loop.glycol.get_density(state, 273.15)
            sup_side_mdot = self.supply_side_loop.design_volume_flow_rate * rho
            rho = self.demand_side_loop.loop.glycol.get_density(state, 273.15)
            dmd_side_mdot = self.demand_side_loop.design_volume_flow_rate * rho
            
            self.calculate(state, sup_side_mdot, dmd_side_mdot)
            self.supply_side_loop.max_load = abs(self.heat_transfer_rate)
        
        self.update_comp_flow_data(state)

    def control(self, state: Any, my_load: float, first_hvac_iteration: bool) -> None:
        avail_sched_value = self.avail_sched.get_current_val()
        scheduled_off = avail_sched_value <= 0
        
        limit_tripped_off = False
        if (state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp < self.min_operation_temp or
            state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp < self.min_operation_temp):
            limit_tripped_off = True
        if (state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp > self.max_operation_temp or
            state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp > self.max_operation_temp):
            limit_tripped_off = True
        
        if not scheduled_off and not limit_tripped_off:
            if self.control_mode == ControlType.UncontrolledOn:
                mdot_sup_side = self.supply_side_loop.mass_flow_rate_max
                mdot_dmd_side = self.demand_side_loop.mass_flow_rate_max if mdot_sup_side > 1e-5 else 0.0
            
            elif self.control_mode == ControlType.OperationSchemeModulated:
                if abs(my_load) > 0.01:
                    if my_load < -0.01:
                        delta_t_cooling = self.supply_side_loop.inlet_temp - self.demand_side_loop.inlet_temp
                        if delta_t_cooling > self.temp_control_tol:
                            mdot_sup_side = self.supply_side_loop.mass_flow_rate_max
                            if mdot_sup_side > 1e-5:
                                cp = self.supply_side_loop.loop.glycol.get_specific_heat(
                                    state, self.supply_side_loop.inlet_temp
                                )
                                target_leaving_temp = self.supply_side_loop.inlet_temp - abs(my_load) / (cp * mdot_sup_side)
                                self.find_demand_side_loop_flow(state, target_leaving_temp, HXAction.CoolingSupplySideLoop)
                            else:
                                mdot_dmd_side = 0.0
                        else:
                            mdot_sup_side = 0.0
                            mdot_dmd_side = self.demand_side_loop.mass_flow_rate_max if first_hvac_iteration else 0.0
                    else:
                        delta_t_heating = self.demand_side_loop.inlet_temp - self.supply_side_loop.inlet_temp
                        if delta_t_heating > self.temp_control_tol:
                            mdot_sup_side = self.supply_side_loop.mass_flow_rate_max
                            if mdot_sup_side > 1e-5:
                                cp = self.supply_side_loop.loop.glycol.get_specific_heat(
                                    state, self.supply_side_loop.inlet_temp
                                )
                                target_leaving_temp = self.supply_side_loop.inlet_temp + abs(my_load) / (cp * mdot_sup_side)
                                self.find_demand_side_loop_flow(state, target_leaving_temp, HXAction.HeatingSupplySideLoop)
                            else:
                                mdot_dmd_side = 0.0
                        else:
                            mdot_sup_side = 0.0
                            mdot_dmd_side = self.demand_side_loop.mass_flow_rate_max if first_hvac_iteration else 0.0
                else:
                    mdot_sup_side = 0.0
                    mdot_dmd_side = 0.0
            
            elif self.control_mode in (ControlType.HeatingSetPointModulated, ControlType.HeatingSetPointOnOff,
                                       ControlType.CoolingSetPointModulated, ControlType.CoolingSetPointOnOff,
                                       ControlType.DualDeadBandSetPointModulated, ControlType.DualDeadBandSetPointOnOff,
                                       ControlType.CoolingDifferentialOnOff, ControlType.OperationSchemeOnOff,
                                       ControlType.CoolingSetPointOnOffWithComponentOverride):
                pass
        else:
            mdot_sup_side = 0.0
            mdot_dmd_side = 0.0

    def calculate(self, state: Any, sup_side_mdot: float, dmd_side_mdot: float) -> None:
        sup_side_loop_inlet_temp = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].temp
        dmd_side_loop_inlet_temp = state.data_loop_nodes[self.demand_side_loop.inlet_node_num].temp
        
        sup_side_loop_inlet_cp = self.supply_side_loop.loop.glycol.get_specific_heat(state, sup_side_loop_inlet_temp)
        dmd_side_loop_inlet_cp = self.demand_side_loop.loop.glycol.get_specific_heat(state, dmd_side_loop_inlet_temp)
        
        sup_side_cap_rate = sup_side_mdot * sup_side_loop_inlet_cp
        dmd_side_cap_rate = dmd_side_mdot * dmd_side_loop_inlet_cp
        min_cap_rate = min(sup_side_cap_rate, dmd_side_cap_rate)
        max_cap_rate = max(sup_side_cap_rate, dmd_side_cap_rate)
        
        if min_cap_rate > 0.0:
            if self.heat_exchange_model_type == FluidHXType.CrossFlowBothUnMixed:
                ntu = self.ua / min_cap_rate
                cap_ratio = min_cap_rate / max_cap_rate if max_cap_rate > 0 else 0
                self.effectiveness = 1.0 - math.exp((math.pow(ntu, 0.22) / cap_ratio) * 
                                                    (math.exp(-cap_ratio * math.pow(ntu, 0.78)) - 1.0))
                self.effectiveness = min(1.0, self.effectiveness)
            
            elif self.heat_exchange_model_type == FluidHXType.Ideal:
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

    def find_demand_side_loop_flow(self, state: Any, target_supply_side_loop_leaving_temp: float, hx_action_mode: HXAction) -> None:
        max_ite = 500
        acc = 1.0e-3
        
        sup_side_mdot = state.data_loop_nodes[self.supply_side_loop.inlet_node_num].mass_flow_rate
        
        dmd_side_mdot = self.demand_side_loop.mass_flow_rate_min
        self.calculate(state, sup_side_mdot, dmd_side_mdot)
        leaving_temp_min_flow = self.supply_side_loop.outlet_temp
        
        dmd_side_mdot = self.demand_side_loop.mass_flow_rate_max
        self.calculate(state, sup_side_mdot, dmd_side_mdot)
        leaving_temp_full_flow = self.supply_side_loop.outlet_temp
        
        if hx_action_mode == HXAction.HeatingSupplySideLoop:
            if ((leaving_temp_full_flow > target_supply_side_loop_leaving_temp) and 
                (target_supply_side_loop_leaving_temp > leaving_temp_min_flow)):
                pass
            elif ((target_supply_side_loop_leaving_temp >= leaving_temp_full_flow) and 
                  (leaving_temp_full_flow > leaving_temp_min_flow)):
                dmd_side_mdot = self.demand_side_loop.mass_flow_rate_max
            elif leaving_temp_min_flow >= target_supply_side_loop_leaving_temp:
                dmd_side_mdot = self.demand_side_loop.mass_flow_rate_min
        
        elif hx_action_mode == HXAction.CoolingSupplySideLoop:
            if ((leaving_temp_full_flow < target_supply_side_loop_leaving_temp) and 
                (target_supply_side_loop_leaving_temp < leaving_temp_min_flow)):
                pass
            elif ((target_supply_side_loop_leaving_temp <= leaving_temp_full_flow) and 
                  (leaving_temp_full_flow < leaving_temp_min_flow)):
                dmd_side_mdot = self.demand_side_loop.mass_flow_rate_max
            elif leaving_temp_min_flow <= target_supply_side_loop_leaving_temp:
                dmd_side_mdot = self.demand_side_loop.mass_flow_rate_min

    def one_time_init(self, state: Any) -> None:
        if self.my_one_time_flag:
            self.setup_output_vars(state)
            self.my_flag = True
            self.my_envrnflag = True
            self.my_one_time_flag = False
        
        if self.my_flag:
            self.my_flag = False

    def update_comp_flow_data(self, state: Any) -> None:
        pass

    def has_supply_side_tes(self, state: Any) -> bool:
        return False


@dataclass
class PlantHeatExchangerFluidToFluidData:
    number_of_plant_fluid_hxs: int = 0
    get_input: bool = True
    fluid_hx: List[HeatExchangerStruct] = field(default_factory=list)


def get_fluid_heat_exchanger_input(state: Any) -> None:
    state.data_plant_hx_fluid_to_fluid.number_of_plant_fluid_hxs = 0
    state.data_plant_hx_fluid_to_fluid.fluid_hx = []
