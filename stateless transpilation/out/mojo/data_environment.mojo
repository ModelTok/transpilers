"""
EnergyPlus DataEnvironment module - environment and weather data

EXTERNAL DEPS (to wire in glue):
- EnergyPlusData: state container with data_envrn field (from EnergyPlus.Data.EnergyPlusData)
- Constant.KELVIN: absolute zero offset = 273.15 (from EnergyPlus.Data.Constant)
- show_severe_error, show_continue_error, show_fatal_error: error reporting (from EnergyPlus.UtilityRoutines)
- Sched.Schedule: schedule type stub (from EnergyPlus.ScheduleManager)
"""

from math import pow

alias Real64 = Float64


struct GroundTempType:
    alias Invalid = -1
    alias BuildingSurface = 0
    alias Shallow = 1
    alias Deep = 2
    alias FCFactorMethod = 3
    alias Num = 4


alias EARTH_RADIUS = 6356000.0
alias ATMOSPHERIC_TEMP_GRADIENT = 0.0065
alias SUN_IS_UP_VALUE = 0.00001
alias STD_PRESSURE_SEA_LEVEL = 101325.0


struct Vector3:
    var x: Real64
    var y: Real64
    var z: Real64
    
    fn __init__(inout self, x: Real64 = 0.0, y: Real64 = 0.0, z: Real64 = 0.0):
        self.x = x
        self.y = y
        self.z = z


struct EnvironmentData:
    var beam_solar_rad: Real64
    var ems_beam_solar_rad_override_on: Bool
    var ems_beam_solar_rad_override_value: Real64
    var day_of_month: Int32
    var day_of_month_tomorrow: Int32
    var day_of_week: Int32
    var day_of_week_tomorrow: Int32
    var day_of_year: Int32
    var day_of_year_schedule: Int32
    var dif_solar_rad: Real64
    var ems_dif_solar_rad_override_on: Bool
    var ems_dif_solar_rad_override_value: Real64
    var dst_indicator: Int32
    var elevation: Real64
    var end_month_flag: Bool
    var end_year_flag: Bool
    var gnd_reflectance_for_dayltg: Real64
    var gnd_reflectance: Real64
    var gnd_solar_rad: Real64
    var ground_temp_kelvin: Real64
    var ground_temp: InlineArray[Real64, 4]
    
    var holiday_index: Int32
    var holiday_index_tomorrow: Int32
    var is_rain: Bool
    var is_snow: Bool
    var latitude: Real64
    var longitude: Real64
    var month: Int32
    var month_tomorrow: Int32
    var out_baro_press: Real64
    var out_dry_bulb_temp: Real64
    var ems_out_dry_bulb_override_on: Bool
    var ems_out_dry_bulb_override_value: Real64
    var out_hum_rat: Real64
    var out_rel_hum: Real64
    var out_rel_hum_value: Real64
    var ems_out_rel_hum_override_on: Bool
    var ems_out_rel_hum_override_value: Real64
    var out_enthalpy: Real64
    var out_air_density: Real64
    var out_wet_bulb_temp: Real64
    var out_dew_point_temp: Real64
    var ems_out_dew_point_temp_override_on: Bool
    var ems_out_dew_point_temp_override_value: Real64
    var sky_temp: Real64
    var sky_temp_kelvin: Real64
    var liquid_precipitation: Real64
    var sun_is_up: Bool
    var sun_is_up_prev_ts: Bool
    var previous_sol_rad_positive: Bool
    var wind_dir: Real64
    var ems_wind_dir_override_on: Bool
    var ems_wind_dir_override_value: Real64
    var wind_speed: Real64
    var ems_wind_speed_override_on: Bool
    var ems_wind_speed_override_value: Real64
    var water_mains_temp: Real64
    var year: Int32
    var year_tomorrow: Int32
    var solcos: Vector3
    var cloud_fraction: Real64
    var hiskf: Real64
    var hisunf: Real64
    var hisunf_norm: Real64
    var pdirlw: Real64
    var pdiflw: Real64
    var sky_clearness: Real64
    var sky_brightness: Real64
    var total_cloud_cover: Real64
    var opaque_cloud_cover: Real64
    var std_baro_press: Real64
    var std_rho_air: Real64
    var rho_air_stp: Real64
    var time_zone_number: Real64
    var time_zone_meridian: Real64
    var environment_name: String
    var weather_file_location_title: String
    var cur_mn_dy_hr: String
    var cur_mn_dy: String
    var cur_mn_dy_yr: String
    var cur_environ_num: Int32
    var tot_des_days: Int32
    var tot_run_des_pers_days: Int32
    var current_overall_sim_day: Int32
    var total_overall_sim_days: Int32
    var max_number_sim_years: Int32
    var run_period_start_day_of_week: Int32
    var cos_solar_declin_angle: Real64
    var equation_of_time: Real64
    var sin_latitude: Real64
    var cos_latitude: Real64
    var sin_solar_declin_angle: Real64
    var ts1_time_offset: Real64
    var weather_file_wind_mod_coeff: Real64
    var weather_file_temp_mod_coeff: Real64
    var site_wind_exp: Real64
    var site_wind_bl_height: Real64
    var site_temp_gradient: Real64
    
    var ground_temp_inputs: InlineArray[Bool, 4]
    
    var display_weather_missing_data_warnings: Bool
    var ignore_solar_radiation: Bool
    var ignore_beam_radiation: Bool
    var ignore_diffuse_radiation: Bool
    var print_envrnstamp_warmup: Bool
    var print_envrnstamp_warmup_printed: Bool
    var run_period_environment: Bool
    var start_year: Int32
    var end_year: Int32
    var environment_start_end: String
    var current_year_is_leap_year: Bool
    var varying_location_lat_sched: UnsafeCPointer[UInt8]
    var varying_location_long_sched: UnsafeCPointer[UInt8]
    var varying_orientation_sched: UnsafeCPointer[UInt8]
    var force_begin_env_reset_suppress: Bool
    var one_time_comp_rpt_header_flag: Bool
    
    fn __init__(inout self):
        self.beam_solar_rad = 0.0
        self.ems_beam_solar_rad_override_on = False
        self.ems_beam_solar_rad_override_value = 0.0
        self.day_of_month = 0
        self.day_of_month_tomorrow = 0
        self.day_of_week = 0
        self.day_of_week_tomorrow = 0
        self.day_of_year = 0
        self.day_of_year_schedule = 0
        self.dif_solar_rad = 0.0
        self.ems_dif_solar_rad_override_on = False
        self.ems_dif_solar_rad_override_value = 0.0
        self.dst_indicator = 0
        self.elevation = 0.0
        self.end_month_flag = False
        self.end_year_flag = False
        self.gnd_reflectance_for_dayltg = 0.0
        self.gnd_reflectance = 0.0
        self.gnd_solar_rad = 0.0
        self.ground_temp_kelvin = 0.0
        self.ground_temp = InlineArray[Real64, 4](fill=0.0)
        
        self.holiday_index = 0
        self.holiday_index_tomorrow = 0
        self.is_rain = False
        self.is_snow = False
        self.latitude = 0.0
        self.longitude = 0.0
        self.month = 0
        self.month_tomorrow = 0
        self.out_baro_press = 0.0
        self.out_dry_bulb_temp = 0.0
        self.ems_out_dry_bulb_override_on = False
        self.ems_out_dry_bulb_override_value = 0.0
        self.out_hum_rat = 0.0
        self.out_rel_hum = 0.0
        self.out_rel_hum_value = 0.0
        self.ems_out_rel_hum_override_on = False
        self.ems_out_rel_hum_override_value = 0.0
        self.out_enthalpy = 0.0
        self.out_air_density = 0.0
        self.out_wet_bulb_temp = 0.0
        self.out_dew_point_temp = 0.0
        self.ems_out_dew_point_temp_override_on = False
        self.ems_out_dew_point_temp_override_value = 0.0
        self.sky_temp = 0.0
        self.sky_temp_kelvin = 0.0
        self.liquid_precipitation = 0.0
        self.sun_is_up = False
        self.sun_is_up_prev_ts = False
        self.previous_sol_rad_positive = False
        self.wind_dir = 0.0
        self.ems_wind_dir_override_on = False
        self.ems_wind_dir_override_value = 0.0
        self.wind_speed = 0.0
        self.ems_wind_speed_override_on = False
        self.ems_wind_speed_override_value = 0.0
        self.water_mains_temp = 0.0
        self.year = 0
        self.year_tomorrow = 0
        self.solcos = Vector3(0.0, 0.0, 0.0)
        self.cloud_fraction = 0.0
        self.hiskf = 0.0
        self.hisunf = 0.0
        self.hisunf_norm = 0.0
        self.pdirlw = 0.0
        self.pdiflw = 0.0
        self.sky_clearness = 0.0
        self.sky_brightness = 0.0
        self.total_cloud_cover = 5.0
        self.opaque_cloud_cover = 5.0
        self.std_baro_press = STD_PRESSURE_SEA_LEVEL
        self.std_rho_air = 0.0
        self.rho_air_stp = 0.0
        self.time_zone_number = 0.0
        self.time_zone_meridian = 0.0
        self.environment_name = String()
        self.weather_file_location_title = String()
        self.cur_mn_dy_hr = String()
        self.cur_mn_dy = String()
        self.cur_mn_dy_yr = String()
        self.cur_environ_num = 0
        self.tot_des_days = 0
        self.tot_run_des_pers_days = 0
        self.current_overall_sim_day = 0
        self.total_overall_sim_days = 0
        self.max_number_sim_years = 0
        self.run_period_start_day_of_week = 0
        self.cos_solar_declin_angle = 0.0
        self.equation_of_time = 0.0
        self.sin_latitude = 0.0
        self.cos_latitude = 0.0
        self.sin_solar_declin_angle = 0.0
        self.ts1_time_offset = -0.5
        self.weather_file_wind_mod_coeff = 1.5863
        self.weather_file_temp_mod_coeff = 0.0
        self.site_wind_exp = 0.22
        self.site_wind_bl_height = 370.0
        self.site_temp_gradient = 0.0065
        
        self.ground_temp_inputs = InlineArray[Bool, 4](fill=False)
        
        self.display_weather_missing_data_warnings = False
        self.ignore_solar_radiation = False
        self.ignore_beam_radiation = False
        self.ignore_diffuse_radiation = False
        self.print_envrnstamp_warmup = False
        self.print_envrnstamp_warmup_printed = False
        self.run_period_environment = False
        self.start_year = 0
        self.end_year = 0
        self.environment_start_end = String()
        self.current_year_is_leap_year = False
        self.varying_location_lat_sched = UnsafeCPointer[UInt8]()
        self.varying_location_long_sched = UnsafeCPointer[UInt8]()
        self.varying_orientation_sched = UnsafeCPointer[UInt8]()
        self.force_begin_env_reset_suppress = False
        self.one_time_comp_rpt_header_flag = True
    
    fn init_constant_state(inout self, state: UnsafeCPointer[UInt8]):
        pass
    
    fn init_state(inout self, state: UnsafeCPointer[UInt8]):
        pass
    
    fn clear_state(inout self):
        self = Self()


struct EnergyPlusDataStub:
    var data_envrn: EnvironmentData


fn show_severe_error(state: UnsafeCPointer[EnergyPlusDataStub], message: String):
    pass


fn show_continue_error(state: UnsafeCPointer[EnergyPlusDataStub], message: String):
    pass


fn show_fatal_error(state: UnsafeCPointer[EnergyPlusDataStub], message: String):
    pass


fn out_dry_bulb_temp_at(state: UnsafeCPointer[EnergyPlusDataStub], Z: Real64) -> Real64:
    """
    Calculates outdoor dry bulb temperature at a given altitude.
    1976 U.S. Standard Atmosphere.
    """
    let base_temp = state[].data_envrn.out_dry_bulb_temp + state[].data_envrn.weather_file_temp_mod_coeff
    
    var local_out_dry_bulb_temp: Real64
    if state[].data_envrn.site_temp_gradient == 0.0:
        local_out_dry_bulb_temp = state[].data_envrn.out_dry_bulb_temp
    elif Z <= 0.0:
        local_out_dry_bulb_temp = base_temp
    else:
        local_out_dry_bulb_temp = base_temp - state[].data_envrn.site_temp_gradient * EARTH_RADIUS * Z / (EARTH_RADIUS + Z)
    
    if local_out_dry_bulb_temp < -100.0:
        show_severe_error(state, "OutDryBulbTempAt: outdoor drybulb temperature < -100 C")
        show_continue_error(state, "...check heights, this height=[" + String(Int(Z)) + "].")
        show_fatal_error(state, "Program terminates due to preceding condition(s).")
    
    return local_out_dry_bulb_temp


fn out_wet_bulb_temp_at(state: UnsafeCPointer[EnergyPlusDataStub], Z: Real64) -> Real64:
    """
    Calculates outdoor wet bulb temperature at a given altitude.
    1976 U.S. Standard Atmosphere.
    """
    let base_temp = state[].data_envrn.out_wet_bulb_temp + state[].data_envrn.weather_file_temp_mod_coeff
    
    var local_out_wet_bulb_temp: Real64
    if state[].data_envrn.site_temp_gradient == 0.0:
        local_out_wet_bulb_temp = state[].data_envrn.out_wet_bulb_temp
    elif Z <= 0.0:
        local_out_wet_bulb_temp = base_temp
    else:
        local_out_wet_bulb_temp = base_temp - state[].data_envrn.site_temp_gradient * EARTH_RADIUS * Z / (EARTH_RADIUS + Z)
    
    if local_out_wet_bulb_temp < -100.0:
        show_severe_error(state, "OutWetBulbTempAt: outdoor wetbulb temperature < -100 C")
        show_continue_error(state, "...check heights, this height=[" + String(Int(Z)) + "].")
        show_fatal_error(state, "Program terminates due to preceding condition(s).")
    
    return local_out_wet_bulb_temp


fn wind_speed_at(state: UnsafeCPointer[EnergyPlusDataStub], Z: Real64) -> Real64:
    """
    Calculates local wind speed at a given altitude.
    2005 ASHRAE Fundamentals, Chapter 16, Equation 4.
    """
    if Z <= 0.0:
        return 0.0
    if state[].data_envrn.site_wind_exp == 0.0:
        return state[].data_envrn.wind_speed
    
    return state[].data_envrn.wind_speed * state[].data_envrn.weather_file_wind_mod_coeff * \
           pow(Z / state[].data_envrn.site_wind_bl_height, state[].data_envrn.site_wind_exp)


fn out_baro_press_at(state: UnsafeCPointer[EnergyPlusDataStub], Z: Real64) -> Real64:
    """
    Calculates local air barometric pressure at a given altitude.
    U.S. Standard Atmosphere 1976, Part 1, Chapter 1.3, Equation 33b.
    """
    alias STD_GRAVITY = 9.80665
    alias AIR_MOLAR_MASS = 0.028964
    alias GAS_CONSTANT = 8.31432
    alias TEMP_GRADIENT = -0.0065
    alias GEOPOTENTIAL_H = 0.0
    alias KELVIN = 273.15
    
    let base_temp = out_dry_bulb_temp_at(state, Z) + KELVIN
    
    var local_air_pressure: Real64
    if Z <= 0.0:
        local_air_pressure = 0.0
    elif state[].data_envrn.site_temp_gradient == 0.0:
        local_air_pressure = state[].data_envrn.out_baro_press
    else:
        local_air_pressure = state[].data_envrn.std_baro_press * pow(
            base_temp / (base_temp + TEMP_GRADIENT * (Z - GEOPOTENTIAL_H)),
            (STD_GRAVITY * AIR_MOLAR_MASS) / (GAS_CONSTANT * TEMP_GRADIENT)
        )
    
    return local_air_pressure


fn set_out_bulb_temp_at_error(state: UnsafeCPointer[EnergyPlusDataStub], settings: String, max_height: Real64, settings_name: String):
    """Error reporting for temperature out-of-range conditions"""
    show_severe_error(state, "SetOutBulbTempAt: " + settings + " Outdoor Temperatures < -100 C")
    show_continue_error(state, "...check " + settings + " Heights - Maximum " + settings + " Height=[" + String(Int(max_height)) + "].")
    if max_height >= 20000.0:
        show_continue_error(state, "...according to your maximum Z height, your building is somewhere in the Stratosphere.")
        show_continue_error(state, "...look at " + settings + " Name= " + settings_name)
    show_fatal_error(state, "Program terminates due to preceding condition(s).")


fn set_wind_speed_at(state: UnsafeCPointer[EnergyPlusDataStub], num_items: Int32, heights: UnsafeCPointer[Real64], local_wind_speed: UnsafeCPointer[Real64], settings: String):
    """
    Routine provides facility for doing bulk Set Windspeed at Height.
    """
    if state[].data_envrn.site_wind_exp == 0.0:
        for i in range(int(num_items)):
            local_wind_speed[i] = state[].data_envrn.wind_speed
    else:
        let fac = state[].data_envrn.wind_speed * state[].data_envrn.weather_file_wind_mod_coeff * \
                  pow(state[].data_envrn.site_wind_bl_height, -state[].data_envrn.site_wind_exp)
        
        for i in range(int(num_items)):
            let Z = heights[i]
            if Z <= 0.0:
                local_wind_speed[i] = 0.0
            else:
                local_wind_speed[i] = fac * pow(Z, state[].data_envrn.site_wind_exp)
