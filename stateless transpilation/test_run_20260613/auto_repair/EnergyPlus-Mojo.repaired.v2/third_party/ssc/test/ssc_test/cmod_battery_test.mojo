from gtest import Test, TestInfo, AssertionResult, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_GT, EXPECT_LT, EXPECT_LE, EXPECT_GE
from core import *
from sscapi import *
from vartab import *
from ...ssc.common import *
from ...input_cases.code_generator_utilities import *
from ...input_cases.battery_common_data import *
from memory import pointer
from numeric import accumulate, max_element
from vector import DynamicVector

struct CMBattery_cmod_battery(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]
    var m_error_tolerance_hi: Float64 = 1.0
    var m_error_tolerance_lo: Float64 = 0.1

    def SetUp(inout self):
        self.data = ssc_data_create()
        battery_commercial_peak_shaving_lifetime(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None

    def SetCalculated(inout self, name: String):
        ssc_data_get_number(self.data, name, pointer(self.calculated_value))

    def SetCalculatedArray(inout self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, pointer(n))

def test_CommercialLifetimePeakShaving(inout self: CMBattery_cmod_battery):
    var n_years: ssc_number_t
    ssc_data_get_number(self.data, "analysis_period", pointer(n_years))
    var n_lifetime: Int = Int(n_years) * 8760
    var errors: Int = run_module(self.data, "battery")
    EXPECT_FALSE(errors)
    if not errors:
        var roundtripEfficiency: ssc_number_t
        ssc_data_get_number(self.data, "average_battery_roundtrip_efficiency", pointer(roundtripEfficiency))
        EXPECT_NEAR(roundtripEfficiency, 94.42, 2)
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, "gen", pointer(n))
        EXPECT_EQ(n_lifetime, n)
        self.calculated_array = ssc_data_get_array(self.data, "batt_bank_replacement", pointer(n))
        var replacements: Int = accumulate(self.calculated_array, self.calculated_array + n, 0)
        EXPECT_GT(replacements, 0)
        var arr: Pointer[Float64] = ssc_data_get_array(self.data, "batt_temperature", pointer(n))
        var temp_array = DynamicVector[Float64](arr, arr + n)
        var max_temp: Float64 = max_element(temp_array.begin(), temp_array.end())
        EXPECT_NEAR(max_temp, 33, 1)

def test_ResilienceMetricsFullLoad(inout self: CMBattery_cmod_battery):
    var data_vtab = Pointer[var_table](self.data).value
    data_vtab.assign("crit_load", data_vtab.as_vector_ssc_number_t("load"))
    data_vtab.assign("system_use_lifetime_output", 0)
    data_vtab.assign("analysis_period", 1)
    data_vtab.assign("gen", var_data(data_vtab.as_array("gen", None), 8760))
    data_vtab.assign("batt_replacement_option", 0)
    var errors: Int = run_module(self.data, "battery")
    EXPECT_FALSE(errors)
    var resilience_hours = data_vtab.as_vector_ssc_number_t("resilience_hrs")
    var resilience_hrs_min: Float64 = data_vtab.as_number("resilience_hrs_min")
    var resilience_hrs_max: Float64 = data_vtab.as_number("resilience_hrs_max")
    var resilience_hrs_avg: Float64 = data_vtab.as_number("resilience_hrs_avg")
    var outage_durations = data_vtab.as_vector_ssc_number_t("outage_durations")
    var pdf_of_surviving = data_vtab.as_vector_ssc_number_t("pdf_of_surviving")
    var avg_critical_load: Float64 = data_vtab.as_double("avg_critical_load")
    EXPECT_EQ(resilience_hours[0], 0)
    EXPECT_EQ(resilience_hours[1], 1)
    EXPECT_NEAR(avg_critical_load, 979.67, 0.1)
    EXPECT_NEAR(resilience_hrs_avg, 1.34, 0.01)
    EXPECT_EQ(resilience_hrs_min, 0)
    EXPECT_EQ(outage_durations[0], 0)
    EXPECT_EQ(resilience_hrs_max, 23)
    EXPECT_EQ(outage_durations[17], 17)
    EXPECT_NEAR(pdf_of_surviving[0], 0.629, 1e-3)
    EXPECT_NEAR(pdf_of_surviving[1], 0.118, 1e-3)
    var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
    var power_max: Float64 = max_element(batt_power.begin(), batt_power.end())
    EXPECT_NEAR(power_max, 167.28, 1e-2)
    var max_indices = DynamicVector[Int]()
    for i in range(batt_power.size):
        if power_max - batt_power[i] < 0.1:
            max_indices.push_back(i)
    EXPECT_EQ(max_indices.size, 3)
    EXPECT_EQ(max_indices[0], 3631)
    var batt_q0 = data_vtab.as_vector_ssc_number_t("batt_q0")
    var cap_max: Float64 = max_element(batt_q0.begin(), batt_q0.end())
    EXPECT_NEAR(cap_max, 11540, 10)
    max_indices.clear()
    for i in range(batt_q0.size):
        if cap_max - batt_q0[i] < 0.01:
            max_indices.push_back(i)
    EXPECT_EQ(max_indices[0], 2)

def test_ResilienceMetricsFullLoadLifetime(inout self: CMBattery_cmod_battery):
    var nyears: Int = 3
    var data_vtab = Pointer[var_table](self.data).value
    data_vtab.assign("crit_load", data_vtab.as_vector_ssc_number_t("load"))
    data_vtab.assign("system_use_lifetime_output", 1)
    data_vtab.assign("analysis_period", nyears)
    data_vtab.assign("gen", var_data(data_vtab.as_array("gen", None), 8760 * nyears))
    data_vtab.assign("batt_replacement_option", 0)
    var errors: Int = run_module(self.data, "battery")
    EXPECT_FALSE(errors)
    var resilience_hours = data_vtab.as_vector_ssc_number_t("resilience_hrs")
    var resilience_hrs_min: Float64 = data_vtab.as_number("resilience_hrs_min")
    var resilience_hrs_max: Float64 = data_vtab.as_number("resilience_hrs_max")
    var resilience_hrs_avg: Float64 = data_vtab.as_number("resilience_hrs_avg")
    var outage_durations = data_vtab.as_vector_ssc_number_t("outage_durations")
    var pdf_of_surviving = data_vtab.as_vector_ssc_number_t("pdf_of_surviving")
    var avg_critical_load: Float64 = data_vtab.as_double("avg_critical_load")
    EXPECT_EQ(resilience_hours[0], 0)
    EXPECT_EQ(resilience_hours[1], 1)
    EXPECT_NEAR(avg_critical_load, 963.6, 0.1)
    EXPECT_NEAR(resilience_hrs_avg, 1.313, 0.01)
    EXPECT_EQ(resilience_hrs_min, 0)
    EXPECT_EQ(outage_durations[0], 0)
    EXPECT_EQ(resilience_hrs_max, 23)
    EXPECT_EQ(outage_durations[17], 17)
    EXPECT_NEAR(pdf_of_surviving[0], 0.636, 1e-3)
    EXPECT_NEAR(pdf_of_surviving[1], 0.112, 1e-3)
    var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
    var power_max: Float64 = max_element(batt_power.begin(), batt_power.end())
    EXPECT_NEAR(power_max, 167.28, 1e-2)
    var max_indices = DynamicVector[Int]()
    for i in range(batt_power.size):
        if power_max - batt_power[i] < 0.1:
            max_indices.push_back(i)
    EXPECT_EQ(max_indices[0], 3631)
    var batt_q0 = data_vtab.as_vector_ssc_number_t("batt_q0")
    var cap_max: Float64 = max_element(batt_q0.begin(), batt_q0.end())
    EXPECT_NEAR(cap_max, 11540, 10)
    max_indices.clear()
    for i in range(batt_q0.size):
        if cap_max - batt_q0[i] < 0.01:
            max_indices.push_back(i)
    EXPECT_EQ(max_indices[0], 2)