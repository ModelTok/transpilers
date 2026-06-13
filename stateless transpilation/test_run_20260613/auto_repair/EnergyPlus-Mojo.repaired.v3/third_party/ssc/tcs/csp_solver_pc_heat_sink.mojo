"""
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
"""
from csp_solver_core import C_csp_power_cycle, C_csp_weatherreader, C_csp_solver_htf_1state, C_csp_solver_sim_info, C_csp_reported_outputs, C_csp_messages, C_csp_exception
from csp_solver_util import check_double, util
from lib_util import *
from htf_props import HTFProperties

@value
struct S_output_info:
    var index: Int
    var type: Int

var csp_info_invalid = S_output_info(-1, -1)

var S_output_info_arr: List[S_output_info] = List[S_output_info](
    S_output_info(C_pc_heat_sink.E_Q_DOT_HEAT_SINK, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_heat_sink.E_W_DOT_PUMPING, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_heat_sink.E_M_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_heat_sink.E_T_HTF_IN, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_heat_sink.E_T_HTF_OUT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

class C_pc_heat_sink(C_csp_power_cycle):
    enum E:
        E_Q_DOT_HEAT_SINK = 0      # [MWt]
        E_W_DOT_PUMPING = 1        # [MWe]
        E_M_DOT_HTF = 2            # [kg/s]
        E_T_HTF_IN = 3             # [C]
        E_T_HTF_OUT = 4            # [C]

    var mc_reported_outputs: C_csp_reported_outputs

    var m_max_frac: Float64
    var m_m_dot_htf_des: Float64
    var mc_pc_htfProps: HTFProperties

    def check_double_params_are_set(self) raises:
        if not check_double(self.ms_params.m_T_htf_cold_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method:", "m_W_dot_des")
        if not check_double(self.ms_params.m_T_htf_hot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method:", "m_W_dot_des")
        if not check_double(self.ms_params.m_q_dot_des):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method:", "m_W_dot_des")
        if not check_double(self.ms_params.m_htf_pump_coef):
            raise C_csp_exception("The following parameter was not set prior to calling the C_pc_heat_sink init() method:", "m_W_dot_des")

    var mc_csp_messages: C_csp_messages

    @value
    struct S_params:
        var m_T_htf_cold_des: Float64
        var m_T_htf_hot_des: Float64
        var m_q_dot_des: Float64
        var m_htf_pump_coef: Float64
        var m_pc_fl: Int
        var m_pc_fl_props: matrix_t[Float64]

        def __init__(self):
            self.m_T_htf_cold_des = Float64.NaN
            self.m_T_htf_hot_des = Float64.NaN
            self.m_q_dot_des = Float64.NaN
            self.m_htf_pump_coef = Float64.NaN
            self.m_pc_fl = 0
            self.m_pc_fl_props = matrix_t[Float64]()

    var ms_params: S_params

    def __init__(self):
        self.mc_reported_outputs = C_csp_reported_outputs()
        self.mc_reported_outputs.construct(S_output_info_arr)
        self.m_max_frac = 100.0
        self.m_m_dot_htf_des = Float64.NaN
        self.ms_params = S_params()
        self.mc_csp_messages = C_csp_messages()
        self.mc_pc_htfProps = HTFProperties()

    def __del__(self):

    def init(self, inout solved_params: C_csp_power_cycle.S_solved_params) raises:
        self.check_double_params_are_set()
        if self.ms_params.m_pc_fl != HTFProperties.User_defined and self.ms_params.m_pc_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_pc_htfProps.SetFluid(self.ms_params.m_pc_fl):
                raise C_csp_exception("Power cycle HTF code is not recognized", "Rankine Indirect Power Cycle Initialization")
        elif self.ms_params.m_pc_fl == HTFProperties.User_defined:
            var n_rows = self.ms_params.m_pc_fl_props.nrows()
            var n_cols = self.ms_params.m_pc_fl_props.ncols()
            if n_rows > 2 and n_cols == 7:
                if not self.mc_pc_htfProps.SetUserDefinedFluid(self.ms_params.m_pc_fl_props):
                    var error_msg = util.format(self.mc_pc_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(error_msg, "Heat Sink Initialization")
            else:
                var error_msg = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(error_msg, "Heat Sink Initialization")
        else:
            raise C_csp_exception("Power cycle HTF code is not recognized", "Heat Sink Initialization")
        var cp_htf_des = self.mc_pc_htfProps.Cp_ave(self.ms_params.m_T_htf_cold_des + 273.15, self.ms_params.m_T_htf_hot_des + 273.15, 5)
        self.m_m_dot_htf_des = self.ms_params.m_q_dot_des * 1.0e3 / (cp_htf_des * (self.ms_params.m_T_htf_hot_des - self.ms_params.m_T_htf_cold_des))
        solved_params.m_W_dot_des = 0.0
        solved_params.m_eta_des = 1.0
        solved_params.m_q_dot_des = self.ms_params.m_q_dot_des
        solved_params.m_q_startup = 0.0
        solved_params.m_max_frac = self.m_max_frac
        solved_params.m_max_frac = 1.0
        solved_params.m_cutoff_frac = 0.0
        solved_params.m_sb_frac = 0.0
        solved_params.m_T_htf_hot_ref = self.ms_params.m_T_htf_hot_des
        solved_params.m_m_dot_design = self.m_m_dot_htf_des * 3600.0
        solved_params.m_m_dot_min = solved_params.m_m_dot_design * solved_params.m_cutoff_frac
        solved_params.m_m_dot_max = solved_params.m_m_dot_design * solved_params.m_max_frac

    def get_operating_state(self) -> Int:
        return C_csp_power_cycle.ON

    def get_cold_startup_time(self) -> Float64:
        return 0.0

    def get_warm_startup_time(self) -> Float64:
        return 0.0

    def get_hot_startup_time(self) -> Float64:
        return 0.0

    def get_standby_energy_requirement(self) -> Float64:
        return 0.0

    def get_cold_startup_energy(self) -> Float64:
        return 0.0

    def get_warm_startup_energy(self) -> Float64:
        return 0.0

    def get_hot_startup_energy(self) -> Float64:
        return 0.0

    def get_max_thermal_power(self) -> Float64:
        return self.m_max_frac * self.ms_params.m_q_dot_des

    def get_min_thermal_power(self) -> Float64:
        return 0.0

    def get_max_power_output_operation_constraints(self, T_amb: Float64, inout m_dot_HTF_ND_max: Float64, inout W_dot_ND_max: Float64):
        m_dot_HTF_ND_max = self.m_max_frac
        W_dot_ND_max = m_dot_HTF_ND_max
        return

    def get_efficiency_at_TPH(self, T_degC: Float64, P_atm: Float64, relhum_pct: Float64, w_dot_condenser: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        return 1.0

    def get_efficiency_at_load(self, load_frac: Float64, w_dot_condenser: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        return 1.0

    def get_max_q_pc_startup(self) -> Float64:
        return 0.0

    def get_htf_pumping_parasitic_coef(self) -> Float64:
        return self.ms_params.m_htf_pump_coef * self.m_m_dot_htf_des / (self.ms_params.m_q_dot_des * 1000.0)

    def call(self, weather: C_csp_weatherreader.S_outputs, inout htf_state_in: C_csp_solver_htf_1state, inputs: C_csp_power_cycle.S_control_inputs, inout out_solver: C_csp_power_cycle.S_csp_pc_out_solver, sim_info: C_csp_solver_sim_info) raises:
        var T_htf_hot = htf_state_in.m_temp
        var m_dot_htf = inputs.m_m_dot / 3600.0
        var cp_htf = self.mc_pc_htfProps.Cp_ave(self.ms_params.m_T_htf_cold_des + 273.15, T_htf_hot + 273.15, 5)
        var q_dot_htf = m_dot_htf * cp_htf * (T_htf_hot - self.ms_params.m_T_htf_cold_des) / 1.0e3
        out_solver.m_P_cycle = 0.0
        out_solver.m_T_htf_cold = self.ms_params.m_T_htf_cold_des
        out_solver.m_m_dot_htf = m_dot_htf * 3600.0
        out_solver.m_W_cool_par = 0.0
        out_solver.m_time_required_su = 0.0
        out_solver.m_q_dot_htf = q_dot_htf
        out_solver.m_W_dot_htf_pump = self.ms_params.m_htf_pump_coef * m_dot_htf / 1.0e3
        out_solver.m_was_method_successful = True
        self.mc_reported_outputs.value(self.E.E_Q_DOT_HEAT_SINK, q_dot_htf)
        self.mc_reported_outputs.value(self.E.E_W_DOT_PUMPING, out_solver.m_W_dot_htf_pump)
        self.mc_reported_outputs.value(self.E.E_M_DOT_HTF, m_dot_htf)
        self.mc_reported_outputs.value(self.E.E_T_HTF_IN, T_htf_hot)
        self.mc_reported_outputs.value(self.E.E_T_HTF_OUT, out_solver.m_T_htf_cold)
        return

    def converged(self):
        self.mc_reported_outputs.set_timestep_outputs()
        return

    def write_output_intervals(self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64):
        self.mc_reported_outputs.send_to_reporting_ts_array(report_time_start, v_temp_ts_time_end, report_time_end)

    def assign(self, index: Int, p_reporting_ts_array: Pointer[Float64], n_reporting_ts_array: Int):
        self.mc_reported_outputs.assign(index, p_reporting_ts_array, n_reporting_ts_array)
        return