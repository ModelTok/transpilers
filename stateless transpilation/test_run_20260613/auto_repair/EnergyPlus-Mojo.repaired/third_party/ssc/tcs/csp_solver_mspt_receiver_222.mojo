/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from csp_solver_util import util
from htf_props import HTFProperties, ambient_air, field_htfProps, tube_material
from ngcc_powerblock import ngcc_power_cycle
from csp_solver_core import C_csp_collector_receiver, C_csp_messages, C_csp_solver_htf_1state, C_csp_solver_sim_info, CSP
from csp_solver_pt_receiver import C_pt_receiver
from Ambient import Ambient
from definitions import error_msg, m_eta_pump, m_night_recirc, m_h_tower, m_q_rec_des, m_f_rec_min, m_rec_qf_delay, m_rec_su_delay, m_T_htf_hot_des, m_T_htf_cold_des, m_m_dot_htf_max_frac, m_m_dot_htf_des, m_epsilon, ms_outputs, m_mode, m_mode_prev, m_q_dot_inc_min, outputs
from Math import *

struct s_steady_state_soln:
    var mode: C_csp_collector_receiver.E_csp_cr_modes
    var rec_is_off: Bool
    var itermode: Int
    var hour: Float64
    var T_amb: Float64
    var T_dp: Float64
    var v_wind_10: Float64
    var p_amb: Float64
    var dni: Float64
    var field_eff: Float64
    var od_control: Float64
    var m_dot_salt: Float64
    var m_dot_salt_tot: Float64
    var T_salt_cold_in: Float64
    var T_salt_hot: Float64
    var T_salt_hot_rec: Float64
    var T_salt_props: Float64
    var u_salt: Float64
    var f: Float64
    var Q_inc_sum: Float64
    var Q_conv_sum: Float64
    var Q_rad_sum: Float64
    var Q_abs_sum: Float64
    var Q_dot_piping_loss: Float64
    var Q_inc_min: Float64
    var Q_thermal: Float64
    var eta_therm: Float64
    var T_s: util.matrix_t[Float64]
    var T_panel_out: util.matrix_t[Float64]
    var T_panel_in: util.matrix_t[Float64]
    var T_panel_ave: util.matrix_t[Float64]
    var q_dot_inc: util.matrix_t[Float64]
    var q_dot_conv: util.matrix_t[Float64]
    var q_dot_rad: util.matrix_t[Float64]
    var q_dot_loss: util.matrix_t[Float64]
    var q_dot_abs: util.matrix_t[Float64]

    def __init__(inout self):
        self.clear()

    def clear(inout self):
        self.hour = Float64.NaN
        self.T_amb = Float64.NaN
        self.T_dp = Float64.NaN
        self.v_wind_10 = Float64.NaN
        self.p_amb = Float64.NaN
        self.dni = Float64.NaN
        self.od_control = Float64.NaN
        self.field_eff = Float64.NaN
        self.m_dot_salt = Float64.NaN
        self.m_dot_salt_tot = Float64.NaN
        self.T_salt_cold_in = Float64.NaN
        self.T_salt_hot = Float64.NaN
        self.T_salt_hot_rec = Float64.NaN
        self.T_salt_props = Float64.NaN
        self.u_salt = Float64.NaN
        self.f = Float64.NaN
        self.Q_inc_sum = Float64.NaN
        self.Q_conv_sum = Float64.NaN
        self.Q_rad_sum = Float64.NaN
        self.Q_abs_sum = Float64.NaN
        self.Q_dot_piping_loss = Float64.NaN
        self.Q_inc_min = Float64.NaN
        self.Q_thermal = Float64.NaN
        self.eta_therm = Float64.NaN
        self.mode = C_csp_collector_receiver.E_csp_cr_modes.OFF
        self.itermode = -1
        self.rec_is_off = True

class C_mspt_receiver_222(C_pt_receiver):
    var cycle_calcs: ngcc_power_cycle
    var m_id_tube: Float64
    var m_A_tube: Float64
    var m_n_t: Int
    var m_A_rec_proj: Float64
    var m_A_node: Float64
    var m_Q_dot_piping_loss: Float64
    var m_piping_loss_coeff: Float64
    var m_itermode: Int
    var m_od_control: Float64
    var m_eta_field_iter_prev: Float64
    var m_tol_od: Float64
    var m_E_su: Float64
    var m_E_su_prev: Float64
    var m_t_su: Float64
    var m_t_su_prev: Float64
    var m_flow_pattern: util.matrix_t[Int]
    var m_n_lines: Int
    var m_flux_in: util.matrix_t[Float64]
    var m_q_dot_inc: util.matrix_t[Float64]
    var m_T_s: util.matrix_t[Float64]
    var m_T_panel_out: util.matrix_t[Float64]
    var m_T_panel_in: util.matrix_t[Float64]
    var m_T_panel_ave: util.matrix_t[Float64]
    var m_q_dot_conv: util.matrix_t[Float64]
    var m_q_dot_rad: util.matrix_t[Float64]
    var m_q_dot_loss: util.matrix_t[Float64]
    var m_q_dot_abs: util.matrix_t[Float64]
    var m_m_mixed: Float64
    var m_LoverD: Float64
    var m_RelRough: Float64
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var m_P_amb_low: Float64
    var m_P_amb_high: Float64
    var m_q_iscc_max: Float64
    var m_ncall: Int
    var m_Rtot_riser: Float64
    var m_Rtot_downc: Float64
    var m_mflow_soln_prev: s_steady_state_soln
    var m_mflow_soln_csky_prev: s_steady_state_soln
    var csp_messages: C_csp_messages
    var m_n_panels: Int
    var m_d_rec: Float64
    var m_h_rec: Float64
    var m_od_tube: Float64
    var m_th_tube: Float64
    var m_hl_ffact: Float64
    var m_A_sf: Float64
    var m_pipe_loss_per_m: Float64
    var m_pipe_length_add: Float64
    var m_pipe_length_mult: Float64
    var m_m_dot_htf_max: Float64
    var m_n_flux_x: Int
    var m_n_flux_y: Int
    var m_T_salt_hot_target: Float64
    var m_hel_stow_deploy: Float64
    var m_field_fl: Int
    var m_field_fl_props: util.matrix_t[Float64]
    var m_mat_tube: Int
    var m_flow_type: Int
    var m_crossover_shift: Int
    var m_is_iscc: Bool
    var m_cycle_config: Int
    var m_csky_frac: Float64
    var outputs: S_outputs

    def __init__(inout self):
        self.m_n_panels = -1
        self.m_d_rec = Float64.NaN
        self.m_h_rec = Float64.NaN
        self.m_od_tube = Float64.NaN
        self.m_th_tube = Float64.NaN
        self.m_hl_ffact = Float64.NaN
        self.m_A_sf = Float64.NaN
        self.m_pipe_loss_per_m = Float64.NaN
        self.m_pipe_length_add = Float64.NaN
        self.m_pipe_length_mult = Float64.NaN
        self.m_id_tube = Float64.NaN
        self.m_A_tube = Float64.NaN
        self.m_n_t = -1
        self.m_n_flux_x = 0
        self.m_n_flux_y = 0
        self.m_T_salt_hot_target = Float64.NaN
        self.m_eta_pump = Float64.NaN
        self.m_night_recirc = -1
        self.m_hel_stow_deploy = Float64.NaN
        self.m_field_fl = -1
        self.m_mat_tube = -1
        self.m_flow_type = -1
        self.m_crossover_shift = 0
        self.m_A_rec_proj = Float64.NaN
        self.m_A_node = Float64.NaN
        self.m_Q_dot_piping_loss = Float64.NaN
        self.m_piping_loss_coeff = Float64.NaN
        self.m_m_dot_htf_max = Float64.NaN
        self.m_itermode = -1
        self.m_od_control = Float64.NaN
        self.m_eta_field_iter_prev = Float64.NaN
        self.m_tol_od = Float64.NaN
        self.m_q_dot_inc_min = Float64.NaN
        self.m_mode = C_csp_collector_receiver.E_csp_cr_modes.OFF
        self.m_mode_prev = C_csp_collector_receiver.E_csp_cr_modes.OFF
        self.m_E_su = Float64.NaN
        self.m_E_su_prev = Float64.NaN
        self.m_t_su = Float64.NaN
        self.m_t_su_prev = Float64.NaN
        self.m_flow_pattern = util.matrix_t[Int]()
        self.m_n_lines = -1
        self.m_m_mixed = Float64.NaN
        self.m_LoverD = Float64.NaN
        self.m_RelRough = Float64.NaN
        self.m_is_iscc = False
        self.m_cycle_config = 1
        self.m_T_amb_low = Float64.NaN
        self.m_T_amb_high = Float64.NaN
        self.m_P_amb_low = Float64.NaN
        self.m_P_amb_high = Float64.NaN
        self.m_q_iscc_max = Float64.NaN
        self.m_csky_frac = Float64.NaN
        self.m_ncall = -1

    def __del__(self): pass

    def init(inout self):
        ambient_air.SetFluid(ambient_air.Air)
        if self.m_field_fl != HTFProperties.User_defined and self.m_field_fl < HTFProperties.End_Library_Fluids:
            if not field_htfProps.SetFluid(self.m_field_fl):
                raise C_csp_exception("Receiver HTF code is not recognized", "MSPT receiver")
        elif self.m_field_fl == HTFProperties.User_defined:
            var n_rows = self.m_field_fl_props.nrows()
            var n_cols = self.m_field_fl_props.ncols()
            if n_rows > 2 and n_cols == 7:
                if not field_htfProps.SetUserDefinedFluid(self.m_field_fl_props):
                    error_msg = util.format(field_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(error_msg, "MSPT receiver")
            else:
                error_msg = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(error_msg, "MSPT receiver")
        else:
            raise C_csp_exception("Receiver HTF code is not recognized", "MSPT receiver")
        if self.m_mat_tube == HTFProperties.Stainless_AISI316 or self.m_mat_tube == HTFProperties.T91_Steel or self.m_mat_tube == HTFProperties.N06230 or self.m_mat_tube == HTFProperties.N07740:
            if not tube_material.SetFluid(self.m_mat_tube):
                raise C_csp_exception("Tube material code not recognized", "MSPT receiver")
        elif self.m_mat_tube == HTFProperties.User_defined:
            raise C_csp_exception("Receiver material currently does not accept user defined properties", "MSPT receiver")
        else:
            error_msg = util.format("Receiver material code, %d, is not recognized", self.m_mat_tube)
            raise C_csp_exception(error_msg, "MSPT receiver")
        self.m_od_tube /= 1.0E3
        self.m_th_tube /= 1.0E3
        self.m_T_htf_hot_des += 273.15
        self.m_T_htf_cold_des += 273.15
        self.m_q_rec_des *= 1.0E6
        self.m_id_tube = self.m_od_tube - 2.0 * self.m_th_tube
        self.m_A_tube = CSP.pi * self.m_od_tube / 2.0 * self.m_h_rec
        self.m_n_t = (CSP.pi * self.m_d_rec / (self.m_od_tube * self.m_n_panels))
        var n_tubes = self.m_n_t * self.m_n_panels
        self.m_A_rec_proj = self.m_od_tube * self.m_h_rec * n_tubes
        self.m_A_node = CSP.pi * self.m_d_rec / self.m_n_panels * self.m_h_rec
        self.m_mode = C_csp_collector_receiver.OFF
        self.m_itermode = 1
        self.m_od_control = 1.0
        self.m_tol_od = 0.001
        var c_htf_des = field_htfProps.Cp((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0) * 1000.0
        self.m_m_dot_htf_des = self.m_q_rec_des / (c_htf_des * (self.m_T_htf_hot_des - self.m_T_htf_cold_des))
        var eta_therm_des = 0.9
        self.m_q_dot_inc_min = self.m_q_rec_des * self.m_f_rec_min / eta_therm_des
        if self.m_m_dot_htf_max_frac != self.m_m_dot_htf_max_frac:
            if self.m_m_dot_htf_max != self.m_m_dot_htf_max:
                raise C_csp_exception("maximum rec htf mass flow rate not defined", "MSPT receiver")
            self.m_m_dot_htf_max /= 3600.0
        self.m_m_dot_htf_max = self.m_m_dot_htf_max_frac * self.m_m_dot_htf_des
        self.m_mode_prev = self.m_mode
        self.m_E_su_prev = self.m_q_rec_des * self.m_rec_qf_delay
        self.m_t_su_prev = self.m_rec_su_delay
        self.m_eta_field_iter_prev = 1.0
        self.m_T_salt_hot_target += 273.15
        if self.m_pipe_loss_per_m > 0.0 and self.m_pipe_length_mult > 0.0:
            self.m_Q_dot_piping_loss = self.m_pipe_loss_per_m * (self.m_h_tower * self.m_pipe_length_mult + self.m_pipe_length_add)
        else:
            self.m_Q_dot_piping_loss = 0.0
        var flow_msg: String
        if not CSP.flow_patterns(self.m_n_panels, self.m_crossover_shift, self.m_flow_type, self.m_n_lines, self.m_flow_pattern, &flow_msg):
            raise C_csp_exception(flow_msg, "MSPT receiver initialization")
        self.m_q_dot_inc.resize(self.m_n_panels)
        self.m_q_dot_inc.fill(0.0)
        self.m_T_s.resize(self.m_n_panels)
        self.m_T_s.fill(0.0)
        self.m_T_panel_out.resize(self.m_n_panels)
        self.m_T_panel_out.fill(0.0)
        self.m_T_panel_in.resize(self.m_n_panels)
        self.m_T_panel_in.fill(0.0)
        self.m_T_panel_ave.resize(self.m_n_panels)
        self.m_T_panel_ave.fill(0.0)
        self.m_q_dot_conv.resize(self.m_n_panels)
        self.m_q_dot_conv.fill(0.0)
        self.m_q_dot_rad.resize(self.m_n_panels)
        self.m_q_dot_rad.fill(0.0)
        self.m_q_dot_loss.resize(self.m_n_panels)
        self.m_q_dot_loss.fill(0.0)
        self.m_q_dot_abs.resize(self.m_n_panels)
        self.m_q_dot_abs.fill(0.0)
        self.m_m_mixed = 3.2
        self.m_LoverD = self.m_h_rec / self.m_id_tube
        self.m_RelRough = (4.5e-5) / self.m_id_tube
        if self.m_is_iscc:
            self.cycle_calcs.set_cycle_config(self.m_cycle_config)
            self.cycle_calcs.get_table_range(self.m_T_amb_low, self.m_T_amb_high, self.m_P_amb_low, self.m_P_amb_high)
        self.m_ncall = -1
        self.m_Rtot_riser = 0.0
        self.m_Rtot_downc = 0.0
        return

    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: C_mspt_receiver_222.S_inputs, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var field_eff = inputs.m_field_eff
        var flux_map_input = inputs.m_flux_map_input
        var input_operation_mode = inputs.m_input_operation_mode
        if input_operation_mode < C_csp_collector_receiver.OFF or input_operation_mode > C_csp_collector_receiver.STEADY_STATE:
            error_msg = util.format("Input operation mode must be either [0,1,2], but value is %d", input_operation_mode)
            raise C_csp_exception(error_msg, "MSPT receiver timestep performance call")
        var step = sim_info.ms_ts.m_step
        var time = sim_info.ms_ts.m_time
        var T_salt_cold_in = htf_state_in.m_temp
        T_salt_cold_in += 273.15
        var P_amb = weather.m_pres * 100.0
        var hour = time / 3600.0
        var T_dp = weather.m_tdew + 273.15
        var T_amb = weather.m_tdry + 273.15
        var zenith = weather.m_solzen
        var azimuth = weather.m_solazi
        var v_wind_10 = weather.m_wspd
        var I_bn = weather.m_beam
        var n_flux_y = flux_map_input.nrows()
        if n_flux_y > 1:
            error_msg = util.format("The Molten Salt External Receiver (Type222) model does not currently support 2-dimensional flux maps. The flux profile in the vertical dimension will be averaged. NY=%d", n_flux_y)
            self.csp_messages.add_message(C_csp_messages.WARNING, error_msg)
        var n_flux_x = flux_map_input.ncols()
        self.m_flux_in.resize(n_flux_x)
        var T_sky = CSP.skytemp(T_amb, T_dp, hour)
        self.m_mode = C_csp_collector_receiver.OFF
        self.m_E_su = Float64.NaN
        self.m_t_su = Float64.NaN
        self.m_itermode = 1
        var v_wind = log((self.m_h_tower + self.m_h_rec / 2.0) / 0.003) / log(10.0 / 0.003) * v_wind_10
        var c_p_coolant: Float64
        var rho_coolant: Float64
        var f: Float64
        var u_coolant: Float64
        var q_conv_sum: Float64
        var q_rad_sum: Float64
        var q_dot_inc_sum: Float64
        var q_dot_piping_loss: Float64
        var q_dot_inc_min_panel: Float64
        c_p_coolant = Float64.NaN
        rho_coolant = Float64.NaN
        f = Float64.NaN
        u_coolant = Float64.NaN
        q_conv_sum = Float64.NaN
        q_rad_sum = Float64.NaN
        q_dot_inc_sum = Float64.NaN
        q_dot_piping_loss = Float64.NaN
        q_dot_inc_min_panel = Float64.NaN
        var eta_therm: Float64
        var m_dot_salt_tot: Float64
        var T_salt_hot: Float64
        var m_dot_salt_tot_ss: Float64
        var T_salt_hot_rec: Float64
        eta_therm = Float64.NaN
        m_dot_salt_tot = Float64.NaN
        T_salt_hot = Float64.NaN
        m_dot_salt_tot_ss = Float64.NaN
        T_salt_hot_rec = Float64.NaN
        var clearsky: Float64 = Float64.NaN
        var rec_is_off: Bool = False
        var rec_is_defocusing: Bool = False
        var field_eff_adj: Float64 = 0.0
        var q_thermal_ss: Float64 = 0.0
        var f_rec_timestep: Float64 = 1.0
        if input_operation_mode == C_csp_collector_receiver.OFF:
            rec_is_off = True
        if zenith > (90.0 - self.m_hel_stow_deploy) or I_bn <= 1.0E-6 or (zenith == 0.0 and azimuth == 180.0):
            if self.m_night_recirc == 1:
                I_bn = 0.0
            else:
                self.m_mode = C_csp_collector_receiver.OFF
                rec_is_off = True
        var T_coolant_prop = (self.m_T_salt_hot_target + T_salt_cold_in) / 2.0
        c_p_coolant = field_htfProps.Cp(T_coolant_prop) * 1000.0
        var m_dot_htf_max = self.m_m_dot_htf_max
        if self.m_is_iscc:
            if self.m_ncall == 0:
                var T_amb_C = fmax(self.m_P_amb_low, fmin(self.m_T_amb_high, T_amb - 273.15))
                var P_amb_bar = fmax(self.m_P_amb_low, fmin(self.m_P_amb_high, P_amb / 1.0E5))
                self.m_q_iscc_max = self.cycle_calcs.get_ngcc_data(0.0, T_amb_C, P_amb_bar, ngcc_power_cycle.E_solar_heat_max) * 1.0E6
            var m_dot_iscc_max = self.m_q_iscc_max / (c_p_coolant * (self.m_T_salt_hot_target - T_salt_cold_in))
            m_dot_htf_max = fmin(self.m_m_dot_htf_max, m_dot_iscc_max)
        if field_eff < self.m_eta_field_iter_prev and self.m_od_control < 1.0:
            self.m_od_control = fmin(self.m_od_control + (1.0 - field_eff / self.m_eta_field_iter_prev), 1.0)
        var soln: s_steady_state_soln
        var soln_actual: s_steady_state_soln
        var soln_clearsky: s_steady_state_soln
        soln.hour = time / 3600.0
        soln.T_amb = weather.m_tdry + 273.15
        soln.T_dp = weather.m_tdew + 273.15
        soln.v_wind_10 = weather.m_wspd
        soln.p_amb = weather.m_pres * 100.0
        soln.dni = I_bn
        soln.field_eff = field_eff
        soln.T_salt_cold_in = T_salt_cold_in
        soln.od_control = self.m_od_control
        soln.mode = input_operation_mode
        soln.itermode = self.m_itermode
        soln.rec_is_off = rec_is_off
        clearsky = self.get_clearsky(weather, hour)
        var clearsky_adj = fmax(clearsky, weather.m_beam)
        if rec_is_off:
            soln.q_dot_inc.resize_fill(self.m_n_panels, 0.0)
        else:
            if self.m_csky_frac <= 0.9999 or abs(I_bn - clearsky_adj) < 0.001:
                soln_actual = soln
                soln_actual.dni = I_bn
                if self.use_previous_solution(soln_actual, self.m_mflow_soln_prev):
                    soln_actual = self.m_mflow_soln_prev
                else:
                    self.solve_for_mass_flow_and_defocus(soln_actual, m_dot_htf_max, flux_map_input)
                self.m_mflow_soln_prev = soln_actual
            if self.m_csky_frac >= 0.0001:
                if abs(I_bn - clearsky_adj) < 0.001:
                    soln_clearsky = soln_actual
                else:
                    soln_clearsky = soln
                    soln_clearsky.dni = clearsky_adj
                    if self.use_previous_solution(soln_clearsky, self.m_mflow_soln_csky_prev):
                        soln_clearsky = self.m_mflow_soln_csky_prev
                    else:
                        self.solve_for_mass_flow_and_defocus(soln_clearsky, m_dot_htf_max, flux_map_input)
                    self.m_mflow_soln_csky_prev = soln_clearsky
            if abs(I_bn - clearsky_adj) < 0.001 or self.m_csky_frac < 0.0001:
                soln = soln_actual
            elif soln_clearsky.rec_is_off:
                soln.rec_is_off = True
                soln.q_dot_inc = soln_clearsky.q_dot_inc
            elif self.m_csky_frac > 0.9999:
                soln.m_dot_salt = soln_clearsky.m_dot_salt
                soln.rec_is_off = soln_clearsky.rec_is_off
                soln.od_control = soln_clearsky.od_control
                soln.q_dot_inc = self.calculate_flux_profiles(I_bn, field_eff, soln_clearsky.od_control, flux_map_input)
                self.calculate_steady_state_soln(soln, 0.00025)
            else:
                if soln_actual.rec_is_off:
                    soln_actual.m_dot_salt = self.m_f_rec_min * self.m_m_dot_htf_max
                    soln_actual.od_control = 1.0
                soln.rec_is_off = False
                soln.m_dot_salt = (1.0 - self.m_csky_frac) * soln_actual.m_dot_salt + self.m_csky_frac * soln_clearsky.m_dot_salt
                if soln_clearsky.od_control >= 0.9999:
                    soln.od_control = soln_clearsky.od_control
                    soln.q_dot_inc = soln_actual.q_dot_inc
                    self.calculate_steady_state_soln(soln, 0.00025)
                else:
                    soln.od_control = (1.0 - self.m_csky_frac) * soln_actual.od_control + self.m_csky_frac * soln_clearsky.od_control
                    self.solve_for_defocus_given_flow(soln, flux_map_input)
        rec_is_off = soln.rec_is_off
        self.m_mode = soln.mode
        self.m_itermode = soln.itermode
        self.m_od_control = soln.od_control
        field_eff_adj = field_eff * soln.od_control
        m_dot_salt_tot = soln.m_dot_salt_tot
        T_salt_hot = soln.T_salt_hot
        T_salt_hot_rec = soln.T_salt_hot_rec
        eta_therm = soln.eta_therm
        u_coolant = soln.u_salt
        f = soln.f
        T_coolant_prop = (T_salt_hot + T_salt_cold_in) / 2.0
        c_p_coolant = field_htfProps.Cp(T_coolant_prop) * 1000.0
        rho_coolant = field_htfProps.dens(T_coolant_prop, 1.0)
        q_conv_sum = soln.Q_conv_sum
        q_rad_sum = soln.Q_rad_sum
        q_dot_piping_loss = soln.Q_dot_piping_loss
        q_dot_inc_sum = soln.Q_inc_sum
        q_dot_inc_min_panel = soln.Q_inc_min
        self.m_T_s = soln.T_s
        self.m_T_panel_in = soln.T_panel_in
        self.m_T_panel_out = soln.T_panel_out
        self.m_T_panel_ave = soln.T_panel_ave
        self.m_q_dot_conv = soln.q_dot_conv
        self.m_q_dot_rad = soln.q_dot_rad
        self.m_q_dot_loss = soln.q_dot_conv + soln.q_dot_rad
        self.m_q_dot_abs = soln.q_dot_abs
        self.m_q_dot_inc = soln.q_dot_inc
        if soln.Q_inc_sum != soln.Q_inc_sum:
            q_dot_inc_sum = 0.0
            q_dot_inc_min_panel = self.m_q_dot_inc.at(0)
            for i in range(self.m_n_panels):
                q_dot_inc_sum += self.m_q_dot_inc.at(i)
                q_dot_inc_min_panel = fmin(q_dot_inc_min_panel, self.m_q_dot_inc.at(i))
        var q_thermal_steadystate = soln.Q_thermal
        var q_thermal_csky: Float64 = 0.0
        if self.m_csky_frac > 0.0001:
            q_thermal_csky = soln_clearsky.Q_thermal
        var DELTAP: Float64
        var Pres_D: Float64
        var W_dot_pump: Float64
        var q_thermal: Float64
        var q_startup: Float64
        DELTAP = Float64.NaN
        Pres_D = Float64.NaN
        W_dot_pump = Float64.NaN
        q_thermal = Float64.NaN
        q_startup = Float64.NaN
        q_startup = 0.0
        var time_required_su = step / 3600.0
        if not rec_is_off:
            m_dot_salt_tot_ss = m_dot_salt_tot
            if input_operation_mode == C_csp_collector_receiver.STARTUP:
                var time_require_su_energy = self.m_E_su_prev / (m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in))
                var time_require_su_ramping = self.m_t_su_prev
                var time_required_max = fmax(time_require_su_energy, time_require_su_ramping)
                var time_step_hrs = step / 3600.0
                if time_required_max > time_step_hrs:
                    time_required_su = time_step_hrs
                    self.m_mode = C_csp_collector_receiver.STARTUP
                    q_startup = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0
                else:
                    time_required_su = time_required_max
                    self.m_mode = C_csp_collector_receiver.ON
                    var q_startup_energy_req = self.m_E_su_prev
                    var q_startup_ramping_req = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * self.m_t_su_prev
                    q_startup = fmax(q_startup_energy_req, q_startup_ramping_req)
                self.m_E_su = fmax(0.0, self.m_E_su_prev - m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0)
                self.m_t_su = fmax(0.0, self.m_t_su_prev - step / 3600.0)
                rec_is_off = True
            elif input_operation_mode == C_csp_collector_receiver.ON:
                if self.m_E_su_prev > 0.0 or self.m_t_su_prev > 0.0:
                    self.m_E_su = fmax(0.0, self.m_E_su_prev - m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0)
                    self.m_t_su = fmax(0.0, self.m_t_su_prev - step / 3600.0)
                    if self.m_E_su + self.m_t_su > 0.0:
                        self.m_mode = C_csp_collector_receiver.STARTUP
                        q_startup = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0
                        rec_is_off = True
                        f_rec_timestep = 0.0
                    else:
                        self.m_mode = C_csp_collector_receiver.ON
                        var q_startup_energy_req = self.m_E_su_prev
                        var q_startup_ramping_req = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * self.m_t_su
                        q_startup = fmax(q_startup_energy_req, q_startup_ramping_req)
                        m_dot_salt_tot = fmin((1.0 - self.m_t_su_prev / (step / 3600.0)) * m_dot_salt_tot, m_dot_salt_tot - self.m_E_su_prev / ((step / 3600.0) * c_p_coolant * (T_salt_hot - T_salt_cold_in)))
                        f_rec_timestep = fmax(0.0, fmin(1.0 - self.m_t_su_prev / (step / 3600.0), 1.0 - self.m_E_su_prev / (m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in))))
                else:
                    self.m_E_su = self.m_E_su_prev
                    self.m_t_su = self.m_t_su_prev
                    self.m_mode = C_csp_collector_receiver.ON
                    q_startup = 0.0
                    q_thermal = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                    if q_dot_inc_sum < self.m_q_dot_inc_min:
                        self.m_mode = C_csp_collector_receiver.OFF
                        W_dot_pump = 0.0
                        DELTAP = 0.0
                        Pres_D = 0.0
                        u_coolant = 0.0
            elif input_operation_mode == C_csp_collector_receiver.STEADY_STATE:
                self.m_mode = C_csp_collector_receiver.STEADY_STATE
                f_rec_timestep = 1.0
            self.calc_pump_performance(rho_coolant, m_dot_salt_tot, f, Pres_D, W_dot_pump)
            q_thermal = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in)
            q_thermal_ss = m_dot_salt_tot_ss * c_p_coolant * (T_salt_hot - T_salt_cold_in)
            if q_dot_inc_sum < self.m_q_dot_inc_min:
                if self.m_mode != C_csp_collector_receiver.STEADY_STATE or self.m_mode_prev == C_csp_collector_receiver.ON:
                    rec_is_off = True
        else:
            self.m_mode = C_csp_collector_receiver.OFF
            W_dot_pump = 0.0
            DELTAP = 0.0
            Pres_D = 0.0
            u_coolant = 0.0
        if rec_is_off:
            m_dot_salt_tot = 0.0
            eta_therm = 0.0
            q_conv_sum = 0.0
            q_rad_sum = 0.0
            self.m_T_s.fill(0.0)
            q_thermal = 0.0
            T_salt_hot = self.m_T_htf_cold_des
            q_dot_inc_sum = 0.0
            m_dot_salt_tot_ss = 0.0
            f_rec_timestep = 0.0
            q_thermal_ss = 0.0
            q_thermal_csky = 0.0
            q_thermal_steadystate = 0.0
            self.m_od_control = 1.0
        self.outputs.m_m_dot_salt_tot = m_dot_salt_tot * 3600.0
        self.outputs.m_eta_therm = eta_therm
        self.outputs.m_W_dot_pump = W_dot_pump / 1.0E6
        self.outputs.m_q_conv_sum = q_conv_sum / 1.0E6
        self.outputs.m_q_rad_sum = q_rad_sum / 1.0E6
        self.outputs.m_Q_thermal = q_thermal / 1.0E6
        self.outputs.m_T_salt_hot = T_salt_hot - 273.15
        self.outputs.m_field_eff_adj = field_eff_adj
        self.outputs.m_component_defocus = self.m_od_control
        self.outputs.m_q_dot_rec_inc = q_dot_inc_sum / 1.0E6
        self.outputs.m_q_startup = q_startup / 1.0E6
        self.outputs.m_dP_receiver = DELTAP * self.m_n_panels / self.m_n_lines / 1.0E5
        self.outputs.m_dP_total = Pres_D * 10.0
        self.outputs.m_vel_htf = u_coolant
        self.outputs.m_T_salt_cold = T_salt_cold_in - 273.15
        self.outputs.m_m_dot_ss = m_dot_salt_tot_ss * 3600.0
        self.outputs.m_q_dot_ss = q_thermal_ss / 1.0E6
        self.outputs.m_f_timestep = f_rec_timestep
        self.outputs.m_time_required_su = time_required_su * 3600.0
        if q_thermal > 0.0:
            self.outputs.m_q_dot_piping_loss = q_dot_piping_loss / 1.0E6
        else:
            self.outputs.m_q_dot_piping_loss = 0.0
        self.outputs.m_q_heattrace = 0.0
        self.outputs.m_clearsky = clearsky
        self.outputs.m_Q_thermal_csky_ss = q_thermal_csky / 1.0E6
        self.outputs.m_Q_thermal_ss = q_thermal_steadystate / 1.0E6
        ms_outputs = self.outputs
        self.m_eta_field_iter_prev = field_eff

    def off(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, sim_info: C_csp_solver_sim_info):
        self.m_mode = C_csp_collector_receiver.OFF
        self.outputs.m_m_dot_salt_tot = 0.0
        self.outputs.m_eta_therm = 0.0
        self.outputs.m_W_dot_pump = 0.0
        self.outputs.m_q_conv_sum = 0.0
        self.outputs.m_q_rad_sum = 0.0
        self.outputs.m_Q_thermal = 0.0
        self.outputs.m_T_salt_hot = 0.0
        self.outputs.m_field_eff_adj = 0.0
        self.outputs.m_component_defocus = 1.0
        self.outputs.m_q_dot_rec_inc = 0.0
        self.outputs.m_q_startup = 0.0
        self.outputs.m_dP_receiver = 0.0
        self.outputs.m_dP_total = 0.0
        self.outputs.m_vel_htf = 0.0
        self.outputs.m_T_salt_cold = 0.0
        self.outputs.m_m_dot_ss = 0.0
        self.outputs.m_q_dot_ss = 0.0
        self.outputs.m_f_timestep = 0.0
        self.outputs.m_time_required_su = sim_info.ms_ts.m_step
        self.outputs.m_q_dot_piping_loss = 0.0
        self.outputs.m_q_heattrace = 0.0
        self.outputs.m_clearsky = self.get_clearsky(weather, sim_info.ms_ts.m_time / 3600.0)
        self.outputs.m_Q_thermal_csky_ss = 0.0
        self.outputs.m_Q_thermal_ss = 0.0
        ms_outputs = self.outputs
        return

    def converged(inout self):
        if self.m_mode == C_csp_collector_receiver.STEADY_STATE:
            raise C_csp_exception("Receiver should only be run at STEADY STATE mode for estimating output. It must be run at a different mode before exiting a timestep",
                "MSPT receiver converged method")
        if self.m_mode == C_csp_collector_receiver.OFF:
            self.m_E_su = self.m_q_rec_des * self.m_rec_qf_delay
            self.m_t_su = self.m_rec_su_delay
        self.m_mode_prev = self.m_mode
        self.m_E_su_prev = self.m_E_su
        self.m_t_su_prev = self.m_t_su
        self.m_itermode = 1
        self.m_od_control = 1.0
        self.m_eta_field_iter_prev = 1.0
        self.m_ncall = -1
        ms_outputs = self.outputs

    def use_previous_solution(self, soln: s_steady_state_soln, soln_prev: s_steady_state_soln) -> Bool:
        if not soln_prev.rec_is_off and \
            soln.dni == soln_prev.dni and \
            soln.T_salt_cold_in == soln_prev.T_salt_cold_in and \
            soln.field_eff == soln_prev.field_eff and \
            soln.od_control == soln_prev.od_control and \
            soln.T_amb == soln_prev.T_amb and \
            soln.T_dp == soln_prev.T_dp and \
            soln.v_wind_10 == soln_prev.v_wind_10 and \
            soln.p_amb == soln_prev.p_amb:
            return True
        else:
            return False

    def calculate_flux_profiles(self, dni: Float64, field_eff: Float64, od_control: Float64, flux_map_input: util.matrix_t[Float64]) -> util.matrix_t[Float64]:
        var q_dot_inc: util.matrix_t[Float64]
        var flux: util.matrix_t[Float64]
        q_dot_inc.resize_fill(self.m_n_panels, 0.0)
        var field_eff_adj = field_eff * od_control
        var n_flux_y = flux_map_input.nrows()
        var n_flux_x = flux_map_input.ncols()
        flux.resize_fill(n_flux_x, 0.0)
        if dni > 1.0:
            for j in range(n_flux_x):
                flux.at(j) = 0.0
                for i in range(n_flux_y):
                    flux.at(j) += flux_map_input(i, j) * dni * field_eff_adj * self.m_A_sf / 1000.0 / (CSP.pi * self.m_h_rec * self.m_d_rec / n_flux_x)
        else:
            flux.fill(0.0)
        var n_flux_x_d = self.m_n_flux_x
        var n_panels_d = self.m_n_panels
        if self.m_n_panels >= self.m_n_flux_x:
            for i in range(self.m_n_panels):
                var ppos = (n_flux_x_d / n_panels_d * i + n_flux_x_d * 0.5 / n_panels_d)
                var flo = floor(ppos)
                var ceiling = ceil(ppos)
                var ind = (ppos - flo) / fmax(ceiling - flo, 1.0E-6)
                if ceiling > self.m_n_flux_x - 1:
                    ceiling = 0
                var psp_field = (ind * (flux.at(ceiling) - flux.at(flo)) + flux.at(flo))
                q_dot_inc.at(i) = self.m_A_node * psp_field * 1000.0
        else:
            var leftovers = 0.0
            var index_start: Int = 0
            var index_stop: Int = 0
            var q_flux_sum: Float64 = 0.0
            var panel_step = n_flux_x_d / n_panels_d
            for i in range(self.m_n_panels):
                var panel_pos = panel_step * (i + 1)
                index_start = floor(panel_step * i)
                index_stop = floor(panel_pos)
                q_flux_sum = 0.0
                for j in range(index_start, index_stop + 1):
                    if j == self.m_n_flux_x:
                        if leftovers > 0.0:
                            self.csp_messages.add_message(C_csp_messages.WARNING, "An error occurred during interpolation of the receiver flux map. The results may be inaccurate! Contact SAM support to resolve this issue.")
                        break
                    if j == 0:
                        q_flux_sum = flux.at(j)
                        leftovers = 0.0
                    elif j == index_start:
                        q_flux_sum += leftovers
                        leftovers = 0.0
                    elif j == index_stop:
                        var stop_mult = (panel_pos - floor(panel_pos))
                        q_flux_sum += stop_mult * flux.at(j)
                        leftovers = (1.0 - stop_mult) * flux.at(j)
                    else:
                        q_flux_sum += flux[j]
                q_dot_inc.at(i) = q_flux_sum * self.m_A_node / n_flux_x_d * n_panels_d * 1000.0
        return q_dot_inc

    def calculate_steady_state_soln(inout self, soln: s_steady_state_soln, tol: Float64, max_iter: Int = 50):
        var P_amb = soln.p_amb
        var hour = soln.hour
        var T_dp = soln.T_dp
        var T_amb = soln.T_amb
        var v_wind_10 = soln.v_wind_10
        var T_sky = CSP.skytemp(T_amb, T_dp, hour)
        var v_wind = log((self.m_h_tower + self.m_h_rec / 2.0) / 0.003) / log(10.0 / 0.003) * v_wind_10
        var T_s_guess: util.matrix_t[Float64]
        T_s_guess.resize(self.m_n_panels)
        var T_panel_out_guess: util.matrix_t[Float64]
        T_panel_out_guess.resize(self.m_n_panels)
        var T_panel_in_guess: util.matrix_t[Float64]
        T_panel_in_guess.resize(self.m_n_panels)
        var T_film: util.matrix_t[Float64]
        T_film.resize(self.m_n_panels)
        var soln_exists = (soln.T_salt_hot == soln.T_salt_hot)
        soln.m_dot_salt_tot = soln.m_dot_salt * self.m_n_lines
        var T_salt_hot_guess: Float64
        if soln_exists:
            T_salt_hot_guess = soln.T_salt_hot
            T_s_guess = soln.T_s
            T_panel_out_guess = soln.T_panel_out
            T_panel_in_guess = soln.T_panel_in
        else:
            T_salt_hot_guess = self.m_T_salt_hot_target
            soln.T_s.resize(self.m_n_panels)
            soln.T_panel_out.resize(self.m_n_panels)
            soln.T_panel_in.resize(self.m_n_panels)
            soln.q_dot_conv.resize(self.m_n_panels)
            soln.q_dot_rad.resize(self.m_n_panels)
            soln.q_dot_loss.resize(self.m_n_panels)
            soln.q_dot_abs.resize(self.m_n_panels)
            soln.T_panel_ave.resize(self.m_n_panels)
            if self.m_night_recirc == 1:
                T_s_guess.fill(self.m_T_salt_hot_target)
                T_panel_out_guess.fill((self.m_T_salt_hot_target + soln.T_salt_cold_in) / 2.0)
                T_panel_in_guess.fill((self.m_T_salt_hot_target + soln.T_salt_cold_in) / 2.0)
            else:
                T_s_guess.fill(self.m_T_salt_hot_target)
                T_panel_out_guess.fill(soln.T_salt_cold_in)
                T_panel_in_guess.fill(soln.T_salt_cold_in)
        for q in range(max_iter):
            var T_coolant_prop: Float64
            if soln.T_salt_props == soln.T_salt_props:
                T_coolant_prop = soln.T_salt_props
            else:
                T_coolant_prop = (T_salt_hot_guess + soln.T_salt_cold_in) / 2.0
            var c_p_coolant = field_htfProps.Cp(T_coolant_prop) * 1000.0
            for i in range(self.m_n_panels):
                soln.T_s.at(i) = T_s_guess.at(i)
                soln.T_panel_out.at(i) = T_panel_out_guess.at(i)
                soln.T_panel_in.at(i) = T_panel_in_guess.at(i)
                soln.T_panel_ave.at(i) = (soln.T_panel_in.at(i) + soln.T_panel_out.at(i)) / 2.0
                T_film.at(i) = (soln.T_s.at(i) + T_amb) / 2.0
            var T_s_sum: Float64 = 0.0
            for i in range(self.m_n_panels):
                T_s_sum += soln.T_s.at(i)
            var T_film_ave = (T_amb + T_salt_hot_guess) / 2.0
            var k_film = ambient_air.cond(T_film_ave)
            var mu_film = ambient_air.visc(T_film_ave)
            var rho_film = ambient_air.dens(T_film_ave, P_amb)
            var c_p_film = ambient_air.Cp(T_film_ave)
            var Re_for = rho_film * v_wind * self.m_d_rec / mu_film
            var ksD = (self.m_od_tube / 2.0) / self.m_d_rec
            var Nusselt_for = CSP.Nusselt_FC(ksD, Re_for)
            var h_for = Nusselt_for * k_film / self.m