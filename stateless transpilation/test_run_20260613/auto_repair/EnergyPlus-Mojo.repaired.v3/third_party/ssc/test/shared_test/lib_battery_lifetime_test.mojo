# Mojo translation of lib_battery_lifetime_test.cpp
# Faithful 1:1 translation, no refactoring.

from lib_util import *
from lib_battery import *
from random import Random
from math import abs

# ----------------------------------------------------------------------
# Structs defined in .cpp file
struct cycle_lifetime_state:
    var relative_q: Float64
    var Xlt: Float64
    var Ylt: Float64
    var Range: Float64
    var average_range: Float64
    var nCycles: Int
    var jlt: Float64
    var Peaks: List[Float64]

    def __init__(inout self, relative_q: Float64, Xlt: Float64, Ylt: Float64, Range: Float64, average_range: Float64, nCycles: Int, jlt: Float64):
        self.relative_q = relative_q
        self.Xlt = Xlt
        self.Ylt = Ylt
        self.Range = Range
        self.average_range = average_range
        self.nCycles = nCycles
        self.jlt = jlt
        self.Peaks = List[Float64]()

# ----------------------------------------------------------------------
# Fixture classes (from header)

class lib_battery_lifetime_cycle_test:
    var cycle_model: lifetime_cycle_t
    var tol: Float64 = 0.01
    var cycles_vs_DOD: matrix_t[Float64]
    var dt_hour: Float64 = 1

    def __init__(inout self):

    def SetUp(inout self):
        var table_vals = List[Float64](20, 0, 100, 20, 5000, 80, 20, 10000, 60, 80, 0, 100, 80, 1000, 80, 80, 2000, 60)
        self.cycles_vs_DOD.assign(table_vals, 6, 3)
        self.cycle_model = lifetime_cycle_t(self.cycles_vs_DOD)

    # Test methods from .cpp
    def SetUpTest(inout self):
        assert self.cycle_model.capacity_percent() == 100

    def runCycleLifetimeTest(inout self):
        var DOD: Float64 = 5
        var idx: Int = 0
        while idx < 500:
            if idx % 2 != 0:
                DOD = 95
            else:
                DOD = 5
            self.cycle_model.runCycleLifetime(DOD)
            idx += 1
        var s: lifetime_state = self.cycle_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.cycle.q_relative_cycle - 95.02) <= tol
        assert abs(s.cycle.rainflow_Xlt - 90) <= tol
        assert abs(s.cycle.rainflow_Ylt - 90) <= tol
        assert abs(s.cycle.rainflow_jlt - 2) <= tol
        assert abs(s.range - 90) <= tol
        assert abs(s.average_range - 90) <= tol
        assert abs(Float64(s.n_cycles) - 249) <= tol
        while idx < 1000:
            if idx % 2 != 0:
                DOD = 90
            self.cycle_model.runCycleLifetime(DOD)
            idx += 1
        s = self.cycle_model.get_state()
        assert abs(s.cycle.q_relative_cycle - 91.244) <= tol
        assert abs(s.cycle.rainflow_Xlt - 0) <= tol
        assert abs(s.cycle.rainflow_Ylt - 0) <= tol
        assert abs(s.cycle.rainflow_jlt - 2) <= tol
        assert abs(s.range - 0) <= tol
        assert abs(s.average_range - 44.9098) <= tol
        assert abs(Float64(s.n_cycles) - 499) <= tol

    def runCycleLifetimeTestJaggedProfile(inout self):
        var DOD = List[Float64](5, 95, 50, 85, 10, 50, 5, 95, 5)
        var idx: Int = 0
        while idx < len(DOD):
            self.cycle_model.runCycleLifetime(DOD[idx])
            idx += 1
        var s: lifetime_state = self.cycle_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.cycle.q_relative_cycle - 99.95) <= tol
        assert abs(s.cycle.rainflow_Xlt - 90) <= tol
        assert abs(s.cycle.rainflow_Ylt - 90) <= tol
        assert abs(s.cycle.rainflow_jlt - 1) <= tol
        assert abs(s.range - 90) <= tol
        assert abs(s.average_range - 63.75) <= tol
        assert abs(Float64(s.n_cycles) - 4) <= tol

    def runCycleLifetimeTestKokamProfile(inout self):
        var DOD = List[Float64](0.66, 1.0, 0.24722075172048893, 1.0, 0.24559790735021855, 0.9989411900454035, 0.24559790735021936, 0.9989411900454057, 0.24573025859454606, 0.9990735412897335, 0.24625966357184892, 0.9992058925340614, 0.2466567173048243, 0.9992058925340647, 0.2465243660605033, 0.9982794338237967, 0.24718612228213058, 0.9992058925340731, 0.24718612228213466, 0.9982794338238032, 0.24612731232753976, 0.9981470825794796, 0.24625966357186685, 0.9984117850681331, 0.24678906854916766, 0.9984117850681358, 0.24731847352646982, 0.9985441363124643, 0.24784787850377074, 0.9988088388011173, 0.24784787850377454)
        var idx: Int = 0
        while idx < len(DOD):
            self.cycle_model.runCycleLifetime((1 - DOD[idx]) * 100.0)
            idx += 1
        var s: lifetime_state = self.cycle_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.cycle.q_relative_cycle - 99.79) <= tol
        assert abs(s.cycle.rainflow_Xlt - 75.09) <= tol
        assert abs(s.cycle.rainflow_Ylt - 75.27) <= tol
        assert abs(s.cycle.rainflow_jlt - 5) <= tol
        assert abs(s.range - 75.07) <= tol
        assert abs(s.average_range - 72.03) <= tol
        assert abs(Float64(s.n_cycles) - 13) <= tol

    def runCycleLifetimeTestWithNoise(inout self):
        var seed: Int = 100
        var tol_high: Float64 = 1.6
        var randomEngine = Random(seed)
        var unifRealDist = randomEngine.uniform(0.0, 1.0) # returns a generator; we'll call .rand() later
        var DOD: Float64 = 5
        var idx: Int = 0
        while idx < 500:
            var number = randomEngine.randrange(0, 100) / 100.0 * 2.0 - 1.0 # approximate uniform[-1,1]
            if idx % 2 != 0:
                DOD = 95 + number
            else:
                DOD = 5 + number
            self.cycle_model.runCycleLifetime(DOD)
            idx += 1
        var s: lifetime_state = self.cycle_model.get_state()
        assert abs(s.cycle.q_relative_cycle - 95.06) <= tol_high
        assert abs(s.range - 90.6) <= tol_high
        assert abs(s.average_range - 90.02) <= tol_high

    def replaceBatteryTest(inout self):
        var DOD: Float64 = 5
        var idx: Int = 0
        while idx < 1500:
            if idx % 2 != 0:
                DOD = 95
            else:
                DOD = 5
            self.cycle_model.runCycleLifetime(DOD)
            idx += 1
        var st = cycle_lifetime_state(85.02, 90, 90, 90, 90, 749, 2)
        var s: lifetime_state = self.cycle_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.cycle.q_relative_cycle - 85.02) <= tol
        assert abs(s.cycle.rainflow_Xlt - 90) <= tol
        assert abs(s.cycle.rainflow_Ylt - 90) <= tol
        assert abs(s.cycle.rainflow_jlt - 2) <= tol
        assert abs(s.range - 90) <= tol
        assert abs(s.average_range - 90) <= tol
        assert abs(Float64(s.n_cycles) - 749) <= tol
        self.cycle_model.replaceBattery(5)
        s = self.cycle_model.get_state()
        assert abs(s.cycle.q_relative_cycle - 90.019) <= tol
        assert abs(s.cycle.rainflow_Xlt - 0) <= tol
        assert abs(s.cycle.rainflow_Ylt - 0) <= tol
        assert abs(s.cycle.rainflow_jlt - 0) <= tol
        assert abs(s.range - 0) <= tol
        assert abs(s.average_range - 90) <= tol
        assert abs(Float64(s.n_cycles) - 749) <= tol

# ----------------------------------------------------------------------
# Fixture for calendar matrix test

class lib_battery_lifetime_calendar_matrix_test:
    var cal_model: lifetime_calendar_t
    var tol: Float64 = 0.01
    var calendar_matrix: matrix_t[Float64]
    var dt_hour: Float64 = 1

    def __init__(inout self):

    def SetUp(inout self):
        var table_vals = List[Float64](0, 100, 3650, 80, 7300, 50)
        self.calendar_matrix.assign(table_vals, 3, 2)
        self.cal_model = lifetime_calendar_t(self.dt_hour, self.calendar_matrix)

    def runCalendarMatrixTest(inout self):
        var T: Float64 = 278
        var SOC: Float64 = 20
        var idx: Int = 0
        while idx < 500:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        var s: lifetime_state = self.cal_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.day_age_of_battery - 20.79) <= tol
        assert abs(s.calendar.q_relative_calendar - 99.89) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0) <= tol
        while idx < 1000:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        s = self.cal_model.get_state()
        assert abs(s.day_age_of_battery - 41.625) <= tol
        assert abs(s.calendar.q_relative_calendar - 99.775) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0) <= tol

    def replaceBatteryTest(inout self):
        var T: Float64 = 4.85
        var SOC: Float64 = 20
        var idx: Int = 0
        while idx < 200000:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        var s: lifetime_state = self.cal_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.day_age_of_battery - 8333.29) <= tol
        assert abs(s.calendar.q_relative_calendar - 41.51) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0) <= tol
        self.cal_model.replaceBattery(5)
        s = self.cal_model.get_state()
        assert abs(s.day_age_of_battery - 0) <= tol
        assert abs(s.calendar.q_relative_calendar - 46.51) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0) <= tol

    def TestLifetimeDegradation(inout self):
        var vals = List[Float64](0, 100, 365, 50)
        var lifetime_matrix: matrix_t[Float64]
        lifetime_matrix.assign(vals, 2, 2)
        var dt_hour: Float64 = 1
        var hourly_lifetime = lifetime_calendar_t(dt_hour, lifetime_matrix)
        for idx in range(8760):
            hourly_lifetime.runLifetimeCalendarModel(idx, 20, 80)
        assert abs(hourly_lifetime.capacity_percent() - 50) <= 1
        dt_hour = 1.0 / 12.0
        var subhourly_lifetime = lifetime_calendar_t(dt_hour, lifetime_matrix)
        for idx in range(8760 * 12):
            subhourly_lifetime.runLifetimeCalendarModel(idx, 20, 80)
        assert abs(subhourly_lifetime.capacity_percent() - 50) <= 1

# ----------------------------------------------------------------------
# Fixture for calendar model test

class lib_battery_lifetime_calendar_model_test:
    var cal_model: lifetime_calendar_t
    var tol: Float64 = 0.01
    var dt_hour: Float64 = 1

    def __init__(inout self):

    def SetUp(inout self):
        self.cal_model = lifetime_calendar_t(self.dt_hour)

    def SetUpTest(inout self):
        assert self.cal_model.capacity_percent() == 102

    def runCalendarModelTest(inout self):
        var T: Float64 = 4.85
        var SOC: Float64 = 20
        var idx: Int = 0
        while idx < 500:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        var s: lifetime_state = self.cal_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.day_age_of_battery - 20.79) <= tol
        assert abs(s.calendar.q_relative_calendar - 101.78) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0.00217) <= tol
        while idx < 1000:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        s = self.cal_model.get_state()
        assert abs(s.day_age_of_battery - 41.625) <= tol
        assert abs(s.calendar.q_relative_calendar - 101.69) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0.00306) <= tol

    def replaceBatteryTest(inout self):
        var T: Float64 = 4.85
        var SOC: Float64 = 20
        var idx: Int = 0
        while idx < 200000:
            if idx % 2 != 0:
                SOC = 90
            self.cal_model.runLifetimeCalendarModel(idx, T, SOC)
            idx += 1
        var s: lifetime_state = self.cal_model.get_state()
        var tol: Float64 = self.tol
        assert abs(s.day_age_of_battery - 8333.29) <= tol
        assert abs(s.calendar.q_relative_calendar - 97.67) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0.043) <= tol
        self.cal_model.replaceBattery(5)
        s = self.cal_model.get_state()
        assert abs(s.day_age_of_battery - 0) <= tol
        assert abs(s.calendar.q_relative_calendar - 102) <= tol
        assert abs(s.calendar.dq_relative_calendar_old - 0.0) <= tol

    def TestLifetimeDegradation(inout self):
        for idx in range(8760):
            self.cal_model.runLifetimeCalendarModel(idx, 20, 80)
        assert abs(self.cal_model.capacity_percent() - 99.812) <= 1
        self.dt_hour = 1.0 / 12.0
        var subhourly_lifetime = lifetime_calendar_t(self.dt_hour)
        for idx in range(8760 * 12):
            subhourly_lifetime.runLifetimeCalendarModel(idx, 20, 80)
        assert abs(subhourly_lifetime.capacity_percent() - 99.812) <= 1

# ----------------------------------------------------------------------
# Fixture for combined cycle+calendar test

class lib_battery_lifetime_test:
    var model: lifetime_calendar_cycle_t
    var cycles_vs_DOD: matrix_t[Float64]
    var dt_hour: Float64 = 1

    def __init__(inout self):

    def SetUp(inout self):
        var table_vals = List[Float64](20, 0, 100, 20, 5000, 80, 20, 10000, 60, 80, 0, 100, 80, 1000, 80, 80, 2000, 60)
        self.cycles_vs_DOD.assign(table_vals, 6, 3)
        self.model = lifetime_calendar_cycle_t(self.cycles_vs_DOD, self.dt_hour, 1.02, 2.66e-3, -7280, 930)

    def updateCapacityTest(inout self):
        var idx: Int = 0
        while idx < 876:
            self.model.runLifetimeModels(idx, True, 5, 95, 25)
            self.model.runLifetimeModels(idx, True, 95, 5, 25)
            var state = self.model.get_state()
            assert state.cycle.q_relative_cycle == self.model.capacity_percent_cycle()
            assert state.calendar.q_relative_calendar == self.model.capacity_percent_calendar()
            idx += 1

    def runCycleLifetimeTestWithRestPeriod(inout self):
        var tol: Float64 = 0.01
        var DOD = List[Float64](5, 50, 95, 50, 5, 5, 5, 50, 95, 50, 5, 5, 5, 50, 95, 50, 5)
        var charge_changed = List[Bool](True, False, False, True, False, False, False, True, False, True, False, False, False, True, False, True, False)
        var idx: Int = 0
        var T_battery: Float64 = 25
        while idx < len(DOD):
            var DOD_prev: Float64 = 0
            if idx > 0:
                DOD_prev = DOD[idx - 1]
            self.model.runLifetimeModels(idx, charge_changed[idx], DOD_prev, DOD[idx], T_battery)
            idx += 1
        var s: lifetime_state = self.model.get_state()
        assert abs(s.cycle.q_relative_cycle - 99.96) <= tol
        assert abs(s.cycle.rainflow_Xlt - 90) <= tol
        assert abs(s.cycle.rainflow_Ylt - 90) <= tol
        assert abs(s.cycle.rainflow_jlt - 2) <= tol
        assert abs(s.range - 90) <= tol
        assert abs(s.average_range - 90) <= tol
        assert abs(Float64(s.n_cycles) - 2) <= tol

# ----------------------------------------------------------------------
# Fixture for NMC test

class lib_battery_lifetime_nmc_test:
    var model: lifetime_nmc_t
    var dt_hour: Float64 = 1

    def __init__(inout self):

    def SetUp(inout self):
        self.model = lifetime_nmc_t(self.dt_hour)

    def InitTest(inout self):
        var tol: Float64 = 0.001
        var lifetime_state = self.model.get_state()
        assert abs(lifetime_state.nmc_li_neg.q_relative_neg - 100.853) <= tol
        assert abs(lifetime_state.nmc_li_neg.q_relative_li - 107.142) <= tol
        assert self.model.get_state().day_age_of_battery == 0
        assert self.model.get_state().n_cycles == 0
        assert abs(self.model.calculate_Uneg(0.1) - 0.242) <= tol
        assert abs(self.model.calculate_Voc(0.1) - 3.4679) <= tol
        assert abs(self.model.calculate_Uneg(0.5) - 0.1726) <= tol
        assert abs(self.model.calculate_Voc(0.5) - 3.6912) <= tol
        assert abs(self.model.calculate_Uneg(0.9) - 0.1032) <= tol
        assert abs(self.model.calculate_Voc(0.9) - 4.0818) <= tol

    def StorageDays(inout self):
        var days = List[Float64](0, 10, 50, 500, 5000)
        var expected_q_li = List[Float64](106.50, 104.36, 103.97, 103.72, 102.93)
        for i in range(Int(days.back()) + 1):
            for h in range(24):
                var hr: Int = i * 24 + h
                self.model.runLifetimeModels(hr, False, 50, 50, 25)
            var pos = days.find(Float64(i))
            if pos != -1:
                var state = self.model.get_state()
                assert abs(state.nmc_li_neg.q_relative_li - expected_q_li[pos]) <= 0.5
        assert Int(self.model.get_state().day_age_of_battery) == 5001

    def StorageMinuteTimestep(inout self):
        var dt_hr: Float64 = 1.0 / 60
        self.model = lifetime_nmc_t(dt_hr)
        var days = List[Float64](0, 10, 50, 500, 5000)
        var expected_q_li = List[Float64](106.50, 104.36, 103.97, 103.72, 102.93)
        var steps_per_day = Int(24 / dt_hr)
        for i in range(Int(days.back()) + 1):
            for h in range(steps_per_day):
                var hr: Int = i * steps_per_day + h
                self.model.runLifetimeModels(hr, False, 50, 50, 25)
            var pos = days.find(Float64(i))
            if pos != -1:
                var state = self.model.get_state()
                assert abs(state.nmc_li_neg.q_relative_li - expected_q_li[pos]) <= 0.5
        assert Int(self.model.get_state().day_age_of_battery) == 5001

    def StorageTemp(inout self):
        var temps = List[Float64](0, 10, 15, 40)
        var expected_q_li = List[Float64](81.73, 93.08, 97.43, 102.33)
        for n in range(3, len(temps)):
            self.model = lifetime_nmc_t(self.dt_hour)
            for d in range(5000 + 1):
                for h in range(24):
                    var hr: Int = d * 24 + h
                    self.model.runLifetimeModels(hr, False, 50, 50, temps[n])
            var state = self.model.get_state()
            assert abs(Float64(Int(state.nmc_li_neg.q_relative_li)) - expected_q_li[n]) <= 1

    def CyclingHighDOD(inout self):
        var day: Int = 0
        var T: Float64 = 25.15
        while day < 87:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 90, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 90, 10, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 10, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        var state = self.model.get_state()
        assert state.n_cycles == 86
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 103.23) <= 0.5
        assert abs(state.nmc_li_neg.q_relative_neg - 100.6) <= 0.5
        assert abs(state.day_age_of_battery - 87) <= 1e-3
        while day < 870:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 90, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 90, 10, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 10, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 869
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 99.6) <= 0.5
        assert abs(state.nmc_li_neg.q_relative_neg - 98.00) <= 0.5
        assert abs(state.day_age_of_battery - 870) <= 1e-3
        while day < 8700:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 90, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 90, 10, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 10, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 8699
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 84.19) <= 3
        assert abs(state.nmc_li_neg.q_relative_neg - 67.00) <= 0.5
        assert abs(state.day_age_of_battery - 8700) <= 1e-3

    def CyclingHighTemp(inout self):
        var day: Int = 0
        var T: Float64 = 35.0
        while day < 87:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 70, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 70, 30, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 30, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        var state = self.model.get_state()
        assert state.n_cycles == 86
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 105.45) <= 0.6
        assert abs(state.nmc_li_neg.q_relative_neg - 103.79) <= 0.5
        assert abs(state.day_age_of_battery - 87) <= 1e-3
        while day < 870:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 70, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 70, 30, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 30, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 869
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 103.49) <= 0.5
        assert abs(state.nmc_li_neg.q_relative_neg - 103.35) <= 0.5
        assert abs(state.day_age_of_battery - 870) <= 1e-3
        while day < 8700:
            for i in range(24):
                var idx: Int = day * 24 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 70, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 70, 30, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 30, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 8699
        assert state.nmc_li_neg.DOD_max == 50
        assert abs(state.nmc_li_neg.q_relative_li - 92.38) <= 0.5
        assert abs(state.nmc_li_neg.q_relative_neg - 98.93) <= 0.5
        assert abs(state.day_age_of_battery - 8700) <= 1e-3

    def CyclingCRate(inout self):
        var day: Int = 0
        var DODs_day = List[Float64](50.0, 56.67, 63.33, 70.0, 76.67, 83.33, 90.0, 83.33, 76.67, 70.0, 63.33, 56.67, 50.0, 43.33, 36.67, 30.0, 23.33, 16.67, 10.0, 16.67, 23.33, 30.0, 36.67, 43.33)
        while day < 87:
            for i in range(len(DODs_day)):
                var idx: Int = day * 24 + i
                var charge_changed = (i == 7) or (i == 19)
                var prev_DOD = DODs_day[i % 24]
                var DOD = DODs_day[i]
                self.model.runLifetimeModels(idx, charge_changed, prev_DOD, DOD, 25)
            day += 1
        var state = self.model.get_state()
        assert state.n_cycles == 86
        assert state.nmc_li_neg.DOD_max == 43.33
        assert abs(state.nmc_li_neg.q_relative_li - 103) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 100) <= 1
        assert abs(state.day_age_of_battery - 87) <= 1e-3
        while day < 870:
            for i in range(len(DODs_day)):
                var idx: Int = day * 24 + i
                var charge_changed = (i == 7) or (i == 19)
                var prev_DOD = DODs_day[i % 24]
                var DOD = DODs_day[i]
                self.model.runLifetimeModels(idx, charge_changed, prev_DOD, DOD, 25)
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 869
        assert state.nmc_li_neg.DOD_max == 43.33
        assert abs(state.nmc_li_neg.q_relative_li - 97.61) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 98) <= 1
        assert abs(state.day_age_of_battery - 870) <= 1e-3

    def CyclingCRateMinuteTimestep(inout self):
        var dt_hr: Float64 = 1.0 / 60
        var steps_per_day = Int(24 / dt_hr)
        self.model = lifetime_nmc_t(dt_hr)
        var day: Int = 0
        var idx: Int = 0
        var DODs_day = List[Float64](50.0, 56.67, 63.33, 70.0, 76.67, 83.33, 90.0, 83.33, 76.67, 70.0, 63.33, 56.67, 50.0, 43.33, 36.67, 30.0, 23.33, 16.67, 10.0, 16.67, 23.33, 30.0, 36.67, 43.33)
        while day < 87:
            for hr in range(len(DODs_day)):
                var prev_DOD = DODs_day[hr % 24]
                var DOD = DODs_day[hr]
                for min in range(Int(1.0 / dt_hr)):
                    var charge_changed = (hr == 7 or hr == 19) and min == 0
                    if min != 0:
                        prev_DOD = DOD
                    self.model.runLifetimeModels(idx, charge_changed, prev_DOD, DOD, 25)
                    idx += 1
            day += 1
        var state = self.model.get_state()
        assert state.n_cycles == 86
        assert state.nmc_li_neg.DOD_max == 43.33
        assert abs(state.nmc_li_neg.q_relative_li - 103) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 100) <= 1
        assert abs(state.day_age_of_battery - 87) <= 1e-3
        while day < 870:
            for hr in range(len(DODs_day)):
                var prev_DOD = DODs_day[hr % 24]
                var DOD = DODs_day[hr]
                for min in range(Int(1.0 / dt_hr)):
                    var charge_changed = (hr == 7 or hr == 19) and min == 0
                    if min != 0:
                        prev_DOD = DOD
                    self.model.runLifetimeModels(idx, charge_changed, prev_DOD, DOD, 25)
                    idx += 1
            day += 1
        state = self.model.get_state()
        assert state.n_cycles == 869
        assert state.nmc_li_neg.DOD_max == 43.33
        assert abs(state.nmc_li_neg.q_relative_li - 97.61) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 98) <= 1
        assert abs(state.day_age_of_battery - 870) <= 1e-3

    def CyclingEveryTwoDays(inout self):
        var T: Float64 = 25.15
        var day: Int = 0
        while day < 87:
            for i in range(48):
                var idx: Int = day * 48 + i
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 10, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 10, 90, T)
                elif i == 46:
                    self.model.runLifetimeModels(idx, True, 90, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
            day += 2
        var state = self.model.get_state()
        assert state.n_cycles == 43
        assert abs(state.nmc_li_neg.q_relative_li - 103.29) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 100.6) <= 0.5
        assert abs(state.day_age_of_battery - 88) <= 1e-3

    def IrregularTimeStep(inout self):
        var T: Float64 = 35.15
        var state = self.model.get_state()
        assert abs(state.nmc_li_neg.q_relative_li - 106.213) <= 1
        assert abs(state.nmc_li_neg.q_relative_neg - 100.6) <= 0.5
        var b_params = lifetime_params(self.model.get_params())
        b_params.dt_hr = 0.5
        var b_state = lifetime_state(self.model.get_state())
        var subhourly_model = lifetime_nmc_t(b_params, b_state)
        var day: Int = 0
        while day < 87:
            var idx: Int = 0
            while idx < 48:
                var i: Int = idx % 24
                if i == 0:
                    self.model.runLifetimeModels(idx, False, 50, 70, T)
                elif i == 1:
                    self.model.runLifetimeModels(idx, True, 70, 30, T)
                elif i == 3:
                    self.model.runLifetimeModels(idx, True, 30, 50, T)
                else:
                    self.model.runLifetimeModels(idx, False, 50, 50, T)
                idx += 1
            day += 2
        state = self.model.get_state()
        assert state.n_cycles == 87
        assert abs(state.nmc_li_neg.q_relative_li - 105.966) <= 1e-3
        assert abs(state.nmc_li_neg.q_relative_neg - 103.829) <= 1e-3
        assert abs(state.day_age_of_battery - 88) <= 1e-3
        print()
        day = 0
        while day < 87:
            var idx: Int = 0
            while idx < Int(23.5 * 2):
                var i: Int = idx
                if i <= 1:
                    subhourly_model.runLifetimeModels(idx, False, 50, 70, T)
                elif i <= 3:
                    subhourly_model.runLifetimeModels(idx, i == 2, 70, 30, T)
                elif i == 6 or i == 7:
                    subhourly_model.runLifetimeModels(idx, i == 6, 30, 50, T)
                else:
                    subhourly_model.runLifetimeModels(idx, False, 50, 50, T)
                idx += 1
            b_params.dt_hr = 1
            b_state = lifetime_state(subhourly_model.get_state())
            subhourly_model = lifetime_nmc_t(b_params, b_state)
            idx = 0
            while idx < 24:
                var i: Int = idx % 24
                if i == 0:
                    subhourly_model.runLifetimeModels(idx, False, 50, 70, T)
                elif i == 1:
                    subhourly_model.runLifetimeModels(idx, True, 70, 30, T)
                elif i == 3:
                    subhourly_model.runLifetimeModels(idx, True, 30, 50, T)
                else:
                    subhourly_model.runLifetimeModels(idx, False, 50, 50, T)
                idx += 1
            b_params.dt_hr = 0.5
            b_state = lifetime_state(subhourly_model.get_state())
            subhourly_model = lifetime_nmc_t(b_params, b_state)
            subhourly_model.runLifetimeModels(idx, False, 50, 50, T)
            day += 2
        state = subhourly_model.get_state()
        assert state.n_cycles == 87
        assert abs(state.nmc_li_neg.q_relative_li - 105.965) <= 1e-3
        assert abs(state.nmc_li_neg.q_relative_neg - 103.829) <= 1e-3
        assert abs(state.day_age_of_battery - 88) <= 1e-3