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
from csp_solver_core import C_csp_tes, C_csp_reported_outputs, C_csp_messages, C_csp_exception, csp_info_invalid
from csp_solver_util import HTFProperties, util, CSP
from sam_csp_util import CSP as CSP_util  # assume pi etc.

const N_tes_pipe_sections: Int = 11

struct C_hx_two_tank_tes:
    var mc_field_htfProps: HTFProperties
    var mc_store_htfProps: HTFProperties
    var m_m_dot_des_ave: Float64
    var m_eff_des: Float64
    var m_UA_des: Float64

    def __init__(inout self):
        self.m_m_dot_des_ave = Float64.nan
        self.m_eff_des = Float64.nan
        self.m_UA_des = Float64.nan

    def init(inout self, fluid_field: HTFProperties, fluid_store: HTFProperties, q_transfer_des: Float64, dt_des: Float64, T_h_in_des: Float64, T_h_out_des: Float64):
        self.mc_field_htfProps = fluid_field
        self.mc_store_htfProps = fluid_store
        var T_ave: Float64 = (T_h_in_des + T_h_out_des) / 2.0
        var c_h: Float64 = self.mc_field_htfProps.Cp(T_ave) * 1000.0
        var c_c: Float64 = self.mc_store_htfProps.Cp(T_ave) * 1000.0
        var T_c_out: Float64 = T_h_in_des - dt_des
        var T_c_in: Float64 = T_h_out_des - dt_des
        var m_dot_h: Float64 = q_transfer_des / (c_h * (T_h_in_des - T_h_out_des))
        var m_dot_c: Float64 = q_transfer_des / (c_c * (T_c_out - T_c_in))
        self.m_m_dot_des_ave = 0.5 * (m_dot_h + m_dot_c)
        var c_dot_h: Float64 = m_dot_h * c_h
        var c_dot_c: Float64 = m_dot_c * c_c
        var c_dot_max: Float64 = fmax(c_dot_h, c_dot_c)
        var c_dot_min: Float64 = fmin(c_dot_h, c_dot_c)
        var cr: Float64 = c_dot_min / c_dot_max
        var q_max: Float64 = c_dot_min * (T_h_in_des - T_c_in)
        self.m_eff_des = q_transfer_des / q_max
        if cr > 1.0 or cr < 0.0:
            raise C_csp_exception("Heat exchanger design calculations failed", "")
        var NTU: Float64 = Float64.nan
        if cr < 1.0:
            NTU = log((1.0 - self.m_eff_des * cr) / (1.0 - self.m_eff_des)) / (1.0 - cr)
        else:
            NTU = self.m_eff_des / (1.0 - self.m_eff_des)
        self.m_UA_des = NTU * c_dot_min

    def solve(inout self, T_f_htf_hx_in: Float64, m_dot_f_htf: Float64, T_s_htf_hx_in: Float64, m_dot_s_htf: Float64, 
        inout T_f_htf_hx_out: Float64, inout T_s_htf_hx_out: Float64, inout eff: Float64, inout q_dot_hx: Float64):
        if m_dot_f_htf == 0.0 or m_dot_s_htf == 0.0:
            T_f_htf_hx_out = T_f_htf_hx_in
            T_s_htf_hx_out = T_s_htf_hx_in
            eff = 0.0
            q_dot_hx = 0.0
            return
        var m_dot_od: Float64 = 0.5 * (m_dot_f_htf + m_dot_s_htf)
        var UA: Float64 = self.m_UA_des * pow(m_dot_od / self.m_m_dot_des_ave, 0.8)
        var T_ave: Float64 = (T_f_htf_hx_in + T_s_htf_hx_in) / 2.0
        var cp_f: Float64 = self.mc_field_htfProps.Cp(T_ave) * 1000.0
        var c_dot_f: Float64 = cp_f * m_dot_f_htf
        var cp_s: Float64 = self.mc_store_htfProps.Cp(T_ave) * 1000.0
        var c_dot_s: Float64 = cp_s * m_dot_s_htf
        var c_dot_min: Float64 = min(c_dot_f, c_dot_s)
        var CR: Float64 = min(c_dot_f, c_dot_s) / max(c_dot_s, c_dot_f)
        var NTU: Float64 = UA / c_dot_min
        if CR > 0.999:
            eff = NTU / (1.0 + NTU)
        else:
            eff = (1.0 - exp(-NTU * (1.0 - CR))) / (1.0 - CR * exp(-NTU * (1.0 - CR)))
        if isnan(eff) or eff <= 0.0 or eff > 1.0:
            T_f_htf_hx_out = Float64.nan
            T_s_htf_hx_out = Float64.nan
            eff = Float64.nan
            q_dot_hx = Float64.nan
            raise C_csp_exception("Off design heat exchanger failed", "")
        var T_hot_in: Float64 = max(T_f_htf_hx_in, T_s_htf_hx_in)
        var T_cold_in: Float64 = min(T_f_htf_hx_in, T_s_htf_hx_in)
        var q_dot_max: Float64 = c_dot_min * (T_hot_in - T_cold_in)
        q_dot_hx = eff * q_dot_max
        if T_s_htf_hx_in > T_f_htf_hx_in:
            T_s_htf_hx_out = T_s_htf_hx_in - q_dot_hx / c_dot_s
            T_f_htf_hx_out = T_f_htf_hx_in + q_dot_hx / c_dot_f
        else:
            T_s_htf_hx_out = T_s_htf_hx_in + q_dot_hx / c_dot_s
            T_f_htf_hx_out = T_f_htf_hx_in - q_dot_hx / c_dot_f
        q_dot_hx *= 1.0e-6

struct C_storage_tank:
    var mc_htf: HTFProperties
    var m_V_total: Float64
    var m_V_active: Float64
    var m_V_inactive: Float64
    var m_UA: Float64
    var m_T_htr: Float64
    var m_max_q_htr: Float64
    var m_T_design: Float64
    var m_mass_total: Float64
    var m_mass_inactive: Float64
    var m_mass_active: Float64
    var m_V_prev: Float64
    var m_T_prev: Float64
    var m_m_prev: Float64
    var m_V_calc: Float64
    var m_T_calc: Float64
    var m_m_calc: Float64

    def __init__(inout self):
        self.m_V_prev = Float64.nan
        self.m_T_prev = Float64.nan
        self.m_m_prev = Float64.nan
        self.m_V_total = Float64.nan
        self.m_V_active = Float64.nan
        self.m_V_inactive = Float64.nan
        self.m_UA = Float64.nan
        self.m_T_htr = Float64.nan
        self.m_max_q_htr = Float64.nan
        self.m_T_design = Float64.nan
        self.m_mass_total = Float64.nan
        self.m_mass_inactive = Float64.nan
        self.m_mass_active = Float64.nan

    def init(inout self, htf_class_in: HTFProperties, V_tank: Float64, h_tank: Float64, h_min: Float64, u_tank: Float64, 
        tank_pairs: Float64, T_htr: Float64, max_q_htr: Float64, V_ini: Float64, T_ini: Float64, T_design: Float64):
        self.mc_htf = htf_class_in
        var rho_des: Float64 = self.mc_htf.dens(T_design, 1.0)
        self.m_V_total = V_tank
        self.m_mass_total = self.m_V_total * rho_des
        self.m_V_inactive = self.m_V_total * h_min / h_tank
        self.m_mass_inactive = self.m_V_inactive * rho_des
        self.m_V_active = self.m_V_total - self.m_V_inactive
        self.m_mass_active = self.m_mass_total - self.m_mass_inactive
        var A_cs: Float64 = self.m_V_total / (h_tank * tank_pairs)
        var diameter: Float64 = pow(A_cs / CSP.pi, 0.5) * 2.0
        self.m_UA = u_tank * (A_cs + CSP.pi * diameter * h_tank) * tank_pairs
        self.m_T_htr = T_htr
        self.m_max_q_htr = max_q_htr
        self.m_V_prev = V_ini
        self.m_T_prev = T_ini
        self.m_m_prev = self.calc_mass_at_prev()

    def calc_mass_at_prev(self) -> Float64:
        return self.m_V_prev * self.mc_htf.dens(self.m_T_prev, 1.0)

    def calc_cp_at_prev(self) -> Float64:
        return self.mc_htf.Cp(self.m_T_prev) * 1000.0

    def calc_enth_at_prev(self) -> Float64:
        return self.mc_htf.enth(self.m_T_prev)

    def get_m_UA(self) -> Float64:
        return self.m_UA

    def get_m_T_prev(self) -> Float64:
        return self.m_T_prev

    def get_m_T_calc(self) -> Float64:
        return self.m_T_calc

    def get_m_m_calc(self) -> Float64:
        return self.m_m_calc

    def get_vol_frac(self) -> Float64:
        return (self.m_V_prev - self.m_V_inactive) / self.m_V_active

    def m_dot_available(self, f_unavail: Float64, timestep: Float64) -> Float64:
        var mass_avail: Float64 = max(self.m_m_prev - self.m_mass_inactive, 0.0)
        var m_dot_avail: Float64 = max(mass_avail - self.m_mass_active * f_unavail, 0.0) / timestep
        return m_dot_avail

    def converged(inout self):
        self.m_V_prev = self.m_V_calc
        self.m_T_prev = self.m_T_calc
        self.m_m_prev = self.m_m_calc

    def energy_balance(inout self, timestep: Float64, m_dot_in: Float64, m_dot_out: Float64, T_in: Float64, T_amb: Float64, 
        inout T_ave: Float64, inout q_heater: Float64, inout q_dot_loss: Float64):
        var rho: Float64 = self.mc_htf.dens(self.m_T_prev, 1.0)
        var cp: Float64 = self.mc_htf.Cp(self.m_T_prev) * 1000.0
        self.m_m_calc = self.m_m_prev + timestep * (m_dot_in - m_dot_out)
        var m_min: Float64 = 0.001
        var m_dot_out_adj: Float64
        var tank_is_empty: Bool = False
        if self.m_m_calc < m_min:
            self.m_m_calc = m_min
            tank_is_empty = True
            m_dot_out_adj = m_dot_in - (m_min - self.m_m_prev) / timestep
        else:
            m_dot_out_adj = m_dot_out
        self.m_V_calc = self.m_m_calc / rho
        if self.m_m_prev <= 1e-4 and tank_is_empty == True:
            if m_dot_in > 0:
                self.m_T_calc = T_ave = T_in
            else:
                self.m_T_calc = T_ave = self.m_T_prev
            q_dot_loss = 0.0
            self.m_V_calc = 0.0
            self.m_m_calc = 0.0
            q_heater = 0.0
            return
        var diff_m_dot: Float64 = m_dot_in - m_dot_out_adj
        if diff_m_dot >= 0.0:
            diff_m_dot = max(diff_m_dot, 1e-5)
        else:
            diff_m_dot = min(diff_m_dot, -1e-5)
        if diff_m_dot != 0.0:
            var a_coef: Float64 = m_dot_in * T_in + self.m_UA / cp * T_amb
            var b_coef: Float64 = m_dot_in + self.m_UA / cp
            var c_coef: Float64 = diff_m_dot
            self.m_T_calc = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef)
            T_ave = a_coef / b_coef + self.m_m_prev * (self.m_T_prev - a_coef / b_coef) / ((c_coef - b_coef) * timestep) * (pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), 1.0 - b_coef / c_coef) - 1.0)
            if timestep < 1e-6:
                T_ave = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1e6
            if self.m_T_calc < self.m_T_htr:
                q_heater = b_coef * ((self.m_T_htr - self.m_T_prev * pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef)) / (-pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef) + 1.0)) - a_coef
                q_heater = q_heater * cp
                q_heater /= 1e6
            else:
                q_heater = 0.0
                return
            if q_heater > self.m_max_q_htr:
                q_heater = self.m_max_q_htr
            a_coef += q_heater * 1e6 / cp
            self.m_T_calc = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef)
            T_ave = a_coef / b_coef + self.m_m_prev * (self.m_T_prev - a_coef / b_coef) / ((c_coef - b_coef) * timestep) * (pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), 1.0 - b_coef / c_coef) - 1.0)
            if timestep < 1e-6:
                T_ave = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow(max(timestep * c_coef / self.m_m_prev + 1.0, 0.0), -b_coef / c_coef)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1e6
        else:
            var b_coef: Float64 = self.m_UA / (cp * self.m_m_prev)
            var c_coef: Float64 = self.m_UA / (cp * self.m_m_prev) * T_amb
            self.m_T_calc = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            T_ave = c_coef / b_coef - (self.m_T_prev - c_coef / b_coef) / (b_coef * timestep) * (exp(-b_coef * timestep) - 1.0)
            if timestep < 1e-6:
                T_ave = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1e6
            if self.m_T_calc < self.m_T_htr:
                q_heater = (b_coef * (self.m_T_htr - self.m_T_prev * exp(-b_coef * timestep)) / (-exp(-b_coef * timestep) + 1.0) - c_coef) * cp * self.m_m_prev
                q_heater /= 1e6
            else:
                q_heater = 0.0
                return
            if q_heater > self.m_max_q_htr:
                q_heater = self.m_max_q_htr
            c_coef += q_heater * 1e6 / (cp * self.m_m_prev)
            self.m_T_calc = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            T_ave = c_coef / b_coef - (self.m_T_prev - c_coef / b_coef) / (b_coef * timestep) * (exp(-b_coef * timestep) - 1.0)
            if timestep < 1e-6:
                T_ave = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1e6
        if tank_is_empty:
            self.m_V_calc = 0.0
            self.m_m_calc = 0.0

    def energy_balance_constant_mass(inout self, timestep: Float64, m_dot_in: Float64, T_in: Float64, T_amb: Float64, 
        inout T_ave: Float64, inout q_heater: Float64, inout q_dot_loss: Float64):
        var rho: Float64 = self.mc_htf.dens(self.m_T_prev, 1.0)
        var cp: Float64 = self.mc_htf.Cp(self.m_T_prev) * 1000.0
        self.m_m_calc = self.m_m_prev
        self.m_V_calc = self.m_m_calc / rho
        var a_coef: Float64 = m_dot_in / self.m_m_calc + self.m_UA / (self.m_m_calc * cp)
        var b_coef: Float64 = m_dot_in / self.m_m_calc * T_in + self.m_UA / (self.m_m_calc * cp) * T_amb
        self.m_T_calc = b_coef / a_coef - (b_coef / a_coef - self.m_T_prev) * exp(-a_coef * timestep)
        T_ave = b_coef / a_coef - (b_coef / a_coef - self.m_T_prev) * exp(-a_coef * timestep / 2.0)
        q_heater = 0.0
        return

# Static output info array
var S_output_info: List[C_csp_reported_outputs.S_output_info] = List[C_csp_reported_outputs.S_output_info](
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_Q_DOT_LOSS, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_W_DOT_HEATER, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_TES_T_HOT, C_csp_reported_outputs.TS_LAST),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_TES_T_COLD, C_csp_reported_outputs.TS_LAST),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_M_DOT_TANK_TO_TANK, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_MASS_COLD_TANK, C_csp_reported_outputs.TS_LAST),
    C_csp_reported_outputs.S_output_info(C_csp_two_tank_tes.E_MASS_HOT_TANK, C_csp_reported_outputs.TS_LAST),
    csp_info_invalid
)

struct C_csp_two_tank_tes(C_csp_tes):
    var mc_field_htfProps: HTFProperties
    var mc_store_htfProps: HTFProperties
    var mc_hx: C_hx_two_tank_tes
    var mc_cold_tank: C_storage_tank
    var mc_hot_tank: C_storage_tank
    var error_msg: String
    var m_is_tes: Bool
    var m_vol_tank: Float64
    var m_V_tank_active: Float64
    var m_q_pb_design: Float64
    var m_V_tank_hot_ini: Float64
    var m_cp_field_avg: Float64
    var m_m_dot_tes_des_over_m_dot_field_des: Float64
    var mc_reported_outputs: C_csp_reported_outputs
    var mc_csp_messages: C_csp_messages
    var ms_params: S_params
    var pipe_vol_tot: Float64
    var pipe_v_dot_rel: DynamicMatrix[Float64]
    var pipe_diams: DynamicMatrix[Float64]
    var pipe_wall_thk: DynamicMatrix[Float64]
    var pipe_lengths: DynamicMatrix[Float64]
    var pipe_m_dot_des: DynamicMatrix[Float64]
    var pipe_vel_des: DynamicMatrix[Float64]
    var pipe_T_des: DynamicMatrix[Float64]
    var pipe_P_des: DynamicMatrix[Float64]
    var P_in_des: Float64

    struct S_params:
        var m_field_fl: Int
        var m_field_fl_props: DynamicMatrix[Float64]
        var m_tes_fl: Int
        var m_tes_fl_props: DynamicMatrix[Float64]
        var m_is_hx: Bool
        var m_W_dot_pc_design: Float64
        var m_eta_pc: Float64
        var m_solarm: Float64
        var m_ts_hours: Float64
        var m_h_tank: Float64
        var m_u_tank: Float64
        var m_tank_pairs: Int
        var m_hot_tank_Thtr: Float64
        var m_hot_tank_max_heat: Float64
        var m_cold_tank_Thtr: Float64
        var m_cold_tank_max_heat: Float64
        var m_dt_hot: Float64
        var m_T_field_in_des: Float64
        var m_T_field_out_des: Float64
        var m_dP_field_des: Float64
        var m_T_tank_hot_ini: Float64
        var m_T_tank_cold_ini: Float64
        var m_h_tank_min: Float64
        var m_f_V_hot_ini: Float64
        var m_htf_pump_coef: Float64
        var m_tes_pump_coef: Float64
        var eta_pump: Float64
        var tanks_in_parallel: Bool
        var has_hot_tank_bypass: Bool
        var T_tank_hot_inlet_min: Float64
        var V_tes_des: Float64
        var custom_tes_p_loss: Bool
        var custom_tes_pipe_sizes: Bool
        var k_tes_loss_coeffs: DynamicMatrix[Float64]
        var tes_diams: DynamicMatrix[Float64]
        var tes_wallthicks: DynamicMatrix[Float64]
        var tes_lengths: DynamicMatrix[Float64]
        var calc_design_pipe_vals: Bool
        var pipe_rough: Float64
        var DP_SGS: Float64

        def __init__(inout self):
            self.m_field_fl = -1
            self.m_tes_fl = -1
            self.m_tank_pairs = -1
            self.m_is_hx = True
            self.tanks_in_parallel = True
            self.has_hot_tank_bypass = True
            self.custom_tes_p_loss = False
            self.custom_tes_pipe_sizes = False
            self.calc_design_pipe_vals = True
            self.m_ts_hours = 0.0
            self.m_W_dot_pc_design = Float64.nan
            self.m_eta_pc = Float64.nan
            self.m_solarm = Float64.nan
            self.m_h_tank = Float64.nan
            self.m_u_tank = Float64.nan
            self.m_hot_tank_Thtr = Float64.nan
            self.m_hot_tank_max_heat = Float64.nan
            self.m_cold_tank_Thtr = Float64.nan
            self.m_cold_tank_max_heat = Float64.nan
            self.m_dt_hot = Float64.nan
            self.m_T_field_in_des = Float64.nan
            self.m_T_field_out_des = Float64.nan
            self.m_dP_field_des = Float64.nan
            self.m_T_tank_hot_ini = Float64.nan
            self.m_T_tank_cold_ini = Float64.nan
            self.m_h_tank_min = Float64.nan
            self.m_f_V_hot_ini = Float64.nan
            self.m_htf_pump_coef = Float64.nan
            self.m_tes_pump_coef = Float64.nan
            self.eta_pump = Float64.nan
            self.T_tank_hot_inlet_min = Float64.nan
            self.V_tes_des = Float64.nan
            self.pipe_rough = Float64.nan
            self.DP_SGS = Float64.nan
            self.k_tes_loss_coeffs = DynamicMatrix[Float64]()
            self.k_tes_loss_coeffs.resize_fill(11, 0.0)
            self.tes_diams = DynamicMatrix[Float64]()
            self.tes_diams.resize_fill(1, -1.0)
            self.tes_wallthicks = DynamicMatrix[Float64]()
            self.tes_wallthicks.resize_fill(1, -1.0)
            var vals1: List[Float64] = List[Float64](0.0, 90.0, 100.0, 120.0, 0.0, 0.0, 0.0, 0.0, 80.0, 120.0, 80.0)
            self.tes_lengths = DynamicMatrix[Float64]()
            self.tes_lengths.assign(vals1, 11)

    enum E:
        E_Q_DOT_LOSS = 0
        E_W_DOT_HEATER = 1
        E_TES_T_HOT = 2
        E_TES_T_COLD = 3
        E_M_DOT_TANK_TO_TANK = 4
        E_MASS_COLD_TANK = 5
        E_MASS_HOT_TANK = 6

    def __init__(inout self):
        self.m_vol_tank = Float64.nan
        self.m_V_tank_active = Float64.nan
        self.m_q_pb_design = Float64.nan
        self.m_V_tank_hot_ini = Float64.nan
        self.m_cp_field_avg = Float64.nan
        self.m_m_dot_tes_des_over_m_dot_field_des = Float64.nan
        self.mc_reported_outputs = C_csp_reported_outputs()
        self.mc_reported_outputs.construct(S_output_info)

    def __del__():

    def init(inout self, init_inputs: C_csp_tes.S_csp_tes_init_inputs):
        if not (self.ms_params.m_ts_hours > 0.0):
            self.m_is_tes = False
            return
        self.m_is_tes = True
        if self.ms_params.m_field_fl != HTFProperties.User_defined and self.ms_params.m_field_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_field_htfProps.SetFluid(self.ms_params.m_field_fl):
                raise C_csp_exception("Field HTF code is not recognized", "Two Tank TES Initialization")
        elif self.ms_params.m_field_fl == HTFProperties.User_defined:
            var n_rows = self.ms_params.m_field_fl_props.nrows() as Int
            var n_cols = self.ms_params.m_field_fl_props.ncols() as Int
            if n_rows > 2 and n_cols == 7:
                if not self.mc_field_htfProps.SetUserDefinedFluid(self.ms_params.m_field_fl_props):
                    self.error_msg = util.format(self.mc_field_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
            else:
                self.error_msg = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        else:
            raise C_csp_exception("Field HTF code is not recognized", "Two Tank TES Initialization")
        if self.ms_params.m_tes_fl != HTFProperties.User_defined and self.ms_params.m_tes_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_store_htfProps.SetFluid(self.ms_params.m_tes_fl):
                raise C_csp_exception("Storage HTF code is not recognized", "Two Tank TES Initialization")
        elif self.ms_params.m_tes_fl == HTFProperties.User_defined:
            var n_rows = self.ms_params.m_tes_fl_props.nrows() as Int
            var n_cols = self.ms_params.m_tes_fl_props.ncols() as Int
            if n_rows > 2 and n_cols == 7:
                if not self.mc_store_htfProps.SetUserDefinedFluid(self.ms_params.m_tes_fl_props):
                    self.error_msg = util.format(self.mc_store_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
            else:
                self.error_msg = util.format("The user defined storage HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        else:
            raise C_csp_exception("Storage HTF code is not recognized", "Two Tank TES Initialization")
        var is_hx_calc: Bool = True
        if self.ms_params.m_tes_fl != self.ms_params.m_field_fl:
            is_hx_calc = True
        elif self.ms_params.m_field_fl != HTFProperties.User_defined:
            is_hx_calc = False
        else:
            is_hx_calc = not self.mc_field_htfProps.equals(&self.mc_store_htfProps)
        if self.ms_params.m_is_hx != is_hx_calc:
            if is_hx_calc:
                self.mc_csp_messages.add_message(C_csp_messages.NOTICE, "Input field and storage fluids are different, but the inputs did not specify a field-to-storage heat exchanger. The system was modeled assuming a heat exchanger.")
            else:
                self.mc_csp_messages.add_message(C_csp_messages.NOTICE, "Input field and storage fluids are identical, but the inputs specified a field-to-storage heat exchanger. The system was modeled assuming no heat exchanger.")
            self.ms_params.m_is_hx = is_hx_calc
        if self.ms_params.m_is_hx and not self.ms_params.tanks_in_parallel:
            self.mc_csp_messages.add_message(C_csp_messages.NOTICE, "The inputs specified serial TES operation, but the field and storage fluids are different The simulation model parallel TES operation.")
            self.ms_params.tanks_in_parallel = True
        self.m_q_pb_design = self.ms_params.m_W_dot_pc_design / self.ms_params.m_eta_pc * 1e6
        self.ms_params.m_hot_tank_Thtr += 273.15
        self.ms_params.m_cold_tank_Thtr += 273.15
        self.ms_params.m_T_field_in_des += 273.15
        self.ms_params.m_T_field_out_des += 273.15
        self.ms_params.m_T_tank_hot_ini += 273.15
        self.ms_params.m_T_tank_cold_ini += 273.15
        var Q_tes_des: Float64 = self.m_q_pb_design / 1e6 * self.ms_params.m_ts_hours
        var d_tank_temp: Float64 = Float64.nan
        var q_dot_loss_temp: Float64 = Float64.nan
        two_tank_tes_sizing(self.mc_store_htfProps, Q_tes_des, self.ms_params.m_T_field_out_des, self.ms_params.m_T_field_in_des,
            self.ms_params.m_h_tank_min, self.ms_params.m_h_tank, self.ms_params.m_tank_pairs, self.ms_params.m_u_tank,
            self.m_V_tank_active, self.m_vol_tank, d_tank_temp, q_dot_loss_temp)
        var duty: Float64 = self.m_q_pb_design * fmax(1.0, self.ms_params.m_solarm)
        if self.ms_params.m_ts_hours > 0.0:
            self.mc_hx.init(self.mc_field_htfProps, self.mc_store_htfProps, duty, self.ms_params.m_dt_hot, self.ms_params.m_T_field_out_des, self.ms_params.m_T_field_in_des)
        var V_inactive: Float64 = self.m_vol_tank - self.m_V_tank_active
        var V_hot_ini: Float64 = self.ms_params.m_f_V_hot_ini * 0.01 * self.m_V_tank_active + V_inactive
        var V_cold_ini: Float64 = (1.0 - self.ms_params.m_f_V_hot_ini * 0.01) * self.m_V_tank_active + V_inactive
        var T_hot_ini: Float64 = self.ms_params.m_T_tank_hot_ini
        var T_cold_ini: Float64 = self.ms_params.m_T_tank_cold_ini
        self.mc_hot_tank.init(self.mc_store_htfProps, self.m_vol_tank, self.ms_params.m_h_tank, self.ms_params.m_h_tank_min, self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_hot_tank_Thtr, self.ms_params.m_hot_tank_max_heat, V_hot_ini, T_hot_ini, self.ms_params.m_T_field_out_des)
        self.mc_cold_tank.init(self.mc_store_htfProps, self.m_vol_tank, self.ms_params.m_h_tank, self.ms_params.m_h_tank_min, self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat, V_cold_ini, T_cold_ini, self.ms_params.m_T_field_in_des)
        if self.ms_params.tes_lengths.ncells() < 11:
            var vals1: List[Float64] = List[Float64](0.0, 90.0, 100.0, 120.0, 0.0, 0.0, 0.0, 0.0, 80.0, 120.0, 80.0)
            self.ms_params.tes_lengths.assign(vals1, 11)
        if self.ms_params.custom_tes_pipe_sizes and (self.ms_params.tes_diams.ncells() != N_tes_pipe_sections or self.ms_params.tes_wallthicks.ncells() != N_tes_pipe_sections):
            self.error_msg = "The number of custom TES pipe sections is not correct."
            raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        var rho_avg: Float64 = self.mc_field_htfProps.dens((self.ms_params.m_T_field_in_des + self.ms_params.m_T_field_out_des) / 2.0, 9.0 / 1e-5)
        self.m_cp_field_avg = self.mc_field_htfProps.Cp((self.ms_params.m_T_field_in_des + self.ms_params.m_T_field_out_des) / 2.0)
        var cp_tes_avg: Float64 = self.mc_store_htfProps.Cp((self.ms_params.m_T_field_in_des + self.ms_params.m_T_field_out_des) / 2.0)
        self.m_m_dot_tes_des_over_m_dot_field_des = self.m_cp_field_avg / cp_tes_avg
        var m_dot_pb_design: Float64 = self.ms_params.m_W_dot_pc_design * 1e3 / (self.ms_params.m_eta_pc * self.m_cp_field_avg * (self.ms_params.m_T_field_out_des - self.ms_params.m_T_field_in_des))
        var ret: Int = size_tes_piping(self.ms_params.V_tes_des, self.ms_params.tes_lengths, rho_avg, m_dot_pb_design, self.ms_params.m_solarm, self.ms_params.tanks_in_parallel,
            self.pipe_vol_tot, self.pipe_v_dot_rel, self.pipe_diams, self.pipe_wall_thk, self.pipe_m_dot_des, self.pipe_vel_des, self.ms_params.custom_tes_pipe_sizes)
        if ret != 0:
            self.error_msg = "TES piping sizing failed"
            raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        self.pipe_lengths = self.ms_params.tes_lengths
        if self.ms_params.calc_design_pipe_vals:
            ret = size_tes_piping_TandP(self.mc_field_htfProps, init_inputs.T_to_cr_at_des, init_inputs.T_from_cr_at_des, init_inputs.P_to_cr_at_des * 1e5, self.ms_params.DP_SGS * 1e5,
                self.ms_params.tes_lengths, self.ms_params.k_tes_loss_coeffs, self.ms_params.pipe_rough, self.ms_params.tanks_in_parallel,
                self.pipe_diams, self.pipe_vel_des, self.pipe_T_des, self.pipe_P_des, self.P_in_des)
            if ret != 0:
                self.error_msg = "TES piping design temperature and pressure calculation failed"
                raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
            var DP_before_hot_tank: Float64 = self.pipe_P_des[3]
            self.pipe_P_des[1] += DP_before_hot_tank
            self.pipe_P_des[2] += DP_before_hot_tank

    def does_tes_exist(self) -> Bool:
        return self.m_is_tes

    def get_hot_temp(self) -> Float64:
        return self.mc_hot_tank.get_m_T_prev()

    def get_cold_temp(self) -> Float64:
        return self.mc_cold_tank.get_m_T_prev()

    def get_hot_tank_vol_frac(self) -> Float64:
        return self.mc_hot_tank.get_vol_frac()

    def get_initial_charge_energy(self) -> Float64:
        return self.m_q_pb_design * self.ms_params.m_ts_hours * self.m_V_tank_hot_ini / self.m_vol_tank * 1e-6

    def get_min_charge_energy(self) -> Float64:
        return 0.0

    def get_max_charge_energy(self) -> Float64:
        return self.m_q_pb_design * self.ms_params.m_ts_hours / 1e6

    def get_degradation_rate(self) -> Float64:
        var d_tank: Float64 = sqrt(self.m_vol_tank / (self.ms_params.m_tank_pairs * self.ms_params.m_h_tank * 3.14159))
        var e_loss: Float64 = self.ms_params.m_u_tank * 3.14159 * self.ms_params.m_tank_pairs * d_tank * (self.ms_params.m_T_field_in_des + self.ms_params.m_T_field_out_des - 576.3) * 1e-6
        return e_loss / (self.m_q_pb_design * self.ms_params.m_ts_hours * 3600.0)

    def get_tes_m_dot(self, m_dot_field: Float64) -> Float64:
        return m_dot_field * self.m_m_dot_tes_des_over_m_dot_field_des

    def get_field_m_dot(self, m_dot_tes: Float64) -> Float64:
        return m_dot_tes / self.m_m_dot_tes_des_over_m_dot_field_des

    def discharge_avail_est(self, T_cold_K: Float64, step_s: Float64, inout q_dot_dc_est: Float64, inout m_dot_field_est: Float64, inout T_hot_field_est: Float64):
        var f_storage: Float64 = 0.0
        var m_dot_tank_disch_avail: Float64 = self.mc_hot_tank.m_dot_available(f_storage, step_s)
        if m_dot_tank_disch_avail == 0.0:
            q_dot_dc_est = 0.0
            m_dot_field_est = 0.0
            T_hot_field_est = Float64.nan
            return
        var T_hot_ini: Float64 = self.mc_hot_tank.get_m_T_prev()
        if self.ms_params.m_is_hx:
            self.m_dot_field_est = self.get_field_m_dot(m_dot_tank_disch_avail)
            var T_cold_tes: Float64 = Float64.nan
            var eff: Float64 = Float64.nan
            self.mc_hx.solve(T_cold_K, self.m_dot_field_est, T_hot_ini, m_dot_tank_disch_avail, T_hot_field_est, T_cold_tes, eff, q_dot_dc_est)
        else:
            var cp_T_avg: Float64 = self.mc_store_htfProps.Cp(0.5 * (T_cold_K + T_hot_ini))
            q_dot_dc_est = m_dot_tank_disch_avail * cp_T_avg * (T_hot_ini - T_cold_K) * 1e-3
            m_dot_field_est = m_dot_tank_disch_avail
            T_hot_field_est = T_hot_ini

    def charge_avail_est(self, T_hot_K: Float64, step_s: Float64, inout q_dot_ch_est: Float64, inout m_dot_field_est: Float64, inout T_cold_field_est: Float64):
        var f_ch_storage: Float64 = 0.0
        var m_dot_tank_charge_avail: Float64 = self.mc_cold_tank.m_dot_available(f_ch_storage, step_s)
        var T_cold_ini: Float64 = self.mc_cold_tank.get_m_T_prev()
        if self.ms_params.m_is_hx:
            self.m_dot_field_est = self.get_field_m_dot(m_dot_tank_charge_avail)
            var eff: Float64 = Float64.nan
            var T_hot_tes: Float64 = Float64.nan
            self.mc_hx.solve(T_hot_K, self.m_dot_field_est, T_cold_ini, m_dot_tank_charge_avail, T_cold_field_est, T_hot_tes, eff, q_dot_ch_est)
        else:
            var cp_T_avg: Float64 = self.mc_store_htfProps.Cp(0.5 * (T_cold_ini + T_hot_K))
            q_dot_ch_est = m_dot_tank_charge_avail * cp_T_avg * (T_hot_K - T_cold_ini) * 1e-3
            m_dot_field_est = m_dot_tank_charge_avail
            T_cold_field_est = T_cold_ini

    def solve_tes_off_design(inout self, timestep: Float64, T_amb: Float64, m_dot_field: Float64, m_dot_cycle: Float64, 
        T_field_htf_out_hot: Float64, T_cycle_htf_out_cold: Float64, inout T_cycle_htf_in_hot: Float64, inout T_field_htf_in_cold: Float64, 
        inout s_outputs: C_csp_tes.S_csp_tes_outputs) -> Int:
        s_outputs = C_csp_tes.S_csp_tes_outputs()
        var m_dot_cr_to_tes_hot: Float64 = Float64.nan
        var m_dot_tes_hot_out: Float64 = Float64.nan
        var m_dot_pc_to_tes_cold: Float64 = Float64.nan
        var m_dot_tes_cold_out: Float64 = Float64.nan
        var m_dot_field_to_cycle: Float64 = Float64.nan
        var m_dot_cycle_to_field: Float64 = Float64.nan
        if self.ms_params.tanks_in_parallel:
            if m_dot_field >= m_dot_cycle:
                m_dot_cr_to_tes_hot = m_dot_field - m_dot_cycle
                m_dot_tes_hot_out = 0.0
                m_dot_pc_to_tes_cold = 0.0
                m_dot_tes_cold_out = m_dot_cr_to_tes_hot
                m_dot_field_to_cycle = m_dot_cycle
                m_dot_cycle_to_field = m_dot_cycle
            else:
                m_dot_cr_to_tes_hot = 0.0
                m_dot_tes_hot_out = m_dot_cycle - m_dot_field
                m_dot_pc_to_tes_cold = m_dot_tes_hot_out
                m_dot_tes_cold_out = 0.0
                m_dot_field_to_cycle = m_dot_field
                m_dot_cycle_to_field = m_dot_field
        else:
            if self.ms_params.m_is_hx:
                raise C_csp_exception("Serial operation of C_csp_two_tank_tes not available if there is a storage HX")
            m_dot_cr_to_tes_hot = m_dot_field
            m_dot_tes_hot_out = m_dot_cycle
            m_dot_pc_to_tes_cold = m_dot_cycle
            m_dot_tes_cold_out = m_dot_field
            m_dot_field_to_cycle = 0.0
            m_dot_cycle_to_field = 0.0
        var q_dot_heater: Float64 = Float64.nan
        var m_dot_cold_tank_to_hot_tank: Float64 = Float64.nan
        var W_dot_rhtf_pump: Float64 = Float64.nan
        var q_dot_loss: Float64 = Float64.nan
        var q_dot_dc_to_htf: Float64 = Float64.nan
        var q_dot_ch_from_htf: Float64 = Float64.nan
        var T_hot_ave: Float64 = Float64.nan
        var T_cold_ave: Float64 = Float64.nan
        var T_hot_final: Float64 = Float64.nan
        var T_cold_final: Float64 = Float64.nan
        if self.ms_params.tanks_in_parallel:
            if m_dot_field >= m_dot_cycle:
                T_cycle_htf_in_hot = T_field_htf_out_hot
                var m_dot_tes_ch: Float64 = m_dot_field - m_dot_cycle
                var T_htf_tes_cold: Float64 = Float64.nan
                var ch_solved: Bool = self.charge(timestep, T_amb, m_dot_tes_ch, T_field_htf_out_hot, T_htf_tes_cold,
                    q_dot_heater, m_dot_cold_tank_to_hot_tank, W_dot_rhtf_pump, q_dot_loss, q_dot_dc_to_htf, q_dot_ch_from_htf,
                    T_hot_ave, T_cold_ave, T_hot_final, T_cold_final)
                if not ch_solved:
                    return -3
                if m_dot_field == 0.0:
                    T_field_htf_in_cold = T_htf_tes_cold
                else:
                    T_field_htf_in_cold = (m_dot_tes_ch * T_htf_tes_cold + m_dot_cycle * T_cycle_htf_out_cold) / m_dot_field
            else:
                T_field_htf_in_cold = T_cycle_htf_out_cold
                var m_dot_tes_dc: Float64 = m_dot_cycle - m_dot_field
                var T_htf_tes_hot: Float64 = Float64.nan
                var is_tes_success: Bool = self.discharge(timestep, T_amb, m_dot_tes_dc, T_cycle_htf_out_cold, T_htf_tes_hot,
                    q_dot_heater, m_dot_cold_tank_to_hot_tank, W_dot_rhtf_pump, q_dot_loss, q_dot_dc_to_htf, q_dot_ch_from_htf,
                    T_hot_ave, T_cold_ave, T_hot_final, T_cold_final)
                m_dot_cold_tank_to_hot_tank *= -1.0
                if not is_tes_success:
                    return -4
                T_cycle_htf_in_hot = (m_dot_tes_dc * T_htf_tes_hot + m_dot_field * T_field_htf_out_hot) / m_dot_cycle
        else:
            if self.ms_params.m_is_hx:
                raise C_csp_exception("C_csp_two_tank_tes::discharge_decoupled not available if there is a storage HX")
            var q_dot_ch_est: Float64 = Float64.nan
            var m_dot_tes_ch_max: Float64 = Float64.nan
            var T_cold_to_field_est: Float64 = Float64.nan
            charge_avail_est(T_field_htf_out_hot, timestep, q_dot_ch_est, m_dot_tes_ch_max, T_cold_to_field_est)
            if m_dot_field > m_dot_cycle and max(1e-4, (m_dot_field - m_dot_cycle)) > 1.0001 * max(1e-4, m_dot_tes_ch_max):
                q_dot_heater = Float64.nan
                m_dot_cold_tank_to_hot_tank = Float64.nan
                W_dot_rhtf_pump = Float64.nan
                q_dot_loss = Float64.nan
                q_dot_dc_to_htf = Float64.nan
                q_dot_ch_from_htf = Float64.nan
                T_hot_ave = Float64.nan
                T_cold_ave = Float64.nan
                T_hot_final = Float64.nan
                T_cold_final = Float64.nan
                return -1
            var q_dot_dc_est: Float64 = Float64.nan
            var m_dot_tes_dc_max: Float64 = Float64.nan
            var T_hot_to_pc_est: Float64 = Float64.nan
            discharge_avail_est(T_cycle_htf_out_cold, timestep, q_dot_dc_est, m_dot_tes_dc_max, T_hot_to_pc_est)
            if m_dot_cycle > m_dot_field and max(1e-4, (m_dot_cycle - m_dot_field)) > 1.0001 * max(1e-4, m_dot_tes_dc_max):
                q_dot_heater = Float64.nan
                m_dot_cold_tank_to_hot_tank = Float64.nan
                W_dot_rhtf_pump = Float64.nan
                q_dot_loss = Float64.nan
                q_dot_dc_to_htf = Float64.nan
                q_dot_ch_from_htf = Float64.nan
                T_hot_ave = Float64.nan
                T_cold_ave = Float64.nan
                T_hot_final = Float64.nan
                T_cold_final = Float64.nan
                return -2
            m_dot_cold_tank_to_hot_tank = 0.0
            var q_heater_hot: Float64 = Float64.nan
            var q_dot_loss_hot: Float64 = Float64.nan
            var q_heater_cold: Float64 = Float64.nan
            var q_dot_loss_cold: Float64 = Float64.nan
            self.mc_hot_tank.energy_balance(timestep, m_dot_field, m_dot_cycle, T_field_htf_out_hot, T_amb, T_cycle_htf_in_hot, q_heater_hot, q_dot_loss_hot)
            self.mc_cold_tank.energy_balance(timestep, m_dot_cycle, m_dot_field, T_cycle_htf_out_cold, T_amb, T_field_htf_in_cold, q_heater_cold, q_dot_loss_cold)
            q_dot_heater = q_heater_cold + q_heater_hot
            var m_dot_tes_abs_net: Float64 = fabs(m_dot_cycle - m_dot_field)
            W_dot_rhtf_pump = 0.0
            q_dot_loss = q_dot_loss_cold + q_dot_loss_hot
            q_dot_ch_from_htf = 0.0
            T_hot_ave = T_cycle_htf_in_hot
            T_cold_ave = T_field_htf_in_cold
            T_hot_final = self.mc_hot_tank.get_m_T_calc()
            T_cold_final = self.mc_cold_tank.get_m_T_calc()
            var q_dot_tes_net_discharge: Float64 = self.m_cp_field_avg * (m_dot_tes_hot_out * T_hot_ave + m_dot_tes_cold_out * T_cold_ave - m_dot_cr_to_tes_hot * T_field_htf_out_hot - m_dot_pc_to_tes_cold * T_cycle