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
from math import exp, fabs, floor, isnan
from lib_util import util
from lib_battery_capacity import capacity_t, capacity_kibam_t, capacity_lithium_ion_t, capacity_state, capacity_params
from lib_battery_voltage import voltage_t, voltage_table_t, voltage_dynamic_t, voltage_vanadium_redox_t, voltage_state, voltage_params
from lib_battery_lifetime_calendar_cycle import lifetime_calendar_cycle_t
from lib_battery_lifetime_nmc import lifetime_nmc_t
from lib_battery_lifetime_calendar_cycle import lifetime_t, lifetime_state, lifetime_params

struct thermal_state:
    var q_relative_thermal: Float64   # [%]
    var T_batt: Float64               # C
    var T_room: Float64
    var heat_dissipated: Float64      # W
    var T_batt_prev: Float64

    def __init__(inout self):
        self.q_relative_thermal = 0.0
        self.T_batt = 0.0
        self.T_room = 0.0
        self.heat_dissipated = 0.0
        self.T_batt_prev = 0.0

struct thermal_params:
    var dt_hr: Float64
    var mass: Float64                 # [kg]
    var surface_area: Float64         # [m2] - exposed surface area
    var Cp: Float64                   # [J/KgK] - battery specific heat capacity
    var h: Float64                    # [W/m2/K] - general heat transfer coefficient
    var resistance: Float64                    # [Ohm] - internal resistance
    var en_cap_vs_temp: Bool       # if true, no capacity degradation from temp and do not use cap_vs_temp
    var cap_vs_temp: util.matrix_t[Float64]
    var option: Int
    var T_room_init: Float64                    # starting temperature C
    var T_room_schedule: List[Float64]   # can be year one hourly data or a single value constant throughout year

    def __init__(inout self):
        self.dt_hr = 0.0
        self.mass = 0.0
        self.surface_area = 0.0
        self.Cp = 0.0
        self.h = 0.0
        self.resistance = 0.0
        self.en_cap_vs_temp = False
        self.cap_vs_temp = util.matrix_t[Float64]()
        self.option = 0
        self.T_room_init = 0.0
        self.T_room_schedule = List[Float64]()

    def __copyinit__(inout self, other: Self):
        self.dt_hr = other.dt_hr
        self.mass = other.mass
        self.surface_area = other.surface_area
        self.Cp = other.Cp
        self.h = other.h
        self.resistance = other.resistance
        self.en_cap_vs_temp = other.en_cap_vs_temp
        self.cap_vs_temp = other.cap_vs_temp
        self.option = other.option
        self.T_room_init = other.T_room_init
        self.T_room_schedule = other.T_room_schedule

    def __del__(owned self):

@value
struct thermal_params_OPTIONS:
    var VALUE: Int = 0
    var SCHEDULE: Int = 1

class thermal_t:
    var params: Pointer[thermal_params]
    var state: Pointer[thermal_state]
    var dt_sec: Float64              # [sec] - timestep

    def __init__(inout self, dt_hour: Float64, mass: Float64, surface_area: Float64, R: Float64, Cp: Float64, h: Float64,
                 c_vs_t: util.matrix_t[Float64], T_room_C: List[Float64]):
        self.params = Pointer[thermal_params].alloc()
        self.params[] = thermal_params{dt_hr: dt_hour, mass: mass, surface_area: surface_area, Cp: Cp, h: h, resistance: R, en_cap_vs_temp: True, cap_vs_temp: c_vs_t, option: 0, T_room_init: 0.0, T_room_schedule: List[Float64]()}
        self.params[].option = thermal_params_OPTIONS.SCHEDULE
        self.params[].T_room_schedule = T_room_C
        self.initialize()
        self.state[].T_room = self.params[].T_room_schedule[0]

    def __init__(inout self, dt_hour: Float64, mass: Float64, surface_area: Float64, R: Float64, Cp: Float64, h: Float64,
                 c_vs_t: util.matrix_t[Float64], T_room_C: Float64):
        self.params = Pointer[thermal_params].alloc()
        self.params[] = thermal_params{dt_hr: dt_hour, mass: mass, surface_area: surface_area, Cp: Cp, h: h, resistance: R, en_cap_vs_temp: True, cap_vs_temp: c_vs_t, option: 0, T_room_init: 0.0, T_room_schedule: List[Float64]()}
        self.params[].option = thermal_params_OPTIONS.VALUE
        self.params[].T_room_init = T_room_C
        self.initialize()

    def __init__(inout self, dt_hour: Float64, mass: Float64, surface_area: Float64, R: Float64, Cp: Float64, h: Float64,
                 T_room_C: Float64):
        self.params = Pointer[thermal_params].alloc()
        self.params[] = thermal_params{dt_hr: dt_hour, mass: mass, surface_area: surface_area, Cp: Cp, h: h, resistance: R, en_cap_vs_temp: False, cap_vs_temp: util.matrix_t[Float64](), option: 0, T_room_init: 0.0, T_room_schedule: List[Float64]()}
        self.params[].option = thermal_params_OPTIONS.VALUE
        self.params[].T_room_init = T_room_C
        self.initialize()

    def __init__(inout self, dt_hour: Float64, mass: Float64, surface_area: Float64, R: Float64, Cp: Float64, h: Float64,
                 T_room_C: List[Float64]):
        self.params = Pointer[thermal_params].alloc()
        self.params[] = thermal_params{dt_hr: dt_hour, mass: mass, surface_area: surface_area, Cp: Cp, h: h, resistance: R, en_cap_vs_temp: False, cap_vs_temp: util.matrix_t[Float64](), option: 0, T_room_init: 0.0, T_room_schedule: List[Float64]()}
        self.params[].option = thermal_params_OPTIONS.SCHEDULE
        self.params[].T_room_schedule = T_room_C
        self.initialize()
        self.state[].T_room = self.params[].T_room_schedule[0]

    def __init__(inout self, p: Pointer[thermal_params]):
        self.params = p
        self.initialize()

    def __copyinit__(inout self, other: Self):
        self.params = Pointer[thermal_params].alloc()
        self.params[] = other.params[]
        self.state = Pointer[thermal_state].alloc()
        self.state[] = other.state[]
        self.dt_sec = other.dt_sec

    def __del__(owned self):
        if self.params:
            self.params.free()
        if self.state:
            self.state.free()

    def __moveassign__(inout self, owned other: Self):
        self.params = other.params
        self.state = other.state
        self.dt_sec = other.dt_sec

    def clone(inout self) -> Self:
        return Self(self)

    def replace_battery(inout self, lifetimeIndex: Int):
        if self.params[].option == thermal_params_OPTIONS.VALUE:
            self.state[].T_batt = self.params[].T_room_schedule[lifetimeIndex % len(self.params[].T_room_schedule)]
        else:
            self.state[].T_batt = self.state[].T_room
        self.state[].heat_dissipated = 0
        self.state[].T_batt_prev = self.state[].T_room
        self.state[].q_relative_thermal = 100.0

    def calc_capacity(inout self):
        var percent: Float64 = 100
        if self.params[].en_cap_vs_temp:
            percent = util.linterp_col(self.params[].cap_vs_temp, 0, self.state[].T_batt, 1)
        if isnan(percent) or percent < 0 or percent > 100:
            percent = 100
        self.state[].q_relative_thermal = percent

    def updateTemperature(inout self, I: Float64, lifetimeIndex: Int):
        if self.params[].option == thermal_params_OPTIONS.SCHEDULE:
            self.state[].T_room = self.params[].T_room_schedule[lifetimeIndex % len(self.params[].T_room_schedule)]
        var T_steady_state: Float64 = I * I * self.params[].resistance / (self.params[].surface_area * self.params[].h) + self.state[].T_room
        var diffusion: Float64 = exp(-self.params[].surface_area * self.params[].h * self.dt_sec / self.params[].mass / self.params[].Cp)
        var coeff_avg: Float64 = self.params[].mass * self.params[].Cp / self.params[].surface_area / self.params[].h / self.dt_sec
        self.state[].T_batt = (self.state[].T_batt_prev - T_steady_state) * coeff_avg * (1 - diffusion) + T_steady_state
        self.state[].heat_dissipated = (self.state[].T_batt - self.state[].T_room) * self.params[].surface_area * self.params[].h / 1000.0
        self.state[].T_batt_prev = (self.state[].T_batt_prev - T_steady_state) * diffusion + T_steady_state
        self.calc_capacity()

    def capacity_percent(inout self) -> Float64:
        return self.state[].q_relative_thermal

    def T_battery(inout self) -> Float64:
        return self.state[].T_batt

    def get_state(inout self) -> thermal_state:
        return self.state[]

    def get_params(inout self) -> thermal_params:
        return self.params[]

    def initialize(inout self):
        if self.params[].en_cap_vs_temp and (self.params[].cap_vs_temp.nrows() < 2 or self.params[].cap_vs_temp.ncols() != 2):
            raise Error("thermal_t: capacity vs temperature matrix must have two columns and at least two rows")
        if self.params[].en_cap_vs_temp:
            var n: Int = self.params[].cap_vs_temp.nrows()
            for i in range(n):
                self.params[].cap_vs_temp(i, 0)
        self.state = Pointer[thermal_state].alloc()
        self.state[] = thermal_state()
        if self.params[].option == thermal_params_OPTIONS.SCHEDULE:
            self.state[].T_room = self.params[].T_room_schedule[0]
        else:
            self.state[].T_room = self.params[].T_room_init
        self.state[].T_batt = self.state[].T_room
        self.state[].T_batt_prev = self.state[].T_room
        self.state[].heat_dissipated = 0
        self.state[].q_relative_thermal = 100
        self.dt_sec = self.params[].dt_hr * 3600

struct losses_state:
    var loss_kw: Float64

    def __init__(inout self):
        self.loss_kw = 0.0

struct losses_params:
    var loss_choice: Int
    var monthly_charge_loss: List[Float64]
    var monthly_discharge_loss: List[Float64]
    var monthly_idle_loss: List[Float64]
    var schedule_loss: List[Float64]

    def __init__(inout self):
        self.loss_choice = 0
        self.monthly_charge_loss = List[Float64]()
        self.monthly_discharge_loss = List[Float64]()
        self.monthly_idle_loss = List[Float64]()
        self.schedule_loss = List[Float64]()

    def __copyinit__(inout self, other: Self):
        self.loss_choice = other.loss_choice
        self.monthly_charge_loss = other.monthly_charge_loss
        self.monthly_discharge_loss = other.monthly_discharge_loss
        self.monthly_idle_loss = other.monthly_idle_loss
        self.schedule_loss = other.schedule_loss

    def __del__(owned self):

@value
struct losses_params_OPTIONS:
    var MONTHLY: Int = 0
    var SCHEDULE: Int = 1

class losses_t:
    var state: Pointer[losses_state]
    var params: Pointer[losses_params]

    def __init__(inout self, monthly_charge: List[Float64], monthly_discharge: List[Float64], monthly_idle: List[Float64]):
        self.params = Pointer[losses_params].alloc()
        self.params[] = losses_params()
        self.params[].loss_choice = losses_params_OPTIONS.MONTHLY
        self.params[].monthly_charge_loss = monthly_charge
        self.params[].monthly_discharge_loss = monthly_discharge
        self.params[].monthly_idle_loss = monthly_idle
        self.initialize()

    def __init__(inout self, schedule_loss: List[Float64] = List[Float64](1, 0)):
        self.params = Pointer[losses_params].alloc()
        self.params[] = losses_params()
        self.params[].loss_choice = losses_params_OPTIONS.SCHEDULE
        self.params[].schedule_loss = schedule_loss
        self.initialize()

    def __init__(inout self, p: Pointer[losses_params]):
        self.params = p
        self.initialize()

    def __copyinit__(inout self, other: Self):
        self.params = Pointer[losses_params].alloc()
        self.params[] = other.params[]
        self.state = Pointer[losses_state].alloc()
        self.state[] = other.state[]

    def __del__(owned self):
        if self.params:
            self.params.free()
        if self.state:
            self.state.free()

    def __moveassign__(inout self, owned other: Self):
        self.params = other.params
        self.state = other.state

    def run_losses(inout self, lifetimeIndex: Int, dtHour: Float64, charge_operation: Float64):
        var indexYearOne: Int = util.yearOneIndex(dtHour, lifetimeIndex)
        var hourOfYear: Int = Int(floor(Float64(indexYearOne) * dtHour))
        var monthIndex: Int = util.month_of(Float64(hourOfYear)) - 1
        if self.params[].loss_choice == losses_params_OPTIONS.MONTHLY:
            if charge_operation == capacity_state.CHARGE:
                self.state[].loss_kw = self.params[].monthly_charge_loss[monthIndex]
            if charge_operation == capacity_state.DISCHARGE:
                self.state[].loss_kw = self.params[].monthly_discharge_loss[monthIndex]
            if charge_operation == capacity_state.NO_CHARGE:
                self.state[].loss_kw = self.params[].monthly_idle_loss[monthIndex]
        elif self.params[].loss_choice == losses_params_OPTIONS.SCHEDULE:
            self.state[].loss_kw = self.params[].schedule_loss[lifetimeIndex % len(self.params[].schedule_loss)]

    def getLoss(inout self) -> Float64:
        return self.state[].loss_kw

    def get_state(inout self) -> losses_state:
        return self.state[]

    def get_params(inout self) -> losses_params:
        return self.params[]

    def initialize(inout self):
        self.state = Pointer[losses_state].alloc()
        self.state[] = losses_state()
        self.state[].loss_kw = 0
        if self.params[].loss_choice == losses_params_OPTIONS.MONTHLY:
            if len(self.params[].monthly_charge_loss) == 1:
                self.params[].monthly_charge_loss = List[Float64](12, self.params[].monthly_charge_loss[0])
            elif len(self.params[].monthly_charge_loss) != 12:
                raise Error("losses_t error: loss arrays length must be 1 or 12 for monthly input mode")
            if len(self.params[].monthly_discharge_loss) == 1:
                self.params[].monthly_discharge_loss = List[Float64](12, self.params[].monthly_discharge_loss[0])
            elif len(self.params[].monthly_discharge_loss) != 12:
                raise Error("losses_t error: loss arrays length must be 1 or 12 for monthly input mode")
            if len(self.params[].monthly_idle_loss) == 1:
                self.params[].monthly_idle_loss = List[Float64](12, self.params[].monthly_idle_loss[0])
            elif len(self.params[].monthly_idle_loss) != 12:
                raise Error("losses_t error: loss arrays length must be 1 or 12 for monthly input mode")
        else:
            if len(self.params[].schedule_loss) == 0:
                raise Error("losses_t error: loss length must be greater than 0 for schedule mode")

struct replacement_state:
    var n_replacements: Int                                 # number of replacements this year
    var indices_replaced: List[Int]               # lifetime indices at which replacements occurred

    def __init__(inout self):
        self.n_replacements = 0
        self.indices_replaced = List[Int]()

struct replacement_params:
    var replacement_option: Int
    var replacement_capacity: Float64
    var replacement_schedule_percent: List[Float64]    # (0 - 100%)

    def __init__(inout self):
        self.replacement_option = 0
        self.replacement_capacity = 0.0
        self.replacement_schedule_percent = List[Float64]()

    def __copyinit__(inout self, other: Self):
        self.replacement_option = other.replacement_option
        self.replacement_capacity = other.replacement_capacity
        self.replacement_schedule_percent = other.replacement_schedule_percent

    def __del__(owned self):

@value
struct replacement_params_OPTIONS:
    var NONE: Int = 0
    var CAPACITY_PERCENT: Int = 1
    var SCHEDULE: Int = 2

struct battery_state:
    var last_idx: Int
    var V: Float64
    var Q: Float64
    var Q_max: Float64
    var I: Float64
    var I_dischargeable: Float64
    var I_chargeable: Float64
    var P: Float64
    var P_dischargeable: Float64
    var P_chargeable: Float64
    var capacity: Pointer[capacity_state]
    var voltage: Pointer[voltage_state]
    var thermal: Pointer[thermal_state]
    var lifetime: Pointer[lifetime_state]
    var losses: Pointer[losses_state]
    var replacement: Pointer[replacement_state]

    def __init__(inout self):
        self.last_idx = 0
        self.V = 0.0
        self.Q = 0.0
        self.Q_max = 0.0
        self.I = 0.0
        self.I_dischargeable = 0.0
        self.I_chargeable = 0.0
        self.P = 0.0
        self.P_dischargeable = 0.0
        self.P_chargeable = 0.0
        self.capacity = Pointer[capacity_state].alloc()
        self.capacity[] = capacity_state()
        self.voltage = Pointer[voltage_state].alloc()
        self.voltage[] = voltage_state()
        self.thermal = Pointer[thermal_state].alloc()
        self.thermal[] = thermal_state()
        self.lifetime = Pointer[lifetime_state].alloc()
        self.lifetime[] = lifetime_state()
        self.losses = Pointer[losses_state].alloc()
        self.losses[] = losses_state()
        self.replacement = Pointer[replacement_state].alloc()
        self.replacement[] = replacement_state()

    def __init__(inout self, cap: Pointer[capacity_state], vol: Pointer[voltage_state],
                 therm: Pointer[thermal_state], life: Pointer[lifetime_state],
                 loss: Pointer[losses_state]):
        self.last_idx = 0
        self.V = 0.0
        self.P = 0.0
        self.Q = 0.0
        self.Q_max = 0.0
        self.I = 0.0
        self.I_dischargeable = 0.0
        self.I_chargeable = 0.0
        self.P_dischargeable = 0.0
        self.P_chargeable = 0.0
        self.capacity = cap
        self.voltage = vol
        self.thermal = therm
        self.lifetime = life
        self.losses = loss
        self.replacement = Pointer[replacement_state].alloc()
        self.replacement[] = replacement_state()

    def __copyinit__(inout self, other: Self):
        self.last_idx = other.last_idx
        self.V = other.V
        self.P = other.P
        self.Q = other.Q
        self.Q_max = other.Q_max
        self.I = other.I
        self.I_dischargeable = other.I_dischargeable
        self.I_chargeable = other.I_chargeable
        self.P_dischargeable = other.P_dischargeable
        self.P_chargeable = other.P_chargeable
        self.capacity = Pointer[capacity_state].alloc()
        self.capacity[] = other.capacity[]
        self.voltage = Pointer[voltage_state].alloc()
        self.voltage[] = other.voltage[]
        self.thermal = Pointer[thermal_state].alloc()
        self.thermal[] = other.thermal[]
        self.lifetime = Pointer[lifetime_state].alloc()
        self.lifetime[] = other.lifetime[]
        self.losses = Pointer[losses_state].alloc()
        self.losses[] = other.losses[]
        self.replacement = Pointer[replacement_state].alloc()
        self.replacement[] = other.replacement[]

    def __del__(owned self):
        if self.capacity:
            self.capacity.free()
        if self.voltage:
            self.voltage.free()
        if self.thermal:
            self.thermal.free()
        if self.lifetime:
            self.lifetime.free()
        if self.losses:
            self.losses.free()
        if self.replacement:
            self.replacement.free()

    def __moveassign__(inout self, owned other: Self):
        self.last_idx = other.last_idx
        self.V = other.V
        self.P = other.P
        self.Q = other.Q
        self.Q_max = other.Q_max
        self.I = other.I
        self.I_dischargeable = other.I_dischargeable
        self.I_chargeable = other.I_chargeable
        self.P_dischargeable = other.P_dischargeable
        self.P_chargeable = other.P_chargeable
        self.capacity = other.capacity
        self.voltage = other.voltage
        self.thermal = other.thermal
        self.lifetime = other.lifetime
        self.losses = other.losses
        self.replacement = other.replacement

struct battery_params:
    var chem: Int
    var dt_hr: Float64
    var nominal_energy: Float64
    var nominal_voltage: Float64
    var capacity: Pointer[capacity_params]
    var voltage: Pointer[voltage_params]
    var thermal: Pointer[thermal_params]
    var lifetime: Pointer[lifetime_params]
    var losses: Pointer[losses_params]
    var replacement: Pointer[replacement_params]

    def __init__(inout self):
        self.chem = -1
        self.dt_hr = 0.0
        self.nominal_energy = 0.0
        self.nominal_voltage = 0.0
        self.capacity = Pointer[capacity_params].alloc()
        self.capacity[] = capacity_params()
        self.voltage = Pointer[voltage_params].alloc()
        self.voltage[] = voltage_params()
        self.thermal = Pointer[thermal_params].alloc()
        self.thermal[] = thermal_params()
        self.lifetime = Pointer[lifetime_params].alloc()
        self.lifetime[] = lifetime_params()
        self.losses = Pointer[losses_params].alloc()
        self.losses[] = losses_params()
        self.replacement = Pointer[replacement_params].alloc()
        self.replacement[] = replacement_params()

    def __init__(inout self, cap: Pointer[capacity_params], vol: Pointer[voltage_params],
                 therm: Pointer[thermal_params], life: Pointer[lifetime_params],
                 loss: Pointer[losses_params]):
        self.chem = -1
        self.dt_hr = 0.0
        self.nominal_energy = 0.0
        self.nominal_voltage = 0.0
        self.capacity = cap
        self.voltage = vol
        self.thermal = therm
        self.lifetime = life
        self.losses = loss
        self.replacement = Pointer[replacement_params].alloc()
        self.replacement[] = replacement_params()

    def __copyinit__(inout self, other: Self):
        self.chem = other.chem
        self.dt_hr = other.dt_hr
        self.nominal_voltage = other.nominal_voltage
        self.nominal_energy = other.nominal_energy
        self.capacity = Pointer[capacity_params].alloc()
        self.capacity[] = other.capacity[]
        self.voltage = Pointer[voltage_params].alloc()
        self.voltage[] = other.voltage[]
        self.thermal = Pointer[thermal_params].alloc()
        self.thermal[] = other.thermal[]
        self.lifetime = Pointer[lifetime_params].alloc()
        self.lifetime[] = other.lifetime[]
        self.losses = Pointer[losses_params].alloc()
        self.losses[] = other.losses[]
        self.replacement = Pointer[replacement_params].alloc()
        self.replacement[] = other.replacement[]

    def __del__(owned self):
        if self.capacity:
            self.capacity.free()
        if self.voltage:
            self.voltage.free()
        if self.thermal:
            self.thermal.free()
        if self.lifetime:
            self.lifetime.free()
        if self.losses:
            self.losses.free()
        if self.replacement:
            self.replacement.free()

    def __moveassign__(inout self, owned other: Self):
        self.chem = other.chem
        self.dt_hr = other.dt_hr
        self.nominal_voltage = other.nominal_voltage
        self.nominal_energy = other.nominal_energy
        self.capacity = other.capacity
        self.voltage = other.voltage
        self.thermal = other.thermal
        self.lifetime = other.lifetime
        self.losses = other.losses
        self.replacement = other.replacement

@value
struct battery_params_CHEM:
    var LEAD_ACID: Int = 0
    var LITHIUM_ION: Int = 1
    var VANADIUM_REDOX: Int = 2
    var IRON_FLOW: Int = 3

class battery_t:
    var capacity: Pointer[capacity_t]
    var thermal: Pointer[thermal_t]
    var lifetime: Pointer[lifetime_t]
    var voltage: Pointer[voltage_t]
    var losses: Pointer[losses_t]
    var state: Pointer[battery_state]
    var params: Pointer[battery_params]

    def __init__(inout self, dt_hr: Float64, chem: Int,
                capacity_model: Pointer[capacity_t],
                voltage_model: Pointer[voltage_t],
                lifetime_model: Pointer[lifetime_t],
                thermal_model: Pointer[thermal_t],
                losses_model: Pointer[losses_t]):
        self.capacity = capacity_model
        self.voltage = voltage_model
        self.lifetime = lifetime_model
        self.thermal = thermal_model
        if losses_model.is_null():
            self.losses = Pointer[losses_t].alloc()
            self.losses[] = losses_t()
        else:
            self.losses = losses_model
        self.state = Pointer[battery_state].alloc()
        self.state[] = battery_state(self.capacity[].state, self.voltage[].state, self.thermal[].state, self.lifetime[].state, self.losses[].state)
        self.params = Pointer[battery_params].alloc()
        self.params[] = battery_params(self.capacity[].params, self.voltage[].params, self.thermal[].params, self.lifetime[].params, self.losses[].params)
        self.params[].dt_hr = dt_hr
        self.params[].chem = chem
        self.params[].nominal_voltage = self.params[].voltage[].Vnom_default * self.params[].voltage[].num_cells_series
        self.params[].nominal_energy = self.params[].nominal_voltage * self.params[].voltage[].num_strings * self.params[].voltage[].dynamic.Qfull * 1e-3
        self.voltage[].set_initial_SOC(self.capacity[].state[].SOC)

    def __init__(inout self, p: Pointer[battery_params]):
        self.params = p
        self.initialize()

    def __copyinit__(inout self, other: Self):
        self.params = Pointer[battery_params].alloc()
        self.params[] = other.params[]
        self.initialize()
        self.state[] = other.state[]

    def __del__(owned self):
        if self.capacity:
            self.capacity.free()
        if self.thermal:
            self.thermal.free()
        if self.lifetime:
            self.lifetime.free()
        if self.voltage:
            self.voltage.free()
        if self.losses:
            self.losses.free()
        if self.state:
            self.state.free()
        if self.params:
            self.params.free()

    def __moveassign__(inout self, owned other: Self):
        self.capacity = other.capacity
        self.thermal = other.thermal
        self.lifetime = other.lifetime
        self.voltage = other.voltage
        self.losses = other.losses
        self.state = other.state
        self.params = other.params

    def setupReplacements(inout self, capacity_percent: Float64):
        self.params[].replacement = Pointer[replacement_params].alloc()
        self.params[].replacement[] = replacement_params()
        self.params[].replacement[].replacement_option = replacement_params_OPTIONS.CAPACITY_PERCENT
        self.params[].replacement[].replacement_capacity = capacity_percent

    def setupReplacements(inout self, replacement_percents: List[Float64]):
        self.params[].replacement = Pointer[replacement_params].alloc()
        self.params[].replacement[] = replacement_params()
        self.params[].replacement[].replacement_option = replacement_params_OPTIONS.SCHEDULE
        self.params[].replacement[].replacement_schedule_percent = replacement_percents

    def runReplacement(inout self, year: Int, hour: Int, step: Int):
        if year == 0 and hour == 0:
            return
        if self.params[].replacement[].replacement_option == replacement_params_OPTIONS.NONE:
            return
        var replace: Bool = False
        var percent: Float64 = 0
        if self.params[].replacement[].replacement_option == replacement_params_OPTIONS.SCHEDULE:
            if year < len(self.params[].replacement[].replacement_schedule_percent):
                percent = self.params[].replacement[].replacement_schedule_percent[year]
                if percent > 0 and hour == 0 and step == 0:
                    replace = True
        elif self.params[].replacement[].replacement_option == replacement_params_OPTIONS.CAPACITY_PERCENT:
            if (self.lifetime[].capacity_percent() - tolerance) <= self.params[].replacement[].replacement_capacity:
                replace = True
                percent = 100.0
        if replace:
            self.state[].replacement[].n_replacements += 1
            self.state[].replacement[].indices_replaced.append(util.lifetimeIndex(year, hour, step, Int(1 / self.params[].dt_hr)))
            self.lifetime[].replaceBattery(percent)
            self.capacity[].replace_battery(percent)
            self.thermal[].replace_battery(year)

    def resetReplacement(inout self):
        self.state[].replacement[].n_replacements = 0

    def getNumReplacementYear(inout self) -> Float64:
        return Float64(self.state[].replacement[].n_replacements)

    def getReplacementPercent(inout self) -> Float64:
        if self.params[].replacement[].replacement_option == replacement_params_OPTIONS.CAPACITY_PERCENT:
            return (self.params[].replacement[].replacement_capacity / 100.0)
        return 0.0

    def ChangeTimestep(inout self, dt_hr: Float64):
        if dt_hr <= 0:
            raise Error("battery_t timestep must be greater than 0 hour")
        if dt_hr > 1:
            raise Error("battery_t timestep must be less than or equal to 1 hour")
        var old_hr: Float64 = Float64(self.state[].last_idx) * self.params[].dt_hr
        self.state[].last_idx = Int(old_hr / dt_hr)
        self.params[].dt_hr = dt_hr
        self.params[].capacity[].dt_hr = dt_hr
        self.params[].voltage[].dt_hr = dt_hr
        self.params[].thermal[].dt_hr = dt_hr
        self.thermal[].dt_sec = dt_hr * 3600
        self.params[].lifetime[].dt_hr = dt_hr

    def run(inout self, lifetimeIndex: Int, I: Float64) -> Float64:
        var I_initial: Float64 = I
        var iterate_count: Int = 0
        var capacity_initial: capacity_state = self.capacity[].get_state()
        var thermal_initial: thermal_state = self.thermal[].get_state()
        while iterate_count < 5:
            self.runThermalModel(I, lifetimeIndex)
            self.runCapacityModel(I)
            var numerator: Float64 = fabs(I - I_initial)
            if (numerator > 0.0) and (numerator / fabs(I_initial) > tolerance):
                self.thermal[].state[] = thermal_initial
                self.capacity[].state[] = capacity_initial
                I_initial = I
                iterate_count += 1
            else:
                break
        self.runVoltageModel()
        self.runLifetimeModel(lifetimeIndex)
        self.runLossesModel(lifetimeIndex)
        self.update_state(I)
        return self.state[].P

    def runCurrent(inout self, I: Float64):
        self.state[].last_idx += 1
        self.run(self.state[].last_idx, I)

    def runPower(inout self, P: Float64):
        var I: Float64 = self.calculate_current_for_power_kw(P)
        self.state[].last_idx += 1
        self.run(self.state[].last_idx, I)

    def runThermalModel(inout self, I: Float64, lifetimeIndex: Int):
        self.thermal[].updateTemperature(I, lifetimeIndex)

    def estimateCycleDamage(inout self) -> Float64:
        return self.lifetime[].estimateCycleDamage()

    def runCapacityModel(inout self, I: Float64):
        if fabs(I) > tolerance:
            self.capacity[].updateCapacityForThermal(self.thermal[].capacity_percent())
        self.capacity[].updateCapacity(I, self.params[].dt_hr)

    def runVoltageModel(inout self):
        self.voltage[].updateVoltage(self.capacity[].q0(), self.capacity[].qmax(), self.capacity[].I(), self.thermal[].T_battery(), self.params[].dt_hr)

    def runLifetimeModel(inout self, lifetimeIndex: Int):
        self.lifetime[].runLifetimeModels(lifetimeIndex,
                                self.capacity[].chargeChanged(), 100.0 - self.capacity[].SOC_prev(), 100.0 - self.capacity[].SOC(),
                                self.thermal[].T_battery())
        self.capacity[].updateCapacityForLifetime(self.lifetime[].capacity_percent())

    def runLossesModel(inout self, idx: Int):
        if idx > self.state[].last_idx or idx == 0:
            self.losses[].run_losses(idx, self.params[].dt_hr, self.capacity[].charge_operation())
            self.state[].last_idx = idx

    def changeSOCLimits(inout self, min: Float64, max: Float64):
        self.capacity[].change_SOC_limits(min, max)

    def charge_needed(inout self, SOC_max: Float64) -> Float64:
        var charge_needed: Float64 = self.capacity[].qmax_thermal() * SOC_max * 0.01 - self.capacity[].q0()
        if charge_needed > 0:
            return charge_needed
        else:
            return 0.0

    def charge_total(inout self) -> Float64:
        return self.capacity[].q0()

    def charge_maximum(inout self) -> Float64:
        return min(self.capacity[].qmax(), self.capacity[].qmax_thermal())

    def charge_maximum_lifetime(inout self) -> Float64:
        return self.capacity[].qmax()

    def charge_maximum_thermal(inout self) -> Float64:
        return self.capacity[].qmax_thermal()

    def energy_nominal(inout self) -> Float64:
        return self.V_nominal() * self.capacity[].qmax() * util.watt_to_kilowatt

    def energy_max(inout self, SOC_max: Float64, SOC_min: Float64) -> Float64:
        return self.V() * self.charge_maximum_lifetime() * (SOC_max - SOC_min) * 0.01 * util.watt_to_kilowatt

    def energy_available(inout self, SOC_min: Float64) -> Float64:
        return self.V() * self.charge_maximum_lifetime() * (self.SOC() - SOC_min) * 0.01 * util.watt_to_kilowatt

    def energy_to_fill(inout self, SOC_max: Float64) -> Float64:
        var battery_voltage: Float64 = self.V_nominal() # [V]
        var charge_needed_to_fill: Float64 = self.charge_needed(SOC_max) # [Ah] - qmax - q0
        return (charge_needed_to_fill * battery_voltage) * util.watt_to_kilowatt  # [kWh]

    def power_to_fill(inout self, SOC_max: Float64) -> Float64:
        return (self.energy_to_fill(SOC_max) / self.params[].dt_hr)

    def V(inout self) -> Float64:
        return self.voltage[].battery_voltage()

    def V_nominal(inout self) -> Float64:
        return self.voltage[].battery_voltage_nominal()

    def SOC(inout self) -> Float64:
        return self.capacity[].SOC()

    def I(inout self) -> Float64:
        return self.capacity[].I()

    def calculate_voltage_for_current(inout self, I: Float64) -> Float64:
        var qmax: Float64 = min(self.capacity[].qmax(), self.capacity[].qmax_thermal())
        return self.voltage[].calculate_voltage_for_current(I, self.charge_total(), qmax, self.thermal[].T_battery())

    def calculate_max_charge_kw(inout self, max_current_A: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        var thermal_initial: thermal_state = self.thermal[].get_state()
        var q: Float64 = self.capacity[].q0()
        var SOC_ratio: Float64 = self.capacity[].params[].maximum_SOC * 0.01
        var qmax: Float64 = self.charge_maximum() * SOC_ratio
        var power_W: Float64 = 0
        var current: Float64 = 0
        var its: Int = 0
        while fabs(power_W - self.voltage[].calculate_max_charge_w(q, qmax, self.thermal[].T_battery(), &current)) > tolerance and its < 10:
            power_W = self.voltage[].calculate_max_charge_w(q, qmax, self.thermal[].T_battery(), &current)
            self.thermal[].updateTemperature(current, self.state[].last_idx + 1)
            qmax = self.capacity[].qmax() * self.thermal[].capacity_percent() * 0.01 * SOC_ratio
            its += 1
        if not max_current_A.is_null():
            max_current_A[] = current
        self.thermal[].state[] = thermal_initial
        return power_W / 1000.0

    def calculate_max_discharge_kw(inout self, max_current_A: Pointer[Float64] = Pointer[Float64]()) -> Float64:
        var thermal_initial: thermal_state = self.thermal[].get_state()
        var q: Float64 = self.capacity[].q0()
        var SOC_ratio: Float64 = (1.0 - self.capacity[].params[].minimum_SOC * 0.01)
        var qmax: Float64 = self.charge_maximum() * SOC_ratio
        var power_W: Float64 = 0
        var current: Float64 = 0
        var its: Int = 0
        while fabs(power_W - self.voltage[].calculate_max_discharge_w(q, qmax, self.thermal[].T_battery(), &current)) > tolerance and its < 5:
            power_W = self.voltage[].calculate_max_discharge_w(q, qmax, self.thermal[].T_battery(), &current)
            self.thermal[].updateTemperature(current, self.state[].last_idx + 1)
            qmax = self.capacity[].qmax() * self.thermal[].capacity_percent() * 0.01 * SOC_ratio
            its += 1
        if not max_current_A.is_null():
            max_current_A[] = current
        self.thermal[].state[] = thermal_initial
        return power_W / 1000.0

    def calculate_current_for_power_kw(inout self, P_kw: Float64) -> Float64:
        if P_kw == 0.0:
            return 0.0
        var current: Float64
        if P_kw < 0:
            var max_P: Float64 = self.calculate_max_charge_kw(&current)
            if max_P > P_kw:
                P_kw = max_P
                return current
        else:
            var max_P: Float64 = self.calculate_max_discharge_kw(&current)
            if max_P < P_kw:
                P_kw = max_P
                return current
        return self.voltage[].calculate_current_for_target_w(P_kw * 1000.0, self.capacity[].q0(),
                                                   min(self.capacity[].qmax(), self.capacity[].qmax_thermal()),
                                                   self.thermal[].T_battery())

    def calculate_loss(inout self, power: Float64, lifetimeIndex: Int) -> Float64:
        var indexYearOne: Int = util.yearOneIndex(self.params[].dt_hr, lifetimeIndex)
        var hourOfYear: Int = Int(floor(Float64(indexYearOne) * self.params[].dt_hr))
        var monthIndex: Int = Int(util.month_of(Float64(hourOfYear))) - 1
        if self.params[].losses[].loss_choice == losses_params_OPTIONS.MONTHLY:
            if power > 0:
                return self.params[].losses[].monthly_discharge_loss[monthIndex]
            elif power < 0:
                return self.params[].losses[].monthly_charge_loss[monthIndex]
            else:
                return self.params[].losses[].monthly_idle_loss[monthIndex]
        else:
            return self.params[].losses[].schedule_loss[lifetimeIndex % len(self.params[].losses[].schedule_loss)]

    def getLoss(inout self) -> Float64:
        return self.losses[].getLoss()

    def get_state(inout self) -> battery_state:
        return self.state[]

    def get_params(inout self) -> battery_params:
        return self.params[]

    def set_state(inout self, tmp_state: battery_state, dt_hr: Float64 = 0.0):
        self.state[] = tmp_state
        if dt_hr > 0 and dt_hr <= 1:
            self.params[].dt_hr = dt_hr

    def initialize(inout self):
        if self.params[].chem == battery_params_CHEM.LEAD_ACID:
            self.capacity = Pointer[capacity_t].alloc()
            self.capacity[] = capacity_kibam_t(self.params[].capacity)
        else:
            self.capacity = Pointer[capacity_t].alloc()
            self.capacity[] = capacity_lithium_ion_t(self.params[].capacity)
        if self.params[].voltage[].voltage_choice == voltage_params.TABLE or self.params[].chem == battery_params_CHEM.IRON_FLOW:
            self.voltage = Pointer[voltage_t].alloc()
            self.voltage[] = voltage_table_t(self.params[].voltage)
        elif self.params[].chem == battery_params_CHEM.LEAD_ACID or self.params[].chem == battery_params_CHEM.LITHIUM_ION:
            self.voltage = Pointer[voltage_t].alloc()
            self.voltage[] = voltage_dynamic_t(self.params[].voltage)
        elif self.params[].chem == battery_params_CHEM.VANADIUM_REDOX:
            self.voltage = Pointer[voltage_t].alloc()
            self.voltage[] = voltage_vanadium_redox_t(self.params[].voltage)
        self.voltage[].set_initial_SOC(self.capacity[].state[].SOC)
        if self.params[].lifetime[].model_choice == lifetime_params.CALCYC:
            self.lifetime = Pointer[lifetime_t].alloc()
            self.lifetime[] = lifetime_calendar_cycle_t(self.params[].lifetime)
        else:
            self.lifetime = Pointer[lifetime_t].alloc()
            self.lifetime[] = lifetime_nmc_t(self.params[].lifetime)
        self.thermal = Pointer[thermal_t].alloc()
        self.thermal[] = thermal_t(self.params[].thermal)
        self.losses = Pointer[losses_t].alloc()
        self.losses[] = losses_t(self.params[].losses)
        self.state = Pointer[battery_state].alloc()
        self.state[] = battery_state(self.capacity[].state, self.voltage[].state, self.thermal[].state, self.lifetime[].state, self.losses[].state)

    def update_state(inout self, I: Float64):
        self.state[].I = I
        self.state[].Q = self.capacity[].q0()
        self.state[].Q_max = self.capacity[].qmax()
        self.state[].V = self.voltage[].battery_voltage()
        self.state[].P_dischargeable = self.calculate_max_discharge_kw(&self.state[].I_dischargeable)
        self.state[].P_chargeable = self.calculate_max_charge_kw(&self.state[].I_chargeable)
        self.state[].P = I * self.voltage[].battery_voltage() * util.watt_to_kilowatt

var tolerance: Float64 = 1e-7