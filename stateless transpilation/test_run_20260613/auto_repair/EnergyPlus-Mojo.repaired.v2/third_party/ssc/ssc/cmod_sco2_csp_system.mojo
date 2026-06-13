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
from core import *
from common import *
from csp_common import vtab_sco2_design, sco2_design_cmod_common, calculate_turbomachinery_outlet_1
from sco2_pc_csp_int import *
from time import now
from math import fabs, floor, min, max, pow
from memory import Pointer, DTypePointer
from random import NAN  # not used, but we use Float64.NAN

// forward declaration
def test_mono_function(x: Float64, y: Pointer[Float64]) -> Int:
    ...

// Matrix class to mimic util::matrix_t<double>
struct Matrix:
    var data: DynamicVector[DynamicVector[Float64]]
    var n_rows: Int
    var n_cols: Int

    def __init__(inout self):
        self.n_rows = 0
        self.n_cols = 0
        self.data = DynamicVector[DynamicVector[Float64]]()

    def __init__(inout self, rows: Int, cols: Int):
        self.n_rows = rows
        self.n_cols = cols
        self.data = DynamicVector[DynamicVector[Float64]](capacity=rows)
        for i in range(rows):
            self.data.push_back(DynamicVector[Float64](capacity=cols, fill=0.0, count=cols))

    def __getitem__(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]

    def __setitem__(inout self, i: Int, j: Int, val: Float64):
        self.data[i][j] = val

    def nrows(self) -> Int:
        return self.n_rows

    def ncols(self) -> Int:
        return self.n_cols

    def resize_fill(inout self, rows: Int, cols: Int, fill_val: Float64):
        self.n_rows = rows
        self.n_cols = cols
        self.data = DynamicVector[DynamicVector[Float64]](capacity=rows)
        for i in range(rows):
            self.data.push_back(DynamicVector[Float64](capacity=cols, fill=fill_val, count=cols))

// var_info struct matching SSC var_info
@value
struct var_info:
    var vartype: Int
    var datatype: Int
    var name: String
    var label: String
    var units: String
    var meta: String
    var group: String
    var required_if: String
    var constraints: String
    var ui_hints: String

// sentinel
var var_info_invalid = var_info(0,0,"","","","","","","","")

static var _cm_vtab_sco2_csp_system: StaticArray[var_info, ...] = [
    var_info(SSC_INPUT,  SSC_NUMBER,  "od_rel_tol",           "Baseline off-design relative convergence tolerance exponent (10^-od_rel_tol)", "-", "High temperature recuperator", "Heat Exchanger Design", "?=3","",       "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,  "od_T_t_in_mode",       "0: model solves co2/HTF PHX od model to calculate turbine inlet temp, 1: model sets turbine inlet temp to HTF hot temp", "", "", "", "?=0", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "od_opt_objective",     "0: find P_LP_in to achieve target power, optimize efficiency 1: find P_LP_in to achieve T_HTF_cold, optimize efficiency", "", "", "", "?=0", "", "" ),
    var_info(SSC_INPUT,  SSC_MATRIX,  "od_cases",             "Columns: 0) T_htf_C, 1) m_dot_htf_ND, 2) T_amb_C,"
                                                               " 3) f_N_rc (=1 use design, =0 optimize, <0, frac_des = abs(input)),"
                                                               " 4) f_N_mc (=1 use design, =0 optimize, <0, frac_des = abs(input)),"
                                                               " 5) f_N_pc (=1 use design, =0 optimize, <0, frac_des = abs(input)),"
                                                               " 6) PHX_f_dP (=1 use design, <0 = abs(input), Rows: cases", "", "", "", "", "", "" ),
	var_info(SSC_INPUT,  SSC_ARRAY,   "od_P_mc_in_sweep",     "Columns: 0) T_htf_C, 1) m_dot_htf_ND, 2) T_amb_C,"
                                                               " 3) T_mc_in_C, 4) T_pc_in_C,"
                                                               " 5) f_N_rc (=1 use design, <0, frac_des = abs(input),"
                                                               " 6) f_N_mc (=1 use design, <0, frac_des = abs(input),"
                                                               " 7) f_N_pc (=1 use design, =0 optimize, <0, frac_des = abs(input)),"
                                                               " 8) PHX_f_dP (=1 use design, <0 = abs(input)", "", "", "", "",  "", "" ),
    var_info(SSC_INPUT,  SSC_ARRAY,   "od_T_mc_in_sweep",     "Columns: 0) T_htf_C, 1) m_dot_htf_ND, 2) T_amb_C,"
                                                               "3) f_N_rc (=1 use design, <0, frac_des = abs(input),"
                                                               "4) f_N_mc (=1 use design, <0, frac_des = abs(input),"
                                                               "5) f_N_pc (=1 use design, <0, frac_des = abs(input),"
                                                               "6) PHX_f_dP (=1 use design, <0 = abs(input)", "", "", "", "",  "", "" ),
    var_info(SSC_INPUT,  SSC_MATRIX,  "od_max_htf_m_dot",     "Columns: T_htf_C, T_amb_C, f_N_rc (=1 use design, <0, frac_des = abs(input), f_N_mc (=1 use design, <0, frac_des = abs(input), PHX_f_dP (=1 use design, <0 = abs(input), Rows: cases", "", "", "", "",  "", "" ),
	var_info(SSC_INPUT,  SSC_MATRIX,  "od_set_control",       "Columns: 0) T_htf_C, 1) m_dot_htf_ND, 2) T_amb_C,"
                                                               " 3) P_LP_in_MPa, 4) T_mc_in_C, 5) T_pc_in_C,"
                                                               " 6) f_N_rc (=1 use design, <0, frac_des = abs(input),"
                                                               " 7) f_N_mc (=1 use design, <0, frac_des = abs(input),"
                                                               " 8) f_N_pc (=1 use design, =0 optimize, <0, frac_des = abs(input)),"
                                                               " 9) PHX_f_dP (=1 use design, <0 = abs(input), Rows: cases", "", "", "", "", "", "" ),
    var_info(SSC_INPUT,  SSC_ARRAY,   "od_generate_udpc",     "True/False, f_N_rc (=1 use design, =0 optimize, <0, frac_des = abs(input), f_N_mc (=1 use design, =0 optimize, <0, frac_des = abs(input), PHX_f_dP (=1 use design, <0 = abs(input)", "", "", "", "",  "", "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,  "is_gen_od_polynomials","Generate off-design polynomials for Generic CSP models? 1 = Yes, 0 = No", "", "", "",  "?=0",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "m_dot_htf_fracs",      "Normalized mass flow rate",                              "",           "Off-Design",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_amb_od",             "Ambient temperatures",                                   "C",          "Off-Design",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_htf_hot_od",         "HTF hot temperatures",                                   "C",          "Off-Design",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "P_comp_in_od",         "Main compressor inlet pressures",                        "MPa",        "Off-Design Cycle Control",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "mc_phi_od",            "Off-design main compressor flow coefficient [od run][stage]", "",      "Off-Design Cycle Control",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "recomp_frac_od",       "Recompression fractions",                                "",           "Off-Design Cycle Control",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "sim_time_od",          "Simulation time for off design optimization",            "s",          "Off-Design Optimizer",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "eta_thermal_od",       "Off-design cycle thermal efficiency",                    "",           "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_mc_in_od",           "Off-design compressor inlet temperature",                "C",          "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "P_mc_out_od",          "Off-design high side pressure",                          "MPa",        "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_htf_cold_od",        "Off-design cold return temperature",                     "C",          "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "m_dot_co2_full_od",    "Off-design mass flow rate through turbine",              "kg/s",       "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "W_dot_net_od",         "Off-design cycle net output (no cooling pars)",          "MWe",        "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "Q_dot_od",             "Off-design thermal input",                               "MWt",        "Off-Design System Solution",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "W_dot_net_less_cooling_od", "Off-design system output subtracting cooling parastics","MWe",    "Off-Design System Solution",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "eta_thermal_net_less_cooling_od","Calculated cycle thermal efficiency using W_dot_net_less_cooling", "-", "Off-Design System Solution","", "",   "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_T_out_od",          "Off-design main compressor outlet temperature",          "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_W_dot_od",          "Off-design main compressor power",                       "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_m_dot_od",          "Off-design main compressor mass flow",                   "kg/s",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_rho_in_od",         "Off-design main compressor inlet density",               "kg/m3",      "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "mc_psi_od",            "Off-design main compressor ideal head coefficient [od run][stage]","", "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_ideal_spec_work_od","Off-design main compressor ideal specific work",         "kJ/kg",      "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_N_od",              "Off-design main compressor speed",                       "rpm",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_N_od_perc",         "Off-design main compressor speed relative to design",    "%",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_eta_od",            "Off-design main compressor overall isentropic efficiency", "",         "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "mc_tip_ratio_od",      "Off-design main compressor tip speed ratio [od run][stage]", "",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "mc_eta_stages_od",     "Off-design main compressor stages isentropic efficiency [od run][stage]", "", "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_f_bypass_od",       "Off-design main compressor bypass to cooler inlet",      "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_T_in_od",           "Off-design recompressor inlet temperature",              "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_P_in_od",           "Off-design recompressor inlet pressure",                 "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_T_out_od",          "Off-design recompressor outlet temperature",             "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_P_out_od",          "Off-design recompressor outlet pressure",                "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_W_dot_od",          "Off-design recompressor power",                          "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_m_dot_od",          "Off-design recompressor mass flow",                      "kg/s",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_eta_od",            "Off-design recompressor overal isentropic efficiency",   "",           "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "rc_phi_od",            "Off-design recompressor flow coefficients [od run][stage]", "-",	   "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "rc_psi_od",            "Off-design recompressor ideal head coefficient [od run][stage]", "-",  "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_N_od",              "Off-design recompressor shaft speed",                    "rpm",		   "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "rc_N_od_perc",         "Off-design recompressor shaft speed relative to design", "%",		   "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "rc_tip_ratio_od",      "Off-design recompressor tip speed ratio [od run][stage]","-",		   "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "rc_eta_stages_od",     "Off-design recompressor stages isentropic efficiency [od run][stage]", "",    "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_T_in_od",           "Off-design precompressor inlet temperature",             "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_P_in_od",           "Off-design precompressor inlet pressure",                "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_W_dot_od",          "Off-design precompressor power",                         "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_m_dot_od",          "Off-design precompressor mass flow",                     "kg/s",       "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_rho_in_od",         "Off-design precompressor inlet density",                 "kg/m3",      "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_ideal_spec_work_od","Off-design precompressor ideal spec work",               "kJ/kg",      "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_eta_od",            "Off-design precompressor overal isentropic efficiency",  "",           "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "pc_phi_od",            "Off-design precompressor flow coefficient [od run][stage]", "-",	   "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_N_od",              "Off-design precompressor shaft speed",                   "rpm",		   "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "pc_tip_ratio_od",      "Off-design precompressor tip speed ratio [od run][stage]","-",		   "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_MATRIX,  "pc_eta_stages_od",     "Off-design precompressor stages isentropic efficiency [od run][stage]", "",    "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_f_bypass_od",       "Off-design precompressor bypass to cooler inlet",        "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "c_tot_W_dot_od",       "Compressor total off-design power",                      "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_P_in_od",            "Off-design turbine inlet pressure",                      "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_T_out_od",           "Off-design turbine outlet temperature",                  "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_P_out_od",           "Off-design turbine outlet pressure",                     "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_W_dot_od",           "Off-design turbine power",                               "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_m_dot_od",           "Off-design turbine mass flow rate",                      "kg/s",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_delta_h_isen_od",    "Off-design turbine isentropic specific work",            "kg/s",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_rho_in_od",          "Off-design turbine inlet density",                       "kg/m3",      "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_nu_od",              "Off-design turbine velocity ratio",	                     "-",	       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_N_od",               "Off-design turbine shaft speed",	                     "rpm",	       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_tip_ratio_od",       "Off-design turbine tip speed ratio",                     "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "t_eta_od",             "Off-design turbine efficiency",                          "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "LTR_HP_T_out_od",      "Off-design low temp recup HP outlet temperature",        "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "eff_LTR_od",           "Off-design low temp recup effectiveness",                "",           "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "q_dot_LTR_od",         "Off-design low temp recup heat transfer",                "MWt",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "LTR_LP_deltaP_od",     "Off-design low temp recup low pressure side pressure drop","-",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "LTR_HP_deltaP_od",     "Off-design low temp recup high pressure side pressure drop","-",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "LTR_min_dT_od",        "Off-design low temp recup minimum temperature difference","C",         "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "HTR_LP_T_out_od",      "Off-design high temp recup LP outlet temperature",       "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "HTR_HP_T_in_od",       "Off-design high temp recup HP inlet temperature",        "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "eff_HTR_od",           "Off-design high temp recup effectiveness",               "",           "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "q_dot_HTR_od",         "Off-design high temp recup heat transfer",               "MWt",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "HTR_LP_deltaP_od",     "Off-design high temp recup low pressure side pressure drop","-",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "HTR_HP_deltaP_od",     "Off-design high temp recup high pressure side pressure drop","-",       "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "HTR_min_dT_od",        "Off-design high temp recup minimum temperature difference","C",         "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_co2_PHX_in_od",      "Off-design PHX co2 inlet temperature",                   "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "P_co2_PHX_in_od",      "Off-design PHX co2 inlet pressure",                      "MPa",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_co2_PHX_out_od",     "Off-design PHX co2 outlet temperature",                  "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "deltaT_HTF_PHX_od",    "Off-design HTF temp difference across PHX",              "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "phx_eff_od",           "Off-design PHX effectiveness",                           "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "phx_co2_deltaP_od",    "Off-design PHX co2 side pressure drop",                  "-",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_cooler_T_in_od",    "Off-design Low pressure cooler inlet temperature",                  "C",          "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_cooler_rho_in_od",  "Off-design Low pressure cooler inlet density",                      "kg/m3",      "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_cooler_in_isen_deltah_to_P_mc_out_od",  "Off-design Low pressure cooler inlet isen enthalpy rise to mc outlet pressure", "kJ/kg", "", "", "", "", "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_cooler_co2_deltaP_od", "Off-design Off-design low pressure cooler co2 side pressure drop","-",         "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "mc_cooler_W_dot_fan_od","Off-design Low pressure cooler fan power",                         "MWe",        "",    "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "pc_cooler_W_dot_fan_od","Off-design Intermediate pressure cooler fan power",                "MWe",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "cooler_tot_W_dot_fan_od","Intermediate pressure cooler fan power",               "MWe",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "diff_m_dot_od",          "Off-design mass flow rate balance",        "-",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "diff_E_cycle",           "Off-design cycle energy balance",          "-",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "diff_Q_LTR",             "Off-design LTR energy balance",            "-",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,   "diff_Q_HTR",             "Off-design HTR energy balance",            "-",        "",    "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "udpc_table",  "Columns (7): HTF Temp [C], HTF ND mass flow [-], Ambient Temp [C], ND Power, ND Heat In, ND Fan Power, ND Water. Rows = runs" "", "", "", "", "", "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "udpc_n_T_htf",         "Number of HTF temperature values in udpc parametric",    "",          "",     "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "udpc_n_T_amb",         "Number of ambient temperature values in udpc parametric","",          "",     "",      "",     "",       "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "udpc_n_m_dot_htf",     "Number of HTF mass flow rate values in udpc parameteric","",          "",     "",      "",     "",       "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "od_code",              "Diagnostic info",                                        "-",          ""     "",      "",     "",       "" ),
	var_info_invalid
]

class cm_sco2_csp_system(compute_module):
    var p_m_dot_htf_fracs: Pointer[Float64]
    var p_T_amb_od: Pointer[Float64]
    var p_T_htf_hot_od: Pointer[Float64]
    var p_P_comp_in_od: Pointer[Float64]
    var pm_mc_phi_od: Pointer[Float64]
    var p_recomp_frac_od: Pointer[Float64]
    var p_sim_time_od: Pointer[Float64]
    var p_eta_thermal_od: Pointer[Float64]
    var p_T_mc_in_od: Pointer[Float64]
    var p_P_mc_out_od: Pointer[Float64]
    var p_T_htf_cold_od: Pointer[Float64]
    var p_m_dot_co2_full_od: Pointer[Float64]
    var p_W_dot_net_od: Pointer[Float64]
    var p_Q_dot_od: Pointer[Float64]
    var p_eta_thermal_net_less_cooling_od: Pointer[Float64]
    var p_mc_T_out_od: Pointer[Float64]
    var p_mc_W_dot_od: Pointer[Float64]
    var p_mc_m_dot_od: Pointer[Float64]
    var p_mc_rho_in_od: Pointer[Float64]
    var pm_mc_psi_od: Pointer[Float64]
    var p_mc_ideal_spec_work_od: Pointer[Float64]
    var p_mc_N_od: Pointer[Float64]
    var p_mc_N_od_perc: Pointer[Float64]
    var p_mc_eta_od: Pointer[Float64]
    var pm_mc_tip_ratio_od: Pointer[Float64]
    var pm_mc_eta_stages_od: Pointer[Float64]
    var p_mc_f_bypass_od: Pointer[Float64]
    var p_rc_T_in_od: Pointer[Float64]
    var p_rc_P_in_od: Pointer[Float64]
    var p_rc_T_out_od: Pointer[Float64]
    var p_rc_P_out_od: Pointer[Float64]
    var p_rc_W_dot_od: Pointer[Float64]
    var p_rc_m_dot_od: Pointer[Float64]
    var p_rc_eta_od: Pointer[Float64]
    var pm_rc_phi_od: Pointer[Float64]
    var pm_rc_psi_od: Pointer[Float64]
    var p_rc_N_od: Pointer[Float64]
    var p_rc_N_od_perc: Pointer[Float64]
    var pm_rc_tip_ratio_od: Pointer[Float64]
    var pm_rc_eta_stages_od: Pointer[Float64]
    var p_pc_T_in_od: Pointer[Float64]
    var p_pc_P_in_od: Pointer[Float64]
    var p_pc_W_dot_od: Pointer[Float64]
    var p_pc_m_dot_od: Pointer[Float64]
    var p_pc_rho_in_od: Pointer[Float64]
    var p_pc_ideal_spec_work_od: Pointer[Float64]
    var p_pc_eta_od: Pointer[Float64]
    var pm_pc_phi_od: Pointer[Float64]
    var p_pc_N_od: Pointer[Float64]
    var pm_pc_tip_ratio_od: Pointer[Float64]
    var pm_pc_eta_stages_od: Pointer[Float64]
    var p_pc_f_bypass_od: Pointer[Float64]
    var p_c_tot_W_dot_od: Pointer[Float64]
    var p_t_P_in_od: Pointer[Float64]
    var p_t_T_out_od: Pointer[Float64]
    var p_t_P_out_od: Pointer[Float64]
    var p_t_W_dot_od: Pointer[Float64]
    var p_t_m_dot_od: Pointer[Float64]
    var p_t_delta_h_isen_od: Pointer[Float64]
    var p_t_rho_in_od: Pointer[Float64]
    var p_t_nu_od: Pointer[Float64]
    var p_t_N_od: Pointer[Float64]
    var p_t_tip_ratio_od: Pointer[Float64]
    var p_t_eta_od: Pointer[Float64]
    var p_LTR_HP_T_out_od: Pointer[Float64]
    var p_eff_LTR_od: Pointer[Float64]
    var p_q_dot_LTR_od: Pointer[Float64]
    var p_LTR_LP_deltaP_od: Pointer[Float64]
    var p_LTR_HP_deltaP_od: Pointer[Float64]
    var p_LTR_min_dT_od: Pointer[Float64]
    var p_HTR_LP_T_out_od: Pointer[Float64]
    var p_HTR_HP_T_in_od: Pointer[Float64]
    var p_eff_HTR_od: Pointer[Float64]
    var p_q_dot_HTR_od: Pointer[Float64]
    var p_HTR_LP_deltaP_od: Pointer[Float64]
    var p_HTR_HP_deltaP_od: Pointer[Float64]
    var p_HTR_min_dT_od: Pointer[Float64]
    var p_T_co2_PHX_in_od: Pointer[Float64]
    var p_P_co2_PHX_in_od: Pointer[Float64]
    var p_T_co2_PHX_out_od: Pointer[Float64]
    var p_deltaT_HTF_PHX_od: Pointer[Float64]
    var p_phx_eff_od: Pointer[Float64]
    var p_phx_co2_deltaP_od: Pointer[Float64]
    var p_mc_cooler_T_in_od: Pointer[Float64]
    var p_mc_cooler_rho_in_od: Pointer[Float64]
    var p_mc_cooler_in_isen_deltah_to_P_mc_out_od: Pointer[Float64]
    var p_mc_cooler_co2_deltaP_od: Pointer[Float64]
    var p_mc_cooler_W_dot_fan_od: Pointer[Float64]
    var p_W_dot_net_less_cooling_od: Pointer[Float64]
    var p_pc_cooler_W_dot_fan_od: Pointer[Float64]
    var p_cooler_tot_W_dot_fan_od: Pointer[Float64]
    var p_diff_m_dot_od: Pointer[Float64]
    var p_diff_E_cycle: Pointer[Float64]
    var p_diff_Q_LTR: Pointer[Float64]
    var p_diff_Q_HTR: Pointer[Float64]
    var pm_udpc_table: Pointer[Float64]
    var p_od_code: Pointer[Float64]

    def __init__(inout self):
        self.add_var_info(vtab_sco2_design)
        self.add_var_info(_cm_vtab_sco2_csp_system)

    def exec(inout self) raises:
        var c_sco2_cycle = C_sco2_phx_air_cooler()
        var sco2_des_err = sco2_design_cmod_common(self, c_sco2_cycle)
        if sco2_des_err != 0:
            return
        var m_dot_htf_design = c_sco2_cycle.get_phx_des_par().m_m_dot_hot_des  # [kg/s]
        var is_rc = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_is_rc
        var n_mc_stages = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_n_stages
        var n_rc_stages: Int = 1
        if is_rc:
            n_rc_stages = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_n_stages  # [-]
        var cycle_config = c_sco2_cycle.get_design_par().m_cycle_config
        var n_pc_stages: Int = 1
        if cycle_config == 2:
            n_pc_stages = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_n_stages  # [-]
        var is_od_cases_assigned = self.is_assigned("od_cases")
        var is_P_mc_in_od_sweep_assigned = self.is_assigned("od_P_mc_in_sweep")
        var is_od_T_mc_in_sweep_assigned = self.is_assigned("od_T_mc_in_sweep")
        var is_od_max_htf_m_dot_assigned = self.is_assigned("od_max_htf_m_dot")
        var is_od_set_control = self.is_assigned("od_set_control")
        var is_od_generate_udpc_assigned = self.is_assigned("od_generate_udpc")
        if is_od_cases_assigned and is_P_mc_in_od_sweep_assigned:
            self.log("Both off design cases and main compressor inlet pressure sweep assigned. Only modeling off design cases")
            is_P_mc_in_od_sweep_assigned = False
        if is_od_cases_assigned and is_od_T_mc_in_sweep_assigned:
            self.log("Both off design cases and main compressor inlet temperature sweep assigned. Only modeling off design cases")
            is_od_T_mc_in_sweep_assigned = False
        if is_od_cases_assigned and is_od_max_htf_m_dot_assigned:
            self.log("Both off design cases and 'od_max_htf_m_dot' assigned. Only modeling off design cases")
            is_od_max_htf_m_dot_assigned = False
        if is_od_cases_assigned and is_od_set_control:
            self.log("Both off design cases and od set control assigned. Only modeling off design cases")
            is_od_set_control = False
        if is_od_cases_assigned and is_od_generate_udpc_assigned:
            self.log("Both 'od_cases' and 'od_generate_udpc' were assigned. Only modeling 'od_cases'")
            is_od_generate_udpc_assigned = False
        if is_P_mc_in_od_sweep_assigned and is_od_T_mc_in_sweep_assigned:
            self.log("Both main compressor inlet sweep and is_od_T_mc_in_sweep assigned. Only modeling off design cases")
            is_od_T_mc_in_sweep_assigned = False
        if is_P_mc_in_od_sweep_assigned and is_od_max_htf_m_dot_assigned:
            self.log("Both main compressor inlet sweep and 'od_max_htf_m_dot' assigned. Only modeling off design cases")
            is_od_max_htf_m_dot_assigned = False
        if is_P_mc_in_od_sweep_assigned and is_od_set_control:
            self.log("Both main compressor inlet sweep and od set control assigned. Only modeling off design cases")
            is_od_set_control = False
        if is_P_mc_in_od_sweep_assigned and is_od_generate_udpc_assigned:
            self.log("Both 'od_P_mc_in_sweep' and 'od_generate_udpc' were assigned. Only modeling 'od_P_mc_in_sweep'")
            is_od_generate_udpc_assigned = False
        if is_od_T_mc_in_sweep_assigned and is_od_max_htf_m_dot_assigned:
            self.log("Both is_od_T_mc_in_sweep and od set 'od_max_htf_m_dot' assigned. Only modeling od_T_mc_in_sweep")
            is_od_max_htf_m_dot_assigned = False
        if is_od_T_mc_in_sweep_assigned and is_od_set_control:
            self.log("Both is_od_T_mc_in_sweep and od set control assigned. Only modeling od_T_mc_in_sweep")
            is_od_set_control = False
        if is_od_T_mc_in_sweep_assigned and is_od_generate_udpc_assigned:
            self.log("Both 'od_T_mc_in_sweep' and 'od_generate_udpc' were assigned. Only modeling 'od_T_mc_in_sweep'")
            is_od_generate_udpc_assigned = False
        if is_od_max_htf_m_dot_assigned and is_od_set_control:
            self.log("Both 'od_max_htf_m_dot' and od set control assigned. Only modeling 'od_max_htf_m_dot'")
            is_od_set_control = False
        if is_od_max_htf_m_dot_assigned and is_od_generate_udpc_assigned:
            self.log("Both 'od_max_htf_m_dot' and 'od_generate_udpc' were assigned. Only modeling 'od_max_htf_m_dot'")
            is_od_generate_udpc_assigned = False
        if is_od_set_control and is_od_generate_udpc_assigned:
            self.log("Both 'od_set_control' and 'od_generate_udpc' were assigned. Only modeling 'od_set_control'")
            is_od_generate_udpc_assigned = False
        if not is_od_cases_assigned and not is_P_mc_in_od_sweep_assigned and not is_od_set_control and not is_od_generate_udpc_assigned and not is_od_T_mc_in_sweep_assigned and not is_od_max_htf_m_dot_assigned:
            self.log("No off-design cases or main compressor inlet sweep specified")
            return
        var P_LP_comp_in_des: Float64 = Float64.NAN  # [MPa]
        var delta_P: Float64 = Float64.NAN
        if cycle_config == 1:
            P_LP_comp_in_des = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_IN] / 1000.0  # [MPa] convert from kPa
            delta_P = 10.0
        else:
            P_LP_comp_in_des = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.PC_IN] / 1000.0  # [MPa] convert from kPa
            delta_P = 6.0
        var T_t_in_mode = self.as_integer("od_T_t_in_mode")
        var T_htf_hot_des = c_sco2_cycle.get_design_par().m_T_htf_hot_in  # [K]
        var T_amb_des = c_sco2_cycle.get_design_par().m_T_amb_des  # [K]
        var T_t_in_des = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.TURB_IN]  # [K]
        var T_co2_PHX_in_des = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.HTR_HP_OUT]  # [K]
        var T_htf_PHX_out_des = c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_T_h_out  # [K]
        var od_strategy_in = self.as_integer("od_opt_objective")
        var od_strategy: C_sco2_phx_air_cooler.E_off_design_strategies = C_sco2_phx_air_cooler.E_off_design_strategies(od_strategy_in)
        od_strategy = C_sco2_phx_air_cooler.E_TARGET_T_HTF_COLD_POWER_MAX
        var od_cases = Matrix()
        if is_od_cases_assigned:
            var od_cases_local = self.as_matrix("od_cases")
            var n_od_cols_loc = Int(od_cases_local.ncols())
            var n_od_runs_loc = Int(od_cases_local.nrows())
            if n_od_cols_loc < 3 and n_od_runs_loc == 1:
                self.log("No off-design cases specified")
                return
            elif n_od_cols_loc < 3:
                var err_msg = String.format("The matrix of off design cases requires at least 3 columns. The entered matrix has {} columns", n_od_cols_loc)
                raise exec_error("sco2_csp_system", err_msg)
            elif n_od_cols_loc < 7:
                od_cases.resize_fill(n_od_runs_loc, 7, 1.0)
                for i in range(n_od_runs_loc):
                    for j in range(n_od_cols_loc):
                        od_cases[i, j] = od_cases_local[i, j]
            else:
                od_cases = od_cases_local
        elif is_P_mc_in_od_sweep_assigned:
            var od_case = self.as_vector_double("od_P_mc_in_sweep")
            var n_od = od_case.size()
            if n_od < 5:
                var err_msg = String.format("The matrix of off design cases requires at least 5 columns. The entered matrix has {} columns", n_od)
                raise exec_error("sco2_csp_system", err_msg)
            var n_P_mc_in: Int = 101
            var P_mc_in_low = P_LP_comp_in_des - delta_P / 2.0  # [MPa]
            var delta_P_i = delta_P / Float64(n_P_mc_in - 1)  # [MPa]
            od_cases.resize_fill(n_P_mc_in, 10, 1.0)
            var n_cols_in = min(Int(n_od), 9)
            for i in range(n_P_mc_in):
                for j in range(n_cols_in):
                    od_cases[i, j] = od_case[j]
                od_cases[i, 9] = P_mc_in_low + delta_P_i * Float64(i)  # [MPa]
        elif is_od_T_mc_in_sweep_assigned:
            var od_case_local = self.as_vector_double("od_T_mc_in_sweep")
            var n_od = od_case_local.size()
            if n_od < 3:
                var err_msg = String.format("od_T_mc_in_sweep requires at least 3 columns. The entered value has {} columns", n_od)
                raise exec_error("sco2_csp_system", err_msg)
            var range_T_mc_in: Float64 = 30.0  # [C]
            var delta_T_mc_in: Float64 = 0.5  # [C]
            var T_mc_in_start = od_case_local[2] + 0.5  # [C]
            var n_T_mc_in = floor(range_T_mc_in / delta_T_mc_in + 0.5) + 1  # [-]
            od_cases.resize_fill(Int(n_T_mc_in), 8, 1.0)
            var n_cols_in = min(Int(n_od), 7)
            for i in range(Int(n_T_mc_in)):
                for j in range(n_cols_in):
                    od_cases[i, j] = od_case_local[j]
                od_cases[i, 7] = (T_mc_in_start + delta_T_mc_in * Float64(i)) + 273.15  # [K] convert from C
        elif is_od_max_htf_m_dot_assigned:
            var od_cases_local = self.as_matrix("od_max_htf_m_dot")
            var n_od_cols_loc = Int(od_cases_local.ncols())
            var n_od_runs_loc = Int(od_cases_local.nrows())
            if n_od_cols_loc < 2 and n_od_runs_loc == 1:
                self.log("No od_max_htf_m_dot cases specified")
                return
            elif n_od_cols_loc < 2:
                var err_msg = String.format("The od_max_htf_m_dot matrix requires at least 2 columns. The entered matrix has {} columns", n_od_cols_loc)
                raise exec_error("sco2_csp_system", err_msg)
            od_cases.resize_fill(n_od_runs_loc, 6, 1.0)
            for i in range(n_od_runs_loc):
                for j in range(1):
                    od_cases[i, j] = od_cases_local[i, j]
                for j in range(1, n_od_cols_loc):
                    od_cases[i, j+1] = od_cases_local[i, j]
        elif is_od_set_control:
            var od_cases_local = self.as_matrix("od_set_control")
            var n_od_cols_loc = Int(od_cases_local.ncols())
            var n_od_runs_loc = Int(od_cases_local.nrows())
            if n_od_cols_loc < 6:
                var err_msg = String.format("The matrix of od set control requires at least 6 columns. The entered matrix has {} columns", n_od_cols_loc)
                raise exec_error("sco2_csp_system", err_msg)
            elif n_od_cols_loc < 10:
                od_cases.resize_fill(n_od_runs_loc, 10, 1.0)
                for i in range(n_od_runs_loc):
                    for j in range(n_od_cols_loc):
                        od_cases[i, j] = od_cases_local[i, j]
            else:
                od_cases = od_cases_local
        elif is_od_generate_udpc_assigned:
            if self.as_integer("od_T_t_in_mode") == 1:
                T_htf_hot_des = T_t_in_des  # [K]
            var m_dot_htf_ND_low: Float64 = 0.5  # [-]
            var m_dot_htf_ND_high: Float64 = 1.05  # [-]
            var n_m_dot_htf_ND: Int = 12
            var T_htf_delta_cold: Float64 = 30.0  # [K--C]
            var T_htf_delta_hot: Float64 = 15.0  # [K--C]
            var n_T_htf_hot: Int = 4
            var T_amb_low: Float64 = 273.15 + 0.0  # [K]
            var T_amb_high: Float64 = max(273.15 + 45.0, T_amb_des + 5.0)  # [K]
            var n_T_amb = Int(T_amb_high - T_amb_low + 1)
            var udpc_pars = self.as_vector_double("od_generate_udpc")
            var n_udpc_pars = udpc_pars.size()
            var n_od_cases_mode_pars = min(3, n_udpc_pars - 1)
            self.assign("udpc_n_m_dot_htf", Float64(n_m_dot_htf_ND))
            var m_dot_htf_ND_des: Float64 = 1.0  # [-]
            var m_dot_htf_ND_par_start = m_dot_htf_ND_low  # m_dot_htf_ND_low - 0.05; [-]
            var m_dot_htf_ND_par_end = m_dot_htf_ND_high  # m_dot_htf_ND_high + 0.05; [-]
            var delta_m_dot_htf_ND = (m_dot_htf_ND_par_end - m_dot_htf_ND_par_start) / Float64(n_m_dot_htf_ND - 1)
            var m_dot_htf_ND_levels = DynamicVector[Float64](3)
            m_dot_htf_ND_levels[0] = m_dot_htf_ND_low
            m_dot_htf_ND_levels[1] = m_dot_htf_ND_des
            m_dot_htf_ND_levels[2] = m_dot_htf_ND_high
            var T_htf_low = T_htf_hot_des - T_htf_delta_cold  # [K]
            var T_htf_high = T_htf_hot_des + T_htf_delta_hot  # [K]
            self.assign("udpc_n_T_htf", Float64(n_T_htf_hot))
            var T_htf_par_start = T_htf_low  # T_htf_low - 5.0; [K]
            var T_htf_par_end = T_htf_high  # T_htf_high + 5.0; [K]
            var delta_T_htf_hot = (T_htf_par_end - T_htf_par_start) / Float64(n_T_htf_hot - 1)
            var