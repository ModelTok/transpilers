"""
EnergyPlus HVACMultiSpeedHeatPump module (Mojo)

Multi-speed heat pump simulation module.
AUTHOR: Lixing Gu, Florida Solar Energy Center
DATE WRITTEN: June 2007
"""

from math import ceil, floor, fabs, max, min
from builtin import IndexError


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (struct with state.dataHVACMultiSpdHP, state.dataEnvrn, state.dataLoopNodes, etc.)
# - HVAC module: enums (FanOp, CompressorOp, FanType, FanPlace, CoilType), SmallLoad, SmallMassFlow, SmallAirVolFlow
# - DXCoils module: functions (SimDXCoilMultiSpeed, GetDXCoilIndex, GetDXCoilNumberOfSpeeds, GetCoilInletNode, GetCoilOutletNode, GetMinOATCompressor, DisableLatentDegradation, SetMSHPDXCoilHeatRecoveryFlag, GetDXCoilAvailSched, DXCoilPartLoadRatio)
# - HeatingCoils module: functions (GetHeatingCoilIndex, GetHeatingCoilNumberOfStages, GetCoilInletNode, GetCoilOutletNode, GetCoilCapacity, SimulateHeatingCoilComponents)
# - WaterCoils module: functions (GetCoilWaterInletNode, GetCoilMaxWaterFlowRate, GetCoilInletNode, GetCoilOutletNode, SimulateWaterCoilComponents)
# - SteamCoils module: functions (GetSteamCoilIndex, GetCoilAirOutletNode, GetCoilMaxSteamFlowRate, GetCoilAirInletNode, SimulateSteamCoilComponents, GetCoilCapacity)
# - Psychrometrics module: functions (RhoH2O, PsyCpAirFnW, PsyDeltaHSenFnTdb2W2Tdb1W1)
# - ScheduleManager module: functions (GetScheduleAlwaysOn, GetSchedule)
# - Fans module: fan object interface
# - PlantUtilities module: functions (ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode, RegisterPlantCompDesignFlow)
# - NodeInputManager module: GetOnlySingleNode
# - General module: SolveRoot
# - Util module: FindItemInList, SameString
# - OutputProcessor module: SetupOutputVariable
# - OutputReportPredefined module: PreDefTableEntry
# - Constant module: HWInitConvTemp, Units, eResource, Group, EndUseCat
# - DataSizing module: AutoSize, HeatCoilSizMethod
# - DataPlant module: PlantEquipmentType, PlantLocation, CompData
# - ErrorHandling module: ShowWarningError, ShowContinueError, ShowFatalError, ShowSevereError, etc.


struct ModeOfOperation:
    """Mode of operation for heat pump"""
    alias INVALID = -1
    alias COOLING_MODE = 0
    alias HEATING_MODE = 1
    alias NUM = 2


struct AirflowControl:
    """Airflow control for constant fan mode"""
    alias INVALID = -1
    alias USE_COMPRESSOR_ON_FLOW = 0
    alias USE_COMPRESSOR_OFF_FLOW = 1
    alias NUM = 2


struct CurveType:
    """Curve types"""
    alias INVALID = -1
    alias LINEAR = 0
    alias BILINEAR = 1
    alias QUADRATIC = 2
    alias BIQUADRATIC = 3
    alias CUBIC = 4
    alias NUM = 5


struct MSHeatPumpData:
    """Multi-speed heat pump data"""
    var name: String
    var avail_sched: OpaquePointer
    var air_inlet_node_num: Int32
    var air_outlet_node_num: Int32
    var air_inlet_node_name: String
    var air_outlet_node_name: String
    var control_zone_num: Int32
    var zone_sequence_cooling_num: Int32
    var zone_sequence_heating_num: Int32
    var control_zone_name: String
    var node_num_of_controlled_zone: Int32
    var flow_fraction: Float64
    var fan_name: String
    var fan_type: Int32
    var fan_num: Int32
    var fan_place: Int32
    var fan_inlet_node: Int32
    var fan_outlet_node: Int32
    var fan_vol_flow: Float64
    var fan_op_mode_sched: OpaquePointer
    var fan_op: Int32
    var dx_heat_coil_name: String
    var heat_coil_type: Int32
    var heat_coil_num: Int32
    var dx_heat_coil_index: Int32
    var heat_coil_name: String
    var heat_coil_index: Int32
    var dx_cool_coil_name: String
    var cool_coil_type: Int32
    var dx_cool_coil_index: Int32
    var supp_heat_coil_name: String
    var supp_heat_coil_type: Int32
    var supp_heat_coil_num: Int32
    var design_supp_heating_capacity: Float64
    var supp_max_air_temp: Float64
    var supp_max_oa_temp: Float64
    var aux_on_cycle_power: Float64
    var aux_off_cycle_power: Float64
    var design_heat_rec_flow_rate: Float64
    var heat_rec_active: Bool
    var heat_rec_name: String
    var heat_rec_inlet_node_num: Int32
    var heat_rec_outlet_node_num: Int32
    var max_heat_rec_outlet_temp: Float64
    var design_heat_rec_mass_flow_rate: Float64
    var hr_plant_loc: OpaquePointer
    var aux_elec_power: Float64
    var idle_volume_air_rate: Float64
    var idle_mass_flow_rate: Float64
    var idle_speed_ratio: Float64
    var num_of_speed_cooling: Int32
    var num_of_speed_heating: Int32
    var heat_volume_flow_rate: DynamicVector[Float64]
    var heat_mass_flow_rate: DynamicVector[Float64]
    var cool_volume_flow_rate: DynamicVector[Float64]
    var cool_mass_flow_rate: DynamicVector[Float64]
    var heating_speed_ratio: DynamicVector[Float64]
    var cooling_speed_ratio: DynamicVector[Float64]
    var check_fan_flow: Bool
    var last_mode: Int32
    var heat_cool_mode: Int32
    var air_loop_number: Int32
    var num_controlled_zones: Int32
    var zone_inlet_node: Int32
    var comp_part_load_ratio: Float64
    var fan_part_load_ratio: Float64
    var tot_cool_energy_rate: Float64
    var tot_heat_energy_rate: Float64
    var sens_cool_energy_rate: Float64
    var sens_heat_energy_rate: Float64
    var lat_cool_energy_rate: Float64
    var lat_heat_energy_rate: Float64
    var elec_power: Float64
    var load_met: Float64
    var heat_recovery_rate: Float64
    var heat_recovery_inlet_temp: Float64
    var heat_recovery_outlet_temp: Float64
    var heat_recovery_mass_flow_rate: Float64
    var air_flow_control: Int32
    var err_index_cyc: Int32
    var err_index_var: Int32
    var load_loss: Float64
    var supp_coil_air_inlet_node: Int32
    var supp_coil_air_outlet_node: Int32
    var supp_heat_coil_type_num: Int32
    var supp_heat_coil_index: Int32
    var supp_coil_control_node: Int32
    var max_supp_coil_fluid_flow: Float64
    var supp_coil_outlet_node: Int32
    var coil_air_inlet_node: Int32
    var coil_control_node: Int32
    var max_coil_fluid_flow: Float64
    var coil_outlet_node: Int32
    var hot_water_coil_control_node: Int32
    var hot_water_coil_outlet_node: Int32
    var hot_water_coil_name: String
    var hot_water_coil_num: Int32
    var plant_loc: OpaquePointer
    var supp_plant_loc: OpaquePointer
    var hot_water_plant_loc: OpaquePointer
    var hot_water_coil_max_iter_index: Int32
    var hot_water_coil_max_iter_index2: Int32
    var stage_num: Int32
    var staged: Bool
    var cool_count_avail: Int32
    var cool_index_avail: Int32
    var heat_count_avail: Int32
    var heat_index_avail: Int32
    var first_pass: Bool
    var full_output: DynamicVector[Float64]
    var min_oat_compressor_cooling: Float64
    var min_oat_compressor_heating: Float64
    var my_envrnflag: Bool
    var my_size_flag: Bool
    var my_check_flag: Bool
    var my_flow_frac_flag: Bool
    var my_plant_scant_flag: Bool
    var my_staged_flag: Bool
    var ems_override_coil_speed_num_on: Bool
    var ems_override_coil_speed_num_value: Float64
    var coil_speed_err_index: Int32
    var heating_sizing_ratio: Float64
    var is_heat_pump: Bool
    var report_acca_manual_s: Bool

    fn __init__(inout self):
        self.name = ""
        self.avail_sched = OpaquePointer()
        self.air_inlet_node_num = 0
        self.air_outlet_node_num = 0
        self.air_inlet_node_name = ""
        self.air_outlet_node_name = ""
        self.control_zone_num = 0
        self.zone_sequence_cooling_num = 0
        self.zone_sequence_heating_num = 0
        self.control_zone_name = ""
        self.node_num_of_controlled_zone = 0
        self.flow_fraction = 0.0
        self.fan_name = ""
        self.fan_type = -1
        self.fan_num = 0
        self.fan_place = -1
        self.fan_inlet_node = 0
        self.fan_outlet_node = 0
        self.fan_vol_flow = 0.0
        self.fan_op_mode_sched = OpaquePointer()
        self.fan_op = -1
        self.dx_heat_coil_name = ""
        self.heat_coil_type = -1
        self.heat_coil_num = 0
        self.dx_heat_coil_index = 0
        self.heat_coil_name = ""
        self.heat_coil_index = 0
        self.dx_cool_coil_name = ""
        self.cool_coil_type = -1
        self.dx_cool_coil_index = 0
        self.supp_heat_coil_name = ""
        self.supp_heat_coil_type = -1
        self.supp_heat_coil_num = 0
        self.design_supp_heating_capacity = 0.0
        self.supp_max_air_temp = 0.0
        self.supp_max_oa_temp = 0.0
        self.aux_on_cycle_power = 0.0
        self.aux_off_cycle_power = 0.0
        self.design_heat_rec_flow_rate = 0.0
        self.heat_rec_active = False
        self.heat_rec_name = ""
        self.heat_rec_inlet_node_num = 0
        self.heat_rec_outlet_node_num = 0
        self.max_heat_rec_outlet_temp = 0.0
        self.design_heat_rec_mass_flow_rate = 0.0
        self.hr_plant_loc = OpaquePointer()
        self.aux_elec_power = 0.0
        self.idle_volume_air_rate = 0.0
        self.idle_mass_flow_rate = 0.0
        self.idle_speed_ratio = 0.0
        self.num_of_speed_cooling = 0
        self.num_of_speed_heating = 0
        self.heat_volume_flow_rate = DynamicVector[Float64]()
        self.heat_mass_flow_rate = DynamicVector[Float64]()
        self.cool_volume_flow_rate = DynamicVector[Float64]()
        self.cool_mass_flow_rate = DynamicVector[Float64]()
        self.heating_speed_ratio = DynamicVector[Float64]()
        self.cooling_speed_ratio = DynamicVector[Float64]()
        self.check_fan_flow = True
        self.last_mode = -1
        self.heat_cool_mode = -1
        self.air_loop_number = 0
        self.num_controlled_zones = 0
        self.zone_inlet_node = 0
        self.comp_part_load_ratio = 0.0
        self.fan_part_load_ratio = 0.0
        self.tot_cool_energy_rate = 0.0
        self.tot_heat_energy_rate = 0.0
        self.sens_cool_energy_rate = 0.0
        self.sens_heat_energy_rate = 0.0
        self.lat_cool_energy_rate = 0.0
        self.lat_heat_energy_rate = 0.0
        self.elec_power = 0.0
        self.load_met = 0.0
        self.heat_recovery_rate = 0.0
        self.heat_recovery_inlet_temp = 0.0
        self.heat_recovery_outlet_temp = 0.0
        self.heat_recovery_mass_flow_rate = 0.0
        self.air_flow_control = -1
        self.err_index_cyc = 0
        self.err_index_var = 0
        self.load_loss = 0.0
        self.supp_coil_air_inlet_node = 0
        self.supp_coil_air_outlet_node = 0
        self.supp_heat_coil_type_num = 0
        self.supp_heat_coil_index = 0
        self.supp_coil_control_node = 0
        self.max_supp_coil_fluid_flow = 0.0
        self.supp_coil_outlet_node = 0
        self.coil_air_inlet_node = 0
        self.coil_control_node = 0
        self.max_coil_fluid_flow = 0.0
        self.coil_outlet_node = 0
        self.hot_water_coil_control_node = 0
        self.hot_water_coil_outlet_node = 0
        self.hot_water_coil_name = ""
        self.hot_water_coil_num = 0
        self.plant_loc = OpaquePointer()
        self.supp_plant_loc = OpaquePointer()
        self.hot_water_plant_loc = OpaquePointer()
        self.hot_water_coil_max_iter_index = 0
        self.hot_water_coil_max_iter_index2 = 0
        self.stage_num = 0
        self.staged = False
        self.cool_count_avail = 0
        self.cool_index_avail = 0
        self.heat_count_avail = 0
        self.heat_index_avail = 0
        self.first_pass = True
        self.full_output = DynamicVector[Float64]()
        self.min_oat_compressor_cooling = 0.0
        self.min_oat_compressor_heating = 0.0
        self.my_envrnflag = True
        self.my_size_flag = True
        self.my_check_flag = True
        self.my_flow_frac_flag = True
        self.my_plant_scant_flag = True
        self.my_staged_flag = True
        self.ems_override_coil_speed_num_on = False
        self.ems_override_coil_speed_num_value = 0.0
        self.coil_speed_err_index = 0
        self.heating_sizing_ratio = 1.0
        self.is_heat_pump = False
        self.report_acca_manual_s = True


struct MSHeatPumpReportData:
    """Multi-speed heat pump report data"""
    var elec_power_consumption: Float64
    var heat_recovery_energy: Float64
    var cyc_ratio: Float64
    var speed_ratio: Float64
    var speed_num: Int32
    var aux_elec_cool_consumption: Float64
    var aux_elec_heat_consumption: Float64

    fn __init__(inout self):
        self.elec_power_consumption = 0.0
        self.heat_recovery_energy = 0.0
        self.cyc_ratio = 0.0
        self.speed_ratio = 0.0
        self.speed_num = 0
        self.aux_elec_cool_consumption = 0.0
        self.aux_elec_heat_consumption = 0.0


struct HVACMultiSpeedHeatPumpData:
    """Global heat pump data"""
    var num_msheat_pumps: Int32
    var air_loop_pass: Int32
    var temp_steam_in: Float64
    var current_module_object: String
    var comp_on_mass_flow: Float64
    var comp_off_mass_flow: Float64
    var comp_on_flow_ratio: Float64
    var comp_off_flow_ratio: Float64
    var fan_speed_ratio: Float64
    var sup_heater_load: Float64
    var save_load_residual: Float64
    var save_compressor_plr: Float64
    var check_equip_name: DynamicVector[Bool]
    var msheat_pump: DynamicVector[MSHeatPumpData]
    var msheat_pump_report: DynamicVector[MSHeatPumpReportData]
    var get_input_flag: Bool
    var flow_frac_flag_ready: Bool
    var err_count_cyc: Int32
    var err_count_var: Int32
    var heat_coil_name: String

    fn __init__(inout self):
        self.num_msheat_pumps = 0
        self.air_loop_pass = 0
        self.temp_steam_in = 100.0
        self.current_module_object = ""
        self.comp_on_mass_flow = 0.0
        self.comp_off_mass_flow = 0.0
        self.comp_on_flow_ratio = 0.0
        self.comp_off_flow_ratio = 0.0
        self.fan_speed_ratio = 0.0
        self.sup_heater_load = 0.0
        self.save_load_residual = 0.0
        self.save_compressor_plr = 0.0
        self.check_equip_name = DynamicVector[Bool]()
        self.msheat_pump = DynamicVector[MSHeatPumpData]()
        self.msheat_pump_report = DynamicVector[MSHeatPumpReportData]()
        self.get_input_flag = True
        self.flow_frac_flag_ready = True
        self.err_count_cyc = 0
        self.err_count_var = 0
        self.heat_coil_name = ""


@export
fn sim_msheat_pump(state: OpaquePointer, comp_name: StringRef, first_hvac_iteration: Bool, air_loop_num: Int32, inout comp_index: Int32):
    """Simulate multi-speed heat pump"""
    pass  # Placeholder


@export
fn sim_mshp(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, air_loop_num: Int32, inout qsens_unit_out: Float64, qzn_req: Float64, inout on_off_air_flow_ratio: Float64):
    """Simulate multi-speed heat pump"""
    pass  # Placeholder


@export
fn get_msheat_pump_input(state: OpaquePointer):
    """Get multi-speed heat pump input"""
    pass  # Placeholder


@export
fn init_msheat_pump(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, air_loop_num: Int32, inout qzn_req: Float64, inout on_off_air_flow_ratio: Float64):
    """Initialize multi-speed heat pump"""
    pass  # Placeholder


@export
fn size_msheat_pump(state: OpaquePointer, msheat_pump_num: Int32):
    """Size multi-speed heat pump"""
    pass  # Placeholder


@export
fn control_mshp_output(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, compressor_op: Int32, fan_op: Int32, qzn_req: Float64, zone_num: Int32, inout speed_num: Int32, inout speed_ratio: Float64, inout part_load_frac: Float64, inout on_off_air_flow_ratio: Float64, inout sup_heater_load: Float64):
    """Control multi-speed heat pump output"""
    pass  # Placeholder


@export
fn control_mshp_sup_heater(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, compressor_op: Int32, fan_op: Int32, qzn_req: Float64, ems_output: Int32, speed_num: Int32, speed_ratio: Float64, part_load_frac: Float64, on_off_air_flow_ratio: Float64, inout sup_heater_load: Float64):
    """Control supplemental heater"""
    pass  # Placeholder


@export
fn control_mshp_output_ems(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, compressor_op: Int32, fan_op: Int32, qzn_req: Float64, speed_val: Float64, inout speed_num: Int32, inout speed_ratio: Float64, inout part_load_frac: Float64, inout on_off_air_flow_ratio: Float64, inout sup_heater_load: Float64):
    """Control multi-speed heat pump output with EMS"""
    pass  # Placeholder


@export
fn calc_msheat_pump(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, compressor_op: Int32, speed_num: Int32, speed_ratio: Float64, part_load_frac: Float64, inout load_met: Float64, qzn_req: Float64, inout on_off_air_flow_ratio: Float64, inout sup_heater_load: Float64):
    """Calculate multi-speed heat pump performance"""
    pass  # Placeholder


@export
fn update_msheat_pump(state: OpaquePointer, msheat_pump_num: Int32):
    """Update multi-speed heat pump"""
    pass  # Placeholder


@export
fn report_msheat_pump(state: OpaquePointer, msheat_pump_num: Int32):
    """Report multi-speed heat pump"""
    pass  # Placeholder


@export
fn mshp_heat_recovery(state: OpaquePointer, msheat_pump_num: Int32):
    """Calculate heat recovery"""
    pass  # Placeholder


@export
fn set_average_air_flow(state: OpaquePointer, msheat_pump_num: Int32, part_load_ratio: Float64, inout on_off_air_flow_ratio: Float64, speed_num: Optional[Int32] = None, speed_ratio: Optional[Float64] = None):
    """Set average air flow"""
    pass  # Placeholder


@export
fn calc_non_dx_heating_coils(state: OpaquePointer, msheat_pump_num: Int32, first_hvac_iteration: Bool, heating_load: Float64, fan_op: Int32, inout heat_coil_loadmet: Float64, part_load_frac: Optional[Float64] = None):
    """Calculate non-DX heating coils"""
    pass  # Placeholder
