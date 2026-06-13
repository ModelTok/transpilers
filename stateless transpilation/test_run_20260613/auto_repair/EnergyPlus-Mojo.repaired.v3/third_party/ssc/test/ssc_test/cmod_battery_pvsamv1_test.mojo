from gtest import Test, TestWithParam, EXPECT_EQ, EXPECT_NEAR, EXPECT_FALSE, EXPECT_LT, EXPECT_TRUE
from core import ssc_data_t, ssc_number_t, ssc_data_create, ssc_data_free, ssc_data_get_number, ssc_data_get_array, ssc_data_set_number, ssc_data_set_string, ssc_data_set_matrix, var_table
from vartab import var_table
from ...ssc.common import *
from ...input_cases.pvsamv1_common_data import *

from math import fabs, max, min, abs
from algorithm import max_element, min_element
from vector import *
from functional import *

struct daily_battery_stats:
    var steps_per_hour: size_t
    var peakKwCharge: ssc_number_t
    var peakKwDischarge: ssc_number_t
    var peakCycles: ssc_number_t
    var avgCycles: ssc_number_t

    def __init__(inout self, batt_power_data: List[ssc_number_t], steps_per_hr: size_t = 1):
        self.steps_per_hour = steps_per_hr
        self.peakKwDischarge = 0
        self.peakCycles = 0
        self.peakKwCharge = 0
        self.avgCycles = 0
        self.compute(batt_power_data)

    def compute(inout self, batt_power_data: List[ssc_number_t]):
        var index: size_t = 0
        var n: size_t = len(batt_power_data)
        var cycleState: Int = 0  # -1 for charging, 1 for discharging;
        var halfCycle: Bool = False
        while index < n:
            var cycles: Int = 0
            for hour in range(24 * self.steps_per_hour):
                var currentPower: ssc_number_t = batt_power_data[index]
                if fabs(currentPower - 0) < 1e-7:
                    currentPower = 0
                if currentPower < 0:
                    if cycleState != -1:
                        if halfCycle:
                            cycles += 1
                            halfCycle = False
                        else:
                            halfCycle = True
                    cycleState = -1
                if currentPower > 0:
                    if cycleState != 1:
                        if halfCycle:
                            cycles += 1
                            halfCycle = False
                        else:
                            halfCycle = True
                    cycleState = 1
                index += 1
            if cycles > self.peakCycles:
                self.peakCycles = cycles
            self.avgCycles += cycles
        var days: ssc_number_t = n / 24.0 / self.steps_per_hour
        self.avgCycles = self.avgCycles / days
        # Note: max_element/min_element on List; in Mojo we can use max/min via list
        var max_val: ssc_number_t = max(batt_power_data)
        var min_val: ssc_number_t = min(batt_power_data)
        self.peakKwDischarge = max_val
        self.peakKwCharge = min_val

class CMPvsamv1BatteryIntegration_cmod_pvsamv1(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]
    var m_error_tolerance_hi: Float64 = 100
    var m_error_tolerance_lo: Float64 = 0.1

    def SetUp(inout self):
        self.data = ssc_data_create()
        pvsamv_nofinancial_default(self.data)
        self.calculated_array = Pointer[ssc_number_t].alloc(8760)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = ssc_data_t(None)
        if self.calculated_array:
            self.calculated_array.free()

    def SetCalculated(inout self, name: String):
        ssc_data_get_number(self.data, name.data(), addressof(self.calculated_value))

    def SetCalculatedArray(inout self, name: String):
        var n: Int = 0
        self.calculated_array = ssc_data_get_array(self.data, name.data(), addressof(n))

def TestDailyBatteryStats_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    var batt_power_data = List[ssc_number_t](0, 1, 0, -1, 0, 2, 0, -2, 0, 3, -3, 4, -1, 6, -4, -1, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, -1, -1, -1)
    EXPECT_EQ(len(batt_power_data), 48)
    var batt_stats = daily_battery_stats(batt_power_data)
    EXPECT_EQ(batt_stats.peakKwCharge, -4)
    EXPECT_EQ(batt_stats.peakKwDischarge, 6)
    EXPECT_EQ(batt_stats.peakCycles, 5)
    EXPECT_NEAR(batt_stats.avgCycles, 3, 0.1)

def ResidentialACBatteryModelIntegration_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["batt_ac_or_dc"] = 1  # AC
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    var expectedEnergy = List[ssc_number_t](8594, 8594, 8689)
    var expectedBatteryChargeEnergy = List[ssc_number_t](1442, 1443, 258)
    var expectedBatteryDischargeEnergy = List[ssc_number_t](1321, 1323, 233)
    var peakKwCharge = List[ssc_number_t](-2.81, -3.02, -2.25)
    var peakKwDischarge = List[ssc_number_t](1.39, 1.30, 0.97)
    var peakCycles = List[ssc_number_t](1, 1, 1)
    var avgCycles = List[ssc_number_t](1, 0.9973, 0.4904)
    for i in range(3):
        pairs["batt_dispatch_choice"] = i
        var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy."
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy."
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy."
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)

def ResidentialACDCBatteryModelIntegrationCustomDispatchSparse_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    pairs["batt_dispatch_choice"] = 3
    set_array(test.data, "batt_custom_dispatch", custom_dispatch_residential_schedule, 8760)
    var expectedEnergy = List[ssc_number_t](8710, 8717)
    var expectedBatteryChargeEnergy = List[ssc_number_t](4.6, 4.7)
    var expectedBatteryDischargeEnergy = List[ssc_number_t](0.76, 7.6)
    var peakKwCharge = List[ssc_number_t](-2.7, -2.8)
    var peakKwDischarge = List[ssc_number_t](0.03, 0.16)
    var peakCycles = List[ssc_number_t](1, 1)
    var avgCycles = List[ssc_number_t](0.0027, 0.0027)
    for i in range(2):
        pairs["batt_ac_or_dc"] = i
        var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy."
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy."
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy."
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)  # Runs once per year

def ResidentialACDCBatteryModelIntegrationCustomDispatchFull_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    pairs["batt_dispatch_choice"] = 3
    set_array(test.data, "batt_custom_dispatch", custom_dispatch_residential_hourly_schedule, 8760)
    var expectedEnergy = List[ssc_number_t](8708, 8672)
    var expectedBatteryChargeEnergy = List[ssc_number_t](396.1, 359.95)
    var expectedBatteryDischargeEnergy = List[ssc_number_t](395.95, 419.2)
    var peakKwCharge = List[ssc_number_t](-0.47, -0.46)
    var peakKwDischarge = List[ssc_number_t](0.39, 0.41)
    var peakCycles = List[ssc_number_t](2, 2)
    var avgCycles = List[ssc_number_t](0.8219, 0.8219)
    for i in range(2):
        pairs["batt_ac_or_dc"] = i
        var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy for " << i
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy for " << i
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy for " << i
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)

def ResidentialACDCBatteryModelIntegrationManualDispatch_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    pairs["batt_dispatch_choice"] = 4
    var expectedEnergy = List[ssc_number_t](8701, 8672)
    var expectedBatteryChargeEnergy = List[ssc_number_t](468, 488)
    var expectedBatteryDischargeEnergy = List[ssc_number_t](437, 446)
    var peakKwCharge = List[ssc_number_t](-2.37, -2.27)
    var peakKwDischarge = List[ssc_number_t](1.31, 1.31)
    var peakCycles = List[ssc_number_t](2, 2)
    var avgCycles = List[ssc_number_t](0.7178, 0.7205)
    for i in range(2):
        pairs["batt_ac_or_dc"] = i
        var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy."
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy."
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy."
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)

def ResidentialDCBatteryModelIntegration_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["batt_ac_or_dc"] = 0  # DC
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    var expectedEnergy = List[ssc_number_t](8634, 8637, 8703)
    var expectedBatteryChargeEnergy = List[ssc_number_t](1412.75, 1414.89, 253.2)
    var expectedBatteryDischargeEnergy = List[ssc_number_t](1283.8, 1285.88, 226.3)
    var peakKwCharge = List[ssc_number_t](-3.21, -2.96, -2.69)
    var peakKwDischarge = List[ssc_number_t](1.40, 1.31, 0.967)
    var peakCycles = List[ssc_number_t](2, 2, 1)
    var avgCycles = List[ssc_number_t](1.0109, 1.0054, 0.4794)
    for i in range(3):
        pairs["batt_dispatch_choice"] = i
        var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy."
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy."
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy."
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)

def PPA_ACBatteryModelIntegration_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv1_pv_defaults(test.data)
    pvsamv1_battery_defaults(test.data)
    grid_and_rate_defaults(test.data)
    singleowner_defaults(test.data)
    var expectedEnergy = List[ssc_number_t](37308020, 37307080, 37308021)
    var expectedBatteryChargeEnergy = List[ssc_number_t](14779, 24265, 14779)  # No rate model means battery use is low
    var expectedBatteryDischargeEnergy = List[ssc_number_t](14663, 23209, 14663)
    var peakKwCharge = List[ssc_number_t](-1040.2, -1051.5, -1051.5)
    var peakKwDischarge = List[ssc_number_t](967.5, 969.5, 969.5)
    var peakCycles = List[ssc_number_t](1, 1, 1)
    var avgCycles = List[ssc_number_t](0.003, 0.006, 0.003)
    for i in range(3):
        ssc_data_set_number(test.data, "batt_dispatch_choice", i)
        var pvsam_errors = run_pvsam1_battery_ppa(test.data)
        EXPECT_FALSE(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
            EXPECT_NEAR(annual_energy, expectedEnergy[i], test.m_error_tolerance_hi) << "Annual energy for " << i
            var data_vtab = var_table(test.data)
            var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
            EXPECT_NEAR(annualChargeEnergy[1], expectedBatteryChargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual charge energy for " << i
            var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
            EXPECT_NEAR(annualDischargeEnergy[1], expectedBatteryDischargeEnergy[i], test.m_error_tolerance_hi) << "Battery annual discharge energy for " << i
            var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
            var batt_stats = daily_battery_stats(batt_power)
            EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge[i], test.m_error_tolerance_hi)
            EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge[i], test.m_error_tolerance_hi)
            EXPECT_NEAR(batt_stats.peakCycles, peakCycles[i], test.m_error_tolerance_lo)
            EXPECT_NEAR(batt_stats.avgCycles, avgCycles[i], 0.0001)
            var temp_array = data_vtab.as_vector_ssc_number_t("batt_temperature")
            var max_temp: Float64 = max(temp_array)
            EXPECT_LT(max_temp, 26)

def PPA_ManualDispatchBatteryModelIntegration_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv1_pv_defaults(test.data)
    pvsamv1_battery_defaults(test.data)
    grid_and_rate_defaults(test.data)
    singleowner_defaults(test.data)
    var expectedEnergy: ssc_number_t = 37175792
    var expectedBatteryChargeEnergy: ssc_number_t = 1298028
    var expectedBatteryDischargeEnergy: ssc_number_t = 1165681
    var peakKwCharge: ssc_number_t = -1052.0
    var peakKwDischarge: ssc_number_t = 846.8
    var peakCycles: ssc_number_t = 1
    var avgCycles: ssc_number_t = 1
    ssc_data_set_number(test.data, "batt_dispatch_choice", 4)
    var p_ur_ec_sched_weekday_srp = List[ssc_number_t](6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6)
    ssc_data_set_matrix(test.data, "ur_ec_sched_weekday", p_ur_ec_sched_weekday_srp, 12, 24)
    var p_ur_ec_sched_weekend_srp = List[ssc_number_t](6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6)
    ssc_data_set_matrix(test.data, "ur_ec_sched_weekend", p_ur_ec_sched_weekend_srp, 12, 24)
    var p_ur_ec_tou_mat_srp = List[ssc_number_t](1, 1, 9.9999999999999998e+37, 0, 0.2969, 0, 2, 1, 9.9999999999999998e+37, 0, 0.081900000000000001, 0, 3, 1, 9.9999999999999998e+37, 0, 0.34989999999999999, 0, 4, 1, 9.9999999999999998e+37, 0, 0.083599999999999994, 0, 5, 1, 9.9999999999999998e+37, 0, 0.123, 0, 6, 1, 9.9999999999999998e+37, 0, 0.074999999999999997, 0)
    ssc_data_set_matrix(test.data, "ur_ec_tou_mat", p_ur_ec_tou_mat_srp, 6, 6)
    var pvsam_errors = run_pvsam1_battery_ppa(test.data)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[1], expectedBatteryChargeEnergy, 10) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[1], expectedBatteryDischargeEnergy, 10) << "Battery annual discharge energy."
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)

def PPA_CustomDispatchBatteryModelDCIntegrationSparse_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv1_pv_defaults(test.data)
    pvsamv1_battery_defaults(test.data)
    grid_and_rate_defaults(test.data)
    singleowner_defaults(test.data)
    var expectedEnergy: ssc_number_t = 37308785
    var expectedBatteryChargeEnergy: ssc_number_t = 2040
    var expectedBatteryDischargeEnergy: ssc_number_t = 3254.
    var peakKwCharge: ssc_number_t = -1020.4
    var peakKwDischarge: ssc_number_t = 958.7
    var peakCycles: ssc_number_t = 1
    var avgCycles: ssc_number_t = 0.0027
    ssc_data_set_number(test.data, "batt_dispatch_choice", 3)
    ssc_data_set_number(test.data, "batt_ac_or_dc", 0)
    set_array(test.data, "batt_custom_dispatch", custom_dispatch_singleowner_schedule, 8760)
    var pvsam_errors = run_pvsam1_battery_ppa(test.data)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[1], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[1], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)  # Runs once per year

def PPA_CustomDispatchBatteryModelDCIntegrationFull_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv1_pv_defaults(test.data)
    pvsamv1_battery_defaults(test.data)
    grid_and_rate_defaults(test.data)
    singleowner_defaults(test.data)
    var expectedEnergy: ssc_number_t = 37251482
    var expectedBatteryChargeEnergy: ssc_number_t = 419044
    var expectedBatteryDischargeEnergy: ssc_number_t = 348966
    var roundtripEfficiency: ssc_number_t = 80.6
    var peakKwCharge: ssc_number_t = -948.6
    var peakKwDischarge: ssc_number_t = 651.7
    var peakCycles: ssc_number_t = 3
    var avgCycles: ssc_number_t = 1.1945
    ssc_data_set_number(test.data, "batt_dispatch_choice", 3)
    ssc_data_set_number(test.data, "batt_ac_or_dc", 0)
    set_array(test.data, "batt_custom_dispatch", custom_dispatch_singleowner_hourly_schedule, 8760)
    var pvsam_errors = run_pvsam1_battery_ppa(test.data)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[1], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[1], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        EXPECT_NEAR(data_vtab.lookup("average_battery_roundtrip_efficiency").num[0], roundtripEfficiency, test.m_error_tolerance_hi) << "Battery roundtrip efficiency."
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)

def CommercialMultipleSubarrayBatteryIntegration_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    commercial_multiarray_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["analysis_period"] = 1
    var expectedEnergy: ssc_number_t = 537434
    var expectedBatteryChargeEnergy: ssc_number_t = 929
    var expectedBatteryDischargeEnergy: ssc_number_t = 849
    var expectedClipLoss: ssc_number_t = 593.5
    var peakKwCharge: ssc_number_t = -10.12
    var peakKwDischarge: ssc_number_t = 1.39
    var peakCycles: ssc_number_t = 1
    var avgCycles: ssc_number_t = 1
    var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        var dcInverterLoss = data_vtab.as_vector_ssc_number_t("dc_invmppt_loss")
        var totalLoss: ssc_number_t = 0
        for i in range(len(dcInverterLoss)):
            totalLoss += dcInverterLoss[i]
        EXPECT_NEAR(totalLoss, expectedClipLoss, test.m_error_tolerance_lo)
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)

def ClippingForecastTest1_DC_FOM_Dispatch_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    commercial_multiarray_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["analysis_period"] = 1
    pairs["batt_ac_or_dc"] = 0
    var expectedEnergy: ssc_number_t = 537030
    var expectedBatteryChargeEnergy: ssc_number_t = 929
    var expectedBatteryDischargeEnergy: ssc_number_t = 343.96
    var expectedClipLoss: ssc_number_t = 593.5
    var peakKwCharge: ssc_number_t = -9.488
    var peakKwDischarge: ssc_number_t = 1.1
    var peakCycles: ssc_number_t = 1
    var avgCycles: ssc_number_t = 1
    var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        var dcInverterLoss = data_vtab.as_vector_ssc_number_t("dc_invmppt_loss")
        var totalLoss: ssc_number_t = 0
        for i in range(len(dcInverterLoss)):
            totalLoss += dcInverterLoss[i]
        EXPECT_NEAR(totalLoss, expectedClipLoss, test.m_error_tolerance_lo)
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)

def ClippingForecastTest2_DC_FOM_Dispatch_w_forecast_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    commercial_multiarray_default(test.data)
    var pairs = Dict[String, Float64]()
    pairs["analysis_period"] = 1
    pairs["batt_ac_or_dc"] = 0
    set_array(test.data, "batt_pv_clipping_forecast", clipping_forecast, 8760)
    var expectedEnergy: ssc_number_t = 537030
    var expectedBatteryChargeEnergy: ssc_number_t = 929
    var expectedBatteryDischargeEnergy: ssc_number_t = 343.96
    var expectedClipLoss: ssc_number_t = 593.5
    var peakKwCharge: ssc_number_t = -9.488
    var peakKwDischarge: ssc_number_t = 1.1
    var peakCycles: ssc_number_t = 1
    var avgCycles: ssc_number_t = 1
    var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        var dcInverterLoss = data_vtab.as_vector_ssc_number_t("dc_invmppt_loss")
        var totalLoss: ssc_number_t = 0
        for i in range(len(dcInverterLoss)):
            totalLoss += dcInverterLoss[i]
        EXPECT_NEAR(totalLoss, expectedClipLoss, test.m_error_tolerance_lo)
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.0001)

def PPA_CustomDispatchBatteryModelDCIntegrationFullSubhourly_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv1_pv_defaults(test.data)
    pvsamv1_battery_defaults(test.data)
    grid_and_rate_defaults(test.data)
    singleowner_defaults(test.data)
    var expectedEnergy: ssc_number_t = 37252473
    var expectedBatteryChargeEnergy: ssc_number_t = 430570
    var expectedBatteryDischargeEnergy: ssc_number_t = 349127
    var roundtripEfficiency: ssc_number_t = 80.6
    var peakKwCharge: ssc_number_t = -948.6
    var peakKwDischarge: ssc_number_t = 651.7
    var peakCycles: ssc_number_t = 3
    var avgCycles: ssc_number_t = 1.1829
    ssc_data_set_number(test.data, "batt_dispatch_choice", 3)
    ssc_data_set_number(test.data, "batt_ac_or_dc", 0)
    set_array(test.data, "batt_custom_dispatch", custom_dispatch_singleowner_subhourly_schedule, 8760 * 4)
    set_array(test.data, "batt_room_temperature_celsius", subhourly_batt_temps, 8760 * 4)
    set_array(test.data, "dispatch_factors_ts", subhourly_dispatch_factors, 8760 * 4)
    ssc_data_set_string(test.data, "solar_resource_file", subhourly_weather_file)
    var pvsam_errors = run_pvsam1_battery_ppa(test.data)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var tol: Float64 = .05
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, expectedEnergy * tol) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[1], expectedBatteryChargeEnergy, expectedBatteryChargeEnergy * tol) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[1], expectedBatteryDischargeEnergy, expectedBatteryDischargeEnergy * tol) << "Battery annual discharge energy."
        EXPECT_NEAR(data_vtab.lookup("average_battery_roundtrip_efficiency").num[0], roundtripEfficiency, test.m_error_tolerance_hi) << "Battery roundtrip efficiency."
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power, 4)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, abs(peakKwCharge * 0.01))
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, peakKwDischarge * 0.01)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.05)

def ResidentialDCBatteryModelPriceSignalDispatch_CMPvsamv1BatteryIntegration_cmod_pvsamv1(inout test: CMPvsamv1BatteryIntegration_cmod_pvsamv1):
    pvsamv_nofinancial_default(test.data)
    battery_data_default(test.data)
    setup_residential_utility_rates(test.data)
    var pairs = Dict[String, Float64]()
    pairs["en_batt"] = 1
    pairs["batt_meter_position"] = 0  # Behind the meter
    pairs["batt_ac_or_dc"] = 0  # DC
    pairs["analysis_period"] = 1
    set_array(test.data, "load", load_profile_path, 8760)  # Load is required for peak shaving controllers
    var expectedEnergy: ssc_number_t = 8634
    var expectedBatteryChargeEnergy: ssc_number_t = 390.9
    var expectedBatteryDischargeEnergy: ssc_number_t = 360.2
    var peakKwCharge: ssc_number_t = -3.914
    var peakKwDischarge: ssc_number_t = 1.99
    var peakCycles: ssc_number_t = 2
    var avgCycles: ssc_number_t = 0.41
    pairs["batt_dispatch_choice"] = 5
    var pvsam_errors = modify_ssc_data_and_run_module(test.data, "pvsamv1", pairs)
    EXPECT_FALSE(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        ssc_data_get_number(test.data, "annual_energy", addressof(annual_energy))
        EXPECT_NEAR(annual_energy, expectedEnergy, test.m_error_tolerance_hi) << "Annual energy."
        var data_vtab = var_table(test.data)
        var annualChargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_charge_energy")
        EXPECT_NEAR(annualChargeEnergy[0], expectedBatteryChargeEnergy, test.m_error_tolerance_hi) << "Battery annual charge energy."
        var annualDischargeEnergy = data_vtab.as_vector_ssc_number_t("batt_annual_discharge_energy")
        EXPECT_NEAR(annualDischargeEnergy[0], expectedBatteryDischargeEnergy, test.m_error_tolerance_hi) << "Battery annual discharge energy."
        var batt_power = data_vtab.as_vector_ssc_number_t("batt_power")
        var batt_stats = daily_battery_stats(batt_power)
        EXPECT_NEAR(batt_stats.peakKwCharge, peakKwCharge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakKwDischarge, peakKwDischarge, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.peakCycles, peakCycles, test.m_error_tolerance_lo)
        EXPECT_NEAR(batt_stats.avgCycles, avgCycles, 0.1)  # As of 8-26-20 Linux cycles 2 more times in a year than Windows, this changes the NPV by $2 over 25 years
        var batt_q_rel = data_vtab.as_vector_ssc_number_t("batt_capacity_percent")
        var batt_cyc_avg = data_vtab.as_vector_ssc_number_t("batt_DOD_cycle_average")
        EXPECT_NEAR(batt_q_rel.back(), 97.846, 2e-2)
        EXPECT_NEAR(batt_cyc_avg.back(), 26.15, 0.5)