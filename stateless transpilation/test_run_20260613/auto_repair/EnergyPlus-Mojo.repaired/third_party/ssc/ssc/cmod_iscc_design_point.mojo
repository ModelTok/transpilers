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
from core import compute_module, var_info, var_info_invalid, SSC_INPUT, SSC_NUMBER, SSC_MATRIX, SSC_OUTPUT, as_integer, as_double, as_matrix, assign, exec_error, util
from ngcc_powerblock import ngcc_power_cycle
from water_properties import water_state, water_TP, water_PQ
from htf_props import HTFProperties
from math import pow, nan

# Static var_info table
var _cm_vtab_iscc_design_point: List[var_info] = [
    #   VARTYPE   DATATYPE         NAME               LABEL                                          UNITS     META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS
    var_info(SSC_INPUT,  SSC_NUMBER,  "ngcc_model",         "1: NREL, 2: GE",                                 "",        "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "q_pb_design",        "Design point power block thermal power",         "MWt",     "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "pinch_point_cold",   "Cold side pinch point",                          "C",       "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "pinch_point_hot",    "Hot side pinch point",                           "C",       "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "elev",               "Plant elevation",                                "m",       "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "HTF_code",           "HTF fluid code",                                 "-",       "",    "",      "*",     "",                ""),
    var_info(SSC_INPUT,  SSC_MATRIX,  "field_fl_props",     "User defined field fluid property data",         "-",       "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "W_dot_fossil",       "Electric output with no solar contribution",     "MWe",     "",    "",      "*",     "",                ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "T_st_inject",        "Steam injection temp into HRSG",                 "C",       "",    "",      "*",     "",                ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "q_solar_max",        "Max. solar thermal input at design",             "MWt",     "",    "",      "*",     "",                ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "T_htf_cold",         "HTF return temp from HRSG",                      "C",       "",    "",      "*",     "",                ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "W_dot_solar",        "Solar contribution to hybrid output",            "MWe",     "",    "",      "*",     "",                ""),
    var_info_invalid
]

struct cm_iscc_design_point:
    var _compute_module: compute_module

    def __init__(inout self):
        self._compute_module = compute_module()
        self._compute_module.add_var_info(_cm_vtab_iscc_design_point)

    def exec(inout self):
        var htfProps: HTFProperties = HTFProperties()			# Instance of HTFProperties class for receiver/HX htf
        var field_fl: Int = as_integer("HTF_code")
        if field_fl != HTFProperties.User_defined:
            htfProps.SetFluid(field_fl) # field_fl should match up with the constants
        else:
            var nrows: Int = 0
            var ncols: Int = 0
            var htf_mat: Pointer[Float64] = as_matrix("field_fl_props", &nrows, &ncols)
            if htf_mat != None and nrows > 2 and ncols == 7:
                var mat: util.matrix_t[Float64] = util.matrix_t[Float64]()
                mat.assign(htf_mat, nrows, ncols)
                var mat_double: util.matrix_t[Float64] = util.matrix_t[Float64](nrows, ncols)
                for i in range(nrows):
                    for j in range(ncols):
                        mat_double[i, j] = Float64(mat[i, j])
                if not htfProps.SetUserDefinedFluid(mat_double):
                    raise exec_error("tcsmolten_salt", util.format("The user-defined HTF did not read correctly"))
            else:
                raise exec_error("tcsmolten_salt", util.format("The user-defined HTF did not load correctly"))

        var cycle_calcs: ngcc_power_cycle = ngcc_power_cycle()
        var cycle_config: Int = as_integer("ngcc_model")
        cycle_calcs.set_cycle_config(cycle_config)
        var T_amb_low: Float64
        var T_amb_high: Float64
        var P_amb_low: Float64
        var P_amb_high: Float64
        T_amb_low = T_amb_high = P_amb_low = P_amb_high = nan
        cycle_calcs.get_table_range(T_amb_low, T_amb_high, P_amb_low, P_amb_high)
        var q_pb_des: Float64 = as_double("q_pb_design")   # [MWt]
        var T_amb_des: Float64 = 20.0						# [C]
        var plant_elevation: Float64 = as_double("elev")		# [m]
        var P_amb_des: Float64 = 101325.0 * pow(1 - 2.25577E-5 * plant_elevation, 5.25588) / 1.E5	# [bar] http://www.engineeringtoolbox.com/air-altitude-pressure-d_462.html						
        if P_amb_des < P_amb_low:
            P_amb_des = P_amb_low
        if P_amb_des > P_amb_high:
            P_amb_des = P_amb_high			
        var q_pb_max: Float64 = cycle_calcs.get_ngcc_data(0.0, T_amb_des, P_amb_des, ngcc_power_cycle.E_solar_heat_max)				# [MWt]
        if q_pb_des > q_pb_max:
            q_pb_des = q_pb_max
        var P_st_extract: Float64 = cycle_calcs.get_ngcc_data(q_pb_des, T_amb_des, P_amb_des, ngcc_power_cycle.E_solar_extraction_p) * 100.0	# [kPa] convert from [bar]
        var P_st_inject: Float64 = cycle_calcs.get_ngcc_data(q_pb_des, T_amb_des, P_amb_des, ngcc_power_cycle.E_solar_injection_p) * 100.0	# [kPa] convert from [bar]
        var T_st_extract: Float64 = cycle_calcs.get_ngcc_data(q_pb_des, T_amb_des, P_amb_des, ngcc_power_cycle.E_solar_extraction_t)		# [C]
        var T_st_inject: Float64 = cycle_calcs.get_ngcc_data(q_pb_des, T_amb_des, P_amb_des, ngcc_power_cycle.E_solar_injection_t)			# [C]
        var W_dot_fossil: Float64 = cycle_calcs.get_ngcc_data(0.0, T_amb_des, P_amb_des, ngcc_power_cycle.E_plant_power_net)
        var W_dot_hybrid: Float64 = cycle_calcs.get_ngcc_data(q_pb_des, T_amb_des, P_amb_des, ngcc_power_cycle.E_plant_power_net)
        var W_dot_solar: Float64 = W_dot_hybrid - W_dot_fossil
        var wp: water_state = water_state()
        water_TP(T_st_extract + 273.15, P_st_extract, &wp)
        var h_st_extract: Float64 = wp.enth			# [kJ/kg]
        water_TP(T_st_inject + 273.15, P_st_inject, &wp)
        var h_st_inject: Float64 = wp.enth			# [kJ/kg]
        var m_dot_st_des: Float64 = q_pb_des * 1000.0 / (h_st_inject - h_st_extract)
        water_PQ(P_st_extract, 0.0, &wp)						# Steam props at design pressure and quality = 0
        var h_x0: Float64 = wp.enth									# [kJ/kg] Steam enthalpy at evaporator inlet
        water_PQ(P_st_extract, 1.0, &wp)						# Steam props at design pressure and quality = 1
        var T_sat: Float64 = wp.temp - 273.15						# [C] Saturation temperature
        var h_x1: Float64 = wp.enth									# [kJ/kg] Steam enthalpy at evaporator exit
        water_TP(T_st_inject + 273.15, P_st_inject, &wp)		# Steam props at superheater exit
        var h_sh_out: Float64 = wp.enth								# [kJ/kg] Steam enthalpy at sh exit
        water_TP(T_st_extract + 273.15, P_st_extract, &wp)		# Steam props at economizer inlet
        var h_econo_in: Float64 = wp.enth							# [kJ/kg] Steam enthalpy at econo inlet
        var q_dot_econo: Float64 = m_dot_st_des * (h_x0 - h_econo_in)		# [kW] design point duty of economizer
        var q_dot_evap: Float64 = m_dot_st_des * (h_x1 - h_x0)				# [kW] design point duty of evaporator
        var q_dot_sh_des: Float64 = m_dot_st_des * (h_sh_out - h_x1)		# [kW] design point duty of superheater
        var q_dot_evap_and_sh: Float64 = q_dot_evap + q_dot_sh_des		# [kW]
        var T_pinch_point: Float64 = as_double("pinch_point_cold")
        var T_ms_evap_out: Float64 = T_sat + T_pinch_point			# [C] Molten Salt evaporator outlet temperature
        var T_approach: Float64 = as_double("pinch_point_hot")
        var T_ms_sh_in: Float64 = T_st_inject + T_approach
        var cp_ms: Float64 = htfProps.Cp((T_ms_evap_out + T_ms_sh_in) / 2.0)				# [kJ/kg-K] Specific heat of molten salt
        var m_dot_ms_des: Float64 = q_dot_evap_and_sh / (cp_ms * (T_ms_sh_in - T_ms_evap_out))	# [kg/s] Mass flow rate of molten salt
        var T_ms_econo_out: Float64 = T_ms_evap_out - q_dot_econo / (m_dot_ms_des * cp_ms)		# [C] Temperature of molten salt at outlet of economizer
        assign("W_dot_fossil", Float64(W_dot_fossil))
        assign("T_st_inject", Float64(T_st_inject))
        assign("q_solar_max", Float64(q_pb_max))
        assign("T_htf_cold", Float64(T_ms_econo_out))
        assign("W_dot_solar", Float64(W_dot_solar))

# Module entry point
def iscc_design_point() -> cm_iscc_design_point:
    return cm_iscc_design_point()