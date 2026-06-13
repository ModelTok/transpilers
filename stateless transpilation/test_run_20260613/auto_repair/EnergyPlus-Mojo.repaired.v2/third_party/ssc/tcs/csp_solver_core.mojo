from lib_weatherfile import weather_data_provider, weather_header, weather_record
from csp_solver_util import C_csp_messages, C_csp_reported_outputs, C_csp_exception, util, csp_info_invalid
from numeric_solvers import C_monotonic_equation
from lib_util import *
from csp_dispatch import csp_dispatch_opt

import std.math
from std import *
from memory import Pointer, AddressSpace
import sys

# Comments and license text preserved

string C_csp_solver::tech_operating_modes_str[] = [
    "ENTRY_MODE",
    "CR_OFF__PC_OFF__TES_OFF__AUX_OFF",
    "CR_SU__PC_OFF__TES_OFF__AUX_OFF",
    "CR_ON__PC_SU__TES_OFF__AUX_OFF",
    "CR_ON__PC_SB__TES_OFF__AUX_OFF",
    "CR_ON__PC_RM_HI__TES_OFF__AUX_OFF",
    "CR_ON__PC_RM_LO__TES_OFF__AUX_OFF",
    "CR_DF__PC_MAX__TES_OFF__AUX_OFF",
    "CR_OFF__PC_SU__TES_DC__AUX_OFF",
    "CR_ON__PC_OFF__TES_CH__AUX_OFF",
    "SKIP_10",
    "CR_ON__PC_TARGET__TES_CH__AUX_OFF",
    "CR_ON__PC_TARGET__TES_DC__AUX_OFF",
    "CR_ON__PC_RM_LO__TES_EMPTY__AUX_OFF",
    "CR_DF__PC_OFF__TES_FULL__AUX_OFF",
    "CR_OFF__PC_SB__TES_DC__AUX_OFF",
    "CR_OFF__PC_MIN__TES_EMPTY__AUX_OFF",
    "CR_OFF__PC_RM_LO__TES_EMPTY__AUX_OFF",
    "CR_ON__PC_SB__TES_CH__AUX_OFF",
    "CR_SU__PC_MIN__TES_EMPTY__AUX_OFF",
    "SKIP_20",
    "CR_SU__PC_SB__TES_DC__AUX_OFF",
    "CR_ON__PC_SB__TES_DC__AUX_OFF",
    "CR_OFF__PC_TARGET__TES_DC__AUX_OFF",
    "CR_SU__PC_TARGET__TES_DC__AUX_OFF",
    "CR_ON__PC_RM_HI__TES_FULL__AUX_OFF",
    "CR_ON__PC_MIN__TES_EMPTY__AUX_OFF",
    "CR_SU__PC_RM_LO__TES_EMPTY__AUX_OFF",
    "CR_DF__PC_MAX__TES_FULL__AUX_OFF",
    "CR_ON__PC_SB__TES_FULL__AUX_OFF",
    "SKIP_30",
    "CR_SU__PC_SU__TES_DC__AUX_OFF",
    "CR_ON__PC_SU__TES_CH__AUX_OFF",
    "CR_DF__PC_SU__TES_FULL__AUX_OFF",
    "CR_DF__PC_SU__TES_OFF__AUX_OFF"
]

# class C_csp_solver_steam_state
struct C_csp_solver_steam_state:
    var m_temp: Float64     # [K]
    var m_pres: Float64     # [bar]
    var m_enth: Float64     # [kJ/kg]
    var m_x: Float64        # [-]
    def __init__(inout self):
        self.m_temp = Float64.nan
        self.m_pres = Float64.nan
        self.m_enth = Float64.nan
        self.m_x = Float64.nan

# class C_csp_solver_htf_1state
struct C_csp_solver_htf_1state:
    var m_temp: Float64     # [C]
    var m_pres: Float64     # [kPa]
    var m_qual: Float64     # [-]
    var m_m_dot: Float64    # [kg/s]
    def __init__(inout self):
        self.m_temp = Float64.nan
        self.m_pres = Float64.nan
        self.m_qual = Float64.nan
        self.m_m_dot = Float64.nan

# struct S_timestep
struct S_timestep:
    var m_time_start: Float64   # [s] Time at beginning of timestep
    var m_time: Float64         # [s] Time at *end* of timestep
    var m_step: Float64         # [s] Duration of timestep
    def __init__(inout self):
        self.m_time_start = Float64.nan
        self.m_time = Float64.nan
        self.m_step = Float64.nan

# class C_timestep_fixed
struct C_timestep_fixed:
    var ms_timestep: S_timestep
    def init(inout self, time_start: Float64, step: Float64):
        self.ms_timestep.m_time_start = time_start
        self.ms_timestep.m_step = step
        self.ms_timestep.m_time = self.ms_timestep.m_time_start + self.ms_timestep.m_step
    def get_end_time(self) -> Float64:
        return self.ms_timestep.m_time
    def get_step(self) -> Float64:
        return self.ms_timestep.m_step
    def step_forward(inout self):
        self.ms_timestep.m_time_start = self.ms_timestep.m_time
        self.ms_timestep.m_time += self.ms_timestep.m_step

# class C_csp_solver_sim_info
struct C_csp_solver_sim_info:
    var ms_ts: S_timestep
    var m_tou: Int32        # [-] Time-Of-Use Period
    def __init__(inout self):
        self.m_tou = -1

# class C_csp_weatherreader (partial, we need full)
struct C_csp_weatherreader:
    var m_first: Bool
    var m_error_msg: String
    var m_ncall: Int32
    var day_prev: Int32
    var m_is_wf_init: Bool
    var m_weather_data_provider: Pointer[weather_data_provider]
    var m_hdr: Pointer[weather_header]
    var m_rec: weather_record
    var mc_csp_messages: C_csp_messages

    struct S_csp_weatherreader_solved_params:
        var m_lat: Float64
        var m_lon: Float64
        var m_tz: Float64
        var m_shift: Float64
        var m_elev: Float64
        var m_leapyear: Bool
        def __init__(inout self):
            self.m_lat = Float64.nan
            self.m_lon = Float64.nan
            self.m_tz = Float64.nan
            self.m_shift = Float64.nan
            self.m_elev = Float64.nan
            self.m_leapyear = False

    struct S_outputs:
        var m_year: Int32
        var m_month: Int32
        var m_day: Int32
        var m_hour: Int32
        var m_minute: Float64
        var m_global: Float64
        var m_beam: Float64
        var m_hor_beam: Float64
        var m_diffuse: Float64
        var m_tdry: Float64
        var m_twet: Float64
        var m_tdew: Float64
        var m_wspd: Float64
        var m_wdir: Float64
        var m_rhum: Float64
        var m_pres: Float64
        var m_snow: Float64
        var m_albedo: Float64
        var m_aod: Float64
        var m_poa: Float64
        var m_solazi: Float64
        var m_solzen: Float64
        var m_lat: Float64
        var m_lon: Float64
        var m_tz: Float64
        var m_shift: Float64
        var m_elev: Float64
        var m_time_rise: Float64
        var m_time_set: Float64
        def __init__(inout self):
            self.m_year = -1
            self.m_month = -1
            self.m_day = -1
            self.m_hour = -1
            self.m_global = Float64.nan
            self.m_beam = Float64.nan
            self.m_hor_beam = Float64.nan
            self.m_diffuse = Float64.nan
            self.m_tdry = Float64.nan
            self.m_twet = Float64.nan
            self.m_tdew = Float64.nan
            self.m_wspd = Float64.nan
            self.m_wdir = Float64.nan
            self.m_rhum = Float64.nan
            self.m_pres = Float64.nan
            self.m_snow = Float64.nan
            self.m_albedo = Float64.nan
            self.m_aod = Float64.nan
            self.m_poa = Float64.nan
            self.m_solazi = Float64.nan
            self.m_solzen = Float64.nan
            self.m_lat = Float64.nan
            self.m_lon = Float64.nan
            self.m_tz = Float64.nan
            self.m_shift = Float64.nan
            self.m_elev = Float64.nan
            self.m_time_rise = Float64.nan
            self.m_time_set = Float64.nan

    var ms_solved_params: S_csp_weatherreader_solved_params
    var ms_outputs: S_outputs
    var m_filename: String
    var m_trackmode: Int32
    var m_tilt: Float64
    var m_azimuth: Float64

    def __init__(inout self):
        self.m_first = True
        self.m_error_msg = ""
        self.m_ncall = 0
        self.day_prev = 0
        self.m_is_wf_init = False
        self.m_weather_data_provider = Pointer[weather_data_provider]()
        self.m_hdr = Pointer[weather_header]()
        self.m_rec = weather_record()
        self.mc_csp_messages = C_csp_messages()
        self.ms_solved_params = S_csp_weatherreader_solved_params()
        self.ms_outputs = S_outputs()
        self.m_filename = ""
        self.m_trackmode = 0
        self.m_tilt = Float64.nan
        self.m_azimuth = Float64.nan

    def init(inout self):

    def timestep_call(inout self, p_sim_info: C_csp_solver_sim_info):

    def converged(inout self):

    def read_time_step(inout self, time_step: Int32, p_sim_info: C_csp_solver_sim_info) -> Bool:
        return True
    def has_error(self) -> Bool:
        return self.m_error_msg.size() > 0
    def get_error(self) -> String:
        return self.m_error_msg

# class C_csp_tou (partial)
struct C_csp_tou:
    struct S_csp_tou_params:
        var m_isleapyear: Bool
        var m_dispatch_optimize: Bool
        var m_optimize_frequency: Int32
        var m_disp_steps_per_hour: Int32
        var m_optimize_horizon: Int32
        var m_solver_timeout: Float64
        var m_mip_gap: Float64
        var m_presolve_type: Int32
        var m_bb_type: Int32
        var m_disp_reporting: Int32
        var m_scaling_type: Int32
        var m_max_iterations: Int32
        var m_disp_time_weighting: Float64
        var m_rsu_cost: Float64
        var m_csu_cost: Float64
        var m_q_rec_standby: Float64
        var m_pen_delta_w: Float64
        var m_disp_inventory_incentive: Float64
        var m_w_rec_ht: Float64
        var m_w_lim_full: List[Float64]
        var m_is_write_ampl_dat: Bool
        var m_is_ampl_engine: Bool
        var m_ampl_data_dir: String
        var m_ampl_exec_call: String
        var m_is_tod_pc_target_also_pc_max: Bool
        var m_is_block_dispatch: Bool
        var m_use_rule_1: Bool
        var m_standby_off_buffer: Float64
        var m_use_rule_2: Bool
        var m_q_dot_rec_des_mult: Float64
        var m_f_q_dot_pc_overwrite: Float64
        def __init__(inout self):
            self.m_isleapyear = False
            self.m_dispatch_optimize = False
            self.m_optimize_frequency = 24
            self.m_disp_steps_per_hour = 1
            self.m_optimize_horizon = 48
            self.m_solver_timeout = 5.0
            self.m_mip_gap = 0.055
            self.m_max_iterations = 10000
            self.m_bb_type = -1
            self.m_disp_reporting = -1
            self.m_presolve_type = -1
            self.m_scaling_type = -1
            self.m_disp_time_weighting = 0.99
            self.m_rsu_cost = 952.0
            self.m_csu_cost = 10000.0
            self.m_pen_delta_w = 0.1
            self.m_disp_inventory_incentive = 0.0
            self.m_q_rec_standby = 9e99
            self.m_w_rec_ht = 0.0
            self.m_w_lim_full = List[Float64](8760)
            for i in range(8760):
                self.m_w_lim_full[i] = 9e99
            self.m_is_write_ampl_dat = False
            self.m_is_ampl_engine = False
            self.m_ampl_data_dir = ""
            self.m_ampl_exec_call = ""
            self.m_is_tod_pc_target_also_pc_max = False
            self.m_is_block_dispatch = True
            self.m_use_rule_1 = False
            self.m_standby_off_buffer = -1.23
            self.m_use_rule_2 = False
            self.m_q_dot_rec_des_mult = -1.23
            self.m_f_q_dot_pc_overwrite = 1.23

    struct S_csp_tou_outputs:
        var m_csp_op_tou: Int32
        var m_pricing_tou: Int32
        var m_f_turbine: Float64
        var m_price_mult: Float64
        def __init__(inout self):
            self.m_csp_op_tou = -1
            self.m_pricing_tou = -1
            self.m_f_turbine = Float64.nan
            self.m_price_mult = Float64.nan

    var mc_dispatch_params: S_csp_tou_params
    def __init__(inout self):
        self.mc_dispatch_params = S_csp_tou_params()
    def init_parent(inout self):
        # body from .cpp
        if not (self.mc_dispatch_params.m_dispatch_optimize or self.mc_dispatch_params.m_is_block_dispatch):
            throw C_csp_exception("Must select a plant control strategy", "TOU initialization")
        if self.mc_dispatch_params.m_dispatch_optimize and self.mc_dispatch_params.m_is_block_dispatch:
            throw C_csp_exception("Both plant control strategies were selected. Please select one.", "TOU initialization")
        if self.mc_dispatch_params.m_is_block_dispatch:
            if self.mc_dispatch_params.m_use_rule_1:
                if self.mc_dispatch_params.m_standby_off_buffer < 0.0:
                    throw C_csp_exception("Block Dispatch Rule 1 was selected, but the time entered was invalid. Please select a time >= 0", "TOU initialization")
            if self.mc_dispatch_params.m_use_rule_2:
                if self.mc_dispatch_params.m_f_q_dot_pc_overwrite <= 0.0 or self.mc_dispatch_params.m_q_dot_rec_des_mult <= 0.0:
                    throw C_csp_exception("Block Dispatch Rule 2 was selected, but the parameters entered were invalid. Both values must be greater than 0", "TOU initialization")
    def init(inout self): pass # pure virtual, will be overridden by implementing struct
    def call(inout self, time_s: Float64, tou_outputs: inout S_csp_tou_outputs): pass

# trait for C_csp_collector_receiver
trait C_csp_collector_receiver:
    var mc_csp_messages: C_csp_messages
    var m_max_step: Float64
    var m_is_sensible_htf: Bool

    struct S_csp_cr_init_inputs:
        var m_latitude: Float64
        var m_longitude: Float64
        var m_tz: Float64
        var m_shift: Float64
        var m_elev: Float64
        def __init__(inout self):
            self.m_latitude = Float64.nan
            self.m_longitude = Float64.nan
            self.m_tz = Float64.nan
            self.m_shift = Float64.nan
            self.m_elev = Float64.nan

    struct S_csp_cr_solved_params:
        var m_T_htf_cold_des: Float64
        var m_P_cold_des: Float64
        var m_x_cold_des: Float64
        var m_T_htf_hot_des: Float64
        var m_q_dot_rec_des: Float64
        var m_A_aper_total: Float64
        var m_dP_sf: Float64
        def __init__(inout self):
            self.m_T_htf_cold_des = Float64.nan
            self.m_P_cold_des = Float64.nan
            self.m_x_cold_des = Float64.nan
            self.m_T_htf_hot_des = Float64.nan
            self.m_q_dot_rec_des = Float64.nan
            self.m_A_aper_total = Float64.nan
            self.m_dP_sf = Float64.nan

    struct S_csp_cr_inputs:
        var m_field_control: Float64
        var m_input_operation_mode: Int32
        var m_adjust: Float64
        def __init__(inout self):
            self.m_field_control = Float64.nan
            self.m_input_operation_mode = 0 # OFF
            self.m_adjust = Float64.nan

    struct S_csp_cr_out_solver:
        var m_q_startup: Float64
        var m_time_required_su: Float64
        var m_m_dot_salt_tot: Float64
        var m_q_thermal: Float64
        var m_T_salt_hot: Float64
        var m_component_defocus: Float64
        var m_is_recirculating: Bool
        var m_E_fp_total: Float64
        var m_W_dot_col_tracking: Float64
        var m_W_dot_htf_pump: Float64
        var m_dP_sf: Float64
        var m_q_rec_heattrace: Float64
        var m_standby_control: Int32
        var m_dP_sf_sh: Float64
        var m_h_htf_hot: Float64
        var m_xb_htf_hot: Float64
        var m_P_htf_hot: Float64
        def __init__(inout self):
            self.m_q_startup = Float64.nan
            self.m_time_required_su = Float64.nan
            self.m_m_dot_salt_tot = Float64.nan
            self.m_q_thermal = Float64.nan
            self.m_T_salt_hot = Float64.nan
            self.m_W_dot_col_tracking = Float64.nan
            self.m_W_dot_htf_pump = Float64.nan
            self.m_component_defocus = 1.0
            self.m_is_recirculating = False
            self.m_E_fp_total = Float64.nan
            self.m_dP_sf = Float64.nan
            self.m_q_rec_heattrace = 0.0
            self.m_standby_control = -1
            self.m_dP_sf_sh = Float64.nan
            self.m_h_htf_hot = Float64.nan
            self.m_xb_htf_hot = Float64.nan
            self.m_P_htf_hot = Float64.nan

    struct S_csp_cr_est_out:
        var m_q_startup_avail: Float64
        var m_q_dot_avail: Float64
        var m_m_dot_avail: Float64
        var m_T_htf_hot: Float64
        def __init__(inout self):
            self.m_q_startup_avail = Float64.nan
            self.m_q_dot_avail = Float64.nan
            self.m_m_dot_avail = Float64.nan
            self.m_T_htf_hot = Float64.nan

    def init(inout self, init_inputs: S_csp_cr_init_inputs, solved_params: inout S_csp_cr_solved_params): pass
    def get_operating_state(self) -> Int32: pass
    def get_startup_time(self) -> Float64: pass
    def get_startup_energy(self) -> Float64: pass
    def get_pumping_parasitic_coef(self) -> Float64: pass
    def get_min_power_delivery(self) -> Float64: pass
    def get_tracking_power(self) -> Float64: pass
    def get_col_startup_power(self) -> Float64: pass
    def off(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, cr_out_solver: inout S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info): pass
    def startup(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, cr_out_solver: inout S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info): pass
    def on(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, field_control: Float64, cr_out_solver: inout S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info): pass
    def estimates(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, est_out: inout S_csp_cr_est_out, sim_info: C_csp_solver_sim_info): pass
    def converged(inout self): pass
    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64): pass
    def calculate_optical_efficiency(self, weather: C_csp_weatherreader.S_outputs, sim: C_csp_solver_sim_info) -> Float64: pass
    def calculate_thermal_efficiency_approx(self, weather: C_csp_weatherreader.S_outputs, q_incident: Float64) -> Float64: pass
    def get_collector_area(self) -> Float64: pass

# trait for C_csp_power_cycle
trait C_csp_power_cycle:
    var m_is_sensible_htf: Bool

    struct S_control_inputs:
        var m_standby_control: Int32
        var m_m_dot: Float64
        def __init__(inout self):
            self.m_standby_control = 0 # OFF
            # m_m_dot not initialized in ctor

    struct S_solved_params:
        var m_W_dot_des: Float64
        var m_eta_des: Float64
        var m_q_dot_des: Float64
        var m_q_startup: Float64
        var m_max_frac: Float64
        var m_cutoff_frac: Float64
        var m_sb_frac: Float64
        var m_T_htf_hot_ref: Float64
        var m_m_dot_design: Float64
        var m_m_dot_max: Float64
        var m_m_dot_min: Float64
        var m_P_hot_des: Float64
        var m_x_hot_des: Float64
        def __init__(inout self):
            self.m_W_dot_des = Float64.nan
            self.m_eta_des = Float64.nan
            self.m_q_dot_des = Float64.nan
            self.m_q_startup = Float64.nan
            self.m_max_frac = Float64.nan
            self.m_cutoff_frac = Float64.nan
            self.m_sb_frac = Float64.nan
            self.m_T_htf_hot_ref = Float64.nan
            self.m_m_dot_design = Float64.nan
            self.m_m_dot_max = Float64.nan
            self.m_m_dot_min = Float64.nan
            self.m_P_hot_des = Float64.nan
            self.m_x_hot_des = Float64.nan

    struct S_csp_pc_out_solver:
        var m_time_required_su: Float64
        var m_time_required_max: Float64
        var m_P_cycle: Float64
        var m_T_htf_cold: Float64
        var m_q_dot_htf: Float64
        var m_m_dot_htf: Float64
        var m_W_dot_htf_pump: Float64
        var m_W_cool_par: Float64
        var m_was_method_successful: Bool
        def __init__(inout self):
            self.m_time_required_su = Float64.nan
            self.m_time_required_max = Float64.nan
            self.m_P_cycle = Float64.nan
            self.m_T_htf_cold = Float64.nan
            self.m_q_dot_htf = Float64.nan
            self.m_m_dot_htf = Float64.nan
            self.m_W_dot_htf_pump = Float64.nan
            self.m_W_cool_par = Float64.nan
            self.m_was_method_successful = False

    def init(inout self, solved_params: inout S_solved_params): pass
    def get_operating_state(self) -> Int32: pass
    def get_cold_startup_time(self) -> Float64: pass
    def get_warm_startup_time(self) -> Float64: pass
    def get_hot_startup_time(self) -> Float64: pass
    def get_standby_energy_requirement(self) -> Float64: pass
    def get_cold_startup_energy(self) -> Float64: pass
    def get_warm_startup_energy(self) -> Float64: pass
    def get_hot_startup_energy(self) -> Float64: pass
    def get_max_thermal_power(self) -> Float64: pass
    def get_min_thermal_power(self) -> Float64: pass
    def get_max_power_output_operation_constraints(inout self, T_amb: Float64, m_dot_HTF_ND_max: inout Float64, W_dot_ND_max: inout Float64): pass
    def get_efficiency_at_TPH(self, T_degC: Float64, P_atm: Float64, relhum_pct: Float64, w_dot_condenser: inout Float64 = Pointer[Float64]()) -> Float64: pass
    def get_efficiency_at_load(self, load_frac: Float64, w_dot_condenser: inout Float64 = Pointer[Float64]()) -> Float64: pass
    def get_htf_pumping_parasitic_coef(self) -> Float64: pass
    def get_max_q_pc_startup(self) -> Float64: pass
    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: S_control_inputs, out_solver: inout S_csp_pc_out_solver, sim_info: C_csp_solver_sim_info): pass
    def converged(inout self): pass
    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64): pass
    def assign(inout self, index: Int32, p_reporting_ts_array: inout Pointer[Float64], n_reporting_ts_array: Int): pass

# trait for C_csp_tes
trait C_csp_tes:
    struct S_csp_tes_init_inputs:
        var T_to_cr_at_des: Float64
        var T_from_cr_at_des: Float64
        var P_to_cr_at_des: Float64
        def __init__(inout self):
            self.T_to_cr_at_des = Float64.nan
            self.T_from_cr_at_des = Float64.nan
            self.P_to_cr_at_des = Float64.nan

    struct S_csp_tes_outputs:
        var m_q_heater: Float64
        var m_q_dot_dc_to_htf: Float64
        var m_q_dot_ch_from_htf: Float64
        var m_m_dot_cr_to_tes_hot: Float64
        var m_m_dot_tes_hot_out: Float64
        var m_m_dot_pc_to_tes_cold: Float64
        var m_m_dot_tes_cold_out: Float64
        var m_m_dot_field_to_cycle: Float64
        var m_m_dot_cycle_to_field: Float64
        var m_m_dot_cold_tank_to_hot_tank: Float64
        def __init__(inout self):
            self.m_q_heater = Float64.nan
            self.m_q_dot_dc_to_htf = Float64.nan
            self.m_q_dot_ch_from_htf = Float64.nan
            self.m_m_dot_cr_to_tes_hot = Float64.nan
            self.m_m_dot_tes_hot_out = Float64.nan
            self.m_m_dot_pc_to_tes_cold = Float64.nan
            self.m_m_dot_tes_cold_out = Float64.nan
            self.m_m_dot_field_to_cycle = Float64.nan
            self.m_m_dot_cycle_to_field = Float64.nan
            self.m_m_dot_cold_tank_to_hot_tank = Float64.nan

    def init(inout self, init_inputs: S_csp_tes_init_inputs): pass
    def does_tes_exist(self) -> Bool: pass
    def get_hot_temp(self) -> Float64: pass
    def get_cold_temp(self) -> Float64: pass
    def get_hot_tank_vol_frac(self) -> Float64: pass
    def get_initial_charge_energy(self) -> Float64: pass
    def get_min_charge_energy(self) -> Float64: pass
    def get_max_charge_energy(self) -> Float64: pass
    def get_degradation_rate(self) -> Float64: pass
    def discharge_avail_est(inout self, T_cold_K: Float64, step_s: Float64, q_dot_dc_est: inout Float64, m_dot_field_est: inout Float64, T_hot_field_est: inout Float64): pass
    def charge_avail_est(inout self, T_hot_K: Float64, step_s: Float64, q_dot_ch_est: inout Float64, m_dot_field_est: inout Float64, T_cold_field_est: inout Float64): pass
    def solve_tes_off_design(inout self, timestep: Float64, T_amb: Float64, m_dot_field: Float64, m_dot_cycle: Float64, T_field_htf_out_hot: Float64, T_cycle_htf_out_cold: Float64, T_cycle_htf_in_hot: inout Float64, T_field_htf_in_cold: inout Float64, outputs: inout S_csp_tes_outputs) -> Int32: pass
    def converged(inout self): pass
    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64): pass
    def assign(inout self, index: Int32, p_reporting_ts_array: inout Pointer[Float64], n_reporting_ts_array: Int): pass
    def pumping_power(self, m_dot_sf: Float64, m_dot_pb: Float64, m_dot_tank: Float64, T_sf_in: Float64, T_sf_out: Float64, T_pb_in: Float64, T_pb_out: Float64, recirculating: Bool) -> Float64: pass

# class C_csp_solver (main class)
struct C_csp_solver:
    var mc_weather: C_csp_weatherreader
    var mc_collector_receiver: Pointer[C_csp_collector_receiver]
    var mc_power_cycle: Pointer[C_csp_power_cycle]
    var mc_tes: Pointer[C_csp_tes]
    var mc_tou: C_csp_tou
    var ms_system_params: C_csp_solver.S_csp_system_params
    var mc_cr_htf_state_in: C_csp_solver_htf_1state
    var mc_cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver
    var mc_pc_htf_state_in: C_csp_solver_htf_1state
    var mc_pc_inputs: C_csp_power_cycle.S_control_inputs
    var mc_pc_out_solver: C_csp_power_cycle.S_csp_pc_out_solver
    var mc_tes_outputs: C_csp_tes.S_csp_tes_outputs
    var mc_tou_outputs: C_csp_tou.S_csp_tou_outputs
    var mc_kernel: C_csp_solver.C_csp_solver_kernel
    var mc_reported_outputs: C_csp_reported_outputs
    var m_is_CR_SU__PC_OFF__TES_OFF__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SB__TES_OFF__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SU__TES_OFF__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_OFF__TES_CH__AUX_OFF_avail: Bool
    var m_is_CR_OFF__PC_SU__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_DF__PC_MAX__TES_OFF__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_HI_SIDE: Bool
    var m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_LO_SIDE: Bool
    var m_is_CR_ON__PC_RM_LO__TES_OFF__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_HI_SIDE: Bool
    var m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_LO_SIDE: Bool
    var m_is_CR_ON__PC_TARGET__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_RM_LO__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_DF__PC_OFF__TES_FULL__AUX_OFF_avail: Bool
    var m_is_CR_OFF__PC_SB__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_OFF__PC_MIN__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_OFF__PC_RM_LO__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SB__TES_CH__AUX_OFF_avail: Bool
    var m_is_CR_SU__PC_MIN__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_SU__PC_SB__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SB__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_OFF__PC_TARGET__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_SU__PC_TARGET__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_RM_HI__TES_FULL__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_MIN__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_SU__PC_RM_LO__TES_EMPTY__AUX_OFF_avail: Bool
    var m_is_CR_DF__PC_MAX__TES_FULL__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SB__TES_FULL__AUX_OFF_avail: Bool
    var m_is_CR_SU__PC_SU__TES_DC__AUX_OFF_avail: Bool
    var m_is_CR_ON__PC_SU__TES_CH__AUX_OFF_avail: Bool
    var m_is_CR_DF__PC_SU__TES_FULL__AUX_OFF_avail: Bool
    var m_is_CR_DF__PC_SU__TES_OFF__AUX_OFF_avail: Bool
    var error_msg: String
    var m_T_htf_cold_des: Float64
    var m_P_cold_des: Float64
    var m_x_cold_des: Float64
    var m_q_dot_rec_des: Float64
    var m_A_aperture: Float64
    var m_cycle_W_dot_des: Float64
    var m_cycle_eta_des: Float64
    var m_cycle_q_dot_des: Float64
    var m_cycle_max_frac: Float64
    var m_cycle_cutoff_frac: Float64
    var m_cycle_sb_frac_des: Float64
    var m_cycle_T_htf_hot_des: Float64
    var m_cycle_P_hot_des: Float64
    var m_cycle_x_hot_des: Float64
    var m_m_dot_pc_des: Float64
    var m_m_dot_pc_min: Float64
    var m_m_dot_pc_max: Float64
    var m_m_dot_pc_max_startup: Float64
    var m_is_tes: Bool
    var m_is_cr_config_recirc: Bool
    var m_T_field_cold_limit: Float64
    var m_T_field_in_hot_limit: Float64
    var m_is_first_timestep: Bool
    var m_i_reporting: Int32
    var m_report_time_start: Float64
    var m_report_time_end: Float64
    var m_report_step: Float64
    var m_step_tolerance: Float64
    var m_T_htf_pc_cold_est: Float64
    var m_defocus: Float64
    var m_q_dot_pc_max: Float64
    var mv_time_local: List[Float64]
    var mpf_callback: Pointer[ (String, String, inout Void, Float64, Int32) -> Bool ]
    var mp_cmod_active: Pointer[Void]
    var mc_csp_messages: C_csp_messages
    var m_op_mode_tracking: List[Int32]

    struct C_solver_outputs:
        enum E:
            TIME_FINAL = 0
            MONTH = 1
            HOUR_DAY = 2
            ERR_M_DOT = 3
            ERR_Q_DOT = 4
            N_OP_MODES = 5
            OP_MODE_1 = 6
            OP_MODE_2 = 7
            OP_MODE_3 = 8
            TOU_PERIOD = 9
            PRICING_MULT = 10
            PC_Q_DOT_SB = 11
            PC_Q_DOT_MIN = 12
            PC_Q_DOT_TARGET = 13
            PC_Q_DOT_MAX = 14
            CTRL_IS_REC_SU = 15
            CTRL_IS_PC_SU = 16
            CTRL_IS_PC_SB = 17
            EST_Q_DOT_CR_SU = 18
            EST_Q_DOT_CR_ON = 19
            EST_Q_DOT_DC = 20
            EST_Q_DOT_CH = 21
            CTRL_OP_MODE_SEQ_A = 22
            CTRL_OP_MODE_SEQ_B = 23
            CTRL_OP_MODE_SEQ_C = 24
            DISPATCH_SOLVE_STATE = 25
            DISPATCH_SOLVE_ITER = 26
            DISPATCH_SOLVE_OBJ = 27
            DISPATCH_SOLVE_OBJ_RELAX = 28
            DISPATCH_QSF_EXPECT = 29
            DISPATCH_QSFPROD_EXPECT = 30
            DISPATCH_QSFSU_EXPECT = 31
            DISPATCH_TES_EXPECT = 32
            DISPATCH_PCEFF_EXPECT = 33
            DISPATCH_SFEFF_EXPECT = 34
            DISPATCH_QPBSU_EXPECT = 35
            DISPATCH_WPB_EXPECT = 36
            DISPATCH_REV_EXPECT = 37
            DISPATCH_PRES_NCONSTR = 38
            DISPATCH_PRES_NVAR = 39
            DISPATCH_SOLVE_TIME = 40
            SOLZEN = 41
            SOLAZ = 42
            BEAM = 43
            TDRY = 44
            TWET = 45
            RH = 46
            WSPD = 47
            PRES = 48
            CR_DEFOCUS = 49
            TES_Q_DOT_DC = 50
            TES_Q_DOT_CH = 51
            TES_E_CH_STATE = 52
            M_DOT_CR_TO_TES_HOT = 53
            M_DOT_TES_HOT_OUT = 54
            M_DOT_PC_TO_TES_COLD = 55
            M_DOT_TES_COLD_OUT = 56
            M_DOT_FIELD_TO_CYCLE = 57
            M_DOT_CYCLE_TO_FIELD = 58
            COL_W_DOT_TRACK = 59
            CR_W_DOT_PUMP = 60
            SYS_W_DOT_PUMP = 61
            PC_W_DOT_COOLING = 62
            SYS_W_DOT_FIXED = 63
            SYS_W_DOT_BOP = 64
            W_DOT_NET = 65

    struct S_sim_setup:
        var m_sim_time_start: Float64
        var m_sim_time_end: Float64
        var m_report_step: Float64
        def __init__(inout self):
            self.m_sim_time_start = Float64.nan
            self.m_sim_time_end = Float64.nan
            self.m_report_step = Float64.nan

    struct S_op_mode_params:
        var m_cr_mode: Int32
        var m_pc_mode: Int32
        var m_solver_mode: Int32
        var m_step_target_mod: Int32
        var m_is_defocus: Bool
        def __init__(inout self):
            self.m_cr_mode = -1
            self.m_pc_mode = -1
            self.m_solver_mode = -1
            self.m_step_target_mod = -1
            self.m_is_defocus = False

    struct C_csp_solver_kernel:
        var ms_sim_setup: S_sim_setup
        var mc_ts_weatherfile: C_timestep_fixed
        var mc_ts_sim_baseline: C_timestep_fixed
        var mc_sim_info: C_csp_solver_sim_info
        def init(inout self, sim_setup: inout S_sim_setup, wf_step: Float64, baseline_step: Float64, csp_messages: inout C_csp_messages):
            self.ms_sim_setup = sim_setup # copy
            if baseline_step > wf_step:
                var msg: String = util.format("The input Baseline Simulation Timestep (%lg [s]) must be less than or equal to the Weatherfile Timestep (%lg [s]). It was reset to the Weatherfile Timestep", baseline_step, wf_step)
                csp_messages.add_message(C_csp_messages.WARNING, msg)
                baseline_step = wf_step
            elif (Int32)(wf_step) % (Int32)(baseline_step) != 0:
                var wf_over_bl: Float64 = wf_step / baseline_step
                var wf_over_bl_new: Float64 = ceil(wf_over_bl)
                var baseline_step_new: Float64 = wf_step / wf_over_bl_new
                var msg: String = util.format("The Weatherfile Timestep (%lg [s]) must be divisible by the input Baseline Simulation Timestep (%lg [s]). It was reset to %lg [s].", wf_step, baseline_step, baseline_step_new)
                csp_messages.add_message(C_csp_messages.WARNING, msg)
                baseline_step = baseline_step_new
            var wf_time_start: Float64 = self.ms_sim_setup.m_sim_time_start
            var baseline_time_start: Float64 = self.ms_sim_setup.m_sim_time_start
            self.mc_ts_weatherfile.init(wf_time_start, wf_step)
            self.mc_ts_sim_baseline.init(baseline_time_start, baseline_step)
            self.mc_sim_info.ms_ts.m_time_start = self.ms_sim_setup.m_sim_time_start
            self.mc_sim_info.ms_ts.m_step = baseline_step
            self.mc_sim_info.ms_ts.m_time = self.mc_sim_info.ms_ts.m_time_start + self.mc_sim_info.ms_ts.m_step
        def get_wf_end_time(self) -> Float64:
            return self.mc_ts_weatherfile.get_end_time()
        def get_baseline_end_time(self) -> Float64:
            return self.mc_ts_sim_baseline.get_end_time()
        def wf_step_forward(inout self):
            self.mc_ts_weatherfile.step_forward()
        def get_sim_setup(self) -> Pointer[S_sim_setup]:
            return Pointer[S_sim_setup].address_of(self.ms_sim_setup)
        def get_wf_step(self) -> Float64:
            return self.mc_ts_weatherfile.get_step()
        def get_baseline_step(self) -> Float64:
            return self.mc_ts_sim_baseline.get_step()
        def baseline_step_forward(inout self):
            self.mc_ts_sim_baseline.step_forward()

    struct S_csp_system_params:
        var m_pb_fixed_par: Float64
        var m_bop_par: Float64
        var m_bop_par_f: Float64
        var m_bop_par_0: Float64
        var m_bop_par_1: Float64
        var m_bop_par_2: Float64
        def __init__(inout self):
            self.m_pb_fixed_par = Float64.nan
            self.m_bop_par = Float64.nan
            self.m_bop_par_f = Float64.nan
            self.m_bop_par_0 = Float64.nan
            self.m_bop_par_1 = Float64.nan
            self.m_bop_par_2 = Float64.nan

    # Nested classes C_MEQ__m_dot_tes, C_MEQ__T_field_cold, C_MEQ__timestep, C_MEQ__defocus
    struct C_MEQ__m_dot_tes(C_monotonic_equation):
        enum E_m_dot_solver_modes:
            E__PC_MAX_PLUS_TES_FULL__PC_MAX = 0
            E__CR_OUT__CR_OUT_PLUS_TES_EMPTY = 1
            E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU = 2
            E__CR_OUT__0 = 3
            E__CR_OUT__ITER_M_DOT_SU_CH_ONLY = 4
            E__CR_OUT__ITER_M_DOT_SU_DC_ONLY = 5
            E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY = 6
            E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY = 7
            E__CR_OUT__CR_OUT = 8
            E__CR_OUT__CR_OUT_LESS_TES_FULL = 9
            E__TO_PC__PC_MAX = 10
            E__TO_PC__ITER_M_DOT_SU = 11
            E__TES_FULL__0 = 12

        var m_solver_mode: E_m_dot_solver_modes
        var mpc_csp_solver: Pointer[C_csp_solver]
        var m_pc_mode: Int32
        var m_cr_mode: Int32
        var m_q_dot_pc_target: Float64
        var m_defocus: Float64
        var m_t_ts_in: Float64
        var m_P_field_in: Float64
        var m_x_field_in: Float64
        var m_T_field_cold_guess: Float64
        var m_T_field_cold_calc: Float64
        var m_t_ts_calc: Float64
        var m_m_dot_pc_in: Float64

        def __init__(inout self, solver_mode: E_m_dot_solver_modes, pc_csp_solver: Pointer[C_csp_solver],
                     pc_mode: Int32, cr_mode: Int32,
                     q_dot_pc_target: Float64,
                     defocus: Float64, t_ts: Float64,
                     P_field_in: Float64, x_field_in: Float64,
                     T_field_cold_guess: Float64):
            self.m_solver_mode = solver_mode
            self.mpc_csp_solver = pc_csp_solver
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_defocus = defocus
            self.m_t_ts_in = t_ts
            self.m_P_field_in = P_field_in
            self.m_x_field_in = x_field_in
            self.m_T_field_cold_guess = T_field_cold_guess
            self.init_calc_member_vars()
        def init_calc_member_vars(inout self):

        def __call__(inout self, f_m_dot_tes: Float64, diff_target: inout Float64) -> Int32:
            # placeholder; actual implementation omitted due to length
            return 0

    struct C_MEQ__T_field_cold(C_monotonic_equation):
        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var mpc_csp_solver: Pointer[C_csp_solver]
        var m_q_dot_pc_target: Float64
        var m_pc_mode: Int32
        var m_cr_mode: Int32
        var m_defocus: Float64
        var m_t_ts_in: Float64
        var m_P_field_in: Float64
        var m_x_field_in: Float64
        var m_t_ts_calc: Float64

        def __init__(inout self, solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes, pc_csp_solver: Pointer[C_csp_solver],
                     q_dot_pc_target: Float64,
                     pc_mode: Int32, cr_mode: Int32,
                     defocus: Float64, t_ts: Float64,
                     P_field_in: Float64, x_field_in: Float64):
            self.m_solver_mode = solver_mode
            self.mpc_csp_solver = pc_csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_defocus = defocus
            self.m_t_ts_in = t_ts
            self.m_P_field_in = P_field_in
            self.m_x_field_in = x_field_in
            self.init_calc_member_vars()
        def init_calc_member_vars(inout self):

        def __call__(inout self, T_field_cold: Float64, diff_T_field_cold: inout Float64) -> Int32:
            return 0

    struct C_MEQ__timestep(C_monotonic_equation):
        enum E_timestep_target_modes:
            E_STEP_FROM_COMPONENT = 0
            E_STEP_Q_DOT_PC = 1
            E_STEP_FIXED = 2

        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var m_step_target_mode: E_timestep_target_modes
        var mpc_csp_solver: Pointer[C_csp_solver]
        var m_q_dot_pc_target: Float64
        var m_pc_mode: Int32
        var m_cr_mode: Int32
        var m_defocus: Float64

        def __init__(inout self, solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes, step_target_mode: E_timestep_target_modes,
                     pc_csp_solver: Pointer[C_csp_solver],
                     q_dot_pc_target: Float64,
                     pc_mode: Int32, cr_mode: Int32,
                     defocus: Float64):
            self.m_solver_mode = solver_mode
            self.m_step_target_mode = step_target_mode
            self.mpc_csp_solver = pc_csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_defocus = defocus
        def __call__(inout self, t_ts_guess: Float64, diff_t_ts_guess: inout Float64) -> Int32:
            return 0

    struct C_MEQ__defocus(C_monotonic_equation):
        enum E_defocus_target_modes:
            E_M_DOT_BAL = 0
            E_Q_DOT_PC = 1

        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var m_df_target_mode: E_defocus_target_modes
        var m_ts_target_mode: C_MEQ__timestep.E_timestep_target_modes
        var mpc_csp_solver: Pointer[C_csp_solver]
        var m_q_dot_pc_target: Float64
        var m_pc_mode: Int32
        var m_cr_mode: Int32
        var m_t_ts_initial: Float64

        def __init__(inout self, solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes,
                     df_target_mode: E_defocus_target_modes, ts_target_mode: C_MEQ__timestep.E_timestep_target_modes,
                     pc_csp_solver: Pointer[C_csp_solver],
                     q_dot_pc_target: Float64,
                     pc_mode: Int32, cr_mode: Int32,
                     t_ts_initial: Float64):
            self.m_solver_mode = solver_mode
            self.m_df_target_mode = df_target_mode
            self.m_ts_target_mode = ts_target_mode
            self.mpc_csp_solver = pc_csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_t_ts_initial = t_ts_initial
        def __call__(inout self, defocus: Float64, target: inout Float64) -> Int32:
            return 0
        def calc_meq_target(self) -> Float64:
            return 0.0

    # Constructor
    def __init__(inout self, weather: C_csp_weatherreader,
                 collector_receiver: Pointer[C_csp_collector_receiver],
                 power_cycle: Pointer[C_csp_power_cycle],
                 tes: Pointer[C_csp_tes],
                 tou: C_csp_tou,
                 system: S_csp_system_params,
                 pf_callback: Pointer[ (String, String, inout Void, Float64, Int32) -> Bool ] = Pointer[ (String, String, inout Void, Float64, Int32) -> Bool ](),
                 p_cmod_active: Pointer[Void] = Pointer[Void]()):
        self.mc_weather = weather
        self.mc_collector_receiver = collector_receiver
        self.mc_power_cycle = power_cycle
        self.mc_tes = tes
        self.mc_tou = tou
        self.ms_system_params = system
        self.reset_hierarchy_logic()
        self.m_T_htf_cold_des = Float64.nan
        self.m_P_cold_des = Float64.nan
        self.m_x_cold_des = Float64.nan
        self.m_q_dot_rec_des = Float64.nan
        self.m_A_aperture = Float64.nan
        self.m_cycle_W_dot_des = Float64.nan
        self.m_cycle_eta_des = Float64.nan
        self.m_cycle_q_dot_des = Float64.nan
        self.m_cycle_max_frac = Float64.nan
        self.m_cycle_cutoff_frac = Float64.nan
        self.m_cycle_sb_frac_des = Float64.nan
        self.m_cycle_T_htf_hot_des = Float64.nan
        self.m_cycle_P_hot_des = Float64.nan
        self.m_cycle_x_hot_des = Float64.nan
        self.m_m_dot_pc_des = Float64.nan
        self.m_m_dot_pc_min = Float64.nan
        self.m_m_dot_pc_max = Float64.nan
        self.m_m_dot_pc_max_startup = Float64.nan
        self.m_T_htf_pc_cold_est = Float64.nan
        self.m_is_cr_config_recirc = True
        self.mc_reported_outputs.construct(S_solver_output_info)
        self.m_i_reporting = -1
        self.m_report_time_start = Float64.nan
        self.m_report_time_end = Float64.nan
        self.m_report_step = Float64.nan
        self.m_step_tolerance = 10.0
        self.m_op_mode_tracking = List[Int32]()
        self.error_msg = ""
        self.mv_time_local.reserve(10)
        self.mpf_callback = pf_callback
        self.mp_cmod_active = p_cmod_active
        self.m_defocus = Float64.nan
        self.m_q_dot_pc_max = Float64.nan

    def send_callback(inout self, percent: Float64):
        if self.mpf_callback and self.mp_cmod_active:
            var out_type: Int32 = 1
            var out_msg: String = ""
            var prg_msg: String = "Simulation Progress"
            while self.mc_csp_messages.get_message(&out_type, &out_msg):
                self.mpf_callback(out_msg, prg_msg, self.mp_cmod_active, percent, out_type)
            out_msg = ""
            var cmod_ret: Bool = self.mpf_callback(out_msg, prg_msg, self.mp_cmod_active, percent, out_type)
            if not cmod_ret:
                var error_msg: String = "User terminated simulation..."
                var loc_msg: String = "C_csp_solver"
                throw C_csp_exception(error_msg, loc_msg, 1)

    def reset_hierarchy_logic(inout self):
        self.m_is_CR_SU__PC_OFF__TES_OFF__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SB__TES_OFF__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SU__TES_OFF__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_OFF__TES_CH__AUX_OFF_avail = True
        self.m_is_CR_OFF__PC_SU__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_DF__PC_MAX__TES_OFF__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_HI_SIDE = True
        self.m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_LO_SIDE = True
        self.m_is_CR_ON__PC_RM_LO__TES_OFF__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_HI_SIDE = True
        self.m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_LO_SIDE = True
        self.m_is_CR_ON__PC_TARGET__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_RM_LO__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_DF__PC_OFF__TES_FULL__AUX_OFF_avail = True
        self.m_is_CR_OFF__PC_SB__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_OFF__PC_MIN__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_OFF__PC_RM_LO__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SB__TES_CH__AUX_OFF_avail = True
        self.m_is_CR_SU__PC_MIN__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_SU__PC_SB__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SB__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_OFF__PC_TARGET__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_SU__PC_TARGET__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_RM_HI__TES_FULL__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_MIN__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_SU__PC_RM_LO__TES_EMPTY__AUX_OFF_avail = True
        self.m_is_CR_DF__PC_MAX__TES_FULL__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SB__TES_FULL__AUX_OFF_avail = True
        self.m_is_CR_SU__PC_SU__TES_DC__AUX_OFF_avail = True
        self.m_is_CR_ON__PC_SU__TES_CH__AUX_OFF_avail = True
        self.m_is_CR_DF__PC_SU__TES_FULL__AUX_OFF_avail = True
        self.m_is_CR_DF__PC_SU__TES_OFF__AUX_OFF_avail = True

    def turn_off_plant(inout self):
        self.m_is_CR_SU__PC_OFF__TES_OFF__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_SB__TES_OFF__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_SU__TES_OFF__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_OFF__TES_CH__AUX_OFF_avail = False
        self.m_is_CR_OFF__PC_SU__TES_DC__AUX_OFF_avail = False
        self.m_is_CR_DF__PC_MAX__TES_OFF__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_HI_SIDE = False
        self.m_is_CR_ON__PC_RM_HI__TES_OFF__AUX_OFF_avail_LO_SIDE = False
        self.m_is_CR_ON__PC_RM_LO__TES_OFF__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_HI_SIDE = False
        self.m_is_CR_ON__PC_TARGET__TES_CH__AUX_OFF_avail_LO_SIDE = False
        self.m_is_CR_ON__PC_TARGET__TES_DC__AUX_OFF_avail = False
        self.m_is_CR_ON__PC_RM_LO__TES_EMPTY__AUX_OFF_avail = False
        self.m_is_CR_DF__PC_OFF__TES_FULL__AUX_OFF_avail = False
        self.m_is_CR_OFF__PC_SB__TES_DC