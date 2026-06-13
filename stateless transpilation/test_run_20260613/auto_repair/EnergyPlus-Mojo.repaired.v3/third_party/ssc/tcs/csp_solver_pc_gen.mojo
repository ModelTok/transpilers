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
# from csp_solver_util import check_double, format
from csp_solver_core import C_csp_power_cycle, C_csp_reported_outputs, C_csp_solver_htf_1state, C_csp_solver_sim_info, C_csp_weatherreader, C_csp_exception, S_output_info, csp_info_invalid
from lib_util import format
from math import pow

# Global static output info array
let S_output_info: List[S_output_info] = List[S_output_info](
    S_output_info(C_pc_gen.E_ETA_THERMAL, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

struct C_pc_gen():
    # Private members
    var m_T_htf_cold_fixed: Float64   # [K]
    var m_T_htf_hot_fixed: Float64    # [K]
    var m_cp_htf_fixed: Float64       # [kJ/kg-K]
    var m_q_startup_remain: Float64   # [MWt]
    var m_q_startup_used: Float64     # [MWt]
    var m_pc_mode_prev: Int           # [-]
    var m_pc_mode: Int                # [-]
    var m_q_des: Float64              # [MWt]
    var m_qttmin: Float64             # [MWt]
    var m_qttmax: Float64             # [MWt]

    # Public members
    # Enum for output indices
    enum:
        E_ETA_THERMAL = 0   # [-]

    var mc_reported_outputs: C_csp_reported_outputs
    var mc_csp_messages: C_csp_messages   # (assuming this exists; if not, replace with appropriate type)

    var ms_params: S_params

    # S_params struct inside
    struct S_params:
        var m_W_dot_des: Float64   # [MWe]
        var m_eta_des: Float64     # [-]
        var m_f_wmax: Float64      # [-]
        var m_f_wmin: Float64      # [-]
        var m_f_startup: Float64   # [hr]
        var m_T_pc_des: Float64    # [C]
        var m_PC_T_corr: Int       # [-]
        var mv_etaQ_coefs: List[Float64]   # [1/Mwt]
        var mv_etaT_coefs: List[Float64]   # [1/C]

        def __init__(inout self):
            self.m_W_dot_des = Float64.NaN
            self.m_eta_des = Float64.NaN
            self.m_f_wmax = Float64.NaN
            self.m_f_wmin = Float64.NaN
            self.m_f_startup = Float64.NaN
            self.m_T_pc_des = Float64.NaN
            self.m_PC_T_corr = -1
            self.mv_etaQ_coefs = List[Float64]()
            self.mv_etaT_coefs = List[Float64]()

    # Constructor
    def __init__(inout self):
        self.m_T_htf_cold_fixed = 300.0 + 273.15  # [K]
        self.m_T_htf_hot_fixed = 500.0 + 273.15   # [K]
        self.m_cp_htf_fixed = 2.0                 # [kJ/kg-K]
        self.m_q_startup_remain = Float64.NaN
        self.m_q_startup_used = Float64.NaN
        self.m_q_des = Float64.NaN
        self.m_qttmin = Float64.NaN
        self.m_qttmax = Float64.NaN
        self.m_pc_mode_prev = -1
        self.m_pc_mode = -1
        self.mc_reported_outputs = C_csp_reported_outputs()
        self.mc_reported_outputs.construct(S_output_info)

    # Destructor (not needed in Mojo)
    # ~C_pc_gen() {}

    def get_fixed_properties(inout self, inout T_htf_cold_fixed: Float64, inout T_htf_hot_fixed: Float64, inout cp_htf_fixed: Float64):
        """[K] temperatures, [kJ/kg-K] cp"""
        T_htf_cold_fixed = self.m_T_htf_cold_fixed  # [K]
        T_htf_hot_fixed = self.m_T_htf_hot_fixed    # [K]
        cp_htf_fixed = self.m_cp_htf_fixed           # [kJ/kg-K]

    def check_double_params_are_set(self) raises:
        if not check_double(self.ms_params.m_W_dot_des):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_W_dot_des")
        if not check_double(self.ms_params.m_eta_des):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_eta_des")
        if not check_double(self.ms_params.m_f_wmax):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_f_wmax")
        if not check_double(self.ms_params.m_f_wmin):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_f_wmin")
        if not check_double(self.ms_params.m_f_startup):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_f_startup")
        if not check_double(self.ms_params.m_T_pc_des):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_T_pc_des")

    def init(inout self, inout solved_params: C_csp_power_cycle.S_solved_params) raises:
        self.check_double_params_are_set()
        if self.ms_params.m_PC_T_corr < 1 or self.ms_params.m_PC_T_corr > 2:
            var msg: String = format("The power cycle temperature correction mode must be "
                "1 (Wet Bulb) or 2 (Dry Bulb). The input value was %d, so it was reset to 2.", self.ms_params.m_PC_T_corr)
            self.mc_csp_messages.add_notice(msg)
            self.ms_params.m_PC_T_corr = 2
        if self.ms_params.mv_etaQ_coefs.size < 1:
            raise C_csp_exception("C_csp_gen_pc::init",
                "The model requires at least one part-load power cycle efficiency coefficient (mv_etaQ_coefs)")
        if self.ms_params.mv_etaT_coefs.size < 1:
            raise C_csp_exception("C_csp_gen_pc::init",
                "The model requires at least one temperature correction power cycle efficiency coefficient (mv_etaT_coefs)")
        self.ms_params.m_T_pc_des += 273.15  # [K], convert from C
        self.m_q_des = self.ms_params.m_W_dot_des / self.ms_params.m_eta_des  # [MWt]
        self.m_qttmin = self.m_q_des * self.ms_params.m_f_wmin   # [MWt]
        self.m_qttmax = self.m_q_des * self.ms_params.m_f_wmax   # [MWt]
        self.m_q_startup_remain = self.m_q_des * self.ms_params.m_f_startup  # [MWt-hr]
        self.m_pc_mode_prev = 0
        solved_params.m_W_dot_des = self.ms_params.m_W_dot_des   # [MWe]
        solved_params.m_eta_des = self.ms_params.m_eta_des        # [-]
        solved_params.m_q_dot_des = self.m_q_des                  # [MWt]
        solved_params.m_q_startup = self.m_q_startup_remain       # [MWt-hr]
        solved_params.m_max_frac = self.ms_params.m_f_wmax        # [-]
        solved_params.m_cutoff_frac = self.ms_params.m_f_wmin     # [-]
        solved_params.m_sb_frac = 0.0                             # [-]
        solved_params.m_T_htf_hot_ref = self.m_T_htf_hot_fixed - 273.15  # [C]
        solved_params.m_m_dot_design = self.m_q_des * 1.0e3 / (self.m_cp_htf_fixed * (self.m_T_htf_hot_fixed - self.m_T_htf_cold_fixed)) * 3600.0  # [kg/hr]
        solved_params.m_m_dot_min = solved_params.m_m_dot_design * solved_params.m_cutoff_frac  # [kg/hr]
        solved_params.m_m_dot_max = solved_params.m_m_dot_design * solved_params.m_max_frac     # [kg/hr]

    def get_operating_state(self) -> Int:
        return self.m_pc_mode_prev  # [-]

    def get_cold_startup_time(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_cold_startup_time() is not complete")
        return Float64.NaN

    def get_warm_startup_time(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_warm_startup_time() is not complete")
        return Float64.NaN

    def get_hot_startup_time(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_hot_startup_time() is not complete")
        return Float64.NaN

    def get_standby_energy_requirement(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_standby_energy_requirement() is not complete")
        return Float64.NaN  # [MWt]

    def get_cold_startup_energy(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_cold_startup_energy() is not complete")
        return Float64.NaN  # [MWh]

    def get_warm_startup_energy(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_warm_startup_energy() is not complete")
        return Float64.NaN  # [MWh]

    def get_hot_startup_energy(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_hot_startup_energy() is not complete")
        return Float64.NaN  # [MWh]

    def get_max_thermal_power(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_max_thermal_power() is not complete")
        return Float64.NaN  # [MW]

    def get_min_thermal_power(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_min_thermal_power() is not complete")
        return Float64.NaN  # [MW]

    def get_max_power_output_operation_constraints(self, T_amb: Float64, inout m_dot_HTF_ND_max: Float64, inout W_dot_ND_max: Float64) raises:
        raise C_csp_exception("C_csp_gen_pc::get_max_power_output_operation_constraints() is not complete")
        return  # [-]

    def get_efficiency_at_TPH(self, T_degC: Float64, P_atm: Float64, relhum_pct: Float64, w_dot_condenser: Optional[Pointer[Float64]] = None) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_efficiency_at_TPH() is not complete")
        return Float64.NaN

    def get_efficiency_at_load(self, load_frac: Float64, w_dot_condenser: Optional[Pointer[Float64]] = None) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_efficiency_at_load() is not complete")
        return Float64.NaN

    def get_max_q_pc_startup(self) -> Float64 raises:
        raise C_csp_exception("C_csp_gen_pc::get_max_q_pc_startup() is not complete")
        return Float64.NaN  # [MWt]

    def get_htf_pumping_parasitic_coef(self) -> Float64 raises:
        raise C_csp_exception("C_pc_gen::get_htf_pumping_parasitic_coef() is not complete")
        return Float64.NaN  # [MWt]  kWe/kWt

    def call(self, weather: C_csp_weatherreader.S_outputs,
        htf_state_in: C_csp_solver_htf_1state,
        inputs: C_csp_power_cycle.S_control_inputs,
        out_solver: C_csp_power_cycle.S_csp_pc_out_solver,
        sim_info: C_csp_solver_sim_info) raises:
        var twb: Float64 = weather.m_twet + 273.15  # [K] Wet-bulb temperature, convert from C
        var tdb: Float64 = weather.m_tdry + 273.15  # [K] Dry-bulb temperature, convert from C
        var T_hot: Float64 = htf_state_in.m_temp + 273.15  # [K] hot inlet temp
        var m_dot: Float64 = inputs.m_m_dot / 3600.0  # [kg/s] mass flow rate
        var q_to_pb: Float64 = m_dot * self.m_cp_htf_fixed * (T_hot - self.m_T_htf_cold_fixed) * 1.0e-3  # [MWt]
        var qnorm: Float64 = q_to_pb / self.m_q_des  # [-] The normalized thermal energy flow
        var tnorm: Float64 = Float64.NaN
        if self.ms_params.m_PC_T_corr == 1:  # [-] Select the dry or wet bulb temperature as the driving difference
            tnorm = twb - self.ms_params.m_T_pc_des
        else:
            tnorm = tdb - self.ms_params.m_T_pc_des
        var f_effpc_qtpb: Float64 = 0.0
        var f_effpc_tamb: Float64 = 0.0
        for i in range(self.ms_params.mv_etaQ_coefs.size):
            f_effpc_qtpb += self.ms_params.mv_etaQ_coefs[i] * pow(qnorm, i)
        for i in range(self.ms_params.mv_etaT_coefs.size):
            f_effpc_tamb += self.ms_params.mv_etaT_coefs[i] * pow(tnorm, i)
        var eta_cycle: Float64 = self.ms_params.m_eta_des * (f_effpc_qtpb + f_effpc_tamb)  # [-] Adjusted power conversion efficiency
        if q_to_pb <= 0.0:
            eta_cycle = 0.0  # [-] Set conversion efficiency to zero when the power block isn't operating
        var w_gr: Float64 = q_to_pb * eta_cycle  # [MWe]
        out_solver.m_time_required_su = 0.0           # [s]
        out_solver.m_P_cycle = w_gr                   # [MWe]
        out_solver.m_T_htf_cold = self.m_T_htf_cold_fixed  # [K]
        out_solver.m_q_dot_htf = q_to_pb              # [MWt]
        out_solver.m_m_dot_htf = m_dot * 3600.0       # [kg/hr]
        out_solver.m_W_dot_htf_pump = 0.0             # [MWe]
        out_solver.m_W_cool_par = 0.0                 # [MWe]
        self.mc_reported_outputs.value(self.E_ETA_THERMAL, eta_cycle)  # [-]

    def converged(self) raises:
        self.mc_reported_outputs.set_timestep_outputs()
        raise C_csp_exception("C_csp_gen_pc::converged() is not complete")

    def write_output_intervals(self, report_time_start: Float64,
        v_temp_ts_time_end: List[Float64], report_time_end: Float64):
        self.mc_reported_outputs.send_to_reporting_ts_array(report_time_start,
            v_temp_ts_time_end, report_time_end)

    def assign(self, index: Int, p_reporting_ts_array: Pointer[Float64], n_reporting_ts_array: Int):
        self.mc_reported_outputs.assign(index, p_reporting_ts_array, n_reporting_ts_array)