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

# Mojo translation of sam_mw_trough_type251.cpp

from tcstype import *
from htf_props import HTFProperties
from sam_csp_util import CSP
from storage_hx import Storage_HX
from thermocline_tes import Thermocline_TES
from CO2_properties import *
from sco2_recompression_cycle import *

import math

# ------------------------------------------------------------
# Utility matrix class (replacing util::matrix_t<double>)
# To match C++ usage exactly, we provide the needed methods.
# ------------------------------------------------------------
@value
struct matrix_t:
    var data: List[Float64]
    var nrows: Int = 0
    var ncols: Int = 0

    def __init__(inout self):
        self.data = List[Float64]()
        self.nrows = 0
        self.ncols = 0

    def __init__(inout self, rows: Int, cols: Int, val: Float64):
        self.data = List[Float64](size=rows*cols, fill=val)
        self.nrows = rows
        self.ncols = cols

    def __init__(inout self, ptr: Pointer[Float64], length: Int):
        # Not used directly, we use assign instead
        self.data = List[Float64](size=length, fill=0.0)
        self.nrows = length
        self.ncols = 1

    def assign(inout self, ptr: DTypePointer[Float64], length: Int):
        self.data = List[Float64](size=length, fill=0.0)
        self.nrows = length
        self.ncols = 1
        for i in range(length):
            self.data[i] = ptr[i]

    def assign(inout self, ptr: List[Float64], length: Int):
        self.data = List[Float64](size=length, fill=0.0)
        self.nrows = length
        self.ncols = 1
        for i in range(length):
            self.data[i] = ptr[i]

    def at(inout self, r: Int, c: Int) -> Float64:
        return self.data[r * self.ncols + c]

    def ncells(self) -> Int:
        return len(self.data)

    def data(self) -> DTypePointer[Float64]:
        return self.data.data

    def resize_fill(inout self, n: Int, val: Float64):
        self.data = List[Float64](size=n, fill=val)
        self.nrows = n
        self.ncols = 1


# ------------------------------------------------------------
# tcsvarinfo struct (matching C++ definition)
# ------------------------------------------------------------
@value
struct tcsvarinfo:
    var vartype: Int
    var datatype: Int
    var index: Int
    var name: String
    var description: String
    var units: String
    var group: String
    var meta: String
    var default: String

# Constants for vartype and datatype (matching TCS_* macros)
alias TCS_PARAM = 0
alias TCS_INPUT = 1
alias TCS_OUTPUT = 2
alias TCS_NUMBER = 0
alias TCS_MATRIX = 1
alias TCS_ARRAY = 2
alias TCS_INVALID = -1
alias TCS_ERROR = 1
alias TCS_NOTICE = 2
alias TCS_WARNING = 3
# TCS_MATRIX_INDEX: macro to access matrix element
@parameter
def TCS_MATRIX_INDEX(var_ptr: Pointer[Float64], r: Int, c: Int) -> Float64:
    # This is a placeholder; the actual macro in C++ accesses a 2D array.
    # Since we pass a pointer to the whole flat array, we assume row-major.
    # For the variable list, the matrix is stored as a flat list.
    # The user must ensure correct indexing.
    return var_ptr[r * 7 + c]  # typical 7 columns

# ------------------------------------------------------------
# Global enum for variable indices (C++ anonymous enum)
# ------------------------------------------------------------
enum VarIndex:
    P_field_fl = 0
    P_field_fl_props = 1
    P_store_fl = 2
    P_store_fl_props = 3
    P_tshours = 4
    P_eta_pump = 5
    P_hdr_rough = 6
    P_is_hx = 7
    P_dt_hot = 8
    P_dt_cold = 9
    P_hx_config = 10
    P_q_max_aux = 11
    P_lhv_eff = 12
    P_T_set_aux = 13
    P_V_tank_hot_ini = 14
    P_T_tank_hot_ini = 15
    P_T_tank_cold_ini = 16
    P_vol_tank = 17
    P_h_tank = 18
    P_h_tank_min = 19
    P_u_tank = 20
    P_tank_pairs = 21
    P_cold_tank_Thtr = 22
    P_hot_tank_Thtr = 23
    P_cold_tank_max_heat = 24
    P_hot_tank_max_heat = 25
    P_tanks_in_parallel = 26
    P_hot_tank_bypass = 27
    P_T_tank_hot_in_min = 28
    P_des_pipe_vals = 29
    P_T_field_in_des = 30
    P_T_field_out_des = 31
    P_q_pb_design = 32
    P_W_pb_design = 33
    P_cycle_max_frac = 34
    P_cycle_cutoff_frac = 35
    P_solarm = 36
    P_pb_pump_coef = 37
    P_tes_pump_coef = 38
    P_V_tes_des = 39
    P_custom_tes_p_loss = 40
    P_k_tes_loss_coeffs = 41
    P_custom_sgs_pipe_sizes = 42
    P_sgs_diams = 43
    P_sgs_wallthicks = 44
    P_sgs_lengths = 45
    P_dp_sgs = 46
    P_pb_fixed_par = 47
    P_bop_array = 48
    P_aux_array = 49
    P_T_startup = 50
    P_fossil_mode = 51
    P_fthr_ok = 52
    P_nSCA = 53
    P_I_bn_des = 54
    P_fc_on = 55
    P_q_sby_frac = 56
    P_t_standby_init = 57
    P_sf_type = 58
    P_tes_type = 59
    P_tslogic_a = 60
    P_tslogic_b = 61
    P_tslogic_c = 62
    P_ffrac = 63
    P_tc_fill = 64
    P_tc_void = 65
    P_t_dis_out_min = 66
    P_t_ch_out_max = 67
    P_nodes = 68
    P_f_tc_cold = 69
    P_PB_TECH_TYPE = 70
    # Inputs
    I_I_bn = 71
    I_m_dot_field = 72
    I_m_dot_htf_ref = 73
    I_T_field_out = 74
    I_T_pb_out = 75
    I_T_amb = 76
    I_dnifc = 77
    I_TOUPeriod = 78
    I_T_field_in_at_des = 79
    I_T_field_out_at_des = 80
    I_P_field_in_at_des = 81
    I_defocus = 82
    I_T_HTF_COLD_DES = 83
    # Outputs
    O_V_sgs = 84
    O_D_sgs = 85
    O_wall_thk_sgs = 86
    O_m_dot_des_sgs = 87
    O_vel_des_sgs = 88
    O_t_des_sgs = 89
    O_p_des_sgs = 90
    O_p_des_sgs_1 = 91
    O_defocus = 92
    O_recirc = 93
    O_standby = 94
    O_m_dot_pb = 95
    O_T_pb_in = 96
    O_T_field_in = 97
    O_charge_field = 98
    O_charge_tank = 99
    O_Ts_hot = 100
    O_Ts_cold = 101
    O_T_tank_hot_in = 102
    O_T_tank_cold_in = 103
    O_vol_tank_hot_fin = 104
    O_vol_tank_cold_fin = 105
    O_T_tank_hot_fin = 106
    O_T_tank_cold_fin = 107
    O_q_par_fp = 108
    O_m_dot_aux = 109
    O_q_aux_heat = 110
    O_q_aux_fuel = 111
    O_vol_tank_total = 112
    O_hx_eff = 113
    O_mass_tank_hot = 114
    O_mass_tank_cold = 115
    O_mass_tank_total = 116
    O_htf_pump_power = 117
    O_bop_par = 118
    O_fixed_par = 119
    O_aux_par = 120
    O_q_pb = 121
    O_tank_losses = 122
    O_q_to_tes = 123
    O_mode = 124
    O_TOU = 125
    O_T_hot_node = 126
    O_T_cold_node = 127
    O_T_max = 128
    O_f_hot = 129
    O_f_cold = 130
    N_MAX = 131

# ------------------------------------------------------------
# Variable registry (C++ array sam_mw_trough_type251_variables)
# ------------------------------------------------------------
var sam_mw_trough_type251_variables: List[tcsvarinfo] = List[tcsvarinfo]()
# Populate (exact copy of C++ array, row by row)
# We use a function to set up the list
def __init_variables():
    # Using appends (the C++ static array is indexed by enum)
    # We'll assign each element by index
    # Because Mojo has no static initializer, we do it here.
    # We'll create a list with N_MAX elements and set them.

# But for brevity, we manually add elements. Since the list is long, we'll replicate the exact ordering.
# Actually the array is defined in C++ as a global static array. In Mojo we can define a global list.
# We'll write each element explicitly.
let _ = sam_mw_trough_type251_variables.append

_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_field_fl, "field_fluid", "Material number for the collector field", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_MATRIX, VarIndex.P_field_fl_props, "field_fl_props", "User defined field fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_store_fl, "store_fluid", "Material number for storage fluid", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_MATRIX, VarIndex.P_store_fl_props, "store_fl_props", "User defined fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tshours, "tshours", "Equivalent full-load thermal storage hours", "hr", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_eta_pump, "eta_pump", "HTF pump efficiency", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_hdr_rough, "HDR_rough", "Header pipe roughness - used as general pipe roughness", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_is_hx, "is_hx", "1=yes, 0=no", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_dt_hot, "dt_hot", "Hot side HX approach temp", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_dt_cold, "dt_cold", "Cold side HX approach temp", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_hx_config, "hx_config", "HX configuration", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_q_max_aux, "q_max_aux", "Max heat rate of auxiliary heater", "MWt", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_lhv_eff, "lhv_eff", "Fuel LHV efficiency (0..1)", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_set_aux, "T_set_aux", "Aux heater outlet temp set point", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_V_tank_hot_ini, "V_tank_hot_ini", "Initial hot tank fluid volume", "m3", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_tank_hot_ini, "T_tank_hot_ini", "Initial hot tank fluid temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_tank_cold_ini, "T_tank_cold_ini", "Initial cold tank fluid temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_vol_tank, "vol_tank", "Total tank volume, including unusable HTF at bottom", "m3", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_h_tank, "h_tank", "Total height of tank (height of HTF when tank is full)", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_h_tank_min, "h_tank_min", "Minimum allowable HTF height in storage tank", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_u_tank, "u_tank", "Loss coefficient from the tank", "W/m2-K", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tank_pairs, "tank_pairs", "Number of equivalent tank pairs", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_cold_tank_Thtr, "cold_tank_Thtr", "Minimum allowable cold tank HTF temp", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_hot_tank_Thtr, "hot_tank_Thtr", "Minimum allowable hot tank HTF temp", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_cold_tank_max_heat, "cold_tank_max_heat", "Rated heater capacity for cold tank heating", "MW", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_hot_tank_max_heat, "hot_tank_max_heat", "Rated heater capacity for hot tank heating", "MW", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tanks_in_parallel, "tanks_in_parallel", "Tanks are in parallel, not in series, with solar field", "-", "", "", "true")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_hot_tank_bypass, "has_hot_tank_bypass", "Bypass valve connects field outlet to cold tank", "-", "", "", "false")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_tank_hot_in_min, "T_tank_hot_inlet_min", "Minimum hot tank htf inlet temperature", "C", "", "", "400")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_des_pipe_vals, "calc_design_pipe_vals", "Calculate pipe temps and pressures at design conditions", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_field_in_des, "T_field_in_des", "Field design inlet temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_field_out_des, "T_field_out_des", "Field design outlet temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_q_pb_design, "q_pb_design", "Design heat input to power block", "MWt", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_W_pb_design, "W_pb_design", "Rated plant capacity", "MWe", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_cycle_max_frac, "cycle_max_frac", "Maximum turbine over design operation fraction", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_cycle_cutoff_frac, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_solarm, "solarm", "Solar Multiple", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_pb_pump_coef, "pb_pump_coef", "Pumping power to move 1kg of HTF through PB loop", "kW/(kg/s)", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tes_pump_coef, "tes_pump_coef", "Pumping power to move 1kg of HTF through tes loop", "kW/(kg/s)", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_V_tes_des, "V_tes_des", "Design-point velocity to size the TES pipe diameters", "m/s", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_custom_tes_p_loss, "custom_tes_p_loss", "TES pipe losses are based on custom lengths and coeffs", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_k_tes_loss_coeffs, "k_tes_loss_coeffs", "Minor loss coeffs for the coll, gen, and bypass loops", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_custom_sgs_pipe_sizes, "custom_sgs_pipe_sizes", "Use custom SGS pipe diams, wallthks, and lengths", "-", "", "", "false")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_sgs_diams, "sgs_diams", "Custom SGS diameters", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_sgs_wallthicks, "sgs_wallthicks", "Custom SGS wall thicknesses", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_sgs_lengths, "sgs_lengths", "Custom SGS lengths", "m", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_dp_sgs, "DP_SGS", "Pressure drop within the steam generator", "bar", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_pb_fixed_par, "pb_fixed_par", "Fraction of rated gross power constantly consumed", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_bop_array, "bop_array", "Coefficients for balance of plant parasitics calcs", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_aux_array, "aux_array", "Coefficients for auxiliary heater parasitics calcs", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_startup, "T_startup", "Startup temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_fossil_mode, "fossil_mode", "Fossil backup mode 1=Normal 2=Topping", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_fthr_ok, "fthr_ok", "Does the defocus control allow partial defocusing", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_nSCA, "nSCA", "Number of SCAs in a single loop", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_I_bn_des, "I_bn_des", "Design point irradiation value", "W/m2", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_fc_on, "fc_on", "DNI forecasting enabled", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_q_sby_frac, "q_sby_frac", "Fraction of thermal power required for standby", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_t_standby_init, "t_standby_reset", "Maximum allowable time for PB standby operation", "hr", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_sf_type, "sf_type", "Solar field type, 1 = trough & MSLF, 2 = tower", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tes_type, "tes_type", "1=2-tank, 2=thermocline", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_tslogic_a, "tslogic_a", "Dispatch logic without solar", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_tslogic_b, "tslogic_b", "Dispatch logic with solar", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_tslogic_c, "tslogic_c", "Dispatch logic for turbine load fraction", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_ffrac, "ffrac", "Fossil dispatch logic", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tc_fill, "tc_fill", "Thermocline fill material", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_tc_void, "tc_void", "Thermocline void fraction", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_t_dis_out_min, "t_dis_out_min", "Min allowable hot side outlet temp during discharge", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_t_ch_out_max, "t_ch_out_max", "Max allowable cold side outlet temp during charge", "C", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_nodes, "nodes", "Nodes modeled in the flow path", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_f_tc_cold, "f_tc_cold", "0=entire tank is hot, 1=entire tank is cold", "-", "", "", "")
_ = tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_PB_TECH_TYPE, "pb_tech_type", "Flag indicating which coef. set to use. (1=tower,2=trough,3=user)", "none", "", "", "2")
# Inputs
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_I_bn, "I_bn", "Direct beam irradiance", "W/m2", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_m_dot_field, "m_dot_field", "Mass flow rate from the field", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_m_dot_htf_ref, "m_dot_htf_ref", "Reference HTF flow rate at design conditions", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_field_out, "T_field_out", "HTF temperature from the field", "C", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_pb_out, "T_pb_out", "Fluid temperature from the power block", "C", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_amb, "T_amb", "Ambient temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_dnifc, "dnifc", "Forecast DNI", "W/m2", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_TOUPeriod, "TOUPeriod", "The time-of-use period", "", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_field_in_at_des, "T_field_in_at_des", "Field inlet temperature at design conditions", "C", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_field_out_at_des, "T_field_out_at_des", "Field outlet temperature at design conditions", "C", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_P_field_in_at_des, "P_field_in_at_des", "Field inlet pressure at design conditions", "bar", "", "", "")
_ = tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_defocus, "defocus_prev", "Previous relative defocus", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.I_T_HTF_COLD_DES, "i_T_htf_cold_des", "Calculated htf cold temperature at design", "C", "", "", "")
# Outputs
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_V_sgs, "SGS_vol_tot", "HTF volume in SGS minus bypass loop", "m3", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_D_sgs, "SGS_diams", "Pipe diameters in SGS", "m", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_wall_thk_sgs, "SGS_wall_thk", "Pipe wall thickness in SGS", "m", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_m_dot_des_sgs, "SGS_m_dot_des", "Mass flow SGS pipes at design conditions", "kg/s", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_vel_des_sgs, "SGS_vel_des", "Velocity in SGS pipes at design conditions", "m/s", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_t_des_sgs, "SGS_T_des", "Temperature in SGS pipes at design conditions", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, VarIndex.O_p_des_sgs, "SGS_P_des", "Pressure in SGS pipes at design conditions", "bar", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_p_des_sgs_1, "SGS_P_des_1", "Pressure in first SGS pipe section at design conditions", "bar", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_defocus, "defocus", "Absolute defocus = defocus_abs_prev * defocus_rel", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_recirc, "recirculating", "Field recirculating bypass valve control", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_standby, "standby_control", "Standby control flag", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_m_dot_pb, "m_dot_pb", "Mass flow rate of HTF to PB", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_pb_in, "T_pb_in", "HTF temperature to power block", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_field_in, "T_field_in", "HTF temperature into collector field header", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_charge_field, "m_dot_charge_field", "Mass flow rate on field side of HX", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_charge_tank, "m_dot_discharge_tank", "Mass flow rate on storage side of HX", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_Ts_hot, "Ts_hot", "Field/pb HTF exiting HX (or hot tank) during discharge", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_Ts_cold, "Ts_cold", "Field/pb HTF exiting HX (or cold tank) during charge", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_tank_hot_in, "T_tank_hot_in", "Hot tank HTF inlet temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_tank_cold_in, "T_tank_cold_in", "Cold tank HTF inlet temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_vol_tank_hot_fin, "vol_tank_hot_fin", "Hot tank HTF volume at end of timestep", "m3", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_vol_tank_cold_fin, "vol_tank_cold_fin", "Cold tank HTF volume at end of timestep", "m3", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_tank_hot_fin, "T_tank_hot_fin", "Hot tank HTF temperature at end of timestep", "K", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_tank_cold_fin, "T_tank_cold_fin", "Cold tank HTF temperature at end of timestep", "K", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_q_par_fp, "tank_fp_par", "Total parasitic power required for tank freeze protect.", "MWe", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_m_dot_aux, "m_dot_aux", "Auxiliary heater mass flow rate", "kg/hr", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_q_aux_heat, "q_aux_heat", "Thermal energy provided to fluid by aux heater", "MWt", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_q_aux_fuel, "q_aux_fuel", "Heat content of fuel required to provide aux heat", "MMBTU", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_vol_tank_total, "vol_tank_total", "Total HTF volume in storage", "m3", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_hx_eff, "hx_eff", "Heat exchanger effectiveness", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_mass_tank_hot, "mass_tank_hot", "Mass of total fluid in the hot tank", "kg", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_mass_tank_cold, "mass_tank_cold", "Mass of total fluid in the cold tank", "kg", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_mass_tank_total, "mass_tank_total", "Total mass of fluid in tanks", "kg", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_htf_pump_power, "htf_pump_power", "Pumping power for storage, power block loops", "MWe", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_bop_par, "bop_par", "Parasitic power as a function of power block load", "MWe", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_fixed_par, "fixed_par", "Fixed parasitic power losses - every hour of operation", "MWe", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_aux_par, "aux_par", "Parasitic power associated with auxiliary heater", "MWe", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_q_pb, "q_pb", "Thermal energy to the power block", "MWt", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_tank_losses, "tank_losses", "Thermal losses from tank", "MWt", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_q_to_tes, "q_to_tes", "Thermal energy into storage", "MWt", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_mode, "mode", "Operation mode", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_TOU, "TOU", "Time of use period", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_hot_node, "T_hot_node", "Thermocline: Hot node temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_cold_node, "T_cold_node", "Thermocline: Cold node temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_max, "T_max", "Thermocline: Maximum temperature", "C", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_f_hot, "f_hot", "Thermocline: Hot depth fraction", "-", "", "", "")
_ = tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_f_cold, "f_cold", "Thermocline: Cold depth fraction", "-", "", "", "")
_ = tcsvarinfo(TCS_INVALID, TCS_INVALID, VarIndex.N_MAX, "0", 0, 0, 0, 0, "0")

# ------------------------------------------------------------
# Main class
# ------------------------------------------------------------
class sam_mw_trough_type251(tcstypeinterface):
    # Private members
    var field_htfProps: HTFProperties         # Instance of HTFProperties class for field HTF
    var store_htfProps: HTFProperties         # Instance of HTFProperties class for storage HTF
    var hx_storage: Storage_HX                # Instance of Storage_HX class for heat exchanger between storage and field HTFs
    var thermocline: Thermocline_TES
    const N_sgs_pipe_sections: Int = 11
    var tshours: Float64
    var eta_pump: Float64
    var HDR_rough: Float64
    var is_hx: Bool
    var dt_hot: Float64
    var dt_cold: Float64
    var hx_config: Int
    var q_max_aux: Float64
    var lhv_eff: Float64
    var T_set_aux: Float64
    var store_fl: Int
    var vol_tank: Float64
    var h_tank: Float64
    var h_tank_min: Float64
    var u_tank: Float64
    var tank_pairs: Int
    var cold_tank_Thtr: Float64
    var hot_tank_Thtr: Float64
    var cold_tank_max_heat: Float64
    var hot_tank_max_heat: Float64
    var field_fl: Int
    var T_field_in_des: Float64
    var T_field_out_des: Float64
    var q_pb_design: Float64
    var W_pb_design: Float64
    var cycle_max_frac: Float64
    var cycle_cutoff_frac: Float64
    var solarm: Float64
    var pb_pump_coef: Float64
    var tes_pump_coef: Float64
    var V_tes_des: Float64
    var custom_tes_p_loss: Bool
    var l_k_tes_loss_coeffs: Int
    var k_tes_loss_coeffs_in: DTypePointer[Float64]
    var k_tes_loss_coeffs: matrix_t
    var custom_sgs_pipe_sizes: Bool
    var l_sgs_diams: Int
    var sgs_diams: DTypePointer[Float64]
    var l_sgs_wallthicks: Int
    var sgs_wallthicks: DTypePointer[Float64]
    var l_sgs_lengths: Int
    var sgs_lengths_in: DTypePointer[Float64]
    var DP_SGS: Float64
    var pb_fixed_par: Float64
    var l_bop_array: Int
    var bop_array: DTypePointer[Float64]
    var l_aux_array: Int
    var aux_array: DTypePointer[Float64]
    var T_startup: Float64
    var fossil_mode: Int
    var fthr_ok: Bool
    var nSCA: Int
    var I_bn_des: Float64
    var fc_on: Bool
    var t_standby_reset: Float64
    var sf_type: Int
    var tes_type: Int
    var numtou: Int
    var tslogic_a: DTypePointer[Float64]
    var tslogic_b: DTypePointer[Float64]
    var tslogic_c: DTypePointer[Float64]
    var ffrac: DTypePointer[Float64]
    var tanks_in_parallel: Bool
    var has_hot_tank_bypass: Bool
    var T_tank_hot_inlet_min: Float64
    var calc_design_pipe_vals: Bool
    var T_field_in_at_des: Float64
    var T_field_out_at_des: Float64
    var P_field_in_at_des: Float64
    var tc_fill: Int
    var tc_void: Float64
    var t_dis_out_min: Float64
    var t_ch_out_max: Float64
    var nodes: Int
    var f_tc_cold: Float64
    var ccoef: Float64
    var q_sby_frac: Float64
    var q_sby: Float64
    var m_dot_pb_design: Float64
    var m_dot_pb_max: Float64
    var ms_charge_max: Float64
    var ms_disch_max: Float64
    var V_tank_active: Float64
    var t_standby: Float64
    var tempmode: Int
    var SGS_v_dot_rel: matrix_t
    var SGS_diams: matrix_t
    var SGS_wall_thk: matrix_t
    var SGS_lengths: matrix_t
    var SGS_m_dot_des: matrix_t
    var SGS_vel_des: matrix_t
    var SGS_T_des: matrix_t
    var SGS_P_des: matrix_t
    var V_tank_hot_prev: Float64
    var T_tank_hot_prev: Float64
    var V_tank_cold_prev: Float64
    var T_tank_cold_prev: Float64
    var mode_prev_ncall: Int
    var m_tank_hot_prev: Float64
    var m_tank_cold_prev: Float64
    var pb_on_prev: Int
    var defocus_rel_prev_ncall: Float64
    var defocus_abs: Float64
    var defocus_prev_ncall: Float64          # absolute defocus previously output for trough model
    var defocus_abs_prev: Float64            # absolute defocus from previous timestep
    var recirc_prev_ncall: Bool
    var t_standby_prev: Float64
    var vol_tank_hot_fin: Float64
    var T_tank_hot_fin: Float64
    var vol_tank_cold_fin: Float64
    var T_tank_cold_fin: Float64
    var m_tank_hot_fin: Float64
    var m_tank_cold_fin: Float64
    var pb_on: Int
    var T_pb_in: Float64
    var hx_err_flag: Bool
    var pb_tech_type: Int
    var initialize_sco2: Bool
    var err_prev_call: Float64
    var derr_prev_call: Float64

    # Constants for mode
    enum Mode:
        pb_off_or_standby = 1
        pb_partial_load = 2
        excess_energy = 3
        charging_storage = 4

    def __init__(self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.tshours = float('nan')
        self.eta_pump = float('nan')
        self.HDR_rough = float('nan')
        self.is_hx = False
        self.dt_hot = float('nan')
        self.dt_cold = float('nan')
        self.hx_config = -1
        self.q_max_aux = float('nan')
        self.lhv_eff = float('nan')
        self.T_set_aux = float('nan')
        self.store_fl = -1
        self.vol_tank = float('nan')
        self.h_tank = float('nan')
        self.h_tank_min = float('nan')
        self.u_tank = float('nan')
        self.tank_pairs = -1
        self.cold_tank_Thtr = float('nan')
        self.hot_tank_Thtr = float('nan')
        self.cold_tank_max_heat = float('nan')
        self.hot_tank_max_heat = float('nan')
        self.field_fl = -1
        self.T_field_in_des = float('nan')
        self.T_field_out_des = float('nan')
        self.q_pb_design = float('nan')
        self.W_pb_design = float('nan')
        self.cycle_max_frac = float('nan')
        self.cycle_cutoff_frac = float('nan')
        self.solarm = float('nan')
        self.pb_pump_coef = float('nan')
        self.tes_pump_coef = float('nan')
        self.V_tes_des = float('nan')
        self.custom_tes_p_loss = False
        self.l_k_tes_loss_coeffs = -1
        self.k_tes_loss_coeffs_in = DTypePointer[Float64]()
        self.DP_SGS = float('nan')
        self.pb_fixed_par = float('nan')
        self.l_bop_array = -1
        self.bop_array = DTypePointer[Float64]()
        self.l_aux_array = -1
        self.aux_array = DTypePointer[Float64]()
        self.T_startup = float('nan')
        self.fossil_mode = -1
        self.fthr_ok = False
        self.nSCA = -1
        self.I_bn_des = float('nan')
        self.fc_on = False
        self.t_standby_reset = float('nan')
        self.sf_type = -1
        self.tes_type = -1
        self.numtou = -1
        self.tslogic_a = DTypePointer[Float64]()
        self.tslogic_b = DTypePointer[Float64]()
        self.tslogic_c = DTypePointer[Float64]()
        self.ffrac = DTypePointer[Float64]()
        self.tanks_in_parallel = False
        self.has_hot_tank_bypass = False
        self.T_tank_hot_inlet_min = float('nan')
        self.calc_design_pipe_vals = False
        self.T_field_in_at_des = float('nan')
        self.T_field_out_at_des = float('nan')
        self.P_field_in_at_des = float('nan')
        self.tc_fill = -1
        self.tc_void = float('nan')
        self.t_dis_out_min = float('nan')
        self.t_ch_out_max = float('nan')
        self.nodes = -1
        self.f_tc_cold = float('nan')
        self.ccoef = float('nan')
        self.q_sby = float('nan')
        self.m_dot_pb_design = float('nan')
        self.m_dot_pb_max = float('nan')
        self.ms_charge_max = float('nan')
        self.ms_disch_max = float('nan')
        self.V_tank_active = float('nan')
        self.t_standby = float('nan')
        self.V_tank_hot_prev = float('nan')
        self.T_tank_hot_prev = float('nan')
        self.V_tank_cold_prev = float('nan')
        self.T_tank_cold_prev = float('nan')
        self.mode_prev_ncall = -1
        self.m_tank_hot_prev = float('nan')
        self.m_tank_cold_prev = float('nan')
        self.pb_on_prev = -1
        self.defocus_rel_prev_ncall = float('nan')
        self.defocus_abs = float('nan')
        self.defocus_prev_ncall = float('nan')
        self.defocus_abs_prev = float('nan')
        self.recirc_prev_ncall = False
        self.t_standby_prev = float('nan')
        self.pb_on = -1
        self.vol_tank_hot_fin = float('nan')
        self.T_tank_hot_fin = float('nan')
        self.vol_tank_cold_fin = float('nan')
        self.T_tank_cold_fin = float('nan')
        self.m_tank_hot_fin = float('nan')
        self.m_tank_cold_fin = float('nan')
        self.T_pb_in = float('nan')
        self.q_sby_frac = float('nan')
        self.err_prev_call = float('nan')
        self.derr_prev_call = float('nan')

    def __del__(self):

    def init(self) -> Int:
        self.field_fl = int(self.value(VarIndex.P_field_fl))
        if self.field_fl != HTFProperties.User_defined:
            if not self.field_htfProps.SetFluid(self.field_fl):
                self.message(TCS_ERROR, "Field HTF code is not recognized")
                return -1
        else:
            nrows: Int = 0
            ncols: Int = 0
            fl_mat_ptr = self.value(VarIndex.P_field_fl_props, nrows, ncols)
            if fl_mat_ptr != 0 and nrows > 2 and ncols == 7:
                mat = matrix_t(nrows, ncols, 0.0)
                for r in range(nrows):
                    for c in range(ncols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(VarIndex.P_field_fl_props), r, c)
                if not self.field_htfProps.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, self.field_htfProps.UserFluidErrMessage(), nrows, ncols)
                    return -1
            else:
                self.message(TCS_ERROR, "The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains " + str(nrows) + " row(s) and " + str(ncols) + " column(s)")
                return -1

        self.store_fl = int(self.value(VarIndex.P_store_fl))
        if self.store_fl != HTFProperties.User_defined:
            if not self.store_htfProps.SetFluid(self.store_fl):
                self.message(TCS_ERROR, "Field HTF code is not recognized")
                return -1
        else:
            nrows = 0
            ncols = 0
            fl_mat_ptr = self.value(VarIndex.P_store_fl_props, nrows, ncols)
            if fl_mat_ptr != 0 and nrows > 2 and ncols == 7:
                mat = matrix_t(nrows, ncols, 0.0)
                for r in range(nrows):
                    for c in range(ncols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(VarIndex.P_store_fl_props), r, c)
                if not self.store_htfProps.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, "user defined htf property table was invalid (rows=" + str(nrows) + " cols=" + str(ncols) + ")")
                    return -1
            else:
                self.message(TCS_ERROR, "The user defined storage HTF table must contain at least 3 rows and exactly 7 columns. The current table contains " + str(nrows) + " row(s) and " + str(ncols) + " column(s)")
                return -1

        var is_hx_calc: Bool = True
        if self.store_fl != self.field_fl:
            is_hx_calc = True
        elif self.field_fl != HTFProperties.User_defined:
            is_hx_calc = False
        else:
            is_hx_calc = not self.field_htfProps.equals(self.store_htfProps)

        self.is_hx = (self.value(VarIndex.P_is_hx) != 0)
        if self.is_hx != is_hx_calc:
            if is_hx_calc:
                self.message(TCS_NOTICE, "Input field and storage fluids are different, but the inputs did not specify a field-to-storage heat exchanger. The system was modeled assuming a heat exchanger.")
            else:
                self.message(TCS_NOTICE, "Input field and storage fluids are identical, but the inputs specified a field-to-storage heat exchanger. The system was modeled assuming no heat exchanger.")
            self.is_hx = is_hx_calc

        self.tshours = self.value(VarIndex.P_tshours)                  # [hr]
        self.eta_pump = self.value(VarIndex.eta_pump)                  # [-]
        self.HDR_rough = self.value(VarIndex.P_hdr_rough)              # [m]
        self.dt_hot = self.value(VarIndex.P_dt_hot)                    # [K]
        self.dt_cold = self.value(VarIndex.P_dt_cold)                  # [K]
        self.hx_config = int(self.value(VarIndex.P_hx_config))         # [-]
        self.q_max_aux = self.value(VarIndex.P_q_max_aux)*1.E6         # [W] convert from [MW]
        self.lhv_eff = self.value(VarIndex.P_lhv_eff)
        self.T_set_aux = self.value(VarIndex.P_T_set_aux)+273.15        # [K] convert from [C]
        self.vol_tank = self.value(VarIndex.P_vol_tank)                # [m3]
        self.h_tank = self.value(VarIndex.P_h_tank)                    # [m]
        self.h_tank_min = self.value(VarIndex.P_h_tank_min)            # [m]
        self.u_tank = self.value(VarIndex.P_u_tank)                    # [W/m2-K]
        self.tank_pairs = int(self.value(VarIndex.P_tank_pairs))       # [-]
        self.cold_tank_Thtr = self.value(VarIndex.P_cold_tank_Thtr)+273.15  # [K]
        self.hot_tank_Thtr = self.value(VarIndex.P_hot_tank_Thtr)+273.15    # [K]
        self.cold_tank_max_heat = self.value(VarIndex.P_cold_tank_max_heat) # [MW]
        self.hot_tank_max_heat = self.value(VarIndex.P_hot_tank_max_heat)   # [MW]
        self.T_field_in_des = self.value(VarIndex.P_T_field_in_des) + 273.15      # [K]
        self.T_field_out_des = self.value(VarIndex.P_T_field_out_des) + 273.15    # [K]
        self.q_pb_design = self.value(VarIndex.P_q_pb_design)*1.E6        # [W]
        self.W_pb_design = self.value(VarIndex.P_W_pb_design)*1.E6        # [W]
        self.cycle_max_frac = self.value(VarIndex.P_cycle_max_frac)        # [-]
        self.cycle_cutoff_frac = self.value(VarIndex.P_cycle_cutoff_frac)  # [-]
        self.solarm = self.value(VarIndex.P_solarm)                        # [-]
        self.pb_pump_coef = self.value(VarIndex.P_pb_pump_coef)            # [kW/kg]
        self.tes_pump_coef = self.value(VarIndex.P_tes_pump_coef)          # [kW/kg]
        self.V_tes_des = self.value(VarIndex.P_V_tes_des)                  # [m/s]
        self.custom_tes_p_loss = bool(self.value(VarIndex.P_custom_tes_p_loss))  # [-]
        self.k_tes_loss_coeffs_in = self.value(VarIndex.P_k_tes_loss_coeffs, self.l_k_tes_loss_coeffs)
        self.k_tes_loss_coeffs.assign(self.k_tes_loss_coeffs_in, self.l_k_tes_loss_coeffs)
        self.custom_sgs_pipe_sizes = bool(self.value(VarIndex.P_custom_sgs_pipe_sizes))
        self.sgs_diams = self.value(VarIndex.P_sgs_diams, self.l_sgs_diams)                   # [m]
        self.sgs_wallthicks = self.value(VarIndex.P_sgs_wallthicks, self.l_sgs_wallthicks)    # [m]
        self.sgs_lengths_in = self.value(VarIndex.P_sgs_lengths, self.l_sgs_lengths)           # [m]
        self.SGS_lengths.assign(self.sgs_lengths_in, self.l_sgs_lengths)
        self.DP_SGS = self.value(VarIndex.P_dp_sgs) * 1.e5                    # bar to Pa
        self.pb_fixed_par = self.value(VarIndex.P_pb_fixed_par)                # [-]
        self.bop_array = self.value(VarIndex.P_bop_array, self.l_bop_array)
        self.aux_array = self.value(VarIndex.P_aux_array, self.l_aux_array)
        self.T_startup = self.value(VarIndex.P_T_startup) + 273.15              # [K]
        self.fossil_mode = int(self.value(VarIndex.P_fossil_mode))              # [-]
        self.fthr_ok = (self.value(VarIndex.P_fthr_ok) != 0)                    # [-]
        self.nSCA = int(self.value(VarIndex.P_nSCA))                            # [-]
        self.I_bn_des = self.value(VarIndex.P_I_bn_des)                         # [W/m2]
        self.fc_on = (self.value(VarIndex.P_fc_on) != 0)                        # [-]
        self.q_sby_frac = self.value(VarIndex.P_q_sby_frac)                     # [-]
        self.t_standby_reset = self.value(VarIndex.P_t_standby_init)*3600        # [s]
        self.sf_type = int(self.value(VarIndex.P_sf_type))                      # [-]
        self.tes_type = int(self.value(VarIndex.P_tes_type))                    # [-]
        var l_tslogic_a: Int
        var l_tslogic_b: Int
        var l_tslogic_c: Int
        var l_ffrac: Int
        self.tslogic_a = self.value(VarIndex.P_tslogic_a, l_tslogic_a)
        self.tslogic_b = self.value(VarIndex.P_tslogic_b, l_tslogic_b)
        self.tslogic_c = self.value(VarIndex.P_tslogic_c, l_tslogic_c)
        self.ffrac = self.value(VarIndex.P_ffrac, l_ffrac)
        if l_tslogic_a != l_tslogic_b or l_tslogic_a != l_tslogic_c or l_tslogic_a != l_ffrac:
            self.message(TCS_ERROR, "Time-of-use schedules do not contain the same number of periods")
            return -1
        self.numtou = l_tslogic_a
        self.tanks_in_parallel = bool(self.value(VarIndex.P_tanks_in_parallel))
        self.has_hot_tank_bypass = bool(self.value(VarIndex.P_hot_tank_bypass))
        self.T_tank_hot_inlet_min = self.value(VarIndex.P_T_tank_hot_in_min) + 273.15
        self.calc_design_pipe_vals = bool(self.value(VarIndex.P_des_pipe_vals))
        self.err_prev_call = -1.
        self.derr_prev_call = -1.
        self.tc_fill = int(self.value(VarIndex.P_tc_fill))                      # [-]
        self.tc_void = self.value(VarIndex.P_tc_void)                           # [-]
        self.t_dis_out_min = self.value(VarIndex.P_t_dis_out_min)               # [C]
        self.t_ch_out_max = self.value(VarIndex.P_t_ch_out_max)                 # [C]
        self.nodes = int(self.value(VarIndex.P_nodes))                          # [-]
        self.f_tc_cold = self.value(VarIndex.P_f_tc_cold)                       # [-]

        self.pb_tech_type = int(self.value(VarIndex.P_PB_TECH_TYPE))
        if self.pb_tech_type != 424:
            var finalize_error_code: Int = self.finalize_initial_calcs()
            if finalize_error_code != 0:
                return -1
            self.initialize_sco2 = False
        else:
            self.initialize_sco2 = True

        return 0

    def finalize_initial_calcs(self) -> Int:
        self.q_sby = self.q_sby_frac * self.q_pb_design
        var duty: Float64 = self.q_pb_design * self.solarm      # mjw 10/13/14
        if self.tshours > 0.0:
            if not self.hx_storage.define_storage(self.field_htfProps, self.store_htfProps, not self.is_hx, self.hx_config, duty, self.vol_tank, self.h_tank, self.u_tank, self.tank_pairs,
                self.hot_tank_Thtr, self.cold_tank_Thtr, self.cold_tank_max_heat, self.hot_tank_max_heat, self.dt_hot, self.dt_cold, self.T_field_out_des, self.T_field_in_des):
                self.message(TCS_ERROR, "Heat exchanger sizing failed")
                return -1
        var c_pb_ref: Float64 = self.field_htfProps.Cp((self.T_field_in_des + self.T_field_out_des) / 2.0)*1000.0   # [J/kg-K] Reference power block specific heat
        self.m_dot_pb_design = self.q_pb_design / (c_pb_ref*(self.T_field_out_des - self.T_field_in_des))            # [kg/s]
        self.m_dot_pb_max = self.cycle_max_frac * self.m_dot_pb_design                                            # [kg/s]
        if self.is_hx:
            self.ms_charge_max = max(self.m_dot_pb_max, duty / (c_pb_ref*(self.T_field_out_des - self.T_field_in_des)))
        else:
            self.ms_charge_max = 999. * self.m_dot_pb_max
        self.ms_disch_max = self.m_dot_pb_max
        self.V_tank_hot_prev = self.value(VarIndex.P_V_tank_hot_ini)                 # [m3]
        self.T_tank_hot_prev = self.value(VarIndex.P_T_tank_hot_ini) + 273.15         # [K]
        self.V_tank_cold_prev = self.vol_tank - self.V_tank_hot_prev                  # [m3]
        self.T_tank_cold_prev = self.value(VarIndex.P_T_tank_cold_ini) + 273.15        # [K]
        self.mode_prev_ncall = 1
        self.m_tank_hot_prev = self.V_tank_hot_prev * self.store_htfProps.dens(self.T_tank_hot_prev, 1.0)
        self.m_tank_cold_prev = self.V_tank_cold_prev * self.store_htfProps.dens(self.T_tank_cold_prev, 1.0)
        self.pb_on_prev = 0
        self.defocus_rel_prev_ncall = 1.
        self.defocus_abs = 1.
        self.defocus_prev_ncall = 1.
        self.defocus_abs_prev = 1.
        self.recirc_prev_ncall = False
        self.t_standby_prev = self.t_standby_reset
        self.V_tank_active = self.vol_tank*(1. - 2.*self.h_tank_min / self.h_tank)
        if self.tanks_in_parallel:
            self.T_pb_in = self.T_field_out_des
        else:
            self.T_pb_in = self.T_tank_hot_prev
        if self.custom_sgs_pipe_sizes:
            if self.l_sgs_diams == self.N_sgs_pipe_sections and self.l_sgs_wallthicks == self.N_sgs_pipe_sections:
                self.SGS_diams.assign(self.sgs_diams, self.l_sgs_diams)
                self.SGS_wall_thk.assign(self.sgs_wallthicks, self.l_sgs_wallthicks)
            else:
                self.message(TCS_ERROR, "The number of custom SGS pipe sections is not correct.")
                return -1
        var rho_avg: Float64 = self.field_htfProps.dens((self.T_field_in_des + self.T_field_out_des) / 2, 9 / 1.e-5)
        var SGS_vol_tot: Float64
        if self.size_sgs_piping(self.V_tes_des, self.SGS_lengths, rho_avg, self.m_dot_pb_design, self.solarm, self.tanks_in_parallel,
            SGS_vol_tot, self.SGS_v_dot_rel, self.SGS_diams, self.SGS_wall_thk, self.SGS_m_dot_des, self.SGS_vel_des, self.custom_sgs_pipe_sizes) != 0:
            self.message(TCS_ERROR, "SGS piping sizing failed.")
            return -1
        self.value(VarIndex.O_V_sgs, SGS_vol_tot)
        var sgs_diams_ptr = self.allocate(VarIndex.O_D_sgs, int(self.SGS_diams.ncells()))
        for i in range(self.SGS_diams.ncells()):
            sgs_diams_ptr[i] = self.SGS_diams.data[i]
        var sgs_wall_thk_ptr = self.allocate(VarIndex.O_wall_thk_sgs, int(self.SGS_wall_thk.ncells()))
        for i in range(self.SGS_wall_thk.ncells()):
            sgs_wall_thk_ptr[i] = self.SGS_wall_thk.data[i