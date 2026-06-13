from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Protocol
from enum import IntEnum
import math


class Psychrometrics(Protocol):
    @staticmethod
    def PsyCpAirFnW(humidity_ratio: float) -> float: ...
    @staticmethod
    def PsyHFnTdbW(tdb: float, w: float) -> float: ...
    @staticmethod
    def PsyDeltaHSenFnTdb2W2Tdb1W1(tdb2: float, w2: float, tdb1: float, w1: float) -> float: ...
    @staticmethod
    def PsyDeltaHSenFnTdb2Tdb1W(tdb2: float, tdb1: float, w: float) -> float: ...


class WaterCoils(Protocol):
    @staticmethod
    def SimulateWaterCoilComponents(state: Any, comp_name: str, first_hvac_iteration: bool, comp_num: int) -> None: ...


class PlantUtilities(Protocol):
    @staticmethod
    def SetActuatedBranchFlowRate(state: Any, flow_rate: float, node: int, plant_loc: Any, autodesk_optional: bool) -> None: ...


class BaseboardRadiator(Protocol):
    @staticmethod
    def SimHWConvective(state: Any, comp_num: int, load_met: list) -> None: ...


class SteamBaseboardRadiator(Protocol):
    @staticmethod
    def CalcSteamBaseboard(state: Any, comp_num: int, load_met: list) -> None: ...


class HWBaseboardRadiator(Protocol):
    @staticmethod
    def CalcHWBaseboard(state: Any, comp_num: int, load_met: list) -> None: ...


class FanCoilUnits(Protocol):
    @staticmethod
    def Calc4PipeFanCoil(state: Any, comp_num: int, controlled_zone_index: Optional[int], first_hvac_iteration: bool, load_met: list) -> None: ...


class OutdoorAirUnit(Protocol):
    @staticmethod
    def CalcOAUnitCoilComps(state: Any, comp_num: int, first_hvac_iteration: bool, equip_index: Optional[int], load_met: list) -> None: ...


class UnitHeater(Protocol):
    @staticmethod
    def CalcUnitHeaterComponents(state: Any, comp_num: int, first_hvac_iteration: bool, load_met: list) -> None: ...


class UnitVentilator(Protocol):
    @staticmethod
    def CalcUnitVentilatorComponents(state: Any, comp_num: int, first_hvac_iteration: bool, load_met: list) -> None: ...


class VentilatedSlab(Protocol):
    @staticmethod
    def CalcVentilatedSlabComps(state: Any, comp_num: int, first_hvac_iteration: bool, load_met: list) -> None: ...


class Util(Protocol):
    @staticmethod
    def FindItem(item: str, list_items: List[str], num_items: int) -> int: ...
    @staticmethod
    def makeUPPER(text: str) -> str: ...
    @staticmethod
    def SameString(str1: str, str2: str) -> bool: ...


class PlantLocation(Protocol):
    loop_num: int


@dataclass
class IntervalHalf:
    max_flow: float = 0.0
    min_flow: float = 0.0
    max_result: float = 0.0
    min_result: float = 0.0
    mid_flow: float = 0.0
    mid_result: float = 0.0
    max_flow_calc: bool = False
    min_flow_calc: bool = False
    min_flow_result: bool = False
    norm_flow_calc: bool = False


@dataclass
class ZoneEquipControllerProps:
    set_point: float = 0.0
    max_set_point: float = 0.0
    min_set_point: float = 0.0
    sensed_value: float = 0.0
    calculated_set_point: float = 0.0


class GeneralRoutinesEquipNums(IntEnum):
    PARALLEL_PIU_REHEAT_NUM = 1
    SERIES_PIU_REHEAT_NUM = 2
    HEATING_COIL_WATER_NUM = 3
    BB_WATER_CONV_ONLY_NUM = 4
    BB_STEAM_RAD_CONV_NUM = 5
    BB_WATER_RAD_CONV_NUM = 6
    FOUR_PIPE_FAN_COIL_NUM = 7
    OUTDOOR_AIR_UNIT_NUM = 8
    UNIT_HEATER_NUM = 9
    UNIT_VENTILATOR_NUM = 10
    VENTILATED_SLAB_NUM = 11


class AirLoopHVACCompType(IntEnum):
    INVALID = -1
    SUPPLY_PLENUM = 0
    ZONE_SPLITTER = 1
    ZONE_MIXER = 2
    RETURN_PLENUM = 3
    NUM = 4


AIR_LOOP_HVAC_COMP_TYPE_NAMES_UC = [
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:RETURNPLENUM"
]

LIST_OF_COMPONENTS = [
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "COIL:HEATING:WATER",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:FOURPIPEFANCOIL",
    "ZONEHVAC:OUTDOORAIRUNIT",
    "ZONEHVAC:UNITHEATER",
    "ZONEHVAC:UNITVENTILATOR",
    "ZONEHVAC:VENTILATEDSLAB"
]

MAX_ITER = 25
ITER_FAC = 1.0 / (2 ** (MAX_ITER - 3))
I_REVERSE_ACTION = 1
I_NORMAL_ACTION = 2
BB_ITER_LIMIT = 0.00001


def control_comp_output(
    state: Any,
    comp_name: str,
    comp_type: str,
    comp_num: int,
    first_hvac_iteration: bool,
    q_zn_req: float,
    actuated_node: int,
    max_flow: float,
    min_flow: float,
    control_offset: float,
    control_comp_type_num: int,
    comp_err_index: int,
    temp_in_node: Optional[int] = None,
    temp_out_node: Optional[int] = None,
    air_mass_flow: Optional[float] = None,
    action: Optional[int] = None,
    equip_index: Optional[int] = None,
    plant_loc: Optional[PlantLocation] = None,
    controlled_zone_index: Optional[int] = None,
    psychrometrics: Any = None,
    water_coils: Any = None,
    plant_utilities: Any = None,
    util: Any = None,
) -> tuple:
    """Control component output via interval halving."""
    
    if plant_loc is None:
        plant_loc = PlantLocation()
        plant_loc.loop_num = 0
    
    zone_inter_half = state.data_general_routines.zone_inter_half
    zone_controller = state.data_general_routines.zone_controller
    
    if control_comp_type_num != 0:
        sim_comp_num = control_comp_type_num
    else:
        sim_comp_num = util.FindItem(comp_type, LIST_OF_COMPONENTS, len(LIST_OF_COMPONENTS))
        control_comp_type_num = sim_comp_num
    
    iter_count = 0
    converged = False
    water_coil_air_flow_control = False
    load_met = 0.0
    halving_prec = 0.0
    cp_air = 0.0
    
    zone_controller.set_point = 0.0
    
    zone_inter_half.max_flow_calc = True
    zone_inter_half.min_flow_calc = False
    zone_inter_half.norm_flow_calc = False
    zone_inter_half.min_flow_result = False
    zone_inter_half.max_result = 1.0
    zone_inter_half.min_result = 0.0
    
    while not converged:
        if first_hvac_iteration:
            state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail = max_flow
            state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail = min_flow
            if min_flow > max_flow:
                # Error handling would go here
                pass
        
        if (sim_comp_num == 3) and (air_mass_flow is None):
            zone_controller.max_set_point = state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail
            zone_controller.min_set_point = state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail
        else:
            zone_controller.max_set_point = min(
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_max_avail,
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_max
            )
            zone_controller.min_set_point = max(
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_min_avail,
                state.data_loop_nodes.node[actuated_node].mass_flow_rate_min
            )
        
        if zone_inter_half.max_flow_calc:
            zone_controller.calculated_set_point = zone_controller.max_set_point
            zone_inter_half.max_flow = zone_controller.max_set_point
            zone_inter_half.max_flow_calc = False
            zone_inter_half.min_flow_calc = True
        
        elif zone_inter_half.min_flow_calc:
            zone_inter_half.max_result = zone_controller.sensed_value
            zone_controller.calculated_set_point = zone_controller.min_set_point
            zone_inter_half.min_flow = zone_controller.min_set_point
            zone_inter_half.min_flow_calc = False
            zone_inter_half.min_flow_result = True
        
        elif zone_inter_half.min_flow_result:
            zone_inter_half.min_result = zone_controller.sensed_value
            halving_prec = (zone_inter_half.max_result - zone_inter_half.min_result) * ITER_FAC
            zone_inter_half.mid_flow = (zone_inter_half.max_flow + zone_inter_half.min_flow) / 2.0
            zone_controller.calculated_set_point = (zone_inter_half.max_flow + zone_inter_half.min_flow) / 2.0
            zone_inter_half.min_flow_result = False
            zone_inter_half.norm_flow_calc = True
        
        elif zone_inter_half.norm_flow_calc:
            zone_inter_half.mid_result = zone_controller.sensed_value
            
            if zone_inter_half.max_result == zone_inter_half.min_result:
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
                if 4 <= sim_comp_num <= 6:
                    zone_controller.calculated_set_point = 0.0
                else:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                
                if plant_loc.loop_num != 0:
                    plant_utilities.SetActuatedBranchFlowRate(
                        state, zone_controller.calculated_set_point, actuated_node, plant_loc, False
                    )
                else:
                    state.data_loop_nodes.node[actuated_node].mass_flow_rate = zone_controller.calculated_set_point
                return (comp_num, control_comp_type_num, comp_err_index)
            
            if zone_inter_half.max_result <= zone_inter_half.min_result:
                if water_coil_air_flow_control:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                else:
                    zone_controller.calculated_set_point = zone_inter_half.min_flow
                converged = True
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
            else:
                if zone_controller.set_point <= zone_inter_half.min_result:
                    zone_controller.calculated_set_point = zone_inter_half.min_flow
                    converged = True
                    zone_inter_half.max_flow_calc = True
                    zone_inter_half.min_flow_calc = False
                    zone_inter_half.norm_flow_calc = False
                    zone_inter_half.min_flow_result = False
                    zone_inter_half.max_result = 1.0
                    zone_inter_half.min_result = 0.0
                
                elif zone_controller.set_point >= zone_inter_half.max_result:
                    zone_controller.calculated_set_point = zone_inter_half.max_flow
                    converged = True
                    zone_inter_half.max_flow_calc = True
                    zone_inter_half.min_flow_calc = False
                    zone_inter_half.norm_flow_calc = False
                    zone_inter_half.min_flow_result = False
                    zone_inter_half.max_result = 1.0
                    zone_inter_half.min_result = 0.0
                
                elif zone_controller.set_point >= zone_inter_half.mid_result:
                    zone_controller.calculated_set_point = (zone_inter_half.max_flow + zone_inter_half.mid_flow) / 2.0
                    zone_inter_half.min_flow = zone_inter_half.mid_flow
                    zone_inter_half.min_result = zone_inter_half.mid_result
                    zone_inter_half.mid_flow = (zone_inter_half.max_flow + zone_inter_half.mid_flow) / 2.0
                
                else:
                    zone_controller.calculated_set_point = (zone_inter_half.min_flow + zone_inter_half.mid_flow) / 2.0
                    zone_inter_half.max_flow = zone_inter_half.mid_flow
                    zone_inter_half.max_result = zone_inter_half.mid_result
                    zone_inter_half.mid_flow = (zone_inter_half.min_flow + zone_inter_half.mid_flow) / 2.0
        
        if zone_controller.calculated_set_point > zone_controller.max_set_point:
            zone_controller.calculated_set_point = zone_controller.max_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        elif zone_controller.calculated_set_point < zone_controller.min_set_point:
            zone_controller.calculated_set_point = zone_controller.min_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        
        if (iter_count > MAX_ITER / 2) and (zone_controller.calculated_set_point < state.data_branch_air_loop_plant.mass_flow_tolerance):
            zone_controller.calculated_set_point = zone_controller.min_set_point
            converged = True
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
        
        if plant_loc.loop_num != 0:
            plant_utilities.SetActuatedBranchFlowRate(
                state, zone_controller.calculated_set_point, actuated_node, plant_loc, False
            )
        else:
            state.data_loop_nodes.node[actuated_node].mass_flow_rate = zone_controller.calculated_set_point
        
        denom = math.copysign(max(abs(q_zn_req), 100.0), q_zn_req)
        if action is not None:
            if action == I_NORMAL_ACTION:
                denom = max(abs(q_zn_req), 100.0)
            elif action == I_REVERSE_ACTION:
                denom = -max(abs(q_zn_req), 100.0)
        
        if sim_comp_num in (1, 2):
            water_coils.SimulateWaterCoilComponents(state, comp_name, first_hvac_iteration, comp_num)
            cp_air = psychrometrics.PsyCpAirFnW(state.data_loop_nodes.node[temp_out_node].hum_rat)
            load_met = cp_air * state.data_loop_nodes.node[temp_out_node].mass_flow_rate * (
                state.data_loop_nodes.node[temp_out_node].temp - state.data_loop_nodes.node[temp_in_node].temp
            )
            zone_controller.sensed_value = (load_met - q_zn_req) / denom
        
        elif sim_comp_num == 3:
            water_coils.SimulateWaterCoilComponents(state, comp_name, first_hvac_iteration, comp_num)
            cp_air = psychrometrics.PsyCpAirFnW(state.data_loop_nodes.node[temp_out_node].hum_rat)
            if air_mass_flow is not None:
                load_met = air_mass_flow * cp_air * state.data_loop_nodes.node[temp_out_node].temp
                zone_controller.sensed_value = (load_met - q_zn_req) / denom
            else:
                water_coil_air_flow_control = True
                load_met = state.data_loop_nodes.node[temp_out_node].mass_flow_rate * cp_air * (
                    state.data_loop_nodes.node[temp_out_node].temp - state.data_loop_nodes.node[temp_in_node].temp
                )
                zone_controller.sensed_value = (load_met - q_zn_req) / denom
        
        # Other sim_comp_num cases would be handled similarly with subsystem calls
        
        if abs(zone_controller.sensed_value) <= control_offset or abs(zone_controller.sensed_value) <= halving_prec:
            zone_inter_half.max_flow_calc = True
            zone_inter_half.min_flow_calc = False
            zone_inter_half.norm_flow_calc = False
            zone_inter_half.min_flow_result = False
            zone_inter_half.max_result = 1.0
            zone_inter_half.min_result = 0.0
            break
        
        if not converged:
            if bb_converge_check(sim_comp_num, zone_inter_half.max_flow, zone_inter_half.min_flow):
                zone_inter_half.max_flow_calc = True
                zone_inter_half.min_flow_calc = False
                zone_inter_half.norm_flow_calc = False
                zone_inter_half.min_flow_result = False
                zone_inter_half.max_result = 1.0
                zone_inter_half.min_result = 0.0
                break
        
        iter_count += 1
        if (iter_count > MAX_ITER) and (not state.data_global.warmup_flag):
            # Error reporting would go here
            break
        
        if iter_count > MAX_ITER * 2:
            break
    
    return (comp_num, control_comp_type_num, comp_err_index)


def bb_converge_check(sim_comp_num: int, max_flow: float, min_flow: float) -> bool:
    """Check baseboard convergence."""
    if sim_comp_num not in (GeneralRoutinesEquipNums.BB_STEAM_RAD_CONV_NUM, GeneralRoutinesEquipNums.BB_WATER_RAD_CONV_NUM):
        return False
    else:
        if (max_flow - min_flow) > BB_ITER_LIMIT:
            return False
        else:
            return True


def check_sys_sizing(state: Any, comp_type: str, comp_name: str) -> None:
    """Check that system sizing run has been done."""
    if not state.data_size.sys_sizing_run_done:
        # Error reporting would go here
        pass


def check_this_air_system_for_sizing(state: Any, air_loop_num: int) -> bool:
    """Check if this air system has sizing."""
    air_loop_was_sized = False
    if state.data_size.sys_sizing_run_done:
        for i in range(state.data_size.num_sys_siz_input):
            if state.data_size.sys_siz_input[i].air_loop_num == air_loop_num:
                air_loop_was_sized = True
                break
    return air_loop_was_sized


def check_zone_sizing(state: Any, comp_type: str, comp_name: str) -> None:
    """Check that zone sizing run has been done."""
    if not state.data_size.zone_sizing_run_done:
        # Error reporting would go here
        pass


def check_this_zone_for_sizing(state: Any, zone_num: int) -> bool:
    """Check if this zone has sizing."""
    zone_was_sized = False
    if state.data_size.zone_sizing_run_done:
        for i in range(state.data_size.num_zone_siz_input):
            if state.data_size.zone_siz_input[i].zone_num == zone_num:
                zone_was_sized = True
                break
    return zone_was_sized


def validate_component(
    state: Any,
    comp_type: str,
    comp_name: str,
    call_string: str,
    comp_val_type: Optional[str] = None,
) -> bool:
    """Validate component type-name pair."""
    is_not_ok = False
    
    comp_type_upper = comp_type.upper()
    if comp_type_upper in ("HEATPUMP:AIRTOWATER:COOLING", "HEATPUMP:AIRTOWATER:HEATING"):
        comp_type_upper = "HEATPUMP:AIRTOWATER"
    
    if comp_val_type is None:
        item_num = state.data_input_processing.input_processor.get_object_item_num(state, comp_type_upper, comp_name)
    else:
        item_num = state.data_input_processing.input_processor.get_object_item_num(state, comp_type_upper, comp_val_type, comp_name)
    
    if item_num < 0:
        is_not_ok = True
    elif item_num == 0:
        is_not_ok = True
    
    return is_not_ok


def calc_basin_heater_power(
    state: Any,
    capacity: float,
    sched: Optional[Any],
    set_point_temp: float,
) -> float:
    """Calculate basin heater power."""
    power = 0.0
    
    if sched is not None:
        basin_heater_sch = sched.get_current_val()
        if capacity > 0.0 and basin_heater_sch > 0.0:
            power = max(0.0, capacity * (set_point_temp - state.data_envrn.out_dry_bulb_temp))
    else:
        if capacity > 0.0:
            power = max(0.0, capacity * (set_point_temp - state.data_envrn.out_dry_bulb_temp))
    
    return power


def test_air_path_integrity(state: Any) -> bool:
    """Test supply, return and overall air path integrity."""
    err_found = False
    
    # Array allocations and initialization
    num_sap_nodes = [[0] * state.data_hvac_global.num_primary_air_sys for _ in range(state.data_loop_nodes.num_of_nodes)]
    num_rap_nodes = [[0] * state.data_hvac_global.num_primary_air_sys for _ in range(state.data_loop_nodes.num_of_nodes)]
    val_ret_a_paths = [[0] * state.data_hvac_global.num_primary_air_sys for _ in range(state.data_loop_nodes.num_of_nodes)]
    val_sup_a_paths = [[0] * state.data_hvac_global.num_primary_air_sys for _ in range(state.data_loop_nodes.num_of_nodes)]
    
    err_flag = False
    test_supply_air_path_integrity(state, err_flag)
    if err_flag:
        err_found = True
    
    err_flag = False
    test_return_air_path_integrity(state, err_flag, val_ret_a_paths)
    if err_flag:
        err_found = True
    
    for loop in range(state.data_hvac_global.num_primary_air_sys):
        if val_ret_a_paths[0][loop] != 0:
            continue
        if state.data_air_loop.air_to_zone_node_info[loop].num_return_nodes <= 0:
            continue
        val_ret_a_paths[0][loop] = state.data_air_loop.air_to_zone_node_info[loop].zone_equip_return_node_num[0]
    
    for loop in range(state.data_hvac_global.num_primary_air_sys):
        for loop1 in range(state.data_loop_nodes.num_of_nodes):
            test_node = val_ret_a_paths[loop1][loop]
            count = 0
            for loop2 in range(state.data_hvac_global.num_primary_air_sys):
                for loop3 in range(state.data_loop_nodes.num_of_nodes):
                    if loop2 == loop and loop1 == loop3:
                        continue
                    if val_ret_a_paths[loop3][loop2] == 0:
                        break
                    if val_ret_a_paths[loop3][loop2] == test_node:
                        count += 1
            
            if count > 0:
                err_found = True
    
    return err_found


def test_supply_air_path_integrity(state: Any, err_found: bool) -> None:
    """Test supply air path integrity."""
    # Implementation would include detailed path validation
    pass


def test_return_air_path_integrity(state: Any, err_found: bool, val_ret_a_paths: list) -> None:
    """Test return air path integrity."""
    # Implementation would include detailed path validation
    pass


def calc_component_sensible_latent_output(
    mass_flow: float,
    tdb2: float,
    w2: float,
    tdb1: float,
    w1: float,
    psychrometrics: Any,
) -> tuple:
    """Calculate sensible and latent output."""
    total_output = 0.0
    latent_output = 0.0
    sensible_output = 0.0
    
    if mass_flow > 0.0:
        total_output = mass_flow * (
            psychrometrics.PsyHFnTdbW(tdb2, w2) - psychrometrics.PsyHFnTdbW(tdb1, w1)
        )
        sensible_output = mass_flow * psychrometrics.PsyDeltaHSenFnTdb2W2Tdb1W1(tdb2, w2, tdb1, w1)
        latent_output = total_output - sensible_output
    
    return (sensible_output, latent_output, total_output)


def calc_zone_sensible_latent_output(
    mass_flow: float,
    tdb_equip: float,
    w_equip: float,
    tdb_zone: float,
    w_zone: float,
    psychrometrics: Any,
) -> tuple:
    """Calculate zone sensible and latent output."""
    total_output = 0.0
    latent_output = 0.0
    sensible_output = 0.0
    
    if mass_flow > 0.0:
        total_output = mass_flow * (
            psychrometrics.PsyHFnTdbW(tdb_equip, w_equip) - psychrometrics.PsyHFnTdbW(tdb_zone, w_zone)
        )
        sensible_output = mass_flow * psychrometrics.PsyDeltaHSenFnTdb2Tdb1W(tdb_equip, tdb_zone, w_zone)
        latent_output = total_output - sensible_output
    
    return (sensible_output, latent_output, total_output)


def calc_zone_sensible_output(
    mass_flow: float,
    tdb_equip: float,
    tdb_zone: float,
    w_zone: float,
    psychrometrics: Any,
) -> float:
    """Calculate zone sensible output."""
    sensible_output = 0.0
    if mass_flow > 0.0:
        sensible_output = mass_flow * psychrometrics.PsyDeltaHSenFnTdb2Tdb1W(tdb_equip, tdb_zone, w_zone)
    return sensible_output
