from lib_battery_dispatch_automatic_fom_test.h import AutoFOM_lib_battery_dispatch
from lib_battery_dispatch_test import BatteryProperties, DispatchProperties
from lib_battery_dispatch_automatic_fom import dispatch_automatic_front_of_meter_t
from lib_battery import battery_t, capacity_lithium_ion_t, voltage_dynamic_t, lifetime_calendar_cycle_t, thermal_t, losses_t
from lib_shared_inverter import SharedInverter
from lib_battery_power import BatteryPower, ChargeController
from lib_battery_dispatch import dispatch_t
from gtest import Test, EXPECT_FALSE, EXPECT_NEAR

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOMInput")
def DispatchFOMInput(self: AutoFOM_lib_battery_dispatch):
    var dtHourFOM: Float64 = 1.0
    self.CreateBattery(dtHourFOM)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHourFOM, 15, 95, 1, 999, 999, self.max_power, self.max_power,
                                                           self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 24, 1, True, True, False, True, 0,
                                                          self.replacementCost, 0, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    var P_batt: List[Float64] = List[Float64](-336.062, 336.062)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.powerSystem = 750
    self.batteryPower.powerFuelCell = 300
    self.dispatchAuto.set_custom_dispatch(P_batt)
    EXPECT_FALSE(self.batteryPower.canGridCharge)
    self.dispatchAuto.update_dispatch(0, 0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -322.6, 0.1)
    self.dispatchAuto.dispatch(0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, -322.6, 0.1)
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, -336.1, 0.1)
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)
    EXPECT_NEAR(self.dispatchAuto.battery_model().SOC(), 50.2, 1e-2)
    self.dispatchAuto.update_dispatch(0, 0, 0, 1)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, 350.0, 0.1)
    self.dispatchAuto.dispatch(0, 1, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, 350, 0.1)
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, 336, 0.1)
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOMInputWithLosses")
def DispatchFOMInputWithLosses(self: AutoFOM_lib_battery_dispatch):
    var dtHourFOM: Float64 = 1.0
    self.CreateBatteryWithLosses(dtHourFOM)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHourFOM, 15, 95, 1, 999, 999, self.max_power, self.max_power,
        self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 24, 1, True, True, False, True, 0,
        self.replacementCost, 0, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    var P_batt: List[Float64] = List[Float64](-336.062, 336.062)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.powerSystem = 750
    self.batteryPower.powerFuelCell = 300
    self.dispatchAuto.set_custom_dispatch(P_batt)
    EXPECT_FALSE(self.batteryPower.canGridCharge)
    self.dispatchAuto.update_dispatch(0, 0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -322.6, 0.1)
    self.dispatchAuto.dispatch(0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, -322.6, 0.1) 
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, -336.1, 0.1) # Expect charging to remain unchanged, losses will come from the grid
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)
    EXPECT_NEAR(self.batteryPower.powerSystemLoss, 10.0, 0.1)
    EXPECT_NEAR(self.dispatchAuto.battery_model().SOC(), 50.2, 1e-2)
    self.dispatchAuto.update_dispatch(0, 0, 0, 1)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, 370.9, 0.1)
    self.dispatchAuto.dispatch(0, 1, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, 370.9, 0.1)
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, 356, 0.1) # Dispatch increases to cover loss
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)
    EXPECT_NEAR(self.batteryPower.powerSystemLoss, 20.0, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOMInputSubhourly")
def DispatchFOMInputSubhourly(self: AutoFOM_lib_battery_dispatch):
    var dtHourFOM: Float64 = 0.5
    self.CreateBattery(dtHourFOM)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHourFOM, 15, 95, 1, 999, 999, self.max_power, self.max_power,
                                                           self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 24, 1, True, True, False, True, 0,
                                                            self.replacementCost, 0, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    var P_batt: List[Float64] = List[Float64](-336.062, 336.062)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.powerSystem = 750
    self.batteryPower.powerFuelCell = 300
    self.dispatchAuto.set_custom_dispatch(P_batt)
    EXPECT_FALSE(self.batteryPower.canGridCharge)
    self.dispatchAuto.update_dispatch(0, 0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -322.6, 0.1)
    self.dispatchAuto.dispatch(0, 0, 0)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, -322.6, 0.1)
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, -336.1, 0.1)
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)
    EXPECT_NEAR(self.dispatchAuto.battery_model().SOC(), 50.1, 0.1)
    self.dispatchAuto.update_dispatch(0, 0, 0, 1)
    EXPECT_NEAR(self.batteryPower.powerBatteryTarget, 350.0, 0.1)
    self.dispatchAuto.dispatch(0, 0, 1)
    EXPECT_NEAR(self.batteryPower.powerBatteryDC, 350, 0.1)
    EXPECT_NEAR(self.batteryPower.powerBatteryAC, 336, 0.1)
    EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_DCCustomCharge")
def DispatchFOM_DCCustomCharge(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 18, 1, True,
                                                           True, True, False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98,
                                                           98)
    var P_batt: List[Float64] = List[Float64](6, -25000)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.dispatchAuto.set_custom_dispatch(P_batt)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.canGridCharge = True
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    self.batteryPower.inverterEfficiencyCutoff = 0
    self.batteryPower.powerGeneratedBySystem = 0
    self.batteryPower.powerSystem = 0
    self.batteryPower.powerSystemClipped = 0
    var SOC: List[Float64] = List[Float64](64.42, 78.77, 93.06, 100., 100., 100.)
    for h in range(6):
        self.dispatchAuto.update_dispatch(0, 0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -25000, 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1)
        if h < 3:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -25000, 100) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 25868, 100) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 97.6, 0.1)
        elif h == 3:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -12207, 100) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 12589, 100) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 97.9, 0.1)
        else:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, 0, 1e-3) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 0, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_DCCustomChargeSubhourly")
def DispatchFOM_DCCustomChargeSubhourly(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 0.5
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 18, 1, True,
                                                           True, True, False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98,
                                                           98)
    var P_batt: List[Float64] = List[Float64](12, -25000)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.dispatchAuto.set_custom_dispatch(P_batt)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.canGridCharge = True
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    self.batteryPower.inverterEfficiencyCutoff = 0
    self.batteryPower.powerGeneratedBySystem = 0
    self.batteryPower.powerSystem = 0
    self.batteryPower.powerSystemClipped = 0
    var SOC: List[Float64] = List[Float64](57.24, 64.45, 71.64, 78.81, 85.97, 93.12, 100.00, 100.00, 100.00, 100.00, 100.00, 100.00)
    for h in range(12):
        var hour_of_year: Int = hour_of_year_from_index(h, dtHour)
        var step: Int = step_from_index(h, dtHour)
        self.dispatchAuto.update_dispatch(0, hour_of_year, step, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -25000, 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, hour_of_year, step)
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "hour " << h
        if h < 6:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -25000, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 25868, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 97.6, 0.1)
        elif h == 6:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -24392, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 25233, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 97.64, 0.1)
        else:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, 0, 1e-3) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 0, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_DCAuto")
def DispatchFOM_DCAuto(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
                                                           False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0., # 0 - 5
                                        -41690.48, -16690.50, -2334.45, -324.19, 0., 0., # 6 - 11
                                        0., 0., 0., 0., 0., 77000, # 12 - 17
                                        77000, 77000, 77000, 77000, 77000, 0.) # 18 - 23
    var dispatchedkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0., # 0 - 5
                                        -29200.17, -16690.50, -2334.45, -324.19, 0., 0., # 6 - 11
                                        0., 0., 0., 0., 0., 28116.05, # 18
                                        27946.64, 27664.23, 27099.14, 25401.83, 9343.36, 0.) # 24
    var SOC: List[Float64] = List[Float64](55.72, 61.58, 66.93, 71.12, 72.21, 72.21, # 6
                                88.87, 98.44, 99.78, 99.97, 99.97, 99.97, # 12
                                99.97, 99.97, 99.97, 99.97, 99.97, 83.30, # 12 - 17
                                66.63, 49.97, 33.30, 16.63, 10, 10) # 18 - 23
    for h in range(24):
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, h, 0, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, dispatchedkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_DCAutoWithLosses")
def DispatchFOM_DCAutoWithLosses(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBatteryWithLosses(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
        self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
        False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0., # 0 - 5
                                    -41690.48, -16690.50, -2334.45, -324.19, 0., 0., # 6 - 11
                                    0., 0., 0., 0., 0., 77005, # 12 - 17
                                    77005, 77005, 77005, 77005, 77005, 0.) # 18 - 23
    var dispatchedkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0., # 0 - 5
                                        -29200.17, -16690.50, -2334.45, -324.19, 0., 0., # 6 - 11
                                        0., 0., 0., 0., 0., 28116.05, # 18
                                        27946.64, 27664.23, 27099.14, 25401.83, 9343.36, 0.) # 24
    var SOC: List[Float64] = List[Float64](55.72, 61.58, 66.93, 71.12, 72.21, 72.21, # 6
                                88.87, 98.44, 99.78, 99.97, 99.97, 99.97, # 12
                                99.97, 99.97, 99.97, 99.97, 99.97, 83.30, # 12 - 17
                                66.63, 49.97, 33.30, 16.63, 10, 10) # 18 - 23
    for h in range(24):
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, h, 0, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, dispatchedkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_DCAutoSubhourly")
def DispatchFOM_DCAutoSubhourly(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 0.5
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
                                                           False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.DC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.)
    var SOC: List[Float64] = List[Float64](52.86, 55.80, 58.49, 60.60, 61.14, 61.14)
    for h in range(6):
        var hour_of_year: Int = hour_of_year_from_index(h, dtHour)
        var step: Int = step_from_index(h, dtHour)
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, hour_of_year, step, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, hour_of_year, step)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, targetkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_ACCustomCharge")
def DispatchFOM_ACCustomCharge(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 18, 1, True,
                                                             True, True, False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98,
                                                             98)
    var P_batt: List[Float64] = List[Float64](6, -25000)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.dispatchAuto.set_custom_dispatch(P_batt)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.canGridCharge = True
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    self.batteryPower.powerGeneratedBySystem = 0
    self.batteryPower.powerSystem = 0
    self.batteryPower.powerSystemClipped = 0
    var SOC: List[Float64] = List[Float64](63.86, 77.64, 91.37, 100.00, 100.00, 100.00)
    for h in range(6):
        self.dispatchAuto.update_dispatch(0, 0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -24000, 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1)
        if h < 3:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -24000, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 25000, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)
        elif h == 3:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -15195, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 15828., 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)
        else:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, 0, 1e-3) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_ACCustomChargeSubhourly")
def DispatchFOM_ACCustomChargeSubhourly(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 0.5
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_CUSTOM_DISPATCH, dispatch_t.FRONT, 1, 18, 1, True,
                                                           True, True, False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98,
                                                           98)
    var P_batt: List[Float64] = List[Float64](12, -25000)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.dispatchAuto.set_custom_dispatch(P_batt)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.canGridCharge = True
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    self.batteryPower.powerGeneratedBySystem = 0
    self.batteryPower.powerSystem = 0
    self.batteryPower.powerSystemClipped = 0
    var SOC: List[Float64] = List[Float64](56.95, 63.88, 70.79, 77.68, 84.56, 91.43, 98.28, 100.00, 100.00, 100.00, 100.00, 100.00)
    for h in range(12):
        var hour_of_year: Int = hour_of_year_from_index(h, dtHour)
        var step: Int = step_from_index(h, dtHour)
        self.dispatchAuto.update_dispatch(0, hour_of_year, step, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, -24000, 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, hour_of_year, step)
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1)
        if h < 7:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -24000, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 25000, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)
        elif h == 7:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, -6022, 1) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 6273, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)
        else:
            EXPECT_NEAR(self.batteryPower.powerBatteryDC, 0, 1e-3) << "error in dispatched power at hour " << h
            EXPECT_NEAR(self.batteryPower.powerGridToBattery, 0, 1) << "hour " << h
            EXPECT_NEAR(self.batteryPower.sharedInverter.efficiencyAC, 96, 0.1)

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_ACAuto")
def DispatchFOM_ACAuto(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
                                                           False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv) # PV Resource is available for the 1st 10 hrs
    self.dispatchAuto.update_cliploss_data(self.clip) # Clip charging is available for the 1st 5 hrs
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.,
                                    -41690.48, -16690.50, -2334.45, -324.19, 0., 0.,
                                    0., 0., 0., 0., 0., 77000,
                                    77000, 77000, 77000, 77000, 77000, 0.)
    var dispatchedkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.,
                                -29200.17, -16690.50, -2334.45, -324.19, 0., 0.,
                                0., 0., 0., 0., 0., 28116.05,
                                27946.64, 27664.23, 27099.14, 25401.83, 9343.36, 0.)
    var SOC: List[Float64] = List[Float64](55.72, 61.58, 66.93, 71.12, 72.21, 72.21,
                                88.87, 98.44, 99.78, 99.97, 99.97, 99.97,
                                99.97, 99.97, 99.97, 99.97, 99.97, 83.30,
                                66.63, 49.97, 33.30, 16.63, 10.0, 10.0)
    for h in range(24):
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, h, 0, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, dispatchedkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_ACAutoWithLosses")
def DispatchFOM_ACAutoWithLosses(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 1
    self.CreateBatteryWithLosses(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
        self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
        False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv) # PV Resource is available for the 1st 10 hrs
    self.dispatchAuto.update_cliploss_data(self.clip) # Clip charging is available for the 1st 5 hrs
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.,
                                    -41690.48, -16690.50, -2334.45, -324.19, 0., 0.,
                                    0., 0., 0., 0., 0., 77000,
                                    77000, 77000, 77000, 77000, 77000, 0.)
    var dispatchedkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.,
                                -29200.17, -16690.50, -2334.45, -324.19, 0., 0.,
                                0., 0., 0., 0., 0., 28116.05,
                                27946.64, 27664.23, 27099.14, 25401.83, 9343.36, 0.) # Battery was already discharging at max power, it stays unchanged
    var SOC: List[Float64] = List[Float64](55.72, 61.58, 66.93, 71.12, 72.21, 72.21,
                                88.87, 98.44, 99.78, 99.97, 99.97, 99.97,
                                99.97, 99.97, 99.97, 99.97, 99.97, 83.30,
                                66.63, 49.97, 33.30, 16.63, 10.0, 10.0)
    for h in range(24):
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, h, 0, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, h, 0)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, dispatchedkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h

@register_test("AutoFOM_lib_battery_dispatch", "DispatchFOM_ACAutoSubhourly")
def DispatchFOM_ACAutoSubhourly(self: AutoFOM_lib_battery_dispatch):
    var dtHour: Float64 = 0.5
    self.CreateBattery(dtHour)
    self.dispatchAuto = dispatch_automatic_front_of_meter_t(self.batteryModel, dtHour, 10, 100, 1, 49960, 49960, self.max_power,
                                                           self.max_power, self.max_power, self.max_power, 1, dispatch_t.FOM_LOOK_AHEAD, dispatch_t.FRONT, 1, 18, 1, True, True, False,
                                                           False, 77000, self.replacementCost, 1, self.cyclingCost, self.ppaRate, self.ur, 98, 98, 98)
    self.dispatchAuto.update_pv_data(self.pv)
    self.dispatchAuto.update_cliploss_data(self.clip)
    self.batteryPower = self.dispatchAuto.getBatteryPower()
    self.batteryPower.connectionMode = ChargeController.AC_CONNECTED
    self.batteryPower.voltageSystem = 600
    self.batteryPower.setSharedInverter(self.m_sharedInverter)
    var targetkW: List[Float64] = List[Float64](-9767.18, -10052.40, -9202.19, -7205.42, -1854.60, 0.)
    var SOC: List[Float64] = List[Float64](52.86, 55.80, 58.49, 60.60, 61.14, 61.14)
    for h in range(6):
        var hour_of_year: Int = hour_of_year_from_index(h, dtHour)
        var step: Int = step_from_index(h, dtHour)
        self.batteryPower.powerGeneratedBySystem = self.pv[h]
        self.batteryPower.powerSystem = self.pv[h]
        self.batteryPower.powerSystemClipped = self.clip[h]
        self.dispatchAuto.update_dispatch(0, hour_of_year, step, h)
        EXPECT_NEAR(self.batteryPower.powerBatteryTarget, targetkW[h], 0.1) << "error in expected target at hour " << h
        self.dispatchAuto.dispatch(0, hour_of_year, step)
        EXPECT_NEAR(self.batteryPower.powerBatteryDC, targetkW[h], 0.1) << "error in dispatched power at hour " << h
        EXPECT_NEAR(self.dispatchAuto.battery_soc(), SOC[h], 0.1) << "error in SOC at hour " << h