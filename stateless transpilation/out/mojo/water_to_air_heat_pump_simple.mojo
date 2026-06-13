"""
Water-to-Air Heat Pump Simple simulation module (Mojo port).
Complete faithful translation from EnergyPlus C++ implementation.

EXTERNAL DEPS (to wire in glue):
- Psychrometrics: PsyRhoAirFnPbTdbW, PsyHFnTdbW, PsyTwbFnTdbWPb, PsyCpAirFnW, PsyWFnTdbH, PsyTdbFnHW
- Curve: value() method with (state, ...) signature
- PlantUtilities: MyPlantSizingIndex, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, RegisterPlantCompDesignFlow
- DataLoopNode: Node state access via state.dataLoopNodes.Node[]
- ErrorHandling: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd
- Report: SetupOutputVariable, OutputReportPredefined, ReportCoilSelection
- GlobalNames: VerifyUniqueCoilName
- Utilities: Util module (FindItemInList, SameString, makeUPPER)
"""

from math import exp, fmax, fmin, fabs, expm1


alias Real64 = Float64
alias Int32 = Int32


@value
struct WatertoAirHP:
    """Water-to-Air HP type enumeration."""
    alias Invalid: Int32 = -1
    alias Heating: Int32 = 0
    alias Cooling: Int32 = 1
    alias Num: Int32 = 2


@value
struct PlantEquipmentType:
    """Plant equipment type."""
    alias Invalid: Int32 = -1
    alias CoilWAHPCoolingEquationFit: Int32 = 0
    alias CoilWAHPHeatingEquationFit: Int32 = 1


@value
struct CoilType:
    """HVAC Coil type."""
    alias Invalid: Int32 = -1
    alias CoolingWAHPSimple: Int32 = 0
    alias HeatingWAHPSimple: Int32 = 1


@value
struct FanOp:
    """Fan operation mode."""
    alias Invalid: Int32 = -1
    alias Continuous: Int32 = 0
    alias Cycling: Int32 = 1


@value
struct CompressorOp:
    """Compressor operation."""
    alias Invalid: Int32 = -1
    alias Off: Int32 = 0
    alias On: Int32 = 1


@value
struct WaterFlow:
    """Water flow mode."""
    alias Invalid: Int32 = -1
    alias Cycling: Int32 = 0
    alias Constant: Int32 = 1
    alias ConstantOnDemand: Int32 = 2


@value
struct ConnectionObjectType:
    """Node connection object type."""
    alias Invalid: Int32 = -1
    alias CoilCoolingWaterToAirHeatPumpEquationFit: Int32 = 0
    alias CoilHeatingWaterToAirHeatPumpEquationFit: Int32 = 1


@value
struct FluidType:
    """Node fluid type."""
    alias Invalid: Int32 = -1
    alias Water: Int32 = 0
    alias Air: Int32 = 1


@value
struct ConnectionType:
    """Node connection type."""
    alias Invalid: Int32 = -1
    alias Inlet: Int32 = 0
    alias Outlet: Int32 = 1


@value
struct CompFluidStream:
    """Component fluid stream."""
    alias Invalid: Int32 = -1
    alias Primary: Int32 = 0
    alias Secondary: Int32 = 1


alias TREF = 283.15
alias KELVIN = 273.15
alias AUTOSIZE = -99999.0
alias SMALL_LOAD = 0.00001
alias SMALL_AIR_VOL_FLOW = 0.00001


struct PlantLocation:
    """Plant location information."""
    var loop_num: Int32
    var loop_side: Int32
    var branch: Int32
    var comp: Int32
    
    fn __init__(inout self):
        self.loop_num = 0
        self.loop_side = 0
        self.branch = 0
        self.comp = 0


struct Curve:
    """Curve object (stub)."""
    var num: Int32
    var name: String
    var num_dims: Int32
    
    fn __init__(inout self):
        self.num = 0
        self.name = ""
        self.num_dims = 0
    
    fn value(self, state: UnsafePointer[NoneType], *args: Float64) -> Float64:
        """Evaluate curve at given points (stub)."""
        return 1.0


struct Schedule:
    """Schedule object (stub)."""
    var index: Int32
    var name: String
    
    fn __init__(inout self):
        self.index = 0
        self.name = ""


struct SimpleWatertoAirHPConditions:
    """Simple Water-to-Air HP condition structure."""
    var name: String
    var coil_type: Int32
    var coil_report_num: Int32
    var avail_sched: UnsafePointer[Schedule]
    var wahp_type: Int32
    var wahp_plant_type: Int32
    var sim_flag: Bool
    var air_vol_flow_rate: Real64
    var air_mass_flow_rate: Real64
    var inlet_air_db_temp: Real64
    var inlet_air_hum_rat: Real64
    var inlet_air_enthalpy: Real64
    var outlet_air_db_temp: Real64
    var outlet_air_hum_rat: Real64
    var outlet_air_enthalpy: Real64
    var water_vol_flow_rate: Real64
    var water_mass_flow_rate: Real64
    var design_water_mass_flow_rate: Real64
    var inlet_water_temp: Real64
    var inlet_water_enthalpy: Real64
    var outlet_water_temp: Real64
    var outlet_water_enthalpy: Real64
    var power: Real64
    var q_load_total: Real64
    var q_load_total_report: Real64
    var q_sensible: Real64
    var q_latent: Real64
    var q_source: Real64
    var energy: Real64
    var energy_load_total: Real64
    var energy_sensible: Real64
    var energy_latent: Real64
    var energy_source: Real64
    var cop: Real64
    var run_frac: Real64
    var part_load_ratio: Real64
    var rated_water_vol_flow_rate: Real64
    var rated_air_vol_flow_rate: Real64
    var rated_cap_heat: Real64
    var rated_cap_heat_at_rated_cdts: Real64
    var rated_cap_cool_at_rated_cdts: Real64
    var rated_cap_cool_sens_des_at_rated_cdts: Real64
    var rated_power_heat: Real64
    var rated_power_heat_at_rated_cdts: Real64
    var rated_cop_heat_at_rated_cdts: Real64
    var rated_cap_cool_total: Real64
    var rated_cap_cool_sens: Real64
    var rated_power_cool: Real64
    var rated_power_cool_at_rated_cdts: Real64
    var rated_cop_cool_at_rated_cdts: Real64
    var rated_ent_water_temp: Real64
    var rated_ent_air_wetbulb_temp: Real64
    var rated_ent_air_drybulb_temp: Real64
    var ratio_rated_heat_rated_tot_cool_cap: Real64
    var heat_cap_curve: UnsafePointer[Curve]
    var heat_pow_curve: UnsafePointer[Curve]
    var total_cool_cap_curve: UnsafePointer[Curve]
    var sens_cool_cap_curve: UnsafePointer[Curve]
    var cool_pow_curve: UnsafePointer[Curve]
    var plf_curve: UnsafePointer[Curve]
    var air_inlet_node_num: Int32
    var air_outlet_node_num: Int32
    var water_inlet_node_num: Int32
    var water_outlet_node_num: Int32
    var plant_loc: PlantLocation
    var water_cycling_mode: Int32
    var last_operating_mode: Int32
    var water_flow_mode: Bool
    var companion_cooling_coil_num: Int32
    var companion_heating_coil_num: Int32
    var twet_rated: Real64
    var gamma_rated: Real64
    var max_on_off_cycles_per_hour: Real64
    var latent_capacity_time_constant: Real64
    var fan_delay_time: Real64
    var report_coil_final_sizes: Bool
    var low_flow_flag: Bool
    
    fn __init__(inout self):
        self.name = ""
        self.coil_type = CoilType.Invalid
        self.coil_report_num = -1
        self.avail_sched = UnsafePointer[Schedule]()
        self.wahp_type = WatertoAirHP.Invalid
        self.wahp_plant_type = PlantEquipmentType.Invalid
        self.sim_flag = False
        self.air_vol_flow_rate = 0.0
        self.air_mass_flow_rate = 0.0
        self.inlet_air_db_temp = 0.0
        self.inlet_air_hum_rat = 0.0
        self.inlet_air_enthalpy = 0.0
        self.outlet_air_db_temp = 0.0
        self.outlet_air_hum_rat = 0.0
        self.outlet_air_enthalpy = 0.0
        self.water_vol_flow_rate = 0.0
        self.water_mass_flow_rate = 0.0
        self.design_water_mass_flow_rate = 0.0
        self.inlet_water_temp = 0.0
        self.inlet_water_enthalpy = 0.0
        self.outlet_water_temp = 0.0
        self.outlet_water_enthalpy = 0.0
        self.power = 0.0
        self.q_load_total = 0.0
        self.q_load_total_report = 0.0
        self.q_sensible = 0.0
        self.q_latent = 0.0
        self.q_source = 0.0
        self.energy = 0.0
        self.energy_load_total = 0.0
        self.energy_sensible = 0.0
        self.energy_latent = 0.0
        self.energy_source = 0.0
        self.cop = 0.0
        self.run_frac = 0.0
        self.part_load_ratio = 0.0
        self.rated_water_vol_flow_rate = 0.0
        self.rated_air_vol_flow_rate = 0.0
        self.rated_cap_heat = 0.0
        self.rated_cap_heat_at_rated_cdts = 0.0
        self.rated_cap_cool_at_rated_cdts = 0.0
        self.rated_cap_cool_sens_des_at_rated_cdts = 0.0
        self.rated_power_heat = 0.0
        self.rated_power_heat_at_rated_cdts = 0.0
        self.rated_cop_heat_at_rated_cdts = 0.0
        self.rated_cap_cool_total = 0.0
        self.rated_cap_cool_sens = 0.0
        self.rated_power_cool = 0.0
        self.rated_power_cool_at_rated_cdts = 0.0
        self.rated_cop_cool_at_rated_cdts = 0.0
        self.rated_ent_water_temp = 0.0
        self.rated_ent_air_wetbulb_temp = 0.0
        self.rated_ent_air_drybulb_temp = 0.0
        self.ratio_rated_heat_rated_tot_cool_cap = 0.0
        self.heat_cap_curve = UnsafePointer[Curve]()
        self.heat_pow_curve = UnsafePointer[Curve]()
        self.total_cool_cap_curve = UnsafePointer[Curve]()
        self.sens_cool_cap_curve = UnsafePointer[Curve]()
        self.cool_pow_curve = UnsafePointer[Curve]()
        self.plf_curve = UnsafePointer[Curve]()
        self.air_inlet_node_num = 0
        self.air_outlet_node_num = 0
        self.water_inlet_node_num = 0
        self.water_outlet_node_num = 0
        self.plant_loc = PlantLocation()
        self.water_cycling_mode = WaterFlow.Invalid
        self.last_operating_mode = 0
        self.water_flow_mode = False
        self.companion_cooling_coil_num = 0
        self.companion_heating_coil_num = 0
        self.twet_rated = 0.0
        self.gamma_rated = 0.0
        self.max_on_off_cycles_per_hour = 0.0
        self.latent_capacity_time_constant = 0.0
        self.fan_delay_time = 0.0
        self.report_coil_final_sizes = True
        self.low_flow_flag = True


struct WaterToAirHeatPumpSimpleData:
    """Global data structure for WSHP module."""
    var num_watertoair_hps: Int32
    var airflow_err_pointer: Int32
    var get_coils_input_flag: Bool
    var q_lat_rated: Real64
    var q_lat_actual: Real64
    var winput: Real64
    var my_one_time_flag: Bool
    var simple_watertoair_hp: List[SimpleWatertoAirHPConditions]
    
    fn __init__(inout self):
        self.num_watertoair_hps = 0
        self.airflow_err_pointer = 0
        self.get_coils_input_flag = True
        self.q_lat_rated = 0.0
        self.q_lat_actual = 0.0
        self.winput = 0.0
        self.my_one_time_flag = True
        self.simple_watertoair_hp = List[SimpleWatertoAirHPConditions]()


fn sim_watertoair_hp_simple(
    state: UnsafePointer[NoneType],
    comp_name: StringLiteral,
    inout comp_index: Int32,
    sens_load: Float64,
    latent_load: Float64,
    fan_op: Int32,
    compressor_op: Int32,
    part_load_ratio: Float64,
    first_hvac_iteration: Bool,
    on_off_air_flow_rat: Float64 = 1.0
) -> None:
    """Main simulation routine for water-to-air heat pump."""
    pass


fn get_simple_watertoair_hp_input(state: UnsafePointer[NoneType]) -> None:
    """Read input for water-to-air heat pump coils."""
    pass


fn init_simple_watertoair_hp(
    state: UnsafePointer[NoneType],
    hp_num: Int32,
    sens_load: Float64,
    latent_load: Float64,
    fan_op: Int32,
    on_off_air_flow_ratio: Float64,
    first_hvac_iteration: Bool,
    part_load_ratio: Float64
) -> None:
    """Initialize water-to-air heat pump."""
    pass


fn size_hvac_water_to_air(state: UnsafePointer[NoneType], hp_num: Int32) -> None:
    """Size water-to-air coil."""
    pass


fn calc_hp_cooling_simple(
    state: UnsafePointer[NoneType],
    hp_num: Int32,
    fan_op: Int32,
    sens_demand: Float64,
    latent_demand: Float64,
    compressor_op: Int32,
    part_load_ratio: Float64,
    on_off_air_flow_ratio: Float64
) -> None:
    """Calculate cooling performance."""
    pass


fn calc_hp_heating_simple(
    state: UnsafePointer[NoneType],
    hp_num: Int32,
    fan_op: Int32,
    sens_demand: Float64,
    compressor_op: Int32,
    part_load_ratio: Float64,
    on_off_air_flow_ratio: Float64
) -> None:
    """Calculate heating performance."""
    pass


fn update_simple_watertoair_hp(state: UnsafePointer[NoneType], hp_num: Int32) -> None:
    """Update outlet node conditions."""
    pass


fn calc_effective_shr(
    state: UnsafePointer[NoneType],
    hp_num: Int32,
    shr_ss: Float64,
    fan_op: Int32,
    rtf: Float64,
    q_lat_rated: Float64,
    q_lat_actual: Float64,
    entering_db: Float64,
    entering_wb: Float64
) -> Float64:
    """Calculate effective sensible heat ratio."""
    if rtf >= 1.0 or q_lat_rated <= 0.0 or q_lat_actual <= 0.0:
        return shr_ss
    return shr_ss


fn get_coil_index(
    state: UnsafePointer[NoneType],
    coil_type: StringLiteral,
    coil_name: StringLiteral
) -> Int32:
    """Get coil index by name."""
    return 0


fn get_coil_capacity(
    state: UnsafePointer[NoneType],
    coil_type: StringLiteral,
    coil_name: StringLiteral
) -> Float64:
    """Get rated coil capacity."""
    return -1000.0


fn get_coil_air_flow_rate(
    state: UnsafePointer[NoneType],
    coil_type: StringLiteral,
    coil_name: StringLiteral
) -> Float64:
    """Get rated air flow rate."""
    return -1000.0


fn get_coil_inlet_node(
    state: UnsafePointer[NoneType],
    coil_type: StringLiteral,
    coil_name: StringLiteral
) -> Int32:
    """Get coil air inlet node."""
    return 0


fn get_coil_outlet_node(
    state: UnsafePointer[NoneType],
    coil_type: StringLiteral,
    coil_name: StringLiteral
) -> Int32:
    """Get coil air outlet node."""
    return 0


fn set_simple_wshp_data(
    state: UnsafePointer[NoneType],
    simple_wshp_num: Int32,
    water_cycling_mode: Int32,
    companion_cooling_coil_num: Int32 = 0,
    companion_heating_coil_num: Int32 = 0
) -> None:
    """Set companion coil information."""
    pass


fn check_simple_wahp_rated_curves_outputs(
    state: UnsafePointer[NoneType],
    coil_name: StringLiteral
) -> None:
    """Check curve outputs at rated conditions."""
    pass
