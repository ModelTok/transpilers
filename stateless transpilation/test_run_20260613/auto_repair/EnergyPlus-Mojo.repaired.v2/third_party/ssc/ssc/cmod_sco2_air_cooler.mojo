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

from core import (
    compute_module,
    var_info,
    SSC_INPUT,
    SSC_OUTPUT,
    SSC_NUMBER,
    SSC_MATRIX,
    SSC_ARRAY,
    SSC_ERROR,
    var_info_invalid,
    ssc_number_t,
)
from heat_exchangers import (
    C_CO2_to_air_cooler,
    C_csp_exception,
)
from util import matrix_t
from builtin import Pointer, Float64, Int, String

alias ssc_number_t = Float64

var _cm_vtab_sco2_air_cooler: List[var_info] = List[
    /*   VARTYPE   DATATYPE         NAME               LABEL                                      UNITS  META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS*/
    var_info(SSC_INPUT,  SSC_MATRIX,   "od_calc_W_dot_fan",  "Columns: T_co2_hot_C, P_co2_hot_MPa, T_co2_cold_C, m_dot_CO2_ND, T_amb_C. Rows: cases", "", "", "", "", "", "" ),
    var_info(SSC_INPUT,  SSC_MATRIX,   "od_calc_T_co2_cold", "Columns: T_co2_hot_C, P_co2_hot_MPa, W_dot_fan_ND, m_dot_CO2_ND, T_amb_C. Rows: cases", "", "", "", "", "", "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "T_amb_od",          "Off-design ambient temperature",           "C",   "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "T_co2_hot_od",      "Off-design co2 hot inlet temperature",     "C",   "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "P_co2_hot_od",      "Off-design co2 hot inlet pressure",        "MPa", "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "T_co2_cold_od",     "Off-design co2 cold outlet temperature",   "C",   "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "P_co2_cold_od",     "Off-design co2 cold outlet pressure",      "MPa", "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "deltaP_co2_od",     "Off-design co2 cold pressure drop",        "MPa", "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "m_dot_co2_od_ND",   "Off-design co2 mass flow normalized design","-",  "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "W_dot_fan_od",      "Off-design fan power",                     "MWe", "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "W_dot_fan_od_ND",   "Off-design fan power normalized v design", "-",   "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "q_dot_od",          "Off-design heat rejection",                "MWt", "", "",  "", "",  "" ),
    var_info(SSC_OUTPUT, SSC_ARRAY,    "q_dot_od_ND",       "Off-design heat rejection normalized design","-", "", "",  "", "",  "" ),
    var_info_invalid
]

var vtab_sco2_air_cooler_design: List[var_info] = List[
    /*   VARTYPE   DATATYPE         NAME               LABEL                                      UNITS  META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS*/
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_amb_des",         "Ambient temperature at design",              "C",    "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "q_dot_des",		    "Heat rejected from CO2 stream",			  "MWt",  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_co2_hot_des",		"Hot temperature of CO2 at inlet to cooler",  "C",	  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "P_co2_hot_des",		"Pressure of CO2 at inlet to cooler",		  "MPa",  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "deltaP_co2_des",	"Pressure drop of CO2 through cooler",		  "MPa",  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_co2_cold_des",	"Cold temperature of CO2 at cooler exit",	  "C",	  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "W_dot_fan_des",	    "Air fan power",							  "MWe",  "",  "", "*", "", ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "site_elevation",	"Site elevation",							  "m",	  "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "d_tube_out",        "CO2 tube outer diameter",                    "cm",   "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "d_tube_in",         "CO2 tube inner diameter",                    "cm",   "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "depth_footprint",   "Dimension of total air cooler in loop/air flow direction",  "m",  "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "width_footprint",   "Dimension of total air cooler of parallel loops",           "m",  "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "parallel_paths",    "Number of parallel flow paths",              "-",    "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "number_of_tubes",   "Number of tubes (one pass)",                 "-",    "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "length",            "Length of tube (one pass)",                  "m",    "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "n_passes_series",   "Number of serial tubes in flow path",        "-",    "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "UA_total",          "Total air-side conductance",                 "kW/K", "",  "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "m_V_hx_material",   "Total hx material volume - no headers",      "m^3",  "",  "", "*", "", ""),
    var_info_invalid
]

def sco2_air_cooler_design_common(inout cm: compute_module, inout c_air_cooler: C_CO2_to_air_cooler) -> Int:
    var s_air_cooler_des_par_cycle: C_CO2_to_air_cooler.S_des_par_cycle_dep
    var s_air_cooler_des_par_ambient: C_CO2_to_air_cooler.S_des_par_ind
    s_air_cooler_des_par_ambient.m_T_amb_des = cm.as_double("T_amb_des") + 273.15		//[K]
    s_air_cooler_des_par_ambient.m_elev = cm.as_double("site_elevation")			//[m]
    s_air_cooler_des_par_cycle.m_Q_dot_des = cm.as_double("q_dot_des")			//[MWt]
    s_air_cooler_des_par_cycle.m_T_hot_in_des = cm.as_double("T_co2_hot_des") + 273.15		//[K] convert from C
    s_air_cooler_des_par_cycle.m_P_hot_in_des = cm.as_double("P_co2_hot_des")*1.E3			//[MPa] convert from MPa
    s_air_cooler_des_par_cycle.m_T_hot_out_des = cm.as_double("T_co2_cold_des") + 273.15	//[K] convert from C
    s_air_cooler_des_par_cycle.m_delta_P_des = cm.as_double("deltaP_co2_des")*1.E3				//[MPa] convert from MPa
    s_air_cooler_des_par_cycle.m_W_dot_fan_des = cm.as_double("W_dot_fan_des")		//[MWe]
    s_air_cooler_des_par_ambient.m_eta_fan = 0.5
    s_air_cooler_des_par_ambient.m_N_nodes_pass = 10
    var out_type: Int = -1
    var out_msg: String = ""
    try:
        c_air_cooler.design_hx(s_air_cooler_des_par_ambient, s_air_cooler_des_par_cycle, 1.E-3)
    except C_csp_exception as csp_exception:
        while var msg_opt = c_air_cooler.mc_messages.pop_message():
            out_type = msg_opt[0]
            out_msg = msg_opt[1]
            cm.log(out_msg)
        cm.log(csp_exception.m_error_message, SSC_ERROR, -1.0)
        return 0
    while var msg_opt = c_air_cooler.mc_messages.pop_message():
        out_type = msg_opt[0]
        out_msg = msg_opt[1]
        cm.log(out_msg + "\n")
    var p_hx_des_sol: C_CO2_to_air_cooler.S_des_solved
    p_hx_des_sol = c_air_cooler.get_design_solved()
    cm.assign("d_tube_out", ssc_number_t(p_hx_des_sol.m_d_out*1.E2))		//[cm] convert from m
    cm.assign("d_tube_in", ssc_number_t(p_hx_des_sol.m_d_in*1.E2))			//[cm] convert from m
    cm.assign("depth_footprint", ssc_number_t(p_hx_des_sol.m_Depth))		//[m]
    cm.assign("width_footprint", ssc_number_t(p_hx_des_sol.m_W_par))		//[m]
    cm.assign("parallel_paths", ssc_number_t(p_hx_des_sol.m_N_par))		//[-]
    cm.assign("number_of_tubes", ssc_number_t(p_hx_des_sol.m_N_tubes))		//[-]
    cm.assign("length", ssc_number_t(p_hx_des_sol.m_L_tube))				//[m]
    cm.assign("n_passes_series", ssc_number_t(p_hx_des_sol.m_N_passes))	//[-]
    cm.assign("UA_total", ssc_number_t(p_hx_des_sol.m_UA_total / 1.E3))		//[kW/K]
    cm.assign("m_V_hx_material", ssc_number_t(p_hx_des_sol.m_V_material_total))	//[m^3]
    return 0

struct cm_sco2_air_cooler(compute_module):
    var p_T_amb_od: Pointer[ssc_number_t]
    var p_T_co2_hot_od: Pointer[ssc_number_t]
    var p_P_co2_hot_od: Pointer[ssc_number_t]
    var p_T_co2_cold_od: Pointer[ssc_number_t]
    var p_P_co2_cold_od: Pointer[ssc_number_t]
    var p_deltaP_co2_od: Pointer[ssc_number_t]
    var p_m_dot_co2_ND: Pointer[ssc_number_t]
    var p_W_dot_fan_od: Pointer[ssc_number_t]
    var p_W_dot_fan_od_ND: Pointer[ssc_number_t]
    var p_q_dot_od: Pointer[ssc_number_t]
    var p_q_dot_od_ND: Pointer[ssc_number_t]

    def __init__(inout self):
        self.add_var_info(vtab_sco2_air_cooler_design)
        self.add_var_info(_cm_vtab_sco2_air_cooler)

    def exec(inout self) raises:
        var c_air_cooler: C_CO2_to_air_cooler
        sco2_air_cooler_design_common(self, c_air_cooler)
        var is_od_calc_W_dot_fan: Bool = self.is_assigned("od_calc_W_dot_fan")
        var is_od_calc_T_co2_cold: Bool = self.is_assigned("od_calc_T_co2_cold")
        if not is_od_calc_W_dot_fan and not is_od_calc_T_co2_cold:
            self.log("No off-design cases specified")
            return
        var od_cases: matrix_t[Float64]
        if is_od_calc_W_dot_fan:
            od_cases = self.as_matrix("od_calc_W_dot_fan")
            var n_od_cols_loc: Int = Int(od_cases.ncols())
            var n_od_runs_loc: Int = Int(od_cases.nrows())
            if n_od_cols_loc != 5:
                self.log("Input od_calc_W_dot_fan requires exactly 5 columns")
                return
        elif is_od_calc_T_co2_cold:
            od_cases = self.as_matrix("od_calc_T_co2_cold")
            var n_od_cols_loc: Int = Int(od_cases.ncols())
            var n_od_runs_loc: Int = Int(od_cases.nrows())
            if n_od_cols_loc != 5:
                self.log("Input od_calc_W_dot_fan requires exactly 5 columns")
                return
        var m_dot_co2_des: Float64 = c_air_cooler.get_design_solved().m_m_dot_co2   //[kg/s]
        var W_dot_fan_des: Float64 = c_air_cooler.get_design_solved().m_W_dot_fan   //[MWe]
        var q_dot_des: Float64 = c_air_cooler.get_design_solved().m_q_dot*1.E-6     //[MWt]
        var n_od_runs: Int = Int(od_cases.nrows())
        self.allocate_vtab_outputs(n_od_runs)
        for n_run in range(n_od_runs):
            var i_T_co2_hot: Float64 = od_cases[n_run][0] + 273.15   //[K] convert from C
            var i_P_co2_hot: Float64 = od_cases[n_run][1]*1.E3       //[kPa] convert from MPa
            var i_m_dot_co2: Float64 = od_cases[n_run][3]*m_dot_co2_des  //[kg/s] convert from ND
            var i_T_amb: Float64 = od_cases[n_run][4] + 273.15       //[K] convert from C
            var ac_od_err_code: Int = -1
            if is_od_calc_W_dot_fan:
                var i_T_co2_cold: Float64 = od_cases[n_run][2] + 273.15  //[K] convert from C
                var i_W_dot_fan: Float64 = Float64.NaN
                var i_P_co2_cold: Float64 = Float64.NaN
                ac_od_err_code = c_air_cooler.off_design_given_T_out(i_T_amb, i_T_co2_hot, i_P_co2_hot,
                    i_m_dot_co2, i_T_co2_cold, 1.E-4, 1.E-3, i_W_dot_fan, i_P_co2_cold)
            elif is_od_calc_T_co2_cold:
                var i_W_dot_fan_target: Float64 = od_cases[n_run][2]*W_dot_fan_des        //[MWe]
                var i_T_co2_out: Float64 = Float64.NaN
                var i_P_co2_cold: Float64 = Float64.NaN
                ac_od_err_code = c_air_cooler.off_design_given_fan_power(i_T_amb, i_T_co2_hot, i_P_co2_hot,
                    i_m_dot_co2, i_W_dot_fan_target, 1.E-4, 1.E-3, i_T_co2_out, i_P_co2_cold)
            if ac_od_err_code == 0:
                self.p_T_amb_od[n_run] = ssc_number_t(i_T_amb - 273.15)           //[C] convert from K
                self.p_T_co2_hot_od[n_run] = ssc_number_t(i_T_co2_hot - 273.15)   //[C] convert from K
                self.p_P_co2_hot_od[n_run] = ssc_number_t(i_P_co2_hot*1.E-3)      //[MPa] convert from kPa
                self.p_T_co2_cold_od[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_T_co2_cold - 273.15) //[C] convert from K
                self.p_P_co2_cold_od[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_P_co2_cold*1.E-3)    //[MPa] convet from kPa
                self.p_deltaP_co2_od[n_run] = self.p_P_co2_hot_od[n_run] - self.p_P_co2_cold_od[n_run]    //[MPa]
                self.p_m_dot_co2_ND[n_run] = od_cases[n_run][3]         //[-]
                self.p_W_dot_fan_od[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_W_dot_fan)    //[MWe]
                self.p_W_dot_fan_od_ND[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_W_dot_fan / W_dot_fan_des) //[-]
                self.p_q_dot_od[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_q_dot) //[MWt]
                self.p_q_dot_od_ND[n_run] = ssc_number_t(c_air_cooler.get_od_solved().m_q_dot / q_dot_des)
            else:
                self.p_T_amb_od[n_run] = Float64.NaN
                self.p_T_co2_hot_od[n_run] = Float64.NaN
                self.p_P_co2_hot_od[n_run] = Float64.NaN
                self.p_T_co2_cold_od[n_run] = Float64.NaN
                self.p_P_co2_cold_od[n_run] = Float64.NaN
                self.p_deltaP_co2_od[n_run] = Float64.NaN
                self.p_m_dot_co2_ND[n_run] = Float64.NaN
                self.p_W_dot_fan_od[n_run] = Float64.NaN
                self.p_W_dot_fan_od_ND[n_run] = Float64.NaN
                self.p_q_dot_od[n_run] = Float64.NaN
                self.p_q_dot_od_ND[n_run] = Float64.NaN

    def allocate_vtab_outputs(inout self, n_od_runs: Int):
        self.p_T_amb_od = self.allocate("T_amb_od", n_od_runs)
        self.p_T_co2_hot_od = self.allocate("T_co2_hot_od", n_od_runs)
        self.p_P_co2_hot_od = self.allocate("P_co2_hot_od", n_od_runs)
        self.p_T_co2_cold_od = self.allocate("T_co2_cold_od", n_od_runs)
        self.p_P_co2_cold_od = self.allocate("P_co2_cold_od", n_od_runs)
        self.p_deltaP_co2_od = self.allocate("deltaP_co2_od", n_od_runs)
        self.p_m_dot_co2_ND = self.allocate("m_dot_co2_od_ND", n_od_runs)
        self.p_W_dot_fan_od = self.allocate("W_dot_fan_od", n_od_runs)
        self.p_W_dot_fan_od_ND = self.allocate("W_dot_fan_od_ND", n_od_runs)
        self.p_q_dot_od = self.allocate("q_dot_od", n_od_runs)
        self.p_q_dot_od_ND = self.allocate("q_dot_od_ND", n_od_runs)

// DEFINE_MODULE_ENTRY(sco2_air_cooler, "Returns air cooler dimensions given fluid and location design points", 0)
def sco2_air_cooler() -> compute_module:
    return cm_sco2_air_cooler()