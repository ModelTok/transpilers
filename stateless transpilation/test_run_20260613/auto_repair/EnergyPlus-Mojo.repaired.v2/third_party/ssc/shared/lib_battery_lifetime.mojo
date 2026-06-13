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
from lib_battery_lifetime_calendar_cycle import calendar_cycle_params, cycle_state, calendar_state
from lib_battery_lifetime_nmc import lifetime_nmc_state
from math import fmin

struct calendar_cycle_params:

struct lifetime_params:
    var dt_hr: Float64
    enum MODEL_CHOICE:
        case CALCYC
        case NMCNREL
    var model_choice: MODEL_CHOICE
    var cal_cyc: Pointer[calendar_cycle_params]

    def __init__(inout self):
        self.model_choice = MODEL_CHOICE.CALCYC
        self.cal_cyc = Pointer[calendar_cycle_params].alloc(1)
        self.cal_cyc[0] = calendar_cycle_params()

    def __copyinit__(inout self, other: Self):
        self.dt_hr = other.dt_hr
        self.model_choice = other.model_choice
        self.cal_cyc = Pointer[calendar_cycle_params].alloc(1)
        self.cal_cyc[0] = other.cal_cyc[0]

    def __del__(owned self):
        self.cal_cyc.free()

struct cycle_state:
    var q_relative_cycle: Float64
    def __init__(inout self):
        self.q_relative_cycle = 0.0

struct calendar_state:
    var q_relative_calendar: Float64
    def __init__(inout self):
        self.q_relative_calendar = 0.0

struct lifetime_nmc_state:
    var q_relative_li: Float64
    var q_relative_neg: Float64
    def __init__(inout self):
        self.q_relative_li = 0.0
        self.q_relative_neg = 0.0

struct lifetime_state:
    var q_relative: Float64
    var n_cycles: Int
    var range: Float64
    var average_range: Float64
    var day_age_of_battery: Float64
    var calendar: Pointer[calendar_state]
    var cycle: Pointer[cycle_state]
    var nmc_li_neg: Pointer[lifetime_nmc_state]

    def __init__(inout self):
        self.q_relative = 0.0
        self.n_cycles = 0
        self.range = 0.0
        self.average_range = 0.0
        self.day_age_of_battery = 0.0
        self.cycle = Pointer[cycle_state].alloc(1)
        self.cycle[0] = cycle_state()
        self.calendar = Pointer[calendar_state].alloc(1)
        self.calendar[0] = calendar_state()
        self.nmc_li_neg = Pointer[lifetime_nmc_state].alloc(1)
        self.nmc_li_neg[0] = lifetime_nmc_state()

    def __init__(inout self, other: Self):
        self.q_relative = other.q_relative
        self.n_cycles = other.n_cycles
        self.range = other.range
        self.average_range = other.average_range
        self.day_age_of_battery = other.day_age_of_battery
        self.cycle = Pointer[cycle_state].alloc(1)
        self.cycle[0] = other.cycle[0]
        self.calendar = Pointer[calendar_state].alloc(1)
        self.calendar[0] = other.calendar[0]
        self.nmc_li_neg = Pointer[lifetime_nmc_state].alloc(1)
        self.nmc_li_neg[0] = other.nmc_li_neg[0]

    def __init__(inout self, cyc: Pointer[cycle_state], cal: Pointer[calendar_state]):
        self.q_relative = 0.0
        self.n_cycles = 0
        self.range = 0.0
        self.average_range = 0.0
        self.day_age_of_battery = 0.0
        self.cycle = cyc
        self.calendar = cal
        self.nmc_li_neg = Pointer[lifetime_nmc_state].alloc(1)
        self.nmc_li_neg[0] = lifetime_nmc_state()
        self.q_relative = fmin(self.cycle[0].q_relative_cycle, self.calendar[0].q_relative_calendar)

    def __init__(inout self, nmc: Pointer[lifetime_nmc_state]):
        self.q_relative = 0.0
        self.n_cycles = 0
        self.range = 0.0
        self.average_range = 0.0
        self.day_age_of_battery = 0.0
        self.nmc_li_neg = nmc
        self.cycle = Pointer[cycle_state].alloc(1)
        self.cycle[0] = cycle_state()
        self.calendar = Pointer[calendar_state].alloc(1)
        self.calendar[0] = calendar_state()
        self.q_relative = fmin(self.nmc_li_neg[0].q_relative_li, self.nmc_li_neg[0].q_relative_neg)

    def __copyinit__(inout self, other: Self):
        self.q_relative = other.q_relative
        self.n_cycles = other.n_cycles
        self.range = other.range
        self.average_range = other.average_range
        self.day_age_of_battery = other.day_age_of_battery
        self.cycle = Pointer[cycle_state].alloc(1)
        self.cycle[0] = other.cycle[0]
        self.calendar = Pointer[calendar_state].alloc(1)
        self.calendar[0] = other.calendar[0]
        self.nmc_li_neg = Pointer[lifetime_nmc_state].alloc(1)
        self.nmc_li_neg[0] = other.nmc_li_neg[0]

    def __del__(owned self):
        self.cycle.free()
        self.calendar.free()
        self.nmc_li_neg.free()

trait lifetime_t:
    def __init__(inout self):

    def __init__(inout self, rhs: Self):
        self.state = Pointer[lifetime_state].alloc(1)
        self.state[0] = rhs.state[0]
        self.params = Pointer[lifetime_params].alloc(1)
        self.params[0] = rhs.params[0]

    def __copyinit__(inout self, other: Self):
        self.params = Pointer[lifetime_params].alloc(1)
        self.params[0] = other.params[0]
        self.state = Pointer[lifetime_state].alloc(1)
        self.state[0] = other.state[0]

    def __del__(owned self):
        self.state.free()
        self.params.free()

    def clone(self) -> Pointer[lifetime_t]:
        ...

    def runLifetimeModels(inout self, lifetimeIndex: Int, charge_changed: Bool, prev_DOD: Float64, DOD: Float64, T_battery: Float64):
        ...

    def capacity_percent(self) -> Float64:
        return self.state[0].q_relative

    def estimateCycleDamage(self) -> Float64:
        ...

    def replaceBattery(inout self, percent_to_replace: Float64):
        ...

    def get_params(self) -> lifetime_params:
        return self.params[0]

    def get_state(self) -> lifetime_state:
        var state_copy = self.state[0]
        return state_copy

    var state: Pointer[lifetime_state]
    var params: Pointer[lifetime_params]