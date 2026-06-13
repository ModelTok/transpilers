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
from CO2_properties import CO2_state, CO2_TP, CO2_PH, CO2_visc, CO2_cond, CO2_error_message
from sam_csp_util import CSP
from math import pow, log10, log, sqrt, fabs, exp
from memory import Pointer
from utils import Vector, Matrix
from sys import float64

struct sco2_exception(Exception):
    var message: String
    def __init__(inout self, message: String):
        self.message = message
    def __init__(inout self, msg: StringLiteral):
        self.message = String(msg)

@value
struct C_rec_des_props:
    var m_material: Int
    enum Haynes_230: Int = 1

    def __init__(inout self, material: Int):
        self.m_material = material

    def cond(inout self, T_C: Float64) -> Float64:
        if self.m_material == C_rec_des_props.Haynes_230:
            return 8.4 + 0.02 * T_C
        else:
            return float64(float64.nan)

    def modE(inout self, T_C: Float64) -> Float64:
        if self.m_material == C_rec_des_props.Haynes_230:
            return 212.258813 - 0.063305782 * T_C + 0.0000298956743 * pow(T_C, 2) - 4.27361456E-8 * pow(T_C, 3)
        else:
            return float64(float64.nan)

    def alpha_inst(inout self, T_C: Float64) -> Float64:
        if self.m_material == C_rec_des_props.Haynes_230:
            return 12.2619521 + 0.00647096736 * T_C - 0.0000234157719 * pow(T_C, 2) + 1.50217826E-7 * pow(T_C, 3) - 2.83989121E-10 * pow(T_C, 4) + 1.67497618E-13 * pow(T_C, 5)
        else:
            return float64(float64.nan)

    def poisson(inout self) -> Float64:
        if self.m_material == C_rec_des_props.Haynes_230:
            return 0.31
        return -999.9

    def creep_life(inout self, sigma_MPa: Float64, T_C: Float64) -> Float64:
        var T_F: Float64 = (9.0 / 5.0) * T_C + 32.0
        var sigma_ksi: Float64 = 0.145 * sigma_MPa
        if self.m_material == C_rec_des_props.Haynes_230:
            var T_start: Float64 = self.haynes230_enum_creep_temps(T_1050F)
            var T_end: Float64 = self.haynes230_enum_creep_temps(T_1800F)
            if T_F <= T_start:
                return self.haynes230_creep_life(T_1050F, sigma_ksi)
            elif T_F >= T_end:
                return self.haynes230_creep_life(T_1800F, sigma_ksi)
            else:
                var temps_int: Int = T_1050F
                while temps_int != T_1800F:
                    var T_high: Float64 = self.haynes230_enum_creep_temps(temps_int + 1)
                    if T_F < T_high:
                        return self.interpolate_creep_life(temps_int, temps_int + 1, T_F, sigma_ksi)
                    temps_int += 1
        return -999.9

    def interpolate_creep_life(inout self, enum_T_low: Int, enum_T_high: Int, T_F: Float64, sigma_ksi: Float64) -> Float64:
        var t_low: Float64 = self.haynes230_creep_life(enum_T_low, sigma_ksi)
        var t_high: Float64 = self.haynes230_creep_life(enum_T_high, sigma_ksi)
        var T_F_low: Float64 = self.haynes230_enum_creep_temps(enum_T_low)
        var T_F_high: Float64 = self.haynes230_enum_creep_temps(enum_T_high)
        return pow(10, (T_F - T_F_low) / (T_F_high - T_F_low) * log10(t_high) + (T_F_high - T_F) / (T_F_high - T_F_low) * log10(t_low))

    def haynes230_enum_creep_temps(inout self, enum_T_F: Int) -> Float64:
        if enum_T_F == T_1050F:
            return 1050.0
        elif enum_T_F == T_1100F:
            return 1100.0
        elif enum_T_F == T_1200F:
            return 1200.0
        elif enum_T_F == T_1300F:
            return 1300.0
        elif enum_T_F == T_1400F:
            return 1400.0
        elif enum_T_F == T_1500F:
            return 1500.0
        elif enum_T_F == T_1600F:
            return 1600.0
        elif enum_T_F == T_1700F:
            return 1700.0
        elif enum_T_F == T_1800F:
            return 1800.0
        else:
            return 0

    def haynes230_creep_life(inout self, enum_T_F: Int, sigma_ksi: Float64) -> Float64:
        if enum_T_F == T_1050F:
            return 1.E8
        elif enum_T_F == T_1100F:
            var sigma_MPa: Float64 = 6.8948 * sigma_ksi
            if sigma_MPa > 100.0:
                return min(1.E8, exp(-18.073 * log(sigma_MPa) + 117.495))
            else:
                return 1.E8
        elif enum_T_F == T_1200F:
            return min(1.E8, pow(10, -7.3368 * log10(sigma_ksi) + 14.8349))
        elif enum_T_F == T_1300F:
            return min(1.E8, pow(10, -6.8634 * log10(sigma_ksi) + 13.1366))
        elif enum_T_F == T_1400F:
            return min(1.E8, pow(10, -7.6453 * log10(sigma_ksi) + 12.9472))
        elif enum_T_F == T_1500F:
            return min(1.E8, pow(10, -7.2307 * log10(sigma_ksi) + 11.2307))
        elif enum_T_F == T_1600F:
            return min(1.E8, pow(10, -6.2657 * log10(sigma_ksi) + 9.0733))
        elif enum_T_F == T_1700F:
            return min(1.E8, pow(10, -4.5434 * log10(sigma_ksi) + 6.5797))
        elif enum_T_F == T_1800F:
            return min(1.E8, pow(10, -3.7908 * log10(sigma_ksi) + 4.9022))
        else:
            return -999

    def haynes230_enum_cycle_temps(inout self, enum_T_C: Int) -> Float64:
        if enum_T_C == T_427C:
            return 427.0
        elif enum_T_C == T_538C:
            return 538.0
        elif enum_T_C == T_649C:
            return 649.0
        elif enum_T_C == T_760C:
            return 760.0
        elif enum_T_C == T_871C:
            return 871.0
        elif enum_T_C == T_982C:
            return 982.0
        else:
            return 0

    def cycles_to_failure(inout self, epsilon_equiv: Float64, T_C: Float64) -> Float64:
        if self.m_material == C_rec_des_props.Haynes_230:
            var T_start: Float64 = self.haynes230_enum_cycle_temps(T_427C)
            var T_end: Float64 = self.haynes230_enum_cycle_temps(T_982C)
            if T_C <= T_start:
                if epsilon_equiv < self.haynes230_eps_min(T_427C):
                    return 100000.0
                else:
                    return self.haynes230_cycles_to_failure(T_427C, epsilon_equiv)
            elif T_C >= T_end:
                if epsilon_equiv < self.haynes230_eps_min(T_982C):
                    return 100000.0
                else:
                    return self.haynes230_cycles_to_failure(T_982C, epsilon_equiv)
            else:
                var temps_int: Int = T_427C
                while temps_int != T_982C:
                    var T_high: Float64 = self.haynes230_enum_cycle_temps(temps_int + 1)
                    if T_C < T_high:
                        if epsilon_equiv < self.haynes230_eps_min(temps_int + 1):
                            return 100000.0
                        else:
                            return self.interpolate_cycles_to_failure(temps_int, temps_int + 1, T_C, epsilon_equiv)
                    temps_int += 1
        return -999.0

    def haynes230_eps_min(inout self, enum_T_C: Int) -> Float64:
        if enum_T_C == T_427C:
            return 0.55
        elif enum_T_C == T_538C:
            return 0.52
        elif enum_T_C == T_649C:
            return 0.45
        elif enum_T_C == T_760C:
            return 0.38
        elif enum_T_C == T_871C:
            return 0.29
        elif enum_T_C == T_982C:
            return 0.27
        else:
            return -999.9

    def haynes230_cycles_to_failure(inout self, enum_T_C: Int, eps_equiv: Float64) -> Float64:
        var OF_E: Float64 = 0.0
        var b: Float64 = 0.0
        var e_f: Float64 = 0.0
        var c: Float64 = 0.0
        if enum_T_C == T_427C:
            OF_E = 0.2
            b = 0.01
            e_f = 18.0
            c = 0.45
        elif enum_T_C == T_538C:
            OF_E = 0.2
            b = 0.0005
            e_f = 45.0
            c = 0.60
        elif enum_T_C == T_649C:
            OF_E = 0.2
            b = 0.001
            e_f = 45.0
            c = 0.65
        elif enum_T_C == T_760C:
            OF_E = 0.2
            b = 0.02
            e_f = 45.0
            c = 0.70
        elif enum_T_C == T_871C:
            OF_E = 0.15
            b = 0.02
            e_f = 12.0
            c = 0.55
        elif enum_T_C == T_982C:
            OF_E = 0.22
            b = 0.05
            e_f = 45.0
            c = 0.80
        else:
            return -999.9
        var N_low_baseline: Float64 = 1.0
        var N_low: Float64 = N_low_baseline
        var N_high_baseline: Float64 = 300000.0
        var N_high: Float64 = N_high_baseline
        var eps_guess: Float64 = 2 * (OF_E * pow(N_high, -b) + e_f * pow(N_high, -c))
        var N_allowable: Float64 = 0.0
        if eps_guess > eps_equiv:
            return N_high
        else:
            var counter: Int = 0
            while True:
                counter += 1
                N_allowable = pow(10, 0.5 * log10(N_low) + 0.5 * log10(N_high))
                eps_guess = 2 * (OF_E * pow(N_allowable, -b) + e_f * pow(N_allowable, -c))
                var eps_err: Float64 = (eps_guess - eps_equiv) / eps_equiv
                if fabs(eps_err) < 1.E-8:
                    return N_allowable
                else:
                    if eps_err > 0.0:
                        N_low = N_allowable
                    else:
                        N_high = N_allowable
                if counter > 100:
                    return -999.9

    def interpolate_cycles_to_failure(inout self, enum_T_low: Int, enum_T_high: Int, T_C: Float64, eps_equiv: Float64) -> Float64:
        var N_low: Float64 = self.haynes230_cycles_to_failure(enum_T_low, eps_equiv)
        var N_high: Float64 = self.haynes230_cycles_to_failure(enum_T_high, eps_equiv)
        var T_C_low: Float64 = self.haynes230_enum_cycle_temps(enum_T_low)
        var T_C_high: Float64 = self.haynes230_enum_cycle_temps(enum_T_high)
        return pow(10.0, (T_C - T_C_low) / (T_C_high - T_C_low) * log10(N_high) + (T_C_high - T_C) / (T_C_high - T_C_low) * log10(N_low))

    # Private enum constants
    enum T_1050F: Int = 1
    enum T_1100F: Int = 2
    enum T_1200F: Int = 3
    enum T_1300F: Int = 4
    enum T_1400F: Int = 5
    enum T_1500F: Int = 6
    enum T_1600F: Int = 7
    enum T_1700F: Int = 8
    enum T_1800F: Int = 9
    enum T_427C: Int = 1
    enum T_538C: Int = 2
    enum T_649C: Int = 3
    enum T_760C: Int = 4
    enum T_871C: Int = 5
    enum T_982C: Int = 6

@value
struct C_tube_slice:
    var p_tube_mat: Pointer[C_rec_des_props]
    var s_ID_OD_perf_and_lifetime_inputs: S_ID_OD_perf_and_lifetime_inputs
    var m_F_avg: Float64
    var m_SF_fatigue: Float64
    var m_F_inelastic: Float64
    var m_N_design_cycles: Float64
    var m_t_hours_design: Float64
    var m_T_surf_in: Float64
    var m_T_surf_out: Float64
    var m_nu_poisson: Float64
    var m_E: Float64
    var m_alpha: Float64
    var m_r_in: Float64
    var m_r_out: Float64

    @value
    struct S_creep_fatigue_outputs:
        var m_eps_a_perc_inel: Float64
        var m_eps_r_perc_inel: Float64
        var m_eps_t_perc_inel: Float64
        var m_eps_equiv_perc_SF: Float64
        var m_N_cycles: Float64
        var m_fatigue_damage: Float64
        var m_max_stress_SF: Float64
        var m_creep_life: Float64
        var m_creep_damage: Float64
        var m_total_damage: Float64
        def __init__(inout self):
            self.m_eps_a_perc_inel = float64(float64.nan)
            self.m_eps_r_perc_inel = float64(float64.nan)
            self.m_eps_t_perc_inel = float64(float64.nan)
            self.m_eps_equiv_perc_SF = float64(float64.nan)
            self.m_N_cycles = float64(float64.nan)
            self.m_fatigue_damage = float64(float64.nan)
            self.m_max_stress_SF = float64(float64.nan)
            self.m_creep_life = float64(float64.nan)
            self.m_creep_damage = float64(float64.nan)
            self.m_total_damage = float64(float64.nan)

    @value
    struct S_principal_stresses:
        var m_sigma_r: Float64
        var m_sigma_t: Float64
        var m_sigma_a: Float64
        def __init__(inout self):
            self.m_sigma_r = float64(float64.nan)
            self.m_sigma_t = float64(float64.nan)
            self.m_sigma_a = float64(float64.nan)

    @value
    struct S_thermal_stress_rad_profile_outputs:
        var s_thermal_stresses: S_principal_stresses
        var s_pressure_stresses: S_principal_stresses
        var s_total_stresses: S_principal_stresses
        def __init__(inout self):
            self.s_thermal_stresses = S_principal_stresses()
            self.s_pressure_stresses = S_principal_stresses()
            self.s_total_stresses = S_principal_stresses()

    @value
    struct S_ID_OD_perf_and_lifetime_inputs:
        var m_P_internal: Float64
        var m_T_fluid: Float64
        var m_d_out: Float64
        var m_d_in: Float64
        var m_flux: Float64
        var m_h_conv: Float64
        def __init__(inout self):
            self.m_P_internal = float64(float64.nan)
            self.m_T_fluid = float64(float64.nan)
            self.m_d_out = float64(float64.nan)
            self.m_d_in = float64(float64.nan)
            self.m_flux = float64(float64.nan)
            self.m_h_conv = float64(float64.nan)

    @value
    struct S_ID_OD_perf_and_lifetime_outputs:
        var m_T_surf_in: Float64
        var m_T_surf_out: Float64
        var s_ID_stress_outputs: S_thermal_stress_rad_profile_outputs
        var s_OD_stress_outputs: S_thermal_stress_rad_profile_outputs
        var s_ID_lifetime_outputs: S_creep_fatigue_outputs
        var s_OD_lifetime_outputs: S_creep_fatigue_outputs
        def __init__(inout self):
            self.m_T_surf_in = float64(float64.nan)
            self.m_T_surf_out = float64(float64.nan)
            self.s_ID_stress_outputs = S_thermal_stress_rad_profile_outputs()
            self.s_OD_stress_outputs = S_thermal_stress_rad_profile_outputs()
            self.s_ID_lifetime_outputs = S_creep_fatigue_outputs()
            self.s_OD_lifetime_outputs = S_creep_fatigue_outputs()

    @value
    struct S_ID_OD_stress_and_lifetime_inputs:
        var m_P_internal: Float64
        var m_T_fluid: Float64
        var m_d_out: Float64
        var m_d_in: Float64
        var m_T_surf_in: Float64
        var m_T_surf_out: Float64
        def __init__(inout self):
            self.m_P_internal = float64(float64.nan)
            self.m_T_fluid = float64(float64.nan)
            self.m_d_out = float64(float64.nan)
            self.m_d_in = float64(float64.nan)
            self.m_T_surf_in = float64(float64.nan)
            self.m_T_surf_out = float64(float64.nan)

    @value
    struct S_ID_OD_stress_and_lifetime_outputs:
        var s_ID_stress_outputs: S_thermal_stress_rad_profile_outputs
        var s_OD_stress_outputs: S_thermal_stress_rad_profile_outputs
        var s_ID_lifetime_outputs: S_creep_fatigue_outputs
        var s_OD_lifetime_outputs: S_creep_fatigue_outputs
        def __init__(inout self):
            self.s_ID_stress_outputs = S_thermal_stress_rad_profile_outputs()
            self.s_OD_stress_outputs = S_thermal_stress_rad_profile_outputs()
            self.s_ID_lifetime_outputs = S_creep_fatigue_outputs()
            self.s_OD_lifetime_outputs = S_creep_fatigue_outputs()

    def __init__(inout self, enum_tube_mat: Int):
        self.general_constructor(enum_tube_mat)
        self.reset_SFs_and_design_targets()

    def __init__(inout self, enum_tube_mat: Int, F_avg: Float64, SF_fatigue: Float64, F_inelastic: Float64, N_design_cycles: Float64, t_hours_design: Float64):
        self.general_constructor(enum_tube_mat)
        self.specify_SFs_and_design_targets(F_avg, SF_fatigue, F_inelastic, N_design_cycles, t_hours_design)

    def __del__(owned self):

    def reset_SFs_and_design_targets(inout self):
        self.m_F_avg = 0.67
        self.m_SF_fatigue = 0.5
        self.m_F_inelastic = 1.1
        self.m_N_design_cycles = 10000.0
        self.m_t_hours_design = 100000.0

    def specify_SFs_and_design_targets(inout self, F_avg: Float64, SF_fatigue: Float64, F_inelastic: Float64, N_design_cycles: Float64, t_hours_design: Float64):
        self.reset_SFs_and_design_targets()
        if F_avg > 0.0:
            self.m_F_avg = F_avg
        if SF_fatigue > 0.0:
            self.m_SF_fatigue = SF_fatigue
        if F_inelastic > 0.0:
            self.m_F_inelastic = F_inelastic
        if N_design_cycles > 0.0:
            self.m_N_design_cycles = N_design_cycles
        if t_hours_design > 0.0:
            self.m_t_hours_design = t_hours_design

    def calc_ID_OD_perf_and_lifetime(inout self, s_inputs: S_ID_OD_perf_and_lifetime_inputs, s_outputs: Pointer[S_ID_OD_perf_and_lifetime_outputs]):
        self.clear_calc_member_data()
        self.s_ID_OD_perf_and_lifetime_inputs = s_inputs
        self.radial_ss_E_bal()
        s_outputs[].m_T_surf_in = self.m_T_surf_in
        s_outputs[].m_T_surf_out = self.m_T_surf_out
        self.avg_temps_and_props()
        self.thermal_stress_rad_profile(self.s_ID_OD_perf_and_lifetime_inputs.m_d_in, s_outputs[].s_ID_stress_outputs)
        self.thermal_stress_rad_profile(self.s_ID_OD_perf_and_lifetime_inputs.m_d_out, s_outputs[].s_OD_stress_outputs)
        self.creep_fatigue_lifetime(self.m_T_surf_in, s_outputs[].s_ID_stress_outputs.s_total_stresses, s_outputs[].s_ID_lifetime_outputs)
        self.creep_fatigue_lifetime(self.m_T_surf_out, s_outputs[].s_OD_stress_outputs.s_total_stresses, s_outputs[].s_OD_lifetime_outputs)

    def calc_ID_OD_stress_and_lifetime(inout self, s_inputs: S_ID_OD_stress_and_lifetime_inputs, s_outputs: Pointer[S_ID_OD_stress_and_lifetime_outputs]):
        self.s_ID_OD_perf_and_lifetime_inputs.m_P_internal = s_inputs.m_P_internal
        self.s_ID_OD_perf_and_lifetime_inputs.m_T_fluid = s_inputs.m_T_fluid
        self.s_ID_OD_perf_and_lifetime_inputs.m_d_out = s_inputs.m_d_out
        self.s_ID_OD_perf_and_lifetime_inputs.m_d_in = s_inputs.m_d_in
        self.s_ID_OD_perf_and_lifetime_inputs.m_flux = 0.0
        self.s_ID_OD_perf_and_lifetime_inputs.m_h_conv = 0.0
        self.m_T_surf_in = s_inputs.m_T_surf_in
        self.m_T_surf_out = s_inputs.m_T_surf_out
        self.avg_temps_and_props()
        self.thermal_stress_rad_profile(self.s_ID_OD_perf_and_lifetime_inputs.m_d_in, s_outputs[].s_ID_stress_outputs)
        self.thermal_stress_rad_profile(self.s_ID_OD_perf_and_lifetime_inputs.m_d_out, s_outputs[].s_OD_stress_outputs)
        self.creep_fatigue_lifetime(self.m_T_surf_in, s_outputs[].s_ID_stress_outputs.s_total_stresses, s_outputs[].s_ID_lifetime_outputs)
        self.creep_fatigue_lifetime(self.m_T_surf_out, s_outputs[].s_OD_stress_outputs.s_total_stresses, s_outputs[].s_OD_lifetime_outputs)

    def general_constructor(inout self, enum_tube_mat: Int):
        self.p_tube_mat = Pointer[C_rec_des_props].alloc(1)
        self.p_tube_mat[0] = C_rec_des_props(enum_tube_mat)
        self.clear_calc_member_data()

    def clear_calc_member_data(inout self):
        self.m_T_surf_in = float64(float64.nan)
        self.m_T_surf_out = float64(float64.nan)
        self.m_nu_poisson = float64(float64.nan)
        self.m_E = float64(float64.nan)
        self.m_alpha = float64(float64.nan)
        self.m_r_in = float64(float64.nan)
        self.m_r_out = float64(float64.nan)

    def radial_ss_E_bal(inout self):
        var q_max: Float64 = self.s_ID_OD_perf_and_lifetime_inputs.m_flux * self.s_ID_OD_perf_and_lifetime_inputs.m_d_out * CSP.pi
        var T_surf_in: Float64 = q_max / (self.s_ID_OD_perf_and_lifetime_inputs.m_d_in * CSP.pi * self.s_ID_OD_perf_and_lifetime_inputs.m_h_conv) + self.s_ID_OD_perf_and_lifetime_inputs.m_T_fluid
        var T_surf_out_guess: Float64 = T_surf_in
        var T_low: Float64 = T_surf_in
        var T_high: Float64 = float64(float64.nan)
        var high_flag: Bool = False
        while True:
            var T_surf_avg_guess: Float64 = (T_surf_in + T_surf_out_guess) / 2.0
            var k_tube: Float64 = self.p_tube_mat[0].cond(T_surf_avg_guess)
            var T_surf_out_calc: Float64 = q_max * log(self.s_ID_OD_perf_and_lifetime_inputs.m_d_out / self.s_ID_OD_perf_and_lifetime_inputs.m_d_in) / (2.0 * CSP.pi * k_tube) + T_surf_in
            var T_surf_out_err: Float64 = (T_surf_out_guess - T_surf_out_calc) / T_surf_out_calc
            if T_surf_out_err != T_surf_out_err:
                raise sco2_exception("Convergence failed in the sCO2 receiver tube model: radial_ss_E_bal().")
            if fabs(T_surf_out_err) < 1.E-10:
                break
            else:
                if T_surf_out_err > 0.0:
                    high_flag = True
                    T_high = T_surf_out_guess
                    T_surf_out_guess = (T_low + T_high) / 2.0
                else:
                    T_low = T_surf_out_guess
                    if high_flag:
                        T_surf_out_guess = (T_low + T_high) / 2.0
                    else:
                        T_surf_out_guess = T_surf_out_calc
        self.m_T_surf_in = T_surf_in
        self.m_T_surf_out = T_surf_out_guess

    def avg_temps_and_props(inout self):
        self.m_nu_poisson = self.p_tube_mat[0].poisson()
        var T_surf_avg: Float64 = 0.5 * (self.m_T_surf_in + self.m_T_surf_out)
        self.m_E = self.p_tube_mat[0].modE(T_surf_avg) * 1.E3
        self.m_alpha = self.p_tube_mat[0].alpha_inst(T_surf_avg) / (1.E6)
        self.m_r_in = self.s_ID_OD_perf_and_lifetime_inputs.m_d_in / 2.0
        self.m_r_out = self.s_ID_OD_perf_and_lifetime_inputs.m_d_out / 2.0

    def thermal_stress_rad_profile(inout self, d_local: Float64, outputs: Pointer[S_thermal_stress_rad_profile_outputs]):
        var r_local: Float64 = d_local / 2.0
        outputs[].s_thermal_stresses.m_sigma_r = self.m_alpha * self.m_E * (self.m_T_surf_in - self.m_T_surf_out) / (2.0 * (1.0 - self.m_nu_poisson) * log(self.m_r_out / self.m_r_in)) * (-log(self.m_r_out / r_local) - pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2)) * (1.0 - (pow(self.m_r_out, 2) / pow(r_local, 2))) * log(self.m_r_out / self.m_r_in))
        outputs[].s_thermal_stresses.m_sigma_t = self.m_alpha * self.m_E * (self.m_T_surf_in - self.m_T_surf_out) / (2.0 * (1.0 - self.m_nu_poisson) * log(self.m_r_out / self.m_r_in)) * (1.0 - log(self.m_r_out / r_local) - pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2)) * (1.0 + (pow(self.m_r_out, 2) / pow(r_local, 2))) * log(self.m_r_out / self.m_r_in))
        outputs[].s_thermal_stresses.m_sigma_a = self.m_alpha * self.m_E * (self.m_T_surf_in - self.m_T_surf_out) / (2.0 * (1.0 - self.m_nu_poisson) * log(self.m_r_out / self.m_r_in)) * (1.0 - 2.0 * log(self.m_r_out / r_local) - 2.0 * pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2)) * log(self.m_r_out / self.m_r_in))
        outputs[].s_pressure_stresses.m_sigma_r = self.s_ID_OD_perf_and_lifetime_inputs.m_P_internal * pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2)) * (1.0 - (pow(self.m_r_out, 2) / pow(r_local, 2)))
        outputs[].s_pressure_stresses.m_sigma_t = self.s_ID_OD_perf_and_lifetime_inputs.m_P_internal * pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2)) * (1.0 + (pow(self.m_r_out, 2) / pow(r_local, 2)))
        outputs[].s_pressure_stresses.m_sigma_a = self.s_ID_OD_perf_and_lifetime_inputs.m_P_internal * pow(self.m_r_in, 2) / (pow(self.m_r_out, 2) - pow(self.m_r_in, 2))
        outputs[].s_total_stresses.m_sigma_a = outputs[].s_pressure_stresses.m_sigma_a + outputs[].s_thermal_stresses.m_sigma_a
        outputs[].s_total_stresses.m_sigma_r = outputs[].s_pressure_stresses.m_sigma_r + outputs[].s_thermal_stresses.m_sigma_r
        outputs[].s_total_stresses.m_sigma_t = outputs[].s_pressure_stresses.m_sigma_t + outputs[].s_thermal_stresses.m_sigma_t

    def creep_fatigue_lifetime(inout self, T_mat_C: Float64, inputs: S_principal_stresses, outputs: Pointer[S_creep_fatigue_outputs]):
        outputs[].m_eps_a_perc_inel = self.m_F_inelastic * inputs.m_sigma_a / self.m_E * 100.0
        outputs[].m_eps_r_perc_inel = self.m_F_inelastic * inputs.m_sigma_r / self.m_E * 100.0
        outputs[].m_eps_t_perc_inel = self.m_F_inelastic * inputs.m_sigma_t / self.m_E * 100.0
        outputs[].m_eps_equiv_perc_SF = sqrt(2.0) / 3.0 * sqrt(pow(outputs[].m_eps_t_perc_inel - outputs[].m_eps_a_perc_inel, 2.0) + pow(outputs[].m_eps_t_perc_inel - outputs[].m_eps_r_perc_inel, 2.0) + pow(outputs[].m_eps_a_perc_inel - outputs[].m_eps_r_perc_inel, 2.0)) / self.m_SF_fatigue
        outputs[].m_N_cycles = self.p_tube_mat[0].cycles_to_failure(outputs[].m_eps_equiv_perc_SF, T_mat_C)
        outputs[].m_fatigue_damage = self.m_N_design_cycles / outputs[].m_N_cycles
        outputs[].m_max_stress_SF = max(inputs.m_sigma_a, max(inputs.m_sigma_r, inputs.m_sigma_t)) / self.m_F_avg
        outputs[].m_creep_life = self.p_tube_mat[0].creep_life(outputs[].m_max_stress_SF, T_mat_C)
        outputs[].m_creep_damage = self.m_t_hours_design / outputs[].m_creep_life
        outputs[].m_total_damage = outputs[].m_fatigue_damage + outputs[].m_creep_damage

@value
struct C_calc_tube_min_th:
    var co2_props: CO2_state
    var m_flux_array: Matrix[Float64]
    var m_q_abs_array: Vector[Float64]
    var m_q_max_array: Vector[Float64]
    var m_d_out: Float64
    var m_T_fluid_in: Float64
    var m_T_fluid_out: Float64
    var m_P_fluid_in: Float64
    var m_e_roughness: Float64
    var m_L_tube: Float64
    var m_m_dot_tube: Float64
    var m_know_T_out: Bool
    var m_n_tube_elements: Int
    var m_n_temps: Int
    var m_d_in: Float64
    var m_L_node: Float64
    var m_deltaP_kPa: Float64
    var m_max_damage: Float64
    var m_th_min_guess: Float64
    var m_th_step: Float64
    var m_max_deltaP_frac: Float64
    var m_iter_d_in_max: Int
    var m_Temp: Vector[Float64]
    var m_Pres: Vector[Float64]
    var m_Enth: Vector[Float64]
    var m_h_conv_ave: Vector[Float64]
    var m_Tsurf: Vector[Float64]
    var m_P_fluid_out: Vector[Float64]
    var m_total_damage: Matrix[Float64]
    var m_element_results_temp: Matrix[Float64]
    var m_n_results_cols: Int
    var m_n_vector_results: Int

    def __init__(inout self):
        self.m_d_out = float64(float64.nan)
        self.m_T_fluid_in = float64(float64.nan)
        self.m_T_fluid_out = float64(float64.nan)
        self.m_P_fluid_in = float64(float64.nan)
        self.m_L_tube = float64(float64.nan)
        self.m_d_in = float64(float64.nan)
        self.m_L_node = float64(float64.nan)
        self.m_m_dot_tube = float64(float64.nan)
        self.m_deltaP_kPa = float64(float64.nan)
        self.m_max_damage = float64(float64.nan)
        self.m_e_roughness = 4.5E-5
        self.m_n_tube_elements = 0
        self.m_n_temps = 0
        self.m_n_results_cols = 1
        self.m_know_T_out = True
        self.m_th_min_guess = 0.0002
        self.m_th_step = 0.00005
        self.m_max_deltaP_frac = 0.2
        self.m_iter_d_in_max = 9999
        self.co2_props = CO2_state()
        self.m_flux_array = Matrix[Float64]()
        self.m_q_abs_array = Vector[Float64]()
        self.m_q_max_array = Vector[Float64]()
        self.m_Temp = Vector[Float64]()
        self.m_Pres = Vector[Float64]()
        self.m_Enth = Vector[Float64]()
        self.m_h_conv_ave = Vector[Float64]()
        self.m_Tsurf = Vector[Float64]()
        self.m_P_fluid_out = Vector[Float64]()
        self.m_total_damage = Matrix[Float64]()
        self.m_element_results_temp = Matrix[Float64]()

    def get_min_d_in(inout self) -> Float64:
        return self.m_d_in

    def get_m_dot_tube_kgsec(inout self) -> Float64:
        return self.m_m_dot_tube

    def get_T_out_C(inout self) -> Float64:
        return self.m_T_fluid_out

    def get_deltaP_kPa(inout self) -> Float64:
        return self.m_deltaP_kPa

    def get_max_damage(inout self) -> Float64:
        return self.m_max_damage

    def get_max_damage_matrix(inout self) -> Vector[Float64]:
        var d: Vector[Float64] = Vector[Float64]()
        var nr: Int = self.m_total_damage.nrows()
        var nc: Int = self.m_total_damage.ncols()
        d.reserve(nr)
        for i in range(nr):
            var dmax: Float64 = 0.0
            for j in range(nc):
                dmax = max(dmax, self.m_total_damage[i, j])
            d.push_back(dmax)
        return d

    def get_damage_matrix(inout self) -> Pointer[Matrix[Float64]]:
        return Pointer[Matrix[Float64]](address_of(self.m_total_damage))

    def get_damage_matrix(inout self, damage: Pointer[Matrix[Float64]]):
        var nr: Int = self.m_total_damage.nrows()
        var nc: Int = self.m_total_damage.ncols()
        damage[].resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                damage[][i, j] = self.m_total_damage[i, j]

    def get_fluid_temp_matrix(inout self) -> Pointer[Vector[Float64]]:
        return Pointer[Vector[Float64]](address_of(self.m_Temp))

    def get_surface_temp_matrix(inout self) -> Pointer[Vector[Float64]]:
        return Pointer[Vector[Float64]](address_of(self.m_Tsurf))

    def get_fluid_pres_matrix(inout self) -> Pointer[Vector[Float64]]:
        return Pointer[Vector[Float64]](address_of(self.m_Pres))

    def calc_th_flux_Tout(inout self, flux_Wm2: Matrix[Float64], L_tube_m: Float64, d_out_m: Float64, T_fluid_in_C: Float64, T_fluid_out_C: Float64, P_fluid_in_MPa: Float64) -> Bool:
        return self.calc_th_flux(flux_Wm2, L_tube_m, d_out_m, T_fluid_in_C, T_fluid_out_C, P_fluid_in_MPa, -999.0, True)

    def calc_th_flux_mdot(inout self, flux_Wm2: Matrix[Float64], L_tube_m: Float64, d_out_m: Float64, T_fluid_in_C: Float64, P_fluid_in_MPa: Float64, m_dot_tube_kgs: Float64) -> Bool:
        return self.calc_th_flux(flux_Wm2, L_tube_m, d_out_m, T_fluid_in_C, -999.9, P_fluid_in_MPa, m_dot_tube_kgs, False)

    def calc_perf_flux_mdot(inout self, flux_Wm2: Matrix[Float64], L_tube_m: Float64, d_out_m: Float64, th_m: Float64, T_fluid_in_C: Float64, P_fluid_in_MPa: Float64, m_dot_tube_kgs: Float64) -> Bool:
        var last_iter_max: Int = self.m_iter_d_in_max
        var last_th_min: Float64 = self.m_th_min_guess
        self.m_iter_d_in_max = 1
        self.m_th_min_guess = th_m
        var simok: Bool = self.calc_th_flux(flux_Wm2, L_tube_m, d_out_m, T_fluid_in_C, -999.9, P_fluid_in_MPa, m_dot_tube_kgs, False)
        self.m_iter_d_in_max = last_iter_max
        self.m_th_min_guess = last_th_min
        return simok

    def calc_th_flux(inout self, flux_Wm2: Matrix[Float64], L_tube_m: Float64, d_out_m: Float64, T_fluid_in_C: Float64, T_fluid_out_C: Float64, P_fluid_in_MPa: Float64, m_dot_tube: Float64, know_Tout: Bool) -> Bool:
        self.m_d_out = d_out_m
        self.m_T_fluid_in = T_fluid_in_C
        self.m_T_fluid_out = T_fluid_out_C
        self.m_P_fluid_in = P_fluid_in_MPa
        self.m_L_tube = L_tube_m
        self.m_m_dot_tube = m_dot_tube
        self.m_know_T_out = know_Tout
        self.m_flux_array = flux_Wm2
        self.m_n_tube_elements = self.m_flux_array.nrows()
        self.m_q_abs_array.resize(self.m_n_tube_elements)
        self.m_q_max_array.resize(self.m_n_tube_elements)
        self.m_L_node = self.m_L_tube / self.m_n_tube_elements
        for i in range(self.m_n_tube_elements):
            var qmax: Float64 = 0.0
            var qave: Float64 = 0.0
            var ncirc: Int = self.m_flux_array.ncols()
            for j in range(ncirc):
                var thisflux: Float64 = self.m_flux_array[i, j]
                qmax = qmax if qmax > thisflux else thisflux
                qave += thisflux
            qave /= ncirc
            self.m_q_abs_array[i] = qave * 2.0 * self.m_d_out * self.m_L_node
            self.m_q_max_array[i] = qmax
        return self.calc_min_thick_general()

    def calc_min_thick_general(inout self) -> Bool:
        self.m_n_temps = self.m_n_tube_elements + 1
        self.m_Temp.resize(self.m_n_temps)
        self.m_Pres.resize(self.m_n_temps)
        self.m_Enth.resize(self.m_n_temps)
        self.m_Tsurf.resize(self.m_n_temps)
        self.m_h_conv_ave.resize(self.m_n_tube_elements)
        var q_abs_total: Float64 = 0.0
        for i in range(self.m_n_tube_elements):
            q_abs_total += self.m_q_abs_array[i]
        self.m_Temp[0] = self.m_T_fluid_in
        self.m_Tsurf[0] = self.m_T_fluid_in
        self.m_Pres[0] = self.m_P_fluid_in * 1000.0
        var ret: Int = CO2_TP(self.m_Temp[0] + 273.15, self.m_Pres[0], Pointer[CO2_state](address_of(self.co2_props)))
        self.m_Enth[0] = self.co2_props.enth * 1000.0
        var tube_slice: C_tube_slice = C_tube_slice(C_rec_des_props.Haynes_230)
        var tube_inputs: C_tube_slice.S_ID_OD_perf_and_lifetime_inputs = C_tube_slice.S_ID_OD_perf_and_lifetime_inputs()
        var tube_outputs: C_tube_slice.S_ID_OD_perf_and_lifetime_outputs = C_tube_slice.S_ID_OD_perf_and_lifetime_outputs()
        var th_min_guess: Float64 = self.m_th_min_guess
        var th_step: Float64 = self.m_th_step
        var max_deltaP_frac: Float64 = self.m_max_deltaP_frac
        var search_min_th: Bool = True
        var is_deltaP_too_large: Bool = False
        var P_tube_out_prev: Float64 = self.m_Pres[0]
        var P_tube_out_min: Float64 = (1.0 - max_deltaP_frac) * self.m_Pres[0]
        var iter_d_in: Int = -1
        if self.m_know_T_out:
            self.m_m_dot_tube = float64(float64.nan)
        else:
            self.m_T_fluid_out = float64(float64.nan)
        self.m_d_in = float64(float64.nan)
        self.initialize_all_output_columns()
        while search_min_th:
            iter_d_in += 1
            self.m_d_in = self.m_d_out - 2.0 * (th_min_guess + th_step * iter_d_in)
            var A_cs: Float64 = 0.25 * CSP.pi * pow(self.m_d_in, 2)
            var relRough: Float64 = self.m_e_roughness / self.m_d_in
            var P_tube_out_guess: Float64 = 0.95 * P_tube_out_prev
            var P_tube_out_tolerance: Float64 = 0.001
            var P_tube_out_diff: Float64 = 2.0 * P_tube_out_tolerance
            var P_tube_guess_high: Float64 = P_tube_out_prev
            var P_tube_guess_low: Float64 = -999.9
            var iter_P_tube: Int = 0
            while fabs(P_tube_out_diff) > P_tube_out_tolerance:
                iter_P_tube += 1
                if iter_P_tube > 1:
                    if P_tube_out_diff > 0.0:
                        P_tube_guess_low = P_tube_out_guess
                        P_tube_out_guess = 0.5 * (P_tube_guess_low + P_tube_guess_high)
                    else:
                        P_tube_guess_high = P_tube_out_guess
                        if P_tube_guess_low < 0.0:
                            P_tube_out_guess = 0.95 * self.m_Pres[self.m_n_temps - 1]
                        else:
                            P_tube_out_guess = 0.5 * (P_tube_guess_low + P_tube_guess_high)
                    if P_tube_guess_high <= P_tube_out_min:
                        is_deltaP_too_large = True
                        break
                if P_tube_out_guess < P_tube_out_min:
                    P_tube_out_guess = P_tube_out_min
                if self.m_know_T_out:
                    ret = CO2_TP(self.m_T_fluid_out + 273.15, P_tube_out_guess, Pointer[CO2_state](address_of(self.co2_props)))
                    if ret != 0:
                        raise sco2_exception(CO2_error_message(ret))
                    var h_tube_out: Float64 = self.co2_props.enth * 1000.0
                    self.m_m_dot_tube = q_abs_total / (h_tube_out - self.m_Enth[0])
                else:
                    var h_tube_out: Float64 = q_abs_total / self.m_m_dot_tube + self.m_Enth[0]
                    ret = CO2_PH(P_tube_out_guess, h_tube_out / 1000.0, Pointer[CO2_state](address_of(self.co2_props)))
                    if ret != 0:
                        raise sco2_exception(CO2_error_message(ret))
                    self.m_T_fluid_out = self.co2_props.temp - 273.15
                var P_node_out_tolerance: Float64 = P_tube_out_tolerance
                var P_node_out_diff: Float64 = 2.0 * P_node_out_tolerance
                var is_P_out_too_low: Bool = False
                for i in range(1, self.m_n_temps):
                    var P_node_out_guess: Float64 = -999.9
                    if i == 1:
                        P_node_out_guess = self.m_Pres[0] - i / self.m_n_temps * (self.m_Pres[0] - P_tube_out_guess)
                    else:
                        P_node_out_guess = self.m_Pres[i - 1] - 1.25 * (self.m_Pres[i - 1] - self.m_Pres[i - 2])
                    var P_guess_high: Float64 = self.m_Pres[i - 1]
                    var P_guess_low: Float64 = -999.9
                    var iter_P_local: Int = 0
                    while fabs(P_node_out_diff) > P_node_out_tolerance:
                        iter_P_local += 1
                        if iter_P_local > 1:
                            if P_node_out_diff > 0.0:
                                P_guess_low = self.m_Pres[i]
                                P_node_out_guess = 0.5 * (P_guess_high + P_guess_low)
                            else:
                                P_guess_high = self.m_Pres[i]
                                if P_guess_low < 0.0:
                                    P_node_out_guess = 0.95 * self.m_Pres[i]
                                else:
                                    P_node_out_guess = 0.5 * (P_guess_high + P_guess_low)
                            if P_guess_high <= P_tube_out_min:
                                is_P_out_too_low = True
                                break
                        if P_node_out_guess < P_tube_out_min:
                            P_node_out_guess = P_tube_out_min
                        self.m_Enth[i] = self.m_Enth[i - 1] + self.m_q_abs_array[i - 1] / self.m_m_dot_tube
                        ret = CO2_PH(P_node_out_guess, self.m_Enth[i] / 1000.0, Pointer[CO2_state](address_of(self.co2_props)))
                        if ret != 0:
                            raise sco2_exception(CO2_error_message(ret))
                        self.m_Temp[i] = self.co2_props.temp - 273.15
                        var P_ave: Float64 = 0.5 * (P_node_out_guess + self.m_Pres[i - 1])
                        var h_ave: Float64 = 0.5 * (self.m_Enth[i] + self.m_Enth[i - 1])
                        ret = CO2_PH(P_ave, h_ave / 1000.0, Pointer[CO2_state](address_of(self.co2_props)))
                        if ret != 0:
                            raise sco2_exception(CO2_error_message(ret))
                        var visc_dyn: Float64 = CO2_visc(self.co2_props.dens, self.co2_props.temp) * 1.E-6
                        var Re: Float64 = self.m_m_dot_tube * self.m_d_in / (A_cs * visc_dyn)
                        var rho: Float64 = self.co2_props.dens
                        var visc_kin: Float64 = visc_dyn / rho
                        var cond: Float64 = CO2_cond(self.co2_props.dens, self.co2_props.temp)
                        var specheat: Float64 = self.co2_props.cp * 1000.0
                        var alpha: Float64 = cond / (specheat * rho)
                        var Pr: Float64 = visc_kin / alpha
                        var Nusselt: Float64 = -999.9
                        var f: Float64 = -999.9
                        CSP.PipeFlow(Re, Pr, 1000.0, relRough, Pointer[Float64](address_of(Nusselt)), Pointer[Float64](address_of(f)))
                        self.m_h_conv_ave[i - 1] = Nusselt * cond / self.m_d_in
                        var u_m: Float64 = self.m_m_dot_tube / (rho * A_cs)
                        self.m_Pres[i] = self.m_Pres[i - 1] - f * self.m_L_node * rho * pow(u_m, 2) / (2.0 * self.m_d_in) / 1000.0
                        P_node_out_diff = (self.m_Pres[i] - P_node_out_guess) / P_node_out_guess
                    if is_P_out_too_low:
                        self.m_Pres[self.m_n_temps - 1] = 0.9 * P_tube_out_guess
                        break
                P_tube_out_diff = (self.m_Pres[self.m_n_temps - 1] - P_tube_out_guess) / P_tube_out_guess
                P_tube_out_prev = self.m_Pres[self.m_n_temps - 1]
            if self.m_P_fluid_out[0] == self.m_P_fluid_out[0]:
                self.push_back_all_vectors()
            self.m_P_fluid_out[self.m_n_vector_results - 1] = self.m_Pres[self.m_n_temps - 1]
            if is_deltaP_too_large:
                break
            var total_damage: Float64 = 0.0
            if self.m_total_damage[1, 0] == self.m_total_damage[1, 0]:
                self.add_all_output_columns()
            for i in range(1, self.m_n_temps):
                tube_inputs.m_P_internal = self.m_Pres[0] / 1.E3
                tube_inputs.m_T_fluid = self.m_Temp[i]
                tube_inputs.m_d_out = self.m_d_out
                tube_inputs.m_d_in = self.m_d_in
                tube_inputs.m_flux = self.m_q_max_array[i - 1]
                tube_inputs.m_h_conv = self.m_h_conv_ave[i - 1]
                tube_slice.calc_ID_OD_perf_and_lifetime(tube_inputs, Pointer[C_tube_slice.S_ID_OD_perf_and_lifetime_outputs](address_of(tube_outputs)))
                var inner_total_damage: Float64 = tube_outputs.s_ID_lifetime_outputs.m_total_damage
                var outer_total_damage: Float64 = tube_outputs.s_OD_lifetime_outputs.m_total_damage
                total_damage = max(total_damage, max(inner_total_damage, outer_total_damage))
                self.m_total_damage[i - 1, self.m_n_results_cols - 1] = max(inner_total_damage, outer_total_damage)
                self.m_Tsurf[i] = tube_outputs.m_T_surf_out
            self.m_max_damage = total_damage
            if total_damage <= 1.0:
                search_min_th = False
            if not (iter_d_in < self.m_iter_d_in_max):
                search_min_th = False
        self.m_deltaP_kPa = self.m_Pres[self.m_n_temps - 1] - self.m_Pres[0]
        if is_deltaP_too_large or self.m_max_damage > 1.0:
            return False
        return True

    def initialize_all_output_columns(inout self):
        self.initialize_output_column(self.m_total_damage)
        self.m_n_results_cols = 1
        self.initialize_vector(self.m_P_fluid_out)
        self.m_n_vector_results = 1

    def initialize_output_column(inout self, results_matrix: Pointer[Matrix[Float64]]):
        results_matrix[].resize_fill(self.m_n_tube_elements, 1, float64(float64.nan))

    def initialize_vector(inout self, results_vector: Pointer[Vector[Float64]]):
        results_vector[].resize(1)
        results_vector[][0] = float64(float64.nan)

    def push_back_all_vectors(inout self):
        self.push_back_vector(self.m_P_fluid_out)
        self.m_n_vector_results += 1

    def push_back_vector(inout self, results_vector: Pointer[Vector[Float64]]):
        results_vector[].push_back(float64(float64.nan))

    def add_all_output_columns(inout self):
        self.add_output_column(self.m_total_damage)

    def add_output_column(inout self, results_matrix: Pointer[Matrix[Float64]]):
        self.m_element_results_temp = results_matrix[].copy()
        results_matrix[].resize(self.m_n_tube_elements, self.m_n_results_cols + 1)
        for i in range(self.m_n_tube_elements):
            for j in range(self.m_n_results_cols):
                results_matrix[][i, j] = self.m_element_results_temp[i, j]
            results_matrix[][i, self.m_n_results_cols] = float64(float64.nan)
        self.m_n_results_cols += 1