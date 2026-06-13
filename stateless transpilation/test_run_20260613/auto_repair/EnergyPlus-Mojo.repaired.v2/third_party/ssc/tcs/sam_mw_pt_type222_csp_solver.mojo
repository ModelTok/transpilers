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
from tcstype import *
from htf_props import *
from sam_csp_util import *
from ngcc_powerblock import *
from csp_solver_mspt_receiver_222 import *
from csp_solver_util import *
from csp_solver_core import *

enum:
    P_N_panels = 0
    P_D_rec = 1
    P_H_rec = 2
    P_THT = 3
    P_D_out = 4
    P_th_tu = 5
    P_mat_tube = 6
    P_field_fl = 7
    P_field_fl_props = 8
    P_Flow_type = 9
    P_crossover_shift = 10
    P_epsilon = 11
    P_hl_ffact = 12
    P_T_htf_hot_des = 13
    P_T_htf_cold_des = 14
    P_f_rec_min = 15
    P_Q_rec_des = 16
    P_rec_su_delay = 17
    P_rec_qf_delay = 18
    P_m_dot_htf_max = 19
    P_A_sf = 20
    P_IS_DIRECT_ISCC = 21
    P_CYCLE_CONFIG = 22
    P_n_flux_x = 23
    P_n_flux_y = 24
    P_PIPING_LOSS_PER_M = 25
    P_PIPE_LENGTH_ADD = 26
    P_PIPE_LENGTH_MULT = 27
    I_azimuth = 28
    I_zenith = 29
    I_T_salt_hot = 30
    I_T_salt_cold = 31
    I_v_wind_10 = 32
    I_P_amb = 33
    I_eta_pump = 34
    I_T_dp = 35
    I_I_bn = 36
    I_field_eff = 37
    I_T_db = 38
    I_night_recirc = 39
    I_hel_stow_deploy = 40
    I_flux_map = 41
    O_m_dot_salt_tot = 42
    O_eta_therm = 43
    O_W_dot_pump = 44
    O_q_conv_sum = 45
    O_q_rad_sum = 46
    O_Q_thermal = 47
    O_T_salt_hot = 48
    O_field_eff_adj = 49
    O_q_solar_total = 50
    O_q_startup = 51
    O_dP_receiver = 52
    O_dP_total = 53
    O_vel_htf = 54
    O_T_salt_in = 55
    O_M_DOT_SS = 56
    O_Q_DOT_SS = 57
    O_F_TIMESTEP = 58
    N_MAX = 59

var sam_mw_pt_type222_variables: StaticArray[tcsvarinfo, N_MAX] = tcsvarinfo(
    {TCS_PARAM, TCS_NUMBER, P_N_panels, "N_panels", "Number of individual panels on the receiver", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_D_rec, "D_rec", "The overall outer diameter of the receiver", "m", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_H_rec, "H_rec", "The height of the receiver", "m", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_THT, "THT", "The height of the tower (hel. pivot to rec equator)", "m", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_D_out, "d_tube_out", "The outer diameter of an individual receiver tube", "mm", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_th_tu, "th_tube", "The wall thickness of a single receiver tube", "mm", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_mat_tube, "mat_tube", "The material name of the receiver tubes", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_field_fl, "rec_htf", "The name of the HTF used in the receiver", "", "", "", ""},
    {TCS_PARAM, TCS_MATRIX, P_field_fl_props, "field_fl_props", "User defined field fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_Flow_type, "Flow_type", "A flag indicating which flow pattern is used", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_crossover_shift, "crossover_shift", "", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_epsilon, "epsilon", "The emissivity of the receiver surface coating", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_hl_ffact, "hl_ffact", "The heat loss factor (thermal loss fudge factor)", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_T_htf_hot_des, "T_htf_hot_des", "Hot HTF outlet temperature at design conditions", "C", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_T_htf_cold_des, "T_htf_cold_des", "Cold HTF inlet temperature at design conditions", "C", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_f_rec_min, "f_rec_min", "Minimum receiver mass flow rate turn down fraction", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_Q_rec_des, "Q_rec_des", "Design-point receiver thermal power output", "MWt", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_rec_su_delay, "rec_su_delay", "Fixed startup delay time for the receiver", "hr", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_rec_qf_delay, "rec_qf_delay", "Energy-based receiver startup delay (fraction of rated thermal power)", "", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_m_dot_htf_max, "m_dot_htf_max", "Maximum receiver mass flow rate", "kg/hr", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_A_sf, "A_sf", "Solar Field Area", "m^2", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_IS_DIRECT_ISCC, "is_direct_iscc", "Is receiver directly connected to an iscc power block", "-", "", "", "-999"},
    {TCS_PARAM, TCS_NUMBER, P_CYCLE_CONFIG, "cycle_config", "Configuration of ISCC power cycle", "-", "", "", "1"},
    {TCS_PARAM, TCS_NUMBER, P_n_flux_x, "n_flux_x", "Receiver flux map resolution - X", "-", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_n_flux_y, "n_flux_y", "Receiver flux map resolution - Y", "-", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_PIPING_LOSS_PER_M, "piping_loss", "Thermal losses per meter of calculated tower piping", "Wt/m", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_PIPE_LENGTH_ADD, "piping_length_add", "Value added to product of tower height*piping length multiple", "m", "", "", ""},
    {TCS_PARAM, TCS_NUMBER, P_PIPE_LENGTH_MULT, "piping_length_mult", "Value multiplied to tower height", "-", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_azimuth, "azimuth", "Solar azimuth angle", "deg", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_zenith, "zenith", "Solar zenith angle", "deg", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_T_salt_hot, "T_salt_hot_target", "Desired HTF outlet temperature", "C", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_T_salt_cold, "T_salt_cold", "Desired HTF inlet temperature", "C", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_v_wind_10, "V_wind_10", "Ambient wind velocity, ground level", "m/s", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_P_amb, "P_amb", "Ambient atmospheric pressure", "mbar", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_eta_pump, "eta_pump", "Receiver HTF pump efficiency", "", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_T_dp, "T_dp", "Ambient dew point temperature", "C", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_I_bn, "I_bn", "Direct (beam) normal radiation", "W/m^2-K", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_field_eff, "field_eff", "Heliostat field efficiency", "", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_T_db, "T_db", "Ambient dry bulb temperature", "C", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_night_recirc, "night_recirc", "Flag to indicate night recirculation through the rec.", "", "", "", ""},
    {TCS_INPUT, TCS_NUMBER, I_hel_stow_deploy, "hel_stow_deploy", "Heliostat field stow/deploy solar angle", "deg", "", "", ""},
    {TCS_INPUT, TCS_MATRIX, I_flux_map, "flux_map", "Receiver flux map", "-", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_m_dot_salt_tot, "m_dot_salt_tot", "Total HTF flow rate through the receiver", "kg/hr", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_eta_therm, "eta_therm", "Receiver thermal efficiency", "", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_W_dot_pump, "W_dot_pump", "Receiver pump power", "MWe", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_q_conv_sum, "q_conv_sum", "Receiver convective losses", "MWt", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_q_rad_sum, "q_rad_sum", "Receiver radiative losses", "MWt", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_Q_thermal, "Q_thermal", "Receiver thermal output", "MWt", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_T_salt_hot, "T_salt_hot", "HTF outlet temperature", "C", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_field_eff_adj, "field_eff_adj", "Adjusted heliostat field efficiency - includes overdesign adjustment", "", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_q_solar_total, "Q_solar_total", "Total incident power on the receiver", "MWt", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_q_startup, "q_startup", "Startup energy consumed during the current time step", "MWt-hr", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_dP_receiver, "dP_receiver", "Receiver HTF pressure drop", "bar", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_dP_total, "dP_total", "Total receiver and tower pressure drop", "bar", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_vel_htf, "vel_htf", "Heat transfer fluid average velocity", "m/s", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_T_salt_in, "T_salt_cold", "Inlet salt temperature", "C", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_M_DOT_SS, "m_dot_ss", "Mass flow rate at steady state - does not derate for startup", "kg/hr", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_Q_DOT_SS, "q_dot_ss", "Thermal at steady state - does not derate for startup", "MW", "", "", ""},
    {TCS_OUTPUT, TCS_NUMBER, O_F_TIMESTEP, "f_timestep", "Fraction of timestep that receiver is operational (not starting-up)", "-", "", "", ""},
    {TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0}
)

class sam_mw_pt_type222(tcstypeinterface):
    var mspt_receiver: C_mspt_receiver_222
    var ms_weather: C_csp_weatherreader.S_outputs
    var ms_htf_state_in: C_csp_solver_htf_1state
    var ms_inputs: C_mspt_receiver_222.S_inputs
    var ms_sim_info: C_csp_solver_sim_info

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)

    def __del__(inout self):

    def init(inout self) -> Int:
        self.mspt_receiver.m_field_fl = Int(self.value(P_field_fl))
        var n_rows: Int = 0
        var n_cols: Int = 0
        var field_fl_props_ptr = self.value(P_field_fl_props, &n_rows, &n_cols)
        self.mspt_receiver.m_field_fl_props.resize(n_rows, n_cols)
        for r in range(n_rows):
            for c in range(n_cols):
                self.mspt_receiver.m_field_fl_props[r, c] = TCS_MATRIX_INDEX(self.var(P_field_fl_props), r, c)
        self.mspt_receiver.m_mat_tube = Int(self.value(P_mat_tube))
        self.mspt_receiver.m_n_panels = Int(self.value(P_N_panels))
        self.mspt_receiver.m_d_rec = self.value(P_D_rec)
        self.mspt_receiver.m_h_rec = self.value(P_H_rec)
        self.mspt_receiver.m_h_tower = self.value(P_THT)
        self.mspt_receiver.m_od_tube = self.value(P_D_out)
        self.mspt_receiver.m_th_tube = self.value(P_th_tu)
        self.mspt_receiver.m_flow_type = Int(self.value(P_Flow_type))
        self.mspt_receiver.m_crossover_shift = Int(self.value(P_crossover_shift))
        self.mspt_receiver.m_epsilon = self.value(P_epsilon)
        self.mspt_receiver.m_hl_ffact = self.value(P_hl_ffact)
        self.mspt_receiver.m_T_htf_hot_des = self.value(P_T_htf_hot_des)
        self.mspt_receiver.m_T_htf_cold_des = self.value(P_T_htf_cold_des)
        self.mspt_receiver.m_f_rec_min = self.value(P_f_rec_min)
        self.mspt_receiver.m_q_rec_des = self.value(P_Q_rec_des)
        self.mspt_receiver.m_rec_su_delay = self.value(P_rec_su_delay)
        self.mspt_receiver.m_rec_qf_delay = self.value(P_rec_qf_delay)
        self.mspt_receiver.m_m_dot_htf_max = self.value(P_m_dot_htf_max)
        self.mspt_receiver.m_m_dot_htf_max_frac = Float64.nan
        self.mspt_receiver.m_A_sf = self.value(P_A_sf)
        self.mspt_receiver.m_pipe_loss_per_m = self.value(P_PIPING_LOSS_PER_M)
        self.mspt_receiver.m_pipe_length_add = self.value(P_PIPE_LENGTH_ADD)
        self.mspt_receiver.m_pipe_length_mult = self.value(P_PIPE_LENGTH_MULT)
        self.mspt_receiver.m_n_flux_x = Int(self.value(P_n_flux_x))
        self.mspt_receiver.m_n_flux_y = Int(self.value(P_n_flux_y))
        self.mspt_receiver.m_T_salt_hot_target = self.value(I_T_salt_hot)
        self.mspt_receiver.m_eta_pump = self.value(I_eta_pump)
        self.mspt_receiver.m_night_recirc = Int(self.value(I_night_recirc))
        self.mspt_receiver.m_hel_stow_deploy = self.value(I_hel_stow_deploy)
        var p_i_flux_map = self.allocate(I_flux_map, self.mspt_receiver.m_n_flux_y, self.mspt_receiver.m_n_flux_x)
        self.mspt_receiver.m_is_iscc = self.value(P_IS_DIRECT_ISCC) == 1.0
        self.mspt_receiver.m_cycle_config = Int(self.value(P_CYCLE_CONFIG))
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mspt_receiver.init()
        except C_csp_exception as csp_exception:
            while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        self.ms_weather.m_solazi = self.value(I_azimuth)
        self.ms_weather.m_solzen = self.value(I_zenith)
        var T_salt_cold_in_csp: Float64 = self.value(I_T_salt_cold)
        self.ms_weather.m_wspd = self.value(I_v_wind_10)
        self.ms_weather.m_pres = self.value(I_P_amb)
        self.ms_weather.m_tdew = self.value(I_T_dp)
        self.ms_weather.m_beam = self.value(I_I_bn)
        self.ms_inputs.m_field_eff = self.value(I_field_eff)
        self.ms_weather.m_tdry = self.value(I_T_db)
        var n_flux_y_csp: Int = 0
        var n_flux_x_csp: Int = 0
        var p_i_flux_map = self.value(I_flux_map, &n_flux_y_csp, &n_flux_x_csp)
        var flux_map_in = util.matrix_t[Float64](n_flux_y_csp, n_flux_x_csp)
        for i in range(n_flux_y_csp):
            for j in range(n_flux_x_csp):
                flux_map_in[i, j] = p_i_flux_map[j * n_flux_y_csp + i]
        self.ms_inputs.m_flux_map_input = &flux_map_in
        self.ms_sim_info.ms_ts.m_time = time
        self.ms_sim_info.ms_ts.m_step = step
        self.ms_htf_state_in.m_temp = T_salt_cold_in_csp
        self.ms_inputs.m_input_operation_mode = C_csp_collector_receiver.E_csp_cr_modes.ON
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mspt_receiver.call(self.ms_weather, self.ms_htf_state_in, self.ms_inputs, self.ms_sim_info)
        except C_csp_exception as csp_exception:
            while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        self.value(O_m_dot_salt_tot, self.mspt_receiver.ms_outputs.m_m_dot_salt_tot)
        self.value(O_eta_therm, self.mspt_receiver.ms_outputs.m_eta_therm)
        self.value(O_W_dot_pump, self.mspt_receiver.ms_outputs.m_W_dot_pump)
        self.value(O_q_conv_sum, self.mspt_receiver.ms_outputs.m_q_conv_sum)
        self.value(O_q_rad_sum, self.mspt_receiver.ms_outputs.m_q_rad_sum)
        self.value(O_Q_thermal, self.mspt_receiver.ms_outputs.m_Q_thermal)
        self.value(O_T_salt_hot, self.mspt_receiver.ms_outputs.m_T_salt_hot)
        self.value(O_field_eff_adj, self.mspt_receiver.ms_outputs.m_field_eff_adj)
        self.value(O_q_solar_total, self.mspt_receiver.ms_outputs.m_q_dot_rec_inc)
        self.value(O_q_startup, self.mspt_receiver.ms_outputs.m_q_startup)
        self.value(O_dP_receiver, self.mspt_receiver.ms_outputs.m_dP_receiver)
        self.value(O_dP_total, self.mspt_receiver.ms_outputs.m_dP_total)
        self.value(O_vel_htf, self.mspt_receiver.ms_outputs.m_vel_htf)
        self.value(O_T_salt_in, self.mspt_receiver.ms_outputs.m_T_salt_cold)
        self.value(O_M_DOT_SS, self.mspt_receiver.ms_outputs.m_m_dot_ss)
        self.value(O_Q_DOT_SS, self.mspt_receiver.ms_outputs.m_q_dot_ss)
        self.value(O_F_TIMESTEP, self.mspt_receiver.ms_outputs.m_f_timestep)
        return 0

    def converged(inout self, time: Float64) -> Int:
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mspt_receiver.converged()
        except C_csp_exception as csp_exception:
            while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mspt_receiver.csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_pt_type222, "External Receiver/Tower", "Ty Neises", 1, sam_mw_pt_type222_variables, NULL, 1)