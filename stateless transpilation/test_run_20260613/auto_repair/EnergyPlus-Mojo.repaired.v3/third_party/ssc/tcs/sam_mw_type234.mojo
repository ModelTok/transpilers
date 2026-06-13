# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from tcstype import tcsvarinfo, tcscontext, tcstypeinterface, value
from water_properties import water_state, water_TQ, water_TP, water_PQ, water_PS, water_PH
from sam_csp_util import CSP
from math import min, max, fabs, pow
from memory import memcpy

# utility matrix class to mimic util::matrix_t<double>
struct Matrix:
    var data: List[List[Float64]]
    var nrows: Int
    var ncols: Int

    def __init__(inout self):
        self.data = List[List[Float64]]()
        self.nrows = 0
        self.ncols = 0

    def assign(inout self, ptr: Pointer[Float64], rows: Int, cols: Int):
        self.nrows = rows
        self.ncols = cols
        self.data = List[List[Float64]](capacity=rows)
        for i in range(rows):
            var row = List[Float64](capacity=cols)
            for j in range(cols):
                row.append(ptr[i * cols + j])
            self.data.append(row)

    def at(self, row: Int, col: Int) -> Float64:
        return self.data[row][col]

    def ncols(self) -> Int:
        return self.ncols

# helper to mimic C++ arrays
struct P_max_check:
    var m_P_max: Float64 = 0.0
    def set_P_max(inout self, pmax: Float64):
        self.m_P_max = pmax
    def P_check(self, P: Float64) -> Float64:
        if P > self.m_P_max:
            return self.m_P_max
        else:
            return P

# enum values (same names and order)
@value
enum VarIndex:
    P_P_REF = 0
    P_ETA_REF = 1
    P_T_HOT_REF = 2
    P_T_COLD_REF = 3
    P_DT_CW_REF = 4
    P_T_AMB_DES = 5
    P_Q_SBY_FRAC = 6
    P_P_BOIL_DES = 7
    P_IS_RH = 8
    P_P_RH_REF = 9
    P_T_RH_HOT_REF = 10
    P_RH_FRAC_REF = 11
    P_CT = 12
    P_STARTUP_TIME = 13
    P_STARTUP_FRAC = 14
    P_TECH_TYPE = 15
    P_T_APPROACH = 16
    P_T_ITD_DES = 17
    P_P_COND_RATIO = 18
    P_PB_BD_FRAC = 19
    P_P_COND_MIN = 20
    P_N_PL_INC = 21
    P_F_WC = 22
    I_MODE = 23
    I_T_HOT = 24
    I_M_DOT_ST = 25
    I_T_WB = 26
    I_DEMAND_VAR = 27
    I_STANDBY_CONTROL = 28
    I_T_DB = 29
    I_P_AMB = 30
    I_TOU = 31
    I_RH = 32
    I_F_RECSU = 33
    I_DP_B = 34
    I_DP_SH = 35
    I_DP_RH = 36
    O_P_CYCLE = 37
    O_ETA = 38
    O_T_COLD = 39
    O_M_DOT_MAKEUP = 40
    O_M_DOT_DEMAND = 41
    O_M_DOT_OUT = 42
    O_M_DOT_REF = 43
    O_W_COOL_PAR = 44
    O_P_REF_OUT = 45
    O_F_BAYS = 46
    O_P_COND = 47
    O_P_BOILER_IN = 48
    O_F_RH = 49
    O_P_RH_IN = 50
    O_T_RH_IN = 51
    O_T_RH_OUT = 52
    N_MAX = 53

# variable table (exact copy of the C array)
var sam_mw_type234_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_REF, "P_ref", "Reference output electric power at design condition", "MW", "", "", "111"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_ETA_REF, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "", "0.3774"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_HOT_REF, "T_hot_ref", "Reference HTF inlet temperature at design", "C", "", "", "391"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_COLD_REF, "T_cold_ref", "Reference HTF outlet temperature at design", "C", "", "", "293"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_DT_CW_REF, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "", "10"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_AMB_DES, "T_amb_des", "Reference ambient temperature at design point", "C", "", "", "20"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_Q_SBY_FRAC, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "", "0.2"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_BOIL_DES, "P_boil_des", "Boiler operating pressure @ design", "bar", "", "", "100"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_IS_RH, "is_rh", "Flag indicating whether reheat is used 0:no, 1:yes", "none", "", "", "1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_RH_REF, "P_rh_ref", "Reheater operating pressure at design", "bar", "", "", "40"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_RH_HOT_REF, "T_rh_hot_ref", "Reheater design outlet temperature", "C", "", "", "500"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_RH_FRAC_REF, "rh_frac_ref", "Reheater flow fraction at design", "none", "", "", "0.9"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_CT, "CT", "Flag for using dry cooling or wet cooling system", "none", "", "", "1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_STARTUP_TIME, "startup_time", "Time needed for power block startup", "hr", "", "", "0.5"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_STARTUP_FRAC, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "", "0.2"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_TECH_TYPE, "tech_type", "Flag indicating which coef. set to use. (1=tower,2=trough,3=user)", "none", "", "", "2"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_APPROACH, "T_approach", "Cooling tower approach temperature", "C", "", "", "5"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_ITD_DES, "T_ITD_des", "ITD at design for dry system", "C", "", "", "16"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_COND_RATIO, "P_cond_ratio", "Condenser pressure ratio", "none", "", "", "1.0028"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_PB_BD_FRAC, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "", "0.02"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_COND_MIN, "P_cond_min", "Minimum condenser pressure", "inHg", "", "", "1.25"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_N_PL_INC, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "", "2"),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_F_WC, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "9 indices for each TOU Period", "", "0,0,0,0,0,0,0,0,0"),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_MODE, "mode", "Cycle part load control, from plant controller", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_HOT, "T_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_M_DOT_ST, "m_dot_st", "HTF mass flow rate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_WB, "T_wb", "Ambient wet bulb temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_DEMAND_VAR, "demand_var", "Control signal indicating operational mode", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_STANDBY_CONTROL, "standby_control", "Control signal indicating standby mode", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_DB, "T_db", "Ambient dry bulb temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_P_AMB, "P_amb", "Ambient pressure", "atm", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_TOU, "TOU", "Current Time-of-use period", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_RH, "relhum", "Relative humidity of the ambient air", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_F_RECSU, "f_recSU", "Fraction powerblock can run due to receiver startup", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_DP_B, "dp_b", "Pressure drop in boiler", "Pa", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_DP_SH, "dp_sh", "Pressure drop in superheater", "Pa", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_DP_RH, "dp_rh", "Pressure drop in reheater", "Pa", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_CYCLE, "P_cycle", "Cycle power output", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_ETA, "eta", "Cycle thermal efficiency", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_COLD, "T_cold", "Heat transfer fluid outlet temperature ", "C", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_MAKEUP, "m_dot_makeup", "Cooling water makeup flow rate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_DEMAND, "m_dot_demand", "HTF required flow rate to meet power load", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_OUT, "m_dot_out", "Actual HTF flow rate passing through the power cycle", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_REF, "m_dot_ref", "Calculated reference HTF flow rate at design", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_W_COOL_PAR, "W_cool_par", "Cooling system parasitic load", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_REF_OUT, "P_ref_out", "Reference power level output at design (mirror param)", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_F_BAYS, "f_bays", "Fraction of operating heat rejection bays", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_COND, "P_cond", "Condenser pressure", "Pa", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_BOILER_IN, "P_boiler_in", "Superheater inlet pressure", "bar", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_F_RH, "f_rh", "Reheat mass flow fraction", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_RH_IN, "P_rh_in", "Reheater inlet pressure", "bar", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_RH_IN, "T_rh_in", "Reheater inlet temperature", "C", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_RH_OUT, "T_rh_out", "Reheater outlet temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, VarIndex.N_MAX, 0, 0, 0, 0, 0, 0)
)

class sam_mw_type234(tcstypeinterface):
    var wp: water_state
    var check_pressure: P_max_check
    var m_P_ref: Float64
    var m_eta_ref: Float64
    var m_T_hot_ref: Float64
    var m_T_cold_ref: Float64
    var m_dT_cw_ref: Float64
    var m_T_amb_des: Float64
    var m_q_sby_frac: Float64
    var m_P_boil_des: Float64
    var m_is_rh: Bool
    var m_P_rh_ref: Float64
    var m_T_rh_hot_ref: Float64
    var m_rh_frac_ref: Float64
    var m_CT: Int
    var m_startup_time: Float64
    var m_startup_frac: Float64
    var m_tech_type: Int
    var m_T_approach: Float64
    var m_T_ITD_des: Float64
    var m_P_cond_ratio: Float64
    var m_pb_bd_frac: Float64
    var m_P_cond_min: Float64
    var m_n_pl_inc: Int
    var m_F_wc: List[Float64]
    var m_F_wcmin: Float64
    var m_F_wcmax: Float64
    var m_P_max: Float64
    var m_startup_energy: Float64
    var m_Psat_ref: Float64
    var m_eta_adj: Float64
    var m_q_dot_ref: Float64
    var m_m_dot_ref: Float64
    var m_q_dot_rh_ref: Float64
    var m_q_dot_st_ref: Float64
    var m_db: Matrix
    var m_standby_control_prev: Int
    var m_standby_control: Int
    var m_time_su_prev: Float64
    var m_time_su: Float64
    var m_E_su_prev: Float64
    var m_E_su: Float64

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.m_P_ref = Float64.quiet_NaN()
        self.m_eta_ref = Float64.quiet_NaN()
        self.m_T_hot_ref = Float64.quiet_NaN()
        self.m_T_cold_ref = Float64.quiet_NaN()
        self.m_dT_cw_ref = Float64.quiet_NaN()
        self.m_T_amb_des = Float64.quiet_NaN()
        self.m_q_sby_frac = Float64.quiet_NaN()
        self.m_P_boil_des = Float64.quiet_NaN()
        self.m_is_rh = False
        self.m_P_rh_ref = Float64.quiet_NaN()
        self.m_T_rh_hot_ref = Float64.quiet_NaN()
        self.m_rh_frac_ref = Float64.quiet_NaN()
        self.m_CT = -1
        self.m_startup_time = Float64.quiet_NaN()
        self.m_startup_frac = Float64.quiet_NaN()
        self.m_tech_type = -1
        self.m_T_approach = Float64.quiet_NaN()
        self.m_T_ITD_des = Float64.quiet_NaN()
        self.m_P_cond_ratio = Float64.quiet_NaN()
        self.m_pb_bd_frac = Float64.quiet_NaN()
        self.m_P_cond_min = Float64.quiet_NaN()
        self.m_n_pl_inc = -1
        self.m_F_wc = List[Float64](capacity=9)
        for i in range(9):
            self.m_F_wc.append(Float64.quiet_NaN())
        self.m_F_wcmin = Float64.quiet_NaN()
        self.m_F_wcmax = Float64.quiet_NaN()
        self.m_P_max = Float64.quiet_NaN()
        self.m_startup_energy = Float64.quiet_NaN()
        self.m_Psat_ref = Float64.quiet_NaN()
        self.m_eta_adj = Float64.quiet_NaN()
        self.m_q_dot_ref = Float64.quiet_NaN()
        self.m_m_dot_ref = Float64.quiet_NaN()
        self.m_q_dot_rh_ref = Float64.quiet_NaN()
        self.m_q_dot_st_ref = Float64.quiet_NaN()
        self.m_standby_control_prev = -1
        self.m_standby_control = -1
        self.m_time_su_prev = Float64.quiet_NaN()
        self.m_time_su = Float64.quiet_NaN()
        self.m_E_su_prev = Float64.quiet_NaN()
        self.m_E_su = Float64.quiet_NaN()

    def __del__(self):

    def init(inout self) -> Int:
        self.m_P_ref = self.value(VarIndex.P_P_REF) * 1.E3
        self.m_eta_ref = self.value(VarIndex.P_ETA_REF)
        self.m_T_hot_ref = self.value(VarIndex.P_T_HOT_REF)
        self.m_T_cold_ref = self.value(VarIndex.P_T_COLD_REF)
        self.m_dT_cw_ref = self.value(VarIndex.P_DT_CW_REF)
        self.m_T_amb_des = self.value(VarIndex.P_T_AMB_DES)
        self.m_q_sby_frac = self.value(VarIndex.P_Q_SBY_FRAC)
        self.m_P_boil_des = self.value(VarIndex.P_P_BOIL_DES)
        self.m_is_rh = self.value(VarIndex.P_IS_RH) != 0.0
        self.m_P_rh_ref = self.value(VarIndex.P_P_RH_REF)
        self.m_T_rh_hot_ref = self.value(VarIndex.P_T_RH_HOT_REF)
        self.m_rh_frac_ref = self.value(VarIndex.P_RH_FRAC_REF)
        self.m_CT = Int(self.value(VarIndex.P_CT))
        self.m_startup_time = self.value(VarIndex.P_STARTUP_TIME)
        self.m_startup_frac = self.value(VarIndex.P_STARTUP_FRAC)
        self.m_tech_type = Int(self.value(VarIndex.P_TECH_TYPE))
        self.m_T_approach = self.value(VarIndex.P_T_APPROACH)
        self.m_T_ITD_des = self.value(VarIndex.P_T_ITD_DES)
        self.m_P_cond_ratio = self.value(VarIndex.P_P_COND_RATIO)
        self.m_pb_bd_frac = self.value(VarIndex.P_PB_BD_FRAC)
        self.m_P_cond_min = self.value(VarIndex.P_P_COND_MIN) * 3386.388667
        self.m_n_pl_inc = Int(self.value(VarIndex.P_N_PL_INC))
        var F_wc_in: Pointer[Float64]
        var nval_F_wc: Int
        F_wc_in = self.value(VarIndex.P_F_WC, &nval_F_wc)
        if nval_F_wc != 9:
            return -1
        self.m_F_wcmax = 0.0
        self.m_F_wcmin = 1.0
        for i in range(9):
            self.m_F_wc[i] = F_wc_in[i]
            self.m_F_wcmin = min(self.m_F_wcmin, self.m_F_wc[i])
            self.m_F_wcmax = max(self.m_F_wcmax, self.m_F_wc[i])
        self.m_P_max = 190.0
        if self.m_P_boil_des > self.m_P_max:
            self.m_P_boil_des = self.m_P_max
        self.check_pressure.set_P_max(self.m_P_max)
        self.m_startup_energy = self.m_startup_frac * self.m_P_ref / self.m_eta_ref
        self.m_standby_control_prev = 3
        self.m_time_su_prev = self.m_startup_time
        self.m_E_su_prev = self.m_startup_energy
        self.m_time_su = self.m_time_su_prev
        self.m_E_su = self.m_E_su_prev
        if self.m_P_boil_des > 190.0:
            self.m_P_boil_des = 190.0
        self.Set_PB_coefficients()
        self.Set_PB_ref_values()
        return 0

    def Set_PB_coefficients(inout self):
        if self.m_tech_type == 1:
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [0.16759, 0.21750, 0.26932, 0.32275, 0.37743, 0.43300, 0.48910, 0.54545, 0.60181, 0.65815, 0.71431, 0.77018, 0.82541, 0.88019, 0.93444, 0.98886, 1.04378, 1.09890, 1.15425, 1.20982],
                [0.19656, 0.24969, 0.30325, 0.35710, 0.41106, 0.46497, 0.51869, 0.57215, 0.62529, 0.67822, 0.73091, 0.78333, 0.83526, 0.88694, 0.93838, 0.98960, 1.04065, 1.09154, 1.14230, 1.19294],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [1.07401, 1.04917, 1.03025, 1.01488, 1.00201, 0.99072, 0.98072, 0.97174, 0.96357, 0.95607, 0.94914, 0.94269, 0.93666, 0.93098, 0.92563, 0.92056, 0.91573, 0.91114, 0.90675, 0.90255],
                [1.00880, 1.00583, 1.00355, 1.00168, 1.00010, 0.99870, 0.99746, 0.99635, 0.99532, 0.99438, 0.99351, 0.99269, 0.99193, 0.99121, 0.99052, 0.98988, 0.98926, 0.98867, 0.98810, 0.98756],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [0.09403, 0.16542, 0.23861, 0.31328, 0.38901, 0.46540, 0.54203, 0.61849, 0.69437, 0.76928, 0.84282, 0.91458, 0.98470, 1.05517, 1.12536, 1.19531, 1.26502, 1.33450, 1.40376, 1.47282],
                [0.10659, 0.18303, 0.25848, 0.33316, 0.40722, 0.48075, 0.55381, 0.62646, 0.69873, 0.77066, 0.84228, 0.91360, 0.98464, 1.05542, 1.12596, 1.19627, 1.26637, 1.33625, 1.40593, 1.47542],
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [1.03323, 1.04058, 1.04456, 1.04544, 1.04357, 1.03926, 1.03282, 1.02446, 1.01554, 1.00944, 1.00487, 1.00169, 0.99986, 0.99926, 0.99980, 1.00027, 1.00021, 1.00015, 1.00006, 0.99995],
                [0.98344, 0.98630, 0.98876, 0.99081, 0.99247, 0.99379, 0.99486, 0.99574, 0.99649, 0.99716, 0.99774, 0.99826, 0.99877, 0.99926, 0.99972, 1.00017, 1.00060, 1.00103, 1.00143, 1.00182],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [0.99269, 0.99520, 0.99718, 0.99882, 1.00024, 1.00150, 1.00264, 1.00368, 1.00464, 1.00554, 1.00637, 1.00716, 1.00790, 1.00840, 1.00905, 1.00965, 1.01022, 1.01075, 1.01126, 1.01173],
                [0.99768, 0.99861, 0.99933, 0.99992, 1.00043, 1.00087, 1.00127, 1.00164, 1.00197, 1.00227, 1.00255, 1.00282, 1.00307, 1.00331, 1.00353, 1.00375, 1.00395, 1.00415, 1.00433, 1.00451],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [1.00812, 1.00513, 1.00294, 1.00128, 0.99980, 0.99901, 0.99855, 0.99836, 0.99846, 0.99883, 0.99944, 1.00033, 1.00042, 1.00056, 1.00069, 1.00081, 1.00093, 1.00104, 1.00115, 1.00125],
                [1.09816, 1.07859, 1.06487, 1.05438, 1.04550, 1.03816, 1.03159, 1.02579, 1.02061, 1.01587, 1.01157, 1.00751, 1.00380, 1.00033, 0.99705, 0.99400, 0.99104, 0.98832, 0.98565, 0.98316]
            )
            # flatten dTemp into a single array and assign to m_db
            var flat: List[Float64] = List[Float64]()
            for row in range(18):
                for col in range(20):
                    flat.append(dTemp[row][col])
            var ptr = flat.to_pointer()
            self.m_db.assign(ptr, 18, 20)
        if self.m_tech_type == 2:
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000],
                [0.08547, 0.14823, 0.21378, 0.28166, 0.35143, 0.42264, 0.49482, 0.56747, 0.64012, 0.71236, 0.78378, 0.85406, 0.92284, 0.98989, 1.05685, 1.12369, 1.19018, 1.25624, 1.32197, 1.38744],
                [0.10051, 0.16934, 0.23822, 0.30718, 0.37623, 0.44534, 0.51443, 0.58338, 0.65209, 0.72048, 0.78848, 0.85606, 0.92317, 0.98983, 1.05604, 1.12182, 1.18718, 1.25200, 1.31641, 1.38047],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [1.08827, 1.06020, 1.03882, 1.02145, 1.00692, 0.99416, 0.98288, 0.97273, 0.96350, 0.95504, 0.94721, 0.93996, 0.93314, 0.92673, 0.92069, 0.91496, 0.90952, 0.90433, 0.89938, 0.89464],
                [1.01276, 1.00877, 1.00570, 1.00318, 1.00106, 0.99918, 0.99751, 0.99601, 0.99463, 0.99335, 0.99218, 0.99107, 0.99004, 0.98907, 0.98814, 0.98727, 0.98643, 0.98563, 0.98487, 0.98413],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [0.09307, 0.16421, 0.23730, 0.31194, 0.38772, 0.46420, 0.54098, 0.61763, 0.69374, 0.76896, 0.84287, 0.91511, 0.98530, 1.05512, 1.12494, 1.19447, 1.26373, 1.33273, 1.40148, 1.46999],
                [0.10741, 0.18443, 0.26031, 0.33528, 0.40950, 0.48308, 0.55610, 0.62861, 0.70066, 0.77229, 0.84354, 0.91443, 0.98497, 1.05520, 1.12514, 1.19478, 1.26416, 1.33329, 1.40217, 1.47081],
                [0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000],
                [1.01749, 1.03327, 1.04339, 1.04900, 1.05051, 1.04825, 1.04249, 1.03343, 1.02126, 1.01162, 1.00500, 1.00084, 0.99912, 0.99966, 0.99972, 0.99942, 0.99920, 0.99911, 0.99885, 0.99861],
                [0.99137, 0.99297, 0.99431, 0.99564, 0.99681, 0.99778, 0.99855, 0.99910, 0.99948, 0.99971, 0.99984, 0.99989, 0.99993, 0.99993, 0.99992, 0.99992, 0.99992, 1.00009, 1.00010, 1.00012],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [0.99653, 0.99756, 0.99839, 0.99906, 0.99965, 1.00017, 1.00063, 1.00106, 1.00146, 1.00183, 1.00218, 1.00246, 1.00277, 1.00306, 1.00334, 1.00361, 1.00387, 1.00411, 1.00435, 1.00458],
                [0.99760, 0.99831, 0.99888, 0.99934, 0.99973, 1.00008, 1.00039, 1.00067, 1.00093, 1.00118, 1.00140, 1.00161, 1.00180, 1.00199, 1.00217, 1.00234, 1.00250, 1.00265, 1.00280, 1.00294],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [1.01994, 1.01645, 1.01350, 1.01073, 1.00801, 1.00553, 1.00354, 1.00192, 1.00077, 0.99995, 0.99956, 0.99957, 1.00000, 0.99964, 0.99955, 0.99945, 0.99937, 0.99928, 0.99919, 0.99918],
                [1.02055, 1.01864, 1.01869, 1.01783, 1.01508, 1.01265, 1.01031, 1.00832, 1.00637, 1.00454, 1.00301, 1.00141, 1.00008, 0.99851, 0.99715, 0.99586, 0.99464, 0.99347, 0.99227, 0.99177]
            )
            var flat: List[Float64] = List[Float64]()
            for row in range(18):
                for col in range(20):
                    flat.append(dTemp[row][col])
            var ptr = flat.to_pointer()
            self.m_db.assign(ptr, 18, 20)
        if self.m_tech_type == 3:
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.10000, 0.21111, 0.32222, 0.43333, 0.54444, 0.65556, 0.76667, 0.87778, 0.98889, 1.10000],
                [0.89280, 0.90760, 0.92160, 0.93510, 0.94820, 0.96110, 0.97370, 0.98620, 0.99860, 1.01100],
                [0.93030, 0.94020, 0.94950, 0.95830, 0.96690, 0.97520, 0.98330, 0.99130, 0.99910, 1.00700],
                [4000.00, 6556.00, 9111.00, 11677.0, 14222.0, 16778.0, 19333.0, 21889.0, 24444.0, 27000.0],
                [1.04800, 1.01400, 0.99020, 0.97140, 0.95580, 0.94240, 0.93070, 0.92020, 0.91060, 0.90190],
                [0.99880, 0.99960, 1.00000, 1.00100, 1.00100, 1.00100, 1.00100, 1.00200, 1.00200, 1.00200],
                [0.20000, 0.31667, 0.43333, 0.55000, 0.66667, 0.78333, 0.90000, 1.01667, 1.13333, 1.25000],
                [0.16030, 0.27430, 0.39630, 0.52310, 0.65140, 0.77820, 0.90060, 1.01600, 1.12100, 1.21400],
                [0.22410, 0.34700, 0.46640, 0.58270, 0.69570, 0.80550, 0.91180, 1.01400, 1.11300, 1.20700],
                [0.10000, 0.21111, 0.32222, 0.43333, 0.54444, 0.65556, 0.76667, 0.87778, 0.98889, 1.10000],
                [1.05802, 1.05127, 1.04709, 1.03940, 1.03297, 1.02480, 1.01758, 1.00833, 1.00180, 0.99307],
                [1.03671, 1.03314, 1.02894, 1.02370, 1.01912, 1.01549, 1.01002, 1.00486, 1.00034, 0.99554],
                [4000.00, 6556.00, 9111.00, 11677.0, 14222.0, 16778.0, 19333.0, 21889.0, 24444.0, 27000.0],
                [1.00825, 0.98849, 0.99742, 1.02080, 1.02831, 1.03415, 1.03926, 1.04808, 1.05554, 1.05862],
                [1.01838, 1.02970, 0.99785, 0.99663, 0.99542, 0.99183, 0.98897, 0.99299, 0.99013, 0.98798],
                [0.20000, 0.31667, 0.43333, 0.55000, 0.66667, 0.78333, 0.90000, 1.01667, 1.13333, 1.25000],
                [1.43311, 1.27347, 1.19090, 1.13367, 1.09073, 1.05602, 1.02693, 1.00103, 0.97899, 0.95912],
                [0.48342, 0.64841, 0.64322, 0.74366, 0.76661, 0.82764, 0.97792, 1.15056, 1.23117, 1.31179]
            )
            var flat: List[Float64] = List[Float64]()
            for row in range(18):
                for col in range(10):
                    flat.append(dTemp[row][col])
            var ptr = flat.to_pointer()
            self.m_db.assign(ptr, 18, 10)
        if self.m_tech_type == 5:
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [0.74230, 0.76080, 0.77870, 0.79620, 0.81340, 0.83050, 0.84740, 0.86440, 0.88120, 0.89780, 0.91440, 0.93090, 0.94730, 0.96380, 0.98030, 0.99670, 1.01300, 1.03000, 1.04700, 1.06300],
                [0.80770, 0.82580, 0.84220, 0.85740, 0.87170, 0.88510, 0.89800, 0.91030, 0.92220, 0.93380, 0.94500, 0.95600, 0.96670, 0.97730, 0.98770, 0.99790, 1.00800, 1.01800, 1.02800, 1.03800],
                [0.86950, 0.85270, 0.84380, 0.84070, 0.84210, 0.84730, 0.85550, 0.86630, 0.87890, 0.89280, 0.90780, 0.92390, 0.94090, 0.95860, 0.97710, 0.99620, 1.01600, 1.03600, 1.05700, 1.07800],
                [4000.00, 5368.42, 6736.84, 8105.26, 9473.68, 10842.11, 12210.53, 13578.95, 14947.37, 16315.79, 17684.21, 19052.63, 20421.05, 21789.47, 23157.89, 24526.32, 25894.74, 27263.16, 28631.58, 30000.00],
                [1.03800, 1.02200, 1.01000, 0.99930, 0.99030, 0.98230, 0.97520, 0.96870, 0.96280, 0.95730, 0.95220, 0.94740, 0.94300, 0.93870, 0.93480, 0.93100, 0.92730, 0.92390, 0.92060, 0.91740],
                [1.00100, 1.00100, 1.00000, 0.99990, 0.99950, 0.99920, 0.99890, 0.99860, 0.99840, 0.99810, 0.99790, 0.99770, 0.99750, 0.99730, 0.99720, 0.99700, 0.99690, 0.99670, 0.99660, 0.99640],
                [0.99430, 0.99670, 0.99860, 1.00000, 1.00200, 1.00300, 1.00400, 1.00500, 1.00600, 1.00700, 1.00700, 1.00800, 1.00900, 1.01000, 1.01000, 1.01100, 1.01100, 1.01200, 1.01200, 1.01300],
                [0.10000, 0.15263, 0.20526, 0.25789, 0.31053, 0.36316, 0.41579, 0.46842, 0.52105, 0.57368, 0.62632, 0.67895, 0.73158, 0.78421, 0.83684, 0.88947, 0.94211, 0.99474, 1.04737, 1.10000],
                [0.08098, 0.12760, 0.17660, 0.22780, 0.28070, 0.33520, 0.39090, 0.44730, 0.50030, 0.55780, 0.61510, 0.67200, 0.72820, 0.78370, 0.83820, 0.89160, 0.94400, 0.99500, 1.04500, 1.09300],
                [0.10940, 0.16700, 0.22450, 0.28210, 0.33970, 0.39730, 0.45490, 0.51240, 0.56520, 0.61620, 0.66630, 0.71560, 0.76420, 0.81190, 0.85890, 0.90520, 0.95070, 0.99550, 1.04000, 1.08300],
                [0.07722, 0.12110, 0.16690, 0.21440, 0.26350, 0.31380, 0.36520, 0.41720, 0.44960, 0.50670, 0.56500, 0.62440, 0.68480, 0.74580, 0.80740, 0.86940, 0.93160, 0.99390, 1.05600, 1.11800],
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [0.98450, 0.98907, 0.99169, 0.99305, 0.99451, 0.99467, 0.99555, 0.99573, 0.99599, 0.99695, 0.99727, 0.99763, 0.99802, 0.99778, 0.99755, 0.99790, 1.00412, 1.00094, 0.99786, 1.00541],
                [0.96043, 0.96885, 0.97567, 0.98076, 0.98406, 0.98772, 0.99019, 0.99223, 0.99443, 0.99800, 0.99722, 0.99780, 1.00043, 0.99745, 1.00199, 1.00164, 1.00199, 1.00298, 0.99803, 0.99903],
                [1.13799, 1.12215, 1.10761, 1.09474, 1.08321, 1.07117, 1.06082, 1.05054, 1.04231, 1.03449, 1.03001, 1.02000, 1.01481, 1.01075, 1.00730, 1.00112, 0.99609, 0.99440, 0.98833, 0.98641],
                [4000.00, 5368.42, 6736.84, 8105.26, 9473.68, 10842.11, 12210.53, 13578.95, 14947.37, 16315.79, 17684.21, 19052.63, 20421.05, 21789.47, 23157.89, 24526.32, 25894.74, 27263.16, 28631.58, 30000.00],
                [0.99027, 1.00027, 1.00141, 1.00607, 1.00445, 1.01006, 1.00791, 1.01656, 1.02015, 1.02004, 1.02471, 1.02659, 1.02510, 1.02729, 1.02884, 1.03094, 1.03294, 1.03397, 1.03576, 1.03745],
                [0.99692, 0.99900, 0.99870, 1.00116, 0.99392, 0.99817, 1.00268, 0.99376, 0.99685, 1.00111, 1.00394, 0.99386, 0.99669, 0.99953, 1.00121, 1.00405, 1.00573, 0.99511, 0.99679, 0.99964],
                [1.02527, 1.01447, 1.00819, 0.99962, 0.99609, 0.99128, 0.98686, 0.98321, 0.97395, 0.97108, 0.97250, 0.97040, 0.96232, 0.96099, 0.95682, 0.95587, 0.95208, 0.95152, 0.94811, 0.94756],
                [0.10000, 0.15263, 0.20526, 0.25789, 0.31053, 0.36316, 0.41579, 0.46842, 0.52105, 0.57368, 0.62632, 0.67895, 0.73158, 0.78421, 0.83684, 0.88947, 0.94211, 0.99474, 1.04737, 1.10000],
                [1.09510, 1.10157, 1.10663, 1.10675, 1.11166, 1.10757, 1.10278, 1.13312, 1.14401, 1.11992, 1.09445, 1.07305, 1.05616, 1.03925, 1.02666, 1.01617, 1.00719, 1.00320, 1.00355, 1.00405],
                [0.00000, 0.00000, 0.00000, 0.00000, 0.00000, 0.00000, 0.00000, 0.35237, 0.98785, 0.97371, 1.07142, 1.10630, 1.09046, 1.18378, 1.20956, 1.17838, 1.21840, 1.24170, 1.01496, 1.43634],
                [3.04989, 3.04563, 3.06817, 3.07452, 3.07856, 3.06611, 3.07191, 1.77603, 0.66771, 0.72244, 0.75574, 0.79547, 0.83991, 0.86983, 0.90542, 0.93997, 0.96970, 0.98014, 1.00831, 1.06526]
            )
            var flat: List[Float64] = List[Float64]()
            for row in range(24):
                for col in range(20):
                    flat.append(dTemp[row][col])
            var ptr = flat.to_pointer()
            self.m_db.assign(ptr, 24, 20)

    def Set_PB_ref_values(inout self) -> Bool:
        # comment preserved
        switch self.m_CT:
            case 1:
                if self.m_tech_type != 4:
                    water_TQ(self.m_dT_cw_ref + 3.0 + self.m_T_approach + self.m_T_amb_des + 273.15, 1.0, &self.wp)
                    self.m_Psat_ref = self.wp.pres * 1000.0
                else:
                    self.m_Psat_ref = CSP.P_sat4(self.m_dT_cw_ref + 3.0 + self.m_T_approach + self.m_T_amb