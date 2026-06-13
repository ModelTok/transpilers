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
from math import exp, fabs, fmin, fmax, sqrt, pow
from memory import shared_ptr, make_shared_ptr
from lib_util import util
from lib_battery_lifetime import lifetime_params, lifetime_state, lifetime_t
from lib_battery_lifetime_nmc import *

var tolerance: Float64
var low_tolerance: Float64

struct calendar_cycle_params:
    var cycling_matrix: util.matrix_t[Float64]
    enum CYCLING_COLUMNS:
        DOD = 0
        CYCLE = 1
        CAPACITY_CYCLE = 2
    enum CALENDAR_CHOICE:
        NONE = 0
        MODEL = 1
        TABLE = 2
    var calendar_choice: Int
    var calendar_q0: Float64
    var calendar_a: Float64
    var calendar_b: Float64
    var calendar_c: Float64
    var calendar_matrix: util.matrix_t[Float64]
    enum CALENDAR_COLUMNS:
        DAYS = 0
        CAPACITY_CAL = 1

struct cycle_state:
    var q_relative_cycle: Float64
    enum RAINFLOW_CODES:
        LT_SUCCESS = 0
        LT_GET_DATA = 1
        LT_RERANGE = 2
    var rainflow_Xlt: Float64
    var rainflow_Ylt: Float64
    var rainflow_jlt: Int
    var rainflow_peaks: List[Float64]

class lifetime_cycle_t:
    var params: shared_ptr[lifetime_params]
    var state: shared_ptr[lifetime_state]

    def __init__(self, batt_lifetime_matrix: util.matrix_t[Float64]):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.cal_cyc.cycling_matrix = batt_lifetime_matrix
        self.state = make_shared_ptr[lifetime_state]()
        self.initialize()

    def __init__(self, params_ptr: shared_ptr[lifetime_params]):
        self.params = params_ptr
        self.state = make_shared_ptr[lifetime_state]()
        self.initialize()

    def __init__(self, params_ptr: shared_ptr[lifetime_params], state_ptr: shared_ptr[lifetime_state]):
        self.params = params_ptr
        self.state = state_ptr

    def __init__(self, rhs: Self):
        self.state = make_shared_ptr[lifetime_state](rhs.state[])
        self.__copyinit__(rhs)

    def __copyinit__(self, rhs: Self):
        if self is not rhs:
            self.state[] = rhs.state[]
            self.params[] = rhs.params[]

    def clone(self) -> Self:
        return Self(self)

    def runCycleLifetime(self, DOD: Float64) -> Float64:
        self.rainflow(DOD)
        return self.state.cycle.q_relative_cycle

    def estimateCycleDamage(self) -> Float64:
        var DOD: Float64 = 50.0
        if self.state.average_range > 0.0:
            DOD = self.state.average_range
        return (self.bilinear(DOD, self.state.n_cycles + 1) - self.bilinear(DOD, self.state.n_cycles + 2))

    def capacity_percent(self) -> Float64:
        return self.state.cycle.q_relative_cycle

    def rainflow(self, DOD: Float64):
        var retCode: Int = cycle_state.RAINFLOW_CODES.LT_GET_DATA
        self.state.cycle.rainflow_peaks.append(DOD)
        var atStepTwo: Bool = True
        while atStepTwo:
            if self.state.cycle.rainflow_jlt >= 2:
                self.rainflow_ranges()
            else:
                retCode = cycle_state.RAINFLOW_CODES.LT_GET_DATA
                break
            retCode = self.rainflow_compareRanges()
            if retCode == cycle_state.RAINFLOW_CODES.LT_GET_DATA:
                break
        if retCode == cycle_state.RAINFLOW_CODES.LT_GET_DATA:
            self.state.cycle.rainflow_jlt += 1

    def rainflow_ranges(self):
        self.state.cycle.rainflow_Ylt = fabs(self.state.cycle.rainflow_peaks[self.state.cycle.rainflow_jlt - 1] - self.state.cycle.rainflow_peaks[self.state.cycle.rainflow_jlt - 2])
        self.state.cycle.rainflow_Xlt = fabs(self.state.cycle.rainflow_peaks[self.state.cycle.rainflow_jlt] - self.state.cycle.rainflow_peaks[self.state.cycle.rainflow_jlt - 1])

    def rainflow_ranges_circular(self, index: Int):
        var end: Int = len(self.state.cycle.rainflow_peaks) - 1
        if index == 0:
            self.state.cycle.rainflow_Xlt = fabs(self.state.cycle.rainflow_peaks[0] - self.state.cycle.rainflow_peaks[end])
            self.state.cycle.rainflow_Ylt = fabs(self.state.cycle.rainflow_peaks[end] - self.state.cycle.rainflow_peaks[end - 1])
        elif index == 1:
            self.state.cycle.rainflow_Xlt = fabs(self.state.cycle.rainflow_peaks[1] - self.state.cycle.rainflow_peaks[0])
            self.state.cycle.rainflow_Ylt = fabs(self.state.cycle.rainflow_peaks[0] - self.state.cycle.rainflow_peaks[end])
        else:
            self.rainflow_ranges()

    def rainflow_compareRanges(self) -> Int:
        var retCode: Int = cycle_state.RAINFLOW_CODES.LT_SUCCESS
        var contained: Bool = True
        if self.state.cycle.rainflow_Xlt + tolerance < self.state.cycle.rainflow_Ylt:
            retCode = cycle_state.RAINFLOW_CODES.LT_GET_DATA
        else:
            contained = False
        if not contained:
            self.state.range = self.state.cycle.rainflow_Ylt
            self.state.average_range = (self.state.average_range * self.state.n_cycles + self.state.range) / Float64(self.state.n_cycles + 1)
            self.state.n_cycles += 1
            var dq: Float64 = self.bilinear(self.state.average_range, self.state.n_cycles) - self.bilinear(self.state.average_range, self.state.n_cycles + 1)
            if dq > 0.0:
                self.state.cycle.q_relative_cycle -= dq
            if self.state.cycle.q_relative_cycle < 0.0:
                self.state.cycle.q_relative_cycle = 0.0
            var save: Float64 = self.state.cycle.rainflow_peaks[self.state.cycle.rainflow_jlt]
            self.state.cycle.rainflow_peaks.pop_back()
            self.state.cycle.rainflow_peaks.pop_back()
            self.state.cycle.rainflow_peaks.pop_back()
            self.state.cycle.rainflow_peaks.append(save)
            self.state.cycle.rainflow_jlt -= 2
            retCode = cycle_state.RAINFLOW_CODES.LT_RERANGE
        return retCode

    def replaceBattery(self, replacement_percent: Float64):
        self.state.cycle.q_relative_cycle += replacement_percent
        self.state.cycle.q_relative_cycle = fmin(self.bilinear(0.0, 0), self.state.cycle.q_relative_cycle)
        if replacement_percent == 100.0:
            self.state.n_cycles = 0
        self.state.cycle.rainflow_jlt = 0
        self.state.cycle.rainflow_Xlt = 0.0
        self.state.cycle.rainflow_Ylt = 0.0
        self.state.range = 0.0
        self.state.cycle.rainflow_peaks.clear()

    def cycles_elapsed(self) -> Int:
        return self.state.n_cycles

    def cycle_range(self) -> Float64:
        return self.state.range

    def average_range(self) -> Float64:
        return self.state.average_range

    def get_state(self) -> lifetime_state:
        return self.state[]

    def bilinear(self, DOD: Float64, cycle_number: Int) -> Float64:
        var D_unique_vect: List[Float64] = List[Float64]()
        var C_n_low_vect: List[Float64] = List[Float64]()
        var D_high_vect: List[Float64] = List[Float64]()
        var C_n_high_vect: List[Float64] = List[Float64]()
        var low_indices: List[Int] = List[Int]()
        var high_indices: List[Int] = List[Int]()
        var D: Float64 = 0.0
        var n: Int = 0
        var C: Float64 = 100.0
        var n_rows: Int = self.params.cal_cyc.cycling_matrix.nrows()
        D_unique_vect.append(self.params.cal_cyc.cycling_matrix.at(0, calendar_cycle_params.CYCLING_COLUMNS.DOD))
        for i in range(n_rows):
            var contained: Bool = False
            for j in D_unique_vect:
                if self.params.cal_cyc.cycling_matrix.at(i, calendar_cycle_params.CYCLING_COLUMNS.DOD) == j:
                    contained = True
                    break
            if not contained:
                D_unique_vect.append(self.params.cal_cyc.cycling_matrix.at(i, calendar_cycle_params.CYCLING_COLUMNS.DOD))
        n = len(D_unique_vect)
        if n > 1:
            var D_lo: Float64 = 0.0
            var D_hi: Float64 = 100.0
            for i in range(n_rows):
                D = self.params.cal_cyc.cycling_matrix.at(i, calendar_cycle_params.CYCLING_COLUMNS.DOD)
                if D < DOD and D > D_lo:
                    D_lo = D
                elif D >= DOD and D < D_hi:
                    D_hi = D
            var D_min: Float64 = 100.0
            var D_max: Float64 = 0.0
            for i in range(n_rows):
                D = self.params.cal_cyc.cycling_matrix.at(i, calendar_cycle_params.CYCLING_COLUMNS.DOD)
                if D == D_lo:
                    low_indices.append(i)
                elif D == D_hi:
                    high_indices.append(i)
                if D < D_min:
                    D_min = D
                elif D > D_max:
                    D_max = D
            if len(high_indices) == 0:
                for i in range(n_rows):
                    if self.params.cal_cyc.cycling_matrix.at(i, calendar_cycle_params.CYCLING_COLUMNS.DOD) == D_max:
                        high_indices.append(i)
            var n_rows_lo: Int = len(low_indices)
            var n_rows_hi: Int = len(high_indices)
            var n_cols: Int = 2
            if n_rows_lo == 0:
                for i in range(n_rows_hi):
                    C_n_low_vect.append(0.0 + Float64(i) * 500.0)
                    C_n_low_vect.append(100.0)
            if n_rows_lo != 0:
                for i in range(n_rows_lo):
                    C_n_low_vect.append(self.params.cal_cyc.cycling_matrix.at(low_indices[i], calendar_cycle_params.CYCLING_COLUMNS.CYCLE))
                    C_n_low_vect.append(self.params.cal_cyc.cycling_matrix.at(low_indices[i], calendar_cycle_params.CYCLING_COLUMNS.CAPACITY_CYCLE))
            if n_rows_hi != 0:
                for i in range(n_rows_hi):
                    C_n_high_vect.append(self.params.cal_cyc.cycling_matrix.at(high_indices[i], calendar_cycle_params.CYCLING_COLUMNS.CYCLE))
                    C_n_high_vect.append(self.params.cal_cyc.cycling_matrix.at(high_indices[i], calendar_cycle_params.CYCLING_COLUMNS.CAPACITY_CYCLE))
            n_rows_lo = len(C_n_low_vect) // n_cols
            n_rows_hi = len(C_n_high_vect) // n_cols
            if n_rows_lo == 0 or n_rows_hi == 0:

            var C_n_low: util.matrix_t[Float64] = util.matrix_t[Float64](n_rows_lo, n_cols, C_n_low_vect)
            var C_n_high: util.matrix_t[Float64] = util.matrix_t[Float64](n_rows_lo, n_cols, C_n_high_vect)
            var C_Dlo: Float64 = util.linterp_col(C_n_low, 0, cycle_number, 1)
            var C_Dhi: Float64 = util.linterp_col(C_n_high, 0, cycle_number, 1)
            if C_Dlo < 0.0:
                C_Dlo = 0.0
            if C_Dhi > 100.0:
                C_Dhi = 100.0
            C = util.interpolate(D_lo, C_Dlo, D_hi, C_Dhi, DOD)
        else:
            C = util.linterp_col(self.params.cal_cyc.cycling_matrix, 1, cycle_number, 2)
        return C

    def initialize(self):
        self.state.n_cycles = 0
        self.state.range = 0.0
        self.state.average_range = 0.0
        self.state.cycle.q_relative_cycle = self.bilinear(0.0, 0)
        self.state.cycle.rainflow_jlt = 0
        self.state.cycle.rainflow_Xlt = 0.0
        self.state.cycle.rainflow_Ylt = 0.0
        self.state.cycle.rainflow_peaks.clear()

struct calendar_state:
    var q_relative_calendar: Float64
    var dq_relative_calendar_old: Float64

    def __eq__(self, p: Self) -> Bool:
        var equal: Bool = (self.q_relative_calendar == p.q_relative_calendar)
        equal = equal and (self.dq_relative_calendar_old == p.dq_relative_calendar_old)
        return equal

class lifetime_calendar_t:
    var dt_day: Float64
    var params: shared_ptr[lifetime_params]
    var state: shared_ptr[lifetime_state]

    def __init__(self, dt_hour: Float64, calendar_matrix: util.matrix_t[Float64]):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.dt_hr = dt_hour
        self.params.cal_cyc.calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.TABLE
        self.params.cal_cyc.calendar_matrix = calendar_matrix
        self.state = make_shared_ptr[lifetime_state]()
        self.initialize()

    def __init__(self, dt_hour: Float64, q0: Float64 = 1.02, a: Float64 = 2.66e-3, b: Float64 = -7280.0, c: Float64 = 930.0):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.dt_hr = dt_hour
        self.params.cal_cyc.calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.MODEL
        self.params.cal_cyc.calendar_q0 = q0
        self.params.cal_cyc.calendar_a = a
        self.params.cal_cyc.calendar_b = b
        self.params.cal_cyc.calendar_c = c
        self.state = make_shared_ptr[lifetime_state]()
        self.initialize()

    def __init__(self, params_ptr: shared_ptr[lifetime_params], state_ptr: shared_ptr[lifetime_state]):
        self.params = params_ptr
        self.state = state_ptr

    def __init__(self, rhs: Self):
        self.state = make_shared_ptr[lifetime_state](rhs.state[])
        self.params = make_shared_ptr[lifetime_params](rhs.params[])
        self.dt_day = rhs.dt_day

    def __copyinit__(self, rhs: Self):
        if self is not rhs:
            self.params[] = rhs.params[]
            self.state[] = rhs.state[]
            self.dt_day = rhs.dt_day

    def clone(self) -> Self:
        return Self(self)

    def runLifetimeCalendarModel(self, lifetimeIndex: Int, T: Float64, SOC: Float64) -> Float64:
        self.state.day_age_of_battery = Float64(lifetimeIndex) / (util.hours_per_day / self.params.dt_hr)
        if self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.MODEL:
            self.runLithiumIonModel(T, SOC)
        elif self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.TABLE:
            self.runTableModel()
        else:
            self.state.calendar.q_relative_calendar = 100.0
        return self.state.calendar.q_relative_calendar

    def replaceBattery(self, replacement_percent: Float64):
        self.state.day_age_of_battery = 0.0
        self.state.calendar.dq_relative_calendar_old = 0.0
        self.state.calendar.q_relative_calendar += replacement_percent
        if self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.MODEL:
            self.state.calendar.q_relative_calendar = fmin(self.params.cal_cyc.calendar_q0 * 100.0, self.state.calendar.q_relative_calendar)
        if self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.TABLE:
            self.state.calendar.q_relative_calendar = fmin(100.0, self.state.calendar.q_relative_calendar)

    def capacity_percent(self) -> Float64:
        return self.state.calendar.q_relative_calendar

    def get_state(self) -> lifetime_state:
        return self.state[]

    def runLithiumIonModel(self, temp: Float64, SOC: Float64):
        var temp_k: Float64 = temp + 273.15
        var SOC_frac: Float64 = SOC * 0.01
        var k_cal: Float64 = self.params.cal_cyc.calendar_a * exp(self.params.cal_cyc.calendar_b * (1.0 / temp_k - 1.0 / 296.0)) * exp(self.params.cal_cyc.calendar_c * (SOC_frac / temp_k - 1.0 / 296.0))
        var dq_new: Float64
        if self.state.calendar.dq_relative_calendar_old == 0.0:
            dq_new = k_cal * sqrt(self.dt_day)
        else:
            dq_new = (0.5 * pow(k_cal, 2) / self.state.calendar.dq_relative_calendar_old) * self.dt_day + self.state.calendar.dq_relative_calendar_old
        self.state.calendar.dq_relative_calendar_old = dq_new
        self.state.calendar.q_relative_calendar = (self.params.cal_cyc.calendar_q0 - dq_new) * 100.0

    def runTableModel(self):
        var n_rows: Int = self.params.cal_cyc.calendar_matrix.nrows()
        var n: Int = n_rows - 1
        var day_lo: Int = 0
        var day_hi: Int = Int(self.params.cal_cyc.calendar_matrix.at(n, calendar_cycle_params.CALENDAR_COLUMNS.DAYS))
        var capacity_lo: Float64 = 100.0
        var capacity_hi: Float64 = 0.0
        for i in range(n_rows):
            var day: Int = Int(self.params.cal_cyc.calendar_matrix.at(i, calendar_cycle_params.CALENDAR_COLUMNS.DAYS))
            var capacity: Float64 = Float64(Int(self.params.cal_cyc.calendar_matrix.at(i, calendar_cycle_params.CALENDAR_COLUMNS.CAPACITY_CAL)))
            if Float64(day) <= self.state.day_age_of_battery:
                day_lo = day
                capacity_lo = capacity
            if Float64(day) > self.state.day_age_of_battery:
                day_hi = day
                capacity_hi = capacity
                break
        if day_lo == day_hi:
            day_lo = Int(self.params.cal_cyc.calendar_matrix.at(n - 1, calendar_cycle_params.CALENDAR_COLUMNS.DAYS))
            day_hi = Int(self.params.cal_cyc.calendar_matrix.at(n, calendar_cycle_params.CALENDAR_COLUMNS.DAYS))
            capacity_lo = Float64(Int(self.params.cal_cyc.calendar_matrix.at(n - 1, calendar_cycle_params.CALENDAR_COLUMNS.CAPACITY_CAL)))
            capacity_hi = Float64(Int(self.params.cal_cyc.calendar_matrix.at(n, calendar_cycle_params.CALENDAR_COLUMNS.CAPACITY_CAL)))
        self.state.calendar.q_relative_calendar = util.interpolate(Float64(day_lo), capacity_lo, Float64(day_hi), capacity_hi, self.state.day_age_of_battery)

    def initialize(self):
        self.state.day_age_of_battery = 0.0
        self.state.calendar.q_relative_calendar = 100.0
        self.state.calendar.dq_relative_calendar_old = 0.0
        if self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.MODEL:
            self.dt_day = self.params.dt_hr / util.hours_per_day
            self.state.calendar.q_relative_calendar = self.params.cal_cyc.calendar_q0 * 100.0
        elif self.params.cal_cyc.calendar_choice == calendar_cycle_params.CALENDAR_CHOICE.TABLE:
            if self.params.cal_cyc.calendar_matrix.nrows() < 2 or self.params.cal_cyc.calendar_matrix.ncols() != 2:
                raise Error("lifetime_calendar_t error: Battery calendar lifetime matrix must have 2 columns and at least 2 rows")

class lifetime_calendar_cycle_t(lifetime_t):
    var calendar_model: lifetime_calendar_t
    var cycle_model: lifetime_cycle_t

    def __init__(self, batt_lifetime_matrix: util.matrix_t[Float64], dt_hour: Float64, calendar_matrix: util.matrix_t[Float64]):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.model_choice = lifetime_params.CALCYC
        self.params.dt_hr = dt_hour
        self.params.cal_cyc.cycling_matrix = batt_lifetime_matrix
        self.params.cal_cyc.calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.TABLE
        self.params.cal_cyc.calendar_matrix = calendar_matrix
        self.initialize()

    def __init__(self, batt_lifetime_matrix: util.matrix_t[Float64], dt_hour: Float64, q0: Float64, a: Float64, b: Float64, c: Float64):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.model_choice = lifetime_params.CALCYC
        self.params.dt_hr = dt_hour
        self.params.cal_cyc.cycling_matrix = batt_lifetime_matrix
        self.params.cal_cyc.calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.MODEL
        self.params.cal_cyc.calendar_q0 = q0
        self.params.cal_cyc.calendar_a = a
        self.params.cal_cyc.calendar_b = b
        self.params.cal_cyc.calendar_c = c
        self.initialize()

    def __init__(self, batt_lifetime_matrix: util.matrix_t[Float64], dt_hour: Float64):
        self.params = make_shared_ptr[lifetime_params]()
        self.params.model_choice = lifetime_params.CALCYC
        self.params.dt_hr = dt_hour
        self.params.cal_cyc.cycling_matrix = batt_lifetime_matrix
        self.params.cal_cyc.calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.NONE
        self.initialize()

    def __init__(self, params_ptr: shared_ptr[lifetime_params]):
        self.params = params_ptr
        self.initialize()

    def __init__(self, rhs: Self):
        lifetime_t.__init__(self, rhs)
        self.__copyinit__(rhs)

    def __copyinit__(self, rhs: Self):
        if self is not rhs:
            self.params[] = rhs.params[]
            self.state[] = rhs.state[]
            self.calendar_model = lifetime_calendar_t(self.params, self.state)
            self.cycle_model = lifetime_cycle_t(self.params, self.state)

    def clone(self) -> Self:
        return Self(self)

    def runLifetimeModels(self, lifetimeIndex: Int, charge_changed: Bool, prev_DOD: Float64, DOD: Float64, T_battery: Float64):
        var q_last: Float64 = self.state.q_relative
        if q_last > 0.0:
            var q_cycle: Float64 = self.cycle_model.capacity_percent()
            var q_calendar: Float64
            if charge_changed:
                q_cycle = self.cycle_model.runCycleLifetime(prev_DOD)
            elif lifetimeIndex == 0:
                q_cycle = self.cycle_model.runCycleLifetime(DOD)
            q_calendar = self.calendar_model.runLifetimeCalendarModel(lifetimeIndex, T_battery, 100.0 - DOD)
            self.state.q_relative = fmin(q_cycle, q_calendar)
        self.state.q_relative = fmax(self.state.q_relative, 0.0)
        self.state.q_relative = fmin(self.state.q_relative, q_last)

    def estimateCycleDamage(self) -> Float64:
        return self.cycle_model.estimateCycleDamage()

    def replaceBattery(self, percent_to_replace: Float64):
        self.cycle_model.replaceBattery(percent_to_replace)
        self.calendar_model.replaceBattery(percent_to_replace)
        self.state.q_relative = fmin(self.cycle_model.capacity_percent(), self.calendar_model.capacity_percent())

    def capacity_percent_cycle(self) -> Float64:
        return self.cycle_model.capacity_percent()

    def capacity_percent_calendar(self) -> Float64:
        return self.calendar_model.capacity_percent()

    def initialize(self):
        self.state = make_shared_ptr[lifetime_state]()
        if self.params.cal_cyc.cycling_matrix.nrows() < 3 or self.params.cal_cyc.cycling_matrix.ncols() != 3:
            raise Error("lifetime_cycle_t error: Battery lifetime matrix must have three columns and at least three rows")
        self.cycle_model = lifetime_cycle_t(self.params, self.state)
        self.cycle_model.initialize()
        self.calendar_model = lifetime_calendar_t(self.params, self.state)
        self.calendar_model.initialize()
        self.state.q_relative = fmin(self.state.cycle.q_relative_cycle, self.state.calendar.q_relative_calendar)