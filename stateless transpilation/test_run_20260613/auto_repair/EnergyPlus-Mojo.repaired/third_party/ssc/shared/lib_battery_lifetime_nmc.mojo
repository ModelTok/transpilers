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
from math import exp, sqrt, pow, fabs, fmin
from memory import shared_ptr, make_shared_ptr
from lib_util import util
from lib_battery_lifetime_calendar_cycle import lifetime_cycle_t, lifetime_params, lifetime_state, lifetime_t

const Rug: Float64 = 8.314
const T_ref: Float64 = 298.15
const F: Float64 = 96485

struct lifetime_nmc_state:
    var q_relative_li: Float64
    var q_relative_neg: Float64
    var dq_relative_li_old: Float64
    var dq_relative_neg_old: Float64
    var DOD_max: Float64
    var n_cycles_prev_day: Int
    var cum_dt: Float64
    var b1_dt: Float64
    var b2_dt: Float64
    var b3_dt: Float64
    var c0_dt: Float64
    var c2_dt: Float64

    def __init__(inout self):
        self.q_relative_li = 0.0
        self.q_relative_neg = 0.0
        self.dq_relative_li_old = 0.0
        self.dq_relative_neg_old = 0.0
        self.DOD_max = 0.0
        self.n_cycles_prev_day = 0
        self.cum_dt = 0.0
        self.b1_dt = 0.0
        self.b2_dt = 0.0
        self.b3_dt = 0.0
        self.c0_dt = 0.0
        self.c2_dt = 0.0

class lifetime_nmc_t(lifetime_t):
    var cycle_model: lifetime_cycle_t
    var Uneg_ref: Float64
    var V_ref: Float64
    var d0_ref: Float64
    var Ea_d0_1: Float64
    var Ea_d0_2: Float64
    var Ah_ref: Float64
    var b0: Float64
    var b1_ref: Float64
    var Ea_b1: Float64
    var alpha_a_b1: Float64
    var beta_b1: Float64
    var gamma: Float64
    var b2_ref: Float64
    var Ea_b_2: Float64
    var b3_ref: Float64
    var Ea_b3: Float64
    var alpha_a_b3: Float64
    var tau_b3: Float64
    var theta: Float64
    var c0_ref: Float64
    var Ea_c0_ref: Float64
    var c2_ref: Float64
    var Ea_c2: Float64
    var beta_c2: Float64

    def __init__(inout self, dt_hr: Float64):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.model_choice = lifetime_params.NMCNREL
        self.params.dt_hr = dt_hr
        self.initialize()

    def __init__(inout self, params_pt: shared_ptr[lifetime_params]):
        self.params = params_pt
        self.initialize()

    def __init__(inout self, params_pt: shared_ptr[lifetime_params], state_pt: shared_ptr[lifetime_state]):
        self.params = params_pt
        self.state = state_pt
        self.cycle_model = lifetime_cycle_t(self.params, self.state)

    def __init__(inout self, rhs: Self):
        lifetime_t.__init__(self, rhs)
        self = rhs

    def __copyinit__(inout self, rhs: Self):
        self = rhs

    def __moveinit__(inout self, owned rhs: Self):
        self.params = rhs.params
        self.state = rhs.state
        self.cycle_model = rhs.cycle_model
        self.Uneg_ref = rhs.Uneg_ref
        self.V_ref = rhs.V_ref
        self.d0_ref = rhs.d0_ref
        self.Ea_d0_1 = rhs.Ea_d0_1
        self.Ea_d0_2 = rhs.Ea_d0_2
        self.Ah_ref = rhs.Ah_ref
        self.b0 = rhs.b0
        self.b1_ref = rhs.b1_ref
        self.Ea_b1 = rhs.Ea_b1
        self.alpha_a_b1 = rhs.alpha_a_b1
        self.beta_b1 = rhs.beta_b1
        self.gamma = rhs.gamma
        self.b2_ref = rhs.b2_ref
        self.Ea_b_2 = rhs.Ea_b_2
        self.b3_ref = rhs.b3_ref
        self.Ea_b3 = rhs.Ea_b3
        self.alpha_a_b3 = rhs.alpha_a_b3
        self.tau_b3 = rhs.tau_b3
        self.theta = rhs.theta
        self.c0_ref = rhs.c0_ref
        self.Ea_c0_ref = rhs.Ea_c0_ref
        self.c2_ref = rhs.c2_ref
        self.Ea_c2 = rhs.Ea_c2
        self.beta_c2 = rhs.beta_c2

    def __del__(owned self):

    def clone(inout self) -> lifetime_t:
        return lifetime_nmc_t(self)

    def runLifetimeModels(inout self, lifetimeIndex: Int, charge_changed: Bool, prev_DOD: Float64, DOD: Float64, T_battery: Float64):
        var q_last: Float64 = self.state.q_relative
        T_battery += 273.15
        if charge_changed:
            self.cycle_model.rainflow(prev_DOD)
        var dt_day: Float64 = (1.0 / Float64(util.hours_per_day)) * self.params.dt_hr
        var new_cum_dt: Float64 = self.state.nmc_li_neg.cum_dt + dt_day
        if new_cum_dt > 1 + 1e-7:
            var dt_day_to_end_of_day: Float64 = 1 - self.state.nmc_li_neg.cum_dt
            var DOD_at_end_of_day: Float64 = (DOD - prev_DOD) / dt_day * dt_day_to_end_of_day + prev_DOD
            self.state.nmc_li_neg.DOD_max = fmax(DOD_at_end_of_day, self.state.nmc_li_neg.DOD_max)
            self.state.day_age_of_battery += dt_day_to_end_of_day
            self.integrateDegParams(dt_day_to_end_of_day, DOD_at_end_of_day, T_battery)
            self.integrateDegLoss(DOD_at_end_of_day, T_battery)
            dt_day = new_cum_dt - 1
        self.state.nmc_li_neg.DOD_max = fmax(DOD, self.state.nmc_li_neg.DOD_max)
        self.state.day_age_of_battery += dt_day
        self.integrateDegParams(dt_day, DOD, T_battery)
        if fabs(self.state.nmc_li_neg.cum_dt - 1.0) < 1e-7:
            self.integrateDegLoss(DOD, T_battery)
        self.state.q_relative = fmin(self.state.q_relative, q_last)

    def estimateCycleDamage(inout self) -> Float64:
        var c2: Float64 = self.c2_ref * pow(0.01 * self.state.average_range, self.beta_c2)
        var dq_cycle: Float64 = c2 / sqrt(self.c0_ref * self.c0_ref - 2 * c2 * self.c0_ref * Float64(self.state.n_cycles))
        return self.c0_ref / self.Ah_ref * dq_cycle * 100

    def replaceBattery(inout self, percent_to_replace: Float64):
        self.state.day_age_of_battery = 0
        self.state.nmc_li_neg.dq_relative_li_old = 0
        self.state.nmc_li_neg.dq_relative_neg_old = 0
        self.state.nmc_li_neg.q_relative_li += percent_to_replace
        self.state.nmc_li_neg.q_relative_neg += percent_to_replace
        self.state.nmc_li_neg.q_relative_li = fmin(100, self.state.nmc_li_neg.q_relative_li)
        self.state.nmc_li_neg.q_relative_neg = fmin(100, self.state.nmc_li_neg.q_relative_neg)
        self.state.q_relative = fmin(self.state.nmc_li_neg.q_relative_li, self.state.nmc_li_neg.q_relative_neg)

    def calculate_Uneg(SOC: Float64) -> Float64:
        var Uneg: Float64
        if SOC <= 0.1:
            Uneg = ((0.2420 - 1.2868) / 0.1) * SOC + 1.2868
        else:
            Uneg = ((0.0859 - 0.2420) / 0.9) * (SOC - 0.1) + 0.2420
        return Uneg

    def calculate_Voc(SOC: Float64) -> Float64:
        var Voc: Float64
        if SOC <= 0.1:
            Voc = ((0.4679) / 0.1) * SOC + 3
        elif SOC <= 0.6:
            Voc = ((3.747 - 3.4679) / 0.5) * (SOC - 0.1) + 3.4679
        else:
            Voc = ((4.1934 - 3.7469) / 0.4) * (SOC - 0.6) + 3.7469
        return Voc

    def runQli(inout self, T_battery_K: Float64) -> Float64:
        var dt_day: Float64 = 1
        var dn_cycles: Int = self.state.n_cycles - self.state.nmc_li_neg.n_cycles_prev_day
        var b1: Float64 = self.state.nmc_li_neg.b1_dt
        var b2: Float64 = self.state.nmc_li_neg.b2_dt
        var b3: Float64 = self.state.nmc_li_neg.b3_dt
        self.state.nmc_li_neg.b1_dt = 0
        self.state.nmc_li_neg.b2_dt = 0
        self.state.nmc_li_neg.b3_dt = 0
        var d0_t: Float64 = self.d0_ref * exp(-(self.Ea_d0_1 / Rug) * (1 / T_battery_K - 1 / T_ref) -
                          (self.Ea_d0_2 / Rug) * pow(1 / T_battery_K - 1 / T_ref, 2))
        var k_cal: Float64 = 0
        if self.state.day_age_of_battery > 0:
            k_cal = (0.5 * b1) / sqrt(self.state.day_age_of_battery) + (b3 / self.tau_b3) * exp(-(self.state.day_age_of_battery / self.tau_b3))
        var dq_new: Float64 = k_cal * dt_day + b2 * Float64(dn_cycles) + self.state.nmc_li_neg.dq_relative_li_old
        self.state.nmc_li_neg.dq_relative_li_old = dq_new
        self.state.nmc_li_neg.q_relative_li = d0_t / self.Ah_ref * (self.b0 - dq_new) * 100.0
        return self.state.nmc_li_neg.q_relative_li

    def runQneg(inout self) -> Float64:
        var dn_cycles: Int = self.state.n_cycles - self.state.nmc_li_neg.n_cycles_prev_day
        var c0: Float64 = self.state.nmc_li_neg.c0_dt
        var c2: Float64 = self.state.nmc_li_neg.c2_dt
        self.state.nmc_li_neg.c0_dt = 0
        self.state.nmc_li_neg.c2_dt = 0
        var dq_new: Float64 = 0
        if self.state.n_cycles > 0:
            dq_new = c2 / sqrt(c0 * c0 - 2 * c2 * c0 * Float64(self.state.n_cycles)) * Float64(dn_cycles) + self.state.nmc_li_neg.dq_relative_neg_old
        self.state.nmc_li_neg.dq_relative_neg_old = dq_new
        self.state.nmc_li_neg.q_relative_neg = c0 / self.Ah_ref * (1 - dq_new) * 100
        return self.state.nmc_li_neg.q_relative_neg

    def integrateDegParams(inout self, dt_day: Float64, DOD: Float64, T_battery: Float64):
        var SOC: Float64 = 0.01 * (100 - DOD)
        var DOD_max: Float64 = self.state.nmc_li_neg.DOD_max * 0.01
        var U_neg: Float64 = lifetime_nmc_t.calculate_Uneg(SOC)
        var V_oc: Float64 = lifetime_nmc_t.calculate_Voc(SOC)
        var b1_dt_el: Float64 = self.b1_ref * exp(-(self.Ea_b1 / Rug) * (1.0 / T_battery - 1.0 / T_ref)) \
                          * exp((self.alpha_a_b1 * F / Rug) * (U_neg / T_battery - self.Uneg_ref / T_ref)) \
                          * exp(self.gamma * pow(DOD_max, self.beta_b1)) * dt_day
        var b2_dt_el: Float64 = self.b2_ref * exp(-(self.Ea_b_2 / Rug) * (1.0 / T_battery - 1.0 / T_ref)) * dt_day
        var b3_dt_el: Float64 = self.b3_ref * exp(-(self.Ea_b3 / Rug) * (1.0 / T_battery - 1.0 / T_ref)) \
                          * exp((self.alpha_a_b3 * F / Rug) * (V_oc / T_battery - self.V_ref / T_ref)) \
                          * (1 + self.theta * DOD_max) * dt_day
        self.state.nmc_li_neg.b1_dt += b1_dt_el
        self.state.nmc_li_neg.b2_dt += b2_dt_el
        self.state.nmc_li_neg.b3_dt += b3_dt_el
        var c2_dt_el: Float64 = self.c2_ref * exp(-(self.Ea_c2 / Rug) * (1.0 / T_battery - 1.0 / T_ref)) \
                          * pow(0.01 * self.state.nmc_li_neg.DOD_max, self.beta_c2) * dt_day
        var c0_dt_el: Float64 = self.c0_ref * exp(-self.Ea_c0_ref / Rug * (1 / T_battery - 1 / T_ref)) * dt_day
        self.state.nmc_li_neg.c0_dt += c0_dt_el
        self.state.nmc_li_neg.c2_dt += c2_dt_el
        self.state.nmc_li_neg.cum_dt += dt_day

    def integrateDegLoss(inout self, DOD: Float64, T_battery: Float64):
        self.state.nmc_li_neg.q_relative_li = self.runQli(T_battery)
        self.state.nmc_li_neg.q_relative_neg = self.runQneg()
        self.state.q_relative = fmin(self.state.nmc_li_neg.q_relative_li, self.state.nmc_li_neg.q_relative_neg)
        self.state.nmc_li_neg.cum_dt = 0
        if self.state.n_cycles - self.state.nmc_li_neg.n_cycles_prev_day > 0:
            self.state.nmc_li_neg.DOD_max = DOD
        self.state.nmc_li_neg.n_cycles_prev_day = self.state.n_cycles

    def initialize(inout self):
        self.state = make_shared_ptr[lifetime_state]()
        self.cycle_model = lifetime_cycle_t(self.params, self.state)
        self.state.nmc_li_neg.dq_relative_li_old = 0
        self.state.nmc_li_neg.dq_relative_neg_old = 0
        self.state.nmc_li_neg.DOD_max = 0
        self.state.nmc_li_neg.n_cycles_prev_day = 0
        self.state.nmc_li_neg.cum_dt = 0
        self.state.nmc_li_neg.b1_dt = self.b1_ref
        self.state.nmc_li_neg.b2_dt = self.b2_ref
        self.state.nmc_li_neg.b3_dt = self.b3_ref
        self.state.nmc_li_neg.q_relative_li = self.runQli(T_ref)
        self.state.nmc_li_neg.c0_dt = self.c0_ref
        self.state.nmc_li_neg.c2_dt = self.c2_ref
        self.state.nmc_li_neg.q_relative_neg = self.runQneg()
        self.state.q_relative = fmin(self.state.nmc_li_neg.q_relative_li, self.state.nmc_li_neg.q_relative_neg)