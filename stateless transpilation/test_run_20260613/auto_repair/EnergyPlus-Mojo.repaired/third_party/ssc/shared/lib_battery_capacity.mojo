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

from math import fabs, fmax, fmin, exp
from memory import Pointer
from utils import StringRef

var low_tolerance: Float64 = 0.01
var tolerance: Float64 = 0.002

struct capacity_state:
    var q0: Float64  # [Ah] - Total capacity at timestep
    var qmax_lifetime: Float64  # [Ah] - maximum possible capacity
    var qmax_thermal: Float64  # [Ah] - maximum capacity adjusted for temperature affects
    var cell_current: Float64  # [A]  - Current draw during last step
    var I_loss: Float64  # [A] - Lifetime and thermal losses
    var SOC: Float64  # [%] - State of Charge
    var SOC_prev: Float64  # [%] - previous step
    var charge_mode: Int32  # {CHARGE, NO_CHARGE, DISCHARGE}
    var prev_charge: Int32  # {CHARGE, NO_CHARGE, DISCHARGE}
    var chargeChange: Bool  # [true/false] - indicates if charging state has changed since last step
    var leadacid: leadacid_substruct

    struct leadacid_substruct:
        var q1_0: Float64  # [Ah] - charge available
        var q2_0: Float64  # [Ah] - charge bound
        var q1: Float64  # [Ah]- capacity at discharge rate t1
        var q2: Float64  # [Ah] - capacity at discharge rate t2

    def __init__(inout self):
        self.q0 = 0.0
        self.qmax_lifetime = 0.0
        self.qmax_thermal = 0.0
        self.cell_current = 0.0
        self.I_loss = 0.0
        self.SOC = 0.0
        self.SOC_prev = 0.0
        self.charge_mode = 0
        self.prev_charge = 0
        self.chargeChange = False
        self.leadacid = leadacid_substruct()

    def __eq__(self, other: Self) -> Bool:
        var equal: Bool = (self.q0 == other.q0)
        equal = equal and (self.qmax_lifetime == other.qmax_lifetime)
        equal = equal and (self.qmax_thermal == other.qmax_thermal)
        equal = equal and (self.cell_current == other.cell_current)
        equal = equal and (self.I_loss == other.I_loss)
        equal = equal and (self.SOC == other.SOC)
        equal = equal and (self.SOC_prev == other.SOC_prev)
        equal = equal and (self.charge_mode == other.charge_mode)
        equal = equal and (self.prev_charge == other.prev_charge)
        equal = equal and (self.chargeChange == other.chargeChange)
        equal = equal and (self.leadacid.q1_0 == other.leadacid.q1_0)
        equal = equal and (self.leadacid.q2_0 == other.leadacid.q2_0)
        equal = equal and (self.leadacid.q1 == other.leadacid.q1)
        equal = equal and (self.leadacid.q2 == other.leadacid.q2)
        return equal

    @staticmethod
    def CHARGE() -> Int32:
        return 0
    @staticmethod
    def NO_CHARGE() -> Int32:
        return 1
    @staticmethod
    def DISCHARGE() -> Int32:
        return 2

struct capacity_params:
    var qmax_init: Float64  # [Ah] - original maximum capacity
    var initial_SOC: Float64  # [%] - Initial SOC
    var maximum_SOC: Float64  # [%] - Maximum SOC
    var minimum_SOC: Float64  # [%] - Minimum SOC
    var dt_hr: Float64  # [hr] - Timestep in hours
    var leadacid: leadacid_substruct

    struct leadacid_substruct:
        var tn: Float64  # [h] - discharge rate for capacity at qn
        var t2: Float64  # [h] - discharge rate for capacity at q2
        var F1: Float64  # [unitless] - internal ratio computation
        var F2: Float64  # [unitless] - internal ratio computation
        var qn: Float64  #  [Ah] - Capacity at tn hour discharge rate
        var q10: Float64  #  [Ah] - Capacity at 10 hour discharge rate
        var q20: Float64  # [Ah] - Capacity at 20 hour discharge rate
        var I20: Float64  # [A]  - Current at 20 hour discharge rate

    def __init__(inout self):
        self.qmax_init = 0.0
        self.initial_SOC = 0.0
        self.maximum_SOC = 0.0
        self.minimum_SOC = 0.0
        self.dt_hr = 0.0
        self.leadacid = leadacid_substruct()

trait capacity_t:
    def __init__(inout self)
    def __init__(inout self, q: Float64, SOC_init: Float64, SOC_max: Float64, SOC_min: Float64, dt_hour: Float64)
    def __init__(inout self, p: Pointer[capacity_params])
    def __copyinit__(inout self, rhs: Self)
    def __del__(owned self)
    def updateCapacity(inout self, I: Pointer[Float64], dt: Float64)
    def updateCapacityForThermal(inout self, capacity_percent: Float64)
    def updateCapacityForLifetime(inout self, capacity_percent: Float64)
    def replace_battery(inout self, replacement_percent: Float64)
    def change_SOC_limits(inout self, min: Float64, max: Float64)
    def q1(self) -> Float64
    def q10(self) -> Float64
    def check_charge_change(inout self)
    def check_SOC(inout self)
    def update_SOC(inout self)
    def SOC_min(self) -> Float64
    def SOC_max(self) -> Float64
    def SOC(self) -> Float64
    def SOC_prev(self) -> Float64
    def q0(self) -> Float64
    def qmax(self) -> Float64
    def qmax_thermal(self) -> Float64
    def I(self) -> Float64
    def chargeChanged(self) -> Bool
    def I_loss(self) -> Float64
    def charge_operation(self) -> Int32
    def get_params(self) -> capacity_params
    def get_state(self) -> capacity_state

@value
struct capacity_t_impl:
    var params: Pointer[capacity_params]
    var state: Pointer[capacity_state]

    def __init__(inout self):
        self.params = Pointer[capacity_params].alloc()
        self.state = Pointer[capacity_state].alloc()
        self.params[].__init__()
        self.state[].__init__()
        self.initialize()

    def __init__(inout self, q: Float64, SOC_init: Float64, SOC_max: Float64, SOC_min: Float64, dt_hour: Float64):
        self.__init__()
        self.params[].qmax_init = q
        self.params[].dt_hr = dt_hour
        self.params[].initial_SOC = SOC_init
        self.params[].maximum_SOC = SOC_max
        self.params[].minimum_SOC = SOC_min
        self.initialize()

    def __init__(inout self, p: Pointer[capacity_params]):
        self.params = p
        self.state = Pointer[capacity_state].alloc()
        self.state[].__init__()
        if (self.params[].initial_SOC < 0 or self.params[].initial_SOC > 100) or \
           (self.params[].maximum_SOC < 0 or self.params[].maximum_SOC > 100) or \
           (self.params[].minimum_SOC < 0 or self.params[].minimum_SOC > 100):
            raise Error("Initial, Max and Min state-of-charge % must be [0, 100]")
        self.initialize()

    def __copyinit__(inout self, rhs: Self):
        self.state = Pointer[capacity_state].alloc()
        self.params = Pointer[capacity_params].alloc()
        self.state[] = rhs.state[]
        self.params[] = rhs.params[]

    def __del__(owned self):
        self.params.free()
        self.state.free()

    def initialize(inout self):
        self.state[].q0 = 0.01 * self.params[].initial_SOC * self.params[].qmax_init
        self.state[].qmax_lifetime = self.params[].qmax_init
        self.state[].qmax_thermal = self.params[].qmax_init
        self.state[].cell_current = 0.0
        self.state[].I_loss = 0.0
        self.state[].SOC = self.params[].initial_SOC
        self.state[].SOC_prev = 0.0
        self.state[].prev_charge = capacity_state.DISCHARGE()
        self.state[].charge_mode = capacity_state.DISCHARGE()
        self.state[].chargeChange = False

    def check_charge_change(inout self):
        self.state[].charge_mode = capacity_state.NO_CHARGE()
        if self.state[].cell_current < 0:
            self.state[].charge_mode = capacity_state.CHARGE()
        elif self.state[].cell_current > 0:
            self.state[].charge_mode = capacity_state.DISCHARGE()
        self.state[].chargeChange = False
        if (self.state[].charge_mode != self.state[].prev_charge) and \
           (self.state[].charge_mode != capacity_state.NO_CHARGE()) and \
           (self.state[].prev_charge != capacity_state.NO_CHARGE()):
            self.state[].chargeChange = True
            self.state[].prev_charge = self.state[].charge_mode

    def charge_operation(self) -> Int32:
        return self.state[].charge_mode

    def get_params(self) -> capacity_params:
        return self.params[]

    def get_state(self) -> capacity_state:
        return self.state[]

    def check_SOC(inout self):
        var q_upper: Float64 = self.state[].qmax_lifetime * self.params[].maximum_SOC * 0.01
        var q_lower: Float64 = self.state[].qmax_lifetime * self.params[].minimum_SOC * 0.01
        if q_upper > self.state[].qmax_thermal * self.params[].maximum_SOC * 0.01:
            q_upper = self.state[].qmax_thermal * self.params[].maximum_SOC * 0.01
        if q_lower > self.state[].qmax_thermal * self.params[].minimum_SOC * 0.01:
            q_lower = self.state[].qmax_thermal * self.params[].minimum_SOC * 0.01
        if self.state[].q0 > q_upper + tolerance:
            if self.state[].cell_current < -tolerance:
                self.state[].cell_current += (self.state[].q0 - q_upper) / self.params[].dt_hr
                self.state[].cell_current = fmin(0, self.state[].cell_current)
            self.state[].q0 = q_upper
        elif self.state[].q0 < q_lower - tolerance:
            if self.state[].cell_current > tolerance:
                self.state[].cell_current += (self.state[].q0 - q_lower) / self.params[].dt_hr
                self.state[].cell_current = fmax(0, self.state[].cell_current)
            self.state[].q0 = q_lower

    def update_SOC(inout self):
        var max: Float64 = fmin(self.state[].qmax_lifetime, self.state[].qmax_thermal)
        if max == 0:
            self.state[].q0 = 0
            self.state[].SOC = 0
            return
        if self.state[].q0 > max:
            self.state[].q0 = max
        if self.state[].qmax_lifetime > 0:
            self.state[].SOC = 100.0 * (self.state[].q0 / max)
        else:
            self.state[].SOC = 0.0
        if self.state[].SOC > 100.0:
            self.state[].SOC = 100.0
        elif self.state[].SOC < 0.0:
            self.state[].SOC = 0.0

    def chargeChanged(self) -> Bool:
        return self.state[].chargeChange

    def SOC_max(self) -> Float64:
        return self.params[].maximum_SOC

    def SOC_min(self) -> Float64:
        return self.params[].minimum_SOC

    def SOC(self) -> Float64:
        return self.state[].SOC

    def SOC_prev(self) -> Float64:
        return self.state[].SOC_prev

    def q0(self) -> Float64:
        return self.state[].q0

    def qmax(self) -> Float64:
        return self.state[].qmax_lifetime

    def qmax_thermal(self) -> Float64:
        return self.state[].qmax_thermal

    def I(self) -> Float64:
        return self.state[].cell_current

    def I_loss(self) -> Float64:
        return self.state[].I_loss

    def change_SOC_limits(inout self, min: Float64, max: Float64):
        self.params[].minimum_SOC = min
        self.params[].maximum_SOC = max

struct capacity_kibam_t:
    var base: capacity_t_impl
    var c: Float64  # [0-1] - capacity fraction
    var k: Float64  # [1/hour] - rate constant

    def __init__(inout self, q20: Float64, t1: Float64, q1: Float64, q10: Float64, SOC_init: Float64, SOC_max: Float64,
                SOC_min: Float64, dt_hr: Float64):
        self.base = capacity_t_impl(q20, SOC_init, SOC_max, SOC_min, dt_hr)
        self.base.params[].leadacid.tn = t1
        self.base.params[].leadacid.qn = q1
        self.base.params[].leadacid.q10 = q10
        self.base.params[].leadacid.q20 = q20
        self.initialize()

    def __init__(inout self, p: Pointer[capacity_params]):
        self.base = capacity_t_impl(p)
        self.initialize()

    def __copyinit__(inout self, rhs: Self):
        self.base = rhs.base
        self.c = rhs.c
        self.k = rhs.k

    def __del__(owned self):

    def initialize(inout self):
        self.base.params[].leadacid.t2 = 10.0
        self.base.params[].leadacid.F1 = self.base.params[].leadacid.qn / self.base.params[].leadacid.q20
        self.base.params[].leadacid.F2 = self.base.params[].leadacid.qn / self.base.params[].leadacid.q10
        self.base.params[].leadacid.I20 = self.base.params[].leadacid.q20 / 20.0
        self.base.state[].leadacid.q1 = self.base.params[].leadacid.qn
        self.base.state[].leadacid.q2 = self.base.params[].leadacid.q10
        self.parameter_compute()
        self.base.state[].qmax_thermal = self.base.state[].qmax_lifetime
        self.base.params[].qmax_init = self.base.state[].qmax_lifetime
        self.base.state[].q0 = self.base.params[].qmax_init * self.base.params[].initial_SOC * 0.01
        self.replace_battery(100)

    def replace_battery(inout self, replacement_percent: Float64):
        replacement_percent = fmax(0, replacement_percent)
        var qmax_old: Float64 = self.base.state[].qmax_lifetime
        self.base.state[].qmax_lifetime += replacement_percent * 0.01 * self.base.params[].qmax_init
        self.base.state[].qmax_lifetime = fmin(self.base.state[].qmax_lifetime, self.base.params[].qmax_init)
        self.base.state[].qmax_thermal = self.base.state[].qmax_lifetime
        self.base.state[].q0 += (self.base.state[].qmax_lifetime - qmax_old) * self.base.params[].initial_SOC * 0.01
        self.base.state[].leadacid.q1_0 = self.base.state[].q0 * self.c
        self.base.state[].leadacid.q2_0 = self.base.state[].q0 - self.base.state[].leadacid.q1_0
        self.base.state[].SOC = self.base.params[].initial_SOC
        self.base.state[].SOC_prev = 50
        self.base.update_SOC()

    def c_compute(self, F: Float64, t1: Float64, t2: Float64, k_guess: Float64) -> Float64:
        var num: Float64 = F * (1 - exp(-k_guess * t1)) * t2 - (1 - exp(-k_guess * t2)) * t1
        var denom: Float64 = F * (1 - exp(-k_guess * t1)) * t2 - (1 - exp(-k_guess * t2)) * t1 - k_guess * F * t1 * t2 + \
                             k_guess * t1 * t2
        return (num / denom)

    def q1_compute(self, q10: Float64, q0: Float64, dt: Float64, I: Float64) -> Float64:
        var A: Float64 = q10 * exp(-self.k * dt)
        var B: Float64 = (q0 * self.k * self.c - I) * (1 - exp(-self.k * dt)) / self.k
        var C: Float64 = I * self.c * (self.k * dt - 1 + exp(-self.k * dt)) / self.k
        return (A + B - C)

    def q2_compute(self, q20: Float64, q0: Float64, dt: Float64, I: Float64) -> Float64:
        var A: Float64 = q20 * exp(-self.k * dt)
        var B: Float64 = q0 * (1 - self.c) * (1 - exp(-self.k * dt))
        var C: Float64 = I * (1 - self.c) * (self.k * dt - 1 + exp(-self.k * dt)) / self.k
        return (A + B - C)

    def Icmax_compute(self, q10: Float64, q0: Float64, dt: Float64) -> Float64:
        var num: Float64 = -self.k * self.c * self.base.state[].qmax_lifetime + self.k * q10 * exp(-self.k * dt) + \
                           q0 * self.k * self.c * (1 - exp(-self.k * dt))
        var denom: Float64 = 1 - exp(-self.k * dt) + self.c * (self.k * dt - 1 + exp(-self.k * dt))
        return (num / denom)

    def Idmax_compute(self, q10: Float64, q0: Float64, dt: Float64) -> Float64:
        var num: Float64 = self.k * q10 * exp(-self.k * dt) + q0 * self.k * self.c * (1 - exp(-self.k * dt))
        var denom: Float64 = 1 - exp(-self.k * dt) + self.c * (self.k * dt - 1 + exp(-self.k * dt))
        return (num / denom)

    def qmax_compute(self) -> Float64:
        var num: Float64 = self.base.params[].leadacid.q20 * ((1 - exp(-self.k * 20)) * (1 - self.c) + self.k * self.c * 20)
        var denom: Float64 = self.k * self.c * 20
        return (num / denom)

    def qmax_of_i_compute(self, T: Float64) -> Float64:
        return ((self.base.state[].qmax_lifetime * self.k * self.c * T) / \
                (1 - exp(-self.k * T) + self.c * (self.k * T - 1 + exp(-self.k * T))))

    def parameter_compute(inout self):
        var k_guess: Float64 = 0.0
        var c1: Float64 = 0.0
        var c2: Float64 = 0.0
        var minRes: Float64 = 10000.0
        for i in range(5000):
            k_guess = i * 0.001
            c1 = self.c_compute(self.base.params[].leadacid.F1, self.base.params[].leadacid.tn, 20, k_guess)
            c2 = self.c_compute(self.base.params[].leadacid.F2, self.base.params[].leadacid.tn, self.base.params[].leadacid.t2, k_guess)
            if fabs(c1 - c2) < minRes:
                minRes = fabs(c1 - c2)
                self.k = k_guess
                self.c = 0.5 * (c1 + c2)
        self.base.state[].qmax_lifetime = self.qmax_compute()

    def updateCapacity(inout self, I: Pointer[Float64], dt_hour: Float64):
        if fabs(I[]) < low_tolerance:
            I[] = 0
        self.base.state[].SOC_prev = self.base.state[].SOC
        self.base.state[].I_loss = 0.0
        self.base.state[].cell_current = I[]
        self.base.params[].dt_hr = dt_hour
        var Idmax: Float64 = 0.0
        var Icmax: Float64 = 0.0
        var Id: Float64 = 0.0
        var Ic: Float64 = 0.0
        var q1: Float64 = 0.0
        var q2: Float64 = 0.0
        if self.base.state[].cell_current > 0:
            Idmax = self.Idmax_compute(self.base.state[].leadacid.q1_0, self.base.state[].q0, dt_hour)
            Id = fmin(self.base.state[].cell_current, Idmax)
            self.base.state[].cell_current = Id
        elif self.base.state[].cell_current < 0:
            Icmax = self.Icmax_compute(self.base.state[].leadacid.q1_0, self.base.state[].q0, dt_hour)
            Ic = -fmin(fabs(self.base.state[].cell_current), fabs(Icmax))
            self.base.state[].cell_current = Ic
        q1 = self.q1_compute(self.base.state[].leadacid.q1_0, self.base.state[].q0, dt_hour, self.base.state[].cell_current)
        q2 = self.q2_compute(self.base.state[].leadacid.q2_0, self.base.state[].q0, dt_hour, self.base.state[].cell_current)
        if q1 + q2 > self.base.state[].qmax_thermal:
            var q0: Float64 = q1 + q2
            var p1: Float64 = q1 / q0
            var p2: Float64 = q2 / q0
            self.base.state[].q0 = self.base.state[].qmax_thermal
            q1 = self.base.state[].q0 * p1
            q2 = self.base.state[].q0 * p2
        self.base.state[].leadacid.q1_0 = q1
        self.base.state[].leadacid.q2_0 = q2
        self.base.state[].q0 = q1 + q2
        self.base.update_SOC()
        self.base.check_charge_change()
        I[] = self.base.state[].cell_current

    def updateCapacityForThermal(inout self, capacity_percent: Float64):
        if capacity_percent < 0:
            capacity_percent = 0
        self.base.state[].qmax_thermal = self.base.state[].qmax_lifetime * capacity_percent * 0.01
        if self.base.state[].q0 > self.base.state[].qmax_thermal:
            var q0_orig: Float64 = self.base.state[].q0
            var p: Float64 = self.base.state[].qmax_thermal / self.base.state[].q0
            self.base.state[].q0 *= p
            self.base.state[].leadacid.q1 *= p
            self.base.state[].leadacid.q2 *= p
            self.base.state[].I_loss += (q0_orig - self.base.state[].q0) / self.base.params[].dt_hr
        self.base.update_SOC()

    def updateCapacityForLifetime(inout self, capacity_percent: Float64):
        if capacity_percent < 0:
            capacity_percent = 0
        if self.base.params[].qmax_init * capacity_percent * 0.01 <= self.base.state[].qmax_lifetime:
            self.base.state[].qmax_lifetime = self.base.params[].qmax_init * capacity_percent * 0.01
        if self.base.state[].q0 > self.base.state[].qmax_lifetime:
            var q0_orig: Float64 = self.base.state[].q0
            var p: Float64 = self.base.state[].qmax_lifetime / self.base.state[].q0
            self.base.state[].q0 *= p
            self.base.state[].leadacid.q1 *= p
            self.base.state[].leadacid.q2 *= p
            self.base.state[].I_loss += (q0_orig - self.base.state[].q0) / self.base.params[].dt_hr
        self.base.update_SOC()

    def q1(self) -> Float64:
        return self.base.state[].leadacid.q1_0

    def q2(self) -> Float64:
        return self.base.state[].leadacid.q2_0

    def q10(self) -> Float64:
        return self.base.params[].leadacid.q10

    def q20(self) -> Float64:
        return self.base.params[].leadacid.q20

    def clone(self) -> Self:
        return Self(self)

struct capacity_lithium_ion_t:
    var base: capacity_t_impl

    def __init__(inout self, q: Float64, SOC_init: Float64, SOC_max: Float64, SOC_min: Float64, dt_hr: Float64):
        self.base = capacity_t_impl(q, SOC_init, SOC_max, SOC_min, dt_hr)

    def __init__(inout self, p: Pointer[capacity_params]):
        self.base = capacity_t_impl(p)

    def __copyinit__(inout self, rhs: Self):
        self.base = rhs.base

    def __del__(owned self):

    def replace_battery(inout self, replacement_percent: Float64):
        replacement_percent = fmax(0, replacement_percent)
        var qmax_old: Float64 = self.base.state[].qmax_lifetime
        self.base.state[].qmax_lifetime += self.base.params[].qmax_init * replacement_percent * 0.01
        self.base.state[].qmax_lifetime = fmin(self.base.params[].qmax_init, self.base.state[].qmax_lifetime)
        self.base.state[].qmax_thermal = self.base.state[].qmax_lifetime
        self.base.state[].q0 += (self.base.state[].qmax_lifetime - qmax_old) * self.base.params[].initial_SOC * 0.01
        self.base.state[].SOC = self.base.params[].initial_SOC
        self.base.state[].SOC_prev = 50
        self.base.update_SOC()

    def updateCapacity(inout self, I: Pointer[Float64], dt: Float64):
        self.base.state[].SOC_prev = self.base.state[].SOC
        self.base.state[].I_loss = 0.0
        self.base.params[].dt_hr = dt
        self.base.state[].cell_current = I[]
        self.base.state[].q0 -= self.base.state[].cell_current * dt
        self.base.check_SOC()
        self.base.update_SOC()
        self.base.check_charge_change()
        I[] = self.base.state[].cell_current

    def updateCapacityForThermal(inout self, capacity_percent: Float64):
        if capacity_percent < 0:
            capacity_percent = 0
        self.base.state[].qmax_thermal = self.base.state[].qmax_lifetime * capacity_percent * 0.01
        if self.base.state[].q0 > self.base.state[].qmax_thermal:
            self.base.state[].I_loss += (self.base.state[].q0 - self.base.state[].qmax_thermal) / self.base.params[].dt_hr
            self.base.state[].q0 = self.base.state[].qmax_thermal
        self.base.update_SOC()

    def updateCapacityForLifetime(inout self, capacity_percent: Float64):
        if capacity_percent < 0:
            capacity_percent = 0
        if self.base.params[].qmax_init * capacity_percent * 0.01 <= self.base.state[].qmax_lifetime:
            self.base.state[].qmax_lifetime = self.base.params[].qmax_init * capacity_percent * 0.01
        if self.base.state[].q0 > self.base.state[].qmax_lifetime:
            self.base.state[].I_loss += (self.base.state[].q0 - self.base.state[].qmax_lifetime) / self.base.params[].dt_hr
            self.base.state[].q0 = self.base.state[].qmax_lifetime
        self.base.update_SOC()

    def q1(self) -> Float64:
        return self.base.state[].q0

    def q10(self) -> Float64:
        return self.base.state[].qmax_lifetime

    def clone(self) -> Self:
        return Self(self)