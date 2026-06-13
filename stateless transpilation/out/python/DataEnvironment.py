"""
EnergyPlus DataEnvironment module - environment and weather data

EXTERNAL DEPS (to wire in glue):
- EnergyPlusData: state container with .dataEnvrn attribute (from EnergyPlus.Data.EnergyPlusData)
- Constant.Kelvin: absolute zero offset = 273.15 (from EnergyPlus.Data.Constant)
- ShowSevereError, ShowContinueError, ShowFatalError: error reporting (from EnergyPlus.UtilityRoutines)
- Sched.Schedule: schedule type stub (from EnergyPlus.ScheduleManager)
"""

from dataclasses import dataclass, field
from typing import Any, Optional, Protocol
from enum import IntEnum
import math


class GroundTempType(IntEnum):
    Invalid = -1
    BuildingSurface = 0
    Shallow = 1
    Deep = 2
    FCFactorMethod = 3
    Num = 4


EARTH_RADIUS = 6356000.0
ATMOSPHERIC_TEMP_GRADIENT = 0.0065
SUN_IS_UP_VALUE = 0.00001
STD_PRESSURE_SEA_LEVEL = 101325.0


class EnvironmentDataState(Protocol):
    """Protocol for state container with environment data"""
    dataEnvrn: 'EnvironmentData'


def show_severe_error(state: Any, message: str) -> None:
    """Placeholder for error reporting"""
    pass


def show_continue_error(state: Any, message: str) -> None:
    """Placeholder for error reporting"""
    pass


def show_fatal_error(state: Any, message: str) -> None:
    """Placeholder for fatal error reporting"""
    raise RuntimeError(message)


@dataclass
class EnvironmentData:
    """Environmental and weather data container"""
    
    beam_solar_rad: float = 0.0
    ems_beam_solar_rad_override_on: bool = False
    ems_beam_solar_rad_override_value: float = 0.0
    day_of_month: int = 0
    day_of_month_tomorrow: int = 0
    day_of_week: int = 0
    day_of_week_tomorrow: int = 0
    day_of_year: int = 0
    day_of_year_schedule: int = 0
    dif_solar_rad: float = 0.0
    ems_dif_solar_rad_override_on: bool = False
    ems_dif_solar_rad_override_value: float = 0.0
    dst_indicator: int = 0
    elevation: float = 0.0
    end_month_flag: bool = False
    end_year_flag: bool = False
    gnd_reflectance_for_dayltg: float = 0.0
    gnd_reflectance: float = 0.0
    gnd_solar_rad: float = 0.0
    ground_temp_kelvin: float = 0.0
    ground_temp: list = field(default_factory=lambda: [0.0, 0.0, 0.0, 0.0])
    
    holiday_index: int = 0
    holiday_index_tomorrow: int = 0
    is_rain: bool = False
    is_snow: bool = False
    latitude: float = 0.0
    longitude: float = 0.0
    month: int = 0
    month_tomorrow: int = 0
    out_baro_press: float = 0.0
    out_dry_bulb_temp: float = 0.0
    ems_out_dry_bulb_override_on: bool = False
    ems_out_dry_bulb_override_value: float = 0.0
    out_hum_rat: float = 0.0
    out_rel_hum: float = 0.0
    out_rel_hum_value: float = 0.0
    ems_out_rel_hum_override_on: bool = False
    ems_out_rel_hum_override_value: float = 0.0
    out_enthalpy: float = 0.0
    out_air_density: float = 0.0
    out_wet_bulb_temp: float = 0.0
    out_dew_point_temp: float = 0.0
    ems_out_dew_point_temp_override_on: bool = False
    ems_out_dew_point_temp_override_value: float = 0.0
    sky_temp: float = 0.0
    sky_temp_kelvin: float = 0.0
    liquid_precipitation: float = 0.0
    sun_is_up: bool = False
    sun_is_up_prev_ts: bool = False
    previous_sol_rad_positive: bool = False
    wind_dir: float = 0.0
    ems_wind_dir_override_on: bool = False
    ems_wind_dir_override_value: float = 0.0
    wind_speed: float = 0.0
    ems_wind_speed_override_on: bool = False
    ems_wind_speed_override_value: float = 0.0
    water_mains_temp: float = 0.0
    year: int = 0
    year_tomorrow: int = 0
    solcos: tuple = field(default_factory=lambda: (0.0, 0.0, 0.0))
    cloud_fraction: float = 0.0
    hiskf: float = 0.0
    hisunf: float = 0.0
    hisunf_norm: float = 0.0
    pdirlw: float = 0.0
    pdiflw: float = 0.0
    sky_clearness: float = 0.0
    sky_brightness: float = 0.0
    total_cloud_cover: float = 5.0
    opaque_cloud_cover: float = 5.0
    std_baro_press: float = STD_PRESSURE_SEA_LEVEL
    std_rho_air: float = 0.0
    rho_air_stp: float = 0.0
    time_zone_number: float = 0.0
    time_zone_meridian: float = 0.0
    environment_name: str = ""
    weather_file_location_title: str = ""
    cur_mn_dy_hr: str = ""
    cur_mn_dy: str = ""
    cur_mn_dy_yr: str = ""
    cur_environ_num: int = 0
    tot_des_days: int = 0
    tot_run_des_pers_days: int = 0
    current_overall_sim_day: int = 0
    total_overall_sim_days: int = 0
    max_number_sim_years: int = 0
    run_period_start_day_of_week: int = 0
    cos_solar_declin_angle: float = 0.0
    equation_of_time: float = 0.0
    sin_latitude: float = 0.0
    cos_latitude: float = 0.0
    sin_solar_declin_angle: float = 0.0
    ts1_time_offset: float = -0.5
    weather_file_wind_mod_coeff: float = 1.5863
    weather_file_temp_mod_coeff: float = 0.0
    site_wind_exp: float = 0.22
    site_wind_bl_height: float = 370.0
    site_temp_gradient: float = 0.0065
    
    ground_temp_inputs: list = field(default_factory=lambda: [False, False, False, False])
    
    display_weather_missing_data_warnings: bool = False
    ignore_solar_radiation: bool = False
    ignore_beam_radiation: bool = False
    ignore_diffuse_radiation: bool = False
    print_envrnstamp_warmup: bool = False
    print_envrnstamp_warmup_printed: bool = False
    run_period_environment: bool = False
    start_year: int = 0
    end_year: int = 0
    environment_start_end: str = ""
    current_year_is_leap_year: bool = False
    varying_location_lat_sched: Optional[Any] = None
    varying_location_long_sched: Optional[Any] = None
    varying_orientation_sched: Optional[Any] = None
    force_begin_env_reset_suppress: bool = False
    one_time_comp_rpt_header_flag: bool = True
    
    def init_constant_state(self, state: Any) -> None:
        """Initialize constant state (no-op)"""
        pass
    
    def init_state(self, state: Any) -> None:
        """Initialize state (no-op)"""
        pass
    
    def clear_state(self) -> None:
        """Reset to default state"""
        for key, field_obj in self.__dataclass_fields__.items():
            if field_obj.default is not None:
                setattr(self, key, field_obj.default)
            elif field_obj.default_factory is not None:
                setattr(self, key, field_obj.default_factory())


def out_dry_bulb_temp_at(state: EnvironmentDataState, Z: float) -> float:
    """
    Calculates outdoor dry bulb temperature at a given altitude.
    1976 U.S. Standard Atmosphere.
    """
    base_temp = state.dataEnvrn.out_dry_bulb_temp + state.dataEnvrn.weather_file_temp_mod_coeff
    
    if state.dataEnvrn.site_temp_gradient == 0.0:
        local_out_dry_bulb_temp = state.dataEnvrn.out_dry_bulb_temp
    elif Z <= 0.0:
        local_out_dry_bulb_temp = base_temp
    else:
        local_out_dry_bulb_temp = base_temp - state.dataEnvrn.site_temp_gradient * EARTH_RADIUS * Z / (EARTH_RADIUS + Z)
    
    if local_out_dry_bulb_temp < -100.0:
        show_severe_error(state, "OutDryBulbTempAt: outdoor drybulb temperature < -100 C")
        show_continue_error(state, f"...check heights, this height=[{Z:.0f}].")
        show_fatal_error(state, "Program terminates due to preceding condition(s).")
    
    return local_out_dry_bulb_temp


def out_wet_bulb_temp_at(state: EnvironmentDataState, Z: float) -> float:
    """
    Calculates outdoor wet bulb temperature at a given altitude.
    1976 U.S. Standard Atmosphere.
    """
    base_temp = state.dataEnvrn.out_wet_bulb_temp + state.dataEnvrn.weather_file_temp_mod_coeff
    
    if state.dataEnvrn.site_temp_gradient == 0.0:
        local_out_wet_bulb_temp = state.dataEnvrn.out_wet_bulb_temp
    elif Z <= 0.0:
        local_out_wet_bulb_temp = base_temp
    else:
        local_out_wet_bulb_temp = base_temp - state.dataEnvrn.site_temp_gradient * EARTH_RADIUS * Z / (EARTH_RADIUS + Z)
    
    if local_out_wet_bulb_temp < -100.0:
        show_severe_error(state, "OutWetBulbTempAt: outdoor wetbulb temperature < -100 C")
        show_continue_error(state, f"...check heights, this height=[{Z:.0f}].")
        show_fatal_error(state, "Program terminates due to preceding condition(s).")
    
    return local_out_wet_bulb_temp


def wind_speed_at(state: EnvironmentDataState, Z: float) -> float:
    """
    Calculates local wind speed at a given altitude.
    2005 ASHRAE Fundamentals, Chapter 16, Equation 4.
    """
    if Z <= 0.0:
        return 0.0
    if state.dataEnvrn.site_wind_exp == 0.0:
        return state.dataEnvrn.wind_speed
    
    return state.dataEnvrn.wind_speed * state.dataEnvrn.weather_file_wind_mod_coeff * \
           math.pow(Z / state.dataEnvrn.site_wind_bl_height, state.dataEnvrn.site_wind_exp)


def out_baro_press_at(state: EnvironmentDataState, Z: float) -> float:
    """
    Calculates local air barometric pressure at a given altitude.
    U.S. Standard Atmosphere 1976, Part 1, Chapter 1.3, Equation 33b.
    """
    STD_GRAVITY = 9.80665
    AIR_MOLAR_MASS = 0.028964
    GAS_CONSTANT = 8.31432
    TEMP_GRADIENT = -0.0065
    GEOPOTENTIAL_H = 0.0
    KELVIN = 273.15
    
    base_temp = out_dry_bulb_temp_at(state, Z) + KELVIN
    
    if Z <= 0.0:
        local_air_pressure = 0.0
    elif state.dataEnvrn.site_temp_gradient == 0.0:
        local_air_pressure = state.dataEnvrn.out_baro_press
    else:
        local_air_pressure = state.dataEnvrn.std_baro_press * math.pow(
            base_temp / (base_temp + TEMP_GRADIENT * (Z - GEOPOTENTIAL_H)),
            (STD_GRAVITY * AIR_MOLAR_MASS) / (GAS_CONSTANT * TEMP_GRADIENT)
        )
    
    return local_air_pressure


def set_out_bulb_temp_at_error(state: EnvironmentDataState, settings: str, max_height: float, settings_name: str) -> None:
    """Error reporting for temperature out-of-range conditions"""
    show_severe_error(state, f"SetOutBulbTempAt: {settings} Outdoor Temperatures < -100 C")
    show_continue_error(state, f"...check {settings} Heights - Maximum {settings} Height=[{max_height:.0f}].")
    if max_height >= 20000.0:
        show_continue_error(state, "...according to your maximum Z height, your building is somewhere in the Stratosphere.")
        show_continue_error(state, f"...look at {settings} Name= {settings_name}")
    show_fatal_error(state, "Program terminates due to preceding condition(s).")


def set_wind_speed_at(state: EnvironmentDataState, num_items: int, heights: list, local_wind_speed: list, settings: str) -> None:
    """
    Routine provides facility for doing bulk Set Windspeed at Height.
    """
    if state.dataEnvrn.site_wind_exp == 0.0:
        for i in range(num_items):
            local_wind_speed[i] = state.dataEnvrn.wind_speed
    else:
        fac = state.dataEnvrn.wind_speed * state.dataEnvrn.weather_file_wind_mod_coeff * \
              math.pow(state.dataEnvrn.site_wind_bl_height, -state.dataEnvrn.site_wind_exp)
        
        for i in range(num_items):
            Z = heights[i]
            if Z <= 0.0:
                local_wind_speed[i] = 0.0
            else:
                local_wind_speed[i] = fac * math.pow(Z, state.dataEnvrn.site_wind_exp)
