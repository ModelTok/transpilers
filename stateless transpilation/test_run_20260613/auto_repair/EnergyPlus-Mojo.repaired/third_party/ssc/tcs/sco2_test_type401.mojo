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
from tcstype import *
from sco2_power_cycle import *
from sco2_rec_util import *
from sam_csp_util import *
from CO2_properties import *
from heat_exchangers import *
from sco2_recompression_cycle import *
from math import *
from memory import *
from utils import *

enum:
	P_1 = 0
	I_1 = 1
	O_1 = 2
	N_MAX = 3

var sco2_test_type401_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_1, "eta", "Field efficiency", "-", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_1, "vwind", "Wind velocity", "m/s", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_1, "pparasi", "Parasitic tracking/startup power", "MWe", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

@value
class sco2_test_type401(tcstypeinterface):
	var n_zen: Float64

	def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
		self.n_zen = Float64.NAN

	def __del__(owned self):

	def init(inout self) -> Int:
		"""
		CO2_state co2_props_1;
		double T_in = 800.0;
		double P_in = 20000.0;
		CO2_TP(T_in, P_in, &co2_props_1);
		double ssnd_in = co2_props_1.ssnd;
		double P_out = 10000.0;
		double poly_eta = 0.75;
		int error_code = 0;
		double isen_eta = -999.9;
		double enth_in, entr_in, dens_in, temp_out, enth_out, entr_out, dens_out, spec_work;
		enth_in = entr_in = dens_in = temp_out = enth_out = entr_out = dens_out = spec_work = numeric_limits<double>::quiet_NaN();
		isen_eta_from_poly_eta(T_in, P_in, P_out, poly_eta, false, error_code, isen_eta);
		calculate_turbomachinery_outlet_1(T_in, P_in, P_out, poly_eta, false, error_code, enth_in, entr_in, dens_in, temp_out, enth_out, entr_out, dens_out, spec_work);
		C_turbine::S_design_parameters t_des_par;
		t_des_par.m_D_in = dens_in;
		t_des_par.m_h_in = enth_in;
		t_des_par.m_h_out = enth_out;
		t_des_par.m_m_dot = 35000.0 / spec_work;
		t_des_par.m_N_comp_design_if_linked = 123.456;
		t_des_par.m_N_design = 3600.0;
		t_des_par.m_P_in = P_in;
		t_des_par.m_P_out = P_out;
		t_des_par.m_s_in = entr_in;
		t_des_par.m_T_in = T_in;
		C_turbine turbine;
		turbine.turbine_sizing(t_des_par, error_code);
		double m_dot_t, T_t_out;
		m_dot_t = T_t_out = -999.9;
		turbine.off_design_turbine(T_in, 0.75*P_in, P_out, 3600.0, error_code, m_dot_t, T_t_out);
		T_in = 310.0;
		P_in = 10000.0;
		P_out = 20000.0;
		isen_eta = 0.75;
		calculate_turbomachinery_outlet_1(T_in, P_in, P_out, isen_eta, true, error_code, enth_in, entr_in, dens_in, temp_out, enth_out, entr_out, dens_out, spec_work);
		CO2_TD(temp_out, dens_out, &co2_props_1);
		double f_recomp = 0.2;
		C_compressor::S_design_parameters mc_des_par;
		mc_des_par.m_D_in = dens_in;
		mc_des_par.m_D_out = dens_out;
		mc_des_par.m_h_in = enth_in;
		mc_des_par.m_h_out = enth_out;
		mc_des_par.m_m_dot = t_des_par.m_m_dot*(1.0-f_recomp);
		mc_des_par.m_P_out = P_out;
		mc_des_par.m_s_in = entr_in;
		mc_des_par.m_T_out = temp_out;
		C_compressor mc;
		mc.compressor_sizing(mc_des_par, error_code);
		double T_rc_in = 370.0;
		calculate_turbomachinery_outlet_1(T_rc_in, P_in, P_out, isen_eta, true, error_code, enth_in, entr_in, dens_in, temp_out, enth_out, entr_out, dens_out, spec_work);
		C_recompressor::S_design_parameters rc_des_par;
		rc_des_par.m_P_in = P_in;
		rc_des_par.m_D_in = dens_in;
		rc_des_par.m_D_out = dens_out;
		rc_des_par.m_h_in = enth_in;
		rc_des_par.m_h_out = enth_out;
		rc_des_par.m_m_dot = t_des_par.m_m_dot*f_recomp;
		rc_des_par.m_P_out = P_out;
		rc_des_par.m_s_in = entr_in;
		rc_des_par.m_T_out = temp_out;
		C_recompressor rc;
		rc.recompressor_sizing(rc_des_par, error_code);
		double T_rc_od_out = -999.9;
		rc.off_design_recompressor(T_rc_in, 0.8*P_in, 0.85*rc_des_par.m_m_dot, P_out, error_code, T_rc_od_out);
		double T_c_od_out = numeric_limits<double>::quiet_NaN();
		double P_c_od_out = numeric_limits<double>::quiet_NaN();
		mc.off_design_compressor(T_in, P_in, 0.75*m_dot_t, mc.get_design_solved()->m_N_design, error_code, T_c_od_out, P_c_od_out);
		C_RecompCycle::S_design_parameters cycle_des_par;
		cycle_des_par.m_W_dot_net = 10000.0;
		cycle_des_par.m_T_mc_in = 55.0 + 273.15;
		cycle_des_par.m_T_t_in = 700.0 + 273.15;
		cycle_des_par.m_P_mc_out = 20000.0;
		double pressure_ratio = 2.6;
		cycle_des_par.m_P_mc_in = cycle_des_par.m_P_mc_out / pressure_ratio;
		cycle_des_par.m_DP_LT[0] = 0.0;
		cycle_des_par.m_DP_LT[1] = 0.0;
		cycle_des_par.m_DP_HT[0] = 0.0;
		cycle_des_par.m_DP_HT[1] = 0.0;
		cycle_des_par.m_DP_PC[0] = 0.0;
		cycle_des_par.m_DP_PC[1] = 0.0;
		cycle_des_par.m_DP_PHX[0] = 0.0;
		cycle_des_par.m_DP_PHX[1] = 0.0;
		cycle_des_par.m_UA_LT = 250.0;
		cycle_des_par.m_UA_HT = 250.0;
		cycle_des_par.m_recomp_frac = 0.0;
		cycle_des_par.m_eta_mc = 0.89;
		cycle_des_par.m_eta_rc = 0.89;
		cycle_des_par.m_eta_t = 0.9;
		cycle_des_par.m_N_sub_hxrs = 10;
		cycle_des_par.m_P_high_limit = 20000.0;
		cycle_des_par.m_tol = 1.E-3;
		cycle_des_par.m_N_turbine = 3600.0;
		C_RecompCycle rc_cycle;
		C_RecompCycle::S_opt_design_parameters cycle_opt_des_par;
		cycle_opt_des_par.m_W_dot_net = 10000.0;
		cycle_opt_des_par.m_T_mc_in = 55.0 + 273.15;
		cycle_opt_des_par.m_T_t_in = 700.0 + 273.15;
		cycle_opt_des_par.m_DP_LT[0] = 0.0;
		cycle_opt_des_par.m_DP_LT[1] = 0.0;
		cycle_opt_des_par.m_DP_HT[0] = 0.0;
		cycle_opt_des_par.m_DP_HT[1] = 0.0;
		cycle_opt_des_par.m_DP_PC[0] = 0.0;
		cycle_opt_des_par.m_DP_PC[1] = 0.0;
		cycle_opt_des_par.m_DP_PHX[0] = 0.0;
		cycle_opt_des_par.m_DP_PHX[1] = 0.0;
		cycle_opt_des_par.m_UA_rec_total = 5000.0;
		cycle_opt_des_par.m_eta_mc = 0.89;
		cycle_opt_des_par.m_eta_rc = 0.89;
		cycle_opt_des_par.m_eta_t = 0.9;
		cycle_opt_des_par.m_N_sub_hxrs = 10;
		cycle_opt_des_par.m_P_high_limit = 20000.0;
		cycle_opt_des_par.m_tol = 1.E-3;
		cycle_opt_des_par.m_opt_tol = 1.E-3;
		cycle_opt_des_par.m_N_turbine = 3600.0;
		cycle_opt_des_par.m_P_mc_out_guess = 20000.0;
		cycle_opt_des_par.m_fixed_P_mc_out = true;
		cycle_opt_des_par.m_PR_HP_to_LP_guess = 2.6;
		cycle_opt_des_par.m_fixed_PR_HP_to_LP = true;
		cycle_opt_des_par.m_recomp_frac_guess = 0.0;
		cycle_opt_des_par.m_fixed_recomp_frac = false;
		cycle_opt_des_par.m_LT_frac_guess = 0.5;
		cycle_opt_des_par.m_fixed_LT_frac = false;
		C_RecompCycle::S_auto_opt_design_parameters cycle_auto_opt_des_par;
		cycle_auto_opt_des_par.m_W_dot_net = 10000.0;
		cycle_auto_opt_des_par.m_T_mc_in = 55.0 + 273.15;
		cycle_auto_opt_des_par.m_T_t_in = 700.0 + 273.15;
		cycle_auto_opt_des_par.m_DP_LT[0] = 0.0;
		cycle_auto_opt_des_par.m_DP_LT[1] = 0.0;
		cycle_auto_opt_des_par.m_DP_HT[0] = 0.0;
		cycle_auto_opt_des_par.m_DP_HT[1] = 0.0;
		cycle_auto_opt_des_par.m_DP_PC[0] = 0.0;
		cycle_auto_opt_des_par.m_DP_PC[1] = 0.0;
		cycle_auto_opt_des_par.m_DP_PHX[0] = 0.0;
		cycle_auto_opt_des_par.m_DP_PHX[1] = 0.0;
		cycle_auto_opt_des_par.m_UA_rec_total = 5000.0;
		cycle_auto_opt_des_par.m_eta_mc = 0.89;
		cycle_auto_opt_des_par.m_eta_rc = 0.89;
		cycle_auto_opt_des_par.m_eta_t = 0.9;
		cycle_auto_opt_des_par.m_N_sub_hxrs = 10;
		cycle_auto_opt_des_par.m_P_high_limit = 20000.0;
		cycle_auto_opt_des_par.m_tol = 1.E-3;
		cycle_auto_opt_des_par.m_opt_tol = 1.E-3;
		cycle_auto_opt_des_par.m_N_turbine = 3600.0;
		rc_cycle.auto_opt_design(cycle_auto_opt_des_par, error_code);
		C_RecompCycle::S_od_parameters cycle_od_par;
		cycle_od_par.m_T_mc_in = cycle_auto_opt_des_par.m_T_mc_in;
		cycle_od_par.m_T_t_in = cycle_auto_opt_des_par.m_T_t_in;
		cycle_od_par.m_P_mc_in = rc_cycle.get_design_solved()->m_pres[1-1];
			cycle_od_par.m_P_mc_in = 7698.8;
		cycle_od_par.m_recomp_frac = rc_cycle.get_design_solved()->m_recomp_frac;
			cycle_od_par.m_recomp_frac = 0.2452;
		cycle_od_par.m_N_mc = rc_cycle.get_design_solved()->m_N_mc;
			cycle_od_par.m_N_mc = 30181.0;
		cycle_od_par.m_N_t = rc_cycle.get_design_solved()->m_N_t;
		cycle_od_par.m_N_sub_hxrs = cycle_auto_opt_des_par.m_N_sub_hxrs;
		cycle_od_par.m_tol = cycle_auto_opt_des_par.m_tol;
		C_RecompCycle::S_target_od_parameters cycle_tar_od_par;
		cycle_tar_od_par.m_T_mc_in = cycle_auto_opt_des_par.m_T_mc_in;
		cycle_tar_od_par.m_T_t_in = cycle_auto_opt_des_par.m_T_t_in;
		cycle_tar_od_par.m_recomp_frac = rc_cycle.get_design_solved()->m_recomp_frac;
		cycle_tar_od_par.m_N_mc = rc_cycle.get_design_solved()->m_N_mc;
		cycle_tar_od_par.m_N_t = rc_cycle.get_design_solved()->m_N_t;
		cycle_tar_od_par.m_N_sub_hxrs = cycle_auto_opt_des_par.m_N_sub_hxrs;
		cycle_tar_od_par.m_tol = cycle_auto_opt_des_par.m_tol;
		cycle_tar_od_par.m_target = rc_cycle.get_design_solved()->m_W_dot_net / rc_cycle.get_design_solved()->m_eta_thermal * 0.5;
		cycle_tar_od_par.m_is_target_Q = true;
		cycle_tar_od_par.m_lowest_pressure = 3000.0;
		cycle_tar_od_par.m_highest_pressure = 25000.0;
		C_RecompCycle::S_opt_target_od_parameters cycle_opt_tar_od_par;
		cycle_opt_tar_od_par.m_T_mc_in = cycle_auto_opt_des_par.m_T_mc_in;
		cycle_opt_tar_od_par.m_T_t_in = cycle_auto_opt_des_par.m_T_t_in;
		cycle_opt_tar_od_par.m_target = cycle_tar_od_par.m_target;
		cycle_opt_tar_od_par.m_is_target_Q = true;
		cycle_opt_tar_od_par.m_N_sub_hxrs = cycle_auto_opt_des_par.m_N_sub_hxrs;
		cycle_opt_tar_od_par.m_lowest_pressure = cycle_tar_od_par.m_lowest_pressure;
		cycle_opt_tar_od_par.m_highest_pressure = cycle_tar_od_par.m_highest_pressure;
		cycle_opt_tar_od_par.m_recomp_frac_guess = rc_cycle.get_design_solved()->m_recomp_frac;
		cycle_opt_tar_od_par.m_fixed_recomp_frac = false;
		cycle_opt_tar_od_par.m_N_mc_guess = rc_cycle.get_design_solved()->m_N_mc;
		cycle_opt_tar_od_par.m_fixed_N_mc = false;
		cycle_opt_tar_od_par.m_N_t_guess = rc_cycle.get_design_solved()->m_N_t;
		cycle_opt_tar_od_par.m_fixed_N_t = true;
		cycle_opt_tar_od_par.m_tol = cycle_auto_opt_des_par.m_tol;
		cycle_opt_tar_od_par.m_opt_tol = cycle_auto_opt_des_par.m_opt_tol;
		rc_cycle.optimal_target_off_design(cycle_opt_tar_od_par, error_code);
		C_RecompCycle::S_opt_od_parameters   cycle_opt_od_par;
		cycle_opt_od_par.m_T_mc_in = cycle_tar_od_par.m_T_mc_in;
		cycle_opt_od_par.m_T_t_in = cycle_tar_od_par.m_T_t_in;
		cycle_opt_od_par.m_is_max_W_dot = true;
		cycle_opt_od_par.m_N_sub_hxrs = cycle_tar_od_par.m_N_sub_hxrs;
		cycle_opt_od_par.m_P_mc_in_guess = cycle_od_par.m_P_mc_in;
		cycle_opt_od_par.m_fixed_P_mc_in = false;
		cycle_opt_od_par.m_recomp_frac_guess = rc_cycle.get_design_solved()->m_recomp_frac;
		cycle_opt_od_par.m_fixed_recomp_frac = false;
		cycle_opt_od_par.m_N_mc_guess = rc_cycle.get_design_solved()->m_N_mc;
		cycle_opt_od_par.m_fixed_N_mc = false;
		cycle_opt_od_par.m_N_t_guess = rc_cycle.get_design_solved()->m_N_t;
		cycle_opt_od_par.m_fixed_N_t = true;
		cycle_opt_od_par.m_tol = cycle_tar_od_par.m_tol;
		cycle_opt_od_par.m_opt_tol = cycle_tar_od_par.m_tol;
		int N_sub_hxrs = 10;
		double Q_dot = 30000.0;
		double m_dot_c = 57.0;
		double m_dot_h = 57.0;
		double T_c_in = 330.0;
		double T_h_in = 800.0;
		double P_c_in = 20000.0;
		double P_h_in = 10000.0;
		double P_c_out = P_c_in;
		double P_h_out = P_h_in;
		double UA_des = -999.9;
		double min_DT_des = -999.9;
		calculate_hxr_UA_1(N_sub_hxrs, Q_dot, m_dot_c, m_dot_h, T_c_in, T_h_in, P_c_in, P_c_out, P_h_in, P_h_out, error_code, UA_des, min_DT_des);
		C_HeatExchanger::S_design_parameters hx_des_par;
		hx_des_par.m_m_dot_design[0] = m_dot_c;
		hx_des_par.m_m_dot_design[1] = m_dot_h;
		hx_des_par.m_UA_design = UA_des;
		hx_des_par.m_DP_design[0] = 0.0;
		hx_des_par.m_DP_design[1] = 0.0;
		C_HeatExchanger hx;
		hx.initialize(hx_des_par);
		vector<double> m_dots_od(2);
		m_dots_od[0] = m_dot_c*0.75;
		m_dots_od[1] = m_dot_h*0.75;
		double UA_od = -999.9;
		hx.hxr_conductance(m_dots_od, UA_od);
		vector<double> deltaP_od;
		hx.hxr_pressure_drops(m_dots_od, deltaP_od);
		"""
		var air_cooler: C_CO2_to_air_cooler = C_CO2_to_air_cooler()
		var ac_des_par_ind: C_CO2_to_air_cooler.S_des_par_ind = C_CO2_to_air_cooler.S_des_par_ind()
		ac_des_par_ind.m_T_amb_des = 32.0+273.15			#[K]
		ac_des_par_ind.m_elev = 300.0						#[m]
		var ac_des_par_cycle_dep: C_CO2_to_air_cooler.S_des_par_cycle_dep = C_CO2_to_air_cooler.S_des_par_cycle_dep()
		ac_des_par_cycle_dep.m_T_hot_in_des = 100.0+273.15	#[K]
		ac_des_par_cycle_dep.m_P_hot_in_des = 8000.0		#[kPa]
		ac_des_par_cycle_dep.m_m_dot_total = 938.9			#[kg/s]
		ac_des_par_cycle_dep.m_delta_P_des = 62.5		#[kPa]
		ac_des_par_cycle_dep.m_T_hot_in_des = ac_des_par_ind.m_T_amb_des+15.0	#[K]
		ac_des_par_cycle_dep.m_W_dot_fan_des = 0.35				#[MW] Cooler air fan power at design
		var W_dot_od: Float64 = 0.0
		var air_cooler_error_code: Int = 0
		"""
		- Flux profile
		- T_fluid_in
		- P_fluid_in
		- T_fluid_out +/ m_dot?
		- d_out
		- L
		- material
		- roughness
		"""		
		/* Find minimum thickness that results in all axial sections having a Total Damage < 1 */
		/* 1) Step in to axial node i = 0. Find minimum thickness.
	       2) i++, Test th_min from previous step.
		         if th_min results in Total Damage > 1, then find new min thickness and GOTO 1, else GOTO 2
		   3) End either with a min thickness for the tube or all possible thicknesses exhausted. The latter 
		         resulting in a solid tube. Could instead enforce some pressure drop that, when exceeded, signals
				 that there is no feasible solution for the given inputs
	    */
		var tube_length: Float64 = 4.1		#[m]
		var tube_flux_map: util.matrix_t[Float64] = util.matrix_t[Float64]()
		var n_tube_nodes: Int = 5
		var q_abs_total_input: Float64 = 150000/(CSP.pi/2.0)
		tube_flux_map.resize(n_tube_nodes,1)
		var n_axial: Int = tube_flux_map.nrows()
		var n_circ: Int = tube_flux_map.ncols()
		for i in range(n_axial):
			for j in range(n_circ):
				tube_flux_map[i,j] = q_abs_total_input		#[W/m2]
		n_tube_nodes = 10
		q_abs_total_input = 300000.0
		tube_flux_map.resize(n_tube_nodes, 1)
		n_axial = tube_flux_map.nrows()
		n_circ = tube_flux_map.ncols()
		for i in range(n_axial):
			for j in range(n_circ):
				tube_flux_map[i, j] = q_abs_total_input - 0.1*q_abs_total_input*(i)		#[W/m2]
		n_tube_nodes = 10
		var d_out: Float64 = 0.012			#[m]
		var T_fluid_in: Float64 = 470.0		#[C]
		var T_fluid_out: Float64 = 650.0		#[C]
		var P_fluid_in: Float64 = 25.0		#[MPa]
		var e_roughness: Float64 = 4.5E-5	#[m] Absolute tube roughness
		var L_tube: Float64 = 4.1			#[m] Length of tube
		var calc_min_th: N_sco2_rec.C_calc_tube_min_th = N_sco2_rec.C_calc_tube_min_th()
		q_abs_total_input = 300000.0
		var max_flux_in: List[Float64] = List[Float64](n_tube_nodes)
		for i in range(n_tube_nodes):
			max_flux_in[i] = q_abs_total_input - 0.1*q_abs_total_input*(i)		#[W/m2]
		for i in range(n_tube_nodes):
			max_flux_in[i] *= 0.9
		var A_surf_total: Float64 = d_out*CSP.pi*tube_length			#[m^2] Total tube surface area
		var A_surf_per_node: Float64 = A_surf_total/(n_axial*n_circ)		#[m^2] Total surface area per axial/circ control area
		var q_abs_total: Float64 = 0.0
		var q_abs_1D: List[Float64] = List[Float64](n_axial)
		for i in range(n_axial):
			q_abs_1D[i] = 0.0
			for j in range(n_circ):
				q_abs_total += tube_flux_map[i, j]*A_surf_per_node		#[W]
				q_abs_1D[i] += tube_flux_map[i, j]*A_surf_per_node		#[W]
		var n_temps: Int = n_axial + 1
		var Temp: List[Float64] = List[Float64](n_temps)
		var Pres: List[Float64] = List[Float64](n_temps)
		var Enth: List[Float64] = List[Float64](n_temps)
		var h_conv_ave: List[Float64] = List[Float64](n_axial)
		var L_node: List[Float64] = List[Float64](n_axial)
		for i in range(n_axial):
			L_node[i] = L_tube / n_axial
		var co2_props: CO2_state = CO2_state()
		Temp[0] = T_fluid_in
		Pres[0] = P_fluid_in*1000.0		#[kPa]
		CO2_TP(Temp[0]+273.15,Pres[0],co2_props)
		Enth[0] = co2_props.enth*1000.0				#[J/kg], convert from [kJ/kg]
		var tube_slice: N_sco2_rec.C_tube_slice = N_sco2_rec.C_tube_slice(N_sco2_rec.C_rec_des_props.Haynes_230)
		var tube_inputs: N_sco2_rec.C_tube_slice.S_ID_OD_perf_and_lifetime_inputs = N_sco2_rec.C_tube_slice.S_ID_OD_perf_and_lifetime_inputs()
		var tube_outputs: N_sco2_rec.C_tube_slice.S_ID_OD_perf_and_lifetime_outputs = N_sco2_rec.C_tube_slice.S_ID_OD_perf_and_lifetime_outputs()
		var search_min_th: Bool = True
		var th_min_guess: Float64 = 0.001	# Smallest possible thickness = 1 mm
		var th_step: Float64 = 0.0002
		var P_tube_out_prev: Float64 = Pres[0]
		var m_dot_tube: Float64 = Float64.NAN
		var d_in: Float64 = Float64.NAN
		var P_tube_out_min: Float64 = 0.8*Pres[0]	# At max, allow 20% pressure drop
		var is_deltaP_too_large: Bool = False
		var iter_d_in: Int = -1
		do:
			iter_d_in += 1
			d_in = d_out - 2.0*(th_min_guess+th_step*iter_d_in)
			var A_cs: Float64 = 0.25*CSP.pi*pow(d_in,2)
			var relRough: Float64 = e_roughness / d_in
			var P_tube_out_guess: Float64 = 0.95*P_tube_out_prev
			var P_tube_out_tolerance: Float64 = 0.001
			var P_tube_out_diff: Float64 = 2.0*P_tube_out_tolerance
			var P_tube_guess_high: Float64 = P_tube_out_prev
			var P_tube_guess_low: Float64 = -999.9
			var iter_P_tube: Int = 0			
			do:		# Solve for correct mass flow rate given pressure drops through tube
				iter_P_tube += 1
				if iter_P_tube > 1:
					if P_tube_out_diff > 0.0:	# Calculated P_tube_Out > Guessed P_tube_out
						P_tube_guess_low = P_tube_out_guess
						P_tube_out_guess = 0.5*(P_tube_guess_low+P_tube_guess_high)
					else:						# Calculated P_tube_out < Guessed P_tube_out
						P_tube_guess_high = P_tube_out_guess
						if P_tube_guess_low < 0.0:
							P_tube_out_guess = 0.95*Pres[n_temps-1]
						else:
							P_tube_out_guess = 0.5*(P_tube_guess_low + P_tube_guess_high)
					if P_tube_guess_high <= P_tube_out_min:
						is_deltaP_too_large = True
						break
				if P_tube_out_guess < P_tube_out_min:
					P_tube_out_guess = P_tube_out_min
				CO2_TP(T_fluid_out + 273.15, P_tube_out_guess, co2_props)
				var h_tube_out: Float64 = co2_props.enth*1000.0
				m_dot_tube = q_abs_total/(h_tube_out-Enth[0])
				var P_node_out_tolerance: Float64 = P_tube_out_tolerance
				var P_node_out_diff: Float64 = 2.0*P_node_out_tolerance
				var is_P_out_too_low: Bool = False
				for i in range(1, n_temps):		# Step through loop
					var P_node_out_guess: Float64 = -999.9
					if i == 1:
						P_node_out_guess = Pres[0] - i/n_temps*(Pres[0]-P_tube_out_guess)
					else:
						P_node_out_guess = Pres[i-1] - 1.25*(Pres[i-1]-Pres[i-2])
					var P_guess_high: Float64 = Pres[i - 1]	#[kPa] Upper guess is always pressure at previous node
					var P_guess_low: Float64 = -999.9		#[kPa] If negative then it's a flag that lower guess hasn't been calculated
					var iter_P_local: Int = 0		# Track iterations					
					do:		# Converge local pressure
						iter_P_local += 1
						if iter_P_local > 1:		# Reguess P_node_out_guess until convergence
							if P_node_out_diff > 0.0:	# Calculated P_out > Guessed P_out
								P_guess_low = Pres[i]
								P_node_out_guess = 0.5*(P_guess_high + P_guess_low)
							else:						# Calculated P_out < Guessed P_out
								P_guess_high = Pres[i]
								if P_guess_low < 0.0:		# Lower bound hasn't been reached
									P_node_out_guess = 0.95*Pres[i]
								else:
									P_node_out_guess = 0.5*(P_guess_high + P_guess_low)
							if P_guess_high <= P_tube_out_min:
								is_P_out_too_low = True
								break
						if P_node_out_guess < P_tube_out_min:
							P_node_out_guess = P_tube_out_min
						Enth[i] = Enth[i-1] + q_abs_1D[i-1]/m_dot_tube
						CO2_PH(P_node_out_guess, Enth[i]/1000.0, co2_props)
						Temp[i] = co2_props.temp-273.15		#[C], convert from K
						var P_ave: Float64 = 0.5*(P_node_out_guess + Pres[i-1])
						var h_ave: Float64 = 0.5*(Enth[i] + Enth[i-1])
						CO2_PH(P_ave, h_ave/1000.0, co2_props)
						var visc_dyn: Float64 = CO2_visc(co2_props.dens, co2_props.temp)*1.E-6
						var Re: Float64 = m_dot_tube*d_in/(A_cs*visc_dyn)
						var rho: Float64 = co2_props.dens
						var visc_kin: Float64 = visc_dyn / rho
						var cond: Float64 = CO2_cond(co2_props.dens, co2_props.temp)
						var specheat: Float64 = co2_props.cp*1000.0
						var alpha: Float64 = cond/(specheat*rho)
						var Pr: Float64 = visc_kin/alpha
						var Nusselt: Float64 = -999.9
						var f: Float64 = -999.9
						CSP.PipeFlow(Re, Pr, 1000.0, relRough, Nusselt, f)
						h_conv_ave[i-1] = Nusselt*cond / d_in
						var u_m: Float64 = m_dot_tube/(rho*A_cs)
						Pres[i] = Pres[i-1] - f*L_node[i-1]*rho*pow(u_m,2)/(2.0*d_in)/1000.0
						P_node_out_diff = (Pres[i] - P_node_out_guess)/P_node_out_guess
					} while abs(P_node_out_diff) > P_node_out_tolerance
					if is_P_out_too_low:
						Pres[n_temps-1] = 0.9*P_tube_out_guess		# Ensures P_tube_out_diff is negative
						break
				P_tube_out_diff = (Pres[n_temps-1] - P_tube_out_guess)/P_tube_out_guess
				P_tube_out_prev = Pres[n_temps-1]
			} while abs(P_tube_out_diff) > P_tube_out_tolerance
			if is_deltaP_too_large:
				break
			var total_damage: Float64 = 0.0
			for i in range(1, n_temps):
				tube_inputs.m_P_internal = Pres[0]/1.E3	#[MPa] Constant: always max pressure
				tube_inputs.m_T_fluid = Temp[i]
				tube_inputs.m_d_out = d_out				# Constant
				tube_inputs.m_d_in = d_in					# Constant
				tube_inputs.m_flux = tube_flux_map[i-1,0]
				tube_inputs.m_h_conv = h_conv_ave[i-1]
				tube_slice.calc_ID_OD_perf_and_lifetime(tube_inputs, tube_outputs)
				var inner_total_damage: Float64 = tube_outputs.s_ID_lifetime_outputs.m_total_damage
				var outer_total_damage: Float64 = tube_outputs.s_OD_lifetime_outputs.m_total_damage
				total_damage = max(total_damage, max(inner_total_damage, outer_total_damage))
			if total_damage <= 1.0:
				search_min_th = False
		} while search_min_th
		"""
		cycle_design_parameters rc_des_par;
		rc_des_par.m_mc_type = 1;
		rc_des_par.m_rc_type = 1;
		rc_des_par.m_W_dot_net = 10.0 * 1000.0;				//[kW]
		rc_des_par.m_T_mc_in = 32.0 + 273.15;				//[K]
		rc_des_par.m_T_t_in = 550.0 + 273.15;				//[K]
		rc_des_par.m_DP_LT[0] = 0.0;
		rc_des_par.m_DP_LT[1] = 0.0;
		rc_des_par.m_DP_HT[0] = 0.0;
		rc_des_par.m_DP_HT[1] = 0.0;
		rc_des_par.m_DP_PC[0] = 0.0;
		rc_des_par.m_DP_PC[1] = 0.0;
		rc_des_par.m_DP_PHX[0] = 0.0;
		rc_des_par.m_DP_PHX[1] = 0.0;
		rc_des_par.m_N_t = -1.0;
		rc_des_par.m_eta_mc = 0.89;
		rc_des_par.m_eta_rc = 0.89;
		rc_des_par.m_eta_t = 0.9;
		rc_des_par.m_N_sub_hxrs = 20;
		rc_des_par.m_tol = 1.E-6;
		rc_des_par.m_opt_tol = 1.E-6;
		double UA_LT = 500.0;
		double UA_HT = 500.0;
		rc_des_par.m_fixed_LT_frac = true;
		rc_des_par.m_UA_rec_total = UA_LT + UA_HT;
		rc_des_par.m_LT_frac = UA_LT / rc_des_par.m_UA_rec_total;
		rc_des_par.m_LT_frac_guess = 0.5;
		double P_mc_in = 7.69*1000.0;
		double P_mc_out = 20.0*1000.0;		
		rc_des_par.m_fixed_P_mc_out = true;
		rc_des_par.m_P_mc_out = P_mc_out;
		rc_des_par.m_P_high_limit = 25.0*1000.0;
		rc_des_par.m_P_mc_out_guess = rc_des_par.m_P_mc_out;
		rc_des_par.m_fixed_PR_HP_to_LP = true;
		rc_des_par.m_PR_mc = P_mc_out / P_mc_in;
		rc_des_par.m_PR_HP_to_LP_guess = rc_des_par.m_PR_mc;
		rc_des_par.m_fixed_recomp_frac = false;
		rc_des_par.m_recomp_frac = 0.5;
		rc_des_par.m_recomp_frac_guess = 0.5;
		RecompCycle rc_cycle(rc_des_par);
		bool auto_cycle_success = rc_cycle.auto_optimal_design();
		cycle_opt_off_des_inputs rc_opt_off_des_in;
		rc_opt_off_des_in.m_T_mc_in = 40.0 + 273.15;
		rc_opt_off_des_in.m_T_t_in = rc_cycle.get_cycle_design_parameters()->m_T_t_in;
		rc_opt_off_des_in.m_W_dot_net_target = rc_cycle.get_cycle_design_parameters()->m_W_dot_net;
		rc_opt_off_des_in.m_N_sub_hxrs = rc_cycle.get_cycle_design_parameters()->m_N_sub_hxrs;
		rc_opt_off_des_in.m_fixed_recomp_frac = false;
		rc_opt_off_des_in.m_recomp_frac_guess = rc_cycle.get_cycle_design_parameters()->m_recomp_frac;
		rc_opt_off_des_in.m_fixed_N_mc = false;
		rc_opt_off_des_in.m_N_mc_guess = rc_cycle.get_cycle_design_metrics()->m_N_mc;
		rc_opt_off_des_in.m_fixed_N_t = true;
		rc_opt_off_des_in.m_N_t = rc_cycle.get_cycle_design_parameters()->m_N_t;
		rc_opt_off_des_in.m_tol = rc_cycle.get_cycle_design_parameters()->m_tol;
		rc_opt_off_des_in.m_opt_tol = rc_cycle.get_cycle_design_parameters()->m_opt_tol;
		bool od_opt_cycle_success = rc_cycle.optimal_off_design(rc_opt_off_des_in);
		"""
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
		return 0

	def converged(inout self, time: Float64) -> Int:
		return 0

TCS_IMPLEMENT_TYPE(sco2_test_type401, "Basic heliostat field", "Ty Neises", 1, sco2_test_type401_variables, None, 1)