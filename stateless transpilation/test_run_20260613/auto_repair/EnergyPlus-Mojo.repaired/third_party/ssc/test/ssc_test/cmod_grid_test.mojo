from gtest import Test, TestWithParam, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR
from cmod_grid_test import CMGrid_cmod_grid
from grid_common_data import grid_default_60_min, grid_default_30_min, grid_default_30_min_lifetime, grid_default_60_min_no_financial
from sscapi import ssc_data_get_number, ssc_data_get_array, run_module

@register_test
class CMGrid_cmod_grid(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]
    var m_error_tolerance_hi: Float64 = 1.0
    var m_error_tolerance_lo: Float64 = 0.1
    var interval: Int = 100

    def SetUp(self):
        self.data = ssc_data_create()

    def TearDown(self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None

    def SetCalculated(self, name: String):
        ssc_data_get_number(self.data, name, self.calculated_value)

    def SetCalculatedArray(self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, n)

    def GetArray(self, name: String, n: Int) -> Pointer[ssc_number_t]:
        var ret: Pointer[ssc_number_t] = ssc_data_get_array(self.data, name, n)
        return ret

def test_SingleYearHourly_cmod_grid():
    var data: ssc_data_t
    grid_default_60_min(data)
    var errors: Int = run_module(data, "grid")
    EXPECT_FALSE(errors)
    if not errors:
        var capacity_factor: ssc_number_t
        var annual_energy_pre_interconnect: ssc_number_t
        var annual_energy_interconnect: ssc_number_t
        var gen_size: Int
        ssc_data_get_number(data, "capacity_factor_interconnect_ac", capacity_factor)
        ssc_data_get_number(data, "annual_energy_pre_interconnect_ac", annual_energy_pre_interconnect)
        ssc_data_get_number(data, "annual_energy", annual_energy_interconnect)
        var system_kwac: Pointer[ssc_number_t] = GetArray(data, "gen", gen_size)
        var system_pre_interconnect_kwac: Pointer[ssc_number_t] = GetArray(data, "system_pre_interconnect_kwac", gen_size)
        EXPECT_EQ(gen_size, 8760)
        EXPECT_NEAR(capacity_factor, 29.0167, 0.001)
        EXPECT_NEAR(annual_energy_interconnect, 457534759, 10)
        EXPECT_NEAR(annual_energy_pre_interconnect, 460351000, 10)

def test_SingleYearSubHourly_cmod_grid():
    var data: ssc_data_t
    grid_default_30_min(data)
    var errors: Int = run_module(data, "grid")
    EXPECT_FALSE(errors)
    if not errors:
        var capacity_factor: ssc_number_t
        var annual_energy_pre_interconnect: ssc_number_t
        var annual_energy: ssc_number_t
        var annual_energy_pre_curtailment_ac: ssc_number_t
        var gen_size: Int
        ssc_data_get_number(data, "capacity_factor_interconnect_ac", capacity_factor)
        ssc_data_get_number(data, "annual_energy_pre_interconnect_ac", annual_energy_pre_interconnect)
        ssc_data_get_number(data, "annual_energy", annual_energy)
        ssc_data_get_number(data, "annual_energy_pre_curtailment_ac", annual_energy_pre_curtailment_ac)
        var system_kwac: Pointer[ssc_number_t] = GetArray(data, "gen", gen_size)
        var system_pre_interconnect_kwac: Pointer[ssc_number_t] = GetArray(data, "system_pre_interconnect_kwac", gen_size)
        EXPECT_EQ(gen_size, 8760*2)
        EXPECT_NEAR(capacity_factor, 30.78777, 0.001)
        EXPECT_NEAR(annual_energy, 485461500, 10)
        EXPECT_NEAR(annual_energy_pre_interconnect, 498820000, 10)
        EXPECT_NEAR(annual_energy_pre_curtailment_ac, 485461500, 10)

def test_SingleYearSubHourlyLifetime_cmod_grid():
    var data: ssc_data_t
    grid_default_30_min_lifetime(data)
    var errors: Int = run_module(data, "grid")
    EXPECT_FALSE(errors)
    if not errors:
        var capacity_factor: ssc_number_t
        var annual_energy_pre_interconnect: ssc_number_t
        var annual_energy_interconnect: ssc_number_t
        var gen_size: Int
        ssc_data_get_number(data, "capacity_factor_interconnect_ac", capacity_factor)
        ssc_data_get_number(data, "annual_energy_pre_interconnect_ac", annual_energy_pre_interconnect)
        ssc_data_get_number(data, "annual_energy", annual_energy_interconnect)
        var system_kwac: Pointer[ssc_number_t] = GetArray(data, "gen", gen_size)
        var system_pre_interconnect_kwac: Pointer[ssc_number_t] = GetArray(data, "system_pre_interconnect_kwac", gen_size)
        EXPECT_EQ(gen_size, 8760 * 2 * 2)
        EXPECT_NEAR(capacity_factor, 30.78777, 0.001)
        EXPECT_NEAR(annual_energy_interconnect, 485461500, 10)
        EXPECT_NEAR(annual_energy_pre_interconnect, 498820000, 10)

def test_SingleYearNoFinancial_cmod_grid():
    var data: ssc_data_t
    grid_default_60_min_no_financial(data)
    var errors: Int = run_module(data, "grid")
    EXPECT_FALSE(errors)
    if not errors:
        var capacity_factor: ssc_number_t
        var annual_energy_pre_interconnect: ssc_number_t
        var annual_energy_interconnect: ssc_number_t
        var gen_size: Int
        ssc_data_get_number(data, "capacity_factor_interconnect_ac", capacity_factor)
        ssc_data_get_number(data, "annual_energy_pre_interconnect_ac", annual_energy_pre_interconnect)
        ssc_data_get_number(data, "annual_energy", annual_energy_interconnect)
        var system_kwac: Pointer[ssc_number_t] = GetArray(data, "gen", gen_size)
        var system_pre_interconnect_kwac: Pointer[ssc_number_t] = GetArray(data, "system_pre_interconnect_kwac", gen_size)
        EXPECT_EQ(gen_size, 8760)
        EXPECT_NEAR(capacity_factor, 29.0167, 0.001)
        EXPECT_NEAR(annual_energy_interconnect, 457534759, 10)
        EXPECT_NEAR(annual_energy_pre_interconnect, 460351000, 10)