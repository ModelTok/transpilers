/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  (“Alliance”) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as “System Advisor Model” or “SAM”. Except
*  to comply with the foregoing, the terms “System Advisor Model”, “SAM”, or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHERm
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/

from csp_solver_pt_receiver import C_pt_receiver
from ngcc_powerblock import ngcc_power_cycle
from csp_solver_util import matrix_t, C_csp_messages, C_csp_exception, CSP
from csp_solver_core import C_csp_weatherreader, C_csp_solver_htf_1state, C_csp_solver_sim_info
from sam_csp_util import sam_csp_util
from Ambient import Ambient
from definitions import HTFProperties

# Utility to get NaN
alias QNAN = Float64.NaN

struct C_mspt_receiver(C_pt_receiver):
    private var cycle_calcs: ngcc_power_cycle
    var m_id_tube: Float64
    var m_A_tube: Float64
    var m_n_t: Int
    var m_A_rec_proj: Float64
    var m_A_node: Float64
    var m_Q_dot_piping_loss: Float64 # [Wt] = Constant thermal losses from piping to env. = (THT*length_mult + length_add) * piping_loss_coef
    var m_itermode: Int
    var m_od_control: Float64
    var m_eta_field_iter_prev: Float64    # [-] Efficiency from heliostat on last iteration. Maybe change if CR gets defocus signal from controller
    var m_tol_od: Float64
    # declare storage variables here
    var m_E_su: Float64
    var m_E_su_prev: Float64
    var m_t_su: Float64
    var m_t_su_prev: Float64
    var m_flow_pattern: matrix_t[Int]
    var m_n_lines: Int
    var m_flux_in: matrix_t[Float64]
    var m_q_dot_inc: matrix_t[Float64]
    var m_T_s: matrix_t[Float64]
    var m_T_panel_out: matrix_t[Float64]
    var m_T_panel_in: matrix_t[Float64]
    var m_T_panel_ave: matrix_t[Float64]
    var m_q_dot_conv: matrix_t[Float64]
    var m_q_dot_rad: matrix_t[Float64]
    var m_q_dot_loss: matrix_t[Float64]
    var m_q_dot_abs: matrix_t[Float64]
    var m_m_mixed: Float64
    var m_LoverD: Float64
    var m_RelRough: Float64
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var m_P_amb_low: Float64
    var m_P_amb_high: Float64
    var m_q_iscc_max: Float64
    var m_ncall: Int

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
        var T_s: matrix_t[Float64]
        var T_panel_out: matrix_t[Float64]
        var T_panel_in: matrix_t[Float64]
        var T_panel_ave: matrix_t[Float64]
        var q_dot_inc: matrix_t[Float64]
        var q_dot_conv: matrix_t[Float64]
        var q_dot_rad: matrix_t[Float64]
        var q_dot_loss: matrix_t[Float64]
        var q_dot_abs: matrix_t[Float64]

        def __init__(inout self):
            self.clear()

        def clear(inout self):
            self.hour = QNAN
            self.T_amb = QNAN
            self.T_dp = QNAN
            self.v_wind_10 = QNAN
            self.p_amb = QNAN
            self.dni = QNAN
            self.od_control = QNAN
            self.field_eff = QNAN
            self.m_dot_salt = QNAN
            self.m_dot_salt_tot = QNAN
            self.T_salt_cold_in = QNAN
            self.T_salt_hot = QNAN
            self.T_salt_hot_rec = QNAN
            self.T_salt_props = QNAN
            self.u_salt = QNAN
            self.f = QNAN
            self.Q_inc_sum = QNAN
            self.Q_conv_sum = QNAN
            self.Q_rad_sum = QNAN
            self.Q_abs_sum = QNAN
            self.Q_dot_piping_loss = QNAN
            self.Q_inc_min = QNAN
            self.Q_thermal = QNAN
            self.eta_therm = QNAN
            self.mode = C_csp_collector_receiver.E_csp_cr_modes.OFF
            self.itermode = -1
            self.rec_is_off = true

    var m_mflow_soln_prev: s_steady_state_soln
    var m_mflow_soln_csky_prev: s_steady_state_soln
    var m_startup_mode: Int
    var m_startup_mode_initial: Int
    var m_n_call_fill: Int
    var m_n_call_fill_initial: Int
    var m_id_riser: Float64
    var m_od_riser: Float64
    var m_id_downc: Float64
    var m_od_downc: Float64
    var m_Rtot_riser: Float64
    var m_Rtot_downc: Float64
    var m_total_startup_time: Float64
    var m_total_startup_time_initial: Float64
    var m_minimum_startup_time: Float64
    var m_total_ramping_time: Float64
    var m_total_ramping_time_initial: Float64
    var m_total_fill_time: Float64
    var m_total_fill_time_initial: Float64
    var m_total_preheat_time: Float64
    var m_total_preheat_time_initial: Float64
    var m_crossover_index: Int
    var m_n_elem: Int
    var m_nz_tot: Int
    var m_tm: DynamicVector[Float64]   # [J/K/m]
    var m_tm_solid: DynamicVector[Float64]  # [J/K/m]
    var m_od: DynamicVector[Float64]   # [m]
    var m_id: DynamicVector[Float64]   # [m]
    var m_flowelem_type: matrix_t[Int]
    var m_tinit: matrix_t[Float64]
    var m_tinit_wall: matrix_t[Float64]

    struct transient_inputs:
        var nelem: Int
        var nztot: Int
        var npath: Int
        var inlet_temp: Float64
        var lam1: matrix_t[Float64]
        var lam2: matrix_t[Float64]
        var cval: matrix_t[Float64]
        var aval: matrix_t[Float64]
        var tinit: matrix_t[Float64]
        var tinit_wall: matrix_t[Float64]
        var Rtube: matrix_t[Float64]
        var length: DynamicVector[Float64]
        var zpts: DynamicVector[Float64]
        var nz: DynamicVector[Int]
        var startpt: DynamicVector[Int]

        def __init__(inout self):
            self.nelem = 0
            self.nztot = 0
            self.npath = 0
            self.inlet_temp = QNAN

    var trans_inputs: transient_inputs

    struct transient_outputs:
        var timeavg_tout: Float64
        var tout: Float64
        var max_tout: Float64
        var min_tout: Float64
        var max_rec_tout: Float64
        var timeavg_conv_loss: Float64
        var timeavg_rad_loss: Float64
        var timeavg_piping_loss: Float64
        var timeavg_qthermal: Float64
        var timeavg_qnet: Float64
        var timeavg_qheattrace: Float64
        var timeavg_eta_therm: Float64
        var time_min_tout: Float64
        var tube_temp_inlet: Float64
        var tube_temp_outlet: Float64
        var t_profile: matrix_t[Float64]
        var t_profile_wall: matrix_t[Float64]
        var timeavg_temp: matrix_t[Float64]

        def __init__(inout self):
            self.timeavg_tout = QNAN
            self.tout = QNAN
            self.max_tout = QNAN
            self.min_tout = QNAN
            self.max_rec_tout = QNAN
            self.timeavg_conv_loss = QNAN
            self.timeavg_rad_loss = QNAN
            self.timeavg_piping_loss = QNAN
            self.timeavg_qthermal = QNAN
            self.timeavg_qnet = QNAN
            self.timeavg_qheattrace = QNAN
            self.timeavg_eta_therm = QNAN
            self.time_min_tout = QNAN
            self.tube_temp_inlet = QNAN
            self.tube_temp_outlet = QNAN

    var trans_outputs: transient_outputs

    struct parameter_eval_inputs:
        var T_amb: Float64
        var T_sky: Float64
        var pres: Float64
        var wspd: Float64
        var c_htf: Float64
        var rho_htf: Float64
        var mu_htf: Float64
        var k_htf: Float64
        var Pr_htf: Float64
        var mflow_tot: Float64
        var finitial: Float64
        var ffinal: Float64
        var ramptime: Float64
        var tm: DynamicVector[Float64]
        var Tfeval: matrix_t[Float64]
        var Tseval: matrix_t[Float64]
        var qinc: matrix_t[Float64]
        var qheattrace: matrix_t[Float64]

        def __init__(inout self):
            self.T_amb = QNAN
            self.T_sky = QNAN
            self.pres = QNAN
            self.wspd = QNAN
            self.c_htf = QNAN
            self.rho_htf = QNAN
            self.mu_htf = QNAN
            self.k_htf = QNAN
            self.Pr_htf = QNAN
            self.mflow_tot = QNAN
            self.finitial = QNAN
            self.ffinal = QNAN
            self.ramptime = QNAN

    var param_inputs: parameter_eval_inputs

    def __init__(inout self):
        self.m_n_panels = -1
        self.m_d_rec = QNAN
        self.m_h_rec = QNAN
        self.m_od_tube = QNAN
        self.m_th_tube = QNAN
        self.m_hl_ffact = QNAN
        self.m_A_sf = QNAN
        self.m_pipe_loss_per_m = QNAN
        self.m_pipe_length_add = QNAN
        self.m_pipe_length_mult = QNAN
        self.m_id_tube = QNAN
        self.m_A_tube = QNAN
        self.m_n_t = -1
        self.m_n_flux_x = 0
        self.m_n_flux_y = 0
        self.m_T_salt_hot_target = QNAN
        self.m_eta_pump = QNAN
        self.m_night_recirc = -1
        self.m_hel_stow_deploy = QNAN
        self.m_field_fl = -1
        self.m_mat_tube = -1
        self.m_flow_type = -1
        self.m_crossover_shift = 0
        self.m_A_rec_proj = QNAN
        self.m_A_node = QNAN
        self.m_Q_dot_piping_loss = QNAN
        self.m_m_dot_htf_max = QNAN
        self.m_itermode = -1
        self.m_od_control = QNAN
        self.m_eta_field_iter_prev = QNAN
        self.m_tol_od = QNAN
        self.m_q_dot_inc_min = QNAN
        self.m_E_su = QNAN
        self.m_E_su_prev = QNAN
        self.m_t_su = QNAN
        self.m_t_su_prev = QNAN
        self.m_flow_pattern = matrix_t[Int]()
        self.m_n_lines = -1
        self.m_m_mixed = QNAN
        self.m_LoverD = QNAN
        self.m_RelRough = QNAN
        self.m_is_iscc = false
        self.m_cycle_config = 1
        self.m_T_amb_low = QNAN
        self.m_T_amb_high = QNAN
        self.m_P_amb_low = QNAN
        self.m_P_amb_high = QNAN
        self.m_q_iscc_max = QNAN
        self.m_ncall = -1
        self.m_is_transient = 0
        self.m_is_startup_transient = 0
        self.m_rec_tm_mult = QNAN
        self.m_u_riser = QNAN
        self.m_th_riser = QNAN
        self.m_th_downc = QNAN
        self.m_piping_loss_coeff = QNAN
        self.m_riser_tm_mult = QNAN
        self.m_downc_tm_mult = QNAN
        self.m_id_riser = QNAN
        self.m_od_riser = QNAN
        self.m_id_downc = QNAN
        self.m_od_downc = QNAN
        self.m_Rtot_riser = QNAN
        self.m_Rtot_downc = QNAN
        self.m_tube_flux_preheat = QNAN
        self.m_fill_time = QNAN
        self.m_flux_ramp_time = QNAN
        self.m_heat_trace_power = QNAN
        self.m_preheat_target = QNAN
        self.m_startup_target_delta = QNAN
        self.m_is_startup_from_solved_profile = 0
        self.m_is_enforce_min_startup = 1
        self.m_n_elem = 0
        self.m_nz_tot = 0
        self.m_startup_mode = -1
        self.m_startup_mode_initial = -1
        self.m_n_call_fill = -1
        self.m_n_call_fill_initial = -1
        self.m_total_startup_time = QNAN
        self.m_total_startup_time_initial = QNAN
        self.m_minimum_startup_time = QNAN
        self.m_total_ramping_time_initial = QNAN
        self.m_total_ramping_time = QNAN
        self.m_total_preheat_time_initial = QNAN
        self.m_total_preheat_time = QNAN
        self.m_total_fill_time_initial = QNAN
        self.m_total_fill_time = QNAN
        self.m_crossover_index = -1
        self.m_csky_frac = QNAN

    def init(inout self):
        ambient_air.SetFluid(ambient_air.Air)
        if self.m_field_fl != HTFProperties.User_defined and self.m_field_fl < HTFProperties.End_Library_Fluids:
            if not field_htfProps.SetFluid(self.m_field_fl):
                raise C_csp_exception("Receiver HTF code is not recognized", "MSPT receiver")
        elif self.m_field_fl == HTFProperties.User_defined:
            var n_rows = field_htfProps.nrows()
            var n_cols = field_htfProps.ncols()
            if n_rows > 2 and n_cols == 7:
                if not field_htfProps.SetUserDefinedFluid(self.m_field_fl_props):
                    var error_msg = util.format(field_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(error_msg, "MSPT receiver")
            else:
                var error_msg = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(error_msg, "MSPT receiver")
        else:
            raise C_csp_exception("Receiver HTF code is not recognized", "MSPT receiver")
        if self.m_mat_tube == HTFProperties.Stainless_AISI316 or self.m_mat_tube == HTFProperties.T91_Steel or self.m_mat_tube == HTFProperties.N06230 or self.m_mat_tube == HTFProperties.N07740:
            if not tube_material.SetFluid(self.m_mat_tube):
                raise C_csp_exception("Tube material code not recognized", "MSPT receiver")
        elif self.m_mat_tube == HTFProperties.User_defined:
            raise C_csp_exception("Receiver material currently does not accept user defined properties", "MSPT receiver")
        else:
            var error_msg = util.format("Receiver material code, %d, is not recognized", self.m_mat_tube)
            raise C_csp_exception(error_msg, "MSPT receiver")
        self.m_od_tube /= 1.E3                     # [m] Convert from input in [mm]
        self.m_th_tube /= 1.E3                     # [m] Convert from input in [mm]
        self.m_T_htf_hot_des += 273.15            # [K] Convert from input in [C]
        self.m_T_htf_cold_des += 273.15           # [K] Convert from input in [C]
        self.m_q_rec_des *= 1.E6                   # [W] Convert from input in [MW]
        self.m_id_tube = self.m_od_tube - 2 * self.m_th_tube
        self.m_A_tube = CSP.pi * self.m_od_tube / 2.0 * self.m_h_rec
        self.m_n_t = (Int)(CSP.pi * self.m_d_rec / (self.m_od_tube * self.m_n_panels))
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
            self.m_m_dot_htf_max /= 3600.0    # [kg/s] Convert from input in [kg/hr]
        self.m_m_dot_htf_max = self.m_m_dot_htf_max_frac * self.m_m_dot_htf_des   # [kg/s]
        self.m_mode_prev = self.m_mode
        self.m_E_su_prev = self.m_q_rec_des * self.m_rec_qf_delay
        self.m_t_su_prev = self.m_rec_su_delay
        self.m_eta_field_iter_prev = 1.0
        self.m_T_salt_hot_target += 273.15
        if self.m_pipe_loss_per_m > 0.0 and self.m_pipe_length_mult > 0.0:
            self.m_Q_dot_piping_loss = self.m_pipe_loss_per_m * (self.m_h_tower * self.m_pipe_length_mult + self.m_pipe_length_add)
        else:
            self.m_Q_dot_piping_loss = 0.0
        var flow_msg = ""
        if not CSP.flow_patterns(self.m_n_panels, self.m_crossover_shift, self.m_flow_type, self.m_n_lines, self.m_flow_pattern, flow_msg):
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
        self.initialize_transient_parameters()
        return

    def initialize_transient_parameters(inout self):
        self.m_flux_ramp_time *= 3600.0  # [s], convert from input in [hr]
        self.m_fill_time *= 3600.0       # [s], convert from input in [hr]
        self.m_min_preheat_time *= 3600. # [s], convert from input in [hr]
        self.m_th_riser /= 1.E3          # [m], Riser wall thickness, convert from input in [mm]
        self.m_th_downc = self.m_th_riser
        self.m_heat_trace_power *= 1.e3  # [W/m-length], heat trace power, convert from input in [kW/m]
        self.m_initial_temperature += 273.15
        self.m_preheat_target += 273.15
        var rho_htf_inlet = field_htfProps.dens(self.m_T_htf_cold_des, 1.0)
        var rho_htf_des = field_htfProps.dens((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0, 1.0)
        var mu_htf_des = field_htfProps.visc((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0)
        var rho_tube_des = tube_material.dens((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0, 1.0)
        var c_tube_des = tube_material.Cp((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0) * 1000.0
        var c_htf_des = field_htfProps.Cp((self.m_T_htf_hot_des + self.m_T_htf_cold_des) / 2.0) * 1000.0
        self.m_id_riser = pow(4.0 * self.m_m_dot_htf_des / rho_htf_inlet / CSP.pi / self.m_u_riser, 0.5)
        self.m_id_downc = self.m_id_riser
        self.m_od_riser = self.m_id_riser + 2.0 * self.m_th_riser
        self.m_od_downc = self.m_id_downc + 2.0 * self.m_th_downc
        var tm_riser = self.m_riser_tm_mult * (0.25 * CSP.pi * pow(self.m_id_riser, 2) * rho_htf_des * c_htf_des + 0.25 * CSP.pi * (pow(self.m_od_riser, 2) - pow(self.m_id_riser, 2)) * rho_tube_des * c_tube_des)
        var tm_downc = self.m_downc_tm_mult * (0.25 * CSP.pi * pow(self.m_id_downc, 2) * rho_htf_des * c_htf_des + 0.25 * CSP.pi * (pow(self.m_od_downc, 2) - pow(self.m_id_downc, 2)) * rho_tube_des * c_tube_des)
        var tm_riser_solid = tm_riser - 0.25 * CSP.pi * pow(self.m_id_riser, 2) * rho_htf_des * c_htf_des
        var tm_downc_solid = tm_downc - 0.25 * CSP.pi * pow(self.m_id_downc, 2) * rho_htf_des * c_htf_des
        self.m_piping_loss_coeff = self.m_pipe_loss_per_m / (0.5 * CSP.pi * (self.m_id_downc * (self.m_T_htf_hot_des - 298.) + self.m_id_riser * (self.m_T_htf_cold_des - 298.)))
        self.m_piping_loss_coeff = fmax(1.e-4, self.m_piping_loss_coeff)
        self.m_Rtot_riser = 1.0 / (self.m_piping_loss_coeff * 0.5 * self.m_id_riser)
        self.m_Rtot_downc = 1.0 / (self.m_piping_loss_coeff * 0.5 * self.m_id_downc)
        var dp_header_fract = 0.1
        var L_header = 2.0 * (CSP.pi * self.m_d_rec / self.m_n_panels)
        var m_m_dot_head = self.m_m_dot_htf_des / self.m_n_lines
        var ftube_des, Nutube_des, m_id_header, m_th_header, m_od_header = QNAN, QNAN, QNAN, QNAN, QNAN
        var m_per_tube_des = self.m_m_dot_htf_des / (Float64(self.m_n_lines) * Float64(self.m_n_t))
        var utube_des = m_per_tube_des / (rho_htf_des * self.m_id_tube * self.m_id_tube * 0.25 * CSP.pi)
        var Retube_des = rho_htf_des * utube_des * self.m_id_tube / mu_htf_des
        CSP.PipeFlow(Retube_des, 4.0, self.m_LoverD, self.m_RelRough, Nutube_des, ftube_des)
        var dp_tube = 0.5 * rho_htf_des * ftube_des * pow(utube_des, 2) * (self.m_h_rec / self.m_id_tube + 2*16.0 + 4*30.0)
        var dp_header = dp_header_fract * dp_tube
        self.calc_header_size(dp_header, m_m_dot_head, rho_htf_des, mu_htf_des, L_header, m_id_header, m_th_header, m_od_header)
        var tm_header_tot = L_header * (0.25 * CSP.pi * pow(m_id_header, 2) * rho_htf_des * c_htf_des + 0.25 * CSP.pi * (pow(m_od_header, 2) - pow(m_id_header, 2)) * rho_tube_des * c_tube_des)
        var tm_header_cross, tm_header_cross_solid, od_header_cross, id_header_cross = 0.0, 0.0, 0.0, 0.0
        if self.m_flow_type == 1 or self.m_flow_type == 2:
            var th_header_cross = QNAN
            self.calc_header_size(dp_header, m_m_dot_head, rho_htf_des, mu_htf_des, self.m_d_rec, id_header_cross, th_header_cross, od_header_cross)
            tm_header_cross = 0.25 * CSP.pi * pow(id_header_cross, 2) * rho_htf_des * c_htf_des + 0.25 * CSP.pi * (pow(od_header_cross, 2) - pow(id_header_cross, 2)) * rho_tube_des * c_tube_des
            tm_header_cross_solid = tm_header_cross - 0.25 * CSP.pi * pow(id_header_cross, 2) * rho_htf_des * c_htf_des
        var tm_tube = self.m_rec_tm_mult * (0.25 * CSP.pi * pow(self.m_id_tube, 2) * rho_htf_des * c_htf_des + 0.25 * CSP.pi * (pow(self.m_od_tube, 2) - pow(self.m_id_tube, 2)) * rho_tube_des * c_tube_des + tm_header_tot / self.m_h_rec / Float64(self.m_n_t))
        var tm_tube_solid = tm_tube - 0.25 * CSP.pi * pow(self.m_id_tube, 2) * rho_htf_des * c_htf_des - (0.25 * CSP.pi * pow(m_id_header, 2) * rho_htf_des * c_htf_des) * L_header / self.m_h_rec / Float64(self.m_n_t)
        self.m_n_elem = self.m_n_panels / self.m_n_lines + 2
        var nz_panel = 4
        var nz_tower = 8
        self.m_nz_tot = nz_panel * self.m_n_panels / self.m_n_lines + 2 * nz_tower
        var crossposition = 0
        if self.m_flow_type == 1 or self.m_flow_type == 2:
            self.m_n_elem = self.m_n_elem + 1
            self.m_nz_tot = self.m_nz_tot + nz_panel
            var npq = Float64(self.m_n_panels) / 4.0
            var nq1: Int
            if self.m_n_panels % 4 != 0:
                nq1 = Int(floor(npq)) + 1
            else:
                nq1 = Int(floor(npq + 1.e-6))
            crossposition = nq1 + 1
        self.trans_inputs.nelem = self.m_n_elem
        self.trans_inputs.nztot = self.m_nz_tot
        self.trans_inputs.npath = self.m_n_lines
        self.trans_inputs.length.resize(self.m_n_elem, self.m_h_rec)
        self.trans_inputs.nz.resize(self.m_n_elem, nz_panel)
        self.trans_inputs.zpts.resize(self.m_nz_tot)
        self.trans_inputs.startpt.resize(self.m_n_elem)
        self.trans_inputs.lam1.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_inputs.lam2.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_inputs.cval.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_inputs.aval.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_inputs.Rtube.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_inputs.tinit.resize(self.m_nz_tot, self.m_n_lines)
        self.trans_inputs.tinit_wall.resize(self.m_nz_tot, self.m_n_lines)
        self.m_tinit.resize_fill(self.m_nz_tot, self.m_n_lines, self.m_initial_temperature)
        self.m_tinit_wall.resize_fill(self.m_nz_tot, self.m_n_lines, self.m_initial_temperature)
        self.m_flowelem_type.resize(self.m_n_elem, self.m_n_lines)
        self.m_flowelem_type.fill(0)
        self.m_tm.resize(self.m_n_elem, tm_tube)
        self.m_tm_solid.resize(self.m_n_elem, tm_tube_solid)
        self.m_od.resize(self.m_n_elem, self.m_od_tube)
        self.m_id.resize(self.m_n_elem, self.m_id_tube)
        var k = 0
        for j in range(self.m_n_panels / self.m_n_lines):
            k = j + 1
            if (self.m_flow_type == 1 or self.m_flow_type == 2) and k >= crossposition:
                k = k + 1
            for i in range(self.m_n_lines):
                self.m_flowelem_type.at(k, i) = self.m_flow_pattern.at(i, j)
        self.trans_inputs.length.at(0) = self.trans_inputs.length.at(self.m_n_elem-1) = 0.5 * (self.m_h_tower * self.m_pipe_length_mult + self.m_pipe_length_add)
        self.trans_inputs.nz.at(0) = self.trans_inputs.nz.at(self.m_n_elem-1) = nz_tower
        self.m_tm.at(0) = tm_riser
        self.m_tm_solid.at(0) = tm_riser_solid
        self.m_tm.at(self.m_n_elem-1) = tm_downc
        self.m_tm_solid.at(self.m_n_elem-1) = tm_downc_solid
        self.m_od.at(0) = self.m_od_riser
        self.m_od.at(self.m_n_elem-1) = self.m_od_downc
        self.m_id.at(0) = self.m_id_riser
        self.m_id.at(self.m_n_elem-1) = self.m_id_downc
        if self.m_flow_type == 1 or self.m_flow_type == 2:
            self.trans_inputs.length.at(crossposition) = self.m_d_rec
            self.m_tm.at(crossposition) = tm_header_cross
            self.m_tm_solid.at(crossposition) = tm_header_cross_solid
            self.m_od.at(crossposition) = od_header_cross
            self.m_id.at(crossposition) = id_header_cross
            self.m_crossover_index = crossposition
        for i in range(self.m_n_lines):
            self.m_flowelem_type.at(0, i) = -1
            self.m_flowelem_type.at(self.m_n_elem-1, i) = -2
            if self.m_flow_type == 1 or self.m_flow_type == 2:
                self.m_flowelem_type.at(crossposition, i) = -3
        var dz: Float64
        var s: Int = 0
        for j in range(self.m_n_elem):
            self.trans_inputs.startpt.at(j) = s
            var nspace = self.trans_inputs.nz.at(j) - 1
            dz = self.trans_inputs.length.at(j) / Float64(nspace)
            for i in range(self.trans_inputs.nz.at(j)):
                self.trans_inputs.zpts.at(s + i) = dz * i
            s = s + self.trans_inputs.nz.at(j)
        self.trans_outputs.timeavg_tout = QNAN
        self.trans_outputs.timeavg_conv_loss = QNAN
        self.trans_outputs.timeavg_rad_loss = QNAN
        self.trans_outputs.timeavg_piping_loss = QNAN
        self.trans_outputs.timeavg_qthermal = QNAN
        self.trans_outputs.timeavg_qnet = QNAN
        self.trans_outputs.timeavg_eta_therm = QNAN
        self.trans_outputs.time_min_tout = QNAN
        self.trans_outputs.max_tout = QNAN
        self.trans_outputs.min_tout = QNAN
        self.trans_outputs.max_rec_tout = QNAN
        self.trans_outputs.timeavg_temp.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.trans_outputs.t_profile.resize_fill(self.m_nz_tot, self.m_n_lines, self.m_initial_temperature)
        self.trans_outputs.t_profile_wall.resize_fill(self.m_nz_tot, self.m_n_lines, self.m_initial_temperature)
        self.trans_outputs.tube_temp_inlet = self.m_initial_temperature
        self.trans_outputs.tube_temp_outlet = self.m_initial_temperature
        self.param_inputs.T_amb = QNAN
        self.param_inputs.T_sky = QNAN
        self.param_inputs.c_htf = QNAN
        self.param_inputs.rho_htf = QNAN
        self.param_inputs.mu_htf = QNAN
        self.param_inputs.k_htf = QNAN
        self.param_inputs.Pr_htf = QNAN
        self.param_inputs.Tfeval.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.param_inputs.Tseval.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.param_inputs.qinc.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
        self.param_inputs.qheattrace.resize_fill(self.m_n_elem, 0.0)
        return

    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: C_pt_receiver.S_inputs, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var field_eff = inputs.m_field_eff
        var flux_map_input = inputs.m_flux_map_input
        var input_operation_mode = inputs.m_input_operation_mode
        if input_operation_mode < C_csp_collector_receiver.OFF or input_operation_mode > C_csp_collector_receiver.STEADY_STATE:
            var error_msg = util.format("Input operation mode must be either [0,1,2], but value is %d", input_operation_mode)
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
        var n_flux_y = Int(flux_map_input.nrows())
        if n_flux_y > 1:
            var error_msg = util.format("The Molten Salt External Receiver (Type222) model does not currently support 2-dimensional flux maps. The flux profile in the vertical dimension will be averaged. NY=%d", n_flux_y)
            self.csp_messages.add_message(C_csp_messages.WARNING, error_msg)
        var n_flux_x = Int(flux_map_input.ncols())
        self.m_flux_in.resize(n_flux_x)
        var T_sky = CSP.skytemp(T_amb, T_dp, hour)
        self.m_mode = C_csp_collector_receiver.OFF
        self.m_E_su = QNAN
        self.m_t_su = QNAN
        self.m_itermode = 1
        var v_wind = log((self.m_h_tower + self.m_h_rec / 2) / 0.003) / log(10.0 / 0.003) * v_wind_10
        var c_p_coolant, rho_coolant, f, u_coolant, q_conv_sum, q_rad_sum, q_dot_inc_sum, q_dot_inc_min_panel, q_dot_piping_loss = QNAN, QNAN, QNAN, QNAN, QNAN, QNAN, QNAN, QNAN, QNAN
        var eta_therm, m_dot_salt_tot, T_salt_hot, m_dot_salt_tot_ss, T_salt_hot_rec = QNAN, QNAN, QNAN, QNAN, QNAN
        var clearsky = QNAN
        var rec_is_off = false
        var rec_is_defocusing = false
        var field_eff_adj = 0.0
        var panel_req_preheat = self.m_tube_flux_preheat * self.m_od_tube * self.m_h_rec * self.m_n_t * 1000
        var total_req_preheat = (self.m_tube_flux_preheat * self.m_od_tube * self.m_h_rec * self.m_n_t) * self.m_n_panels * 1000
        var startup_low_flux = false
        var q_thermal_ss = 0.0
        var f_rec_timestep = 1.0
        if input_operation_mode == C_csp_collector_receiver.OFF:
            rec_is_off = true
        if zenith > (90.0 - self.m_hel_stow_deploy) or I_bn <= 1.E-6 or (zenith == 0.0 and azimuth == 180.0):
            if self.m_night_recirc == 1:
                I_bn = 0.0
            else:
                self.m_mode = C_csp_collector_receiver.OFF
                rec_is_off = true
        var T_coolant_prop = (self.m_T_salt_hot_target + T_salt_cold_in) / 2.0
        c_p_coolant = field_htfProps.Cp(T_coolant_prop) * 1000.0
        var m_dot_htf_max = self.m_m_dot_htf_max
        if self.m_is_iscc:
            if self.m_ncall == 0:
                var T_amb_C = fmax(self.m_P_amb_low, fmin(self.m_T_amb_high, T_amb - 273.15))
                var P_amb_bar = fmax(self.m_P_amb_low, fmin(self.m_P_amb_high, P_amb / 1.E5))
                self.m_q_iscc_max = self.cycle_calcs.get_ngcc_data(0.0, T_amb_C, P_amb_bar, ngcc_power_cycle.E_solar_heat_max) * 1.E6
            var m_dot_iscc_max = self.m_q_iscc_max / (c_p_coolant * (self.m_T_salt_hot_target - T_salt_cold_in))
            m_dot_htf_max = fmin(self.m_m_dot_htf_max, m_dot_iscc_max)
        if field_eff < self.m_eta_field_iter_prev and self.m_od_control < 1.0:
            self.m_od_control = fmin(self.m_od_control + (1.0 - field_eff / self.m_eta_field_iter_prev), 1.0)
        var soln = s_steady_state_soln()
        var soln_actual = s_steady_state_soln()
        var soln_clearsky = s_steady_state_soln()
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
        clearsky = get_clearsky(weather, hour)
        var clearsky_adj = fmax(clearsky, weather.m_beam)
        if rec_is_off:
            soln.q_dot_inc.resize_fill(self.m_n_panels, 0.0)
        else:
            if self.m_csky_frac <= 0.9999 or fabs(I_bn - clearsky_adj) < 0.001:
                soln_actual = soln
                soln_actual.dni = I_bn
                if self.use_previous_solution(soln_actual, self.m_mflow_soln_prev):
                    soln_actual = self.m_mflow_soln_prev
                else:
                    self.solve_for_mass_flow_and_defocus(soln_actual, m_dot_htf_max, flux_map_input)
            if self.m_csky_frac >= 0.0001:
                if fabs(I_bn - clearsky_adj) < 0.001:
                    soln_clearsky = soln_actual
                else:
                    soln_clearsky = soln
                    soln_clearsky.dni = clearsky_adj
                    if self.use_previous_solution(soln_clearsky, self.m_mflow_soln_csky_prev):
                        soln_clearsky = self.m_mflow_soln_csky_prev
                    else:
                        self.solve_for_mass_flow_and_defocus(soln_clearsky, m_dot_htf_max, flux_map_input)
            self.m_mflow_soln_prev = soln_actual
            self.m_mflow_soln_csky_prev = soln_clearsky
            if fabs(I_bn - clearsky_adj) < 0.001 or self.m_csky_frac < 0.0001:
                soln = soln_actual
            elif soln_clearsky.rec_is_off:
                soln.rec_is_off = true
                soln.q_dot_inc = soln_clearsky.q_dot_inc
            elif self.m_csky_frac > 0.9999:
                soln.m_dot_salt = soln_clearsky.m_dot_salt
                soln.rec_is_off = soln_clearsky.rec_is_off
                soln.q_dot_inc = self.calculate_flux_profiles(I_bn, field_eff, soln_clearsky.od_control, flux_map_input)
                self.calculate_steady_state_soln(soln, 0.00025)
            else:
                if soln_actual.rec_is_off:
                    soln_actual.m_dot_salt = self.m_f_rec_min * self.m_m_dot_htf_max
                    soln_actual.od_control = 1.0
                soln.rec_is_off = false
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
        var q_thermal_csky = 0.0
        if self.m_csky_frac > 0.0001:
            q_thermal_csky = soln_clearsky.Q_thermal
        var DELTAP, Pres_D, W_dot_pump, q_thermal, q_startup = QNAN, QNAN, QNAN, QNAN, QNAN
        if self.m_is_startup_transient:
            if self.m_mode_prev == C_csp_collector_receiver.OFF or self.m_mode_prev == C_csp_collector_receiver.STARTUP:
                if rec_is_off and q_dot_inc_sum >= total_req_preheat and q_dot_inc_min_panel >= panel_req_preheat:
                    rec_is_off = false
                    startup_low_flux = true
        if not rec_is_off and (self.m_is_transient or self.m_is_startup_transient) and (input_operation_mode != C_csp_collector_receiver.STEADY_STATE):
            self.trans_inputs.inlet_temp = T_salt_cold_in
            self.trans_inputs.tinit = self.m_tinit
            self.trans_inputs.tinit_wall = self.m_tinit_wall
            self.initialize_transient_param_inputs(soln, self.param_inputs)
        var q_heat_trace_energy = 0.0
        var q_startup_energy = 0.0
        q_startup = 0.0
        var time_required_su = step / 3600.0
        if not rec_is_off:
            m_dot_salt_tot_ss = m_dot_salt_tot
            var m_dot_rec_des = self.m_q_rec_des / (c_p_coolant * (self.m_T_htf_hot_des - self.m_T_htf_cold_des))
            if input_operation_mode == C_csp_collector_receiver.STARTUP:
                if not self.m_is_startup_transient:
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
                    rec_is_off = true
                    self.calc_pump_performance(rho_coolant, m_dot_salt_tot, f, Pres_D, W_dot_pump)
                    if self.m_is_transient and self.m_mode == C_csp_collector_receiver.ON:
                        self.param_inputs.tm = self.m_tm
                        self.param_inputs.mflow_tot = m_dot_salt_tot
                        self.param_inputs.finitial = 1.0
                        self.param_inputs.ffinal = 1.0
                        self.param_inputs.ramptime = 0.0
                        self.update_pde_parameters(false, self.param_inputs, self.trans_inputs)
                        self.calc_ss_profile(self.trans_inputs, self.trans_outputs.t_profile, self.trans_outputs.t_profile_wall)
                if self.m_is_startup_transient:
                    var time_remaining = step
                    var min_circulate_time = 0.0
                    if q_dot_inc_sum >= total_req_preheat and q_dot_inc_min_panel >= panel_req_preheat:
                        var heat_trace_target = self.m_T_htf_cold_des
                        var preheat_target = self.m_preheat_target
                        var circulation_target = T_salt_hot + self.m_startup_target_delta
                        var m_dot_salt_startup = 0.0
                        var Tmin_rec, Tmin_piping = QNAN, QNAN
                        self.m_mode = C_csp_collector_receiver.STARTUP
                        if self.m_startup_mode_initial == -1:
                            self.m_startup_mode = self.HEAT_TRACE
                            self.m_total_startup_time_initial = 0.0
                            self.m_total_ramping_time_initial = 0.0
                            self.m_total_preheat_time_initial = 0.0
                            self.m_total_fill_time_initial = 0.0
                            self.m_n_call_fill_initial = -1
                            self.m_minimum_startup_time = self.m_rec_su_delay * 3600.0
                            if not self.m_is_startup_from_solved_profile:
                                self.trans_inputs.tinit.fill(T_amb)
                                self.trans_inputs.tinit_wall.fill(T_amb)
                        else:
                            self.m_startup_mode = self.m_startup_mode_initial
                        Tmin_rec = 5000.0
                        Tmin_piping = 5000.0
                        for i in range(self.m_n_lines):
                            for j in range(self.m_n_elem):
                                var p1 = self.trans_inputs.startpt.at(j)
                                var Twall_min = fmin(self.trans_inputs.tinit.at(p1, i), self.trans_inputs.tinit.at(p1 + self.trans_inputs.nz.at(j) - 1, i))
                                if self.m_flowelem_type.at(j, i) >= 0:
                                    Tmin_rec = fmin(Tmin_rec, Twall_min)
                                if self.m_flowelem_type.at(j, i) == -1 or self.m_flowelem_type.at(j, i) == -2:
                                    Tmin_piping = fmin(Tmin_piping, Twall_min)
                        if self.m_startup_mode_initial == -1 and not self.m_is_enforce_min_startup and Tmin_rec > preheat_target:
                            self.m_minimum_startup_time = 0.0
                        self.m_total_startup_time = self.m_total_startup_time_initial
                        self.m_total_ramping_time = self.m_total_ramping_time_initial
                        self.m_total_preheat_time = self.m_total_preheat_time_initial
                        self.m_total_fill_time = self.m_total_fill_time_initial
                        self.m_n_call_fill = self.m_n_call_fill_initial
                        var tinit_start = self.trans_inputs.tinit
                        var tinit_wall_start = self.trans_inputs.tinit_wall
                        var q_inc_panel_full = self.param_inputs.qinc
                        var time_flow = 0.0
                        while time_remaining > 0.1 and self.m_mode == C_csp_collector_receiver.STARTUP:
                            self.trans_inputs.lam1.fill(0.0)
                            self.trans_inputs.lam2.fill(0.0)
                            self.trans_inputs.cval.fill(0.0)
                            self.param_inputs.qinc.fill(0.0)
                            self.param_inputs.qheattrace.fill(0.0)
                            self.param_inputs.finitial = 1.0
                            self.param_inputs.ffinal = 1.0
                            self.param_inputs.ramptime = 0.0
                            var time, energy, parasitic = QNAN, QNAN, QNAN
                            if self.m_startup_mode == self.HEAT_TRACE:
                                if Tmin_piping > heat_trace_target:
                                    self.m_startup_mode = self.PREHEAT
                                else:
                                    self.param_inputs.qinc.fill(0.0)
                                    self.param_inputs.tm = self.m_tm_solid
                                    self.param_inputs.mflow_tot = 0.0
                                    self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.HEAT_TRACE, heat_trace_target, 0.0, time_remaining, self.trans_outputs, time, energy, parasitic)
                                    q_heat_trace_energy += parasitic
                                    self.m_total_startup_time += time
                                    time_remaining -= time
                                    self.m_startup_mode = self.HEAT_TRACE
                                    if time_remaining > 0:
                                        self.m_startup_mode = self.PREHEAT
                                        self.trans_inputs.tinit = self.trans_outputs.t_profile
                                        self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                            elif self.m_startup_mode == self.PREHEAT:
                                if Tmin_rec > preheat_target:
                                    self.m_startup_mode = self.FILL
                                else:
                                    self.param_inputs.mflow_tot = 0.0
                                    self.param_inputs.tm = self.m_tm_solid
                                    self.param_inputs.qinc.fill(self.m_tube_flux_preheat * 1000. * self.m_od_tube * self.m_h_rec)
                                    self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.PREHEAT, preheat_target, 0.0, time_remaining, self.trans_outputs, time, energy, parasitic)
                                    q_startup_energy += energy
                                    q_heat_trace_energy += parasitic
                                    self.m_total_preheat_time += time
                                    self.m_total_startup_time += time
                                    time_remaining -= time
                                    self.m_startup_mode = self.PREHEAT
                                    if time_remaining > 0:
                                        if self.m_total_preheat_time < self.m_min_preheat_time:
                                            self.m_startup_mode = self.PREHEAT_HOLD
                                        else:
                                            self.m_startup_mode = self.FILL
                                        self.trans_inputs.tinit = self.trans_outputs.t_profile
                                        self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                            elif self.m_startup_mode == self.PREHEAT_HOLD:
                                self.param_inputs.mflow_tot = 0.0
                                self.param_inputs.tm = self.m_tm_solid
                                var time_preheat = fmax(0.01, fmin(time_remaining, self.m_min_preheat_time - self.m_total_preheat_time))
                                self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.PREHEAT_HOLD, preheat_target, 0.0, time_preheat, self.trans_outputs, time, energy, parasitic)
                                q_startup_energy += energy
                                q_heat_trace_energy += parasitic
                                self.m_total_preheat_time += time
                                self.m_total_startup_time += time
                                time_remaining -= time
                                self.m_startup_mode = self.PREHEAT_HOLD
                                if time_remaining > 0:
                                    self.m_startup_mode = self.FILL
                                    self.trans_inputs.tinit = self.trans_outputs.t_profile
                                    self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                            elif self.m_startup_mode == self.FILL:
                                self.m_n_call_fill += 1
                                if self.m_n_call_fill == 0:
                                    for j in range(self.m_n_elem):
                                        var tinit_avg = (self.m_tm_solid.at(j) / self.m_tm.at(j)) * self.trans_inputs.tinit.at(self.trans_inputs.startpt.at(j), 0) + (1.0 - self.m_tm_solid.at(j) / self.m_tm.at(j)) * T_salt_cold_in
                                        for i in range(self.m_n_lines):
                                            for kk in range(self.trans_inputs.nz.at(j)):
                                                self.trans_inputs.tinit.at(self.trans_inputs.startpt.at(j) + kk, i) = tinit_avg
                                self.trans_inputs.tinit_wall = self.trans_inputs.tinit
                                self.param_inputs.mflow_tot = 0.0
                                self.param_inputs.tm = self.m_tm
                                var fill_time = fmax(0.01, fmin(time_remaining, self.m_fill_time - self.m_total_fill_time))
                                self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.FILL, 0.0, 0.0, fill_time, self.trans_outputs, time, energy, parasitic)
                                q_startup_energy += energy
                                q_heat_trace_energy += parasitic
                                self.m_total_fill_time += time
                                self.m_total_startup_time += time
                                time_remaining -= time
                                self.m_startup_mode = self.FILL
                                if time_remaining > 0:
                                    self.m_startup_mode = self.CIRCULATE
                                    self.trans_inputs.tinit = self.trans_outputs.t_profile
                                    self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                            elif self.m_startup_mode == self.CIRCULATE:
                                m_dot_salt_startup = fmax(m_dot_salt_tot, self.m_f_rec_min * m_dot_rec_des)
                                self.param_inputs.mflow_tot = m_dot_salt_startup
                                self.param_inputs.tm = self.m_tm
                                self.param_inputs.qinc = q_inc_panel_full
                                var ramp_time = 0.0
                                if self.m_flux_ramp_time > 0.0:
                                    ramp_time = fmin(time_remaining, self.m_flux_ramp_time - self.m_total_ramping_time)
                                    self.param_inputs.ramptime = ramp_time
                                    self.param_inputs.finitial = fmin(1.0, self.m_total_ramping_time / self.m_flux_ramp_time)
                                    self.param_inputs.ffinal = fmin(1.0, (self.m_total_ramping_time + self.param_inputs.ramptime) / self.m_flux_ramp_time)
                                self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.CIRCULATE, circulation_target, min_circulate_time, time_remaining, self.trans_outputs, time, energy, parasitic)
                                q_startup_energy += energy
                                q_heat_trace_energy += parasitic
                                self.m_total_startup_time += time
                                self.m_total_ramping_time += ramp_time
                                time_flow += time
                                time_remaining -= time
                                if time_remaining <= 1e-6 or self.trans_outputs.tout < circulation_target:
                                    self.m_startup_mode = self.CIRCULATE
                                else:
                                    if self.m_total_startup_time < self.m_minimum_startup_time:
                                        self.m_startup_mode = self.HOLD
                                        self.trans_inputs.tinit = self.trans_outputs.t_profile
                                        self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                                    else:
                                        self.m_mode = C_csp_collector_receiver.ON
                                        self.m_startup_mode = -1
                            elif self.m_startup_mode == self.HOLD:
                                var required_hold_time = self.m_minimum_startup_time - self.m_total_startup_time
                                var time_hold = fmax(0.01, fmin(required_hold_time, time_remaining))
                                self.param_inputs.tm = self.m_tm
                                self.param_inputs.qinc = q_inc_panel_full
                                m_dot_salt_startup = fmax(m_dot_salt_tot, self.m_f_rec_min * m_dot_rec_des)
                                self.param_inputs.mflow_tot = m_dot_salt_startup
                                if time_hold >= time_remaining:
                                    self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.HOLD, 0.0, 0.0, time_remaining, self.trans_outputs, time, energy, parasitic)
                                    q_startup_energy += energy
                                    q_heat_trace_energy += parasitic
                                    self.m_total_startup_time += time
                                    time_flow += time
                                    time_remaining -= time
                                    self.m_startup_mode = self.HOLD
                                else:
                                    self.m_startup_mode = self.CIRCULATE
                                    min_circulate_time = time_hold
                    else:
                        q_startup = 0.0
                        self.m_mode = C_csp_collector_receiver.OFF
                    rec_is_off = true
                    if self.m_startup_mode != -1 and q_dot_inc_sum >= total_req_preheat and q_dot_inc_min_panel >= panel_req_preheat:
                        q_startup = q_startup_energy / 3600.0
                        time_required_su = (step - time_remaining) / 3600.0
                        self.trans_inputs.tinit = tinit_start
                        self.trans_inputs.tinit_wall = tinit_wall_start
                        m_dot_salt_tot = m_dot_salt_startup
                        W_dot_pump = 0.0
                        if time_flow > 0:
                            var mu_coolant = field_htfProps.visc(T_coolant_prop)
                            var k_coolant = field_htfProps.cond(T_coolant_prop)
                            rho_coolant = field_htfProps.dens(T_coolant_prop, 1.0)
                            var fstartup, Nusselt_t
                            u_coolant = m_dot_salt_tot / (self.m_n_t * rho_coolant * pow((self.m_id_tube / 2.0), 2) * CSP.pi)
                            var Re_inner = rho_coolant * u_coolant * self.m_id_tube / mu_coolant
                            var Pr_inner = c_p_coolant * mu_coolant / k_coolant
                            CSP.PipeFlow(Re_inner, Pr_inner, self.m_LoverD, self.m_RelRough, Nusselt_t, fstartup)
                            self.calc_pump_performance(rho_coolant, m_dot_salt_tot, fstartup, Pres_D, W_dot_pump)
                            W_dot_pump = W_dot_pump * time_flow / (time_required_su * 3600.0)
                    else:
                        if q_dot_inc_sum < total_req_preheat or q_dot_inc_min_panel < panel_req_preheat:
                            self.m_mode = C_csp_collector_receiver.OFF
            elif input_operation_mode == C_csp_collector_receiver.ON:
                if not self.m_is_transient:
                    if self.m_E_su_prev > 0.0 or self.m_t_su_prev > 0.0:
                        self.m_E_su = fmax(0.0, self.m_E_su_prev - m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0)
                        self.m_t_su = fmax(0.0, self.m_t_su_prev - step / 3600.0)
                        if self.m_E_su + self.m_t_su > 0.0:
                            self.m_mode = C_csp_collector_receiver.STARTUP
                            q_startup = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in) * step / 3600.0
                            rec_is_off = true
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
                        if q_dot_inc_sum < self.m_q_dot_inc_min:
                            self.m_mode = C_csp_collector_receiver.OFF
                            W_dot_pump = 0.0
                            DELTAP = 0.0
                            Pres_D = 0.0
                            u_coolant = 0.0
                    q_thermal = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                    q_thermal_ss = m_dot_salt_tot_ss * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                    self.calc_pump_performance(rho_coolant, m_dot_salt_tot, f, Pres_D, W_dot_pump)
                    if self.m_mode == C_csp_collector_receiver.ON and self.m_is_startup_from_solved_profile:
                        self.param_inputs.tm = self.m_tm
                        self.param_inputs.mflow_tot = m_dot_salt_tot
                        self.update_pde_parameters(false, self.param_inputs, self.trans_inputs)
                        self.calc_ss_profile(self.trans_inputs, self.trans_outputs.t_profile, self.trans_outputs.t_profile_wall)
                if self.m_is_transient:
                    q_startup = 0.0
                    self.m_mode = C_csp_collector_receiver.ON
                    q_thermal = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                    q_thermal_ss = m_dot_salt_tot_ss * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                    self.calc_pump_performance(rho_coolant, m_dot_salt_tot, f, Pres_D, W_dot_pump)
                    if q_dot_inc_sum < self.m_q_dot_inc_min:
                        self.m_mode = C_csp_collector_receiver.OFF
                        W_dot_pump = 0.0
                        DELTAP = 0.0
                        Pres_D = 0.0
                        u_coolant = 0.0
                    else:
                        self.param_inputs.tm = self.m_tm
                        self.param_inputs.mflow_tot = m_dot_salt_tot
                        self.param_inputs.finitial = 1.0
                        self.param_inputs.ffinal = 1.0
                        self.param_inputs.ramptime = 0.0
                        self.solve_transient_model(step, 100.0, self.param_inputs, self.trans_inputs, self.trans_outputs)
                        self.trans_outputs.timeavg_eta_therm = 1.0 - (self.trans_outputs.timeavg_conv_loss + self.trans_outputs.timeavg_rad_loss) / q_dot_inc_sum
                if q_dot_inc_sum < self.m_q_dot_inc_min:
                    rec_is_off = true
            elif input_operation_mode == C_csp_collector_receiver.STEADY_STATE:
                self.m_mode = C_csp_collector_receiver.STEADY_STATE
                f_rec_timestep = 1.0
                self.calc_pump_performance(rho_coolant, m_dot_salt_tot, f, Pres_D, W_dot_pump)
                q_thermal = m_dot_salt_tot * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                q_thermal_ss = m_dot_salt_tot_ss * c_p_coolant * (T_salt_hot - T_salt_cold_in)
                if self.m_is_startup_transient and startup_low_flux:
                    q_thermal = q_dot_inc_sum
                else:
                    if q_dot_inc_sum < self.m_q_dot_inc_min and self.m_mode_prev == C_csp_collector_receiver.ON:
                        rec_is_off = true
        else:
            self.m_mode = C_csp_collector_receiver.OFF
            W_dot_pump = 0.0
            DELTAP = 0.0
            Pres_D = 0.0
            u_coolant = 0.0
            self.m_startup_mode_initial = -1
            self.m_startup_mode = -1
        if rec_is_off:
            m_dot_salt_tot = 0.0
            eta_therm = 0.0
            q_conv_sum = 0.0
            q_rad_sum = 0.0
            self.m_T_s.fill(0.0)
            q_thermal = 0.0
            T_salt_hot = self.m_T_htf_cold_des
            T_salt_hot_rec = self.m_T_htf_cold_des
            q_dot_inc_sum = 0.0
            m_dot_salt_tot_ss = 0.0
            f_rec_timestep = 0.0
            q_thermal_ss = 0.0
            q_thermal_csky = 0.0
            q_thermal_steadystate = 0.0
            self.m_od_control = 1.0
            if self.m_is_transient or self.m_is_startup_transient:
                self.trans_outputs.timeavg_conv_loss = 0.0
                self.trans_outputs.timeavg_rad_loss = 0.0
                self.trans_outputs.timeavg_piping_loss = 0.0
                self.trans_outputs.timeavg_qthermal = 0.0
                self.trans_outputs.timeavg_tout = self.m_T_htf_cold_des
                self.trans_outputs.tout = self.m_T_htf_cold_des
                self.trans_outputs.max_tout = self.m_T_htf_cold_des
                self.trans_outputs.min_tout = self.m_T_htf_cold_des
                self.trans_outputs.max_rec_tout = self.m_T_htf_cold_des
        self.outputs.m_m_dot_salt_tot = m_dot_salt_tot * 3600.0
        self.outputs.m_eta_therm = eta_therm
        self.outputs.m_W_dot_pump = W_dot_pump / 1.E6
        self.outputs.m_q_conv_sum = q_conv_sum / 1.E6
        self.outputs.m_q_rad_sum = q_rad_sum / 1.E6
        self.outputs.m_Q_thermal = q_thermal / 1.E6
        self.outputs.m_T_salt_hot = T_salt_hot - 273.15
        self.outputs.m_field_eff_adj = field_eff_adj
        self.outputs.m_component_defocus = self.m_od_control
        self.outputs.m_q_dot_rec_inc = q_dot_inc_sum / 1.E6
        self.outputs.m_q_startup = q_startup / 1.E6
        self.outputs.m_dP_receiver = DELTAP * self.m_n_panels / self.m_n_lines / 1.E5
        self.outputs.m_dP_total = Pres_D * 10.0
        self.outputs.m_vel_htf = u_coolant
        self.outputs.m_T_salt_cold = T_salt_cold_in - 273.15
        self.outputs.m_m_dot_ss = m_dot_salt_tot_ss * 3600.0
        self.outputs.m_q_dot_ss = q_thermal_ss / 1.E6
        self.outputs.m_f_timestep = f_rec_timestep
        self.outputs.m_time_required_su = time_required_su * 3600.0
        if q_thermal > 0.0:
            self.outputs.m_q_dot_piping_loss = q_dot_piping_loss / 1.E6
        else:
            self.outputs.m_q_dot_piping_loss = 0.0
        self.outputs.m_inst_T_salt_hot = T_salt_hot - 273.15
        self.outputs.m_max_T_salt_hot = T_salt_hot - 273.15
        self.outputs.m_min_T_salt_hot = T_salt_hot - 273.15
        self.outputs.m_max_rec_tout = T_salt_hot_rec - 273.15
        self.outputs.m_q_heattrace = 0.0
        self.outputs.m_Twall_inlet = 0.0
        self.outputs.m_Twall_outlet = 0.0
        self.outputs.m_Triser = 0.0
        self.outputs.m_Tdownc = 0.0
        if (self.m_is_transient and input_operation_mode == C_csp_collector_receiver.ON) or (self.m_is_startup_transient and input_operation_mode == C_csp_collector_receiver.STARTUP):
            if q_dot_inc_sum == 0.0:
                self.outputs.m_eta_therm = 0.0
            else:
                self.outputs.m_eta_therm = self.trans_outputs.timeavg_eta_therm
            self.outputs.m_q_conv_sum = self.trans_outputs.timeavg_conv_loss / 1.e6
            self.outputs.m_q_rad_sum = self.trans_outputs.timeavg_rad_loss / 1.e6
            self.outputs.m_Q_thermal = self.trans_outputs.timeavg_qthermal / 1.e6
            self.outputs.m_q_dot_piping_loss = self.trans_outputs.timeavg_piping_loss / 1.e6
            self.outputs.m_q_heattrace = q_heat_trace_energy / 1.e6 / 3600.0
            self.outputs.m_T_salt_hot = self.trans_outputs.timeavg_tout - 273.15
            self.outputs.m_inst_T_salt_hot = self.trans_outputs.tout - 273.15
            self.outputs.m_max_T_salt_hot = self.trans_outputs.max_tout - 273.15
            self.outputs.m_min_T_salt_hot = self.trans_outputs.min_tout - 273.15
            self.outputs.m_max_rec_tout = self.trans_outputs.max_rec_tout - 273.15
            self.outputs.m_Twall_inlet = self.trans_outputs.tube_temp_inlet - 273.15
            self.outputs.m_Twall_outlet = self.trans_outputs.tube_temp_outlet - 273.15
            self.outputs.m_Triser = self.trans_outputs.t_profile.at(0, 0) - 273.15
            self.outputs.m_Tdownc = self.trans_outputs.t_profile.at(self.m_nz_tot-1, 0) - 273.15
        self.outputs.m_clearsky = clearsky
        self.outputs.m_Q_thermal_csky_ss = q_thermal_csky / 1.e6
        self.outputs.m_Q_thermal_ss = q_thermal_steadystate / 1.e6
        self.ms_outputs = self.outputs
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
        self.outputs.m_inst_T_salt_hot = 0.0
        self.outputs.m_max_T_salt_hot = 0.0
        self.outputs.m_min_T_salt_hot = 0.0
        self.outputs.m_max_rec_tout = 0.0
        self.outputs.m_q_heattrace = 0.0
        self.outputs.m_Twall_inlet = 0.0
        self.outputs.m_Twall_outlet = 0.0
        self.outputs.m_Triser = 0.0
        self.outputs.m_Tdownc = 0.0
        self.m_startup_mode = -1
        if self.m_is_startup_from_solved_profile:
            var step = sim_info.ms_ts.m_step
            var hour = sim_info.ms_ts.m_time / 3600.0
            self.param_inputs.T_amb = weather.m_tdry + 273.15
            self.param_inputs.T_sky = CSP.skytemp(weather.m_tdry + 273.15, weather.m_tdew + 273.15, hour)
            self.param_inputs.qinc.fill(0.0)
            self.param_inputs.tm = self.m_tm_solid
            self.param_inputs.mflow_tot = 0.0
            self.param_inputs.wspd = weather.m_wspd
            self.param_inputs.pres = weather.m_pres * 100.
            self.trans_inputs.tinit = self.m_tinit_wall
            self.trans_inputs.tinit_wall = self.m_tinit_wall
            self.trans_inputs.inlet_temp = 0.0
            self.solve_transient_model(step, 50.0, self.param_inputs, self.trans_inputs, self.trans_outputs)
            self.outputs.m_Twall_inlet = self.trans_outputs.tube_temp_inlet - 273.15
            self.outputs.m_Twall_outlet = self.trans_outputs.tube_temp_outlet - 273.15
            self.outputs.m_Triser = self.trans_outputs.t_profile.at(0, 0) - 273.15
            self.outputs.m_Tdownc = self.trans_outputs.t_profile.at(self.trans_inputs.startpt.at(self.m_n_elem - 1), 0) - 273.15
            for j in range(self.m_n_elem):
                if self.m_flowelem_type.at(j, 0) == -3:
                    for i in range(self.m_n_lines):
                        self.trans_outputs.timeavg_temp.at(j, i) = self.trans_outputs.timeavg_temp.at(j-1, i)
                        var krec = self.trans_inputs.startpt.at(j-1)
                        for qq in range(self.trans_inputs.nz.at(j)):
                            var kk = self.trans_inputs.startpt.at(j) + qq
                            self.trans_outputs.t_profile.at(kk, i) = self.trans_outputs.t_profile.at(krec, i)
                            self.trans_outputs.t_profile_wall.at(kk, i) = self.trans_outputs.t_profile.at(kk, i)
        self.outputs.m_clearsky = get_clearsky(weather, sim_info.ms_ts.m_time / 3600.)
        self.outputs.m_Q_thermal_csky_ss = 0.0
        self.outputs.m_Q_thermal_ss = 0.0
        self.ms_outputs = self.outputs
        return

    def converged(inout self):
        if self.m_mode == C_csp_collector_receiver.STEADY_STATE:
            raise C_csp_exception("Receiver should only be run at STEADY STATE mode for estimating output. It must be run at a different mode before exiting a timestep", "MSPT receiver converged method")
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
        self.m_startup_mode_initial = self.m_startup_mode
        self.m_n_call_fill_initial = self.m_n_call_fill
        self.m_total_startup_time_initial = self.m_total_startup_time
        self.m_total_ramping_time_initial = self.m_total_ramping_time
        self.m_total_preheat_time_initial = self.m_total_preheat_time
        self.m_total_fill_time_initial = self.m_total_fill_time
        self.m_tinit = self.trans_outputs.t_profile
        self.m_tinit_wall = self.trans_outputs.t_profile_wall
        self.ms_outputs = self.outputs

    def use_previous_solution(inout self, soln: s_steady_state_soln, soln_prev: s_steady_state_soln) -> Bool:
        if not soln_prev.rec_is_off and soln.dni == soln_prev.dni and soln.T_salt_cold_in == soln_prev.T_salt_cold_in and soln.field_eff == soln_prev.field_eff and soln.od_control == soln_prev.od_control and soln.T_amb == soln_prev.T_amb and soln.T_dp == soln_prev.T_dp and soln.v_wind_10 == soln_prev.v_wind_10 and soln.p_amb == soln_prev.p_amb:
            return true
        else:
            return false

    def calculate_flux_profiles(inout self, dni: Float64, field_eff: Float64, od_control: Float64, flux_map_input: matrix_t[Float64]) -> matrix_t[Float64]:
        var q_dot_inc = matrix_t[Float64]()
        var flux = matrix_t[Float64]()
        q_dot_inc.resize_fill(self.m_n_panels, 0.0)
        var field_eff_adj = field_eff * od_control
        var n_flux_y = Int(flux_map_input.nrows())
        var n_flux_x = Int(flux_map_input.ncols())
        flux.resize_fill(n_flux_x, 0.0)
        if dni > 1.0:
            for j in range(n_flux_x):
                flux.at(j) = 0.0
                for i in range(n_flux_y):
                    flux.at(j) += flux_map_input.at(i, j) * dni * field_eff_adj * self.m_A_sf / 1000.0 / (CSP.pi * self.m_h_rec * self.m_d_rec / Float64(n_flux_x))
        else:
            flux.fill(0.0)
        var n_flux_x_d = Float64(self.m_n_flux_x)
        var n_panels_d = Float64(self.m_n_panels)
        if self.m_n_panels >= self.m_n_flux_x:
            for i in range(self.m_n_panels):
                var ppos = (n_flux_x_d / n_panels_d * i + n_flux_x_d * 0.5 / n_panels_d)
                var flo = Int(floor(ppos))
                var ceiling = Int(ceil(ppos))
                var ind = (ppos - flo) / fmax(Float64(ceiling) - Float64(flo), 1.e-6)
                if ceiling > self.m_n_flux_x - 1:
                    ceiling = 0
                var psp_field = (ind * (flux.at(ceiling) - flux.at(flo)) + flux.at(flo))
                q_dot_inc.at(i) = self.m_A_node * psp_field * 1000.0
        else:
            var leftovers = 0.0
            var index_start = 0
            var index_stop = 0
            var q_flux_sum = 0.0
            var panel_step = n_flux_x_d / n_panels_d
            for i in range(self.m_n_panels):
                var panel_pos = panel_step * (i + 1)
                index_start = Int(floor(panel_step * i))
                index_stop = Int(floor(panel_pos))
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
                        var stop_mult = panel_pos - floor(panel_pos)
                        q_flux_sum += stop_mult * flux.at(j)
                        leftovers = (1 - stop_mult) * flux.at(j)
                    else:
                        q_flux_sum += flux[j]
                q_dot_inc.at(i) = q_flux_sum * self.m_A_node / n_flux_x_d * n_panels_d * 1000.0
        return q_dot_inc

    def calculate_steady_state_soln(inout self, soln: inout s_steady_state_soln, tol: Float64, max_iter: Int = 50):
        var P_amb = soln.p_amb
        var hour = soln.hour
        var T_dp = soln.T_dp
        var T_amb = soln.T_amb
        var v_wind_10 = soln.v_wind_10
        var T_sky = CSP.skytemp(T_amb, T_dp, hour)
        var v_wind = log((self.m_h_tower + self.m_h_rec / 2) / 0.003) / log(10.0 / 0.003) * v_wind_10
        var T_s_guess = matrix_t[Float64](self.m_n_panels)
        var T_panel_out_guess = matrix_t[Float64](self.m_n_panels)
        var T_panel_in_guess = matrix_t[Float64](self.m_n_panels)
        var T_film = matrix_t[Float64](self.m_n_panels)
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
        for qq in range(max_iter):
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
            var T_s_sum = 0.0
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
            var h_for = Nusselt_for * k_film / self.m_d_rec * self.m_hl_ffact
            var beta = 1.0 / T_amb
            var nu_amb = ambient_air.visc(T_amb) / ambient_air.dens(T_amb, P_amb)
            for j in range(self.m_n_lines):
                for i in range(self.m_n_panels / self.m_n_lines):
                    var i_fp = self.m_flow_pattern.at(j, i)
                    var Gr_nat = fmax(0.0, CSP.grav * beta * (soln.T_s.at(i_fp) - T_amb) * pow(self.m_h_rec, 3) / pow(nu_amb, 2))
                    var Nusselt_nat = 0.098 * pow(Gr_nat, 1.0 / 3.0) * pow(soln.T_s.at(i_fp) / T_amb, -0.14)
                    var h_nat = Nusselt_nat * ambient_air.cond(T_amb) / self.m_h_rec * self.m_hl_ffact
                    var h_mixed = pow((pow(h_for, self.m_m_mixed) + pow(h_nat, self.m_m_mixed)), 1.0 / self.m_m_mixed) * 4.0
                    soln.q_dot_conv.at(i_fp) = h_mixed * self.m_A_node * (soln.T_s.at(i_fp) - T_film.at(i_fp))
                    soln.q_dot_rad.at(i_fp) = 0.5 * CSP.sigma * self.m_epsilon * self.m_A_node * (2.0 * pow(soln.T_s.at(i_fp), 4) - pow(T_amb, 4) - pow(T_sky, 4)) * self.m_hl_ffact
                    soln.q_dot_loss.at(i_fp) = soln.q_dot_rad.at(i_fp) + soln.q_dot_conv.at(i_fp)
                    soln.q_dot_abs.at(i_fp) = soln.q_dot_inc.at(i_fp) - soln.q_dot_loss.at(i_fp)
                    var T_wall = (soln.T_s.at(i_fp) + soln.T_panel_ave.at(i_fp)) / 2.0
                    var k_tube = tube_material.cond(T_wall)
                    var R_tube_wall = self.m_th_tube / (k_tube * self.m_h_rec * self.m_d_rec * pow(CSP.pi, 2) / 2.0 / Float64(self.m_n_panels))
                    var mu_coolant = field_htfProps.visc(T_coolant_prop)
                    var k_coolant = field_htfProps.cond(T_coolant_prop)
                    var rho_coolant = field_htfProps.dens(T_coolant_prop, 1.0)
                    var u_coolant = soln.m_dot_salt / (self.m_n_t * rho_coolant * pow((self.m_id_tube / 2.0), 2) * CSP.pi)
                    var Re_inner = rho_coolant * u_coolant * self.m_id_tube / mu_coolant
                    var Pr_inner = c_p_coolant * mu_coolant / k_coolant
                    var Nusselt_t, f_inner
                    CSP.PipeFlow(Re_inner, Pr_inner, self.m_LoverD, self.m_RelRough, Nusselt_t, f_inner)
                    if Nusselt_t <= 0.0:
                        soln.mode = C_csp_collector_receiver.OFF
                        break
                    var h_inner = Nusselt_t * k_coolant / self.m_id_tube
                    var R_conv_inner = 1.0 / (h_inner * CSP.pi * self.m_id_tube / 2.0 * self.m_h_rec * self.m_n_t)
                    soln.u_salt = u_coolant
                    soln.f = f_inner
                    if i > 0:
                        var i_prev = self.m_flow_pattern.at(j, i - 1)
                        T_panel_in_guess.at(i_fp) = T_panel_out_guess.at(i_prev)
                    else:
                        T_panel_in_guess.at(i_fp) = soln.T_salt_cold_in
                    T_panel_out_guess.at(i_fp) = T_panel_in_guess.at(i_fp) + soln.q_dot_abs.at(i_fp) / (soln.m_dot_salt * c_p_coolant)
                    var Tavg = (T_panel_out_guess.at(i_fp) + T_panel_in_guess.at(i_fp)) / 2.0
                    T_s_guess.at(i_fp) = Tavg + soln.q_dot_abs.at(i_fp) * (R_conv_inner + R_tube_wall)
                    if T_s_guess.at(i_fp) < 1.0:
                        soln.mode = C_csp_collector_receiver.OFF
            if soln.mode == C_csp_collector_receiver.OFF:
                break
            var klast = self.m_n_panels / self.m_n_lines - 1
            var T_salt_hot_guess_sum = 0.0
            for j in range(self.m_n_lines):
                T_salt_hot_guess_sum += T_panel_out_guess.at(self.m_flow_pattern.at(j, klast))
            soln.T_salt_hot = T_salt_hot_guess_sum / Float64(self.m_n_lines)
            soln.Q_dot_piping_loss = 0.0
            if self.m_Q_dot_piping_loss > 0.0:
                var m_dot_salt_tot_temp = soln.m_dot_salt * self.m_n_lines
                if self.m_piping_loss_coeff != self.m_piping_loss_coeff:
                    soln.Q_dot_piping_loss = self.m_Q_dot_piping_loss
                else:
                    var riser_loss = 2.0 * CSP.pi * (soln.T_salt_cold_in - T_amb) / self.m_Rtot_riser
                    var downc_loss = 2.0 * CSP.pi * (soln.T_salt_hot - T_amb) / self.m_Rtot_downc
                    soln.Q_dot_piping_loss = 0.5 * (riser_loss + downc_loss) * (self.m_h_tower * self.m_pipe_length_mult + self.m_pipe_length_add)
                var delta_T_piping = soln.Q_dot_piping_loss / (m_dot_salt_tot_temp * c_p_coolant)
                soln.T_salt_hot_rec = soln.T_salt_hot
                soln.T_salt_hot -= delta_T_piping
            var err = (soln.T_salt_hot - T_salt_hot_guess) / T_salt_hot_guess
            T_salt_hot_guess = soln.T_salt_hot
            if fabs(err) < tol and qq > 0:
                break
        if soln.T_salt_hot < soln.T_salt_cold_in:
            soln.mode = C_csp_collector_receiver.OFF
        soln.Q_inc_sum = 0.0
        soln.Q_conv_sum = 0.0
        soln.Q_rad_sum = 0.0
        soln.Q_abs_sum = 0.0
        soln.Q_inc_min = soln.q_dot_inc.at(0)
        for i in range(self.m_n_panels):
            soln.Q_inc_sum += soln.q_dot_inc.at(i)
            soln.Q_conv_sum += soln.q_dot_conv.at(i)
            soln.Q_rad_sum += soln.q_dot_rad.at(i)
            soln.Q_abs_sum += soln.q_dot_abs.at(i)
            soln.Q_inc_min = fmin(soln.Q_inc_min, soln.q_dot_inc.at(i))
        soln.Q_thermal = soln.Q_abs_sum - soln.Q_dot_piping_loss
        if soln.Q_inc_sum > 0.0:
            soln.eta_therm = soln.Q_abs_sum / soln.Q_inc_sum
        else:
            soln.eta_therm = 0.0
        soln.rec_is_off = false
        if soln.mode == C_csp_collector_receiver.OFF:
            soln.rec_is_off = true
        if not soln.rec_is_off:
            soln.T_s = T_s_guess
            soln.T_panel_out = T_panel_out_guess
            soln.T_panel_in = T_panel_in_guess
            for i in range(self.m_n_panels):
                soln.T_panel_ave.at(i) = (soln.T_panel_in.at(i) + soln.T_panel_out.at(i)) / 2.0
        return

    def solve_for_mass_flow(inout self, soln: inout s_steady_state_soln):
        var soln_exists = (soln.m_dot_salt == soln.m_dot_salt)
        soln.T_salt_props = (self.m_T_salt_hot_target + soln.T_salt_cold_in) / 2.0
        var c_p_coolant = field_htfProps.Cp(soln.T_salt_props) * 1000.0
        var m_dot_salt_guess: Float64
        if soln_exists:
            m_dot_salt_guess = soln.m_dot_salt
        else:
            var q_dot_inc_sum = 0.0
            for i in range(self.m_n_panels):
                q_dot_inc_sum += soln.q_dot_inc.at(i)
            var c_guess = field_htfProps.Cp((self.m_T_salt_hot_target + soln.T_salt_cold_in) / 2.0) * 1000.0
            if soln.dni > 1.E-6:
                var q_guess = 0.85 * q_dot_inc_sum
                m_dot_salt_guess = q_guess / (c_guess * (self.m_T_salt_hot_target - soln.T_salt_cold_in) * self.m_n_lines)
            else:
                var T_salt_hot = self.m_T_salt_hot_target
                self.m_T_salt_hot_target = soln.T_salt_cold_in
                soln.T_salt_cold_in = T_salt_hot
                m_dot_salt_guess = -3500.0 / (c_guess * (self.m_T_salt_hot_target - soln.T_salt_cold_in) / 2.0)
        var T_salt_hot_guess = 9999.9
        var err = -999.9
        var tol: Float64
        if self.m_night_recirc == 1:
            tol = 0.0057
        else:
            tol = 0.00025
        var qq_max = 50
        var qq = 0
        var converged = false
        while not converged:
            qq += 1
            if qq > qq_max:
                soln.mode = C_csp_collector_receiver.OFF
                soln.rec_is_off = true
                break
            soln.m_dot_salt = m_dot_salt_guess
            var tolT = tol
            self.calculate_steady_state_soln(soln, tolT, 50)
            err = (soln.T_salt_hot - self.m_T_salt_hot_target) / self.m_T_salt_hot_target
            if soln.rec_is_off:
                soln.T_salt_hot = QNAN
            if fabs(err) > tol:
                m_dot_salt_guess = (soln.Q_abs_sum - soln.Q_dot_piping_loss) / (self.m_n_lines * c_p_coolant * (self.m_T_salt_hot_target - soln.T_salt_cold_in))
                if m_dot_salt_guess < 1.E-5:
                    soln.mode = C_csp_collector_receiver.OFF
                    soln.rec_is_off = true
                    break
            elif err > 0.0:
                m_dot_salt_guess *= (soln.T_salt_hot - soln.T_salt_cold_in) / ((1.0 - 0.5 * tol) * self.m_T_salt_hot_target - soln.T_salt_cold_in)
            else:
                converged = true
        soln.m_dot_salt_tot = soln.m_dot_salt * self.m_n_lines
        return

    def solve_for_mass_flow_and_defocus(inout self, soln: inout s_steady_state_soln, m_dot_htf_max: Float64, flux_map_input: matrix_t[Float64]):
        var rec_is_defocusing = true
        var err_od = 999.0
        while rec_is_defocusing:
            if soln.rec_is_off:
                break
            soln.q_dot_inc = self.calculate_flux_profiles(soln.dni, soln.field_eff, soln.od_control, flux_map_input)
            self.solve_for_mass_flow(soln)
            if soln.rec_is_off:
                break
            var m_dot_salt_tot = soln.m_dot_salt * self.m_n_lines
            var m_dot_tube = soln.m_dot_salt / Float64(self.m_n_t)
            rec_is_defocusing = false
            if (m_dot_salt_tot > m_dot_htf_max) or soln.itermode == 2:
                var err_od = (m_dot_salt_tot - m_dot_htf_max) / m_dot_htf_max
                if err_od < self.m_tol_od:
                    soln.itermode = 1
                    soln.od_control = 1.0
                    rec_is_defocusing = false
                else:
                    soln.od_control = soln.od_control * pow((m_dot_htf_max / m_dot_salt_tot), 0.8)
                    soln.itermode = 2
                    rec_is_defocusing = true
        return

    def solve_for_defocus_given_flow(inout self, soln: inout s_steady_state_soln, flux_map_input: matrix_t[Float64]):
        var Tprev, od, odprev, odlow, odhigh = QNAN, QNAN, QNAN, QNAN, QNAN
        var tolT = 0.00025
        var urf = 0.8
        od = soln.od_control
        odhigh = 1.0
        od = odprev * (self.m_T_salt_hot_target - soln.T_salt_cold_in) / (Tprev - soln.T_salt_cold_in)
        var q = 0
        while q < 50:
            soln.od_control = od
            if odprev != odprev:
                soln.q_dot_inc = self.calculate_flux_profiles(soln.dni, soln.field_eff, soln.od_control, flux_map_input)
            else:
                soln.q_dot_inc = soln.q_dot_inc * soln.od_control / odprev
            self.calculate_steady_state_soln(soln, tolT)
            if soln.od_control > 0.9999 and soln.T_salt_hot < self.m_T_salt_hot_target:
                break
            elif fabs(soln.T_salt_hot - self.m_T_salt_hot_target) / self.m_T_salt_hot_target < tolT:
                break
            else:
                if soln.rec_is_off:
                    odlow = soln.od_control
                    od = odlow + 0.5 * (odhigh - odlow)
                elif odprev != odprev:
                    od = odprev * (self.m_T_salt_hot_target - soln.T_salt_cold_in) / (Tprev - soln.T_salt_cold_in)
                else:
                    var delta_od = (soln.T_salt_hot - self.m_T_salt_hot_target) / ((soln.T_salt_hot - Tprev) / (soln.od_control - odprev))
                    var od_new = soln.od_control - urf * delta_od
                    if od_new < odlow or od_new > odhigh:
                        if odlow == odlow:
                            od_new = odlow + 0.5 * (odhigh - odlow)
                        else:
                            od_new = od_new * 0.95 * odhigh
                    od = od_new
                odprev = soln.od_control
                Tprev = soln.T_salt_hot
            q += 1
        return

    def calc_pump_performance(self, rho_f: Float64, mdot: Float64, ffact: Float64, PresDrop_calc: inout Float64, WdotPump_calc: inout Float64):
        var mpertube = mdot / (Float64(self.m_n_lines) * Float64(self.m_n_t))
        var u_coolant = mpertube / (rho_f * self.m_id_tube * self.m_id_tube * 0.25 * CSP.pi)
        var L_e_45 = 16.0
        var L_e_90 = 30.0
        var DELTAP_tube = rho_f * (ffact * self.m_h_rec / self.m_id_tube * pow(u_coolant, 2) / 2.0)
        var DELTAP_45 = rho_f * (ffact * L_e_45 * pow(u_coolant, 2) / 2.0)
        var DELTAP_90 = rho_f * (ffact * L_e_90 * pow(u_coolant, 2) / 2.0)
        var DELTAP = DELTAP_tube + 2 * DELTAP_45 + 4 * DELTAP_90
        var DELTAP_h_tower = rho_f * self.m_h_tower * CSP.grav
        var DELTAP_net = DELTAP * self.m_n_panels / Float64(self.m_n_lines) + DELTAP_h_tower
        PresDrop_calc = DELTAP_net * 1.E-6
        var est_load = fmax(0.25, mdot / self.m_m_dot_htf_des) * 100.0
        var eta_pump_adj = self.m_eta_pump * (-2.8825E-9 * pow(est_load, 4) + 6.0231E-7 * pow(est_load, 3) - 1.3867E-4 * pow(est_load, 2) + 2.0683E-2 * est_load)
        WdotPump_calc = DELTAP_net * mdot / rho_f / eta_pump_adj

    def get_pumping_parasitic_coef(self) -> Float64:
        var Tavg = (self.m_T_htf_cold_des + self.m_T_htf_hot_des) / 2.0
        var mu_coolant = field_htfProps.visc(Tavg)
        var k_coolant = field_htfProps.cond(Tavg)
        var rho_coolant = field_htfProps.dens(Tavg, 1.0)
        var c_p_coolant = field_htfProps.Cp(Tavg) * 1e3
        var m_dot_salt = self.m_q_rec_des / (c_p_coolant * (self.m_T_htf_hot_des - self.m_T_htf_cold_des))
        var n_t = Int(CSP.pi * self.m_d_rec / (self.m_od_tube * self.m_n_panels))
        var id_tube = self.m_od_tube - 2 * self.m_th_tube
        var u_coolant = m_dot_salt / (n_t * rho_coolant * pow((id_tube / 2.0), 2) * CSP.pi)
        var Re_inner = rho_coolant * u_coolant * id_tube / mu_coolant
        var Pr_inner = c_p_coolant * mu_coolant / k_coolant
        var Nusselt_t, f
        var LoverD = self.m_h_rec / id_tube
        var RelRough = (4.5e-5) / id_tube
        CSP.PipeFlow(Re_inner, Pr_inner, LoverD, RelRough, Nusselt_t, f)
        var deltap, wdot: Float64
        self.calc_pump_performance(rho_coolant, m_dot_salt, f, deltap, wdot)
        return wdot / self.m_q_rec_des

    def area_proj(self) -> Float64:
        return CSP.pi * self.m_d_rec * self.m_h_rec

    def calc_external_convection_coeff(self, T_amb: Float64, P_amb: Float64, wspd: Float64, Twall: Float64) -> Float64:
        var v_wind_10 = wspd
        var v_wind = log((self.m_h_tower + self.m_h_rec / 2) / 0.003) / log(10.0 / 0.003) * v_wind_10
        var T_film_ave = 0.5 * (T_amb + Twall)
        var Re_for = ambient_air.dens(T_film_ave, P_amb) * v_wind * self.m_d_rec / ambient_air.visc(T_film_ave)
        var ksD = (self.m_od_tube / 2.0) / self.m_d_rec
        var Nufor = CSP.Nusselt_FC(ksD, Re_for)
        var hfor = Nufor * ambient_air.cond(T_film_ave) / self.m_d_rec
        var nu_amb = ambient_air.visc(T_amb) / ambient_air.dens(T_amb, P_amb)
        var Gr = fmax(0.0, CSP.grav * (Twall - T_amb) * pow(self.m_h_rec, 3) / pow(nu_amb, 2) / T_amb)
        var Nunat = 0.098 * pow(Gr, 1.0 / 3.0) * pow(Twall / T_amb, -0.14)
        var hnat = Nunat * ambient_air.cond(T_amb) / self.m_h_rec
        var hmix = pow((pow(hfor, self.m_m_mixed) + pow(hnat, self.m_m_mixed)), 1.0 / self.m_m_mixed) * 4.0
        return hmix

    def calc_thermal_loss(self, Ts: Float64, T_amb: Float64, T_sky: Float64, P_amb: Float64, wspd: Float64, hext: inout Float64, qconv: inout Float64, qrad: inout Float64):
        var vf = 2.0 / CSP.pi
        var Tfilm = 0.5 * (Ts + T_amb)
        hext = self.calc_external_convection_coeff(T_amb, P_amb, wspd, Ts) * (2.0 / CSP.pi)
        qconv = hext * (Ts - Tfilm) * self.m_hl_ffact
        qrad = vf * CSP.sigma * self.m_epsilon * (pow(Ts, 4) - 0.5 * pow(T_amb, 4) - 0.5 * pow(T_sky, 4)) * self.m_hl_ffact
        return

    def calc_surface_temperature(self, Tf: Float64, qabs: Float64, Rtube: Float64, OD: Float64, T_amb: Float64, T_sky: Float64, P_amb: Float64, wspd: Float64, Tsguess: inout Float64):
        var hext, qconv, qrad: Float64
        var f, dfdT, Tsguessnew: Float64
        var vf = 2.0 / CSP.pi
        var qq = 0
        var delT = 100.0
        while delT > 1.0 and qq < 20:
            self.calc_thermal_loss(Tsguess, T_amb, T_sky, P_amb, wspd, hext, qconv, qrad)
            f = Tsguess - Tf - (qabs - qconv - qrad) * 0.5 * OD * Rtube
            dfdT = 1.0 + 0.5 * OD * Rtube * (hext + 4.0 * vf * self.m_epsilon * CSP.sigma * pow(Tsguess, 3))
            Tsguessnew = Tsguess - f / dfdT
            delT = abs(Tsguessnew - Tsguess)
            Tsguess = Tsguessnew
            qq += 1

    def calc_header_size(self, pdrop: Float64, mdot: Float64, rhof: Float64, muf: Float64, Lh: Float64, id_calc: inout Float64, th_calc: inout Float64, od_calc: inout Float64):
        var id_min, Re_h: Float64
        var fh = 0.015
        var Nucalc = 0.0
        var id_min_prev = 0.0
        for i in range(10):
            id_min = pow(8.0 * fh * mdot * mdot * Lh / rhof / pow(CSP.pi, 2) / pdrop, 0.2)
            Re_h = 4.0 * mdot / CSP.pi / muf / id_min
            CSP.PipeFlow(Re_h, 4.0, Lh / id_min, 4.5e-5 / id_min, Nucalc, fh)
            if fabs(id_calc - id_min_prev) <= 0.001:
                break
            else:
                id_min_prev = id_min
        var wall, id: Float64
        var odin = DynamicVector[Float64]([0.405, 0.54, 0.675, 0.84, 1.05, 1.315, 1.66, 1.9, 2.375, 2.875, 3.5, 4.0, 4.5, 5.563, 6.625, 8.625, 10.75, 12.75, 14.0, 16.0, 18.0, 20.0, 24.0, 32.0, 34.0, 36.0])
        var wallin = DynamicVector[Float64]([0.068, 0.088, 0.091, 0.109, 0.113, 0.133, 0.14, 0.145, 0.154, 0.203, 0.216, 0.226, 0.237, 0.258, 0.28, 0.322, 0.365, 0.406, 0.437, 0.5, 0.562, 0.593, 0.687, 0.688, 0.688, 0.75])
        var i = 0
        while id_min / 0.0254 > odin[i] - 2 * wallin[i] and i <= 25:
            i += 1
        if i <= 25:
            wall = wallin[i] * 0.0254
            id = odin[i] * 0.0254 - 2 * wall
        else:
            id = id_min
            wall = wallin[25] * 0.0254
        id_calc = id
        th_calc = wall
        od_calc = id + 2 * wall

    def interpolate(self, x: Float64, xarray: DynamicVector[Float64], yarray: DynamicVector[Float64], klow: Int, khigh: Int) -> Float64:
        var jl = klow
        var ju = khigh
        var jm: Int
        while ju - jl > 1:
            jm = (ju + jl) / 2
            if x < xarray.at(jm):
                ju = jm
            else:
                jl = jm
        var yinterp = yarray.at(jl) + (yarray.at(ju) - yarray.at(jl)) / (xarray.at(ju) - xarray.at(jl)) * (x - xarray.at(jl))
        return yinterp

    def integrate(self, xlow: Float64, xhigh: Float64, xarray: DynamicVector[Float64], yarray: DynamicVector[Float64], klow: Int, khigh: Int) -> Float64:
        var i = klow
        var j = khigh - 1
        while i < khigh and xarray.at(i) < xlow:
            i += 1
        while j >= klow and xarray.at(i) > xhigh:
            j -= 1
        var y1 = yarray.at(i)
        if i > klow:
            y1 = yarray.at(i) + (yarray.at(i) - yarray.at(i - 1)) / (xarray.at(i) - xarray.at(i - 1)) * (xlow - xarray.at(i))
        var y2 = yarray.at(j)
        if j < khigh:
            y2 = yarray.at(j) + (yarray.at(j) - yarray.at(j + 1)) / (xarray.at(j) - xarray.at(j + 1)) * (xhigh - xarray.at(j))
        var inteval = 0.0
        for k in range(i, j):
            inteval = inteval + (xarray.at(k + 1) - xarray.at(k)) * 0.5 * (yarray.at(k) + yarray.at(k + 1))
        inteval = inteval + (xarray.at(i) - xlow) * 0.5 * (y1 + yarray.at(i))
        if j >= i:
            inteval = inteval + (xhigh - xarray.at(j)) * 0.5 * (yarray.at(j) + y2)
        return inteval

    def cubic_splines(self, xarray: DynamicVector[Float64], yarray: DynamicVector[Float64], splines: inout matrix_t[Float64]):
        var n = xarray.size() - 1
        splines.resize_fill(n, 5, 0.0)
        var a = DynamicVector[Float64](n + 1, 0.0)
        var b = DynamicVector[Float64](n, 0.0)
        var d = DynamicVector[Float64](n, 0.0)
        var h = DynamicVector[Float64](n, 0.0)
        var alpha = DynamicVector[Float64](n, 0.0)
        var c = DynamicVector[Float64](n + 1, 0.0)
        var l = DynamicVector[Float64](n + 1, 0.0)
        var mu = DynamicVector[Float64](n + 1, 0.0)
        var z = DynamicVector[Float64](n + 1, 0.0)
        for i in range(n + 1):
            a.at(i) = yarray.at(i)
        l.at(0) = 1.0
        mu.at(0) = 0.0
        z.at(0) = 0.0
        for i in range(n):
            h.at(i) = xarray.at(i + 1) - xarray.at(i)
            if i > 0:
                alpha.at(i) = (3.0 / h.at(i)) * (a.at(i + 1) - a.at(i)) - (3.0 / h.at(i - 1)) * (a.at(i) - a.at(i - 1))
                l.at(i) = 2.0 * (xarray.at(i + 1) - xarray.at(i - 1)) - h.at(i - 1) * mu.at(i - 1)
                mu.at(i) = h.at(i) / l.at(i)
                z.at(i) = (alpha.at(i) - h.at(i - 1) * z.at(i - 1)) / l.at(i)
        l.at(n) = 1.0
        z.at(n) = 0.0
        c.at(n) = 0.0
        for i in range(n - 1, -1, -1):
            var idx = i
            c.at(idx) = z.at(idx) - mu.at(idx) * c.at(idx + 1)
            b.at(idx) = (a.at(idx + 1) - a.at(idx)) / h.at(idx) - h.at(idx) * (c.at(idx + 1) + 2.0 * c.at(idx)) / 3.0
            d.at(idx) = (c.at(idx + 1) - c.at(idx)) / 3.0 / h.at(idx)
        for i in range(n):
            splines.at(i, 0) = a.at(i)
            splines.at(i, 1) = b.at(i)
            splines.at(i, 2) = c.at(i)
            splines.at(i, 3) = d.at(i)
            splines.at(i, 4) = xarray.at(i)

    def calc_timeavg_exit_temp(self, tstep: Float64, flowid: Int, pathid: Int, tinputs: transient_inputs) -> Float64:
        var Tavg = QNAN
        var p = flowid
        var nelem = tinputs.nelem
        var Tfin = tinputs.inlet_temp
        var lam1 = DynamicVector[Float64](nelem, 0.0)
        var lam2 = DynamicVector[Float64](nelem, 0.0)
        var cval = DynamicVector[Float64](nelem, 0.0)
        var aval = DynamicVector[Float64](nelem, 0.0)
        var len = DynamicVector[Float64](nelem, 0.0)
        var gam = DynamicVector[Float64](nelem, 0.0)
        var Tinit = DynamicVector[Float64](tinputs.nztot, 0.0)
        for i in range(nelem):
            lam1.at(i) = tinputs.lam1.at(i, pathid)
            lam2.at(i) = tinputs.lam2.at(i, pathid)
            cval.at(i) = tinputs.cval.at(i, pathid)
            aval.at(i) = tinputs.aval.at(i, pathid)
            len.at(i) = tinputs.length.at(i)
            gam.at(i) = lam2.at(i) / lam1.at(i)
        for i in range(tinputs.nztot):
            Tinit.at(i) = tinputs.tinit.at(i, pathid)
        var T1 = Tinit.at(tinputs.startpt.at(p) + tinputs.nz.at(p) - 1)
        if tstep < 1.e-3:
            Tavg = T1
        else:
            if lam1.at(p) == 0.0:
                if lam2.at(p) != 0.0:
                    Tavg = (1.0 / lam2.at(p)) * (cval.at(p) - aval.at(p) / lam2.at(p) + aval.at(p) * tstep / 2.0) + (1.0 - exp(-lam2.at(p) * tstep)) / lam2.at(p) / tstep * (T1 - cval.at(p) / lam2.at(p) + aval.at(p) / lam2.at(p) / lam2.at(p))
                else:
                    Tavg = T1 + cval.at(p) * tstep / 2.0 + aval.at(p) * tstep * tstep / 6.0
            else:
                var sum1 = matrix_t[Float64]()
                var mult = matrix_t[Float64]()
                sum1.resize_fill(p+1, p+1, 0.0)
                mult.resize_fill(p+1, p+1, 1.0)
                var Tint = DynamicVector[Float64](tinputs.nztot, 0.0)
                for i in range(p+1):
                    mult.at(i, i) = exp(-gam.at(i) * len.at(i))
                    sum1.at(i, i) = len.at(i) / lam1.at(i)
                    for jj in range(i+1, p+1):
                        mult.at(i, jj) = mult.at(i, jj-1) * exp(-gam.at(jj) * len.at(jj))
                        sum1.at(i, jj) = sum1.at(i, jj-1) + len.at(jj) / lam1.at(jj)
                    var jj = tinputs.startpt.at(i)
                    for kk in range(tinputs.nz.at(i)):
                        Tint.at(jj + kk) = Tinit.at(jj + kk) * exp(gam.at(i) * tinputs.zpts.at(jj + kk))
                var q = p
                var tcritq: Float64
                while q > -1:
                    tcritq = sum1.at(q, p)
                    if tcritq > tstep:
                        break
                    q -= 1
                var qplus1 = q + 1
                var sum = 0.0
                for jj in range(qplus1, p+1):
                    var multval = 1.0
                    if jj + 1 <= p:
                        multval = mult.at(jj + 1, p)
                    var intTj = self.integrate(0.0, len.at(jj), tinputs.zpts, Tint, tinputs.startpt.at(jj), tinputs.startpt.at(jj) + tinputs.nz.at(jj) - 1)
                    var term1, term2, term3: Float64
                    term1 = 1.0 / lam1.at(jj) * exp(-gam.at(jj) * len.at(jj)) * intTj
                    if lam2.at(jj) != 0.0:
                        term2 = (cval.at(jj) / lam2.at(jj) - aval.at(jj) / lam2.at(jj) / lam2.at(jj)) * (len.at(jj) / lam1.at(jj) - (1.0 - exp(-gam.at(jj) * len.at(jj))) / lam2.at(jj)) + aval.at(jj) / 2.0 / lam2.at(jj) * pow((len.at(jj) / lam1.at(jj)), 2)
                        term3 = (tstep - sum1.at(jj, p)) * ((cval.at(jj) / lam2.at(jj) - aval.at(jj) / lam2.at(jj) / lam2.at(jj)) * (1.0 - exp(-gam.at(jj) * len.at(jj))) + (aval.at(jj) * len.at(jj) / lam1.at(jj) / lam2.at(jj)) + (aval.at(jj) / 2.0 / lam2.at(jj)) * (1.0 - exp(-gam.at(jj) * len.at(jj))) * (tstep - sum1.at(jj, p)))
                    else:
                        term2 = pow((len.at(jj) / lam1.at(jj)), 2) * ((cval.at(jj) / 2.0) + (aval.at(jj) / 6.0) * (len.at(jj) / lam1.at(jj)))
                        term3 = (tstep - sum1.at(jj, p)) * (cval.at(jj) + (aval.at(jj) / 2.0) * (len.at(jj) / lam1.at(jj)) + (aval.at(jj) / 2.0) * (tstep - sum1.at(jj, p)))
                    sum += multval * (term1 + term2 + term3)
                var multval_final = 1.0
                if qplus1 <= p:
                    multval_final = mult.at(qplus1, p)
                var M: Float64
                if q == -1:
                    M = Tfin * (tstep - sum1.at(0, p))
                else:
                    var tsub = tstep
                    var term1: Float64
                    if qplus1 <= p:
                        tsub -= sum1.at(qplus1, p)
                    if lam2.at(q) != 0.0:
                        term1 = (cval.at(q) / lam2.at(q) - aval.at(q) / lam2.at(q) / lam2.at(q)) * (tsub - (1.0 / lam2.at(q)) * (1.0 - exp(-lam2.at(q) * tsub))) + aval.at(q) / 2.0 / lam2.at(q) * tsub * tsub
                    else:
                        term1 = tsub * tsub * (cval.at(q) / 2.0 + aval.at(q) / 6.0 * tsub)
                    var intTq = self.integrate(len.at(q) - lam1.at(q) * tsub, len.at(q), tinputs.zpts, Tint, tinputs.startpt.at(q), tinputs.startpt.at(q) + tinputs.nz.at(q) - 1)
                    M = term1 + (1.0 / lam1.at(q)) * exp(-gam.at(q) * len.at(q)) * intTq
                Tavg = (sum + multval_final * M) / tstep
        return Tavg

    def calc_single_pt(self, tpt: Float64, zpt: Float64, flowid: Int, pathid: Int, tinputs: transient_inputs) -> Float64:
        var p = flowid
        var nelem = tinputs.nelem
        var Tfin = tinputs.inlet_temp
        var lam1 = DynamicVector[Float64](nelem, 0.0)
        var lam2 = DynamicVector[Float64](nelem, 0.0)
        var cval = DynamicVector[Float64](nelem, 0.0)
        var aval = DynamicVector[Float64](nelem, 0.0)
        var len = DynamicVector[Float64](nelem, 0.0)
        var gam = DynamicVector[Float64](nelem, 0.0)
        var Tinit = DynamicVector[Float64](tinputs.nztot, 0.0)
        for i in range(nelem):
            lam1.at(i) = tinputs.lam1.at(i, pathid)
            lam2.at(i) = tinputs.lam2.at(i, pathid)
            cval.at(i) = tinputs.cval.at(i, pathid)
            aval.at(i) = tinputs.aval.at(i, pathid)
            len.at(i) = tinputs.length.at(i)
            gam.at(i) = lam2.at(i) / lam1.at(i)
        for i in range(tinputs.nztot):
            Tinit.at(i) = tinputs.tinit.at(i, pathid)
        var np = zpt - lam1.at(p) * tpt
        if lam1.at(p) == 0.0 or np >= 0:
            var Tval = self.interpolate(np, tinputs.zpts, Tinit, tinputs.startpt.at(p), tinputs.startpt.at(p) + tinputs.nz.at(p) - 1)
            if lam2.at(p) != 0.0:
                var Tpt = (cval.at(p) / lam2.at(p) - aval.at(p) / lam2.at(p) / lam2.at(p)) * (1.0 - exp(-lam2.at(p) * tpt)) + aval.at(p) * tpt / lam2.at(p) + Tval * exp(-lam2.at(p) * tpt)
            else:
                var Tpt = Tval + cval.at(p) * tpt + 0.5 * aval.at(p) * tpt * tpt
            return Tpt
        else:
            var Ap: Float64
            if lam2.at(p) != 0.0:
                Ap = (cval.at(p) / lam2.at(p) - (aval.at(p) / lam2.at(p) / lam2.at(p)) * (1. - lam2.at(p) * tpt)) * (1. - exp(-gam.at(p) * zpt)) + aval.at(p) * zpt / lam1.at(p) / lam2.at(p) * exp(-gam.at(p) * zpt)
            else:
                Ap = (zpt / lam1.at(p)) * (cval.at(p) + aval.at(p) * tpt) - (aval.at(p) / 2.0) * pow(zpt / lam1.at(p), 2)
            var k = p
            var nk = -1.0
            var tk = 0.0
            while nk < 0 and k > 0:
                k -= 1
                if k == p - 1:
                    tk = tpt - zpt / lam1.at(p)
                else:
                    var kplus1 = k + 1
                    tk -= len.at(kplus1) / lam1.at(kplus1)
                nk = len.at(k) - lam1.at(k) * tk
            var qq: Int
            if nk >= 0:
                qq = k + 1
            else:
                qq = 0
            var j = p - 1
            var sum = 0.0
            var mult2 = 1.0
            while j >= qq:
                var jplus1 = j + 1
                if j < p - 1:
                    mult2 *= exp(-gam.at(jplus1) * len.at(jplus1))
                var tj = 0.0
                if j == p - 1:
                    tj = tpt - zpt / lam1.at(p)
                else:
                    tj -= len.at(jplus1) / lam1.at(jplus1)
                var Aj: Float64
                if lam2.at(j) != 0.0:
                    Aj = (cval.at(j) / lam2.at(j) - (aval.at(j) / lam2.at(j) / lam2.at(j)) * (1. - lam2.at(j) * tj)) * (1. - exp(-gam.at(j) * len.at(j))) + aval.at(j) * len.at(j) / lam1.at(j) / lam2.at(j) * exp(-gam.at(j) * len.at(j))
                else:
                    Aj = (len.at(j) / lam1.at(j)) * (cval.at(j) + aval.at(j) * tj) - (aval.at(j) / 2.0) * pow(len.at(j) / lam1.at(j), 2)
                sum += Aj * mult2
                j -= 1
            var mult = mult2
            if qq <= p - 1:
                mult *= exp(-gam.at(qq) * len.at(qq))
            if nk >= 0:
                var Tval = self.interpolate(nk, tinputs.zpts, Tinit, tinputs.startpt.at(k), tinputs.startpt.at(k) + tinputs.nz.at(k) - 1)
                var Dk: Float64
                if lam2.at(k) != 0.0:
                    Dk = (cval.at(k) / lam2.at(k) - aval.at(k) / lam2.at(k) / lam2.at(k)) * (1 - exp(-lam2.at(k) * tk)) + aval.at(k) * tk / lam2.at(k) + Tval * exp(-lam2.at(k) * tk)
                else:
                    Dk = cval.at(k) * tk + 0.5 * aval.at(k) * tk * tk + Tval
                var Tpt = Ap + exp(-gam.at(p) * zpt) * (Dk * mult + sum)
                return Tpt
            else:
                var Tpt = Ap + exp(-gam.at(p) * zpt) * (mult * Tfin + sum)
                return Tpt

    def calc_axial_profile(self, tpt: Float64, tinputs: transient_inputs, tprofile: inout matrix_t[Float64]):
        var nelem = tinputs.nelem
        var Tfin = tinputs.inlet_temp
        if tinputs.lam1.at(0, 0) == 0.0:
            for pathid in range(tinputs.npath):
                for j in range(tinputs.nelem):
                    for i in range(tinputs.nz.at(j)):
                        var k = tinputs.startpt.at(j)
                        var Tinit = tinputs.tinit.at(k + i, pathid)
                        var c = tinputs.cval.at(j, pathid)
                        var a = tinputs.aval.at(j, pathid)
                        var lam2 = tinputs.lam2.at(j, pathid)
                        if lam2 != 0:
                            tprofile.at(k + i, pathid) = (c / lam2 + a / lam2 / lam2) * (1.0 - exp(-lam2 * tpt)) + a * tpt / lam2 + Tinit * exp(-lam2 * tpt)
                        else:
                            tprofile.at(k + i, pathid) = Tinit + c * tpt + 0.5 * a * tpt * tpt
        else:
            for pathid in range(tinputs.npath):
                var lam1 = DynamicVector[Float64](nelem, 0.0)
                var lam2 = DynamicVector[Float64](nelem, 0.0)
                var cval = DynamicVector[Float64](nelem, 0.0)
                var aval = DynamicVector[Float64](nelem, 0.0)
                var len = DynamicVector[Float64](nelem, 0.0)
                var gam = DynamicVector[Float64](nelem, 0.0)
                var Tinit = DynamicVector[Float64](tinputs.nztot, 0.0)
                for i in range(nelem):
                    lam1.at(i) = tinputs.lam1.at(i, pathid)
                    lam2.at(i) = tinputs.lam2.at(i, pathid)
                    cval.at(i) = tinputs.cval.at(i, pathid)
                    aval.at(i) = tinputs.aval.at(i, pathid)
                    len.at(i) = tinputs.length.at(i)
                    gam.at(i) = lam2.at(i) / lam1.at(i)
                for i in range(tinputs.nztot):
                    Tinit.at(i) = tinputs.tinit.at(i, pathid)
                var sumAconst = matrix_t[Float64]()
                var sumApos = matrix_t[Float64]()
                var mult = matrix_t[Float64]()
                sumAconst.resize_fill(nelem, nelem, 0.0)
                sumApos.resize_fill(nelem, nelem, 0.0)
                mult.resize_fill(nelem, nelem, 1.0)
                for i in range(nelem):
                    mult.at(i, i) = exp(-gam.at(i) * len.at(i))
                    for jj in range(i+1, nelem):
                        mult.at(i, jj) = mult.at(i, jj-1) * exp(-gam.at(jj) * len.at(jj))
                for i in range(nelem - 1, -1, -1):
                    var sum = 0.0
                    for j in range(i, -1, -1):
                        var Aconst, Apos: Float64
                        if lam2.at(j) != 0.0:
                            Aconst = (cval.at(j) / lam2.at(j) - aval.at(j) / lam2.at(j) * (1.0 / lam2.at(j) - tpt + sum)) * (1.0 - exp(-gam.at(j) * len.at(j))) + aval.at(j) * len.at(j) / lam1.at(j) / lam2.at(j) * exp(-gam.at(j) * len.at(j))
                            Apos = -aval.at(j) / lam2.at(j) * (1.0 - exp(-gam.at(j) * len.at(j)))
                        else:
                            Aconst = len.at(j) / lam1.at(j) * (cval.at(j) + aval.at(j) * tpt - aval.at(j) * sum) - aval.at(j) * len.at(j) * len.at(j) / lam1.at(j) / lam1.at(j)
                            Apos = -aval.at(j) * len.at(j) / lam1.at(j)
                        if j == i:
                            sumAconst.at(j, i) = Aconst
                            sumApos.at(j, i) = Apos
                        else:
                            var jplus1 = j + 1
                            sumAconst.at(j, i) = sumAconst.at(jplus1, i) + Aconst * mult.at(jplus1, i)
                            sumApos.at(j, i) = sumApos.at(jplus1, i) + Apos * mult.at(jplus1, i)
                        sum += len.at(j) / lam1.at(j)
                for p in range(nelem):
                    var nz = tinputs.nz.at(p)
                    var j = tinputs.startpt.at(p)
                    if p == 0:
                        tprofile.at(j, pathid) = Tfin
                    else:
                        tprofile.at(j, pathid) = tprofile.at(j - 1, pathid)
                    for i in range(1, nz):
                        var zp = tinputs.zpts.at(j + i)
                        var np = zp - lam1.at(p) * tpt
                        if np >= 0:
                            var kk = p
                            var nk = np
                            var tk = tpt
                            var Tval = self.interpolate(nk, tinputs.zpts, Tinit, j, j + nz - 1)
                            var Dk: Float64
                            if lam2.at(kk) != 0.0:
                                Dk = (cval.at(kk) / lam2.at(kk) - aval.at(kk) / (lam2.at(kk) * lam2.at(kk))) * (1 - exp(-lam2.at(kk) * tk)) + aval.at(kk) * tk / lam2.at(kk) + Tval * exp(-lam2.at(kk) * tk)
                            else:
                                Dk = cval.at(kk) * tk + 0.5 * aval.at(kk) * tk * tk + Tval
                            tprofile.at(j + i, pathid) = Dk
                        else:
                            var kk = p
                            var nk = -1.0
                            var tk = tpt - zp / lam1.at(p)
                            while nk < 0 and kk > 0:
                                kk -= 1
                                if kk < p - 1:
                                    tk -= len.at(kk + 1) / lam1.at(kk + 1)
                                nk = len.at(kk) - lam1.at(kk) * tk
                            var qq = 0
                            if nk >= 0:
                                qq = kk + 1
                            var sum_val = 0.0
                            if p > 0:
                                sum_val = sumAconst.at(qq, p - 1) + zp / lam1.at(p) * sumApos.at(qq, p - 1)
                            var Ap: Float64
                            if lam2.at(p) != 0.0:
                                Ap = (cval.at(p) / lam2.at(p) - aval.at(p) / (lam2.at(p) * lam2.at(p)) * (1. - lam2.at(p) * tpt)) * (1 - exp(-gam.at(p) * zp)) + aval.at(p) * zp / lam1.at(p) / lam2.at(p) * exp(-gam.at(p) * zp)
                            else:
                                Ap = (zp / lam1.at(p)) * (cval.at(p) + aval.at(p) * tpt) - aval.at(p) * zp * zp / 2.0 / (lam1.at(p) * lam1.at(p))
                            if nk >= 0:
                                var Tval = self.interpolate(nk, tinputs.zpts, Tinit, tinputs.startpt.at(kk), tinputs.startpt.at(kk) + tinputs.nz.at(kk) - 1)
                                var Dk: Float64
                                if lam2.at(kk) != 0.0:
                                    Dk = (cval.at(kk) / lam2.at(kk) - aval.at(kk) / (lam2.at(kk) * lam2.at(kk))) * (1 - exp(-lam2.at(kk) * tk)) + aval.at(kk) * tk / lam2.at(kk) + Tval * exp(-lam2.at(kk) * tk)
                                else:
                                    Dk = cval.at(kk) * tk + 0.5 * aval.at(kk) * tk * tk + Tval
                                tprofile.at(j + i, pathid) = Ap + exp(-gam.at(p) * zp) * (Dk * mult.at(kk + 1, p - 1) + sum_val)
                            else:
                                var m = 1.0
                                if p > 0:
                                    m = mult.at(0, p - 1)
                                tprofile.at(j + i, pathid) = Ap + exp(-gam.at(p) * zp) * (Tfin * m + sum_val)
            if tinputs.npath > 1:
                var j = tinputs.startpt.at(nelem - 1)
                for i in range(tinputs.nz.at(nelem - 1)):
                    tprofile.at(j + i, 0) = 0.5 * tprofile.at(j + i, 0) + 0.5 * tprofile.at(j + i, 1)
                    tprofile.at(j + i, 1) = tprofile.at(j + i, 0)

    def calc_extreme_outlet_values(self, tstep: Float64, flowid: Int, tinputs: transient_inputs, textreme: inout matrix_t[Float64], tpt: inout matrix_t[Float64]):
        var p = flowid
        var zp = tinputs.length.at(flowid)
        var nlines = self.m_n_lines
        var combine = false
        if flowid == self.m_n_elem - 1 and self.m_n_lines > 1:
            nlines = 1
            combine = true
        var lam1 = matrix_t[Float64](tinputs.nelem, self.m_n_lines)
        var lam2 = matrix_t[Float64](tinputs.nelem, self.m_n_lines)
        var cval = matrix_t[Float64](tinputs.nelem, self.m_n_lines)
        var aval = matrix_t[Float64](tinputs.nelem, self.m_n_lines)
        var gam = matrix_t[Float64](tinputs.nelem, self.m_n_lines)
        var Tinit = matrix_t[Float64](tinputs.nztot, self.m_n_lines)
        for j in range(self.m_n_lines):
            for i in range(tinputs.nelem):
                lam1.at(i, j) = tinputs.lam1.at(i, j)
                lam2.at(i, j) = tinputs.lam2.at(i, j)
                cval.at(i, j) = tinputs.cval.at(i, j)
                aval.at(i, j) = tinputs.aval.at(i, j)
                gam.at(i, j) = lam2.at(i, j) / lam1.at(i, j)
            for i in range(tinputs.nztot):
                Tinit.at(i, j) = tinputs.tinit.at(i, j)
        textreme.resize_fill(2, nlines, 0.0)
        tpt.resize_fill(2, nlines, 0.0)
        var s = tinputs.startpt.at(flowid) + tinputs.nz.at(flowid) - 1
        var Tcalc: DynamicVector[Float64]
        for i in range(nlines):
            textreme.at(0, i) = Tinit.at(s, i)
            textreme.at(1, i) = Tinit.at(s, i)
            if not combine:
                Tcalc[i] = self.calc_single_pt(tstep, tinputs.length.at(flowid), flowid, i, tinputs)
            else:
                Tcalc[0] = 0.5 * (self.calc_single_pt(tstep, tinputs.length.at(flowid), flowid, 0, tinputs) + self.calc_single_pt(tstep, tinputs.length.at(flowid), flowid, 1, tinputs))
        for i in range(nlines):
            if Tcalc[i] < textreme.at(0, i):
                tpt.at(0, i) = tstep
                textreme.at(0, i) = Tcalc[i]
            if Tcalc[i] > textreme.at(1, i):
                tpt.at(1, i) = tstep
                textreme.at(1, i) = Tcalc[i]
        if lam1.at(0, 0) != 0:
            var sumval = matrix_t[Float64]()
            var multval = matrix_t[Float64]()
            sumval.resize_fill(p+1, self.m_n_lines, 0.0)
            multval.resize_fill(p+1, self.m_n_lines, 1.0)
            for mm in range(self.m_n_lines):
                var term1: Float64
                if lam2.at(p, mm) != 0.0:
                    term1 = (aval.at(p, mm) / lam2.at(p, mm)) * (1.0 - exp(-gam.at(p, mm) * zp))
                else:
                    term1 = aval.at(p, mm) * zp / lam1.at(p, mm)
                for j in range(p):
                    sumval.at(j, mm) = term1
                    multval.at(j, mm) *= exp(-gam.at(p, mm) * zp)
                    for k in range(j+1, p):
                        multval.at(j, mm) *= exp(-gam.at(k, mm) * tinputs.length.at(k))
                        var mult2 = exp(-gam.at(p, mm) * zp)
                        for l in range(k+1, p):
                            mult2 *= exp(-gam.at(l, mm) * tinputs.length.at(l))
                        if lam2.at(k, mm) != 0.0:
                            sumval.at(j, mm) += aval.at(k, mm) / lam2.at(k, mm) * (1.0 - exp(-gam.at(k, mm) * tinputs.length.at(k))) * mult2
                        else:
                            sumval.at(j, mm) += aval.at(k, mm) * tinputs.length.at(k) / lam1.at(k, mm) * mult2
                    sumval.at(j, mm) *= (-1.0 / lam1.at(j, mm))
            for mm in range(nlines):
                var currentsign, sign, Tval, dTval, d2Tval, n, dz, f, df, nnew, ndiff, term2, term3, len_elem, zint: Float64
                currentsign = 0.0
                for j in range(p, -1, -1):
                    var k1 = tinputs.startpt.at(j)
                    var x = DynamicVector[Float64](tinputs.nz.at(j))
                    var y = DynamicVector[Float64](tinputs.nz.at(j))
                    var splines = matrix_t[Float64]()
                    var splines2 = matrix_t[Float64]()
                    for i in range(tinputs.nz.at(j)):
                        x.at(i) = tinputs.zpts.at(k1 + i)
                        y.at(i) = Tinit.at(k1 + i, mm)
                    self.cubic_splines(x, y, splines)
                    if combine and j < p:
                        for i in range(tinputs.nz.at(j)):
                            y.at(i) = Tinit.at(k1 + i, mm + 1)
                        self.cubic_splines(x, y, splines2)
                    len_elem = tinputs.length.at(j)
                    zint = tinputs.zpts.at(k1 + 1) - tinputs.zpts.at(k1)
                    for i in range(tinputs.nz.at(j) - 1, -1, -1):
                        n = tinputs.zpts.at(k1 + i)
                        var stop = false
                        var found = false
                        var qqq = 0
                        sign = 0.0
                        while qqq < 50 and not stop:
                            qqq += 1
                            var ss = Int(fmin(n / zint, tinputs.nz.at(j) - 2))
                            dz = n - splines.at(ss, 4)
                            Tval = splines.at(ss, 0) + splines.at(ss, 1) * dz + splines.at(ss, 2) * dz * dz + splines.at(ss, 3) * dz * dz * dz
                            dTval = splines.at(ss, 1) + 2.0 * splines.at(ss, 2) * dz + 3.0 * splines.at(ss, 3) * dz * dz
                            d2Tval = 2.0 * splines.at(ss, 2) + 6.0 * splines.at(ss, 3) * dz
                            term2 = cval.at(j, mm) / lam1.at(j, mm) - gam.at(j, mm) * Tval - dTval
                            term3 = (gam.at(j, mm) * cval.at(j, mm) / lam1.at(j, mm) - aval.at(j, mm) / lam1.at(j, mm) / lam1.at(j, mm) - pow(gam.at(j, mm), 2) * Tval - 2.0 * gam.at(j, mm) * dTval - d2Tval)
                            if j == p:
                                f = -exp(-gam.at(j, mm) * (zp - n)) * term2
                                if lam2.at(j, mm) != 0.0:
                                    f -= aval.at(j, mm) / lam2.at(j, mm) / lam1.at(j, mm) * (1.0 - exp(-gam.at(j, mm) * (zp - n)))
                                else:
                                    f -= aval.at(j, mm) / lam1.at(j, mm) * (zp - n)
                                df = -exp(-gam.at(p, mm) * (zp - n)) * term3
                            else:
                                f = sumval.at(j, mm) - multval.at(j, mm) * exp(-gam.at(j, mm) * (len_elem - n)) * term2
                                if lam2.at(j, mm) != 0.0:
                                    f -= multval.at(j, mm) * (aval.at(j, mm) / lam2.at(j, mm) / lam1.at(j, mm)) * (1.0 - exp(-gam.at(j, mm) * (len_elem - n)))
                                else:
                                    f -= multval.at(j, mm) * aval.at(j, mm) / lam1.at(j, mm) / lam1.at(j, mm) * (len_elem - n)
                                df = -multval.at(j, mm) * exp(-gam.at(j, mm) * (len_elem - n)) * term3
                                if combine:
                                    Tval = splines2.at(ss, 0) + splines2.at(ss, 1) * dz + splines2.at(ss, 2) * dz * dz + splines2.at(ss, 3) * dz * dz * dz
                                    dTval = splines2.at(ss, 1) + 2.0 * splines2.at(ss, 2) * dz + 3.0 * splines2.at(ss, 3) * dz * dz
                                    d2Tval = 2.0 * splines2.at(ss, 2) + 6.0 * splines2.at(ss, 3) * dz
                                    term2 = cval.at(j, mm + 1) / lam1.at(j, mm + 1) - gam.at(j, mm + 1) * Tval - dTval
                                    term3 = (gam.at(j, mm + 1) * cval.at(j, mm + 1) / lam1.at(j, mm + 1) - aval.at(j, mm + 1) / lam1.at(j, mm + 1) / lam1.at(j, mm + 1) - pow(gam.at(j, mm + 1), 2) * Tval - 2.0 * gam.at(j, mm + 1) * dTval - d2Tval)
                                    var f2 = sumval.at(j, mm + 1) - multval.at(j, mm + 1) * exp(-gam.at(j, mm + 1) * (len_elem - n)) * term2
                                    var df2 = -multval.at(j, mm + 1) * exp(-gam.at(j, mm + 1) * (len_elem - n)) * term3
                                    f = 0.5 * (f + f2)
                                    if lam2.at(j, mm + 1) != 0.0:
                                        f -= 0.5 * multval.at(j, mm + 1) * (aval.at(j, mm + 1) / lam2.at(j, mm + 1) / lam1.at(j, mm + 1)) * (1.0 - exp(-gam.at(j, mm + 1) * (len_elem - n)))
                                    else:
                                        f -= 0.5 * multval.at(j, mm + 1) * aval.at(j, mm + 1) / lam1.at(j, mm + 1) / lam1.at(j, mm + 1) * (len_elem - n)
                                    df = 0.5 * (df + df2)
                            if qqq == 1:
                                sign = Float64(f > 0) - Float64(f < 0)
                                if sign == currentsign:
                                    stop = true
                                if sign != currentsign and i == tinputs.nz.at(j) - 1:
                                    stop = true
                                    found = true
                            if not stop:
                                nnew = n - 0.8 * f / df
                                nnew = fmin(nnew, len_elem)
                                nnew = fmax(nnew, 0.0)
                                ndiff = abs(nnew - n)
                                n = nnew
                                if abs(ndiff / len_elem) < 1.e-3 and abs(f) < 1.e-4:
                                    stop = true
                                    found = true
                        currentsign = sign
                        if found:
                            var t, Textreme: Float64
                            t = (len_elem - n) / lam1.at(j, mm)
                            for kk in range(j+1, p+1):
                                t += tinputs.length.at(kk) / lam1.at(kk, mm)
                            if t <= tstep:
                                Textreme = self.calc_single_pt(t, zp, flowid, mm, tinputs)
                                if combine and j < p:
                                    Textreme = 0.5 * Textreme + 0.5 * self.calc_single_pt(t, zp, flowid, mm + 1, tinputs)
                                if Textreme < textreme.at(0, mm):
                                    tpt.at(0, mm) = t
                                    textreme.at(0, mm) = Textreme
                                if Textreme > textreme.at(1, mm):
                                    tpt.at(1, mm) = t
                                    textreme.at(1, mm) = Textreme

    def calc_ss_profile(self, tinputs: transient_inputs, tprofile: inout matrix_t[Float64], tprofile_wall: inout matrix_t[Float64]):
        if tinputs.lam1.at(0, 0) == 0.0:
            for pathid in range(tinputs.npath):
                for j in range(tinputs.nelem):
                    var k = tinputs.startpt.at(j)
                    if j > 0:
                        tprofile.at(k, pathid) = tprofile.at(k - 1, pathid)
                    for i in range(1, tinputs.nz.at(j)):
                        if tinputs.lam2.at(j, pathid) != 0.0:
                            tprofile.at(k + i, pathid) = tinputs.cval.at(j, pathid) / tinputs.lam2.at(j, pathid)
                        else:
                            tprofile.at(k + i, pathid) = 1.0e6
        else:
            for pathid in range(tinputs.npath):
                tprofile.at(0, pathid) = tinputs.inlet_temp
                for j in range(tinputs.nelem):
                    var k = tinputs.startpt.at(j)
                    if j > 0:
                        tprofile.at(k, pathid) = tprofile.at(k - 1, pathid)
                    for i in range(1, tinputs.nz.at(j)):
                        var z = tinputs.zpts.at(k + i)
                        var term1: Float64
                        if tinputs.lam2.at(j, pathid) != 0.0:
                            term1 = tinputs.cval.at(j, pathid) / tinputs.lam2.at(j, pathid) * (1.0 - exp(-tinputs.lam2.at(j, pathid) / tinputs.lam1.at(j, pathid) * z))
                        else:
                            term1 = tinputs.cval.at(j, pathid) / tinputs.lam1.at(j, pathid) * z
                        tprofile.at(k + i, pathid) = term1 + tprofile.at(k, pathid) * exp(-tinputs.lam2.at(j, pathid) / tinputs.lam1.at(j, pathid) * z)
            if tinputs.npath > 1:
                var j = tinputs.startpt.at(tinputs.nelem - 1)
                for i in range(tinputs.nz.at(tinputs.nelem - 1)):
                    tprofile.at(j + i, 0) = 0.5 * tprofile.at(j + i, 0) + 0.5 * tprofile.at(j + i, 1)
                    tprofile.at(j + i, 1) = tprofile.at(j + i, 0)
        for i in range(self.m_n_lines):
            var k = 0
            for j in range(self.m_n_elem):
                for qq in range(tinputs.nz.at(j)):
                    var Tf = tprofile.at(k, i)
                    var qnet = (tinputs.cval.at(j, i) - tinputs.lam2.at(j, i) * Tf) * self.m_tm.at(j)
                    tprofile_wall.at(k, i) = Tf
                    if self.m_flowelem_type.at(j, i) >= 0:
                        tprofile_wall.at(k, i) += qnet / CSP.pi * tinputs.Rtube.at(j, i)
                    k += 1

    def initialize_transient_param_inputs(self, soln: s_steady_state_soln, pinputs: inout parameter_eval_inputs):
        var P_amb = soln.p_amb
        var hour = soln.hour
        var T_dp = soln.T_dp
        var T_amb = soln.T_amb
        var v_wind_10 = soln.v_wind_10
        var T_sky = CSP.skytemp(T_amb, T_dp, hour)
        var T_coolant_prop = (soln.T_salt_hot + soln.T_salt_cold_in) / 2.0
        pinputs.mflow_tot = soln.m_dot_salt_tot
        pinputs.c_htf = field_htfProps.Cp(T_coolant_prop) * 1000.0
        pinputs.rho_htf = field_htfProps.dens(T_coolant_prop, 1.0)
        pinputs.mu_htf = field_htfProps.visc(T_coolant_prop)
        pinputs.k_htf = field_htfProps.cond(T_coolant_prop)
        pinputs.Pr_htf = pinputs.c_htf * pinputs.mu_htf / pinputs.k_htf
        pinputs.T_amb = T_amb
        pinputs.T_sky = T_sky
        pinputs.wspd = v_wind_10
        pinputs.pres = P_amb
        pinputs.qinc.fill(0.0)
        pinputs.qheattrace.fill(0.0)
        for i in range(self.m_n_lines):
            var jdc = self.m_n_elem - 1
            pinputs.Tfeval.at(0, i) = soln.T_salt_cold_in
            pinputs.Tseval.at(0, i) = soln.T_salt_cold_in
            pinputs.Tfeval.at(jdc, i) = soln.T_salt_hot
            pinputs.Tseval.at(jdc, i) = soln.T_salt_hot
            for j in range(1, jdc):
                if self.m_flowelem_type.at(j, i) >= 0:
                    pinputs.qinc.at(j, i) = soln.q_dot_inc.at(self.m_flowelem_type.at(j, i)) / Float64(self.m_n_t)
                    pinputs.Tfeval.at(j, i) = soln.T_panel_ave.at(self.m_flowelem_type.at(j, i))
                    pinputs.Tseval.at(j, i) = soln.T_s.at(self.m_flowelem_type.at(j, i))
                if self.m_flowelem_type.at(j, i) == -3:
                    pinputs.Tfeval.at(j, i) = pinputs.Tfeval.at(j - 1, i)
                    pinputs.Tseval.at(j, i) = pinputs.Tfeval.at(j, i)

    def update_pde_parameters(self, use_initial_t: Bool, pinputs: inout parameter_eval_inputs, tinputs: inout transient_inputs):
        var Pr_htf = pinputs.c_htf * pinputs.mu_htf / pinputs.k_htf
        tinputs.lam1.fill(0.0)
        tinputs.lam2.fill(0.0)
        tinputs.cval.fill(0.0)
        tinputs.aval.fill(0.0)
        tinputs.Rtube.fill(0.0)
        for i in range(self.m_n_lines):
            for j in range(self.m_n_elem):
                if use_initial_t:
                    var k = tinputs.startpt.at(j) + Int(floor(tinputs.nz.at(j) / 2))
                    pinputs.Tfeval.at(j, i) = tinputs.tinit.at(k, i)
                    pinputs.Tseval.at(j, i) = tinputs.tinit_wall.at(k, i)
                var k_tube = tube_material.cond((pinputs.Tseval.at(j, i) + pinputs.Tfeval.at(j, i)) / 2.0)
                var Rwall = log(self.m_od.at(j) / self.m_id.at(j)) / k_tube
                var Rconv = 0.0
                if pinputs.mflow_tot > 0.0:
                    var mmult: Float64 = 1.0 / Float64(self.m_n_lines) / Float64(self.m_n_t)
                    if self.m_flowelem_type.at(j, i) == -1 or self.m_flowelem_type.at(j, i) == -2:
                        mmult = 1.0
                    if self.m_flowelem_type.at(j, i) == -3:
                        mmult = 1.0 / Float64(self.m_n_lines)
                    var Reelem = 4 * mmult * pinputs.mflow_tot / (CSP.pi * self.m_id.at(j) * pinputs.mu_htf)
                    var Nuelem, felem: Float64
                    CSP.PipeFlow(Reelem, Pr_htf, tinputs.length.at(j) / self.m_id.at(j), (4.5e-5) / self.m_id.at(j), Nuelem, felem)
                    var hinner = Nuelem * pinputs.k_htf / self.m_id.at(j)
                    tinputs.lam1.at(j, i) = mmult * pinputs.mflow_tot * pinputs.c_htf / pinputs.tm.at(j)
                    Rconv = 1.0 / (0.5 * hinner * self.m_id.at(j))
                if self.m_flowelem_type.at(j, i) >= 0:
                    var sa = CSP.pi * 0.5 * self.m_od.at(j)
                    var vf = 2.0 / CSP.pi
                    var hmix = self.calc_external_convection_coeff(pinputs.T_amb, pinputs.pres, pinputs.wspd, pinputs.Tseval.at(j, i)) * (2.0 / CSP.pi)
                    var Tlin = pinputs.Tseval.at(j, i)
                    var heff = self.m_hl_ffact * (0.5 * hmix + 4.0 * vf * CSP.sigma * self.m_epsilon * pow(Tlin, 3))
                    var qabstube = pinputs.qinc.at(j, i) / (sa * tinputs.length.at(j))
                    if pinputs.mflow_tot > 0.0:
                        tinputs.Rtube.at(j, i) = Rwall + Rconv
                    var den = (1.0 + 0.5 * self.m_od.at(j) * tinputs.Rtube.at(j, i) * heff) * pinputs.tm.at(j)
                    tinputs.lam2.at(j, i) = sa * heff / den
                    tinputs.cval.at(j, i) = sa * (pinputs.finitial * qabstube + 0.5 * hmix * self.m_hl_ffact * pinputs.T_amb + vf * self.m_hl_ffact * self.m_epsilon * CSP.sigma * (3.0 * pow(Tlin, 4) + 0.5 * pow(pinputs.T_amb, 4) + 0.5 * pow(pinputs.T_sky, 4))) / den
                    if pinputs.ramptime > 0:
                        var ramp_rate = qabstube * (pinputs.ffinal - pinputs.finitial) / pinputs.ramptime
                        tinputs.aval.at(j, i) = sa * ramp_rate / den
                if self.m_flowelem_type.at(j, i) == -1 or self.m_flowelem_type.at(j, i) == -2:
                    var Rtot: Float64
                    if self.m_flowelem_type.at(j, i) == -1:
                        Rtot = self.m_Rtot_riser
                    else:
                        Rtot = self.m_Rtot_downc
                    tinputs.lam2.at(j, i) = 2.0 * CSP.pi / Rtot / pinputs.tm.at(j)
                    tinputs.cval.at(j, i) = (pinputs.qheattrace.at(j) + 2.0 * CSP.pi * pinputs.T_amb / Rtot) / pinputs.tm.at(j)
                if self.m_flowelem_type.at(j, i) == -3:
                    tinputs.lam2.at(j, i) = 0.0
                    tinputs.cval.at(j, i) = pinputs.qheattrace.at(j) / pinputs.tm.at(j)
        return

    def solve_transient_model(self, tstep: Float64, allowable_Trise: Float64, pinputs: inout parameter_eval_inputs, tinputs: inout transient_inputs, toutputs: inout transient_outputs):
        toutputs.timeavg_tout = 0.0
        toutputs.tout = 0.0
        toutputs.max_tout = 0.0
        toutputs.min_tout = 5000.0
        toutputs.max_rec_tout = 0.0
        toutputs.timeavg_conv_loss = 0.0
        toutputs.timeavg_rad_loss = 0.0
        toutputs.timeavg_piping_loss = 0.0
        toutputs.timeavg_qthermal = 0.0
        toutputs.timeavg_qnet = 0.0
        toutputs.timeavg_qheattrace = 0.0
        toutputs.t_profile.fill(0.0)
        toutputs.t_profile_wall.fill(0.0)
        toutputs.timeavg_temp.fill(0.0)
        toutputs.time_min_tout = 0.0
        toutputs.tube_temp_inlet = 0.0
        toutputs.tube_temp_outlet = 0.0
        var max_Trise: Float64
        var allowable_min_step = 60.0
        var transmodel_step = tstep
        var solved_time = 0.0
        var qsub = 0
        var qmax = 50
        var tinit_start = tinputs.tinit
        self.update_pde_parameters(true, pinputs, tinputs)
        while solved_time < tstep:
            max_Trise = 0.0
            var maxTdiff = 1000.0
            var Tconverge = 10.0
            var panel_loss_sum, piping_loss_sum, rad_loss_sum, conv_loss_sum, qnet_sum, qheattrace_sum = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
            var q = 0
            while maxTdiff > Tconverge and q < qmax:
                maxTdiff = 0.0
                panel_loss_sum = 0.0
                piping_loss_sum = 0.0
                rad_loss_sum = 0.0
                conv_loss_sum = 0.0
                qnet_sum = 0.0
                qheattrace_sum = 0.0
                if q > 0:
                    self.update_pde_parameters(false, pinputs, tinputs)
                for i in range(self.m_n_lines):
                    for j in range(self.m_n_elem):
                        toutputs.timeavg_temp.at(j, i) = self.calc_timeavg_exit_temp(transmodel_step, j, i, tinputs)
                if self.m_n_lines > 1:
                    var j = self.m_n_elem - 1
                    toutputs.timeavg_temp.at(j, 0) = 0.5 * (toutputs.timeavg_temp.at(j, 0) + toutputs.timeavg_temp.at(j, 1))
                    toutputs.timeavg_temp.at(j, 1) = toutputs.timeavg_temp.at(j, 0)
                var Tfavg = matrix_t[Float64]()
                var Tsavg = matrix_t[Float64]()
                Tfavg.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
                Tsavg.resize_fill(self.m_n_elem, self.m_n_lines, 0.0)
                for i in range(self.m_n_lines):
                    for j in range(self.m_n_elem):
                        Tfavg.at(j, i) = toutputs.timeavg_temp.at(j, i)
                        if pinputs.mflow_tot > 0.0:
                            if j > 0:
                                Tfavg.at(j, i) += toutputs.timeavg_temp.at(j - 1, i)
                            else:
                                Tfavg.at(j, i) += tinputs.inlet_temp
                            Tfavg.at(j, i) = Tfavg.at(j, i) / 2.0
                        Tsavg.at(j, i) = Tfavg.at(j, i)
                        if self.m_flowelem_type.at(j, i) >= 0:
                            var sa = 0.5 * CSP.pi * self.m_od.at(j) * tinputs.length.at(j)
                            var qabs_avg = 0.5 * (pinputs.finitial + pinputs.ffinal) * (pinputs.qinc.at(j, i) / sa)
                            var hext, qconv, qrad: Float64
                            var Tsguess = Tfavg.at(j, i)
                            if pinputs.mflow_tot > 0.0:
                                Tsguess = Tfavg.at(j, i) + ((tinputs.cval.at(j, i) - tinputs.lam2.at(j, i) * Tfavg.at(j, i)) * pinputs.tm.at(j)) / CSP.pi * tinputs.Rtube.at(j, i)
                                self.calc_surface_temperature(Tfavg.at(j, i), qabs_avg, tinputs.Rtube.at(j, i), self.m_od.at(j), pinputs.T_amb, pinputs.T_sky, pinputs.pres, pinputs.wspd, Tsguess)
                            self.calc_thermal_loss(Tsguess, pinputs.T_amb, pinputs.T_sky, pinputs.pres, pinputs.wspd, hext, qconv, qrad)
                            rad_loss_sum += qrad * sa * self.m_n_t
                            conv_loss_sum += qconv * sa * self.m_n_t
                            panel_loss_sum += (qconv + qrad) * sa * self.m_n_t
                            qnet_sum += (qabs_avg - qrad - qconv) * sa * self.m_n_t
                            Tsavg.at(j, i) = Tsguess
                        if self.m_flowelem_type.at(j, i) == -3:
                            qheattrace_sum += pinputs.qheattrace.at(j) * tinputs.length.at(j)
                        if self.m_flowelem_type.at(j, i) == -1 and i == 0:
                            var heatloss = (2.0 * CSP.pi * (Tfavg.at(j, i) - pinputs.T_amb) / self.m_Rtot_riser) * tinputs.length.at(j)
                            piping_loss_sum += heatloss
                            qnet_sum -= heatloss
                            qheattrace_sum += pinputs.qheattrace.at(j) * tinputs.length.at(j)
                        if self.m_flowelem_type.at(j, i) == -2 and i == 0:
                            var heatloss = (2.0 * CSP.pi * (Tfavg.at(j, i) - pinputs.T_amb) / self.m_Rtot_downc) * tinputs.length.at(j)
                            piping_loss_sum += heatloss
                            qnet_sum -= heatloss
                            qheattrace_sum += pinputs.qheattrace.at(j) * tinputs.length.at(j)
                for i in range(self.m_n_lines):
                    for j in range(self.m_n_elem):
                        maxTdiff = fmax(maxTdiff, fmax(fabs(Tsavg.at(j, i) - pinputs.Tseval.at(j, i)), fabs(Tfavg.at(j, i) - pinputs.Tfeval.at(j, i))))
                pinputs.Tfeval = Tfavg
                pinputs.Tseval = Tsavg
                q += 1
            self.calc_axial_profile(transmodel_step, tinputs, toutputs.t_profile)
            for i in range(self.m_n_lines):
                for j in range(self.m_nz_tot):
                    max_Trise = fmax(max_Trise, fabs(toutputs.t_profile.at(j, i) - tinputs.tinit.at(j, i)))
            var textreme_d = matrix_t[Float64]()
            var tpt_d = matrix_t[Float64]()
            var textreme_r = matrix_t[Float64]()
            var tpt_r = matrix_t[Float64]()
            self.calc_extreme_outlet_values(transmodel_step, self.m_n_elem - 1, tinputs, textreme_d, tpt_d)
            self.calc_extreme_outlet_values(transmodel_step, self.m_n_elem - 2, tinputs, textreme_r, tpt_r)
            max_Trise = fmax(max_Trise, fmax(textreme_d.at(1, 0) - textreme_d.at(0, 0), textreme_r.at(1, 0) - textreme_r.at(0, 0)))
            if self.m_n_lines > 1:
                max_Trise = fmax(max_Trise, textreme_r.at(1, 1) - textreme_r.at(0, 1))
            if max_Trise < allowable_Trise or transmodel_step <= allowable_min_step:
                toutputs.timeavg_qnet = toutputs.timeavg_qnet + qnet_sum * (transmodel_step / tstep)
                toutputs.timeavg_qheattrace = toutputs.timeavg_qheattrace + qheattrace_sum * (transmodel_step / tstep)
                toutputs.timeavg_rad_loss = toutputs.timeavg_rad_loss + rad_loss_sum * (transmodel_step / tstep)
                toutputs.timeavg_conv_loss = toutputs.timeavg_conv_loss + conv_loss_sum * (transmodel_step / tstep)
                toutputs.timeavg_piping_loss = toutputs.timeavg_piping_loss + piping_loss_sum * (transmodel_step / tstep)
                toutputs.timeavg_tout = toutputs.timeavg_tout + toutputs.timeavg_temp.at(self.m_n_elem - 1, 0) * (transmodel_step / tstep)
                toutputs.max_tout = fmax(toutputs.max_tout, textreme_d.at(1, 0))
                if textreme_d.at(0, 0) < toutputs.min_tout:
                    toutputs.min_tout = textreme_d.at(1, 0)
                    toutputs.time_min_tout = solved_time + tpt_d.at(1, 0)
                toutputs.max_rec_tout = fmax(toutputs.max_rec_tout, textreme_r.at(1, 0))
                if self.m_n_lines > 1:
                    toutputs.max_rec_tout = fmax(toutputs.max_rec_tout, textreme_r.at(1, 1))
                solved_time = solved_time + transmodel_step
                if tstep - solved_time > 0.01:
                    transmodel_step = tstep - solved_time
                    tinputs.tinit = toutputs.t_profile
            else:
                transmodel_step = transmodel_step / 2.0
            qsub += 1
        toutputs.tout = toutputs.t_profile.at(self.m_nz_tot - 1, 0)
        toutputs.timeavg_qthermal = pinputs.mflow_tot * pinputs.c_htf * (toutputs.timeavg_tout - tinputs.inlet_temp)
        tinputs.tinit = tinit_start
        var krecout = tinputs.startpt.back() - 1
        for i in range(self.m_n_lines):
            var k = 0
            for j in range(self.m_n_elem):
                for qq in range(tinputs.nz.at(j)):
                    var Tf = toutputs.t_profile.at(k, i)
                    var qnet = (tinputs.cval.at(j, i) + tinputs.aval.at(j, i) * tstep - tinputs.lam2.at(j, i) * Tf) * pinputs.tm.at(j)
                    toutputs.t_profile_wall.at(k, i) = Tf
                    if self.m_flowelem_type.at(j, i) >= 0:
                        toutputs.t_profile_wall.at(k, i) += qnet / CSP.pi * tinputs.Rtube.at(j, i)
                    k += 1
            toutputs.tube_temp_inlet += toutputs.t_profile_wall.at(tinputs.startpt.at(1), i) / Float64(self.m_n_lines)
            toutputs.tube_temp_outlet += toutputs.t_profile_wall.at(krecout, i) / Float64(self.m_n_lines)

    def solve_transient_startup_model(self, pinputs: inout parameter_eval_inputs, tinputs: inout transient_inputs, startup_mode: Int, target_temperature: Float64, min_time: Float64, max_time: Float64, toutputs: inout transient_outputs, startup_time: inout Float64, energy: inout Float64, parasitic: inout Float64):
        if startup_mode == self.HEAT_TRACE:
            var heat_trace_time = 0.0
            var heat_trace_energy = 0.0
            var max_time_required = 0.0
            var elems = DynamicVector[Int]([0, self.m_n_elem - 1])
            var time = DynamicVector[Float64]([0.0, 0.0])
            if self.m_flow_type == 1 or self.m_flow_type == 2:
                elems.push_back(self.m_crossover_index)
                time.push_back(0.0)
            pinputs.qheattrace.fill(self.m_heat_trace_power)
            self.update_pde_parameters(true, pinputs, tinputs)
            for kk in range(elems.size()):
                var j = elems.at(kk)
                var T0 = tinputs.tinit.at(tinputs.startpt.at(j), 0)
                if tinputs.lam2.at(j, 0) == 0.0:
                    time.at(kk) = (target_temperature - T0) / tinputs.cval.at(j, 0)
                else:
                    time.at(kk) = 1.0 / tinputs.lam2.at(j, 0) * log((T0 - tinputs.cval.at(j, 0) / tinputs.lam2.at(j, 0)) / (target_temperature - tinputs.cval.at(j, 0) / tinputs.lam2.at(j, 0)))
                time.at(kk) = fmax(0.0, time.at(kk))
                time.at(kk) = fmin(max_time, time.at(kk))
                max_time_required = fmax(max_time_required, time.at(kk))
            self.set_heattrace_power(false, target_temperature, max_time_required, pinputs, tinputs)
            self.solve_transient_model(max_time_required, 150.0, pinputs, tinputs, toutputs)
            energy = toutputs.timeavg_qnet * max_time_required
            parasitic = toutputs.timeavg_qheattrace * max_time_required
            startup_time = max_time_required
        elif startup_mode == self.PREHEAT:
            var preheat_time = 0.0
            var preheat_energy = 0.0
            var Tmin_rec = 5000.0
            for i in range(self.m_n_lines):
                for j in range(self.m_n_elem):
                    var p1 = tinputs.startpt.at(j)
                    if self.m_flowelem_type.at(j, i) >= 0:
                        var Twall_min = fmin(tinputs.tinit.at(p1, i), tinputs.tinit.at(p1 + tinputs.nz.at(j) - 1, i))
                        Tmin_rec = fmin(Tmin_rec, Twall_min)
                        pinputs.Tseval.at(j, i) = 0.5 * (tinputs.tinit.at(p1, i) + target_temperature)
                    else:
                        pinputs.Tseval.at(j, i) = tinputs.tinit.at(p1, i)
            pinputs.Tfeval = pinputs.Tseval
            self.update_pde_parameters(false, pinputs, tinputs)
            if tinputs.lam2.at(1, 0) == 0.0:
                preheat_time = (target_temperature - Tmin_rec) / tinputs.cval.at(1, 0)
            else:
                var preheat_ss_temp = tinputs.cval.at(1, 0) / tinputs.lam2.at(1, 0)
                if preheat_ss_temp > target_temperature:
                    preheat_time = 1.0 / tinputs.lam2.at(1, 0) * log((Tmin_rec - tinputs.cval.at(1, 0) / tinputs.lam2.at(1, 0)) / (target_temperature - tinputs.cval.at(1, 0) / tinputs.lam2.at(1, 0)))
                else:
                    preheat_time = max_time
            preheat_time = fmin(preheat_time, max_time)
            self.set_heattrace_power(true, 0.0, 0.0, pinputs, tinputs)
            self.solve_transient_model(preheat_time, 150.0, pinputs, tinputs, toutputs)
            energy = toutputs.timeavg_qnet * preheat_time
            parasitic = toutputs.timeavg_qheattrace * preheat_time
            startup_time = preheat_time
        elif startup_mode == self.PREHEAT_HOLD:
            var hext, qconv, qrad: Float64
            var Ts = tinputs.tinit.at(tinputs.startpt.at(1), 0)
            self.calc_thermal_loss(Ts, pinputs.T_amb, pinputs.T_sky, pinputs.pres, pinputs.wspd, hext, qconv, qrad)
            var sa = 0.5 * CSP.pi * self.m_od.at(1) * tinputs.length.at(1)
            pinputs.qinc.fill((qconv + qrad) * sa)
            self.update_pde_parameters(false, pinputs, tinputs)
            self.set_heattrace_power(true, 0.0, 0.0, pinputs, tinputs)
            self.solve_transient_model(max_time, 150.0, pinputs, tinputs, toutputs)
            energy = toutputs.timeavg_qnet * max_time
            parasitic = toutputs.timeavg_qheattrace * max_time
            startup_time = max_time
        elif startup_mode == self.FILL:
            var hext, qconv, qrad: Float64
            var Ts = tinputs.tinit.at(tinputs.startpt.at(1), 0)
            self.calc_thermal_loss(Ts, pinputs.T_amb, pinputs.T_sky, pinputs.pres, pinputs.wspd, hext, qconv, qrad)
            var sa = 0.5 * CSP.pi * self.m_od.at(1) * tinputs.length.at(1)
            pinputs.qinc.fill((qconv + qrad) * sa)
            self.update_pde_parameters(false, pinputs, tinputs)
            self.set_heattrace_power(true, 0.0, 0.0, pinputs, tinputs)
            self.solve_transient_model(max_time, 150.0, pinputs, tinputs, toutputs)
            energy = toutputs.timeavg_qnet * max_time
            parasitic = toutputs.timeavg_qheattrace * max_time
            startup_time = max_time
        elif startup_mode == self.CIRCULATE:
            var circulate_time = 0.0
            var circulate_energy = 0.0
            var max_Trise = 150.0
            var total_time = 0.0
            if pinputs.ramptime >= max_time:
                self.solve_transient_model(max_time, max_Trise, pinputs, tinputs, toutputs)
                circulate_energy += toutputs.timeavg_qnet * max_time
                energy = circulate_energy
                parasitic = 0.0
                startup_time = max_time
            else:
                if pinputs.finitial < pinputs.ffinal:
                    self.solve_transient_model(pinputs.ramptime, max_Trise, pinputs, tinputs, toutputs)
                    circulate_energy += toutputs.timeavg_qnet * pinputs.ramptime
                    total_time = pinputs.ramptime
                    self.trans_inputs.tinit = self.trans_outputs.t_profile
                    self.trans_inputs.tinit_wall = self.trans_outputs.t_profile_wall
                    max_time -= pinputs.ramptime
                    pinputs.finitial = 1.0
                    pinputs.ffinal = 1.0
                    pinputs.ramptime = 0.0
                var lowerbound = 0.0
                if min_time > 0.01:
                    lowerbound = fmin(min_time, max_time)
                if tinputs.tinit.at(self.m_nz_tot - 1, 0) >= target_temperature and lowerbound == 0.0:
                    circulate_time = fmin(1.0, max_time)
                else:
                    var upperbound = fmax(max_time, lowerbound)
                    circulate_time = upperbound
                    self.solve_transient_model(circulate_time, max_Trise, pinputs, tinputs, toutputs)
                    if toutputs.tout < target_temperature:
                        circulate_time = max_time
                    else:
                        if toutputs.min_tout < target_temperature:
                            lowerbound = fmax(lowerbound, toutputs.time_min_tout)
                        self.update_pde_parameters(true, pinputs, tinputs)
                        var est_time_ss = DynamicVector[Float64](self.m_n_elem, 0.0)
                        var time_ss: Float64
                        for i in range(self.m_n_lines):
                            var est_time_ss_path = DynamicVector[Float64](self.m_n_elem, 0.0)
                            for j in range(self.m_n_elem):
                                est_time_ss_path.at(j) = tinputs.length.at(j) / tinputs.lam1.at(j, i) + (est_time_ss_path.at(j - 1) if j > 0 else 0.0)
                                est_time_ss.at(j) = fmax(est_time_ss.at(j), est_time_ss_path.at(j))
                        if tinputs.tinit.at(0, 0) - tinputs.inlet_temp < self.m_startup_target_delta:
                            circulate_time = est_time_ss.back()
                        else:
                            var t, tprev, tsolve, f_val, fprev, fsolve = QNAN, QNAN, QNAN, QNAN, QNAN, QNAN
                            var ttol = 0.05
                            var ftol = 0.01
                            var qqq = 0
                            while qqq < 100:
                                if qqq == 0 and toutputs.tout - target_temperature < 0.5:
                                    t = upperbound
                                    f_val = toutputs.tout - target_temperature
                                    tsolve = t - 0.1
                                elif qqq == 0:
                                    tsolve = est_time_ss.at(self.m_n_elem - 2)
                                elif fprev != fprev:
                                    tsolve = est_time_ss.at(self.m_n_elem - 3) if fsolve > 0 else tsolve + 10
                                elif f_val < 0 and fprev < 0 and fabs(f_val - fprev) < 0.1:
                                    tsolve = tsolve + (0.05 if fabs(f_val) < 0.01 else 0.5)
                                elif f_val > 0 and fprev > 0 and fabs(f_val - fprev) < 0.2:
                                    tsolve = 0.5 * (upperbound + lowerbound)
                                else:
                                    tsolve = t - f_val * (t - tprev) / (f_val - fprev) + 0.001
                                if tsolve <= lowerbound or tsolve >= upperbound:
                                    tsolve = 0.5 * (upperbound + lowerbound)
                                self.solve_transient_model(tsolve, max_Trise, pinputs, tinputs, toutputs)
                                fsolve = toutputs.tout - target_temperature
                                if fsolve < 0.0:
                                    lowerbound = tsolve
                                else:
                                    upperbound = tsolve
                                if fsolve > 0.0 and (fsolve < ftol or (upperbound - lowerbound) < ttol):
                                    break
                                tprev = t
                                fprev = f_val
                                t = tsolve
                                f_val = fsolve
                                qqq += 1
                            circulate_time = tsolve
                    if circulate_time == max_time:
                        circulate_time -= 0.1
                if circulate_time > 0.0:
                    circulate_energy += toutputs.timeavg_qnet * circulate_time
                total_time += circulate_time
                energy = circulate_energy
                parasitic = 0.0
                startup_time = total_time
        elif startup_mode == self.HOLD:
            self.solve_transient_model(max_time, 150.0, pinputs, tinputs, toutputs)
            energy = toutputs.timeavg_qnet * max_time
            parasitic = 0.0
            startup_time = max_time

    def set_heattrace_power(self, is_maintain_T: Bool, Ttarget: Float64, time: Float64, pinputs: inout parameter_eval_inputs, tinputs: transient_inputs):
        pinputs.qheattrace.fill(0.0)
        var elems = DynamicVector[Int]([0, self.m_n_elem - 1])
        if self.m_flow_type == 1 or self.m_flow_type == 2:
            elems.push_back(self.m_crossover_index)
        for kk in range(elems.size()):
            var j = elems.at(kk)
            var T0 = tinputs.tinit.at(tinputs.startpt.at(j), 0)
            if is_maintain_T:
                if tinputs.lam2.at(j, 0) > 0.0:
                    pinputs.qheattrace.at(j) = (tinputs.lam2.at(j, 0) * pinputs.tm.at(j)) * (T0 - pinputs.T_amb)
            else:
                if tinputs.lam2.at(j, 0) == 0.0:
                    pinputs.qheattrace.at(j) = (pinputs.tm.at(j) / time) * (Ttarget - T0)
                else:
                    pinputs.qheattrace.at(j) = (tinputs.lam2.at(j, 0) * pinputs.tm.at(j)) * ((Ttarget - pinputs.T_amb) - (T0 - pinputs.T_amb) * exp(-tinputs.lam2.at(j, 0) * time)) / (1. - exp(-tinputs.lam2.at(j, 0) * time))
            pinputs.qheattrace.at(j) = fmax(pinputs.qheattrace.at(j), 0.0)
        return

    def est_startup_time_energy(self, fract: Float64, est_time: inout Float64, est_energy: inout Float64):
        var start_time = 0.0
        var start_energy = 0.0
        var hext = 10.0
        var Tamb = 20.0 + 273.15
        var time_heattrace = (self.m_T_htf_cold_des - Tamb) * self.m_tm_solid.at(0) / self.m_heat_trace_power
        start_time += time_heattrace
        var Tavg = 0.5 * (self.m_T_htf_cold_des + Tamb)
        var qpreheat = self.m_od_tube * self.m_tube_flux_preheat * 1000.0
        var qloss = (0.5 * CSP.pi * self.m_od_tube) * (hext * (Tavg - Tamb) + (2.0 / CSP.pi) * CSP.sigma * self.m_epsilon * (pow(Tavg, 4) - pow(Tamb, 4)))
        var time_preheat = (self.m_preheat_target - Tamb) * self.m_tm_solid.at(1) / (qpreheat - qloss)
        var energy_preheat = time_preheat * ((qpreheat - qloss) * self.m_h_rec * self.m_n_t * self.m_n_panels) * 1.e-6 / 3600.0
        time_preheat = fmax(time_preheat, self.m_min_preheat_time)
        start_time += time_preheat
        start_energy += energy_preheat
        start_time += self.m_fill_time
        var weather = C_csp_weatherreader.S_outputs()
        weather.m_pres = 101325.0 / 100.0
        weather.m_tdew = 2.0
        weather.m_tdry = Tamb - 273.15
        weather.m_wspd = 5.0
        var soln = s_steady_state_soln()
        soln.hour = 182.0 * 24.0 + 8.0
        soln.T_amb = Tamb
        soln.T_dp = 2.0 + 273.15
        soln.v_wind_10 = 5.0
        soln.p_amb = 101325.0
        soln.T_salt_cold_in = self.m_T_htf_cold_des
        var qinc_approx = fract * self.m_q_rec_des / 0.92 / Float64(self.m_n_panels)
        soln.q_dot_inc.resize_fill(self.m_n_panels, qinc_approx)
        soln.dni = 500.0
        self.solve_for_mass_flow(soln)
        self.initialize_transient_param_inputs(soln, self.param_inputs)
        self.param_inputs.tm = self.m_tm
        self.param_inputs.ramptime = self.m_flux_ramp_time
        self.param_inputs.finitial = 0.0
        self.param_inputs.ffinal = 1.0
        if self.m_flux_ramp_time == 0.0:
            self.param_inputs.finitial = 1.0
        self.trans_inputs.inlet_temp = self.m_T_htf_cold_des
        self.trans_inputs.tinit.fill(self.m_T_htf_cold_des)
        self.trans_inputs.tinit_wall.fill(self.m_T_htf_cold_des)
        var time_circulate, circulate_energy, parasitic: Float64
        self.solve_transient_startup_model(self.param_inputs, self.trans_inputs, self.CIRCULATE, self.m_T_htf_hot_des + self.m_startup_target_delta, 0.0, 1.e6, self.trans_outputs, time_circulate, circulate_energy, parasitic)
        if time_circulate == 1.e6:
            var tube_lam1 = (self.param_inputs.mflow_tot / self.m_n_lines / self.m_n_t) * self.param_inputs.c_htf / self.m_tm.at(1)
            var downc_lam1 = self.param_inputs.mflow_tot * self.param_inputs.c_htf / self.m_tm.back()
            time_circulate = (self.m_n_panels / self.m_n_lines) * self.m_h_rec / tube_lam1 + 0.5 * (self.m_h_tower * self.m_pipe_length_mult + self.m_pipe_length_add) / downc_lam1
            time_circulate += self.m_flux_ramp_time * 3600.0
        start_time += time_circulate
        start_time = fmax(start_time, self.m_rec_su_delay * 3600.0)
        start_energy += circulate_energy * 1.e-6 / 3600.0
        est_time = start_time
        est_energy = start_energy

    def est_heattrace_energy(self) -> Float64:
        var Tamb = 290.0
        if self.m_is_startup_transient:
            var riser_tm = self.m_tm_solid.at(0) * self.trans_inputs.length.at(0)
            var downc_tm = self.m_tm_solid.back() * self.trans_inputs.length.back()
            var heattrace_energy = (riser_tm + downc_tm) * (self.m_T_htf_cold_des - Tamb)
            return heattrace_energy * 1e-6 / 3600.0
        else:
            return 0.0

    def get_startup_time(self) -> Float64:
        var startup_time = QNAN
        if not self.m_is_startup_transient:
            startup_time = self.m_rec_su_delay * 3600.0
        else:
            var startup_energy: Float64
            var fract = 0.4
            self.est_startup_time_energy(fract, startup_time, startup_energy)
        return startup_time

    def get_startup_energy(self) -> Float64:
        var startup_energy = QNAN
        if not self.m_is_startup_transient:
            startup_energy = self.m_rec_qf_delay * self.m_q_rec_des * 1.e-6
        else:
            var startup_time: Float64
            var fract = 0.4
            self.est_startup_time_energy(fract, startup_time, startup_energy)
        return startup_energy