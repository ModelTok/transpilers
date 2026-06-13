// Translation of C++ test file to Mojo (faithful 1:1, no refactoring)
// Original header: lib_battery_dispatch_automatic_btm_test.h
// Original body: lib_battery_dispatch_automatic_btm_test.cpp

from lib_battery_dispatch_automatic_btm import dispatch_automatic_behind_the_meter_t
from lib_battery_dispatch_test import BatteryProperties, DispatchProperties
from code_generator_utilities import *
from ...input_cases.shared_rate_data import set_up_default_commercial_rate_data, set_up_residential_1_4_peak
from testing import assert_equal, assert_almost_equal

// Forward declarations for types used (assumed defined in imported modules)
// capacity_lithium_ion_t, voltage_dynamic_t, thermal_t, lifetime_t, losses_t, battery_t,
// BatteryPower, SharedInverter, ChargeController, rate_data, etc.

struct AutoBTMTest_lib_battery_dispatch(BatteryProperties, DispatchProperties):
    var capacityModel: Pointer[capacity_lithium_ion_t]
    var voltageModel: Pointer[voltage_dynamic_t]
    var thermalModel: Pointer[thermal_t]
    var lifetimeModel: Pointer[lifetime_t]
    var lossModel: Pointer[losses_t]
    var batteryModel: Pointer[battery_t]
    var batteryPower: Pointer[BatteryPower]
    var util_rate: Pointer[rate_data] = Pointer[rate_data](None)
    var dispatchAutoBTM: Pointer[dispatch_automatic_behind_the_meter_t] = Pointer[dispatch_automatic_behind_the_meter_t](None)
    var max_power: SimFloat = 50.0
    var max_current: SimFloat = 500.0
    var surface_area: SimFloat = 1.2 * 1.2 * 6.0
    var n_series: SInt = 139
    var n_strings: SInt = 89
    var replacementCost: List[SimFloat] = List[SimFloat](0.0)
    var cyclingChoice: SInt = 1
    var cyclingCost: List[SimFloat] = List[SimFloat](0.0)
    // Variables to store forecast data
    var pv_prediction: List[SimFloat] = List[SimFloat]()
    var load_prediction: List[SimFloat] = List[SimFloat]()
    var cliploss_prediction: List[SimFloat] = List[SimFloat]()

    def __init__(inout self):
        super()
        // Initialize base members? Not needed if base traits have default init

    def CreateBattery(inout self, dtHour: SimFloat):
        BatteryProperties.SetUp(self)  // assume SetUp is a method from base trait
        self.n_strings = 445
        self.capacityModel = Pointer[capacity_lithium_ion_t](new capacity_lithium_ion_t(Qfull * self.n_strings, SOC_init, SOC_max, SOC_min, dtHour))
        self.voltageModel = Pointer[voltage_dynamic_t](new voltage_dynamic_t(n_series, n_strings, Vnom_default, Vfull, Vexp, Vnom, Qfull, Qexp, Qnom,
                                             C_rate, resistance, dtHour))
        self.lifetimeModel = Pointer[lifetime_calendar_cycle_t](new lifetime_calendar_cycle_t(cycleLifeMatrix, dtHour, calendar_q0, calendar_a, calendar_b, calendar_c))
        self.thermalModel = Pointer[thermal_t](new thermal_t(1.0, mass, surface_area, resistance, Cp, h, capacityVsTemperature, T_room))
        self.lossModel = Pointer[losses_t](new losses_t())
        self.batteryModel = Pointer[battery_t](new battery_t(dtHour, chemistry, self.capacityModel, self.voltageModel, self.lifetimeModel, self.thermalModel, self.lossModel))
        var numberOfInverters: SInt = 40
        self.m_sharedInverter = Pointer[SharedInverter](new SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, sandia, partload, ond))

    def CreateResidentialBattery(inout self, dtHour: SimFloat):
        self.n_strings = 9
        self.CreateBattery(dtHour)
        delete self.m_sharedInverter
        var numberOfInverters: SInt = 1
        self.m_sharedInverter = Pointer[SharedInverter](new SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, sandia, partload, ond))

    def CreateBatteryWithLosses(inout self, dtHour: SimFloat):
        BatteryProperties.SetUp(self)
        q = 1000.0 / 89.0
        self.capacityModel = Pointer[capacity_lithium_ion_t](new capacity_lithium_ion_t(q * self.n_strings, SOC_init, SOC_max, SOC_min, dtHour))
        self.voltageModel = Pointer[voltage_dynamic_t](new voltage_dynamic_t(n_series, n_strings, Vnom_default, Vfull, Vexp, Vnom, Qfull, Qexp, Qnom,
            C_rate, resistance, dtHour))
        self.lifetimeModel = Pointer[lifetime_calendar_cycle_t](new lifetime_calendar_cycle_t(cycleLifeMatrix, dtHour, calendar_q0, calendar_a, calendar_b, calendar_c))
        self.thermalModel = Pointer[thermal_t](new thermal_t(1.0, mass, surface_area, resistance, Cp, h, capacityVsTemperature, T_room))
        var charging_losses: List[SimFloat] = List[SimFloat](12, 1.0) // Monthly losses
        var discharging_losses: List[SimFloat] = List[SimFloat](12, 2.0)
        var idle_losses: List[SimFloat] = List[SimFloat](12, 0.5)
        self.lossModel = Pointer[losses_t](new losses_t(charging_losses, discharging_losses, idle_losses))
        self.batteryModel = Pointer[battery_t](new battery_t(dtHour, chemistry, self.capacityModel, self.voltageModel, self.lifetimeModel, self.thermalModel, self.lossModel))
        var numberOfInverters: SInt = 40
        self.m_sharedInverter = Pointer[SharedInverter](new SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, sandia, partload, ond))

    def TearDown(inout self):
        BatteryProperties.TearDown(self)
        delete self.batteryModel
        delete self.dispatchAutoBTM

// Test functions (translated from TEST_F macros)
def test_DispatchAutoBTMGridCharging():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
                                                                max_current,
                                                                max_current, max_power, max_power, max_power, max_power,
                                                                0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
                                                                true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        test.pv_prediction.push_back(0) // Set detailed PV later
        if h < 4:
            test.load_prediction.push_back(600)
        else:
            test.load_prediction.push_back(0)
    test.pv_prediction[0] = 500
    test.pv_prediction[1] = 400
    test.pv_prediction[2] = 300
    test.pv_prediction[3] = 200
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    assert_equal(test.batteryPower.powerBatteryChargeMaxAC, 50)
    test.dispatchAutoBTM.update_dispatch(0, 0, 0, 0)
    test.dispatchAutoBTM.dispatch(0, 0, 0)
    assert_equal(test.batteryPower.powerGridToBattery, 0)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0, 0.02)
    test.batteryPower.canGridCharge = true
    test.dispatchAutoBTM.update_dispatch(0, 0, 0, 0)
    test.dispatchAutoBTM.dispatch(0, 0, 0)
    assert_almost_equal(test.batteryPower.powerGridToBattery, 50, 1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, -48, 1)

def test_DispatchAutoBTMPVCharging():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
                                                                max_current,
                                                                max_current, max_power, max_power, max_power, max_power,
                                                                0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
                                                                true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        if h > 6 and h < 18:
            test.pv_prediction.push_back(700)
        else:
            test.pv_prediction.push_back(0)
        test.load_prediction.push_back(500)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.94, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    for h in range(24):
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 700 // Match the predicted PV
        else:
            test.batteryPower.powerSystem = 0
        test.batteryPower.powerLoad = 500 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.2, " error in expected at hour " + str(h))

def test_DispatchAutoBTMPVChargeAndDischarge():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
                                                                max_current,
                                                                max_current, max_power, max_power, max_power, max_power,
                                                                0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
                                                                true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        if h > 6 and h < 18:
            test.pv_prediction.push_back(700)
        else:
            test.pv_prediction.push_back(0)
        if h > 18:
            test.load_prediction.push_back(600)
        else:
            test.load_prediction.push_back(500)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50, 50, 50, 50)
    for h in range(24):
        test.batteryPower.powerLoad = 500
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 700 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 600 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_DispatchAutoBTMPVChargeAndDischargeSubhourly():
    var dtHour: SimFloat = 0.25
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
                                                                max_current,
                                                                max_current, max_power, max_power, max_power, max_power,
                                                                0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
                                                                true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        for step in range(4):
            if h > 6 and h < 18:
                test.pv_prediction.push_back(700)
            else:
                test.pv_prediction.push_back(0)
            if h > 18:
                test.load_prediction.push_back(600)
            else:
                test.load_prediction.push_back(500)
    var expectedPower: List[SimFloat] = List[SimFloat](0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                                         0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                                         0.00, 0.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00,
                                         -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00, -50.00,
                                         -50.00, -50.00, -6.40, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                                         0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                                         0.00, 0.00, 0.00, 0.00, 0.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00,
                                         50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00,
                                         50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00,
                                         50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00,
                                         50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00, 50.00)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var index: SInt = 0
    for h in range(24):
        for step in range(4):
            test.batteryPower.powerLoad = 500
            test.batteryPower.powerSystem = 0
            if h > 6 and h < 18:
                test.batteryPower.powerSystem = 700 // Match the predicted PV
            elif h > 18:
                test.batteryPower.powerLoad = 600 // Match the predicted load
            test.dispatchAutoBTM.dispatch(0, h, step)
            assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[index], 0.2, " error in expected at step " + str(index))
            index += 1

def test_DispatchAutoBTMDCClipCharge():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
                                                                max_current,
                                                                max_current, max_power, max_power, max_power, max_power,
                                                                0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1,
                                                                false, true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        if h > 6 and h < 18:
            test.pv_prediction.push_back(700)
        else:
            test.pv_prediction.push_back(0)
        if h > 18:
            test.load_prediction.push_back(600)
        else:
            test.load_prediction.push_back(500)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -47.93, -47.92, -47.92, -47.91, -48.0, -12.295,
                                         0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50.25)
    for h in range(24):
        test.batteryPower.powerLoad = 500
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 700 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 600 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.2, " error in expected at hour " + str(h))

def test_TestBasicForecast():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_default_commercial_rate_data(test.util_rate)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(48):
        if h % 24 > 6 and h % 24 < 18:
            test.pv_prediction.push_back(700)
        else:
            test.pv_prediction.push_back(0)
        if h % 24 > 18:
            test.load_prediction.push_back(600)
        else:
            test.load_prediction.push_back(500)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](50, 50, 50, 34.79, 0, 0, 0, -49.99, -49.99, -49.99, -49.99, -49.99, -49.99, -49.99, -49.99, -41.70, 0, 0, 50, 50, 50, 50, 50, 50, 50, 50, 50)
    for h in range(24):
        test.batteryPower.powerLoad = 500
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 700 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 600 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_TestSummerPeak():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateResidentialBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_residential_1_4_peak(test.util_rate, 1)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    test.load_prediction = List[SimFloat](1.44289, 1.27067, 1.1681, 1.09342, 1.12921, 1.39345, 1.57299, 1.63055, 1.85622, 2.44991, 2.61812, 2.90909, 3.29601, 3.64366, 3.88232, 3.99237, 4.09673, 4.11102, 4.09175, 4.13445, 3.91011, 3.27815, 2.67845, 2.11802, 1.78025, 1.57142, 1.42908, 1.32466,
                            1.34971, 1.65378, 1.80832, 1.89189, 2.15165, 2.83263, 2.98228, 3.22567, 3.50516, 3.83516, 3.92251, 4.05548, 4.13676, 4.13277, 4.0915, 4.19724, 4.00006, 3.34509, 2.68845, 2.08509, 1.7126)
    test.pv_prediction = List[SimFloat](-0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.129814, 0.75348, 1.47006, 2.45093, 2.9696, 3.30167, 3.47537, 3.42799, 3.14281, 2.59477, 1.83033, 0.857618, 0.176968, -0.00116655, -0.00116655, -0.00116655,
                -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.078559, 0.420793, 1.35006, 2.03824, 2.47638, 2.70446, 3.22802, 2.74022, 2.81986, 2.39299, 1.68699, 0.881843,
                0.169532, -0.00116655, -0.00116655, -0.00116655, -0.00116655)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.058, -0.0054, 0, 0, 0.0, 1.564, 2.3757, 3.368, 4.122, 0.0, 0, 0, 0, 0)
    for h in range(24):
        test.batteryPower.powerSystem = test.pv_prediction[h] // Match the predicted PV
        test.batteryPower.powerLoad = test.load_prediction[h] // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_TestSummerPeakNetMeteringCredits():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateResidentialBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_residential_1_4_peak(test.util_rate, 1)
    test.util_rate.nm_credit_sell_rate = 0.02
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    test.load_prediction = List[SimFloat](1.44289, 1.27067, 1.1681, 1.09342, 1.12921, 1.39345, 1.57299, 1.63055, 1.85622, 2.44991, 2.61812, 2.90909, 3.29601, 3.64366, 3.88232, 3.99237, 4.09673, 4.11102, 4.09175, 4.13445, 3.91011, 3.27815, 2.67845, 2.11802, 1.78025, 1.57142, 1.42908, 1.32466,
                            1.34971, 1.65378, 1.80832, 1.89189, 2.15165, 2.83263, 2.98228, 3.22567, 3.50516, 3.83516, 3.92251, 4.05548, 4.13676, 4.13277, 4.0915, 4.19724, 4.00006, 3.34509, 2.68845, 2.08509, 1.7126)
    test.pv_prediction = List[SimFloat](-0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.129814, 0.75348, 1.47006, 2.45093, 2.9696, 3.30167, 3.47537, 3.42799, 3.14281, 2.59477, 1.83033, 0.857618, 0.176968, -0.00116655, -0.00116655, -0.00116655,
                -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.078559, 0.420793, 1.35006, 2.03824, 2.47638, 2.70446, 3.22802, 2.74022, 2.81986, 2.39299, 1.68699, 0.881843,
                0.169532, -0.00116655, -0.00116655, -0.00116655, -0.00116655)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.058, -0.0054, 0, 0, 0.0, 1.564, 2.3757, 3.368, 4.122, 0.0, 0, 0, 0, 0)
    for h in range(24):
        test.batteryPower.powerSystem = test.pv_prediction[h] // Match the predicted PV
        test.batteryPower.powerLoad = test.load_prediction[h] // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.1, " error in expected at hour " + str(h))

def test_TestSummerPeakGridCharging():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateResidentialBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_residential_1_4_peak(test.util_rate, 1)
    var canGridCharge: Bool = true
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, canGridCharge, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    test.load_prediction = List[SimFloat](1.44289, 1.27067, 1.1681, 1.09342, 1.12921, 1.39345, 1.57299, 1.63055, 1.85622, 2.44991, 2.61812, 2.90909, 3.29601, 3.64366, 3.88232, 3.99237, 4.09673, 4.11102, 4.09175, 4.13445, 3.91011, 3.27815, 2.67845, 2.11802, 1.78025, 1.57142, 1.42908, 1.32466,
                            1.34971, 1.65378, 1.80832, 1.89189, 2.15165, 2.83263, 2.98228, 3.22567, 3.50516, 3.83516, 3.92251, 4.05548, 4.13676, 4.13277, 4.0915, 4.19724, 4.00006, 3.34509, 2.68845, 2.08509, 1.7126)
    test.pv_prediction = List[SimFloat](-0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.129814, 0.75348, 1.47006, 2.45093, 2.9696, 3.30167, 3.47537, 3.42799, 3.14281, 2.59477, 1.83033, 0.857618, 0.176968, -0.00116655, -0.00116655, -0.00116655,
                -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.078559, 0.420793, 1.35006, 2.03824, 2.47638, 2.70446, 3.22802, 2.74022, 2.81986, 2.39299, 1.68699, 0.881843,
                0.169532, -0.00116655, -0.00116655, -0.00116655, -0.00116655)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](-0.648, -0.813, -0.912, -0.984, -0.949, -0.695, -0.523, -0.124, -0.723,
                                          -1.093, -1.874, -2.092, -2.092, -1.872, -1.598, -1.21, -0.592, 0, 3.3688,
                                         4.122, 0.0, 0.0, 0.0, -0.317)
    for h in range(24):
        test.batteryPower.powerSystem = test.pv_prediction[h] // Match the predicted PV
        test.batteryPower.powerLoad = test.load_prediction[h] // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.1, " error in expected at hour " + str(h))

def test_TestSummerPeakGridChargingSubhourly():
    var dtHour: SimFloat = 0.5
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateResidentialBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_residential_1_4_peak(test.util_rate, 2)
    var canGridCharge: Bool = true
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, canGridCharge, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    test.load_prediction = List[SimFloat](1.44289, 1.27067, 1.1681, 1.09342, 1.12921, 1.39345, 1.57299, 1.63055, 1.85622, 2.44991, 2.61812, 2.90909, 3.29601, 3.64366, 3.88232, 3.99237, 4.09673, 4.11102, 4.09175, 4.13445, 3.91011, 3.27815, 2.67845, 2.11802, 1.78025, 1.57142, 1.42908, 1.32466,
                            1.34971, 1.65378, 1.80832, 1.89189, 2.15165, 2.83263, 2.98228, 3.22567, 3.50516, 3.83516, 3.92251, 4.05548, 4.13676, 4.13277, 4.0915, 4.19724, 4.00006, 3.34509, 2.68845, 2.08509, 1.7126)
    test.pv_prediction = List[SimFloat](-0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.129814, 0.75348, 1.47006, 2.45093, 2.9696, 3.30167, 3.47537, 3.42799, 3.14281, 2.59477, 1.83033, 0.857618, 0.176968, -0.00116655, -0.00116655, -0.00116655,
                -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, -0.00116655, 0.078559, 0.420793, 1.35006, 2.03824, 2.47638, 2.70446, 3.22802, 2.74022, 2.81986, 2.39299, 1.68699, 0.881843,
                0.169532, -0.00116655, -0.00116655, -0.00116655, -0.00116655)
    var subhourly_load: List[SimFloat] = List[SimFloat]()
    var subhourly_pv: List[SimFloat] = List[SimFloat]()
    for i in range(min(test.load_prediction.size, test.pv_prediction.size)):
        for j in range(2):
            subhourly_load.push_back(test.load_prediction[i])
            subhourly_pv.push_back(test.pv_prediction[i])
    test.dispatchAutoBTM.update_load_data(subhourly_load)
    test.dispatchAutoBTM.update_pv_data(subhourly_pv)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](-0.648, -0.813, -0.912, -0.984, -0.949, -0.695, -0.523, -0.124, -0.723, -1.093, -1.874, -2.092, -2.092, -1.872, -1.598, 0.885, 1.564, 2.3757, 3.3688, 4.122, 0.0, 0.0, 0.0, -0.317)
    for h in range(24):
        test.batteryPower.powerSystem = test.pv_prediction[h] // Match the predicted PV
        test.batteryPower.powerLoad = test.load_prediction[h] // Match the predicted load
        for j in range(2):
            test.dispatchAutoBTM.dispatch(0, h, j)
            assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.1, " error in expected at hour " + str(h) + " step " + str(j))

def test_TestCommercialPeakForecasting():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.util_rate = Pointer[rate_data](new rate_data())
    set_up_default_commercial_rate_data(test.util_rate)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.FORECAST, 0, 1, 24, 1, true,
        true, true, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    test.load_prediction = List[SimFloat](49.9898, 42.4037, 42.1935, 43.3778, 39.4545, 59.3723, 84.6907, 180.423, 180.836, 186.225, 197.275, 205.302, 231.362,
                        240.712, 249.681, 263.722, 249.91, 188.621, 173.452, 134.803, 121.631, 56.1207, 57.5053, 50.6343, 49.1768, 44.4999, 44.3999,
                        44.3927, 42.8778, 61.4139, 86.7599, 186.891, 190.837, 198.747, 207.645, 211.838, 241.774, 262.163, 268.742, 274.231, 262.211,
                        199.747, 178.862, 145.017, 122.382, 55.8128, 58.1977, 51.3724, 48.2751, 42.5604, 39.8775, 38.8493, 38.2728, 62.2958, 66.9385,
                        99.3759, 111.364, 120.912, 129.247, 133.878, 135.635, 106.555, 114.328, 119.437, 104.461, 50.5622, 47.9985, 60.8511, 54.6621,
                        49.8308, 46.5466, 46.981)
    test.pv_prediction = List[SimFloat](-0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127, 0.660882, 12.559, 49.7136,  91.8535, 127.144, 152.689,
                    169.057, 173.287, 166.498, 149.011, 121.686, 85.1714, 44.2784, 11.3531, -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127,
                -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127, 0.684759, 12.9444, 49.138, 90.4215, 123.972, 146.219, 159.256, 165.567,
                161.568, 149.301, 123.484, 87.7486, 45.423, 9.46763, -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127, -0.0544127,
                -0.0544127, -0.0544127, -0.0544127, 0.775864, 12.2175, 50.052, 90.8638, 123.436, 147.375, 145.671, 168.646, 164.069, 148.132, 121.686,
                85.7045, 44.54, 10.726, -0.0544127, -0.0544127, -0.0544127, -0.0544127)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.dispatchAutoBTM.setup_rate_forecast()
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](50.02, 44.22, 44.0, 45.24, 1.34, 0, 0, 0, 0, 0.0, 0, -46.0, -46.0, -45.39, -30.26, 50.08, 50.06, 50.15, 13.25, 0, 0, -46.0, -46.0, -46.0)
    for h in range(24):
        test.batteryPower.powerSystem = test.pv_prediction[h] // Match the predicted PV
        test.batteryPower.powerLoad = test.load_prediction[h] // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_DispatchAutoBTMPVChargeAndDischargeSmallLoad():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        if h > 6 and h < 18:
            test.pv_prediction.push_back(100)
        else:
            test.pv_prediction.push_back(0)
        if h > 18:
            test.load_prediction.push_back(40)
        else:
            test.load_prediction.push_back(30)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479)
    for h in range(24):
        test.batteryPower.powerLoad = 30
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 100 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 40 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_DispatchAutoBTMPVChargeAndDischargeSmallLoadWithLosses():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBatteryWithLosses(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.LOOK_AHEAD, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    for h in range(24):
        if h > 6 and h < 18:
            test.pv_prediction.push_back(100)
        else:
            test.pv_prediction.push_back(0)
        if h > 18:
            test.load_prediction.push_back(40)
        else:
            test.load_prediction.push_back(30)
    test.dispatchAutoBTM.update_load_data(test.load_prediction)
    test.dispatchAutoBTM.update_pv_data(test.pv_prediction)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479)
    for h in range(24):
        test.batteryPower.powerLoad = 30
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 100 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 40 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryDC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_DispatchAutoBTMCustomDispatch():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBattery(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.CUSTOM_DISPATCH, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479)
    test.dispatchAutoBTM.set_custom_dispatch(expectedPower)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    for h in range(24):
        test.batteryPower.powerLoad = 30
        test.batteryPower.powerSystem = 0
        if h > 6 and h < 18:
            test.batteryPower.powerSystem = 100 // Match the predicted PV
        elif h > 18:
            test.batteryPower.powerLoad = 40 // Match the predicted load
        test.dispatchAutoBTM.dispatch(0, h, 0)
        assert_almost_equal(test.batteryPower.powerBatteryAC, expectedPower[h], 0.5, " error in expected at hour " + str(h))

def test_DispatchAutoBTMCustomDispatchWithLosses():
    var dtHour: SimFloat = 1.0
    var test: AutoBTMTest_lib_battery_dispatch = AutoBTMTest_lib_battery_dispatch()
    test.CreateBatteryWithLosses(dtHour)
    test.dispatchAutoBTM = Pointer[dispatch_automatic_behind_the_meter_t](new dispatch_automatic_behind_the_meter_t(test.batteryModel, dtHour, SOC_min, SOC_max, currentChoice,
        max_current,
        max_current, max_power, max_power, max_power, max_power,
        0, dispatch_t.BTM_MODES.CUSTOM_DISPATCH, 0, 1, 24, 1, true,
        true, false, false, test.util_rate, test.replacementCost, test.cyclingChoice, test.cyclingCost))
    var dispatchedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479, 9.479)
    var expectedPower: List[SimFloat] = List[SimFloat](0, 0, 0, 0, 0, 0, 0, -50, -50, -50, -50, -50, -1.63, 0, 0, 0, 0, 0, 0, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479, 11.479)
    test.dispatchAutoBTM.set_custom_dispatch(dispatchedPower)
    test.batteryPower = test.dispatchAutoBTM.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    for h in range(24):
        test.batteryPower.powerLoad =