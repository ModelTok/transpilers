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
from CO2_properties import CO2_state, CO2_PH, CO2_TP, CO2_TQ, CO2_cond, CO2_visc
from water_properties import water_state, water_PH, water_TP, water_TQ, water_cond, water_visc
from htf_props import HTFProperties
from lib_util import util
from numeric_solvers import C_monotonic_eq_solver, C_monotonic_equation
from csp_solver_util import C_csp_exception, C_csp_messages, CSP
from sam_csp_util import *
from algorithm import *
from math import *

def NS_HX_counterflow_eqs__calc_max_q_dot_enth(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    h_h_in: Float64, P_h_in: Float64, P_h_out: Float64, m_dot_h: Float64,
    h_c_in: Float64, P_c_in: Float64, P_c_out: Float64, m_dot_c: Float64) -> Float64:
    var h_h_out: Float64
    var T_h_out: Float64
    var h_c_out: Float64
    var T_c_out: Float64
    var T_h_in: Float64
    var T_c_in: Float64
    return NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        h_h_in, P_h_in, P_h_out, m_dot_h,
        h_c_in, P_c_in, P_c_out, m_dot_c,
        h_h_out, T_h_out, 
        h_c_out, T_c_out, 
        T_h_in, T_c_in)

def NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    h_h_in: Float64, P_h_in: Float64, P_h_out: Float64, m_dot_h: Float64,
    h_c_in: Float64, P_c_in: Float64, P_c_out: Float64, m_dot_c: Float64,
    h_h_out: Float64, T_h_out: Float64,
    h_c_out: Float64, T_c_out: Float64,
    T_h_in: Float64, T_c_in: Float64) -> Float64:
    var prop_error_code: Int = 0
    T_h_in = Float64.NaN
    if hot_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_PH(P_h_in, h_h_in, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::design",
                "Hot side CO2 inlet enthalpy calculations failed", 12)
        T_h_in = ms_co2_props.temp
    elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_PH(P_h_in, h_h_in, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Hot side water/steam inlet enthalpy calculations failed", 12)
        T_h_in = ms_water_props.temp
    else:
        T_h_in = hot_htf_class.temp_lookup(h_h_in)
    T_c_in = Float64.NaN
    if cold_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_PH(P_c_in, h_c_in, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::design",
                "Cold side inlet enthalpy calculations failed", 13)
        T_c_in = ms_co2_props.temp
    elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_PH(P_c_in, h_c_in, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Cold side water/steam inlet enthalpy calculations failed", 12)
        T_c_in = ms_water_props.temp
    else:
        T_c_in = cold_htf_class.temp_lookup(h_c_in)
    var Q_dot_cold_max: Float64 = Float64.NaN
    if cold_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_TP(T_h_in, P_c_out, ms_co2_props)
        if prop_error_code == 205:
            prop_error_code = CO2_TQ(T_h_in, 0.0, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Cold side inlet enthalpy calculations at effectiveness calc failed", 12)
        var h_c_out_max: Float64 = max(ms_co2_props.enth, h_c_in)
        Q_dot_cold_max = m_dot_c*(h_c_out_max - h_c_in)
    elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_TP(T_h_in, P_c_out, ms_water_props)
        if prop_error_code == 205:
            prop_error_code = water_TQ(T_h_in, 0.0, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Cold side water/steam enthalpy calcs at max eff failed", 12)
        var h_c_out_max: Float64 = max(ms_water_props.enth, h_c_in)
        Q_dot_cold_max = m_dot_c*(h_c_out_max - h_c_in)
    else:
        var h_c_out_max: Float64 = cold_htf_class.enth_lookup(T_h_in)
        Q_dot_cold_max = m_dot_c*(h_c_out_max - h_c_in)
    var Q_dot_hot_max: Float64 = Float64.NaN
    if hot_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_TP(T_c_in, P_h_out, ms_co2_props)
        if prop_error_code == 205:
            prop_error_code = CO2_TQ(T_c_in, 1.0, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Hot side inlet enthalpy calculations at effectiveness calc failed", 12)
        var h_h_out_min: Float64 = min(h_h_in, ms_co2_props.enth)
        Q_dot_hot_max = m_dot_h*(h_h_in - h_h_out_min)
    elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_TP(T_c_in, P_h_out, ms_water_props)
        if prop_error_code == 205:
            prop_error_code = water_TQ(T_c_in, 1.0, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Hot side water/stream inlet enthalpy calcs at max eff failed", 12)
        var h_h_out_min: Float64 = min(h_h_in, ms_water_props.enth)
        Q_dot_hot_max = m_dot_h*(h_h_in - h_h_out_min)
    else:
        var h_h_out_min: Float64 = hot_htf_class.enth_lookup(T_c_in)
        Q_dot_hot_max = m_dot_h*(h_h_in - h_h_out_min)
    var q_dot_max: Float64 = min(Q_dot_hot_max, Q_dot_cold_max)
    h_h_out = h_h_in - q_dot_max / m_dot_h
    h_c_out = h_c_in + q_dot_max / m_dot_c
    T_h_out = Float64.NaN
    if hot_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_PH(P_h_out, h_h_out, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Hot CO2 outlet temp from PH calcs failed", 12)
        T_h_out = ms_co2_props.temp
    elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_PH(P_h_out, h_h_out, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Hot side water/stream outlet temp from PH calcs failed", 12)
        T_h_out = ms_water_props.temp
    else:
        T_h_out = hot_htf_class.temp_lookup(h_h_out)
    T_c_out = Float64.NaN
    if cold_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_PH(P_c_out, h_c_out, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Cold CO2 outlet temp from PH calcs failed", 12)
        T_c_out = ms_co2_props.temp
    elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_PH(P_c_out, h_c_out, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot_enth",
                "Cold side water/steam outlet temp from PH calcs failed", 12)
        T_c_out = ms_water_props.temp
    else:
        T_c_out = cold_htf_class.temp_lookup(h_c_out)
    return q_dot_max

def NS_HX_counterflow_eqs__calc_max_q_dot(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    T_h_in: Float64, P_h_in: Float64, P_h_out: Float64, m_dot_h: Float64,
    T_c_in: Float64, P_c_in: Float64, P_c_out: Float64, m_dot_c: Float64,
    h_h_out: Float64, T_h_out: Float64,
    h_c_out: Float64, T_c_out: Float64) -> Float64:
    var prop_error_code: Int = 0
    var h_c_in: Float64 = Float64.NaN
    if cold_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_TP(T_c_in, P_c_in, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Cold side inlet enthalpy calculations at effectiveness calc failed", 12)
        h_c_in = ms_co2_props.enth
    elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_TP(T_c_in, P_c_in, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Cold side water/steam inlet enthalpy calculations at effectiveness calc failed", 12)
        h_c_in = ms_water_props.enth
    else:
        h_c_in = cold_htf_class.enth_lookup(T_c_in)
    var h_h_in: Float64 = Float64.NaN
    if hot_fl_code == NS_HX_counterflow_eqs__CO2:
        var ms_co2_props: CO2_state
        prop_error_code = CO2_TP(T_h_in, P_h_in, ms_co2_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Hot side inlet enthalpy calculations at effectiveness calc failed", 12)
        h_h_in = ms_co2_props.enth
    elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
        var ms_water_props: water_state
        prop_error_code = water_TP(T_h_in, P_h_in, ms_water_props)
        if prop_error_code != 0:
            raise C_csp_exception("C_HX_counterflow::calc_max_q_dot",
                "Hot side water/steam inlet enthalpy calculations at effectiveness calc failed", 12)
        h_h_in = ms_water_props.enth
    else:
        h_h_in = hot_htf_class.enth_lookup(T_h_in)
    var T_h_in_calc: Float64
    var T_c_in_calc: Float64
    T_h_in_calc = Float64.NaN
    T_c_in_calc = Float64.NaN
    return NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        h_h_in, P_h_in, P_h_out, m_dot_h,
        h_c_in, P_c_in, P_c_out, m_dot_c,
        h_h_out, T_h_out,
        h_c_out, T_c_out,
        T_h_in_calc, T_c_in_calc)

def NS_HX_counterflow_eqs__hx_fl__calc_h__TP(fl_code: Int, fl_htf_class: HTFProperties,
    T_K: Float64, P_kpa: Float64) -> Float64:
    var c_TP: NS_HX_counterflow_eqs__C_hx_fl__TP__core = NS_HX_counterflow_eqs__C_hx_fl__TP__core(fl_code, fl_htf_class, T_K, P_kpa, False)
    return c_TP.m_h

@value
struct NS_HX_counterflow_eqs__C_hx_fl__TP__core:
    var m_h: Float64
    var m_rho: Float64
    var m_cp: Float64
    var m_k: Float64
    var m_mu: Float64
    def __init__(inout self, fl_code: Int, fl_htf_class: HTFProperties,
        T_K: Float64, P_kpa: Float64, is_calc_cond_visc: Bool):
        if fl_code == NS_HX_counterflow_eqs__CO2:
            var ms_co2_props: CO2_state
            var prop_error_code: Int = CO2_TP(T_K, P_kpa, ms_co2_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::design",
                    "Cold side inlet enthalpy calculations failed", 12)
            self.m_h = ms_co2_props.enth
            self.m_rho = ms_co2_props.dens
            self.m_cp = ms_co2_props.cp
            if is_calc_cond_visc:
                self.m_k = CO2_cond(ms_co2_props.dens, ms_co2_props.temp)
                self.m_mu = CO2_visc(ms_co2_props.dens, ms_co2_props.temp)
        elif fl_code == NS_HX_counterflow_eqs__WATER:
            var ms_water_props: water_state
            var prop_error_code: Int = water_TP(T_K, P_kpa, ms_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                    "Cold side inlet enthalpy calculations failed", 12)
            self.m_h = ms_water_props.enth
            self.m_rho = ms_water_props.dens
            self.m_cp = ms_water_props.cp
            if is_calc_cond_visc:
                self.m_k = water_cond(ms_water_props.dens, ms_water_props.temp)
                self.m_mu = water_visc(ms_water_props.dens, ms_water_props.temp)
        else:
            self.m_h = fl_htf_class.enth_lookup(T_K)
            self.m_rho = fl_htf_class.dens(T_K, P_kpa*1.E3)
            self.m_cp = fl_htf_class.Cp(T_K)
            if is_calc_cond_visc:
                self.m_k = fl_htf_class.cond(T_K)
                self.m_mu = fl_htf_class.visc(T_K)*1.E6
        if not is_calc_cond_visc:
            self.m_k = Float64.NaN
            self.m_mu = Float64.NaN

@value
struct NS_HX_counterflow_eqs__C_hx_fl__Ph__core:
    var m_T: Float64
    var m_rho: Float64
    var m_cp: Float64
    var m_k: Float64
    var m_mu: Float64
    def __init__(inout self, fl_code: Int, fl_htf_class: HTFProperties,
        P_kpa: Float64, h_kjkg: Float64, is_calc_cond_visc: Bool):
        if fl_code == NS_HX_counterflow_eqs__CO2:
            var ms_co2_props: CO2_state
            var prop_error_code: Int = CO2_PH(P_kpa, h_kjkg, ms_co2_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::design",
                    "Cold side inlet enthalpy calculations failed", 12)
            self.m_T = ms_co2_props.temp
            self.m_rho = ms_co2_props.dens
            self.m_cp = ms_co2_props.cp
            if is_calc_cond_visc:
                self.m_k = CO2_cond(ms_co2_props.dens, ms_co2_props.temp)
                self.m_mu = CO2_visc(ms_co2_props.dens, ms_co2_props.temp)
        elif fl_code == NS_HX_counterflow_eqs__WATER:
            var ms_water_props: water_state
            var prop_error_code: Int = water_PH(P_kpa, h_kjkg, ms_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                    "Cold side inlet enthalpy calculations failed", 12)
            self.m_T = ms_water_props.temp
            self.m_rho = ms_water_props.dens
            self.m_cp = ms_water_props.cp
            if is_calc_cond_visc:
                self.m_k = water_cond(ms_water_props.dens, ms_water_props.temp)
                self.m_mu = water_visc(ms_water_props.dens, ms_water_props.temp)
        else:
            self.m_T = fl_htf_class.temp_lookup(h_kjkg)
            self.m_rho = fl_htf_class.dens(self.m_T, P_kpa*1.E3)
            self.m_cp = fl_htf_class.Cp(self.m_T)
            if is_calc_cond_visc:
                self.m_k = fl_htf_class.cond(self.m_T)
                self.m_mu = fl_htf_class.visc(self.m_T)*1.E6
        if not is_calc_cond_visc:
            self.m_k = Float64.NaN
            self.m_mu = Float64.NaN

def NS_HX_counterflow_eqs__hx_fl__calc_T__Ph(fl_code: Int, fl_htf_class: HTFProperties,
    P_kpa: Float64, h_kjkg: Float64) -> Float64:
    var c_ph: NS_HX_counterflow_eqs__C_hx_fl__Ph__core = NS_HX_counterflow_eqs__C_hx_fl__Ph__core(fl_code, fl_htf_class, P_kpa, h_kjkg, False)
    return c_ph.m_T

def NS_HX_counterflow_eqs__calc_req_UA(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    N_sub_hx: Int,
    q_dot: Float64, m_dot_c: Float64, m_dot_h: Float64,
    T_c_in: Float64, T_h_in: Float64, P_c_in: Float64, P_c_out: Float64, P_h_in: Float64, P_h_out: Float64,
    UA: Float64, min_DT: Float64, eff: Float64, NTU: Float64, T_h_out: Float64, T_c_out: Float64, q_dot_calc: Float64,
    v_s_node_info: List[NS_HX_counterflow_eqs__S_hx_node_info]):
    v_s_node_info.clear()
    if q_dot < 0.0:
        raise C_csp_exception("C_HX_counterflow::design",
            "Input heat transfer rate is less than 0.0. It must be >= 0.0", 4)
    if m_dot_c < 1.E-14:
        raise C_csp_exception("C_HX_counterflow::design",
            "The cold mass flow rate must be a positive value")
    if m_dot_h < 1.E-14:
        raise C_csp_exception("C_HX_counterflow::design",
            "The hot mass flow rate must be a positive value")
    if T_h_in < T_c_in:
        raise C_csp_exception("C_HX_counterflow::design",
            "Inlet hot temperature is colder than the cold inlet temperature", 5)
    if P_h_in < P_h_out:
        raise C_csp_exception("C_HX_counterflow::design",
            "Hot side outlet pressure is greater than hot side inlet pressure", 6)
    if P_c_in < P_c_out:
        raise C_csp_exception("C_HX_counterflow::design",
            "Cold side outlet pressure is greater than cold side inlet pressure", 7)
    if q_dot <= 1.E-14:
        UA = 0.0
        NTU = 0.0
        q_dot_calc = 0.0
        min_DT = T_h_in - T_c_in
        eff = 0.0
        T_h_out = T_h_in
        T_c_out = T_c_in
        return
    var h_c_in: Float64 = Float64.NaN
    var h_h_in: Float64 = Float64.NaN
    var prop_error_code: Int = 0
    h_c_in = NS_HX_counterflow_eqs__hx_fl__calc_h__TP(cold_fl_code, cold_htf_class, T_c_in, P_c_in)
    h_h_in = NS_HX_counterflow_eqs__hx_fl__calc_h__TP(hot_fl_code, hot_htf_class, T_h_in, P_h_in)
    var h_c_out: Float64 = Float64.NaN
    var h_h_out: Float64 = Float64.NaN
    NS_HX_counterflow_eqs__calc_req_UA_enth(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        N_sub_hx,
        q_dot, m_dot_c, m_dot_h, 
        h_c_in, h_h_in, P_c_in, P_c_out, P_h_in, P_h_out, 
        h_h_out, T_h_out, h_c_out, T_c_out,
        UA, min_DT, eff, NTU, q_dot_calc,
        v_s_node_info)
    return

def NS_HX_counterflow_eqs__calc_req_UA_enth(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    N_sub_hx: Int,
    q_dot: Float64, m_dot_c: Float64, m_dot_h: Float64,
    h_c_in: Float64, h_h_in: Float64, P_c_in: Float64, P_c_out: Float64, P_h_in: Float64, P_h_out: Float64,
    h_h_out: Float64, T_h_out: Float64, h_c_out: Float64, T_c_out: Float64,
    UA: Float64, min_DT: Float64, eff: Float64, NTU: Float64, q_dot_calc: Float64,
    v_s_node_info: List[NS_HX_counterflow_eqs__S_hx_node_info]):
    v_s_node_info.resize(N_sub_hx)
    if q_dot < 0.0:
        raise C_csp_exception("C_HX_counterflow::design",
            "Input heat transfer rate is less than 0.0. It must be >= 0.0", 4)
    if m_dot_c < 1.E-14:
        raise C_csp_exception("C_HX_counterflow::design",
            "The cold mass flow rate must be a positive value")
    if m_dot_h < 1.E-14:
        raise C_csp_exception("C_HX_counterflow::design",
            "The hot mass flow rate must be a positive value")
    if P_h_in < P_h_out:
        raise C_csp_exception("C_HX_counterflow::design",
            "Hot side outlet pressure is greater than hot side inlet pressure", 6)
    if P_c_in < P_c_out:
        raise C_csp_exception("C_HX_counterflow::design",
            "Cold side outlet pressure is greater than cold side inlet pressure", 7)
    var ms_co2_props: CO2_state
    var ms_water_props: water_state
    var prop_error_code: Int = 0
    h_h_out = h_h_in - q_dot / m_dot_h
    h_c_out = h_c_in + q_dot / m_dot_c
    var N_nodes: Int = N_sub_hx + 1
    var h_h_prev: Float64 = 0.0
    var T_h_prev: Float64 = 0.0
    var P_h_prev: Float64 = 0.0
    var h_c_prev: Float64 = 0.0
    var T_c_prev: Float64 = 0.0
    var P_c_prev: Float64 = 0.0
    var T_c_in: Float64 = Float64.NaN
    var T_h_in: Float64 = Float64.NaN
    var is_temp_violation: Bool = False
    UA = 0.0
    min_DT = T_h_in
    for i in range(N_nodes):
        var P_c: Float64 = P_c_out + i * (P_c_in - P_c_out) / Float64(N_nodes - 1)
        var P_h: Float64 = P_h_in - i * (P_h_in - P_h_out) / Float64(N_nodes - 1)
        var h_c: Float64 = h_c_out + i * (h_c_in - h_c_out) / Float64(N_nodes - 1)
        var h_h: Float64 = h_h_in - i * (h_h_in - h_h_out) / Float64(N_nodes - 1)
        var T_h: Float64 = Float64.NaN
        if hot_fl_code == NS_HX_counterflow_eqs__CO2:
            prop_error_code = CO2_PH(P_h, h_h, ms_co2_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::design",
                    "Cold side inlet enthalpy calculations failed", 12)
            T_h = ms_co2_props.temp
        elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
            prop_error_code = water_PH(P_h, h_h, ms_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                    "Cold side inlet enthalpy calculations failed", 12)
            T_h = ms_water_props.temp
        else:
            T_h = hot_htf_class.temp_lookup(h_h)
        var T_c: Float64 = Float64.NaN
        if cold_fl_code == NS_HX_counterflow_eqs__CO2:
            prop_error_code = CO2_PH(P_c, h_c, ms_co2_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::design",
                    "Cold side inlet enthalpy calculations failed", 13)
            T_c = ms_co2_props.temp
        elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
            prop_error_code = water_PH(P_c, h_c, ms_water_props)
            if prop_error_code != 0:
                raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                    "Cold side water/steam inlet enthalpy calculations failed", 13)
            T_c = ms_water_props.temp
        else:
            T_c = cold_htf_class.temp_lookup(h_c)
        if i == 0:
            T_h_in = T_h
            T_c_out = T_c
        if i == N_nodes - 1:
            T_h_out = T_h
            T_c_in = T_c
        if T_c >= T_h:
            is_temp_violation = True
        min_DT = fmin(min_DT, T_h - T_c)
        if i > 0:
            var is_h_2phase: Bool = False
            var is_c_2phase: Bool = False
            var h_h_avg: Float64 = 0.5*(h_h_prev + h_h)
            var P_h_avg: Float64 = 0.5*(P_h_prev + P_h)
            var cp_h_avg: Float64 = Float64.NaN
            v_s_node_info[i - 1].s_fl_hot.m_dot = m_dot_h
            if hot_fl_code == NS_HX_counterflow_eqs__CO2:
                prop_error_code = CO2_PH(P_h_avg, h_h_avg, ms_co2_props)
                if prop_error_code != 0:
                    raise C_csp_exception("C_HX_counterflow::design",
                        "Cold side inlet enthalpy calculations failed", 12)
                cp_h_avg = ms_co2_props.cp
                v_s_node_info[i - 1].s_fl_hot.cp = ms_co2_props.cp
                v_s_node_info[i - 1].s_fl_hot.rho = ms_co2_props.dens
                v_s_node_info[i - 1].s_fl_hot.k = CO2_cond(ms_co2_props.dens, ms_co2_props.temp)
                v_s_node_info[i - 1].s_fl_hot.mu = CO2_visc(ms_co2_props.dens, ms_co2_props.temp)
            elif hot_fl_code == NS_HX_counterflow_eqs__WATER:
                prop_error_code = water_PH(P_h_avg, h_h_avg, ms_water_props)
                if prop_error_code != 0:
                    raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                        "Cold side inlet enthalpy calculations failed", 12)
                cp_h_avg = ms_water_props.cp
                v_s_node_info[i - 1].s_fl_hot.cp = ms_water_props.cp
                v_s_node_info[i - 1].s_fl_hot.rho = ms_water_props.dens
                v_s_node_info[i - 1].s_fl_hot.k = water_cond(ms_water_props.dens, ms_water_props.temp)
                v_s_node_info[i - 1].s_fl_hot.mu = water_visc(ms_water_props.dens, ms_water_props.temp)
            else:
                var T_h_avg: Float64 = hot_htf_class.temp_lookup(h_h_avg)
                cp_h_avg = hot_htf_class.Cp(T_h_avg)
                v_s_node_info[i - 1].s_fl_hot.cp = cp_h_avg
                v_s_node_info[i - 1].s_fl_hot.rho = hot_htf_class.dens(T_h_avg, P_h_avg)
                v_s_node_info[i - 1].s_fl_hot.k = hot_htf_class.cond(T_h_avg)
                v_s_node_info[i - 1].s_fl_hot.mu = hot_htf_class.visc(T_h_avg)*1.E6
            if not (isfinite(cp_h_avg) and cp_h_avg > 0.0):
                is_h_2phase = True
            var h_c_avg: Float64 = 0.5*(h_c_prev + h_c)
            var P_c_avg: Float64 = 0.5*(P_c_prev + P_c)
            var cp_c_avg: Float64 = Float64.NaN
            v_s_node_info[i - 1].s_fl_cold.m_dot = m_dot_c
            if cold_fl_code == NS_HX_counterflow_eqs__CO2:
                prop_error_code = CO2_PH(P_c_avg, h_c_avg, ms_co2_props)
                if prop_error_code != 0:
                    raise C_csp_exception("C_HX_counterflow::design",
                        "Cold side inlet enthalpy calculations failed", 13)
                cp_c_avg = ms_co2_props.cp
                v_s_node_info[i - 1].s_fl_cold.cp = ms_co2_props.cp
                v_s_node_info[i - 1].s_fl_cold.rho = ms_co2_props.dens
                v_s_node_info[i - 1].s_fl_cold.k = CO2_cond(ms_co2_props.dens, ms_co2_props.temp)
                v_s_node_info[i - 1].s_fl_cold.mu = CO2_visc(ms_co2_props.dens, ms_co2_props.temp)
            elif cold_fl_code == NS_HX_counterflow_eqs__WATER:
                prop_error_code = water_PH(P_c_avg, h_c_avg, ms_water_props)
                if prop_error_code != 0:
                    raise C_csp_exception("C_HX_counterflow::calc_req_UA_enth",
                        "Cold side water/steam inlet enthalpy calculations failed", 13)
                cp_c_avg = ms_water_props.cp
                v_s_node_info[i - 1].s_fl_cold.cp = ms_water_props.cp
                v_s_node_info[i - 1].s_fl_cold.rho = ms_water_props.dens
                v_s_node_info[i - 1].s_fl_cold.k = water_cond(ms_water_props.dens, ms_water_props.temp)
                v_s_node_info[i - 1].s_fl_cold.mu = water_visc(ms_water_props.dens, ms_water_props.temp)
            else:
                var T_c_avg: Float64 = cold_htf_class.temp_lookup(h_c_avg)
                cp_c_avg = cold_htf_class.Cp(T_c_avg)
                v_s_node_info[i - 1].s_fl_cold.cp = cp_c_avg
                v_s_node_info[i - 1].s_fl_cold.rho = hot_htf_class.dens(T_c_avg, P_c_avg)
                v_s_node_info[i - 1].s_fl_cold.k = hot_htf_class.cond(T_c_avg)
                v_s_node_info[i - 1].s_fl_cold.mu = hot_htf_class.visc(T_c_avg)*1.E6
            if not (isfinite(cp_c_avg) and cp_c_avg > 0.0):
                is_c_2phase = True
            var C_dot_min: Float64
            var C_R: Float64
            C_dot_min = Float64.NaN
            C_R = Float64.NaN
            if is_h_2phase and not is_c_2phase:
                C_dot_min = m_dot_c * cp_c_avg
                C_R = 0.0
            elif not is_c_2phase and is_h_2phase:
                C_dot_min = m_dot_h * cp_h_avg
                C_R = 0.0
            elif is_c_2phase and is_h_2phase:
                C_dot_min = q_dot / Float64(N_sub_hx) * 1.E10 * (T_h_prev - T_c)
                C_R = 1.0
            else:
                var C_dot_h: Float64 = m_dot_h * cp_h_avg
                var C_dot_c: Float64 = m_dot_c * cp_c_avg
                C_dot_min = fmin(C_dot_h, C_dot_c)
                var C_dot_max: Float64 = fmax(C_dot_h, C_dot_c)
                C_R = C_dot_min / C_dot_max
            var eff: Float64 = min(0.99999, (q_dot / Float64(N_sub_hx)) / (C_dot_min*(T_h_prev - T_c)))
            var NTU: Float64 = 0.0
            if C_R != 1.0:
                NTU = log((1.0 - eff * C_R) / (1.0 - eff)) / (1.0 - C_R)
            else:
                NTU = eff / (1.0 - eff)
            var UA_local: Float64 = NTU * C_dot_min
            UA += UA_local
            v_s_node_info[i - 1].UA = UA_local
        h_h_prev = h_h
        T_h_prev = T_h
        P_h_prev = P_h
        h_c_prev = h_c
        T_c_prev = T_c
        P_c_prev = P_c
    if is_temp_violation:
        raise C_csp_exception("C_HX_counterflow::design",
            "Cold temperature is hotter than hot temperature.", 11)
    if UA != UA:
        raise C_csp_exception("C_HX_counterflow::design",
            "NaN found for total heat exchanger UA", 14)
    q_dot_calc = q_dot
    var h_h_out_q_max: Float64
    var T_h_out_q_max: Float64
    var h_c_out_q_max: Float64
    var T_c_out_q_max: Float64
    var T_h_in_q_max: Float64
    var T_c_in_q_max: Float64
    h_h_out_q_max = Float64.NaN
    T_h_out_q_max = Float64.NaN
    h_c_out_q_max = Float64.NaN
    T_c_out_q_max = Float64.NaN
    T_h_in_q_max = Float64.NaN
    T_c_in_q_max = Float64.NaN
    var q_dot_max: Float64 = NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        h_h_in, P_h_in, P_h_out, m_dot_h,
        h_c_in, P_c_in, P_c_out, m_dot_c,
        h_h_out_q_max, T_h_out_q_max,
        h_c_out_q_max, T_c_out_q_max,
        T_h_in_q_max, T_c_in_q_max)
    eff = q_dot / q_dot_max
    var is_h_2phase: Bool = False
    if fabs(T_h_in - T_h_out) < 0.001:
        is_h_2phase = True
    var is_c_2phase: Bool = False
    if fabs(T_c_out - T_c_in) < 0.001:
        is_c_2phase = True
    var C_dot_min: Float64
    var C_R: Float64
    C_dot_min = Float64.NaN
    C_R = Float64.NaN
    if is_h_2phase and not is_c_2phase:
        C_dot_min = m_dot_c * (h_c_out - h_c_in) / (T_c_out - T_c_in)
        C_R = 0.0
    elif not is_c_2phase and is_h_2phase:
        C_dot_min = m_dot_h * (h_h_in - h_h_out) / (T_h_in - T_h_out)
        C_R = 0.0
    elif is_c_2phase and is_h_2phase:
        C_dot_min = q_dot / Float64(N_sub_hx) * 1.E10 * (T_h_in - T_c_in)
        C_R = 1.0
    else:
        var C_dot_h: Float64 = m_dot_h * (h_h_in - h_h_out) / (T_h_in - T_h_out)
        var C_dot_c: Float64 = m_dot_c * (h_c_out - h_c_in) / (T_c_out - T_c_in)
        C_dot_min = fmin(C_dot_h, C_dot_c)
        var C_dot_max: Float64 = fmax(C_dot_h, C_dot_c)
        C_R = C_dot_min / C_dot_max
    if C_R != 1.0:
        NTU = log((1.0 - eff * C_R) / max(1.E-6, (1.0 - eff))) / (1.0 - C_R)
    else:
        NTU = eff / max(1.E-6, (1.0 - eff))
    if NTU < 0.0 or not isfinite(NTU):
        NTU = 0.0
    return

def NS_HX_counterflow_eqs__UA_CRM(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties, 
    s_node_info_des: NS_HX_counterflow_eqs__S_hx_node_info,
    P_hot_in: Float64, P_hot_out: Float64,
    h_hot_in: Float64, h_hot_out: Float64,
    m_dot_hot: Float64,
    P_cold_in: Float64, P_cold_out: Float64,
    h_cold_in: Float64, h_cold_out: Float64,
    m_dot_cold: Float64) -> Float64:
    var UA_des: Float64 = s_node_info_des.UA
    var hA_ratio: Float64 = 1.0
    var hA_hot_des: Float64 = UA_des * (1.0 + hA_ratio)
    var hA_cold_des: Float64 = hA_hot_des / hA_ratio
    var P_hot_avg: Float64 = 0.5*(P_hot_in + P_hot_out)
    var h_hot_avg: Float64 = 0.5*(h_hot_in + h_hot_out)
    var c_hot_avg_props: NS_HX_counterflow_eqs__C_hx_fl__Ph__core = NS_HX_counterflow_eqs__C_hx_fl__Ph__core(hot_fl_code, hot_htf_class, P_hot_avg, h_hot_avg, True)
    var hA_hot_scale: Float64 = (c_hot_avg_props.m_k / s_node_info_des.s_fl_hot.k) * \
        pow((m_dot_hot / c_hot_avg_props.m_mu) / (s_node_info_des.s_fl_hot.m_dot / s_node_info_des.s_fl_hot.mu), 0.8)* \
        pow((c_hot_avg_props.m_mu*c_hot_avg_props.m_cp / c_hot_avg_props.m_k) /
        (s_node_info_des.s_fl_hot.mu*s_node_info_des.s_fl_hot.cp/ s_node_info_des.s_fl_hot.k), 0.3)
    var hA_hot: Float64 = hA_hot_des * hA_hot_scale
    var P_cold_avg: Float64 = 0.5*(P_cold_in + P_cold_out)
    var h_cold_avg: Float64 = 0.5*(h_cold_in + h_cold_out)
    var c_cold_avg_props: NS_HX_counterflow_eqs__C_hx_fl__Ph__core = NS_HX_counterflow_eqs__C_hx_fl__Ph__core(cold_fl_code, cold_htf_class, P_cold_avg, h_cold_avg, True)
    var hA_cold_scale: Float64 = (c_cold_avg_props.m_k / s_node_info_des.s_fl_cold.k) * \
        pow((m_dot_cold / c_cold_avg_props.m_mu) / (s_node_info_des.s_fl_cold.m_dot / s_node_info_des.s_fl_cold.mu), 0.8)* \
        pow((c_cold_avg_props.m_mu*c_cold_avg_props.m_cp / c_cold_avg_props.m_k) /
        (s_node_info_des.s_fl_cold.mu*s_node_info_des.s_fl_cold.cp / s_node_info_des.s_fl_cold.k), 0.4)
    var hA_cold: Float64 = hA_cold_des * hA_cold_scale
    var UA: Float64 = 1.0 / (1.0 / hA_hot + 1.0 / hA_cold)
    return UA

def NS_HX_counterflow_eqs__C_MEQ__q_dot__target_UA__c_in_h_out__enth__op(self: NS_HX_counterflow_eqs__C_MEQ__q_dot__target_UA__c_in_h_out__enth, q_dot: Float64, diff_UA_calc: Float64) -> Int:
    var q_dot_calc: Float64 = Float64.NaN
    self.mv_s_node_info_calc.clear()
    self.m_h_hot_in = self.m_h_hot_out + q_dot / self.m_m_dot_hot
    self.m_h_cold_out = self.m_h_cold_in + q_dot / self.m_m_dot_cold
    var m_dot_cold_des: Float64 = self.ms_node_info_des.s_fl_cold.m_dot
    var m_dot_hot_des: Float64 = self.ms_node_info_des.s_fl_hot.m_dot
    var UA_design: Float64 = self.ms_node_info_des.UA
    var UA_target: Float64 = max(1.E-6, UA_design * NS_HX_counterflow_eqs__UA_scale_vs_m_dot(self.m_m_dot_cold / m_dot_cold_des, self.m_m_dot_hot / m_dot_hot_des))
    UA_target = NS_HX_counterflow_eqs__UA_CRM(self.m_hot_fl_code, self.mc_hot_htf_class, self.m_cold_fl_code, self.mc_cold_htf_class,
        self.ms_node_info_des, self.m_P_hot_in, self.m_P_hot_out, self.m_h_hot_in, self.m_h_hot_out, self.m_m_dot_hot,
        self.m_P_cold_in, self.m_P_cold_out, self.m_h_cold_in, self.m_h_cold_out, self.m_m_dot_cold)
    var h_hot_out: Float64
    var T_hot_out: Float64
    h_hot_out = Float64.NaN
    T_hot_out = Float64.NaN
    try:
        NS_HX_counterflow_eqs__calc_req_UA_enth(self.m_hot_fl_code, self.mc_hot_htf_class,
            self.m_cold_fl_code, self.mc_cold_htf_class,
            self.m_N_sub_hx,
            q_dot, self.m_m_dot_cold, self.m_m_dot_hot,
            self.m_h_cold_in, self.m_h_hot_in, self.m_P_cold_in, self.m_P_cold_out, self.m_P_hot_in, self.m_P_hot_out,
            h_hot_out, T_hot_out, self.m_h_cold_out, self.m_T_cold_out,
            self.m_UA_calc, self.m_min_DT, self.m_eff, self.m_NTU, q_dot_calc,
            self.mv_s_node_info_calc)
    except C_csp_exception:
        diff_UA_calc = Float64.NaN
        return -1
    diff_UA_calc = (self.m_UA_calc - UA_target) / UA_target
    return 0

def NS_HX_counterflow_eqs__C_MEQ__q_dot__UA_target__enth__op(self: NS_HX_counterflow_eqs__C_MEQ__q_dot__UA_target__enth, q_dot: Float64, diff_UA: Float64) -> Int:
    var q_dot_calc: Float64 = Float64.NaN
    self.mv_s_node_info.clear()
    try:
        NS_HX_counterflow_eqs__calc_req_UA_enth(self.m_hot_fl_code, self.mc_hot_htf_class,
            self.m_cold_fl_code, self.mc_cold_htf_class,
            self.m_N_sub_hx,
            q_dot, self.m_m_dot_c, self.m_m_dot_h, 
            self.m_h_c_in, self.m_h_h_in, self.m_P_c_in, self.m_P_c_out, self.m_P_h_in, self.m_P_h_out, 
            self.m_h_h_out, self.m_T_h_out, self.m_h_c_out, self.m_T_c_out,
            self.m_UA_calc, self.m_min_DT, self.m_eff, self.m_NTU, q_dot_calc,
            self.mv_s_node_info)
    except C_csp_exception:
        self.m_T_c_out = Float64.NaN
        self.m_T_h_out = Float64.NaN
        diff_UA = Float64.NaN
        return -1
    if self.m_UA_target_type == NS_HX_counterflow_eqs__E_calc_UA:
        self.m_UA_target = NS_HX_counterflow_eqs__UA_CRM(self.m_hot_fl_code, self.mc_hot_htf_class,
            self.m_cold_fl_code, self.mc_cold_htf_class,
            self.mps_node_info_des[],
            self.m_P_h_in, self.m_P_h_out,
            self.m_h_h_in, self.m_h_h_out,
            self.m_m_dot_h,
            self.m_P_c_in, self.m_P_c_out,
            self.m_h_c_in, self.m_h_c_out,
            self.m_m_dot_c)
    diff_UA = (self.m_UA_calc - self.m_UA_target) / self.m_UA_target
    return 0

def NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot__op(self: NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot, q_dot: Float64, min_dT: Float64) -> Int:
    var q_dot_calc: Float64 = Float64.NaN
    self.mv_s_node_info.clear()
    try:
        NS_HX_counterflow_eqs__calc_req_UA_enth(self.m_hot_fl_code, self.mc_hot_htf_class,
            self.m_cold_fl_code, self.mc_cold_htf_class,
            self.m_N_sub_hx,
            q_dot, self.m_m_dot_c, self.m_m_dot_h,
            self.m_h_c_in, self.m_h_h_in, self.m_P_c_in, self.m_P_c_out, self.m_P_h_in, self.m_P_h_out,
            self.m_h_h_out, self.m_T_h_out, self.m_h_c_out, self.m_T_c_out,
            self.m_UA_calc, self.m_min_DT, self.m_eff, self.m_NTU, q_dot_calc,
            self.mv_s_node_info)
    except C_csp_exception as csp_except:
        if csp_except.m_error_code != 11:
            self.m_T_c_out = Float64.NaN
            self.m_T_h_out = Float64.NaN
            min_dT = Float64.NaN
            return -1
    min_dT = self.m_min_DT
    return 0

def NS_HX_counterflow_eqs__solve_q_dot__fixed_eff__enth(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    N_sub_hx: Int,
    h_c_in: Float64, P_c_in: Float64, m_dot_c: Float64, P_c_out: Float64,
    h_h_in: Float64, P_h_in: Float64, m_dot_h: Float64, P_h_out: Float64,
    eff_target: Float64,
    T_c_out: Float64, h_c_out: Float64,
    T_h_out: Float64, h_h_out: Float64,
    q_dot: Float64, eff_calc: Float64, min_DT: Float64, NTU: Float64, UA_calc: Float64,
    v_s_node_info: List[NS_HX_counterflow_eqs__S_hx_node_info]):
    if eff_target > 1.0 or eff_target < 0.0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_eff__enth(...) was sent infeasible effectiveness target")
    var h_h_out_q_max: Float64
    var T_h_out_q_max: Float64
    var h_c_out_q_max: Float64
    var T_c_out_q_max: Float64
    var T_h_in: Float64
    var T_c_in: Float64
    h_h_out_q_max = Float64.NaN
    T_h_out_q_max = Float64.NaN
    h_c_out_q_max = Float64.NaN
    T_c_out_q_max = Float64.NaN
    var q_dot_max: Float64 = NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        h_h_in, P_h_in, P_h_out, m_dot_h,
        h_c_in, P_c_in, P_c_out, m_dot_c,
        h_h_out_q_max, T_h_out_q_max,
        h_c_out_q_max, T_c_out_q_max,
        T_h_in, T_c_in)
    if q_dot_max < 0.0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_eff__enth(...) was sent infeasible hx design conditions")
    elif q_dot_max == 0.0:
        T_c_out = T_c_out_q_max
        h_c_out = h_c_out_q_max
        T_h_out = T_h_out_q_max
        h_h_out = h_h_out_q_max
        q_dot = 0.0
        eff_calc = 0.0
        min_DT = T_h_out - T_c_out
        NTU = 0.0
        UA_calc = 0.0
        return
    var q_dot_eff_target: Float64 = eff_target * q_dot_max
    var hx_min_dt_eq: NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot = NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        N_sub_hx,
        P_c_out, P_h_out,
        h_c_in, P_c_in, m_dot_c,
        h_h_in, P_h_in, m_dot_h)
    var hx_min_dt_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(hx_min_dt_eq)
    var min_dT_eff_target: Float64 = Float64.NaN
    var min_dT_test_code: Int = hx_min_dt_solver.test_member_function(q_dot_eff_target, min_dT_eff_target)
    if min_dT_test_code != 0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_eff__enth(...) failed at q_dot_upper")
    if min_dT_eff_target > 0.0:
        T_c_out = hx_min_dt_eq.m_T_c_out
        h_c_out = hx_min_dt_eq.m_h_c_out
        T_h_out = hx_min_dt_eq.m_T_h_out
        h_h_out = hx_min_dt_eq.m_h_h_out
        q_dot = q_dot_eff_target
        eff_calc = hx_min_dt_eq.m_eff
        min_DT = hx_min_dt_eq.m_min_DT
        NTU = hx_min_dt_eq.m_NTU
        UA_calc = hx_min_dt_eq.m_UA_calc
        v_s_node_info = hx_min_dt_eq.mv_s_node_info
        return
    var q_dot_guess: Float64 = 0.95*q_dot_eff_target
    var min_dT_q_dot_guess: Float64 = Float64.NaN
    min_dT_test_code = hx_min_dt_solver.test_member_function(q_dot_guess, min_dT_q_dot_guess)
    if min_dT_test_code != 0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_eff__enth(...) failed at q_dot_guess")
    var tol: Float64 = 0.1
    var min_dT_target: Float64 = tol
    var q_dot_lower: Float64 = 1.E-10
    if fabs(min_dT_q_dot_guess - min_dT_target) < tol:
        T_c_out = hx_min_dt_eq.m_T_c_out
        h_c_out = hx_min_dt_eq.m_h_c_out
        T_h_out = hx_min_dt_eq.m_T_h_out
        h_h_out = hx_min_dt_eq.m_h_h_out
        q_dot = q_dot_guess
        eff_calc = hx_min_dt_eq.m_eff
        min_DT = hx_min_dt_eq.m_min_DT
        NTU = hx_min_dt_eq.m_NTU
        UA_calc = hx_min_dt_eq.m_UA_calc
        v_s_node_info = hx_min_dt_eq.mv_s_node_info
        return
    hx_min_dt_solver.settings(tol, 1000, q_dot_lower, q_dot_eff_target, False)
    var xy1: C_monotonic_eq_solver__S_xy_pair
    xy1.x = q_dot_eff_target
    xy1.y = min_dT_eff_target
    var xy2: C_monotonic_eq_solver__S_xy_pair
    xy2.x = q_dot_guess
    xy2.y = min_dT_q_dot_guess
    var tol_solved: Float64
    var q_dot_solved: Float64
    q_dot_solved = Float64.NaN
    tol_solved = Float64.NaN
    var iter_solved: Int = -1
    var hx_min_dT_solver_code: Int = hx_min_dt_solver.solve(xy1, xy2, min_dT_target,
        q_dot_solved, tol_solved, iter_solved)
    if hx_min_dT_solver_code != C_monotonic_eq_solver__CONVERGED:
        if not (hx_min_dT_solver_code > C_monotonic_eq_solver__CONVERGED and fabs(tol_solved) <= 1.0):
            raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_min_dT__enth(...) failed to converge")
    T_c_out = hx_min_dt_eq.m_T_c_out
    h_c_out = hx_min_dt_eq.m_h_c_out
    T_h_out = hx_min_dt_eq.m_T_h_out
    h_h_out = hx_min_dt_eq.m_h_h_out
    q_dot = q_dot_solved
    eff_calc = hx_min_dt_eq.m_eff
    min_DT = hx_min_dt_eq.m_min_DT
    NTU = hx_min_dt_eq.m_NTU
    UA_calc = hx_min_dt_eq.m_UA_calc
    v_s_node_info = hx_min_dt_eq.mv_s_node_info
    return

def NS_HX_counterflow_eqs__solve_q_dot__fixed_min_dT__enth(hot_fl_code: Int, hot_htf_class: HTFProperties,
    cold_fl_code: Int, cold_htf_class: HTFProperties,
    N_sub_hx: Int,
    h_c_in: Float64, P_c_in: Float64, m_dot_c: Float64, P_c_out: Float64,
    h_h_in: Float64, P_h_in: Float64, m_dot_h: Float64, P_h_out: Float64,
    min_dT_target: Float64, eff_limit: Float64,
    T_c_out: Float64, h_c_out: Float64,
    T_h_out: Float64, h_h_out: Float64,
    q_dot: Float64, eff_calc: Float64, min_DT: Float64, NTU: Float64, UA_calc: Float64,
    v_s_node_info: List[NS_HX_counterflow_eqs__S_hx_node_info]):
    var h_h_out_q_max: Float64
    var T_h_out_q_max: Float64
    var h_c_out_q_max: Float64
    var T_c_out_q_max: Float64
    var T_h_in: Float64
    var T_c_in: Float64
    h_h_out_q_max = Float64.NaN
    T_h_out_q_max = Float64.NaN
    h_c_out_q_max = Float64.NaN
    T_c_out_q_max = Float64.NaN
    var q_dot_max: Float64 = NS_HX_counterflow_eqs__calc_max_q_dot_enth_2(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        h_h_in, P_h_in, P_h_out, m_dot_h,
        h_c_in, P_c_in, P_c_out, m_dot_c,
        h_h_out_q_max, T_h_out_q_max,
        h_c_out_q_max, T_c_out_q_max,
        T_h_in, T_c_in)
    if q_dot_max < 0.0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_min_dT__enth(...) was sent infeasible hx design conditions")
    elif q_dot_max == 0.0:
        T_c_out = T_c_out_q_max
        h_c_out = h_c_out_q_max
        T_h_out = T_h_out_q_max
        h_h_out = h_h_out_q_max
        q_dot = 0.0
        eff_calc = 0.0
        min_DT = T_h_out - T_c_out
        NTU = 0.0
        UA_calc = 0.0
        return
    if (T_h_in - T_c_in) < min_dT_target:
        T_c_out = T_c_in
        h_c_out = h_c_in
        T_h_out = T_h_in
        h_h_out = h_h_in
        q_dot = 0.0
        eff_calc = 0.0
        min_DT = T_h_out - T_c_out
        NTU = 0.0
        UA_calc = 0.0
        return
    var q_dot_upper: Float64 = eff_limit * q_dot_max
    var hx_min_dt_eq: NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot = NS_HX_counterflow_eqs__C_MEQ__min_dT__q_dot(hot_fl_code, hot_htf_class,
        cold_fl_code, cold_htf_class,
        N_sub_hx,
        P_c_out, P_h_out,
        h_c_in, P_c_in, m_dot_c,
        h_h_in, P_h_in, m_dot_h)
    var hx_min_dt_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(hx_min_dt_eq)
    var tol: Float64 = 0.1
    var q_dot_lower: Float64 = 1.E-10
    hx_min_dt_solver.settings(tol, 1000, q_dot_lower, q_dot_upper, False)
    var min_dT_eff_ideal: Float64 = Float64.NaN
    var min_dT_test_code: Int = hx_min_dt_solver.test_member_function(q_dot_upper, min_dT_eff_ideal)
    if min_dT_test_code != 0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q_dot__fixed_min_dT__enth(...) failed at q_dot_upper")
    if fabs(min_dT_eff_ideal - min_dT_target) < tol or min_dT_eff_ideal - min_dT_target > tol:
        T_c_out = hx_min_dt_eq.m_T_c_out
        h_c_out = hx_min_dt_eq.m_h_c_out
        T_h_out = hx_min_dt_eq.m_T_h_out
        h_h_out = hx_min_dt_eq.m_h_h_out
        q_dot = q_dot_upper
        eff_calc = hx_min_dt_eq.m_eff
        min_DT = hx_min_dt_eq.m_min_DT
        NTU = hx_min_dt_eq.m_NTU
        UA_calc = hx_min_dt_eq.m_UA_calc
        v_s_node_info = hx_min_dt_eq.mv_s_node_info
        return
    var q_dot_guess: Float64 = 0.95*q_dot_upper
    var min_dT_q_dot_guess: Float64 = Float64.NaN
    min_dT_test_code = hx_min_dt_solver.test_member_function(q_dot_guess, min_dT_q_dot_guess)
    if min_dT_test_code != 0:
        raise C_csp_exception("NS_HX_counterflow_eqs::solve_q