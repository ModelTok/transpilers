#include <gtest/gtest.h>
#include "../input_cases/code_generator_utilities.h"
#include "vartab.h"
#include "cmod_battwatts_test.h"
#include "battwatts_cases.h"
#include "lib_util.h"

struct CMBattwatts_cmod_battwatts:
    var_table data
    vector<double> ac
    vector<double> load
    vector<double> crit_load
    double m_error_tolerance_hi = 1.0
    double m_error_tolerance_lo = 0.1

    def CreateData(nyears: size_t):
        for i in range(8760 * nyears):
            var hr = i % 24
            if hr > 7 and hr < 18:
                ac.push_back(1.0)
            else:
                ac.push_back(0.0)
            load.push_back(0.5)
            crit_load.push_back(0.25)
        data.assign("system_use_lifetime_output", nyears > 1)
        data.assign("analysis_period", int(nyears))
        data.assign("batt_simple_enable", 1)
        data.assign("batt_simple_kwh", 10)
        data.assign("batt_simple_kw", 5)
        data.assign("batt_simple_chemistry", 1)
        data.assign("batt_simple_dispatch", 0)
        data.assign("batt_simple_meter_position", 0)
        data.assign("ac", ac)
        data.assign("load", load)
        data.assign("crit_load", crit_load)
        data.assign("inverter_model", 0)
        data.assign("inverter_efficiency", 96)
    end
end

@Test
def ResilienceMetricsHalfLoad():
    var self = CMBattwatts_cmod_battwatts()
    self.CreateData(1)
    var ssc_dat = static_cast[ssc_data_t](ref self.data)
    var errors = run_module(ssc_dat, "battwatts")
    EXPECT_FALSE(errors)
    var resilience_hours = self.data.as_vector_ssc_number_t("resilience_hrs")
    var resilience_hrs_min = self.data.as_number("resilience_hrs_min")
    var resilience_hrs_max = self.data.as_number("resilience_hrs_max")
    var resilience_hrs_avg = self.data.as_number("resilience_hrs_avg")
    var outage_durations = self.data.as_vector_ssc_number_t("outage_durations")
    var pdf_of_surviving = self.data.as_vector_ssc_number_t("pdf_of_surviving")
    var avg_critical_load = self.data.as_double("avg_critical_load")
    EXPECT_EQ(resilience_hours[0], 16)
    EXPECT_EQ(resilience_hours[1], 16)
    EXPECT_NEAR(avg_critical_load, 8.35, 0.1)
    EXPECT_NEAR(resilience_hrs_avg, 32.68, 0.01)
    EXPECT_EQ(resilience_hrs_min, 16)
    EXPECT_EQ(outage_durations[0], 16)
    EXPECT_EQ(resilience_hrs_max, 33)
    EXPECT_EQ(outage_durations[16], 32)
    EXPECT_NEAR(pdf_of_surviving[0], 0.00205, 1e-3)
    EXPECT_NEAR(pdf_of_surviving[1], 0.00217, 1e-3)
end

@Test
def ResilienceMetricsHalfLoadLifetime():
    var self = CMBattwatts_cmod_battwatts()
    self.CreateData(2)
    var ssc_dat = static_cast[ssc_data_t](ref self.data)
    var errors = run_module(ssc_dat, "battwatts")
    EXPECT_FALSE(errors)
    var resilience_hours = self.data.as_vector_ssc_number_t("resilience_hrs")
    var resilience_hrs_min = self.data.as_number("resilience_hrs_min")
    var resilience_hrs_max = self.data.as_number("resilience_hrs_max")
    var resilience_hrs_avg = self.data.as_number("resilience_hrs_avg")
    var outage_durations = self.data.as_vector_ssc_number_t("outage_durations")
    var pdf_of_surviving = self.data.as_vector_ssc_number_t("pdf_of_surviving")
    var cdf_of_surviving = self.data.as_vector_ssc_number_t("cdf_of_surviving")
    var avg_critical_load = self.data.as_double("avg_critical_load")
    EXPECT_EQ(resilience_hours[0], 16)
    EXPECT_EQ(resilience_hours[1], 16)
    EXPECT_NEAR(avg_critical_load, 8.39, 0.1)
    EXPECT_NEAR(resilience_hrs_avg, 32.84, 0.01)
    EXPECT_EQ(resilience_hrs_min, 16)
    EXPECT_EQ(resilience_hrs_max, 33)
    EXPECT_EQ(outage_durations[0], 16)
    EXPECT_EQ(outage_durations[16], 32)
    EXPECT_NEAR(pdf_of_surviving[0], 0.00205/2, 1e-5)
    EXPECT_NEAR(pdf_of_surviving[1], 0.00217/2, 1e-5)
end

@Test
def ResidentialDefaults():
    var self = CMBattwatts_cmod_battwatts()
    var ssc_dat = static_cast[ssc_data_t](ref self.data)
    pvwatts_pv_defaults(ssc_dat)
    simple_battery_data(ssc_dat)
    var errors = run_module(ssc_dat, "battwatts")
    EXPECT_FALSE(errors)
    var charge_percent = self.data.as_number("batt_system_charge_percent")
    EXPECT_NEAR(charge_percent, 70.8, 0.1)
    var batt_power_data = self.data.as_vector_ssc_number_t("batt_power")
    var peakKwDischarge = *std.max_element(batt_power_data.begin(), batt_power_data.end())
    var peakKwCharge = *std.min_element(batt_power_data.begin(), batt_power_data.end())
    EXPECT_NEAR(peakKwDischarge, 1.97, 0.1)
    EXPECT_NEAR(peakKwCharge, -3.0, 0.1)
    var batt_voltage = self.data.as_vector_ssc_number_t("batt_voltage")
    var peakVoltage = *std.max_element(batt_voltage.begin(), batt_voltage.end())
    EXPECT_NEAR(peakVoltage, 578.9, 0.1)
    var cycles = self.data.as_vector_ssc_number_t("batt_cycles")
    var maxCycles = *std.max_element(cycles.begin(), cycles.end())
    EXPECT_NEAR(maxCycles, 614, 0.1)
end

@Test
def ResidentialDefaultsLeadAcid():
    var self = CMBattwatts_cmod_battwatts()
    var ssc_dat = static_cast[ssc_data_t](ref self.data)
    pvwatts_pv_defaults(ssc_dat)
    simple_battery_data(ssc_dat)
    ssc_data_set_number(ssc_dat, "batt_simple_chemistry", 0)
    var errors = run_module(ssc_dat, "battwatts")
    EXPECT_FALSE(errors)
    var charge_percent = self.data.as_number("batt_system_charge_percent")
    EXPECT_NEAR(charge_percent, 76.4, 0.1)
    var batt_power_data = self.data.as_vector_ssc_number_t("batt_power")
    var peakKwDischarge = *std.max_element(batt_power_data.begin(), batt_power_data.end())
    var peakKwCharge = *std.min_element(batt_power_data.begin(), batt_power_data.end())
    EXPECT_NEAR(peakKwDischarge, 1.83, 0.1)
    EXPECT_NEAR(peakKwCharge, -2.7, 0.1)
    var batt_voltage = self.data.as_vector_ssc_number_t("batt_voltage")
    var peakVoltage = *std.max_element(batt_voltage.begin(), batt_voltage.end())
    EXPECT_NEAR(peakVoltage, 61.8, 0.1)
    var cycles = self.data.as_vector_ssc_number_t("batt_cycles")
    var maxCycles = *std.max_element(cycles.begin(), cycles.end())
    EXPECT_NEAR(maxCycles, 614, 0.1)
end

@Test
def NoPV():
    var self = CMBattwatts_cmod_battwatts()
    var ssc_dat = static_cast[ssc_data_t](ref self.data)
    pvwatts_pv_defaults(ssc_dat)
    simple_battery_data(ssc_dat)
    vector<double> ac(8760, 0)
    self.data.assign("ac", ac)
    var errors = run_module(ssc_dat, "battwatts")
    EXPECT_FALSE(errors)
    var charge_percent = self.data.as_number("batt_system_charge_percent")
    EXPECT_NEAR(charge_percent, 0.0, 0.1)
    var batt_power_data = self.data.as_vector_ssc_number_t("batt_power")
    var peakKwDischarge = *std.max_element(batt_power_data.begin(), batt_power_data.end())
    var peakKwCharge = *std.min_element(batt_power_data.begin(), batt_power_data.end())
    EXPECT_NEAR(peakKwDischarge, 0.9, 0.1)
    EXPECT_NEAR(peakKwCharge, -0.7, 0.1)
    var batt_voltage = self.data.as_vector_ssc_number_t("batt_voltage")
    var peakVoltage = *std.max_element(batt_voltage.begin(), batt_voltage.end())
    EXPECT_NEAR(peakVoltage, 573.5, 0.1)
    var cycles = self.data.as_vector_ssc_number_t("batt_cycles")
    var maxCycles = *std.max_element(cycles.begin(), cycles.end())
    EXPECT_NEAR(maxCycles, 522, 0.1)
end