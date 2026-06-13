from math import max
from memory import UnsafePointer


@value
struct AirNodeType:
    alias INVALID = -1
    alias PATH_INLET = 0
    alias COMP_INLET = 1
    alias INTERMEDIATE = 2
    alias OUTLET = 3
    alias NUM = 4


@value
struct AirLoopHVACZone:
    alias INVALID = -1
    alias SPLITTER = 0
    alias SUPPLY_PLENUM = 1
    alias MIXER = 2
    alias RETURN_PLENUM = 3
    alias NUM = 4


fn get_air_loop_hvac_type_names_cc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("AirLoopHVAC:ZoneSplitter")
    names.append("AirLoopHVAC:SupplyPlenum")
    names.append("AirLoopHVAC:ZoneMixer")
    names.append("AirLoopHVAC:ReturnPlenum")
    return names


fn get_air_loop_hvac_type_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("AIRLOOPHVAC:ZONESPLITTER")
    names.append("AIRLOOPHVAC:SUPPLYPLENUM")
    names.append("AIRLOOPHVAC:ZONEMIXER")
    names.append("AIRLOOPHVAC:RETURNPLENUM")
    return names


@value
struct ZoneEquipType:
    alias INVALID = -1
    alias DUMMY = 0
    alias FOUR_PIPE_FAN_COIL = 1
    alias PACKAGED_TERMINAL_HEAT_PUMP = 2
    alias PACKAGED_TERMINAL_AIR_CONDITIONER = 3
    alias PACKAGED_TERMINAL_HEAT_PUMP_WATER_TO_AIR = 4
    alias WINDOW_AIR_CONDITIONER = 5
    alias UNIT_HEATER = 6
    alias UNIT_VENTILATOR = 7
    alias ENERGY_RECOVERY_VENTILATOR = 8
    alias VENTILATED_SLAB = 9
    alias OUTDOOR_AIR_UNIT = 10
    alias VARIABLE_REFRIGERANT_FLOW_TERMINAL = 11
    alias PURCHASED_AIR = 12
    alias EVAPORATIVE_COOLER = 13
    alias HYBRID_EVAPORATIVE_COOLER = 14
    alias AIR_DISTRIBUTION_UNIT = 15
    alias BASEBOARD_CONVECTIVE_WATER = 16
    alias BASEBOARD_CONVECTIVE_ELECTRIC = 17
    alias BASEBOARD_STEAM = 18
    alias BASEBOARD_WATER = 19
    alias BASEBOARD_ELECTRIC = 20
    alias HIGH_TEMPERATURE_RADIANT = 21
    alias LOW_TEMPERATURE_RADIANT_CONST_FLOW = 22
    alias LOW_TEMPERATURE_RADIANT_VAR_FLOW = 23
    alias LOW_TEMPERATURE_RADIANT_ELECTRIC = 24
    alias EXHAUST_FAN = 25
    alias HEAT_EXCHANGER = 26
    alias HEAT_PUMP_WATER_HEATER_PUMPED_CONDENSER = 27
    alias HEAT_PUMP_WATER_HEATER_WRAPPED_CONDENSER = 28
    alias DEHUMIDIFIER_DX = 29
    alias REFRIGERATION_CHILLER_SET = 30
    alias USER_DEFINED_HVAC_FORCED_AIR = 31
    alias COOLING_PANEL = 32
    alias UNITARY_SYSTEM = 33
    alias AIR_TERMINAL_DUAL_DUCT_CONSTANT_VOLUME = 34
    alias AIR_TERMINAL_DUAL_DUCT_VAV = 35
    alias AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_REHEAT = 36
    alias AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_NO_REHEAT = 37
    alias AIR_TERMINAL_SINGLE_DUCT_VAV_REHEAT = 38
    alias AIR_TERMINAL_SINGLE_DUCT_VAV_NO_REHEAT = 39
    alias AIR_TERMINAL_SINGLE_DUCT_SERIES_PIU_REHEAT = 40
    alias AIR_TERMINAL_SINGLE_DUCT_PARALLEL_PIU_REHEAT = 41
    alias AIR_TERMINAL_SINGLE_DUCT_CAV_FOUR_PIPE_INDUCTION = 42
    alias AIR_TERMINAL_SINGLE_DUCT_VAV_REHEAT_VARIABLE_SPEED_FAN = 43
    alias AIR_TERMINAL_SINGLE_DUCT_VAV_HEAT_AND_COOL_REHEAT = 44
    alias AIR_TERMINAL_SINGLE_DUCT_VAV_HEAT_AND_COOL_NO_REHEAT = 45
    alias AIR_TERMINAL_SINGLE_DUCT_CONSTANT_VOLUME_COOLED_BEAM = 46
    alias AIR_TERMINAL_DUAL_DUCT_VAV_OUTDOOR_AIR = 47
    alias AIR_LOOP_HVAC_RETURN_AIR = 48
    alias NUM = 49


fn get_zone_equip_type_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("DUMMY")
    names.append("ZONEHVAC:FOURPIPEFANCOIL")
    names.append("ZONEHVAC:PACKAGEDTERMINALHEATPUMP")
    names.append("ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER")
    names.append("ZONEHVAC:WATERTOAIRHEATPUMP")
    names.append("ZONEHVAC:WINDOWAIRCONDITIONER")
    names.append("ZONEHVAC:UNITHEATER")
    names.append("ZONEHVAC:UNITVENTILATOR")
    names.append("ZONEHVAC:ENERGYRECOVERYVENTILATOR")
    names.append("ZONEHVAC:VENTILATEDSLAB")
    names.append("ZONEHVAC:OUTDOORAIRUNIT")
    names.append("ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW")
    names.append("ZONEHVAC:IDEALLOADSAIRSYSTEM")
    names.append("ZONEHVAC:EVAPORATIVECOOLERUNIT")
    names.append("ZONEHVAC:HYBRIDUNITARYHVAC")
    names.append("ZONEHVAC:AIRDISTRIBUTIONUNIT")
    names.append("ZONEHVAC:BASEBOARD:CONVECTIVE:WATER")
    names.append("ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC")
    names.append("ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM")
    names.append("ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER")
    names.append("ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:ELECTRIC")
    names.append("ZONEHVAC:HIGHTEMPERATURERADIANT")
    names.append("ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW")
    names.append("ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW")
    names.append("ZONEHVAC:LOWTEMPERATURERADIANT:ELECTRIC")
    names.append("FAN:ZONEEXHAUST")
    names.append("HEATEXCHANGER:AIRTOAIR:FLATPLATE")
    names.append("WATERHEATER:HEATPUMP:PUMPEDCONDENSER")
    names.append("WATERHEATER:HEATPUMP:WRAPPEDCONDENSER")
    names.append("ZONEHVAC:DEHUMIDIFIER:DX")
    names.append("ZONEHVAC:REFRIGERATIONCHILLERSET")
    names.append("ZONEHVAC:FORCEDAIR:USERDEFINED")
    names.append("ZONEHVAC:COOLINGPANEL:RADIANTCONVECTIVE:WATER")
    names.append("AIRLOOPHVAC:UNITARYSYSTEM")
    names.append("AIRTERMINAL:DUALDUCT:CONSTANTVOLUME")
    names.append("AIRTERMINAL:DUALDUCT:VAV")
    names.append("AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:VAV:REHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION")
    names.append("AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN")
    names.append("AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT")
    names.append("AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM")
    names.append("AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR")
    names.append("AIRLOOPHVACRETURNAIR")
    return names


alias NUM_VALID_SYS_AVAIL_ZONE_COMPONENTS = 14


fn get_valid_sys_avail_manager_comp_types() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("ZoneHVAC:FourPipeFanCoil")
    names.append("ZoneHVAC:PackagedTerminalHeatPump")
    names.append("ZoneHVAC:PackagedTerminalAirConditioner")
    names.append("ZoneHVAC:WaterToAirHeatPump")
    names.append("ZoneHVAC:WindowAirConditioner")
    names.append("ZoneHVAC:UnitHeater")
    names.append("ZoneHVAC:UnitVentilator")
    names.append("ZoneHVAC:EnergyRecoveryVentilator")
    names.append("ZoneHVAC:VentilatedSlab")
    names.append("ZoneHVAC:OutdoorAirUnit")
    names.append("ZoneHVAC:TerminalUnit:VariableRefrigerantFlow")
    names.append("ZoneHVAC:IdealLoadsAirSystem")
    names.append("ZoneHVAC:EvaporativeCoolerUnit")
    names.append("ZoneHVAC:HybridUnitaryHVAC")
    return names


@value
struct PerPersonVentRateMode:
    alias INVALID = -1
    alias DCV_BY_CURRENT_LEVEL = 0
    alias BY_DESIGN_LEVEL = 1
    alias NUM = 2


@value
struct LoadDist:
    alias INVALID = -1
    alias SEQUENTIAL = 0
    alias UNIFORM = 1
    alias UNIFORM_PLR = 2
    alias SEQUENTIAL_UNIFORM_PLR = 3
    alias NUM = 4


fn get_load_dist_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("SEQUENTIALLOAD")
    names.append("UNIFORMLOAD")
    names.append("UNIFORMPLR")
    names.append("SEQUENTIALUNIFORMPLR")
    return names


@value
struct LightReturnExhaustConfig:
    alias INVALID = -1
    alias NO_EXHAUST = 0
    alias SINGLE = 1
    alias MULTI = 2
    alias SHARED = 3
    alias NUM = 4


@value
struct ZoneEquipTstatControl:
    alias INVALID = -1
    alias SINGLE_SPACE = 0
    alias MAXIMUM = 1
    alias IDEAL = 2
    alias NUM = 3


fn get_zone_equip_tstat_control_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("SINGLESPACE")
    names.append("MAXIMUM")
    names.append("IDEAL")
    return names


@value
struct SpaceEquipSizingBasis:
    alias INVALID = -1
    alias DESIGN_COOLING_LOAD = 0
    alias DESIGN_HEATING_LOAD = 1
    alias FLOOR_AREA = 2
    alias VOLUME = 3
    alias PERIMETER_LENGTH = 4
    alias NUM = 5


fn get_space_equip_sizing_basis_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("DESIGNCOOLINGLOAD")
    names.append("DESIGNHEATINGLOAD")
    names.append("FLOORAREA")
    names.append("VOLUME")
    names.append("PERIMETERLENGTH")
    return names


struct SubSubEquipmentData:
    var type_of: String
    var name: String
    var equip_index: Int32
    var on: Bool
    var inlet_node_num: Int32
    var outlet_node_num: Int32
    var num_metered_vars: Int32
    var metered_var: List[AnyType]
    var energy_trans_comp: Int32
    var zone_eq_to_plant_ptr: Int32
    var op_mode: Int32
    var capacity: Float64
    var efficiency: Float64
    var tot_plant_supply_elec: Float64
    var tot_plant_supply_gas: Float64
    var tot_plant_supply_purch: Float64

    fn __init__(inout self):
        self.type_of = String()
        self.name = String()
        self.equip_index = 0
        self.on = True
        self.inlet_node_num = 0
        self.outlet_node_num = 0
        self.num_metered_vars = 0
        self.metered_var = List[AnyType]()
        self.energy_trans_comp = 0
        self.zone_eq_to_plant_ptr = 0
        self.op_mode = 0
        self.capacity = 0.0
        self.efficiency = 0.0
        self.tot_plant_supply_elec = 0.0
        self.tot_plant_supply_gas = 0.0
        self.tot_plant_supply_purch = 0.0


struct SubEquipmentData:
    var parent: Bool
    var num_sub_sub_equip: Int32
    var type_of: String
    var name: String
    var equip_index: Int32
    var on: Bool
    var inlet_node_num: Int32
    var outlet_node_num: Int32
    var num_metered_vars: Int32
    var metered_var: List[AnyType]
    var sub_sub_equip_data: List[SubSubEquipmentData]
    var energy_trans_comp: Int32
    var zone_eq_to_plant_ptr: Int32
    var op_mode: Int32
    var capacity: Float64
    var efficiency: Float64
    var tot_plant_supply_elec: Float64
    var tot_plant_supply_gas: Float64
    var tot_plant_supply_purch: Float64

    fn __init__(inout self):
        self.parent = False
        self.num_sub_sub_equip = 0
        self.type_of = String()
        self.name = String()
        self.equip_index = 0
        self.on = True
        self.inlet_node_num = 0
        self.outlet_node_num = 0
        self.num_metered_vars = 0
        self.metered_var = List[AnyType]()
        self.sub_sub_equip_data = List[SubSubEquipmentData]()
        self.energy_trans_comp = 0
        self.zone_eq_to_plant_ptr = 0
        self.op_mode = 0
        self.capacity = 0.0
        self.efficiency = 0.0
        self.tot_plant_supply_elec = 0.0
        self.tot_plant_supply_gas = 0.0
        self.tot_plant_supply_purch = 0.0


struct AirIn:
    var in_node: Int32
    var out_node: Int32
    var supply_air_path_exists: Bool
    var air_loop_num: Int32
    var main_branch_index: Int32
    var supply_branch_index: Int32
    var air_dist_unit_index: Int32
    var term_unit_sizing_index: Int32
    var supply_air_path_index: Int32
    var supply_air_path_out_node_index: Int32
    var coil: List[SubSubEquipmentData]

    fn __init__(inout self):
        self.in_node = 0
        self.out_node = 0
        self.supply_air_path_exists = False
        self.air_loop_num = 0
        self.main_branch_index = 0
        self.supply_branch_index = 0
        self.air_dist_unit_index = 0
        self.term_unit_sizing_index = 0
        self.supply_air_path_index = 0
        self.supply_air_path_out_node_index = 0
        self.coil = List[SubSubEquipmentData]()


struct EquipConfiguration:
    var zone_name: String
    var equip_list_name: String
    var equip_list_index: Int32
    var control_list_name: String
    var zone_node: Int32
    var num_inlet_nodes: Int32
    var num_exhaust_nodes: Int32
    var num_return_nodes: Int32
    var num_return_flow_basis_nodes: Int32
    var return_flow_frac_sched: AnyType
    var flow_error: Bool
    var inlet_node: List[Int32]
    var inlet_node_air_loop_num: List[Int32]
    var inlet_node_adu_num: List[Int32]
    var exhaust_node: List[Int32]
    var return_node: List[Int32]
    var return_node_air_loop_num: List[Int32]
    var return_node_ret_path_num: List[Int32]
    var return_node_ret_path_comp_num: List[Int32]
    var return_node_inlet_num: List[Int32]
    var fixed_return_flow: List[Bool]
    var return_node_plenum_num: List[Int32]
    var return_node_exhaust_node_num: List[Int32]
    var shared_exhaust_node: List[Int32]
    var return_node_space_mixer_index: List[Int32]
    var zonal_system_only: Bool
    var is_controlled: Bool
    var zone_exh: Float64
    var zone_exh_balanced: Float64
    var plenum_mass_flow: Float64
    var excess_zone_exh: Float64
    var tot_avail_air_loop_oa: Float64
    var tot_inlet_air_mass_flow_rate: Float64
    var tot_exhaust_air_mass_flow_rate: Float64
    var air_dist_unit_heat: List[AirIn]
    var air_dist_unit_cool: List[AirIn]
    var in_floor_active_element: Bool
    var in_wall_active_element: Bool
    var in_ceiling_active_element: Bool
    var zone_has_air_loop_with_oa_sys: Bool
    var zone_air_distribution_index: Int32
    var zone_design_spec_oa_index: Int32
    var air_loop_des_supply: Float64

    fn __init__(inout self):
        self.zone_name = String("Uncontrolled Zone")
        self.equip_list_name = String()
        self.equip_list_index = 0
        self.control_list_name = String()
        self.zone_node = 0
        self.num_inlet_nodes = 0
        self.num_exhaust_nodes = 0
        self.num_return_nodes = 0
        self.num_return_flow_basis_nodes = 0
        self.return_flow_frac_sched = AnyType()
        self.flow_error = False
        self.inlet_node = List[Int32]()
        self.inlet_node_air_loop_num = List[Int32]()
        self.inlet_node_adu_num = List[Int32]()
        self.exhaust_node = List[Int32]()
        self.return_node = List[Int32]()
        self.return_node_air_loop_num = List[Int32]()
        self.return_node_ret_path_num = List[Int32]()
        self.return_node_ret_path_comp_num = List[Int32]()
        self.return_node_inlet_num = List[Int32]()
        self.fixed_return_flow = List[Bool]()
        self.return_node_plenum_num = List[Int32]()
        self.return_node_exhaust_node_num = List[Int32]()
        self.shared_exhaust_node = List[Int32]()
        self.return_node_space_mixer_index = List[Int32]()
        self.zonal_system_only = False
        self.is_controlled = False
        self.zone_exh = 0.0
        self.zone_exh_balanced = 0.0
        self.plenum_mass_flow = 0.0
        self.excess_zone_exh = 0.0
        self.tot_avail_air_loop_oa = 0.0
        self.tot_inlet_air_mass_flow_rate = 0.0
        self.tot_exhaust_air_mass_flow_rate = 0.0
        self.air_dist_unit_heat = List[AirIn]()
        self.air_dist_unit_cool = List[AirIn]()
        self.in_floor_active_element = False
        self.in_wall_active_element = False
        self.in_ceiling_active_element = False
        self.zone_has_air_loop_with_oa_sys = False
        self.zone_air_distribution_index = 0
        self.zone_design_spec_oa_index = 0
        self.air_loop_des_supply = 0.0

    fn set_total_inlet_flows(self, state: AnyType):
        pass

    fn begin_environ_init(self, state: AnyType):
        pass

    fn hvac_time_step_init(self, state: AnyType, first_hvac_iteration: Bool):
        pass

    fn calc_return_flows(
        self,
        state: AnyType,
        exp_total_return_mass_flow: Float64,
        final_total_return_mass_flow: Float64,
    ):
        pass


struct EquipmentData:
    var parent: Bool
    var num_sub_equip: Int32
    var type_of: String
    var name: String
    var on: Bool
    var num_inlets: Int32
    var num_outlets: Int32
    var inlet_node_nums: List[Int32]
    var outlet_node_nums: List[Int32]
    var num_metered_vars: Int32
    var metered_var: List[AnyType]
    var sub_equip_data: List[SubEquipmentData]
    var energy_trans_comp: Int32
    var zone_eq_to_plant_ptr: Int32
    var tot_plant_supply_elec: Float64
    var tot_plant_supply_gas: Float64
    var tot_plant_supply_purch: Float64
    var op_mode: Int32

    fn __init__(inout self):
        self.parent = False
        self.num_sub_equip = 0
        self.type_of = String()
        self.name = String()
        self.on = True
        self.num_inlets = 0
        self.num_outlets = 0
        self.inlet_node_nums = List[Int32]()
        self.outlet_node_nums = List[Int32]()
        self.num_metered_vars = 0
        self.metered_var = List[AnyType]()
        self.sub_equip_data = List[SubEquipmentData]()
        self.energy_trans_comp = 0
        self.zone_eq_to_plant_ptr = 0
        self.tot_plant_supply_elec = 0.0
        self.tot_plant_supply_gas = 0.0
        self.tot_plant_supply_purch = 0.0
        self.op_mode = 0


struct EquipList:
    var name: String
    var load_dist_scheme: Int32
    var num_of_equip_types: Int32
    var num_avail_heat_equip: Int32
    var num_avail_cool_equip: Int32
    var equip_type_name: List[String]
    var equip_type: List[Int32]
    var equip_name: List[String]
    var equip_index: List[Int32]
    var zone_equip_splitter_index: List[Int32]
    var comp_pointer: List[AnyType]
    var cooling_priority: List[Int32]
    var heating_priority: List[Int32]
    var sequential_cooling_fraction_scheds: List[AnyType]
    var sequential_heating_fraction_scheds: List[AnyType]
    var cooling_capacity: List[Int32]
    var heating_capacity: List[Int32]
    var equip_data: List[EquipmentData]

    fn __init__(inout self):
        self.name = String()
        self.load_dist_scheme = 0
        self.num_of_equip_types = 0
        self.num_avail_heat_equip = 0
        self.num_avail_cool_equip = 0
        self.equip_type_name = List[String]()
        self.equip_type = List[Int32]()
        self.equip_name = List[String]()
        self.equip_index = List[Int32]()
        self.zone_equip_splitter_index = List[Int32]()
        self.comp_pointer = List[AnyType]()
        self.cooling_priority = List[Int32]()
        self.heating_priority = List[Int32]()
        self.sequential_cooling_fraction_scheds = List[AnyType]()
        self.sequential_heating_fraction_scheds = List[AnyType]()
        self.cooling_capacity = List[Int32]()
        self.heating_capacity = List[Int32]()
        self.equip_data = List[EquipmentData]()

    fn get_priorities_for_inlet_node(
        self, state: AnyType, inlet_node_num: Int32
    ) -> Tuple[Int32, Int32]:
        return (0, 0)

    fn sequential_heating_fraction(self, state: AnyType, equip_num: Int32) -> Float64:
        return 0.0

    fn sequential_cooling_fraction(self, state: AnyType, equip_num: Int32) -> Float64:
        return 0.0


struct ZoneEquipSplitterMixerSpace:
    var space_index: Int32
    var fraction: Float64
    var space_node_num: Int32

    fn __init__(inout self):
        self.space_index = 0
        self.fraction = 0.0
        self.space_node_num = 0


struct ZoneEquipmentSplitterMixer:
    var name: String
    var space_equip_type: AnyType
    var space_sizing_basis: Int32
    var spaces: List[ZoneEquipSplitterMixerSpace]

    fn __init__(inout self):
        self.name = String()
        self.space_equip_type = AnyType()
        self.space_sizing_basis = -1
        self.spaces = List[ZoneEquipSplitterMixerSpace]()

    fn size(self, state: AnyType):
        pass


struct ZoneEquipmentSplitter(ZoneEquipmentSplitterMixer):
    var zone_equip_type: Int32
    var zone_equip_name: String
    var zone_equip_outlet_node_num: Int32
    var tstat_control: Int32
    var control_space_index: Int32
    var control_space_number: Int32
    var save_zone_sys_sensible_demand: AnyType
    var save_zone_sys_moisture_demand: AnyType

    fn __init__(inout self):
        super().__init__()
        self.zone_equip_type = -1
        self.zone_equip_name = String()
        self.zone_equip_outlet_node_num = 0
        self.tstat_control = -1
        self.control_space_index = 0
        self.control_space_number = 0
        self.save_zone_sys_sensible_demand = AnyType()
        self.save_zone_sys_moisture_demand = AnyType()

    fn distribute_output(
        self,
        state: AnyType,
        zone_num: Int32,
        sys_output_provided: Float64,
        lat_output_provided: Float64,
        non_air_sys_output: Float64,
        equip_type_num: Int32,
    ):
        pass

    fn adjust_loads(self, state: AnyType, zone_num: Int32, equip_type_num: Int32):
        pass


struct ZoneMixer(ZoneEquipmentSplitterMixer):
    var outlet_node_num: Int32

    fn __init__(inout self):
        super().__init__()
        self.outlet_node_num = 0

    fn set_outlet_conditions(self, state: AnyType):
        pass


struct ZoneEquipmentMixer(ZoneMixer):
    fn __init__(inout self):
        super().__init__()

    fn set_inlet_flows(self, state: AnyType):
        pass


struct ZoneReturnMixer(ZoneMixer):
    fn __init__(inout self):
        super().__init__()

    fn set_inlet_conditions(self, state: AnyType):
        pass

    fn set_inlet_flows(self, state: AnyType):
        pass


struct ControlList:
    var name: String
    var num_of_controls: Int32
    var control_type: List[String]
    var control_name: List[String]

    fn __init__(inout self):
        self.name = String()
        self.num_of_controls = 0
        self.control_type = List[String]()
        self.control_name = List[String]()


struct SupplyAir:
    var name: String
    var num_of_components: Int32
    var inlet_node_num: Int32
    var component_type: List[String]
    var component_type_enum: List[Int32]
    var component_name: List[String]
    var component_index: List[Int32]
    var splitter_index: List[Int32]
    var plenum_index: List[Int32]
    var num_outlet_nodes: Int32
    var outlet_node: List[Int32]
    var outlet_node_supply_path_comp_num: List[Int32]
    var num_nodes: Int32
    var node: List[Int32]
    var node_type: List[Int32]

    fn __init__(inout self):
        self.name = String()
        self.num_of_components = 0
        self.inlet_node_num = 0
        self.component_type = List[String]()
        self.component_type_enum = List[Int32]()
        self.component_name = List[String]()
        self.component_index = List[Int32]()
        self.splitter_index = List[Int32]()
        self.plenum_index = List[Int32]()
        self.num_outlet_nodes = 0
        self.outlet_node = List[Int32]()
        self.outlet_node_supply_path_comp_num = List[Int32]()
        self.num_nodes = 0
        self.node = List[Int32]()
        self.node_type = List[Int32]()


struct ReturnAir:
    var name: String
    var num_of_components: Int32
    var outlet_node_num: Int32
    var outlet_ret_path_comp_num: Int32
    var component_type: List[String]
    var component_type_enum: List[Int32]
    var component_name: List[String]
    var component_index: List[Int32]

    fn __init__(inout self):
        self.name = String()
        self.num_of_components = 0
        self.outlet_node_num = 0
        self.outlet_ret_path_comp_num = 0
        self.component_type = List[String]()
        self.component_type_enum = List[Int32]()
        self.component_name = List[String]()
        self.component_index = List[Int32]()


fn get_zone_equipment_data(state: AnyType):
    pass


fn process_zone_equipment_input(
    state: AnyType,
    zone_eq_module_object: StringRef,
    zone_or_space_num: Int32,
    is_space: Bool,
    loc_term_unit_sizing_counter: Int32,
    overall_equip_count: Int32,
    this_equip_config: EquipConfiguration,
    alph_array: List[String],
    c_alpha_fields: List[String],
    l_alpha_blanks: List[Bool],
    node_nums: List[Int32],
):
    pass


fn process_zone_equip_splitter_input(
    state: AnyType,
    zeq_splitter_module_object: StringRef,
    zeq_splitter_num: Int32,
    zone_num: Int32,
    object_schema_props: AnyType,
    object_fields: AnyType,
    this_zeq_splitter: ZoneEquipmentSplitter,
):
    pass


fn process_zone_equip_mixer_input(
    state: AnyType,
    zeq_mixer_module_object: StringRef,
    zone_num: Int32,
    object_schema_props: AnyType,
    object_fields: AnyType,
    this_zeq_mixer: ZoneEquipmentMixer,
):
    pass


fn process_zone_return_mixer_input(
    state: AnyType,
    zeq_mixer_module_object: StringRef,
    zone_num: Int32,
    object_schema_props: AnyType,
    object_fields: AnyType,
    mixer_index: Int32,
):
    pass


fn check_zone_equipment_list(
    state: AnyType,
    component_type: StringRef,
    component_name: StringRef,
    ctrl_zone_num: UnsafePointer[Int32],
) -> Bool:
    return False


fn get_controlled_zone_index(state: AnyType, zone_name: String) -> Int32:
    return 0


fn find_controlled_zone_index_from_system_node_number_for_zone(
    state: AnyType, trial_zone_node_num: Int32
) -> Int32:
    return 0


fn get_system_node_number_for_zone(state: AnyType, zone_num: Int32) -> Int32:
    return 0


fn get_return_air_node_for_zone(
    state: AnyType,
    zone_num: Int32,
    node_name: String,
    called_from_description: String,
) -> Int32:
    return 0


fn get_return_num_for_zone(state: AnyType, zone_num: Int32, node_name: String) -> Int32:
    return 0


fn get_zone_equip_controlled_zone_num(
    state: AnyType, zone_equip_type: Int32, equipment_name: String
) -> Int32:
    return 0


fn verify_lights_exhaust_node_for_zone(
    state: AnyType, zone_num: Int32, zone_exhaust_node_num: Int32
) -> Bool:
    return False


fn check_shared_exhaust(state: AnyType):
    pass


fn scale_inlet_flows(
    state: AnyType, zone_node_num: Int32, space_node_num: Int32, frac: Float64
):
    pass


struct DataZoneEquipmentData:
    var get_zone_equipment_data_errors_found: Bool
    var get_zone_equipment_data_found: Int32
    var num_supply_air_paths: Int32
    var num_return_air_paths: Int32
    var num_exhaust_air_systems: Int32
    var num_zone_exhaust_controls: Int32
    var zone_equip_inputs_filled: Bool
    var zone_equip_simulated_once: Bool
    var num_of_zone_equip_lists: Int32
    var zone_equip_avail: List[AnyType]
    var zone_equip_config: List[EquipConfiguration]
    var space_equip_config: List[EquipConfiguration]
    var unique_zone_equip_list_names: Dict[String, Bool]
    var zone_equip_list: List[EquipList]
    var supply_air_path: List[SupplyAir]
    var return_air_path: List[ReturnAir]
    var exhaust_air_system: List[AnyType]
    var zone_exhaust_control_system: List[AnyType]
    var zone_equip_splitter: List[ZoneEquipmentSplitter]
    var zone_equip_mixer: List[ZoneEquipmentMixer]
    var zone_return_mixer: List[ZoneReturnMixer]

    fn __init__(inout self):
        self.get_zone_equipment_data_errors_found = False
        self.get_zone_equipment_data_found = 0
        self.num_supply_air_paths = 0
        self.num_return_air_paths = 0
        self.num_exhaust_air_systems = 0
        self.num_zone_exhaust_controls = 0
        self.zone_equip_inputs_filled = False
        self.zone_equip_simulated_once = False
        self.num_of_zone_equip_lists = 0
        self.zone_equip_avail = List[AnyType]()
        self.zone_equip_config = List[EquipConfiguration]()
        self.space_equip_config = List[EquipConfiguration]()
        self.unique_zone_equip_list_names = Dict[String, Bool]()
        self.zone_equip_list = List[EquipList]()
        self.supply_air_path = List[SupplyAir]()
        self.return_air_path = List[ReturnAir]()
        self.exhaust_air_system = List[AnyType]()
        self.zone_exhaust_control_system = List[AnyType]()
        self.zone_equip_splitter = List[ZoneEquipmentSplitter]()
        self.zone_equip_mixer = List[ZoneEquipmentMixer]()
        self.zone_return_mixer = List[ZoneReturnMixer]()

    fn init_constant_state(self, state: AnyType):
        pass

    fn init_state(self, state: AnyType):
        pass

    fn clear_state(inout self):
        self = DataZoneEquipmentData()
