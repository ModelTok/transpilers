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
from htf_props import HTFProperties
from lib_util import *
from sam_csp_util import pi
from math import log, exp, pow, abs, min, max, sqrt

@value
struct Storage_HX:
    enum:
        Counter_flow = 2
        Parallel_flow = 3
        Cross_flow_unmixed = 4
        Shell_and_tube = 5

    var m_field_htfProps: HTFProperties
    var m_store_htfProps: HTFProperties
    var m_config: Int
    var m_dt_cold_des: Float64
    var m_dt_hot_des: Float64
    var m_vol_des: Float64
    var m_h_des: Float64
    var m_u_des: Float64
    var m_tank_pairs_des: Float64
    var m_Thtr_hot_des: Float64
    var m_Thtr_cold_des: Float64
    var m_a_cs: Float64
    var m_dia: Float64
    var m_ua: Float64
    var m_dot_des: Float64
    var m_max_q_htr_cold: Float64
    var m_max_q_htr_hot: Float64
    var m_eff_des: Float64
    var m_UA_des: Float64

    def __init__(inout self):
        self.m_config = -1
        self.m_vol_des = Float64.nan
        self.m_h_des = Float64.nan
        self.m_u_des = Float64.nan
        self.m_tank_pairs_des = Float64.nan
        self.m_Thtr_hot_des = Float64.nan
        self.m_Thtr_cold_des = Float64.nan
        self.m_dt_cold_des = Float64.nan
        self.m_dt_hot_des = Float64.nan
        self.m_eff_des = Float64.nan
        self.m_UA_des = Float64.nan
        self.m_a_cs = Float64.nan
        self.m_dia = Float64.nan
        self.m_ua = Float64.nan
        self.m_dot_des = Float64.nan
        self.m_max_q_htr_cold = Float64.nan
        self.m_max_q_htr_hot = Float64.nan

    def define_storage(inout self, fluid_field: borrowed HTFProperties, fluid_store: borrowed HTFProperties, is_direct: Bool,
        config: Int, duty_des: Float64, vol_des: Float64, h_des: Float64, 
        u_des: Float64, tank_pairs_des: Float64, hot_htr_set_point_des: Float64, cold_htr_set_point_des: Float64,
        max_q_htr_cold: Float64, max_q_htr_hot: Float64, dt_hot_des: Float64, dt_cold_des: Float64, T_h_in_des: Float64, T_h_out_des: Float64) -> Bool:
        """ Author: Michael J. Wagner
        Converted from Fortran (sam_mw_trough_Type251) to c++ in November 2012 by Ty Neises """
        self.m_field_htfProps = fluid_field
        self.m_store_htfProps = fluid_store
        self.m_config = config
        self.m_vol_des = vol_des
        self.m_h_des = h_des
        self.m_u_des = u_des
        self.m_tank_pairs_des = tank_pairs_des
        self.m_Thtr_hot_des = hot_htr_set_point_des
        self.m_Thtr_cold_des = cold_htr_set_point_des
        self.m_dt_cold_des = dt_cold_des
        self.m_dt_hot_des = dt_hot_des
        self.m_max_q_htr_cold = max_q_htr_cold
        self.m_max_q_htr_hot = max_q_htr_hot
        self.m_a_cs = self.m_vol_des / (self.m_h_des * self.m_tank_pairs_des)  # [m2] Cross-sectional area of a single tank
        self.m_dia = pow((self.m_a_cs / pi), 0.5) * 2.0  # [m] The diameter of a single tank
        self.m_ua = self.m_u_des * (self.m_a_cs + pi * self.m_dia * self.m_h_des) * self.m_tank_pairs_des  # [W/K]
        if is_direct:
            self.m_eff_des = -1.2345
            self.m_UA_des = -1.2345
        else:
            var q_trans: Float64 = duty_des  # [W] heat exchanger duty
            var T_ave: Float64 = (T_h_in_des + T_h_out_des) / 2.0  # [K] Average hot side temperature
            var c_h: Float64 = self.m_field_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K] Specific heat of hot side fluid at hot side average temperature 
            var c_c: Float64 = self.m_store_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K] Specific heat of cold side fluid at hot side average temperature (estimate, but should be close)
            var T_c_out: Float64 = T_h_in_des - dt_hot_des  # [K]
            var T_c_in: Float64 = T_h_out_des - dt_cold_des  # [K]
            var m_dot_h: Float64 = q_trans / (c_h * (T_h_in_des - T_h_out_des))  # [kg/s]
            var m_dot_c: Float64 = q_trans / (c_c * (T_c_out - T_c_in))  # [kg/s]
            self.m_dot_des = 0.5 * (m_dot_h + m_dot_c)  # [kg/s] 7/9/14, twn: added
            var c_dot_h: Float64 = m_dot_h * c_h  # [W/K]
            var c_dot_c: Float64 = m_dot_c * c_c  # [W/K]
            var c_dot_max: Float64 = max(c_dot_h, c_dot_c)  # [W/K]
            var c_dot_min: Float64 = min(c_dot_h, c_dot_c)  # [W/K]
            var cr: Float64 = c_dot_min / c_dot_max  # [W/K]
            var q_max: Float64 = c_dot_min * (T_h_in_des - T_c_in)  # [W]
            self.m_eff_des = q_trans / q_max  # [-]
            if cr > 1.0 or cr < 0.0:
                return False
            var NTU: Float64
            var ff: Float64
            var ee1: Float64
            var ee: Float64
            if config == Storage_HX.Counter_flow:
                if cr < 1.0:
                    NTU = log((1.0 - self.m_eff_des * cr) / (1.0 - self.m_eff_des)) / (1.0 - cr)
                else:
                    NTU = self.m_eff_des / (1.0 - self.m_eff_des)
            elif config == Storage_HX.Parallel_flow:
                NTU = log(1.0 - self.m_eff_des * (1.0 + cr)) / (1.0 + cr)
            elif config == Storage_HX.Cross_flow_unmixed:
                NTU = -log(1.0 + log(1.0 - self.m_eff_des * cr) / cr)
            elif config == Storage_HX.Shell_and_tube:
                ff = (self.m_eff_des * cr - 1.0) / (self.m_eff_des - 1.0)
                ee1 = (ff - 1.0) / (ff - cr)
                ee = (2.0 - ee1 * (1.0 + cr)) / (ee1 * pow((1.0 + cr * cr), 0.5))
                NTU = log((ee + 1.0) / (ee - 1.0)) / pow((1.0 + cr * cr), 0.5)
            else:
                return False
            self.m_UA_des = NTU * c_dot_min  # [W/K]
        return True

    def hx_perf_q_transfer(inout self, is_hot_side_mdot: Bool, is_storage_side: Bool, T_hot_in: Float64, m_dot_known: Float64, T_cold_in: Float64, inout q_trans: Float64) -> Bool:
        var eff: Float64 = Float64.nan
        var T_hot_out: Float64 = Float64.nan
        var T_cold_out: Float64 = Float64.nan
        var m_dot_solved: Float64 = Float64.nan
        return self.hx_performance(is_hot_side_mdot, is_storage_side, T_hot_in, m_dot_known, T_cold_in, eff, T_hot_out, T_cold_out, q_trans, m_dot_solved)

    def hx_performance(inout self, is_hot_side_mdot: Bool, is_storage_side: Bool, T_hot_in: Float64, m_dot_known: Float64, T_cold_in: Float64, 
        inout eff: Float64, inout T_hot_out: Float64, inout T_cold_out: Float64, inout q_trans: Float64, inout m_dot_solved: Float64) -> Bool:
        """ Author: Michael J. Wagner
        Converted from Fortran (sam_mw_trough_Type251) to c++ in November 2012 by Ty Neises
        This function combines "hx_perf" and "hx_reverse" fortran subroutines 
        7/19/14, twn: Modified performance calcs so UA is fixed, not deltaTs """
        var m_dot_hot: Float64
        var m_dot_cold: Float64
        var c_hot: Float64
        var c_cold: Float64
        var c_dot: Float64
        var T_ave: Float64 = (T_hot_in + T_cold_in) / 2.0  # [K]
        if is_hot_side_mdot:  # know hot side mass flow rate - assuming always know storage side and solving for field
            if is_storage_side:
                c_cold = self.m_field_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
                c_hot = self.m_store_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
            else:
                c_hot = self.m_field_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
                c_cold = self.m_store_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
            m_dot_hot = m_dot_known
            var c_dot_hot: Float64 = m_dot_hot * c_hot
            c_dot = c_dot_hot
            m_dot_cold = c_dot_hot / c_cold
            m_dot_solved = m_dot_cold
        else:  # know cold side mass flow rate - assuming always know storage side and solving for field
            if is_storage_side:
                c_hot = self.m_field_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
                c_cold = self.m_store_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
            else:
                c_cold = self.m_field_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
                c_hot = self.m_store_htfProps.Cp(T_ave) * 1000.0  # [J/kg-K]
            m_dot_cold = m_dot_known
            var c_dot_cold: Float64 = m_dot_cold * c_cold
            c_dot = c_dot_cold
            m_dot_hot = c_dot_cold / c_hot
            m_dot_solved = m_dot_hot
        var m_dot_od: Float64 = 0.5 * (m_dot_cold + m_dot_hot)
        var UA: Float64 = self.m_UA_des * pow(m_dot_od / self.m_dot_des, 0.8)
        var NTU: Float64 = UA / c_dot
        eff = NTU / (1.0 + NTU)
        var q_dot_max: Float64 = c_dot * (T_hot_in - T_cold_in)
        q_trans = eff * q_dot_max
        T_hot_out = T_hot_in - q_trans / c_dot
        T_cold_out = T_cold_in + q_trans / c_dot
        q_trans = q_trans * 1.0e-6  # [MWt] 
        if eff <= 0.0 or eff > 1.0:
            return False
        else:
            return True

    def mixed_tank(inout self, is_hot_tank: Bool, dt: Float64, m_prev: Float64, T_prev: Float64, m_dot_in: Float64, m_dot_out: Float64, 
        T_in: Float64, T_amb: Float64, inout T_ave: Float64, inout vol_ave: Float64, 
        inout q_loss: Float64, inout T_fin: Float64, inout vol_fin: Float64, inout m_fin: Float64, inout q_heater: Float64) -> Bool:
        """ !Subroutine for storage tanks based on type230 - but rewritten by Mike
            Converted from Fortran (sam_mw_trough_Type251) to c++ in November 2012 by Ty Neises """
        /**********************************************************************************
        !*********************************************************************************
        !** This function consists largely of TRNSYS code and a new, independent
        !** function should replace the functionality of this code before code is publically released.
        !*********************************************************************************
        !*********************************************************************************
        !----------Inputs and parameters-------------------------------------------------------------------
        !   * m0        - [kg] total HTF mass in the tank at the end of the last time step
        !   * T0        - [K] Temperature of the HTF at the end of the last time step
        !   * m_dot_in  - [kg/s] mass flow rate of HTF into the tank
        !   * m_dot_out - [kg/s] mass flow rate leaving the tank
        !   * T_in      - [K] Temperature of the HTF entering the tank
        !   * T_amb     - [K] Temperature of the ambient air
        !----------Outputs---------------------------------------------------------------------------------
        !   * T_ave     - [K] Average HTF temperature throughout the timestep
        !   * vol_ave   - [m3] Average HTF volume level during the timestep
        !   * q_loss    - [MWt] Total thermal loss rate from the tank
        !   * T_fin     - [K] Temperature of the HTF at the end of the timestep
        !   * vol_fin   - [m3] Volume of the HTF at the end of the timestep (total volume)
        !   * m_fin     - [kg] total mass at the end of the timestep
        !   * q_heater  - [MWt] Total energy consumed by the freeze protection heater
        !--------------------------------------------------------------------------------------------------*/
        var rho: Float64 = self.m_store_htfProps.dens(T_prev, 1.0)  # [kg/m^3] Density
        var cp: Float64 = self.m_store_htfProps.Cp(T_prev) * 1000.0  # [J/kg-K] Specific heat
        m_fin = m_prev + dt * (m_dot_in - m_dot_out)  # [kg] Available mass at the end of the timestep
        var m_min: Float64
        var m_dot_out_adj: Float64  # limit m_dot_out so the ending mass is above a given minimum to eliminate erratic behavior
        var tank_is_empty: Bool = False
        m_min = 0.001  # minimum tank mass for use in the calculations
        if m_fin < m_min:
            m_fin = m_min
            tank_is_empty = True
            m_dot_out_adj = m_dot_in - (m_min - m_prev) / dt
        else:
            m_dot_out_adj = m_dot_out
        var m_ave: Float64 = (m_prev + m_fin) / 2.0  # [kg] Average mass 
        vol_fin = m_fin / rho  # [m3] Available volume at the end of the timestep
        vol_ave = m_ave / rho  # [m3] Average volume
        if m_prev <= 1.0e-4 and tank_is_empty == True:
            if m_dot_in > 0.0:
                T_fin = T_ave = T_in
            else:
                T_fin = T_ave = T_prev
            vol_ave = 0.0
            q_loss = 0.0
            vol_fin = 0.0
            m_fin = 0.0
            q_heater = 0.0
            return False
        var B: Float64 = m_dot_in + self.m_ua / cp  # [kg/s] + [W/K]*[kg-K/J]
        var D: Float64
        var G: Float64
        var H1: Float64
        var A1: Float64
        var E: Float64
        var C: Float64
        var CC: Float64
        var DD: Float64
        var AA: Float64
        var BB: Float64
        if (abs(m_dot_in - m_dot_out_adj) < B * 1.0e-5) or ((m_dot_in < 0.001) and (m_dot_out_adj < 0.001)):
            D = m_dot_in * T_in + (self.m_ua / cp) * T_amb
            G = -B / m_prev
            H1 = 1.0 / (dt * (-B))
            A1 = D - B * T_prev
            E = A1 * exp(dt * G)
            T_fin = (E - D) / (-B)
            T_ave = H1 * ((E - A1) / G) + D / B
        else:
            C = m_dot_in - m_dot_out_adj
            D = m_dot_in * T_in + self.m_ua / cp * T_amb
            CC = T_prev - D / B
            DD = pow(max((1.0 + (C * dt) / m_prev), 0.0), (-B / C))  # MJW 9.2.2010 :: limit to positive argument
            T_fin = CC * DD + D / B
            AA = (T_prev - D / B) / (C - B)
            BB = pow(max((1.0 + (C * dt) / m_prev), 0.0), (1.0 - B / C))
            T_ave = AA * (m_prev / dt) * (BB - 1.0) + D / B
        var htr_set_point: Float64
        var max_q_htr: Float64
        var Q_vol: Float64
        var Q_flow: Float64
        if is_hot_tank:
            htr_set_point = self.m_Thtr_hot_des
            max_q_htr = self.m_max_q_htr_hot
        else:
            htr_set_point = self.m_Thtr_cold_des
            max_q_htr = self.m_max_q_htr_cold
        if T_fin < htr_set_point:
            Q_vol = cp * vol_fin * rho / dt * (htr_set_point - T_fin) / (1.0e6)  # MW  4/30/12 - Fixed unit conversion
            Q_flow = cp * m_dot_out_adj * (htr_set_point - T_fin) / (1.0e6)  # MW  4/30/12 - Fixed unit conversion
            q_heater = min(Q_flow + Q_vol, max_q_htr)  # MW
            T_fin = T_prev + dt * min(Q_vol * 1.0e6, max_q_htr * 1.0e6) / (cp * rho * vol_fin)
            T_ave = (T_fin + T_prev) / 2.0
        else:
            q_heater = 0.0
        q_loss = self.m_ua * (T_ave - T_amb) / 1.0e6  # [MW]
        if tank_is_empty:
            vol_fin = 0.0
            m_fin = 0.0
        return False