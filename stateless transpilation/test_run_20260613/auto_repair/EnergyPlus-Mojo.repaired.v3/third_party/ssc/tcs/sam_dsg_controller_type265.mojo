# /**
# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# */

from tcstype import *
from sam_csp_util import *
from direct_steam_receivers import *
from water_properties import *

# enum constants
var P_fossil_mode: Int = 0
var P_q_pb_design: Int = 1
var P_q_aux_max: Int = 2
var P_lhv_eff: Int = 3
var P_h_tower: Int = 4
var P_n_panels: Int = 5
var P_flowtype: Int = 6
var P_d_rec: Int = 7
var P_q_rec_des: Int = 8
var P_f_rec_min: Int = 9
var P_rec_qf_delay: Int = 10
var P_rec_su_delay: Int = 11
var P_f_pb_cutoff: Int = 12
var P_f_pb_sb: Int = 13
var P_t_standby_ini: Int = 14
var P_x_b_target: Int = 15
var P_eta_rec_pump: Int = 16
var P_P_hp_in_des: Int = 17
var P_P_hp_out_des: Int = 18
var P_f_mdotrh_des: Int = 19
var P_p_cycle_design: Int = 20
var P_ct: Int = 21
var P_T_amb_des: Int = 22
var P_dT_cw_ref: Int = 23
var P_T_approach: Int = 24
var P_T_ITD_des: Int = 25
var P_hl_ffact: Int = 26
var P_h_boiler: Int = 27
var P_d_t_boiler: Int = 28
var P_th_t_boiler: Int = 29
var P_emis_boiler: Int = 30
var P_abs_boiler: Int = 31
var P_mat_boiler: Int = 32
var P_h_sh: Int = 33
var P_d_sh: Int = 34
var P_th_sh: Int = 35
var P_emis_sh: Int = 36
var P_abs_sh: Int = 37
var P_mat_sh: Int = 38
var P_T_sh_out_des: Int = 39
var P_h_rh: Int = 40
var P_d_rh: Int = 41
var P_th_rh: Int = 42
var P_emis_rh: Int = 43
var P_abs_rh: Int = 44
var P_mat_rh: Int = 45
var P_T_rh_out_des: Int = 46
var P_cycle_max_frac: Int = 47
var P_A_sf: Int = 48
var P_ffrac: Int = 49
var P_n_flux_x: Int = 50
var P_n_flux_y: Int = 51
var I_azimuth: Int = 52
var I_zenith: Int = 53
var I_I_bn: Int = 54
var I_T_amb: Int = 55
var I_v_wind_10: Int = 56
var I_P_atm: Int = 57
var I_T_dp: Int = 58
var I_field_eff: Int = 59
var I_P_b_in: Int = 60
var I_f_mdotrh: Int = 61
var I_P_hp_out: Int = 62
var I_T_hp_out: Int = 63
var I_T_rh_target: Int = 64
var I_T_fw: Int = 65
var I_P_cond: Int = 66
var I_TOUPeriod: Int = 67
var I_flux_map: Int = 68
var O_T_fw: Int = 69
var O_T_b_in: Int = 70
var O_T_boil: Int = 71
var O_P_b_in: Int = 72
var O_P_b_out: Int = 73
var O_P_drop_b: Int = 74
var O_m_dot_b: Int = 75
var O_eta_b: Int = 76
var O_q_b_conv: Int = 77
var O_q_b_rad: Int = 78
var O_q_b_abs: Int = 79
var O_T_max_b_surf: Int = 80
var O_m_dot_sh: Int = 81
var O_P_sh_out: Int = 82
var O_dP_sh: Int = 83
var O_eta_sh: Int = 84
var O_q_sh_conv: Int = 85
var O_q_sh_rad: Int = 86
var O_q_sh_abs: Int = 87
var O_T_max_sh_surf: Int = 88
var O_v_sh_max: Int = 89
var O_f_mdot_rh: Int = 90
var O_P_rh_in: Int = 91
var O_T_rh_in: Int = 92
var O_P_rh_out: Int = 93
var O_T_rh_out: Int = 94
var O_dP_rh: Int = 95
var O_eta_rh: Int = 96
var O_T_max_rh_surf: Int = 97
var O_v_rh_max: Int = 98
var O_q_rh_conv: Int = 99
var O_q_rh_rad: Int = 100
var O_q_rh_abs: Int = 101
var O_q_inc_full: Int = 102
var O_q_inc_actual: Int = 103
var O_defocus: Int = 104
var O_field_eta_adj: Int = 105
var O_q_abs_rec: Int = 106
var O_q_conv_rec: Int = 107
var O_q_rad_rec: Int = 108
var O_q_abs_less_rad: Int = 109
var O_q_therm_in_rec: Int = 110
var O_eta_rec: Int = 111
var O_W_dot_boost: Int = 112
var O_m_dot_aux: Int = 113
var O_q_aux: Int = 114
var O_q_aux_fuel: Int = 115
var O_standby_control: Int = 116
var O_f_timestep: Int = 117
var O_m_dot_toPB: Int = 118
var N_MAX: Int = 119

# sam_dsg_controller_type265_variables array - we assume tcsvarinfo is defined elsewhere
# We will not replicate the array here; the original macro TCS_IMPLEMENT_TYPE uses it.
# For simplicity, we'll just have the class.

class sam_dsg_controller_type265(tcstypeinterface):
    var m_tol_T_rh: Float64
    var m_tol_T_sh_base: Float64
    var m_tol_T_sh_high: Float64
    var m_bracket_tol: Float64
    var dsg_rec: C_DSG_macro_receiver
    var boiler: C_DSG_Boiler
    var superheater: C_DSG_Boiler
    var reheater: C_DSG_Boiler
    var m_fossil_mode: Int
    var m_q_pb_design: Float64
    var m_q_aux_max: Float64
    var m_lhv_eff: Float64
    var m_h_tower: Float64
    var m_q_rec_des: Float64
    var m_f_rec_min: Float64
    var m_rec_qf_delay: Float64
    var m_rec_su_delay: Float64
    var m_f_pb_cutoff: Float64
    var m_f_pb_sb: Float64
    var m_t_standby_ini: Float64
    var m_x_b_target: Float64
    var m_eta_rec_pump: Float64
    var m_P_hp_in_des: Float64
    var m_P_hp_out_des: Float64
    var m_f_mdotrh_des: Float64
    var m_p_cycle_design: Float64
    var m_ct: Float64
    var m_T_amb_des: Float64
    var m_dT_cw_ref: Float64
    var m_T_approach: Float64
    var m_T_ITD_des: Float64
    var m_h_sh: Float64
    var m_d_sh: Float64
    var m_th_sh: Float64
    var m_emis_sh: Float64
    var m_abs_sh: Float64
    var m_mat_sh: Float64
    var m_T_sh_out_des: Float64
    var m_h_rh: Float64
    var m_d_rh: Float64
    var m_th_rh: Float64
    var m_emis_rh: Float64
    var m_abs_rh: Float64
    var m_mat_rh: Float64
    var m_T_rh_out_des: Float64
    var m_cycle_max_frac: Float64
    var m_A_sf: Float64
    var m_ffrac: Pointer[Float64]
    var m_numtou: Int
    var m_n_flux_x: Int
    var m_n_flux_y: Int
    var m_i_flux_map: Pointer[Float64]
    var m_q_rec_min: Float64
    var m_q_pb_min: Float64
    var m_q_sb_min: Float64
    var m_eta_des: Float64
    var m_P_b_in_min: Float64
    var m_P_hp_out_min: Float64
    var m_high_pres_count: Int
    var m_eta_lin_approx: Bool
    var m_q_low_set: Bool
    var m_q_high_set: Bool
    var m_azimuth: Float64
    var m_zenith: Float64
    var m_I_bn: Float64
    var m_T_amb: Float64
    var m_P_atm: Float64
    var m_hour: Float64
    var m_T_dp: Float64
    var m_touperiod: Int
    var m_field_eff: Float64
    var m_h_total: Float64
    var m_v_wind: Float64
    var m_T_sky: Float64
    var m_q_aux: Float64
    var m_m_dot_aux: Float64
    var m_defocus: Float64
    var m_df_flag: Bool
    var m_flux_in: matrix_t[Float64]
    var m_q_inc_base: matrix_t[Float64]
    var m_q_inc: matrix_t[Float64]
    var m_q_inc_rh: matrix_t[Float64]
    var m_q_inc_b: matrix_t[Float64]
    var m_q_inc_sh: matrix_t[Float64]
    var m_msg: String
    var m_success: Bool
    var m_q_total: Float64
    var m_A_panel: Float64
    var m_q_total_df: Float64
    var m_eta_b_high: Float64
    var m_eta_b_low: Float64
    var m_eta_sh_high: Float64
    var m_eta_sh_low: Float64
    var m_eta_rh_high: Float64
    var m_eta_rh_low: Float64
    var m_q_total_high: Float64
    var m_q_total_low: Float64
    var m_eta_b_ref: Float64
    var m_eta_sh_ref: Float64
    var m_eta_rh_ref: Float64
    var m_mguessmult: Float64
    var m_q_b_des_sp: Float64
    var m_q_sh_des_sp: Float64
    var m_q_rh_des_sp: Float64
    var m_m_dot_ref: Float64
    var m_m_dot_des: Float64
    var m_m_dot_ND: Float64
    var m_Psat_des: Float64
    var m_deltaT_fw_des: Float64
    var m_h_sh_in_ref: Float64
    var m_T_boil_pred: Float64
    var m_s_sh_out_ref: Float64
    var m_h_lp_isen_ref: Float64
    var m_h_rh_in_ref: Float64
    var m_h_sh_out_ref: Float64
    var m_rho_hp_out: Float64
    var m_dp_rh_up: Float64
    var m_P_rh_in: Float64
    var m_h_rh_out_ref: Float64
    var m_h_fw: Float64
    var m_q_pb_max: Float64
    var m_m_dot_guess: Float64
    var m_f_rh: Float64
    var m_f_b: Float64
    var m_P_sh_out_min: Float64
    var m_P_rh_out_min: Float64
    var m_b_EB_count: Int
    var m_h_hp_out: Float64
    var m_h_boiler: Float64
    var m_E_su_rec_prev: Float64
    var m_t_su_rec_prev: Float64
    var m_t_sb_pb_prev: Float64
    var m_E_su_rec: Float64
    var m_t_su_rec: Float64
    var m_t_sb_pb: Float64
    var m_diff_m_dot_old_ncall: Float64
    var m_diff_m_dot_out_ncall: Float64
    var m_m_dot_prev_ncall: Float64
    var m_dp_b_prev_ncall: Float64
    var m_dp_sh_prev_ncall: Float64
    var m_dp_rh_prev_ncall: Float64
    var f_timestep_prev_ncall: Float64
    var m_standby_control: Int

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.m_tol_T_rh = 0.005
        self.m_tol_T_sh_base = 0.005
        self.m_tol_T_sh_high = 0.03
        self.m_bracket_tol = 0.001
        self.m_fossil_mode = -1
        self.m_q_pb_design = float64.nan
        self.m_q_aux_max = float64.nan
        self.m_lhv_eff = float64.nan
        self.m_h_tower = float64.nan
        self.m_q_rec_des = float64.nan
        self.m_f_rec_min = float64.nan
        self.m_rec_qf_delay = float64.nan
        self.m_rec_su_delay = float64.nan
        self.m_f_pb_cutoff = float64.nan
        self.m_f_pb_sb = float64.nan
        self.m_t_standby_ini = float64.nan
        self.m_x_b_target = float64.nan
        self.m_eta_rec_pump = float64.nan
        self.m_P_hp_in_des = float64.nan
        self.m_P_hp_out_des = float64.nan
        self.m_f_mdotrh_des = float64.nan
        self.m_p_cycle_design = float64.nan
        self.m_ct = float64.nan
        self.m_T_amb_des = float64.nan
        self.m_dT_cw_ref = float64.nan
        self.m_T_approach = float64.nan
        self.m_T_ITD_des = float64.nan
        self.m_h_sh = float64.nan
        self.m_d_sh = float64.nan
        self.m_th_sh = float64.nan
        self.m_emis_sh = float64.nan
        self.m_abs_sh = float64.nan
        self.m_mat_sh = float64.nan
        self.m_T_sh_out_des = float64.nan
        self.m_h_rh = float64.nan
        self.m_d_rh = float64.nan
        self.m_th_rh = float64.nan
        self.m_emis_rh = float64.nan
        self.m_abs_rh = float64.nan
        self.m_mat_rh = float64.nan
        self.m_T_rh_out_des = float64.nan
        self.m_cycle_max_frac = float64.nan
        self.m_A_sf = float64.nan
        self.m_ffrac = Pointer[Float64]()
        self.m_numtou = -1
        self.m_q_rec_min = float64.nan
        self.m_q_pb_min = float64.nan
        self.m_q_sb_min = float64.nan
        self.m_eta_des = float64.nan
        self.m_P_b_in_min = float64.nan
        self.m_P_hp_out_min = float64.nan
        self.m_high_pres_count = -1
        self.m_eta_lin_approx = False
        self.m_q_low_set = False
        self.m_q_high_set = False
        self.m_azimuth = float64.nan
        self.m_zenith = float64.nan
        self.m_I_bn = float64.nan
        self.m_T_amb = float64.nan
        self.m_P_atm = float64.nan
        self.m_hour = float64.nan
        self.m_T_dp = float64.nan
        self.m_touperiod = -1
        self.m_field_eff = float64.nan
        self.m_h_total = float64.nan
        self.m_v_wind = float64.nan
        self.m_T_sky = float64.nan
        self.m_q_aux = float64.nan
        self.m_m_dot_aux = float64.nan
        self.m_defocus = float64.nan
        self.m_df_flag = False
        self.m_success = False
        self.m_q_total = float64.nan
        self.m_A_panel = float64.nan
        self.m_q_total_df = float64.nan
        self.m_eta_b_high = float64.nan
        self.m_eta_b_low = float64.nan
        self.m_eta_sh_high = float64.nan
        self.m_eta_sh_low = float64.nan
        self.m_eta_rh_high = float64.nan
        self.m_eta_rh_low = float64.nan
        self.m_q_total_high = float64.nan
        self.m_q_total_low = float64.nan
        self.m_eta_b_ref = float64.nan
        self.m_eta_sh_ref = float64.nan
        self.m_eta_rh_ref = float64.nan
        self.m_mguessmult = float64.nan
        self.m_q_b_des_sp = float64.nan
        self.m_q_sh_des_sp = float64.nan
        self.m_q_rh_des_sp = float64.nan
        self.m_m_dot_ref = float64.nan
        self.m_m_dot_des = float64.nan
        self.m_m_dot_ND = float64.nan
        self.m_Psat_des = float64.nan
        self.m_deltaT_fw_des = float64.nan
        self.m_h_sh_in_ref = float64.nan
        self.m_T_boil_pred = float64.nan
        self.m_s_sh_out_ref = float64.nan
        self.m_h_lp_isen_ref = float64.nan
        self.m_h_rh_in_ref = float64.nan
        self.m_h_sh_out_ref = float64.nan
        self.m_rho_hp_out = float64.nan
        self.m_dp_rh_up = float64.nan
        self.m_P_rh_in = float64.nan
        self.m_h_rh_out_ref = float64.nan
        self.m_h_fw = float64.nan
        self.m_q_pb_max = float64.nan
        self.m_m_dot_guess = float64.nan
        self.m_f_rh = float64.nan
        self.m_f_b = float64.nan
        self.m_P_sh_out_min = float64.nan
        self.m_P_rh_out_min = float64.nan
        self.m_b_EB_count = -1
        self.m_h_hp_out = float64.nan
        self.m_h_boiler = float64.nan
        self.m_E_su_rec_prev = float64.nan
        self.m_t_su_rec_prev = float64.nan
        self.m_t_sb_pb_prev = float64.nan
        self.m_E_su_rec = float64.nan
        self.m_t_su_rec = float64.nan
        self.m_t_sb_pb = float64.nan
        self.m_diff_m_dot_old_ncall = float64.nan
        self.m_diff_m_dot_out_ncall = float64.nan
        self.m_m_dot_prev_ncall = float64.nan
        self.m_dp_b_prev_ncall = float64.nan
        self.m_dp_sh_prev_ncall = float64.nan
        self.m_dp_rh_prev_ncall = float64.nan
        self.f_timestep_prev_ncall = float64.nan
        self.m_standby_control = -1
        self.m_n_flux_x = 0
        self.m_n_flux_y = 0

    def __del__(owned self):

    def init(inout self) -> Int:
        self.m_fossil_mode = Int(self.value(P_fossil_mode))
        self.m_q_pb_design = self.value(P_q_pb_design) * 1.0E6
        self.m_q_aux_max = self.value(P_q_aux_max) * 1.0E6
        self.m_lhv_eff = self.value(P_lhv_eff)
        self.m_h_tower = self.value(P_h_tower)
        var n_panels_local: Int = Int(self.value(P_n_panels))
        var flowtype_local: Int = Int(self.value(P_flowtype))
        self.m_n_flux_x = Int(self.value(P_n_flux_x))
        self.m_n_flux_y = Int(self.value(P_n_flux_y))
        self.m_q_inc_base.resize(n_panels_local)
        self.m_q_inc_base.fill(0.0)
        self.m_q_inc.resize(n_panels_local)
        self.m_q_inc.fill(0.0)
        self.m_q_inc_rh.resize(n_panels_local)
        self.m_q_inc_rh.fill(0.0)
        self.m_q_inc_b.resize(n_panels_local)
        self.m_q_inc_sh.resize(n_panels_local)
        var d_rec: Float64 = self.value(P_d_rec)
        var per_rec: Float64 = CSP.pi * d_rec
        self.m_q_rec_des = self.value(P_q_rec_des) * 1.0E6
        self.m_f_rec_min = self.value(P_f_rec_min)
        self.m_q_rec_min = self.m_q_rec_des * self.m_f_rec_min
        self.m_rec_qf_delay = self.value(P_rec_qf_delay)
        self.m_rec_su_delay = self.value(P_rec_su_delay)
        self.m_f_pb_cutoff = self.value(P_f_pb_cutoff)
        self.m_q_pb_min = self.m_q_pb_design * self.m_f_pb_cutoff
        self.m_f_pb_sb = self.value(P_f_pb_sb)
        self.m_q_sb_min = self.m_q_pb_design * self.m_f_pb_sb
        self.m_t_standby_ini = self.value(P_t_standby_ini)
        self.m_x_b_target = self.value(P_x_b_target)
        self.m_eta_rec_pump = self.value(P_eta_rec_pump)
        self.m_P_hp_in_des = self.value(P_P_hp_in_des) * 1.0E2
        self.m_P_hp_out_des = self.value(P_P_hp_out_des) * 1.0E2
        if self.m_P_hp_in_des > 18000.0 or self.m_P_hp_out_des > 18000.0:
            self.message(TCS_ERROR, "The design cycle pressure(s) are greater than the 180 bar limit")
            return -1
        self.m_f_mdotrh_des = self.value(P_f_mdotrh_des)
        if self.m_f_mdotrh_des > 1.0:
            self.message(TCS_ERROR, "The design reheat mass flow rate fraction, %lg, must be less than or equal to 1.0", self.m_f_mdotrh_des)
            return -1
        if self.m_f_mdotrh_des < 0.5:
            self.message(TCS_ERROR, "For this model, the design reheat mass flow rate fraction, %lg, must be greater than or equal to 0.5", self.m_f_mdotrh_des)
        self.m_p_cycle_design = self.value(P_p_cycle_design) * 1.E3
        self.m_eta_des = self.m_p_cycle_design * 1000.0 / self.m_q_pb_design
        self.m_ct = self.value(P_ct)
        self.m_T_amb_des = self.value(P_T_amb_des) + 273.15
        self.m_dT_cw_ref = self.value(P_dT_cw_ref)
        self.m_T_approach = self.value(P_T_approach)
        self.m_T_ITD_des = self.value(P_T_ITD_des)
        self.m_P_b_in_min = 0.5 * self.m_P_hp_in_des
        self.m_P_hp_out_min = 0.5 * self.m_P_hp_out_des
        var hl_ffact: Float64 = self.value(P_hl_ffact)
        self.m_h_boiler = self.value(P_h_boiler)
        var d_t_boiler: Float64 = self.value(P_d_t_boiler)
        var th_t_boiler: Float64 = self.value(P_th_t_boiler)
        var emis_boiler: Float64 = self.value(P_emis_boiler)
        var mat_boiler: Float64 = self.value(P_mat_boiler)
        var th_fin: Float64 = 0.0
        var l_fin: Float64 = 0.0
        var emis_fin: Float64 = 0.0
        var mat_fin: Float64 = 0.0
        if not self.dsg_rec.Initialize_Receiver(n_panels_local, d_rec, per_rec, hl_ffact, flowtype_local, False, 0, 0.0):
            self.message(TCS_ERROR, "Receiver initialization failed")
            return -1
        if not self.boiler.Initialize_Boiler(self.dsg_rec, self.m_h_boiler, d_t_boiler, th_t_boiler, emis_boiler, mat_boiler, 0.0, th_fin, l_fin, emis_fin, mat_fin, False):
            self.message(TCS_ERROR, "Boiler initialization failed")
            return -1
        self.m_T_sh_out_des = self.value(P_T_sh_out_des) + 273.15
        self.m_h_sh = self.value(P_h_sh)
        self.m_d_sh = self.value(P_d_sh)
        self.m_th_sh = self.value(P_th_sh)
        self.m_emis_sh = self.value(P_emis_sh)
        self.m_abs_sh = self.value(P_abs_sh)
        self.m_mat_sh = self.value(P_mat_sh)
        var h_sh_max: Float64 = 4658519.0
        if not self.superheater.Initialize_Boiler(self.dsg_rec, self.m_h_sh, self.m_d_sh, self.m_th_sh, self.m_emis_sh, self.m_mat_sh, h_sh_max, 0.0, 0.0, 0.0, 0.0, False):
            self.message(TCS_ERROR, "Superheater initialization failed")
            return -1
        self.m_T_rh_out_des = self.value(P_T_rh_out_des) + 273.15
        self.m_h_rh = self.value(P_h_rh)
        self.m_d_rh = self.value(P_d_rh)
        self.m_th_rh = self.value(P_th_rh)
        self.m_emis_rh = self.value(P_emis_rh)
        self.m_abs_rh = self.value(P_abs_rh)
        self.m_mat_rh = self.value(P_mat_rh)
        var h_rh_max: Float64 = 4658519.0
        if not self.reheater.Initialize_Boiler(self.dsg_rec, self.m_h_rh, self.m_d_rh, self.m_th_rh, self.m_emis_rh, self.m_mat_rh, h_rh_max, 0.0, 0.0, 0.0, 0.0, False):
            self.message(TCS_ERROR, "Reheater initialization failed")
            return -1
        self.m_h_total = self.m_h_boiler + self.m_h_sh + self.m_h_rh
        self.m_A_panel = self.m_h_total * per_rec / Float64(n_panels_local)
        self.m_cycle_max_frac = self.value(P_cycle_max_frac)
        self.m_A_sf = self.value(P_A_sf)
        self.m_q_pb_max = self.m_cycle_max_frac * self.m_q_pb_design
        self.m_ffrac = self.value(P_ffrac, &self.m_numtou)
        var wp: water_state
        water_TP(self.m_T_sh_out_des, self.m_P_hp_in_des, &wp)
        var h_hp_in_des: Float64 = wp.enth
        var s_hp_in_des: Float64 = wp.entr
        var rho_hp_in_des: Float64 = wp.dens
        water_PS(self.m_P_hp_out_des, s_hp_in_des, &wp)
        var h_hp_out_isen: Float64 = wp.enth
        var h_hp_out_des: Float64 = h_hp_in_des - (h_hp_in_des - h_hp_out_isen) * 0.88
        water_PH(self.m_P_hp_out_des, h_hp_out_des, &wp)
        water_TP(self.m_T_rh_out_des, self.m_P_hp_out_des, &wp)
        var h_rh_out_des: Float64 = wp.enth
        var s_rh_out_des: Float64 = wp.entr
        var rho_lp_in_des: Float64 = wp.dens
        if self.m_ct == 1:
            water_TQ(self.m_dT_cw_ref + 3.0 + self.m_T_approach + self.m_T_amb_des, 0.0, &wp)
        elif self.m_ct == 2 or self.m_ct == 3:
            water_TQ(self.m_T_ITD_des + self.m_T_amb_des, 0.0, &wp)
        self.m_Psat_des = wp.pres
        water_PS(self.m_Psat_des, s_rh_out_des, &wp)
        var h_lp_out_isen: Float64 = wp.enth
        var h_lp_out_des: Float64 = h_rh_out_des - (h_rh_out_des - h_lp_out_isen) * 0.88
        water_PQ(self.m_P_hp_in_des, 1.0, &wp)
        var h_sh_in_des: Float64 = wp.enth
        var T_boil_des: Float64 = wp.temp
        self.m_m_dot_des = self.m_p_cycle_design / ((h_hp_in_des - h_hp_out_des) + self.m_f_mdotrh_des * (h_rh_out_des - h_lp_out_des))
        var q_sh_des: Float64 = (h_hp_in_des - h_sh_in_des) * self.m_m_dot_des
        var q_rh_des: Float64 = (h_rh_out_des - h_hp_out_des) * self.m_m_dot_des * self.m_f_mdotrh_des
        var q_b_des: Float64 = self.m_q_pb_design / 1.E3 - q_sh_des - q_rh_des
        var h_fw_out_des: Float64 = h_sh_in_des - q_b_des / self.m_m_dot_des
        water_PH(self.m_P_hp_in_des, h_fw_out_des, &wp)
        var T_fw_out_des: Float64 = wp.temp
        var rho_fw_out_des: Float64 = wp.dens
        self.m_q_sh_des_sp = h_hp_in_des - h_sh_in_des
        self.m_q_rh_des_sp = h_rh_out_des - h_hp_out_des
        self.m_q_b_des_sp = h_sh_in_des - h_fw_out_des
        self.m_deltaT_fw_des = T_boil_des - T_fw_out_des
        self.m_Psat_des *= 1.E3
        self.m_high_pres_count = 0
        self.m_eta_lin_approx = True
        self.m_q_low_set = False
        self.m_q_high_set = False
        self.m_E_su_rec_prev = self.m_q_rec_des * self.m_rec_qf_delay
        self.m_t_su_rec_prev = self.m_rec_su_delay
        self.m_t_sb_pb_prev = self.m_t_standby_ini
        self.m_i_flux_map = self.allocate(I_flux_map, self.m_n_flux_y, self.m_n_flux_x)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        if (self.m_standby_control > 1) and (ncall > 0):
            return 0
        # // If debugging just this type for a specific set of inputs (one timestep), set stored variables here
        # self.m_E_su_rec_prev = 0.0
        # self.m_t_su_rec_prev = 0.0
        # self.m_t_sb_pb_prev = 2.0
        # self.m_eta_lin_approx = False
        # self.m_eta_b_high = 0.92079
        # self.m_eta_b_low = 0.8474
        # self.m_q_total_high = 232006614
        # self.m_q_total_low = 114349354
        # self.m_eta_sh_high = 0.7970
        # self.m_eta_sh_low = 0.5992
        # self.m_eta_rh_high = 0.6816
        # self.m_eta_rh_low = 0.4433
        var P_b_in: Float64 = self.value(I_P_b_in) * 1.E2
        var f_mdotrh: Float64 = self.value(I_f_mdotrh)
        var P_hp_out: Float64 = self.value(I_P_hp_out) * 1.E2
        var T_hp_out: Float64 = self.value(I_T_hp_out) + 273.15
        var T_rh_target: Float64 = self.value(I_T_rh_target) + 273.15
        var T_fw: Float64 = self.value(I_T_fw) + 273.15
        var P_cond: Float64 = self.value(I_P_cond)
        self.m_touperiod = Int(self.value(I_TOUPeriod)) - 1
        var T_rh_in: Float64 = T_hp_out
        var skip_rec_calcs: Bool = False
        if not self.m_success and ncall > 0:
            skip_rec_calcs = True
        var m_dot_sh: Float64 = float64.nan
        var m_dot_rh: Float64 = float64.nan
        var dp_sh: Float64 = float64.nan
        var dp_rh: Float64 = float64.nan
        var q_therm_in_b: Float64 = float64.nan
        var q_therm_in_sh: Float64 = float64.nan
        var q_therm_in_rh: Float64 = float64.nan
        var q_therm_in_rec: Float64 = float64.nan
        var deltaP1: Float64 = float64.nan
        var W_dot_fw: Float64 = float64.nan
        var W_dot_boost: Float64 = float64.nan
        var eta_rh: Float64 = float64.nan
        var eta_sh: Float64 = float64.nan
        var eta_b: Float64 = float64.nan
        var h_fw_Jkg: Float64 = float64.nan
        var P_sh_in: Float64 = float64.nan
        var P_hp_in: Float64 = float64.nan
        var P_lp_in: Float64 = float64.nan
        var q_boiler_abs: Float64 = float64.nan
        var q_sh_abs: Float64 = float64.nan
        var q_rh_abs: Float64 = float64.nan
        var rho_fw: Float64 = float64.nan
        var T_in: Float64 = float64.nan
        var P_b_out: Float64 = float64.nan
        var T_boil: Float64 = float64.nan
        var h_hp_in: Float64 = float64.nan
        var h_lp_in: Float64 = float64.nan
        var h_rh_in: Float64 = float64.nan
        var dp_b: Float64 = 0.0
        var P_sh_out_var: Float64 = 0.0
        var P_rh_out: Float64 = 0.0
        var n_flux_y: Int
        var n_flux_x: Int
        self.m_i_flux_map = self.value(I_flux_map, &n_flux_y, &n_flux_x)
        if n_flux_y > 1:
            self.message(TCS_WARNING, "The Direct Steam External Receiver (Type265) model does not currently support 2-dimensional flux maps. The flux profile in the vertical dimension will be averaged. NY=%d", n_flux_y)
        self.m_flux_in.resize(n_flux_x)
        var wp: water_state
        while True:
            skip_rec_calcs = True
            var df_upflag: Bool = False
            var df_lowflag: Bool = False
            if ncall == 0:
                self.m_azimuth = self.value(I_azimuth)
                self.m_zenith = self.value(I_zenith)
                self.m_I_bn = self.value(I_I_bn)
                self.m_T_amb = self.value(I_T_amb) + 273.15
                var v_wind_10: Float64 = self.value(I_v_wind_10)
                self.m_P_atm = self.value(I_P_atm) * 100.0
                self.m_hour = time / 3600.0
                self.m_T_dp = self.value(I_T_dp) + 273.15
                self.m_field_eff = self.value(I_field_eff)
                self.m_T_sky = CSP.skytemp(self.m_T_amb, self.m_T_dp, self.m_hour)
                self.m_v_wind = log((self.m_h_tower + (self.m_h_total / 2.0) / 2.0) / 0.003) / log(10.0 / 0.003) * v_wind_10
                self.m_E_su_rec = self.m_E_su_rec_prev
                self.m_t_su_rec = self.m_t_su_rec_prev
                self.m_t_sb_pb = self.m_t_sb_pb_prev
                self.m_q_aux = 0.0
                self.m_m_dot_aux = 0.0
                self.m_defocus = 1.0
                self.m_df_flag = False
                if self.m_I_bn > 150.0:
                    for j in range(n_flux_x):
                        self.m_flux_in.at(j) = 0.0
                        for i in range(n_flux_y):
                            self.m_flux_in.at(j) += self.m_i_flux_map[j * n_flux_y + i] * self.m_I_bn * self.m_field_eff * self.m_A_sf / 1000.0 / (self.m_h_total * self.dsg_rec.Get_per_rec() / Float64(n_flux_x))
                else:
                    self.m_flux_in.fill(0.0)
                    self.m_success = False
                    self.m_q_total = 0.0
                    self.m_msg = "type 265: fail at m_I_bn=" + to_string(self.m_I_bn) + " <= 1.0"
                    break
                var n_flux_x_d: Float64 = Float64(self.m_n_flux_x)
                var n_panels_local: Float64 = Float64(self.dsg_rec.Get_n_panels_rec())
                if n_panels_local >= Float64(self.m_n_flux_x):
                    for i in range(Int(n_panels_local)):
                        var ppos: Float64 = (n_flux_x_d / n_panels_local * Float64(i) + n_flux_x_d * 0.5 / n_panels_local)
                        var flo: Int = Int(math.floor(ppos))
                        var ceiling: Int = Int(math.ceil(ppos))
                        var ind: Float64 = Float64(Int((ppos - Float64(flo)) / max(Float64(ceiling - flo), 1.e-6)))
                        if ceiling > self.m_n_flux_x - 1:
                            ceiling = 0
                        var psp_field: Float64 = (ind * (self.m_flux_in.at(ceiling) - self.m_flux_in.at(flo)) + self.m_flux_in.at(flo))
                        self.m_q_inc_base.at(i) = psp_field * 1000.0
                else:
                    var back_mult: Float64 = 1.0
                    var front_mult: Float64 = 0.0
                    var index_start: Int = -1
                    var index_stop: Int = -1
                    var is_div: Bool = False
                    if self.m_n_flux_x % Int(n_panels_local) == 0:
                        is_div = True
                    for i in range(Int(n_panels_local)):
                        front_mult = 1.0 - back_mult
                        index_start = index_stop
                        if is_div:
                            index_stop = Int(Float64(self.m_n_flux_x) / n_panels_local * Float64(i + 1) - 1.0)
                        else:
                            index_stop = Int(math.ceil(Float64(Float64(self.m_n_flux_x) / n_panels_local * Float64(i + 1)))) - 1
                        if is_div:
                            back_mult = 1.0
                        else:
                            back_mult = Float64(Float64(self.m_n_flux_x) / n_panels_local * Float64(i + 1)) - Float64(Int(Float64(self.m_n_flux_x) / n_panels_local * Float64(i + 1)))
                        var sum_fracs: Float64 = 0.0
                        var sum_flux: Float64 = 0.0
                        for j in range(index_start, index_stop + 1):
                            if j == index_start:
                                sum_fracs += front_mult
                                if j == -1:
                                    sum_flux += front_mult * self.m_flux_in.at(self.m_n_flux_x - 1)
                                else:
                                    sum_flux += front_mult * self.m_flux_in.at(j)
                            elif j == index_stop:
                                sum_fracs += back_mult
                                if j == 12:
                                    sum_flux += back_mult * self.m_flux_in.at(0)
                                else:
                                    sum_flux += back_mult * self.m_flux_in.at(j)
                            else:
                                sum_fracs += 1.0
                                sum_flux += self.m_flux_in.at(j)
                        self.m_q_inc_base.at(i) = sum_flux * 1000.0 / sum_fracs
                var sum_q_inc: Float64 = 0.0
                for i in range(Int(n_panels_local)):
                    sum_q_inc += self.m_q_inc_base.at(i)
                self.m_q_total = sum_q_inc * self.m_A_panel
                if self.m_q_total < self.m_q_rec_min:
                    self.m_success = False
                    break
                self.m_q_total_df = self.m_q_total
                self.m_mguessmult = 1.0
                if self.m_eta_lin_approx:
                    self.m_eta_b_ref = 0.86
                    self.m_eta_sh_ref = 0.78
                    self.m_eta_rh_ref = 0.55
                else:
                    self.m_eta_b_ref = min(0.99, (self.m_eta_b_high - self.m_eta_b_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total - self.m_q_total_low) + self.m_eta_b_low)
                    self.m_eta_sh_ref = min(0.99, (self.m_eta_sh_high - self.m_eta_sh_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total - self.m_q_total_low) + self.m_eta_sh_low)
                    self.m_eta_rh_ref = min(0.99, (self.m_eta_rh_high - self.m_eta_rh_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total - self.m_q_total_low) + self.m_eta_rh_low)
                self.m_m_dot_ref = (self.m_q_total / 1.E3) / (self.m_q_b_des_sp / self.m_eta_b_ref + self.m_q_sh_des_sp / self.m_eta_sh_ref + self.m_q_rh_des_sp * self.m_f_mdotrh_des / self.m_eta_rh_ref)
                self.m_m_dot_ND = min(self.m_cycle_max_frac, self.m_m_dot_ref / self.m_m_dot_des)
                P_hp_out = pow(pow(self.m_Psat_des, 2.0) + pow(self.m_m_dot_ND, 2.0) * (pow(self.m_P_hp_out_des * 1.E3, 2.0) - pow(self.m_Psat_des, 2.0)), 0.5)
                P_b_in = pow(pow(P_hp_out, 2.0) + pow(self.m_m_dot_ND, 2.0) * (pow(self.m_P_hp_in_des * 1.E3, 2.0) - pow(self.m_P_hp_out_des * 1.E3, 2.0)), 0.5)
                P_hp_out /= 1.E3
                P_b_in /= 1.E3
                P_b_in = min(19.E3, max(self.m_P_b_in_min, P_b_in))
                P_hp_out = min(19.E3, max(self.m_P_hp_out_min, P_hp_out))
                if T_rh_target == 273.15:
                    T_rh_target = self.m_T_rh_out_des
                if f_mdotrh == 0.0:
                    f_mdotrh = self.m_f_mdotrh_des
                f_mdotrh = min(1.0, f_mdotrh)
                water_PQ(P_b_in, 1.0, &wp)
                self.m_h_sh_in_ref = wp.enth
                self.m_T_boil_pred = wp.temp - 273.15
                T_fw = self.m_T_boil_pred - self.m_deltaT_fw_des + 273.15
                water_TP(self.m_T_sh_out_des, P_b_in, &wp)
                self.m_h_sh_out_ref = wp.enth
                self.m_s_sh_out_ref = wp.entr
                water_PS(P_hp_out, self.m_s_sh_out_ref, &wp)
                self.m_h_lp_isen_ref = wp.enth
                self.m_h_rh_in_ref = self.m_h_sh_out_ref - (self.m_h_sh_out_ref - self.m_h_lp_isen_ref) * 0.88
                water_PH(P_hp_out, self.m_h_rh_in_ref, &wp)
                self.m_rho_hp_out = wp.dens
                self.m_dp_rh_up = self.m_rho_hp_out * 9.81 * self.m_h_tower
                self.m_P_rh_in = P_hp_out - self.m_dp_rh_up / 1.E3
                water_PH(self.m_P_rh_in, self.m_h_rh_in_ref, &wp)
                T_rh_in = wp.temp
                water_TP(self.m_T_rh_out_des, self.m_P_rh_in, &wp)
                self.m_h_rh_out_ref = wp.enth
                water_TP(T_fw, P_b_in, &wp)
                self.m_h_fw = wp.enth
                var q_b_pred: Float64 = float64.nan
                var q_sh_pred: Float64 = float64.nan
                var q_rh_pred: Float64 = float64.nan
                var q_rec_pred_tot: Float64 = float64.nan
                for i in range(2):
                    var q_b_pred_sp: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / self.m_eta_b_ref
                    var q_sh_pred_sp: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / self.m_eta_sh_ref
                    var q_rh_pred_sp: Float64 = (self.m_h_rh_out_ref - self.m_h_rh_in_ref) * 1000.0 / self.m_eta_rh_ref
                    self.m_m_dot_ref = self.m_q_total_df / (q_b_pred_sp + q_sh_pred_sp + q_rh_pred_sp * f_mdotrh)
                    q_b_pred = q_b_pred_sp * self.m_m_dot_ref
                    q_sh_pred = q_sh_pred_sp * self.m_m_dot_ref
                    q_rh_pred = q_rh_pred_sp * self.m_m_dot_ref * f_mdotrh
                    q_rec_pred_tot = q_b_pred + q_sh_pred + q_rh_pred
                    var q_therm_in_diff: Float64 = (q_rec_pred_tot - self.m_q_pb_max) / self.m_q_pb_max
                    var break_loop: Bool = True
                    if q_therm_in_diff > 0.1 and i == 0:
                        self.m_defocus = min(1.0, self.m_defocus * self.m_q_pb_max / q_rec_pred_tot)
                        self.m_q_total_df = self.m_q_total * self.m_defocus
                        break_loop = False
                        if not self.m_eta_lin_approx:
                            self.m_eta_b_ref = (self.m_eta_b_high - self.m_eta_b_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total_df - self.m_q_total_low) + self.m_eta_b_low
                            self.m_eta_sh_ref = (self.m_eta_sh_high - self.m_eta_sh_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total_df - self.m_q_total_low) + self.m_eta_sh_low
                            self.m_eta_rh_ref = (self.m_eta_rh_high - self.m_eta_rh_low) / (self.m_q_total_high - self.m_q_total_low) * (self.m_q_total_df - self.m_q_total_low) + self.m_eta_rh_low
                        if self.m_defocus < 0.7:
                            self.m_mguessmult = 1.4
                    else:
                        break_loop = True
                    if break_loop:
                        break
                self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                self.m_f_rh = q_rh_pred / (q_b_pred + q_sh_pred + q_rh_pred)
                self.m_f_b = q_b_pred / (q_b_pred + q_sh_pred)
                P_cond = self.m_Psat_des
                self.m_P_sh_out_min = max(1.E5, P_cond)
                self.m_P_rh_out_min = max(1.E5, P_cond)
                self.m_b_EB_count = 0
            if ncall > 0:
                P_b_in = min(19.E3, P_b_in)
                water_TP(self.m_T_sh_out_des, P_b_in, &wp)
                self.m_h_sh_out_ref = wp.enth
                water_TP(T_hp_out, P_hp_out, &wp)
                self.m_rho_hp_out = wp.dens
                self.m_h_hp_out = wp.enth
                self.m_dp_rh_up = self.m_rho_hp_out * 9.81 * self.m_h_tower
                self.m_P_rh_in = P_hp_out - self.m_dp_rh_up / 1000.0
                water_PH(self.m_P_rh_in, self.m_h_hp_out, &wp)
                T_rh_in = wp.temp
                self.m_h_rh_in_ref = self.m_h_hp_out
                water_TP(T_rh_target, self.m_P_rh_in, &wp)
                self.m_h_rh_out_ref = wp.enth
            var rh_count: Int = 0
            var sh_count: Int = 0
            var boiler_count: Int = 0
            var df_count: Int = -1
            var defocus_mode: Bool = False
            eta_b = self.m_eta_b_ref
            eta_sh = self.m_eta_sh_ref
            eta_rh = self.m_eta_rh_ref
            var iter_T_rh: Int = -1
            var df_upper: Float64 = float64.nan
            var y_df_upper: Float64 = float64.nan
            var df_lower: Float64 = float64.nan
            var y_df_lower: Float64 = float64.nan
            var break_def_calcs: Bool = False
            while True:
                defocus_mode = False
                df_count += 1
                for i in range(self.dsg_rec.Get_n_panels_rec()):
                    self.m_q_inc.at(i) = self.m_defocus * self.m_q_inc_base.at(i)
                self.m_q_total_df = self.m_defocus * self.m_q_total
                if df_count > 0 and not self.m_df_flag:
                    if df_count > 10:
                        break_def_calcs = True
                        break
                    var q_b_pred_sp_outer: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                    var q_sh_pred_sp_outer: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                    var q_rh_pred_sp_outer: Float64 = (self.m_h_rh_out_ref - self.m_h_rh_in_ref) * 1000.0 / eta_rh
                    self.m_m_dot_ref = self.m_q_total_df / (q_b_pred_sp_outer + q_sh_pred_sp_outer + q_rh_pred_sp_outer)
                    self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                    var q_b_pred_outer: Float64 = q_b_pred_sp_outer * self.m_m_dot_ref
                    var q_sh_pred_outer: Float64 = q_sh_pred_sp_outer * self.m_m_dot_ref
                    var q_rh_pred_outer: Float64 = q_rh_pred_sp_outer * self.m_m_dot_ref
                    self.m_f_rh = q_rh_pred_outer / (q_b_pred_outer + q_sh_pred_outer + q_rh_pred_outer)
                    self.m_f_b = q_b_pred_outer / (q_b_pred_outer + q_sh_pred_outer)
                var diff_frh_b: Float64 = 999.0
                var diff_T_rh: Float64 = 999.0
                iter_T_rh = 0
                var rh_low_guess: Bool = False
                var rh_low_flag: Bool = False
                var rh_up_guess: Bool = False
                var rh_up_flag: Bool = False
                var f_rh_upper: Float64 = 1.0
                var f_rh_lower: Float64 = 0.0
                var rh_br_upper: Int = 0
                var rh_br_lower: Int = 0
                self.m_success = True
                var check_hxs: Bool = False
                var high_tol: Bool = True
                var fb_stuck: Int = -1
                var rh_exit: Int = -1
                var y_rh_upper: Float64 = float64.nan
                var y_rh_lower: Float64 = float64.nan
                var break_to_rh_iter: Bool = False
                var break_rec_calcs: Bool = False
                while (abs(diff_T_rh) > self.m_tol_T_rh or high_tol) and (iter_T_rh < 20):
                    iter_T_rh += 1
                    break_to_rh_iter = False
                    diff_frh_b = f_rh_upper - f_rh_lower
                    if iter_T_rh > 1:
                        if fb_stuck == 0 and rh_exit == 0:
                            var f_rh_adjust: Float64 = float64.nan
                            if high_tol:
                                high_tol = False
                                var q_b_pred_sp_inner: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                                var q_sh_pred_sp_inner: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                                var q_rh_pred_sp_inner: Float64 = (self.m_h_rh_out_ref - self.m_h_rh_in_ref) * 1000.0 / eta_rh
                                self.m_m_dot_ref = self.m_q_total_df / (q_b_pred_sp_inner + q_sh_pred_sp_inner + q_rh_pred_sp_inner * f_mdotrh)
                                self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                                var q_b_pred_inner: Float64 = q_b_pred_sp_inner * self.m_m_dot_ref
                                var q_sh_pred_inner: Float64 = q_sh_pred_sp_inner * self.m_m_dot_ref
                                var q_rh_pred_inner: Float64 = q_rh_pred_sp_inner * self.m_m_dot_ref * f_mdotrh
                                f_rh_adjust = q_rh_pred_inner / (q_b_pred_inner + q_sh_pred_inner + q_rh_pred_inner)
                                self.m_f_b = q_b_pred_inner / (q_b_pred_inner + q_sh_pred_inner)
                            elif rh_up_flag and rh_low_flag:
                                if diff_T_rh < 0.0:
                                    rh_br_upper = 3
                                    f_rh_upper = self.m_f_rh
                                    y_rh_upper = diff_T_rh
                                else:
                                    rh_br_lower = 4
                                    f_rh_lower = self.m_f_rh
                                    y_rh_lower = diff_T_rh
                                self.m_f_rh = (y_rh_upper) / (y_rh_upper - y_rh_lower) * (f_rh_lower - f_rh_upper) + f_rh_upper
                            else:
                                if diff_T_rh < 0.0:
                                    rh_br_upper = 3
                                    f_rh_upper = self.m_f_rh
                                    y_rh_upper = diff_T_rh
                                    rh_up_flag = True
                                    var q_b_pred_sp_inner: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                                    var q_sh_pred_sp_inner: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                                    var q_rh_pred_sp_inner: Float64 = (self.m_h_rh_out_ref - self.m_h_rh_in_ref) * 1000.0 / eta_rh
                                    self.m_m_dot_ref = self.m_q_total_df / (q_b_pred_sp_inner + q_sh_pred_sp_inner + q_rh_pred_sp_inner * f_mdotrh)
                                    self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                                    var q_b_pred_inner: Float64 = q_b_pred_sp_inner * self.m_m_dot_ref
                                    var q_sh_pred_inner: Float64 = q_sh_pred_sp_inner * self.m_m_dot_ref
                                    var q_rh_pred_inner: Float64 = q_rh_pred_sp_inner * self.m_m_dot_ref * f_mdotrh
                                    f_rh_adjust = q_rh_pred_inner / (q_b_pred_inner + q_sh_pred_inner + q_rh_pred_inner)
                                    self.m_f_b = q_b_pred_inner / (q_b_pred_inner + q_sh_pred_inner)
                                    if self.m_f_rh - f_rh_adjust < 0.0005:
                                        f_rh_adjust = self.m_f_rh - 0.001
                                else:
                                    rh_br_lower = 4
                                    f_rh_lower = self.m_f_rh
                                    y_rh_lower = diff_T_rh
                                    rh_low_flag = True
                                    var q_b_pred_sp_inner: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                                    var q_sh_pred_sp_inner: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                                    var q_rh_pred_sp_inner: Float64 = (self.m_h_rh_out_ref - self.m_h_rh_in_ref) * 1000.0 / eta_rh
                                    self.m_m_dot_ref = self.m_q_total_df / (q_b_pred_sp_inner + q_sh_pred_sp_inner + q_rh_pred_sp_inner * f_mdotrh)
                                    self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                                    var q_b_pred_inner: Float64 = q_b_pred_sp_inner * self.m_m_dot_ref
                                    var q_sh_pred_inner: Float64 = q_sh_pred_sp_inner * self.m_m_dot_ref
                                    var q_rh_pred_inner: Float64 = q_rh_pred_sp_inner * self.m_m_dot_ref * f_mdotrh
                                    f_rh_adjust = q_rh_pred_inner / (q_b_pred_inner + q_sh_pred_inner + q_rh_pred_inner)
                                    self.m_f_b = q_b_pred_inner / (q_b_pred_inner + q_sh_pred_inner)
                                    if f_rh_adjust - self.m_f_rh < 0.0005:
                                        f_rh_adjust = self.m_f_rh + 0.001
                                if rh_up_flag and rh_low_flag:
                                    self.m_f_rh = (y_rh_upper) / (y_rh_upper - y_rh_lower) * (f_rh_lower - f_rh_upper) + f_rh_upper
                                else:
                                    self.m_f_rh = f_rh_adjust
                        elif fb_stuck == 1 or rh_exit == 1 or rh_exit == 2:
                            if fb_stuck == 1:
                                rh_br_lower = 1
                            if rh_exit == 1:
                                rh_br_lower = 2
                            if rh_exit == 2:
                                rh_br_lower = 3
                            rh_exit = 0
                            f_rh_lower = self.m_f_rh
                            rh_low_guess = True
                            rh_low_flag = False
                            if rh_up_flag or rh_up_guess:
                                self.m_f_rh = 0.5 * f_rh_lower + 0.5 * f_rh_upper
                            else:
                                self.m_f_rh = 1.25 * self.m_f_rh
                        elif fb_stuck == 2 or rh_exit == 3:
                            if fb_stuck == 2:
                                rh_br_upper = 1
                            elif rh_exit == 3:
                                rh_br_upper = 2
                            rh_exit = 0
                            f_rh_upper = self.m_f_rh
                            rh_up_guess = True
                            rh_up_flag = False
                            if rh_low_flag or rh_low_guess:
                                self.m_f_rh = 0.5 * f_rh_lower + 0.5 * f_rh_upper
                            else:
                                self.m_f_rh = 0.75 * self.m_f_rh
                    if abs(diff_frh_b) < 0.0051 or iter_T_rh == 20:
                        if f_rh_upper < 0.01 and rh_br_lower == 0:
                            rh_br_lower = 5
                        if (rh_br_lower == 2 and rh_br_upper == 1) or \
                           (rh_br_lower == 3 and rh_br_upper == 1) or (rh_br_lower == 3 and rh_br_upper == 2) or (rh_br_lower == 3 and rh_br_upper == 3) or \
                           (rh_br_lower == 4 and rh_br_upper == 1) or (rh_br_lower == 4 and rh_br_upper == 2) or \
                           (rh_br_lower == 5 and rh_br_upper == 1):
                            self.m_success = False
                            break_rec_calcs = True
                            break
                        elif (rh_br_lower == 1 and rh_br_upper == 2) or (rh_br_lower == 1 and rh_br_upper == 3) or \
                             (rh_br_lower == 2 and rh_br_upper == 2) or (rh_br_lower == 2 and rh_br_upper == 3):
                            self.m_df_flag = True
                            self.m_defocus = max(0.5 * self.m_defocus, self.m_defocus - 0.1)
                            break_rec_calcs = True
                            break
                        elif rh_br_lower == 4 and rh_br_upper == 3 and abs(diff_frh_b) < 0.0005:
                            if diff_T_rh < 0.0:
                                self.m_f_rh = self.m_f_rh - 0.01
                                rh_low_flag = False
                                f_rh_lower = self.m_f_rh
                            else:
                                self.m_f_rh = self.m_f_rh + 0.01
                                rh_up_flag = False
                                f_rh_upper = self.m_f_rh
                    if self.m_f_rh > 1.0:
                        f_rh_lower = 1.0
                        self.m_f_rh = 1.0
                    rh_exit = 0
                    var sum_q_inc_rh: Float64 = 0.0
                    for i in range(self.dsg_rec.Get_n_panels_rec()):
                        self.m_q_inc_rh.at(i) = self.m_f_rh * self.m_q_inc.at(i) * self.m_h_total / self.m_h_rh
                        sum_q_inc_rh += self.m_q_inc_rh.at(i)
                    var q_inc_b_sh: Float64 = self.m_q_total_df - sum_q_inc_rh * (self.m_h_rh / self.m_h_total) * self.m_A_panel
                    diff_T_rh = 999.9
                    var diff_T_sh: Float64 = 999.9
                    var diff_f_bracket: Float64 = 999.9
                    var iter_T_sh: Int = 0
                    var f_upper: Float64 = 1.0
                    var f_lower: Float64 = 0.0
                    var upflag: Bool = False
                    var lowflag: Bool = False
                    var upguess: Bool = False
                    var lowguess: Bool = False
                    var br_lower: Int = 0
                    var br_upper: Int = 0
                    fb_stuck = 0
                    var tol_T_sh: Float64
                    if high_tol:
                        tol_T_sh = self.m_tol_T_sh_high
                    else:
                        tol_T_sh = self.m_tol_T_sh_base
                    var sh_exit: Int = -1
                    var boiler_exit: Int = -1
                    var y_upper: Float64 = float64.nan
                    var y_lower: Float64 = float64.nan
                    var f_adjust: Float64 = float64.nan
                    var checkflux: Bool
                    while abs(diff_T_sh) > tol_T_sh and iter_T_sh < 20:
                        iter_T_sh += 1
                        diff_f_bracket = f_upper - f_lower
                        if iter_T_sh > 1:
                            if sh_exit == 0 and boiler_exit == 0:
                                if upflag and lowflag:
                                    if diff_T_sh > 0.0:
                                        br_upper = 3
                                        f_upper = self.m_f_b
                                        y_upper = diff_T_sh
                                    else:
                                        br_lower = 3
                                        f_lower = self.m_f_b
                                        y_lower = diff_T_sh
                                    self.m_f_b = (y_upper) / (y_upper - y_lower) * (f_lower - f_upper) + f_upper
                                else:
                                    if diff_T_sh > 0.0:
                                        br_upper = 3
                                        f_upper = self.m_f_b
                                        y_upper = diff_T_sh
                                        upflag = True
                                        var q_b_pred_sp_boil: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                                        var q_sh_pred_sp_boil: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                                        self.m_m_dot_ref = q_inc_b_sh / (q_b_pred_sp_boil + q_sh_pred_sp_boil)
                                        self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                                        f_adjust = q_b_pred_sp_boil * self.m_m_dot_ref / q_inc_b_sh
                                        if self.m_f_b - f_adjust < 0.0005:
                                            f_adjust = self.m_f_b - 0.001
                                        if f_adjust < f_lower:
                                            f_adjust = 0.8 * f_lower + 0.2 * f_upper
                                    else:
                                        br_lower = 3
                                        f_lower = self.m_f_b
                                        y_lower = diff_T_sh
                                        lowflag = True
                                        var q_b_pred_sp_boil: Float64 = (self.m_h_sh_in_ref - self.m_h_fw) * 1000.0 / eta_b
                                        var q_sh_pred_sp_boil: Float64 = (self.m_h_sh_out_ref - self.m_h_sh_in_ref) * 1000.0 / eta_sh
                                        self.m_m_dot_ref = q_inc_b_sh / (q_b_pred_sp_boil + q_sh_pred_sp_boil)
                                        self.m_m_dot_guess = self.m_m_dot_ref / self.m_x_b_target
                                        f_adjust = q_b_pred_sp_boil * self.m_m_dot_ref / q_inc_b_sh
                                        if f_adjust - self.m_f_b < 0.0005:
                                            f_adjust = self.m_f_b + 0.001
                                        if f_adjust > f_upper:
                                            f_adjust = 0.8 * f_upper + 0.2 * f_lower
                                    if upflag and lowflag:
                                        self.m_f_b = y_upper / (y_upper - y_lower) * (f_lower - f_upper) + f_upper
                                    else:
                                        self.m_f_b = f_adjust
                            elif boiler_exit == 2 or sh_exit == 3:
                                if boiler_exit == 2:
                                    br_lower = 1
                                else:
                                    br_lower = 2
                                f_lower = self.m_f_b
                                lowguess = True
                                if upflag or upguess:
                                    self.m_f_b = 0.5 * f_upper + 0.5 * f_lower
                                else:
                                    self.m_f_b = self.m_f_b + 0.05
                            elif sh_exit == 1 or sh_exit == 2 or boiler_exit == 3:
                                if sh_exit == 1:
                                    br_upper = 1
                                if sh_exit == 2:
                                    br_upper = 2
                                if boiler_exit == 3:
                                    br_upper = 5
                                f_upper = self.m_f_b
                                upguess = True
                                if lowguess or lowflag:
                                    self.m_f_b = 0.5 * f_upper + 0.5 * f_lower
                                else:
                                    self.m_f_b = self.m_f_b - 0.05
                        if self.m_f_b > 1.0:
                            self.m_f_b = 1.0
                        boiler_exit = 0
                        sh_exit = 0
                        if abs(diff_f_bracket) < self.m_bracket_tol and iter_T_sh < 20:
                            if f_lower > 0.99 and br_upper == 0:
                                br_upper = 4
                            if (br_lower == 1 and br_upper == 2) or (br_lower == 1 and br_upper == 3) or (br_lower == 1 and br_upper == 4) or \
                               (br_lower == 2 and br_upper == 2) or (br_lower == 2 and br_upper == 3) or (br_lower == 2 and br_upper == 4):
                                fb_stuck = 2
                                break_to_rh_iter = True
                                break
                            elif (br_lower == 2 and br_upper == 1) or (br_lower == 2 and br_upper == 5) or \
                                 (br_lower == 3 and br_upper == 1) or (br_lower == 3 and br_upper == 5):
                                fb_stuck = 1
                                break_to_rh_iter = True
                                break
                            elif (br_lower == 1 and br_upper == 1) or (br_lower == 1 and br_upper == 5) or \
                                 (br_lower == 3 and br_upper == 2) or (br_lower == 3 and br_upper == 4):

                            elif br_lower == 3 and br_upper == 3:
                                break
                        for i in range(self.dsg_rec.Get_n_panels_rec()):
                            self.m_q_inc_b.at(i) = self.m_f_b * (1.0 - self.m_f_rh) * self.m_q_inc.at(i) * self.m_h_total / self.m_h_boiler
                            self.m_q_inc_sh.at(i) = (1.0 - self.m_f_b) * (1.0 - self.m_f_rh) * self.m_q_inc.at(i) * self.m_h_total / self.m_h_sh
                        var m_dot_lower: Float64 = 0.75 * self.m_m_dot_guess / self.m_mguessmult
                        var m_dot_upper: Float64 = 1.35 * self.m_m_dot_guess * self.m_mguessmult
                        if check_hxs:
                            checkflux = True
                            boiler_exit = 0
                            var dum1: Float64 = 0.0
                            var dum2: Float64 = 0.0
                            var dum3: Float64 = 0.0
                            var dum4: Float64 = 0.0
                            var dum5: Float64 = 0.0
                            var dum6: Float64 = 0.0
                            var dum7: Float64 = 0.0
                            var dum8: Float64 = 0.0
                            var dum9: Float64 = 0.0
                            self.boiler.Solve_Boiler(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, T_fw, P_b_in, self.m_x_b_target, self.m_m_dot_guess, m_dot_lower, m_dot_upper, checkflux, self.m_q_inc_b, boiler_exit, dum1, dum2, dum3, dum4, dum5, dum6, dum7, dum8, dum9)
                            if boiler_exit == 2:
                                continue
                            sh_exit = 0
                            water_TQ(self.m_T_boil_pred, 0.0, &wp)
                            var h_sh_in_dummy: Float64 = wp.enth
                            var P_sh_in_dummy: Float64 = wp.pres
                            self.superheater.Solve_Superheater(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, P_sh_in_dummy, 1.0, h_sh_in_dummy, 1.0, checkflux, self.m_q_inc_sh, sh_exit, 1.0, dum1, dum2, dum3, dum4, dum5)
                            if sh_exit == 2:
                                continue
                            rh_exit = 0
                            water_TP(T_hp_out, self.m_P_rh_in, &wp)
                            var h_rh_in_dummy: Float64 = wp.enth
                            self.reheater.Solve_Superheater(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, self.m_P_rh_in, 1.0, h_rh_in_dummy, 1.0, checkflux, self.m_q_inc_rh, rh_exit, 1.0, dum1, dum2, dum3, dum4, dum5)
                            if rh_exit == 2:
                                break_to_rh_iter = True
                                break
                        checkflux = False
                        boiler_exit = 0
                        boiler_count += 1
                        self.boiler.Solve_Boiler(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, T_fw, P_b_in, self.m_x_b_target, self.m_m_dot_guess, m_dot_lower, m_dot_upper, checkflux, self.m_q_inc_b, boiler_exit, eta_b, T_boil, m_dot_sh, self.m_h_fw, P_b_out, self.m_h_sh_in_ref, rho_fw, q_boiler_abs, T_in)
                        if boiler_exit > 0:
                            if boiler_exit == 1:
                                self.m_success = False
                                break_rec_calcs = True
                                break_def_calcs = True
                                break
                            if boiler_exit == 2:
                                check_hxs = True
                                continue
                            if boiler_exit == 3:
                                continue
                        self.m_m_dot_guess = m_dot_sh / self.m_x_b_target
                        dp_b = (P_b_in - P_b_out) * 1.E3
                        sh_count += 1
                        var T_sh_in: Float64 = T_boil
                        water_TQ(T_sh_in, 1.0, &wp)
                        P_sh_in = wp.pres
                        var h_sh_in: Float64 = wp.enth
                        var rho_sh_out: Float64 = 0.0
                        var h_sh_out: Float64 = 0.0
                        self.superheater.Solve_Superheater(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, P_sh_in, m_dot_sh, h_sh_in, self.m_P_sh_out_min, checkflux, self.m_q_inc_sh, sh_exit, self.m_T_sh_out_des, P_sh_out_var, eta_sh, rho_sh_out, h_sh_out, q_sh_abs)
                        if sh_exit > 0:
                            continue
                        water_TP(self.m_T_sh_out_des, P_sh_out_var, &wp)
                        self.m_h_sh_out_ref = wp.enth
                        var dp_sh_down: Float64 = rho_sh_out * CSP.grav * self.m_h_tower
                        P_hp_in = P_sh_out_var + dp_sh_down / 1.E3
                        water_PH(P_hp_in, h_sh_out, &wp)
                        var T_sh_out: Float64 = wp.temp
                        h_hp_in = h_sh_out
                        diff_T_sh = (self.m_T_sh_out_des - T_sh_out) / self.m_T_sh_out_des
                    if iter_T_sh == 20 and abs(diff_T_sh) > tol_T_sh:
                        self.m_success = False
                        break_rec_calcs = True
                        break_def_calcs = True
                    if break_rec_calcs:
                        break
                    if break_to_rh_iter:
                        continue
                    m_dot_rh = f_mdotrh * m_dot_sh
                    rh_exit = 0
                    rh_count += 1
                    var rho_rh_out: Float64 = 0.0
                    var h_rh_out: Float64 = 0.0
                    water_TP(T_rh_in, self.m_P_rh_in, &wp)
                    h_rh_in = wp.enth
                    self.reheater.Solve_Superheater(self.m_T_amb, self.m_T_sky, self.m_v_wind, self.m_P_atm, self.m_P_rh_in, m_dot_rh, h_rh_in, self.m_P_rh_out_min, checkflux, self.m_q_inc_rh, rh_exit, self.m_T_rh_out_des, P_rh_out, eta_rh, rho_rh_out, h_rh_out, q_rh_abs)
                    if rh_exit > 0:
                        continue
                    water_TP(self.m_T_rh_out_des, P_rh_out, &wp)
                    self.m_h_rh_out_ref = wp.enth
                    var dp_rh_down: Float64 = rho_rh_out * CSP.grav * self.m_h_tower
                    P_lp_in = P_rh_out + dp_rh_down / 1.e3
                    water_PH(P_lp_in, h_rh_out, &wp)
                    var T_rh_out_val: Float64 = wp.temp
                    h_lp_in = h_rh_out
                    diff_T_rh = (self.m_T_rh_out_des - T_rh_out_val) / self.m_T_rh_out_des
                    if high_tol and abs(diff_T_sh) < self.m_tol_T_sh_base and abs(diff_T_rh) > self.m_tol_T_rh:
                        high_tol = False
                if break_def_calcs:
                    break
                if iter_T_rh == 20 and abs(diff_T_rh) > self.m_tol_T_rh:
                    self.m_success = False
                self.m_m_dot_ND = m_dot_sh / self.m_m_dot_des
                if (self.m_m_dot_ND - self.m_cycle_max_frac) / self.m_cycle_max_frac > 0.005 or ((self.m_m_dot_ND - self.m_cycle_max_frac) / self.m_cycle_max_frac < -0.005 and self.m_defocus < 1.0 and not self.m_df_flag):
                    if df_upflag and df_lowflag:
                        if (self.m_m_dot_ND - self.m_cycle_max_frac) > 0.0:
                            df_upper = self.m_defocus
                            y_df_upper = self.m_m_dot_ND - self.m_cycle_max_frac
                        else:
                            df_lower = self.m_defocus
                            y_df_lower = self.m_m_dot_ND - self.m_cycle_max_frac
                        self.m_defocus = y_df_upper / (y_df_upper - y_df_lower) * (df_lower - df_upper) + df_upper
                    else:
                        if (self.m_m_dot_ND - self.m_cycle_max_frac) > 0.0:
                            df_upflag = True
                            df_upper = self.m_defocus
                            y_df_upper = self.m_m_dot_ND - self.m_cycle_max_frac
                        else:
                            df_lowflag = True
                            df_lower = self.m_defocus
                            y_df_lower = self.m_m_dot_ND - self.m_cycle_max_frac
                        if df_upflag and df_lowflag:
                            self.m_defocus = y_df_upper / (y_df_upper - y_df_lower) * (df_lower - df_upper) + df_upper
                        else:
                            self.m_defocus = min(1.0, self.m_defocus * (self.m_cycle_max_frac / self.m_m_dot_ND))
                    defocus_mode = True
            if break_def_calcs:
                break
        # end while skip_rec_calcs
        h_fw_Jkg = self.m_h_fw * 1000.0
        if not self.m_success:
            m_dot_sh = 0.0
            m_dot_rh = 0.0
            self.m_E_su_rec = self.m_q_rec_des * self.m_rec_qf_delay
            self.m_t_su_rec = self.m_rec_su_delay
            dp_sh = 0.0
            dp_rh = 0.0
            q_therm_in_b = 0.0
            q_therm_in_sh = 0.0
            q_therm_in_rh = 0.0
            q_therm_in_rec = 0.0
            P_cond = 0.0
            deltaP1 = 10.E6
            W_dot_fw = 0.0
            W_dot_boost = 0.0
        else:
            if self.m_eta_lin_approx and self.m_defocus > 0.999:
                if self.m_q_total < (0.75 * self.m_q_rec_min + 0.25 * self.m_q_pb_design) and not self.m_q_low_set:
                    self.m_q_total_low = self.m_q_total
                    self.m_eta_rh_low = eta_rh
                    self.m_eta_sh_low = eta_sh
                    self.m_eta_b_low = eta_b
                    self.m_q_low_set = True
                if self.m_q_total > 0.85 * self.m_q_pb_design and not self.m_q_high_set:
                    self.m_q_total_high = self.m_q_total
                    self.m_eta_rh_high = eta_rh
                    self.m_eta_sh_high = eta_sh
                    self.m_eta_b_high = eta_b
                    self.m_q_high_set = True
                if self.m_q_low_set and self.m_q_high_set:
                    self.m_eta_lin_approx = False
            dp_sh = (P_sh_in - P_hp_in) * 1000.0
            dp_rh = (P_hp_out - P_lp_in) * 1000.0
            q_therm_in_b = q_boiler_abs
            q_therm_in_sh = q_sh_abs
            q_therm_in_rh = q_rh_abs
            q_therm_in_rec = q_therm_in_b + q_therm_in_sh + q_therm_in_rh
            deltaP1 = rho_fw * CSP.grav * self.m_h_tower
            W_dot_fw = (deltaP1 + max(0.0, dp_sh)) * m_dot_sh / rho_fw
            water_TQ(T_boil, 0.0, &wp)
            var rho_x0: Float64 = wp.dens
            var W_dot_sd: Float64 = max(0.0, dp_b) * (m_dot_sh / self.m_x_b_target) / rho_x0
            W_dot_boost = (W_dot_fw + W_dot_sd) / self.m_eta_rec_pump
        self.m_m_dot_aux = 0.0
        self.m_q_aux = 0.0
        var q_aux_fuel: Float64 = 0.0
        var f_timestep: Float64 = 1.0
        if self.m_ffrac[self.m_touperiod] > 0.01:
            if self.m_success:
                h_hp_in = h_hp_in * 1000.0
                h_lp_in = h_lp_in * 1000.0
                water_TP(T_rh_in, self.m_P_rh_in, &wp)
                h_rh_in = wp.enth * 1000.0
            else:
                water_TP(self.m_T_sh_out_des, P_b_in, &wp)
                h_hp_in = wp.enth * 1000.0
                water_TP(T_fw, self.m_P_b_in_min, &wp)
                h_fw_Jkg = wp.enth * 1000.0
                rho_fw = wp.dens
                water_TP(self.m_T_rh_out_des, P_hp_out, &wp)
                h_lp_in = wp.enth * 1000.0
                water_TP(T_rh_in, P_hp_out, &wp)
                h_rh_in = wp.enth * 1000.0
            if self.m_fossil_mode == 1:
                if self.m_ffrac[self.m_touperiod] < self.m_f_pb_cutoff or self.m_ffrac[self.m_touperiod] * self.m_m_dot_des < m_dot_sh:
                    self.m_m_dot_aux = 0.0
                else:
                    self.m_m_dot_aux = self.m_ffrac[self.m_touperiod] * self.m_m_dot_des - m_dot_sh
            elif self.m_fossil_mode == 2:
                self.m_m_dot_aux = self.m_ffrac[self.m_touperiod] * self.m_m_dot_des
                if (self.m_m_dot_aux + m_dot_sh) < (self.m_f_pb_cutoff * self.m_m_dot_des):
                    self.m_m_dot_aux = 0.0
                elif ((self.m_m_dot_aux + m_dot_sh) / self.m_m_dot_des - self.m_cycle_max_frac) / self.m_cycle_max_frac > 0.005:
                    self.m_m_dot_aux = max(0.0, self.m_cycle_max_frac * self.m_m_dot_des - m_dot_sh)
            self.m_q_aux = self.m_m_dot_aux * ((h_hp_in - h_fw_Jkg) + f_mdotrh * (h_lp_in - h_rh_in))
            q_aux_fuel = self.m_q_aux / self.m_lhv_eff * step * (1.0 / 3600.0) * 3.41214116E-6
            var W_dot_aux: Float64 = max(0.0, dp_sh) * self.m_m_dot_aux / rho_fw
            W_dot_boost = W_dot_boost + W_dot_aux
        var m_dot_toPB: Float64 = self.m_m_dot_aux + m_dot_sh
        if m_dot_toPB > self.m_f_pb_cutoff * self.m_m_dot_des:
            self.m_standby_control = 1
            self.m_t_sb_pb = self.m_t_standby_ini
        elif m_dot_toPB > self.m_f_pb_sb * self.m_m_dot_des and self.m_t_sb_pb_prev - step / 3600.0 > 0.0:
            self.m_standby_control = 2
            self.m_t_sb_pb = self.m_t_sb_pb_prev - step / 3600.0
        else:
            self.m_standby_control = 3
            self.m_t_sb_pb = 0.0
        var q_startup: Float64
        if (self.m_E_su_rec_prev > 0.0 or self.m_t_su_rec_prev > 0.0) and self.m_success:
            q_startup = min(self.m_E_su_rec_prev, q_therm_in_rec * step / 3600.0)
            self.m_E_su_rec = max(0.0, self.m_E_su_rec_prev - q_therm_in_rec * step / 3600.0)
            self.m_t_su_rec = max(0.0, self.m_t_su_rec_prev - step / 3600.0)
            if self.m_E_su_rec + self.m_t_su_rec > 0.0:
                f_timestep = 0.0
            else:
                f_timestep = max(0.0, min(1.0 - self.m_t_su_rec_prev / (step / 3600.0), 1.0 - self.m_E_su_rec_prev / (q_therm_in_rec) * step / 3600.0))
            if self.m_m_dot_aux > 0.0:
                f_timestep = m_dot_sh / m_dot_toPB * f_timestep + self.m_m_dot_aux / m_dot_toPB
                f_timestep = min(1.0, f_timestep)
        self.m_diff_m_dot_old_ncall = self.m_diff_m_dot_out_ncall
        self.m_diff_m_dot_out_ncall = m_dot_toPB - self.m_m_dot_prev_ncall
        var diff_dp_b: Float64 = (dp_b - self.m_dp_b_prev_ncall) / (P_b_in / 1.E3)
        var diff_dp_sh: Float64 = (dp_sh - self.m_dp_sh_prev_ncall) / (P_b_in / 1.E3)
        var diff_dp_rh: Float64 = (dp_rh - self.m_dp_rh_prev_ncall) / (self.m_P_rh_in / 1.E3)
        if ncall > 2:
            if self.m_diff_m_dot_old_ncall > self.m_diff_m_dot_out_ncall:
                if abs(self.m_diff_m_dot_old_ncall + self.m_diff_m_dot_out_ncall) < 0.01:
                    m_dot_toPB = 0.5 * self.m_m_dot_prev_ncall + 0.5 * m_dot_toPB
                    self.m_diff_m_dot_out_ncall = m_dot_toPB - self.m_m_dot_prev_ncall
            elif self.m_diff_m_dot_out_ncall > self.m_diff_m_dot_old_ncall:
                if abs(self.m_diff_m_dot_out_ncall + self.m_diff_m_dot_old_ncall) < 0.01:
                    m_dot_toPB = 0.5 * self.m_m_dot_prev_ncall + 0.5 * m_dot_toPB
                    self.m_diff_m_dot_out_ncall = m_dot_toPB - self.m_m_dot_prev_ncall
        if ncall > 0 and abs(self.m_diff_m_dot_out_ncall / m_dot_toPB) < 0.005 and abs(diff_dp_b) < 0.005 and abs(diff_dp_sh) < 0.005 and abs(diff_dp_rh) < 0.005:
            m_dot_toPB = self.m_m_dot_prev_ncall
            f_timestep = self.f_timestep_prev_ncall
            dp_b = self.m_dp_b_prev_ncall
            dp_sh = self.m_dp_sh_prev_ncall
            dp_rh = self.m_dp_rh_prev_ncall
        self.m_m_dot_prev_ncall = m_dot_toPB
        self.f_timestep_prev_ncall = f_timestep
        self.m_dp_b_prev_ncall = dp_b
        self.m_dp_sh_prev_ncall = dp_sh
        self.m_dp_rh_prev_ncall = dp_rh
        var PB_on: Bool = True
        if not self.m_success and m_dot_toPB == 0.0:
            PB_on = False
        var b_m_dot: Float64 = 0.0
        var b_T_max: Float64 = 0.0
        var b_q_out: Float64 = 0.0
        var b_q_in: Float64 = 0.0
        var b_q_conv: Float64 = 0.0
        var b_q_rad: Float64 = 0.0
        var b_q_abs: Float64 = 0.0
        self.boiler.Get_Other_Boiler_Outputs(b_m_dot, b_T_max, b_q_out, b_q_in, b_q_conv, b_q_rad, b_q_abs)
        var sh_q_conv: Float64 = 0.0
        var sh_q_rad: Float64 = 0.0
        var sh_q_abs: Float64 = 0.0
        var sh_T_surf_max: Float64 = 0.0
        var sh_v_exit: Float64 = 0.0
        var sh_q_in: Float64 = 0.0
        if self.m_success:
            self.value(O_T_b_in, (T_in - 273.15))
            self.value(O_T_boil, (T_boil - 273.15))
            self.value(O_P_b_out, P_b_out)
            self.value(O_P_drop_b, dp_b)
            self.value(O_m_dot_b, b_m_dot * 3600.0)
            self.value(O_eta_b, eta_b)
            self.value(O_q_b_conv, b_q_conv)
            self.value(O_q_b_rad, b_q_rad)
            self.value(O_q_b_abs, b_q_abs)
            self.value(O_T_max_b_surf, (b_T_max - 273.15))
            self.value(O_m_dot_sh, m_dot_sh * 3600.0)
            self.value(O_P_sh_out, P_sh_out_var)
            self.value(O_dP_sh, dp_sh)
            self.value(O_eta_sh, eta_sh)
            self.superheater.Get_Other_Superheater_Outputs(sh_q_conv, sh_q_rad, sh_q_abs, sh_T_surf_max, sh_v_exit, sh_q_in)
            self.value(O_q_sh_conv, sh_q_conv)
            self.value(O_q_sh_rad, sh_q_rad)
            self.value(O_q_sh_abs, sh_q_abs)
            self.value(O_T_max_sh_surf, (sh_T_surf_max - 273.15))
            self.value(O_v_sh_max, sh_v_exit)
            self.value(O_P_rh_out, P_rh_out)
            self.value(O_dP_rh, dp_rh)
            self.value(O_eta_rh, eta_rh)
            var rh_q_conv: Float64 = 0.0
            var rh_q_rad: Float64 = 0.0
            var rh_q_abs: Float64 = 0.0
            var rh_T_surf: Float64 = 0.0
            var rh_v_exit: Float64 = 0.0
            var rh_q_in: Float64 = 0.0
            self.reheater.Get_Other_Superheater_Outputs(rh_q_conv, rh_q_rad, rh_q_abs, rh_T_surf, rh_v_exit, rh_q_in)
            self.value(O_T_max_rh_surf, (rh_T_surf - 273.15))
            self.value(O_v_rh_max, rh_v_exit)
            self.value(O_q_rh_conv, rh_q_conv)
            self.value(O_q_rh_rad, rh_q_rad)
            self.value(O_q_rh_abs, rh_q_abs)
            var EnergyInComb: Float64 = b_q_in + sh_q_in + rh_q_in
            var field_eff_adj: Float64 = self.m_field_eff * self.m_defocus
            var q_abs_rec: Float64 = b_q_abs + sh_q_abs + rh_q_abs
            var q_conv_rec: Float64 = b_q_conv + sh_q_conv + rh_q_conv
            var q_rad_rec: Float64 = b_q_rad + sh_q_rad + rh_q_rad
            var eta_therm_rec: Float64 = q_therm_in_rec / (max(0.001, EnergyInComb))
            self.value(O_q_inc_full, self.m_q_total / 1.E6)
            self.value(O_q_inc_actual, EnergyInComb / 1.E6)
            self.value(O_defocus, self.m_defocus)
            self.value(O_field_eta_adj, field_eff_adj)
            self.value(O_q_abs_rec, q_abs_rec)
            self.value(O_q_conv_rec, q_conv_rec)
            self.value(O_q_rad_rec, q_rad_rec)
            self.value(O_q_abs_less_rad, q_abs_rec - q_rad_rec)
            self.value(O_q_therm_in_rec, q_therm_in_rec / 1.E6)
            self.value(O_eta_rec, eta_therm_rec)
        else:
            self.value(O_T_b_in, 0.0)
            self.value(O_T_boil, 0.0)
            self.value(O_P_b_out, 0.0)
            self.value(O_P_drop_b, 0.0)
            self.value(O_m_dot_b, 0.0)
            self.value(O_eta_b, 0.0)
            self.value(O_q_b_conv, 0.0)
            self.value(O_q_b_rad, 0.0)
            self.value(O_q_b_abs, 0.0)
            self.value(O_T_max_b_surf, 0.0)
            self.value(O_m_dot_sh, 0.0)
            self.value(O_P_sh_out, 0.0)
            self.value(O_dP_sh, 0.0)
            self.value(O_eta_sh, 0.0)
            self.value(O_q_sh_conv, 0.0)
            self.value(O_q_sh_rad, 0.0)
            self.value(O_q_sh_abs, 0.0)
            self.value(O_T_max_sh_surf, 0.0)
            self.value(O_v_sh_max, 0.0)
            self.value(O_P_rh_out, 0.0)
            self.value(O_dP_rh, 0.0)
            self.value(O_eta_rh, 0.0)
            self.value(O_T_max_rh_surf, 0.0)
            self.value(O_v_rh_max, 0.0)
            self.value(O_q_rh_conv, 0.0)
            self.value(O_q_rh_rad, 0.0)
            self.value(O_q_rh_abs, 0.0)
            self.value(O_q_inc_full, 0.0)
            self.value(O_q_inc_actual, 0.0)
            self.value(O_defocus, 0.0)
            self.value(O_field_eta_adj, 0.0)
            self.value(O_q_abs_rec, 0.0)
            self.value(O_q_conv_rec, 0.0)
            self.value(O_q_rad_rec, 0.0)
            self.value(O_q_abs_less_rad, 0.0)
            self.value(O_q_therm_in_rec, 0.0)
            self.value(O_eta_rec, 0.0)
        if PB_on:
            self.value(O_T_fw, (T_fw - 273.15))
            self.value(O_P_b_in, P_b_in)
            self.value(O_f_mdot_rh, f_mdotrh)
            self.value(O_P_rh_in, self.m_P_rh_in)
            self.value(O_T_rh_in, (T_rh_in - 273.15))
            self.value(O_T_rh_out, (T_rh_target - 273.15))
        else:
            self.value(O_T_fw, 0.0)
            self.value(O_P_b_in, 0.0)
            self.value(O_f_mdot_rh, 0.0)
            self.value(O_P_rh_in, 0.0)
            self.value(O_T_rh_in, 0.0)
            self.value(O_T_rh_out, 0.0)
        self.value(O_W_dot_boost, W_dot_boost / 1.E6)
        self.value(O_m_dot_aux, self.m_m_dot_aux * 3600.0)
        self.value(O_q_aux, self.m_q_aux / 1.E6)
        self.value(O_q_aux_fuel, q_aux_fuel)
        self.value(O_standby_control, self.m_standby_control)
        self.value(O_f_timestep, f_timestep)
        self.value(O_m_dot_toPB, m_dot_toPB * 3600.0)
        return 0

    def converged(inout self, time: Float64) -> Int:
        self.m_E_su_rec_prev = self.m_E_su_rec
        self.m_t_su_rec_prev = self.m_t_su_rec
        self.m_t_sb_pb_prev = self.m_t_sb_pb
        if self.m_df_flag:

        if self.value(I_P_b_in) != 0.0:
            self.m_high_pres_count += 1
        return 0

# TCS_IMPLEMENT_TYPE( sam_dsg_controller_type265, "Direct steam receiver controller", "Ty Neises", 1, sam_dsg_controller_type265_variables, NULL, 1 )