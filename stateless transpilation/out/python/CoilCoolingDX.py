from __future__ import annotations
from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Tuple, Any
from enum import Enum, auto
import math

# ============================================================================
# External type stubs and protocols
# ============================================================================

class CoilMode(Enum):
    Normal = auto()
    SubcoolReheat = auto()

class CoilType(Enum):
    Invalid = auto()
    CoolingDX = auto()

class FanType(Enum):
    Invalid = auto()

class FanOp(Enum):
    Cycling = auto()

class CapControlMethod(Enum):
    pass

class NodeData(Protocol):
    Temp: float
    HumRat: float
    MassFlowRate: float
    Press: float
    Quality: float
    MassFlowRateMax: float
    MassFlowRateMin: float
    MassFlowRateMaxAvail: float
    MassFlowRateMinAvail: float
    Enthalpy: float
    OutAirWetBulb: float

class Schedule(Protocol):
    pass

class CoilCoolingDXPerformanceBase(Protocol):
    pass

# ============================================================================
# Data structures
# ============================================================================

@dataclass
class HeatReclaimDataBase:
    Name: str = ""
    SourceType: str = ""
    AvailCapacity: float = 0.0

@dataclass
class CoilCoolingDXInputSpecification:
    name: str = ""
    evaporator_inlet_node_name: str = ""
    evaporator_outlet_node_name: str = ""
    availability_schedule_name: str = ""
    condenser_zone_name: str = ""
    condenser_inlet_node_name: str = ""
    condenser_outlet_node_name: str = ""
    performance_object_name: str = ""
    condensate_collection_water_storage_tank_name: str = ""
    evaporative_condenser_supply_water_storage_tank_name: str = ""

@dataclass
class CoilCoolingDX:
    original_input_specs: CoilCoolingDXInputSpecification = field(default_factory=CoilCoolingDXInputSpecification)
    name: str = ""
    coil_type: CoilType = CoilType.Invalid
    coil_report_num: int = -1
    my_one_time_init_flag: bool = True
    evap_inlet_node_index: int = 0
    evap_outlet_node_index: int = 0
    avail_sched: Optional[Schedule] = None
    cond_inlet_node_index: int = 0
    cond_outlet_node_index: int = 0
    performance: Optional[CoilCoolingDXPerformanceBase] = None
    condensate_tank_index: int = 0
    condensate_tank_supply_arrid: int = 0
    condensate_volume_flow: float = 0.0
    condensate_volume_consumption: float = 0.0
    evaporative_cond_supply_tank_index: int = 0
    evaporative_cond_supply_tank_arrid: int = 0
    evaporative_cond_supply_tank_volume_flow: float = 0.0
    evaporative_cond_supply_tank_consump: float = 0.0
    evap_cond_pump_elec_power: float = 0.0
    evap_cond_pump_elec_consumption: float = 0.0
    air_loop_num: int = 0
    supply_fan_index: int = 0
    supply_fan_type: FanType = FanType.Invalid
    supply_fan_name: str = ""
    subcool_reheat_flag: bool = False
    total_cooling_energy_rate: float = 0.0
    total_cooling_energy: float = 0.0
    sens_cooling_energy_rate: float = 0.0
    sens_cooling_energy: float = 0.0
    lat_cooling_energy_rate: float = 0.0
    lat_cooling_energy: float = 0.0
    cooling_coil_runtime_fraction: float = 0.0
    elec_cooling_power: float = 0.0
    elec_cooling_consumption: float = 0.0
    air_mass_flow_rate: float = 0.0
    inlet_air_dry_bulb_temp: float = 0.0
    inlet_air_hum_rat: float = 0.0
    outlet_air_dry_bulb_temp: float = 0.0
    outlet_air_hum_rat: float = 0.0
    part_load_ratio_report: float = 0.0
    run_time_fraction: float = 0.0
    speed_num_report: int = 0
    speed_ratio_report: float = 0.0
    waste_heat_energy_rate: float = 0.0
    waste_heat_energy: float = 0.0
    recovered_heat_energy: float = 0.0
    recovered_heat_energy_rate: float = 0.0
    condenser_inlet_temperature: float = 0.0
    dehumidification_mode: CoilMode = CoilMode.Normal
    report_coil_final_sizes: bool = True
    is_secondary_dx_coil_in_zone: bool = False
    sec_coil_sens_heat_rej_energy_rate: float = 0.0
    sec_coil_sens_heat_rej_energy: float = 0.0
    reclaim_heat: HeatReclaimDataBase = field(default_factory=HeatReclaimDataBase)
    is_hundred_percent_doas: bool = False

    @staticmethod
    def make_performance_subclass(state: Any, performance_object_name: str) -> Optional[CoilCoolingDXPerformanceBase]:
        a205_object_name = "Coil:Cooling:DX:CurveFit:Performance"
        curve_fit_object_name = "Coil:Cooling:DX:CurveFit:Performance"
        
        if CoilCoolingDX._find_performance_subclass(state, a205_object_name, performance_object_name):
            return None
        if CoilCoolingDX._find_performance_subclass(state, curve_fit_object_name, performance_object_name):
            return None
        
        return None

    @staticmethod
    def factory(state: Any, coil_name: str) -> int:
        if state.dataCoilCoolingDX.coil_cooling_dx_get_input_flag:
            CoilCoolingDX.get_input(state)
            state.dataCoilCoolingDX.coil_cooling_dx_get_input_flag = False
        
        handle = -1
        coil_name_upper = coil_name.upper()
        for this_coil in state.dataCoilCoolingDX.coil_cooling_dxs:
            handle += 1
            if coil_name_upper == this_coil.name.upper():
                return handle
        return -1

    @staticmethod
    def get_input(state: Any) -> None:
        input_processor = state.dataInputProcessing.inputProcessor
        coil_instances = input_processor.epJSON.get(state.dataCoilCoolingDX.coil_cooling_dx_object_name)
        
        if not coil_instances:
            return
        
        for coil_instance_key, coil_fields in coil_instances.items():
            input_specs = CoilCoolingDXInputSpecification()
            input_specs.name = coil_instance_key.upper()
            input_specs.evaporator_inlet_node_name = coil_fields.get("evaporator_inlet_node_name", "")
            input_specs.evaporator_outlet_node_name = coil_fields.get("evaporator_outlet_node_name", "")
            input_specs.availability_schedule_name = coil_fields.get("availability_schedule_name", "")
            input_specs.condenser_zone_name = coil_fields.get("condenser_zone_name", "")
            input_specs.condenser_inlet_node_name = coil_fields.get("condenser_inlet_node_name", "")
            input_specs.condenser_outlet_node_name = coil_fields.get("condenser_outlet_node_name", "")
            input_specs.performance_object_name = coil_fields.get("performance_object_name", "")
            input_specs.condensate_collection_water_storage_tank_name = coil_fields.get("condensate_collection_water_storage_tank_name", "")
            input_specs.evaporative_condenser_supply_water_storage_tank_name = coil_fields.get("evaporative_condenser_supply_water_storage_tank_name", "")
            
            this_coil = CoilCoolingDX()
            this_coil.instantiate_from_input_spec(state, input_specs)
            state.dataCoilCoolingDX.coil_cooling_dxs.append(this_coil)

    @staticmethod
    def clear_state() -> None:
        pass

    @staticmethod
    def report_all_standard_ratings(state: Any) -> None:
        if not state.dataCoilCoolingDX.coil_cooling_dxs:
            return
        
        CONV_FROM_SI_TO_IP = 3.412141633
        
        if state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag:
            state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag = False
        
        for coil in state.dataCoilCoolingDX.coil_cooling_dxs:
            if coil.performance:
                pass

    def instantiate_from_input_spec(self, state: Any, input_data: CoilCoolingDXInputSpecification) -> None:
        self.original_input_specs = input_data
        self.name = input_data.name
        self.coil_type = CoilType.CoolingDX
        self.reclaim_heat.Name = self.name
        self.reclaim_heat.SourceType = state.dataCoilCoolingDX.coil_cooling_dx_object_name

    def one_time_init(self, state: Any) -> None:
        pass

    def getNumModes(self) -> int:
        num_modes = 1
        if self.performance and hasattr(self.performance, 'maxAvailCoilMode'):
            if self.performance.maxAvailCoilMode != CoilMode.Normal:
                num_modes += 1
        return num_modes

    def getOpModeCapFTIndex(self, mode: CoilMode = CoilMode.Normal) -> int:
        if self.performance:
            return 0
        return 0

    def setData(self, fan_index: int, fan_type: FanType, fan_name: str, air_loop_num: int) -> None:
        self.supply_fan_index = fan_index
        self.supply_fan_name = fan_name
        self.supply_fan_type = fan_type
        self.air_loop_num = air_loop_num

    def getFixedData(self) -> Tuple[int, int, int, int, Any, float]:
        num_speeds = 0
        if self.performance:
            pass
        return (self.evap_inlet_node_index, self.evap_outlet_node_index, self.cond_inlet_node_index, num_speeds, None, 0.0)

    def getDataAfterSizing(self, state: Any) -> Tuple[float, float, List[float], List[float]]:
        return (0.0, 0.0, [], [])

    @staticmethod
    def pass_through_node_data(in_node: NodeData, out_node: NodeData) -> None:
        out_node.MassFlowRate = in_node.MassFlowRate
        out_node.Press = in_node.Press
        out_node.Quality = in_node.Quality
        out_node.MassFlowRateMax = in_node.MassFlowRateMax
        out_node.MassFlowRateMin = in_node.MassFlowRateMin
        out_node.MassFlowRateMaxAvail = in_node.MassFlowRateMaxAvail
        out_node.MassFlowRateMinAvail = in_node.MassFlowRateMinAvail

    def size(self, state: Any) -> None:
        if self.performance:
            self.performance.parentName = self.name

    def simulate(self, state: Any, coil_mode: CoilMode, speed_num: int, speed_ratio: float, 
                 fan_op: FanOp, single_mode: bool, load_shr: float = -1.0) -> None:
        if self.my_one_time_init_flag:
            self.one_time_init(state)
            self.my_one_time_init_flag = False

    def condMassFlowRate(self, state: Any, mode: CoilMode) -> float:
        return 0.0

    def setToHundredPercentDOAS(self) -> None:
        if self.performance:
            pass

    @staticmethod
    def _find_performance_subclass(state: Any, object_to_find: str, idd_performance_name: str) -> bool:
        ip = state.dataInputProcessing.inputProcessor
        if ip and hasattr(ip, 'epJSON'):
            json_dict = ip.epJSON.get(object_to_find)
            if json_dict:
                for key in json_dict:
                    if key.upper() == idd_performance_name.upper():
                        return True
        return False

@dataclass
class CoilCoolingDXData:
    coil_cooling_dxs: List[CoilCoolingDX] = field(default_factory=list)
    coil_cooling_dx_get_input_flag: bool = True
    coil_cooling_dx_object_name: str = "Coil:Cooling:DX"
    coil_type: CoilType = CoilType.CoolingDX
    still_need_to_report_standard_ratings: bool = True

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.coil_cooling_dxs.clear()
        self.coil_cooling_dx_get_input_flag = True
        self.still_need_to_report_standard_ratings = True

def populate_cooling_coil_standard_rating_information(eio: Any, coil_name: str, capacity: float, 
                                                      eer: float, seer_user: float, seer_standard: float, 
                                                      ieer: float, ahri2023_standard_ratings: bool) -> None:
    CONV_FROM_SI_TO_IP = 3.412141633
    if not ahri2023_standard_ratings:
        format_str = " DX Cooling Coil Standard Rating Information, {}, {}, {:.1f}, {:.2f}, {:.2f}, {:.2f}, {:.2f}, {:.1f}\n"
    else:
        format_str = " DX Cooling Coil AHRI 2023 Standard Rating Information, {}, {}, {:.1f}, {:.2f}, {:.2f}, {:.2f}, {:.2f}, {:.1f}\n"
