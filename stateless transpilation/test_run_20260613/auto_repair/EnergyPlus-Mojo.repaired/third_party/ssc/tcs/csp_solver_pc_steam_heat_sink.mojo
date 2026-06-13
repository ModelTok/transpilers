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
from csp_solver_core import C_csp_power_cycle, C_csp_weatherreader, C_csp_solver_htf_1state, C_csp_solver_sim_info, C_csp_reported_outputs, C_csp_exception, csp_info_invalid
from csp_solver_util import check_double
from water_properties import water_TP, water_PQ, water_PS, water_state
from lib_util import util
from memory import memset_zero
from math import isnan, nan
from sys import info as sys_info

@value
struct S_output_info:
    var index: Int
    var averaging: Int

var S_output_info_arr: StaticArray[S_output_info, 3] = StaticArray[S_output_info, 3](
    S_output_info(C_pc_steam_heat_sink.E_Q_DOT_HEAT_SINK, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_steam_heat_sink.E_W_DOT_PUMPING, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

@value
struct S_params:
    var m_x_hot_des: Float64
    var m_T_hot_des: Float64
    var m_P_hot_des: Float64
    var m_T_cold_des: Float64
    var m_dP_frac_des: Float64
    var m_q_dot_des: Float64
    var m_m_dot_max_frac: Float64
    var m_pump_eta_isen: Float64

    def __init__(inout self):
        self.m_x_hot_des = nan()
        self.m_T_hot_des = nan()
        self.m_P_hot_des = nan()
        self.m_T_cold_des = nan()
        self.m_dP_frac_des = nan()
        self.m_q_dot_des = nan()
        self.m_m_dot_max_frac = nan()
        self.m_pump_eta_isen = nan()

@value
class C_pc_steam_heat_sink(C_csp_power_cycle):
    enum E:
        E_Q_DOT_HEAT_SINK = 0
        E_W_DOT_PUMPING = 1

    var mc_reported_outputs: C_csp_reported_outputs
    var m_max_frac: Float64
    var mc_csp_messages: C_csp_messages
    var mc_water_props: water_state
    var ms_params: S_params

    def __init__(inout self):
        self.mc_reported_outputs = C_csp_reported_outputs()
        self.mc_reported_outputs.construct(S_output_info_arr)
        self.m_max_frac = 100.0
        self.m_is_sensible_htf = False
        self.mc_csp_messages = C_csp_messages()
        self.mc_water_props = water_state()
        self.ms_params = S_params()

    def __del__(owned self):

    def check_double_params_are_set(inout self):
        if not check_double(self.ms_params.m_x_hot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_x_hot_des")
        if not check_double(self.ms_params.m_T_hot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_T_hot_des")
        if not check_double(self.ms_params.m_P_hot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_P_hot_des")
        if not check_double(self.ms_params.m_T_cold_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_T_cold_des")
        if not check_double(self.ms_params.m_dP_frac_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_dP_frac_des")
        if not check_double(self.ms_params.m_q_dot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_q_dot_des")
        if not check_double(self.ms_params.m_m_dot_max_frac):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_m_dot_max_frac")
        if not check_double(self.ms_params.m_pump_eta_isen):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method: ", "m_pump_eta_isen")

    def init(inout self, inout solved_params: C_csp_power_cycle.S_solved_params):
        self.check_double_params_are_set()
        var prop_error_code: Int = -1
        if self.ms_params.m_x_hot_des < 0.0 or self.ms_params.m_x_hot_des > 1.0:
            prop_error_code = water_TP(self.ms_params.m_T_hot_des + 273.15, self.ms_params.m_P_hot_des, self.mc_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_pc_steam_heat_sink::init(...) Design hot state point property calcs failed")
        else:
            prop_error_code = water_PQ(self.ms_params.m_P_hot_des, self.ms_params.m_x_hot_des, self.mc_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_pc_steam_heat_sink::init(...) Design hot state point property calcs failed")
        var h_hot: Float64 = self.mc_water_props.enth
        var P_cold_des: Float64 = (1.0 - self.ms_params.m_dP_frac_des) * self.ms_params.m_P_hot_des
        prop_error_code = water_TP(self.ms_params.m_T_cold_des + 273.15, P_cold_des, self.mc_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_pc_steam_heat_sink::init(...) Design cold state point property calcs failed")
        var h_cold: Float64 = self.mc_water_props.enth
        var m_dot_steam_des: Float64 = self.ms_params.m_q_dot_des * 1.0E3 / (h_hot - h_cold)
        solved_params.m_W_dot_des = 0.0
        solved_params.m_eta_des = 0.0
        solved_params.m_q_dot_des = self.ms_params.m_q_dot_des
        solved_params.m_q_startup = 0.0
        solved_params.m_max_frac = self.ms_params.m_m_dot_max_frac
        solved_params.m_cutoff_frac = 0.0
        solved_params.m_sb_frac = 0.0
        solved_params.m_T_htf_hot_ref = self.ms_params.m_T_hot_des
        solved_params.m_m_dot_design = m_dot_steam_des * 3600.0
        solved_params.m_m_dot_min = solved_params.m_m_dot_design * solved_params.m_cutoff_frac
        solved_params.m_m_dot_max = solved_params.m_m_dot_design * solved_params.m_max_frac
        solved_params.m_P_hot_des = self.ms_params.m_P_hot_des
        solved_params.m_x_hot_des = self.ms_params.m_x_hot_des

    def get_operating_state(inout self) -> Int:
        return C_csp_power_cycle.ON

    def get_cold_startup_time(inout self) -> Float64:
        return 0.0

    def get_warm_startup_time(inout self) -> Float64:
        return 0.0

    def get_hot_startup_time(inout self) -> Float64:
        return 0.0

    def get_standby_energy_requirement(inout self) -> Float64:
        return 0.0

    def get_cold_startup_energy(inout self) -> Float64:
        return 0.0

    def get_warm_startup_energy(inout self) -> Float64:
        return 0.0

    def get_hot_startup_energy(inout self) -> Float64:
        return 0.0

    def get_max_thermal_power(inout self) -> Float64:
        return self.m_max_frac * self.ms_params.m_q_dot_des

    def get_min_thermal_power(inout self) -> Float64:
        return 0.0

    def get_htf_pumping_parasitic_coef(inout self) -> Float64:
        return 0.0

    def get_max_power_output_operation_constraints(inout self, T_amb: Float64, inout m_dot_HTF_ND_max: Float64, inout W_dot_ND_max: Float64):
        m_dot_HTF_ND_max = self.m_max_frac
        W_dot_ND_max = m_dot_HTF_ND_max
        return

    def get_efficiency_at_TPH(inout self, T_degC: Float64, P_atm: Float64, relhum_pct: Float64, w_dot_condenser: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        raise C_csp_exception("C_pc_steam_heat_sink::get_efficiency_at_TPH() is not complete")
        return nan()

    def get_efficiency_at_load(inout self, load_frac: Float64, w_dot_condenser: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        raise C_csp_exception("C_pc_steam_heat_sink::get_efficiency_at_load() is not complete")
        return nan()

    def get_max_q_pc_startup(inout self) -> Float64:
        return 0.0

    def call(inout self, weather: C_csp_weatherreader.S_outputs, inout htf_state_in: C_csp_solver_htf_1state, inputs: C_csp_power_cycle.S_control_inputs, inout out_solver: C_csp_power_cycle.S_csp_pc_out_solver, sim_info: C_csp_solver_sim_info):
        var T_steam_hot: Float64 = htf_state_in.m_temp + 273.15
        var P_steam_hot: Float64 = htf_state_in.m_pres
        var x_steam_hot: Float64 = htf_state_in.m_qual
        var m_dot_steam: Float64 = inputs.m_m_dot / 3600.0
        var prop_error_code: Int = -1
        if x_steam_hot < 0.0 or x_steam_hot > 1.0:
            prop_error_code = water_TP(T_steam_hot, P_steam_hot, self.mc_water_props)
            if prop_error_code != 0:
                var msg: String = util.format("Hot inlet water/steam properties failed at T = %lg [K] and P = %lg [kPa]", T_steam_hot, P_steam_hot)
                raise C_csp_exception("C_pc_steam_heat_sink::call(...)", msg)
        else:
            prop_error_code = water_PQ(P_steam_hot, x_steam_hot, self.mc_water_props)
            if prop_error_code != 0:
                var msg: String = util.format("Hot inlet water/steam properties failed at P = %lg [K] and x = %lg [-]", P_steam_hot, x_steam_hot)
                raise C_csp_exception("C_pc_steam_heat_sink::call(...)", msg)
        var h_steam_hot: Float64 = self.mc_water_props.enth
        var P_steam_cold: Float64 = (1.0 - self.ms_params.m_dP_frac_des) * self.ms_params.m_P_hot_des
        var T_steam_cold: Float64 = self.ms_params.m_T_cold_des + 273.15
        prop_error_code = water_TP(T_steam_cold, P_steam_cold, self.mc_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_pc_steam_heat_sink::call(...) Cold outlet water/steam property calcs failed")
        var h_steam_cold: Float64 = self.mc_water_props.enth
        var s_steam_cold: Float64 = self.mc_water_props.entr
        var q_dot_steam: Float64 = m_dot_steam * (h_steam_hot - h_steam_cold) / 1.0E3
        prop_error_code = water_PS(P_steam_hot, s_steam_cold, self.mc_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_pc_steam_heat_sink::call(...) Isentropic compression calcs failed")
        var h_steam_cold_comp_isen: Float64 = self.mc_water_props.enth
        var h_steam_cold_comp: Float64 = (h_steam_cold_comp_isen - h_steam_cold) / self.ms_params.m_pump_eta_isen + h_steam_cold
        out_solver.m_P_cycle = 0.0
        out_solver.m_T_htf_cold = T_steam_cold - 273.15
        out_solver.m_m_dot_htf = m_dot_steam * 3600.0
        out_solver.m_W_cool_par = 0.0
        out_solver.m_time_required_su = 0.0
        out_solver.m_q_dot_htf = q_dot_steam
        out_solver.m_W_dot_htf_pump = m_dot_steam * (h_steam_cold_comp - h_steam_cold) / 1.0E3
        out_solver.m_was_method_successful = True
        self.mc_reported_outputs.value(self.E_Q_DOT_HEAT_SINK, q_dot_steam)
        self.mc_reported_outputs.value(self.E_W_DOT_PUMPING, out_solver.m_W_dot_htf_pump)
        return

    def converged(inout self):
        self.mc_reported_outputs.set_timestep_outputs()
        return

    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: Pointer[Float64], report_time_end: Float64):
        self.mc_reported_outputs.send_to_reporting_ts_array(report_time_start, v_temp_ts_time_end, report_time_end)

    def assign(inout self, index: Int, p_reporting_ts_array: Pointer[Float64], n_reporting_ts_array: Int):
        self.mc_reported_outputs.assign(index, p_reporting_ts_array, n_reporting_ts_array)