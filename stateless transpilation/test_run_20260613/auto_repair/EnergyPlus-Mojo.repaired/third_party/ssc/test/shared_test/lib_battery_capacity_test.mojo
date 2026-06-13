from testing import *
from lib_battery_capacity import *
from lib_battery import *

def compareState(tested_state: capacity_state, expected_state: capacity_state, msg: String):
    var tol: Float64 = 0.01
    assert_approx_equal(tested_state.q0, expected_state.q0, tol)  # msg
    assert_approx_equal(tested_state.qmax_thermal, expected_state.qmax_thermal, tol)  # msg
    assert_approx_equal(tested_state.qmax_lifetime, expected_state.qmax_lifetime, tol)  # msg
    assert_approx_equal(tested_state.cell_current, expected_state.cell_current, tol)  # msg
    assert_approx_equal(tested_state.I_loss, expected_state.I_loss, tol)  # msg
    assert_approx_equal(tested_state.SOC, expected_state.SOC, tol)  # msg
    assert_approx_equal(tested_state.SOC_prev, expected_state.SOC_prev, tol)  # msg
    assert_approx_equal(tested_state.charge_mode, expected_state.charge_mode, tol)  # msg

def compareState(tested_state: Pointer[capacity_state], expected_state: Pointer[capacity_state], msg: String):
    compareState(tested_state[], expected_state[], msg)

@value
struct lib_battery_capacity_test:
    var old_cap: Pointer[capacity_t]
    var tol: Float64 = 0.1
    var error: Float64
    var q: Float64 = 1000
    var SOC_init: Float64 = 50
    var SOC_min: Float64 = 15
    var SOC_max: Float64 = 95
    var dt_hour: Float64 = 1
    var nyears: Int = 1

@value
struct LiIon_lib_battery_capacity_test(lib_battery_capacity_test):
    def SetUp(self):
        self.old_cap = Pointer[capacity_lithium_ion_t].alloc(1)
        self.old_cap[] = capacity_lithium_ion_t(self.q, self.SOC_init, self.SOC_max, self.SOC_min, self.dt_hour)
        var I: Float64 = 1e-7
        self.old_cap[].updateCapacity(I, 1)

@value
struct KiBam_lib_battery_capacity_test(lib_battery_capacity_test):
    var q10: Float64 = 93.
    var t1: Float64 = 1
    var q1: Float64 = 60.
    var q20: Float64 = 100

    def SetUp(self):
        self.old_cap = Pointer[capacity_kibam_t].alloc(1)
        self.old_cap[] = capacity_kibam_t(self.q20, self.t1, self.q1, self.q10, self.SOC_init, self.SOC_max, self.SOC_min, self.dt_hour)

def test_LiIon_lib_battery_capacity_test_SetUpTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    assert_approx_equal(test.old_cap[].q1(), 500, 1e-4)
    assert_approx_equal(test.old_cap[].q10(), 1000, 1e-4)
    assert_approx_equal(test.old_cap[].SOC(), 50, 1e-4)

def test_LiIon_lib_battery_capacity_test_updateCapacityTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    var I: Float64 = 1.5
    test.old_cap[].updateCapacity(I, test.dt_hour)
    var s1 = capacity_state(498.5, 1000, 1000, 1.5, 0, 49.85, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 1")
    I = 3
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(495.5, 1000, 1000, 3, 0, 49.55, 49.85, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 2")
    I = 490
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(150, 1000, 1000, 345.5, 0, 15, 49.55, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 3")
    I = 490
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(150, 1000, 1000, 0, 0, 15, 15, 1)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 4")

def test_LiIon_lib_battery_capacity_test_updateCapacityThermalTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForThermal(percent)
    var s1 = capacity_state(500, 1000, 800, 0, 0, 62.5, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 1")
    percent = 50
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(500, 1000, 500, 0, 0, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 2")
    percent = 10
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(100, 1000, 100, 0, 400, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 3")
    percent = 110
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(100, 1000, 1100, 0, 400, 10, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 4")
    percent = -110
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(0, 1000, 0, 0, 500, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 4")

def test_LiIon_lib_battery_capacity_test_updateCapacityLifetimeTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForLifetime(percent)
    var s1 = capacity_state(500, 800, 1000, 0, 0, 62.5, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 1")
    percent = 50
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(500, 500, 1000, 0, 0, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 2")
    percent = 10
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(100, 100, 1000, 0, 400, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 3")
    percent = 110
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(100, 100, 1000, 0, 400, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 4")
    percent = -110
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(0, 0, 1000, 0, 500, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 5")

def test_LiIon_lib_battery_capacity_test_replaceBatteryTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    var s1 = capacity_state(500, 1000, 1000, 0, 0, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: init")
    test.old_cap[].updateCapacityForLifetime(0)
    s1 = capacity_state(0, 0, 1000, 0, 500, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: init degradation")
    var percent: Float64 = 50
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(250, 500, 500, 0, 500, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 1")
    percent = 20
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(350, 700, 700, 0, 500, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 2")
    percent = 110
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(500, 1000, 1000, 0, 500, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 4")
    percent = -110
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(500, 1000, 1000, 0, 500, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 5")

def test_LiIon_lib_battery_capacity_test_runSequenceTest():
    var test = LiIon_lib_battery_capacity_test()
    test.SetUp()
    var I: Float64 = 400
    test.old_cap[].updateCapacity(I, test.dt_hour)
    var s1 = capacity_state(150, 1000, 1000, 350, 0, 15, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 1")
    I = -400
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(550, 1000, 1000, -400, 0, 55, 15, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 2")
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(550, 1000, 800, -400, 0, 68.75, 15, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 3")
    I = 400
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(150, 1000, 800, 400, 0, 18.75, 68.75, 2)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 4")
    I = -400
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(550, 1000, 800, -400, 0, 68.75, 18.75, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 5")
    percent = 70
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(550, 700, 800, -400, 0, 78.57, 18.75, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 6")
    percent = 20
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(650, 900, 900, -400, 0, 72.22, 50, 0)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 7")
    I = 400
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(250, 900, 900, 400, 0, 27.77, 72.22, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 8")

def test_LiIon_lib_battery_capacity_test_OverchargedSOCLimits():
    var I: Float64 = 35.
    var dt: Float64 = 1./60.
    var cap = Pointer[capacity_lithium_ion_t].alloc(1)
    cap[] = capacity_lithium_ion_t(19984, 90, 95, 15, dt)
    cap[].updateCapacityForThermal(90)
    cap[].updateCapacity(I, dt)
    assert_equal(I, 35)

def test_LiIon_lib_battery_capacity_test_OverchargedSOCLimits1():
    var I: Float64 = -20.
    var dt: Float64 = 1./60.
    var cap = Pointer[capacity_lithium_ion_t].alloc(1)
    cap[] = capacity_lithium_ion_t(19984, 90, 95, 15, dt)
    cap[].updateCapacityForThermal(90)
    cap[].updateCapacity(I, dt)
    assert_approx_equal(I, 0, 1e-2)
    assert_approx_equal(cap[].SOC(), 95, 1e-3)

def test_LiIon_lib_battery_capacity_test_UnderchargedSOCLimits():
    var I: Float64 = 35.
    var dt: Float64 = 1./60.
    var cap = Pointer[capacity_lithium_ion_t].alloc(1)
    cap[] = capacity_lithium_ion_t(19984, 10, 95, 15, dt)
    cap[].updateCapacityForThermal(90)
    cap[].updateCapacity(I, dt)
    assert_equal(I, 0)

def test_LiIon_lib_battery_capacity_test_UnderchargedSOCLimits1():
    var I: Float64 = -35.
    var dt: Float64 = 1./60.
    var cap = Pointer[capacity_lithium_ion_t].alloc(1)
    cap[] = capacity_lithium_ion_t(19984, 10, 95, 15, dt)
    cap[].updateCapacityForThermal(90)
    cap[].updateCapacity(I, dt)
    assert_equal(I, -35)

def test_KiBam_lib_battery_capacity_test_SetUpTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    assert_approx_equal(test.old_cap[].q1(), 25.6938, test.tol)
    assert_equal(test.old_cap[].q10(), 93)
    assert_approx_equal(test.old_cap[].qmax(), 25.6938, 108.15)

def test_KiBam_lib_battery_capacity_test_updateCapacityTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    var I: Float64 = 1.5
    test.old_cap[].updateCapacity(I, test.dt_hour)
    var s1 = capacity_state(52.58, 108.16, 108.16, 1.5, 0, 48.613, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 1")
    I = 3
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(49.58, 108.16, 108.16, 3, 0, 45.839, 48.613, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 2")
    I = 490
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(22.927, 108.16, 108.16, 26.65, 0, 21.19, 45.839, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 3")
    I = 490
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(16.67, 108.16, 108.16, 6.25, 0, 15.413, 21.19, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityTest: 4")

def test_KiBam_lib_battery_capacity_test_updateCapacityThermalTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForThermal(percent)
    var s1 = capacity_state(54.07, 108.15, 86.53, 0, 0, 62.5, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 1")
    percent = 50
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(54.07, 108.15, 54.07, 0, 0, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 2")
    percent = 10
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(10.816, 108.15, 10.816, 0, 43.26, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 3")
    percent = 110
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(10.816, 108.15, 118.97, 0, 43.26, 10, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 4")
    percent = -110
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(0, 108.15, 0, 0, 54.07, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityThermalTest: 4")

def test_KiBam_lib_battery_capacity_test_updateCapacityLifetimeTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForLifetime(percent)
    var s1 = capacity_state(54.07, 86.53, 108.15, 0, 0, 62.5, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 1")
    percent = 50
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(54.07, 54.07, 108.15, 0, 0, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 2")
    percent = 10
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(10.816, 10.816, 108.15, 0, 43.26, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 3")
    percent = 110
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(10.816, 10.816, 108.15, 0, 43.26, 100, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 4")
    percent = -110
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(0, 0, 108.15, 0, 54.07, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "updateCapacityLifetimeTest: 5")

def test_KiBam_lib_battery_capacity_test_replaceBatteryTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    var s1 = capacity_state(54.07, 108.15, 108.15, 0, 0, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: init")
    test.old_cap[].updateCapacityForLifetime(0)
    s1 = capacity_state(0, 0, 108.15, 0, 54.07, 0, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: init degradation")
    var percent: Float64 = 50
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(27.04, 54.07, 54.07, 0, 54.07, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 1")
    percent = 20
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(37.85, 75.71, 75.71, 0, 54.07, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 2")
    percent = 110
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(54.07, 108.15, 108.15, 0, 54.07, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 4")
    percent = -110
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(54.07, 108.15, 108.15, 0, 54.07, 50, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 5")

def test_KiBam_lib_battery_capacity_test_runSequenceTest():
    var test = KiBam_lib_battery_capacity_test()
    test.SetUp()
    var I: Float64 = 30
    test.old_cap[].updateCapacity(I, test.dt_hour)
    var s1 = capacity_state(24.07, 108.16, 108.16, 30, 0, 22.26, 50, 2)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 1")
    I = -30
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(54.07, 108.16, 108.16, -30, 0, 50, 22.26, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 2")
    var percent: Float64 = 80
    test.old_cap[].updateCapacityForThermal(percent)
    s1 = capacity_state(54.07, 108.16, 86.53, -30, 0, 62.5, 22.26, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 3")
    I = 40
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(20.74, 108.16, 86.53, 33.34, 0, 23.97, 62.5, 2)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 4")
    I = -40
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(60.74, 108.16, 86.53, -40, 0, 70.19, 23.97, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 5")
    percent = 70
    test.old_cap[].updateCapacityForLifetime(percent)
    s1 = capacity_state(60.74, 75.71, 86.53, -40, 0, 80.22, 23.97, 0)
    compareState(test.old_cap[].get_state(), s1, "runSequenceTest: 6")
    percent = 20
    test.old_cap[].replace_battery(percent)
    s1 = capacity_state(71.55, 97.34, 97.34, -40, 0, 73.5, 50, 0)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 7")
    I = 40
    test.old_cap[].updateCapacity(I, test.dt_hour)
    s1 = capacity_state(31.86, 97.34, 97.34, 39.7, 0, 32.73, 73.5, 2)
    compareState(test.old_cap[].get_state(), s1, "replaceBatteryTest: 8")