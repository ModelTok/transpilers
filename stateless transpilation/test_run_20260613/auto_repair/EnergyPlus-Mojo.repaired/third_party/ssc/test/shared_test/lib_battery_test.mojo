# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from math import *
from logger import *
from lib_battery import *
from lib_battery_capacity_test import *
from lib_battery_lifetime_test import *
from lib_battery_lifetime_nmc import *

def expect_near(actual: Float64, expected: Float64, tol: Float64, msg: String):
    if abs(actual - expected) > tol:
        print("FAIL: ", msg, " (actual=", actual, " expected=", expected, ")")
        assert(abs(actual - expected) <= tol)

def compareState(tested_state: thermal_state, expected_state: thermal_state, msg: String):
    var tol: Float64 = 0.02
    expect_near(tested_state.T_batt, expected_state.T_batt, tol, msg)
    expect_near(tested_state.T_room, expected_state.T_room, tol, msg)
    expect_near(tested_state.q_relative_thermal, expected_state.q_relative_thermal, tol, msg)
    expect_near(tested_state.heat_dissipated, expected_state.heat_dissipated, 1e-3, msg)

def compareState(tested_state_ref: &thermal_state, expected_state_ref: &thermal_state, msg: String):
    compareState(*tested_state_ref, *expected_state_ref, msg)

struct lib_battery_thermal_test:
    var model: Pointer[thermal_t]
    var tol: Float64
    var error: Float64
    var mass: Float64
    var surface_area: Float64
    var batt_R: Float64
    var Cp: Float64
    var h: Float64
    var T_room: List[Float64]
    var capacityVsTemperature: matrix_t[Float64]
    var dt_hour: Float64
    var nyears: Int

    def __init__(inout self):
        self.tol = 0.01
        self.error = 0.0
        self.mass = 507.0
        self.surface_area = 0.58 * 0.58 * 6.0
        self.batt_R = 0.0002
        self.Cp = 1004.0
        self.h = 20.0
        self.T_room = List[Float64](16.85, 16.85, 21.85, 21.85, 16.85, -3.15, -3.15)
        self.capacityVsTemperature = matrix_t[Float64]()
        self.dt_hour = 1.0
        self.nyears = 1

    def SetUp(inout self):
        var vals3: StaticFloat64Array[8] = (-10.0, 60.0, 0.0, 80.0, 25.0, 100.0, 40.0, 100.0)
        self.capacityVsTemperature.assign(vals3, 4, 2)

    def CreateModel(inout self, Cp: Float64):
        self.model = Pointer[thermal_t](owner=new thermal_t(self.dt_hour, self.mass, self.surface_area, self.batt_R, Cp, self.h, self.capacityVsTemperature, self.T_room))

    def CreateModelSixSecondStep(inout self, Cp: Float64):
        self.dt_hour = 1.0 / 600.0
        self.model = Pointer[thermal_t](owner=new thermal_t(self.dt_hour, self.mass, self.surface_area, self.batt_R, Cp, self.h, self.capacityVsTemperature, self.T_room))

    def __del__(inout self):
        if self.model:
            _ = self.model.take()

struct lib_battery_losses_test:
    var model: Pointer[losses_t]
    var tol: Float64
    var error: Float64
    var chargingLosses: List[Float64]
    var dischargingLosses: List[Float64]
    var fullLosses: List[Float64]
    var dt_hour: Float64
    var nyears: Int

    def __init__(inout self):
        self.tol = 0.01
        self.error = 0.0
        self.chargingLosses = List[Float64]()
        self.dischargingLosses = List[Float64]()
        self.fullLosses = List[Float64]()
        self.dt_hour = 1.0
        self.nyears = 1

    def SetUp(inout self):
        for m in range(12):
            self.chargingLosses.append(Float64(m))
            self.dischargingLosses.append(Float64(m) + 1.0)
        for i in range(8760):
            self.fullLosses.append(Float64(i) / 8760.0)

struct battery_state_test:
    var capacity: capacity_state
    var batt_voltage: Float64
    var lifetime: lifetime_state
    var thermal: thermal_state
    var last_idx: Int

def compareState(model: &battery_t, expected_state: battery_state_test, msg: String):
    var tested_state = model.get_state()
    compareState(*tested_state.capacity, expected_state.capacity, msg)
    expect_near(tested_state.V, expected_state.batt_voltage, 0.01, msg)
    var tol: Float64 = 0.01
    var lifetime_tested = tested_state.lifetime
    var lifetime_expected = expected_state.lifetime
    expect_near(lifetime_tested.day_age_of_battery, lifetime_expected.day_age_of_battery, tol, msg)
    expect_near(lifetime_tested.range, lifetime_expected.range, tol, msg)
    expect_near(lifetime_tested.average_range, lifetime_expected.average_range, tol, msg)
    expect_near(lifetime_tested.n_cycles, lifetime_expected.n_cycles, tol, msg)
    var cal_expected = *lifetime_expected.calendar
    expect_near(lifetime_tested.calendar.q_relative_calendar, cal_expected.q_relative_calendar, tol, msg)
    expect_near(lifetime_tested.calendar.dq_relative_calendar_old, cal_expected.dq_relative_calendar_old, tol, msg)
    var cyc_expected = *lifetime_expected.cycle
    expect_near(lifetime_tested.cycle.q_relative_cycle, cyc_expected.q_relative_cycle, tol, msg)
    expect_near(lifetime_tested.cycle.rainflow_Xlt, cyc_expected.rainflow_Xlt, tol, msg)
    expect_near(lifetime_tested.cycle.rainflow_Ylt, cyc_expected.rainflow_Ylt, tol, msg)
    expect_near(lifetime_tested.cycle.rainflow_jlt, cyc_expected.rainflow_jlt, tol, msg)
    compareState(*tested_state.thermal, expected_state.thermal, msg)

struct lib_battery_test:
    var q: Float64
    var SOC_min: Float64
    var SOC_max: Float64
    var SOC_init: Float64
    var n_series: Int
    var n_strings: Int
    var Vnom_default: Float64
    var Vfull: Float64
    var Vexp: Float64
    var Vnom: Float64
    var Qfull: Float64
    var Qexp: Float64
    var Qnom: Float64
    var C_rate: Float64
    var resistance: Float64
    var cycleLifeMatrix: matrix_t[Float64]
    var calendarLifeMatrix: matrix_t[Float64]
    var calendarChoice: Int
    var replacementOption: Int
    var replacementCapacity: Float64
    var mass: Float64
    var surface_area: Float64
    var Cp: Float64
    var h: Float64
    var T_room: List[Float64]
    var capacityVsTemperature: matrix_t[Float64]
    var monthlyLosses: List[Float64]
    var fullLosses: List[Float64]
    var fullLossesMinute: List[Float64]
    var lossChoice: Int
    var chemistry: Int
    var dtHour: Float64
    var tol: Float64
    var capacityModel: Pointer[capacity_lithium_ion_t]
    var voltageModel: Pointer[voltage_t]
    var thermalModel: Pointer[thermal_t]
    var lifetimeModel: Pointer[lifetime_t]
    var lossModel: Pointer[losses_t]
    var batteryModel: Pointer[battery_t]

    def __init__(inout self):
        self.q = 1000.0
        self.SOC_init = 50.0
        self.SOC_min = 5.0
        self.SOC_max = 95.0
        self.n_series = 139
        self.n_strings = 9
        self.Vnom_default = 3.6
        self.Vfull = 4.1
        self.Vexp = 4.05
        self.Vnom = 3.4
        self.Qfull = 2.25
        self.Qexp = 0.04
        self.Qnom = 2.0
        self.C_rate = 0.2
        self.resistance = 0.0002
        self.cycleLifeMatrix = matrix_t[Float64]()
        self.calendarLifeMatrix = matrix_t[Float64]()
        self.calendarChoice = 1
        self.replacementOption = 0
        self.replacementCapacity = 0.0
        self.mass = 507.0
        self.surface_area = 0.58 * 0.58 * 6.0
        self.Cp = 1004.0
        self.h = 20.0
        self.T_room = List[Float64]()
        self.capacityVsTemperature = matrix_t[Float64]()
        self.monthlyLosses = List[Float64]()
        self.fullLosses = List[Float64]()
        self.fullLossesMinute = List[Float64]()
        self.lossChoice = 0
        self.chemistry = 1
        self.dtHour = 1.0
        self.tol = 0.02
        self.capacityModel = Pointer[capacity_lithium_ion_t]()
        self.voltageModel = Pointer[voltage_t]()
        self.thermalModel = Pointer[thermal_t]()
        self.lifetimeModel = Pointer[lifetime_t]()
        self.lossModel = Pointer[losses_t]()
        self.batteryModel = Pointer[battery_t]()

    def SetUp(inout self):
        self.T_room.emplace_back(20.0)
        var vals: StaticFloat64Array[18] = (20.0, 0.0, 100.0, 20.0, 5000.0, 80.0, 20.0, 10000.0, 60.0, 80.0, 0.0, 100.0, 80.0, 1000.0, 80.0, 80.0, 2000.0, 60.0)
        self.cycleLifeMatrix.assign(vals, 6, 3)
        var vals2: StaticFloat64Array[6] = (0.0, 100.0, 3650.0, 80.0, 7300.0, 50.0)
        self.calendarLifeMatrix.assign(vals2, 3, 2)
        var vals3: StaticFloat64Array[8] = (-10.0, 60.0, 0.0, 80.0, 25.0, 100.0, 40.0, 100.0)
        self.capacityVsTemperature.assign(vals3, 4, 2)
        for m in range(12):
            self.monthlyLosses.append(Float64(m))
        for i in range(8760):
            self.fullLosses.append(0.0)
        for i in range(8760 * 60):
            self.fullLossesMinute.append(0.0)
        self.capacityModel = Pointer[capacity_lithium_ion_t](owner=new capacity_lithium_ion_t(self.q, self.SOC_init, self.SOC_max, self.SOC_min, self.dtHour))
        self.voltageModel = Pointer[voltage_t](owner=new voltage_dynamic_t(self.n_series, self.n_strings, self.Vnom_default, self.Vfull, self.Vexp, self.Vnom, self.Qfull, self.Qexp, self.Qnom, self.C_rate, self.resistance, self.dtHour))
        self.lifetimeModel = Pointer[lifetime_t](owner=new lifetime_calendar_cycle_t(self.cycleLifeMatrix, self.dtHour, 1.02, 2.66e-3, -7280.0, 930.0))
        self.thermalModel = Pointer[thermal_t](owner=new thermal_t(self.dtHour, self.mass, self.surface_area, self.resistance, self.Cp, self.h, self.capacityVsTemperature, self.T_room))
        self.lossModel = Pointer[losses_t](owner=new losses_t(self.monthlyLosses, self.monthlyLosses, self.monthlyLosses))
        self.batteryModel = Pointer[battery_t](owner=new battery_t(self.dtHour, self.chemistry, self.capacityModel.value, self.voltageModel.value, self.lifetimeModel.value, self.thermalModel.value, self.lossModel.value))

    def TearDown(inout self):
        # cleanup handled by __del__ of pointers

def lib_battery_thermal_test_SetUpTest():
    var fixture = lib_battery_thermal_test()
    fixture.SetUp()
    fixture.CreateModel(fixture.Cp)
    expect_near(fixture.model.value.T_battery(), 16.85, fixture.tol, "SetUpTest")
    expect_near(fixture.model.value.capacity_percent(), 100.0, fixture.tol, "SetUpTest")

def lib_battery_thermal_test_updateTemperatureTest():
    var fixture = lib_battery_thermal_test()
    fixture.SetUp()
    fixture.CreateModel(fixture.Cp)
    var I: Float64 = 50.0
    var idx: Int = 0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    var s = thermal_state(93.49, 16.86, 16.85)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 1")
    I = -50.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(93.49, 16.87, 16.85, 0.00017)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 2")
    I = 50.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(94.02, 17.51, 21.85, -0.17533)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 3")
    I = 10.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(94.88, 18.58, 21.85, -0.13172)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 4")
    I = 10.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(95.00, 18.76, 16.85, 0.07658)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 5")
    I = 10.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(92.55, 15.69, -3.15, 0.75990)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 6")
    I = 100.0
    fixture.model.value.updateTemperature(I, idx)
    idx += 1
    s = thermal_state(88.80, 11.01, -3.15, 0.5714)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 7")

def lib_battery_thermal_test_updateTemperatureTestSubMinute():
    var fixture = lib_battery_thermal_test()
    fixture.SetUp()
    fixture.CreateModelSixSecondStep(fixture.Cp)
    var I: Float64 = 50.0
    var idx: Int = 0
    var avgTemp: Float64 = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 16.86, 0.02, "updateTemperatureTest: 1")
    var s = thermal_state(93.49, 16.86, 16.85)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 1")
    I = -50.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 16.87, 0.02, "updateTemperatureTest: 2")
    s = thermal_state(93.49, 16.87, 16.85)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 2")
    I = 50.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 17.51, 0.02, "updateTemperatureTest: 3")
    s = thermal_state(94.47, 18.09, 21.85, -0.1514)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 3")
    I = 10.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 18.59, 0.02, "updateTemperatureTest: 4")
    s = thermal_state(95.22, 19.03, 21.85, -0.1138)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 4")
    I = 10.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 18.74, 0.02, "updateTemperatureTest: 5")
    s = thermal_state(94.79, 18.49, 16.85, 0.06618)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 5")
    I = 10.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 15.69, 0.02, "updateTemperatureTest: 6")
    s = thermal_state(90.49, 13.12, -3.15, 0.6567)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 6")
    I = 100.0
    idx += 1
    avgTemp = 0.0
    for j in range(600):
        fixture.model.value.updateTemperature(I, idx)
        avgTemp += fixture.model.value.get_state().T_batt
    avgTemp /= 600.0
    expect_near(avgTemp, 11.01, 0.02, "updateTemperatureTest: 7")
    s = thermal_state(87.27, 9.09, -3.15, 0.4941)
    compareState(fixture.model.value.get_state(), s, "updateTemperatureTest: 7")

def lib_battery_losses_test_MonthlyLossesTest():
    var fixture = lib_battery_losses_test()
    fixture.SetUp()
    fixture.model = Pointer[losses_t](owner=new losses_t(fixture.chargingLosses, fixture.dischargingLosses, fixture.chargingLosses))
    var charge_mode: Int = capacity_state.CHARGE
    var idx: Int = 0
    var dt_hr: Float64 = 1.0
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 0.0, fixture.tol, "MonthlyLossesTest: 1")
    idx = 40 * 24
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 1.0, fixture.tol, "MonthlyLossesTest: 2")
    idx = 70 * 24
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 2.0, fixture.tol, "MonthlyLossesTest: 3")
    charge_mode = capacity_state.DISCHARGE
    idx = 0
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 1.0, fixture.tol, "MonthlyLossesTest: 4")
    idx = 40 * 24
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 2.0, fixture.tol, "MonthlyLossesTest: 5")
    idx = 70 * 24
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 3.0, fixture.tol, "MonthlyLossesTest: 6")

def lib_battery_losses_test_TimeSeriesLossesTest():
    var fixture = lib_battery_losses_test()
    fixture.SetUp()
    fixture.model = Pointer[losses_t](owner=new losses_t(fixture.fullLosses))
    var charge_mode: Int = -1
    var dt_hr: Float64 = 1.0
    var idx: Int = 0
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 0.0, fixture.tol, "TimeSeriesLossesTest: 1")
    idx = 40
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 40.0 / 8760.0, fixture.tol, "TimeSeriesLossesTest: 2")
    idx = 70
    fixture.model.value.run_losses(idx, fixture.dt_hour, charge_mode)
    expect_near(fixture.model.value.getLoss(), 70.0 / 8760.0, fixture.tol, "TimeSeriesLossesTest: 3")

def lib_battery_test_SetUpTest():
    var fixture = lib_battery_test()
    fixture.SetUp()
    # ASSERT_TRUE(1) --> just pass

def lib_battery_test_runTestCycleAt1C():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var idx: Int = 0
    var capacity_passed: Float64 = 0.0
    var I: Float64 = fixture.Qfull * Float64(fixture.n_strings)
    fixture.batteryModel.value.run(idx, I)
    idx += 1
    capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    var s = battery_state_test()
    s.capacity = capacity_state(479.75, 1000.0, 960.01, 20.25, 0.0, 49.97, 52.09, 2)
    s.batt_voltage = 550.65
    s.lifetime.calendar.q_relative_calendar = 102.0
    s.lifetime.cycle.q_relative_cycle = 100.0
    s.lifetime.cycle.rainflow_jlt = 1
    s.lifetime.q_relative = 100.0
    s.thermal = thermal_state(96.00, 20.00, 20.0)
    compareState(fixture.batteryModel.value, s, "runTestCycleAt1C: 1")
    # Note: loop condition uses fixture.batteryModel.value.SOC() but SOC() returns Float64, ensure correct
    while fixture.batteryModel.value.SOC() > fixture.SOC_min + 1.0:
        fixture.batteryModel.value.run(idx, I)
        idx += 1
        capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    s.capacity = capacity_state(54.5, 1000.0, 960.01, 20.25, 0.0, 5.67, 7.79, 2)
    s.batt_voltage = 366.96
    s.lifetime.day_age_of_battery = 0.875
    s.lifetime.q_relative = 100.0
    s.lifetime.cycle.q_relative_cycle = 100.0
    s.lifetime.calendar.q_relative_calendar = 101.976
    s.lifetime.calendar.dq_relative_calendar_old = 0.0002
    s.thermal = thermal_state(96.01, 20.01, 20.0)
    compareState(fixture.batteryModel.value, s, "runTestCycleAt1C: 2")
    var n_cycles: Int = 400
    while n_cycles > 0:
        n_cycles -= 1
        I *= -1.0
        while fixture.batteryModel.value.SOC() < fixture.SOC_max - 1.0:
            fixture.batteryModel.value.run(idx, I)
            idx += 1
            capacity_passed += -fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
        I *= -1.0
        while fixture.batteryModel.value.SOC() > fixture.SOC_min + 1.0:
            fixture.batteryModel.value.run(idx, I)
            idx += 1
            capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    s.capacity = capacity_state(50.33, 920.36, 883.54, 8.941, 0.0, 5.70, 6.71, 2)
    s.batt_voltage = 367.69
    s.lifetime.q_relative = 93.08
    s.lifetime.cycle.q_relative_cycle = 92.04
    s.lifetime.n_cycles = 399
    s.lifetime.range = 89.04
    s.lifetime.average_range = 88.85
    s.lifetime.cycle.rainflow_Xlt = 89.06
    s.lifetime.cycle.rainflow_Ylt = 89.30
    s.lifetime.cycle.rainflow_jlt = 3
    s.lifetime.day_age_of_battery = 2739.96
    s.lifetime.calendar.q_relative_calendar = 98.0
    s.lifetime.calendar.dq_relative_calendar_old = 0.039
    s.thermal = thermal_state(96.0, 20.00, 20.0)
    s.last_idx = 32991
    compareState(fixture.batteryModel.value, s, "runTestCycleAt1C: 3")
    expect_near(capacity_passed, 352736.0, 1000.0, "Current passing through cell")
    var qmax: Float64 = max(s.capacity.qmax_lifetime, s.capacity.qmax_thermal)
    expect_near(qmax / fixture.q, 0.93, 0.01, "capacity relative to max capacity")

def lib_battery_test_runTestCycleAt3C():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var idx: Int = 0
    var capacity_passed: Float64 = 0.0
    var I: Float64 = fixture.Qfull * Float64(fixture.n_strings) * 3.0
    fixture.batteryModel.value.run(idx, I)
    idx += 1
    capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    var s = battery_state_test()
    s.capacity = capacity_state(439.25, 1000.0, 960.02, 60.75, 0.0, 45.75, 52.08, 2)
    s.batt_voltage = 548.35
    s.lifetime.q_relative = 100.0
    s.lifetime.cycle.q_relative_cycle = 100.0
    s.lifetime.cycle.rainflow_jlt = 1
    s.lifetime.calendar.q_relative_calendar = 102.0
    s.thermal = thermal_state(96.01, 20.01, 20.0)
    s.last_idx = 0
    compareState(fixture.batteryModel.value, s, "runTest: 1")
    while fixture.batteryModel.value.SOC() > fixture.SOC_min + 1.0:
        fixture.batteryModel.value.run(idx, I)
        idx += 1
        capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    s.capacity = capacity_state(48.01, 1000.0, 960.11, 26.74, 0.0, 5.00, 7.78, 2)
    s.batt_voltage = 338.91
    s.lifetime.day_age_of_battery = 0.29
    s.lifetime.q_relative = 101.98
    s.lifetime.calendar.q_relative_calendar = 101.98
    s.last_idx = 0
    compareState(fixture.batteryModel.value, s, "runTest: 2")
    var n_cycles: Int = 400
    while n_cycles > 0:
        n_cycles -= 1
        I *= -1.0
        while fixture.batteryModel.value.SOC() < fixture.SOC_max - 1.0:
            fixture.batteryModel.value.run(idx, I)
            idx += 1
            capacity_passed += -fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
        I *= -1.0
        while fixture.batteryModel.value.SOC() > fixture.SOC_min + 1.0:
            fixture.batteryModel.value.run(idx, I)
            idx += 1
            capacity_passed += fixture.batteryModel.value.I() * fixture.batteryModel.value.V() / 1000.0
    s.capacity = capacity_state(52.06, 920.37, 883.56, 8.94, 0.0, 5.89, 6.90, 2)
    s.batt_voltage = 374.55
    s.lifetime.q_relative = 93.08
    s.lifetime.day_age_of_battery = 2644.0
    s.lifetime.cycle.q_relative_cycle = 92.08
    s.lifetime.n_cycles = 399
    s.lifetime.range = 89.07
    s.lifetime.average_range = 89.00
    s.lifetime.cycle.rainflow_Xlt = 89.09
    s.lifetime.cycle.rainflow_Ylt = 89.11
    s.lifetime.cycle.rainflow_jlt = 3
    s.lifetime.cycle.q_relative_cycle = 92.04
    s.lifetime.calendar.q_relative_calendar = 98.08
    s.lifetime.calendar.dq_relative_calendar_old = 0.0393
    s.thermal = thermal_state(96.01, 20.0, 20.0)
    s.last_idx = 32991
    compareState(fixture.batteryModel.value, s, "runTest: 3")
    expect_near(capacity_passed, 352794.0, 100.0, "Current passing through cell")
    var qmax: Float64 = max(s.capacity.qmax_lifetime, s.capacity.qmax_thermal)
    expect_near(qmax / fixture.q, 0.9209, 0.01, "capacity relative to max capacity")

def lib_battery_test_runDuplicates():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var state = fixture.batteryModel.value.get_state()
    var cap_state = state.capacity
    var volt_state = state.voltage
    var Battery = battery_t(*fixture.batteryModel.value)
    var I: Float64 = 10.0
    Battery.run(0, I)
    var state2 = fixture.batteryModel.value.get_state()
    var cap_state2 = state2.capacity
    var volt_state2 = state2.voltage
    var state3 = Battery.get_state()
    var cap_state3 = state3.capacity
    var volt_state3 = state3.voltage
    # EXPECT_FALSE(*cap_state3 == *cap_state2)
    assert(not (*cap_state3 == *cap_state2))
    # EXPECT_NE(volt_state3->cell_voltage, volt_state2->cell_voltage);
    assert(volt_state3.cell_voltage != volt_state2.cell_voltage)

def lib_battery_test_createFromParams():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var params = battery_params(fixture.batteryModel.value.get_params())
    var bat = battery_t(params)
    var current: Float64 = 10.0
    var P_orig: Float64 = fixture.batteryModel.value.run(0, current)
    var P_new: Float64 = bat.run(0, current)
    # EXPECT_EQ(P_orig, P_new);
    assert(P_orig == P_new)
    # EXPECT_EQ(batteryModel->I(), bat.I());
    assert(fixture.batteryModel.value.I() == bat.I())
    # EXPECT_EQ(batteryModel->charge_maximum(), bat.charge_maximum());
    assert(fixture.batteryModel.value.charge_maximum() == bat.charge_maximum())

def lib_battery_test_logging():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var log = logger(stdout)
    var state = fixture.batteryModel.value.get_state()
    var params_ = fixture.batteryModel.value.get_params()
    log << *state.capacity << "\n"
    log << *params_.capacity << "\n\n"
    log << *state.voltage << "\n"
    log << *params_.voltage << "\n\n"
    log << *state.lifetime << "\n"
    log << *params_.lifetime << "\n\n"
    log << *state.thermal << "\n"
    log << *params_.thermal << "\n\n"
    log << *state.losses << "\n"
    log << *params_.losses << "\n\n"
    log << *state.replacement << "\n"
    log << *params_.replacement << "\n\n"
    log << state << "\n"
    log << params_ << "\n"

def lib_battery_test_RoundtripEffModel():
    var fixture = lib_battery_test()
    fixture.SetUp()
    fixture.batteryModel.value.changeSOCLimits(0.0, 100.0)
    var full_current: Float64 = 1000.0
    var max_current: Float64 = 0.0
    fixture.batteryModel.value.calculate_max_charge_kw(Pointer[Float64](address_of(max_current)))
    var eff_vs_current: List[Float64] = List[Float64]()
    var current: Float64 = fabs(max_current) * 0.01
    while current < fabs(max_current):
        fixture.capacityModel.value.updateCapacity(full_current, 1)   # discharge to empty
        var n_t: Int = 0
        current *= -1.0
        var input_power: Float64 = 0.0
        while fixture.capacityModel.value.SOC() < 100.0:
            var input_current: Float64 = current
            fixture.capacityModel.value.updateCapacity(input_current, 1)
            fixture.voltageModel.value.updateVoltage(fixture.capacityModel.value.q0(), fixture.capacityModel.value.qmax(), fixture.capacityModel.value.I(), 0, 1)
            input_power += fixture.capacityModel.value.I() * fixture.voltageModel.value.battery_voltage()
            n_t += 1
        current *= -1.0
        var output_power: Float64 = 0.0
        while fixture.voltageModel.value.calculate_max_discharge_w(fixture.capacityModel.value.q0(), fixture.capacityModel.value.qmax(), 0, Pointer[Float64]()) > 0.0:
            var output_current: Float64 = current
            fixture.capacityModel.value.updateCapacity(output_current, 1)
            fixture.voltageModel.value.updateVoltage(fixture.capacityModel.value.q0(), fixture.capacityModel.value.qmax(), fixture.capacityModel.value.I(), 0, 1)
            output_power += fixture.capacityModel.value.I() * fixture.voltageModel.value.battery_voltage()
            n_t += 1
        current += fabs(max_current) / 100.0
        eff_vs_current.append(fabs(output_power / input_power))
    var eff_expected: List[Float64] = List[Float64](0.99, 0.99, 0.98, 0.98, 0.97, 0.97, 0.96, 0.96, 0.95, 0.95, 0.94, 0.95, 0.93, 0.93, 0.93, 0.93, 0.95, 0.92, 0.90, 0.93, 0.88, 0.92, 0.90, 0.91, 0.90, 0.89, 0.89, 0.90, 0.90, 0.84, 0.87, 0.88, 0.89, 0.89, 0.81, 0.85, 0.85, 0.86, 0.88, 0.88, 0.87, 0.78, 0.81, 0.81, 0.83, 0.84, 0.85, 0.86, 0.87, 0.87, 0.85, 0.79, 0.75, 0.75, 0.76, 0.77, 0.78, 0.79, 0.80, 0.81, 0.82, 0.83, 0.84, 0.85, 0.85, 0.84, 0.84, 0.82, 0.76, 0.66, 0.66, 0.66, 0.67, 0.68, 0.69, 0.70, 0.70, 0.71, 0.72, 0.73, 0.74, 0.74, 0.75, 0.76, 0.77, 0.77, 0.78, 0.78, 0.79, 0.80, 0.81, 0.81, 0.81, 0.81, 0.81, 0.82, 0.82, 0.81, 0.81)
    for i in range(eff_expected.size):
        expect_near(eff_vs_current[i], eff_expected[i], 0.01, " i = " + String(i))

def lib_battery_test_RoundtripEffTable():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var vals: List[Float64] = List[Float64](0.0, 4.1, 1.78, 4.05, 88.9, 3.4, 99.0, 0.0)
    var table = matrix_t[Float64](4, 2, &vals)
    var capacityModel = capacity_lithium_ion_t(fixture.q, fixture.SOC_init, fixture.SOC_max, fixture.SOC_min, fixture.dtHour)
    var voltageModel = voltage_table_t(fixture.n_series, fixture.n_strings, fixture.Vnom_default, table, fixture.resistance, 1)
    capacityModel.change_SOC_limits(0.0, 100.0)
    var full_current: Float64 = 1000.0
    var max_current: Float64 = 0.0
    voltageModel.calculate_max_charge_w(capacityModel.q0(), capacityModel.qmax(), 0, Pointer[Float64](address_of(max_current)))
    var eff_vs_current: List[Float64] = List[Float64]()
    var current: Float64 = fabs(max_current) * 0.01
    while current < fabs(max_current):
        capacityModel.updateCapacity(full_current, 1)   # discharge to empty
        var n_t: Int = 0
        current *= -1.0
        var input_power: Float64 = 0.0
        while capacityModel.SOC() < 100.0:
            var input_current: Float64 = current
            capacityModel.updateCapacity(input_current, 1)
            voltageModel.updateVoltage(capacityModel.q0(), capacityModel.qmax(), capacityModel.I(), 0, 1)
            input_power += capacityModel.I() * voltageModel.battery_voltage()
            n_t += 1
        current *= -1.0
        var output_power: Float64 = 0.0
        while voltageModel.calculate_max_discharge_w(capacityModel.q0(), capacityModel.qmax(), 0, Pointer[Float64]()) > 0.0:
            var output_current: Float64 = current
            capacityModel.updateCapacity(output_current, 1)
            voltageModel.updateVoltage(capacityModel.q0(), capacityModel.qmax(), capacityModel.I(), 0, 1)
            output_power += capacityModel.I() * voltageModel.battery_voltage()
            n_t += 1
        current += fabs(max_current) / 100.0
        eff_vs_current.append(fabs(output_power / input_power))
    var eff_expected: List[Float64] = List[Float64](0.99, 0.99, 0.98, 0.98, 0.97, 0.96, 0.96, 0.95, 0.95, 0.94, 0.93, 0.94, 0.93, 0.92, 0.92, 0.92, 0.91, 0.90, 0.90, 0.89, 0.88, 0.87, 0.88, 0.87, 0.86, 0.87, 0.86, 0.84, 0.86, 0.87, 0.85, 0.83, 0.81, 0.84, 0.85, 0.86, 0.84, 0.82, 0.79, 0.78, 0.80, 0.82, 0.84, 0.85, 0.85, 0.82, 0.80, 0.77, 0.74, 0.73, 0.74, 0.76, 0.77, 0.78, 0.79, 0.81, 0.82, 0.83, 0.84, 0.83, 0.80, 0.77, 0.74, 0.71, 0.67, 0.64, 0.65, 0.65, 0.66, 0.67, 0.68, 0.69, 0.70, 0.71, 0.71, 0.72, 0.73, 0.74, 0.75, 0.75, 0.76, 0.77, 0.78, 0.79, 0.79, 0.80, 0.81, 0.82, 0.82, 0.79, 0.76, 0.73, 0.69, 0.66, 0.62, 0.59, 0.55, 0.51, 0.47)
    for i in range(eff_expected.size):
        expect_near(eff_vs_current[i], eff_expected[i], 0.01, "")

def lib_battery_test_RoundtripEffVanadiumFlow():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var vol = voltage_vanadium_redox_t(1, 1, 1.41, 0.001, fixture.dtHour)
    var cap = capacity_lithium_ion_t(11.0, 30.0, 100.0, 0.0, fixture.dtHour)
    cap.change_SOC_limits(0.0, 100.0)
    var full_current: Float64 = 1000.0
    var max_current: Float64 = 0.0
    vol.calculate_max_charge_w(cap.q0(), cap.qmax(), 300.0, Pointer[Float64](address_of(max_current)))
    var current: Float64 = fabs(max_current) * 0.01
    while current < fabs(max_current):
        cap.updateCapacity(full_current, 1)   # discharge to empty
        var inputs: List[Float64] = List[Float64]()
        var outputs: List[Float64] = List[Float64]()
        var n_t: Int = 0
        current *= -1.0
        var input_power: Float64 = 0.0
        while cap.SOC() < 100.0:
            var input_current: Float64 = current
            cap.updateCapacity(input_current, 1)
            vol.updateVoltage(cap.q0(), cap.qmax(), cap.I(), 300.0, 1)
            input_power += cap.I() * vol.battery_voltage()
            n_t += 1
            inputs.append(vol.battery_voltage())
        current *= -1.0
        var output_power: Float64 = 0.0
        while vol.calculate_max_discharge_w(cap.q0(), cap.qmax(), 300.0, Pointer[Float64]()) > 0.0:
            var output_current: Float64 = current
            cap.updateCapacity(output_current, 1)
            vol.updateVoltage(cap.q0(), cap.qmax(), cap.I(), 300.0, 1)
            output_power += cap.I() * vol.battery_voltage()
            n_t += 1
            outputs.append(vol.battery_voltage())
        current += fabs(max_current) / 100.0

def lib_battery_test_HourlyVsSubHourly():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var cap_hourly = capacity_lithium_ion_t(fixture.q, fixture.SOC_init, fixture.SOC_max, fixture.SOC_min, fixture.dtHour)
    var volt_hourly = voltage_dynamic_t(fixture.n_series, fixture.n_strings, fixture.Vnom_default, fixture.Vfull, fixture.Vexp, fixture.Vnom, fixture.Qfull, fixture.Qexp, fixture.Qnom, fixture.C_rate, fixture.resistance, 1.0)
    var cap_subhourly = capacity_lithium_ion_t(fixture.q, fixture.SOC_init, fixture.SOC_max, fixture.SOC_min, fixture.dtHour)
    var volt_subhourly = voltage_dynamic_t(fixture.n_series, fixture.n_strings, fixture.Vnom_default, fixture.Vfull, fixture.Vexp, fixture.Vnom, fixture.Qfull, fixture.Qexp, fixture.Qnom, fixture.C_rate, fixture.resistance, 0.5)
    assert(cap_hourly.q0() == cap_subhourly.q0())
    assert(volt_hourly.battery_voltage() == volt_subhourly.battery_voltage())
    var discharge_watts: Float64 = 100.0
    while cap_hourly.SOC() > 16.0:
        var I_hourly: Float64 = volt_hourly.calculate_current_for_target_w(discharge_watts, cap_hourly.q0(), cap_hourly.qmax(), 0)
        cap_hourly.updateCapacity(I_hourly, 1)
        volt_hourly.updateVoltage(cap_hourly.q0(), cap_hourly.qmax(), cap_hourly.I(), 0, 1)
        expect_near(cap_hourly.I() * volt_hourly.battery_voltage(), discharge_watts, 0.1, "")
        var I_subhourly: Float64 = volt_subhourly.calculate_current_for_target_w(discharge_watts, cap_subhourly.q0(), cap_subhourly.qmax(), 0)
        cap_subhourly.updateCapacity(I_subhourly, 0.5)
        volt_subhourly.updateVoltage(cap_subhourly.q0(), cap_subhourly.qmax(), cap_subhourly.I(), 0, 0.5)
        expect_near(cap_subhourly.I() * volt_subhourly.battery_voltage(), discharge_watts, 0.1, "")

def lib_battery_test_AdaptiveTimestep():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var steps_per_hour: Int = 4
    var batt_subhourly = battery_t(*fixture.batteryModel.value)
    batt_subhourly.ChangeTimestep(1.0 / Float64(steps_per_hour))
    var batt_adaptive = battery_t(*batt_subhourly)
    assert(batt_adaptive.charge_total() == fixture.batteryModel.value.charge_total())
    assert(batt_adaptive.charge_maximum() == fixture.batteryModel.value.charge_maximum())
    assert(batt_adaptive.V() == fixture.batteryModel.value.V())
    assert(batt_adaptive.I() == fixture.batteryModel.value.I())
    expect_near(batt_subhourly.get_params().lifetime.dt_hr, 0.25, 1e-3, "")
    var kw_hourly: Float64 = 100.0
    var count: Int = 0
    while count < 2000:
        var hourly_E: Float64 = 0.0
        var hourly_V: Float64 = 0.0
        var hourly_I: Float64 = 0.0
        var subhourly_E: Float64 = 0.0
        var adaptive_E: Float64 = 0.0
        while fixture.batteryModel.value.SOC() > 15.0:
            fixture.batteryModel.value.runPower(kw_hourly)
            hourly_E += fixture.batteryModel.value.get_state().P
            hourly_V = fixture.batteryModel.value.get_state().V
            hourly_I = fixture.batteryModel.value.get_state().I
            expect_near(batt_subhourly.get_params().lifetime.dt_hr, 0.25, 1e-3, "")
            for i in range(steps_per_hour):
                batt_subhourly.runPower(kw_hourly)
                subhourly_E += batt_subhourly.get_state().P / Float64(steps_per_hour)
            if count % 2 == 0:
                batt_adaptive.ChangeTimestep(1.0)
                batt_adaptive.runPower(kw_hourly)
                adaptive_E += batt_adaptive.get_state().P
            else:
                batt_adaptive.ChangeTimestep(1.0 / Float64(steps_per_hour))
                for i in range(steps_per_hour):
                    batt_adaptive.runPower(kw_hourly)
                    adaptive_E += batt_adaptive.get_state().P / Float64(steps_per_hour)
            expect_near(fixture.batteryModel.value.get_state().lifetime.day_age_of_battery, batt_subhourly.get_state().lifetime.day_age_of_battery, 1e-3, "")
            expect_near(fixture.batteryModel.value.get_state().lifetime.day_age_of_battery, batt_adaptive.get_state().lifetime.day_age_of_battery, 1e-3, "")
        while fixture.batteryModel.value.SOC() < 85.0:
            fixture.batteryModel.value.runPower(-kw_hourly)
            hourly_E -= fixture.batteryModel.value.get_state().P
            for i in range(steps_per_hour):
                batt_subhourly.runPower(-kw_hourly)
                subhourly_E -= batt_subhourly.get_state().P / Float64(steps_per_hour)
            if count % 2 == 0:
                batt_adaptive.ChangeTimestep(1.0)
                batt_adaptive.runPower(-kw_hourly)
                adaptive_E -= batt_adaptive.get_state().P
            else:
                batt_adaptive.ChangeTimestep(1.0 / Float64(steps_per_hour))
                for i in range(steps_per_hour):
                    batt_adaptive.runPower(-kw_hourly)
                    adaptive_E -= batt_adaptive.get_state().P / Float64(steps_per_hour)
        count += 1
        expect_near(hourly_E, adaptive_E, hourly_E * 0.10, "At count " + String(count))
        expect_near(subhourly_E, adaptive_E, subhourly_E * 0.15, "At count " + String(count))
        expect_near(fixture.batteryModel.value.charge_maximum(), batt_adaptive.charge_maximum(), 20.0, "At count " + String(count))
        expect_near(batt_subhourly.charge_maximum(), batt_adaptive.charge_maximum(), 20.0, "At count " + String(count))
    expect_near(fixture.batteryModel.value.charge_maximum(), 577.09, 1e-2, "")
    expect_near(batt_subhourly.charge_maximum(), 576.95, 1e-2, "")
    expect_near(batt_adaptive.charge_maximum(), 576.95, 1e-2, "")
    expect_near(fixture.batteryModel.value.SOC(), 94.98, 1e-2, "")
    expect_near(batt_subhourly.SOC(), 94.95, 1e-2, "")
    expect_near(batt_adaptive.SOC(), 94.95, 1e-2, "")

def lib_battery_test_AugmentCapacity():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var augmentation_percent: List[Float64] = List[Float64](50.0, 40.0, 30.0)
    fixture.batteryModel.value.setupReplacements(augmentation_percent)
    var batteries: List[Pointer[battery_t]] = List[Pointer[battery_t]]()
    batteries.append(Pointer[battery_t](owner=new battery_t(*fixture.batteryModel.value)))
    batteries.append(Pointer[battery_t](owner=new battery_t(*fixture.batteryModel.value)))
    batteries[1].value.setupReplacements(augmentation_percent)
    batteries.append(Pointer[battery_t](owner=new battery_t(*fixture.batteryModel.value)))
    batteries[2].value.setupReplacements(augmentation_percent)
    var i: Int = 0
    var I: Float64 = 100.0
    var mult: Float64 = 1.0
    var replaceCount: Int = 0
    for y in range(augmentation_percent.size):
        for t in range(8760):
            mult = 1.0 if Int(fmod(Float64(t), 2.0)) == 0 else -1.0
            var current: Float64 = mult * I
            batteries[replaceCount].value.runReplacement(y, t, 0)
            batteries[replaceCount].value.run(i, current)
            i += 1
        if augmentation_percent[y] > 0.0:
            replaceCount += 1
    assert(batteries[0].value.getNumReplacementYear() == 0)
    assert(batteries[1].value.getNumReplacementYear() == 1)
    assert(batteries[2].value.getNumReplacementYear() == 1)
    for bat in batteries:
        _ = bat.take()

def lib_battery_test_ReplaceByCapacityTest():
    var fixture = lib_battery_test()
    fixture.SetUp()
    fixture.batteryModel.value.setupReplacements(91.0)
    var idx: Int = 0
    var I: Float64 = fixture.Qfull * Float64(fixture.n_strings) * 2.0
    while idx < 100000:
        fixture.batteryModel.value.run(idx, I)
        fixture.batteryModel.value.runReplacement(0, idx, 0)
        idx += 1
        I = -fixture.Qfull * Float64(fixture.n_strings) * 2.0
        fixture.batteryModel.value.run(idx, I)
        fixture.batteryModel.value.runReplacement(0, idx, 0)
        idx += 1
    var rep: Float64 = fixture.batteryModel.value.getNumReplacementYear()
    assert(rep == 1.0)

def lib_battery_test_NMCLifeModel():
    var fixture = lib_battery_test()
    fixture.SetUp()
    var lifetimeModelNMC = lifetime_nmc_t(fixture.dtHour)
    var thermalModelNMC = thermal_t(fixture.dtHour, fixture.mass, fixture.surface_area, fixture.resistance, fixture.Cp, fixture.h, fixture.T_room)
    var capacityModelNMC = capacity_lithium_ion_t(fixture.q, fixture.SOC_init, fixture.SOC_max, fixture.SOC_min, fixture.dtHour)
    var voltageModelNMC = voltage_dynamic_t(fixture.n_series, fixture.n_strings, fixture.Vnom_default, fixture.Vfull, fixture.Vexp, fixture.Vnom, fixture.Qfull, fixture.Qexp, fixture.Qnom, fixture.C_rate, fixture.resistance, fixture.dtHour)
    var lossModelNMC = losses_t(fixture.monthlyLosses, fixture.monthlyLosses, fixture.monthlyLosses)
    var batteryN