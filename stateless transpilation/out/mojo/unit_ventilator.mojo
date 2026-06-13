from memory import memset_zero
from sys import sizeof

alias COILSUSED_INVALID = -1
alias COILSUSED_NONE = 0
alias COILSUSED_BOTH = 1
alias COILSUSED_HEATING = 2
alias COILSUSED_COOLING = 3
alias COILSUSED_NUM = 4

alias OACONTROL_INVALID = -1
alias OACONTROL_VARIABLE_PERCENT = 0
alias OACONTROL_FIXED_TEMPERATURE = 1
alias OACONTROL_FIXED_AMOUNT = 2
alias OACONTROL_NUM = 3

struct UnitVentilatorData:
    var name: String
    var avail_sched: UnsafePointer[UInt8]
    var air_in_node: Int32
    var air_out_node: Int32
    var fan_outlet_node: Int32
    var fan_type: Int32
    var fan_name: String
    var fan_index: Int32
    var fan_op_mode_sched: UnsafePointer[UInt8]
    var fan_avail_sched: UnsafePointer[UInt8]
    var fan_op: Int32
    var control_comp_type_num: Int32
    var comp_err_index: Int32
    var max_air_vol_flow: Float64
    var max_air_mass_flow: Float64
    var oa_control_type: Int32
    var min_oa_sched: UnsafePointer[UInt8]
    var max_oa_sched: UnsafePointer[UInt8]
    var temp_sched: UnsafePointer[UInt8]
    var outside_air_node: Int32
    var air_relief_node: Int32
    var oa_mixer_out_node: Int32
    var out_air_vol_flow: Float64
    var out_air_mass_flow: Float64
    var min_out_air_vol_flow: Float64
    var min_out_air_mass_flow: Float64
    var coil_option: Int32
    var h_coil_present: Bool
    var heat_coil_type: Int32
    var h_coil_name: String
    var h_coil_type_ch: String
    var h_coil_index: Int32
    var heating_coil_type: Int32
    var h_coil_fluid: UnsafePointer[UInt8]
    var h_coil_sched: UnsafePointer[UInt8]
    var h_coil_sched_value: Float64
    var max_vol_hot_water_flow: Float64
    var max_vol_hot_steam_flow: Float64
    var max_hot_water_flow: Float64
    var max_hot_steam_flow: Float64
    var min_hot_steam_flow: Float64
    var min_vol_hot_water_flow: Float64
    var min_vol_hot_steam_flow: Float64
    var min_hot_water_flow: Float64
    var hot_control_node: Int32
    var hot_coil_out_node_num: Int32
    var hot_control_offset: Float64
    var hw_plant_loc: UnsafePointer[UInt8]
    var c_coil_present: Bool
    var c_coil_name: String
    var c_coil_type_ch: String
    var c_coil_index: Int32
    var c_coil_plant_name: String
    var c_coil_plant_type: String
    var cooling_coil_type: Int32
    var cool_coil_type: Int32
    var c_coil_sched: UnsafePointer[UInt8]
    var c_coil_sched_value: Float64
    var max_vol_cold_water_flow: Float64
    var max_cold_water_flow: Float64
    var min_vol_cold_water_flow: Float64
    var min_cold_water_flow: Float64
    var cold_control_node: Int32
    var cold_coil_out_node_num: Int32
    var cold_control_offset: Float64
    var cw_plant_loc: UnsafePointer[UInt8]
    var heat_power: Float64
    var heat_energy: Float64
    var tot_cool_power: Float64
    var tot_cool_energy: Float64
    var sens_cool_power: Float64
    var sens_cool_energy: Float64
    var elec_power: Float64
    var elec_energy: Float64
    var avail_manager_list_name: String
    var avail_status: Int32
    var fan_part_load_ratio: Float64
    var part_load_frac: Float64
    var zone_ptr: Int32
    var hvac_sizing_index: Int32
    var at_mixer_exists: Bool
    var at_mixer_name: String
    var at_mixer_index: Int32
    var at_mixer_type: Int32
    var at_mixer_pri_node: Int32
    var at_mixer_sec_node: Int32
    var at_mixer_out_node: Int32
    var first_pass: Bool
    var solve_root_stats: UnsafePointer[UInt8]

    fn __init__(inout self):
        self.name = String()
        self.avail_sched = UnsafePointer[UInt8]()
        self.air_in_node = 0
        self.air_out_node = 0
        self.fan_outlet_node = 0
        self.fan_type = -1
        self.fan_name = String()
        self.fan_index = 0
        self.fan_op_mode_sched = UnsafePointer[UInt8]()
        self.fan_avail_sched = UnsafePointer[UInt8]()
        self.fan_op = -1
        self.control_comp_type_num = 0
        self.comp_err_index = 0
        self.max_air_vol_flow = 0.0
        self.max_air_mass_flow = 0.0
        self.oa_control_type = OACONTROL_INVALID
        self.min_oa_sched = UnsafePointer[UInt8]()
        self.max_oa_sched = UnsafePointer[UInt8]()
        self.temp_sched = UnsafePointer[UInt8]()
        self.outside_air_node = 0
        self.air_relief_node = 0
        self.oa_mixer_out_node = 0
        self.out_air_vol_flow = 0.0
        self.out_air_mass_flow = 0.0
        self.min_out_air_vol_flow = 0.0
        self.min_out_air_mass_flow = 0.0
        self.coil_option = COILSUSED_INVALID
        self.h_coil_present = False
        self.heat_coil_type = -1
        self.h_coil_name = String()
        self.h_coil_type_ch = String()
        self.h_coil_index = 0
        self.heating_coil_type = -1
        self.h_coil_fluid = UnsafePointer[UInt8]()
        self.h_coil_sched = UnsafePointer[UInt8]()
        self.h_coil_sched_value = 0.0
        self.max_vol_hot_water_flow = 0.0
        self.max_vol_hot_steam_flow = 0.0
        self.max_hot_water_flow = 0.0
        self.max_hot_steam_flow = 0.0
        self.min_hot_steam_flow = 0.0
        self.min_vol_hot_water_flow = 0.0
        self.min_vol_hot_steam_flow = 0.0
        self.min_hot_water_flow = 0.0
        self.hot_control_node = 0
        self.hot_coil_out_node_num = 0
        self.hot_control_offset = 0.0
        self.hw_plant_loc = UnsafePointer[UInt8]()
        self.c_coil_present = False
        self.c_coil_name = String()
        self.c_coil_type_ch = String()
        self.c_coil_index = 0
        self.c_coil_plant_name = String()
        self.c_coil_plant_type = String()
        self.cooling_coil_type = -1
        self.cool_coil_type = -1
        self.c_coil_sched = UnsafePointer[UInt8]()
        self.c_coil_sched_value = 0.0
        self.max_vol_cold_water_flow = 0.0
        self.max_cold_water_flow = 0.0
        self.min_vol_cold_water_flow = 0.0
        self.min_cold_water_flow = 0.0
        self.cold_control_node = 0
        self.cold_coil_out_node_num = 0
        self.cold_control_offset = 0.0
        self.cw_plant_loc = UnsafePointer[UInt8]()
        self.heat_power = 0.0
        self.heat_energy = 0.0
        self.tot_cool_power = 0.0
        self.tot_cool_energy = 0.0
        self.sens_cool_power = 0.0
        self.sens_cool_energy = 0.0
        self.elec_power = 0.0
        self.elec_energy = 0.0
        self.avail_manager_list_name = String()
        self.avail_status = 0
        self.fan_part_load_ratio = 0.0
        self.part_load_frac = 0.0
        self.zone_ptr = 0
        self.hvac_sizing_index = 0
        self.at_mixer_exists = False
        self.at_mixer_name = String()
        self.at_mixer_index = 0
        self.at_mixer_type = -1
        self.at_mixer_pri_node = 0
        self.at_mixer_sec_node = 0
        self.at_mixer_out_node = 0
        self.first_pass = True
        self.solve_root_stats = UnsafePointer[UInt8]()

struct UnitVentNumericFieldData:
    var field_names: DynamicVector[String]

    fn __init__(inout self):
        self.field_names = DynamicVector[String]()

struct UnitVentilatorsData:
    var c_mo_unit_ventilator: String
    var h_coil_on: Bool
    var num_of_unit_vents: Int32
    var oa_mass_flow_rate: Float64
    var q_zn_req: Float64
    var my_size_flag: DynamicVector[Bool]
    var get_unit_ventilator_input_flag: Bool
    var check_equip_name: DynamicVector[Bool]
    var unit_vent: DynamicVector[UnitVentilatorData]
    var unit_vent_numeric_fields: DynamicVector[UnitVentNumericFieldData]
    var my_one_time_flag: Bool
    var zone_equipment_list_checked: Bool
    var my_envrnflag: DynamicVector[Bool]
    var my_plant_scan_flag: DynamicVector[Bool]
    var my_zone_eq_flag: DynamicVector[Bool]
    var at_mix_out_node: Int32
    var at_mixer_pri_node: Int32
    var zone_node: Int32

    fn __init__(inout self):
        self.c_mo_unit_ventilator = String("ZoneHVAC:UnitVentilator")
        self.h_coil_on = False
        self.num_of_unit_vents = 0
        self.oa_mass_flow_rate = 0.0
        self.q_zn_req = 0.0
        self.my_size_flag = DynamicVector[Bool]()
        self.get_unit_ventilator_input_flag = True
        self.check_equip_name = DynamicVector[Bool]()
        self.unit_vent = DynamicVector[UnitVentilatorData]()
        self.unit_vent_numeric_fields = DynamicVector[UnitVentNumericFieldData]()
        self.my_one_time_flag = True
        self.zone_equipment_list_checked = False
        self.my_envrnflag = DynamicVector[Bool]()
        self.my_plant_scan_flag = DynamicVector[Bool]()
        self.my_zone_eq_flag = DynamicVector[Bool]()
        self.at_mix_out_node = 0
        self.at_mixer_pri_node = 0
        self.zone_node = 0

    fn clear_state(inout self):
        self.h_coil_on = False
        self.num_of_unit_vents = 0
        self.oa_mass_flow_rate = 0.0
        self.q_zn_req = 0.0
        self.get_unit_ventilator_input_flag = True
        self.my_size_flag.clear()
        self.check_equip_name.clear()
        self.unit_vent.clear()
        self.unit_vent_numeric_fields.clear()
        self.my_one_time_flag = True
        self.zone_equipment_list_checked = False
        self.my_envrnflag.clear()
        self.my_plant_scan_flag.clear()
        self.my_zone_eq_flag.clear()
        self.at_mix_out_node = 0
        self.at_mixer_pri_node = 0
        self.zone_node = 0

fn sim_unit_ventilator(state: UnsafePointer[UInt8], comp_name: String, zone_num: Int32, first_hvac_iteration: Bool, power_met: UnsafePointer[Float64], lat_output_provided: UnsafePointer[Float64], comp_index: UnsafePointer[Int32]):
    pass

fn get_unit_ventilator_input(state: UnsafePointer[UInt8]):
    pass

fn init_unit_ventilator(state: UnsafePointer[UInt8], unit_vent_num: Int32, first_hvac_iteration: Bool, zone_num: Int32):
    pass

fn size_unit_ventilator(state: UnsafePointer[UInt8], unit_vent_num: Int32):
    pass

fn calc_unit_ventilator(state: UnsafePointer[UInt8], unit_vent_num: UnsafePointer[Int32], zone_num: Int32, first_hvac_iteration: Bool, power_met: UnsafePointer[Float64], lat_output_provided: UnsafePointer[Float64]):
    pass

fn calc_unit_ventilator_components(state: UnsafePointer[UInt8], unit_vent_num: Int32, first_hvac_iteration: Bool, load_met: UnsafePointer[Float64], fan_op: Int32 = -1, part_load_frac: Float64 = 1.0):
    pass

fn sim_unit_vent_oa_mixer(state: UnsafePointer[UInt8], unit_vent_num: Int32, fan_op: Int32):
    pass

fn report_unit_ventilator(state: UnsafePointer[UInt8], unit_vent_num: Int32):
    pass

fn get_unit_ventilator_out_air_node(state: UnsafePointer[UInt8], unit_vent_num: Int32) -> Int32:
    return 0

fn get_unit_ventilator_zone_inlet_air_node(state: UnsafePointer[UInt8], unit_vent_num: Int32) -> Int32:
    return 0

fn get_unit_ventilator_mixed_air_node(state: UnsafePointer[UInt8], unit_vent_num: Int32) -> Int32:
    return 0

fn get_unit_ventilator_return_air_node(state: UnsafePointer[UInt8], unit_vent_num: Int32) -> Int32:
    return 0

fn get_unit_ventilator_index(state: UnsafePointer[UInt8], comp_name: String) -> Int32:
    return 0

fn set_oa_mass_flow_rate_for_cooling_variable_percent(state: UnsafePointer[UInt8], unit_vent_num: Int32, min_oa_frac: Float64, mass_flow_rate: Float64, max_oa_frac: Float64, tinlet: Float64, toutdoor: Float64) -> Float64:
    return 0.0

fn calc_mdot_c_coil_cyc_fan(state: UnsafePointer[UInt8], mdot: UnsafePointer[Float64], q_coil_req: UnsafePointer[Float64], q_zn_req: Float64, unit_vent_num: Int32, part_load_ratio: Float64):
    pass
