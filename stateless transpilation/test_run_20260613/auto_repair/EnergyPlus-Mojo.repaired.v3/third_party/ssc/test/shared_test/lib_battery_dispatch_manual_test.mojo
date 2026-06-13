from lib_battery_dispatch_manual import dispatch_manual_t
from lib_battery_dispatch_test import BatteryProperties, DispatchProperties
from lib_battery_dispatch import dispatch_t
from lib_battery import capacity_lithium_ion_t, voltage_dynamic_t, thermal_t, lifetime_t, losses_t, battery_t
from lib_shared_inverter import SharedInverter
from lib_util import util
from lib_charge_controller import ChargeController
from testing import *

var year: Int = 0
var hour_of_year: Int = 0
var step_of_hour: Int = 0

@value
struct ManualTest_lib_battery_dispatch(BatteryProperties, DispatchProperties):
    var capacityModel: capacity_lithium_ion_t
    var voltageModel: voltage_dynamic_t
    var thermalModel: thermal_t
    var lifetimeModel: lifetime_t
    var lossModel: losses_t
    var batteryModel: battery_t
    var batteryPower: BatteryPower
    var dispatchManual: dispatch_manual_t = None
    var surface_area: Float64 = 1.2 * 1.2 * 6
    var n_series: Int = 139
    var n_strings: Int = 89
    var currentChargeMax: Float64 = 100
    var currentDischargeMax: Float64 = 100
    var powerChargeMax: Float64 = 50
    var powerDischargeMax: Float64 = 50
    var pv_prediction: List[Float64]
    var load_prediction: List[Float64]
    var cliploss_prediction: List[Float64]
    var dtHour: Float64 = 1

    def __init__(inout self):
        BatteryProperties.__init__(self)
        DispatchProperties.__init__(self)
        self.n_strings = 445
        self.capacityModel = capacity_lithium_ion_t(Qfull * n_strings, SOC_init, SOC_max, SOC_min, 1.0)
        self.voltageModel = voltage_dynamic_t(n_series, n_strings, Vnom_default, Vfull, Vexp, Vnom, Qfull, Qexp, Qnom,
            C_rate, resistance, dtHour)
        self.lifetimeModel = lifetime_calendar_cycle_t(cycleLifeMatrix, dtHour, calendar_q0, calendar_a, calendar_b, calendar_c)
        self.thermalModel = thermal_t(1.0, mass, surface_area, resistance, Cp, h, capacityVsTemperature, T_room)
        self.lossModel = losses_t()
        self.batteryModel = battery_t(dtHour, chemistry, capacityModel, voltageModel, lifetimeModel, thermalModel, lossModel)
        var numberOfInverters: Int = 1
        self.m_sharedInverter = SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, sandia, partload, ond)

    def __moveinit__(inout self, owned existing: Self):
        self.capacityModel = existing.capacityModel^
        self.voltageModel = existing.voltageModel^
        self.thermalModel = existing.thermalModel^
        self.lifetimeModel = existing.lifetimeModel^
        self.lossModel = existing.lossModel^
        self.batteryModel = existing.batteryModel^
        self.batteryPower = existing.batteryPower^
        self.dispatchManual = existing.dispatchManual^
        self.surface_area = existing.surface_area
        self.n_series = existing.n_series
        self.n_strings = existing.n_strings
        self.currentChargeMax = existing.currentChargeMax
        self.currentDischargeMax = existing.currentDischargeMax
        self.powerChargeMax = existing.powerChargeMax
        self.powerDischargeMax = existing.powerDischargeMax
        self.pv_prediction = existing.pv_prediction^
        self.load_prediction = existing.load_prediction^
        self.cliploss_prediction = existing.cliploss_prediction^
        self.dtHour = existing.dtHour

    def __del__(owned self):
        BatteryProperties.__del__(self)
        del self.batteryModel
        del self.dispatchManual

@value
struct ManualTest_lib_battery_dispatch_losses(ManualTest_lib_battery_dispatch):
    def __init__(inout self):
        BatteryProperties.__init__(self)
        self.q = 1000. / 89.
        self.capacityModel = capacity_lithium_ion_t(q * n_strings, SOC_init, SOC_max, SOC_min, 1.0)
        self.voltageModel = voltage_dynamic_t(n_series, n_strings, Vnom_default, Vfull, Vexp, Vnom, Qfull, Qexp, Qnom,
            C_rate, resistance, dtHour)
        self.lifetimeModel = lifetime_calendar_cycle_t(cycleLifeMatrix, dtHour, calendar_q0, calendar_a, calendar_b, calendar_c)
        self.thermalModel = thermal_t(1.0, mass, surface_area, resistance, Cp, h, capacityVsTemperature, T_room)
        var charging_losses: List[Float64] = List[Float64](12, 1)
        var discharging_losses: List[Float64] = List[Float64](12, 2)
        var idle_losses: List[Float64] = List[Float64](12, 0.5)
        self.lossModel = losses_t(charging_losses, discharging_losses, idle_losses)
        self.batteryModel = battery_t(dtHour, chemistry, capacityModel, voltageModel, lifetimeModel, thermalModel, lossModel)
        var numberOfInverters: Int = 1
        self.m_sharedInverter = SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, sandia, partload, ond)

    def __moveinit__(inout self, owned existing: Self):
        ManualTest_lib_battery_dispatch.__moveinit__(self, existing^)

    def __del__(owned self):
        ManualTest_lib_battery_dispatch.__del__(self)

def test_PowerLimitsDispatchManualAC():
    var test: ManualTest_lib_battery_dispatch
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax,
                                           test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var powerToFill: Float64 = test.dispatchManual.battery_power_to_fill()
    assert_almost_equal(test.dispatchManual.battery_soc(), 50, 0.1)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -test.powerChargeMax, 2.0)
    assert_true(test.dispatchManual.battery_power_to_fill() < powerToFill)
    powerToFill = test.dispatchManual.battery_power_to_fill()
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, test.powerDischargeMax, 2.0)
    assert_true(test.dispatchManual.battery_power_to_fill() > powerToFill)

def test_PowerLimitsDispatchManualDC():
    var test: ManualTest_lib_battery_dispatch
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax,
                                           test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -test.powerChargeMax, 2.0)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, test.powerDischargeMax, 2.0)

def test_CurrentLimitsDispatchManualAC():
    var test: ManualTest_lib_battery_dispatch
    var testChoice: dispatch_t.CURRENT_CHOICE = dispatch_t.CURRENT_CHOICE.RESTRICT_CURRENT
    var testChargeMax: Float64 = 20
    var testDischargeMax: Float64 = 20
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, testChoice, testChargeMax,
                                           testDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    var current: Float64 = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, -testChargeMax, 2.0)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    current = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, testDischargeMax, 2.0)

def test_CurrentLimitsDispatchManualDC():
    var test: ManualTest_lib_battery_dispatch
    var testChoice: dispatch_t.CURRENT_CHOICE = dispatch_t.CURRENT_CHOICE.RESTRICT_CURRENT
    var testChargeMax: Float64 = 20
    var testDischargeMax: Float64 = 20
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, testChoice, testChargeMax,
                                           testDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    var current: Float64 = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, -testChargeMax, 2.0)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    current = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, testDischargeMax, 2.0)

def test_BothLimitsDispatchManualAC():
    var test: ManualTest_lib_battery_dispatch
    var testChoice: dispatch_t.CURRENT_CHOICE = dispatch_t.CURRENT_CHOICE.RESTRICT_BOTH
    var testChargeMax: Float64 = 20
    var testDischargeMax: Float64 = 20
    var testDischargeMaxPower: Float64 = 11
    var testChargeMaxPower: Float64 = 12
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, testChoice, testChargeMax,
                                           testDischargeMax, testChargeMaxPower, testDischargeMaxPower,
                                           testChargeMaxPower, testDischargeMaxPower, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    var current: Float64 = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, -testChargeMax, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 1200
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -testChargeMaxPower, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    current = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, testDischargeMax, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 1200
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, testDischargeMaxPower, 2.0)

def test_BothLimitsDispatchManualDC():
    var test: ManualTest_lib_battery_dispatch
    var testChoice: dispatch_t.CURRENT_CHOICE = dispatch_t.CURRENT_CHOICE.RESTRICT_BOTH
    var testChargeMax: Float64 = 20
    var testDischargeMax: Float64 = 20
    var testDischargeMaxPower: Float64 = 11
    var testChargeMaxPower: Float64 = 11
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, testChoice, testChargeMax,
                                           testDischargeMax, testChargeMaxPower, testDischargeMaxPower, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    var current: Float64 = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, -testChargeMax, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    current = test.batteryPower.powerBatteryDC * util.kilowatt_to_watt / test.batteryPower.voltageSystem
    assert_almost_equal(current, testDischargeMax, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 1200
    test.batteryPower.powerLoad = 0
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, -testChargeMaxPower, 2.0)
    hour_of_year += 1
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 1200
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, testDischargeMaxPower, 2.0)

def test_DispatchChangeFrequency():
    var test: ManualTest_lib_battery_dispatch
    var testTimestep: Float64 = 1.0 / 60.0
    var testMinTime: Float64 = 4.0
    test.dispatchManual = dispatch_manual_t(test.batteryModel, testTimestep, test.SOC_min, test.SOC_max, test.currentChoice,
                                           test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax,
                                           test.powerChargeMax, test.powerDischargeMax, testMinTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -test.powerChargeMax, 2.0)
    step_of_hour += 1
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)
    step_of_hour += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)
    step_of_hour += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)
    step_of_hour += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 2.0)
    step_of_hour += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, test.powerChargeMax, 2.0)

def test_SOCLimitsOnDispatch():
    var test: ManualTest_lib_battery_dispatch
    hour_of_year = 0
    step_of_hour = 0
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax,
                                           test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax,
                                           test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge,
                                           test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge,
                                           test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    var soc: Float64 = test.dispatchManual.battery_soc()
    assert_almost_equal(test.dispatchManual.battery_soc(), 50, 0.1)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    while soc < test.SOC_max and hour_of_year < 100:
        test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
        hour_of_year += 1
        assert_true(test.dispatchManual.battery_soc() > soc)
        soc = test.dispatchManual.battery_soc()
    assert_almost_equal(test.SOC_max, test.dispatchManual.battery_soc(), 0.1)
    assert_almost_equal(6, hour_of_year, 0.1)
    hour_of_year += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    while soc > test.SOC_min + test.tolerance and hour_of_year < 100:
        test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
        hour_of_year += 1
        soc = test.dispatchManual.battery_soc()
    assert_almost_equal(test.SOC_min, test.dispatchManual.battery_soc(), 0.1)
    assert_almost_equal(16, hour_of_year, 0.1)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    while soc > test.SOC_min + test.tolerance and hour_of_year < 100:
        test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
        hour_of_year += 1
        soc = test.dispatchManual.battery_soc()
    assert_almost_equal(test.SOC_min, test.dispatchManual.battery_soc(), 0.1)
    assert_almost_equal(16, hour_of_year, 0.1)
    hour_of_year += 1
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)

def test_ManualGridChargingOffTest():
    var test: ManualTest_lib_battery_dispatch
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge, test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0, 0.1)
    assert_almost_equal(test.batteryPower.powerGridToBattery, 0, 0.1)

def test_ManualGridChargingOnTest():
    var test: ManualTest_lib_battery_dispatch
    var testCanGridcharge: List[Bool] = List[Bool]()
    var testPercentGridCharge: Dict[Int, Float64] = Dict[Int, Float64]()
    for p in range(6):
        testCanGridcharge.append(True)
        testPercentGridCharge[p] = 100
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, testCanGridcharge, test.canGridcharge, test.percentDischarge, testPercentGridCharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.batteryPower.inverterEfficiencyCutoff = 0
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, -test.powerChargeMax * test.batteryPower.singlePointEfficiencyACToDC, 1.0)
    assert_almost_equal(test.batteryPower.powerGridToBattery, test.powerChargeMax, 2.0)

def test_ManualGridChargingOnDCConnectedTest():
    var test: ManualTest_lib_battery_dispatch
    var testCanGridcharge: List[Bool] = List[Bool]()
    var testPercentGridCharge: Dict[Int, Float64] = Dict[Int, Float64]()
    for p in range(6):
        testCanGridcharge.append(True)
        testPercentGridCharge[p] = 100
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
        test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, testCanGridcharge, test.canGridcharge, test.percentDischarge, testPercentGridCharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.inverterEfficiencyCutoff = 0
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, -test.powerChargeMax * test.batteryPower.singlePointEfficiencyACToDC, 1.0)
    assert_almost_equal(test.batteryPower.powerGridToBattery, test.powerChargeMax, 2.0)

def test_NoGridChargingWhilePVIsOnTest():
    var test: ManualTest_lib_battery_dispatch
    var testCanGridcharge: List[Bool] = List[Bool]()
    var testPercentGridCharge: Dict[Int, Float64] = Dict[Int, Float64]()
    for p in range(6):
        testCanGridcharge.append(True)
        testPercentGridCharge[p] = 100
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, testCanGridcharge, test.canGridcharge, test.percentDischarge, testPercentGridCharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -test.powerChargeMax, 1.0)
    assert_almost_equal(test.batteryPower.powerGridToBattery, 0.0, 2.0)

def test_EfficiencyLimitsDispatchManualDC():
    var test: ManualTest_lib_battery_dispatch
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge, test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryAC, -test.powerChargeMax, 2.0)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerBatteryDC, test.powerDischargeMax, 2.0)

def test_InverterEfficiencyCutoffDC():
    var test: ManualTest_lib_battery_dispatch
    var testCanGridcharge: List[Bool] = List[Bool]()
    var testPercentGridCharge: Dict[Int, Float64] = Dict[Int, Float64]()
    for p in range(6):
        testCanGridcharge.append(True)
        testPercentGridCharge[p] = 1
    testPercentGridCharge[1] = 1
    testPercentGridCharge[3] = 100
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
                                           test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, testCanGridcharge, test.canGridcharge, testPercentGridCharge, testPercentGridCharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.inverterEfficiencyCutoff = 80
    test.batteryPower.canGridCharge = True
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 7
    test.dispatchManual.dispatch(year, 0, step_of_hour)
    assert_almost_equal(test.batteryPower.sharedInverter.efficiencyAC, 0.0, 0.1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 0.1)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 1000
    test.dispatchManual.dispatch(year, 12, step_of_hour)
    assert_almost_equal(test.batteryPower.sharedInverter.efficiencyAC, 93.7, 0.1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, -47.9, 0.1)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 0
    test.batteryPower.powerLoad = 7
    test.dispatchManual.dispatch(year, 0, step_of_hour)
    assert_almost_equal(test.batteryPower.sharedInverter.efficiencyAC, 35.82, 0.1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 4.43, 0.1)
    test.batteryPower.powerSystem = 770
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 0
    test.batteryPower.powerLoad = 1000
    test.dispatchManual.dispatch(year, 12, step_of_hour)
    assert_almost_equal(test.batteryPower.sharedInverter.efficiencyAC, 93.9, 0.1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 49.9, 0.1)
    test.batteryPower.powerSystem = 1000
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerGridToBattery = 0
    test.batteryPower.powerLoad = 1100
    test.dispatchManual.dispatch(year, 12, step_of_hour)
    assert_almost_equal(test.batteryPower.sharedInverter.efficiencyAC, 77, 0.1)
    assert_almost_equal(test.batteryPower.powerBatteryDC, 0.0, 2.0)

def test_TestLossesWithDispatch():
    var test: ManualTest_lib_battery_dispatch_losses
    test.dispatchManual = dispatch_manual_t(test.batteryModel, test.dtHour, test.SOC_min, test.SOC_max, test.currentChoice, test.currentChargeMax, test.currentDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.powerChargeMax, test.powerDischargeMax, test.minimumModeTime,
        test.dispatchChoice, test.meterPosition, test.scheduleWeekday, test.scheduleWeekend, test.canCharge, test.canDischarge, test.canGridcharge, test.canGridcharge, test.percentDischarge, test.percentGridcharge)
    test.batteryPower = test.dispatchManual.getBatteryPower()
    test.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.batteryPower.setSharedInverter(test.m_sharedInverter)
    test.batteryPower.powerSystem = 40
    test.batteryPower.voltageSystem = 600
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerSystemToBattery, test.batteryPower.powerSystem - test.batteryPower.powerSystemLoss, 0.1)
    test.batteryPower.powerSystem = 0
    test.batteryPower.voltageSystem = 600
    test.batteryPower.powerLoad = 40
    test.dispatchManual.dispatch(year, hour_of_year, step_of_hour)
    assert_almost_equal(test.batteryPower.powerGeneratedBySystem, test.batteryPower.powerLoad, 0.5)
    assert_almost_equal(test.batteryPower.powerBatteryToLoad, test.batteryPower.powerLoad, 0.5)