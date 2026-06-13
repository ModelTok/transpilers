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
from csp_solver_util import *
from csp_solver_core import *
from sco2_pc_csp_int import *
from htf_props import *

struct S_output_info:
    var index: Int
    var type: Int

    def __init__(inout self, index: Int, type: Int):
        self.index = index
        self.type = type

var S_output_info_arr: List[S_output_info] = List[S_output_info](
    S_output_info(C_pc_sco2.E_ETA_THERMAL, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_Q_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_M_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_Q_DOT_STARTUP, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_W_DOT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_T_HTF_IN, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_T_HTF_OUT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_sco2.E_M_DOT_WATER, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

@value
struct C_pc_sco2:
    var mc_sco2_recomp: C_sco2_phx_air_cooler
    var mc_pc_htfProps: HTFProperties
    var m_q_dot_design: Float64
    var m_q_dot_standby: Float64
    var m_q_dot_max: Float64
    var m_q_dot_min: Float64
    var m_startup_energy_required: Float64
    var m_W_dot_des: Float64
    var m_T_htf_cold_des: Float64
    var m_m_dot_htf_des: Float64
    var m_standby_control_prev: Int
    var m_startup_time_remain_prev: Float64
    var m_startup_energy_remain_prev: Float64
    var m_standby_control_calc: Int
    var m_startup_time_remain_calc: Float64
    var m_startup_energy_remain_calc: Float64
    var mc_reported_outputs: C_csp_reported_outputs
    var mc_csp_messages: C_csp_messages
    var ms_params: S_des_par

    def __init__(inout self):
        self.m_q_dot_design = Float64.NaN
        self.m_q_dot_standby = Float64.NaN
        self.m_q_dot_max = Float64.NaN
        self.m_q_dot_min = Float64.NaN
        self.m_startup_energy_required = Float64.NaN
        self.m_W_dot_des = Float64.NaN
        self.m_T_htf_cold_des = Float64.NaN
        self.m_m_dot_htf_des = Float64.NaN
        self.m_startup_time_remain_prev = Float64.NaN
        self.m_startup_energy_remain_prev = Float64.NaN
        self.m_startup_time_remain_calc = Float64.NaN
        self.m_startup_energy_remain_calc = Float64.NaN
        self.m_standby_control_prev = -1
        self.m_standby_control_calc = -1
        self.mc_reported_outputs.construct(S_output_info_arr)

    def __del__(owned self):

    def init(inout self, solved_params: C_csp_power_cycle.S_solved_params):
        self.mc_sco2_recomp.design(self.ms_params.ms_mc_sco2_recomp_params)
        if self.ms_params.ms_mc_sco2_recomp_params.m_hot_fl_code != HTFProperties.User_defined and self.ms_params.ms_mc_sco2_recomp_params.m_hot_fl_code < HTFProperties.End_Library_Fluids:
            if not self.mc_pc_htfProps.SetFluid(self.ms_params.ms_mc_sco2_recomp_params.m_hot_fl_code):
                throw(C_csp_exception("Power cycle HTF code is not recognized", "sCO2 Power Cycle Initialization"))
        elif self.ms_params.ms_mc_sco2_recomp_params.m_hot_fl_code == HTFProperties.User_defined:
            var n_rows: Int = self.ms_params.ms_mc_sco2_recomp_params.mc_hot_fl_props.nrows()
            var n_cols: Int = self.ms_params.ms_mc_sco2_recomp_params.mc_hot_fl_props.ncols()
            if n_rows > 2 and n_cols == 7:
                if not self.mc_pc_htfProps.SetUserDefinedFluid(self.ms_params.ms_mc_sco2_recomp_params.mc_hot_fl_props):
                    var error_msg: String = util.format(self.mc_pc_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    throw(C_csp_exception(error_msg, "sCO2 Power Cycle Initialization"))
            else:
                var error_msg: String = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                throw(C_csp_exception(error_msg, "sCO2 Power Cycle Initialization"))
        else:
            throw(C_csp_exception("Power cycle HTF code is not recognized", "sCO2 Power Cycle Initialization"))
        solved_params.m_W_dot_des = self.mc_sco2_recomp.get_design_solved().ms_rc_cycle_solved.m_W_dot_net / 1.E3
        self.m_W_dot_des = solved_params.m_W_dot_des
        solved_params.m_eta_des = self.mc_sco2_recomp.get_design_solved().ms_rc_cycle_solved.m_eta_thermal
        self.m_q_dot_design = solved_params.m_W_dot_des / solved_params.m_eta_des
        solved_params.m_q_dot_des = self.m_q_dot_design
        self.m_startup_energy_required = self.ms_params.m_startup_frac * solved_params.m_q_dot_des * 1.E3
        solved_params.m_q_startup = self.m_startup_energy_required / 1.E3
        solved_params.m_max_frac = self.ms_params.m_cycle_max_frac
        solved_params.m_cutoff_frac = self.ms_params.m_cycle_cutoff_frac
        solved_params.m_sb_frac = self.ms_params.m_q_sby_frac
        solved_params.m_T_htf_hot_ref = self.ms_params.ms_mc_sco2_recomp_params.m_T_htf_hot_in - 273.15
        solved_params.m_m_dot_design = self.mc_sco2_recomp.get_phx_des_par().m_m_dot_hot_des * 3600.0
        solved_params.m_m_dot_min = solved_params.m_m_dot_design * solved_params.m_cutoff_frac
        solved_params.m_m_dot_max = solved_params.m_m_dot_design * solved_params.m_max_frac
        self.m_m_dot_htf_des = solved_params.m_m_dot_design
        self.m_q_dot_standby = self.ms_params.m_q_sby_frac * self.m_q_dot_design
        self.m_q_dot_max = self.ms_params.m_cycle_max_frac * self.m_q_dot_design
        self.m_q_dot_min = self.ms_params.m_cycle_cutoff_frac * self.m_q_dot_design
        self.m_T_htf_cold_des = self.mc_sco2_recomp.get_design_solved().ms_phx_des_solved.m_T_h_out
        self.m_standby_control_prev = OFF
        self.m_startup_energy_remain_prev = self.m_startup_energy_required
        self.m_startup_time_remain_prev = self.ms_params.m_startup_time

    def get_operating_state(inout self) -> Int:
        if self.ms_params.m_startup_frac == 0.0 and self.ms_params.m_startup_time == 0.0:
            return C_csp_power_cycle.ON
        return self.m_standby_control_prev

    def get_cold_startup_time(inout self) -> Float64:
        return self.ms_params.m_startup_time

    def get_warm_startup_time(inout self) -> Float64:
        return self.ms_params.m_startup_time

    def get_hot_startup_time(inout self) -> Float64:
        return self.ms_params.m_startup_time

    def get_standby_energy_requirement(inout self) -> Float64:
        return self.m_q_dot_standby

    def get_cold_startup_energy(inout self) -> Float64:
        return self.m_startup_energy_required / 1.E3

    def get_warm_startup_energy(inout self) -> Float64:
        return self.m_startup_energy_required / 1.E3

    def get_hot_startup_energy(inout self) -> Float64:
        return self.m_startup_energy_required / 1.E3

    def get_max_thermal_power(inout self) -> Float64:
        return self.m_q_dot_max

    def get_min_thermal_power(inout self) -> Float64:
        return self.m_q_dot_min

    def get_max_power_output_operation_constraints(inout self, T_amb: Float64, m_dot_HTF_ND_max: Float64, W_dot_ND_max: Float64):
        throw(C_csp_exception("C_pc_sco2::get_max_power_output_operation_constraints() is not complete"))
        return

    def get_efficiency_at_TPH(inout self, T_degC: Float64, P_atm: Float64, relhum_pct: Float64, w_dot_condenser: Float64) -> Float64:
        throw(C_csp_exception("C_pc_sco2::get_efficiency_at_TPH() is not complete"))
        return Float64.NaN

    def get_efficiency_at_load(inout self, load_frac: Float64, w_dot_condenser: Float64) -> Float64:
        throw(C_csp_exception("C_pc_sco2::get_efficiency_at_load() is not complete"))
        return Float64.NaN

    def get_max_q_pc_startup(inout self) -> Float64:
        if self.m_startup_time_remain_prev > 0.0:
            return fmin(self.m_q_dot_max, self.m_startup_energy_remain_prev / 1.E3 / self.m_startup_time_remain_prev)
        elif self.m_startup_energy_remain_prev > 0.0:
            return self.m_q_dot_max
        else:
            return 0.0

    def get_htf_pumping_parasitic_coef(inout self) -> Float64:
        return self.ms_params.m_htf_pump_coef * (self.m_m_dot_htf_des / 3600.0) / (self.m_q_dot_design * 1000.0)

    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: C_csp_power_cycle.S_control_inputs, out_solver: C_csp_power_cycle.S_csp_pc_out_solver, sim_info: C_csp_solver_sim_info):
        var step_sec: Float64 = sim_info.ms_ts.m_step
        var T_htf_hot: Float64 = htf_state_in.m_temp + 273.15
        var m_dot_htf: Float64 = inputs.m_m_dot
        var standby_control: Int = inputs.m_standby_control
        self.m_standby_control_calc = standby_control
        var P_cycle: Float64 = Float64.NaN
        var eta: Float64 = Float64.NaN
        var T_htf_cold: Float64 = Float64.NaN
        var m_dot_demand: Float64 = Float64.NaN
        var W_cool_par: Float64 = Float64.NaN
        var time_required_su: Float64 = 0.0
        var q_startup: Float64 = 0.0
        var q_dot_htf: Float64 = Float64.NaN
        var was_method_successful: Bool = True
        if standby_control == STARTUP:
            var c_htf: Float64 = self.mc_pc_htfProps.Cp((T_htf_hot + self.m_T_htf_cold_des) / 2.0)
            var time_required_su_energy: Float64 = self.m_startup_energy_remain_prev / (m_dot_htf * c_htf * (T_htf_hot - self.m_T_htf_cold_des) / 3600)
            var time_required_su_ramping: Float64 = self.m_startup_time_remain_prev
            var time_required_max: Float64 = fmax(time_required_su_energy, time_required_su_ramping)
            var time_step_hrs: Float64 = step_sec / 3600.0
            if time_required_max > time_step_hrs:
                time_required_su = time_step_hrs
                self.m_standby_control_calc = STARTUP
                q_startup = m_dot_htf * c_htf * (T_htf_hot - self.m_T_htf_cold_des) * time_step_hrs / 3600.0
            else:
                time_required_su = time_required_max
                self.m_standby_control_calc = ON
                var q_startup_energy_req: Float64 = self.m_startup_energy_remain_prev
                var q_startup_ramping_req: Float64 = m_dot_htf * c_htf * (T_htf_hot - self.m_T_htf_cold_des) * self.m_startup_time_remain_prev / 3600.0
                q_startup = fmax(q_startup_energy_req, q_startup_ramping_req)
            self.m_startup_time_remain_calc = fmax(self.m_startup_time_remain_prev - time_required_su, 0.0)
            self.m_startup_energy_remain_calc = fmax(self.m_startup_energy_remain_prev - q_startup, 0.0)
            q_dot_htf = q_startup / 1000.0 / time_required_su
            P_cycle = 0.0
            eta = 0.0
            T_htf_cold = self.m_T_htf_cold_des
            m_dot_demand = 0.0
            W_cool_par = 0.0
            was_method_successful = True
        elif standby_control == ON:
            var sco2_rc_od_par: C_sco2_phx_air_cooler.S_od_par
            sco2_rc_od_par.m_T_htf_hot = T_htf_hot
            sco2_rc_od_par.m_m_dot_htf = m_dot_htf / 3600.0
            sco2_rc_od_par.m_T_amb = weather.m_tdry + 273.15
            sco2_rc_od_par.m_T_t_in_mode = C_sco2_cycle_core.E_SOLVE_PHX
            var od_strategy: C_sco2_phx_air_cooler.E_off_design_strategies = C_sco2_phx_air_cooler.E_TARGET_POWER_ETA_MAX
            var off_design_code: Int = 0
            try:
                off_design_code = self.mc_sco2_recomp.off_design__constant_N__T_mc_in_P_LP_in__objective(sco2_rc_od_par, True, 1.0, True, 1.0, True, 1.0, False, Float64.NaN, od_strategy, 1.E-3, 1.E-3)
            except C_csp_exception as csp_exception:
                throw(C_csp_exception(csp_exception.m_error_message, "sCO2 power cycle"))
            if off_design_code == 0:
                P_cycle = self.mc_sco2_recomp.get_od_solved().ms_rc_cycle_od_solved.m_W_dot_net
                eta = self.mc_sco2_recomp.get_od_solved().ms_rc_cycle_od_solved.m_eta_thermal
                T_htf_cold = self.mc_sco2_recomp.get_od_solved().ms_phx_od_solved.m_T_h_out
                q_dot_htf = P_cycle / eta / 1.E3
                W_cool_par = 0.0
                m_dot_demand = 0.0
                was_method_successful = True
            else:
                P_cycle = 0.0
                eta = 0.0
                T_htf_cold = self.m_T_htf_cold_des
                q_dot_htf = 0.0
                W_cool_par = 0.0
                m_dot_demand = 0.0
                was_method_successful = False
        elif standby_control == STANDBY:
            var c_htf: Float64 = self.mc_pc_htfProps.Cp((T_htf_hot + self.m_T_htf_cold_des) / 2.0)
            var q_sby_needed: Float64 = self.m_q_dot_standby
            var m_dot_sby: Float64 = q_sby_needed / (c_htf * (T_htf_hot - self.m_T_htf_cold_des)) * 3600.0
            P_cycle = 0.0
            eta = 0.0
            T_htf_cold = self.m_T_htf_cold_des
            m_dot_demand = m_dot_sby
            W_cool_par = 0.0
            q_dot_htf = m_dot_htf / 3600.0 * c_htf * (T_htf_hot - T_htf_cold) / 1000.0
            was_method_successful = True
        elif standby_control == OFF:
            P_cycle = 0.0
            eta = 0.0
            T_htf_cold = self.m_T_htf_cold_des
            m_dot_demand = 0.0
            W_cool_par = 0.0
            q_dot_htf = 0.0
            self.m_startup_time_remain_calc = self.ms_params.m_startup_time
            self.m_startup_energy_remain_calc = self.m_startup_energy_required
            was_method_successful = True
        elif standby_control == STARTUP_CONTROLLED:
            var c_htf: Float64 = self.mc_pc_htfProps.Cp((T_htf_hot + self.m_T_htf_cold_des) / 2.0)
            var q_dot_to_pc_max: Float64 = self.m_q_dot_max * 1.E3
            var time_required_su_energy: Float64 = self.m_startup_energy_remain_prev / q_dot_to_pc_max
            var time_required_su_ramping: Float64 = self.m_startup_time_remain_prev
            if time_required_su_energy > time_required_su_ramping:
                if time_required_su_energy > step_sec / 3600.0:
                    time_required_su = step_sec / 3600.0
                    self.m_standby_control_calc = STARTUP
                else:
                    time_required_su = time_required_su_energy
                    self.m_standby_control_calc = ON
            else:
                if time_required_su_ramping > step_sec / 3600.0:
                    time_required_su = step_sec / 3600.0
                    self.m_standby_control_calc = STARTUP
                else:
                    time_required_su = time_required_su_ramping
                    self.m_standby_control_calc = ON
            q_startup = q_dot_to_pc_max * time_required_su
            var m_dot_htf_required: Float64 = (q_startup / time_required_su) / (c_htf * (T_htf_hot - self.m_T_htf_cold_des))
            self.m_startup_time_remain_calc = fmax(self.m_startup_time_remain_prev - time_required_su, 0.0)
            self.m_startup_energy_remain_calc = fmax(self.m_startup_energy_remain_prev - q_startup, 0.0)
            P_cycle = 0.0
            eta = 0.0
            T_htf_cold = self.m_T_htf_cold_des
            m_dot_htf = m_dot_htf_required * 3600.0
            W_cool_par = 0.0
            q_dot_htf = m_dot_htf_required * c_htf * (T_htf_hot - self.m_T_htf_cold_des) / 1000.0
            was_method_successful = True
        out_solver.m_P_cycle = P_cycle / 1000.0
        self.mc_reported_outputs.value(E_ETA_THERMAL, eta)
        out_solver.m_T_htf_cold = T_htf_cold - 273.15
        self.mc_reported_outputs.value(E_M_DOT_WATER, 0.0)
        out_solver.m_m_dot_htf = m_dot_htf
        out_solver.m_W_cool_par = W_cool_par
        var q_dot_startup: Float64 = 0.0
        if q_startup > 0.0:
            q_dot_startup = q_startup / 1.E3 / time_required_su
        else:
            q_dot_startup = 0.0
        out_solver.m_time_required_su = time_required_su * 3600.0
        out_solver.m_q_dot_htf = q_dot_htf
        out_solver.m_W_dot_htf_pump = self.ms_params.m_htf_pump_coef * (m_dot_htf / 3.6E6)
        out_solver.m_was_method_successful = was_method_successful

    def converged(inout self):
        self.m_standby_control_prev = self.m_standby_control_calc
        self.m_startup_time_remain_prev = self.m_startup_time_remain_calc
        self.m_startup_energy_remain_prev = self.m_startup_energy_remain_calc
        self.mc_reported_outputs.set_timestep_outputs()

    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64):
        self.mc_reported_outputs.send_to_reporting_ts_array(report_time_start, v_temp_ts_time_end, report_time_end)

    def assign(inout self, index: Int, p_reporting_ts_array: Float64, n_reporting_ts_array: Int):
        self.mc_reported_outputs.assign(index, p_reporting_ts_array, n_reporting_ts_array)

struct S_des_par:
    var ms_mc_sco2_recomp_params: C_sco2_phx_air_cooler.S_des_par
    var m_cycle_max_frac: Float64
    var m_cycle_cutoff_frac: Float64
    var m_q_sby_frac: Float64
    var m_startup_time: Float64
    var m_startup_frac: Float64
    var m_htf_pump_coef: Float64

    def __init__(inout self):
        self.m_cycle_max_frac = Float64.NaN
        self.m_cycle_cutoff_frac = Float64.NaN
        self.m_q_sby_frac = Float64.NaN
        self.m_startup_time = Float64.NaN
        self.m_startup_frac = Float64.NaN
        self.m_htf_pump_coef = Float64.NaN