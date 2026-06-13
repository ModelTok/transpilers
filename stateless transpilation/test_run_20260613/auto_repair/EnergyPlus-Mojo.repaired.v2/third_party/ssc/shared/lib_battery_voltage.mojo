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
INCLUDING, BUT NOT LIMITED TO, THE WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from memory import pointer, address_of
from math import exp, log, pow, sqrt, fabs, fmax, fmin
from lib_util import util
from lib_battery_capacity import *
from 6par_newton import newton

struct voltage_params:
    enum MODE:
        MODEL = 0
        TABLE = 1
    var voltage_choice: MODE
    var num_cells_series: Int
    var num_strings: Int
    var Vnom_default: Float64
    var resistance: Float64
    var dt_hr: Float64
    var dynamic: DynamicStruct
    var voltage_table: List[List[Float64]]

    struct DynamicStruct:
        var Vfull: Float64
        var Vexp: Float64
        var Vnom: Float64
        var Qfull: Float64
        var Qexp: Float64
        var Qnom: Float64
        var C_rate: Float64

    def __init__(inout self):
        self.voltage_choice = MODE.MODEL
        self.num_cells_series = 0
        self.num_strings = 0
        self.Vnom_default = 0.0
        self.resistance = 0.0
        self.dt_hr = 0.0
        self.dynamic = DynamicStruct {Vfull: 0.0, Vexp: 0.0, Vnom: 0.0, Qfull: 0.0, Qexp: 0.0, Qnom: 0.0, C_rate: 0.0}
        self.voltage_table = List[List[Float64]]()

struct voltage_state:
    var cell_voltage: Float64

    def __init__(inout self):
        self.cell_voltage = 0.0

    def __eq__(self, other: Self) -> Bool:
        return self.cell_voltage == other.cell_voltage

trait voltage_t:
    def __init__(inout self, mode: Int, num_cells_series: Int, num_strings: Int, voltage: Float64, dt_hour: Float64)
    def __init__(inout self, p: Pointer[voltage_params])
    def __copyinit__(inout self, other: Self)
    def __moveinit__(inout self, owned other: Self)
    def __del__(owned self)
    def clone(self) -> Pointer[voltage_t]
    def set_initial_SOC(inout self, init_soc: Float64)
    def calculate_max_charge_w(self, q: Float64, qmax: Float64, kelvin: Float64, max_current: Pointer[Float64]) -> Float64
    def calculate_max_discharge_w(self, q: Float64, qmax: Float64, kelvin: Float64, max_current: Pointer[Float64]) -> Float64
    def calculate_current_for_target_w(self, P_watts: Float64, q: Float64, qmax: Float64, kelvin: Float64) -> Float64
    def calculate_voltage_for_current(self, I: Float64, q: Float64, qmax: Float64, T_k: Float64) -> Float64
    def updateVoltage(inout self, q: Float64, qmax: Float64, I: Float64, temp: Float64, dt: Float64)
    def battery_voltage(self) -> Float64
    def battery_voltage_nominal(self) -> Float64
    def cell_voltage(self) -> Float64
    def get_params(self) -> voltage_params
    def get_state(self) -> voltage_state

    # protected members
    var params: Pointer[voltage_params]
    var state: Pointer[voltage_state]

    def initialize(inout self):
        self.state = Pointer[voltage_state].alloc()
        self.state.cell_voltage = self.params.Vnom_default

    def __init__(inout self, mode: Int, num_cells_series: Int, num_strings: Int, voltage: Float64, dt_hour: Float64):
        self.params = Pointer[voltage_params].alloc()
        self.params.voltage_choice = voltage_params.MODE(mode)
        self.params.num_cells_series = num_cells_series
        self.params.num_strings = num_strings
        self.params.Vnom_default = voltage
        self.params.resistance = 0.004
        self.params.dt_hr = dt_hour
        self.initialize()

    def __init__(inout self, p: Pointer[voltage_params]):
        self.params = p
        self.initialize()

    def __copyinit__(inout self, other: Self):
        self.state = Pointer[voltage_state].alloc()
        self.state[] = other.state[]
        self.params = Pointer[voltage_params].alloc()
        self.params[] = other.params[]

    def __moveinit__(inout self, owned other: Self):
        self.state = other.state
        self.params = other.params

    def __del__(owned self):
        if self.state:
            self.state.free()
        if self.params:
            self.params.free()

    def battery_voltage(self) -> Float64:
        return self.params.num_cells_series * self.state.cell_voltage

    def battery_voltage_nominal(self) -> Float64:
        return self.params.num_cells_series * self.params.Vnom_default

    def cell_voltage(self) -> Float64:
        return self.state.cell_voltage

    def get_params(self) -> voltage_params:
        return self.params[]

    def get_state(self) -> voltage_state:
        return self.state[]

struct voltage_table_t(voltage_t):
    var slopes: List[Float64]
    var intercepts: List[Float64]

    def initialize(inout self):
        if len(self.params.voltage_table) == 0:
            raise Error("voltage_table_t error: empty voltage table")
        if len(self.params.voltage_table) < 2 or len(self.params.voltage_table[0]) != 2:
            raise Error("voltage_table_t error: Battery lifetime matrix must have 2 columns and at least 2 rows")
        # sort descending by voltage (index 1)
        var n = len(self.params.voltage_table)
        for i in range(n):
            for j in range(i+1, n):
                if self.params.voltage_table[i][1] < self.params.voltage_table[j][1]:
                    var tmp = self.params.voltage_table[i]
                    self.params.voltage_table[i] = self.params.voltage_table[j]
                    self.params.voltage_table[j] = tmp
        for i in range(n):
            var DOD = self.params.voltage_table[i][0]
            var V = self.params.voltage_table[i][1]
            var slope = 0.0
            var intercept = V
            if i > 0:
                var DOD0 = self.params.voltage_table[i-1][0]
                var V0 = self.params.voltage_table[i-1][1]
                slope = (V - V0) / (DOD - DOD0)
                intercept = V0 - (slope * DOD0)
            self.slopes.append(slope)
            self.intercepts.append(intercept)
        self.slopes.append(self.slopes[-1])
        self.intercepts.append(self.intercepts[-1])

    def __init__(inout self, num_cells_series: Int, num_strings: Int, voltage: Float64,
                voltage_table: util.matrix_t[Float64], R: Float64, dt_hour: Float64):
        voltage_t.__init__(self, voltage_params.MODE.TABLE.value, num_cells_series, num_strings, voltage, dt_hour)
        self.params.resistance = R
        for r in range(voltage_table.nrows()):
            self.params.voltage_table.append(List[Float64]([voltage_table.at(r, 0), voltage_table.at(r, 1)]))
        self.slopes = List[Float64]()
        self.intercepts = List[Float64]()
        self.initialize()

    def __init__(inout self, p: Pointer[voltage_params]):
        voltage_t.__init__(self, p)
        self.slopes = List[Float64]()
        self.intercepts = List[Float64]()
        self.initialize()

    def __copyinit__(inout self, other: Self):
        voltage_t.__copyinit__(self, other)
        self.slopes = other.slopes
        self.intercepts = other.intercepts

    def __moveinit__(inout self, owned other: Self):
        voltage_t.__moveinit__(self, other^)
        self.slopes = other.slopes
        self.intercepts = other.intercepts

    def clone(self) -> Pointer[voltage_t]:
        var ptr = Pointer[voltage_table_t].alloc()
        ptr[] = self
        return ptr

    def calculate_voltage(self, DOD: Float64) -> Float64:
        var DOD_ = fmax(0.0, DOD)
        DOD_ = fmin(DOD_, 100.0)
        var row: Int = 0
        while row < len(self.params.voltage_table) and DOD_ > self.params.voltage_table[row][0]:
            row += 1
        return fmax(self.slopes[row] * DOD_ + self.intercepts[row], 0.0)

    def set_initial_SOC(inout self, init_soc: Float64):
        self.state.cell_voltage = self.calculate_voltage(100.0 - init_soc)

    def calculate_voltage_for_current(self, I: Float64, q: Float64, qmax: Float64, _: Float64) -> Float64:
        var DOD = (q - I * self.params.dt_hr) / qmax * 100.0
        return self.calculate_voltage(DOD) * self.params.num_cells_series

    def updateVoltage(inout self, q: Float64, qmax: Float64, _: Float64, _: Float64, _: Float64):
        var DOD = 100.0 * (1.0 - q / qmax)
        self.state.cell_voltage = self.calculate_voltage(DOD)

    def calc_DOD(q: Float64, qmax: Float64) -> Float64:
        return (1.0 - q / qmax) * 100.0

    def calculate_max_charge_w(self, q: Float64, qmax: Float64, _: Float64, max_current: Pointer[Float64]) -> Float64:
        var current = (q - qmax) / self.params.dt_hr
        if max_current:
            max_current[] = current
        return self.calculate_voltage(0.0) * current * self.params.num_cells_series

    def calculate_max_discharge_w(self, q: Float64, qmax: Float64, _: Float64, max_current: Pointer[Float64]) -> Float64:
        var DOD0 = self.calc_DOD(q, qmax)
        var A = q - qmax
        var B = qmax / 100.0
        var max_P: Float64 = 0.0
        var max_I: Float64 = 0.0
        for i in range(len(self.slopes)):
            var dod = -(A * self.slopes[i] + B * self.intercepts[i]) / (2.0 * B * self.slopes[i])
            var current = qmax * ((1.0 - DOD0 / 100.0) - (1.0 - dod / 100.0)) / self.params.dt_hr
            var p = self.calculate_voltage(dod) * current
            if p > max_P:
                max_P = p
                max_I = current
        if max_current:
            max_current[] = fmax(0.0, max_I)
        return max_P * self.params.num_cells_series

    def calculate_current_for_target_w(self, P_watts: Float64, q: Float64, qmax: Float64, _: Float64) -> Float64:
        var DOD = self.calc_DOD(q, qmax)
        var max_p: Float64
        var current: Float64
        if P_watts == 0.0:
            return 0.0
        elif P_watts < 0.0:
            max_p = self.calculate_max_charge_w(q, qmax, 0.0, pointer_of(current))
        else:
            max_p = self.calculate_max_discharge_w(q, qmax, 0.0, pointer_of(current))
        if fabs(max_p) <= fabs(P_watts):
            return current
        var P_watts_ = P_watts / self.params.num_cells_series
        P_watts_ *= self.params.dt_hr
        var multiplier: Float64 = 1.0
        if P_watts_ < 0.0:
            multiplier = -1.0
        var row: Int = 0
        while row < len(self.params.voltage_table) and DOD > self.params.voltage_table[row][0]:
            row += 1
        var A = q - qmax
        var B = qmax / 100.0
        var DOD_new: Float64 = 0.0
        var incr: Float64 = 0.0
        var DOD_best: Float64 = 0.0 if multiplier == -1.0 else 100.0
        var P_best: Float64 = 0.0
        while (incr + row) < len(self.slopes) and (incr + row) >= 0:
            var i = row + Int(incr)
            incr += 1.0 * multiplier
            var a = B * self.slopes[i]
            var b = A * self.slopes[i] + B * self.intercepts[i]
            var c = A * self.intercepts[i] - P_watts_
            if a == 0.0:
                continue
            DOD_new = fabs((-b + sqrt(b * b - 4.0 * a * c)) / (2.0 * a))
            var upper = min(i, len(self.params.voltage_table) - 1)
            var lower = max(0, i - 1)
            var DOD_upper = self.params.voltage_table[upper][0]
            var DOD_lower = self.params.voltage_table[lower][0]
            if DOD_new <= DOD_upper and DOD_new >= DOD_lower:
                var P = (q - (100.0 - DOD_new) * qmax / 100.0) * (a * DOD_new + b)
                if fabs(P) > fabs(P_best):
                    P_best = P
                    DOD_best = DOD_new
        return qmax * ((1.0 - DOD / 100.0) - (1.0 - DOD_best / 100.0)) / self.params.dt_hr

struct voltage_dynamic_t(voltage_t):
    var _A: Float64
    var _B0: Float64
    var _E0: Float64
    var _K: Float64
    var solver_Q: Float64
    var solver_q: Float64
    var solver_cutoff_voltage: Float64
    var solver_power: Float64

    def initialize(inout self):
        if (self.params.dynamic.Vfull < self.params.dynamic.Vexp) or (self.params.dynamic.Vexp < self.params.dynamic.Vnom):
            raise Error("voltage_dynamic_t error: For the electrochemical battery voltage model, voltage inputs must meet the requirement Vfull > Vexp > Vnom.")
        self.state.cell_voltage = self.params.dynamic.Vfull
        self.parameter_compute()

    def __init__(inout self, num_cells_series: Int, num_strings: Int, voltage: Float64, Vfull: Float64,
                Vexp: Float64, Vnom: Float64, Qfull: Float64, Qexp: Float64, Qnom: Float64,
                C_rate: Float64, R: Float64, dt_hr: Float64):
        voltage_t.__init__(self, voltage_params.MODE.MODEL.value, num_cells_series, num_strings, voltage, dt_hr)
        self.params.dynamic.Vfull = Vfull
        self.params.dynamic.Vexp = Vexp
        self.params.dynamic.Vnom = Vnom
        self.params.dynamic.Qfull = Qfull
        self.params.dynamic.Qexp = Qexp
        self.params.dynamic.Qnom = Qnom
        self.params.dynamic.C_rate = C_rate
        self.params.resistance = R
        self._A = 0.0
        self._B0 = 0.0
        self._E0 = 0.0
        self._K = 0.0
        self.solver_Q = 0.0
        self.solver_q = 0.0
        self.solver_cutoff_voltage = 0.0
        self.solver_power = 0.0
        self.initialize()

    def __init__(inout self, p: Pointer[voltage_params]):
        voltage_t.__init__(self, p)
        self._A = 0.0
        self._B0 = 0.0
        self._E0 = 0.0
        self._K = 0.0
        self.solver_Q = 0.0
        self.solver_q = 0.0
        self.solver_cutoff_voltage = 0.0
        self.solver_power = 0.0
        self.initialize()

    def __copyinit__(inout self, other: Self):
        voltage_t.__copyinit__(self, other)
        self._A = other._A
        self._B0 = other._B0
        self._E0 = other._E0
        self._K = other._K
        self.solver_power = other.solver_power
        self.solver_Q = other.solver_Q
        self.solver_q = other.solver_q
        self.solver_cutoff_voltage = other.solver_cutoff_voltage

    def __moveinit__(inout self, owned other: Self):
        voltage_t.__moveinit__(self, other^)
        self._A = other._A
        self._B0 = other._B0
        self._E0 = other._E0
        self._K = other._K
        self.solver_power = other.solver_power
        self.solver_Q = other.solver_Q
        self.solver_q = other.solver_q
        self.solver_cutoff_voltage = other.solver_cutoff_voltage

    def clone(self) -> Pointer[voltage_t]:
        var ptr = Pointer[voltage_dynamic_t].alloc()
        ptr[] = self
        return ptr

    def parameter_compute(inout self):
        var I = self.params.dynamic.Qfull * self.params.dynamic.C_rate
        self._A = self.params.dynamic.Vfull - self.params.dynamic.Vexp
        self._B0 = 3.0 / self.params.dynamic.Qexp
        self._K = ((self.params.dynamic.Vfull - self.params.dynamic.Vnom + self._A * (exp(-self._B0 * self.params.dynamic.Qnom) - 1.0)) *
                   (self.params.dynamic.Qfull - self.params.dynamic.Qnom)) / (self.params.dynamic.Qnom)
        self._E0 = self.params.dynamic.Vfull + self._K + self.params.resistance * I - self._A
        if self._A < 0.0 or self._B0 < 0.0 or self._K < 0.0 or self._E0 < 0.0:
            var err = "Error during calculation of battery voltage model parameters: negative value(s) found.\n" +
                      "A: " + str(self._A) + ", B: " + str(self._B0) + ", K: " + str(self._K) + ", E0: " + str(self._E0)
            raise Error(err)

    def set_initial_SOC(inout self, init_soc: Float64):
        self.updateVoltage(init_soc * 0.01 * self.params.dynamic.Qfull * self.params.num_strings,
                           self.params.dynamic.Qfull * self.params.num_strings, 0.0, 25.0, self.params.dt_hr)

    def voltage_model_tremblay_hybrid(self, Q_cell: Float64, I: Float64, q0_cell: Float64) -> Float64:
        var it = Q_cell - q0_cell
        var E = self._E0 - self._K * (Q_cell / (Q_cell - it)) + self._A * exp(-self._B0 * it)
        return E - self.params.resistance * I

    def calculate_voltage_for_current(self, I: Float64, q: Float64, qmax: Float64, _: Float64) -> Float64:
        return self.params.num_cells_series * fmax(
            self.voltage_model_tremblay_hybrid(qmax / self.params.num_strings, I / self.params.num_strings,
                                               q / self.params.num_strings), 0.0)

    def updateVoltage(inout self, q: Float64, qmax: Float64, I: Float64, _: Float64, _: Float64):
        var qmax_ = qmax / self.params.num_strings
        var q_ = q / self.params.num_strings
        var I_ = I / self.params.num_strings
        self.state.cell_voltage = fmax(self.voltage_model_tremblay_hybrid(qmax_, I_, q_), 0.0)

    def calculate_max_charge_w(self, q: Float64, qmax: Float64, _: Float64, max_current: Pointer[Float64]) -> Float64:
        var q_ = q / self.params.num_strings
        var qmax_ = qmax / self.params.num_strings
        var current = (q_ - qmax_) / self.params.dt_hr
        if max_current:
            max_current[] = current * self.params.num_strings
        return current * self.voltage_model_tremblay_hybrid(qmax_, current, qmax_) * self.params.num_strings * self.params.num_cells_series

    def calculate_max_discharge_w(self, q: Float64, qmax: Float64, _: Float64, max_current: Pointer[Float64]) -> Float64:
        var q_ = q / self.params.num_strings
        var qmax_ = qmax / self.params.num_strings
        var current = q_ * 0.5
        var vol: Float64 = 0.0
        var incr = q_ / 10.0
        var max_p: Float64 = 0.0
        var max_I: Float64 = 0.0
        while current * self.params.dt_hr < q_ - 1e-6 and vol >= 0.0:
            vol = self.voltage_model_tremblay_hybrid(qmax_, current, q_ - current * self.params.dt_hr)
            var p = current * vol
            if p > max_p:
                max_p = p
                max_I = current
            current += incr
        current = max_I
        if max_current:
            max_current[] = current * self.params.num_strings
        return max_p * self.params.num_strings * self.params.num_cells_series

    def calculate_current_for_target_w(self, P_watts: Float64, q: Float64, qmax: Float64, _: Float64) -> Float64:
        if P_watts == 0.0:
            return 0.0
        self.solver_power = fabs(P_watts) / (self.params.num_cells_series * self.params.num_strings)
        self.solver_q = q / self.params.num_strings
        self.solver_Q = qmax / self.params.num_strings
        var direction: Float64 = 1.0
        var f: fn(Pointer[Float64], Pointer[Float64]) raises
        if P_watts > 0.0:
            f = self.solve_current_for_discharge_power
        else:
            f = self.solve_current_for_charge_power
            direction = -1.0
        var x = Pointer[Float64].alloc(1)
        var resid = Pointer[Float64].alloc(1)
        if self.state.cell_voltage != 0.0:
            x[0] = self.solver_power / self.state.cell_voltage * self.params.dt_hr
        else:
            x[0] = self.solver_power / self.params.dynamic.Vnom * self.params.dt_hr
        var check: Bool = False
        newton[Float64, fn(Pointer[Float64], Pointer[Float64]) raises, 1](x, resid, check, f, 100, 1e-6, 1e-6, 0.7)
        var result = x[0] * self.params.num_strings * direction
        x.free()
        resid.free()
        return result

    def solve_current_for_charge_power(self, x: Pointer[Float64], f: Pointer[Float64]):
        var I = x[0]
        var V = self._E0 - self._K * self.solver_Q / (self.solver_q + I * self.params.dt_hr) + \
                self._A * exp(-self._B0 * (self.solver_Q - (self.solver_q + I * self.params.dt_hr))) + self.params.resistance * I
        f[0] = I * V - self.solver_power

    def solve_current_for_discharge_power(self, x: Pointer[Float64], f: Pointer[Float64]):
        var I = x[0]
        var V = self._E0 - self._K * self.solver_Q / (self.solver_q - I * self.params.dt_hr) + \
                self._A * exp(-self._B0 * (self.solver_Q - (self.solver_q - I * self.params.dt_hr))) - self.params.resistance * I
        f[0] = I * V - self.solver_power

struct voltage_vanadium_redox_t(voltage_t):
    var m_RCF: Float64
    var solver_Q: Float64
    var solver_q: Float64
    var solver_T_k: Float64
    var solver_power: Float64

    def initialize(inout self):
        self.m_RCF = 8.314 * 1.38 / (26.801 * 3600)

    def __init__(inout self, num_cells_series: Int, num_strings: Int, Vnom_default: Float64,
                R: Float64, dt_hour: Float64):
        voltage_t.__init__(self, voltage_params.MODE.MODEL.value, num_cells_series, num_strings, Vnom_default, dt_hour)
        self.params.Vnom_default = Vnom_default
        self.params.resistance = R
        self.params.dt_hr = self.params.dt_hr
        self.m_RCF = 0.0
        self.solver_Q = 0.0
        self.solver_q = 0.0
        self.solver_T_k = 0.0
        self.solver_power = 0.0
        self.initialize()

    def __init__(inout self, p: Pointer[voltage_params]):
        voltage_t.__init__(self, p)
        self.m_RCF = 0.0
        self.solver_Q = 0.0
        self.solver_q = 0.0
        self.solver_T_k = 0.0
        self.solver_power = 0.0
        self.initialize()

    def __copyinit__(inout self, other: Self):
        voltage_t.__copyinit__(self, other)
        self.m_RCF = other.m_RCF
        self.solver_power = other.solver_power
        self.solver_T_k = other.solver_T_k
        self.solver_q = other.solver_q
        self.solver_Q = other.solver_Q

    def __moveinit__(inout self, owned other: Self):
        voltage_t.__moveinit__(self, other^)
        self.m_RCF = other.m_RCF
        self.solver_power = other.solver_power
        self.solver_T_k = other.solver_T_k
        self.solver_q = other.solver_q
        self.solver_Q = other.solver_Q

    def clone(self) -> Pointer[voltage_t]:
        var ptr = Pointer[voltage_vanadium_redox_t].alloc()
        ptr[] = self
        return ptr

    def set_initial_SOC(inout self, init_soc: Float64):
        self.updateVoltage(init_soc, 100.0, 0.0, 25.0, self.params.dt_hr)

    def calculate_voltage_for_current(self, I: Float64, q: Float64, qmax: Float64, T_k: Float64) -> Float64:
        return self.voltage_model(q / self.params.num_strings, qmax / self.params.num_strings,
                                  I / self.params.num_strings, T_k) * self.params.num_cells_series

    def updateVoltage(inout self, q: Float64, qmax: Float64, I: Float64, temp: Float64, _: Float64):
        self.state.cell_voltage = self.voltage_model(q / self.params.num_strings, qmax / self.params.num_strings,
                                                     I / self.params.num_strings, temp + 273.15)

    def calculate_max_charge_w(self, q: Float64, qmax: Float64, kelvin: Float64, max_current: Pointer[Float64]) -> Float64:
        var qmax_ = qmax / self.params.num_strings
        var q_ = q / self.params.num_strings
        var max_I = (q_ - qmax_) / self.params.dt_hr
        if max_current:
            max_current[] = max_I * self.params.num_strings
        return self.voltage_model(qmax_, qmax_, max_I, kelvin) * max_I * self.params.num_strings * self.params.num_cells_series

    def calculate_max_discharge_w(self, q: Float64, qmax: Float64, kelvin: Float64, max_current: Pointer[Float64]) -> Float64:
        self.solver_q = q / self.params.num_strings
        self.solver_Q = qmax / self.params.num_strings
        self.solver_T_k = kelvin
        var f: fn(Pointer[Float64], Pointer[Float64]) raises = self.solve_max_discharge_power
        var x = Pointer[Float64].alloc(1)
        var resid = Pointer[Float64].alloc(1)
        x[0] = (self.solver_q - 1e-6) / self.params.dt_hr
        var check: Bool = False
        newton[Float64, fn(Pointer[Float64], Pointer[Float64]) raises, 1](x, resid, check, f, 100, 1e-6, 1e-6, 0.7)
        var current = x[0]
        var power = current * self.voltage_model(self.solver_q - current * self.params.dt_hr, self.solver_Q, current, kelvin) *
                    self.params.num_strings * self.params.num_cells_series
        if power < 0.0:
            current = 0.0
            power = 0.0
        if max_current:
            max_current[] = current * self.params.num_strings
        x.free()
        resid.free()
        return power

    def calculate_current_for_target_w(self, P_watts: Float64, q: Float64, qmax: Float64, kelvin: Float64) -> Float64:
        if P_watts == 0.0:
            return 0.0
        self.solver_power = P_watts / (self.params.num_cells_series * self.params.num_strings)
        self.solver_q = q / self.params.num_strings
        self.solver_Q = qmax / self.params.num_strings
        self.solver_T_k = kelvin
        var f: fn(Pointer[Float64], Pointer[Float64]) raises = self.solve_current_for_power
        var x = Pointer[Float64].alloc(1)
        var resid = Pointer[Float64].alloc(1)
        if self.state.cell_voltage != 0.0:
            x[0] = self.solver_power / self.state.cell_voltage * self.params.dt_hr
        else:
            x[0] = self.solver_power / self.params.Vnom_default * self.params.dt_hr
        var check: Bool = False
        newton[Float64, fn(Pointer[Float64], Pointer[Float64]) raises, 1](x, resid, check, f, 100, 1e-6, 1e-6, 0.7)
        var result = x[0] * self.params.num_strings
        x.free()
        resid.free()
        return result

    def voltage_model(self, q0: Float64, qmax: Float64, I_string: Float64, T: Float64) -> Float64:
        var SOC_use = q0 / qmax
        if SOC_use > 1.0 - 1e-6:
            SOC_use = 1.0 - 1e-6
        elif SOC_use == 0.0:
            SOC_use = 1e-3
        var A = log(pow(SOC_use, 2.0) / pow(1.0 - SOC_use, 2.0))
        return self.params.Vnom_default + self.m_RCF * T * A + fabs(I_string) * self.params.resistance

    def solve_current_for_power(self, x: Pointer[Float64], f: Pointer[Float64]):
        var I = x[0]
        var SOC = (self.solver_q - I * self.params.dt_hr) / self.solver_Q
        f[0] = I * (self.params.Vnom_default + self.m_RCF * self.solver_T_k * log(SOC * SOC / pow(1.0 - SOC, 2.0)) +
                    fabs(I) * self.params.resistance) - self.solver_power

    def solve_max_discharge_power(self, x: Pointer[Float64], f: Pointer[Float64]):
        var I = fabs(x[0])
        var SOC = (self.solver_q - I * self.params.dt_hr) / self.solver_Q
        f[0] = self.params.Vnom_default + 2.0 * I * self.params.resistance + self.m_RCF * self.solver_T_k * \
               (log(SOC * SOC / pow(1.0 - SOC, 2.0)) - 2.0 * I * (1.0 / SOC - 1.0 / (1.0 - SOC)))