from memory import UnsafePointer
from collections.abc import Sized

alias CoilMode = UInt8
alias CoilModeTrait = Sized

alias COIL_MODE_NORMAL = CoilMode(0)
alias COIL_MODE_SUBCOOL_REHEAT = CoilMode(1)

alias CoilType = UInt8
alias COIL_TYPE_INVALID = CoilType(0)
alias COIL_TYPE_COOLING_DX = CoilType(1)

alias FanType = UInt8
alias FAN_TYPE_INVALID = FanType(0)

alias FanOp = UInt8
alias FAN_OP_CYCLING = FanOp(0)

struct NodeData:
    var temp: Float64
    var hum_rat: Float64
    var mass_flow_rate: Float64
    var press: Float64
    var quality: Float64
    var mass_flow_rate_max: Float64
    var mass_flow_rate_min: Float64
    var mass_flow_rate_max_avail: Float64
    var mass_flow_rate_min_avail: Float64
    var enthalpy: Float64
    var out_air_wet_bulb: Float64

    fn __init__(inout self):
        self.temp = 0.0
        self.hum_rat = 0.0
        self.mass_flow_rate = 0.0
        self.press = 0.0
        self.quality = 0.0
        self.mass_flow_rate_max = 0.0
        self.mass_flow_rate_min = 0.0
        self.mass_flow_rate_max_avail = 0.0
        self.mass_flow_rate_min_avail = 0.0
        self.enthalpy = 0.0
        self.out_air_wet_bulb = 0.0

struct HeatReclaimDataBase:
    var name: String
    var source_type: String
    var avail_capacity: Float64

    fn __init__(inout self):
        self.name = String()
        self.source_type = String()
        self.avail_capacity = 0.0

struct CoilCoolingDXInputSpecification:
    var name: String
    var evaporator_inlet_node_name: String
    var evaporator_outlet_node_name: String
    var availability_schedule_name: String
    var condenser_zone_name: String
    var condenser_inlet_node_name: String
    var condenser_outlet_node_name: String
    var performance_object_name: String
    var condensate_collection_water_storage_tank_name: String
    var evaporative_condenser_supply_water_storage_tank_name: String

    fn __init__(inout self):
        self.name = String()
        self.evaporator_inlet_node_name = String()
        self.evaporator_outlet_node_name = String()
        self.availability_schedule_name = String()
        self.condenser_zone_name = String()
        self.condenser_inlet_node_name = String()
        self.condenser_outlet_node_name = String()
        self.performance_object_name = String()
        self.condensate_collection_water_storage_tank_name = String()
        self.evaporative_condenser_supply_water_storage_tank_name = String()

struct CoilCoolingDX:
    var original_input_specs: CoilCoolingDXInputSpecification
    var name: String
    var coil_type: CoilType
    var coil_report_num: Int32
    var my_one_time_init_flag: Bool
    var evap_inlet_node_index: Int32
    var evap_outlet_node_index: Int32
    var avail_sched: UnsafePointer[UInt8]
    var cond_inlet_node_index: Int32
    var cond_outlet_node_index: Int32
    var performance: UnsafePointer[UInt8]
    var condensate_tank_index: Int32
    var condensate_tank_supply_arrid: Int32
    var condensate_volume_flow: Float64
    var condensate_volume_consumption: Float64
    var evaporative_cond_supply_tank_index: Int32
    var evaporative_cond_supply_tank_arrid: Int32
    var evaporative_cond_supply_tank_volume_flow: Float64
    var evaporative_cond_supply_tank_consump: Float64
    var evap_cond_pump_elec_power: Float64
    var evap_cond_pump_elec_consumption: Float64
    var air_loop_num: Int32
    var supply_fan_index: Int32
    var supply_fan_type: FanType
    var supply_fan_name: String
    var subcool_reheat_flag: Bool
    var total_cooling_energy_rate: Float64
    var total_cooling_energy: Float64
    var sens_cooling_energy_rate: Float64
    var sens_cooling_energy: Float64
    var lat_cooling_energy_rate: Float64
    var lat_cooling_energy: Float64
    var cooling_coil_runtime_fraction: Float64
    var elec_cooling_power: Float64
    var elec_cooling_consumption: Float64
    var air_mass_flow_rate: Float64
    var inlet_air_dry_bulb_temp: Float64
    var inlet_air_hum_rat: Float64
    var outlet_air_dry_bulb_temp: Float64
    var outlet_air_hum_rat: Float64
    var part_load_ratio_report: Float64
    var run_time_fraction: Float64
    var speed_num_report: Int32
    var speed_ratio_report: Float64
    var waste_heat_energy_rate: Float64
    var waste_heat_energy: Float64
    var recovered_heat_energy: Float64
    var recovered_heat_energy_rate: Float64
    var condenser_inlet_temperature: Float64
    var dehumidification_mode: CoilMode
    var report_coil_final_sizes: Bool
    var is_secondary_dx_coil_in_zone: Bool
    var sec_coil_sens_heat_rej_energy_rate: Float64
    var sec_coil_sens_heat_rej_energy: Float64
    var reclaim_heat: HeatReclaimDataBase
    var is_hundred_percent_doas: Bool

    fn __init__(inout self):
        self.original_input_specs = CoilCoolingDXInputSpecification()
        self.name = String()
        self.coil_type = COIL_TYPE_INVALID
        self.coil_report_num = -1
        self.my_one_time_init_flag = True
        self.evap_inlet_node_index = 0
        self.evap_outlet_node_index = 0
        self.avail_sched = UnsafePointer[UInt8]()
        self.cond_inlet_node_index = 0
        self.cond_outlet_node_index = 0
        self.performance = UnsafePointer[UInt8]()
        self.condensate_tank_index = 0
        self.condensate_tank_supply_arrid = 0
        self.condensate_volume_flow = 0.0
        self.condensate_volume_consumption = 0.0
        self.evaporative_cond_supply_tank_index = 0
        self.evaporative_cond_supply_tank_arrid = 0
        self.evaporative_cond_supply_tank_volume_flow = 0.0
        self.evaporative_cond_supply_tank_consump = 0.0
        self.evap_cond_pump_elec_power = 0.0
        self.evap_cond_pump_elec_consumption = 0.0
        self.air_loop_num = 0
        self.supply_fan_index = 0
        self.supply_fan_type = FAN_TYPE_INVALID
        self.supply_fan_name = String()
        self.subcool_reheat_flag = False
        self.total_cooling_energy_rate = 0.0
        self.total_cooling_energy = 0.0
        self.sens_cooling_energy_rate = 0.0
        self.sens_cooling_energy = 0.0
        self.lat_cooling_energy_rate = 0.0
        self.lat_cooling_energy = 0.0
        self.cooling_coil_runtime_fraction = 0.0
        self.elec_cooling_power = 0.0
        self.elec_cooling_consumption = 0.0
        self.air_mass_flow_rate = 0.0
        self.inlet_air_dry_bulb_temp = 0.0
        self.inlet_air_hum_rat = 0.0
        self.outlet_air_dry_bulb_temp = 0.0
        self.outlet_air_hum_rat = 0.0
        self.part_load_ratio_report = 0.0
        self.run_time_fraction = 0.0
        self.speed_num_report = 0
        self.speed_ratio_report = 0.0
        self.waste_heat_energy_rate = 0.0
        self.waste_heat_energy = 0.0
        self.recovered_heat_energy = 0.0
        self.recovered_heat_energy_rate = 0.0
        self.condenser_inlet_temperature = 0.0
        self.dehumidification_mode = COIL_MODE_NORMAL
        self.report_coil_final_sizes = True
        self.is_secondary_dx_coil_in_zone = False
        self.sec_coil_sens_heat_rej_energy_rate = 0.0
        self.sec_coil_sens_heat_rej_energy = 0.0
        self.reclaim_heat = HeatReclaimDataBase()
        self.is_hundred_percent_doas = False

    fn get_num_modes(self) -> Int32:
        var num_modes: Int32 = 1
        return num_modes

    fn set_data(inout self, fan_index: Int32, fan_type: FanType, fan_name: String, air_loop_num: Int32):
        self.supply_fan_index = fan_index
        self.supply_fan_name = fan_name
        self.supply_fan_type = fan_type
        self.air_loop_num = air_loop_num

    fn set_to_hundred_percent_doas(inout self):
        pass

struct CoilCoolingDXData:
    var coil_cooling_dxs: DynamicVector[CoilCoolingDX]
    var coil_cooling_dx_get_input_flag: Bool
    var coil_cooling_dx_object_name: String
    var coil_type: CoilType
    var still_need_to_report_standard_ratings: Bool

    fn __init__(inout self):
        self.coil_cooling_dxs = DynamicVector[CoilCoolingDX]()
        self.coil_cooling_dx_get_input_flag = True
        self.coil_cooling_dx_object_name = String("Coil:Cooling:DX")
        self.coil_type = COIL_TYPE_COOLING_DX
        self.still_need_to_report_standard_ratings = True

    fn init_constant_state(inout self):
        pass

    fn init_state(inout self):
        pass

    fn clear_state(inout self):
        pass

fn pass_through_node_data(inout in_node: NodeData, inout out_node: NodeData):
    out_node.mass_flow_rate = in_node.mass_flow_rate
    out_node.press = in_node.press
    out_node.quality = in_node.quality
    out_node.mass_flow_rate_max = in_node.mass_flow_rate_max
    out_node.mass_flow_rate_min = in_node.mass_flow_rate_min
    out_node.mass_flow_rate_max_avail = in_node.mass_flow_rate_max_avail
    out_node.mass_flow_rate_min_avail = in_node.mass_flow_rate_min_avail

fn populate_cooling_coil_standard_rating_information(coil_name: String, capacity: Float64, eer: Float64, 
                                                     seer_user: Float64, seer_standard: Float64, 
                                                     ieer: Float64, ahri2023_standard_ratings: Bool):
    pass
