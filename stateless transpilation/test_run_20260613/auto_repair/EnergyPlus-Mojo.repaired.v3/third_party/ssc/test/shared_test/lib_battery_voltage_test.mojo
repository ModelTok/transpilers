// Ported from C++ to Mojo

from . import assert_approx_equal, assert_equal
from lib_util import matrix_t
from lib_battery import (
    voltage_t, voltage_dynamic_t, voltage_table_t, voltage_vanadium_redox_t,
    capacity_t, capacity_lithium_ion_t
)

struct lib_battery_voltage_test:
    var model: voltage_t
    var cap: capacity_t
    var tol: Float64 = 0.01
    var error: Float64
    var n_cells_series: Int = 139
    var n_strings: Int = 9
    var voltage_nom: Float64 = 3.6
    var R: Float64 = 0.2
    var nyears: Int = 1
    def __init__(inout self): pass

struct voltage_dynamic_lib_battery_voltage_test(lib_battery_voltage_test):
    var Vfull: Float64 = 4.1
    var Vexp: Float64 = 4.05
    var Vnom: Float64 = 3.4
    var Qfull: Float64 = 2.25
    var Qexp: Float64 = 0.04
    var Qnom: Float64 = 2.0
    var C_rate: Float64 = 0.2
    def CreateModel(inout self, dt_hr: Float64):
        self.cap = capacity_lithium_ion_t(10, 50, 95, 5, dt_hr)
        self.model = voltage_dynamic_t(
            self.n_cells_series, self.n_strings,
            self.voltage_nom, self.Vfull, self.Vexp, self.Vnom,
            self.Qfull, self.Qexp, self.Qnom,
            self.C_rate, self.R, dt_hr
        )
        self.model.set_initial_SOC(50)

struct voltage_table_lib_battery_voltage_test(lib_battery_voltage_test):
    var Vfull: Float64 = 4.1
    var Vexp: Float64 = 4.05
    var Vnom: Float64 = 3.4
    var vals: DynamicVector[Float64]
    var table: matrix_t[Float64]
    def CreateModel(inout self, dt_hr: Float64):
        self.vals = DynamicVector[Float64]([0, self.Vfull, 1.78, self.Vexp, 88.9, self.Vnom, 99, 0])
        self.table = matrix_t[Float64](4, 2, self.vals.data())
        self.cap = capacity_lithium_ion_t(10, 50, 95, 5, dt_hr)
        self.model = voltage_table_t(
            self.n_cells_series, self.n_strings, self.voltage_nom, self.table, self.R, dt_hr
        )
        self.model.set_initial_SOC(50)
    def CreateModel_SSC_412(inout self, dt_hr: Float64):
        var voltage_vals: DynamicVector[Float64] = DynamicVector[Float64](
            [0, 1.7, 4, 1.7, 5, 1.58, 60, 1.5, 85, 1.4, 90, 1.3, 93, 1.2, 95, 1, 96, 0.9]
        )
        var voltage_table: matrix_t[Float64] = matrix_t[Float64](9, 2, voltage_vals.data())
        self.cap = capacity_lithium_ion_t(10, 50, 95, 5, dt_hr)
        self.model = voltage_table_t(
            self.n_cells_series, self.n_strings, self.voltage_nom, voltage_table, self.R, dt_hr
        )
        self.model.set_initial_SOC(50)

struct voltage_vanadium_lib_battery_voltage_test(lib_battery_voltage_test):
    def CreateModel(inout self, dt_hr: Float64):
        self.cap = capacity_lithium_ion_t(10, 50, 95, 5, dt_hr)
        self.model = voltage_vanadium_redox_t(
            self.n_cells_series, self.n_strings, self.voltage_nom, self.R, dt_hr
        )
        self.model.set_initial_SOC(50)

@test
def voltage_dynamic_lib_battery_voltage_test_SetUpTest():
    var test = voltage_dynamic_lib_battery_voltage_test()
    test.CreateModel(1)
    assert_approx_equal(test.model.cell_voltage(), 4.058, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_NickelMetalHydrideFromPaperTest():
    var test = voltage_dynamic_lib_battery_voltage_test()
    test.CreateModel(1)
    test.cap = capacity_lithium_ion_t(6.5, 100, 100, 0, 1)
    test.model = voltage_dynamic_t(1, 1, 1.2, 1.4, 1.25, 1.2, 6.5, 1.3, 5.2, 0.2, 0.0046, 1)
    var dt_hr: DynamicVector[Float64] = DynamicVector[Float64]([1.0/6, 1.0/3, 1.0/3])
    var voltages: DynamicVector[Float64] = DynamicVector[Float64]([1.25, 1.22, 1.17])
    for i in range(3):
        var I: Float64 = 6.5
        test.cap.updateCapacity(I, dt_hr[i])
        test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hr[i])
        var msg = "NickelMetalHydrideFromPaperTest: " + String(i)
        assert_approx_equal(test.model.battery_voltage(), voltages[i], 0.05, msg)

@test
def voltage_dynamic_lib_battery_voltage_test_updateCapacityTest():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.9, test.tol)
    assert_approx_equal(test.cap.q0(), 3, test.tol)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 4.1, test.tol)
    assert_approx_equal(test.cap.q0(), 5, test.tol)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 2.49, test.tol)
    assert_approx_equal(test.cap.q0(), 0.5, test.tol)

@test
def voltage_dynamic_lib_battery_voltage_test_updateCapacitySubHourly():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 2
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.98, test.tol)
    assert_approx_equal(test.cap.q0(), 4, test.tol)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 4.1, test.tol)
    assert_approx_equal(test.cap.q0(), 5, test.tol)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.78, test.tol)
    assert_approx_equal(test.cap.q0(), 2.5, test.tol)

@test
def voltage_dynamic_lib_battery_voltage_test_updateCapacitySubMinute():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 4.014, 1e-3)
    assert_approx_equal(test.cap.q0(), 4.99, 1e-3)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 4.103, 1e-3)
    assert_approx_equal(test.cap.q0(), 5, 1e-3)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.947, 1e-3)
    assert_approx_equal(test.cap.q0(), 4.975, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxChargeHourly():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -2989, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -292, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5811, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxChargeSubHourly():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -6132, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -585, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -12180, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxChargeSubMinute():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 360
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -11056338, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -204913, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -38120722, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxDischargeHourly():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 1845, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 10, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 181, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 3829, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 19, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxDischargeSubHourly():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 3592, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 10, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 365, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 7390, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 14.25, 1e-3)

@test
def voltage_dynamic_lib_battery_voltage_test_calculateMaxDischargeSubMinute():
    var test = voltage_dynamic_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 25554, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 45.475, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 25307, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 40.973, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 26689, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.6)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 90.345, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_updateCapacityTest():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.54, test.tol)
    assert_approx_equal(test.cap.q0(), 3, test.tol)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.7, test.tol)
    assert_approx_equal(test.cap.q0(), 5, test.tol)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 1.35, test.tol)
    assert_approx_equal(test.cap.q0(), 0.5, test.tol)

@test
def voltage_table_lib_battery_voltage_test_updateCapacitySubHourly():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 2
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.616, test.tol)
    assert_approx_equal(test.cap.q0(), 4, test.tol)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.7, test.tol)
    assert_approx_equal(test.cap.q0(), 5, test.tol)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.504, test.tol)
    assert_approx_equal(test.cap.q0(), 2.5, test.tol)

@test
def voltage_table_lib_battery_voltage_test_updateCapacitySubMinute():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.689, test.tol)
    assert_approx_equal(test.cap.q0(), 4.99, 1e-3)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.69, test.tol)
    assert_approx_equal(test.cap.q0(), 5, 1e-3)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 0, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.689, test.tol)
    assert_approx_equal(test.cap.q0(), 4.975, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeHourly1():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -2849, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -5, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)
    max_current_calc *= -1
    test.cap.updateCapacity(max_current_calc, dt_hour)
    max_current_calc = test.model.calculate_current_for_target_w(power + 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -4.99, 1e-2)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 99.99, 1e-2)
    assert_approx_equal(test.cap.I() * test.model.battery_voltage(), -2564, 1)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeHourly2():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64 = -4
    test.cap.updateCapacity(max_current, dt_hour)
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -569, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -1, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)
    max_current_calc = 1
    test.cap.updateCapacity(max_current_calc, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -569, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power + 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -0.998, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 99.984, 1e-3)
    assert_approx_equal(test.cap.I() * test.model.battery_voltage(), -512, 1)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5699, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeHourly3():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64 = 4
    test.cap.updateCapacity(max_current, dt_hour)
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5129, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -9, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)
    max_current_calc = 9
    test.cap.updateCapacity(max_current_calc, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5129, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power + 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -8.99, 1e-2)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 99.99, 1e-2)
    assert_approx_equal(test.cap.I() * test.model.battery_voltage(), -4615, 1)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeSubHourly1():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5699, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -10, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)
    max_current_calc *= -1
    test.cap.updateCapacity(max_current_calc, dt_hour)
    max_current_calc = test.model.calculate_current_for_target_w(power + 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -9.999, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 99.99, 1e-2)
    assert_approx_equal(test.cap.I() * test.model.battery_voltage(), -5128, 1)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeSubHourly2():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64 = -8
    test.cap.updateCapacity(max_current, dt_hour)
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -1139, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -2, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)
    max_current_calc = 2
    test.cap.updateCapacity(max_current_calc, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -1139, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power + 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, -2, 1e-2)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 99.99, 1e-2)
    assert_approx_equal(test.cap.I() * test.model.battery_voltage(), -1025, 1)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -11398, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current_calc, dt_hour)
    assert_approx_equal(test.cap.SOC(), 100, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxChargeSubMinute():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 120
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -341940, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -34193, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -649686, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxDischargeHourly():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 1194, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, 2.45, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 25.5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 581, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, 1.22, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 13.25, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 3569, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 27.02, 1e-2)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxDischargeSubHourly():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    test.cap.change_SOC_limits(0, 100)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 2388, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, 4.9, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 25.5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 1163, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, 2.44, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 13.25, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 7139, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power - 1, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 27.02, 1e-2)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxDischargeHourly_table_2():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel_SSC_412(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 3618.3, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 52.06, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 3461.9, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 3774.7, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 54.31, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculateMaxDischargeSubMinute():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 238891, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 25.5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 116333, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 13.25, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, 685795, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 0)
    assert_approx_equal(max_current_calc, max_current, 0.3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 24.52, 1e-3)

@test
def voltage_table_lib_battery_voltage_test_calculate_discharging_past_limits():
    var test = voltage_table_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel_SSC_412(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 3618.3, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 52.06, 1e-2)
    var I: Float64 = 2
    while test.cap.SOC() > 8:
        test.cap.updateCapacity(I, dt_hour)
    max_current_calc = test.model.calculate_current_for_target_w(1000.0, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 0.5, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_SetUpTest():
    var test = voltage_vanadium_lib_battery_voltage_test()
    test.CreateModel(1)
    assert_equal(test.model.cell_voltage(), 3.6)

@test
def voltage_vanadium_lib_battery_voltage_test_updateCapacityTest():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.53, test.tol)
    assert_approx_equal(test.cap.q0(), 3, test.tol)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.64, test.tol)
    assert_approx_equal(test.cap.q0(), 5, test.tol)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.3, test.tol)
    assert_approx_equal(test.cap.q0(), 0.5, test.tol)

@test
def voltage_vanadium_lib_battery_voltage_test_updateCapacitySubMinute():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var I: Float64 = 2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.644, test.tol)
    assert_approx_equal(test.cap.q0(), 4.99, 1e-3)
    I = -2
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.64, test.tol)
    assert_approx_equal(test.cap.q0(), 5, 1e-3)
    I = 5
    test.cap.updateCapacity(I, dt_hour)
    test.model.updateVoltage(test.cap.q0(), test.cap.qmax(), test.cap.I(), 293, dt_hour)
    assert_approx_equal(test.model.cell_voltage(), 3.71, test.tol)
    assert_approx_equal(test.cap.q0(), 4.975, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxChargeHourly():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -2579, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -4.70, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-2)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -251, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -0.45, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-2)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5032, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -9.02, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-2)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxChargeSubHourly():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -5312, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -9.426, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -503, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -0.907, 1e-3)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -10622, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, -18.12, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxChargeSubMinute():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 360
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -10908720, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-2 * abs(max_current))
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -190152, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 0.1 * abs(max_current))
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)
    var I: Float64 = 2
    while test.cap.SOC() > 5:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_charge_w(test.cap.q0(), test.cap.qmax(), 0, max_current)
    assert_approx_equal(power, -37840248, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-2 * abs(max_current))
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 95, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxDischargeHourly():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 2308, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 4.89, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 213, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 4570, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 9.316, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxDischargeSubHourly():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 0.5
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 4729, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 9.611, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 425, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 9617, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 5, 1e-3)

@test
def voltage_vanadium_lib_battery_voltage_test_calculateMaxDischargeSubMinute():
    var test = voltage_vanadium_lib_battery_voltage_test()
    var dt_hour: Float64 = 1.0 / 200
    test.CreateModel(dt_hour)
    var max_current: Float64
    var power: Float64 = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 2015656, 1)
    var max_current_calc: Float64 = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 733.51, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 13.324, 1e-3)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 71831, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, max_current, 1e-1)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 8.641, 1e-3)
    var I: Float64 = -2
    while test.cap.SOC() < 95:
        test.cap.updateCapacity(I, dt_hour)
    power = test.model.calculate_max_discharge_w(test.cap.q0(), test.cap.qmax(), 293, max_current)
    assert_approx_equal(power, 8903223, 1)
    max_current_calc = test.model.calculate_current_for_target_w(power, test.cap.q0(), test.cap.qmax(), 293)
    assert_approx_equal(max_current_calc, 1621.4, 1e-2)
    test.cap.updateCapacity(max_current, dt_hour)
    assert_approx_equal(test.cap.SOC(), 13.93, 1e-3)
