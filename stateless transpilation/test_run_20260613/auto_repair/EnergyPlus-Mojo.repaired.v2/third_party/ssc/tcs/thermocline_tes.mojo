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

# No include guards needed in Mojo

from sam_csp_util import CSP
from htf_props import HTFProperties

from math import floor, ceil, max, min, abs, exp, sqrt

class TC_Fill_Props:
    def __init__(self):
        self.m_fill_material = 0   # placeholder

    def Set_TC_Material(self, fill_material: Int) -> Bool:
        self.m_fill_material = fill_material
        if self.m_fill_material > Quartzite or self.m_fill_material < Taconite:
            return False
        else:
            return True

    def __del__(self):

    # enum (anonymous) translated as class-level constants
    alias Taconite: Int = 1
    alias Calcium_Carbonate: Int = 2
    alias Gravel: Int = 3
    alias Marbel: Int = 4
    alias Limestone: Int = 5
    alias Carbon_Steel: Int = 6
    alias Sand: Int = 7
    alias Quartzite: Int = 8

    def dens_bed(self) -> Float64:
        if self.m_fill_material == Taconite:
            return 3800.0
        elif self.m_fill_material == Calcium_Carbonate:
            return 2710.0
        elif self.m_fill_material == Gravel:
            return 2643.0
        elif self.m_fill_material == Marbel:
            return 2680.0
        elif self.m_fill_material == Limestone:
            return 2320.0
        elif self.m_fill_material == Carbon_Steel:
            return 7854.0
        elif self.m_fill_material == Sand:
            return 1515.0
        elif self.m_fill_material == Quartzite:
            return 2640.0
        else:
            return -999.0

    def cp_bed(self) -> Float64:
        if self.m_fill_material == Taconite:
            return 0.651
        elif self.m_fill_material == Calcium_Carbonate:
            return 0.835
        elif self.m_fill_material == Gravel:
            return 1.065
        elif self.m_fill_material == Marbel:
            return 0.83
        elif self.m_fill_material == Limestone:
            return 0.81
        elif self.m_fill_material == Carbon_Steel:
            return 0.567
        elif self.m_fill_material == Sand:
            return 0.8
        elif self.m_fill_material == Quartzite:
            return 1.105
        else:
            return -999.0

    def k_bed(self) -> Float64:
        if self.m_fill_material == Taconite:
            return 2.1
        elif self.m_fill_material == Calcium_Carbonate:
            return 2.7
        elif self.m_fill_material == Gravel:
            return 1.8
        elif self.m_fill_material == Marbel:
            return 2.8
        elif self.m_fill_material == Limestone:
            return 2.15
        elif self.m_fill_material == Carbon_Steel:
            return 48.0
        elif self.m_fill_material == Sand:
            return 0.27
        elif self.m_fill_material == Quartzite:
            return 5.38
        else:
            return -999.0

    var m_fill_material: Int = 0


class Thermocline_TES:
    def __init__(self):
        self.m_Q_dot_htr_kJ = Float64.nan
        self.m_Q_dot_losses = Float64.nan
        self.m_T_hot_node = Float64.nan
        self.m_T_cold_node = Float64.nan
        self.m_T_max = Float64.nan
        self.m_f_hot = Float64.nan
        self.m_f_cold = Float64.nan

    def __del__(self):

    def Initialize_TC(
        self,
        H_m: Float64,
        A_m2: Float64,
        Fill: Int,
        U_kJ_hrm2K: Float64,
        Utop_kJ_hrm2K: Float64,
        Ubot_kJ_hrm2K: Float64,
        f_void: Float64,
        capfac: Float64,
        Thmin_C: Float64,
        Tcmax_C: Float64,
        nodes: Int,
        T_hot_init_C: Float64,
        T_cold_init_C: Float64,
        TC_break: Float64,
        T_htr_set_C: Float64,
        tank_max_heat_MW: Float64,
        tank_pairs: Int,
        htf_fluid_props: HTFProperties
    ) -> Bool:
        # assign HTF property class
        self.htfProps = htf_fluid_props  # need to store copy? assume struct copy
        self.m_num_TC_max = 10000
        self.m_H = H_m
        self.m_A = A_m2
        self.m_U = U_kJ_hrm2K
        self.m_U_top = Utop_kJ_hrm2K
        self.m_U_bot = Ubot_kJ_hrm2K
        self.m_void = f_void
        self.m_capfac = capfac
        self.m_Thmin = Thmin_C
        self.m_Th_avail_min = self.m_Thmin + 5.0
        self.m_Tcmax = Tcmax_C
        self.m_Tc_avail_max = self.m_Tcmax - 5.0
        self.m_nodes = nodes
        self.m_T_hot_init = T_hot_init_C
        self.m_T_cold_init = T_cold_init_C
        self.m_TC_break = TC_break
        self.m_T_htr_set = T_htr_set_C
        self.m_tank_max_heat = tank_max_heat_MW
        self.m_tank_pairs = tank_pairs
        var nodes_break: Int = (int)( (1.0 - self.m_TC_break)*(self.m_nodes) ) - 1
        self.m_T_hot_in_min = 0.9*self.m_T_hot_init + 0.1*self.m_T_cold_init
        self.m_T_cold_in_max = 0.1*self.m_T_hot_init + 0.9*self.m_T_cold_init

        # Initialize vectors
        self.m_T_prev = DynamicVector[Float64](self.m_nodes, 1.0)
        self.m_T_start = DynamicVector[Float64](self.m_nodes, 1.0)
        self.m_T_ave = DynamicVector[Float64](self.m_nodes, 1.0)
        self.m_T_end = DynamicVector[Float64](self.m_nodes, 1.0)

        if nodes_break <= 0:
            for i in range(len(self.m_T_prev)):
                self.m_T_prev[i] = self.m_T_cold_init
        elif nodes_break >= self.m_nodes - 1:
            for i in range(len(self.m_T_prev)):
                self.m_T_prev[i] = self.m_T_hot_init
        else:
            for i in range(nodes_break):
                self.m_T_prev[i] = self.m_T_hot_init
            for i in range(nodes_break, self.m_nodes):
                self.m_T_prev[i] = self.m_T_cold_init

        self.m_T_final_ave_prev = 0.0
        for i in range(self.m_nodes):
            self.m_T_final_ave_prev += self.m_T_prev[i]   # .at(i, 0);
        self.m_T_final_ave_prev /= self.m_nodes

        if not self.fillProps.Set_TC_Material(Fill):
            return False

        var T_prop: Float64 = 0.5*(self.m_T_hot_init + self.m_T_cold_init)
        var cond_htf: Float64 = self.htfProps.cond(T_prop + 273.15)
        var cond_fill: Float64 = self.fillProps.k_bed()
        self.m_cond = f_void*cond_htf + (1.0 - f_void)*cond_fill
        self.m_cp_a = self.htfProps.Cp(T_prop + 273.15)
        self.m_rho_a = self.htfProps.dens(T_prop + 273.15, 1.0)
        self.m_cp_r = self.fillProps.cp_bed()
        self.m_rho_r = self.fillProps.dens_bed()
        self.m_P = sqrt(self.m_A / CSP.pi) * 2.0 * CSP.pi
        self.m_vol = self.m_A * self.m_H
        self.m_UA = self.m_U * self.m_P * self.m_H / self.m_nodes
        self.m_UA_top = self.m_U_top * self.m_A
        self.m_UA_bot = self.m_U_bot * self.m_A
        self.m_ef_cond = self.m_cond * self.m_A * self.m_nodes / self.m_H
        self.m_cap = (
            self.m_vol * self.m_void * self.m_cp_a * self.m_rho_a +
            self.m_vol * (1.0 - self.m_void) * self.m_cp_r * self.m_rho_r
        )
        self.m_e_tes = self.m_cap * (self.m_T_hot_init - self.m_T_cold_init)
        self.m_cap_node = self.m_cap / self.m_nodes
        var tol_q: Float64 = 0.01
        self.m_tol_TC = 0.5*0.5*tol_q*self.m_UA / (self.m_cond*self.m_A / (self.m_H / self.m_nodes))
        self.m_tol_TC = max(1.E-10, min(0.001, self.m_tol_TC))
        return True

    def Solve_TC(
        self,
        T_hot_in_C: Float64,
        flow_h_kghr: Float64,
        T_cold_in_C: Float64,
        flow_c_kghr: Float64,
        T_env_C: Float64,
        mode_in: Int,
        Q_dis_target_W: Float64,
        Q_cha_target_W: Float64,
        f_storage_in: Float64,
        time_hr: Float64,
        inout m_dis_avail_tot: Float64,
        inout T_dis_avail_C: Float64,
        inout m_ch_avail_tot: Float64,
        inout T_ch_avail_C: Float64,
        inout Q_dot_out_W: Float64,
        inout Q_dot_losses: Float64,
        inout T_hot_bed_C: Float64,
        inout T_cold_bed_C: Float64,
        inout T_max_bed_C: Float64,
        inout f_hot: Float64,
        inout f_cold: Float64,
        inout Q_dot_htr_kJ: Float64
    ) -> Bool:
        var T_hot: Float64 = T_hot_in_C
        var flow_h: Float64 = flow_h_kghr / self.m_tank_pairs
        var T_cold: Float64 = T_cold_in_C
        var flow_c: Float64 = flow_c_kghr / self.m_tank_pairs
        var T_env: Float64 = T_env_C
        var mode: Int = mode_in
        var Q_dis_target: Float64 = Q_dis_target_W / self.m_tank_pairs
        var Q_cha_target: Float64 = Q_cha_target_W / self.m_tank_pairs
        var f_storage: Float64 = f_storage_in
        var delt: Float64 = time_hr

        self.m_T_start = self.m_T_prev.copy()
        self.m_T_ave = self.m_T_prev.copy()
        self.m_T_end = self.m_T_prev.copy()

        var I_flow: Int = -1
        var know_mdot: Bool = False
        var q_target: Float64 = Float64.nan
        var m_dot: Float64 = Float64.nan

        if Q_dis_target > 0.0:
            I_flow = 2
            know_mdot = False
            q_target = Q_dis_target
        elif Q_cha_target > 0.0:
            I_flow = 1
            know_mdot = False
            q_target = Q_cha_target
        elif flow_c > 0.0:
            I_flow = 2
            know_mdot = True
            m_dot = flow_c
        elif flow_h > 0.0:
            I_flow = 1
            know_mdot = True
            m_dot = flow_h
        else:
            I_flow = 1
            know_mdot = False
            m_dot = flow_h
            q_target = 0.0

        var iclim: Int = 0
        var ihlim: Int = 0
        var Thtemp: Float64 = 0.0
        var Tctemp: Float64 = 0.0

        for k in range(self.m_nodes):
            if self.m_T_start[k] > self.m_Th_avail_min:
                ihlim = k
                Thtemp += self.m_T_start[k]
            if self.m_T_start[self.m_nodes - 1 - k] < self.m_Tc_avail_max:
                iclim = k
                Tctemp += self.m_T_start[self.m_nodes - 1 - k]

        var fhlim: Float64 = ihlim
        var fclim: Float64 = iclim
        Thtemp /= max(fhlim + 1.0, 1.0)
        Tctemp /= max(fclim + 1.0, 1.0)
        fhlim = (fhlim + 1.0) / self.m_nodes
        fclim = (fclim + 1.0) / self.m_nodes

        var ChargeNodes: Int = min(self.m_nodes - 1, max(0, (int)floor(f_storage * self.m_nodes)))
        var Qd_fill: Float64 = Float64.nan
        var flc: Float64 = Float64.nan

        if T_cold > self.m_T_cold_in_max:
            Qd_fill = 0.0
            flow_c = 0.0
            flc = self.m_cp_a * flow_c
        else:
            Qd_fill = max(0.0, self.m_vol * fhlim * self.m_rho_r * self.m_cp_r * (1.0 - self.m_void) * max(Thtemp - T_cold, 0.0)) \
                      + max(0.0, self.m_vol * fhlim * self.m_void * self.m_rho_a * self.m_cp_a * max(Thtemp - T_cold, 0.0))

        var Qc_fill: Float64 = Float64.nan
        var flh: Float64 = Float64.nan

        if T_hot < self.m_T_hot_in_min:
            Qc_fill = 0.0
            flow_h = 0.0
            flh = self.m_cp_a * flow_h
        else:
            Qc_fill = max(0.0, self.m_vol * fclim * self.m_rho_r * self.m_cp_r * (1.0 - self.m_void) * max(T_hot - Tctemp, 0.0)) \
                      + max(0.0, self.m_vol * fclim * self.m_void * self.m_rho_a * self.m_cp_a * max(T_hot - Tctemp, 0.0))

        var m_disch_avail: Float64 = 0.0
        Qd_fill = Qd_fill / (3.6 * delt)
        m_disch_avail = Qd_fill / (self.m_cp_a * max(Thtemp - T_cold, 1.0)) * 3.6

        var m_charge_avail: Float64 = 0.0
        Qc_fill = Qc_fill / (3.6 * delt)
        m_charge_avail = Qc_fill / (self.m_cp_a * max(T_hot - Tctemp, 1.0)) * 3.6

        if mode == 2:
            m_dis_avail_tot = m_disch_avail * self.m_tank_pairs
            T_dis_avail_C = self.m_T_start[0]
            m_ch_avail_tot = m_charge_avail * self.m_tank_pairs
            T_ch_avail_C = self.m_T_start[self.m_nodes - 1]
            return True

        var m_dot_lower: Float64 = Float64.nan
        var m_dot_upper: Float64 = Float64.nan

        if know_mdot:
            m_dot_lower = 0.0
            m_dot_upper = m_dot
        elif I_flow == 2:
            m_dot = min(Q_dis_target, Qd_fill) / (self.m_cp_a * max(Thtemp - T_cold, 1.0)) * 3.6
        elif I_flow == 1:
            m_dot = min(Q_cha_target, Qc_fill) / (self.m_cp_a * max(T_hot - Tctemp, 1.0)) * 3.6

        m_dot_upper = 1.5 * m_dot
        m_dot_lower = 0.5 * m_dot

        var m_dot_low0: Float64 = m_dot_lower
        var m_dot_up0: Float64 = m_dot_upper
        var diff_q_target: Float64 = 999.0
        var q_iter: Int = 0
        var TC_limit: Int = 0
        var upflag: Bool = False
        var lowflag: Bool = False
        var mdot_iter: Bool = False
        var q_tol: Float64 = 0.0001
        var t_tol: Float64 = 0.050
        var y_upper: Float64 = Float64.nan
        var y_lower: Float64 = Float64.nan
        var q_calc: Float64 = Float64.nan
        var full: Bool = True
        var num_TC: Int = -1
        var T_disch_avail: Float64 = Float64.nan
        var T_charge_avail: Float64 = Float64.nan

        while (abs(diff_q_target) > q_tol or TC_limit != 0) and q_iter < 40:
            q_iter += 1
            full = True

            if q_iter > 1:
                if TC_limit == 1:
                    m_dot_upper = m_dot
                    upflag = False
                    m_dot = 0.5 * m_dot_upper + 0.5 * m_dot_lower
                elif TC_limit == 2:
                    m_dot_lower = m_dot
                    lowflag = False
                    m_dot = 0.5 * m_dot_upper + 0.5 * m_dot_lower
                elif upflag and lowflag:
                    if diff_q_target < q_tol:
                        m_dot_upper = m_dot
                        y_upper = diff_q_target
                    else:
                        m_dot_lower = m_dot
                        y_lower = diff_q_target
                    m_dot = y_upper / (y_upper - y_lower) * (m_dot_lower - m_dot_upper) + m_dot_upper
                else:
                    if diff_q_target > q_tol:
                        m_dot_upper = m_dot
                        upflag = True
                        y_upper = diff_q_target
                    elif diff_q_target < q_tol:
                        m_dot_lower = m_dot
                        lowflag = True
                        y_lower = diff_q_target
                    if upflag and lowflag:
                        m_dot = y_upper / (y_upper - y_lower) * (m_dot_lower - m_dot_upper) + m_dot_upper
                    else:
                        m_dot = 0.5 * m_dot_upper + 0.5 * m_dot_lower

            if (m_dot - m_dot_low0) / m_dot_low0 < 0.0005:
                m_dot_low0 = 0.0
                m_dot_lower = m_dot_low0
                m_dot = 0.5 * m_dot_upper + 0.5 * m_dot_lower
                lowflag = False

            if (m_dot_up0 - m_dot) / m_dot_up0 < 0.0005:
                m_dot_up0 = 2.0 * m_dot_up0
                m_dot_upper = m_dot_up0
                m_dot = 0.5 * m_dot_upper + 0.5 * m_dot_lower
                upflag = True

            if I_flow == 1:
                flow_h = m_dot
            elif I_flow == 2:
                flow_c = m_dot

            flh = self.m_cp_a * flow_h
            flc = self.m_cp_a * flow_c
            var tau: Float64 = (0.632) * (self.m_cap / self.m_nodes) / max(flh, flc)
            var TC_timestep: Float64 = tau
            num_TC = -1

            if TC_timestep < delt:
                if delt - (int)(delt / TC_timestep) * TC_timestep != 0.0:
                    num_TC = (int)ceil(delt / TC_timestep)
                else:
                    num_TC = (int)(delt / TC_timestep)
                num_TC = min(self.m_num_TC_max, num_TC)
                TC_timestep = delt / num_TC
            else:
                num_TC = 1
                TC_timestep = delt

            self.m_T_start = self.m_T_prev.copy()
            self.m_T_ave = self.m_T_prev.copy()
            self.m_T_end = self.m_T_prev.copy()

            self.m_T_ts_ave = DynamicVector[Float64]()
            self.m_T_ts_ave.reserve(num_TC)
            for i in range(num_TC):
                self.m_T_ts_ave.append(0.0)

            self.m_Q_losses = DynamicVector[Float64]()
            self.m_Q_losses.reserve(num_TC)
            for i in range(num_TC):
                self.m_Q_losses.append(0.0)

            self.m_Q_htr = DynamicVector[Float64]()
            self.m_Q_htr.reserve(num_TC)
            for i in range(num_TC):
                self.m_Q_htr.append(0.0)

            self.m_T_cout_ave = DynamicVector[Float64]()
            self.m_T_cout_ave.reserve(num_TC)
            for i in range(num_TC):
                self.m_T_cout_ave.append(0.0)

            self.m_T_hout_ave = DynamicVector[Float64]()
            self.m_T_hout_ave.reserve(num_TC)
            for i in range(num_TC):
                self.m_T_hout_ave.append(0.0)

            for tcn in range(num_TC):
                var iter: Int = 0
                var max_T_diff: Float64 = 999.9

                while iter < 30 and max_T_diff > self.m_tol_TC:
                    iter += 1
                    self.m_T_ts_ave[tcn] = 0.0
                    self.m_Q_losses[tcn] = 0.0
                    max_T_diff = 0.0

                    for j in range(self.m_nodes):
                        var aa: Float64 = Float64.nan
                        var bb: Float64 = Float64.nan
                        var UA_hl: Float64 = Float64.nan
                        var i: Int = -1

                        if I_flow == 1:
                            i = j
                            if i == 0:
                                aa = -(flh + self.m_UA + self.m_UA_top + self.m_ef_cond) / self.m_cap_node
                                bb = (flh * T_hot + (self.m_UA + self.m_UA_top) * T_env + self.m_ef_cond * self.m_T_ave[i+1]) / self.m_cap_node
                                UA_hl = self.m_UA + self.m_UA_top
                            elif i == self.m_nodes - 1:
                                aa = -(flh + self.m_UA + self.m_UA_bot + self.m_ef_cond) / (self.m_cap_node * self.m_capfac)
                                bb = (flh * self.m_T_ave[i-1] + (self.m_UA + self.m_UA_bot) * T_env + self.m_ef_cond * self.m_T_ave[i-1]) / (self.m_cap_node * self.m_capfac)
                                UA_hl = self.m_UA + self.m_UA_bot
                            else:
                                aa = -(flh + self.m_UA + 2.0 * self.m_ef_cond) / self.m_cap_node
                                bb = (flh * self.m_T_ave[i-1] + self.m_UA * T_env + self.m_ef_cond * (self.m_T_ave[i-1] + self.m_T_ave[i+1])) / self.m_cap_node
                                UA_hl = self.m_UA
                        else:
                            i = self.m_nodes - 1 - j
                            if i == 0:
                                aa = -(flc + self.m_UA + self.m_UA_top + self.m_ef_cond) / self.m_cap_node
                                bb = (flc * self.m_T_ave[i+1] + (self.m_UA + self.m_UA_top) * T_env + self.m_ef_cond * self.m_T_ave[i+1]) / self.m_cap_node
                                UA_hl = self.m_UA + self.m_UA_top
                            elif i == self.m_nodes - 1:
                                aa = -(flc + self.m_UA + self.m_UA_bot + self.m_ef_cond) / (self.m_cap_node * self.m_capfac)
                                bb = (flc * T_cold + (self.m_UA + self.m_UA_bot) * T_env + self.m_ef_cond * self.m_T_ave[i-1]) / (self.m_cap_node * self.m_capfac)
                                UA_hl = self.m_UA + self.m_UA_bot
                            else:
                                aa = -(flc + self.m_UA + 2.0 * self.m_ef_cond) / self.m_cap_node
                                bb = (flc * self.m_T_ave[i+1] + self.m_UA * T_env + self.m_ef_cond * (self.m_T_ave[i+1] + self.m_T_ave[i-1])) / self.m_cap_node
                                UA_hl = self.m_UA

                        var T_node_initial: Float64 = self.m_T_start[i]
                        var T_final: Float64
                        var T_average: Float64

                        if aa != 0.0:
                            T_final = (T_node_initial + bb / aa) * exp(aa * TC_timestep) - bb / aa
                            T_average = (T_node_initial + bb / aa) / aa / TC_timestep * (exp(aa * TC_timestep) - 1.0) - bb / aa
                        else:
                            T_final = bb * TC_timestep + T_node_initial
                            T_average = (T_final + T_node_initial) / 2.0

                        var Q_htr_max: Float64 = Float64.nan
                        if T_final < self.m_T_htr_set:
                            Q_htr_max = self.m_tank_max_heat * 1000.0 * TC_timestep * 3600.0
                            if self.m_Q_htr[tcn] + self.m_cap_node * (self.m_T_htr_set - T_final) < self.m_tank_max_heat:
                                self.m_Q_htr[tcn] = self.m_Q_htr[tcn] + self.m_cap_node * (self.m_T_htr_set - T_final)
                                T_final = self.m_T_htr_set
                            else:
                                T_final = (self.m_tank_max_heat - self.m_Q_htr[tcn]) / self.m_cap_node + T_final

                        self.m_T_end[i] = T_final
                        max_T_diff = max(max_T_diff, abs(self.m_T_ave[i] - T_average))
                        self.m_T_ave[i] = T_average
                        self.m_T_ts_ave[tcn] += T_average
                        self.m_Q_losses[tcn] += UA_hl * (T_average - T_env)

                    self.m_T_ts_ave[tcn] /= self.m_nodes
                    max_T_diff /= 290.0

                self.m_T_cout_ave[tcn] = self.m_T_ave[self.m_nodes - 1]
                self.m_T_hout_ave[tcn] = self.m_T_ave[0]
                self.m_T_start = self.m_T_end.copy()

            self.m_T_final_ave = 0.0
            for i in range(self.m_nodes):
                self.m_T_final_ave += self.m_T_end[i]
            self.m_T_final_ave /= self.m_nodes

            var T_ave: Float64 = 0.0
            for i in range(num_TC):
                T_ave += self.m_T_ts_ave[i]
            T_ave /= num_TC

            T_disch_avail = 0.0
            T_charge_avail = 0.0
            for i in range(num_TC):
                T_disch_avail += self.m_T_hout_ave[i]
                T_charge_avail += self.m_T_cout_ave[i]
            T_disch_avail /= num_TC
            T_charge_avail /= num_TC

            var diff_Tcmax: Float64 = Float64.nan
            var diff_Thmin: Float64 = Float64.nan

            if I_flow == 1:
                diff_Tcmax = self.m_T_end[self.m_nodes - 1] - self.m_Tcmax
            elif I_flow == 2:
                diff_Thmin = self.m_T_end[ChargeNodes] - self.m_Thmin

            TC_limit = 0

            if know_mdot:
                full = False
                if I_flow == 1:
                    q_calc = m_dot * self.m_cp_a * (T_hot - T_charge_avail) / 3.6
                    if mdot_iter:
                        if diff_Tcmax > -t_tol and diff_Tcmax <= 0.0:
                            diff_q_target = 0.0
                            TC_limit = 0
                        elif diff_Tcmax > 0.0:
                            TC_limit = 1
                        else:
                            TC_limit = 2
                    else:
                        if diff_Tcmax <= 0.0:
                            diff_q_target = 0.0
                            TC_limit = 0
                        else:
                            mdot_iter = True
                            TC_limit = 1
                else:
                    q_calc = m_dot * self.m_cp_a * (T_disch_avail - T_cold) / 3.6
                    if mdot_iter:
                        if diff_Thmin >= 0.0 and diff_Thmin < t_tol:
                            diff_q_target = 0.0
                            TC_limit = 0
                        elif diff_Thmin < 0.0:
                            TC_limit = 1
                        else:
                            TC_limit = 2
                    else:
                        if diff_Thmin >= 0.0:
                            diff_q_target = 0.0
                            TC_limit = 0
                        else:
                            mdot_iter = True
                            TC_limit = 1
            elif q_target == 0.0:
                diff_q_target = 0.0
                TC_limit = 0
            elif I_flow == 1:
                q_calc = m_dot * self.m_cp_a * (T_hot - T_charge_avail) / 3.6
                if q_calc < q_target and diff_Tcmax > -t_tol and diff_Tcmax <= 0.0:
                    diff_q_target = 0.0
                    TC_limit = 0
                    full = False
                elif diff_Tcmax > 0.0:
                    TC_limit = 1
                else:
                    diff_q_target = (q_calc - q_target) / q_target
            else:
                q_calc = m_dot * self.m_cp_a * (T_disch_avail - T_cold) / 3.6
                if q_calc < q_target and diff_Thmin < t_tol and diff_Thmin >= 0.0:
                    diff_q_target = 0.0
                    TC_limit = 0
                    full = False
                elif diff_Thmin < 0.0:
                    TC_limit = 1
                else:
                    diff_q_target = (q_calc - q_target) / q_target

        if q_iter == 40 and (abs(diff_q_target) > q_tol or TC_limit != 0):
            full = False

        if full:
            q_calc = q_target

        var Q_losses_sum: Float64 = 0.0
        for i in range(num_TC):
            Q_losses_sum += self.m_Q_losses[i]
        var Q_loss_total: Float64 = Q_losses_sum * delt / num_TC

        var q_charge: Float64 = Float64.nan
        var q_discharge: Float64 = Float64.nan
        var q_stored: Float64 = Float64.nan
        var q_error: Float64 = Float64.nan

        if I_flow == 1:
            m_charge_avail = m_dot
            q_charge = delt * m_dot * self.m_cp_a * (T_hot - T_charge_avail)
            q_stored = self.m_cap * (self.m_T_final_ave - self.m_T_final_ave_prev)
            q_error = (q_charge - q_stored - Q_loss_total) / max(0.01, abs(q_stored))
        else:
            m_disch_avail = m_dot
            q_discharge = delt * m_dot * self.m_cp_a * (T_disch_avail - T_cold)
            q_stored = self.m_cap * (self.m_T_final_ave - self.m_T_final_ave_prev)
            q_error = (-q_stored - q_discharge - Q_loss_total) / max(0.01, abs(q_stored))

        var Q_htr_total: Float64 = 0.0
        for i in range(num_TC):
            Q_htr_total += self.m_Q_htr[i]

        m_dis_avail_tot = m_disch_avail * self.m_tank_pairs
        T_dis_avail_C = T_disch_avail
        m_ch_avail_tot = m_charge_avail * self.m_tank_pairs
        T_ch_avail_C = T_charge_avail
        Q_dot_out_W = q_calc * self.m_tank_pairs
        Q_dot_losses = Q_loss_total * self.m_tank_pairs
        T_hot_bed_C = self.m_T_end[0]
        T_cold_bed_C = self.m_T_end[self.m_nodes - 1]

        var T_max_bed: Float64 = 0.0
        for i in range(self.m_nodes):
            T_max_bed = max(T_max_bed, self.m_T_end[i])
        T_max_bed_C = T_max_bed

        ihlim = 0
        iclim = 0
        for i in range(self.m_nodes):
            if self.m_T_end[i] > self.m_T_hot_in_min:
                ihlim = i
            if self.m_T_end[self.m_nodes - 1 - i] < self.m_T_cold_in_max:
                iclim = i

        f_hot = (ihlim + 1) / self.m_nodes
        f_cold = (self.m_nodes - iclim - 1) / self.m_nodes
        Q_dot_htr_kJ = Q_htr_total * self.m_tank_pairs
        self.m_Q_dot_htr_kJ = Q_dot_htr_kJ
        self.m_Q_dot_losses = Q_dot_losses
        self.m_T_hot_node = T_hot_bed_C
        self.m_T_cold_node = T_cold_bed_C
        self.m_T_max = T_max_bed_C
        self.m_f_hot = f_hot
        self.m_f_cold = f_cold
        return True

    def Converged(self, time: Float64):
        self.m_T_prev = self.m_T_end.copy()
        self.m_T_final_ave_prev = self.m_T_final_ave
        return

    def GetHeaterLoad_kJ(self) -> Float64:
        return self.m_Q_dot_htr_kJ

    def GetHeatLosses(self) -> Float64:
        return self.m_Q_dot_losses

    def GetFinalOutputs(
        self,
        inout T_hot_node: Float64,
        inout T_cold_node: Float64,
        inout T_max: Float64,
        inout f_hot: Float64,
        inout f_cold: Float64
    ):
        T_hot_node = self.m_T_hot_node
        T_cold_node = self.m_T_cold_node
        T_max = self.m_T_max
        f_hot = self.m_f_hot
        f_cold = self.m_f_cold
        return

    # Member variables
    var htfProps: HTFProperties
    var fillProps: TC_Fill_Props = TC_Fill_Props()
    var m_H: Float64 = 0.0
    var m_A: Float64 = 0.0
    var m_U: Float64 = 0.0
    var m_U_top: Float64 = 0.0
    var m_U_bot: Float64 = 0.0
    var m_void: Float64 = 0.0
    var m_capfac: Float64 = 0.0
    var m_Thmin: Float64 = 0.0
    var m_Tcmax: Float64 = 0.0
    var m_nodes: Int = 0
    var m_T_hot_init: Float64 = 0.0
    var m_T_cold_init: Float64 = 0.0
    var m_TC_break: Float64 = 0.0
    var m_T_htr_set: Float64 = 0.0
    var m_tank_max_heat: Float64 = 0.0
    var m_tank_pairs: Int = 0
    var m_Th_avail_min: Float64 = 0.0
    var m_Tc_avail_max: Float64 = 0.0
    var m_num_TC_max: Int = 0
    var m_P: Float64 = 0.0
    var m_vol: Float64 = 0.0
    var m_UA: Float64 = 0.0
    var m_UA_top: Float64 = 0.0
    var m_UA_bot: Float64 = 0.0
    var m_ef_cond: Float64 = 0.0
    var m_cap: Float64 = 0.0
    var m_e_tes: Float64 = 0.0
    var m_cap_node: Float64 = 0.0
    var m_tol_TC: Float64 = 0.0
    var m_T_hot_in_min: Float64 = 0.0
    var m_T_cold_in_max: Float64 = 0.0

    var m_T_prev: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_start: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_ave: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_end: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_ts_ave: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_Q_losses: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_Q_htr: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_cout_ave: DynamicVector[Float64] = DynamicVector[Float64]()
    var m_T_hout_ave: DynamicVector[Float64] = DynamicVector[Float64]()

    var m_T_final_ave_prev: Float64 = 0.0
    var m_T_final_ave: Float64 = 0.0
    var m_Q_dot_htr_kJ: Float64 = 0.0
    var m_Q_dot_losses: Float64 = 0.0
    var m_T_hot_node: Float64 = 0.0
    var m_T_cold_node: Float64 = 0.0
    var m_T_max: Float64 = 0.0
    var m_f_hot: Float64 = 0.0
    var m_f_cold: Float64 = 0.0
    var m_cond: Float64 = 0.0
    var m_cp_a: Float64 = 0.0
    var m_rho_a: Float64 = 0.0
    var m_cp_r: Float64 = 0.0
    var m_rho_r: Float64 = 0.0