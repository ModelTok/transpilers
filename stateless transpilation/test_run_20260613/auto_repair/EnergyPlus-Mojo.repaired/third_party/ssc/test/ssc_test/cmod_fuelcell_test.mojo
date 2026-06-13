from gtest import Test, TestFixture, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_LT
from core import *
from sscapi import *
from vartab import *
from ...ssc.common import *
from ...input_cases.code_generator_utilities import *
from ...input_cases.battery_common_data import *
from ...input_cases.fuelcell_common_data import *

@value
class CMFuelCell(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]
    var m_error_tolerance_hi: Float64 = 1.0
    var m_error_tolerance_lo: Float64 = 0.1
    var interval: Int = 100

    def SetUp(inout self):
        self.data = ssc_data_create()
        fuelcell_nofinancial_default(self.data)
        battery_commercial_peak_shaving_lifetime(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None

    def SetCalculated(inout self, name: String):
        ssc_data_get_number(self.data, name.c_str(), self.calculated_value)

    def SetCalculatedArray(inout self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name.c_str(), n)

    def GetArray(inout self, name: String, n: Int) -> Pointer[ssc_number_t]:
        var ret = ssc_data_get_array(self.data, name.c_str(), n)
        return ret

def NoFinancialModelFixed_cmod_fuelcell():
    var test = CMFuelCell()
    test.SetUp()
    var errors = run_module(test.data, "fuelcell")
    EXPECT_FALSE(errors)
    if not errors:
        var startup_hours: ssc_number_t
        var fixed_pct: ssc_number_t
        var dynamic_response: ssc_number_t
        ssc_data_get_number(test.data, "fuelcell_startup_time", startup_hours)
        ssc_data_get_number(test.data, "fuelcell_fixed_pct", fixed_pct)
        ssc_data_get_number(test.data, "fuelcell_dynamic_response_up", dynamic_response)
        test.SetCalculatedArray("fuelcell_power")
        for h in range(0, startup_hours):
            EXPECT_EQ(test.calculated_array[h], 0)
        EXPECT_NEAR(test.calculated_array[startup_hours], dynamic_response, 0.1)
        EXPECT_NEAR(test.calculated_array[startup_hours + 1], 2 * dynamic_response, 0.1)
        for h in range(startup_hours + 2, 100):
            EXPECT_NEAR(test.calculated_array[h], fixed_pct, 0.1)
    test.TearDown()

def NoFinancialModelFixedLifetime_cmod_fuelcell():
    var test = CMFuelCell()
    test.SetUp()
    var n_years: ssc_number_t
    ssc_data_get_number(test.data, "analysis_period", n_years)
    var n_lifetime: Int = n_years * 8760
    ssc_data_set_number(test.data, "system_use_lifetime_output", 1)
    var errors = run_module(test.data, "fuelcell")
    EXPECT_FALSE(errors)
    if not errors:
        var startup_hours: ssc_number_t
        var fixed_pct: ssc_number_t
        var dynamic_response: ssc_number_t
        ssc_data_get_number(test.data, "fuelcell_startup_time", startup_hours)
        ssc_data_get_number(test.data, "fuelcell_fixed_pct", fixed_pct)
        ssc_data_get_number(test.data, "fuelcell_dynamic_response", dynamic_response)
        var n: Int
        test.calculated_array = ssc_data_get_array(test.data, "fuelcell_power", n)
        EXPECT_EQ(n_lifetime, n)
    test.TearDown()

def FuelCellBattery_cmod_fuelcell():
    var test = CMFuelCell()
    test.SetUp()
    ssc_data_set_number(test.data, "system_use_lifetime_output", 1)
    var errors = run_module(test.data, "fuelcell")
    EXPECT_FALSE(errors)
    if not errors:
        var errors_battery = run_module(test.data, "battery")
        EXPECT_FALSE(errors_battery)
        if not errors_battery:
            var n: Int
            var fc_to_load = test.GetArray("fuelcell_to_load", n)
            var pv_to_load = test.GetArray("system_to_load", n)
            var batt_to_load = test.GetArray("batt_to_load", n)
            var grid_to_load = test.GetArray("grid_to_load", n)
            var load = test.GetArray("load", n)
            for i in range(0, n, test.interval):
                EXPECT_LT(fabs(load[i] - (fc_to_load[i] + pv_to_load[i] + batt_to_load[i] + grid_to_load[i])), 1.0)
    test.TearDown()