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
from core import *
from sco2_recompression_cycle import *
from sco2_pc_csp_int import *
from heat_exchangers import *
from numeric_solvers import *

var _cm_vtab_sco2_design_point: StaticArray[var_info] = StaticArray[
	/*   VARTYPE   DATATYPE         NAME               LABEL                                                  UNITS     META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS*/
	var_info(SSC_INPUT,  SSC_NUMBER,  "W_dot_net_des",   "Design cycle power output",                              "MW",         "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "eta_c",           "Design compressor(s) isentropic efficiency",             "-",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "eta_t",           "Design turbine isentropic efficiency",                   "-",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "P_high_limit",    "High pressure limit in cycle",                           "MPa",        "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "deltaT_PHX",      "Temp diff btw hot HTF and turbine inlet",                "C",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "deltaT_ACC",      "Temp diff btw ambient air and compressor inlet",         "C",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "T_amb_des",       "Design: Ambient temperature for air cooler",             "C",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "T_htf_hot_des",   "Tower design outlet temp",                               "C",          "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "eta_des",         "Power cycle thermal efficiency",                         "",           "",    "",      "*",     "",                "" ),
	var_info(SSC_INPUT,  SSC_NUMBER,  "run_off_des_study", "1 = yes, 0/other = no",                                "",           "",    "",      "*",      "",               "" ),
	var_info(SSC_INPUT,  SSC_ARRAY,   "part_load_fracs", "Array of part load q_dot_in fractions for off-design parametric", "",  "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_INPUT,  SSC_ARRAY,   "T_amb_array",     "Array of ambient temperatures for off-design parametric","C",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "eta_thermal_calc","Calculated cycle thermal efficiency",                    "-",          "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "UA_total",        "Total recuperator UA",                                   "kW/K",       "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "recomp_frac",     "Recompression fraction",                                 "-",          "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "P_comp_in",       "Compressor inlet pressure",                              "MPa",        "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "P_comp_out",      "Compressor outlet pressure",                             "MPa",        "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "T_htf_cold",      "Calculated cold HTF temp",                               "C",          "",    "",      "*",     "",                "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "part_load_fracs_out", "Array of part load fractions that SOLVED at off design", "-",      "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "part_load_eta",   "Matrix of power cycle efficiency results for q_dot_in part load", "-", "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "part_load_coefs", "Part load polynomial coefficients",                      "-",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "part_load_r_squared", "Part load curve fit R squared",                      "-",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_amb_array_out", "Array of ambient temps that SOLVED at off design",       "C",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_amb_eta",       "Matrix of ambient temps and power cycle efficiency",     "-",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY,   "T_amb_coefs",     "Part load polynomial coefficients",                      "-",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER,  "T_amb_r_squared", "T amb curve fit R squared",                              "-",          "",    "",      "run_off_des_study=1", "",  "" ),
	var_info_invalid ]

def test_mono_function(x: Float64, y: Pointer[Float64]) -> Int32:
	y[] = -(x*x)
	return 0

class cm_sco2_design_point(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_sco2_design_point)
    
    def exec(self) -> None:
        var c_ac: C_CO2_to_air_cooler = C_CO2_to_air_cooler()
        var s_des_weather: C_CO2_to_air_cooler.S_des_par_ind = C_CO2_to_air_cooler.S_des_par_ind()
        s_des_weather.m_T_amb_des = 30.0 + 273.15		#[K]
        s_des_weather.m_elev = 300.0					#[m]
        s_des_weather.m_eta_fan = 0.5
        s_des_weather.m_N_nodes_pass = 10
        var s_des_cycle: C_CO2_to_air_cooler.S_des_par_cycle_dep = C_CO2_to_air_cooler.S_des_par_cycle_dep()
        s_des_cycle.m_m_dot_total = 0.0		#[kg/s] Use q_dot to design
        s_des_cycle.m_Q_dot_des = 10.0			#[MWt]
        s_des_cycle.m_T_hot_in_des = 100.0 + 273.15	#[K]
        s_des_cycle.m_P_hot_in_des = 8. * 1.E3	#[kPa]
        s_des_cycle.m_delta_P_des = s_des_cycle.m_P_hot_in_des*0.005	#[kPa]
        s_des_cycle.m_T_hot_out_des = 40.0 + 273.15	#[K]
        s_des_cycle.m_W_dot_fan_des = 10 * 0.02	#[MWe]
        c_ac.design_hx(s_des_weather, s_des_cycle, 1.E-3)
        var T_amb_od: Float64 = c_ac.get_des_par_ind().m_T_amb_des		#[K]
        var P_amb_od: Float64 = c_ac.get_design_solved().m_P_amb_des	#[Pa]
        var T_hot_in: Float64 = c_ac.get_des_par_cycle_dep().m_T_hot_in_des		#[K]
        var P_hot_in: Float64 = c_ac.get_des_par_cycle_dep().m_P_hot_in_des		#[kPa]
        var m_dot_hot: Float64 = c_ac.get_des_par_cycle_dep().m_m_dot_total		#[kg/s]
        var T_hot_out: Float64 = c_ac.get_des_par_cycle_dep().m_T_hot_out_des
        var W_dot_fan: Float64 = Float64.NAN	#[MWe]
        var P_hot_out: Float64 = Float64.NAN    #[kPa]
        var ac_od_code: Int32 = -1
        ac_od_code = c_ac.off_design_given_T_out(T_amb_od, T_hot_in, P_hot_in, m_dot_hot, T_hot_out, 1.E-4, 1.E-3, W_dot_fan, P_hot_out)
        var co2_props: CO2_state = CO2_state()
        var P_in: Float64 = 8000.0		#[kPa]
        var T_in: Float64 = 35 + 273.15	#[K]
        var prop_err_code: Int32 = CO2_TP(T_in, P_in, co2_props)
        if prop_err_code != 0:
            return
        
        var h_in: Float64 = co2_props.enth
        var s_in: Float64 = co2_props.entr
        var P_out: Float64 = 25000.0		#[kPa]
        var s_out_isen: Float64 = s_in	#[kJ/kg-K]
        prop_err_code = CO2_PS(P_out, s_out_isen, co2_props)
        if prop_err_code != 0:
            return
        
        var h_out_isen: Float64 = co2_props.enth
        var eta_isen: Float64 = 0.9
        var h_out: Float64 = h_in + (h_out_isen - h_in) / eta_isen
        prop_err_code = CO2_PH(P_out, h_out, co2_props)
        if prop_err_code != 0:
            return
        
        var T_out: Float64 = co2_props.temp	#[K]
        /*C_compressor c_comp_old;
        C_compressor::S_design_parameters s_des_comp_old;
        s_des_comp_old.m_T_in = T_in;
        s_des_comp_old.m_P_in = P_in;
        s_des_comp_old.m_D_in = D_in;
        s_des_comp_old.m_h_in = h_in;
        s_des_comp_old.m_s_in = s_in;
        s_des_comp_old.m_T_out = T_out;
        s_des_comp_old.m_P_out = P_out;
        s_des_comp_old.m_h_out = h_out;
        s_des_comp_old.m_D_out = D_out;*/
        var m_dot_mc: Float64 = 3000.0 / (h_out - h_in)	#[kg/s] mass flow for 3 MWe compressor
        var T_rc_in: Float64 = 100.0 + 273.15	#[K]
        var P_rc_in: Float64 = P_in				#[kPa]
        CO2_TP(T_rc_in, P_rc_in, co2_props)
        var s_rc_in: Float64 = co2_props.entr
        var h_rc_in: Float64 = co2_props.enth
        var P_rc_out: Float64 = P_out			#[kPa]
        CO2_PS(P_rc_out, s_rc_in, co2_props)
        var h_rc_out_isen: Float64 = co2_props.enth	#[kJ/kg]
        var h_rc_out: Float64 = h_rc_in + (h_rc_out_isen - h_rc_in) / eta_isen
        CO2_PH(P_rc_out, h_rc_out, co2_props)
        var T_rc_out: Float64 = co2_props.temp		#[K]
        var m_dot_rc: Float64 = m_dot_mc / (0.8) * 0.2
        var c_rc_ms: C_comp_multi_stage = C_comp_multi_stage()
        c_rc_ms.design_given_outlet_state(C_comp__psi_eta_vs_phi.E_snl_radial_via_Dyreby, T_rc_in, P_rc_in, m_dot_rc, T_rc_out, P_rc_out, 1.E-3)
        var P_rc_in_od: Float64 = 1.15*P_rc_in
        var T_rc_in_od: Float64 = T_rc_in + 10.0
        var m_dot_rc_od: Float64 = 0.90*m_dot_rc
        var rc_od_err_code: Int32 = 0
        var T_rc_out_od_ms: Float64 = Float64.NAN
        c_rc_ms.off_design_given_P_out(T_rc_in_od, P_rc_in_od, m_dot_rc_od, P_rc_out, 1.E-3, rc_od_err_code, T_rc_out_od_ms)
        var c_comp_ms: C_comp_multi_stage = C_comp_multi_stage()
        c_comp_ms.design_given_outlet_state(C_comp__psi_eta_vs_phi.E_snl_radial_via_Dyreby, T_in, P_in, m_dot_mc, T_out, P_out, 1.E-3)
        var P_in_od: Float64 = 1.15*P_in
        var T_in_od: Float64 = T_in + 5.0
        var m_dot_od: Float64 = 0.90*m_dot_mc
        var P_out_od_new: Float64 = Float64.NAN
        var T_out_od_new: Float64 = Float64.NAN
        var comp_new_err_code: Int32 = 0
        c_comp_ms.off_design_at_N_des(T_in_od, P_in_od, m_dot_od, comp_new_err_code, T_out_od_new, P_out_od_new)
        var W_dot_net: Float64 = 10.0*1.E3	#[KWe]
        var eta: Float64 = 0.492				#[-]
        var q_dot_reject: Float64 = W_dot_net / eta - W_dot_net	#[kWt]
        var P_co2: Float64 = 7.661*1.E3		#[kPa]
        var T_co2_hot: Float64 = 45.0		#[C]
        var T_co2_cold: Float64 = 32.0		#[C]
        var m_dot_co2_full_q_dot: Float64 = 55.8065	#[kg/s]
        var is_partial_med: Bool = True
        var T_water_cold: Float64 = 17.0		#[C] Groundwater temperature
        var T_water_hot: Float64 = 39.0		#[C] Groundwater outlet
        var x_water: Float64 = -1			#[-]
        prop_err_code = CO2_TP(T_co2_hot+273.15, P_co2, co2_props)
        if prop_err_code != 0:
            self.log("CO2 hot props failed", SSC_ERROR, -1.0)
            return
        
        var h_co2_hot: Float64 = co2_props.enth	#[kJ/kg]
        prop_err_code = CO2_TP(T_co2_cold + 273.15, P_co2, co2_props)
        if prop_err_code != 0:
            self.log("CO2 cold props failed", SSC_ERROR, -1.0)
            return
        
        var h_co2_cold: Float64 = co2_props.enth	#[kJ/kg]
        var m_dot_co2: Float64 = Float64.NAN
        if not is_partial_med:
            m_dot_co2 = (q_dot_reject) / (h_co2_hot - h_co2_cold)
        else:
            m_dot_co2 = m_dot_co2_full_q_dot
            q_dot_reject = m_dot_co2*(h_co2_hot - h_co2_cold)
        
        var water_props: water_state = water_state()
        var P_water: Float64 = Float64.NAN
        if x_water > 0.0:
            prop_err_code = water_TQ(T_water_hot + 273.15, x_water, water_props)
            if prop_err_code != 0:
                self.log("Water hot props failed at inlet", SSC_ERROR, -1.0)
                return
            
            P_water = water_props.pres	#[kPa]
        else:
            P_water = 101.0			#[kPa]
            prop_err_code = water_TP(T_water_hot + 273.15, P_water, water_props)
            if prop_err_code != 0:
                self.log("Water hot props failed at inlet", SSC_ERROR, -1.0)
                return
            
        
        var h_water_hot: Float64 = water_props.enth	#[kJ/kg]
        prop_err_code = water_TP(T_water_cold + 273.15, P_water, water_props)
        if prop_err_code != 0:
            self.log("Water hot props failed at inlet", SSC_ERROR, -1.0)
            return
        
        var h_water_cold: Float64 = water_props.enth	#[kJ/kg]
        var m_dot_water: Float64 = (q_dot_reject) / (h_water_hot - h_water_cold)
        var mc_sco2_water_hx: C_HX_counterflow_CRM = C_HX_counterflow_CRM()
        var ms_hx_init: C_HX_counterflow_CRM.S_init_par = C_HX_counterflow_CRM.S_init_par()
        ms_hx_init.m_N_sub_hx = 20
        ms_hx_init.m_hot_fl = NS_HX_counterflow_eqs.CO2
        ms_hx_init.m_cold_fl = NS_HX_counterflow_eqs.WATER
        mc_sco2_water_hx.initialize(ms_hx_init)
        var v_s_node_info: List[NS_HX_counterflow_eqs.S_hx_node_info] = List[NS_HX_counterflow_eqs.S_hx_node_info]()
        var UA_cooler: Float64
        var min_DT_cooler: Float64
        var eff_cooler: Float64
        var NTU_cooler: Float64
        var h_co2_cold_calc: Float64
        var h_water_hot_calc: Float64
        var q_dot_reject_calc: Float64
        try:
            mc_sco2_water_hx.calc_req_UA_enth(q_dot_reject, m_dot_water, m_dot_co2,
                h_water_cold, h_co2_hot, P_water, P_water, P_co2, P_co2,
                UA_cooler, min_DT_cooler, eff_cooler, NTU_cooler, h_co2_cold_calc, h_water_hot_calc, q_dot_reject_calc, v_s_node_info)
        except C_csp_exception as csp_except:

        var W_dot_net_des: Float64 = self.as_double("W_dot_net_des")*1.E3
        var eta_c: Float64 = self.as_double("eta_c")
        var eta_t: Float64 = self.as_double("eta_t")
        var P_high_limit: Float64 = self.as_double("P_high_limit")*1.E3		#[kPa], convert from MPa
        var delta_T_t: Float64 = self.as_double("deltaT_PHX")
        var delta_T_acc: Float64 = self.as_double("deltaT_ACC")
        var T_amb_cycle_des: Float64 = self.as_double("T_amb_des") + 273.15
        var T_htf_hot: Float64 = self.as_double("T_htf_hot_des") + 273.15
        var eta_thermal_des: Float64 = self.as_double("eta_des")
        var DP_LT: List[Float64] = List[Float64](2)
        /*(cold, hot) positive values are absolute [kPa], negative values are relative (-)*/
        DP_LT[0] = 0
        DP_LT[1] = 0
        /*(cold, hot) positive values are absolute [kPa], negative values are relative (-)*/
        var DP_HT: List[Float64] = List[Float64](2)
        DP_HT[0] = 0
        DP_HT[1] = 0
        /*(cold, hot) positive values are absolute [kPa], negative values are relative (-)*/
        var DP_PC: List[Float64] = List[Float64](2)
        DP_PC[0] = 0
        DP_PC[1] = 0
        /*(cold, hot) positive values are absolute [kPa], negative values are relative (-)*/
        var DP_PHX: List[Float64] = List[Float64](2)
        DP_PHX[0] = 0
        DP_PHX[1] = 0
        var N_sub_hxrs: Int32 = 10
        var N_t_des: Float64 = 3600.0
        var tol: Float64 = 1.E-3
        var opt_tol: Float64 = 1.E-3
        var v_P_water_in: List[Float64] = List[Float64]()		#[kPa]
        var v_T_sco2_cold: List[Float64] = List[Float64]()		#[C]
        var T_water_amb: Float64 = 20.0 + 273.15		#[C]
        var P_water_in: Float64 = 50.0				#[kPa]
        var iter_P_water_in: Int32 = 0
        while P_water_in < 110.0:
            P_water_in = 10.0 + 50.0*iter_P_water_in
            var delta_T_pc: Float64 = 5.0				#[C]
            var iter_deltaT_pc: Int32 = 0
            while True:
                delta_T_pc = 5.0 + 1.0*iter_deltaT_pc
                var P_co2_in: Float64 = 9.4E3		#[kPa]
                var T_co2_in: Float64 = 128.1 + 273.15	#[K]
                prop_err_code = CO2_TP(T_co2_in, P_co2_in, co2_props)
                if prop_err_code != 0:
                    self.log("CO2 props failed at inlet", SSC_ERROR, -1.0)
                    return
                
                var h_co2_in: Float64 = co2_props.enth	#[kJ/kg]
                var P_co2_out: Float64 = P_co2_in		#[MPa]
                var T_co2_out: Float64 = T_water_amb + delta_T_pc	#[K]
                prop_err_code = CO2_TP(T_co2_out, P_co2_out, co2_props)
                if prop_err_code != 0:
                    self.log("CO2 props failed at outlet", SSC_ERROR, -1.0)
                    return
                
                var h_co2_out: Float64 = co2_props.enth	#[kJ/kg]
                var q_dot_hx: Float64 = 10.E3		#[kWt]
                var m_dot_co2: Float64 = q_dot_hx / (h_co2_in - h_co2_out)
                var T_water_in: Float64 = T_water_amb	#[K]
                prop_err_code = water_TP(T_water_in, P_water_in, water_props)
                if prop_err_code != 0:
                    self.log("Water props failed at inlet", SSC_ERROR, -1.0)
                    return
                
                var h_water_in: Float64 = water_props.enth	#[kJ/kg]
                var P_water_out: Float64 = P_water_in		#[kPa]
                var x_water_out: Float64 = 1.0				#[-]
                prop_err_code = water_PQ(P_water_out, x_water_out, water_props)
                if prop_err_code != 0:
                    self.log("Water props failed at outlet", SSC_ERROR, -1.0)
                    return
                
                var h_water_out: Float64 = water_props.enth	#[kJ/kg]
                var m_dot_water: Float64 = q_dot_hx / (h_water_out - h_water_in)
                var UA_calc: Float64
                var min_DT_calc: Float64
                var eff_calc: Float64
                var NTU_calc: Float64
                var T_co2_out_calc: Float64
                var T_water_out_calc: Float64
                var q_dot_calc: Float64
                UA_calc = Float64.NAN
                min_DT_calc = Float64.NAN
                eff_calc = Float64.NAN
                NTU_calc = Float64.NAN
                T_co2_out_calc = Float64.NAN
                T_water_out_calc = Float64.NAN
                q_dot_calc = Float64.NAN
                try:
                    mc_sco2_water_hx.calc_req_UA(q_dot_hx, m_dot_water, m_dot_co2,
                        T_water_in, T_co2_in, P_water_in, P_water_out, P_co2_in, P_co2_out,
                        UA_calc, min_DT_calc, eff_calc, NTU_calc, T_co2_out_calc, T_water_out_calc, q_dot_calc, v_s_node_info)
                except C_csp_exception as csp_except:
                    iter_deltaT_pc += 1
                    continue
                
                break
            
            iter_P_water_in += 1
        
        /*HX_object da_solver;
        double result;
        int int_success = da_solver.myfunction(result);*/
        var ty_mono_eq: C_import_mono_eq = C_import_mono_eq(test_mono_function)
        var eq_solv: C_monotonic_eq_solver = C_monotonic_eq_solver(ty_mono_eq)
        var x_low: Float64 = Float64.NAN
        var x_high: Float64 = Float64.NAN
        var iter_limit: Int32 = 50
        eq_solv.settings(0.001, iter_limit, x_low, x_high, True)
        var x_solved: Float64
        var tol_solved: Float64
        x_solved = Float64.NAN
        tol_solved = Float64.NAN
        var iter_solved: Int32 = -1
        var x_guess_1: Float64 = -100.0
        var x_guess_2: Float64 = -99.0
        var y_target: Float64 = -2.0
        eq_solv.solve(x_guess_1, x_guess_2, y_target, x_solved, tol_solved, iter_solved)
        var error_msg: String = ""
        var error_code: Int32 = 0
        var rc_cycle: C_RecompCycle = C_RecompCycle()
        var run_off_des_study: Int32 = self.as_integer("run_off_des_study")
        if run_off_des_study == 1 and eta_thermal_des < 0.0:
            var rc_params_max_eta: C_RecompCycle.S_auto_opt_design_parameters = C_RecompCycle.S_auto_opt_design_parameters()
            rc_params_max_eta.m_W_dot_net = W_dot_net_des					#[kW]
            rc_params_max_eta.m_T_mc_in = T_amb_cycle_des + delta_T_acc	#[K]
            rc_params_max_eta.m_T_t_in = T_htf_hot - delta_T_t				#[K]
            rc_params_max_eta.m_DP_LTR = DP_LT
            rc_params_max_eta.m_DP_HTR = DP_HT
            rc_params_max_eta.m_DP_PC_main = DP_PC
            rc_params_max_eta.m_DP_PHX = DP_PHX
            rc_params_max_eta.m_UA_rec_total = rc_cycle.get_design_limits().m_UA_net_power_ratio_max*rc_params_max_eta.m_W_dot_net		#[kW/K]
            rc_params_max_eta.m_eta_mc = eta_c
            rc_params_max_eta.m_eta_rc = eta_c
            rc_params_max_eta.m_eta_t = eta_t
            rc_params_max_eta.m_LTR_N_sub_hxrs = N_sub_hxrs
            rc_params_max_eta.m_HTR_N_sub_hxrs = N_sub_hxrs
            rc_params_max_eta.m_P_high_limit = P_high_limit
            rc_params_max_eta.m_des_tol = tol
            rc_params_max_eta.m_des_opt_tol = opt_tol
            rc_params_max_eta.m_N_turbine = N_t_des
            error_code = rc_cycle.auto_opt_design(rc_params_max_eta)
            if error_code != 0:
                raise exec_error("sCO2 maximum efficiency calculations failed","")
            
            eta_thermal_des = rc_cycle.get_design_solved().m_eta_thermal - fabs(eta_thermal_des)		#[-]
        
        var rc_params: C_RecompCycle.S_auto_opt_design_hit_eta_parameters = C_RecompCycle.S_auto_opt_design_hit_eta_parameters()
        rc_params.m_W_dot_net = W_dot_net_des					#[kW]
        rc_params.m_eta_thermal = eta_thermal_des
        rc_params.m_T_mc_in = T_amb_cycle_des + delta_T_acc	#[K]
        rc_params.m_T_t_in = T_htf_hot - delta_T_t				#[K]
        rc_params.m_DP_LT = DP_LT
        rc_params.m_DP_HT = DP_HT
        rc_params.m_DP_PC_main = DP_PC
        rc_params.m_DP_PHX = DP_PHX
        rc_params.m_eta_mc = eta_c
        rc_params.m_eta_rc = eta_c
        rc_params.m_eta_t = eta_t
        rc_params.m_LTR_N_sub_hxrs = N_sub_hxrs
        rc_params.m_HTR_N_sub_hxrs = N_sub_hxrs
        rc_params.m_P_high_limit = P_high_limit
        rc_params.m_des_tol = tol
        rc_params.m_des_opt_tol = opt_tol
        rc_params.m_N_turbine = N_t_des
        var sco2_rc_des_par: C_sco2_phx_air_cooler.S_des_par = C_sco2_phx_air_cooler.S_des_par()
        var elevation: Float64 = 300.0		#[m] Elevation
        sco2_rc_des_par.m_hot_fl_code = HTFProperties.Salt_60_NaNO3_40_KNO3
        sco2_rc_des_par.m_T_htf_hot_in = T_htf_hot
        sco2_rc_des_par.m_phx_dt_hot_approach = delta_T_t
        sco2_rc_des_par.m_T_amb_des = T_amb_cycle_des
        sco2_rc_des_par.m_dt_mc_approach = delta_T_acc
        sco2_rc_des_par.m_elevation = elevation
        sco2_rc_des_par.m_W_dot_net = W_dot_net_des
        sco2_rc_des_par.m_eta_thermal = eta_thermal_des
        sco2_rc_des_par.m_is_recomp_ok = 1
        sco2_rc_des_par.m_DP_LT = DP_LT
        sco2_rc_des_par.m_DP_HT = DP_HT
        sco2_rc_des_par.m_DP_PC = DP_PC
        sco2_rc_des_par.m_DP_PHX = DP_PHX
        sco2_rc_des_par.m_eta_mc = eta_c
        sco2_rc_des_par.m_eta_rc = eta_c
        sco2_rc_des_par.m_eta_t = eta_t
        sco2_rc_des_par.m_LTR_N_sub_hxrs = N_sub_hxrs
        sco2_rc_des_par.m_HTR_N_sub_hxrs = N_sub_hxrs
        sco2_rc_des_par.m_P_high_limit = P_high_limit
        sco2_rc_des_par.m_des_tol = tol
        sco2_rc_des_par.m_des_opt_tol = opt_tol
        sco2_rc_des_par.m_N_turbine = N_t_des
        sco2_rc_des_par.m_phx_dt_cold_approach = delta_T_t
        sco2_rc_des_par.m_phx_N_sub_hx = 10
        sco2_rc_des_par.m_frac_fan_power = 0.01
        sco2_rc_des_par.m_deltaP_cooler_frac = 0.002
        var sco2_recomp_csp: C_sco2_phx_air_cooler = C_sco2_phx_air_cooler()
        sco2_recomp_csp.design(sco2_rc_des_par)
        var m_dot_htf: Float64 = sco2_recomp_csp.get_phx_des_par().m_m_dot_hot_des	#[kg/s]
        var sco2_rc_od_par: C_sco2_phx_air_cooler.S_od_par = C_sco2_phx_air_cooler.S_od_par()
        sco2_rc_od_par.m_T_htf_hot = sco2_rc_des_par.m_T_htf_hot_in
        sco2_rc_od_par.m_m_dot_htf = m_dot_htf
        sco2_rc_od_par.m_T_amb = T_amb_cycle_des
        error_code = rc_cycle.auto_opt_design_hit_eta(rc_params, error_msg)
        if error_code != 0:
            raise exec_error("sco2 design point calcs", error_msg)
        
        var eta_thermal_calc: Float64 = rc_cycle.get_design_solved().m_eta_thermal
        var UA_total: Float64 = rc_cycle.get_design_solved().m_UA_HTR + rc_cycle.get_design_solved().m_UA_LTR
        var recomp_frac: Float64 = rc_cycle.get_design_solved().m_recomp_frac
        var P_comp_in: Float64 = rc_cycle.get_design_solved().m_pres[0] / 1.E3
        var P_comp_out: Float64 = rc_cycle.get_design_solved().m_pres[1] / 1.E3
        var T_htf_cold: Float64 = rc_cycle.get_design_solved().m_temp[5 - 1] + delta_T_t - 273.15	#[C]
        self.assign("eta_thermal_calc", ssc_number_t(eta_thermal_calc))
        self.assign("UA_total", ssc_number_t(UA_total))
        self.assign("recomp_frac", ssc_number_t(recomp_frac))
        self.assign("P_comp_in", ssc_number_t(P_comp_in))
        self.assign("P_comp_out", ssc_number_t(P_comp_out))
        self.assign("T_htf_cold", ssc_number_t(T_htf_cold))
        if error_msg == "":
            self.log("Design point optimization was successful!")
        else:
            self.log("The sCO2 design point optimization solved with the following warning(s):\n" + error_msg)
        