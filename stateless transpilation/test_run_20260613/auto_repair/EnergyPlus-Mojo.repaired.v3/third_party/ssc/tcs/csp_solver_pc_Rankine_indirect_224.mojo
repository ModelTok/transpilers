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
from lib_util import *
from htf_props import *
from ud_power_cycle import *
from csp_solver_two_tank_tes import *
from csp_radiator import *
from csp_solver_stratified_tes import *
from lib_physics import *
from water_properties import *
from sam_csp_util import *
from csp_solver_pc_Rankine_indirect_224 import *
from memory import memset_zero
from math import fabs, fmax, fmin, acos, tan, isfinite
from utils import format
from algorithm import sort
from set import Set
from unordered_set import UnorderedSet
from map import Map
from vector import Vector
from matrix import matrix_t

@value
struct S_output_info:
    var index: Int
    var aggregate_type: Int

alias csp_info_invalid = S_output_info(-1, -1)

var S_output_info: StaticTuple[17, S_output_info] = StaticTuple(
    S_output_info(C_pc_Rankine_indirect_224.E_ETA_THERMAL, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_Q_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_M_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_Q_DOT_STARTUP, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_W_DOT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_T_HTF_IN, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_T_HTF_OUT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_T_COND_OUT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_T_COLD, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_M_COLD, C_csp_reported_outputs.TS_LAST),
    S_output_info(C_pc_Rankine_indirect_224.E_M_WARM, C_csp_reported_outputs.TS_LAST),
    S_output_info(C_pc_Rankine_indirect_224.E_T_WARM, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_T_RADOUT, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_M_DOT_WATER, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_P_COND, C_csp_reported_outputs.TS_LAST),
    S_output_info(C_pc_Rankine_indirect_224.E_RADCOOL_CNTRL, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(C_pc_Rankine_indirect_224.E_M_DOT_HTF_REF, C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

@value
struct S_params:
    var m_P_ref: Float64
    var m_eta_ref: Float64
    var m_T_htf_hot_ref: Float64
    var m_T_htf_cold_ref: Float64
    var m_cycle_max_frac: Float64
    var m_cycle_cutoff_frac: Float64
    var m_q_sby_frac: Float64
    var m_startup_time: Float64
    var m_startup_frac: Float64
    var m_htf_pump_coef: Float64
    var m_pc_fl: Int
    var m_pc_fl_props: matrix_t[Float64]
    var DP_SGS: Float64
    var m_is_user_defined_pc: Bool
    var m_dT_cw_ref: Float64
    var m_T_amb_des: Float64
    var m_P_boil: Float64
    var m_CT: Int
    var m_tech_type: Int
    var m_T_approach: Float64
    var m_T_ITD_des: Float64
    var m_P_cond_ratio: Float64
    var m_pb_bd_frac: Float64
    var m_P_cond_min: Float64
    var m_n_pl_inc: Int
    var m_F_wc: StaticTuple[9, Float64]
    var mc_T_htf_ind: matrix_t[Float64]
    var m_T_htf_low: Float64
    var m_T_htf_high: Float64
    var mc_T_amb_ind: matrix_t[Float64]
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var mc_m_dot_htf_ind: matrix_t[Float64]
    var m_m_dot_htf_low: Float64
    var m_m_dot_htf_high: Float64
    var mc_combined_ind: matrix_t[Float64]
    var m_W_dot_cooling_des: Float64
    var m_m_dot_water_des: Float64

    def __init__(inout self):
        self.m_P_ref = Float64.NaN
        self.m_eta_ref = Float64.NaN
        self.m_T_htf_hot_ref = Float64.NaN
        self.m_T_htf_cold_ref = Float64.NaN
        self.m_dT_cw_ref = Float64.NaN
        self.m_T_amb_des = Float64.NaN
        self.m_q_sby_frac = Float64.NaN
        self.m_P_boil = Float64.NaN
        self.m_startup_time = Float64.NaN
        self.m_startup_frac = Float64.NaN
        self.m_T_approach = Float64.NaN
        self.m_T_ITD_des = Float64.NaN
        self.m_P_cond_ratio = Float64.NaN
        self.m_pb_bd_frac = Float64.NaN
        self.m_P_cond_min = Float64.NaN
        self.m_htf_pump_coef = Float64.NaN
        self.m_pc_fl = -1
        self.m_CT = -1
        self.m_tech_type = -1
        self.m_n_pl_inc = -1
        self.m_is_user_defined_pc = False
        self.m_T_htf_low = Float64.NaN
        self.m_T_htf_high = Float64.NaN
        self.m_T_amb_low = Float64.NaN
        self.m_T_amb_high = Float64.NaN
        self.m_m_dot_htf_low = Float64.NaN
        self.m_m_dot_htf_high = Float64.NaN
        self.m_W_dot_cooling_des = Float64.NaN
        self.m_m_dot_water_des = Float64.NaN
        self.DP_SGS = Float64.NaN
        self.m_cycle_max_frac = Float64.NaN
        self.m_cycle_cutoff_frac = Float64.NaN
        self.m_F_wc = StaticTuple[9, Float64](Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN)

class C_pc_Rankine_indirect_224(C_csp_power_cycle):
    var m_is_initialized: Bool
    var m_F_wcMax: Float64
    var m_F_wcMin: Float64
    var m_delta_h_steam: Float64
    var m_startup_energy_required: Float64
    var m_eta_adj: Float64
    var m_m_dot_design: Float64
    var m_m_dot_max: Float64
    var m_m_dot_min: Float64
    var m_q_dot_design: Float64
    var m_cp_htf_design: Float64
    var m_operating_mode_prev: C_csp_power_cycle.E_csp_power_cycle_modes
    var m_startup_time_remain_prev: Float64
    var m_startup_energy_remain_prev: Float64
    var m_operating_mode_calc: C_csp_power_cycle.E_csp_power_cycle_modes
    var m_startup_time_remain_calc: Float64
    var m_startup_energy_remain_calc: Float64
    var m_db: matrix_t[Float64]
    var mc_pc_htfProps: HTFProperties
    var m_error_msg: String
    var mc_user_defined_pc: C_ud_power_cycle
    var m_ncall: Int
    var mc_reported_outputs: C_csp_reported_outputs
    var mc_csp_messages: C_csp_messages
    var mc_two_tank_ctes: C_csp_cold_tes
    var mc_two_tank_ctes_outputs: C_csp_cold_tes.S_csp_cold_tes_outputs
    var mc_stratified_ctes: C_csp_stratified_tes
    var mc_stratified_ctes_outputs: C_csp_stratified_tes.S_csp_strat_tes_outputs
    var m_dot_cold_avail: Float64
    var m_dot_warm_avail: Float64
    var m_dot_condenser: Float64
    var T_warm_prev_K: Float64
    var T_cold_prev_K: Float64
    var T_cold_prev: Float64
    var dT_cw_design: Float64
    var T_s_measured: Float64
    var T_s_corr: Float64
    var T_s_K: Float64
    var idx_time: Int
    var mc_radiator: C_csp_radiator
    var m_dot_radfield: Float64
    var m_dot_radact: Float64
    var W_radpumptest: Float64
    var ms_params: S_params

    def __init__(inout self):
        self.m_is_initialized = False
        self.m_operating_mode_prev = C_csp_power_cycle.E_csp_power_cycle_modes.OFF
        self.m_operating_mode_calc = self.m_operating_mode_prev
        self.m_F_wcMax = Float64.NaN
        self.m_F_wcMin = Float64.NaN
        self.m_delta_h_steam = Float64.NaN
        self.m_startup_energy_required = Float64.NaN
        self.m_eta_adj = Float64.NaN
        self.m_m_dot_design = Float64.NaN
        self.m_q_dot_design = Float64.NaN
        self.m_cp_htf_design = Float64.NaN
        self.m_startup_time_remain_prev = Float64.NaN
        self.m_startup_time_remain_calc = Float64.NaN
        self.m_startup_energy_remain_prev = Float64.NaN
        self.m_startup_energy_remain_calc = Float64.NaN
        self.m_ncall = -1
        self.mc_reported_outputs = C_csp_reported_outputs()
        self.mc_reported_outputs.construct(S_output_info)

    def GetFieldToTurbineTemperatureDropC(inout self) -> Float64:
        return 25.0

    def T_sat4(inout self, P: Float64) -> Float64:
        return 284.482349 + 20.8848464*P - 1.5898147*P*P + 0.0655241456*P*P*P - 0.0010168822*P*P*P*P

    def init(inout self, inout solved_params: C_csp_power_cycle.S_solved_params):
        if self.ms_params.m_pc_fl != HTFProperties.User_defined and self.ms_params.m_pc_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_pc_htfProps.SetFluid(self.ms_params.m_pc_fl):
                raise C_csp_exception("Power cycle HTF code is not recognized", "Rankine Indirect Power Cycle Initialization")
        elif self.ms_params.m_pc_fl == HTFProperties.User_defined:
            var n_rows = self.ms_params.m_pc_fl_props.nrows()
            var n_cols = self.ms_params.m_pc_fl_props.ncols()
            if n_rows > 2 and n_cols == 7:
                if not self.mc_pc_htfProps.SetUserDefinedFluid(self.ms_params.m_pc_fl_props):
                    self.m_error_msg = format(self.mc_pc_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(self.m_error_msg, "Rankine Indirect Power Cycle Initialization")
            else:
                self.m_error_msg = format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(self.m_error_msg, "Rankine Indirect Power Cycle Initialization")
        else:
            raise C_csp_exception("Power cycle HTF code is not recognized", "Rankine Indirect Power Cycle Initialization")

        if not self.ms_params.m_is_user_defined_pc:
            if self.ms_params.m_tech_type == 1:
                var dTemp: StaticTuple[24, StaticTuple[20, Float64]] = StaticTuple(
                    StaticTuple(0.15683, 0.20675, 0.25668, 0.30660, 0.35653, 0.40645, 0.45638, 0.50630, 0.55623, 0.60615, 0.65608, 0.70600, 0.75592, 0.80585, 0.85577, 0.90570, 0.95562, 1.00555, 1.05547, 1.10540),
                    StaticTuple(0.04266, 0.08917, 0.14127, 0.19573, 0.25160, 0.30845, 0.36607, 0.42382, 0.48152, 0.53909, 0.59669, 0.65449, 0.71253, 0.77088, 0.82958, 0.88868, 0.94807, 1.00475, 1.05176, 1.09731),
                    StaticTuple(0.12601, 0.18850, 0.24872, 0.30666, 0.36257, 0.41681, 0.47081, 0.52373, 0.57556, 0.62640, 0.67632, 0.72542, 0.77373, 0.82130, 0.86816, 0.91436, 0.95980, 1.00463, 1.04885, 1.09251),
                    StaticTuple(3000.00000, 4263.16000, 5526.32000, 6789.47000, 8052.63000, 9315.79000, 10578.95000, 11842.11000, 13105.26000, 14368.42000, 15631.58000, 16894.74000, 18157.89000, 19421.05000, 20684.21000, 21947.37000, 23210.53000, 24473.68000, 25736.84000, 27000.00000),
                    StaticTuple(1.00835, 1.00826, 1.00691, 1.00523, 1.00139, 0.99525, 0.98757, 0.97900, 0.96997, 0.96074, 0.95151, 0.94239, 0.93343, 0.92469, 0.91621, 0.90797, 0.89999, 0.89227, 0.88481, 0.87760),
                    StaticTuple(0.99946, 0.99947, 0.99954, 0.99960, 0.99966, 0.99970, 0.99974, 0.99977, 0.99980, 0.99982, 0.99985, 0.99987, 0.99989, 0.99991, 0.99992, 0.99994, 0.99996, 0.99997, 0.99999, 1.00000),
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(0.04780, 0.10739, 0.17298, 0.24212, 0.31328, 0.38563, 0.45878, 0.53250, 0.60677, 0.68160, 0.75710, 0.83340, 0.91069, 0.98909, 1.04906, 1.10353, 1.15273, 1.19563, 1.23086, 1.25617),
                    StaticTuple(0.10714, 0.17950, 0.25053, 0.32067, 0.39005, 0.45876, 0.52687, 0.59444, 0.66151, 0.72809, 0.79421, 0.85987, 0.92505, 0.98976, 1.05397, 1.11762, 1.18067, 1.24303, 1.30457, 1.36510),
                    StaticTuple(0.15683, 0.20675, 0.25668, 0.30660, 0.35653, 0.40645, 0.45638, 0.50630, 0.55623, 0.60615, 0.65608, 0.70600, 0.75592, 0.80585, 0.85577, 0.90570, 0.95562, 1.00555, 1.05547, 1.10540),
                    StaticTuple(1.26158, 1.12986, 1.08433, 1.06137, 1.04723, 1.03742, 1.03026, 1.02473, 1.02028, 1.01655, 1.01340, 1.01068, 1.00830, 1.00621, 1.00437, 1.00272, 1.00124, 0.99976, 0.99793, 0.99589),
                    StaticTuple(2.55300, 2.31235, 2.14933, 2.05259, 1.98444, 1.93397, 1.89580, 1.86685, 1.84682, 1.83756, 1.83575, 1.80301, 1.68476, 1.55946, 1.42659, 1.28547, 1.13596, 0.99081, 0.87407, 0.73510),
                    StaticTuple(0.98576, 0.99189, 0.99511, 0.99706, 0.99829, 0.99913, 0.99966, 0.99999, 1.00020, 1.00034, 1.00041, 1.00044, 1.00043, 1.00038, 1.00031, 1.00022, 1.00009, 0.99994, 0.99979, 0.99962),
                    StaticTuple(0.88057, 0.93549, 0.96537, 0.98353, 0.99511, 1.00348, 1.01034, 1.01445, 1.01733, 1.01920, 1.02014, 1.02014, 1.01923, 1.01738, 1.01458, 1.01080, 1.00638, 1.00048, 0.99316, 0.98416),
                    StaticTuple(3000.00000, 4263.16000, 5526.32000, 6789.47000, 8052.63000, 9315.79000, 10578.95000, 11842.11000, 13105.26000, 14368.42000, 15631.58000, 16894.74000, 18157.89000, 19421.05000, 20684.21000, 21947.37000, 23210.53000, 24473.68000, 25736.84000, 27000.00000),
                    StaticTuple(0.98102, 0.98793, 0.99268, 0.99631, 0.99913, 1.00134, 1.00312, 1.00457, 1.00578, 1.00679, 1.00765, 1.00838, 1.00900, 1.00953, 1.00998, 1.01036, 1.01068, 1.01095, 1.01118, 1.01134),
                    StaticTuple(0.97252, 0.97302, 0.98006, 0.98212, 0.99921, 1.01928, 1.03796, 1.05433, 1.06870, 1.08126, 1.09229, 1.10196, 1.11063, 1.11836, 1.12511, 1.13130, 1.13670, 1.14167, 1.14622, 1.15021),
                    StaticTuple(0.99991, 0.99990, 0.99991, 0.99993, 0.99995, 0.99996, 0.99999, 1.00001, 1.00003, 1.00005, 1.00008, 1.00011, 1.00014, 1.00017, 1.00020, 1.00024, 1.00027, 1.00031, 1.00035, 1.00039),
                    StaticTuple(1.00422, 1.00421, 1.00381, 1.00385, 1.00387, 1.00387, 1.00387, 1.00387, 1.00392, 1.00389, 1.00390, 1.00392, 1.00394, 1.00396, 1.00398, 1.00400, 1.00402, 1.00400, 1.00403, 1.00405),
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(33.05739, 28.88561, 23.67992, 18.96582, 15.01199, 11.70265, 8.97349, 6.82745, 5.22325, 3.92348, 2.93983, 2.16219, 1.56883, 1.12414, 0.81450, 0.59754, 0.45007, 0.35443, 0.29039, 0.23646),
                    StaticTuple(1.33768, 1.71967, 1.75934, 1.74324, 1.70119, 1.64170, 1.57186, 1.49295, 1.40960, 1.32715, 1.24574, 1.16514, 1.08539, 1.00646, 0.94622, 0.88868, 0.83307, 0.77974, 0.72982, 0.68480),
                    StaticTuple(1.94947, 0.31734, -0.12631, 0.00000, 0.12981, 0.22074, 0.31233, 0.38330, 0.44968, 0.50418, 0.46220, 0.44163, 0.41735, 0.40286, 0.37832, 0.35111, 0.32164, 0.29023, 0.25713, 0.21791),
                    StaticTuple(550.69442, 27.85542, -15.96620, -9.35541, 2.56379, 4.35962, -3.79598, -23.55145, -39.30410, -53.56460, -64.21451, -75.59318, -84.31931, -92.95156, -100.57254, -108.26592, -116.88312, -123.89107, -131.07728, -138.45108)
                )
                self.m_db = matrix_t[Float64](dTemp[0].data, 24, 20)
            elif self.ms_params.m_tech_type == 2:
                var dTemp: StaticTuple[24, StaticTuple[20, Float64]] = StaticTuple(
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(0.08547, 0.14823, 0.21378, 0.28166, 0.35143, 0.42264, 0.49482, 0.56747, 0.64012, 0.71236, 0.78378, 0.85406, 0.92284, 0.98989, 1.05685, 1.12369, 1.19018, 1.25624, 1.32197, 1.38744),
                    StaticTuple(0.10051, 0.16934, 0.23822, 0.30718, 0.37623, 0.44534, 0.51443, 0.58338, 0.65209, 0.72048, 0.78848, 0.85606, 0.92317, 0.98983, 1.05604, 1.12182, 1.18718, 1.25200, 1.31641, 1.38047),
                    StaticTuple(3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00),
                    StaticTuple(1.08827, 1.06020, 1.03882, 1.02145, 1.00692, 0.99416, 0.98288, 0.97273, 0.96350, 0.95504, 0.94721, 0.93996, 0.93314, 0.92673, 0.92069, 0.91496, 0.90952, 0.90433, 0.89938, 0.89464),
                    StaticTuple(1.01276, 1.00877, 1.00570, 1.00318, 1.00106, 0.99918, 0.99751, 0.99601, 0.99463, 0.99335, 0.99218, 0.99107, 0.99004, 0.98907, 0.98814, 0.98727, 0.98643, 0.98563, 0.98487, 0.98413),
                    StaticTuple(0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000),
                    StaticTuple(0.09307, 0.16421, 0.23730, 0.31194, 0.38772, 0.46420, 0.54098, 0.61763, 0.69374, 0.76896, 0.84287, 0.91511, 0.98530, 1.05512, 1.12494, 1.19447, 1.26373, 1.33273, 1.40148, 1.46999),
                    StaticTuple(0.10741, 0.18443, 0.26031, 0.33528, 0.40950, 0.48308, 0.55610, 0.62861, 0.70066, 0.77229, 0.84354, 0.91443, 0.98497, 1.05520, 1.12514, 1.19478, 1.26416, 1.33329, 1.40217, 1.47081),
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(1.01749, 1.03327, 1.04339, 1.04900, 1.05051, 1.04825, 1.04249, 1.03343, 1.02126, 1.01162, 1.00500, 1.00084, 0.99912, 0.99966, 0.99972, 0.99942, 0.99920, 0.99911, 0.99885, 0.99861),
                    StaticTuple(1.01749, 1.03327, 1.04339, 1.04900, 1.05051, 1.04825, 1.04249, 1.03343, 1.02126, 1.01162, 1.00500, 1.00084, 0.99912, 0.99966, 0.99972, 0.99942, 0.99920, 0.99911, 0.99885, 0.99861),
                    StaticTuple(0.99137, 0.99297, 0.99431, 0.99564, 0.99681, 0.99778, 0.99855, 0.99910, 0.99948, 0.99971, 0.99984, 0.99989, 0.99993, 0.99993, 0.99992, 0.99992, 0.99992, 1.00009, 1.00010, 1.00012),
                    StaticTuple(0.99137, 0.99297, 0.99431, 0.99564, 0.99681, 0.99778, 0.99855, 0.99910, 0.99948, 0.99971, 0.99984, 0.99989, 0.99993, 0.99993, 0.99992, 0.99992, 0.99992, 1.00009, 1.00010, 1.00012),
                    StaticTuple(3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00),
                    StaticTuple(0.99653, 0.99756, 0.99839, 0.99906, 0.99965, 1.00017, 1.00063, 1.00106, 1.00146, 1.00183, 1.00218, 1.00246, 1.00277, 1.00306, 1.00334, 1.00361, 1.00387, 1.00411, 1.00435, 1.00458),
                    StaticTuple(0.99653, 0.99756, 0.99839, 0.99906, 0.99965, 1.00017, 1.00063, 1.00106, 1.00146, 1.00183, 1.00218, 1.00246, 1.00277, 1.00306, 1.00334, 1.00361, 1.00387, 1.00411, 1.00435, 1.00458),
                    StaticTuple(0.99760, 0.99831, 0.99888, 0.99934, 0.99973, 1.00008, 1.00039, 1.00067, 1.00093, 1.00118, 1.00140, 1.00161, 1.00180, 1.00199, 1.00217, 1.00234, 1.00250, 1.00265, 1.00280, 1.00294),
                    StaticTuple(0.99760, 0.99831, 0.99888, 0.99934, 0.99973, 1.00008, 1.00039, 1.00067, 1.00093, 1.00118, 1.00140, 1.00161, 1.00180, 1.00199, 1.00217, 1.00234, 1.00250, 1.00265, 1.00280, 1.00294),
                    StaticTuple(0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000),
                    StaticTuple(1.01994, 1.01645, 1.01350, 1.01073, 1.00801, 1.00553, 1.00354, 1.00192, 1.00077, 0.99995, 0.99956, 0.99957, 1.00000, 0.99964, 0.99955, 0.99945, 0.99937, 0.99928, 0.99919, 0.99918),
                    StaticTuple(1.01994, 1.01645, 1.01350, 1.01073, 1.00801, 1.00553, 1.00354, 1.00192, 1.00077, 0.99995, 0.99956, 0.99957, 1.00000, 0.99964, 0.99955, 0.99945, 0.99937, 0.99928, 0.99919, 0.99918),
                    StaticTuple(1.02055, 1.01864, 1.01869, 1.01783, 1.01508, 1.01265, 1.01031, 1.00832, 1.00637, 1.00454, 1.00301, 1.00141, 1.00008, 0.99851, 0.99715, 0.99586, 0.99464, 0.99347, 0.99227, 0.99177),
                    StaticTuple(1.02055, 1.01864, 1.01869, 1.01783, 1.01508, 1.01265, 1.01031, 1.00832, 1.00637, 1.00454, 1.00301, 1.00141, 1.00008, 0.99851, 0.99715, 0.99586, 0.99464, 0.99347, 0.99227, 0.99177)
                )
                self.m_db = matrix_t[Float64](dTemp[0].data, 24, 20)
            elif self.ms_params.m_tech_type == 3:
                var dTemp: StaticTuple[24, StaticTuple[20, Float64]] = StaticTuple(
                    StaticTuple(0.15683, 0.20675, 0.25668, 0.30660, 0.35653, 0.40645, 0.45638, 0.50630, 0.55623, 0.60615, 0.65608, 0.70600, 0.75592, 0.80585, 0.85577, 0.90570, 0.95562, 1.00555, 1.05547, 1.10540),
                    StaticTuple(0.18620, 0.24229, 0.29945, 0.35588, 0.40894, 0.46133, 0.51284, 0.55991, 0.60243, 0.64564, 0.68946, 0.73378, 0.77849, 0.82350, 0.86873, 0.91405, 0.95937, 1.00440, 1.04916, 1.09355),
                    StaticTuple(0.27992, 0.33436, 0.38736, 0.43904, 0.48953, 0.53895, 0.58739, 0.63023, 0.66654, 0.70321, 0.74020, 0.77747, 0.81499, 0.85273, 0.89065, 0.92874, 0.96696, 1.00510, 1.04326, 1.08145),
                    StaticTuple(3000.00000, 4263.16000, 5526.32000, 6789.47000, 8052.63000, 9315.79000, 10578.95000, 11842.11000, 13105.26000, 14368.42000, 15631.58000, 16894.74000, 18157.89000, 19421.05000, 20684.21000, 21947.37000, 23210.53000, 24473.68000, 25736.84000, 27000.00000),
                    StaticTuple(1.00824, 1.00816, 1.00682, 1.00515, 1.00134, 0.99524, 0.98759, 0.97902, 0.97000, 0.96079, 0.95155, 0.94242, 0.93346, 0.92473, 0.91622, 0.90798, 0.89998, 0.89226, 0.88479, 0.87756),
                    StaticTuple(1.00063, 1.00064, 1.00071, 1.00078, 1.00084, 1.00089, 1.00093, 1.00096, 1.00099, 1.00102, 1.00105, 1.00107, 1.00109, 1.00111, 1.00113, 1.00115, 1.00117, 1.00118, 1.00120, 1.00121),
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(0.06187, 0.13197, 0.20881, 0.28999, 0.37164, 0.44963, 0.52668, 0.60126, 0.67205, 0.74077, 0.80721, 0.87120, 0.93249, 0.99073, 1.04570, 1.09705, 1.14433, 1.18696, 1.22412, 1.25469),
                    StaticTuple(0.11720, 0.19502, 0.27142, 0.34672, 0.42106, 0.49456, 0.56729, 0.63683, 0.69970, 0.76102, 0.82088, 0.87938, 0.93656, 0.99238, 1.04695, 1.10026, 1.15234, 1.20316, 1.25269, 1.30086),
                    StaticTuple(0.15683, 0.20675, 0.25668, 0.30660, 0.35653, 0.40645, 0.45638, 0.50630, 0.55623, 0.60615, 0.65608, 0.70600, 0.75592, 0.80585, 0.85577, 0.90570, 0.95562, 1.00555, 1.05547, 1.10540),
                    StaticTuple(1.06040, 1.04966, 1.04245, 1.03701, 1.03247, 1.02862, 1.02527, 1.02200, 1.01873, 1.01582, 1.01320, 1.01084, 1.00871, 1.00676, 1.00497, 1.00331, 1.00168, 0.99974, 0.99793, 0.99620),
                    StaticTuple(2.02675, 1.96267, 1.81956, 1.71618, 1.53498, 1.36981, 1.25569, 1.20896, 1.21197, 1.21111, 1.20605, 1.19650, 1.18192, 1.16160, 1.13326, 1.09716, 1.05192, 0.99607, 0.92531, 0.83516),
                    StaticTuple(1.00188, 1.00417, 1.00556, 1.00655, 1.00726, 1.00778, 1.00815, 1.00750, 1.00580, 1.00444, 1.00334, 1.00246, 1.00177, 1.00123, 1.00081, 1.00050, 1.00027, 1.00010, 0.99997, 0.99989),
                    StaticTuple(1.15786, 1.17742, 1.19103, 1.20073, 1.09299, 0.98065, 0.89888, 0.87045, 0.88981, 0.90779, 0.92449, 0.93989, 0.95402, 0.96680, 0.97664, 0.98480, 0.99137, 0.99680, 1.00020, 1.00091),
                    StaticTuple(3000.00000, 4263.16000, 5526.32000, 6789.47000, 8052.63000, 9315.79000, 10578.95000, 11842.11000, 13105.26000, 14368.42000, 15631.58000, 16894.74000, 18157.89000, 19421.05000, 20684.21000, 21947.37000, 23210.53000, 24473.68000, 25736.84000, 27000.00000),
                    StaticTuple(0.95785, 0.96912, 0.97988, 0.98947, 0.99743, 1.00386, 1.00915, 1.01352, 1.01722, 1.02039, 1.02313, 1.02551, 1.02762, 1.02948, 1.03113, 1.03261, 1.03394, 1.03513, 1.03620, 1.03718),
                    StaticTuple(0.97711, 0.97754, 0.98323, 0.98574, 1.00078, 1.01827, 1.03484, 1.04994, 1.06326, 1.07520, 1.08601, 1.09569, 1.10459, 1.11254, 1.11988, 1.12665, 1.13292, 1.13867, 1.14390, 1.14888),
                    StaticTuple(1.00033, 1.00030, 1.00030, 1.00031, 1.00033, 1.00034, 1.00036, 1.00037, 1.00039, 1.00041, 1.00043, 1.00045, 1.00047, 1.00049, 1.00051, 1.00053, 1.00056, 1.00058, 1.00061, 1.00064),
                    StaticTuple(0.98904, 0.98899, 0.98863, 0.98859, 0.98858, 0.98862, 0.98858, 0.98859, 0.98864, 0.98861, 0.98858, 0.98856, 0.98858, 0.98860, 0.98863, 0.98861, 0.98859, 0.98862, 0.98865, 0.98863),
                    StaticTuple(0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000),
                    StaticTuple(30.80307, 26.11517, 20.95267, 16.36681, 12.62005, 9.60562, 7.19104, 5.45324, 4.22218, 3.24286, 2.49008, 1.90885, 1.46070, 1.11769, 0.85750, 0.66468, 0.52327, 0.42251, 0.35069, 0.29738),
                    StaticTuple(1.31905, 1.62397, 1.65281, 1.63236, 1.58996, 1.54416, 1.48563, 1.41169, 1.33301, 1.25919, 1.18974, 1.12437, 1.06256, 1.00439, 0.94939, 0.89738, 0.84839, 0.80240, 0.75951, 0.72018),
                    StaticTuple(-1.50026, 0.00000, 0.10122, -0.06339, -0.16964, -0.25553, -0.33899, -0.42277, -0.47901, -0.43320, -0.42838, -0.41238, -0.39307, -0.37096, -0.35687, -0.33459, -0.31470, -0.29227, -0.27194, -0.27454),
                    StaticTuple(-1.11191, -0.08716, 0.05219, 0.00817, -0.01346, 0.00573, 0.05493, 0.12455, 0.16195, 0.19729, 0.22432, 0.24805, 0.26920, 0.28832, 0.30576, 0.32184, 0.33925, 0.35553, 0.37087, 0.37238)
                )
                self.m_db = matrix_t[Float64](dTemp[0].data, 24, 20)
            elif self.ms_params.m_tech_type == 4:
                var dTemp: StaticTuple[24, StaticTuple[20, Float64]] = StaticTuple(
                    StaticTuple(0.50000, 0.53158, 0.56316, 0.59474, 0.62632, 0.65789, 0.68947, 0.72105, 0.75263, 0.78421, 0.81579, 0.84737, 0.87895, 0.91053, 0.94211, 0.97368, 1.00526, 1.03684, 1.06842, 1.10000),
                    StaticTuple(0.55720, 0.58320, 0.60960, 0.63630, 0.66330, 0.69070, 0.71840, 0.74630, 0.77440, 0.80270, 0.83130, 0.85990, 0.88870, 0.91760, 0.94670, 0.97570, 1.00500, 1.03400, 1.06300, 1.09200),
                    StaticTuple(0.67620, 0.69590, 0.71570, 0.73570, 0.75580, 0.77600, 0.79630, 0.81670, 0.83720, 0.85780, 0.87840, 0.89910, 0.91990, 0.94070, 0.96150, 0.98230, 1.00300, 1.02400, 1.04500, 1.06600),
                    StaticTuple(35000.00, 46315.79, 57631.58, 68947.37, 80263.16, 91578.95, 102894.74, 114210.53, 125526.32, 136842.11, 148157.89, 159473.68, 170789.47, 182105.26, 193421.05, 204736.84, 216052.63, 227368.42, 238684.21, 250000.00),
                    StaticTuple(1.94000, 1.77900, 1.65200, 1.54600, 1.45600, 1.37800, 1.30800, 1.24600, 1.18900, 1.13700, 1.08800, 1.04400, 1.00200, 0.96290, 0.92620, 0.89150, 0.85860, 0.82740, 0.79770, 0.76940),
                    StaticTuple(1.22400, 1.19100, 1.16400, 1.14000, 1.11900, 1.10000, 1.08300, 1.06700, 1.05200, 1.03800, 1.02500, 1.01200, 1.00000, 0.98880, 0.97780, 0.96720, 0.95710, 0.94720, 0.93770, 0.92850),
                    StaticTuple(0.80000, 0.81316, 0.82632, 0.83947, 0.85263, 0.86579, 0.87895, 0.89211, 0.90526, 0.91842, 0.93158, 0.94474, 0.95789, 0.97105, 0.98421, 0.99737, 1.01053, 1.02368, 1.03684, 1.05000),
                    StaticTuple(0.84760, 0.85880, 0.86970, 0.88050, 0.89120, 0.90160, 0.91200, 0.92210, 0.93220, 0.94200, 0.95180, 0.96130, 0.97080, 0.98010, 0.98920, 0.99820, 1.00700, 1.01600, 1.02400, 1.03300),
                    StaticTuple(0.89590, 0.90350, 0.91100, 0.91840, 0.92570, 0.93290, 0.93990, 0.94680, 0.95370, 0.96040, 0.96700, 0.97350, 0.97990, 0.98620, 0.99240, 0.99850, 1.00400, 1.01000, 1.01500, 1.02100),
                    StaticTuple(0.50000, 0.53158, 0.56316, 0.59474, 0.62632, 0.65789, 0.68947, 0.72105, 0.75263, 0.78421, 0.81579, 0.84737, 0.87895, 0.91053, 0.94211, 0.97368, 1.00526, 1.03684, 1.06842, 1.10000),
                    StaticTuple(0.79042, 0.80556, 0.82439, 0.84177, 0.85786, 0.87485, 0.88898, 0.90182, 0.91783, 0.93019, 0.93955, 0.95105, 0.96233, 0.97150, 0.98059, 0.98237, 0.99829, 1.00271, 1.02084, 1.02413),
                    StaticTuple(0.79042, 0.80556, 0.82439, 0.84177, 0.85786, 0.87485, 0.88898, 0.90182, 0.91783, 0.93019, 0.93955, 0.95105, 0.96233, 0.97150, 0.98059, 0.98237, 0.99829, 1.00271, 1.02084, 1.02413),
                    StaticTuple(0.67400, 0.69477, 0.71830, 0.73778, 0.75991, 0.78079, 0.80052, 0.82622, 0.88152, 0.92737, 0.93608, 0.94800, 0.95774, 0.96653, 0.97792, 0.99852, 0.99701, 1.01295, 1.02825, 1.04294),
                    StaticTuple(0.67400, 0.69477, 0.71830, 0.73778, 0.75991, 0.78079, 0.80052, 0.82622, 0.88152, 0.92737, 0.93608, 0.94800, 0.95774, 0.96653, 0.97792, 0.99852, 0.99701, 1.01295, 1.02825, 1.04294),
                    StaticTuple(35000.00, 46315.79, 57631.58, 68947.37, 80263.16, 91578.95, 102894.74, 114210.53, 125526.32, 136842.11, 148157.89, 159473.68, 170789.47, 182105.26, 193421.05, 204736.84, 216052.63, 227368.42, 238684.21, 250000.00),
                    StaticTuple(0.80313, 0.82344, 0.83980, 0.86140, 0.87652, 0.89274, 0.91079, 0.92325, 0.93832, 0.95229, 0.97004, 0.98211, 1.00399, 1.01514, 1.03494, 1.04962, 1.06646, 1.08374, 1.10088, 1.11789),
                    StaticTuple(0.80313, 0.82344, 0.83980, 0.86140, 0.87652, 0.89274, 0.91079, 0.92325, 0.93832, 0.95229, 0.97004, 0.98211, 1.00399, 1.01514, 1.03494, 1.04962, 1.06646, 1.08374, 1.10088, 1.11789),
                    StaticTuple(0.93426, 0.94458, 0.94618, 0.95878, 0.96352, 0.96738, 0.97058, 0.98007, 0.98185, 0.99048, 0.99144, 0.99914, 1.00696, 1.00849, 1.01573, 1.01973, 1.01982, 1.02577, 1.02850, 1.03585),
                    StaticTuple(0.93426, 0.94458, 0.94618, 0.95878, 0.96352, 0.96738, 0.97058, 0.98007, 0.98185, 0.99048, 0.99144, 0.99914, 1.00696, 1.00849, 1.01573, 1.01973, 1.01982, 1.02577, 1.02850, 1.03585),
                    StaticTuple(0.80000, 0.81316, 0.82632, 0.83947, 0.85263, 0.86579, 0.87895, 0.89211, 0.90526, 0.91842, 0.93158, 0.94474, 0.95789, 0.97105, 0.98421, 0.99737, 1.01053, 1.02368, 1.03684, 1.05000),
                    StaticTuple(1.06790, 1.06247, 1.05688, 1.05185, 1.04687, 1.04230, 1.03748, 1.03281, 1.02871, 1.02473, 1.02050, 1.01639, 1.01204, 1.00863, 1.00461, 1.00051, 0.99710, 0.99352, 0.98974, 0.98692),
                    StaticTuple(1.06790, 1.06247, 1.05688, 1.05185, 1.04687, 1.04230, 1.03748, 1.03281, 1.02871, 1.02473, 1.02050, 1.01639, 1.01204, 1.00863, 1.00461, 1.00051, 0.99710, 0.99352, 0.98974, 0.98692),
                    StaticTuple(1.02335, 1.02130, 1.02041, 1.01912, 1.01655, 1.01601, 1.01379, 1.01431, 1.01321, 1.01207, 1.01129, 1.00784, 1.00548, 1.00348, 1.00183, 0.99982, 0.99698, 0.99457, 0.99124, 0.99016),
                    StaticTuple(1.02335, 1.02130, 1.02041, 1.01912, 1.01655, 1.01601, 1.01379, 1.01431, 1.01321, 1.01207, 1.01129, 1.00784, 1.00548, 1.00348, 1.00183, 0.99982, 0.99698, 0.99457, 0.99124, 0.99016)
                )
                self.m_db = matrix_t[Float64](dTemp[0].data, 24, 20)
            elif self.ms_params.m_tech_type == 5:
                var dTemp: StaticTuple[24, StaticTuple[12, Float64]] = StaticTuple(
                    StaticTuple(0.934693878,1,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061,1.032653061),
                    StaticTuple(0.937081782,0.999998651,1.031700474,1.031700474,1.031700474,1.031700474,1.031700474