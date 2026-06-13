from lib_util import *
from lib_time import *
from math import sin, pow
from testing import *

struct libTimeTest_lib_time(Test):
    var is_lifetime: Bool
    var n_years: Int
    var increment: Int
    var lifetime60min: List[Float32]
    var lifetime30min: List[Float32]
    var singleyear60min: List[Float32]
    var singleyear30min: List[Float32]
    var scaleFactors: List[Float32]
    var sched: Pointer[Int]
    var schedule: matrix_t[Int]
    var sched_values: List[Float64] = List[Float64](0.1, 0.0, 0.3)
    var multiplier: Float64 = 2.0
    var interpolation_factor: Float64 = 1.0

    def __init__(inout self):
        self.is_lifetime = True
        self.n_years = 25
        self.increment = 500
        self.lifetime60min = List[Float32]()
        self.lifetime60min.reserve(self.n_years * hours_per_year)
        for i in range(self.n_years * hours_per_year):
            self.lifetime60min.push_back(0.0)
        self.lifetime30min = List[Float32]()
        self.lifetime30min.reserve(2 * self.n_years * hours_per_year)
        for i in range(self.n_years * 2 * hours_per_year):
            self.lifetime30min.push_back(0.0)
        self.singleyear60min = List[Float32]()
        self.singleyear60min.reserve(hours_per_year)
        for i in range(hours_per_year):
            self.singleyear60min.push_back(100.0 * sin(Float64(i)))
        self.singleyear30min = List[Float32]()
        self.singleyear30min.reserve(hours_per_year * 2)
        for i in range(hours_per_year * 2):
            self.singleyear30min.push_back(100.0 * sin(Float64(i)))
        self.scaleFactors = List[Float32]()
        self.scaleFactors.reserve(self.n_years)
        for i in range(self.n_years):
            self.scaleFactors.push_back(1.0)
        self.sched = Pointer[Int].alloc(24 * 12)
        var i: Int = 0
        for m in range(12):
            for h in range(24):
                self.sched[i] = 1
                if h > 11 and h < 19:
                    self.sched[i] = 3
                i += 1
        self.schedule = matrix_t[Int]()
        self.schedule.assign(self.sched, 12, 24)

    def __del__(owned self):
        del self.sched

    @staticmethod
    def SetUp(inout self):

def single_year_to_lifetime_interpolated_SingleYear_1(inout self: libTimeTest_lib_time):
    self.is_lifetime = False
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.singleyear60min.size
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear60min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_equal(lifetime_from_single[i], self.singleyear60min[i])

def single_year_to_lifetime_interpolated_Lifetime_2(inout self: libTimeTest_lib_time):
    self.is_lifetime = True
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.lifetime30min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear60min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * 2 * self.n_years)
    assert_equal(n_rec_singleyear, hours_per_year * 2)
    assert_equal(dt_hour, 0.5)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for y in range(self.n_years):
        var idx: Int = y * self.singleyear60min.size()
        for i in range(0, self.singleyear60min.size(), self.increment):
            assert_equal(lifetime_from_single[idx*2], self.singleyear60min[i])
            idx += self.increment

def single_year_to_lifetime_interpolated_SingleYear_3(inout self: libTimeTest_lib_time):
    self.is_lifetime = False
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.singleyear60min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear60min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_equal(lifetime_from_single[i], self.singleyear60min[i])

def single_year_to_lifetime_with_escalation_4(inout self: libTimeTest_lib_time):
    self.is_lifetime = True
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = hours_per_year * self.n_years
    var n_rec_singleyear: Int
    var load_scale: List[Float32] = List[Float32]()
    load_scale.reserve(self.n_years)
    for i in range(self.n_years):
        load_scale.push_back(pow(Float64(1 + 2.5 * 0.01), Float64(i)))
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear60min, load_scale, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * self.n_years)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_almost_equal(lifetime_from_single[i + n_rec_singleyear], self.singleyear60min[i] * 1.025, 0.0001)

def single_year_to_lifetime_interpolated_SingleValue_5(inout self: libTimeTest_lib_time):
    self.is_lifetime = False
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = 8760
    var n_rec_singleyear: Int
    var single_val: List[Float32] = List[Float32](1.0)
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, single_val, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_equal(lifetime_from_single[i], 1.0)

def single_year_to_lifetime_interpolated_SingleYearSubhourly_6(inout self: libTimeTest_lib_time):
    self.is_lifetime = False
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.singleyear30min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear30min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * 2)
    assert_equal(n_rec_singleyear, hours_per_year * 2)
    assert_equal(dt_hour, 0.5)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_equal(lifetime_from_single[i], self.singleyear30min[i])

def single_year_to_lifetime_interpolated_LifetimeSubhourly_7(inout self: libTimeTest_lib_time):
    self.is_lifetime = True
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.lifetime30min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear30min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * 2 * self.n_years)
    assert_equal(n_rec_singleyear, hours_per_year * 2)
    assert_equal(dt_hour, 0.5)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for y in range(self.n_years):
        var idx: Int = y * self.singleyear30min.size()
        for i in range(0, self.singleyear30min.size(), self.increment):
            assert_equal(lifetime_from_single[idx], self.singleyear30min[i])
            idx += self.increment

def single_year_to_lifetime_interpolated_DownsampleLifetime_8(inout self: libTimeTest_lib_time):
    self.is_lifetime = True
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.lifetime60min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear30min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * self.n_years)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for y in range(self.n_years):
        var idx: Int = y * self.singleyear60min.size()
        for i in range(0, n_rec_singleyear, self.increment):
            assert_equal(lifetime_from_single[idx], self.singleyear30min[i*2])
            idx += self.increment

def single_year_to_lifetime_interpolated_DownsampleLifetime_w_interpolation_9(inout self: libTimeTest_lib_time):
    self.is_lifetime = True
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.lifetime60min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    self.interpolation_factor = 1.0 / 2.0
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear30min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year * self.n_years)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for y in range(self.n_years):
        var idx: Int = y * self.singleyear60min.size()
        for i in range(0, n_rec_singleyear, self.increment):
            assert_equal(lifetime_from_single[idx], self.singleyear30min[i * 2] / self.interpolation_factor)
            idx += self.increment

def single_year_to_lifetime_interpolated_DownsampleSingleYear_10(inout self: libTimeTest_lib_time):
    self.is_lifetime = False
    var lifetime_from_single: List[Float32] = List[Float32]()
    var n_rec_lifetime: Int = self.singleyear60min.size()
    var n_rec_singleyear: Int
    var dt_hour: Float64
    single_year_to_lifetime_interpolated[Float32](self.is_lifetime, self.n_years, n_rec_lifetime, self.singleyear30min, self.scaleFactors, self.interpolation_factor, lifetime_from_single, n_rec_singleyear, dt_hour)
    assert_equal(n_rec_lifetime, hours_per_year)
    assert_equal(n_rec_singleyear, hours_per_year)
    assert_equal(dt_hour, 1.0)
    assert_equal(lifetime_from_single.size(), n_rec_lifetime)
    for i in range(0, n_rec_singleyear, self.increment):
        assert_equal(lifetime_from_single[i], self.singleyear30min[i*2])

def flatten_diurnal_Schedule_11(inout self: libTimeTest_lib_time):
    var flat: List[Float64] = flatten_diurnal(self.schedule, self.schedule, 1, self.sched_values, self.multiplier)
    var flat30min: List[Float64] = flatten_diurnal(self.schedule, self.schedule, 2, self.sched_values, self.multiplier)
    assert_equal(flat.size(), hours_per_year)
    assert_equal(flat30min.size(), hours_per_year * 2)
    for h in range(flat.size()):
        if h % 24 > 11 and h % 24 < 19:
            assert_almost_equal(flat[h], 0.6, 0.0001)
        else:
            assert_almost_equal(flat[h], 0.2, 0.0001)
    var i: Int = 0
    for h in range(hours_per_year):
        for s in range(2):
            if h % 24 > 11 and h % 24 < 19:
                assert_almost_equal(flat30min[i], 0.6, 0.0001)
            else:
                assert_almost_equal(flat30min[i], 0.2, 0.0001)
            i += 1

def flatten_diurnal_ScheduleTOD_12(inout self: libTimeTest_lib_time):
    var flat: List[Float64] = flatten_diurnal(self.schedule, self.schedule, 1, self.sched_values, self.multiplier)
    assert_equal(flat.size(), hours_per_year)
    for h in range(flat.size()):
        if h % 24 > 11 and h % 24 < 19:
            assert_almost_equal(flat[h], 0.6, 0.0001)
        else:
            assert_almost_equal(flat[h], 0.2, 0.0001)

def TestDiurnalToFlat_13(inout self: libTimeTest_lib_time):
    var wk: List[Int] = List[Int](6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6)
    var we: List[Int] = List[Int](6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 8, 8, 8, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 3, 3, 3, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 6, 6, 6)
    var weekday: matrix_t[Int] = matrix_t[Int](12, 24, &wk)
    var weekend: matrix_t[Int] = matrix_t[Int](12, 24, &we)
    var sched_values: List[Float64] = List[Float64](2.2304, 0.8067, 0.9569, 1.1982, 0.7741, 0.9399, 1.1941, 0.6585, 0.9299)
    var flat: List[Float64] = flatten_diurnal(weekday, weekend, 1, sched_values, 1.0)
    assert_equal(flat.size(), hours_per_year)

def main():
    var test_obj = libTimeTest_lib_time()
    test_obj.SetUp()
    single_year_to_lifetime_interpolated_SingleYear_1(test_obj)
    single_year_to_lifetime_interpolated_Lifetime_2(test_obj)
    single_year_to_lifetime_interpolated_SingleYear_3(test_obj)
    single_year_to_lifetime_with_escalation_4(test_obj)
    single_year_to_lifetime_interpolated_SingleValue_5(test_obj)
    single_year_to_lifetime_interpolated_SingleYearSubhourly_6(test_obj)
    single_year_to_lifetime_interpolated_LifetimeSubhourly_7(test_obj)
    single_year_to_lifetime_interpolated_DownsampleLifetime_8(test_obj)
    single_year_to_lifetime_interpolated_DownsampleLifetime_w_interpolation_9(test_obj)
    single_year_to_lifetime_interpolated_DownsampleSingleYear_10(test_obj)
    flatten_diurnal_Schedule_11(test_obj)
    flatten_diurnal_ScheduleTOD_12(test_obj)
    TestDiurnalToFlat_13(test_obj)