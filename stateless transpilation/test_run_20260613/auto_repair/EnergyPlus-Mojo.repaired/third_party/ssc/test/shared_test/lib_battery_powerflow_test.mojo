from testing import *
from ...shared.lib_battery_powerflow import BatteryPowerFlow, BatteryPower, ChargeController
from lib_ondinv import ond_inverter
from lib_power_electronics import *
from lib_pvinv import partload_inverter_t
from lib_sandia import sandia_inverter_t
from lib_shared_inverter import SharedInverter

struct sandia_inverter_t:

struct partload_inverter_t:

struct ond_inverter:

@value
struct BatteryPowerFlowTest_lib_battery_powerflow:
    var m_batteryPowerFlow: BatteryPowerFlow
    var m_batteryPower: BatteryPower
    var m_sharedInverter: SharedInverter
    var sandia: sandia_inverter_t
    var partload: partload_inverter_t
    var ond: ond_inverter
    var error: Float64

    def __init__(inout self):
        self.error = 0.02
        var dtHour: Float64 = 1.0
        self.m_batteryPowerFlow = BatteryPowerFlow(dtHour)
        self.m_batteryPower = self.m_batteryPowerFlow.getBatteryPower()
        self.m_batteryPower.reset()
        self.m_batteryPower.canDischarge = False
        self.m_batteryPower.canSystemCharge = False
        self.m_batteryPower.canGridCharge = False
        self.m_batteryPower.singlePointEfficiencyACToDC = 0.96
        self.m_batteryPower.singlePointEfficiencyDCToAC = 0.96
        self.m_batteryPower.singlePointEfficiencyDCToDC = 0.98
        self.m_batteryPower.powerBatteryChargeMaxDC = 100
        self.m_batteryPower.powerBatteryDischargeMaxDC = 50
        self.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
        var numberOfInverters: Int = 100
        self.sandia = sandia_inverter_t()
        self.partload = partload_inverter_t()
        self.ond = ond_inverter()
        self.sandia.C0 = -3.18e-6
        self.sandia.C1 = -5.12e-5
        self.sandia.C2 = 0.000984
        self.sandia.C3 = -0.00151
        self.sandia.Paco = 3800
        self.sandia.Pdco = 3928.11
        self.sandia.Vdco = 398.497
        self.sandia.Pso = 19.4516
        self.sandia.Pntare = 0.99
        self.m_sharedInverter = SharedInverter(SharedInverter.SANDIA_INVERTER, numberOfInverters, self.sandia, self.partload, self.ond)
        self.m_batteryPower.setSharedInverter(self.m_sharedInverter)

    def calc_dc_gen(self) -> Float64:
        return self.m_batteryPower.powerBatteryAC + self.m_batteryPower.powerSystem - self.m_batteryPower.powerSystemLoss

    def calc_met_load(self) -> Float64:
        return self.m_batteryPower.powerBatteryToLoad + self.m_batteryPower.powerGridToLoad + self.m_batteryPower.powerSystemToLoad

    def check_net_flows(self, id_string: String):
        var dc_error: Float64 = 4
        var gen: Float64 = self.calc_dc_gen()
        expect_almost_equal(self.m_batteryPower.powerGeneratedBySystem, gen, dc_error, id_string)
        var met_load: Float64 = self.calc_met_load()
        expect_almost_equal(met_load, self.m_batteryPower.powerLoad, dc_error, id_string)

    def __del__(owned self):
        if self.m_batteryPowerFlow:
            self.m_batteryPowerFlow = BatteryPowerFlow()
        if self.m_sharedInverter:
            self.m_sharedInverter = SharedInverter()
        if self.sandia:
            self.sandia = sandia_inverter_t()
        if self.partload:
            self.partload = partload_inverter_t()
        if self.ond:
            self.ond = ond_inverter()

def TestInitialize():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.powerSystem = 100
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPowerFlow.initialize(50)
    expect_equal(test.m_batteryPower.powerBatteryDC, -50)
    test.m_batteryPower.canGridCharge = True
    test.m_batteryPowerFlow.initialize(50)
    expect_equal(test.m_batteryPower.powerBatteryDC, -test.m_batteryPower.powerBatteryChargeMaxDC)
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.powerSystem = 50
    test.m_batteryPower.powerLoad = 100
    test.m_batteryPowerFlow.initialize(50)
    expect_equal(test.m_batteryPower.powerBatteryDC, test.m_batteryPower.powerBatteryDischargeMaxDC)

def AC_PVCharging_ExcessPV():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canGridCharge = False
    test.m_batteryPower.powerSystem = 100
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = -50 * test.m_batteryPower.singlePointEfficiencyACToDC
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.m_batteryPower.powerBatteryDC = 50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 48, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -48 * test.m_batteryPower.singlePointEfficiencyACToDC
    test.m_batteryPower.powerSystemLoss = 2.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -48, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 48, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 1.92, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -48, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 48, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 1.92, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    test.m_batteryPower.powerBatteryDC = 50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 48, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def AC_PVCharging_ExcessLoad():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canGridCharge = False
    test.m_batteryPower.powerSystem = 25
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 5.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPower.powerSystemLoss = 0.5
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.5, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPower.powerSystemLoss = 1.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 6.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 18.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 25, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def AC_GridCharging_ExcessPV():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canGridCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canSystemCharge = False
    test.m_batteryPower.powerSystem = 100
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = -50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -52.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 52.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.80, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -50
    test.m_batteryPower.powerSystemLoss = 2.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -52.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 52.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.08, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 17.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.80, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 2.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def AC_GridCharging_ExcessLoad():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canGridCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canSystemCharge = False
    test.m_batteryPower.powerSystem = 10
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 20.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPower.powerSystemLoss = 0.5
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.5, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPower.powerSystemLoss = 1.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 21.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 18.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def AC_GridPVCharging_ExcessPV():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canGridCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.powerSystem = 100
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = -40
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -41.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 41.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 8.33, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 8.33, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 1.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -104.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 54.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 4.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.80, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -40
    test.m_batteryPower.powerSystemLoss = 1.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -41.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 41.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 7.33, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 1.66, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -104.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 49, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 55.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 4.16, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 18.2, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.80, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def AC_GridPVCharging_ExcessLoad():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.AC_CONNECTED
    test.m_batteryPower.canGridCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.powerSystem = 10
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    var gen: Float64 = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 20.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPower.powerSystemLoss = 0.5
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.5, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPower.powerSystemLoss = 1.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 20.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 40, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.83, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 19.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 10, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 21.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 18.19, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 0.8, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    gen = test.m_batteryPower.powerSystem + test.m_batteryPower.powerBatteryAC - test.m_batteryPower.powerSystemLoss
    expect_almost_equal(test.m_batteryPower.powerGeneratedBySystem, gen, test.error)
    expect_almost_equal(test.m_batteryPower.powerLoad, 50, test.error)

def DC_PVCharging_ExcessPV():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canGridCharge = False
    test.m_batteryPower.powerSystem = 100
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = -50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -51.02, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 46.24, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 51.02, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 3.75, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 3.75, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -100, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 100, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -150
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -100, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 100, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = 50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 47.39, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 46.71, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 5.89, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -50
    test.m_batteryPower.powerSystemLoss = 1.0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -51.02, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 45.24, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 51.02, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 4.75, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 3.75, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -100
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -99, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 99, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -150
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -99, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 99, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = 50
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 46.42, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 46.71, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 5.87, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 1.0, test.error)
    test.check_net_flows(String())

def DC_PVCharging_ExcessLoad():
    var test = BatteryPowerFlowTest_lib_battery_powerflow()
    test.m_batteryPower.connectionMode = ChargeController.DC_CONNECTED
    test.m_batteryPower.canSystemCharge = True
    test.m_batteryPower.canDischarge = True
    test.m_batteryPower.canGridCharge = False
    test.m_batteryPower.powerSystem = 25
    test.m_batteryPower.powerLoad = 50
    test.m_batteryPower.powerBatteryDC = 0
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 22.68, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 27.31, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.32, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = 20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, 18.43, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 23.50, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 8.05, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 18.43, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 3.05, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_flows(String())
    test.m_batteryPower.powerBatteryDC = -20
    test.m_batteryPowerFlow.calculate()
    expect_almost_equal(test.m_batteryPower.powerBatteryAC, -20.4, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToLoad, 2.60, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToBattery, 20.40, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToBattery, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerGridToLoad, 47.39, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemToGrid, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerBatteryToLoad, 0, test.error)
    expect_almost_equal(test.m_batteryPower.powerConversionLoss, 2.39, test.error)
    expect_almost_equal(test.m_batteryPower.powerSystemLoss, 0.0, test.error)
    test.check_net_